# 🔀 MAPPING-IDENTITY.md — Règles de réconciliation des identités M&A

> `iam-ma-integration-lab` / phase3-migration
> À lire avant d'exécuter `Audit-IdentityDeduplication.ps1`
> Langue : Français | Cible : ingénieur IAM, DSI, RSSI

---

## Pourquoi ce document existe

En contexte M&A, la question "à quel compte Entra ID correspond cet utilisateur AD ?"
n'a pas toujours de réponse évidente. Quatre situations créent des ambiguïtés
qui, si elles ne sont pas résolues avant migration, produisent des erreurs
silencieuses ou des doublons de comptes.

Ce document définit les **règles de priorité** pour résoudre chaque type
de collision et guide l'utilisation du fichier
`MAPPING-IDENTITY_TOVALIDATE_*.csv` produit par `Audit-IdentityDeduplication.ps1`.

---

## Les cinq types de collision

### Type 1 — UPN_COLLISION

**Situation :** L'UPN cible calculé pour un utilisateur CorpB existe déjà
dans Entra ID CorpA mais appartient à une personne différente.

**Exemple :**
```
CorpB : Thomas Moulin (Commercial) → UPN calculé : t.moulin@corpa.onmicrosoft.com
CorpA : Thomas Moulin (IT)         → UPN existant : t.moulin@corpa.onmicrosoft.com
```

**Règle de résolution :**
```
Priorité 1 (par défaut) : suffixe numérique sur le compte CorpB
  → t.moulin2@corpa.onmicrosoft.com

Priorité 2 (si homonyme dans même département) : prénom complet
  → thomas.moulin@corpa.onmicrosoft.com

Priorité 3 (si convention alternative disponible) : NomPrenom
  → moulin.t@corpa.onmicrosoft.com
```

**Décision requise :** le choix entre ces options doit être validé par
le DSI CorpA et inscrit dans la colonne `Notes` du fichier de mapping.

---

### Type 2 — EMAIL_OVERLAP

**Situation :** L'adresse email source CorpB (`prenom.nom@corpb.local`)
correspond à une adresse mail déjà utilisée dans Entra ID CorpA.

**Exemple :**
```
CorpB : n.perrin@corpb.local  (Nadège Perrin — Commercial CorpB)
CorpA : n.perrin@corpa.fr     (Nathan Perrin — RH CorpA) — même alias, domaine différent
```

**Règle de résolution :**
```
Étape 1 : Vérifier que ce ne sont pas la même personne (comparer EmployeeId, téléphone)
Étape 2 : Si personnes différentes → remapper l'alias email CorpB
  → nperrin@corpa.onmicrosoft.com (sans séparateur)
  → nadege.perrin@corpa.onmicrosoft.com (prénom complet)
Étape 3 : Mettre à jour l'attribut Mail dans Entra ID après migration
```

---

### Type 3 — DISPLAY_NAME_MATCH

**Situation :** Le même DisplayName existe dans CorpA et CorpB.
Peut être un homonyme légitime ou la même personne dans les deux entités.

**Exemple :**
```
CorpB : Laurent Henry (Direction CorpB, DSI)
CorpA : Laurent Henry (IT CorpA, support)  ← homonyme ou même personne ?
```

**Règle de résolution :**
```
Étape 1 : Comparer l'EmployeeId (si disponible dans les deux annuaires)
Étape 2 : Comparer le numéro de téléphone ou le département
Étape 3a : Si même personne → voir Type 4 (EMPLOYEE_ID_MATCH)
Étape 3b : Si homonymes → maintenir les deux comptes avec suffixe
  CorpA : l.henry@corpa.onmicrosoft.com    (inchangé)
  CorpB : l.henry2@corpa.onmicrosoft.com   (migré avec suffixe)
```

**Décision requise :** validation DRH / manager pour confirmer l'identité.

---

### Type 4 — EMPLOYEE_ID_MATCH

**Situation :** La même personne existe dans les deux annuaires.
Cas fréquent : dirigeants, prestataires réguliers, membres du CODIR
présents dans CorpA avant la fusion et listés dans l'AD CorpB.

**Exemple :**
```
CorpB : Thierry Vogt (DSI CorpB) — compte AD CorpB actif
CorpA : Thierry Vogt (compte Entra ID CorpA créé lors d'une précédente collaboration)
```

**Règle de résolution :**
```
Option A — Fusionner (recommandée si le compte CorpA est le compte principal) :
  → Ne pas migrer le compte CorpB
  → Mettre à jour les attributs du compte CorpA existant (Department, Title)
  → Désactiver le compte CorpB après validation

Option B — Migrer et désactiver l'ancien (si compte CorpB = identité principale) :
  → Migrer le compte CorpB avec UPN CorpA
  → Désactiver l'ancien compte CorpA (Enabled=false, pas de suppression)
  → Transférer les licences

Option C — Maintenir les deux (si rôles distincts) :
  → Compte CorpA : accès ressources CorpA
  → Compte CorpB migré : accès ressources CorpB transitoires
  → Fusion à J+90 lors de la revue de gouvernance
```

**Décision requise :** DSI CorpA + concerné directement.

---

### Type 5 — SAM_AMBIGUITY

**Situation :** Deux utilisateurs CorpB différents génèrent le même UPN cible.
Homonymes au sein de CorpB.

**Exemple :**
```
CorpB utilisateur 1 : Marie Martin (Commercial)   → m.martin@corpa.onmicrosoft.com
CorpB utilisateur 2 : Marie Martin (RH)           → m.martin@corpa.onmicrosoft.com ← collision
```

**Règle de résolution :**
```
Règle de priorité par défaut : ancienneté dans l'entreprise
  → Utilisateur le plus ancien : m.martin@corpa.onmicrosoft.com
  → Utilisateur le plus récent : m.martin2@corpa.onmicrosoft.com

Alternative : département comme discriminant
  → Commercial : m.martin.com@corpa.onmicrosoft.com
  → RH         : m.martin.rh@corpa.onmicrosoft.com  ← déconseillé (exposition rôle)
```

---

## Utilisation du fichier MAPPING-IDENTITY_TOVALIDATE.csv

### Structure du fichier

| Colonne | Description | À remplir |
|---|---|---|
| `sAMAccountName_CorpB` | Identifiant AD source | Non |
| `DisplayName_CorpB` | Nom complet | Non |
| `TargetUPN_Calculated` | UPN calculé (peut être en collision) | Non |
| `TargetUPN_Final` | UPN recommandé après résolution | **Vérifier et ajuster** |
| `HasCollision` | OUI / NON | Non |
| `CollisionType` | Type(s) de collision | Non |
| `Severity` | CRITIQUE / ÉLEVÉ / MODÉRÉ / — | Non |
| `Resolution` | Résolution recommandée par le script | Non |
| `Valider` | `OUI` = migration approuvée avec cet UPN | **OUI obligatoire** |
| `ValidatedBy` | Nom du validateur | **Remplir** |
| `Notes` | Contexte ou ajustement | Optionnel |

### Workflow de validation

```
1. Ouvrir MAPPING-IDENTITY_TOVALIDATE_*.csv (séparateur : ;)

2. Filtrer HasCollision = OUI

3. Pour chaque collision :
   a. Lire CollisionType et Resolution
   b. Appliquer la règle correspondante (voir ci-dessus)
   c. Ajuster TargetUPN_Final si nécessaire
   d. Inscrire OUI dans Valider
   e. Remplir ValidatedBy + Notes

4. Valider aussi les lignes HasCollision = NON
   (migration standard — inscrire OUI pour toutes)

5. Sceller le fichier avant d'appeler Migrate-UsersToEntraID.ps1
   Get-FileHash -Path "MAPPING-IDENTITY_TOVALIDATE_*.csv" -Algorithm SHA256

6. Passer le fichier à la migration :
   .\Migrate-UsersToEntraID.ps1 -MappingCsvPath ".\MAPPING-IDENTITY_TOVALIDATE_*.csv" ...
```

---

## Règles globales de nommage — CorpB dans CorpA

### Convention de base (standard du lab)

```
Format : {initiale_prénom}.{nom}@corpa.onmicrosoft.com
Exemple : n.perrin@corpa.onmicrosoft.com

Caractères acceptés : lettres minuscules a-z, chiffre (suffixe uniquement), point
Caractères interdits : accents, espaces, caractères spéciaux
```

### Traitement des caractères spéciaux

| Caractère source | Transformation |
|---|---|
| é, è, ê, ë | e |
| à, â | a |
| ü, û | u |
| ï, î | i |
| ô | o |
| ç | c |
| Tiret dans le nom (Jean-Pierre) | Supprimé (jeanpierre ou jp) |
| Espace dans le nom (De La Rue) | Supprimé (delarue) |
| Apostrophe (O'Brien) | Supprimé (obrien) |

### Ordre de priorité pour les suffixes numériques

```
Collision niveau 1  → suffixe .2   (ex: t.moulin2@...)
Collision niveau 2  → suffixe .3   (ex: t.moulin3@...)
Au-delà de 3        → prénom complet recommandé (ex: thomas.moulin@...)
```

---

## Intégration dans la séquence Phase 3

```
Phase 3 — Séquence complète avec déduplication

Audit-PreMigrationChecklist.ps1         ← Vérifications GO/NoGo générales
        ↓
Audit-IdentityDeduplication.ps1         ← NOUVEAU — détection collisions
        ↓
[Validation humaine MAPPING-IDENTITY]   ← Résolution manuelle des collisions
        ↓
[Scellage SHA-256 du fichier mapping]
        ↓
Migrate-UsersToEntraID.ps1              ← Migration avec mapping validé
  -MappingCsvPath "mapping-validé.csv"
        ↓
Audit-PostMigrationDelta.ps1            ← Vérification delta
```

---

## Cas particuliers documentés dans le scénario CorpB

| Personne | Collision simulée | Type | Résolution recommandée |
|---|---|---|---|
| Thomas Moulin (CorpB) | t.moulin@corpa existe déjà (IT CorpA) | UPN_COLLISION | UPN final : `t.moulin2@corpa.onmicrosoft.com` |
| Laurent Henry (CorpB) | DisplayName identique (IT CorpA) | DISPLAY_NAME_MATCH | Vérifier département — homonymes si rôles différents |
| Thierry Vogt (CorpB) | Compte CorpA existant (collaboration antérieure) | EMPLOYEE_ID_MATCH | Option A — fusionner, compte CorpA = principal |
| Nadège Perrin (CorpB) | n.perrin@corpa — Nathan Perrin dans CorpA | EMAIL_OVERLAP | UPN final inchangé, alias email remap |

---

*MAPPING-IDENTITY.md — `iam-ma-integration-lab` — IAM-Lab Framework*
