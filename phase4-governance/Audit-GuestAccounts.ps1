<#
.SYNOPSIS
    Audit-GuestAccounts.ps1
    Audit des comptes invités (Guest) hérités de CorpB dans Entra ID CorpA.

.DESCRIPTION
    Cartographie les comptes de type Guest dans le tenant CorpA qui ont
    été créés dans le cadre de la collaboration CorpA-CorpB pre-fusion,
    ou transférés lors de la migration.

    Quatre profils de Guest à risque identifiés :
      ANCIEN_INVITE_CORPB    : Guest créé avant la fusion — statut à requalifier
      INVITE_SANS_ACTIVITE   : Guest sans connexion depuis > 30 jours
      INVITE_ACCES_SENSIBLES : Guest membre d'un groupe à données sensibles
      INVITE_NON_NOMME       : Guest dont le DisplayName ne permet pas l'identification

    Mode : LECTURE SEULE.

.PARAMETER Simulation
    Mode simulation

.PARAMETER TargetDomain
    Domaine tenant Entra ID CorpA

.PARAMETER OutputPath
    Répertoire de sortie

.PARAMETER GuestInactiveDays
    Seuil d'inactivité Guest en jours (défaut : 30)

.EXAMPLE
    .\Audit-GuestAccounts.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15, A.5.18 | NIS2 Art.21§2(i) | RGPD Art.5(1)(c)
    Référence croisée : iam-federation-lab / Audit-GuestAccounts.ps1 (adapté M&A)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [int]$GuestInactiveDays = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase4-guest-accounts_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-GuestAccounts.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  Seuil inactivité Guest : $GuestInactiveDays jours" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$sensitiveGroups = @("GRP_Finance_Users","GRP_BambooHR_Access","GRP_Direction_Managers",
                     "GRP_Domain_Admins_Local","GRP_AS400_Access")

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# Données fictives Guest simulées — représentatives d'une collaboration pré-fusion
$SimulatedGuests = @(
    @{ UPN="ext.consultant1@partner.com";  DisplayName="Consultant Externe 1"; CreatedDate="2023-06-15"; LastSignIn="2024-11-20"; Groups="GRP_Jira_Agents";        PreFusion=$true  },
    @{ UPN="ext.dev2@freelance.io";        DisplayName="Dev Freelance";         CreatedDate="2024-01-10"; LastSignIn="2024-08-05"; Groups="GRP_GitLab_Users";       PreFusion=$true  },
    @{ UPN="contact@client-externe.fr";    DisplayName="Contact Client";         CreatedDate="2023-03-20"; LastSignIn="2023-09-12"; Groups="GRP_CRM_Salesforce";     PreFusion=$true  },
    @{ UPN="audit@cabinet-audit.com";      DisplayName="Auditeur Cabinet";       CreatedDate="2024-05-01"; LastSignIn="";           Groups="GRP_Finance_Users";      PreFusion=$true  },
    @{ UPN="";                             DisplayName="#EXT#user123";           CreatedDate="2022-11-30"; LastSignIn="2023-01-05"; Groups="";                       PreFusion=$true  },
    @{ UPN="rh@interim-rh.com";            DisplayName="RH Intérim";             CreatedDate="2024-08-15"; LastSignIn="2024-12-01"; Groups="GRP_BambooHR_Access";    PreFusion=$false },
    @{ UPN="tech.support@vendor.net";      DisplayName="Support Vendeur";        CreatedDate="2023-07-22"; LastSignIn="2025-01-10"; Groups="GRP_Tech_Devs";          PreFusion=$false },
    @{ UPN="project@consulting-firm.com";  DisplayName="Consultant Projet";      CreatedDate="2024-11-01"; LastSignIn="2025-01-15"; Groups="GRP_Jira_Agents";        PreFusion=$false },
)

if ($Simulation) {
    $inactiveCutoff = (Get-Date).AddDays(-$GuestInactiveDays)

    foreach ($g in $SimulatedGuests) {
        $lastSignIn   = if ($g.LastSignIn) { [datetime]::ParseExact($g.LastSignIn,"yyyy-MM-dd",$null) } else { [datetime]::MinValue }
        $createdDate  = [datetime]::ParseExact($g.CreatedDate,"yyyy-MM-dd",$null)
        $guestGroups  = if ($g.Groups) { $g.Groups -split "\|" | ForEach-Object { $_.Trim() } } else { @() }
        $isAnonymous  = [string]::IsNullOrWhiteSpace($g.UPN) -or $g.DisplayName -match "^#EXT#"
        $hasSensitive = $guestGroups | Where-Object { $sensitiveGroups -contains $_ }
        $isInactive   = $lastSignIn -eq [datetime]::MinValue -or $lastSignIn -lt $inactiveCutoff
        $daysSinceSignIn = if ($lastSignIn -ne [datetime]::MinValue) { [int](((Get-Date) - $lastSignIn).TotalDays) } else { 9999 }

        $profiles = @()
        if ($g.PreFusion)     { $profiles += "ANCIEN_INVITE_CORPB" }
        if ($isInactive)      { $profiles += "INVITE_SANS_ACTIVITE" }
        if ($hasSensitive)    { $profiles += "INVITE_ACCES_SENSIBLES" }
        if ($isAnonymous)     { $profiles += "INVITE_NON_NOMME" }

        $riskLevel = if ($profiles.Count -ge 3 -or $hasSensitive) { "CRITIQUE" }
                     elseif ($profiles.Count -eq 2)               { "ELEVE" }
                     elseif ($profiles.Count -eq 1)               { "MODERE" }
                     else                                          { "FAIBLE" }

        $results.Add([PSCustomObject]@{
            GuestUPN              = if ($g.UPN) { $g.UPN } else { "— NON IDENTIFIÉ —" }
            DisplayName           = $g.DisplayName
            CreatedDate           = $g.CreatedDate
            LastSignInDate        = if ($g.LastSignIn) { $g.LastSignIn } else { "Jamais" }
            DaysSinceLastSignIn   = $daysSinceSignIn
            MemberOf              = $g.Groups
            HasSensitiveGroupAccess = if ($hasSensitive) { "OUI — $($hasSensitive -join ', ')" } else { "NON" }
            PreFusionGuest        = if ($g.PreFusion) { "OUI" } else { "NON" }
            RiskProfiles          = ($profiles -join " | ")
            RiskLevel             = $riskLevel
            RecommendedAction     = switch ($riskLevel) {
                "CRITIQUE" { "DESACTIVER_OU_REQUALIFIER_URGENT" }
                "ELEVE"    { "REVUE_PROPRIETAIRE_SOUS_7J" }
                "MODERE"   { "CONFIRMER_BESOIN_ACCES" }
                default    { "SURVEILLANCE_PERIODIQUE" }
            }
            AuditDate             = (Get-Date -Format "yyyy-MM-dd")
        })
    }
} else {
    Import-Module Microsoft.Graph.Users
    Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -ErrorAction Stop

    $inactiveCutoff = (Get-Date).AddDays(-$GuestInactiveDays).ToString("yyyy-MM-ddTHH:mm:ssZ")

    $guests = Get-MgUser -Filter "userType eq 'Guest'" `
        -Property UserPrincipalName,DisplayName,CreatedDateTime,SignInActivity,AccountEnabled,MemberOf -All

    foreach ($g in $guests) {
        $lastSignIn  = $g.SignInActivity?.LastSignInDateTime
        $guestGroups = $g.MemberOf | ForEach-Object { $_.DisplayName }
        $isAnon      = [string]::IsNullOrWhiteSpace($g.UserPrincipalName) -or $g.DisplayName -match "^#EXT#"
        $hasSensitive = $guestGroups | Where-Object { $sensitiveGroups -contains $_ }
        $isInactive  = -not $lastSignIn -or [datetime]$lastSignIn -lt (Get-Date).AddDays(-$GuestInactiveDays)
        $daysSince   = if ($lastSignIn) { [int](((Get-Date) - [datetime]$lastSignIn).TotalDays) } else { 9999 }

        $profiles = @()
        if ($isInactive)   { $profiles += "INVITE_SANS_ACTIVITE" }
        if ($hasSensitive) { $profiles += "INVITE_ACCES_SENSIBLES" }
        if ($isAnon)       { $profiles += "INVITE_NON_NOMME" }

        $riskLevel = if ($profiles.Count -ge 2 -or $hasSensitive) { "CRITIQUE" }
                     elseif ($profiles.Count -eq 1)               { "ELEVE" }
                     else                                          { "MODERE" }

        $results.Add([PSCustomObject]@{
            GuestUPN              = $g.UserPrincipalName
            DisplayName           = $g.DisplayName
            CreatedDate           = if ($g.CreatedDateTime) { ([datetime]$g.CreatedDateTime).ToString("yyyy-MM-dd") } else { "" }
            LastSignInDate        = if ($lastSignIn) { ([datetime]$lastSignIn).ToString("yyyy-MM-dd") } else { "Jamais" }
            DaysSinceLastSignIn   = $daysSince
            MemberOf              = ($guestGroups -join " | ")
            HasSensitiveGroupAccess = if ($hasSensitive) { "OUI — $($hasSensitive -join ', ')" } else { "NON" }
            PreFusionGuest        = "—"
            RiskProfiles          = ($profiles -join " | ")
            RiskLevel             = $riskLevel
            RecommendedAction     = switch ($riskLevel) {
                "CRITIQUE" { "DESACTIVER_OU_REQUALIFIER_URGENT" }
                "ELEVE"    { "REVUE_PROPRIETAIRE_SOUS_7J" }
                default    { "CONFIRMER_BESOIN_ACCES" }
            }
            AuditDate             = (Get-Date -Format "yyyy-MM-dd")
        })
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$critique = ($results | Where-Object { $_.RiskLevel -eq "CRITIQUE" }).Count
$preFusion = ($results | Where-Object { $_.PreFusionGuest -eq "OUI" }).Count
$sensitive = ($results | Where-Object { $_.HasSensitiveGroupAccess -like "OUI*" }).Count

Write-Host "  [OK] $($results.Count) compte(s) Guest détecté(s) → $OutputFile"
Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  Total Guests          : $($results.Count)"
Write-Host "  Niveau CRITIQUE       : $critique"
Write-Host "  Accès données sensib. : $sensitive  ← Traitement prioritaire"
Write-Host "  Antérieurs à la fusion: $preFusion  ← Requalification requise"
Write-Host ""
Write-Host "  Étape suivante : python Audit-SaaSPostFusion.py" -ForegroundColor Cyan
Write-Host ""
