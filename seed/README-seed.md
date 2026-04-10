# 🌱 README-seed.md — Génération de l'environnement fictif CorpB

> `iam-ma-integration-lab` / seed
> Langue : Français | Cible : ingénieur IAM, contributeur lab

---

## Objectif du dossier seed

Le dossier `/seed/` permet de **recréer intégralement l'environnement fictif CorpB** dans un lab sans accès à un AD réel. Il produit trois datasets cohérents entre eux :

| Fichier produit | Contenu | Utilisé par |
|---|---|---|
| `corpb-users.csv` | 312 comptes AD fictifs | `Seed-CorpB-AD.ps1`, `Audit-ADInventory.ps1` |
| `corpb-saas-accounts.csv` | 625 comptes SaaS fictifs | `Audit-SaaSRisk.py`, Phase 1, Phase 4 |
| `seed-log.csv` | Log d'exécution du seed AD | Traçabilité lab |

---

## Contenu du dossier

```
/seed/
├── generate-corpb-users.py       ← Générateur Python des 312 comptes AD
├── generate-corpb-saas.py        ← Générateur Python des 625 comptes SaaS
├── Seed-CorpB-AD.ps1             ← Script PowerShell de seed AD (DryRun par défaut)
├── corpb-users.csv               ← Dataset AD généré (versionné pour le lab)
├── corpb-saas-accounts.csv       ← Dataset SaaS généré (versionné pour le lab)
└── README-seed.md                ← Ce fichier
```

> `corpb-users.csv` et `corpb-saas-accounts.csv` sont **versionnés dans le repo**.
> Ils peuvent être utilisés directement sans régénération.
> Les générateurs Python permettent de comprendre la logique et de personnaliser les datasets.

---

## Prérequis

### Pour les générateurs Python
```
Python 3.10+
Aucune dépendance externe — bibliothèques standard uniquement
```

### Pour Seed-CorpB-AD.ps1
```
Windows PowerShell 5.1+ ou PowerShell 7+
Module ActiveDirectory (RSAT ou Windows Server avec AD DS)
Droits Domain Admin sur le domaine de lab
corpb-users.csv dans le même répertoire
```

---

## Utilisation

### Étape 1 — Régénérer les datasets (optionnel)

Les CSV sont déjà versionnés. Régénérer uniquement si tu souhaites modifier les données fictives.

```bash
# Régénérer le dataset AD
python generate-corpb-users.py
# Produit : corpb-users.csv

# Régénérer le dataset SaaS
python generate-corpb-saas.py
# Produit : corpb-saas-accounts.csv
```

> Les deux générateurs utilisent `random.seed(42)` — les données sont **reproductibles à l'identique**.

### Étape 2 — Simuler le seed AD (DryRun)

```powershell
# Simulation complète — aucune écriture AD
.\Seed-CorpB-AD.ps1 -DryRun

# Sortie attendue :
# [DRYRUN] CREATE_OU  | OU : OU=CorpB-Lab,DC=lab,DC=local
# [DRYRUN] CREATE_OU  | OU : OU=Direction,...
# [DRYRUN] CREATE_GROUP | Group : GRP_All_CorpB
# [DRYRUN] CREATE_USER  | User : t.moulin  Direction
# ...
# SYNTHÈSE : 312 utilisateurs simulés
```

### Étape 3 — Exécuter le seed réel (lab uniquement)

```powershell
# Adapter le TargetOU à ton environnement de lab
.\Seed-CorpB-AD.ps1 -DryRun:$false -TargetOU "OU=CorpB-Lab,DC=lab,DC=local"

# Vérification post-seed
Get-ADUser -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" -Filter * | Measure-Object
# Expected : 312

Get-ADGroup -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" -Filter * | Measure-Object
# Expected : 18
```

---

## Structure des données simulées

### Dataset AD — corpb-users.csv

**Colonnes :**

| Colonne | Type | Description |
|---|---|---|
| `UID` | String | Identifiant unique lab (CB0001–CB0312) |
| `sAMAccountName` | String | Login AD (p.nom) |
| `UserPrincipalName` | String | UPN (p.nom@corpb.local ou @legacy.corpb.local) |
| `GivenName` / `Surname` | String | Prénom / Nom fictifs |
| `Department` | String | OU d'appartenance |
| `Domain` | String | corpb.local ou legacy.corpb.local |
| `Enabled` | Boolean | TRUE / FALSE |
| `PasswordNeverExpires` | Boolean | TRUE sur comptes de service et obsolètes |
| `LastLogonDate` | Date | Ancienne si compte obsolète |
| `PasswordLastSet` | Date | Ancienne si compte obsolète |
| `WhenCreated` | Date | Date de création simulée |
| `MemberOf` | String | Groupes séparés par `\|` |
| `IsStale` | Boolean | Compte obsolète simulé |
| `IsPrivileged` | Boolean | Compte avec droits étendus |
| `IsServiceAccount` | Boolean | Compte de service applicatif |
| `MFAEnabled` | Boolean | FALSE pour tous (CorpB n'a pas de MFA) |
| `Description` | String | Vide sur les comptes privilégiés non documentés |

**Répartition par OU :**

| OU | Domaine | Comptes | Dont obsolètes |
|---|---|---|---|
| Direction | corpb.local | 12 | 0 |
| Commercial | corpb.local | 78 | ~2 |
| Technique | corpb.local | 85 | ~2 |
| RH | corpb.local | 22 | ~1 |
| Prestataires | legacy.corpb.local | 55 | ~3 |
| ServiceCompt | legacy.corpb.local | 15 | ~1 |
| Archived | legacy.corpb.local | 45 | 45 (tous) |
| **Total** | | **312** | **~54** |

### Dataset SaaS — corpb-saas-accounts.csv

**Colonnes clés :**

| Colonne | Description |
|---|---|
| `UID_SaaS` | Identifiant unique SaaS (SAAS0001–SAAS0625) |
| `Application` | Nom de l'application |
| `Login_SaaS` | Identifiant de connexion (email ou SAM) |
| `EmailAD` | Email AD correspondant (vide si email perso) |
| `ComptePartage` | OUI si compte partagé entre utilisateurs |
| `MFA_Active` | OUI / NON / PARTIEL |
| `ShadowIT` | OUI pour Dropbox Biz |
| `IsOrphan` | OUI si compte probablement orphelin |
| `IsSpecialAccount` | OUI pour les comptes à risque documentés |
| `RiskFlag` | TOKEN_EXPOSE / COMPTE_PARTAGE / SHADOW_IT / EMAIL_PERSO |

**Comptes spéciaux simulés :**

| Application | Compte | RiskFlag | Description |
|---|---|---|---|
| Salesforce | `sf-admin@corpb.com` | COMPTE_PARTAGE | Admin partagé Nadège Perrin + ex-collègue |
| GitLab CE | `token-api-bc` | TOKEN_EXPOSE | Token perso dans commit #a3f2c1 |
| GitLab CE | `token-api-deploy` | TOKEN_EXPOSE | Token CI/CD en .env committé |
| GitLab CE | `token-api-legacy` | TOKEN_EXPOSE | Token ancien projet non révoqué |
| AS400 | `QSECOFR` | COMPTE_PARTAGE | Profil sécurité IBM i — mdp générique |
| AS400 | `CORPB_PROD` | COMPTE_PARTAGE | Compte générique partagé entre 3 users |

---

## Nettoyer l'environnement de lab

```powershell
# Supprimer toute la structure CorpB du lab AD
Remove-ADOrganizationalUnit -Identity "OU=CorpB-Lab,DC=lab,DC=local" -Recursive -Confirm:$false

# Vérification
Get-ADOrganizationalUnit -Filter "Name -eq 'CorpB-Lab'" -ErrorAction SilentlyContinue
# Expected : aucun résultat
```

> ⚠️ Cette commande supprime **toute** la structure CorpB-Lab de façon irréversible.
> Ne jamais exécuter en dehors d'un environnement de lab dédié.

---

## Phase suivante

Une fois le seed exécuté (ou les CSV chargés), passer à :

➜ [`../phase1-audit/README-phase1.md`](../phase1-audit/README-phase1.md)

---

*Seed — `iam-ma-integration-lab` — IAM-Lab Framework*
