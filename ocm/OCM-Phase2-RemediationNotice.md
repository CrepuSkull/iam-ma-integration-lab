# 🔔 OCM-Phase2-RemediationNotice.md — Notice de remédiation

> `iam-ma-integration-lab` / ocm
> Livrable OCM associé à la Phase 2 — Remédiation
> Deux temps : avant exécution (demande de validation) + après exécution (confirmation)
> Langue : Français | Destinataires : managers CorpB concernés

---

## Section A — Template générique

### A.1 — Deux communications, deux rôles

La Phase 2 nécessite **deux communications distinctes** :

| Communication | Timing | Objectif | Destinataires |
|---|---|---|---|
| **Avant (A2)** | Avant toute exécution | Expliquer ce qui va être fait + demander validation | Managers concernés |
| **Après (A3)** | Dans les 24h post-exécution | Confirmer ce qui a été fait + rassurer | Mêmes managers + IT CorpB |

> Ne jamais exécuter la Phase 2 sans avoir envoyé la communication "Avant"
> et reçu les CSV validés.

### A.2 — Template communication AVANT — demande de validation

```
Objet : [Action requise] Validation des comptes informatiques — votre département

[Prénom],

Suite à l'audit de l'environnement informatique de [Entreprise cible],
nous vous soumettons la liste des comptes de votre département pour validation.

Vous trouverez en pièce jointe un fichier Excel/CSV listant [X] comptes
identifiés comme potentiellement inactifs.

Ce que nous vous demandons :
→ Ouvrir le fichier
→ Pour chaque compte, inscrire OUI dans la colonne "Valider" si vous
  confirmez que la personne a quitté l'entreprise ou n'a plus besoin
  de cet accès
→ Laisser vide si vous avez un doute ou si la personne est toujours active
→ Utiliser la colonne "Notes" pour tout commentaire

Aucune action ne sera effectuée sans votre validation.
Délai souhaité : [date, ex : vendredi 18h]

En cas de question : [contact IT CorpA]

[Signature]
```

### A.3 — Template communication APRÈS — confirmation d'exécution

```
Objet : Confirmation — Actions réalisées sur les comptes informatiques

[Prénom],

Suite à votre validation, voici ce qui a été effectué sur les comptes
de votre département :

→ [X] compte(s) désactivé(s) et archivé(s)
→ [X] compte(s) conservé(s) (non validés ou en attente)
→ Aucun compte n'a été supprimé — tout peut être réactivé si nécessaire

Les comptes désactivés restent accessibles en lecture dans nos archives
pendant [durée, ex : 12 mois], puis feront l'objet d'une décision
de suppression définitive conforme à notre politique RGPD.

Si vous constatez un accès manquant dans votre équipe suite à ces actions,
contactez immédiatement : [contact IT CorpA]

[Signature]
```

### A.4 — Gestion des cas particuliers

| Situation | Conduite à tenir |
|---|---|
| Manager ne répond pas sous le délai | Relance unique, puis escalade au DSI CorpB. Ne jamais agir sans validation. |
| Manager valide un compte qui est en réalité actif | Log de l'erreur, réactivation immédiate, incident documenté. |
| Désaccord sur un compte (entre deux managers) | Arbitrage par le DSI CorpB. Compte conservé jusqu'à arbitrage. |
| Compte de service dans la liste | Ne jamais valider sans confirmation de l'équipe IT CorpB. |

---

## Section B — Exemple CorpA/CorpB

> Communications rédigées dans le contexte fictif du lab.

---

### B.1 — Communication AVANT — Nadège Perrin (Commercial)

**Émetteur** : Inès Moulin (Ingénieure IAM CorpA)
**Destinataire** : Nadège Perrin, Responsable Commercial CorpB
**Objet** : [Action requise avant vendredi] Validation comptes — équipe Commercial
**Pièce jointe** : `stale-commercial-validation.csv`

---

Nadège,

Suite à l'audit que nous avons réalisé sur l'environnement informatique de CorpB,
je vous soumets la liste des comptes de l'équipe Commercial pour validation.

Le fichier joint liste **14 comptes** identifiés comme potentiellement inactifs
(dernière connexion datant de plus de 90 jours, ou appartenant à des collaborateurs
dont le départ n'a pas été traité informatiquement).

**Ce que je vous demande :**
- Ouvrir le fichier (séparateur point-virgule — si besoin d'aide pour l'ouvrir, appelez-moi)
- Pour chaque personne dont vous confirmez le départ ou la non-utilisation du compte : écrire `OUI` dans la colonne `Valider`
- Laisser vide si vous avez le moindre doute
- La colonne `Notes` est libre pour tout commentaire

**Point spécifique :** le compte `sf-admin@corpb.com` (Salesforce Admin) n'est pas dans ce fichier — il fait l'objet d'un traitement séparé que nous verrons ensemble. Je vous recontacte sur ce point cette semaine.

**Aucune action ne sera effectuée avant réception de votre fichier validé.**

Délai souhaité : vendredi 17h.
Si vous avez besoin de plus de temps, faites-le moi savoir.

Inès Moulin — ines.moulin@corpa.fr — Teams

---

### B.2 — Communication AVANT — Bastien Couture (Technique)

**Émetteur** : Inès Moulin
**Destinataire** : Bastien Couture, Lead Dev CorpB
**Objet** : [Action requise] Validation comptes + tokens GitLab — équipe Technique

---

Bastien,

Deux points distincts dans ce message.

**1. Tokens GitLab — action immédiate requise**

Comme évoqué lors du briefing, 3 tokens d'accès sont exposés dans des dépôts GitLab.
Cela ne peut pas attendre la Phase 2 — chaque heure d'exposition est un risque réel.

Tokens à révoquer et régénérer en priorité :
- `token-api-bc` — repo `infra-scripts`, commit #a3f2c1
- `token-api-deploy` — fichier `.env` committé
- `token-api-legacy` — projet archivé non révoqué

Je sais que tu gères ça et que tu n'as pas besoin de tuto. Je veux juste m'assurer que c'est fait et loggé avant de continuer.

**2. Validation des comptes Technique**

Le fichier joint liste **8 comptes** à valider dans ton périmètre.
Même process que pour les autres équipes : `OUI` dans la colonne Valider pour confirmer.

Pour les comptes de service (`svc_*`) : ne valide rien sans en avoir parlé à Julien Faure.

Délai : vendredi 17h.

Inès

---

### B.3 — Communication AVANT — Thierry Vogt / Julien Faure (IT CorpB)

**Émetteur** : Inès Moulin
**Destinataires** : Thierry Vogt + Julien Faure
**Objet** : [Action requise] Validation comptes privilégiés + groupes orphelins

---

Thierry, Julien,

Je vous soumets deux fichiers distincts pour validation.

**Fichier 1 : comptes-privilegies-validation.csv**
5 comptes disposant de droits d'administration dans l'AD CorpB.
Pour chacun, la colonne `RecommendedAction` indique ce que je recommande :
- `DOCUMENTER` : le compte est légitime, il faut juste ajouter une description
- `REVOQUER_ADMIN` : les droits semblent excessifs par rapport au rôle
- `REVUE_MANUELLE_RSSI` : cas ambigu — à discuter avec Karim Benali

**Fichier 2 : groupes-orphelins-validation.csv**
4 groupes de sécurité sans propriétaire documenté.
Pour chaque groupe : soit vous identifiez un propriétaire (colonne `Notes`), soit on supprime.

Julien — les groupes `GRP_Domain_Admins_Local` et `GRP_Legacy_Sync` sont dans cette liste.
Tu es le mieux placé pour savoir s'ils sont encore utiles.

Délai : vendredi 17h.
On peut faire un appel de 20 min si tu veux qu'on revoit ça ensemble.

Inès

---

### B.4 — Communication APRÈS — synthèse post-exécution

**Émetteur** : Inès Moulin
**Destinataires** : tous les managers + Sophie Arnaud (DSI CorpA) + Karim Benali (RSSI)
**Objet** : Confirmation — Phase 2 remédiation terminée

---

Équipe,

La Phase 2 (remédiation de l'AD CorpB) est terminée. Voici ce qui a été réalisé.

**Comptes désactivés et archivés :**

| Département | Comptes validés | Désactivés | Conservés |
|---|---|---|---|
| Commercial | 14 | 11 | 3 (doutes signalés) |
| Technique | 8 | 6 | 2 (comptes de service — revue Julien) |
| RH | 4 | 4 | 0 |
| Prestataires | 19 | 15 | 4 |
| Direction | 2 | 2 | 0 |
| **Total** | **47** | **38** | **9** |

**Comptes privilégiés :**
- 3 comptes documentés (description ajoutée)
- 1 compte : droits d'administration révoqués (validé par Thierry Vogt)
- 1 compte : en attente d'arbitrage RSSI (Karim Benali)

**Groupes orphelins :**
- 2 groupes documentés (propriétaire identifié par Julien Faure)
- 1 groupe vidé et supprimé (`GRP_Temp_Project_2021` — vide, validé Thierry)
- 1 groupe en attente (`GRP_Legacy_Sync` — usage à confirmer)

**Ce qu'il reste à faire avant Phase 3 :**
- Rotation des tokens GitLab (Bastien — confirmez-moi quand c'est fait)
- Arbitrage compte privilégié en attente (Karim Benali)
- Confirmation GRP_Legacy_Sync (Julien Faure)

Aucun compte n'a été supprimé. Tous les comptes désactivés peuvent être
réactivés en moins de 15 minutes si une erreur est constatée.

Le rapport complet et les fichiers de traçabilité sont disponibles sur demande.

Inès Moulin — ines.moulin@corpa.fr

---

### B.5 — Suivi de diffusion Phase 2

**Communications AVANT**

| Destinataire | Envoyé | CSV reçu | Nb OUI | Observations |
|---|---|---|---|---|
| Nadège Perrin | [ ] | [ ] | — | Point Salesforce Admin séparé |
| Bastien Couture | [ ] | [ ] | — | Tokens GitLab — urgence |
| Amandine Leconte | [ ] | [ ] | — | — |
| Paulo Esteves | [ ] | [ ] | — | Dropbox Biz — sujet séparé |
| Thierry Vogt + Julien Faure | [ ] | [ ] | — | Privilégiés + groupes |

**Communication APRÈS**

| Destinataire | Envoyé | Réactions |
|---|---|---|
| Tous managers CorpB | [ ] | — |
| Sophie Arnaud (DSI CorpA) | [ ] | — |
| Karim Benali (RSSI) | [ ] | — |

---

*OCM Phase 2 — Notice de remédiation — `iam-ma-integration-lab` — IAM-Lab Framework*
