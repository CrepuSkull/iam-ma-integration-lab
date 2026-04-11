# ✅ README-validation.md — Instructions de validation CSV

> `iam-ma-integration-lab` / phase2-remediation / validation-csv
> Destinataires : managers CorpB validateurs, chef de projet IAM

---

## Ce dossier contient

Les fichiers CSV soumis à validation avant toute action de remédiation.

**Aucune modification AD ne sera effectuée tant que vous n'aurez pas
renvoyé votre CSV complété avec les lignes autorisées.**

---

## Comment valider un CSV

### Étape 1 — Ouvrir le fichier

Ouvrir le fichier CSV avec Excel ou un éditeur texte.
Le séparateur est le point-virgule (`;`).

> Si Excel affiche tout en colonne A : Données → Convertir → Délimité → Point-virgule.

### Étape 2 — Lire chaque ligne

Chaque ligne représente un compte ou un groupe à traiter.
Vérifier les colonnes `sAMAccountName`, `DisplayName`, `StaleReason` ou `RecommendedAction`.

### Étape 3 — Compléter la colonne Valider

| Vous souhaitez | Que saisir dans la colonne Valider |
|---|---|
| Autoriser l'action sur ce compte | `OUI` (exactement, en majuscules) |
| Bloquer l'action — conserver le compte | laisser vide |
| Signaler une erreur ou un cas particulier | laisser vide + remplir `Notes` |

> **Important** : seul `OUI` (majuscules, sans espace) déclenche l'action.
> `Oui`, `oui`, `YES`, `O` sont ignorés.

### Étape 4 — Compléter les colonnes ValidatedBy et ValidationDate

```
ValidatedBy    : votre nom et prénom
ValidationDate : la date du jour (format AAAA-MM-JJ, ex : 2025-06-15)
```

### Étape 5 — Renvoyer le fichier

Renvoyer le fichier complété à : **ines.moulin@corpa.fr**
Objet : `[VALIDATION IAM] [Votre département] — [Nom du fichier]`

---

## Exemple de ligne validée

```
sAMAccountName ; DisplayName      ; Department ; StaleReason           ; RecommendedAction ; Valider ; ValidatedBy      ; ValidationDate ; Notes
j.dupont       ; Jean Dupont      ; Commercial ; INACTIF_90J           ; DESACTIVER        ; OUI     ; Nadège Perrin    ; 2025-06-15     ;
m.martin       ; Marie Martin     ; Commercial ; OU_ARCHIVED_ACTIF     ; DESACTIVER        ; OUI     ; Nadège Perrin    ; 2025-06-15     ;
p.bernard      ; Pierre Bernard   ; Commercial ; INACTIF_90J           ; DESACTIVER        ;         ;                  ;                ; Toujours en poste — contrat suspendu
```

---

## Questions fréquentes

**Je reconnais un nom dans la liste mais je ne sais pas si la personne est encore là.**
Laisser vide + noter dans la colonne Notes. L'équipe IT CorpA vérifiera avant d'agir.

**La liste contient des comptes que je ne connais pas.**
Laisser vide. Ne valider que ce que vous pouvez confirmer.

**Je vois un compte de service technique (svc_...) dans la liste.**
Ne pas valider sans confirmation de Julien Faure ou Thierry Vogt (IT CorpB).

**Je veux valider mais je ne veux pas que le compte soit supprimé.**
Les comptes ne sont pas supprimés — ils sont désactivés et archivés.
Ils peuvent être réactivés à tout moment si nécessaire.

---

## Fichiers présents dans ce dossier

| Fichier | Destinataire | Statut |
|---|---|---|
| `Template-Validation-Stale.csv` | Tous les managers | Template vierge |
| `Template-Validation-Privileged.csv` | Thierry Vogt / Julien Faure | Template vierge |
| `Template-Validation-Groups.csv` | Thierry Vogt | Template vierge |

> Les fichiers pré-remplis issus de la Phase 1 (`phase2-remediation-stale_TOVALIDATE_*.csv`)
> sont transmis directement par email aux managers concernés — ils ne sont pas versionnés
> dans le repo pour éviter d'exposer des données nominatives.

---

*Validation CSV — `iam-ma-integration-lab` — IAM-Lab Framework*
