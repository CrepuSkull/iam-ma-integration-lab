# 📊 OCM-Phase1-StakeholderBriefing.md — Restitution d'audit aux référents CorpB

> `iam-ma-integration-lab` / ocm
> Livrable OCM associé à la Phase 1 — Audit
> À produire dans les 48h suivant la fin de l'audit
> Langue : Français | Destinataires : référents métier CorpB, RSSI CorpA

---

## Section A — Template générique

> Instructions : compléter les placeholders `[À COMPLÉTER]` avec les résultats réels.
> Ce document est destiné à des managers et référents métier — pas à des techniciens.
> Éviter le jargon technique non expliqué. Chaque constat doit être suivi d'une action concrète.

### A.1 — Objectif de la restitution

Cette restitution a deux fonctions :

1. **Informer** les référents métier CorpB des résultats de l'audit — ce qui a été trouvé, ce que ça signifie pour leurs équipes
2. **Préparer** leur implication dans la Phase 2 — ils devront valider des listes d'action avant toute modification

> Règle OCM fondamentale : on ne demande jamais à un manager de valider quelque chose
> qu'il n'a pas compris. Ce document est le support de cette compréhension.

### A.2 — Structure du document de restitution

```
1. Résumé exécutif (5 lignes max — ce que tout le monde doit retenir)
2. Ce que nous avons audité
3. Ce que nous avons trouvé (par thème, sans jargon)
4. Ce que ça implique pour vos équipes
5. Ce que nous allons faire, et avec qui
6. Planning et prochaines étapes
```

### A.3 — Template résumé exécutif

```
L'audit des systèmes informatiques de [Entreprise cible] est terminé.

Voici ce qu'il faut retenir :

→ [X] comptes informatiques ont été recensés au total.
→ [X] comptes appartenant à des personnes qui ont quitté l'entreprise
  sont encore actifs. Ils seront désactivés après votre validation.
→ [X] applications utilisées par vos équipes ont été cartographiées,
  dont [X] non déclarées à la DSI ([Entreprise absorbante]).
→ La politique de sécurité des mots de passe présente [X] écarts
  par rapport aux standards de [Entreprise absorbante].

Ces constats n'ont rien d'inhabituel pour une entreprise de la taille
de [Entreprise cible]. Ils seront traités méthodiquement dans les
prochaines semaines, avec votre validation à chaque étape importante.
```

### A.4 — Consignes de diffusion

| Destinataire | Contenu à partager | Canal | Timing |
|---|---|---|---|
| RSSI / DSI entreprise absorbante | Document complet + CSV bruts | Email sécurisé | Immédiat |
| Managers référents entreprise cible | Résumé exécutif + section "impact équipes" | Réunion 30 min | J+1 après audit |
| DG entreprise cible | Résumé exécutif uniquement | Email | J+2 après audit |
| DPO | Section comptes obsolètes + SaaS RGPD | Email | J+2 après audit |

---

## Section B — Exemple CorpA/CorpB

> Restitution rédigée dans le contexte fictif du lab.
> Résultats basés sur les datasets `corpb-users.csv` et `corpb-saas-accounts.csv`.

---

### B.1 — Résumé exécutif

**Destinataires** : Thierry Vogt (DSI CorpB), Nadège Perrin, Bastien Couture, Amandine Leconte, Paulo Esteves
**Émetteur** : Inès Moulin (Ingénieure IAM CorpA) / Sophie Arnaud (DSI CorpA)
**Date** : J+1 après fin Phase 1

---

L'audit des systèmes informatiques de CorpB est terminé. Voici ce qu'il faut retenir.

**312 comptes informatiques** ont été recensés dans l'Active Directory CorpB, répartis sur 5 départements et 2 domaines. **8 applications SaaS** ont été cartographiées, dont une (Dropbox Biz) qui n'avait pas été déclarée à la DSI.

**49 comptes** appartenant à des personnes qui ont quitté CorpB sont encore actifs dans le système. Ils n'ont aucun accès légitime aujourd'hui. Ils seront désactivés après validation de vos managers concernés.

**5 comptes disposent de droits d'administration** dans l'AD CorpB. 2 d'entre eux ne sont pas documentés — nous ne savons pas pourquoi ils ont ces droits. Ce point sera traité en priorité.

**3 tokens d'accès techniques** sont exposés dans des dépôts GitLab. Ce point a été signalé à Bastien Couture dès leur détection — une rotation est nécessaire avant tout autre chose.

Ces constats n'ont rien d'exceptionnel pour une PME de 300 personnes. Ils seront traités méthodiquement, avec votre validation à chaque étape.

---

### B.2 — Ce que nous avons audité

| Périmètre | Méthode | Accès utilisé |
|---|---|---|
| Active Directory CorpB | Scripts PowerShell en lecture seule | Compte Domain Users + Read |
| 8 applications SaaS | Inventaire Phase 0 + analyse des risques | Aucun accès applicatif — données déclaratives et DNS |
| Politique de mots de passe | Lecture Default Domain Policy | Même compte lecture |

> Aucune modification n'a été effectuée. Aucun accès à vos données de travail (emails, fichiers, projets).

---

### B.3 — Ce que nous avons trouvé

#### Comptes informatiques AD

| Constat | Nombre | Niveau de priorité |
|---|---|---|
| Comptes actifs | 263 | — |
| Comptes désactivés | 49 | — |
| Comptes d'anciens collaborateurs encore actifs | 49 | 🔴 Prioritaire |
| Comptes avec droits d'administration | 5 | 🔴 Prioritaire |
| Comptes sans documentation | 2 | 🔴 Prioritaire |
| Comptes de service techniques | 12 | 🟡 À revoir |
| Aucun compte avec double authentification (MFA) | 312/312 | 🟡 À traiter en migration |

**Ce que ça veut dire en langage clair :** des personnes qui ne travaillent plus chez CorpB peuvent potentiellement encore se connecter aux systèmes. Ce n'est pas un problème causé par une négligence — c'est simplement un processus de départ qui n'a pas inclus la désactivation informatique systématique.

#### Applications SaaS

| Application | Constat principal | Priorité |
|---|---|---|
| **Salesforce** | Compte Admin partagé entre 2 personnes dont une partie | 🔴 Urgent |
| **GitLab CE** | 3 tokens d'accès exposés dans des commits | 🔴 Urgent — déjà signalé à Bastien |
| **BambooHR** | Pas de double authentification sur données RH | 🔴 Prioritaire |
| **AS400** | Comptes de service partagés, pas de traçabilité individuelle | 🔴 Risque accepté à documenter |
| **Dropbox Biz** | Non déclaré à la DSI — contenu inconnu | 🟡 À régulariser |
| **SlackConnect** | MFA partiel (admins seulement) | 🟡 À enforcer |
| **Notion** | 12 comptes avec adresses email personnelles | 🟡 À requalifier |
| **Jira Cloud** | 9 agents sans département rattaché | 🟢 À qualifier |

#### Politique de mots de passe

La politique de sécurité des mots de passe de CorpB présente **4 écarts** par rapport aux standards de CorpA :
- Les mots de passe n'ont pas de règle de complexité obligatoire
- Aucun verrouillage automatique après tentatives échouées
- Les mots de passe n'ont pas de durée d'expiration définie
- La longueur minimale est de 6 caractères (contre 12 recommandés)

**Ce que ça veut dire :** ces écarts ne seront pas corrigés sur l'AD CorpB — ce serait un travail inutile puisque l'AD va être migré. En revanche, les comptes CorpB qui seront créés dans l'environnement CorpA hériteront automatiquement des politiques CorpA dès la migration.

---

### B.4 — Ce que ça implique pour vos équipes

**Nadège Perrin (Commercial) :**
Le compte Salesforce Admin partagé va être remplacé par deux comptes nominatifs individuels. Nous vous contacterons pour organiser cette transition sans interruption d'accès. La liste des comptes Salesforce de votre équipe vous sera soumise pour validation.

**Bastien Couture (Technique) :**
Les 3 tokens GitLab exposés doivent être révoqués et régénérés. Nous vous avons déjà alerté. Votre équipe recevra la liste des comptes GitLab et Jira à valider. L'instance GitLab CE on-premises fait partie du périmètre à migrer — nous en parlerons séparément.

**Amandine Leconte (RH) :**
Les données BambooHR sont dans le périmètre RGPD. Marc Deschamps (DPO CorpA) vous contactera séparément. Sur le plan technique : l'activation du MFA sur BambooHR est la priorité avant la migration.

**Paulo Esteves (Prestataires) :**
L'usage de Dropbox Biz sans déclaration DSI nécessite une régularisation. Nous avons besoin de comprendre ce qui y est stocké pour décider : régularisation, migration vers un outil approuvé, ou fermeture. Un échange en tête-à-tête est prévu.

**Thierry Vogt / Julien Faure (IT CorpB) :**
La liste complète des comptes à désactiver et des groupes orphelins vous sera soumise sous forme de fichier à valider. Aucune action avant votre validation. Julien, nous souhaitons vous associer à la Phase 3 pour l'accompagnement Entra ID.

---

### B.5 — Ce que nous allons faire, et avec qui

| Action | Responsable technique | Validateur CorpB | Timing |
|---|---|---|---|
| Désactivation comptes obsolètes | Inès Moulin | Manager département concerné | Phase 2 — Semaine du [date] |
| Rotation tokens GitLab | Bastien Couture | Bastien Couture | **Urgent — avant Phase 2** |
| Création comptes Salesforce nominatifs | Inès Moulin | Nadège Perrin | Phase 2 |
| Régularisation Dropbox Biz | Inès Moulin + Paulo | Paulo Esteves | Phase 2 |
| Activation MFA BambooHR | Inès Moulin | Amandine Leconte | Phase 3 |
| Documentation comptes privilégiés | Julien Faure + Inès | Thierry Vogt | Phase 2 — prioritaire |

---

### B.6 — Planning et prochaines étapes

```
Cette semaine    → Rotation tokens GitLab (Bastien — action immédiate)
Semaine prochaine → Envoi des CSV de validation à chaque manager concerné
                    (30 min de votre temps pour valider ligne par ligne)
Semaine +2       → Exécution des désactivations validées
Semaine +4       → Migration vers Entra ID — vous recevrez un guide utilisateur
                    3 jours avant la date de bascule
```

**Votre interlocutrice pour toute question :**
Inès Moulin — ines.moulin@corpa.fr — Teams

---

### B.7 — Suivi de diffusion

| Destinataire | Envoyé | Retour reçu | Points soulevés |
|---|---|---|---|
| Sophie Arnaud (DSI CorpA) | [ ] | [ ] | — |
| Karim Benali (RSSI CorpA) | [ ] | [ ] | — |
| Marc Deschamps (DPO CorpA) | [ ] | [ ] | — |
| Thierry Vogt (DSI CorpB) | [ ] | [ ] | — |
| Nadège Perrin | [ ] | [ ] | — |
| Bastien Couture | [ ] | [ ] | — |
| Amandine Leconte | [ ] | [ ] | — |
| Paulo Esteves | [ ] | [ ] | — |

---

*OCM Phase 1 — Restitution d'audit — `iam-ma-integration-lab` — IAM-Lab Framework*
