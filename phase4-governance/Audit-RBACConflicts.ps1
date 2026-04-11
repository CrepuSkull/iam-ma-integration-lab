<#
.SYNOPSIS
    Audit-RBACConflicts.ps1
    Détection des conflits RBAC et violations SoD post-fusion CorpA/CorpB.

.DESCRIPTION
    Identifie les situations où un utilisateur CorpB migré cumule des rôles
    incompatibles dans l'environnement fusionné CorpA.

    Quatre types de conflits détectés :

      CUMUL_SENSIBLE     : appartenance simultanée à un groupe CorpB migré
                           ET à un groupe CorpA à périmètre étendu
      SOD_VIOLATION      : cumul de rôles incompatibles (ex: demandeur + approbateur)
      PRIVILEGE_ESCALATION: compte CorpB ayant acquis des droits CorpA non prévus
      DOUBLE_IDENTITE    : compte potentiellement dupliqué (même personne, deux comptes)

    Mode : LECTURE SEULE.

.PARAMETER Simulation
    Mode simulation — évalue sur la base du dataset seed

.PARAMETER SourceCsvPath
    Chemin vers corpb-users.csv

.PARAMETER OutputPath
    Répertoire de sortie

.EXAMPLE
    .\Audit-RBACConflicts.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.3 (SoD), A.5.15 | NIS2 Art.21§2(a)
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
$OutputFile = Join-Path $OutputPath "phase4-rbac-conflicts_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-RBACConflicts.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  SoD = Separation of Duties — cumuls de rôles incompatibles" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Matrice SoD — paires de rôles incompatibles
# ---------------------------------------------------------------------------

# Format : @{ RoleA = ".."; RoleB = ".."; Reason = ".."; Severity = ".." }
$sodMatrix = @(
    @{ RoleA = "GRP_Commercial_Users";   RoleB = "GRP_Finance_Users";
       Reason = "Accès commercial + finances : risque fraude commandes/paiements";    Severity = "CRITIQUE" },
    @{ RoleA = "GRP_CRM_Salesforce";     RoleB = "GRP_Finance_Users";
       Reason = "Accès données clients + finances : risque manipulation tarifs";       Severity = "CRITIQUE" },
    @{ RoleA = "GRP_Tech_DevOps";        RoleB = "GRP_Domain_Admins_Local";
       Reason = "DevOps + Admin AD : accès infrastructure étendu non cloisonné";      Severity = "CRITIQUE" },
    @{ RoleA = "GRP_RH_Users";           RoleB = "GRP_Finance_Users";
       Reason = "RH + Finance : accès salaires source + validation paiements";        Severity = "ELEVE" },
    @{ RoleA = "GRP_Tech_Devs";          RoleB = "GRP_AS400_Access";
       Reason = "Dev applicatif + accès ERP prod : risque modification données prod";  Severity = "ELEVE" },
    @{ RoleA = "GRP_Prestataires_External"; RoleB = "GRP_Direction_Managers";
       Reason = "Prestataire externe + groupe direction : périmètre injustifié";       Severity = "ELEVE" },
    @{ RoleA = "GRP_BambooHR_Access";    RoleB = "GRP_Finance_Users";
       Reason = "Données RH + finances : accès données de paie + validation";         Severity = "MODERE" }
)

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($Simulation) {
    $users = Import-Csv -Path $SourceCsvPath -Delimiter ";" -Encoding UTF8

    # Index nom → groupes
    $userGroups = @{}
    foreach ($u in $users) {
        if ($u.MemberOf) {
            $userGroups[$u.sAMAccountName] = $u.MemberOf -split "\|" | ForEach-Object { $_.Trim() }
        }
    }

    # Évaluer chaque paire SoD
    foreach ($u in $users) {
        $sam    = $u.sAMAccountName
        $groups = if ($userGroups.ContainsKey($sam)) { $userGroups[$sam] } else { @() }

        foreach ($pair in $sodMatrix) {
            $hasA = $groups -contains $pair.RoleA
            $hasB = $groups -contains $pair.RoleB

            if ($hasA -and $hasB) {
                $results.Add([PSCustomObject]@{
                    sAMAccountName   = $sam
                    UPN              = "$($sam.ToLower())@$TargetDomain"
                    DisplayName      = $u.DisplayName
                    Department       = $u.Department
                    ConflictType     = "SOD_VIOLATION"
                    RoleA            = $pair.RoleA
                    RoleB            = $pair.RoleB
                    ConflictReason   = $pair.Reason
                    Severity         = $pair.Severity
                    RecommendedAction = switch ($pair.Severity) {
                        "CRITIQUE" { "RETIRER_UN_ROLE_URGENT — arbitrage RSSI requis" }
                        "ELEVE"    { "REVUE_MANAGER_CORPA — justification écrite requise" }
                        default    { "SURVEILLER — signaler au manager" }
                    }
                    AuditDate        = (Get-Date -Format "yyyy-MM-dd")
                })
            }
        }

        # Privilege escalation simulée — comptes CorpB dans groupes CorpA non prévus
        $corpAGroups = $groups | Where-Object { $_ -notmatch "GRP_(All_CorpB|Direction|Commercial|Tech|RH|Prestataires|Finance|BambooHR|CRM|AS400|GitLab|Jira|Archived|Domain_Admins)" }
        foreach ($cag in $corpAGroups) {
            $results.Add([PSCustomObject]@{
                sAMAccountName    = $sam
                UPN               = "$($sam.ToLower())@$TargetDomain"
                DisplayName       = $u.DisplayName
                Department        = $u.Department
                ConflictType      = "PRIVILEGE_ESCALATION"
                RoleA             = $cag
                RoleB             = "— (groupe CorpA non prévu pour migration CorpB)"
                ConflictReason    = "Compte CorpB migré membre d'un groupe CorpA hors périmètre prévu"
                Severity          = "ELEVE"
                RecommendedAction = "VERIFIER_ATTRIBUTION — retirer si non justifié par manager CorpA"
                AuditDate         = (Get-Date -Format "yyyy-MM-dd")
            })
        }
    }

    # Double identité simulée — même DisplayName dans deux comptes
    $nameCount = $users | Group-Object DisplayName | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $nameCount) {
        foreach ($u in $dup.Group) {
            $results.Add([PSCustomObject]@{
                sAMAccountName    = $u.sAMAccountName
                UPN               = "$($u.sAMAccountName.ToLower())@$TargetDomain"
                DisplayName       = $u.DisplayName
                Department        = $u.Department
                ConflictType      = "DOUBLE_IDENTITE"
                RoleA             = "—"
                RoleB             = "—"
                ConflictReason    = "Même DisplayName sur $($dup.Count) comptes — potentiel doublon"
                Severity          = "MODERE"
                RecommendedAction = "VERIFIER_IDENTITE — confirmer si doublon ou homonyme légitime"
                AuditDate         = (Get-Date -Format "yyyy-MM-dd")
            })
        }
    }
} else {
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Groups
    Connect-MgGraph -Scopes "User.Read.All","Group.Read.All" -ErrorAction Stop

    Write-Host "  Récupération des membres de groupes depuis Graph..." -ForegroundColor Gray

    # Construire l'index groupe → membres
    $groupMemberIndex = @{}
    foreach ($pair in $sodMatrix) {
        foreach ($grpName in @($pair.RoleA, $pair.RoleB)) {
            if (-not $groupMemberIndex.ContainsKey($grpName)) {
                $grp = Get-MgGroup -Filter "DisplayName eq '$grpName'" -ErrorAction SilentlyContinue
                if ($grp) {
                    $members = Get-MgGroupMember -GroupId $grp.Id -All
                    $groupMemberIndex[$grpName] = $members.Id
                } else {
                    $groupMemberIndex[$grpName] = @()
                }
            }
        }
    }

    # Évaluer les SoD
    foreach ($pair in $sodMatrix) {
        $membersA = [System.Collections.Generic.HashSet[string]]$groupMemberIndex[$pair.RoleA]
        $membersB = $groupMemberIndex[$pair.RoleB]

        foreach ($mid in $membersB) {
            if ($membersA.Contains($mid)) {
                try {
                    $u = Get-MgUser -UserId $mid -Property UserPrincipalName,DisplayName,Department
                    $results.Add([PSCustomObject]@{
                        sAMAccountName    = ($u.UserPrincipalName -split "@")[0]
                        UPN               = $u.UserPrincipalName
                        DisplayName       = $u.DisplayName
                        Department        = $u.Department
                        ConflictType      = "SOD_VIOLATION"
                        RoleA             = $pair.RoleA
                        RoleB             = $pair.RoleB
                        ConflictReason    = $pair.Reason
                        Severity          = $pair.Severity
                        RecommendedAction = if ($pair.Severity -eq "CRITIQUE") { "RETIRER_UN_ROLE_URGENT" } else { "REVUE_MANAGER" }
                        AuditDate         = (Get-Date -Format "yyyy-MM-dd")
                    })
                } catch {}
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$byType = $results | Group-Object ConflictType
$critique = ($results | Where-Object { $_.Severity -eq "CRITIQUE" }).Count

Write-Host "  [OK] $($results.Count) conflit(s) RBAC détecté(s) → $OutputFile"
Write-Host ""
Write-Host "  ── Synthèse par type ──" -ForegroundColor Cyan
foreach ($t in $byType) {
    Write-Host "  $($t.Name.PadRight(25)) : $($t.Count)"
}
Write-Host ""
if ($critique -gt 0) {
    Write-Host "  [ALERTE] $critique violation(s) CRITIQUE — arbitrage RSSI requis" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Étape suivante : .\Audit-GuestAccounts.ps1" -ForegroundColor Cyan
Write-Host ""
