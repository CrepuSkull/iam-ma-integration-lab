<#
.SYNOPSIS
    Audit-PasswordPolicy.ps1
    Évaluation de la politique de mots de passe AD CorpB.

.DESCRIPTION
    Audite la Default Domain Password Policy et les Fine-Grained Password
    Policies (FGPP) si présentes. Compare les paramètres CorpB avec les
    exigences minimales recommandées (ISO 27001, ANSSI, Microsoft Baseline).

    Mode : LECTURE SEULE.

.EXAMPLE
    .\Audit-PasswordPolicy.ps1 -Simulation -OutputPath "..\reports\"

.NOTES
    Mapping réglementaire : ISO 27001:2022 A.8.5, A.8.6 | NIS2 Art.21§2(a)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Domain = "corpb.local",

    [Parameter()]
    [string]$OutputPath = "..\reports\",

    [Parameter()]
    [switch]$Simulation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = Join-Path $OutputPath "phase1-pwdpolicy_$Timestamp.csv"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit-PasswordPolicy.ps1 — LECTURE SEULE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan

# Politique simulée CorpB — représentative d'une PME sans durcissement
$SimulatedPolicy = [PSCustomObject]@{
    PolicyName              = "Default Domain Policy — corpb.local (simulé)"
    Domain                  = "corpb.local"
    MinPasswordLength       = 6
    PasswordHistoryCount    = 3
    MaxPasswordAge_Days     = 0       # 0 = jamais expiré (PasswordNeverExpires enforced globalement)
    MinPasswordAge_Days     = 0
    ComplexityEnabled       = $false  # Complexité désactivée
    ReversibleEncryption    = $false
    LockoutThreshold        = 0       # Pas de verrouillage
    LockoutDuration_Min     = 0
    FGPPCount               = 0       # Aucune Fine-Grained Policy
    Source                  = if ($Simulation) { "SIMULATION" } else { "AD_LIVE" }
}

# Référentiel de conformité cible (CorpA / ISO 27001 / ANSSI)
$Baseline = @{
    MinPasswordLength    = 12
    PasswordHistoryCount = 12
    MaxPasswordAge_Days  = 90
    ComplexityEnabled    = $true
    LockoutThreshold     = 10
    LockoutDuration_Min  = 15
}

function Test-Compliant {
    param($Value, $Expected, [switch]$AtLeast, [switch]$MustBeTrue, [switch]$MustNotBeZero)
    if ($MustBeTrue)    { return $Value -eq $true }
    if ($MustNotBeZero) { return $Value -gt 0 }
    if ($AtLeast)       { return $Value -ge $Expected }
    return $Value -eq $Expected
}

$results = @()

if (-not $Simulation) {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "  [WARN] Module AD non disponible — basculement en mode simulation" -ForegroundColor Yellow
        $Simulation = $true
    } else {
        Import-Module ActiveDirectory
        try {
            $policy = Get-ADDefaultDomainPasswordPolicy -Identity $Domain
            $SimulatedPolicy.MinPasswordLength    = $policy.MinPasswordLength
            $SimulatedPolicy.PasswordHistoryCount = $policy.PasswordHistoryCount
            $SimulatedPolicy.MaxPasswordAge_Days  = $policy.MaxPasswordAge.TotalDays
            $SimulatedPolicy.MinPasswordAge_Days  = $policy.MinPasswordAge.TotalDays
            $SimulatedPolicy.ComplexityEnabled    = $policy.ComplexityEnabled
            $SimulatedPolicy.ReversibleEncryption = $policy.ReversibleEncryptionEnabled
            $SimulatedPolicy.LockoutThreshold     = $policy.LockoutThreshold
            $SimulatedPolicy.LockoutDuration_Min  = $policy.LockoutDuration.TotalMinutes
            $SimulatedPolicy.Source               = "AD_LIVE"

            # Compter les FGPP
            $fgpp = Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction SilentlyContinue
            $SimulatedPolicy.FGPPCount = if ($fgpp) { @($fgpp).Count } else { 0 }
        } catch {
            Write-Host "  [WARN] Erreur lecture politique AD : $_ — mode simulation utilisé" -ForegroundColor Yellow
        }
    }
}

# Évaluation par critère
$checks = @(
    @{
        Parameter    = "MinPasswordLength"
        Value        = $SimulatedPolicy.MinPasswordLength
        Target       = $Baseline.MinPasswordLength
        Compliant    = $SimulatedPolicy.MinPasswordLength -ge $Baseline.MinPasswordLength
        Severity     = "ELEVE"
        Recommendation = "Passer à 12 caractères minimum avant migration Phase 3"
    },
    @{
        Parameter    = "PasswordHistoryCount"
        Value        = $SimulatedPolicy.PasswordHistoryCount
        Target       = $Baseline.PasswordHistoryCount
        Compliant    = $SimulatedPolicy.PasswordHistoryCount -ge $Baseline.PasswordHistoryCount
        Severity     = "MODERE"
        Recommendation = "Augmenter à 12 mots de passe mémorisés"
    },
    @{
        Parameter    = "MaxPasswordAge_Days"
        Value        = $SimulatedPolicy.MaxPasswordAge_Days
        Target       = $Baseline.MaxPasswordAge_Days
        Compliant    = ($SimulatedPolicy.MaxPasswordAge_Days -gt 0 -and $SimulatedPolicy.MaxPasswordAge_Days -le $Baseline.MaxPasswordAge_Days)
        Severity     = "ELEVE"
        Recommendation = "Définir une expiration à 90 jours maximum"
    },
    @{
        Parameter    = "ComplexityEnabled"
        Value        = $SimulatedPolicy.ComplexityEnabled
        Target       = $true
        Compliant    = $SimulatedPolicy.ComplexityEnabled -eq $true
        Severity     = "CRITIQUE"
        Recommendation = "Activer la complexité (majuscules, chiffres, caractères spéciaux)"
    },
    @{
        Parameter    = "LockoutThreshold"
        Value        = $SimulatedPolicy.LockoutThreshold
        Target       = $Baseline.LockoutThreshold
        Compliant    = $SimulatedPolicy.LockoutThreshold -gt 0
        Severity     = "CRITIQUE"
        Recommendation = "Configurer un seuil de verrouillage (recommandé : 10 tentatives)"
    },
    @{
        Parameter    = "ReversibleEncryption"
        Value        = $SimulatedPolicy.ReversibleEncryption
        Target       = $false
        Compliant    = $SimulatedPolicy.ReversibleEncryption -eq $false
        Severity     = "CRITIQUE"
        Recommendation = "Désactiver si actif — chiffrement réversible interdit"
    }
)

foreach ($check in $checks) {
    $results += [PSCustomObject]@{
        Parametre         = $check.Parameter
        ValeurActuelle    = $check.Value
        ValeurCible       = $check.Target
        Conforme          = if ($check.Compliant) { "OUI" } else { "NON" }
        Severite          = if ($check.Compliant) { "OK" } else { $check.Severity }
        Recommandation    = if ($check.Compliant) { "—" } else { $check.Recommendation }
        Source            = $SimulatedPolicy.Source
        AuditDate         = (Get-Date -Format "yyyy-MM-dd")
    }
}

# Ligne FGPP
$results += [PSCustomObject]@{
    Parametre      = "FineGrainedPasswordPolicies"
    ValeurActuelle = $SimulatedPolicy.FGPPCount
    ValeurCible    = "≥1 pour comptes privilégiés"
    Conforme       = if ($SimulatedPolicy.FGPPCount -gt 0) { "OUI" } else { "NON" }
    Severite       = if ($SimulatedPolicy.FGPPCount -gt 0) { "OK" } else { "MODERE" }
    Recommandation = if ($SimulatedPolicy.FGPPCount -eq 0) { "Créer une FGPP pour les comptes Admin CorpB" } else { "—" }
    Source         = $SimulatedPolicy.Source
    AuditDate      = (Get-Date -Format "yyyy-MM-dd")
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

# Affichage
$nonCompliant = ($results | Where-Object { $_.Conforme -eq "NON" })
$critique     = ($nonCompliant | Where-Object { $_.Severite -eq "CRITIQUE" }).Count
$eleve        = ($nonCompliant | Where-Object { $_.Severite -eq "ELEVE" }).Count

Write-Host "  [OK] Rapport exporté : $OutputFile"
Write-Host ""
Write-Host "  ── Résultats de conformité ──" -ForegroundColor Cyan
foreach ($r in $results) {
    $color = if ($r.Conforme -eq "OUI") { "Green" } else {
        switch ($r.Severite) { "CRITIQUE" { "Red" } "ELEVE" { "Yellow" } default { "Gray" } }
    }
    $status = if ($r.Conforme -eq "OUI") { "✓" } else { "✗" }
    Write-Host "  $status $($r.Parametre.PadRight(30)) Actuel: $($r.ValeurActuelle)  →  Cible: $($r.ValeurCible)" -ForegroundColor $color
}
Write-Host ""
Write-Host "  Non conformes : $($nonCompliant.Count) (dont $critique CRITIQUE, $eleve ÉLEVÉ)" -ForegroundColor $(if ($critique -gt 0) { "Red" } else { "Yellow" })
Write-Host ""
Write-Host "  Note : Les écarts de politique AD CorpB doivent être traités" -ForegroundColor Gray
Write-Host "         avant la Phase 3. Les comptes migrés héritent des" -ForegroundColor Gray
Write-Host "         politiques Entra ID CorpA dès la bascule." -ForegroundColor Gray
Write-Host ""
Write-Host "  Audit Phase 1 terminé. Produire le livrable OCM :" -ForegroundColor Cyan
Write-Host "  → ..\ocm\OCM-Phase1-StakeholderBriefing.md" -ForegroundColor Cyan
Write-Host ""
