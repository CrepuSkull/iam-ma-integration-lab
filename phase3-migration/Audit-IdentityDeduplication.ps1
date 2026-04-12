<#
.SYNOPSIS
    Audit-IdentityDeduplication.ps1
    Détection des collisions d'identités entre CorpB (source) et CorpA (cible).

.DESCRIPTION
    En contexte M&A, les collisions d'identités sont inévitables :
      - Homonymes (même prénom + même nom dans les deux entreprises)
      - Conventions de nommage différentes (p.nom vs prenom.nom vs pnom)
      - UPN cibles identiques pour deux personnes différentes
      - Même personne présente dans les deux entités (prestataire, dirigeant)

    Ce script détecte CINQ types de collision avant la migration Phase 3 :

      UPN_COLLISION       : L'UPN cible calculé existe déjà dans Entra ID CorpA
      EMAIL_OVERLAP       : L'email source CorpB correspond à un email CorpA existant
      DISPLAY_NAME_MATCH  : Même DisplayName dans CorpA et CorpB — homonyme probable
      EMPLOYEE_ID_MATCH   : Même EmployeeID dans les deux annuaires (même personne)
      SAM_AMBIGUITY       : Le sAMAccountName CorpB génère plusieurs UPN cibles possibles

    Pour chaque collision, le script propose une règle de résolution
    et génère un fichier MAPPING-IDENTITY.csv à valider avant migration.

    Mode : LECTURE SEULE.

.PARAMETER SourceCsvPath
    Chemin vers corpb-users.csv (référentiel source CorpB)

.PARAMETER TargetDomain
    Domaine UPN cible Entra ID CorpA

.PARAMETER CorpAUsersCsvPath
    Fichier CSV des utilisateurs Entra ID CorpA (export manuel ou via Graph)
    Colonnes attendues : UserPrincipalName, DisplayName, Mail, EmployeeId

.PARAMETER OutputPath
    Répertoire de sortie

.PARAMETER Simulation
    Mode simulation — génère des collisions fictives pour démonstration

.PARAMETER NamingConvention
    Convention de nommage UPN cible appliquée à CorpB
    Options : PrenomNom (p.nom), NomPrenom (nom.p), Prenom.Nom (prenom.nom)
    Défaut : PrenomNom (p.nom — standard du lab)

.EXAMPLE
    # Mode simulation
    .\Audit-IdentityDeduplication.ps1 -Simulation -OutputPath "..\reports\"

.EXAMPLE
    # Mode réel avec export Entra ID CorpA
    .\Audit-IdentityDeduplication.ps1 `
        -SourceCsvPath "..\seed\corpb-users.csv" `
        -CorpAUsersCsvPath ".\corpa-users-export.csv" `
        -TargetDomain "corpa.onmicrosoft.com" `
        -OutputPath "..\reports\"

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / phase3-migration
    À exécuter AVANT Migrate-UsersToEntraID.ps1
    Mapping réglementaire : ISO 27001:2022 A.5.15, A.5.16 | RGPD Art.5(1)(c)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourceCsvPath = "..\seed\corpb-users.csv",

    [Parameter()]
    [string]$TargetDomain = "corpa.onmicrosoft.com",

    [Parameter()]
    [string]$CorpAUsersCsvPath = "",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [switch]$Simulation,

    [Parameter()]
    [ValidateSet("PrenomNom", "NomPrenom", "Prenom.Nom")]
    [string]$NamingConvention = "PrenomNom"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$CollisionFile  = Join-Path $OutputPath "phase3-identity-collisions_$Timestamp.csv"
$MappingFile    = Join-Path $OutputPath "MAPPING-IDENTITY_TOVALIDATE_$Timestamp.csv"
$ReportFile     = Join-Path $OutputPath "phase3-deduplication-report_$Timestamp.txt"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-IdentityDeduplication.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "  Détection des collisions d'identités CorpB → CorpA" -ForegroundColor Cyan
Write-Host "  Convention UPN : $NamingConvention | Domaine cible : $TargetDomain" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------

function Remove-Diacritics {
    param([string]$Text)
    $normalized = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($char in $normalized.ToCharArray()) {
        $cat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($char)
        }
    }
    return $sb.ToString().ToLower()
}

function Get-TargetUPN {
    param([string]$GivenName, [string]$Surname, [string]$Convention, [string]$Domain)
    $gn = Remove-Diacritics -Text $GivenName
    $sn = Remove-Diacritics -Text $Surname
    $gn = $gn -replace "[^a-z]",""
    $sn = $sn -replace "[^a-z]",""

    $prefix = switch ($Convention) {
        "PrenomNom"   { "$($gn[0]).$sn" }
        "NomPrenom"   { "$sn.$($gn[0])" }
        "Prenom.Nom"  { "$gn.$sn" }
    }
    return "$prefix@$Domain"
}

function Get-AlternativeUPN {
    param([string]$GivenName, [string]$Surname, [string]$Convention, [string]$Domain, [int]$Suffix)
    $base = (Get-TargetUPN -GivenName $GivenName -Surname $Surname -Convention $Convention -Domain $Domain)
    $prefix = $base.Split("@")[0]
    return "$prefix$Suffix@$Domain"
}

# ---------------------------------------------------------------------------
# Chargement des données
# ---------------------------------------------------------------------------

Write-Host "  Chargement des données source..." -ForegroundColor Gray

$corpBUsers = @()
if (Test-Path $SourceCsvPath) {
    $corpBUsers = Import-Csv -Path $SourceCsvPath -Delimiter ";" -Encoding UTF8 |
        Where-Object { $_.Enabled -eq "TRUE" -and $_.IsServiceAccount -eq "FALSE" -and $_.IsStale -eq "FALSE" }
    Write-Host "  [OK] CorpB : $($corpBUsers.Count) comptes éligibles chargés"
} else {
    Write-Host "  [WARN] CSV CorpB introuvable — mode simulation forcé" -ForegroundColor Yellow
    $Simulation = $true
}

# Données CorpA simulées ou réelles
$corpAUsers = @()

if ($Simulation) {
    Write-Host "  [INFO] Mode simulation — génération de collisions fictives" -ForegroundColor Yellow

    # Simuler ~15 utilisateurs CorpA dont certains créeront des collisions avec CorpB
    $corpASimulated = @(
        # Homonymes exacts
        @{ UPN="t.moulin@corpa.onmicrosoft.com";  DisplayName="Thomas Moulin";   Mail="t.moulin@corpa.fr";   EmployeeId="CA001" },
        @{ UPN="l.henry@corpa.onmicrosoft.com";   DisplayName="Laurent Henry";   Mail="l.henry@corpa.fr";    EmployeeId="CA002" },
        @{ UPN="m.martin@corpa.onmicrosoft.com";  DisplayName="Margot Martin";   Mail="m.martin@corpa.fr";   EmployeeId="CA003" },
        # UPN cible en collision mais personnes différentes
        @{ UPN="c.vincent@corpa.onmicrosoft.com"; DisplayName="Claire Vincent";  Mail="c.vincent@corpa.fr";  EmployeeId="CA004" },
        @{ UPN="n.perrin@corpa.onmicrosoft.com";  DisplayName="Nathan Perrin";   Mail="n.perrin@corpa.fr";   EmployeeId="CA005" },
        # Même personne dans les deux entités (dirigeant / prestataire)
        @{ UPN="t.vogt@corpa.onmicrosoft.com";    DisplayName="Thierry Vogt";    Mail="t.vogt@corpa.fr";     EmployeeId="CB_DSI_EXT" },
        # Comptes CorpA sans collision
        @{ UPN="s.arnaud@corpa.onmicrosoft.com";  DisplayName="Sophie Arnaud";   Mail="s.arnaud@corpa.fr";   EmployeeId="CA010" },
        @{ UPN="k.benali@corpa.onmicrosoft.com";  DisplayName="Karim Benali";    Mail="k.benali@corpa.fr";   EmployeeId="CA011" },
        @{ UPN="i.moulin@corpa.onmicrosoft.com";  DisplayName="Inès Moulin";     Mail="i.moulin@corpa.fr";   EmployeeId="CA012" },
    )

    foreach ($u in $corpASimulated) {
        $corpAUsers += [PSCustomObject]$u
    }
    Write-Host "  [OK] CorpA : $($corpAUsers.Count) comptes simulés chargés"

} elseif ($CorpAUsersCsvPath -and (Test-Path $CorpAUsersCsvPath)) {
    $corpAUsers = Import-Csv -Path $CorpAUsersCsvPath -Delimiter ";" -Encoding UTF8
    Write-Host "  [OK] CorpA : $($corpAUsers.Count) comptes chargés depuis $CorpAUsersCsvPath"
} else {
    # Tentative Graph
    Write-Host "  Tentative de chargement via Microsoft Graph..." -ForegroundColor Gray
    if (Get-Module -ListAvailable -Name Microsoft.Graph) {
        try {
            Import-Module Microsoft.Graph.Users -ErrorAction Stop
            Connect-MgGraph -Scopes "User.Read.All" -ErrorAction Stop
            $mgUsers = Get-MgUser -Filter "userType eq 'Member'" `
                -Property UserPrincipalName,DisplayName,Mail,EmployeeId -All
            foreach ($u in $mgUsers) {
                $corpAUsers += [PSCustomObject]@{
                    UPN        = $u.UserPrincipalName
                    DisplayName = $u.DisplayName
                    Mail       = $u.Mail
                    EmployeeId = $u.EmployeeId
                }
            }
            Write-Host "  [OK] CorpA : $($corpAUsers.Count) comptes chargés via Graph"
        } catch {
            Write-Host "  [WARN] Graph inaccessible : $_ — mode simulation forcé" -ForegroundColor Yellow
            $Simulation = $true
        }
    } else {
        Write-Host "  [WARN] Module Graph absent et pas de CSV CorpA — utiliser -Simulation" -ForegroundColor Yellow
    }
}

# Index CorpA pour recherche rapide
$corpAByUPN         = @{}
$corpAByMail        = @{}
$corpAByDisplayName = @{}
$corpAByEmployeeId  = @{}

foreach ($u in $corpAUsers) {
    if ($u.UPN)         { $corpAByUPN[$u.UPN.ToLower()] = $u }
    if ($u.Mail)        { $corpAByMail[$u.Mail.ToLower()] = $u }
    if ($u.DisplayName) {
        $key = $u.DisplayName.ToLower().Trim()
        if (-not $corpAByDisplayName.ContainsKey($key)) { $corpAByDisplayName[$key] = @() }
        $corpAByDisplayName[$key] += $u
    }
    if ($u.EmployeeId -and $u.EmployeeId -ne "") {
        $corpAByEmployeeId[$u.EmployeeId.ToLower()] = $u
    }
}

# ---------------------------------------------------------------------------
# Détection des collisions
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "  ── Analyse des collisions ──" -ForegroundColor Cyan
Write-Host ""

$collisions = [System.Collections.Generic.List[PSCustomObject]]::new()
$mappings   = [System.Collections.Generic.List[PSCustomObject]]::new()

# Suivi des UPN cibles déjà assignés (collisions intra-CorpB)
$assignedTargetUPNs = @{}

foreach ($user in $corpBUsers) {
    $sam        = $user.sAMAccountName.Trim()
    $gn         = $user.GivenName.Trim()
    $sn         = $user.Surname.Trim()
    $displayName = $user.DisplayName.Trim()
    $email      = $user.EmailAddress.ToLower().Trim()
    $empId      = if ($user.PSObject.Properties['EmployeeId']) { $user.EmployeeId } else { "" }

    $targetUPN   = Get-TargetUPN -GivenName $gn -Surname $sn -Convention $NamingConvention -Domain $TargetDomain
    $targetUPNlo = $targetUPN.ToLower()

    $detected    = @()
    $collisionTarget = $null
    $resolution  = ""
    $severity    = "MODERE"

    # --- TYPE 1 : UPN cible déjà dans Entra ID CorpA ---
    if ($corpAByUPN.ContainsKey($targetUPNlo)) {
        $collisionTarget = $corpAByUPN[$targetUPNlo]
        $sameDisplay     = $collisionTarget.DisplayName.ToLower().Trim() -eq $displayName.ToLower()

        if ($sameDisplay) {
            $detected  += "EMPLOYEE_ID_MATCH"
            $resolution = "VERIFIER_MEME_PERSONNE — si identique : fusionner comptes, ne pas recréer"
            $severity   = "CRITIQUE"
        } else {
            $detected  += "UPN_COLLISION"
            $resolution = "SUFFIXE_NUMERIQUE — UPN cible : $(Get-AlternativeUPN -GivenName $gn -Surname $sn -Convention $NamingConvention -Domain $TargetDomain -Suffix 2)"
            $severity   = "CRITIQUE"
        }
    }

    # --- TYPE 2 : Email source CorpB correspond à un email CorpA ---
    if ($corpAByMail.ContainsKey($email) -and "EMAIL_OVERLAP" -notin $detected) {
        $emailMatch = $corpAByMail[$email]
        if ($emailMatch.UPN.ToLower() -ne $targetUPNlo) {
            $detected  += "EMAIL_OVERLAP"
            $resolution = if ($resolution) { $resolution } else {
                "REMAPPER_EMAIL — l'adresse $email est déjà utilisée par $($emailMatch.DisplayName)"
            }
            $severity   = "ELEVE"
        }
    }

    # --- TYPE 3 : DisplayName identique dans CorpA (homonyme) ---
    $dnKey = $displayName.ToLower()
    if ($corpAByDisplayName.ContainsKey($dnKey) -and "EMPLOYEE_ID_MATCH" -notin $detected) {
        $detected  += "DISPLAY_NAME_MATCH"
        $resolution = if ($resolution) { $resolution } else {
            "VERIFIER_HOMONYME — $displayName existe dans CorpA. Confirmer si personnes différentes avant migration."
        }
        $severity = if ($severity -eq "CRITIQUE") { "CRITIQUE" } else { "ELEVE" }
    }

    # --- TYPE 4 : EmployeeId correspondant ---
    if ($empId -and $corpAByEmployeeId.ContainsKey($empId.ToLower()) -and "EMPLOYEE_ID_MATCH" -notin $detected) {
        $detected  += "EMPLOYEE_ID_MATCH"
        $resolution = "MEME_PERSONNE_CONFIRMEE — fusionner ou ignorer selon la politique HR"
        $severity   = "CRITIQUE"
    }

    # --- TYPE 5 : Collision intra-CorpB (deux CorpB génèrent le même UPN cible) ---
    if ($assignedTargetUPNs.ContainsKey($targetUPNlo)) {
        $conflictSam = $assignedTargetUPNs[$targetUPNlo]
        $detected   += "SAM_AMBIGUITY"
        $resolution  = "SUFFIXE_NUMERIQUE — conflit avec $conflictSam. UPN cible alternatif : $(Get-AlternativeUPN -GivenName $gn -Surname $sn -Convention $NamingConvention -Domain $TargetDomain -Suffix 2)"
        $severity    = "CRITIQUE"
    } else {
        $assignedTargetUPNs[$targetUPNlo] = $sam
    }

    # Déterminer l'UPN cible final recommandé
    $finalUPN = if ("UPN_COLLISION" -in $detected -or "SAM_AMBIGUITY" -in $detected) {
        Get-AlternativeUPN -GivenName $gn -Surname $sn -Convention $NamingConvention -Domain $TargetDomain -Suffix 2
    } else { $targetUPN }

    # Enregistrer si collision détectée
    if ($detected.Count -gt 0) {
        $collisions.Add([PSCustomObject]@{
            sAMAccountName_CorpB  = $sam
            DisplayName_CorpB     = $displayName
            Department            = $user.Department
            TargetUPN_Calculated  = $targetUPN
            TargetUPN_Recommended = $finalUPN
            CollisionTypes        = ($detected -join " | ")
            Severity              = $severity
            CollisionWith         = if ($collisionTarget) { $collisionTarget.UPN } else { "—" }
            Resolution            = $resolution
            AuditDate             = (Get-Date -Format "yyyy-MM-dd")
        })
    }

    # Toujours enregistrer dans le mapping (avec ou sans collision)
    $mappings.Add([PSCustomObject]@{
        sAMAccountName_CorpB  = $sam
        DisplayName_CorpB     = $displayName
        Email_CorpB           = $email
        Department            = $user.Department
        Domain_Source         = $user.Domain
        TargetUPN_Calculated  = $targetUPN
        TargetUPN_Final       = $finalUPN
        HasCollision          = if ($detected.Count -gt 0) { "OUI" } else { "NON" }
        CollisionType         = if ($detected.Count -gt 0) { $detected -join " | " } else { "—" }
        Severity              = if ($detected.Count -gt 0) { $severity } else { "—" }
        Resolution            = if ($resolution) { $resolution } else { "MIGRATION_STANDARD" }
        Valider               = ""   # ← À compléter : OUI = migration approuvée avec cet UPN final
        ValidatedBy           = ""
        Notes                 = ""
        AuditDate             = (Get-Date -Format "yyyy-MM-dd")
    })
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

$collisions | Export-Csv -Path $CollisionFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$mappings   | Export-Csv -Path $MappingFile   -NoTypeInformation -Encoding UTF8 -Delimiter ";"

# ---------------------------------------------------------------------------
# Rapport
# ---------------------------------------------------------------------------

$critique = ($collisions | Where-Object { $_.Severity -eq "CRITIQUE" }).Count
$eleve    = ($collisions | Where-Object { $_.Severity -eq "ELEVE" }).Count
$modere   = ($collisions | Where-Object { $_.Severity -eq "MODERE" }).Count

$byType   = $collisions | ForEach-Object { $_.CollisionTypes -split " \| " } |
    Group-Object | Sort-Object Count -Descending

$report = @"
════════════════════════════════════════════════════════════
  RAPPORT DÉDUPLICATION IDENTITÉS — CorpB → CorpA
  Généré le : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Convention UPN : $NamingConvention | Domaine : $TargetDomain
  Source : $(if ($Simulation) { 'SIMULATION' } else { $SourceCsvPath })
════════════════════════════════════════════════════════════

  VOLUME
  Comptes CorpB analysés   : $($corpBUsers.Count)
  Comptes CorpA référence  : $($corpAUsers.Count)
  Collisions détectées     : $($collisions.Count)
  Sans collision           : $($corpBUsers.Count - $collisions.Count)

  SÉVÉRITÉ DES COLLISIONS
  CRITIQUE                 : $critique  ← Bloquant — résoudre avant migration
  ÉLEVÉ                    : $eleve
  MODÉRÉ                   : $modere

  TYPES DE COLLISION
$(($byType | ForEach-Object { "  $($_.Name.PadRight(30)) : $($_.Count)" }) -join "`n")

  FICHIERS PRODUITS
  Collisions détaillées    : $CollisionFile
  Mapping complet          : $MappingFile

  PROCHAINES ÉTAPES
  1. Ouvrir MAPPING-IDENTITY_TOVALIDATE_*.csv
  2. Pour chaque ligne HasCollision=OUI :
     - Vérifier le TargetUPN_Final recommandé
     - Ajuster si nécessaire
     - Inscrire OUI dans la colonne Valider
  3. Transmettre le fichier validé à Migrate-UsersToEntraID.ps1
     via le paramètre -MappingCsvPath

  ATTENTION : Ne pas lancer Migrate-UsersToEntraID.ps1
  tant que des collisions CRITIQUE ne sont pas résolues.

════════════════════════════════════════════════════════════
  LECTURE SEULE — Aucune modification effectuée
════════════════════════════════════════════════════════════
"@

$report | Tee-Object -FilePath $ReportFile
Write-Host "  [OK] Rapport      : $ReportFile" -ForegroundColor Gray
Write-Host "  [OK] Collisions   : $CollisionFile ($($collisions.Count) détectées)" -ForegroundColor Gray
Write-Host "  [OK] Mapping      : $MappingFile ($($mappings.Count) lignes — colonne Valider à compléter)" -ForegroundColor Yellow
Write-Host ""

if ($critique -gt 0) {
    Write-Host "  [BLOQUANT] $critique collision(s) CRITIQUE — migration impossible sans résolution" -ForegroundColor Red
    Write-Host "  Voir MAPPING-IDENTITY.md pour les règles de résolution" -ForegroundColor Red
} elseif ($collisions.Count -gt 0) {
    Write-Host "  [WARN] $($collisions.Count) collision(s) à traiter — migration conditionnée à validation" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Aucune collision — migration peut démarrer" -ForegroundColor Green
}
Write-Host ""
