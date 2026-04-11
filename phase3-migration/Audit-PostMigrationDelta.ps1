<#
.SYNOPSIS
    Audit-PostMigrationDelta.ps1
    Comparaison AD source CorpB vs tenant Entra ID CorpA post-migration.

.DESCRIPTION
    Compare les comptes éligibles du dataset AD CorpB avec les comptes
    effectivement provisionnés dans le tenant Entra ID CorpA.

    Produit un rapport de delta selon trois catégories :
      MATCH         : compte AD source trouvé dans Entra ID — migration OK
      MANQUANT      : compte AD source absent d'Entra ID — à re-provisionner
      SURPLUS       : compte Entra ID sans correspondance AD — à investiguer

    Un delta MANQUANT ou SURPLUS non justifié bloque le Go/NoGo J-Day.

    Mode : LECTURE SEULE.

.PARAMETER SourceCsvPath
    Chemin vers corpb-users.csv (référentiel source)

.PARAMETER TargetDomain
    Domaine tenant Entra ID cible

.PARAMETER Simulation
    Mode simulation — compare le CSV source avec lui-même pour valider la logique

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    # Mode simulation
    .\Audit-PostMigrationDelta.ps1 -Simulation -OutputPath "..\reports\"

.EXAMPLE
    # Mode réel post-migration Shadow
    .\Audit-PostMigrationDelta.ps1 -TargetDomain "corpa.onmicrosoft.com" -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15 | NIS2 Art.21§2(f) | RGPD Art.30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourceCsvPath = "..\seed\corpb-users.csv",

    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$OutputPath = "..\reports\"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase3-postmigration-delta_$Timestamp.csv"
$ReportFile = Join-Path $OutputPath "phase3-postmigration-report_$Timestamp.txt"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-PostMigrationDelta.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  Mode : $(if ($Simulation) { 'SIMULATION' } else { 'LIVE — Graph API' })" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Chargement source
# ---------------------------------------------------------------------------

if (-not (Test-Path $SourceCsvPath)) {
    Write-Host "  [ERROR] CSV source introuvable : $SourceCsvPath" -ForegroundColor Red; exit 1
}

$allSource = Import-Csv -Path $SourceCsvPath -Delimiter ";" -Encoding UTF8

# Périmètre éligible (cohérent avec Migrate-UsersToEntraID.ps1)
$eligibleSource = $allSource | Where-Object {
    $_.Enabled -eq "TRUE" -and
    $_.IsServiceAccount -eq "FALSE" -and
    $_.IsStale -eq "FALSE"
}

Write-Host "  Comptes source éligibles : $($eligibleSource.Count)"

# ---------------------------------------------------------------------------
# Chargement cible (Entra ID ou simulation)
# ---------------------------------------------------------------------------

$entraUsers = @()

if ($Simulation) {
    # Simulation : on suppose que 95% des comptes ont été migrés correctement
    # 5% manquants pour rendre le delta non-nul et illustrer la logique
    $migrated = $eligibleSource | Select-Object -First ([int]($eligibleSource.Count * 0.95))
    foreach ($u in $migrated) {
        $entraUsers += [PSCustomObject]@{
            UserPrincipalName = "$($u.sAMAccountName.ToLower())@$TargetDomain"
            DisplayName       = $u.DisplayName
            AccountEnabled    = $false   # Shadow — désactivés
            Department        = $u.Department
        }
    }
    Write-Host "  Comptes Entra ID simulés : $($entraUsers.Count) (95% — 5% manquants simulés)" -ForegroundColor Yellow
} else {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "  [ERROR] Module Microsoft.Graph requis. Utiliser -Simulation." -ForegroundColor Red; exit 1
    }
    Import-Module Microsoft.Graph.Users
    Write-Host "  Connexion Graph..." -ForegroundColor Gray
    Connect-MgGraph -Scopes "User.Read.All" -ErrorAction Stop

    # Récupérer les comptes du domaine cible
    $mgUsers = Get-MgUser -Filter "endswith(UserPrincipalName,'@$TargetDomain')" `
        -Property UserPrincipalName, DisplayName, AccountEnabled, Department -All
    foreach ($u in $mgUsers) {
        $entraUsers += [PSCustomObject]@{
            UserPrincipalName = $u.UserPrincipalName
            DisplayName       = $u.DisplayName
            AccountEnabled    = $u.AccountEnabled
            Department        = $u.Department
        }
    }
    Write-Host "  Comptes Entra ID récupérés : $($entraUsers.Count)" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Calcul du delta
# ---------------------------------------------------------------------------

# Index Entra ID par UPN
$entraIndex = @{}
foreach ($eu in $entraUsers) {
    $entraIndex[$eu.UserPrincipalName.ToLower()] = $eu
}

# Index source par UPN cible attendue
$sourceIndex = @{}
foreach ($su in $eligibleSource) {
    $expectedUpn = "$($su.sAMAccountName.Trim().ToLower())@$TargetDomain"
    $sourceIndex[$expectedUpn] = $su
}

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# Comptes source → vérifier présence dans Entra ID
foreach ($kvp in $sourceIndex.GetEnumerator()) {
    $upn    = $kvp.Key
    $source = $kvp.Value
    $match  = $entraIndex[$upn]

    $status = if ($match) { "MATCH" } else { "MANQUANT" }
    $enabled = if ($match) { $match.AccountEnabled } else { "N/A" }

    $results.Add([PSCustomObject]@{
        UPN                  = $upn
        sAMAccountName_Source = $source.sAMAccountName
        DisplayName_Source   = $source.DisplayName
        Department           = $source.Department
        Domain_Source        = $source.Domain
        DeltaStatus          = $status
        AccountEnabled_Entra = $enabled
        ShadowMode           = if ($status -eq "MATCH" -and $enabled -eq $false) { "OUI" } else { "NON" }
        Action               = switch ($status) {
            "MATCH"    { "—" }
            "MANQUANT" { "Re-provisionner via Migrate-UsersToEntraID.ps1" }
        }
        AuditDate            = (Get-Date -Format "yyyy-MM-dd")
    })
}

# Comptes Entra ID → vérifier qu'ils ont une source connue (surplus)
foreach ($kvp in $entraIndex.GetEnumerator()) {
    $upn = $kvp.Key
    if (-not $sourceIndex.ContainsKey($upn)) {
        $eu = $kvp.Value
        $results.Add([PSCustomObject]@{
            UPN                   = $upn
            sAMAccountName_Source = "—"
            DisplayName_Source    = $eu.DisplayName
            Department            = $eu.Department
            Domain_Source         = "—"
            DeltaStatus           = "SURPLUS"
            AccountEnabled_Entra  = $eu.AccountEnabled
            ShadowMode            = "N/A"
            Action                = "Investiguer — compte Entra sans source AD connue"
            AuditDate             = (Get-Date -Format "yyyy-MM-dd")
        })
    }
}

# ---------------------------------------------------------------------------
# Export + rapport
# ---------------------------------------------------------------------------

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$match    = ($results | Where-Object { $_.DeltaStatus -eq "MATCH" }).Count
$manquant = ($results | Where-Object { $_.DeltaStatus -eq "MANQUANT" }).Count
$surplus  = ($results | Where-Object { $_.DeltaStatus -eq "SURPLUS" }).Count
$shadow   = ($results | Where-Object { $_.ShadowMode -eq "OUI" }).Count

$jdayStatus = if ($manquant -eq 0 -and $surplus -eq 0) { "GO" }
              elseif ($manquant -gt 0)                  { "NO-GO (MANQUANTS)" }
              else                                       { "NO-GO (SURPLUS)" }

$report = @"
════════════════════════════════════════════════════════════
  RAPPORT DELTA POST-MIGRATION
  Généré le : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Source     : $SourceCsvPath
  Cible      : $TargetDomain
════════════════════════════════════════════════════════════

  Comptes source éligibles     : $($eligibleSource.Count)
  Comptes Entra ID trouvés     : $($entraUsers.Count)

  ── Résultats delta ──

  MATCH     (migration OK)     : $match
  MANQUANT  (à re-provisionner): $manquant
  SURPLUS   (à investiguer)    : $surplus

  En Shadow Mode (désactivés)  : $shadow / $match comptes migrés

  ── Go/No-Go J-Day ──

  STATUT : $jdayStatus

$(if ($jdayStatus -eq "GO") {
"  ✓ Delta = 0. La bascule J-Day peut être autorisée.
  Commande J-Day :
  .\Migrate-UsersToEntraID.ps1 -CsvPath '$SourceCsvPath' ``
      -DryRun:`$false -ActivateShadowAccounts -TargetDomain '$TargetDomain'"
} else {
"  ✗ Delta non nul — corriger avant bascule.
  Comptes manquants : relancer Migrate-UsersToEntraID.ps1 -ShadowMode
  Comptes surplus   : investiguer et supprimer si non justifiés"
})

════════════════════════════════════════════════════════════
  LECTURE SEULE — Aucune modification effectuée
════════════════════════════════════════════════════════════
"@

$report | Tee-Object -FilePath $ReportFile

$goColor = if ($jdayStatus -eq "GO") { "Green" } else { "Red" }
Write-Host ""
Write-Host "  Statut J-Day : $jdayStatus" -ForegroundColor $goColor
Write-Host "  [OK] CSV     : $OutputFile" -ForegroundColor Gray
Write-Host "  [OK] Rapport : $ReportFile" -ForegroundColor Gray
Write-Host ""
