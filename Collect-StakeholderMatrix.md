# 👥 Collect-StakeholderMatrix.md — Matrice des parties prenantes

> `iam-ma-integration-lab` / phase0-preparation
> Livrable : Phase 0 — Préparation
> Format : Template générique (Section A) + Exemple CorpA/CorpB (Section B)

---

## Section A — Template générique

> Instructions : dupliquer ce fichier, renommer en `stakeholder-matrix-[client].md`,
> remplacer tous les placeholders `[À COMPLÉTER]`.

### A.1 — Objectif de la matrice

Cette matrice sert à :
1. Identifier **qui sait quoi** dans l'entreprise cible (référents métier, propriétaires applicatifs)
2. Déterminer **qui valide quoi** dans le processus d'intégration (approbateurs des CSV de remédiation)
3. Organiser **qui communique avec qui** (plan OCM, chaîne d'information)

### A.2 — Structure de la matrice

| Champ | Description |
|---|---|
| Nom / Fonction | Identité et poste de la personne |
| Entité | CorpA (absorbante) ou CorpB (cible) |
| Domaine métier | Commercial, Technique, RH, Direction, IT, Finance... |
| Rôle dans le projet | Décideur / Validateur / Référent / Informé |
| Applications propriétaires | SaaS dont cette personne est l'administrateur fonctionnel |
| Implication par phase | Phases où cette personne est sollicitée (0 à 5) |
| Canal de communication préféré | Email / Réunion / Slack / Teams |
| Niveau de résistance estimé | Faible / Modéré / Fort (évaluation initiale) |
| Notes | Informations contextuelles utiles |

### A.3 — Rôles dans le projet (définitions)

| Rôle | Définition | Engagement attendu |
|---|---|---|
| **Décideur** | Autorise les actions à impact fort (remédiation, migration) | Valider les CSV de remédiation, approuver le Go/NoGo Phase 3 |
| **Validateur** | Confirme la pertinence des données avant action | Relire les rapports d'audit, valider la liste des comptes à désactiver |
| **Référent** | Source de connaissance métier sur les accès et usages | Répondre aux questionnaires Phase 0, identifier les accès critiques |
| **Informé** | Reçoit les communications sans rôle actif | Destinataires des messages OCM |

### A.4 — Template tableau

```
| Nom / Fonction | Entité | Domaine | Rôle | Apps propriétaires | Phases | Canal | Résistance | Notes |
|---|---|---|---|---|---|---|---|---|
| [À COMPLÉTER] | [CorpA/CorpB] | [À COMPLÉTER] | [Décideur/Validateur/Référent/Informé] | [À COMPLÉTER] | [0,1,2,3,4,5] | [Email/Teams/Réunion] | [Faible/Modéré/Fort] | [À COMPLÉTER] |
```

### A.5 — Checklist de complétude

Avant de passer à la Phase 1, vérifier que la matrice couvre :

- [ ] Au moins un **Décideur** côté CorpA (RSSI ou DSI)
- [ ] Au moins un **Validateur** technique côté CorpB (admin AD)
- [ ] Un **Référent** par département CorpB (Commercial, Technique, RH, Direction)
- [ ] Un propriétaire fonctionnel identifié pour chaque application SaaS critique
- [ ] Un contact DRH CorpB (pour les obligations RGPD Art. 13/14)
- [ ] Un contact DPO ou juridique CorpA (pour validation base légale migration)

---

## Section B — Exemple CorpA/CorpB

> Exemple rédigé dans le contexte fictif du lab. Les noms sont fictifs.
> Utiliser comme référence pour comprendre le niveau de granularité attendu.

### B.1 — Contexte

**Projet** : Intégration IAM post-acquisition — CorpA absorbe CorpB
**Chef de projet** : Sophie Arnaud (DSI CorpA)
**Date de constitution de la matrice** : J-14 avant démarrage Phase 1
**Statut** : Validé par Sophie Arnaud — 12 parties prenantes identifiées

---

### B.2 — Parties prenantes CorpA (absorbante)

| Nom / Fonction | Domaine | Rôle | Apps propriétaires | Phases | Canal | Résistance | Notes |
|---|---|---|---|---|---|---|---|---|
| **Sophie Arnaud** — DSI | IT / Direction | Décideur | Entra ID (tenant CorpA) | 0,1,2,3,4,5 | Teams + Email | Faible | Sponsor du projet. Go/NoGo Phase 3 lui appartient. |
| **Karim Benali** — RSSI (temps partiel) | Sécurité | Décideur / Validateur | iam-evidence-sealer, Conditional Access | 0,1,3,5 | Email | Faible | Valide tous les rapports d'audit avant action. Référent ISO 27001. |
| **Inès Moulin** — Ingénieure IAM | IT | Validateur | Scripts IAM-Lab Framework | 1,2,3,4,5 | Teams | Faible | Exécutante principale des phases techniques. |
| **Marc Deschamps** — DPO | Juridique / Conformité | Validateur | — | 0,3 | Email | Faible | Valide la base légale de la migration (Art. 6 RGPD) avant Phase 3. |

---

### B.3 — Parties prenantes CorpB (cible)

| Nom / Fonction | Domaine | Rôle | Apps propriétaires | Phases | Canal | Résistance | Notes |
|---|---|---|---|---|---|---|---|---|
| **Thierry Vogt** — DSI CorpB | IT | Validateur | AD on-prem, AS400, GitLab CE | 0,1,2,3 | Réunion + Email | Modéré | Légitime sur son périmètre. Rassuré par l'approche DryRun. Présenter la méthodologie en Phase 0. |
| **Nadège Perrin** — Responsable Commercial | Commercial | Référent | Salesforce, SlackConnect | 0,2 | Email | Modéré | Propriétaire fonctionnelle Salesforce. A créé le compte Admin partagé — sujet sensible à aborder avec tact. |
| **Bastien Couture** — Lead Dev | Technique | Référent | GitLab CE, Jira Cloud, Notion | 0,2 | Slack | Fort | Très attaché à l'autonomie technique. Inquiet du contrôle des repos GitLab. Prévoir démonstration du Shadow Mode. |
| **Amandine Leconte** — DRH | RH | Référent / Informé | BambooHR | 0,3 | Email | Faible | Sensible à la confidentialité des données RH. À informer en priorité sur le traitement RGPD des données BambooHR. |
| **Julien Faure** — Admin IT | IT | Validateur | AD on-prem (droits admin) | 1,2 | Teams | Modéré | Connaît l'AD CorpB mieux que quiconque. Indispensable pour la Phase 1. Peut être anxieux sur son rôle post-fusion. |
| **Claire Imbert** — Directrice Générale CorpB | Direction | Informée | — | 0,5 | Email | Faible | Informée en Phase 0 (communication DG-to-DG) et en Phase 5 (bilan). Ne pas l'impliquer dans les détails techniques. |
| **Paulo Esteves** — Responsable Prestataires | Prestataires | Référent | Jira Cloud, Dropbox Biz | 0,4 | Email | Modéré | Gère les comptes prestataires — périmètre sensible. Dropbox Biz Shadow IT vient de son équipe. |
| **[À COMPLÉTER]** — Responsable Finance | Finance | Référent | AS400 | 0,1 | Email | [À COMPLÉTER] | Propriétaire fonctionnel de l'AS400. À identifier précisément. |

---

### B.4 — Synthèse par phase

| Phase | Parties prenantes actives | Action attendue |
|---|---|---|
| **Phase 0** | Tous les référents CorpB + DSI CorpA + DPO | Fournir inventaire SaaS, valider matrice criticité |
| **Phase 1** | Julien Faure (CorpB IT) + Inès Moulin (CorpA IAM) + Karim Benali (RSSI) | Faciliter accès lecture AD, valider périmètre audit |
| **Phase 2** | Thierry Vogt + Nadège Perrin + Bastien Couture + Paulo Esteves | Valider CSV remédiation (colonne `Valider: OUI`) |
| **Phase 3** | Sophie Arnaud (Go/NoGo) + Marc Deschamps (validation RGPD) + Amandine Leconte (info RH) | Autoriser migration, informer les équipes CorpB |
| **Phase 4** | Inès Moulin + managers CorpA réceptionnant les équipes CorpB | Valider passation gouvernance |
| **Phase 5** | Karim Benali + Sophie Arnaud | Valider rapport de clôture |

---

### B.5 — Points de vigilance identifiés

**Bastien Couture (Lead Dev CorpB) — résistance forte**
Le dépôt GitLab CE contient des projets personnels et des tokens d'API. Bastien perçoit l'audit comme une intrusion. Approche recommandée : lui montrer le script en mode DryRun avant exécution, lui expliquer que l'objectif est la protection des repos (et donc de son travail), pas le contrôle de son activité.

**Nadège Perrin (Responsable Commercial CorpB) — sujet sensible**
Le compte Salesforce Admin partagé entre Nadège et un collègue est un anti-pattern de sécurité. Elle en est probablement consciente mais l'a mis en place par pragmatisme. Aborder en tête-à-tête, pas en réunion collective. Proposer la solution (deux comptes nominatifs) en même temps que le constat.

**Julien Faure (Admin IT CorpB) — anxiété sur le rôle post-fusion**
Son rôle d'administrateur AD disparaît de facto avec la migration vers Entra ID. Ne pas esquiver le sujet. Lui proposer d'être associé à la formation sur Entra ID et au suivi Phase 4 pour l'aider à repositionner ses compétences.

---

*Matrice des parties prenantes — `iam-ma-integration-lab` — IAM-Lab Framework*
