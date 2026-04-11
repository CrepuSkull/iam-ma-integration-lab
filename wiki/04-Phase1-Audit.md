# 04 — Phase 1 : Audit AD et SaaS

> Wiki — `iam-ma-integration-lab`

---

## Règle absolue : lecture seule

Aucun des cinq scripts de cette phase ne modifie quoi que ce soit dans l'AD
ni dans les applications SaaS. Cette règle est architecturale — elle n'est
pas un paramètre qu'on peut désactiver.

Si un script d'audit modifiait des données, il ne serait plus un audit.

---

## Les cinq scripts — ordre d'exécution

### Script 1 — `Audit-ADInventory.ps1` (point d'entrée)

Produit la vue d'ensemble : tous les 312 comptes, leurs attributs, leur
score de risque composite (0-100 sur quatre critères), leur niveau de risque
(CRITIQUE / ÉLEVÉ / MODÉRÉ / FAIBLE).

```powershell
# Mode simulation (sans AD)
.\Audit-ADInventory.ps1 -Simulation `
    -SimulationCsvPath "..\seed\corpb-users.csv" `
    -OutputPath "..\reports\"

# Mode AD réel
.\Audit-ADInventory.ps1 `
    -SearchBase "OU=CorpB-Lab,DC=lab,DC=local" `
    -OutputPath "..\reports\"
```

**Sortie :** `phase1-inventory_YYYYMMDD.csv` + rapport texte synthétique.

Le score de risque composite est calculé ainsi :

| Critère | Poids |
|---|---|
| Compte obsolète (IsStale) | +30 |
| Compte privilégié | +25 |
| Mot de passe sans expiration | +15 |
| Inactivité > 365 jours | +20 |
| Sans description | +10 |

### Script 2 — `Audit-StaleAccounts.ps1`

Détecte les comptes obsolètes selon trois critères combinables :
inactivité > N jours, mot de passe > N jours, comptes actifs dans l'OU Archived.

Produit **deux fichiers** : le rapport d'audit (`phase1-stale_*.csv`) et
un CSV de validation pré-rempli pour la Phase 2 avec colonne `Valider` vide.

```powershell
.\Audit-StaleAccounts.ps1 -Simulation -InactiveDays 90 -OutputPath "..\reports\"
```

Résultats CorpB simulés : 49 comptes détectés dont 45 via OU Archived active,
4 via inactivité hors Archived.

### Script 3 — `Audit-PrivilegedAccounts.ps1`

Cartographie les cinq comptes avec droits étendus. Deux d'entre eux ont
la colonne `Description` vide — le script les classe CRITIQUE automatiquement.

La liste des groupes sensibles est configurable via le code (`$PrivilegedGroups`).

### Script 4 — `Audit-GroupMembership.ps1`

Produit deux vues complémentaires : groupes (avec statut orphelin/vide/avec membres)
et membres (matrice utilisateur × groupe). Les quatre groupes sans description
sont détectés et classés selon leur niveau de risque.

Niveau CRITIQUE si le groupe est orphelin ET a des membres actifs — c'est le
cas de `GRP_Domain_Admins_Local` dans le scénario CorpB.

### Script 5 — `Audit-PasswordPolicy.ps1`

Évalue six critères de la politique de mots de passe CorpB contre le référentiel
CorpA/ISO 27001/ANSSI. Résultats CorpB : quatre écarts dont deux CRITIQUE
(complexité désactivée, aucun seuil de verrouillage).

Note importante : ces écarts ne seront pas corrigés sur l'AD CorpB.
Les comptes migrés hériteront automatiquement des politiques Entra ID CorpA
dès la Phase 3.

---

## Colonnes clés des CSV produits

Toutes les sorties Phase 1 partagent ces colonnes structurantes :

| Colonne | Usage |
|---|---|
| `sAMAccountName` | Identifiant AD — clé de jointure avec Phase 2 |
| `IsStale` | Drapeau obsolète — lu par Phase 2 |
| `IsPrivileged` | Drapeau privilège — lu par Phase 2 |
| `IsServiceAccount` | Exclu de migration automatique Phase 3 |
| `RiskLevel` | CRITIQUE / ÉLEVÉ / MODÉRÉ / FAIBLE |
| `Valider` | Vide en Phase 1 — à remplir par manager en Phase 2 |

---

## Livrable OCM associé

Dans les 48h suivant la fin de l'audit, produire la restitution aux référents
CorpB via `OCM-Phase1-StakeholderBriefing.md`.

Ce document traduit les résultats techniques en langage non-technicien :
"49 comptes appartenant à des personnes parties sont encore actifs"
plutôt que "49 comptes avec `IsStale=TRUE` et `Enabled=TRUE`".

---

*Wiki page 04 — `iam-ma-integration-lab` — IAM-Lab Framework*
