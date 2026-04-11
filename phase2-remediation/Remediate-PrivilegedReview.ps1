<#
.SYNOPSIS
    Remediate-PrivilegedReview.ps1
    Révision et remédiation des droits d'administration non documentés CorpB.

.DESCRIPTION
    Traite les comptes identifiés par Audit-PrivilegedAccounts.ps1 selon
    l'action validée dans le CSV :

      DOCUMENTER     → Met à jour la description du compte AD
      REVOQUER_ADMIN → Retire le compte du groupe privilégié validé
      DESACTIVER     → Désactive le compte (cumul avec REVOQUER si applicable)

    Seules les lignes avec Valider = "OUI" exact sont traitées.
    DryRun par défaut.

.PARAMETER CsvPath
    CSV de validation produit par Audit-PrivilegedAccounts.ps1 + complété manager

.PARAMETER DryRun
    Simulation sans écriture AD (défaut : $true)

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    .\Remediate-PrivilegedReview.ps1 -CsvPath ".\validation-csv\privileged-validated.csv" -DryRun

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.8.2 | NIS2 Art.21§2(a)
    ATTENTION : La révocation de droits admin est irréversible à chaud.
    Toujours exécuter en DryRun et relire avant -DryRun:$false.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [string]$OutputPath = "..\reports\"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$ExecutionLog = Join-Path $OutputPath "phase2-privileged-execution_$Timestamp.csv"
$RollbackFile = Join-Path $OutputPath "phase2-privileged-rollback_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  Remediate-PrivilegedReview.ps1" -ForegroundColor White
Write-Host "  Mode : $(if ($DryRun) { 'DRYRUN' } else { 'EXECUTION REELLE' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  AVERTISSEMENT : révocation de droits admin — vérifier le DryRun" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host ""

if (-not (Test-Path $CsvPath)) {
    Write-Host "  [ERROR] CSV introuvable : $CsvPath" -ForegroundColor Red; exit 1
}

$csvData   = Import-Csv -Path $CsvPath -Delimiter ";" -Encoding UTF8
$toProcess = $csvData | Where-Object { $_.Valider.Trim() -ceq "OUI" }

Write-Host "  Total lignes CSV        : $($csvData.Count)"
Write-Host "  Lignes à traiter (OUI)  : $($toProcess.Count)"
Write-Host ""

if ($toProcess.Count -eq 0) {
    Write-Host "  Aucune ligne validée. Aucune action effectuée." -ForegroundColor Gray; exit 0
}

if (-not $DryRun) {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "  [ERROR] Module ActiveDirectory requis." -ForegroundColor Red; exit 1
    }
    Import-Module ActiveDirectory
}

$executionLog = [System.Collections.Generic.List[PSCustomObject]]::new()
$rollbackLog  = [System.Collections.Generic.List[PSCustomObject]]::new()
$stats        = @{ Documented = 0; Revoked = 0; Disabled = 0; Errors = 0; DryRun = 0 }

foreach ($row in $toProcess) {
    $sam    = $row.sAMAccountName.Trim()
    $action = if ($row.PSObject.Properties['RecommendedAction']) { $row.RecommendedAction.Trim() } else { "REVUE_MANUELLE" }
    $groups = if ($row.PSObject.Properties['PrivilegedGroups']) { $row.PrivilegedGroups } else { "" }
    $by     = $row.ValidatedBy
    $notes  = if ($row.PSObject.Properties['Notes']) { $row.Notes } else { "" }

    if ($DryRun) {
        Write-Host "  [DRYRUN] $action : $sam  (Groupes : $groups)" -ForegroundColor Yellow
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; Action = $action; Status = "DRYRUN"
            PrivilegedGroups = $groups; ValidatedBy = $by
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Simulation"
        })
        $stats.DryRun++
        continue
    }

    try {
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$sam'" `
            -Properties Description, Enabled, MemberOf -ErrorAction Stop

        if (-not $adUser) {
            Write-Host "  [WARN] Introuvable : $sam" -ForegroundColor Yellow
            $executionLog.Add([PSCustomObject]@{
                sAMAccountName = $sam; Action = $action; Status = "NOT_FOUND"
                PrivilegedGroups = $groups; ValidatedBy = $by
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Compte AD non trouvé"
            })
            continue
        }

        # Rollback state
        $currentGroups = $adUser.MemberOf | ForEach-Object {
            try { (Get-ADGroup $_).Name } catch { $_ }
        }
        $rollbackLog.Add([PSCustomObject]@{
            sAMAccountName   = $sam
            PreviousEnabled  = $adUser.Enabled
            PreviousDesc     = $adUser.Description
            PreviousGroups   = ($currentGroups -join " | ")
            Timestamp        = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })

        $actionsDone = @()

        # Action DOCUMENTER : mise à jour description
        if ($action -in @("DOCUMENTER_PUIS_REVUE","VALIDER_MAINTIEN") -or $notes) {
            $newDesc = if ($notes) { $notes } else { "COMPTE_ADMIN_VALIDE_$(Get-Date -Format 'yyyy-MM-dd') — Val: $by" }
            Set-ADUser -Identity $sam -Description $newDesc
            $actionsDone += "DOCUMENTER"
            $stats.Documented++
        }

        # Action REVOQUER : retrait du groupe privilégié
        if ($action -in @("REVUE_MANUELLE_RSSI","DOCUMENTER_PUIS_REVUE") -and $groups) {
            foreach ($grpName in ($groups -split "\|" | ForEach-Object { $_.Trim() })) {
                if ($grpName) {
                    try {
                        Remove-ADGroupMember -Identity $grpName -Members $sam -Confirm:$false
                        $actionsDone += "RETRAIT_$grpName"
                    } catch {
                        Write-Host "  [WARN] Retrait groupe $grpName impossible : $_" -ForegroundColor Yellow
                    }
                }
            }
            $stats.Revoked++
        }

        # Action DESACTIVER
        if ($action -eq "DESACTIVER" -or ($action -eq "REVUE_MANUELLE_RSSI" -and $row.IsStale -eq "OUI")) {
            Disable-ADAccount -Identity $sam
            $actionsDone += "DESACTIVER"
            $stats.Disabled++
        }

        $detail = $actionsDone -join " + "
        Write-Host "  [OK] $sam : $detail" -ForegroundColor Green
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; Action = $detail; Status = "SUCCESS"
            PrivilegedGroups = $groups; ValidatedBy = $by
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $detail
        })

    } catch {
        Write-Host "  [ERROR] $sam : $($_.Exception.Message)" -ForegroundColor Red
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; Action = $action; Status = "ERROR"
            PrivilegedGroups = $groups; ValidatedBy = $by
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $_.Exception.Message
        })
        $stats.Errors++
    }
}

$executionLog | Export-Csv -Path $ExecutionLog -NoTypeInformation -Encoding UTF8 -Delimiter ";"
if (-not $DryRun -and $rollbackLog.Count -gt 0) {
    $rollbackLog | Export-Csv -Path $RollbackFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
}

Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Simulés (DryRun)        : $($stats.DryRun)" -ForegroundColor Yellow
} else {
    Write-Host "  Documentés              : $($stats.Documented)" -ForegroundColor Green
    Write-Host "  Droits révoqués         : $($stats.Revoked)" -ForegroundColor Green
    Write-Host "  Désactivés              : $($stats.Disabled)" -ForegroundColor Green
    Write-Host "  Erreurs                 : $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
}
Write-Host ""
Write-Host "  Étape suivante : .\Remediate-GroupCleanup.ps1" -ForegroundColor Cyan
Write-Host ""
