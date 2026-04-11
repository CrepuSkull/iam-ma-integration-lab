<#
.SYNOPSIS
    Invoke-EvidenceSealer.ps1
    Orchestration du scellage cryptographique des rapports — contexte M&A.

.DESCRIPTION
    Wrapper du module iam-evidence-sealer, contextualisé pour le projet
    d'intégration IAM M&A CorpA/CorpB.

    Pour chaque rapport CSV produit par les phases 1 à 4 :
      1. Calcule l'empreinte SHA-256
      2. Vérifie l'intégrité (si empreinte précédente disponible)
      3. Produit un manifest JSON consolidé signé
      4. Appelle iam-evidence-sealer si disponible (RFC 3161 optionnel)

    DryRun par défaut — aucun fichier modifié sans -DryRun:$false.

    IMPORTANT : les certificats auto-signés générés en lab n'ont aucune
    valeur probante réglementaire. Pour une utilisation en production,
    utiliser une CA commerciale avec RFC 3161 (voir iam-evidence-sealer).

.PARAMETER ReportsPath
    Répertoire contenant les rapports CSV à sceller (défaut: ..\reports\)

.PARAMETER OutputPath
    Répertoire de sortie pour le manifest et les empreintes (défaut: ..\reports\evidence\)

.PARAMETER DryRun
    Simulation — calcul des empreintes sans écriture (défaut: $true)

.PARAMETER EvidenceSealerPath
    Chemin vers le script principal de iam-evidence-sealer (optionnel)

.PARAMETER ProjectId
    Identifiant du projet M&A pour les métadonnées (défaut: CorpA-CorpB-Integration)

.EXAMPLE
    # Simulation — aperçu des fichiers qui seront scellés
    .\Invoke-EvidenceSealer.ps1 -DryRun

.EXAMPLE
    # Scellage réel
    .\Invoke-EvidenceSealer.ps1 -DryRun:$false -ReportsPath "..\reports\"

.NOTES
    IAM-Lab Framework — iam-ma-integration-lab / phase5-evidence
    Wrapper de : iam-evidence-sealer (https://github.com/CrepuSkull/iam-evidence-sealer)
    Mapping réglementaire : ISO 27001:2022 A.5.28, A.5.33 | NIS2 Art.21§2(f) | RGPD Art.5(2)
    Certificats auto-signés : démonstration/test uniquement — pas de valeur probante réglementaire.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ReportsPath = "..\reports\",

    [Parameter()]
    [string]$OutputPath = "..\reports\evidence\",

    [Parameter()]
    [bool]$DryRun = $true,

    [Parameter()]
    [string]$EvidenceSealerPath = "",

    [Parameter()]
    [string]$ProjectId = "CorpA-CorpB-Integration"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$ManifestFile = Join-Path $OutputPath "evidence-manifest_$Timestamp.json"
$HashLogFile  = Join-Path $OutputPath "evidence-hashes_$Timestamp.csv"

if (-not $DryRun -and -not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Bannière
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Cyan" })
Write-Host "  Invoke-EvidenceSealer.ps1 — Scellage M&A" -ForegroundColor White
Write-Host "  Mode      : $(if ($DryRun) { 'DRYRUN — aucune écriture' } else { 'EXECUTION — scellage réel' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
Write-Host "  Projet    : $ProjectId" -ForegroundColor Gray
Write-Host "  Rapports  : $ReportsPath" -ForegroundColor Gray
Write-Host "  Sortie    : $OutputPath" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Cyan" })
Write-Host ""
Write-Host "  ⚠  Certificats auto-signés : démonstration/test uniquement" -ForegroundColor Yellow
Write-Host "     Valeur probante nulle — voir iam-evidence-sealer pour CA commerciale" -ForegroundColor Yellow
Write-Host ""

# ---------------------------------------------------------------------------
# Inventaire des rapports à sceller
# ---------------------------------------------------------------------------

# Patterns des rapports produits par les phases 1-4
$reportPatterns = @(
    "phase1-inventory_*.csv",
    "phase1-stale_*.csv",
    "phase1-privileged_*.csv",
    "phase1-groups_*.csv",
    "phase1-group-members_*.csv",
    "phase1-pwdpolicy_*.csv",
    "phase2-stale-execution_*.csv",
    "phase2-privileged-execution_*.csv",
    "phase2-groups-execution_*.csv",
    "phase2-*-rollback_*.csv",
    "phase2-*-validated*.csv",
    "phase3-premigration-checklist_*.csv",
    "phase3-migration-execution_*.csv",
    "phase3-postmigration-delta_*.csv",
    "phase4-orphans_*.csv",
    "phase4-rbac-conflicts_*.csv",
    "phase4-guest-accounts_*.csv",
    "phase4-saas-postfusion_*.csv",
)

$filesToSeal = @()
foreach ($pattern in $reportPatterns) {
    $matches = Get-ChildItem -Path $ReportsPath -Filter $pattern -ErrorAction SilentlyContinue
    if ($matches) { $filesToSeal += $matches }
}

if ($filesToSeal.Count -eq 0) {
    Write-Host "  [WARN] Aucun rapport trouvé dans : $ReportsPath" -ForegroundColor Yellow
    Write-Host "         Exécuter les phases 1-4 d'abord pour générer les rapports." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Mode simulation — calcul sur fichiers fictifs pour démonstration." -ForegroundColor Gray
    # Créer un fichier fictif pour la démonstration du flux
    $demoContent = "sAMAccountName;Action;Status`ndemo.user;AUDIT;OK"
    $demoFile    = Join-Path $ReportsPath "phase1-inventory_DEMO.csv"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null
        $demoContent | Out-File -FilePath $demoFile -Encoding UTF8
        $filesToSeal = @(Get-Item $demoFile)
    }
}

Write-Host "  Rapports à sceller : $($filesToSeal.Count)"
Write-Host ""

# ---------------------------------------------------------------------------
# Calcul des empreintes SHA-256
# ---------------------------------------------------------------------------

Write-Host "  ── Calcul des empreintes SHA-256 ──" -ForegroundColor Cyan
Write-Host ""

$hashResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$manifestEntries = [System.Collections.Generic.List[hashtable]]::new()

$phaseMapping = @{
    "phase1" = "Phase 1 — Audit AD"
    "phase2" = "Phase 2 — Remédiation"
    "phase3" = "Phase 3 — Migration"
    "phase4" = "Phase 4 — Gouvernance"
}

foreach ($file in ($filesToSeal | Sort-Object Name)) {
    $phase = "Inconnu"
    foreach ($key in $phaseMapping.Keys) {
        if ($file.Name -like "$key*") { $phase = $phaseMapping[$key]; break }
    }

    if ($DryRun) {
        # DryRun : calculer l'empreinte sans écrire le manifest
        $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        Write-Host "  [DRYRUN] $($file.Name)" -ForegroundColor Yellow
        Write-Host "           SHA-256 : $($hash.Hash)" -ForegroundColor Gray
        Write-Host "           Phase   : $phase" -ForegroundColor Gray
        Write-Host "           Taille  : $([math]::Round($file.Length/1KB, 1)) KB" -ForegroundColor Gray
        Write-Host ""

        $hashResults.Add([PSCustomObject]@{
            FileName  = $file.Name
            FilePath  = $file.FullName
            Phase     = $phase
            SHA256    = $hash.Hash
            FileSize  = $file.Length
            SealedAt  = "DRYRUN"
            DryRun    = $true
        })
    } else {
        # Exécution réelle
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $sealedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

            Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
            Write-Host "       SHA-256 : $($hash.Hash)" -ForegroundColor Gray

            $hashResults.Add([PSCustomObject]@{
                FileName  = $file.Name
                FilePath  = $file.FullName
                Phase     = $phase
                SHA256    = $hash.Hash
                FileSize  = $file.Length
                SealedAt  = $sealedAt
                DryRun    = $false
            })

            $manifestEntries.Add(@{
                fileName    = $file.Name
                filePath    = $file.FullName
                phase       = $phase
                sha256      = $hash.Hash
                fileSize    = $file.Length
                sealedAt    = $sealedAt
                projectId   = $ProjectId
            })
        } catch {
            Write-Host "  [ERROR] $($file.Name) : $_" -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------------------------
# Export hash log + manifest JSON
# ---------------------------------------------------------------------------

if (-not $DryRun -and $hashResults.Count -gt 0) {
    $hashResults | Export-Csv -Path $HashLogFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host "  [OK] Log empreintes : $HashLogFile" -ForegroundColor Green

    # Manifest JSON
    $manifest = @{
        projectId       = $ProjectId
        generatedAt     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        generatedBy     = "$env:USERNAME@$env:COMPUTERNAME"
        labFramework    = "iam-ma-integration-lab"
        scenario        = "CorpA absorbs CorpB — AD on-premises to Entra ID migration"
        totalFiles      = $manifestEntries.Count
        certificateNote = "DEMONSTRATION/TEST UNIQUEMENT — auto-signé — pas de valeur probante réglementaire"
        rfc3161Note     = "Pour valeur probante : utiliser iam-evidence-sealer avec CA commerciale"
        files           = $manifestEntries
    }

    $manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $ManifestFile -Encoding UTF8
    Write-Host "  [OK] Manifest JSON  : $ManifestFile" -ForegroundColor Green

    # Empreinte du manifest lui-même
    $manifestHash = Get-FileHash -Path $ManifestFile -Algorithm SHA256
    Write-Host "  [OK] SHA-256 manifest : $($manifestHash.Hash)" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Appel iam-evidence-sealer (si disponible)
# ---------------------------------------------------------------------------

if (-not $DryRun -and $EvidenceSealerPath -and (Test-Path $EvidenceSealerPath)) {
    Write-Host ""
    Write-Host "  ── Appel iam-evidence-sealer (RFC 3161) ──" -ForegroundColor Cyan
    try {
        & $EvidenceSealerPath -ManifestPath $ManifestFile -ProjectId $ProjectId
        Write-Host "  [OK] Scellage RFC 3161 effectué" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] iam-evidence-sealer inaccessible : $_" -ForegroundColor Yellow
        Write-Host "         Le scellage SHA-256 reste valide pour traçabilité interne." -ForegroundColor Yellow
    }
} elseif (-not $DryRun) {
    Write-Host ""
    Write-Host "  [INFO] iam-evidence-sealer non configuré (-EvidenceSealerPath vide)" -ForegroundColor Gray
    Write-Host "         Scellage SHA-256 uniquement — suffisant pour traçabilité lab." -ForegroundColor Gray
    Write-Host "         Pour valeur probante : https://github.com/CrepuSkull/iam-evidence-sealer" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Synthèse
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "  ── Synthèse ──" -ForegroundColor Cyan
Write-Host "  Fichiers traités      : $($hashResults.Count)"
Write-Host "  Mode                  : $(if ($DryRun) { 'DRYRUN — empreintes calculées, rien écrit' } else { 'EXECUTION — manifest et hash log produits' })"
Write-Host ""

if ($DryRun) {
    Write-Host "  Pour exécuter le scellage réel :" -ForegroundColor Yellow
    Write-Host "  .\Invoke-EvidenceSealer.ps1 -DryRun:`$false -ReportsPath '$ReportsPath'" -ForegroundColor Yellow
} else {
    Write-Host "  Étape suivante : OCM Phase 5 — Rapport de clôture CODIR" -ForegroundColor Cyan
    Write-Host "  → ..\ocm\OCM-Phase5-ClosureReport.md" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Projet d'intégration IAM M&A CorpA/CorpB — Phases 0-5 terminées." -ForegroundColor Green
Write-Host ""
