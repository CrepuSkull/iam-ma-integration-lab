# 🏛️ Phase 4 — Gouvernance post-intégration

> `iam-ma-integration-lab` / phase4-governance
> Langue : Français | Cible : ingénieur IAM, RSSI, managers CorpA

---

## Principe fondamental

**La migration est un événement. La gouvernance est un état permanent.**

La Phase 4 commence le lendemain de J-Day et ne se termine pas.
Elle établit les contrôles continus qui garantissent que l'environnement
fusionné reste propre, gouverné et conforme dans la durée.

Son périmètre est étendu au SaaS : la migration AD vers Entra ID ne suffit
pas. Les 625 comptes SaaS CorpB existent toujours dans leurs applications
respectives. Ils doivent être gouvernés, alignés ou désactivés.

---

## Objectifs

1. Détecter les comptes orphelins post-migration (comptes Entra ID sans
   rattachement département ou sans activité depuis J-Day)
2. Auditer les conflits RBAC entre rôles CorpA et rôles hérités CorpB
3. Auditer et gouverner les comptes invités hérités de CorpB
4. Auditer les comptes SaaS CorpB post-fusion — aligner ou désactiver
5. Initialiser le cycle JML pour les nouveaux collaborateurs intégrés

---

## Livrables

```
phase4-governance/
├── README-phase4.md                   ← Ce fichier
├── Audit-OrphanAccounts.ps1           ← Détection orphelins Entra ID post-migration
├── Audit-RBACConflicts.ps1            ← Conflits de rôles CorpA/CorpB
├── Audit-GuestAccounts.ps1            ← Comptes invités hérités CorpB
└── Audit-SaaSPostFusion.py            ← Gouvernance comptes SaaS post-intégration
```

OCM associé : `../ocm/OCM-Phase4-GovernanceHandover.md`

Référence JML : [`IAM-Lab-Identity-Lifecycle`](https://github.com/CrepuSkull/IAM-Lab-Identity-Lifecycle)
— Le cycle Joiner/Mover/Leaver pour les collaborateurs CorpB intégrés
est documenté dans ce repo. Ne pas dupliquer ici.

---

## Chronologie post-J-Day

```
J-Day          J+1          J+7          J+30         Trimestriel
───────────────────────────────────────────────────────────────────
Activation     Audit-       Audit-       Audit-       Recertification
comptes        Orphan       RBAC         SaaS          managériale
Shadow         Accounts     Conflicts    PostFusion    (iam-governance-lab)
               ↓            ↓            ↓
               Rapport      CSV          Rapport
               orphelins    validation   SaaS
                            managers
```

---

## Prérequis

- Phase 3 J-Day exécuté — comptes CorpB actifs dans Entra ID
- Module `Microsoft.Graph` PowerShell installé
- Python 3.10+ pour `Audit-SaaSPostFusion.py`
- Fichiers CSV seed disponibles pour le mode simulation
- Permissions Entra ID : `User.Read.All`, `Group.Read.All`,
  `AuditLog.Read.All` (pour les logs de connexion)

---

## Mapping réglementaire

| Script | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| `Audit-OrphanAccounts.ps1` | A.5.15 | Art. 21 §2(e) | Art. 5(1)(c)(e) |
| `Audit-RBACConflicts.ps1` | A.5.3, A.5.15 | Art. 21 §2(a) | — |
| `Audit-GuestAccounts.ps1` | A.5.15, A.5.18 | Art. 21 §2(i) | Art. 5(1)(c) |
| `Audit-SaaSPostFusion.py` | A.5.15, A.5.18 | Art. 21 §2(i) | Art. 28, Art. 5(1)(c) |

---

## Livrable OCM associé

> [`../ocm/OCM-Phase4-GovernanceHandover.md`](../ocm/OCM-Phase4-GovernanceHandover.md)
>
> Document de passation aux managers CorpA — comment gouverner
> les nouvelles identités intégrées dans la durée.

## Phase suivante

➜ [`../phase5-evidence/README-phase5.md`](../phase5-evidence/README-phase5.md)

---

*Phase 4 — Gouvernance — `iam-ma-integration-lab` — IAM-Lab Framework*
