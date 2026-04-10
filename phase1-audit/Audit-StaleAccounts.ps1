<#
.SYNOPSIS
    Audit-StaleAccounts.ps1
    Détection et qualification des comptes obsolètes AD CorpB.

.DESCRIPTION
    Identifie les comptes à risque selon trois critères combinables :
      - Inactivité (dernière connexion > N jours)
      - Mot de passe non changé depuis > N jours
      - Compte actif dans l'OU Archived (départs non traités)

    Produit un CSV prêt pour la Phase 2 (Remediate-StaleAccounts.ps1),
    avec colonne Valider vide — à remplir par les managers validateurs.

    Mode : LECTURE SEULE.

.PARAMETER SearchBase
    OU racine de recherche

.PARAMETER InactiveDays
    Seuil d'inactivité en jours (défaut : 90)

.PARAMETER PwdAgeDays
    Seuil d'ancienneté du mot de passe en jours (défaut : 365)

.PARAMETER OutputPath
    Répertoire de sortie

.PARAMETER Simulation
    Mode simulation — lecture CSV seed

.PARAMETER SimulationCsvPath
    Chemin vers corpb-users.csv

.EXAMPLE
    .\Audit-StaleAccounts.ps1 -Simulation -InactiveDays 90 -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.8.5 | NIS2 Art.21§2(e) | RGPD Art.5(1)(e)
    Référence croisée : iam-foundation-lab / Audit-StaleAccounts.ps1 (adapté M&A)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SearchBase = "OU=CorpB-Lab,DC=lab,DC=local",

    [Parameter()]
    [int]$InactiveDays = 90,

    [Parameter()]
    [int]$PwdAgeDays = 365,

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$SimulationCsvPath = "..\seed\corpb-users.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile  = Join-Path $OutputPath "phase1-stale_$Timestamp.csv"
$ValidationFile = Join-Path $OutputPath "phase2-remediation-stale_TOVALIDATE_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-StaleAccounts.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  Seuil inactivité : $InactiveDays jours" -ForegroundColor Gray
Write-Host "  Seuil mot de passe : $PwdAgeDays jours" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Chargement et évaluation
# ---------------------------------------------------------------------------

$cutoffLogon  = (Get-Date).AddDays(-$InactiveDays)
$cutoffPwd    = (Get-Date).AddDays(-$PwdAgeDays)
$results      = @()

function Get-StaleReason {
    param($LastLogon, $PwdSet, $Enabled, $Department)
    $reasons = @()
    if ($LastLogon -ne [datetime]::MinValue -and $LastLogon -lt $cutoffLogon) {
        $reasons += "INACTIF_$($InactiveDays)J"
    }
    if ($PwdSet -ne [datetime]::MinValue -and $PwdSet -lt $cutoffPwd) {
        $reasons += "MDP_ANCIEN_$($PwdAgeDays)J"
    }
    if ($Department -eq "Archived" -and $Enabled -eq "TRUE") {
        $reasons += "OU_ARCHIVED_ACTIF"
    }
    return ($reasons -join " | ")
}

if ($Simulation) {
    if (-not (Test-Path $SimulationCsvPath)) {
        Write-Host "  [ERROR] CSV introuvable : $SimulationCsvPath" -ForegroundColor Red; exit 1
    }
    $users = Import-Csv -Path $SimulationCsvPath -Delimiter ";" -Encoding UTF8

    foreach ($u in $users) {
        $lastLogon = if ($u.LastLogonDate) { [datetime]::ParseExact($u.LastLogonDate,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }
        $pwdSet    = if ($u.PasswordLastSet) { [datetime]::ParseExact($u.PasswordLastSet,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }
        $enabled   = $u.Enabled -eq "TRUE"

        $reason = Get-StaleReason -LastLogon $lastLogon -PwdSet $pwdSet -Enabled $u.Enabled -Department $u.Department

        if ($reason -or $u.IsStale -eq "TRUE") {
            $daysSince = if ($lastLogon -ne [datetime]::MinValue) {
                [int](((Get-Date) - $lastLogon).TotalDays)
            } else { 9999 }

            $results += [PSCustomObject]@{
                sAMAccountName       = $u.sAMAccountName
                DisplayName          = $u.DisplayName
                Department           = $u.Department
                Domain               = $u.Domain
                Enabled              = $u.Enabled
                LastLogonDate        = $u.LastLogonDate
                DaysSinceLastLogon   = $daysSince
                PasswordLastSet      = $u.PasswordLastSet
                PasswordNeverExpires = $u.PasswordNeverExpires
                WhenCreated          = $u.WhenCreated
                StaleReason          = if ($reason) { $reason } else { "FLAG_SEED" }
                RecommendedAction    = if ($u.IsServiceAccount -eq "TRUE") { "REVUE_MANUELLE" } else { "DESACTIVER" }
                Valider              = ""   # ← À remplir par le manager (OUI = exécution Phase 2)
                ValidatedBy          = ""
                ValidationDate       = ""
                Notes                = ""
            }
        }
    }
} else {
    Import-Module ActiveDirectory
    $adUsers = Get-ADUser -SearchBase $SearchBase -Filter * -Properties `
        DisplayName, Department, Enabled, LastLogonDate,
        PasswordLastSet, PasswordNeverExpires, WhenCreated, Description

    foreach ($u in $adUsers) {
        $lastLogon = if ($u.LastLogonDate) { $u.LastLogonDate } else { [datetime]::MinValue }
        $pwdSet    = if ($u.PasswordLastSet) { $u.PasswordLastSet } else { [datetime]::MinValue }
        $dept      = $u.DistinguishedName -match "OU=Archived" ? "Archived" : $u.Department

        $reason = Get-StaleReason -LastLogon $lastLogon -PwdSet $pwdSet -Enabled $u.Enabled -Department $dept

        if ($reason) {
            $daysSince = if ($lastLogon -ne [datetime]::MinValue) {
                [int](((Get-Date) - $lastLogon).TotalDays)
            } else { 9999 }

            $results += [PSCustomObject]@{
                sAMAccountName       = $u.SamAccountName
                DisplayName          = $u.DisplayName
                Department           = $dept
                Domain               = ($u.DistinguishedName -replace ".*DC=(\w+),DC=(\w+).*",'$1.$2')
                Enabled              = $u.Enabled
                LastLogonDate        = if ($lastLogon -ne [datetime]::MinValue) { $lastLogon.ToString("yyyy-MM-dd") } else { "" }
                DaysSinceLastLogon   = $daysSince
                PasswordLastSet      = if ($pwdSet -ne [datetime]::MinValue) { $pwdSet.ToString("yyyy-MM-dd") } else { "" }
                PasswordNeverExpires = $u.PasswordNeverExpires
                WhenCreated          = if ($u.WhenCreated) { $u.WhenCreated.ToString("yyyy-MM-dd") } else { "" }
                StaleReason          = $reason
                RecommendedAction    = if ($u.SamAccountName -match "^svc_") { "REVUE_MANUELLE" } else { "DESACTIVER" }
                Valider              = ""
                ValidatedBy          = ""
                ValidationDate       = ""
                Notes                = ""
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "  [OK] Rapport audit : $OutputFile ($($results.Count) comptes)"

# CSV de validation pré-rempli pour la Phase 2
$results | Export-Csv -Path $ValidationFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "  [OK] CSV de validation Phase 2 : $ValidationFile" -ForegroundColor Yellow
Write-Host "       → Colonne [Valider] : inscrire OUI pour autoriser la désactivation" -ForegroundColor Yellow

# ---------------------------------------------------------------------------
# Synthèse
# ---------------------------------------------------------------------------

$toDisable = ($results | Where-Object { $_.RecommendedAction -eq "DESACTIVER" }).Count
$toReview  = ($results | Where-Object { $_.RecommendedAction -eq "REVUE_MANUELLE" }).Count
$archived  = ($results | Where-Object { $_.StaleReason -like "*OU_ARCHIVED*" }).Count

Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  Comptes obsolètes détectés    : $($results.Count)"
Write-Host "  → Désactivation recommandée   : $toDisable"
Write-Host "  → Revue manuelle requise      : $toReview  (comptes de service)"
Write-Host "  → OU Archived actifs          : $archived"
Write-Host ""
Write-Host "  Étape suivante : .\Audit-PrivilegedAccounts.ps1" -ForegroundColor Cyan
Write-Host ""
