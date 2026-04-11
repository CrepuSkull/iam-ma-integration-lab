# 🚀 Phase 3 — Migration vers Entra ID (CorpA)

> `iam-ma-integration-lab` / phase3-migration
> Langue : Français | Cible : ingénieur IAM, RSSI

---

## Principe fondamental

**On ne migre pas ce qui n'a pas été validé. On ne bascule pas sans delta confirmé.**

La Phase 3 est la phase de migration effective des identités CorpB vers
le tenant Entra ID CorpA. Elle s'appuie sur trois scripts séquentiels :

```
┌──────────────────────────┐
│  Audit-PreMigration      │  ← Checklist de prérequis — GO / NO-GO
│  Checklist.ps1           │     Aucune migration sans GO validé
└──────────┬───────────────┘
           │ GO confirmé
           ▼
┌──────────────────────────┐
│  Migrate-Users           │  ← Shadow Mode par défaut
│  ToEntraID.ps1           │     Provisioning parallèle — pas de bascule immédiate
└──────────┬───────────────┘
           │ Migration exécutée
           ▼
┌──────────────────────────┐
│  Audit-PostMigration     │  ← Comparaison source AD vs tenant Entra ID
│  Delta.ps1               │     Validation avant bascule J-Day
└──────────────────────────┘
```

---

## Shadow Mode — définition

Le Shadow Mode est le mécanisme central de sécurité de cette phase.

En Shadow Mode, les comptes CorpB sont **provisionnés dans Entra ID CorpA**
mais restent **désactivés** (`AccountEnabled: false`). Ils existent dans
le tenant cible, leurs attributs sont configurés, leurs groupes sont assignés,
mais ils ne peuvent pas se connecter.

La bascule effective (activation des comptes + désactivation AD source)
n'intervient qu'après validation du delta par `Audit-PostMigrationDelta.ps1`
et Go/NoGo explicite du DSI CorpA.

```
AD CorpB (source)          Entra ID CorpA (cible)
─────────────────          ──────────────────────
j.dupont  [ACTIF]    →     j.dupont@corpa.com  [DESACTIVE — Shadow]
m.martin  [ACTIF]    →     m.martin@corpa.com  [DESACTIVE — Shadow]
                           
         Audit-PostMigrationDelta confirme le delta = 0
                           
j.dupont  [DESACTIVE] ←   j.dupont@corpa.com  [ACTIVE — J-Day]
```

---

## Livrables

```
phase3-migration/
├── README-phase3.md                          ← Ce fichier
├── Audit-PreMigrationChecklist.ps1           ← Checklist GO/NO-GO pré-migration
├── Migrate-UsersToEntraID.ps1                ← Provisioning Shadow Mode (DryRun défaut)
└── Audit-PostMigrationDelta.ps1              ← Comparaison source vs cible
```

OCM associé : `../ocm/OCM-Phase3-MigrationGuide.md`

---

## Prérequis

### Techniques
- Phase 2 terminée — comptes CorpB assainis
- Module `Microsoft.Graph` PowerShell installé
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- Permissions Entra ID CorpA :
  - Audit : `User.Read.All`, `Group.Read.All`
  - Migration : `User.ReadWrite.All`, `Group.ReadWrite.All`, `Directory.ReadWrite.All`
- Fichier `../seed/corpb-users.csv` disponible (mode simulation)
- Tenant CorpA configuré : `corpa.onmicrosoft.com`

### Organisationnels
- Go/NoGo Phase 3 signé par Sophie Arnaud (DSI CorpA)
- Validation RGPD par Marc Deschamps (DPO) — base légale migration confirmée
- Plan de communication J-Day envoyé aux collaborateurs CorpB (→ OCM Phase 3)
- Fenêtre de maintenance définie avec les équipes IT

---

## Déroulé opérationnel

### Étape 1 — Checklist pré-migration (J-5 avant J-Day)

```powershell
.\Audit-PreMigrationChecklist.ps1 -Simulation -OutputPath "..\reports\"
```

Produit un rapport GO / NO-GO sur 12 points de contrôle.
**La migration ne peut pas démarrer si un point critique est en NO-GO.**

### Étape 2 — Migration en DryRun (J-3)

```powershell
.\Migrate-UsersToEntraID.ps1 `
    -CsvPath "..\seed\corpb-users.csv" `
    -TargetDomain "corpa.onmicrosoft.com" `
    -DryRun
```

Simule le provisioning complet — vérifier les logs avant d'aller plus loin.

### Étape 3 — Migration Shadow Mode (J-2)

```powershell
.\Migrate-UsersToEntraID.ps1 `
    -CsvPath "..\seed\corpb-users.csv" `
    -TargetDomain "corpa.onmicrosoft.com" `
    -DryRun:$false `
    -ShadowMode
```

Les comptes sont provisionnés dans Entra ID mais restent désactivés.

### Étape 4 — Audit du delta (J-1)

```powershell
.\Audit-PostMigrationDelta.ps1 `
    -SourceCsvPath "..\seed\corpb-users.csv" `
    -TargetDomain "corpa.onmicrosoft.com" `
    -OutputPath "..\reports\"
```

Confirme que chaque compte AD source a son équivalent Entra ID.
Si delta > 0 : corriger avant de basculer.

### Étape 5 — Bascule J-Day

```powershell
# Activer les comptes migrés (sortie du Shadow Mode)
.\Migrate-UsersToEntraID.ps1 `
    -CsvPath "..\seed\corpb-users.csv" `
    -TargetDomain "corpa.onmicrosoft.com" `
    -DryRun:$false `
    -ActivateShadowAccounts
```

---

## Checklist de clôture Phase 3

- [ ] Rapport Audit-PreMigrationChecklist — tous les points critiques en GO
- [ ] DryRun exécuté et relu sans erreur
- [ ] Migration Shadow Mode exécutée — log sans erreur
- [ ] Audit-PostMigrationDelta — delta = 0 ou delta documenté et accepté
- [ ] Conditional Access CorpA appliqué aux nouveaux comptes
- [ ] MFA enrollment déclenché sur tous les comptes migrés
- [ ] Guide utilisateur J-Day envoyé J-3 (→ OCM Phase 3)
- [ ] Bascule J-Day exécutée — comptes AD source désactivés
- [ ] Rapport de migration archivé et scellé (→ Phase 5)

---

## Rollback Phase 3

La Phase 3 dispose d'un rollback en deux temps :

**Avant bascule J-Day** (Shadow Mode actif) :
Supprimer les comptes provisionnés dans Entra ID — les comptes AD source
restent actifs, aucun impact sur les utilisateurs.

**Après bascule J-Day** :
Réactiver les comptes AD source + désactiver les comptes Entra ID.
Durée estimée : < 30 min pour 312 comptes avec script de rollback fourni.

---

## Mapping réglementaire

| Script | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| `Audit-PreMigrationChecklist.ps1` | A.5.15, A.5.16 | Art. 21 §2(i) | Art. 25 |
| `Migrate-UsersToEntraID.ps1` | A.5.16, A.5.18 | Art. 21 §2(i) | Art. 25, Art. 28 |
| `Audit-PostMigrationDelta.ps1` | A.5.15 | Art. 21 §2(f) | Art. 30 |

---

## Livrable OCM associé

> [`../ocm/OCM-Phase3-MigrationGuide.md`](../ocm/OCM-Phase3-MigrationGuide.md)
>
> Guide utilisateur J-Day — à envoyer J-3 avant la bascule.
> Explique aux collaborateurs CorpB comment se connecter avec leurs nouveaux identifiants et activer le MFA.

## Phase suivante

➜ [`../phase4-governance/README-phase4.md`](../phase4-governance/README-phase4.md)

---

*Phase 3 — Migration — `iam-ma-integration-lab` — IAM-Lab Framework*
