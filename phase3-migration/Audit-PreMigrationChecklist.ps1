<#
.SYNOPSIS
    Audit-PreMigrationChecklist.ps1
    Checklist de prérequis GO / NO-GO avant migration vers Entra ID.

.DESCRIPTION
    Évalue 12 points de contrôle couvrant les dimensions technique,
    organisationnelle et réglementaire. Produit un rapport GO/NO-GO
    que le DSI CorpA doit valider avant d'autoriser la Phase 3.

    Un seul point CRITIQUE en NO-GO bloque la migration.
    Les points MODERE en NO-GO sont documentés mais ne bloquent pas.

    Mode : LECTURE SEULE.

.PARAMETER Simulation
    Mode simulation — évalue les contrôles sur la base des datasets seed

.PARAMETER SourceCsvPath
    Chemin vers corpb-users.csv (vérification phase 2 terminée)

.PARAMETER TargetDomain
    Domaine tenant Entra ID cible (ex: corpa.onmicrosoft.com)

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    .\Audit-PreMigrationChecklist.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15, A.5.16 | NIS2 Art.21§2(i) | RGPD Art.25
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [string]$SourceCsvPath = "..\seed\corpb-users.csv",

    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [string]$OutputPath = "..\reports\"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase3-premigration-checklist_$Timestamp.csv"
$ReportFile = Join-Path $OutputPath "phase3-premigration-report_$Timestamp.txt"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-PreMigrationChecklist.ps1 — GO / NO-GO" -ForegroundColor Cyan
Write-Host "  Mode : $(if ($Simulation) { 'SIMULATION' } else { 'LIVE' })" -ForegroundColor Gray
Write-Host "  Tenant cible : $TargetDomain" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Chargement des données source
# ---------------------------------------------------------------------------

$sourceUsers = @()
if (Test-Path $SourceCsvPath) {
    $sourceUsers = Import-Csv -Path $SourceCsvPath -Delimiter ";" -Encoding UTF8
}

# Chercher le dernier rapport de Phase 2
$reportsPath    = Join-Path (Split-Path $OutputPath) "reports"
$phase2StaleLog = Get-ChildItem -Path $reportsPath -Filter "phase2-stale-execution_*.csv" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$phase2PrivLog  = Get-ChildItem -Path $reportsPath -Filter "phase2-privileged-execution_*.csv" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

# ---------------------------------------------------------------------------
# Définition des 12 points de contrôle
# ---------------------------------------------------------------------------

$checks = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Check {
    param(
        [int]$Id,
        [string]$Category,
        [string]$Control,
        [string]$Severity,   # CRITIQUE / MODERE
        [bool]$Passed,
        [string]$Detail,
        [string]$Action = ""
    )
    $checks.Add([PSCustomObject]@{
        Id         = $Id
        Category   = $Category
        Control    = $Control
        Severity   = $Severity
        Status     = if ($Passed) { "GO" } else { "NO-GO" }
        Detail     = $Detail
        Action     = if ($Passed) { "—" } else { $Action }
        AuditDate  = (Get-Date -Format "yyyy-MM-dd")
    })
}

# ── BLOC 1 : SOURCE AD ──────────────────────────────────────────────────

$staleCount    = ($sourceUsers | Where-Object { $_.IsStale -eq "TRUE" -and $_.Enabled -eq "TRUE" }).Count
$privUndocCount= ($sourceUsers | Where-Object { $_.IsPrivileged -eq "TRUE" -and -not $_.Description }).Count
$totalEnabled  = ($sourceUsers | Where-Object { $_.Enabled -eq "TRUE" }).Count

Add-Check -Id 1 -Category "Source AD" -Control "Comptes obsolètes désactivés" `
    -Severity "CRITIQUE" `
    -Passed ($staleCount -eq 0) `
    -Detail "$(if ($staleCount -eq 0) { 'Aucun compte obsolète actif détecté' } else { "$staleCount compte(s) obsolète(s) encore actif(s) — Phase 2 non terminée" })" `
    -Action "Exécuter Remediate-StaleAccounts.ps1 et vérifier les comptes IsStale=TRUE"

Add-Check -Id 2 -Category "Source AD" -Control "Comptes privilégiés documentés" `
    -Severity "CRITIQUE" `
    -Passed ($privUndocCount -eq 0) `
    -Detail "$(if ($privUndocCount -eq 0) { 'Tous les comptes privilégiés sont documentés' } else { "$privUndocCount compte(s) privilégié(s) sans description" })" `
    -Action "Exécuter Remediate-PrivilegedReview.ps1 — documenter ou révoquer"

Add-Check -Id 3 -Category "Source AD" -Control "Volume comptes éligibles à migrer" `
    -Severity "MODERE" `
    -Passed ($totalEnabled -gt 0 -and $totalEnabled -le 400) `
    -Detail "$totalEnabled compte(s) actif(s) identifiés pour migration" `
    -Action "Vérifier que le volume est cohérent avec l'attendu"

# ── BLOC 2 : TENANT CIBLE ───────────────────────────────────────────────

$graphAvailable = $false
if (-not $Simulation) {
    $graphAvailable = $null -ne (Get-Module -ListAvailable -Name Microsoft.Graph)
}

Add-Check -Id 4 -Category "Tenant Entra ID" -Control "Module Microsoft.Graph disponible" `
    -Severity "CRITIQUE" `
    -Passed ($Simulation -or $graphAvailable) `
    -Detail "$(if ($Simulation) { 'Mode simulation — vérification ignorée' } elseif ($graphAvailable) { 'Module Microsoft.Graph installé' } else { 'Module Microsoft.Graph absent' })" `
    -Action "Install-Module Microsoft.Graph -Scope CurrentUser"

Add-Check -Id 5 -Category "Tenant Entra ID" -Control "Domaine cible configuré" `
    -Severity "CRITIQUE" `
    -Passed (-not [string]::IsNullOrWhiteSpace($TargetDomain) -and $TargetDomain -match "\.") `
    -Detail "Domaine cible : $TargetDomain" `
    -Action "Configurer le paramètre -TargetDomain avec le domaine Entra ID CorpA"

Add-Check -Id 6 -Category "Tenant Entra ID" -Control "Licences suffisantes (estimation)" `
    -Severity "MODERE" `
    -Passed $true `
    -Detail "$(if ($Simulation) { "Simulation : $totalEnabled licences nécessaires (Microsoft 365 E3 hypothèse lab)" } else { 'Vérifier manuellement dans le portail Azure AD > Licences' })" `
    -Action "Vérifier le nombre de licences disponibles dans le tenant CorpA"

# ── BLOC 3 : SÉCURITÉ ───────────────────────────────────────────────────

$caAuditExists = $false
if ($Simulation) { $caAuditExists = $true }   # Simulé comme présent

Add-Check -Id 7 -Category "Sécurité" -Control "Conditional Access CorpA documentées" `
    -Severity "CRITIQUE" `
    -Passed $caAuditExists `
    -Detail "$(if ($caAuditExists) { '4 politiques CA CorpA documentées (iam-federation-lab D3)' } else { 'Politiques CA non auditées' })" `
    -Action "Exécuter Audit-ConditionalAccess.ps1 depuis iam-federation-lab"

Add-Check -Id 8 -Category "Sécurité" -Control "MFA enforcement configuré pour nouveaux comptes" `
    -Severity "CRITIQUE" `
    -Passed $Simulation `
    -Detail "$(if ($Simulation) { 'Simulation : MFA enforced via CA policy — vérifier en production' } else { 'Vérifier la politique CA MFA dans le tenant CorpA' })" `
    -Action "S'assurer que la CA policy MFA s'applique aux utilisateurs récemment créés"

Add-Check -Id 9 -Category "Sécurité" -Control "Legacy Auth bloquée sur tenant CorpA" `
    -Severity "MODERE" `
    -Passed $Simulation `
    -Detail "$(if ($Simulation) { 'Simulation : Legacy Auth block CA policy active (iam-federation-lab D2)' } else { 'Vérifier la politique CA Block Legacy Auth' })" `
    -Action "Référence : iam-federation-lab / Audit-LegacyAuth.ps1"

# ── BLOC 4 : ORGANISATIONNEL ────────────────────────────────────────────

$phase2Done = $null -ne $phase2StaleLog
Add-Check -Id 10 -Category "Organisationnel" -Control "Phase 2 remédiation terminée (log présent)" `
    -Severity "CRITIQUE" `
    -Passed ($phase2Done -or $Simulation) `
    -Detail "$(if ($Simulation) { 'Mode simulation — log Phase 2 non requis' } elseif ($phase2Done) { "Log Phase 2 trouvé : $($phase2StaleLog.Name)" } else { 'Aucun log Phase 2 trouvé dans /reports/' })" `
    -Action "Exécuter Phase 2 complète avant de relancer ce contrôle"

Add-Check -Id 11 -Category "Organisationnel" -Control "Validation DPO — base légale migration" `
    -Severity "CRITIQUE" `
    -Passed $Simulation `
    -Detail "$(if ($Simulation) { 'Simulation : validation DPO supposée obtenue' } else { 'Confirmer que Marc Deschamps (DPO) a validé la base légale RGPD Art.6' })" `
    -Action "Obtenir email de validation DPO avant exécution — conserver dans le dossier projet"

Add-Check -Id 12 -Category "Organisationnel" -Control "Guide utilisateur J-Day envoyé (J-3)" `
    -Severity "MODERE" `
    -Passed $Simulation `
    -Detail "$(if ($Simulation) { 'Simulation : guide OCM Phase 3 supposé envoyé' } else { 'Confirmer que OCM-Phase3-MigrationGuide.md a été envoyé aux collaborateurs CorpB' })" `
    -Action "Envoyer ../ocm/OCM-Phase3-MigrationGuide.md aux collaborateurs CorpB J-3 avant J-Day"

# ---------------------------------------------------------------------------
# Calcul GO/NO-GO global
# ---------------------------------------------------------------------------

$critiques  = $checks | Where-Object { $_.Severity -eq "CRITIQUE" }
$noGoCrit   = $critiques | Where-Object { $_.Status -eq "NO-GO" }
$modere     = $checks | Where-Object { $_.Severity -eq "MODERE" }
$noGoMod    = $modere | Where-Object { $_.Status -eq "NO-GO" }

$globalStatus = if ($noGoCrit.Count -eq 0) { "GO" } else { "NO-GO" }

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

$checks | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

# ---------------------------------------------------------------------------
# Rapport console + fichier
# ---------------------------------------------------------------------------

$reportLines = @()
$reportLines += "════════════════════════════════════════════════════════════"
$reportLines += "  RAPPORT PRÉ-MIGRATION — Checklist GO / NO-GO"
$reportLines += "  Généré le : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "  Tenant cible : $TargetDomain"
$reportLines += "════════════════════════════════════════════════════════════"
$reportLines += ""

foreach ($check in $checks) {
    $icon   = if ($check.Status -eq "GO") { "[GO   ]" } else { "[NO-GO]" }
    $sev    = if ($check.Severity -eq "CRITIQUE") { "CRIT" } else { "MOD " }
    $reportLines += "  $icon [$sev] #$($check.Id.ToString().PadLeft(2)) $($check.Control)"
    if ($check.Status -eq "NO-GO") {
        $reportLines += "         → $($check.Detail)"
        $reportLines += "         → ACTION : $($check.Action)"
    }
}

$reportLines += ""
$reportLines += "────────────────────────────────────────────────────────────"
$reportLines += "  RÉSULTAT GLOBAL : $globalStatus"
$reportLines += "  Points CRITIQUE : $($critiques.Count) dont $($noGoCrit.Count) en NO-GO"
$reportLines += "  Points MODERE   : $($modere.Count) dont $($noGoMod.Count) en NO-GO"
$reportLines += "────────────────────────────────────────────────────────────"

if ($globalStatus -eq "GO") {
    $reportLines += ""
    $reportLines += "  ✓ Tous les points CRITIQUE sont en GO."
    $reportLines += "  La migration peut être autorisée par le DSI CorpA."
    $reportLines += ""
    $reportLines += "  Étape suivante :"
    $reportLines += "  .\Migrate-UsersToEntraID.ps1 -DryRun (simulation d'abord)"
} else {
    $reportLines += ""
    $reportLines += "  ✗ $($noGoCrit.Count) point(s) CRITIQUE(s) bloquent la migration."
    $reportLines += "  Corriger les points NO-GO avant de relancer cette checklist."
}

$reportLines += ""
$reportLines += "════════════════════════════════════════════════════════════"
$reportLines += "  LECTURE SEULE — Aucune modification effectuée"
$reportLines += "════════════════════════════════════════════════════════════"

# Affichage console
foreach ($line in $reportLines) {
    if ($line -match "NO-GO") {
        Write-Host $line -ForegroundColor Red
    } elseif ($line -match "\[GO") {
        Write-Host $line -ForegroundColor Green
    } elseif ($line -match "RÉSULTAT GLOBAL") {
        $color = if ($globalStatus -eq "GO") { "Green" } else { "Red" }
        Write-Host $line -ForegroundColor $color
    } else {
        Write-Host $line -ForegroundColor Gray
    }
}

# Export fichier
$reportLines | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host ""
Write-Host "  [OK] CSV exporté : $OutputFile" -ForegroundColor Gray
Write-Host "  [OK] Rapport texte : $ReportFile" -ForegroundColor Gray
Write-Host ""
