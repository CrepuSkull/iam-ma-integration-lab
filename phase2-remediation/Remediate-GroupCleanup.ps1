<#
.SYNOPSIS
    Remediate-GroupCleanup.ps1
    Nettoyage des groupes de sécurité orphelins AD CorpB.

.DESCRIPTION
    Traite les groupes identifiés par Audit-GroupMembership.ps1 selon
    l'action validée dans le CSV :

      DOCUMENTER      → Ajoute une description au groupe (propriétaire identifié)
      VIDER           → Retire tous les membres du groupe orphelin
      SUPPRIMER       → Supprime le groupe (uniquement si vide ou explicitement validé)

    Seules les lignes avec Valider = "OUI" exact sont traitées.
    DryRun par défaut.

    GARDE-FOU suppression : un groupe ne peut être supprimé que si :
      - Il est vide OU
      - La colonne RecommendedAction contient explicitement SUPPRIMER

.PARAMETER CsvPath
    CSV de validation produit par Audit-GroupMembership.ps1 + complété

.PARAMETER DryRun
    Simulation sans écriture AD (défaut : $true)

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    .\Remediate-GroupCleanup.ps1 -CsvPath ".\validation-csv\groups-validated.csv" -DryRun

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15 | NIS2 Art.21§2(i)
    La suppression de groupe est irréversible. Toujours exécuter en DryRun d'abord.
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
$ExecutionLog = Join-Path $OutputPath "phase2-groups-execution_$Timestamp.csv"
$RollbackFile = Join-Path $OutputPath "phase2-groups-rollback_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  Remediate-GroupCleanup.ps1" -ForegroundColor White
Write-Host "  Mode : $(if ($DryRun) { 'DRYRUN' } else { 'EXECUTION REELLE' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "  AVERTISSEMENT : la suppression de groupe est irréversible" -ForegroundColor Yellow
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
$stats        = @{ Documented = 0; Emptied = 0; Deleted = 0; Errors = 0; Skipped = 0; DryRun = 0 }

foreach ($row in $toProcess) {
    $grpName  = $row.GroupName.Trim()
    $action   = if ($row.PSObject.Properties['RecommendedAction']) { $row.RecommendedAction.Trim() } else { "DOCUMENTER" }
    $by       = $row.ValidatedBy
    $notes    = if ($row.PSObject.Properties['Notes']) { $row.Notes } else { "" }
    $members  = if ($row.PSObject.Properties['Members']) { $row.Members } else { "" }
    $isEmpty  = ($row.PSObject.Properties['IsEmpty'] -and $row.IsEmpty -eq "OUI") -or [string]::IsNullOrWhiteSpace($members)

    if ($DryRun) {
        $deleteGuard = if ($action -eq "SUPPRIMER" -and -not $isEmpty) { " [GARDE-FOU : groupe non vide — suppression bloquée]" } else { "" }
        Write-Host "  [DRYRUN] $action : $grpName$deleteGuard" -ForegroundColor Yellow
        $executionLog.Add([PSCustomObject]@{
            GroupName = $grpName; Action = $action; Status = "DRYRUN"
            ValidatedBy = $by; Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Detail = "Simulation$deleteGuard"
        })
        $stats.DryRun++
        continue
    }

    try {
        $adGroup = Get-ADGroup -Filter "Name -eq '$grpName'" -Properties Description, Members -ErrorAction Stop

        if (-not $adGroup) {
            Write-Host "  [WARN] Groupe introuvable : $grpName" -ForegroundColor Yellow
            $executionLog.Add([PSCustomObject]@{
                GroupName = $grpName; Action = $action; Status = "NOT_FOUND"
                ValidatedBy = $by; Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Groupe non trouvé"
            })
            continue
        }

        $currentMembers = @($adGroup.Members)

        # Rollback state
        $rollbackLog.Add([PSCustomObject]@{
            GroupName          = $grpName
            PreviousDescription = $adGroup.Description
            PreviousMembers    = ($currentMembers -join " | ")
            RollbackHint       = "New-ADGroup ou Add-ADGroupMember si supprimé"
            Timestamp          = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })

        $actionsDone = @()

        # DOCUMENTER
        if ($action -in @("DOCUMENTER_OU_SUPPRIMER","DOCUMENTER_PROPRIETAIRE_URGENT","VALIDER_MAINTIEN")) {
            $newDesc = if ($notes) { $notes } else { "PROPRIETAIRE_VALIDE_$(Get-Date -Format 'yyyy-MM-dd') — Val: $by" }
            Set-ADGroup -Identity $grpName -Description $newDesc
            $actionsDone += "DOCUMENTER"
            $stats.Documented++
        }

        # VIDER
        if ($action -eq "VIDER" -and $currentMembers.Count -gt 0) {
            foreach ($member in $currentMembers) {
                try {
                    Remove-ADGroupMember -Identity $grpName -Members $member -Confirm:$false
                } catch {
                    Write-Host "  [WARN] Impossible de retirer $member de $grpName" -ForegroundColor Yellow
                }
            }
            $actionsDone += "VIDER"
            $stats.Emptied++
        }

        # SUPPRIMER — uniquement si groupe vide (garde-fou critique)
        if ($action -eq "SUPPRIMER") {
            $freshGroup = Get-ADGroup -Filter "Name -eq '$grpName'" -Properties Members
            if ($freshGroup -and @($freshGroup.Members).Count -eq 0) {
                Remove-ADGroup -Identity $grpName -Confirm:$false
                $actionsDone += "SUPPRIMER"
                $stats.Deleted++
            } else {
                Write-Host "  [GARDE-FOU] Suppression bloquée : $grpName contient encore des membres." -ForegroundColor Red
                Write-Host "              Vider le groupe d'abord, puis relancer." -ForegroundColor Red
                $actionsDone += "SUPPRESSION_BLOQUEE"
                $stats.Skipped++
            }
        }

        $detail = $actionsDone -join " + "
        Write-Host "  [OK] $grpName : $detail" -ForegroundColor Green
        $executionLog.Add([PSCustomObject]@{
            GroupName = $grpName; Action = $detail; Status = "SUCCESS"
            ValidatedBy = $by; Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $detail
        })

    } catch {
        Write-Host "  [ERROR] $grpName : $($_.Exception.Message)" -ForegroundColor Red
        $executionLog.Add([PSCustomObject]@{
            GroupName = $grpName; Action = $action; Status = "ERROR"
            ValidatedBy = $by; Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $_.Exception.Message
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
    Write-Host "  Simulés (DryRun)     : $($stats.DryRun)" -ForegroundColor Yellow
} else {
    Write-Host "  Documentés           : $($stats.Documented)" -ForegroundColor Green
    Write-Host "  Groupes vidés        : $($stats.Emptied)" -ForegroundColor Green
    Write-Host "  Groupes supprimés    : $($stats.Deleted)" -ForegroundColor Green
    Write-Host "  Bloqués (garde-fou)  : $($stats.Skipped)" -ForegroundColor Yellow
    Write-Host "  Erreurs              : $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
}
Write-Host ""
Write-Host "  Phase 2 terminée." -ForegroundColor Green
Write-Host "  Étape suivante : ..\phase3-migration\README-phase3.md" -ForegroundColor Cyan
Write-Host ""
