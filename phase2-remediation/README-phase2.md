# 🔧 Phase 2 — Remédiation de l'AD source (CorpB)

> `iam-ma-integration-lab` / phase2-remediation
> Langue : Français | Cible : ingénieur IAM, RSSI

---

## Principe fondamental

**Aucune action sans validation humaine préalable. Sans exception.**

La Phase 2 est la première phase d'écriture du lab. Elle modifie l'AD CorpB.
Ce pouvoir est encadré par trois garde-fous non négociables :

```
┌─────────────────────────────────────────────────────────────────┐
│  GARDE-FOU 1 — DryRun par défaut                                │
│  Tout script Remediate-* s'exécute en simulation tant que       │
│  -DryRun:$false n'est pas explicitement passé.                  │
│                                                                 │
│  GARDE-FOU 2 — CSV de validation obligatoire                    │
│  Chaque action passe par un CSV intermédiaire.                  │
│  Colonne [Valider] : OUI (exact, majuscules) = exécution.       │
│  Vide, NON, ou toute autre valeur = ignoré.                     │
│                                                                 │
│  GARDE-FOU 3 — Scellage avant exécution                         │
│  Le CSV validé est scellé (SHA-256) avant toute exécution.      │
│  Toute modification post-scellage invalide l'opération.         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Objectifs

1. Désactiver les comptes obsolètes validés par les managers (pas de suppression)
2. Documenter ou révoquer les droits des comptes privilégiés non documentés
3. Nettoyer les groupes orphelins (documenter ou supprimer)

> **Principe de conservation** : aucun compte n'est supprimé en Phase 2.
> Les comptes désactivés sont déplacés dans l'OU `Archived`.
> La suppression définitive est hors périmètre de ce lab (décision RH/juridique).

---

## Livrables

```
phase2-remediation/
├── README-phase2.md                          ← Ce fichier
├── Remediate-StaleAccounts.ps1               ← Désactivation comptes obsolètes
├── Remediate-PrivilegedReview.ps1            ← Révision droits privilégiés
├── Remediate-GroupCleanup.ps1                ← Nettoyage groupes orphelins
└── validation-csv/
    ├── README-validation.md                  ← Instructions de validation CSV
    ├── Template-Validation-Stale.csv         ← Template vierge (comptes obsolètes)
    ├── Template-Validation-Privileged.csv    ← Template vierge (comptes privilégiés)
    └── Template-Validation-Groups.csv        ← Template vierge (groupes)
```

OCM associé : `../ocm/OCM-Phase2-RemediationNotice.md`

---

## Flux de validation — détail

```
Phase 1 produit          Phase 2 reçoit           Manager valide
─────────────────        ──────────────────        ───────────────
phase1-stale.csv    →    CSV_TOVALIDATE     →      Colonne Valider
                         (copie enrichie)           OUI / vide

                                  ↓ après validation
                         Invoke-EvidenceSealer      SHA-256 calculé
                         (scellage CSV)             Empreinte loggée

                                  ↓ après scellage
                         Remediate-*.ps1            -DryRun:$false
                         -CsvPath validated.csv     Exécution réelle
```

---

## Prérequis

- Scripts Phase 1 exécutés — CSV d'audit disponibles dans `/reports/`
- CSV de validation complétés par les managers (colonne `Valider: OUI`)
- PowerShell 5.1+ avec module `ActiveDirectory`
- Droits : `Account Operators` ou `Domain Admin` sur l'AD de lab
- Module `iam-evidence-sealer` disponible pour le scellage (optionnel en lab)

---

## Déroulé opérationnel

### Étape 1 — Récupérer les CSV de validation Phase 1

Les fichiers `phase2-remediation-stale_TOVALIDATE_*.csv` ont été produits
automatiquement par `Audit-StaleAccounts.ps1`. Les transmettre aux managers
concernés avec les instructions du livrable OCM.

### Étape 2 — Collecter les CSV validés

Chaque manager renvoie son CSV avec la colonne `Valider` complétée.
Placer les fichiers validés dans `/validation-csv/`.

### Étape 3 — Sceller les CSV avant exécution

```powershell
# Via le module iam-evidence-sealer (si disponible)
.\Invoke-EvidenceSealer.ps1 -InputFile ".\validation-csv\stale-validated.csv"

# En lab sans le module : calculer manuellement l'empreinte
Get-FileHash ".\validation-csv\stale-validated.csv" -Algorithm SHA256 |
    Select-Object Hash, Path | Export-Csv ".\validation-csv\stale-validated-hash.csv" -NoTypeInformation
```

### Étape 4 — Exécuter en DryRun d'abord

```powershell
# Toujours simuler avant d'exécuter
.\Remediate-StaleAccounts.ps1 -CsvPath ".\validation-csv\stale-validated.csv" -DryRun
.\Remediate-PrivilegedReview.ps1 -CsvPath ".\validation-csv\privileged-validated.csv" -DryRun
.\Remediate-GroupCleanup.ps1 -CsvPath ".\validation-csv\groups-validated.csv" -DryRun
```

### Étape 5 — Exécuter en réel après relecture du DryRun

```powershell
.\Remediate-StaleAccounts.ps1 -CsvPath ".\validation-csv\stale-validated.csv" -DryRun:$false
```

### Étape 6 — Produire le livrable OCM

➜ [`../ocm/OCM-Phase2-RemediationNotice.md`](../ocm/OCM-Phase2-RemediationNotice.md)

---

## Rollback (< 15 min)

En cas d'erreur d'exécution, chaque script Remediate-* produit un fichier
`rollback-*.csv` listant les objets modifiés avec leur état avant modification.

```powershell
# Réactiver un compte désactivé par erreur
Enable-ADAccount -Identity "sam-account"

# Restaurer l'appartenance à un groupe
Add-ADGroupMember -Identity "GRP_NOM" -Members "sam-account"

# Restaurer la description d'un compte
Set-ADUser -Identity "sam-account" -Description "Description restaurée"
```

Le fichier `rollback-*.csv` contient l'ensemble des états antérieurs
pour permettre une restauration script si le volume le justifie.

---

## Checklist de clôture Phase 2

- [ ] CSV de validation reçus et signés par tous les managers concernés
- [ ] CSV scellés (SHA-256 calculé et archivé)
- [ ] DryRun exécuté et relu avant exécution réelle
- [ ] Comptes obsolètes désactivés et déplacés vers OU Archived
- [ ] Comptes privilégiés non documentés : documentés ou droits révoqués
- [ ] Groupes orphelins : documentés ou supprimés
- [ ] Fichier rollback archivé
- [ ] Livrable OCM envoyé aux managers post-exécution

---

## Mapping réglementaire

| Script | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| `Remediate-StaleAccounts.ps1` | A.5.15, A.8.5 | Art. 21 §2(e) | Art. 5(1)(c)(e) |
| `Remediate-PrivilegedReview.ps1` | A.8.2 | Art. 21 §2(a) | — |
| `Remediate-GroupCleanup.ps1` | A.5.15 | Art. 21 §2(i) | — |

---

## Livrable OCM associé

> [`../ocm/OCM-Phase2-RemediationNotice.md`](../ocm/OCM-Phase2-RemediationNotice.md)
>
> Notice d'information aux managers concernés — avant et après exécution.

## Phase suivante

➜ [`../phase3-migration/README-phase3.md`](../phase3-migration/README-phase3.md)

---

*Phase 2 — Remédiation — `iam-ma-integration-lab` — IAM-Lab Framework*
