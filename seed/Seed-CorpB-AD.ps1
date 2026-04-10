<#
.SYNOPSIS
    Seed-CorpB-AD.ps1
    Génération de l'environnement Active Directory fictif CorpB pour le lab IAM M&A.

.DESCRIPTION
    Ce script crée dans un AD de lab :
      - 2 domaines simulés via 2 racines d'OU distinctes (corpb.local / legacy.corpb.local)
      - 7 unités organisationnelles (OU)
      - 18 groupes de sécurité
      - 312 comptes utilisateurs depuis corpb-users.csv
    
    Utilisé exclusivement en environnement de lab. Ne jamais exécuter en production.

    Prérequis :
      - Windows Server avec rôle AD DS installé (ou RSAT sur poste admin)
      - PowerShell 5.1+ avec module ActiveDirectory
      - Fichier corpb-users.csv dans le même répertoire
      - Droits Domain Admin sur le domaine cible du lab

    Paramètres :
      -DryRun       Simule toutes les actions sans écriture AD (défaut : $true)
      -CsvPath      Chemin vers corpb-users.csv (défaut : .\corpb-users.csv)
      -TargetOU     OU racine dans laquelle créer la structure CorpB (défaut : "OU=CorpB-Lab,DC=lab,DC=local")
      -LogPath      Chemin du fichier log (défaut : .\seed-log.csv)

.EXAMPLE
    # Simulation complète (aucune écriture)
    .\Seed-CorpB-AD.ps1 -DryRun

.EXAMPLE
    # Exécution réelle sur un DC de lab
    .\Seed-CorpB-AD.ps1 -DryRun:$false -TargetOU "OU=CorpB-Lab,DC=lab,DC=local"

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / seed
    Script de démonstration/test uniquement.
    Mapping réglementaire : ISO 27001:2022 A.5.15 — Cadre de référence documenté.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [string]$CsvPath = ".\corpb-users.csv",

    [Parameter()]
    [string]$TargetOU = "OU=CorpB-Lab,DC=lab,DC=local",

    [Parameter()]
    [string]$LogPath = ".\seed-log.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

function Write-Banner {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  IAM-Lab Framework — Seed-CorpB-AD.ps1" -ForegroundColor Cyan
    Write-Host "  Génération environnement AD fictif CorpB" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "  MODE : DRYRUN — Aucune écriture AD effectuée" -ForegroundColor Yellow
    } else {
        Write-Host "  MODE : EXECUTION REELLE — Ecriture AD activée" -ForegroundColor Red
    }
    Write-Host "  TargetOU : $TargetOU" -ForegroundColor Gray
    Write-Host "  CsvPath  : $CsvPath" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

$LogEntries = [System.Collections.Generic.List[PSCustomObject]]::new()

function Write-Log {
    param(
        [string]$Action,
        [string]$ObjectType,
        [string]$ObjectName,
        [string]$Status,
        [string]$Detail = ""
    )
    $entry = [PSCustomObject]@{
        Timestamp  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        DryRun     = $DryRun
        Action     = $Action
        ObjectType = $ObjectType
        ObjectName = $ObjectName
        Status     = $Status
        Detail     = $Detail
    }
    $LogEntries.Add($entry)

    $color = switch ($Status) {
        "OK"      { "Green" }
        "SKIP"    { "Gray" }
        "DRYRUN"  { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    Write-Host "  [$Status] $Action | $ObjectType : $ObjectName" -ForegroundColor $color
    if ($Detail) {
        Write-Host "         $Detail" -ForegroundColor DarkGray
    }
}

function Export-Log {
    $LogEntries | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host ""
    Write-Host "  Log exporté : $LogPath ($($LogEntries.Count) entrées)" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Vérifications préalables
# ---------------------------------------------------------------------------

function Test-Prerequisites {
    Write-Host "-- Vérification des prérequis --" -ForegroundColor Cyan

    # Module ActiveDirectory
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "  [ERROR] Module ActiveDirectory non disponible." -ForegroundColor Red
        Write-Host "          Installer RSAT ou exécuter depuis un DC." -ForegroundColor Red
        exit 1
    }
    Write-Log -Action "CHECK" -ObjectType "Module" -ObjectName "ActiveDirectory" -Status "OK"

    # Fichier CSV
    if (-not (Test-Path $CsvPath)) {
        Write-Host "  [ERROR] Fichier CSV introuvable : $CsvPath" -ForegroundColor Red
        Write-Host "          Exécuter generate-corpb-users.py pour le générer." -ForegroundColor Red
        exit 1
    }
    Write-Log -Action "CHECK" -ObjectType "File" -ObjectName $CsvPath -Status "OK"

    # Connectivité AD (uniquement si pas DryRun)
    if (-not $DryRun) {
        try {
            $null = Get-ADDomain
            Write-Log -Action "CHECK" -ObjectType "AD" -ObjectName "Domain" -Status "OK"
        } catch {
            Write-Host "  [ERROR] Impossible de joindre le domaine AD : $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Log -Action "CHECK" -ObjectType "AD" -ObjectName "Domain" -Status "DRYRUN" -Detail "Vérification AD ignorée en DryRun"
    }

    Write-Host ""
}

# ---------------------------------------------------------------------------
# Création de la structure OU
# ---------------------------------------------------------------------------

$OUStructure = @(
    # OU racine CorpB Lab
    @{ Name = "CorpB-Lab";         Path = "DC=lab,DC=local";                         Description = "Racine lab — environnement fictif CorpB" },
    # OUs domaine corpb.local
    @{ Name = "corpb.local";       Path = "OU=CorpB-Lab,DC=lab,DC=local";            Description = "Domaine principal CorpB" },
    @{ Name = "Direction";         Path = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Direction CorpB" },
    @{ Name = "Commercial";        Path = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Commercial CorpB" },
    @{ Name = "Technique";         Path = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Technique CorpB" },
    @{ Name = "RH";                Path = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Ressources Humaines CorpB" },
    # OUs domaine legacy.corpb.local
    @{ Name = "legacy.corpb.local";Path = "OU=CorpB-Lab,DC=lab,DC=local";            Description = "Domaine legacy CorpB (ancienne fusion)" },
    @{ Name = "Prestataires";      Path = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Prestataires externes" },
    @{ Name = "ServiceCompt";      Path = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU Service Comptabilité (legacy)" },
    @{ Name = "Archived";          Path = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Description = "OU comptes archivés — départs non traités" },
)

function New-OUStructure {
    Write-Host "-- Création de la structure OU --" -ForegroundColor Cyan

    foreach ($ou in $OUStructure) {
        $ouDN = "OU=$($ou.Name),$($ou.Path)"
        try {
            if ($DryRun) {
                Write-Log -Action "CREATE_OU" -ObjectType "OU" -ObjectName $ouDN -Status "DRYRUN"
            } else {
                $existing = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log -Action "CREATE_OU" -ObjectType "OU" -ObjectName $ouDN -Status "SKIP" -Detail "OU déjà existante"
                } else {
                    New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -Description $ou.Description
                    Write-Log -Action "CREATE_OU" -ObjectType "OU" -ObjectName $ouDN -Status "OK"
                }
            }
        } catch {
            Write-Log -Action "CREATE_OU" -ObjectType "OU" -ObjectName $ouDN -Status "ERROR" -Detail $_.Exception.Message
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Création des groupes de sécurité
# ---------------------------------------------------------------------------

$Groups = @(
    # Groupes corpb.local
    @{ Name = "GRP_All_CorpB";             OU = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";                  Scope = "Global"; Description = "Tous les utilisateurs CorpB" },
    @{ Name = "GRP_Direction_Managers";    OU = "OU=Direction,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "Managers direction CorpB" },
    @{ Name = "GRP_Commercial_Users";      OU = "OU=Commercial,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";    Scope = "Global"; Description = "Équipe commerciale CorpB" },
    @{ Name = "GRP_CRM_Salesforce";        OU = "OU=Commercial,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";    Scope = "Global"; Description = "Accès Salesforce CRM" },
    @{ Name = "GRP_Tech_Devs";             OU = "OU=Technique,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "Développeurs CorpB" },
    @{ Name = "GRP_Tech_DevOps";           OU = "OU=Technique,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "DevOps CorpB — accès infra" },
    @{ Name = "GRP_GitLab_Users";          OU = "OU=Technique,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "Accès GitLab CE" },
    @{ Name = "GRP_Jira_Agents";           OU = "OU=Technique,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "Agents Jira Cloud" },
    @{ Name = "GRP_RH_Users";             OU = "OU=RH,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";            Scope = "Global"; Description = "Équipe RH CorpB" },
    @{ Name = "GRP_BambooHR_Access";       OU = "OU=RH,OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";            Scope = "Global"; Description = "Accès BambooHR — données RH sensibles" },
    # Groupes legacy.corpb.local
    @{ Name = "GRP_Prestataires_External"; OU = "OU=Prestataires,OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Scope = "DomainLocal"; Description = "Prestataires externes CorpB" },
    @{ Name = "GRP_Finance_Users";         OU = "OU=ServiceCompt,OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Scope = "Global"; Description = "Service Comptabilité CorpB" },
    @{ Name = "GRP_AS400_Access";          OU = "OU=ServiceCompt,OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"; Scope = "Global"; Description = "Accès AS400 ERP — comptes de service partagés" },
    @{ Name = "GRP_Archived_Accounts";     OU = "OU=Archived,OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local";     Scope = "Global"; Description = "Comptes archivés — départs non traités" },
    # Groupes à risque (sans propriétaire documenté — simulé par absence de Description)
    @{ Name = "GRP_Domain_Admins_Local";   OU = "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local";                  Scope = "Global"; Description = "" },
    @{ Name = "GRP_Legacy_Sync";           OU = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local";           Scope = "DomainLocal"; Description = "" },
    @{ Name = "GRP_Old_VPN_Users";         OU = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local";           Scope = "Global"; Description = "" },
    @{ Name = "GRP_Temp_Project_2021";     OU = "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local";           Scope = "Global"; Description = "" },
)
# Groupes sans description = 4 groupes orphelins simulés (conforme au scénario)

function New-Groups {
    Write-Host "-- Création des groupes de sécurité ($($Groups.Count) groupes) --" -ForegroundColor Cyan

    foreach ($grp in $Groups) {
        try {
            if ($DryRun) {
                $orphan = if (-not $grp.Description) { " [ORPHELIN — sans description]" } else { "" }
                Write-Log -Action "CREATE_GROUP" -ObjectType "Group" -ObjectName $grp.Name -Status "DRYRUN" -Detail "$($grp.Scope)$orphan"
            } else {
                $existing = Get-ADGroup -Filter "Name -eq '$($grp.Name)'" -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log -Action "CREATE_GROUP" -ObjectType "Group" -ObjectName $grp.Name -Status "SKIP"
                } else {
                    $params = @{
                        Name            = $grp.Name
                        Path            = $grp.OU
                        GroupScope      = $grp.Scope
                        GroupCategory   = "Security"
                    }
                    if ($grp.Description) { $params.Description = $grp.Description }
                    New-ADGroup @params
                    Write-Log -Action "CREATE_GROUP" -ObjectType "Group" -ObjectName $grp.Name -Status "OK"
                }
            }
        } catch {
            Write-Log -Action "CREATE_GROUP" -ObjectType "Group" -ObjectName $grp.Name -Status "ERROR" -Detail $_.Exception.Message
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Import des utilisateurs depuis CSV
# ---------------------------------------------------------------------------

function Import-Users {
    param([array]$Users)

    Write-Host "-- Import des utilisateurs ($($Users.Count) comptes) --" -ForegroundColor Cyan

    $stats = @{ Created = 0; Skipped = 0; Errors = 0; DryRun = 0 }

    foreach ($user in $Users) {
        $sam = $user.sAMAccountName
        $upn = $user.UserPrincipalName
        $ou  = $user.OU

        # Reconstruire l'OU dans le contexte du lab (remplacer DC= par la cible lab)
        $labOU = $ou -replace "DC=corpb,DC=local",        "OU=corpb.local,OU=CorpB-Lab,DC=lab,DC=local" `
                     -replace "DC=legacy,DC=corpb,DC=local", "OU=legacy.corpb.local,OU=CorpB-Lab,DC=lab,DC=local"

        try {
            if ($DryRun) {
                $staleLabel = if ($user.IsStale -eq "TRUE") { " [STALE]" } else { "" }
                $privLabel  = if ($user.IsPrivileged -eq "TRUE") { " [PRIV]" } else { "" }
                $svcLabel   = if ($user.IsServiceAccount -eq "TRUE") { " [SVC]" } else { "" }
                Write-Log -Action "CREATE_USER" -ObjectType "User" -ObjectName $sam `
                    -Status "DRYRUN" -Detail "$($user.Department)$staleLabel$privLabel$svcLabel"
                $stats.DryRun++
            } else {
                $existing = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log -Action "CREATE_USER" -ObjectType "User" -ObjectName $sam -Status "SKIP"
                    $stats.Skipped++
                    continue
                }

                $enabled = ($user.Enabled -eq "TRUE")
                $pwdNeverExpires = ($user.PasswordNeverExpires -eq "TRUE")

                $params = @{
                    SamAccountName        = $sam
                    UserPrincipalName     = $upn
                    GivenName             = $user.GivenName
                    Surname               = $user.Surname
                    DisplayName           = $user.DisplayName
                    Title                 = $user.Title
                    Department            = $user.Department
                    EmailAddress          = $user.EmailAddress
                    Description           = $user.Description
                    Path                  = $labOU
                    AccountPassword       = (ConvertTo-SecureString "CorpB@Lab2024!" -AsPlainText -Force)
                    Enabled               = $enabled
                    PasswordNeverExpires  = $pwdNeverExpires
                    ChangePasswordAtLogon = $false
                }

                New-ADUser @params

                # Ajout aux groupes
                if ($user.MemberOf) {
                    foreach ($grpName in ($user.MemberOf -split "\|")) {
                        $grpName = $grpName.Trim()
                        if ($grpName) {
                            try {
                                Add-ADGroupMember -Identity $grpName -Members $sam -ErrorAction SilentlyContinue
                            } catch {
                                # Groupe potentiellement pas encore créé — ignorer en seed
                            }
                        }
                    }
                }

                Write-Log -Action "CREATE_USER" -ObjectType "User" -ObjectName $sam -Status "OK" -Detail $user.Department
                $stats.Created++
            }
        } catch {
            Write-Log -Action "CREATE_USER" -ObjectType "User" -ObjectName $sam -Status "ERROR" -Detail $_.Exception.Message
            $stats.Errors++
        }
    }

    Write-Host ""
    Write-Host "  Résumé import utilisateurs :" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "    DryRun (simulés) : $($stats.DryRun)" -ForegroundColor Yellow
    } else {
        Write-Host "    Créés   : $($stats.Created)" -ForegroundColor Green
        Write-Host "    Ignorés : $($stats.Skipped)" -ForegroundColor Gray
        Write-Host "    Erreurs : $($stats.Errors)" -ForegroundColor Red
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Rapport de synthèse
# ---------------------------------------------------------------------------

function Write-SeedSummary {
    param([array]$Users)

    $stale     = ($Users | Where-Object { $_.IsStale -eq "TRUE" }).Count
    $priv      = ($Users | Where-Object { $_.IsPrivileged -eq "TRUE" }).Count
    $svc       = ($Users | Where-Object { $_.IsServiceAccount -eq "TRUE" }).Count
    $disabled  = ($Users | Where-Object { $_.Enabled -eq "FALSE" }).Count
    $legacy    = ($Users | Where-Object { $_.Domain -like "*legacy*" }).Count
    $noDesc    = ($Groups | Where-Object { -not $_.Description }).Count

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  SYNTHÈSE DU SEED — Environnement CorpB" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Structure créée :" -ForegroundColor White
    Write-Host "    OUs              : $($OUStructure.Count)"
    Write-Host "    Groupes          : $($Groups.Count) (dont $noDesc sans description = orphelins)"
    Write-Host "    Utilisateurs     : $($Users.Count)"
    Write-Host ""
    Write-Host "  Profils à risque simulés :" -ForegroundColor Yellow
    Write-Host "    Comptes obsolètes (IsStale)     : $stale"
    Write-Host "    Comptes de service              : $svc"
    Write-Host "    Comptes privilégiés             : $priv"
    Write-Host "    Comptes désactivés              : $disabled"
    Write-Host "    Domaine legacy.corpb.local      : $legacy"
    Write-Host "    MFA activé                      : 0 (aucun sur CorpB AD)"
    Write-Host ""

    if ($DryRun) {
        Write-Host "  *** DRYRUN — Aucune écriture effectuée ***" -ForegroundColor Yellow
        Write-Host "  Pour exécuter le seed réel : .\Seed-CorpB-AD.ps1 -DryRun:`$false" -ForegroundColor Yellow
    } else {
        Write-Host "  Seed terminé. Vérifier avec :" -ForegroundColor Green
        Write-Host "    Get-ADUser -SearchBase '$TargetOU' -Filter * | Measure-Object"
        Write-Host "    Get-ADGroup -SearchBase '$TargetOU' -Filter * | Measure-Object"
    }

    Write-Host ""
    Write-Host "  Phase suivante : /phase1-audit/Audit-ADInventory.ps1" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------

Write-Banner
Test-Prerequisites

# Chargement du CSV
Write-Host "-- Chargement du fichier CSV --" -ForegroundColor Cyan
$users = Import-Csv -Path $CsvPath -Delimiter ";" -Encoding UTF8
Write-Log -Action "LOAD_CSV" -ObjectType "File" -ObjectName $CsvPath -Status "OK" -Detail "$($users.Count) enregistrements chargés"
Write-Host ""

# Exécution des étapes
New-OUStructure
New-Groups
Import-Users -Users $users

# Synthèse + export log
Write-SeedSummary -Users $users
Export-Log
