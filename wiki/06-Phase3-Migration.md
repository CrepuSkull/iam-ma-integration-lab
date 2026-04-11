# 06 — Phase 3 : Migration vers Entra ID

> Wiki — `iam-ma-integration-lab`

---

## Le Shadow Mode — mécanisme central

Le Shadow Mode est le mécanisme de sécurité qui distingue ce lab d'une
migration naïve. Il permet de provisionner les comptes CorpB dans Entra ID
**sans les activer** — ils existent dans le tenant cible, leurs attributs
sont configurés, leurs groupes sont assignés, mais ils ne peuvent pas
se connecter.

La bascule effective (activer les comptes Entra ID + désactiver les sources AD)
n'intervient qu'après validation explicite du delta par le script d'audit
post-migration et Go/NoGo du DSI CorpA.

```
AD CorpB (source)          Entra ID CorpA (cible)
─────────────────          ──────────────────────
n.perrin  [ACTIF]    →     n.perrin@corpa.fr  [Shadow — désactivé]
b.couture [ACTIF]    →     b.couture@corpa.fr [Shadow — désactivé]

         ↓ Audit-PostMigrationDelta confirme delta = 0

n.perrin  [DÉSACTIVÉ] ←   n.perrin@corpa.fr  [J-Day — activé]
```

---

## Les trois scripts — séquence obligatoire

### Étape 1 — `Audit-PreMigrationChecklist.ps1` (J-5)

Évalue 12 points de contrôle en 4 blocs. Un seul point CRITIQUE en NO-GO
bloque la migration — le script le signale explicitement.

Points CRITIQUE dans le scénario CorpB sans Phase 2 complète :
- Comptes obsolètes encore actifs → NO-GO
- Comptes privilégiés non documentés → NO-GO
- Validation DPO manquante → NO-GO

```powershell
.\Audit-PreMigrationChecklist.ps1 -Simulation -OutputPath "..\reports\"
```

### Étape 2 — `Migrate-UsersToEntraID.ps1` — trois modes

Le même script gère les trois étapes de migration via des paramètres distincts.

**Mode 1 : DryRun (simulation)**
```powershell
.\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" -DryRun
```

**Mode 2 : Shadow Mode (J-2) — provisioning désactivé**
```powershell
.\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" `
    -DryRun:$false -ShadowMode -TargetDomain "corpa.onmicrosoft.com"
```

**Mode 3 : J-Day — activation des comptes Shadow**
```powershell
.\Migrate-UsersToEntraID.ps1 -CsvPath "..\seed\corpb-users.csv" `
    -DryRun:$false -ActivateShadowAccounts -TargetDomain "corpa.onmicrosoft.com"
```

**Comptes exclus de la migration automatique :**
- `IsServiceAccount=TRUE` — traitement manuel séparé
- `IsStale=TRUE` — déjà traités en Phase 2
- `Enabled=FALSE` — déjà désactivés

**Mapping d'attributs AD → Entra ID :**

| AD | Entra ID |
|---|---|
| `sAMAccountName` | `mailNickname` + préfixe UPN |
| `DisplayName` | `displayName` |
| `GivenName` / `Surname` | `givenName` / `surname` |
| `Department` | `department` |
| `Title` | `jobTitle` |
| `EmailAddress` | `mail` + UPN (`@corpa.onmicrosoft.com`) |

### Étape 3 — `Audit-PostMigrationDelta.ps1` (J-1)

Compare les comptes éligibles du CSV source avec les comptes provisionnés
dans Entra ID. Trois états possibles :

- **MATCH** : compte AD source trouvé dans Entra ID — OK
- **MANQUANT** : compte AD source absent d'Entra ID — à re-provisionner
- **SURPLUS** : compte Entra ID sans correspondance AD — à investiguer

Un delta MANQUANT ou SURPLUS non justifié produit un statut **NO-GO J-Day**.
Le rapport inclut la commande de correction directement dans le texte.

En simulation, 5% de comptes manquants sont injectés délibérément pour
que le lab produise un delta non-nul réaliste.

---

## Fichier de mots de passe temporaires

Le script de migration produit un fichier `phase3-migration-credentials_*.csv`
contenant les mots de passe temporaires générés pour chaque compte.

> Ce fichier est marqué **SENSIBLE** dans les logs du script.
> Il ne doit pas être versionné dans Git.
> Il doit être chiffré ou transmis par canal sécurisé aux équipes qui
> gèrent la communication J-Day.

Chaque mot de passe est généré aléatoirement, avec `ForceChangePasswordNextSignIn=true`.

---

## Rollback Phase 3

**Avant J-Day** (Shadow Mode actif) : les comptes Entra ID peuvent être
supprimés — les comptes AD source restent actifs, aucun impact utilisateur.

**Après J-Day** : réactiver les comptes AD source, désactiver les comptes
Entra ID. Le fichier `phase3-migration-rollback_*.csv` contient les
commandes Graph pour chaque compte.

---

## Prérequis techniques Phase 3

```powershell
# Module Microsoft Graph (obligatoire pour mode live)
Install-Module Microsoft.Graph -Scope CurrentUser

# Vérification
Get-Module -ListAvailable Microsoft.Graph
```

Permissions minimales requises dans Entra ID CorpA :
- Audit seul : `User.Read.All`, `Group.Read.All`
- Migration : `User.ReadWrite.All`, `Group.ReadWrite.All`, `Directory.ReadWrite.All`

---

*Wiki page 06 — `iam-ma-integration-lab` — IAM-Lab Framework*
