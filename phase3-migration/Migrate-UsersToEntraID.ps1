<#
.SYNOPSIS
    Migrate-UsersToEntraID.ps1
    Provisioning des identités CorpB vers le tenant Entra ID CorpA.

.DESCRIPTION
    Provisionne les comptes AD CorpB dans Entra ID CorpA via Microsoft Graph.
    Trois modes d'exécution séquentiels :

      DryRun        : simulation complète — aucun appel Graph
      ShadowMode    : provisioning réel — comptes créés mais désactivés
      Activation    : activation des comptes Shadow (J-Day)

    MAPPING D'ATTRIBUTS AD → ENTRA ID :
      sAMAccountName     → mailNickname + UPN prefix
      DisplayName        → displayName
      GivenName/Surname  → givenName / surname
      Department         → department
      Title              → jobTitle
      EmailAddress       → mail + UPN (@TargetDomain)

    Mot de passe temporaire généré aléatoirement par compte.
    Changement obligatoire à la première connexion.

.PARAMETER CsvPath
    Chemin vers corpb-users.csv (comptes à migrer — Enabled=TRUE uniquement)

.PARAMETER DryRun
    Simulation sans écriture Entra ID (défaut : $true)

.PARAMETER ShadowMode
    Provisionne les comptes désactivés dans Entra ID (sans bascule)

.PARAMETER ActivateShadowAccounts
    Active les comptes déjà provisionnés en Shadow Mode (J-Day)

.PARAMETER TargetDomain
    Domaine UPN cible (ex: corpa.onmicrosoft.com)

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    # Simulation
    .\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" -DryRun

.EXAMPLE
    # Shadow Mode — provisioning sans activation
    .\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" `
        -DryRun:$false -ShadowMode -TargetDomain "corpa.onmicrosoft.com"

.EXAMPLE
    # J-Day — activation des comptes Shadow
    .\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" `
        -DryRun:$false -ActivateShadowAccounts -TargetDomain "corpa.onmicrosoft.com"

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / phase3-migration
    Mapping réglementaire : ISO 27001:2022 A.5.16, A.5.18 | NIS2 Art.21§2(i) | RGPD Art.25, Art.28
    Prérequis : Install-Module Microsoft.Graph -Scope CurrentUser
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [switch]$ShadowMode,

    [Parameter()]
    [switch]$ActivateShadowAccounts,

    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [string]$OutputPath = "..\reports\"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$ExecutionLog   = Join-Path $OutputPath "phase3-migration-execution_$Timestamp.csv"
$CredentialFile = Join-Path $OutputPath "phase3-migration-credentials_$Timestamp.csv"
$RollbackFile   = Join-Path $OutputPath "phase3-migration-rollback_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# Déterminer le mode opératoire
$operationMode = if ($DryRun) { "DRYRUN" }
                 elseif ($ActivateShadowAccounts) { "ACTIVATION_JDAY" }
                 elseif ($ShadowMode) { "SHADOW_MODE" }
                 else { "DRYRUN" }   # sécurité — DryRun si aucun flag

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

$modeColor = switch ($operationMode) {
    "DRYRUN"          { "Yellow" }
    "SHADOW_MODE"     { "Cyan" }
    "ACTIVATION_JDAY" { "Red" }
    default           { "Yellow" }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $modeColor
Write-Host "  Migrate-UsersToEntraID.ps1" -ForegroundColor White
Write-Host "  Mode          : $operationMode" -ForegroundColor $modeColor
Write-Host "  Tenant cible  : $TargetDomain" -ForegroundColor Gray
Write-Host "  Source CSV    : $CsvPath" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $modeColor

if ($operationMode -eq "ACTIVATION_JDAY") {
    Write-Host ""
    Write-Host "  ⚠  J-DAY : activation des comptes Shadow — bascule irréversible sans rollback script" -ForegroundColor Red
    Write-Host "     Confirmer que Audit-PostMigrationDelta.ps1 a été exécuté et que le delta = 0" -ForegroundColor Red
}
Write-Host ""

# ---------------------------------------------------------------------------
# Chargement et filtrage
# ---------------------------------------------------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "  [ERROR] CSV introuvable : $CsvPath" -ForegroundColor Red; exit 1
}

$allUsers = Import-Csv -Path $CsvPath -Delimiter ";" -Encoding UTF8

# Filtres : uniquement comptes actifs, non de service (les comptes de service
# font l'objet d'un traitement manuel distinct — hors périmètre migration automatique)
$toMigrate = $allUsers | Where-Object {
    $_.Enabled -eq "TRUE" -and
    $_.IsServiceAccount -eq "FALSE" -and
    $_.IsStale -eq "FALSE"
}

$excluded = $allUsers.Count - $toMigrate.Count

Write-Host "  Total comptes CSV          : $($allUsers.Count)"
Write-Host "  Éligibles à migration      : $($toMigrate.Count)" -ForegroundColor Cyan
Write-Host "  Exclus (service/stale/off) : $excluded" -ForegroundColor Gray
Write-Host ""

if ($toMigrate.Count -eq 0) {
    Write-Host "  Aucun compte éligible à migrer." -ForegroundColor Gray; exit 0
}

# ---------------------------------------------------------------------------
# Connexion Graph (mode réel uniquement)
# ---------------------------------------------------------------------------

if ($operationMode -ne "DRYRUN") {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "  [ERROR] Module Microsoft.Graph requis : Install-Module Microsoft.Graph" -ForegroundColor Red
        exit 1
    }

    Write-Host "  Connexion à Microsoft Graph..." -ForegroundColor Gray
    try {
        $scopes = @("User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All")
        Connect-MgGraph -Scopes $scopes -ErrorAction Stop
        Write-Host "  [OK] Connecté à Graph ($TargetDomain)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Connexion Graph échouée : $_" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Générateur de mot de passe temporaire
# ---------------------------------------------------------------------------

function New-TempPassword {
    $chars  = "abcdefghijkmnpqrstuvwxyz"
    $upper  = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $digits = "23456789"
    $special= "@#$!%"
    $pwd = ""
    $pwd += ($upper  | Get-Random -Count 2) -join ""
    $pwd += ($chars  | Get-Random -Count 5) -join ""
    $pwd += ($digits | Get-Random -Count 2) -join ""
    $pwd += ($special | Get-Random -Count 1)
    # Mélanger
    return (-join (($pwd.ToCharArray() | Get-Random -Count $pwd.Length)))
}

# ---------------------------------------------------------------------------
# Mapping attributs AD → Entra ID
# ---------------------------------------------------------------------------

function ConvertTo-EntraUser {
    param($Row, [string]$Domain, [string]$TempPwd, [bool]$AccountEnabled)

    $sam = $Row.sAMAccountName.Trim().ToLower()
    $upn = "$sam@$Domain"

    # Département CorpB → groupe Entra ID CorpA (mapping M&A)
    $deptGroupMap = @{
        "Direction"    = "GRP_CorpB_Direction_Migrated"
        "Commercial"   = "GRP_CorpB_Commercial_Migrated"
        "Technique"    = "GRP_CorpB_Technique_Migrated"
        "RH"           = "GRP_CorpB_RH_Migrated"
        "Prestataires" = "GRP_CorpB_Prestataires_Migrated"
        "ServiceCompt" = "GRP_CorpB_Finance_Migrated"
        "Archived"     = ""
    }

    return @{
        UserPrincipalName   = $upn
        DisplayName         = $Row.DisplayName
        GivenName           = $Row.GivenName
        Surname             = $Row.Surname
        MailNickname        = $sam
        JobTitle            = $Row.Title
        Department          = $Row.Department
        Mail                = $Row.EmailAddress
        AccountEnabled      = $AccountEnabled
        PasswordProfile     = @{
            Password                      = $TempPwd
            ForceChangePasswordNextSignIn = $true
        }
        UsageLocation       = "FR"
        # Extension attribute — traçabilité source M&A
        OnPremisesSamAccountName = $Row.sAMAccountName
        TargetGroup         = if ($deptGroupMap.ContainsKey($Row.Department)) { $deptGroupMap[$Row.Department] } else { "GRP_CorpB_Misc_Migrated" }
    }
}

# ---------------------------------------------------------------------------
# Exécution
# ---------------------------------------------------------------------------

$executionLog   = [System.Collections.Generic.List[PSCustomObject]]::new()
$credentialLog  = [System.Collections.Generic.List[PSCustomObject]]::new()
$rollbackLog    = [System.Collections.Generic.List[PSCustomObject]]::new()

$stats = @{
    Created     = 0
    Activated   = 0
    Skipped     = 0
    Errors      = 0
    DryRun      = 0
}

foreach ($user in $toMigrate) {
    $sam     = $user.sAMAccountName.Trim()
    $tempPwd = New-TempPassword
    $upn     = "$($sam.ToLower())@$TargetDomain"

    $accountEnabled = switch ($operationMode) {
        "SHADOW_MODE"     { $false }   # Shadow = désactivé
        "ACTIVATION_JDAY" { $true  }   # J-Day  = activé
        default           { $false }
    }

    if ($operationMode -eq "DRYRUN") {
        $entraUser = ConvertTo-EntraUser -Row $user -Domain $TargetDomain -TempPwd $tempPwd -AccountEnabled $false
        Write-Host "  [DRYRUN] PROVISION : $upn  [$($user.Department)] Shadow=$(-not $accountEnabled)" -ForegroundColor Yellow
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; UPN = $upn; Department = $user.Department
            Action = "PROVISION_SHADOW"; Status = "DRYRUN"; AccountEnabled = $false
            TargetGroup = $entraUser.TargetGroup
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Simulation"
        })
        $stats.DryRun++
        continue
    }

    if ($operationMode -eq "ACTIVATION_JDAY") {
        # Chercher le compte existant et l'activer
        try {
            $existing = Get-MgUser -Filter "UserPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            if ($existing) {
                Update-MgUser -UserId $existing.Id -AccountEnabled $true
                Write-Host "  [OK] ACTIVÉ : $upn" -ForegroundColor Green
                $executionLog.Add([PSCustomObject]@{
                    sAMAccountName = $sam; UPN = $upn; Department = $user.Department
                    Action = "ACTIVATE"; Status = "SUCCESS"; AccountEnabled = $true
                    Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "J-Day activation"
                })
                $stats.Activated++
            } else {
                Write-Host "  [WARN] Compte Shadow introuvable : $upn" -ForegroundColor Yellow
                $stats.Skipped++
            }
        } catch {
            Write-Host "  [ERROR] Activation $upn : $_" -ForegroundColor Red
            $stats.Errors++
        }
        continue
    }

    # SHADOW_MODE — provisioning réel désactivé
    try {
        # Vérifier si le compte existe déjà
        $existing = Get-MgUser -Filter "UserPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "  [SKIP] Existe déjà : $upn" -ForegroundColor Gray
            $executionLog.Add([PSCustomObject]@{
                sAMAccountName = $sam; UPN = $upn; Department = $user.Department
                Action = "PROVISION"; Status = "ALREADY_EXISTS"; AccountEnabled = $existing.AccountEnabled
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Compte déjà présent"
            })
            $stats.Skipped++
            continue
        }

        $entraUser = ConvertTo-EntraUser -Row $user -Domain $TargetDomain -TempPwd $tempPwd -AccountEnabled $false

        # Créer l'utilisateur
        $params = @{
            UserPrincipalName = $entraUser.UserPrincipalName
            DisplayName       = $entraUser.DisplayName
            GivenName         = $entraUser.GivenName
            Surname           = $entraUser.Surname
            MailNickname      = $entraUser.MailNickname
            JobTitle          = $entraUser.JobTitle
            Department        = $entraUser.Department
            Mail              = $entraUser.Mail
            AccountEnabled    = $false
            PasswordProfile   = $entraUser.PasswordProfile
            UsageLocation     = "FR"
        }

        $newUser = New-MgUser @params

        # Ajouter au groupe de migration
        if ($entraUser.TargetGroup) {
            try {
                $grp = Get-MgGroup -Filter "DisplayName eq '$($entraUser.TargetGroup)'" -ErrorAction SilentlyContinue
                if ($grp) {
                    New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $newUser.Id
                }
            } catch { <# Groupe non encore créé — ignorer en lab #> }
        }

        Write-Host "  [OK] PROVISIONNÉ (Shadow) : $upn" -ForegroundColor Cyan
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; UPN = $upn; Department = $user.Department
            Action = "PROVISION_SHADOW"; Status = "SUCCESS"; AccountEnabled = $false
            TargetGroup = $entraUser.TargetGroup
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = "Shadow — désactivé"
        })
        $credentialLog.Add([PSCustomObject]@{
            UPN              = $upn
            DisplayName      = $user.DisplayName
            TempPassword     = $tempPwd
            MustChangePwd    = "OUI"
            MFARequired      = "OUI — à configurer à la première connexion"
            Timestamp        = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })
        $rollbackLog.Add([PSCustomObject]@{
            UPN             = $upn
            RollbackCommand = "Remove-MgUser -UserId '$($newUser.Id)'"
            Timestamp       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })
        $stats.Created++

    } catch {
        Write-Host "  [ERROR] $upn : $_" -ForegroundColor Red
        $executionLog.Add([PSCustomObject]@{
            sAMAccountName = $sam; UPN = $upn; Department = $user.Department
            Action = "PROVISION"; Status = "ERROR"; AccountEnabled = $false
            Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Detail = $_.Exception.Message
        })
        $stats.Errors++
    }
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

$executionLog | Export-Csv -Path $ExecutionLog -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host ""
Write-Host "  [OK] Log d'exécution : $ExecutionLog" -ForegroundColor Gray

if ($credentialLog.Count -gt 0) {
    $credentialLog | Export-Csv -Path $CredentialFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host "  [OK] Mots de passe temporaires : $CredentialFile" -ForegroundColor Yellow
    Write-Host "       → Fichier SENSIBLE — à chiffrer et à ne pas versionner" -ForegroundColor Red
}
if ($rollbackLog.Count -gt 0) {
    $rollbackLog | Export-Csv -Path $RollbackFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host "  [OK] Rollback : $RollbackFile" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Synthèse
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  Mode : $operationMode"

if ($operationMode -eq "DRYRUN") {
    Write-Host "  Simulés          : $($stats.DryRun)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Commande Shadow Mode :" -ForegroundColor Gray
    Write-Host "  .\Migrate-UsersToEntraID.ps1 -CsvPath '$CsvPath' -DryRun:`$false -ShadowMode -TargetDomain '$TargetDomain'" -ForegroundColor Gray
} elseif ($operationMode -eq "SHADOW_MODE") {
    Write-Host "  Provisionnés (Shadow) : $($stats.Created)" -ForegroundColor Cyan
    Write-Host "  Déjà existants        : $($stats.Skipped)" -ForegroundColor Gray
    Write-Host "  Erreurs               : $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
    Write-Host ""
    Write-Host "  Étape suivante : Audit-PostMigrationDelta.ps1" -ForegroundColor Cyan
    Write-Host "  Puis J-Day     : -ActivateShadowAccounts" -ForegroundColor Cyan
} elseif ($operationMode -eq "ACTIVATION_JDAY") {
    Write-Host "  Activés (J-Day)  : $($stats.Activated)" -ForegroundColor Green
    Write-Host "  Introuvables     : $($stats.Skipped)" -ForegroundColor Yellow
    Write-Host "  Erreurs          : $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })
    Write-Host ""
    Write-Host "  J-Day terminé. Désactiver les comptes AD source CorpB." -ForegroundColor Green
    Write-Host "  Étape suivante : Phase 4 — Gouvernance" -ForegroundColor Cyan
}

Write-Host ""
