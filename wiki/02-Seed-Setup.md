# 02 — Seed Setup : générer l'environnement fictif CorpB

> Wiki — `iam-ma-integration-lab`

---

## Pourquoi un seed

Ce lab ne nécessite pas d'accès à un AD réel ni à des applications SaaS
de production. Le dossier `/seed/` fournit tout ce qu'il faut pour
simuler l'environnement CorpB de façon réaliste et reproductible.

Les données sont générées avec `random.seed(42)` — elles sont identiques
à chaque exécution, ce qui garantit la reproductibilité des démonstrations.

---

## Ce que le seed produit

| Fichier | Contenu | Lignes |
|---|---|---|
| `corpb-users.csv` | 312 comptes AD fictifs | 313 (header + données) |
| `corpb-saas-accounts.csv` | 625 comptes SaaS fictifs | 626 |

Ces deux fichiers sont **versionnés dans le repo**. Tu peux les utiliser
directement sans régénérer.

---

## Profils simulés dans corpb-users.csv

Le dataset AD est conçu pour être représentatif d'une PME réelle.
Il contient intentionnellement des anomalies pour que les scripts
d'audit aient quelque chose à détecter.

| Profil | Nombre | Flag CSV |
|---|---|---|
| Comptes actifs standards | 263 | `Enabled=TRUE, IsStale=FALSE` |
| Comptes obsolètes (départs non traités) | 49 | `IsStale=TRUE` |
| Comptes de service | 12 | `IsServiceAccount=TRUE` |
| Comptes privilégiés | 5 | `IsPrivileged=TRUE` |
| Comptes sans MFA | 312 | `MFAEnabled=FALSE` (tous) |
| Domaine legacy | 115 | `Domain=legacy.corpb.local` |

Les comptes obsolètes sont concentrés dans l'OU `Archived` (45 comptes)
et éparpillés dans les autres OUs (~4 comptes). Les comptes privilégiés
non documentés ont une colonne `Description` vide — c'est intentionnel
et c'est ce que `Audit-PrivilegedAccounts.ps1` détecte.

---

## Profils simulés dans corpb-saas-accounts.csv

| Application | Comptes | Risques simulés |
|---|---|---|
| Salesforce | 24 | Compte Admin partagé (`sf-admin@corpb.com`) |
| SlackConnect | 287 | MFA partiel, ~23 orphelins potentiels |
| GitLab CE | 45 | 3 tokens API exposés (`TOKEN_EXPOSE`) |
| Notion | 156 | 12 comptes email personnel (`EMAIL_PERSO`) |
| BambooHR | 8 | Données RH sans MFA |
| AS400 | 4 | Comptes partagés, MFA impossible |
| Jira Cloud | 67 | 9 agents sans département |
| Dropbox Biz | 34 | Shadow IT (`SHADOW_IT`) |

---

## Régénérer les données (optionnel)

Les CSV versionnés dans le repo sont suffisants pour utiliser le lab.
Régénérer uniquement si tu veux modifier la logique de simulation.

```bash
cd seed

# Régénérer le dataset AD
python generate-corpb-users.py
# → Produit corpb-users.csv
# → Affiche les statistiques en console

# Régénérer le dataset SaaS
python generate-corpb-saas.py
# → Produit corpb-saas-accounts.csv
# → Affiche les statistiques en console
```

Sortie attendue de `generate-corpb-users.py` :

```
[OK] corpb-users.csv généré — 312 comptes
     Obsolètes (IsStale)         : 49
     Comptes de service          : 12
     Comptes privilégiés         : 5
     Désactivés (Enabled=FALSE)  : 49
     Domaine legacy.corpb.local  : 115
     MFA activé                  : 0
```

---

## Seeder un AD de lab (optionnel)

Si tu disposes d'un DC de lab (Windows Server avec AD DS), le script
PowerShell peut créer toute la structure CorpB dans ton AD.

```powershell
cd seed

# Simulation — voir ce qui serait créé
.\Seed-CorpB-AD.ps1 -DryRun

# Exécution réelle — adapter le TargetOU à ton environnement
.\Seed-CorpB-AD.ps1 -DryRun:$false -TargetOU "OU=CorpB-Lab,DC=lab,DC=local"
```

Le script crée dans l'ordre :
1. L'OU racine `CorpB-Lab`
2. Les 9 sous-OUs (corpb.local et legacy.corpb.local)
3. Les 18 groupes de sécurité (dont 4 intentionnellement sans description)
4. Les 312 utilisateurs avec leurs groupes d'appartenance

**Nettoyer après utilisation :**
```powershell
Remove-ADOrganizationalUnit -Identity "OU=CorpB-Lab,DC=lab,DC=local" `
    -Recursive -Confirm:$false
```

---

## Sans AD — mode simulation

Tous les scripts du lab ont un paramètre `-Simulation` qui lit les CSV
du dossier `/seed/` au lieu d'interroger un AD réel.

```powershell
# Exemple — audit sans AD
.\phase1-audit\Audit-ADInventory.ps1 -Simulation `
    -SimulationCsvPath ".\seed\corpb-users.csv" `
    -OutputPath ".\reports\"
```

Le mode simulation produit des sorties identiques au mode live.
Les seules différences sont la colonne `AuditSource` (`SIMULATION_CSV`
vs `AD_LIVE`) et l'absence de connexion réseau.

---

*Wiki page 02 — `iam-ma-integration-lab` — IAM-Lab Framework*
