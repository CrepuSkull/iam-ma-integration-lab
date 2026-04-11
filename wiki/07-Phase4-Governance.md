# 07 — Phase 4 : Gouvernance post-intégration

> Wiki — `iam-ma-integration-lab`

---

## La migration est un événement — la gouvernance est permanente

La Phase 4 commence le lendemain de J-Day et ne se termine pas avec ce lab.
Elle établit les contrôles qui maintiennent l'environnement fusionné propre
et conforme dans la durée.

Son périmètre dépasse intentionnellement l'AD : les 625 comptes SaaS CorpB
existent toujours dans leurs applications respectives après J-Day. Ils doivent
être gouvernés, alignés avec la politique CorpA, ou désactivés.

---

## Chronologie recommandée

| Moment | Action | Script |
|---|---|---|
| J+1 | Détecter les orphelins post-migration | `Audit-OrphanAccounts.ps1` |
| J+7 | Auditer les conflits RBAC | `Audit-RBACConflicts.ps1` |
| J+7 | Auditer les comptes invités | `Audit-GuestAccounts.ps1` |
| J+30 | Gouvernance SaaS post-fusion | `Audit-SaaSPostFusion.py` |
| J+90 | Recertification managériale | → `iam-governance-lab` |

---

## Les quatre scripts

### `Audit-OrphanAccounts.ps1` — J+1

Détecte les comptes Entra ID CorpB migrés qui présentent des signaux
d'orphelin post-fusion.

**Quatre signaux** :
- `SANS_CONNEXION` : actif mais aucune connexion depuis J-Day
- `SANS_DEPARTEMENT` : attribut Department vide dans Entra ID
- `SANS_MANAGER` : pas de manager assigné (hors Direction)
- `HORS_GROUPE` : non membre d'un groupe de migration CorpB

Un compte avec 3+ signaux est classé CRITIQUE. En simulation, ~14% des
comptes déclenchent au moins un signal.

```powershell
.\Audit-OrphanAccounts.ps1 -Simulation -OutputPath "..\reports\"
```

### `Audit-RBACConflicts.ps1` — J+7

Détecte les situations où un utilisateur CorpB migré cumule des rôles
incompatibles dans l'environnement fusionné.

**Matrice SoD intégrée** — 7 paires de rôles incompatibles :

| Paire | Risque | Sévérité |
|---|---|---|
| Commercial + Finance | Fraude commandes/paiements | CRITIQUE |
| CRM Salesforce + Finance | Manipulation tarifs | CRITIQUE |
| DevOps + Domain Admin | Infrastructure non cloisonnée | CRITIQUE |
| RH + Finance | Accès salaires + validation | ÉLEVÉ |
| Dev + AS400 | Modification données production | ÉLEVÉ |
| Prestataires + Direction | Périmètre injustifié | ÉLEVÉ |
| BambooHR + Finance | Paie + validation | MODÉRÉ |

Deux types supplémentaires : **privilege escalation** (compte CorpB dans
un groupe CorpA hors périmètre de migration prévu) et **double identité**
(même DisplayName sur plusieurs comptes — homonymes ou doublons).

### `Audit-GuestAccounts.ps1` — J+7

Cartographie les comptes Guest dans le tenant CorpA. Quatre profils à risque :
- `ANCIEN_INVITE_CORPB` : Guest créé avant la fusion, à requalifier
- `INVITE_SANS_ACTIVITE` : inactif depuis > 30 jours
- `INVITE_ACCES_SENSIBLES` : accès à des groupes Finance, RH, Direction
- `INVITE_NON_NOMME` : DisplayName de type `#EXT#user123`

Un Guest avec accès Finance ET inactif depuis 90 jours est CRITIQUE
automatiquement dans le script.

### `Audit-SaaSPostFusion.py` — J+30

Croise les 625 comptes SaaS CorpB avec l'état de migration AD.
Pour chaque compte SaaS, détermine l'action de gouvernance :

| Action | Déclencheur |
|---|---|
| `REVOQUER_URGENT` | Token exposé détecté |
| `TRAITEMENT_SPECIAL` | Compte dans la liste des cas critiques |
| `DESACTIVER` | Utilisateur AD désactivé ou parti |
| `REGULARISER` | Shadow IT ou email personnel |
| `INVESTIGUER` | Aucune correspondance AD trouvée |
| `CONSERVER` | Utilisateur AD actif — accès légitime |

```bash
python phase4-governance/Audit-SaaSPostFusion.py \
    --saas seed/corpb-saas-accounts.csv \
    --users seed/corpb-users.csv \
    --output reports/
```

---

## Référence JML — `iam-identity-lifecycle-lab`

Le cycle Joiner/Mover/Leaver pour les collaborateurs CorpB intégrés
est documenté dans le repo [`IAM-Lab-Identity-Lifecycle`](https://github.com/CrepuSkull/IAM-Lab-Identity-Lifecycle).

Ce lab ne duplique pas ce travail. La Phase 4 initialise le cycle JML
en transférant la responsabilité des identités aux managers CorpA
via le livrable OCM de passation.

**Ce que les managers doivent déclarer immédiatement :**
- Départ d'un collaborateur CorpB → désactivation du jour même
- Changement de poste → mise à jour des droits
- Arrivée d'un nouveau collaborateur CorpA → provisioning standard

---

## Dissoudre les groupes de transition

Les groupes `GRP_CorpB_*_Migrated` créés lors de la Phase 3 doivent
être dissous dans les 3 mois suivant J-Day, après validation managériale
que tous les collaborateurs ont bien été intégrés dans les groupes CorpA
permanents.

Cette dissolution est documentée dans le rapport de clôture Phase 5.

---

*Wiki page 07 — `iam-ma-integration-lab` — IAM-Lab Framework*
