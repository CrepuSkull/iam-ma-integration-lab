# 🔍 Phase 1 — Audit et cartographie (CorpB AD + SaaS)

> `iam-ma-integration-lab` / phase1-audit
> Langue : Français | Cible : ingénieur IAM, RSSI

---

## Principe fondamental

**Lecture seule. Sans exception.**

Aucun script de cette phase ne modifie quoi que ce soit dans l'AD CorpB ni dans les
applications SaaS. Les paramètres `-DryRun` ne s'appliquent pas ici — ils n'ont pas
de sens pour des scripts qui, par construction, n'écrivent jamais.

Cette phase produit de la **connaissance documentée et traçable**. Elle ne produit
pas d'actions. Toute action appartient à la Phase 2.

---

## Objectifs

1. Produire un inventaire exhaustif des comptes AD CorpB (actifs, inactifs, de service, privilégiés)
2. Cartographier les groupes de sécurité et leurs membres
3. Identifier les comptes à risque selon des critères mesurables
4. Évaluer la politique de mots de passe
5. Consolider les résultats SaaS (depuis `Audit-SaaSRisk.py` Phase 0) dans un rapport unifié

---

## Livrables

| Fichier | Nature | Sortie |
|---|---|---|
| `Audit-ADInventory.ps1` | Script PowerShell | `phase1-inventory.csv` |
| `Audit-StaleAccounts.ps1` | Script PowerShell | `phase1-stale.csv` |
| `Audit-PrivilegedAccounts.ps1` | Script PowerShell | `phase1-privileged.csv` |
| `Audit-GroupMembership.ps1` | Script PowerShell | `phase1-groups.csv` |
| `Audit-PasswordPolicy.ps1` | Script PowerShell | `phase1-pwdpolicy.csv` |
| `../ocm/OCM-Phase1-StakeholderBriefing.md` | Livrable OCM | Restitution référents CorpB |

Tous les CSV de sortie atterrissent dans `/reports/` (créé automatiquement).

---

## Prérequis

- Seed Phase 2 exécuté **ou** accès lecture à un AD CorpB réel
- Compte AD avec droits : `Domain Users` + `Read` sur toutes les OUs
- PowerShell 5.1+ avec module `ActiveDirectory`
- Fichier `../seed/corpb-users.csv` disponible (mode simulation sans AD)

---

## Déroulé opérationnel

### Étape 1 — Inventaire complet (Audit-ADInventory.ps1)

Point de départ obligatoire. Produit la vue d'ensemble de tous les comptes.

```powershell
.\Audit-ADInventory.ps1 -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" -OutputPath "..\reports\"
```

### Étape 2 — Détection comptes obsolètes (Audit-StaleAccounts.ps1)

```powershell
.\Audit-StaleAccounts.ps1 -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" `
    -InactiveDays 90 -OutputPath "..\reports\"
```

### Étape 3 — Audit comptes privilégiés (Audit-PrivilegedAccounts.ps1)

```powershell
.\Audit-PrivilegedAccounts.ps1 -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" `
    -OutputPath "..\reports\"
```

### Étape 4 — Cartographie des groupes (Audit-GroupMembership.ps1)

```powershell
.\Audit-GroupMembership.ps1 -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" `
    -OutputPath "..\reports\"
```

### Étape 5 — Politique de mots de passe (Audit-PasswordPolicy.ps1)

```powershell
.\Audit-PasswordPolicy.ps1 -Domain "corpb.local" -OutputPath "..\reports\"
```

### Étape 6 — Restitution OCM

Produire le livrable de restitution aux référents CorpB dans les 48h suivant l'audit.

➜ [`../ocm/OCM-Phase1-StakeholderBriefing.md`](../ocm/OCM-Phase1-StakeholderBriefing.md)

---

## Checklist de clôture Phase 1

- [ ] `phase1-inventory.csv` produit — nombre de lignes = nombre de comptes AD
- [ ] `phase1-stale.csv` produit — relu par le RSSI CorpA
- [ ] `phase1-privileged.csv` produit — validé par Sophie Arnaud (DSI CorpA)
- [ ] `phase1-groups.csv` produit — groupes orphelins identifiés
- [ ] `phase1-pwdpolicy.csv` produit — écarts documentés
- [ ] Livrable OCM envoyé aux référents CorpB dans les 48h
- [ ] Tous les CSV archivés et empreintes SHA-256 calculées (→ Phase 5)

---

## Mapping réglementaire

| Script | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| `Audit-ADInventory.ps1` | A.5.15, A.8.5 | Art. 21 §2(i) | Art. 30 |
| `Audit-StaleAccounts.ps1` | A.8.5 | Art. 21 §2(e) | Art. 5(1)(e) |
| `Audit-PrivilegedAccounts.ps1` | A.8.2 | Art. 21 §2(a) | — |
| `Audit-GroupMembership.ps1` | A.5.15 | Art. 21 §2(i) | — |
| `Audit-PasswordPolicy.ps1` | A.8.5, A.8.6 | Art. 21 §2(a) | — |

---

## Référence croisée

Les scripts `Audit-StaleAccounts.ps1` et `Audit-PrivilegedAccounts.ps1` sont des
adaptations des scripts équivalents de [`iam-foundation-lab`](https://github.com/CrepuSkull/iam-foundation-lab),
contextualisés pour le scénario M&A (multi-OU, multi-domaines, flags IsStale/IsPrivileged
cohérents avec le dataset seed).

---

## Livrable OCM associé

> [`../ocm/OCM-Phase1-StakeholderBriefing.md`](../ocm/OCM-Phase1-StakeholderBriefing.md)
>
> Restitution des résultats d'audit aux référents métier CorpB.
> À produire dans les 48h suivant la fin de l'audit.

## Phase suivante

➜ [`../phase2-remediation/README-phase2.md`](../phase2-remediation/README-phase2.md)

---

*Phase 1 — Audit — `iam-ma-integration-lab` — IAM-Lab Framework*
