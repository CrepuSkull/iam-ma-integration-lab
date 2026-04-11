<#
.SYNOPSIS
    Remediate-StaleAccounts.ps1
    Désactivation des comptes obsolètes AD CorpB après validation manager.

.DESCRIPTION
    Lit un CSV de validation produit par Audit-StaleAccounts.ps1 et traité
    par les managers. Pour chaque ligne où la colonne Valider contient
    exactement "OUI" :
      1. Désactive le compte AD
      2. Déplace le compte vers l'OU Archived
      3. Ajoute une description horodatée
      4. Log l'action avec état avant/après pour rollback

    GARDE-FOUS :
      - DryRun par défaut ($true) — aucune écriture sans -DryRun:$false
      - Seul "OUI" exact (majuscules, sans espace) déclenche l'action
      - Le CSV doit contenir les colonnes ValidatedBy et ValidationDate
      - Un fichier rollback est produit avant toute modification

.PARAMETER CsvPath
    Chemin vers le CSV de validation complété par les managers

.PARAMETER DryRun
    Simulation sans écriture AD (défaut : $true)

.PARAMETER TargetOU
    OU de destination pour les comptes désactivés (défaut : OU Archived)

.PARAMETER OutputPath
    Répertoire de sortie pour les rapports d'exécution

.PARAMETER SearchBase
    OU racine de recherche AD

.EXAMPLE
    # Simulation
    .\Remediate-StaleAccounts.ps1 -CsvPath ".\validation-csv\stale-validated.csv" -DryRun

.EXAMPLE
    # Exécution réelle
    .\Remediate-StaleAccounts.ps1 -CsvPath ".\validation-csv\stale-validated.csv" -DryRun:$false

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / phase2-remediation
    Mapping réglementaire : ISO 27001:2022 A.5.15, A.8.5 | NIS2 Art.21§2(e) | RGPD Art.5(1)(c)(e)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [string]$TargetOU = "OU=Archived,OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [string]$SearchBase = "OU=CorpB-Lab,DC=lab,DC=local"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$ExecutionLog = Join-Path $OutputPath "phase2-stale-execution_$Timestamp.csv"
$RollbackFile = Join-Path $OutputPath "phase2-stale-rollback_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  Remediate-StaleAccounts.ps1" -ForegroundColor White
Write-Host "  Mode : $(if ($DryRun) { 'DRYRUN — Aucune écriture AD' } else { 'EXECUTION REELLE — Ecriture AD ACTIVE' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  CSV  : $CsvPath" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host ""

# ---------------------------------------------------------------------------
# Vérifications préalables
# ---------------------------------------------------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "  [ERROR] CSV introuvable : $CsvPath" -ForegroundColor Red
    exit 1
}

$csvData = Import-Csv -Path $CsvPath -Delimiter ";" -Encoding UTF8

# Vérifier les colonnes obligatoires
$requiredCols = @("sAMAccountName","Valider","ValidatedBy","ValidationDate")
$csvCols = $csvData[0].PSObject.Properties.Name
$missing = $requiredCols | Where-Object { $csvCols -notcontains $_ }
if ($missing) {
    Write-Host "  [ERROR] Colonnes manquantes dans le CSV : $($missing -join ', ')" -ForegroundColor Red
    exit 1
}

# Extraire les lignes validées (OUI exact uniquement)
$toProcess = $csvData | Where-Object { $_.Valider.Trim() -ceq "OUI" }
$skipped   = $csvData | Where-Object { $_.Valider.Trim() -cne "OUI" }

Write-Host "  Total lignes CSV         : $($csvData.Count)"
Write-Host "  Lignes à traiter (OUI)   : $($toProcess.Count)" -ForegroundColor $(if ($toProcess.Count -gt 0) { "Yellow" } else { "Gray" })
Write-Host "  Lignes ignorées          : $($skipped.Count)"
Write-Host ""

if ($toProcess.Count -eq 0) {
    Write-Host "  Aucune ligne validée (OUI). Aucune action effectuée." -ForegroundColor Gray
    exit 0
}

# ---------------------------------------------------------------------------
# Vérification des validateurs (intégrité minimale)
# ---------------------------------------------------------------------------

$missingValidator = $toProcess | Where-Object { [string]::IsNullOrWhiteSpace($_.ValidatedBy) }
if ($missingValidator) {
    Write-Host "  [WARN] $($missingValidator.Count) ligne(s) validée(s) sans ValidatedBy." -ForegroundColor Yellow
    Write-Host "         Ces lignes seront traitées mais l'anomalie est loggée." -ForegroundColor Yellow
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Module AD
# ---------------------------------------------------------------------------

$adAvailable = $false
if (-not $DryRun) {
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory
        $adAvailable = $true
    } else {
        Write-Host "  [ERROR] Module ActiveDirectory requis pour l'exécution réelle." -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Exécution
# ---------------------------------------------------------------------------

$executionLog  = [System.Collections.Generic.List[PSCustomObject]]::new()
$rollbackLog   = [System.Collections.Generic.List[PSCustomObject]]::new()

$stats = @{ Success = 0; AlreadyDisabled = 0; NotFound = 0; Error = 0; DryRun = 0 }

foreach ($row in $toProcess) {
    $sam    = $row.sAMAccountName.Trim()
    $by     = $row.ValidatedBy
    $date   = $row.ValidationDate
    $reason = if ($row.PSObject.Properties['StaleReason']) { $row.StaleReason } else { "N/A" }

    if ($DryRun) {
        Write-Host "  [DRYRUN] DISABLE + MOVE : $sam  ($($row.Department)) — Validé par $by" -ForegroundColor Yellow
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam
            Action         = "DISABLE+MOVE"
            Status         = "DRYRUN"
            StaleReason    = $reason
            ValidatedBy    = $by
            ValidationDate = $date
            Timestamp      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Detail         = "Simulation — aucune écriture AD"
        })
        $stats.DryRun++
        continue
    }

    # Mode réel
    try {
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$sam'" -SearchBase $SearchBase `
            -Properties Enabled, Description, DistinguishedName -ErrorAction Stop

        if (-not $adUser) {
            Write-Host "  [WARN] Compte introuvable : $sam" -ForegroundColor Yellow
            $executionLog.Add([PSCustomObject]@{
                sAMAccountName = $sam; Action = "DISABLE"; Status = "NOT_FOUND"
                StaleReason = $reason; ValidatedBy = $by; ValidationDate = $date
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Compte AD non trouvé"
            })
            $stats.NotFound++
            continue
        }

        # Sauvegarder l'état avant modification (rollback)
        $rollbackLog.Add([PSCustomObject]@{
            sAMAccountName       = $sam
            PreviousEnabled      = $adUser.Enabled
            PreviousDescription  = $adUser.Description
            PreviousOU           = $adUser.DistinguishedName
            RollbackCommand      = "Enable-ADAccount -Identity '$sam'; Set-ADUser -Identity '$sam' -Description '$($adUser.Description)'"
            Timestamp            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })

        if (-not $adUser.Enabled) {
            Write-Host "  [SKIP] Déjà désactivé : $sam" -ForegroundColor Gray
            $executionLog.Add([PSCustomObject]@{
                sAMAccountName = $sam; Action = "DISABLE"; Status = "ALREADY_DISABLED"
                StaleReason = $reason; ValidatedBy = $by; ValidationDate = $date
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Compte déjà désactivé"
            })
            $stats.AlreadyDisabled++
            continue
        }

        # 1. Désactiver
        Disable-ADAccount -Identity $sam

        # 2. Mettre à jour la description
        $newDesc = "DESACTIVE_$(Get-Date -Format 'yyyy-MM-dd') | $reason | Val: $by"
        Set-ADUser -Identity $sam -Description $newDesc

        # 3. Déplacer vers OU Archived
        Move-ADObject -Identity $adUser.DistinguishedName -TargetPath $TargetOU

        Write-Host "  [OK] DESACTIVE + ARCHIVE : $sam" -ForegroundColor Green
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; Action = "DISABLE+MOVE"; Status = "SUCCESS"
            StaleReason = $reason; ValidatedBy = $by; ValidationDate = $date
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Désactivé + déplacé vers $TargetOU"
        })
        $stats.Success++

    } catch {
        Write-Host "  [ERROR] $sam : $($_.Exception.Message)" -ForegroundColor Red
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; Action = "DISABLE"; Status = "ERROR"
            StaleReason = $reason; ValidatedBy = $by; ValidationDate = $date
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $_.Exception.Message
        })
        $stats.Error++
    }
}

# ---------------------------------------------------------------------------
# Export logs
# ---------------------------------------------------------------------------

$executionLog | Export-Csv -Path $ExecutionLog -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host ""
Write-Host "  [OK] Log d'exécution : $ExecutionLog" -ForegroundColor Gray

if (-not $DryRun -and $rollbackLog.Count -gt 0) {
    $rollbackLog | Export-Csv -Path $RollbackFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host "  [OK] Fichier rollback : $RollbackFile" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Synthèse
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  Simulés (DryRun)      : $($stats.DryRun)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Pour exécuter : .\Remediate-StaleAccounts.ps1 -CsvPath '$CsvPath' -DryRun:`$false" -ForegroundColor Yellow
} else {
    Write-Host "  Désactivés + archivés : $($stats.Success)" -ForegroundColor Green
    Write-Host "  Déjà désactivés       : $($stats.AlreadyDisabled)" -ForegroundColor Gray
    Write-Host "  Introuvables          : $($stats.NotFound)" -ForegroundColor Yellow
    Write-Host "  Erreurs               : $($stats.Error)" -ForegroundColor $(if ($stats.Error -gt 0) { "Red" } else { "Gray" })

    if ($stats.Error -gt 0) {
        Write-Host ""
        Write-Host "  [WARN] Des erreurs ont été rencontrées. Consulter : $ExecutionLog" -ForegroundColor Yellow
    }
    if ($rollbackLog.Count -gt 0) {
        Write-Host ""
        Write-Host "  Rollback disponible : $RollbackFile" -ForegroundColor Gray
        Write-Host "  Commande rollback   : Enable-ADAccount -Identity <sam>" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "  Étape suivante : .\Remediate-PrivilegedReview.ps1" -ForegroundColor Cyan
Write-Host ""
