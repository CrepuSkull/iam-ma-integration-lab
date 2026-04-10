# 📣 OCM-Phase0-Communication.md — Plan de communication pré-migration

> `iam-ma-integration-lab` / ocm
> Livrable OCM associé à la Phase 0 — Préparation
> Langue : Français | Cible : DRH, managers CorpB, équipes IT

---

## Section A — Template générique

> Instructions : compléter les placeholders `[À COMPLÉTER]` avec les données réelles.
> Ce template produit 4 communications types pour le lancement du projet.

### A.1 — Objectifs de la communication Phase 0

Avant tout démarrage des audits techniques, trois objectifs OCM doivent être atteints :

1. **Légitimer le projet** : les collaborateurs de l'entreprise cible doivent comprendre que l'intégration IAM est une démarche structurée et accompagnée, pas un contrôle imposé
2. **Identifier les relais** : les managers et référents métier doivent savoir qu'ils seront consultés — pas seulement informés
3. **Réduire l'anxiété** : nommer explicitement ce qui va changer (et ce qui ne change pas) est plus rassurant que le silence

### A.2 — Les 4 communications Phase 0

| # | Communication | Émetteur | Destinataires | Canal | Timing |
|---|---|---|---|---|---|
| **C1** | Message de lancement DG-to-DG | DG [Entreprise absorbante] | DG + CODIR [Entreprise cible] | Email formel | J-21 avant audit |
| **C2** | Briefing managers | DSI [Entreprise absorbante] | Managers [Entreprise cible] | Réunion + Email | J-14 avant audit |
| **C3** | Information collaborateurs | DG [Entreprise cible] | Tous collaborateurs [Entreprise cible] | Email | J-10 avant audit |
| **C4** | Briefing IT [Entreprise cible] | DSI [Entreprise absorbante] | Admin IT + référents techniques [Entreprise cible] | Réunion technique | J-7 avant audit |

### A.3 — Template C1 — Message de lancement DG-to-DG

```
Objet : Intégration des systèmes informatiques — lancement du projet

[Prénom Nom DG Entreprise absorbante],

Dans le cadre de notre rapprochement, nous lançons la phase d'intégration
des systèmes d'identité et d'accès (IAM) des équipes [Entreprise cible].

Cette démarche, conduite par nos équipes IT avec l'appui de [À COMPLÉTER],
se déroulera en [X] phases sur [X] semaines. Elle est structurée, documentée
et accompagnée d'un plan de communication à chaque étape.

L'objectif est de garantir à vos collaborateurs une continuité de service
totale au moment de la bascule vers nos systèmes, et de vous assurer une
conformité documentée vis-à-vis des référentiels ISO 27001 et RGPD.

Un briefing de présentation sera organisé avec vos managers le [date].
Je reste disponible pour tout échange préalable.

[Signature]
```

### A.4 — Template C2 — Briefing managers (corps du message)

```
Objet : Projet d'intégration informatique — votre rôle dans le processus

Mesdames, Messieurs,

Dans les prochaines semaines, vos accès et outils informatiques vont être
intégrés dans l'environnement [Entreprise absorbante].

Ce que cela signifie concrètement pour vos équipes :
- Un état des lieux de vos outils actuels sera réalisé (sans modification)
- Certains comptes inactifs pourront être désactivés — vous serez consultés avant
- Vos collaborateurs recevront de nouveaux identifiants de connexion avec MFA
- Vos outils [À COMPLÉTER] resteront accessibles pendant toute la transition

Votre rôle dans ce projet :
Vous serez sollicités pour valider la liste des comptes de votre département
avant toute action. Aucune désactivation ne sera effectuée sans votre validation.

Calendrier prévisionnel :
- [Date] : État des lieux (aucun impact sur vos activités)
- [Date] : Validation des listes avec vous
- [Date] : Migration — vos équipes reçoivent leurs nouveaux accès

Votre interlocuteur technique : [Nom] — [Email] — [Teams/Téléphone]

[Signature]
```

### A.5 — Template C3 — Information collaborateurs

```
Objet : Vos accès informatiques — ce qui va changer, ce qui ne change pas

Chers collègues,

Dans les prochaines semaines, vos comptes informatiques vont être transférés
vers les systèmes de [Entreprise absorbante].

Ce qui va changer :
- Votre identifiant de connexion (vous recevrez un guide détaillé avant J-Day)
- L'activation d'une double authentification (MFA) pour sécuriser votre compte
- L'accès à certains outils partagés avec vos nouveaux collègues

Ce qui ne change pas :
- Vos accès aux outils que vous utilisez au quotidien
- Vos données et documents
- Votre mot de passe actuel jusqu'à la date de migration

Vous recevrez un guide pas-à-pas [X] jours avant la date de bascule.
En cas de question, contactez : [À COMPLÉTER]

[Signature]
```

### A.6 — Template C4 — Briefing IT [Entreprise cible]

```
Objet : Briefing technique — projet d'intégration IAM

[Prénom],

En complément du briefing managers, nous souhaitons organiser une session
technique avec vous pour vous présenter notre méthode de travail.

Au programme :
1. Présentation de la méthodologie IAM-Lab (lecture seule, DryRun, validation CSV)
2. Périmètre de l'audit : AD + applications SaaS
3. Votre rôle : faciliter l'accès lecture, valider les listes techniques
4. Ce que nous ne faisons pas : aucune modification sans votre validation préalable

Cette session est une collaboration, pas un contrôle. Votre connaissance
de l'environnement [Entreprise cible] est indispensable à la qualité du projet.

Disponible le [date] à [heure] — [Lien Teams / Salle]

[Signature]
```

---

## Section B — Exemple CorpA/CorpB

> Exemple rédigé dans le contexte fictif du lab — Sophie Arnaud (DSI CorpA) pilote le projet.

---

### B.1 — Communications produites

#### C1 — Message de lancement DG-to-DG
**Émetteur** : Directeur Général CorpA
**Destinataire** : Claire Imbert, Directrice Générale CorpB
**Date d'envoi** : J-21 (3 semaines avant démarrage Phase 1)

---

Objet : Intégration des systèmes informatiques CorpB — lancement du projet

Claire,

Dans le cadre de notre rapprochement, nous lançons la phase d'intégration des systèmes d'identité et d'accès (IAM) des équipes CorpB.

Cette démarche, conduite par Sophie Arnaud (DSI CorpA), se déroulera en 6 phases sur 16 semaines. Elle est entièrement documentée, conduite en lecture seule dans un premier temps, et accompagnée d'un plan de communication à chaque étape. Aucune action technique ne sera effectuée sans validation préalable de tes équipes.

L'objectif est double : garantir à tes collaborateurs une continuité de service complète lors de la bascule vers nos systèmes, et nous assurer une conformité documentée vis-à-vis de nos engagements ISO 27001 et RGPD.

Sophie prendra contact avec Thierry Vogt (DSI CorpB) cette semaine pour organiser le premier briefing technique. Une réunion d'information des managers CorpB est prévue le [date à compléter].

Je reste disponible pour tout échange.

---

#### C2 — Briefing managers CorpB
**Émetteur** : Sophie Arnaud, DSI CorpA
**Destinataires** : Nadège Perrin, Bastien Couture, Amandine Leconte, Paulo Esteves
**Date d'envoi** : J-14 (accompagné d'une invitation réunion 45 min)

---

Objet : Projet d'intégration informatique CorpB — votre rôle dans le processus

Mesdames, Messieurs,

Dans les prochaines semaines, vos accès et outils informatiques vont être intégrés dans l'environnement CorpA. Je souhaite vous en expliquer le déroulé et vous présenter le rôle qui vous est réservé dans ce projet.

**Ce que cela signifie concrètement pour vos équipes :**
- Un état des lieux de vos outils actuels sera réalisé — sans aucune modification à ce stade
- Vous serez consultés avant toute désactivation de compte dans votre département
- Vos collaborateurs recevront de nouveaux identifiants avec une double authentification (MFA)
- Salesforce, Slack, Jira, Notion et BambooHR restent accessibles pendant toute la transition
- L'AS400 et GitLab CE feront l'objet d'un traitement spécifique — nous en parlerons ensemble

**Votre rôle dans ce projet :**
Vous recevrez une liste des comptes informatiques de votre département. Vous devrez simplement confirmer quels comptes doivent être conservés et lesquels peuvent être désactivés. Aucune action ne sera effectuée sans votre validation écrite.

**Calendrier prévisionnel :**
- Semaine du [date] : état des lieux (aucun impact)
- Semaine du [date] : validation des listes avec vous (30 min par manager)
- [Date] : migration — vos équipes reçoivent leurs nouveaux accès

**Votre interlocutrice :** Inès Moulin — ines.moulin@corpa.fr — Teams

Je vous propose une réunion de 45 minutes le [date] pour répondre à toutes vos questions avant le démarrage. Invitation jointe.

Sophie Arnaud — DSI CorpA

---

#### C3 — Information collaborateurs CorpB
**Émetteur** : Claire Imbert, DG CorpB (relayé par les managers)
**Destinataires** : Tous les collaborateurs CorpB
**Date d'envoi** : J-10

---

Objet : Vos accès informatiques — ce qui va changer, ce qui ne change pas

Chers collègues,

Dans les prochaines semaines, vos comptes informatiques vont être transférés vers les systèmes de CorpA. Je tiens à vous expliquer simplement ce que cela implique pour vous au quotidien.

**Ce qui va changer :**
- Votre identifiant de connexion — vous recevrez un guide détaillé 3 jours avant la date de bascule
- Une double authentification (MFA) sera activée pour sécuriser votre compte. C'est une mesure de protection pour vous, pas une surveillance de votre activité.

**Ce qui ne change pas :**
- Vos accès à vos outils habituels (Slack, Salesforce, Jira, Notion...)
- Vos documents et données
- Votre mot de passe actuel jusqu'à la date de migration

**La date de bascule** est prévue le [date à compléter]. Vous recevrez un guide pas-à-pas 3 jours avant.

Pour toute question dès maintenant : it-integration@corpa.fr

Claire Imbert

---

#### C4 — Briefing IT CorpB
**Émetteur** : Sophie Arnaud + Inès Moulin (DSI / IAM CorpA)
**Destinataires** : Thierry Vogt (DSI CorpB), Julien Faure (Admin IT CorpB)
**Format** : Réunion technique 1h + support partagé
**Date** : J-7

---

Objet : Briefing technique — intégration IAM CorpB — session de travail

Thierry, Julien,

Merci de nous avoir accordé ce temps. L'objectif de cette session est de vous présenter notre méthode de travail et de répondre à vos questions avant le démarrage de l'audit.

**Ce que nous allons faire, et comment :**

Notre méthode repose sur un principe non négociable : **lecture seule d'abord, action ensuite, et uniquement sur validation humaine**.

Concrètement :
1. Les scripts d'audit ne font aucune modification sur votre AD ou vos applications
2. Chaque liste d'action vous sera soumise sous forme de fichier CSV que vous validez ligne par ligne
3. Rien ne s'exécute tant que vous n'avez pas inscrit "OUI" en face d'une ligne

Nous n'avons pas besoin de droits admin. Nous avons besoin d'un accès en lecture sur l'AD (compte Domain Users + Read sur toutes les OUs) et de vos exports SaaS.

**Un sujet sensible que nous voulons nommer directement :**

Julien, nous savons que la migration vers Entra ID modifie ton rôle d'administrateur AD. Nous souhaitons t'associer à la phase de gouvernance post-migration et t'accompagner dans la prise en main d'Entra ID si tu le souhaites. Ton expertise de l'environnement CorpB est précieuse — elle ne s'arrête pas avec la migration.

**Agenda de la session :**
1. Présentation de la méthodologie (15 min)
2. Revue du périmètre AD CorpB ensemble (20 min)
3. Identification des accès SaaS à inventorier (15 min)
4. Questions / organisation pratique (10 min)

À tout de suite.

Sophie Arnaud & Inès Moulin

---

### B.2 — Suivi des communications Phase 0

| Communication | Envoyée | Accusé de réception | Réactions identifiées |
|---|---|---|---|
| C1 — DG-to-DG | [ ] | [ ] | — |
| C2 — Managers CorpB | [ ] | [ ] | Bastien Couture : question sur GitLab (anticipé) |
| C3 — Collaborateurs | [ ] | N/A | — |
| C4 — IT CorpB | [ ] | [ ] | Julien Faure : demande détails sur son futur rôle (anticipé) |

> Ce tableau est à compléter au fil des envois. Conserver les traces de réponse
> pour le rapport de clôture Phase 5.

---

*OCM Phase 0 — Plan de communication — `iam-ma-integration-lab` — IAM-Lab Framework*
