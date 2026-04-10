# 📖 SCENARIO.md — Contexte M&A : CorpA absorbe CorpB

> Document narratif du lab `iam-ma-integration-lab`.
> Langue : Français. Cible : RSSI, DSI, consultant IAM.
> Ce scénario est entièrement fictif. Toute ressemblance avec des entités réelles est fortuite.

---

## 1. Contexte de la fusion

### CorpA — Entreprise absorbante

CorpA est une société de taille intermédiaire (ETI), active dans le secteur des services B2B. Elle dispose d'un système d'information mature sur le plan de la gestion des identités :

- Annuaire : **Microsoft Entra ID**, tenant unique `corpa.onmicrosoft.com`
- Authentification : **MFA obligatoire** pour tous les comptes, enforced via **Conditional Access**
- SaaS : portefeuille gouverné, SSO enforced sur les applications critiques
- Gouvernance : RBAC déployé, groupes de sécurité normés, revue trimestrielle des habilitations
- Conformité : alignement ISO 27001:2022 en cours de certification

CorpA emploie environ **500 utilisateurs** et dispose d'une équipe IT interne de 8 personnes dont un RSSI à temps partiel.

### CorpB — Entreprise cible (absorbée)

CorpB est une PME de 300 personnes, rachetée par CorpA dans le cadre d'une stratégie de croissance externe. Son infrastructure IT est typique d'une PME non accompagnée sur les enjeux IAM :

- Annuaire : **Active Directory on-premises**, déployé sur Windows Server 2016
- Structure : **2 domaines** (`corpb.local`, `legacy.corpb.local`), **5 unités organisationnelles**
- SaaS : **8 applications** en usage réel, sans gouvernance centralisée ni SSO
- MFA : **non déployé** — authentification par mot de passe simple pour tous les comptes
- Gouvernance : aucune politique de révocation formalisée, comptes de départ non désactivés
- Shadow IT : usage de **Dropbox Biz** non sanctionné par la DSI, détecté via analyse DNS

> **Signaux d'alerte identifiés lors du premier contact** : comptes actifs pour des collaborateurs partis depuis plus de 18 mois, trois administrateurs locaux non documentés, un compte Salesforce Admin partagé entre deux commerciaux, et un dépôt GitLab CE contenant des tokens d'API en clair.

---

## 2. Enjeux de l'intégration IAM

### 2.1 Enjeu sécuritaire

Migrer des comptes AD non assainis vers un tenant Entra ID sécurisé revient à **introduire des risques connus dans un environnement maîtrisé**. Les comptes SaaS non gouvernés amplifient ce risque : un ex-collaborateur CorpB encore actif sur Salesforce ou GitLab constitue une surface d'attaque directe sur les données CorpA post-fusion.

**Principe retenu** : on n'intègre pas ce qui n'a pas été audité. On ne provisionne pas ce qui n'a pas été validé.

### 2.2 Enjeu de conformité

CorpA est engagée dans une démarche ISO 27001. L'intégration de CorpB doit être **traçable, documentée et opposable**. Chaque action produit une preuve technique scellée. Le RGPD impose par ailleurs un traitement rigoureux des données personnelles des collaborateurs CorpB tout au long du processus.

### 2.3 Enjeu organisationnel

Les équipes IT de CorpB ne maîtrisent pas les outils Entra ID. Les managers de CorpB ne savent pas ce que la migration implique pour leurs équipes. Le lab modélise un **transfert de compétence progressif et accompagné**, documenté phase par phase via la couche OCM.

### 2.4 Enjeu de continuité

Les collaborateurs de CorpB doivent accéder aux ressources de CorpA **sans interruption de service** au moment du basculement. La Phase 3 intègre une logique de Shadow Mode : provisioning parallèle, comparaison avant bascule, rollback documenté.

---

## 3. Périmètre du lab

### 3.1 Structure AD CorpB simulée

| Élément | Valeur simulée |
|---|---|
| Domaines | `corpb.local`, `legacy.corpb.local` |
| Unités organisationnelles | Direction, Commercial, Technique, RH, Prestataires |
| Comptes utilisateurs | 312 (dont ~40 obsolètes, ~15 comptes de service) |
| Groupes de sécurité | 18 (dont 4 sans propriétaire identifié) |
| Comptes privilégiés | 6 (dont 3 non documentés) |
| Politique de mot de passe | Complexité minimale, aucune expiration enforced |

### 3.2 Catalogue SaaS CorpB simulé

| Application | Catégorie | Comptes simulés | Risque principal |
|---|---|---|---|
| **Salesforce** | CRM | 24 comptes dont 1 Admin partagé | Compte Admin non nominatif |
| **SlackConnect** | Collaboration | 287 comptes | Canaux externes ouverts vers CorpA |
| **GitLab CE** | Dev / SCM | 45 comptes | 3 tokens personnels exposés |
| **Notion** | Knowledge / Doc | 156 comptes | 12 espaces partagés avec adresses perso |
| **BambooHR** | RH | 8 comptes (DRH + managers) | Accès données RH non révoqués |
| **AS400** | ERP Legacy | 4 comptes de service partagés | Pas de MFA possible, mot de passe générique |
| **Jira Cloud** | ITSM | 67 comptes | 9 agents sans département rattaché |
| **Dropbox Biz** | Cloud Storage | 34 comptes | Shadow IT — non déclaré à la DSI |

> **Total SaaS** : 625 comptes applicatifs pour 312 utilisateurs AD.
> Ratio moyen : **2 comptes SaaS par utilisateur**. Certains utilisateurs cumulent 6 à 8 comptes applicatifs.

### 3.3 Tenant Entra ID CorpA (cible)

| Élément | Valeur simulée |
|---|---|
| Tenant | `corpa.onmicrosoft.com` |
| Conditional Access | 4 politiques actives (MFA, compliant device, location, legacy auth block) |
| Groupes de sécurité | Normés par département et niveau de sensibilité |
| Licence | Microsoft 365 E3 (hypothèse lab) |

---

## 4. Approche méthodologique : les 6 phases + OCM transverse

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                        CYCLE D'INTÉGRATION IAM M&A                                   │
│                                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────────┐     │
│  │ PHASE 0  │→ │ PHASE 1  │→ │   PHASE 2    │→ │  PHASE 3  │→ │   PHASE 4   │     │
│  │ PRÉPARAT.│  │  AUDIT   │  │ REMÉDIATION  │  │ MIGRATION │  │ GOUVERNANCE │     │
│  │ AD+SaaS  │  │ AD+SaaS  │  │  (AD source) │  │→ Entra ID │  │ post-fusion │     │
│  └──────────┘  └──────────┘  └──────────────┘  └───────────┘  └──────────────┘     │
│                                                                        ↓             │
│                                                          ┌──────────────────────┐    │
│                                                          │       PHASE 5        │    │
│                                                          │  SCELLAGE PREUVES    │    │
│                                                          └──────────────────────┘    │
│                                                                                      │
│  ══════════════════════════════ OCM TRANSVERSE ══════════════════════════════════   │
│  [Communication] → [Restitution] → [Notification] → [Guide J-Day] → [Passation]    │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### Phase 0 — Préparation (avant tout script)

**Objectif** : constituer la base de connaissance humaine et applicative avant d'ouvrir le moindre terminal.

Cette phase est le différenciateur méthodologique central du lab. La majorité des projets M&A IAM échouent parce qu'ils démarrent l'audit technique sans avoir répondu aux questions suivantes :

- Qui détient la connaissance métier chez CorpB ? (référents, BA, chefs de service)
- Quelles applications SaaS sont réellement utilisées, y compris en Shadow IT ?
- Quels accès sont critiques pour quelle fonction métier ?
- Qui doit être informé, dans quel ordre, et avec quel message ?

Livrables Phase 0 :
- **Matrice des parties prenantes** : référents CorpB par domaine métier, niveau d'implication, canal de communication
- **Inventaire SaaS** : catalogue des 8 applications, propriétaires, nombre de comptes, niveau de risque
- **Matrice de criticité** : croisement fonction métier × application × niveau d'accès
- **Plan de communication initial** : messages clés, calendrier, responsables (→ OCM Phase 0)

> Cette phase ne produit pas de script. Elle produit de la **connaissance structurée** qui conditionne la qualité de toutes les phases suivantes.

### Phase 1 — Audit et cartographie (CorpB AD + SaaS)

**Objectif** : produire une photographie complète et fiable de l'existant CorpB.

Le périmètre d'audit est **étendu au SaaS** : l'AD ne donne qu'une vision partielle des identités CorpB. Les comptes applicatifs SaaS doivent être cartographiés en parallèle.

Livrables : inventaire comptes AD, cartographie groupes, comptes à risque, rapport SaaS consolidé.

> Règle absolue : **lecture seule**. Aucune modification à ce stade.

### Phase 2 — Remédiation de l'AD source

**Objectif** : assainir l'AD CorpB avant migration. Ne migrer que des identités propres et documentées.

Chaque action passe par un **CSV de validation humaine**. Colonne `Valider` : `OUI` exact déclenche l'exécution. Le CSV validé est scellé avant exécution.

### Phase 3 — Migration vers Entra ID

**Objectif** : provisionner les identités CorpB validées dans le tenant CorpA.

Approche Shadow Mode : provisioning parallèle sans bascule immédiate. Vérification de l'application des Conditional Access policies sur les nouveaux comptes. Guide utilisateur J-Day produit par l'OCM.

### Phase 4 — Gouvernance post-intégration

**Objectif** : garantir que l'environnement fusionné reste gouverné et conforme dans la durée.

Périmètre étendu au SaaS : audit des comptes orphelins applicatifs, revue des accès critiques (Salesforce Admin, GitLab tokens), alignement avec la politique SSO CorpA.

### Phase 5 — Scellage des preuves

**Objectif** : garantir l'intégrité et l'opposabilité de l'ensemble des rapports produits.

SHA-256 + RFC 3161 via le module [`iam-evidence-sealer`](https://github.com/CrepuSkull/iam-evidence-sealer).

> Certificats auto-signés dans ce lab : `démonstration/test uniquement` — pas de valeur probante réglementaire.

---

## 5. La couche OCM — accompagnement au changement

### Pourquoi l'OCM n'est pas une phase

L'accompagnement au changement n'intervient pas après les phases techniques. Il les **précède, les accompagne et les prolonge**. Traiter l'OCM comme une phase terminale, c'est arriver trop tard : les résistances sont déjà installées, les rumeurs ont circulé, la confiance est entamée.

Dans ce lab, l'OCM est un **fil conducteur transverse** : chaque phase technique produit un livrable humain associé.

### Principe des livrables duaux

| Phase | Livrable technique | Livrable OCM associé |
|---|---|---|
| Phase 0 | Matrice parties prenantes | Plan de communication initial |
| Phase 1 | Rapport d'audit AD + SaaS | Restitution aux référents métier CorpB |
| Phase 2 | CSV de remédiation validé | Notice d'information aux managers concernés |
| Phase 3 | Rapport de migration | Guide utilisateur J-Day (connexion MFA, nouveaux accès) |
| Phase 4 | Rapport de gouvernance | Document de passation aux managers CorpA |
| Phase 5 | Rapports scellés | Rapport de clôture projet pour le CODIR |

### Ce que l'OCM couvre dans ce lab

- **Information** : qui est informé de quoi, quand, par qui
- **Compréhension** : expliquer l'impact concret sur le quotidien des collaborateurs CorpB
- **Adhésion** : associer les référents métier CorpB à la validation des décisions (Phase 0 et Phase 2)
- **Autonomisation** : former les managers CorpA à gouverner les nouvelles identités (Phase 4)
- **Mémoire** : produire un bilan traçable pour les projets futurs (Phase 5)

> L'OCM ne remplace pas une démarche de conduite du changement à grande échelle. Il en constitue le **squelette opérationnel minimum** applicable à tout projet d'intégration IAM.

---

## 6. Glossaire du scénario

| Terme | Définition |
|---|---|
| **AD on-premises** | Active Directory déployé sur un serveur local (non cloud) |
| **Entra ID** | Service d'identité cloud Microsoft (anciennement Azure Active Directory) |
| **Tenant** | Instance Entra ID isolée, propre à une organisation |
| **OU** | Unité organisationnelle — conteneur logique dans AD |
| **Compte orphelin** | Compte actif dont le titulaire a quitté l'organisation |
| **Compte de service** | Compte technique utilisé par une application ou un processus automatisé |
| **Shadow IT** | Application utilisée sans validation de la DSI |
| **SSO** | Single Sign-On — authentification unique centralisée |
| **RBAC** | Role-Based Access Control — gestion des droits par rôles |
| **SoD** | Separation of Duties — interdiction de cumuler des droits incompatibles |
| **MFA** | Multi-Factor Authentication — authentification à plusieurs facteurs |
| **Conditional Access** | Politiques Entra ID conditionnant l'accès selon des critères contextuels |
| **Shadow Mode** | Fonctionnement en parallèle d'un nouveau système, sans bascule effective |
| **DryRun** | Exécution simulée — aucune écriture en production |
| **JML** | Joiner / Mover / Leaver — cycle de vie complet d'une identité |
| **OCM** | Organizational Change Management — accompagnement au changement |
| **RFC 3161** | Standard d'horodatage tiers certifié, conférant une valeur probante |
| **BA** | Business Analyst — référent métier, interface entre DSI et directions fonctionnelles |

---

## 7. Ce que ce lab ne couvre pas (v1)

- Migration des **ressources** (partages, boîtes mail, licences applicatives)
- **Fédération SAML/OIDC** entre CorpB et les applications CorpA (voir [`iam-federation-lab`](https://github.com/CrepuSkull/iam-federation-lab))
- Déploiement d'un outil IGA du marché (SailPoint, Saviynt)
- Architecture Entra ID Connect en production
- Gestion des **postes de travail** (jointure Entra ID, Intune)
- Intégration **API native SaaS** (les inventaires SaaS sont basés sur exports CSV en v1)
- Démarche OCM à grande échelle (accompagnement psychosocial, comités de pilotage)

Ces extensions pourront faire l'objet d'une v2 du lab.

---

*Document narratif — `iam-ma-integration-lab` — IAM-Lab Framework*
