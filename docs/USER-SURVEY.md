# Questionnaires utilisateurs — Intégration IAM M&A

> `iam-ma-integration-lab` / docs
> Trois questionnaires pour trois moments du projet
> Langue : Français | Cible : chef de projet, RH, managers

---

## Présentation

Ce document contient trois questionnaires distincts :

| # | Questionnaire | Moment | Destinataires |
|---|---|---|---|
| **Q1** | État des lieux IT — pré-migration | Phase 0 (avant tout script) | Managers + référents CorpB |
| **Q2** | Inventaire SaaS déclaratif | Phase 0 (en parallèle de Q1) | Tous les collaborateurs CorpB |
| **Q3** | Satisfaction post-migration | J+30 après J-Day | Tous les collaborateurs CorpB migrés |

Chaque questionnaire est fourni en deux formats :
- **Template générique** : placeholders `[À COMPLÉTER]`
- **Version CorpA/CorpB** : exemple rédigé dans le contexte du lab

---

---

# Q1 — Questionnaire état des lieux IT (managers et référents)

> Destinataires : managers et référents techniques CorpB
> Moment : Phase 0, J-14 avant démarrage Phase 1
> Durée estimée : 20-30 minutes
> Format recommandé : entretien semi-directif ou formulaire en ligne

---

## Q1 — Template générique

**Introduction à envoyer avec le questionnaire :**

```
Dans le cadre de l'intégration de [Entreprise cible] dans [Entreprise absorbante],
nous réalisons un état des lieux de votre environnement informatique.

Ces informations nous permettront de préparer l'intégration en tenant compte
des spécificités de votre environnement et de vos besoins métier.

Durée estimée : 20-30 minutes.
Vos réponses sont confidentielles et utilisées uniquement dans le cadre de ce projet.

Contact : [nom du chef de projet] — [email]
```

---

### Bloc 1 — Votre activité et vos accès

**Q1.1** Quel est votre rôle et votre département ?

**Q1.2** Combien de personnes composent votre équipe directe ?

**Q1.3** Quels outils informatiques utilisez-vous quotidiennement ?
_(Listez tous les outils, y compris ceux que vous utilisez sur votre téléphone personnel pour le travail)_

**Q1.4** Parmi ces outils, lesquels sont indispensables à votre activité ?
_(Si l'accès était coupé pendant plus d'une heure, cela bloquerait votre travail)_

**Q1.5** Y a-t-il des outils ou applications que votre équipe utilise et qui ne sont pas
gérés par la DSI à votre connaissance ?
_(Outils gratuits, abonnements personnels utilisés à des fins professionnelles, etc.)_

---

### Bloc 2 — Gestion des accès dans votre équipe

**Q2.1** Comment se passe l'arrivée d'un nouveau collaborateur dans votre équipe
sur le plan informatique ?
_(Qui demande la création des comptes ? Dans quel délai ?)_

**Q2.2** Comment se passe le départ d'un collaborateur ?
_(Qui est informé ? Les accès sont-ils désactivés rapidement ?)_

**Q2.3** Avez-vous connaissance de collaborateurs qui ont quitté l'entreprise mais
dont les accès informatiques sont peut-être encore actifs ?
_(Pas de jugement — c'est une situation fréquente dans les PME)_

**Q2.4** Des comptes informatiques sont-ils partagés entre plusieurs personnes dans
votre équipe ? (login/mot de passe identique pour plusieurs utilisateurs)
_(Par exemple : un compte administrateur commun, un accès applicatif générique...)_

**Q2.5** Certains membres de votre équipe ont-ils des accès particulièrement étendus
(administrateur local, accès à des données sensibles d'autres départements) ?

---

### Bloc 3 — Applications et données sensibles

**Q3.1** Quelles sont les données les plus sensibles que votre équipe manipule ?
_(Données clients, données financières, données personnelles RH, code source...)_

**Q3.2** Ces données sont-elles stockées uniquement dans les outils officiels
de l'entreprise, ou aussi dans d'autres espaces ?
_(Emails personnels, Dropbox personnel, clé USB, etc.)_

**Q3.3** Avez-vous des accès à des systèmes de l'entreprise depuis votre téléphone
personnel ou un ordinateur non fourni par [Entreprise cible] ?

**Q3.4** Votre équipe utilise-t-elle des outils de collaboration avec des partenaires
ou clients externes ? (espaces partagés, accès invités...)

---

### Bloc 4 — Préparation au changement

**Q4.1** Comment qualifieriez-vous le niveau de connaissance informatique
de votre équipe sur une échelle de 1 (très limité) à 5 (très autonome) ?

**Q4.2** Avez-vous des inquiétudes particulières concernant l'intégration
informatique prévue ? Si oui, lesquelles ?

**Q4.3** Y a-t-il des périodes dans l'année où une coupure ou perturbation
des accès informatiques serait particulièrement problématique pour votre activité ?

**Q4.4** Des membres de votre équipe ont-ils besoin d'un accompagnement
renforcé pour prendre en main de nouveaux outils ?

**Q4.5** Avez-vous des questions ou remarques à transmettre à l'équipe projet ?

---

## Q1 — Version CorpA/CorpB

**Email d'envoi :**

Objet : [10 min de votre temps] Préparation intégration informatique — votre expertise est précieuse

Nadège, Bastien, Amandine, Paulo, Thierry,

Dans le cadre de l'intégration de CorpB dans CorpA, nous réalisons un état
des lieux de votre environnement informatique. Votre vision des outils que
vous utilisez au quotidien et des accès de votre équipe est indispensable
pour préparer une transition sans rupture.

Ce questionnaire prend 20-30 minutes. Vos réponses nous permettront de
prendre en compte vos besoins spécifiques et d'anticiper les points
d'attention avant la migration.

Lien formulaire : [lien]
Date limite : vendredi [date]

En cas de question : ines.moulin@corpa.fr

Inès Moulin — Ingénieure IAM CorpA

---

**Réponses attendues selon les personas :**

| Manager | Point clé attendu | Action Phase 0 associée |
|---|---|---|
| Nadège Perrin | Compte Salesforce Admin partagé (Q2.4) | Préparer remédiation nominative |
| Bastien Couture | Tokens API en clair dans GitLab (Q3.2) | Alerte immédiate RSSI |
| Amandine Leconte | Données RH sensibles (Q3.1) | Informer DPO — RGPD |
| Paulo Esteves | Dropbox Biz non déclaré (Q1.5) | Inventaire Shadow IT |
| Thierry Vogt | AS400 comptes partagés (Q2.4) | Documenter risque accepté |

---

---

# Q2 — Questionnaire inventaire SaaS déclaratif (tous collaborateurs)

> Destinataires : tous les collaborateurs CorpB
> Moment : Phase 0, en parallèle de Q1
> Durée estimée : 5-10 minutes
> Format recommandé : formulaire en ligne anonymisé

---

## Q2 — Template générique

**Introduction :**

```
Nous préparons l'intégration de vos outils informatiques dans l'environnement
de [Entreprise absorbante]. Pour vous garantir une transition sans interruption,
nous avons besoin de savoir quels outils vous utilisez réellement au quotidien.

Ce questionnaire est anonyme et prend 5 minutes.
Il n'y a pas de mauvaise réponse — nous cherchons à établir un inventaire
complet, y compris des outils que vous avez adoptés de votre propre initiative.
```

---

**Q2.1** Quel est votre département ?
_(Liste déroulante : Direction / Commercial / Technique / RH / Finance / Prestataire / Autre)_

**Q2.2** Parmi les outils suivants, lesquels utilisez-vous dans le cadre de votre travail ?
_(Cochez tout ce qui s'applique)_

```
☐ Messagerie (Outlook, Gmail professionnel, autre)
☐ Outil de collaboration (Slack, Teams, autre : ___)
☐ Gestion de projets / tickets (Jira, Asana, Trello, autre : ___)
☐ Documentation / wiki (Notion, Confluence, SharePoint, autre : ___)
☐ Stockage de fichiers (SharePoint, Dropbox, Google Drive, autre : ___)
☐ CRM (Salesforce, HubSpot, autre : ___)
☐ RH (BambooHR, Lucca, autre : ___)
☐ Comptabilité / Finance (Sage, QuickBooks, autre : ___)
☐ Outil de développement (GitHub, GitLab, Bitbucket, autre : ___)
☐ Visioconférence (Zoom, Teams, Google Meet, autre : ___)
☐ Autre outil important : _______________
```

**Q2.3** Utilisez-vous l'un de ces outils avec votre adresse email personnelle
(Gmail, Hotmail, Yahoo...) plutôt qu'avec votre adresse professionnelle ?
```
☐ Oui — lequel : _______________
☐ Non
```

**Q2.4** Utilisez-vous des outils de stockage ou de partage de fichiers
non mentionnés ci-dessus pour stocker des documents professionnels ?
_(Clé USB, disque dur externe, espace personnel en ligne...)_
```
☐ Oui — lequel : _______________
☐ Non
```

**Q2.5** Y a-t-il des outils ou applications dont vous auriez besoin
de conserver l'accès après le changement, et dont vous n'avez pas parlé
à votre responsable ou à la DSI ?

_(Réponse libre — champ texte)_

---

## Q2 — Version CorpA/CorpB

**Ce questionnaire est envoyé aux 312 collaborateurs CorpB via un formulaire
en ligne (type Google Forms ou Microsoft Forms), anonymisé.**

**Résultats attendus :**

En croisant les réponses Q2 avec l'inventaire DSI :

| Découverte probable | Département | Action Phase 0 |
|---|---|---|
| Dropbox confirmé comme outil répandu | Prestataires + Technique | Renforcer la priorité Shadow IT |
| Notion avec emails perso (12 comptes) | Tous départements | Identifier et contacter |
| Outils de visio personnels (Zoom) | Commercial | Évaluer si usage professionnel |
| Outils RH non déclarés | RH | Creuser avec Amandine Leconte |

---

---

# Q3 — Questionnaire satisfaction post-migration (J+30)

> Destinataires : tous les collaborateurs CorpB migrés (263 personnes)
> Moment : J+30 après J-Day
> Durée estimée : 10-15 minutes
> Format recommandé : formulaire en ligne anonymisé

---

## Q3 — Template générique

**Introduction :**

```
Il y a un mois, vos accès informatiques ont basculé vers l'environnement
de [Entreprise absorbante]. Nous souhaitons recueillir votre retour
sur cette expérience pour améliorer nos pratiques.

Ce questionnaire est anonyme. Toutes les réponses sont utiles,
y compris les retours négatifs.

Durée : 10-15 minutes.
```

---

### Bloc 1 — La transition le jour J

**Q1.1** Comment s'est passée votre première connexion avec vos nouveaux identifiants ?
```
☐ Très fluide — j'ai pu me connecter sans problème
☐ Quelques difficultés mais résolu rapidement
☐ Difficultés importantes — j'ai eu besoin d'aide
☐ Je n'ai toujours pas pu me connecter correctement
```

**Q1.2** Si vous avez rencontré des difficultés, de quelle nature étaient-elles ?
_(Plusieurs réponses possibles)_
```
☐ Mot de passe temporaire non reçu
☐ Mot de passe temporaire expiré ou incorrect
☐ Problème avec la double authentification (MFA)
☐ Application inaccessible après la migration
☐ Identifiant incorrect
☐ Autre : _______________
```

**Q1.3** Avez-vous contacté le support informatique le jour J ou les jours suivants ?
```
☐ Oui — le problème a été résolu rapidement
☐ Oui — le problème a mis du temps à être résolu
☐ Oui — le problème n'a pas été résolu
☐ Non — je n'en avais pas besoin
```

**Q1.4** Le guide de connexion reçu avant la migration était-il clair et utile ?
```
☐ Oui, très utile
☐ Utile mais certains points peu clairs
☐ Peu utile
☐ Je ne l'ai pas reçu ou ne l'ai pas lu
```

---

### Bloc 2 — Vos accès aujourd'hui (J+30)

**Q2.1** Avez-vous accès à tous les outils dont vous avez besoin pour travailler ?
```
☐ Oui, tous mes accès sont opérationnels
☐ La plupart — il en manque un ou deux
☐ Non, des accès importants sont toujours manquants
```

**Q2.2** Si des accès manquent, lesquels ? _(Réponse libre)_

**Q2.3** La double authentification (MFA) que vous avez configurée
vous pose-t-elle des problèmes au quotidien ?
```
☐ Non, je l'utilise sans difficulté
☐ Parfois — quelques situations gênantes
☐ Souvent — c'est un frein dans mon travail quotidien
☐ Je ne l'ai pas encore configurée
```

**Q2.4** Vos données et documents sont-ils tous accessibles comme avant ?
```
☐ Oui, je retrouve tout
☐ La plupart — quelques documents semblent manquants
☐ Non, des données importantes sont inaccessibles
```

---

### Bloc 3 — L'accompagnement reçu

**Q3.1** Avez-vous été suffisamment informé(e) à l'avance sur les changements prévus ?
```
☐ Oui, très bien informé(e)
☐ Informé(e) mais avec peu de détails
☐ Peu informé(e) — j'ai appris les changements tardivement
☐ Pas informé(e) du tout
```

**Q3.2** Les communications reçues (emails, guide, briefing manager) étaient-elles
compréhensibles pour quelqu'un qui n'est pas informaticien(ne) ?
```
☐ Oui, très claires
☐ Globalement claires
☐ Parfois trop techniques
☐ Difficiles à comprendre
```

**Q3.3** Votre responsable vous a-t-il(elle) transmis les informations nécessaires
avant la migration ?
```
☐ Oui — j'avais toutes les informations
☐ Partiellement — certaines informations manquaient
☐ Non — j'ai dû me débrouiller seul(e)
```

**Q3.4** Avez-vous eu un interlocuteur clairement identifié pour vos questions
techniques liées à la migration ?
```
☐ Oui — et il/elle a répondu rapidement
☐ Oui — mais le temps de réponse était long
☐ Non — je ne savais pas qui contacter
```

---

### Bloc 4 — Ressenti général

**Q4.1** Sur une échelle de 1 à 5, comment évaluez-vous votre expérience
globale de cette migration informatique ?
```
1 — Très mauvaise expérience
2 — Mauvaise expérience
3 — Expérience neutre
4 — Bonne expérience
5 — Très bonne expérience
```

**Q4.2** Y a-t-il des aspects de la migration qui vous ont particulièrement
perturbé(e) dans votre travail quotidien ?
_(Réponse libre)_

**Q4.3** Y a-t-il des aspects de la migration qui se sont passés mieux
que vous ne l'espériez ?
_(Réponse libre)_

**Q4.4** Avez-vous des suggestions pour améliorer ce type de projet
lors de futures intégrations informatiques ?
_(Réponse libre)_

**Q4.5** Y a-t-il quelque chose d'important que vous souhaitez signaler
et qui n'a pas été couvert par ce questionnaire ?
_(Réponse libre)_

---

### Bloc 5 — Questions spécifiques SaaS

**Q5.1** Utilisez-vous toujours les mêmes applications qu'avant la migration ?
_(Salesforce, Slack, Jira, Notion, BambooHR...)_
```
☐ Oui, toutes mes applications fonctionnent normalement
☐ La plupart — une ou deux ont changé de façon d'accès
☐ Non — certaines applications posent problème
```

**Q5.2** Si vous avez rencontré des problèmes avec une application spécifique,
laquelle et quel type de problème ? _(Réponse libre)_

**Q5.3** La double authentification (MFA) a-t-elle été activée sur vos
applications métier (Salesforce, BambooHR...) ? Si non, est-ce un blocage ?

**Q5.4** Y a-t-il des outils que vous utilisiez avant et auxquels vous n'avez
plus accès depuis la migration ? _(Réponse libre)_

---

## Q3 — Analyse et exploitation des résultats

### Seuils d'alerte

Les résultats du questionnaire déclenchent des actions correctives
si les seuils suivants sont atteints :

| Indicateur | Seuil d'alerte | Action |
|---|---|---|
| Q1.1 — Difficultés connexion J-Day | > 15% | Analyse des causes + correction |
| Q2.1 — Accès manquants J+30 | > 10% | Audit ciblé des accès manquants |
| Q2.3 — MFA non configuré J+30 | > 10% | Session accompagnement dédiée |
| Q3.1 — Insuffisamment informé | > 20% | Revue du plan OCM |
| Q4.1 — Note < 3/5 (moyenne) | — | Réunion équipe projet + plan d'action |

### Intégration dans le rapport de clôture

Les résultats agrégés (anonymisés) du questionnaire sont intégrés
dans `OCM-Phase5-ClosureReport.md` — Section B.6 (Leçons apprises)
et Section B.3 (Métriques clés du projet).

Le taux de participation cible est de 70% minimum. En dessous de ce
seuil, les résultats ne sont pas représentatifs.

---

## Note sur les outils de diffusion

| Outil | Avantages | Limites |
|---|---|---|
| Microsoft Forms | Intégré M365, SSO CorpA, analyses natives | Nécessite compte CorpA actif (J+30 uniquement) |
| Google Forms | Simple, anonymat facile, analyse rapide | Compte Google requis |
| Typeform | UX soignée, taux de complétion meilleur | Payant pour l'anonymat avancé |
| SurveyMonkey | Analyse avancée, export facile | Coût selon volume |

Pour Q1 et Q2 (Phase 0, avant migration) : utiliser un outil accessible
avec les identifiants CorpB actuels. Pour Q3 (J+30) : Microsoft Forms
via le tenant CorpA.

---

*Questionnaires utilisateurs — `iam-ma-integration-lab` — IAM-Lab Framework*
*Version 1.0 — Auteur : Arnaud Montcho — consultant IAM/IGA hybride*
