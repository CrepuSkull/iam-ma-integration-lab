<#
.SYNOPSIS
    Setup-MgGraphApp.ps1
    Création et validation de l'App Registration Microsoft Graph pour le lab.

.DESCRIPTION
    Crée une App Registration dans Entra ID CorpA avec les permissions
    minimales nécessaires aux phases 3 et 4 du lab.

    En DryRun : vérifie les prérequis et affiche ce qui serait créé.
    En mode réel : crée l'App, configure les permissions, génère un fichier .env.

    Prérequis :
      - Droits : Global Administrator ou Application Administrator sur le tenant
      - Module Microsoft.Graph installé
      - Connexion active : Connect-MgGraph -Scopes "Application.ReadWrite.All"

.PARAMETER DryRun
    Vérifie les prérequis sans créer l'App (défaut : $true)

.PARAMETER AppName
    Nom de l'App Registration (défaut : iam-ma-integration-lab)

.PARAMETER OutputEnvFile
    Chemin du fichier .env produit (défaut : .\.env)

.PARAMETER AuditScopesOnly
    Si activé, configure uniquement les scopes lecture (pas d'écriture)
    Utile pour les phases d'audit sans migration

.EXAMPLE
    # Vérification des prérequis
    .\Setup-MgGraphApp.ps1 -DryRun

.EXAMPLE
    # Création complète (audit + migration)
    .\Setup-MgGraphApp.ps1 -DryRun:$false -AppName "iam-ma-integration-lab"

.EXAMPLE
    # Scopes audit uniquement
    .\Setup-MgGraphApp.ps1 -DryRun:$false -AuditScopesOnly

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / docs
    Voir PREREQUISITES-GRAPH.md pour la documentation complète.
    AVERTISSEMENT : le fichier .env produit contient un secret — ne pas versionner.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [string]$AppName = "iam-ma-integration-lab",

    [Parameter()]
    [string]$OutputEnvFile = ".\.env",

    [Parameter()]
    [switch]$AuditScopesOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Cyan" })
Write-Host "  Setup-MgGraphApp.ps1" -ForegroundColor White
Write-Host "  Mode      : $(if ($DryRun) { 'DRYRUN — vérification uniquement' } else { 'EXECUTION — création App Registration' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
Write-Host "  App name  : $AppName" -ForegroundColor Gray
Write-Host "  Scopes    : $(if ($AuditScopesOnly) { 'Lecture seule (audit)' } else { 'Lecture + Écriture (audit + migration)' })" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Cyan" })
Write-Host ""

# ---------------------------------------------------------------------------
# Définition des scopes
# ---------------------------------------------------------------------------

$auditScopes = @(
    "User.Read.All",
    "Group.Read.All",
    "Directory.Read.All",
    "AuditLog.Read.All"
)

$migrationScopes = @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "Directory.ReadWrite.All"
)

$requiredScopes = if ($AuditScopesOnly) { $auditScopes } else { $auditScopes + $migrationScopes }

# ---------------------------------------------------------------------------
# Vérifications préalables
# ---------------------------------------------------------------------------

Write-Host "  ── Vérifications préalables ──" -ForegroundColor Cyan
Write-Host ""

# Module Microsoft.Graph
$mgInstalled = Get-Module -ListAvailable -Name Microsoft.Graph
if ($mgInstalled) {
    $version = ($mgInstalled | Select-Object -First 1).Version
    Write-Host "  [OK] Microsoft.Graph installé — version $version" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Module Microsoft.Graph absent" -ForegroundColor Red
    Write-Host "          Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    exit 1
}

# Connexion active
$ctx = Get-MgContext
if ($ctx) {
    Write-Host "  [OK] Connexion active — $($ctx.Account)" -ForegroundColor Green
    Write-Host "       Tenant : $($ctx.TenantId)" -ForegroundColor Gray

    # Vérifier que le scope Application.ReadWrite.All est disponible
    if ($ctx.Scopes -notcontains "Application.ReadWrite.All" -and -not $DryRun) {
        Write-Host "  [WARN] Scope Application.ReadWrite.All manquant" -ForegroundColor Yellow
        Write-Host "         Reconnecter avec : Connect-MgGraph -Scopes 'Application.ReadWrite.All'" -ForegroundColor Yellow
        if (-not $DryRun) { exit 1 }
    }
} else {
    Write-Host "  [ERROR] Aucune connexion Graph active" -ForegroundColor Red
    Write-Host "          Connect-MgGraph -Scopes 'Application.ReadWrite.All'" -ForegroundColor Red
    if (-not $DryRun) { exit 1 }
    Write-Host "  [INFO]  Mode DryRun — continuation sans connexion" -ForegroundColor Yellow
}

# Vérifier si l'App existe déjà
$existingApp = $null
if ($ctx) {
    $existingApp = Get-MgApplication -Filter "DisplayName eq '$AppName'" -ErrorAction SilentlyContinue
    if ($existingApp) {
        Write-Host "  [INFO] App '$AppName' existe déjà (ClientId: $($existingApp.AppId))" -ForegroundColor Yellow
    } else {
        Write-Host "  [INFO] App '$AppName' n'existe pas encore — sera créée" -ForegroundColor Gray
    }
}

Write-Host ""

# ---------------------------------------------------------------------------
# Affichage du plan (DryRun)
# ---------------------------------------------------------------------------

Write-Host "  ── Plan de configuration ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  App Registration : $AppName"
Write-Host "  Type             : Single tenant (CorpA uniquement)"
Write-Host "  Permissions ($($requiredScopes.Count)) :" -ForegroundColor White
foreach ($scope in $requiredScopes) {
    $type = if ($scope -like "*.ReadWrite.*") { "Lecture/Écriture" } else { "Lecture" }
    $icon = if ($scope -like "*.ReadWrite.*") { "⚠" } else { "✓" }
    Write-Host "    $icon  $scope ($type)"
}
Write-Host ""
Write-Host "  Secret           : Généré automatiquement (24 mois)"
Write-Host "  Fichier .env     : $OutputEnvFile"
Write-Host ""

if ($DryRun) {
    Write-Host "  Mode DryRun — aucune création effectuée." -ForegroundColor Yellow
    Write-Host "  Pour créer l'App : .\Setup-MgGraphApp.ps1 -DryRun:`$false" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  ── Prochaines étapes après création ──" -ForegroundColor Cyan
    Write-Host "  1. Portail Azure → App Registrations → $AppName"
    Write-Host "     → API Permissions → Grant admin consent"
    Write-Host "     (requis même si les permissions sont ajoutées via script)"
    Write-Host ""
    Write-Host "  2. Charger le fichier .env et connecter Graph :"
    Write-Host '     $env = Get-Content ".\.env" | ConvertFrom-StringData'
    Write-Host '     $secret = $env.GRAPH_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force'
    Write-Host '     $cred = New-Object System.Management.Automation.PSCredential($env.GRAPH_CLIENT_ID, $secret)'
    Write-Host '     Connect-MgGraph -ClientSecretCredential $cred -TenantId $env.GRAPH_TENANT_ID'
    Write-Host ""
    Write-Host "  3. Tester la connexion :"
    Write-Host "     Get-MgContext"
    Write-Host "     Get-MgUser -Top 1"
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# Création de l'App Registration
# ---------------------------------------------------------------------------

Write-Host "  ── Création de l'App Registration ──" -ForegroundColor Cyan
Write-Host ""

Import-Module Microsoft.Graph.Applications -ErrorAction Stop

# Récupérer le ServicePrincipalId de Microsoft Graph
$graphServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

if (-not $graphServicePrincipal) {
    Write-Host "  [ERROR] Impossible de trouver le ServicePrincipal Microsoft Graph" -ForegroundColor Red
    exit 1
}

# Construire la liste des permissions requises
$requiredResourceAccess = @()
$graphPermissions = @()

foreach ($scopeName in $requiredScopes) {
    $appRole = $graphServicePrincipal.AppRoles |
        Where-Object { $_.Value -eq $scopeName -and $_.AllowedMemberTypes -contains "Application" }
    if ($appRole) {
        $graphPermissions += @{
            Id   = $appRole.Id
            Type = "Role"
        }
    } else {
        Write-Host "  [WARN] Permission '$scopeName' non trouvée dans Graph" -ForegroundColor Yellow
    }
}

$requiredResourceAccess += @{
    ResourceAppId   = "00000003-0000-0000-c000-000000000000"
    ResourceAccess  = $graphPermissions
}

try {
    if ($existingApp) {
        # Mettre à jour l'App existante
        Update-MgApplication -ApplicationId $existingApp.Id `
            -RequiredResourceAccess $requiredResourceAccess
        $app = Get-MgApplication -ApplicationId $existingApp.Id
        Write-Host "  [OK] App mise à jour : $AppName (ClientId: $($app.AppId))" -ForegroundColor Green
    } else {
        # Créer une nouvelle App
        $app = New-MgApplication -DisplayName $AppName `
            -SignInAudience "AzureADMyOrg" `
            -RequiredResourceAccess $requiredResourceAccess
        Write-Host "  [OK] App créée : $AppName (ClientId: $($app.AppId))" -ForegroundColor Green
    }

    # Créer le ServicePrincipal associé
    $sp = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'" -ErrorAction SilentlyContinue
    if (-not $sp) {
        $sp = New-MgServicePrincipal -AppId $app.AppId
        Write-Host "  [OK] ServicePrincipal créé" -ForegroundColor Green
    }

    # Générer un secret client
    $secretParams = @{
        PasswordCredential = @{
            DisplayName = "iam-lab-secret"
            EndDateTime = (Get-Date).AddMonths(24)
        }
    }
    $secret = Add-MgApplicationPassword -ApplicationId $app.Id @secretParams
    Write-Host "  [OK] Secret client généré (expire le $($secret.EndDateTime.ToString('yyyy-MM-dd')))" -ForegroundColor Green
    Write-Host "  [IMPORTANT] Copier le secret maintenant — il ne sera plus visible" -ForegroundColor Red

    # Récupérer le TenantId
    $tenantId = $ctx.TenantId

    # Générer le fichier .env
    $envContent = @"
# IAM-Ma-Integration-Lab — Microsoft Graph Configuration
# AVERTISSEMENT : Ne pas versionner ce fichier (.gitignore)
# Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Expire le $($secret.EndDateTime.ToString('yyyy-MM-dd'))

GRAPH_TENANT_ID=$tenantId
GRAPH_CLIENT_ID=$($app.AppId)
GRAPH_CLIENT_SECRET=$($secret.SecretText)
GRAPH_TARGET_DOMAIN=corpa.onmicrosoft.com
APP_REGISTRATION_NAME=$AppName
APP_OBJECT_ID=$($app.Id)
"@

    $envContent | Out-File -FilePath $OutputEnvFile -Encoding UTF8
    Write-Host ""
    Write-Host "  [OK] Fichier .env généré : $OutputEnvFile" -ForegroundColor Green
    Write-Host "  [WARN] Ajouter .env au .gitignore immédiatement" -ForegroundColor Red
    Write-Host ""

    # Instructions post-création
    Write-Host "  ── Actions manuelles requises ──" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. OBLIGATOIRE — Consentement admin dans le portail Azure :"
    Write-Host "     Portail Azure → Entra ID → App Registrations → $AppName"
    Write-Host "     → API Permissions → Grant admin consent for [tenant]"
    Write-Host ""
    Write-Host "  2. TEST de connexion :"
    Write-Host "     `$env = Get-Content '$OutputEnvFile' | ConvertFrom-StringData"
    Write-Host "     `$s = `$env.GRAPH_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force"
    Write-Host "     `$c = New-Object System.Management.Automation.PSCredential(`$env.GRAPH_CLIENT_ID, `$s)"
    Write-Host "     Connect-MgGraph -ClientSecretCredential `$c -TenantId `$env.GRAPH_TENANT_ID"
    Write-Host "     Get-MgContext  # Doit afficher l'App et le tenant"
    Write-Host ""
    Write-Host "  3. Alerte rotation secret — ajouter au monitoring :"
    Write-Host "     Date d'expiration : $($secret.EndDateTime.ToString('yyyy-MM-dd'))"
    Write-Host ""

} catch {
    Write-Host "  [ERROR] Création App Registration échouée : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "          Vérifier les droits (Global Admin ou Application Admin requis)" -ForegroundColor Red
    exit 1
}

Write-Host "  Setup terminé." -ForegroundColor Green
Write-Host "  Référence : PREREQUISITES-GRAPH.md" -ForegroundColor Cyan
Write-Host ""
