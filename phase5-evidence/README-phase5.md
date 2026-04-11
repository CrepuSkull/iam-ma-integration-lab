# 🔐 Phase 5 — Scellage des preuves (Evidence Sealing)

> `iam-ma-integration-lab` / phase5-evidence
> Langue : Français | Cible : ingénieur IAM, RSSI, auditeur

---

## Principe fondamental

**Une preuve non scellée est une preuve contestable.**

La Phase 5 garantit l'intégrité et l'opposabilité de l'ensemble des
rapports produits tout au long du projet. Elle ne produit pas de nouveaux
contrôles — elle **sécurise les traces** de tous les contrôles déjà effectués.

---

## Positionnement dans le framework

Cette phase est un **wrapper contextuel** du module
[`iam-evidence-sealer`](https://github.com/CrepuSkull/iam-evidence-sealer).

Elle n'en duplique pas le code. Elle l'orchestre dans le contexte M&A :
quels rapports sceller, dans quel ordre, avec quelle métadonnée.

```
iam-evidence-sealer          iam-ma-integration-lab / phase5-evidence
───────────────────          ──────────────────────────────────────────
SHA-256                  →   Invoke-EvidenceSealer.ps1
X.509                        Orchestration des rapports projet
RFC 3161                     Métadonnées M&A (phases, dates, validateurs)
```

---

## Livrables

```
phase5-evidence/
├── README-phase5.md              ← Ce fichier
└── Invoke-EvidenceSealer.ps1     ← Wrapper d'orchestration M&A
```

---

## Ce que le scellage garantit

| Garantie | Mécanisme | Valeur |
|---|---|---|
| **Intégrité** | SHA-256 de chaque fichier | Détecte toute modification post-audit |
| **Authenticité** | Certificat X.509 | Lie le rapport à l'auteur |
| **Antériorité** | RFC 3161 (CA commerciale) | Preuve de date opposable |
| **Traçabilité** | Manifest JSON signé | Vision consolidée de tous les rapports |

> **Certificats auto-signés (lab)** : démonstration/test uniquement.
> Valeur probante nulle. Pour une valeur réglementaire réelle,
> utiliser une CA commerciale avec RFC 3161 (voir `iam-evidence-sealer`).

---

## Fichiers à sceller

Le script orchestre le scellage dans cet ordre :

| # | Rapport | Phase source |
|---|---|---|
| 1 | `phase1-inventory_*.csv` | Phase 1 |
| 2 | `phase1-stale_*.csv` | Phase 1 |
| 3 | `phase1-privileged_*.csv` | Phase 1 |
| 4 | `phase1-groups_*.csv` | Phase 1 |
| 5 | `phase1-pwdpolicy_*.csv` | Phase 1 |
| 6 | `phase2-stale-execution_*.csv` | Phase 2 |
| 7 | `phase2-privileged-execution_*.csv` | Phase 2 |
| 8 | `phase2-groups-execution_*.csv` | Phase 2 |
| 9 | `phase3-premigration-checklist_*.csv` | Phase 3 |
| 10 | `phase3-migration-execution_*.csv` | Phase 3 |
| 11 | `phase3-postmigration-delta_*.csv` | Phase 3 |
| 12 | `phase4-orphans_*.csv` | Phase 4 |
| 13 | `phase4-rbac-conflicts_*.csv` | Phase 4 |
| 14 | `phase4-guest-accounts_*.csv` | Phase 4 |
| 15 | `phase4-saas-postfusion_*.csv` | Phase 4 |

---

## Déroulé

```powershell
# Scellage complet de tous les rapports
.\Invoke-EvidenceSealer.ps1 -ReportsPath "..\reports\" -DryRun

# Scellage réel
.\Invoke-EvidenceSealer.ps1 -ReportsPath "..\reports\" -DryRun:$false
```

---

## Mapping réglementaire

| Contrôle | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| Scellage SHA-256 | A.5.28, A.5.33 | Art. 21 §2(f) | Art. 5(2) |
| Horodatage RFC 3161 | A.5.28 | Art. 21 §2(f) | Art. 5(2) |

## Phase suivante

➜ [`../ocm/OCM-Phase5-ClosureReport.md`](../ocm/OCM-Phase5-ClosureReport.md)

---

*Phase 5 — Evidence — `iam-ma-integration-lab` — IAM-Lab Framework*
