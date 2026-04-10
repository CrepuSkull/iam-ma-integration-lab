<#
.SYNOPSIS
    Audit-GroupMembership.ps1
    Cartographie des groupes de sécurité AD CorpB.

.DESCRIPTION
    Produit deux vues complémentaires :
      - Vue groupes : liste des groupes avec membres, propriétaire, statut orphelin
      - Vue membres : liste des utilisateurs avec tous leurs groupes d'appartenance

    Détecte les groupes orphelins (sans description = sans propriétaire documenté),
    les groupes vides, et les membres inactifs.

    Mode : LECTURE SEULE.

.EXAMPLE
    .\Audit-GroupMembership.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.5.15 | NIS2 Art.21§2(i)
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

$Timestamp       = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputGroups    = Join-Path $OutputPath "phase1-groups_$Timestamp.csv"
$OutputMembers   = Join-Path $OutputPath "phase1-group-members_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-GroupMembership.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan

# Définition des groupes simulés (cohérence avec Seed-CorpB-AD.ps1)
$SimulatedGroups = @(
    @{ Name="GRP_All_CorpB";             Scope="Global";      Description="Tous les utilisateurs CorpB";      Orphan=$false },
    @{ Name="GRP_Direction_Managers";    Scope="Global";      Description="Managers direction CorpB";         Orphan=$false },
    @{ Name="GRP_Commercial_Users";      Scope="Global";      Description="Équipe commerciale CorpB";         Orphan=$false },
    @{ Name="GRP_CRM_Salesforce";        Scope="Global";      Description="Accès Salesforce CRM";             Orphan=$false },
    @{ Name="GRP_Tech_Devs";             Scope="Global";      Description="Développeurs CorpB";               Orphan=$false },
    @{ Name="GRP_Tech_DevOps";           Scope="Global";      Description="DevOps CorpB";                     Orphan=$false },
    @{ Name="GRP_GitLab_Users";          Scope="Global";      Description="Accès GitLab CE";                  Orphan=$false },
    @{ Name="GRP_Jira_Agents";           Scope="Global";      Description="Agents Jira Cloud";                Orphan=$false },
    @{ Name="GRP_RH_Users";              Scope="Global";      Description="Équipe RH CorpB";                  Orphan=$false },
    @{ Name="GRP_BambooHR_Access";       Scope="Global";      Description="Accès BambooHR";                   Orphan=$false },
    @{ Name="GRP_Prestataires_External"; Scope="DomainLocal"; Description="Prestataires externes CorpB";      Orphan=$false },
    @{ Name="GRP_Finance_Users";         Scope="Global";      Description="Service Comptabilité CorpB";       Orphan=$false },
    @{ Name="GRP_AS400_Access";          Scope="Global";      Description="Accès AS400 ERP";                  Orphan=$false },
    @{ Name="GRP_Archived_Accounts";     Scope="Global";      Description="Comptes archivés";                 Orphan=$false },
    # Groupes orphelins simulés (sans description)
    @{ Name="GRP_Domain_Admins_Local";   Scope="Global";      Description="";  Orphan=$true },
    @{ Name="GRP_Legacy_Sync";           Scope="DomainLocal"; Description="";  Orphan=$true },
    @{ Name="GRP_Old_VPN_Users";         Scope="Global";      Description="";  Orphan=$true },
    @{ Name="GRP_Temp_Project_2021";     Scope="Global";      Description="";  Orphan=$true },
)

$groupResults  = @()
$memberResults = @()

if ($Simulation) {
    $users = Import-Csv -Path $SimulationCsvPath -Delimiter ";" -Encoding UTF8

    # Construire l'index groupe → membres
    $groupMemberIndex = @{}
    foreach ($grp in $SimulatedGroups) {
        $groupMemberIndex[$grp.Name] = @()
    }

    foreach ($u in $users) {
        if ($u.MemberOf) {
            foreach ($grpName in ($u.MemberOf -split "\|" | ForEach-Object { $_.Trim() })) {
                if ($groupMemberIndex.ContainsKey($grpName)) {
                    $groupMemberIndex[$grpName] += $u.sAMAccountName
                }
            }
        }
    }

    # Vue groupes
    foreach ($grp in $SimulatedGroups) {
        $members     = $groupMemberIndex[$grp.Name]
        $memberCount = $members.Count
        $isEmpty     = $memberCount -eq 0
        $isOrphan    = $grp.Orphan -or [string]::IsNullOrWhiteSpace($grp.Description)

        $riskLevel = "FAIBLE"
        if ($isOrphan -and $memberCount -gt 0) { $riskLevel = "CRITIQUE" }
        elseif ($isOrphan)                      { $riskLevel = "ELEVE" }
        elseif ($isEmpty)                       { $riskLevel = "MODERE" }

        $groupResults += [PSCustomObject]@{
            GroupName        = $grp.Name
            Scope            = $grp.Scope
            Description      = $grp.Description
            IsOrphan         = if ($isOrphan) { "OUI" } else { "NON" }
            IsEmpty          = if ($isEmpty) { "OUI" } else { "NON" }
            MemberCount      = $memberCount
            Members          = ($members -join " | ")
            RiskLevel        = $riskLevel
            RecommendedAction = switch ($riskLevel) {
                "CRITIQUE" { "DOCUMENTER_PROPRIETAIRE_URGENT" }
                "ELEVE"    { "DOCUMENTER_OU_SUPPRIMER" }
                "MODERE"   { "SUPPRIMER_SI_INUTILE" }
                default    { "VALIDER_MAINTIEN" }
            }
            AuditDate        = (Get-Date -Format "yyyy-MM-dd")
        }
    }

    # Vue membres — un utilisateur par groupe
    foreach ($u in $users) {
        if ($u.MemberOf) {
            foreach ($grpName in ($u.MemberOf -split "\|" | ForEach-Object { $_.Trim() })) {
                $grpMeta = $SimulatedGroups | Where-Object { $_.Name -eq $grpName } | Select-Object -First 1
                $memberResults += [PSCustomObject]@{
                    sAMAccountName = $u.sAMAccountName
                    DisplayName    = $u.DisplayName
                    Department     = $u.Department
                    Domain         = $u.Domain
                    Enabled        = $u.Enabled
                    IsStale        = $u.IsStale
                    GroupName      = $grpName
                    GroupScope     = if ($grpMeta) { $grpMeta.Scope } else { "?" }
                    GroupIsOrphan  = if ($grpMeta -and $grpMeta.Orphan) { "OUI" } else { "NON" }
                    AuditDate      = (Get-Date -Format "yyyy-MM-dd")
                }
            }
        }
    }

} else {
    Import-Module ActiveDirectory

    $adGroups = Get-ADGroup -SearchBase $SearchBase -Filter * -Properties Description, Members, GroupScope

    foreach ($grp in $adGroups) {
        $members     = @()
        foreach ($m in $grp.Members) {
            try { $members += (Get-ADUser $m).SamAccountName } catch {}
        }
        $memberCount  = $members.Count
        $isEmpty      = $memberCount -eq 0
        $isOrphan     = [string]::IsNullOrWhiteSpace($grp.Description)

        $riskLevel = "FAIBLE"
        if ($isOrphan -and $memberCount -gt 0) { $riskLevel = "CRITIQUE" }
        elseif ($isOrphan)                      { $riskLevel = "ELEVE" }
        elseif ($isEmpty)                       { $riskLevel = "MODERE" }

        $groupResults += [PSCustomObject]@{
            GroupName         = $grp.Name
            Scope             = $grp.GroupScope
            Description       = $grp.Description
            IsOrphan          = if ($isOrphan) { "OUI" } else { "NON" }
            IsEmpty           = if ($isEmpty) { "OUI" } else { "NON" }
            MemberCount       = $memberCount
            Members           = ($members -join " | ")
            RiskLevel         = $riskLevel
            RecommendedAction = switch ($riskLevel) {
                "CRITIQUE" { "DOCUMENTER_PROPRIETAIRE_URGENT" }
                "ELEVE"    { "DOCUMENTER_OU_SUPPRIMER" }
                "MODERE"   { "SUPPRIMER_SI_INUTILE" }
                default    { "VALIDER_MAINTIEN" }
            }
            AuditDate         = (Get-Date -Format "yyyy-MM-dd")
        }
    }
}

$groupResults  | Export-Csv -Path $OutputGroups  -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$memberResults | Export-Csv -Path $OutputMembers -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$orphans  = ($groupResults | Where-Object { $_.IsOrphan -eq "OUI" }).Count
$empty    = ($groupResults | Where-Object { $_.IsEmpty -eq "OUI" }).Count
$critique = ($groupResults | Where-Object { $_.RiskLevel -eq "CRITIQUE" }).Count

Write-Host "  [OK] Vue groupes  : $OutputGroups ($($groupResults.Count) groupes)"
Write-Host "  [OK] Vue membres  : $OutputMembers ($($memberResults.Count) entrées)"
Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  Total groupes         : $($groupResults.Count)"
Write-Host "  Groupes orphelins     : $orphans  (sans propriétaire documenté)"
Write-Host "  Groupes vides         : $empty"
Write-Host "  Niveau CRITIQUE       : $critique  (orphelins avec membres)"
Write-Host ""
Write-Host "  Étape suivante : .\Audit-PasswordPolicy.ps1" -ForegroundColor Cyan
Write-Host ""
