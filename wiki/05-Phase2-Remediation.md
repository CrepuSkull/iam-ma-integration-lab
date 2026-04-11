# 05 — Phase 2 : Remédiation et flux de validation CSV

> Wiki — `iam-ma-integration-lab`

---

## Le flux de validation — comprendre avant d'exécuter

C'est la phase la plus importante à comprendre correctement avant de toucher
quoi que ce soit. Elle introduit le mécanisme de validation humaine qui
est le cœur de sécurité de tout le framework.

```
Phase 1 produit          Phase 2 reçoit           Manager valide
─────────────────        ──────────────────        ──────────────
phase1-stale.csv    →    CSV_TOVALIDATE     →      Valider = OUI
                         (colonne Valider           (exact, maj.)
                          vide)
                                  │
                                  ▼
                         Scellage SHA-256
                         (avant exécution)
                                  │
                                  ▼
                         Remediate-*.ps1
                         -DryRun:$false
                         (uniquement sur OUI)
```

**La colonne `Valider` ne tolère qu'une seule valeur déclenchante : `OUI`**
(majuscules, sans espace, sans accent). Toute autre valeur — `Oui`, `oui`,
`YES`, `X`, vide — est traitée comme un refus.

---

## Les trois scripts de remédiation

### `Remediate-StaleAccounts.ps1`

Traite les comptes validés avec `Valider=OUI` depuis le CSV Phase 1.
Pour chaque compte autorisé :

1. Désactive le compte AD (`Disable-ADAccount`)
2. Ajoute une description horodatée avec le nom du validateur
3. Déplace le compte vers l'OU Archived

**Important :** aucun compte n'est supprimé. La suppression définitive
est une décision RH/juridique hors périmètre de ce lab.

```powershell
# Toujours simuler en premier
.\Remediate-StaleAccounts.ps1 `
    -CsvPath ".\validation-csv\stale-validated.csv" -DryRun

# Exécution après relecture du DryRun
.\Remediate-StaleAccounts.ps1 `
    -CsvPath ".\validation-csv\stale-validated.csv" -DryRun:$false
```

### `Remediate-PrivilegedReview.ps1`

Trois actions selon la valeur de `RecommendedAction` dans le CSV :

| RecommendedAction | Action exécutée |
|---|---|
| `DOCUMENTER_PUIS_REVUE` | Mise à jour de la description AD |
| `REVUE_MANUELLE_RSSI` | Retrait du groupe privilégié validé |
| `DESACTIVER` | Désactivation du compte |

**Avertissement** : la révocation de droits d'administration est irréversible
à chaud. Le DryRun est encore plus important ici.

### `Remediate-GroupCleanup.ps1`

Trois actions selon `RecommendedAction` :

| RecommendedAction | Action |
|---|---|
| `DOCUMENTER_*` | Ajout d'une description au groupe |
| `VIDER` | Retrait de tous les membres |
| `SUPPRIMER` | Suppression — **uniquement si le groupe est physiquement vide** |

Ce dernier garde-fou est codé dans le script : même si le CSV dit
`SUPPRIMER`, le script vérifie l'état réel du groupe au moment de
l'exécution avant de procéder. Un groupe avec des membres ne peut
pas être supprimé par ce script.

---

## Le sous-dossier `validation-csv/`

Ce sous-dossier contient les instructions de validation et les templates
vierges. Il ne contient **pas** les CSV pré-remplis nominatifs — ceux-ci
sont transmis directement aux managers par email pour éviter d'exposer
des données personnelles dans le repo.

`README-validation.md` est rédigé pour un manager non-technicien :
instructions pas-à-pas pour ouvrir le CSV, comprendre la colonne Valider,
et gérer les cas ambigus.

---

## Rollback < 15 minutes

Chaque script de remédiation produit un fichier `rollback_*.csv` avant
toute modification. Ce fichier contient l'état exact de chaque objet
avant modification.

```powershell
# Réactiver un compte désactivé par erreur
Enable-ADAccount -Identity "p.nom"

# Restaurer l'appartenance à un groupe
Add-ADGroupMember -Identity "GRP_NOM" -Members "p.nom"

# Restaurer une description
Set-ADUser -Identity "p.nom" -Description "Description restaurée"
```

Pour un volume important, le fichier rollback peut être parcouru
par script. Cette logique est documentée dans chaque README de phase.

---

## Cas particulier : les comptes de service

Les comptes de service (`IsServiceAccount=TRUE`) ne doivent jamais
être validés sans confirmation de l'équipe IT CorpB (Julien Faure
ou Thierry Vogt dans le scénario). Un compte de service mal désactivé
peut provoquer l'arrêt d'une application en production.

Le script affiche `REVUE_MANUELLE` dans la colonne `RecommendedAction`
pour ces comptes — c'est un signal que le manager seul ne peut pas valider.

---

*Wiki page 05 — `iam-ma-integration-lab` — IAM-Lab Framework*
