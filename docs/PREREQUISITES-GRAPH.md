# ⚙️ PREREQUISITES-GRAPH.md — Configuration Microsoft Graph

> `iam-ma-integration-lab` / docs
> Prérequis techniques pour les phases 3 et 4 (mode live)
> Langue : Français | Cible : ingénieur IAM, admin Entra ID

---

## Pourquoi ce document

Les scripts de migration (Phase 3) et de gouvernance (Phase 4) qui font
appel à Microsoft Graph nécessitent une configuration préalable dans
le tenant Entra ID CorpA. Sans cette configuration, les appels Graph
échouent avec des erreurs d'authentification peu explicites.

Ce document couvre la configuration complète. Le script `Setup-MgGraphApp.ps1`
automatise les étapes techniques et les vérifie en DryRun avant tout engagement.

> **Mode simulation disponible** : tous les scripts du lab ont un paramètre
> `-Simulation` qui lit les CSV du dossier `/seed/` sans appel Graph.
> Ce document est uniquement nécessaire pour le mode live (AD ou Entra ID réels).

---

## 1. Prérequis système

### PowerShell

```powershell
# Vérifier la version
$PSVersionTable.PSVersion
# Minimum requis : 5.1 (Windows PowerShell) ou 7.0+ (PowerShell Core)

# PowerShell 7+ recommandé pour les scripts avec Microsoft.Graph
winget install --id Microsoft.PowerShell --source winget
```

### Module Microsoft Graph

```powershell
# Installation (une seule fois)
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Vérification
Get-Module -ListAvailable Microsoft.Graph | Select-Object Name, Version

# Si le module est déjà installé, mettre à jour
Update-Module Microsoft.Graph
```

### Politique d'exécution PowerShell

```powershell
# Vérifier
Get-ExecutionPolicy -Scope CurrentUser

# Si Restricted — autoriser les scripts signés ou locaux
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# ou pour les scripts non signés en lab :
Set-ExecutionPolicy Bypass -Scope Process  # scope Process = temporaire
```

---

## 2. Option A — Authentification interactive (recommandée pour le lab)

La méthode la plus simple. Elle utilise votre compte administrateur
Entra ID pour s'authentifier via le navigateur.

```powershell
# Connexion avec les scopes nécessaires à l'audit
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","AuditLog.Read.All"

# Connexion avec les scopes nécessaires à la migration
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"

# Vérifier la connexion
Get-MgContext
# Doit afficher : Account, TenantId, Scopes
```

**Quand utiliser :** tests unitaires, démonstrations, lab mono-session.

**Limite :** expire après la session PowerShell. À répéter à chaque session.

---

## 3. Option B — App Registration (recommandée pour l'automatisation)

Pour des exécutions planifiées ou des pipelines sans interaction humaine,
créer une App Registration dans Entra ID CorpA.

### 3.1 Création manuelle (portail Azure)

```
1. Portail Azure → Entra ID → App Registrations → New Registration
   Nom : iam-ma-integration-lab
   Type : Accounts in this organizational directory only
   Redirect URI : (laisser vide)

2. API Permissions → Add a permission → Microsoft Graph → Application permissions
   Ajouter :
   - User.Read.All
   - User.ReadWrite.All    (migration uniquement)
   - Group.Read.All
   - Group.ReadWrite.All   (migration uniquement)
   - Directory.Read.All
   - AuditLog.Read.All     (gouvernance Phase 4)

3. Grant admin consent (bouton en haut de la page des permissions)

4. Certificates & Secrets → New client secret
   Description : iam-lab-secret
   Expires : 12 months
   → Copier la valeur IMMÉDIATEMENT (visible une seule fois)

5. Overview → Copier Application (client) ID et Directory (tenant) ID
```

### 3.2 Création via `Setup-MgGraphApp.ps1`

```powershell
# DryRun — affiche ce qui serait créé sans créer
.\docs\Setup-MgGraphApp.ps1 -DryRun

# Création réelle (nécessite droits Global Admin ou Application Admin)
.\docs\Setup-MgGraphApp.ps1 -DryRun:$false -AppName "iam-ma-integration-lab"

# Sortie : fichier .env avec ClientId, TenantId, ClientSecret
```

### 3.3 Connexion avec l'App Registration

```powershell
# Charger les paramètres depuis le fichier .env
$env = Get-Content ".\.env" | ConvertFrom-StringData
$clientId    = $env.GRAPH_CLIENT_ID
$tenantId    = $env.GRAPH_TENANT_ID
$secret      = $env.GRAPH_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$credential  = New-Object System.Management.Automation.PSCredential($clientId, $secret)

# Connexion non-interactive
Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId

# Vérification
Get-MgContext
```

---

## 4. Scopes nécessaires par script

| Script | Scopes minimaux | Mode |
|---|---|---|
| `Audit-PreMigrationChecklist.ps1` | `User.Read.All`, `Group.Read.All` | Lecture |
| `Audit-IdentityDeduplication.ps1` | `User.Read.All` | Lecture |
| `Migrate-UsersToEntraID.ps1` (Shadow) | `User.ReadWrite.All`, `Group.ReadWrite.All`, `Directory.ReadWrite.All` | Écriture |
| `Migrate-UsersToEntraID.ps1` (J-Day) | `User.ReadWrite.All` | Écriture |
| `Audit-PostMigrationDelta.ps1` | `User.Read.All` | Lecture |
| `Audit-OrphanAccounts.ps1` | `User.Read.All`, `AuditLog.Read.All` | Lecture |
| `Audit-RBACConflicts.ps1` | `User.Read.All`, `Group.Read.All` | Lecture |
| `Audit-GuestAccounts.ps1` | `User.Read.All`, `AuditLog.Read.All` | Lecture |

**Principe de moindre privilège :** utiliser les scopes lecture seuls
pour les phases d'audit. N'activer les scopes d'écriture que pour
les exécutions de migration après validation complète.

---

## 5. Gestion sécurisée des credentials

### Ne jamais versionner les secrets

```bash
# .gitignore — ajouter ces entrées
.env
*.secret
*credentials*.csv
*-credentials_*.csv
phase3-migration-credentials_*.csv
```

### Fichier .env type

```bash
# .env — NE PAS VERSIONNER — ajouter au .gitignore
GRAPH_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
GRAPH_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
GRAPH_CLIENT_SECRET=your-secret-here
GRAPH_TARGET_DOMAIN=corpa.onmicrosoft.com
```

### Rotation des secrets

Le secret App Registration doit être renouvelé avant expiration :

```powershell
# Alerter 30 jours avant expiration (à intégrer dans un monitoring)
$app = Get-MgApplication -Filter "DisplayName eq 'iam-ma-integration-lab'"
$expiringSecrets = $app.PasswordCredentials | Where-Object {
    $_.EndDateTime -lt (Get-Date).AddDays(30)
}
if ($expiringSecrets) {
    Write-Host "[ALERTE] Secret App Registration expire dans moins de 30 jours" -ForegroundColor Red
}
```

---

## 6. Erreurs fréquentes et solutions

### AADSTS700016 — Application not found in directory

```
Cause : Le ClientId ne correspond pas au tenant Entra ID connecté.
Solution : Vérifier que TenantId et ClientId sont bien ceux du tenant CorpA.
```

### AADSTS65001 — No consent for scopes

```
Cause : Le consentement admin n'a pas été accordé sur l'App Registration.
Solution : Portail Azure → App Registrations → iam-ma-integration-lab
           → API Permissions → Grant admin consent for [tenant]
```

### AADSTS70011 — Invalid scope

```
Cause : Un scope demandé n'est pas dans les permissions de l'App.
Solution : Ajouter le scope manquant dans API Permissions + regrant consent.
```

### Insufficient privileges to complete the operation

```
Cause : L'App Registration n'a pas les permissions d'écriture nécessaires.
Solution : Vérifier que User.ReadWrite.All et Directory.ReadWrite.All
           sont accordés (Application permissions, pas Delegated).
```

### Rate limit — 429 Too Many Requests

```
Cause : Trop d'appels Graph en parallèle (> 300 comptes en rafale).
Solution : Le script Migrate-UsersToEntraID.ps1 inclut un throttle
           de 100ms entre chaque appel. Si nécessaire, augmenter :
           Start-Sleep -Milliseconds 200
```

---

## 7. Vérification rapide de l'environnement

```powershell
# Script de diagnostic rapide (2 minutes)
# À exécuter avant toute phase live

Write-Host "=== Diagnostic environnement Graph ===" -ForegroundColor Cyan

# 1. Version PowerShell
Write-Host "PowerShell : $($PSVersionTable.PSVersion)"

# 2. Module Graph
$mgVersion = (Get-Module -ListAvailable Microsoft.Graph | Select-Object -First 1).Version
Write-Host "Microsoft.Graph : $mgVersion"

# 3. Connexion active
$ctx = Get-MgContext
if ($ctx) {
    Write-Host "Connexion : OK — $($ctx.Account) sur $($ctx.TenantId)" -ForegroundColor Green
    Write-Host "Scopes actifs : $($ctx.Scopes -join ', ')"
} else {
    Write-Host "Connexion : NON CONNECTÉ" -ForegroundColor Red
    Write-Host "Exécuter : Connect-MgGraph -Scopes 'User.Read.All'"
}

# 4. Test lecture simple
try {
    $count = (Get-MgUser -Top 1 -ErrorAction Stop).Count
    Write-Host "Lecture Entra ID : OK" -ForegroundColor Green
} catch {
    Write-Host "Lecture Entra ID : ERREUR — $_" -ForegroundColor Red
}
```

---

*PREREQUISITES-GRAPH.md — `iam-ma-integration-lab` — IAM-Lab Framework*
