# 08 — Phase 5 : Scellage des preuves

> Wiki — `iam-ma-integration-lab`

---

## Pourquoi sceller les rapports

Un rapport CSV non scellé peut être modifié après coup — intentionnellement
ou par erreur. En contexte de conformité réglementaire (ISO 27001, NIS2,
RGPD), un rapport modifiable est un rapport contestable.

Le scellage répond à une question simple : **comment prouver que ce rapport
dit exactement ce qu'il disait au moment où l'action a été décidée ?**

La réponse est l'empreinte SHA-256 : si un seul caractère du fichier change
après scellage, l'empreinte devient différente. La falsification est
immédiatement détectable.

---

## Architecture du scellage dans ce lab

Ce lab utilise `Invoke-EvidenceSealer.ps1` comme wrapper contextuel
du module [`iam-evidence-sealer`](https://github.com/CrepuSkull/iam-evidence-sealer).

```
iam-evidence-sealer              Invoke-EvidenceSealer.ps1
─────────────────────            ──────────────────────────────
SHA-256                    →     Orchestre 15 rapports dans l'ordre
X.509 (auto-signé/CA)            Ajoute métadonnées projet M&A
RFC 3161 (horodatage tiers)      Produit manifest JSON consolidé
```

Le manifest JSON final contient pour chaque rapport : nom, phase, taille,
empreinte SHA-256, date de scellage, identifiant projet.

---

## Ce que le scellage garantit — et ce qu'il ne garantit pas

| Garantie | Mécanisme |
|---|---|
| ✅ Intégrité | SHA-256 — détecte toute modification post-audit |
| ✅ Traçabilité | Manifest JSON — vision consolidée de tous les rapports |
| ✅ Authenticité (lab) | Certificat auto-signé — lie le rapport à l'auteur |
| ⚠️ Authenticité (production) | Nécessite une CA commerciale |
| ⚠️ Valeur probante | Nécessite RFC 3161 + CA commerciale |

> **Rappel critique :** les certificats auto-signés générés dans ce lab
> n'ont **aucune valeur probante réglementaire**. Pour une utilisation
> en contexte d'audit réel, utiliser `iam-evidence-sealer` avec une CA
> commerciale et RFC 3161.

---

## Les 15 rapports scellés

Le script scelle automatiquement tous les rapports produits par les phases
1 à 4 dans cet ordre :

```
Phase 1 — 5 rapports :
  phase1-inventory_*.csv
  phase1-stale_*.csv
  phase1-privileged_*.csv
  phase1-groups_*.csv
  phase1-pwdpolicy_*.csv

Phase 2 — 5 rapports :
  phase2-stale-execution_*.csv
  phase2-privileged-execution_*.csv
  phase2-groups-execution_*.csv
  phase2-*-rollback_*.csv
  CSV de validation scellés

Phase 3 — 3 rapports :
  phase3-premigration-checklist_*.csv
  phase3-migration-execution_*.csv
  phase3-postmigration-delta_*.csv

Phase 4 — 4 rapports :
  phase4-orphans_*.csv
  phase4-rbac-conflicts_*.csv
  phase4-guest-accounts_*.csv
  phase4-saas-postfusion_*.csv
```

---

## Exécution

```powershell
# Simulation — calcule les empreintes sans écrire le manifest
.\phase5-evidence\Invoke-EvidenceSealer.ps1 -DryRun

# Scellage réel
.\phase5-evidence\Invoke-EvidenceSealer.ps1 `
    -DryRun:$false `
    -ReportsPath ".\reports\" `
    -ProjectId "CorpA-CorpB-2025"

# Avec iam-evidence-sealer (RFC 3161)
.\phase5-evidence\Invoke-EvidenceSealer.ps1 `
    -DryRun:$false `
    -EvidenceSealerPath "..\..\iam-evidence-sealer\Seal-Evidence.ps1"
```

---

## Vérifier l'intégrité d'un rapport après coup

```powershell
# Recalculer l'empreinte d'un rapport
$hash = Get-FileHash -Path ".\reports\phase1-inventory_20250615.csv" -Algorithm SHA256
Write-Host $hash.Hash

# Comparer avec le manifest
$manifest = Get-Content ".\reports\evidence\evidence-manifest_*.json" | ConvertFrom-Json
$recorded = ($manifest.files | Where-Object { $_.fileName -like "phase1-inventory*" }).sha256

if ($hash.Hash -eq $recorded) {
    Write-Host "INTÉGRITÉ VÉRIFIÉE" -ForegroundColor Green
} else {
    Write-Host "ALERTE : empreinte différente — fichier modifié" -ForegroundColor Red
}
```

---

*Wiki page 08 — `iam-ma-integration-lab` — IAM-Lab Framework*
