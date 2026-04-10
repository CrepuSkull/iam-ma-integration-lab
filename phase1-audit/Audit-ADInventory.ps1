<#
.SYNOPSIS
    Audit-ADInventory.ps1
    Inventaire complet des comptes Active Directory CorpB — contexte M&A.

.DESCRIPTION
    Produit une photographie exhaustive de tous les comptes AD dans le périmètre
    CorpB : comptes actifs, inactifs, de service, privilégiés, avec leurs attributs
    clés pour préparer la Phase 2 (remédiation) et la Phase 3 (migration).

    Mode : LECTURE SEULE. Aucune modification AD.
    
    Deux modes d'exécution :
      - Mode AD réel    : connexion à un contrôleur de domaine
      - Mode simulation : lecture du fichier CSV seed (sans AD disponible)

.PARAMETER SearchBase
    OU racine de recherche (ex: "OU=CorpB-Lab,DC=lab,DC=local")

.PARAMETER OutputPath
    Répertoire de sortie pour les rapports CSV (créé si absent)

.PARAMETER SimulationCsvPath
    Chemin vers corpb-users.csv pour le mode simulation (sans AD)

.PARAMETER Simulation
    Active le mode simulation (lecture CSV au lieu d'une vraie requête AD)

.EXAMPLE
    # Mode AD réel
    .\Audit-ADInventory.ps1 -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" -OutputPath "..\reports\"

.EXAMPLE
    # Mode simulation (lab sans AD)
    .\Audit-ADInventory.ps1 -Simulation -SimulationCsvPath "..\seed\corpb-users.csv" -OutputPath "..\reports\"

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / phase1-audit
    Script de démonstration/test uniquement.
    Mapping réglementaire : ISO 27001:2022 A.5.15, A.8.5 | NIS2 Art.21§2(i) | RGPD Art.30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SearchBase = "OU=CorpB-Lab,DC=lab,DC=local",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [string]$SimulationCsvPath = "..\seed\corpb-users.csv",

    [Parameter()]
    [switch]$Simulation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

$ScriptName    = "Audit-ADInventory"
$Timestamp     = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile    = Join-Path $OutputPath "phase1-inventory_$Timestamp.csv"
$SummaryFile   = Join-Path $OutputPath "phase1-inventory-summary_$Timestamp.txt"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "── $Title ──" -ForegroundColor Cyan
}

function Write-Info  { param([string]$Msg) Write-Host "  [INFO]  $Msg" -ForegroundColor Gray }
function Write-Ok    { param([string]$Msg) Write-Host "  [OK]    $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "  [WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "  [ERROR] $Msg" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  IAM-Lab Framework — $ScriptName" -ForegroundColor Cyan
Write-Host "  Phase 1 — Audit AD CorpB — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Mode       : $(if ($Simulation) { 'SIMULATION (CSV)' } else { 'AD REEL' })" -ForegroundColor $(if ($Simulation) { 'Yellow' } else { 'Green' })
Write-Host "  SearchBase : $SearchBase" -ForegroundColor Gray
Write-Host "  Sortie     : $OutputFile" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Chargement des données
# ---------------------------------------------------------------------------

Write-Section "Chargement des données"

$allUsers = @()
$InactiveDaysThreshold = 90
$PrivilegedGroups = @("Domain Admins","Enterprise Admins","Schema Admins",
                       "GRP_Domain_Admins_Local","Administrators","Account Operators")

if ($Simulation) {
    # Mode simulation — lecture du CSV seed
    if (-not (Test-Path $SimulationCsvPath)) {
        Write-Err "Fichier CSV introuvable : $SimulationCsvPath"
        Write-Err "Exécuter generate-corpb-users.py d'abord."
        exit 1
    }

    $seedData = Import-Csv -Path $SimulationCsvPath -Delimiter ";" -Encoding UTF8
    Write-Ok "$($seedData.Count) comptes chargés depuis $SimulationCsvPath"

    $cutoffDate = (Get-Date).AddDays(-$InactiveDaysThreshold)

    foreach ($u in $seedData) {
        $lastLogon = if ($u.LastLogonDate) { [datetime]::ParseExact($u.LastLogonDate,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }
        $pwdSet    = if ($u.PasswordLastSet) { [datetime]::ParseExact($u.PasswordLastSet,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }
        $created   = if ($u.WhenCreated) { [datetime]::ParseExact($u.WhenCreated,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }

        $daysSinceLogon = if ($lastLogon -ne [datetime]::MinValue) {
            [int](((Get-Date) - $lastLogon).TotalDays)
        } else { 9999 }

        $isPrivileged = ($u.MemberOf -match ($PrivilegedGroups -join "|")) -or ($u.IsPrivileged -eq "TRUE")
        $isStale = ($u.IsStale -eq "TRUE") -or ($lastLogon -lt $cutoffDate -and $u.Enabled -eq "TRUE")
        $isSvc   = $u.IsServiceAccount -eq "TRUE"

        # Score de risque composite (0–100)
        $riskScore = 0
        if ($isStale)                              { $riskScore += 30 }
        if ($isPrivileged)                         { $riskScore += 25 }
        if ($u.PasswordNeverExpires -eq "TRUE")    { $riskScore += 15 }
        if (-not $u.Description)                   { $riskScore += 10 }
        if ($daysSinceLogon -gt 365)               { $riskScore += 20 }

        $riskLevel = switch ($riskScore) {
            { $_ -ge 70 } { "CRITIQUE" }
            { $_ -ge 40 } { "ELEVE" }
            { $_ -ge 20 } { "MODERE" }
            default       { "FAIBLE" }
        }

        $allUsers += [PSCustomObject]@{
            UID                  = $u.UID
            sAMAccountName       = $u.sAMAccountName
            DisplayName          = $u.DisplayName
            UserPrincipalName    = $u.UserPrincipalName
            Department           = $u.Department
            Domain               = $u.Domain
            Title                = $u.Title
            Enabled              = $u.Enabled
            LastLogonDate        = $u.LastLogonDate
            DaysSinceLastLogon   = $daysSinceLogon
            PasswordLastSet      = $u.PasswordLastSet
            PasswordNeverExpires = $u.PasswordNeverExpires
            WhenCreated          = $u.WhenCreated
            MemberOf             = $u.MemberOf
            Description          = $u.Description
            IsStale              = if ($isStale) { "OUI" } else { "NON" }
            IsPrivileged         = if ($isPrivileged) { "OUI" } else { "NON" }
            IsServiceAccount     = if ($isSvc) { "OUI" } else { "NON" }
            MFAEnabled           = $u.MFAEnabled
            RiskScore            = $riskScore
            RiskLevel            = $riskLevel
            AuditDate            = (Get-Date -Format "yyyy-MM-dd")
            AuditSource          = "SIMULATION_CSV"
        }
    }

} else {
    # Mode AD réel
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Err "Module ActiveDirectory non disponible. Utiliser -Simulation pour le mode lab."
        exit 1
    }

    Import-Module ActiveDirectory
    $cutoffDate = (Get-Date).AddDays(-$InactiveDaysThreshold)

    try {
        $adUsers = Get-ADUser -SearchBase $SearchBase -Filter * -Properties `
            DisplayName, Department, Title, Enabled, LastLogonDate,
            PasswordLastSet, PasswordNeverExpires, WhenCreated,
            MemberOf, Description, UserPrincipalName, EmailAddress

        Write-Ok "$($adUsers.Count) comptes récupérés depuis l'AD"

        foreach ($u in $adUsers) {
            $lastLogon = if ($u.LastLogonDate) { $u.LastLogonDate } else { [datetime]::MinValue }
            $daysSinceLogon = if ($lastLogon -ne [datetime]::MinValue) {
                [int](((Get-Date) - $lastLogon).TotalDays)
            } else { 9999 }

            $groupNames = $u.MemberOf | ForEach-Object {
                (Get-ADGroup $_).Name
            }

            $isPrivileged = $groupNames | Where-Object { $PrivilegedGroups -contains $_ }
            $isStale = ($lastLogon -lt $cutoffDate) -and ($u.Enabled -eq $true)
            $isSvc   = $u.SamAccountName -match "^svc_"

            $riskScore = 0
            if ($isStale)                          { $riskScore += 30 }
            if ($isPrivileged)                     { $riskScore += 25 }
            if ($u.PasswordNeverExpires)           { $riskScore += 15 }
            if (-not $u.Description)               { $riskScore += 10 }
            if ($daysSinceLogon -gt 365)           { $riskScore += 20 }

            $riskLevel = switch ($riskScore) {
                { $_ -ge 70 } { "CRITIQUE" }
                { $_ -ge 40 } { "ELEVE" }
                { $_ -ge 20 } { "MODERE" }
                default       { "FAIBLE" }
            }

            $allUsers += [PSCustomObject]@{
                UID                  = $u.ObjectGUID
                sAMAccountName       = $u.SamAccountName
                DisplayName          = $u.DisplayName
                UserPrincipalName    = $u.UserPrincipalName
                Department           = $u.Department
                Domain               = ($u.DistinguishedName -replace ".*DC=(\w+),DC=(\w+).*",'$1.$2')
                Title                = $u.Title
                Enabled              = $u.Enabled
                LastLogonDate        = if ($lastLogon -ne [datetime]::MinValue) { $lastLogon.ToString("yyyy-MM-dd") } else { "" }
                DaysSinceLastLogon   = $daysSinceLogon
                PasswordLastSet      = if ($u.PasswordLastSet) { $u.PasswordLastSet.ToString("yyyy-MM-dd") } else { "" }
                PasswordNeverExpires = $u.PasswordNeverExpires
                WhenCreated          = if ($u.WhenCreated) { $u.WhenCreated.ToString("yyyy-MM-dd") } else { "" }
                MemberOf             = ($groupNames -join "|")
                Description          = $u.Description
                IsStale              = if ($isStale) { "OUI" } else { "NON" }
                IsPrivileged         = if ($isPrivileged) { "OUI" } else { "NON" }
                IsServiceAccount     = if ($isSvc) { "OUI" } else { "NON" }
                MFAEnabled           = "NON"
                RiskScore            = $riskScore
                RiskLevel            = $riskLevel
                AuditDate            = (Get-Date -Format "yyyy-MM-dd")
                AuditSource          = "AD_LIVE"
            }
        }
    } catch {
        Write-Err "Erreur lors de la requête AD : $_"
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Export CSV
# ---------------------------------------------------------------------------

Write-Section "Export des résultats"

$allUsers | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Ok "CSV exporté : $OutputFile ($($allUsers.Count) lignes)"

# ---------------------------------------------------------------------------
# Rapport de synthèse
# ---------------------------------------------------------------------------

Write-Section "Synthèse de l'inventaire"

$total      = $allUsers.Count
$enabled    = ($allUsers | Where-Object { $_.Enabled -eq "TRUE" -or $_.Enabled -eq $true }).Count
$disabled   = $total - $enabled
$stale      = ($allUsers | Where-Object { $_.IsStale -eq "OUI" }).Count
$privileged = ($allUsers | Where-Object { $_.IsPrivileged -eq "OUI" }).Count
$service    = ($allUsers | Where-Object { $_.IsServiceAccount -eq "OUI" }).Count
$noMFA      = ($allUsers | Where-Object { $_.MFAEnabled -eq "FALSE" -or $_.MFAEnabled -eq "NON" }).Count
$noDesc     = ($allUsers | Where-Object { -not $_.Description }).Count

$critique = ($allUsers | Where-Object { $_.RiskLevel -eq "CRITIQUE" }).Count
$eleve    = ($allUsers | Where-Object { $_.RiskLevel -eq "ELEVE" }).Count
$modere   = ($allUsers | Where-Object { $_.RiskLevel -eq "MODERE" }).Count
$faible   = ($allUsers | Where-Object { $_.RiskLevel -eq "FAIBLE" }).Count

$byDept = $allUsers | Group-Object Department | Sort-Object Count -Descending |
    ForEach-Object { "    $($_.Name.PadRight(20)) : $($_.Count)" }

$summary = @"
════════════════════════════════════════════════════════════
  RAPPORT D'INVENTAIRE AD — CorpB
  Généré le : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  Source    : $(if ($Simulation) { "SIMULATION (CSV seed)" } else { "AD LIVE — $SearchBase" })
════════════════════════════════════════════════════════════

  VOLUME
    Total comptes          : $total
    Comptes actifs         : $enabled
    Comptes désactivés     : $disabled

  PROFILS À RISQUE
    Obsolètes (IsStale)    : $stale
    Comptes de service     : $service
    Comptes privilégiés    : $privileged
    Sans description       : $noDesc
    Sans MFA               : $noMFA / $total (100% — CorpB n'a pas déployé MFA)

  NIVEAUX DE RISQUE (score composite)
    CRITIQUE               : $critique
    ÉLEVÉ                  : $eleve
    MODÉRÉ                 : $modere
    FAIBLE                 : $faible

  RÉPARTITION PAR DÉPARTEMENT
$($byDept -join "`n")

  FICHIERS PRODUITS
    $OutputFile

  PROCHAINES ÉTAPES
    Phase 1  → Audit-StaleAccounts.ps1       (détail comptes obsolètes)
    Phase 1  → Audit-PrivilegedAccounts.ps1  (détail comptes privilégiés)
    Phase 1  → Audit-GroupMembership.ps1     (cartographie groupes)
    Phase 1  → Audit-PasswordPolicy.ps1      (politique mots de passe)
    Phase 2  → Remediate-StaleAccounts.ps1   (action sur la base de ce rapport)

════════════════════════════════════════════════════════════
  LECTURE SEULE — Aucune modification AD effectuée
════════════════════════════════════════════════════════════
"@

$summary | Tee-Object -FilePath $SummaryFile
Write-Ok "Résumé exporté : $SummaryFile"

# Alertes
Write-Section "Alertes"
if ($critique -gt 0) {
    Write-Warn "$critique compte(s) CRITIQUE(s) — traitement prioritaire en Phase 2"
}
if ($privileged -gt 0) {
    Write-Warn "$privileged compte(s) privilégié(s) — revue manuelle requise (Audit-PrivilegedAccounts.ps1)"
}
if ($stale -gt 0) {
    Write-Warn "$stale compte(s) obsolète(s) — préparation remédiation Phase 2"
}
if ($noMFA -eq $total) {
    Write-Warn "MFA absent sur 100% des comptes — enforcement requis lors de la migration Phase 3"
}

Write-Host ""
Write-Host "  Phase 1 — Audit-ADInventory terminé." -ForegroundColor Green
Write-Host "  Étape suivante : .\Audit-StaleAccounts.ps1" -ForegroundColor Cyan
Write-Host ""
