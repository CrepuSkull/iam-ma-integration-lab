<#
.SYNOPSIS
    Audit-PrivilegedAccounts.ps1
    Audit des comptes à droits étendus dans l'AD CorpB.

.DESCRIPTION
    Cartographie tous les comptes disposant de droits d'administration ou
    d'appartenance à des groupes sensibles. Détecte les cas non documentés
    (compte privilégié sans description = risque non tracé).

    Produit un CSV de revue pour le RSSI CorpA et un CSV de validation Phase 2.

    Mode : LECTURE SEULE.

.EXAMPLE
    .\Audit-PrivilegedAccounts.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.8.2 | NIS2 Art.21§2(a)
    Référence croisée : iam-foundation-lab / Audit-PrivilegedAccounts.ps1 (adapté M&A)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SearchBase = "OU=CorpB-Lab,DC=lab,DC=local",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$SimulationCsvPath = "..\seed\corpb-users.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase1-privileged_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$PrivilegedGroups = @(
    "Domain Admins", "Enterprise Admins", "Schema Admins",
    "Administrators", "Account Operators", "Backup Operators",
    "GRP_Domain_Admins_Local", "GRP_Tech_DevOps"
)

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-PrivilegedAccounts.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan

$results = @()

if ($Simulation) {
    $users = Import-Csv -Path $SimulationCsvPath -Delimiter ";" -Encoding UTF8

    foreach ($u in $users) {
        $memberOf = $u.MemberOf -split "\|" | ForEach-Object { $_.Trim() }
        $matchedGroups = $memberOf | Where-Object { $PrivilegedGroups -contains $_ }
        $isPrivFlag = $u.IsPrivileged -eq "TRUE"

        if ($matchedGroups -or $isPrivFlag) {
            $isDocumented  = -not [string]::IsNullOrWhiteSpace($u.Description)
            $isStale       = $u.IsStale -eq "TRUE"
            $isSvc         = $u.IsServiceAccount -eq "TRUE"

            # Niveau de risque privilège
            $privRisk = "MODERE"
            if (-not $isDocumented) { $privRisk = "CRITIQUE" }
            elseif ($isStale)       { $privRisk = "ELEVE" }
            elseif ($isSvc)         { $privRisk = "ELEVE" }

            $results += [PSCustomObject]@{
                sAMAccountName       = $u.sAMAccountName
                DisplayName          = $u.DisplayName
                Department           = $u.Department
                Domain               = $u.Domain
                Enabled              = $u.Enabled
                Title                = $u.Title
                PrivilegedGroups     = ($matchedGroups -join " | ")
                IsDocumented         = if ($isDocumented) { "OUI" } else { "NON — RISQUE" }
                Description          = $u.Description
                IsStale              = $u.IsStale
                IsServiceAccount     = $u.IsServiceAccount
                LastLogonDate        = $u.LastLogonDate
                PasswordLastSet      = $u.PasswordLastSet
                PasswordNeverExpires = $u.PasswordNeverExpires
                PrivilegeRiskLevel   = $privRisk
                RecommendedAction    = switch ($privRisk) {
                    "CRITIQUE" { "DOCUMENTER_PUIS_REVUE" }
                    "ELEVE"    { "REVUE_MANUELLE_RSSI" }
                    default    { "VALIDER_MAINTIEN" }
                }
                Valider              = ""
                ValidatedBy          = ""
                Notes                = ""
            }
        }
    }
} else {
    Import-Module ActiveDirectory
    $adUsers = Get-ADUser -SearchBase $SearchBase -Filter * -Properties `
        DisplayName, Department, Title, Enabled, LastLogonDate,
        PasswordLastSet, PasswordNeverExpires, Description, MemberOf

    foreach ($u in $adUsers) {
        $groupNames = @()
        foreach ($grpDN in $u.MemberOf) {
            try { $groupNames += (Get-ADGroup $grpDN).Name } catch {}
        }

        $matchedGroups = $groupNames | Where-Object { $PrivilegedGroups -contains $_ }

        if ($matchedGroups) {
            $isDocumented = -not [string]::IsNullOrWhiteSpace($u.Description)
            $lastLogon    = $u.LastLogonDate
            $isStale      = $lastLogon -and $lastLogon -lt (Get-Date).AddDays(-90)

            $privRisk = "MODERE"
            if (-not $isDocumented)    { $privRisk = "CRITIQUE" }
            elseif ($isStale)          { $privRisk = "ELEVE" }
            elseif ($u.SamAccountName -match "^svc_") { $privRisk = "ELEVE" }

            $results += [PSCustomObject]@{
                sAMAccountName       = $u.SamAccountName
                DisplayName          = $u.DisplayName
                Department           = $u.Department
                Domain               = ($u.DistinguishedName -replace ".*DC=(\w+),DC=(\w+).*",'$1.$2')
                Enabled              = $u.Enabled
                Title                = $u.Title
                PrivilegedGroups     = ($matchedGroups -join " | ")
                IsDocumented         = if ($isDocumented) { "OUI" } else { "NON — RISQUE" }
                Description          = $u.Description
                IsStale              = if ($isStale) { "TRUE" } else { "FALSE" }
                IsServiceAccount     = if ($u.SamAccountName -match "^svc_") { "TRUE" } else { "FALSE" }
                LastLogonDate        = if ($lastLogon) { $lastLogon.ToString("yyyy-MM-dd") } else { "" }
                PasswordLastSet      = if ($u.PasswordLastSet) { $u.PasswordLastSet.ToString("yyyy-MM-dd") } else { "" }
                PasswordNeverExpires = $u.PasswordNeverExpires
                PrivilegeRiskLevel   = $privRisk
                RecommendedAction    = switch ($privRisk) {
                    "CRITIQUE" { "DOCUMENTER_PUIS_REVUE" }
                    "ELEVE"    { "REVUE_MANUELLE_RSSI" }
                    default    { "VALIDER_MAINTIEN" }
                }
                Valider              = ""
                ValidatedBy          = ""
                Notes                = ""
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$critique = ($results | Where-Object { $_.PrivilegeRiskLevel -eq "CRITIQUE" }).Count
$eleve    = ($results | Where-Object { $_.PrivilegeRiskLevel -eq "ELEVE" }).Count
$nonDoc   = ($results | Where-Object { $_.IsDocumented -like "*NON*" }).Count

Write-Host "  [OK] $($results.Count) compte(s) privilégié(s) détecté(s) → $OutputFile"
Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  CRITIQUE (non documenté)  : $critique  ← Traitement prioritaire"
Write-Host "  ÉLEVÉ (stale ou service)  : $eleve"
Write-Host "  Non documentés total      : $nonDoc"
Write-Host ""
if ($critique -gt 0) {
    Write-Host "  [ALERTE] $critique compte(s) privilégié(s) sans description." -ForegroundColor Red
    Write-Host "           Documenter ou révoquer avant migration (Phase 3)." -ForegroundColor Red
}
Write-Host ""
Write-Host "  Étape suivante : .\Audit-GroupMembership.ps1" -ForegroundColor Cyan
Write-Host ""
