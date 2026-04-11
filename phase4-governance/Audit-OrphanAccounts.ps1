<#
.SYNOPSIS
    Audit-OrphanAccounts.ps1
    Détection des comptes orphelins dans Entra ID CorpA post-migration CorpB.

.DESCRIPTION
    Identifie les comptes CorpB migrés qui présentent des signaux d'orphelin
    post-fusion selon quatre critères :

      SANS_CONNEXION    : compte actif mais aucune connexion depuis J-Day
      SANS_DEPARTEMENT  : compte sans attribut Department dans Entra ID
      SANS_MANAGER      : compte sans manager assigné (hors Direction)
      HORS_GROUPE       : compte non membre d'un groupe de migration CorpB

    Mode : LECTURE SEULE.

.PARAMETER TargetDomain
    Domaine tenant Entra ID cible

.PARAMETER MigrationDate
    Date de J-Day (pour calcul de l'inactivité post-migration)

.PARAMETER Simulation
    Mode simulation — évalue sur la base du dataset seed

.PARAMETER SourceCsvPath
    Chemin vers corpb-users.csv (mode simulation)

.PARAMETER OutputPath
    Répertoire de sortie

.PARAMETER InactiveDaysPostMigration
    Nombre de jours sans connexion post J-Day pour qualifier l'orphelin (défaut: 7)

.EXAMPLE
    .\Audit-OrphanAccounts.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15 | NIS2 Art.21§2(e) | RGPD Art.5(1)(c)(e)
    Référence croisée : iam-foundation-lab / Audit-OrphanAccounts.ps1 (adapté post-migration)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [string]$MigrationDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd"),

    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$SourceCsvPath = "..\seed\corpb-users.csv",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [int]$InactiveDaysPostMigration = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase4-orphans_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-OrphanAccounts.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  Mode : $(if ($Simulation) { 'SIMULATION' } else { 'LIVE Graph' })" -ForegroundColor Gray
Write-Host "  J-Day référence : $MigrationDate" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$migrationDt = [datetime]::ParseExact($MigrationDate, "yyyy-MM-dd", $null)
$inactiveThreshold = $migrationDt.AddDays($InactiveDaysPostMigration)

if ($Simulation) {
    $sourceUsers = Import-Csv -Path $SourceCsvPath -Delimiter ";" -Encoding UTF8
    $migrated    = $sourceUsers | Where-Object {
        $_.Enabled -eq "TRUE" -and $_.IsServiceAccount -eq "FALSE" -and $_.IsStale -eq "FALSE"
    }

    $orphanGroups = @("Direction","Commercial","Technique","RH","Prestataires","ServiceCompt")
    $random       = [System.Random]::new(42)

    foreach ($u in $migrated) {
        $upn = "$($u.sAMAccountName.Trim().ToLower())@$TargetDomain"

        # Simuler différents signaux d'orphelin (~15% des comptes)
        $uid     = [int]($u.UID -replace "CB","")
        $noLogin = ($uid % 7  -eq 0)   # ~14% sans connexion post J-Day
        $noDept  = ($uid % 25 -eq 0)   # ~4% sans département
        $noMgr   = ($uid % 15 -eq 0) -and ($u.Department -ne "Direction")
        $noGroup = ($uid % 40 -eq 0)   # ~2.5% hors groupe

        $orphanSignals = @()
        if ($noLogin) { $orphanSignals += "SANS_CONNEXION" }
        if ($noDept)  { $orphanSignals += "SANS_DEPARTEMENT" }
        if ($noMgr)   { $orphanSignals += "SANS_MANAGER" }
        if ($noGroup) { $orphanSignals += "HORS_GROUPE" }

        if ($orphanSignals.Count -eq 0) { continue }

        $signalCount = $orphanSignals.Count
        $riskLevel   = if ($signalCount -ge 3)    { "CRITIQUE" }
                       elseif ($signalCount -eq 2) { "ELEVE" }
                       else                        { "MODERE" }

        $simulatedLastLogin = if ($noLogin) { "" } else {
            $migrationDt.AddDays($random.Next(1, $InactiveDaysPostMigration)).ToString("yyyy-MM-dd")
        }

        $results.Add([PSCustomObject]@{
            UPN                    = $upn
            DisplayName            = $u.DisplayName
            Department             = $u.Department
            Domain_Source          = $u.Domain
            AccountEnabled         = "TRUE"
            LastSignInDateTime     = $simulatedLastLogin
            DaysSinceMigration_NoLogin = if ($noLogin) { $InactiveDaysPostMigration } else { 0 }
            OrphanSignals          = ($orphanSignals -join " | ")
            SignalCount            = $signalCount
            RiskLevel              = $riskLevel
            RecommendedAction      = switch ($riskLevel) {
                "CRITIQUE" { "REVUE_MANUELLE_RSSI_URGENT" }
                "ELEVE"    { "CONTACTER_MANAGER_CORPA" }
                default    { "SURVEILLER_J+14" }
            }
            AuditSource            = "SIMULATION"
            AuditDate              = (Get-Date -Format "yyyy-MM-dd")
        })
    }
} else {
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Reports
    Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -ErrorAction Stop

    $cutoffDate = $inactiveThreshold.ToString("yyyy-MM-ddTHH:mm:ssZ")

    $mgUsers = Get-MgUser -Filter "endswith(UserPrincipalName,'@$TargetDomain') and accountEnabled eq true" `
        -Property UserPrincipalName,DisplayName,Department,JobTitle,Manager,MemberOf,SignInActivity -All

    foreach ($u in $mgUsers) {
        $orphanSignals = @()

        $lastSignIn = $u.SignInActivity?.LastSignInDateTime
        if (-not $lastSignIn -or [datetime]$lastSignIn -lt $inactiveThreshold) {
            $orphanSignals += "SANS_CONNEXION"
        }
        if ([string]::IsNullOrWhiteSpace($u.Department)) {
            $orphanSignals += "SANS_DEPARTEMENT"
        }
        if (-not $u.Manager -and $u.JobTitle -notmatch "Directeur|Director|DG") {
            $orphanSignals += "SANS_MANAGER"
        }

        $memberGroups = $u.MemberOf | ForEach-Object { $_.DisplayName }
        $inMigGroup   = $memberGroups | Where-Object { $_ -match "CorpB.*Migrated" }
        if (-not $inMigGroup) { $orphanSignals += "HORS_GROUPE" }

        if ($orphanSignals.Count -eq 0) { continue }

        $signalCount = $orphanSignals.Count
        $riskLevel   = if ($signalCount -ge 3) { "CRITIQUE" } elseif ($signalCount -eq 2) { "ELEVE" } else { "MODERE" }
        $daysSince   = if ($lastSignIn) { [int](((Get-Date) - [datetime]$lastSignIn).TotalDays) } else { 9999 }

        $results.Add([PSCustomObject]@{
            UPN                        = $u.UserPrincipalName
            DisplayName                = $u.DisplayName
            Department                 = $u.Department
            Domain_Source              = "CorpB (migré)"
            AccountEnabled             = $true
            LastSignInDateTime         = if ($lastSignIn) { ([datetime]$lastSignIn).ToString("yyyy-MM-dd") } else { "" }
            DaysSinceMigration_NoLogin = $daysSince
            OrphanSignals              = ($orphanSignals -join " | ")
            SignalCount                = $signalCount
            RiskLevel                  = $riskLevel
            RecommendedAction          = switch ($riskLevel) {
                "CRITIQUE" { "REVUE_MANUELLE_RSSI_URGENT" }
                "ELEVE"    { "CONTACTER_MANAGER_CORPA" }
                default    { "SURVEILLER_J+14" }
            }
            AuditSource                = "GRAPH_LIVE"
            AuditDate                  = (Get-Date -Format "yyyy-MM-dd")
        })
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$critique = ($results | Where-Object { $_.RiskLevel -eq "CRITIQUE" }).Count
$eleve    = ($results | Where-Object { $_.RiskLevel -eq "ELEVE" }).Count
$modere   = ($results | Where-Object { $_.RiskLevel -eq "MODERE" }).Count

Write-Host "  [OK] $($results.Count) compte(s) orphelin(s) détecté(s) → $OutputFile"
Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  CRITIQUE (multi-signaux)  : $critique  ← Revue RSSI prioritaire"
Write-Host "  ÉLEVÉ    (2 signaux)      : $eleve"
Write-Host "  MODÉRÉ   (1 signal)       : $modere"
Write-Host ""

$signalBreakdown = $results | ForEach-Object { $_.OrphanSignals -split " \| " } |
    Group-Object | Sort-Object Count -Descending
Write-Host "  Signaux les plus fréquents :"
foreach ($s in $signalBreakdown) {
    Write-Host "    $($s.Name.PadRight(25)) : $($s.Count)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  Étape suivante : .\Audit-RBACConflicts.ps1" -ForegroundColor Cyan
Write-Host ""
