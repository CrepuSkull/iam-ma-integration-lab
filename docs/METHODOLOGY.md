# Méthodologie IAM 360° — Intégration des identités en contexte M&A

> `iam-ma-integration-lab` / docs
> Document de référence méthodologique
> Langue : Français | Cible : RSSI, DSI, consultant IAM, chef de projet M&A

---

## Avant-propos

Ce document décrit la méthodologie qui sous-tend le lab `iam-ma-integration-lab`.
Elle est applicable à tout projet d'intégration IAM en contexte de fusion-acquisition,
indépendamment de la taille des entités ou des technologies utilisées.

La méthodologie s'appelle **IAM 360°** parce qu'elle traite simultanément
trois dimensions que les projets IAM classiques dissocient au détriment de leur
réussite : la dimension **Technique**, la dimension **Organisationnelle**
et la dimension **Humaine**.

---

## 1. Fondements de la méthodologie

### 1.1 Le problème que cette méthode résout

Les projets d'intégration IAM en contexte M&A échouent systématiquement
pour trois raisons structurelles, chacune relevant d'une dimension distincte.

**Dimension Technique** : on migre trop tôt. L'audit de l'entreprise cible
est insuffisant, les comptes obsolètes ne sont pas traités avant migration,
les applications SaaS sont oubliées. Résultat : on importe des risques connus
dans un environnement qu'on voulait sécurisé.

**Dimension Organisationnelle** : on ne valide pas. Les décisions
d'action (désactivation d'un compte, révocation d'un droit) sont prises
unilatéralement par l'équipe technique sans implication des responsables
métier. Résultat : des erreurs, des contestations, des réactivations d'urgence.

**Dimension Humaine** : on n'accompagne pas. Les collaborateurs de l'entreprise
absorbée découvrent le changement le jour J, sans préparation, sans contexte,
sans interlocuteur identifié. Résultat : des résistances, des tickets en masse,
une défiance durable envers les équipes IT.

La méthode IAM 360° adresse les trois dimensions de façon simultanée
et non séquentielle.

### 1.2 Les trois piliers

```
┌─────────────────────────────────────────────────────────────────┐
│                      IAM 360°                                   │
│                                                                 │
│   TECHNIQUE              ORGANISATION             HUMAIN        │
│   ──────────             ────────────             ──────        │
│   Audit rigoureux        Validation humaine        OCM          │
│   Scripts reproductibles obligatoire à chaque      transverse   │
│   Preuves scellées       étape d'action            Personas     │
│   Mode DryRun            CSV de validation         identifiés   │
│   Shadow Mode            Go/NoGo formalisé         dès Phase 0  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Le principe de non-duplication

La méthode IAM 360° s'inscrit dans le **IAM-Lab Framework** existant.
Elle n'en réinvente pas les composants — elle les orchestre dans le contexte
spécifique M&A.

- L'audit AD s'appuie sur `iam-foundation-lab`
- Le cycle JML s'appuie sur `IAM-Lab-Identity-Lifecycle`
- La gouvernance continue s'appuie sur `iam-governance-lab`
- Le scellage des preuves s'appuie sur `iam-evidence-sealer`
- L'audit de fédération s'appuie sur `iam-federation-lab`

Le lab M&A orchestre, contextualise et étend. Il ne duplique pas.

---

## 2. Architecture de la méthode

### 2.1 La séquence des six phases

```
PHASE 0        PHASE 1        PHASE 2        PHASE 3
──────────     ──────────     ──────────     ──────────
PRÉPARER       AUDITER        ASSAINIR       MIGRER

Comprendre     Photographier  Corriger ce    Provisionner
le contexte    l'existant     qui est        ce qui est
humain et      sans modifier  problématique  propre
applicatif     quoi que       avec           vers la cible
avant tout     ce soit        validation
               script                        ↓

                                          PHASE 4        PHASE 5
                                          ──────────     ──────────
                                          GOUVERNER      SCELLER

                                          Contrôler      Garantir
                                          l'état         l'intégrité
                                          fusionné       des preuves
                                          dans la durée  produites
```

### 2.2 Le fil conducteur OCM

L'accompagnement au changement n'est pas une phase — c'est une **posture
permanente** matérialisée par des livrables duaux à chaque étape.

```
Phase  →  Livrable technique    +    Livrable humain (OCM)
──────     ────────────────          ──────────────────────
0          Inventaire SaaS           Plan de communication initial
1          Rapport d'audit AD        Restitution aux référents métier
2          CSV de remédiation        Notice d'information managers
3          Rapport de migration      Guide utilisateur J-Day
4          Rapport de gouvernance    Passation aux managers CorpA
5          Rapports scellés          Rapport de clôture CODIR
```

### 2.3 Les garde-fous techniques non négociables

Cinq règles architecturales qui ne peuvent pas être contournées :

**Règle 1 — Lecture seule par défaut**
Tout script d'audit produit des rapports mais ne modifie rien.
Cette règle est codée dans la structure du script, pas dans un paramètre.

**Règle 2 — DryRun activé par défaut**
Tout script de remédiation ou de migration s'exécute en simulation
tant que `-DryRun:$false` n'est pas explicitement passé.

**Règle 3 — Validation CSV obligatoire**
Toute action de remédiation passe par un CSV intermédiaire validé
par un être humain identifié. La colonne `Valider: OUI` (exact) est
le seul déclencheur d'exécution. Vide ou toute autre valeur = refus.

**Règle 4 — Scellage avant exécution**
Le CSV validé est scellé (SHA-256) avant toute exécution.
Toute modification post-scellage invalide l'opération.

**Règle 5 — Rollback documenté**
Chaque phase d'écriture produit un fichier de rollback avec l'état
antérieur de chaque objet modifié. Le rollback doit être exécutable
en moins de 15 minutes.

---

## 3. Principes opérationnels

### 3.1 Le principe de séquentialité stricte

Les phases ne sont pas parallélisables.

On ne démarre pas la Phase 2 sans avoir terminé la Phase 1.
On ne démarre pas la Phase 3 sans que le GO de la checklist Phase 3
soit validé. On ne passe pas au J-Day sans que le delta post-migration
soit nul ou explicitement accepté.

Cette rigueur séquentielle est une protection, pas une contrainte :
elle empêche de se retrouver à migrer des comptes qui n'ont pas été audités,
ou à activer des comptes dont le delta n'a pas été vérifié.

### 3.2 Le principe de connaissance avant action

Aucune action technique ne précède la connaissance humaine et applicative.

La Phase 0 n'est pas optionnelle. Elle n'est pas raccourcissable.
Identifier les référents métier, cartographier le périmètre SaaS,
établir la matrice de criticité — ces activités sont des prérequis
à l'audit, pas des activités parallèles.

Un audit conduit sans avoir identifié à qui transmettre ses résultats
pour validation est un audit sans valeur opérationnelle.

### 3.3 Le principe de proportionnalité

La méthode s'adapte à la taille du projet. Une PME de 50 personnes
et une ETI de 500 personnes n'ont pas le même niveau de complexité,
mais les mêmes étapes s'appliquent avec un niveau de formalisme ajusté.

Ce qui ne s'ajuste pas : les garde-fous techniques (DryRun, CSV validation,
scellage) et la présence d'un livrable OCM à chaque phase.

### 3.4 Le principe de traçabilité totale

Tout ce qui est décidé est tracé. Tout ce qui est exécuté est loggé.

Cela signifie concrètement :
- Les CSV de validation sont conservés avec les noms des validateurs
  et les dates de validation
- Les logs d'exécution sont scellés en Phase 5
- Les rollbacks, s'ils sont utilisés, sont documentés et conservés
- Le rapport de clôture (OCM Phase 5) consolide toutes les métriques

Cette traçabilité n'est pas du reporting pour le reporting. Elle est
la matière première d'une posture de conformité ISO 27001 documentable.

---

## 4. La dimension SaaS — extension nécessaire

### 4.1 Pourquoi l'AD ne suffit pas

L'Active Directory ne donne qu'une vision partielle des identités
d'une PME moderne. Une PME de 300 personnes utilise en moyenne entre
6 et 12 applications SaaS, chacune avec son propre annuaire de comptes,
souvent déconnecté de l'AD.

Dans le scénario CorpB : 312 utilisateurs AD mais 625 comptes SaaS,
soit 2 comptes applicatifs par utilisateur. Certains utilisateurs
cumulent 6 à 8 identités applicatives distinctes.

Migrer l'AD sans cartographier le SaaS, c'est traiter 50% du périmètre.

### 4.2 Le Shadow IT comme cas particulier

Le Shadow IT (applications utilisées sans validation DSI) est présent
dans la quasi-totalité des PME. Il est par définition invisible à l'AD
et aux inventaires DSI classiques.

La méthode prévoit deux vecteurs de détection en Phase 0 :
- Analyse des logs proxy/DNS (détection comportementale)
- Questionnaire aux managers avec question explicite sur les outils
  non déclarés (détection déclarative)

La combinaison des deux augmente significativement la couverture.

### 4.3 Le SaaS dans chaque phase

| Phase | Traitement SaaS |
|---|---|
| 0 | Inventaire + scoring risque (`Audit-SaaSRisk.py`) |
| 1 | Extension de l'audit AD au périmètre SaaS |
| 2 | Traitement des cas urgents (tokens exposés, compte Admin partagé) |
| 3 | Notification aux utilisateurs sur les changements d'identifiant SaaS |
| 4 | Gouvernance post-fusion (`Audit-SaaSPostFusion.py`) |
| 5 | Scellage des rapports SaaS |

---

## 5. La posture du consultant IAM M&A

### 5.1 Facilitateur, pas auditeur certifié

Dans la terminologie de ce framework, le rôle du consultant IAM
n'est pas celui d'un auditeur certifié qui sanctionne des écarts.
C'est celui d'un **facilitateur de conformité** qui accompagne
l'organisation vers un état cible documenté.

Cette distinction est importante pour la relation avec les équipes
de l'entreprise absorbée. Un auditeur qui sanctionne génère de la
résistance. Un facilitateur qui accompagne génère de la coopération.

### 5.2 Les trois postures simultanées

Le consultant IAM M&A tient trois postures en même temps :

**Posture technique :** maîtrise des outils (PowerShell, Graph API,
Python), capacité à produire des scripts reproductibles, compréhension
des architectures AD et Entra ID.

**Posture organisationnelle :** capacité à structurer un projet,
à identifier les parties prenantes, à produire des livrables lisibles
par des non-techniciens, à gérer les validations.

**Posture humaine :** capacité à nommer les résistances sans les
amplifier, à adapter le message à l'interlocuteur (DG vs admin IT vs
manager commercial), à maintenir la confiance même quand les nouvelles
sont difficiles.

### 5.3 Ce que cette méthode ne garantit pas

La méthode IAM 360° garantit une intégration des identités structurée,
traçable et accompagnée. Elle ne garantit pas :
- L'absence d'incidents post-migration (c'est l'objet de la Phase 4)
- La conformité réglementaire complète (qui nécessite une validation juridique)
- La satisfaction de 100% des utilisateurs
- L'absence de résistances

Ce qu'elle garantit : que si un incident survient, les preuves de la
rigueur du processus sont disponibles, intègres et opposables.

---

## 6. Indicateurs de succès

### 6.1 Indicateurs techniques

| Indicateur | Cible | Mesure |
|---|---|---|
| Comptes obsolètes traités avant migration | 100% | Audit Phase 1 + Phase 2 log |
| Comptes privilégiés documentés avant migration | 100% | Audit Phase 1 |
| Delta post-migration (MANQUANT + SURPLUS) | 0 | Audit-PostMigrationDelta |
| MFA activé J+7 | > 90% | Rapport Entra ID SignIn logs |
| Rapports scellés Phase 5 | 100% des rapports | Manifest JSON |

### 6.2 Indicateurs organisationnels

| Indicateur | Cible | Mesure |
|---|---|---|
| CSV de validation retournés | 100% des managers sollicités | Suivi OCM |
| Actions effectuées sans CSV validé | 0 | Log d'exécution |
| Rollbacks nécessaires | 0 | Log d'exécution Phase 2-3 |
| Incidents de sécurité liés à la migration | 0 | ITSM CorpA |

### 6.3 Indicateurs humains

| Indicateur | Cible | Mesure |
|---|---|---|
| Tickets support J-Day | < 5% des utilisateurs | ITSM J-Day |
| Satisfaction collaborateurs CorpB J+30 | > 3,5/5 | Questionnaire post-migration |
| Escalades Phase 2 non résolues | 0 | Suivi chef de projet |

---

## 7. Évolutions prévues (v2)

Les extensions identifiées pour la v2 de ce lab sont :

- **Intégration API native SaaS** : remplacement des exports CSV manuels
  par des appels API directs (Salesforce, Slack, GitLab)
- **Fédération SAML/OIDC** : intégration des flux d'authentification
  fédérés entre CorpB et les applications CorpA
- **Outil IGA** : overlay sur un outil du marché (SailPoint, Saviynt)
  pour les organisations plus matures
- **Multi-entités** : extension du scénario à une acquisition simultanée
  de plusieurs PME (3 entités, 3 niveaux de maturité différents)

---

*Document de méthodologie — `iam-ma-integration-lab` — IAM-Lab Framework*
*Version 1.0 — Auteur : Arnaud Montcho — consultant IAM/IGA hybride*
