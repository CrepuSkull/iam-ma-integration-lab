# 🤝 OCM-Phase4-GovernanceHandover.md — Passation de gouvernance

> `iam-ma-integration-lab` / ocm
> Livrable OCM associé à la Phase 4 — Gouvernance post-intégration
> Destinataires : managers CorpA réceptionnant les équipes CorpB, IT CorpA
> Langue : Français

---

## Section A — Template générique

### A.1 — Objectif de la passation

La passation de gouvernance marque le moment où la responsabilité des
identités CorpB passe de l'équipe projet IAM aux managers opérationnels CorpA.

Ce document leur donne trois informations essentielles :
1. Qui sont les collaborateurs CorpB qu'ils accueillent
2. Comment leurs accès sont structurés dans le nouvel environnement
3. Que faire en cas de changement (arrivée, départ, changement de poste)

### A.2 — Structure du document de passation

```
1. Les collaborateurs intégrés — qui, combien, quel département
2. Leurs accès dans l'environnement CorpA — groupes, applications
3. Les points d'attention spécifiques — comptes en cours de traitement
4. Vos responsabilités en tant que manager — cycle JML
5. Contacts et ressources
```

### A.3 — Template document de passation

```
DOCUMENT DE PASSATION — INTÉGRATION IAM [Entreprise cible]
Date : [date]
Préparé par : [équipe IAM]
Destinataire : [manager CorpA]

──────────────────────────────────────────────────
1. VOS NOUVEAUX COLLABORATEURS
──────────────────────────────────────────────────
[X] collaborateurs de [département CorpB] ont été intégrés
dans votre périmètre managérial.

Liste des comptes créés :
[Tableau : Prénom Nom | Identifiant | Groupes d'appartenance]

──────────────────────────────────────────────────
2. LEURS ACCÈS
──────────────────────────────────────────────────
Chaque collaborateur a été placé dans les groupes :
- [GRP_CorpB_Département_Migrated] : groupe de transition M&A
- [Groupes fonctionnels CorpA correspondants]

Applications accessibles : [liste]
Applications en cours de normalisation : [liste]

──────────────────────────────────────────────────
3. POINTS D'ATTENTION
──────────────────────────────────────────────────
[À COMPLÉTER selon les résultats des audits Phase 4]

──────────────────────────────────────────────────
4. VOS RESPONSABILITÉS — CYCLE JML
──────────────────────────────────────────────────
JOINER  (arrivée)  : déclarer via [formulaire/outil]
MOVER   (mutation) : déclarer via [formulaire/outil]
LEAVER  (départ)   : déclarer IMMÉDIATEMENT via [formulaire/outil]

Référence complète : [lien iam-identity-lifecycle-lab]

──────────────────────────────────────────────────
5. CONTACTS
──────────────────────────────────────────────────
Problème d'accès : [email helpdesk]
Question gouvernance IAM : [email RSSI/IAM]
Urgence sécurité : [email RSSI direct]
```

---

## Section B — Exemple CorpA/CorpB

### B.1 — Document de passation — Managers CorpA

**Destinataires** : chefs de département CorpA accueillant les équipes CorpB
**Émetteur** : Inès Moulin (IAM CorpA) / Sophie Arnaud (DSI)
**Date** : J+7 après J-Day

---

**DOCUMENT DE PASSATION — Intégration IAM CorpB dans CorpA**
**Semaine du [date]**

---

**À l'attention des managers CorpA accueillant des collaborateurs CorpB**

La migration informatique des équipes CorpB est terminée. Ce document vous
donne toutes les informations nécessaires pour gérer les accès de vos
nouveaux collègues dans la durée.

---

**1. Vos nouveaux collaborateurs par département**

| Département CorpA | Collaborateurs intégrés | Identifiants |
|---|---|---|
| Commercial | 67 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |
| R&D / Technique | 73 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |
| RH | 18 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |
| Direction | 10 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |
| Finance | 13 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |
| Prestataires | 42 collaborateurs ex-CorpB | `prenom.nom@corpa.fr` |

La liste nominative complète est disponible sur demande à ines.moulin@corpa.fr.

---

**2. Structure des accès**

Chaque collaborateur CorpB migré est membre de son groupe de transition
(`GRP_CorpB_[Département]_Migrated`) en plus des groupes fonctionnels CorpA
correspondants à son rôle.

| Département | Groupes attribués |
|---|---|
| Commercial | GRP_Commercial_CorpA + GRP_CorpB_Commercial_Migrated |
| Technique | GRP_Tech_CorpA + GRP_CorpB_Technique_Migrated |
| RH | GRP_RH_CorpA + GRP_CorpB_RH_Migrated |
| Finance | GRP_Finance_CorpA + GRP_CorpB_Finance_Migrated |
| Direction | GRP_Direction_CorpA + GRP_CorpB_Direction_Migrated |

Les groupes de transition `GRP_CorpB_*_Migrated` seront dissous dans
**3 mois** (revue trimestrielle). D'ici là, ils permettent l'identification
des comptes issus de la migration M&A.

---

**3. Points d'attention**

**Comptes en cours de traitement** (actions non encore finalisées) :

| Situation | Nb comptes | Responsable | Délai |
|---|---|---|---|
| Conflits RBAC en attente d'arbitrage | 3 | Karim Benali (RSSI) | Cette semaine |
| Comptes invités pré-fusion à requalifier | 4 | Manager CorpA concerné | J+14 |
| AS400 — plan de migration ERP | En cours | Équipe Finance + IT | À définir |
| Tokens GitLab — rotation confirmée | ✓ Traité | — | — |

**SaaS en cours de normalisation** :

| Application | Statut | Action requise |
|---|---|---|
| Salesforce | Comptes nominatifs migrés | Vérifier accès votre équipe Commercial |
| Dropbox Biz | En cours de fermeture | Paulo Esteves migre les contenus |
| GitLab CE on-prem | Transition vers GitLab CorpA | Bastien Couture pilote — Q2 |
| AS400 | Maintenu en parallèle | Finance — pas de changement immédiat |

---

**4. Vos responsabilités — cycle JML**

En tant que manager, vous êtes **le premier maillon de la chaîne de sécurité des identités**.
Trois moments où vous devez agir sans attendre.

**JOINER — Un collaborateur CorpB (ou nouveau) rejoint votre équipe**
Déclarer sur : [formulaire SIRH / portail IAM]
Délai traitement : 24h ouvrées
Référence : [iam-identity-lifecycle-lab — procédure Joiner]

**MOVER — Un collaborateur change de poste ou de département**
Déclarer sur : [formulaire SIRH / portail IAM]
Important : les droits de l'ancien poste sont révoqués automatiquement.
Vérifier que les nouveaux droits correspondent bien au nouveau rôle.

**LEAVER — Un collaborateur quitte l'entreprise**
Déclarer **le jour même** via : [formulaire urgent / email RSSI]
Contact direct : ines.moulin@corpa.fr ou karim.benali@corpa.fr
Ne pas attendre les processus RH pour les départs immédiats.

> Un compte non désactivé à temps est le scénario qui s'est produit chez CorpB.
> 49 comptes d'anciens collaborateurs étaient encore actifs au moment de l'audit.
> Ce que nous gérons ensemble maintenant, c'est précisément pour éviter que cela
> se reproduise dans l'environnement fusionné.

---

**5. Contacts et ressources**

| Besoin | Contact | Délai de réponse |
|---|---|---|
| Problème d'accès collaborateur | it-helpdesk@corpa.fr | < 4h |
| Question sur les droits d'accès | ines.moulin@corpa.fr | < 24h |
| Incident de sécurité | karim.benali@corpa.fr | Immédiat |
| Départ urgent à signaler | ines.moulin@corpa.fr + karim.benali@corpa.fr | Immédiat |
| Documentation JML complète | [lien iam-identity-lifecycle-lab] | — |

**Revue trimestrielle des accès** : dans 3 mois, vous recevrez la liste
des accès de votre équipe pour validation. C'est une procédure standard
de gouvernance — prévoir 30 minutes.

---

**Inès Moulin** — Ingénieure IAM CorpA
**Sophie Arnaud** — DSI CorpA

---

### B.2 — Session questions/réponses IT CorpB (Julien Faure)

**Format** : réunion 1h avec Julien Faure (ex-Admin IT CorpB)
**Animée par** : Inès Moulin
**Objectif** : accompagner Julien dans la compréhension de l'environnement Entra ID
et lui proposer un rôle dans la gouvernance continue

**Agenda proposé :**

| Durée | Sujet |
|---|---|
| 15 min | Tour d'horizon de l'environnement Entra ID CorpA (portail Azure, groupes, politiques CA) |
| 20 min | Démonstration des outils de monitoring (SignIn logs, Audit logs) |
| 15 min | Présentation du cycle JML CorpA — rôle éventuel de Julien en relais IT local |
| 10 min | Questions ouvertes — formation complémentaire si souhaitée |

> Cette session n'est pas une formation obligatoire. C'est une proposition.
> L'objectif est que Julien reparte avec une vision claire de où il peut
> apporter de la valeur dans le nouvel environnement.

---

### B.3 — Suivi de diffusion Phase 4 OCM

| Destinataire | Envoyé | Accusé | Observations |
|---|---|---|---|
| Managers CorpA (tous départements) | [ ] | [ ] | — |
| Julien Faure — session 1h | [ ] | [ ] | À planifier |
| Sophie Arnaud — validation | [ ] | [ ] | — |

---

*OCM Phase 4 — Passation de gouvernance — `iam-ma-integration-lab` — IAM-Lab Framework*
