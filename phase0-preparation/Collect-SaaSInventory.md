# 🌐 Collect-SaaSInventory.md — Inventaire SaaS

> `iam-ma-integration-lab` / phase0-preparation
> Livrable : Phase 0 — Préparation
> Format : Template générique (Section A) + Catalogue fictif CorpB (Section B)

---

## Section A — Template générique

> Instructions : dupliquer ce fichier, renommer en `saas-inventory-[client].md`,
> compléter la Section A avec les données réelles de l'entreprise cible.

### A.1 — Objectif de l'inventaire

Cet inventaire vise à :
1. **Identifier** toutes les applications SaaS utilisées, y compris le Shadow IT
2. **Qualifier** chaque application (criticité, données hébergées, gouvernance IAM)
3. **Préparer** l'audit des comptes SaaS (Phase 1) et la gouvernance post-fusion (Phase 4)
4. **Alimenter** la matrice de criticité et le mapping RGPD (sous-traitants Art. 28)

> Un compte SaaS non inventorié en Phase 0 est un risque non traité en Phase 4.
> Le Shadow IT est systématiquement inclus — son omission fausse l'évaluation globale.

### A.2 — Méthodes de collecte

Utiliser au moins deux méthodes en combinaison :

| Méthode | Outils | Couvre le Shadow IT ? |
|---|---|---|
| Entretien DSI / admin IT | — | Partiel |
| Questionnaire auto-déclaratif (managers) | Google Forms, Teams Form | Partiel |
| Analyse logs proxy / DNS | Proxy logs, Pi-hole, Zscaler | Oui |
| Export facturation IT / comptabilité | ERP, relevés bancaires pro | Oui (apps payantes) |
| Scan réseau passif | Wireshark, Zeek (lab only) | Oui |

> En lab : méthode simulée. Le catalogue CorpB est pré-rempli en Section B.

### A.3 — Structure de l'inventaire

| Champ | Description | Valeurs possibles |
|---|---|---|
| Application | Nom de l'application | — |
| Catégorie | Type fonctionnel | CRM, Collaboration, Dev/SCM, RH, ERP Legacy, ITSM, Knowledge, Cloud Storage |
| Fournisseur | Éditeur / hébergeur | — |
| Propriétaire fonctionnel | Référent métier CorpB | Nom + département |
| Comptes estimés | Nombre d'utilisateurs | Entier |
| Comptes admin | Nombre d'admins | Entier |
| MFA activé | Authentification forte | Oui / Non / Partiel |
| SSO configuré | Fédération avec AD/Entra | Oui / Non |
| Partage de credentials | Compte partagé entre utilisateurs | Oui / Non / Suspicion |
| Données sensibles | Type de données hébergées | Clients / RH / Code source / Finances / Aucune |
| Statut DSI | Déclaré ou Shadow IT | Déclaré / Shadow IT |
| DPA signé | Contrat sous-traitant RGPD | Oui / Non / Inconnu |
| Hébergement | Localisation des données | UE / Hors UE / Inconnu |
| Niveau de risque initial | Évaluation qualitative | CRITIQUE / ÉLEVÉ / MODÉRÉ / FAIBLE |
| Action Phase 0 | Décision immédiate | Inventorier / Régulariser / Bloquer / Escalader |

---

## Section B — Catalogue fictif CorpB

> Catalogue complet des 8 applications SaaS simulées pour le lab.
> Données fictives. Utilisées comme input pour `Audit-SaaSRisk.py`.

### B.1 — Vue d'ensemble

| # | Application | Catégorie | Comptes | Risque | Statut DSI |
|---|---|---|---|---|---|
| 1 | Salesforce | CRM | 24 | CRITIQUE | Déclaré |
| 2 | SlackConnect | Collaboration | 287 | ÉLEVÉ | Déclaré |
| 3 | GitLab CE | Dev / SCM | 45 | ÉLEVÉ | Déclaré |
| 4 | Notion | Knowledge / Doc | 156 | MODÉRÉ | Déclaré |
| 5 | BambooHR | RH | 8 | CRITIQUE | Déclaré |
| 6 | AS400 | ERP Legacy | 4 | CRITIQUE | Déclaré |
| 7 | Jira Cloud | ITSM | 67 | MODÉRÉ | Déclaré |
| 8 | Dropbox Biz | Cloud Storage | 34 | ÉLEVÉ | **Shadow IT** |

**Total comptes SaaS** : 625 pour 312 utilisateurs AD (ratio 2,0 comptes SaaS/utilisateur)

---

### B.2 — Fiches détaillées

---

#### Application 1 — Salesforce (CRM)

| Champ | Valeur |
|---|---|
| **Fournisseur** | Salesforce, Inc. |
| **Propriétaire fonctionnel** | Nadège Perrin — Responsable Commercial |
| **Comptes estimés** | 24 (18 utilisateurs, 3 managers, 1 Admin partagé, 2 inactifs) |
| **Comptes admin** | 1 (partagé entre Nadège Perrin et un collègue parti en mars) |
| **MFA activé** | Non |
| **SSO configuré** | Non |
| **Partage de credentials** | OUI — compte Admin `sf-admin@corpb.com` partagé |
| **Données sensibles** | Clients (pipeline commercial, coordonnées, CA par client) |
| **Statut DSI** | Déclaré |
| **DPA signé** | Oui (Salesforce Data Processing Addendum) |
| **Hébergement** | UE (datacenter Frankfurt) |
| **Niveau de risque** | **CRITIQUE** |
| **Risques identifiés** | (1) Compte Admin non nominatif — impossible d'auditer les actions. (2) Ex-collaborateur potentiellement encore actif sur le compte partagé. (3) Absence de MFA sur données clients. |
| **Action Phase 0** | Escalader à Sophie Arnaud (DSI CorpA) + préparer remédiation nominative pour Phase 2 |

---

#### Application 2 — SlackConnect (Collaboration)

| Champ | Valeur |
|---|---|
| **Fournisseur** | Slack Technologies (Salesforce) |
| **Propriétaire fonctionnel** | Thierry Vogt — DSI CorpB |
| **Comptes estimés** | 287 (dont 23 comptes potentiellement obsolètes) |
| **Comptes admin** | 3 (Thierry Vogt + 2 workspace admins) |
| **MFA activé** | Partiel (activé pour les admins, optionnel pour les utilisateurs) |
| **SSO configuré** | Non |
| **Partage de credentials** | Non détecté |
| **Données sensibles** | Communications internes (potentiellement données clients, RH) |
| **Statut DSI** | Déclaré |
| **DPA signé** | Oui |
| **Hébergement** | UE |
| **Niveau de risque** | **ÉLEVÉ** |
| **Risques identifiés** | (1) 4 canaux Slack Connect actifs avec des interlocuteurs CorpA — canaux potentiellement accessibles post-fusion sans contrôle. (2) MFA non enforced sur la masse des utilisateurs. (3) 23 comptes possiblement orphelins. |
| **Action Phase 0** | Inventorier les canaux Connect CorpA + préparer enforcement MFA pour Phase 3 |

---

#### Application 3 — GitLab CE (Dev / SCM)

| Champ | Valeur |
|---|---|
| **Fournisseur** | GitLab Inc. (instance on-premises CorpB) |
| **Propriétaire fonctionnel** | Bastien Couture — Lead Dev |
| **Comptes estimés** | 45 (développeurs, DevOps, quelques managers) |
| **Comptes admin** | 2 (Bastien Couture + 1 admin IT) |
| **MFA activé** | Non (instance CE sans enforcement) |
| **SSO configuré** | Non |
| **Partage de credentials** | Non |
| **Données sensibles** | Code source propriétaire, tokens d'API (3 détectés en clair dans des repos) |
| **Statut DSI** | Déclaré |
| **DPA signé** | N/A (on-premises) |
| **Hébergement** | On-premises CorpB (serveur local) |
| **Niveau de risque** | **ÉLEVÉ** |
| **Risques identifiés** | (1) 3 tokens d'API exposés en clair dans des commits — rotation immédiate nécessaire. (2) Absence de MFA. (3) L'instance on-premises sera à migrer ou éteindre post-fusion. (4) Repos privés sans propriétaire identifié après départ de 2 développeurs. |
| **Action Phase 0** | Signaler tokens exposés à Bastien Couture + Karim Benali (RSSI CorpA) en urgence |

---

#### Application 4 — Notion (Knowledge / Doc)

| Champ | Valeur |
|---|---|
| **Fournisseur** | Notion Labs, Inc. |
| **Propriétaire fonctionnel** | Plusieurs départements (pas de propriétaire unique) |
| **Comptes estimés** | 156 (dont 12 comptes avec adresses email personnelles) |
| **Comptes admin** | 4 (workspace admins multiples) |
| **MFA activé** | Non |
| **SSO configuré** | Non |
| **Partage de credentials** | Non détecté |
| **Données sensibles** | Documentation interne, process RH, notes stratégiques |
| **Statut DSI** | Déclaré |
| **DPA signé** | Oui |
| **Hébergement** | UE (option activée) |
| **Niveau de risque** | **MODÉRÉ** |
| **Risques identifiés** | (1) 12 comptes avec adresses perso (@gmail, @hotmail) — hors périmètre AD, impossibles à désactiver via politique centralisée. (2) Absence de propriétaire unique complique la gouvernance. (3) Certains espaces partagés avec des prestataires externes. |
| **Action Phase 0** | Identifier les 12 comptes perso + cartographier les espaces partagés prestataires |

---

#### Application 5 — BambooHR (RH)

| Champ | Valeur |
|---|---|
| **Fournisseur** | Bamboo HR, LLC |
| **Propriétaire fonctionnel** | Amandine Leconte — DRH CorpB |
| **Comptes estimés** | 8 (DRH + managers avec accès RH) |
| **Comptes admin** | 1 (Amandine Leconte) |
| **MFA activé** | Non |
| **SSO configuré** | Non |
| **Partage de credentials** | Non |
| **Données sensibles** | Données RH : salaires, évaluations, arrêts maladie, coordonnées personnelles |
| **Statut DSI** | Déclaré |
| **DPA signé** | Oui |
| **Hébergement** | UE |
| **Niveau de risque** | **CRITIQUE** |
| **Risques identifiés** | (1) Données RH sensibles sans MFA — surface d'attaque maximale pour des données à fort impact RGPD. (2) L'accès de 2 managers ayant quitté CorpB doit être vérifié. (3) Intégration post-fusion avec le SI RH CorpA à anticiper. |
| **Action Phase 0** | Prioriser vérification des accès + informer Marc Deschamps (DPO CorpA) |

---

#### Application 6 — AS400 (ERP Legacy)

| Champ | Valeur |
|---|---|
| **Fournisseur** | IBM (instance on-premises CorpB) |
| **Propriétaire fonctionnel** | [À IDENTIFIER — Responsable Finance CorpB] |
| **Comptes estimés** | 4 comptes de service partagés |
| **Comptes admin** | 1 (compte générique `admin-as400`) |
| **MFA activé** | **Impossible** (architecture legacy IBM i) |
| **SSO configuré** | **Impossible** (architecture legacy) |
| **Partage de credentials** | OUI — 4 profils partagés entre plusieurs utilisateurs |
| **Données sensibles** | Données financières, comptabilité, facturation |
| **Statut DSI** | Déclaré |
| **DPA signé** | N/A (on-premises) |
| **Hébergement** | On-premises CorpB |
| **Niveau de risque** | **CRITIQUE** |
| **Risques identifiés** | (1) MFA architecturalement impossible — risque accepté documenté obligatoire. (2) Comptes partagés — aucune traçabilité individuelle des actions. (3) Mot de passe générique `admin-as400` jamais changé depuis l'installation. (4) Continuité critique : l'AS400 ne peut pas être éteint sans plan de migration préalable. |
| **Action Phase 0** | Identifier le propriétaire fonctionnel + documenter le risque accepté pour le RSSI CorpA |

---

#### Application 7 — Jira Cloud (ITSM)

| Champ | Valeur |
|---|---|
| **Fournisseur** | Atlassian |
| **Propriétaire fonctionnel** | Bastien Couture — Lead Dev (par défaut) |
| **Comptes estimés** | 67 (agents, utilisateurs, quelques clients externes) |
| **Comptes admin** | 3 |
| **MFA activé** | Partiel |
| **SSO configuré** | Non |
| **Partage de credentials** | Non détecté |
| **Données sensibles** | Tickets incidents, code (via Jira-GitLab intégration), données clients partielles |
| **Statut DSI** | Déclaré |
| **DPA signé** | Oui |
| **Hébergement** | UE |
| **Niveau de risque** | **MODÉRÉ** |
| **Risques identifiés** | (1) 9 agents sans département rattaché — orphelins applicatifs potentiels. (2) Intégration Jira-GitLab : si GitLab est migré/éteint, des workflows Jira peuvent casser. (3) Quelques comptes clients externes — périmètre à vérifier avec Paulo Esteves. |
| **Action Phase 0** | Inventorier les 9 agents orphelins + vérifier l'intégration GitLab |

---

#### Application 8 — Dropbox Biz (Cloud Storage) — SHADOW IT

| Champ | Valeur |
|---|---|
| **Fournisseur** | Dropbox, Inc. |
| **Propriétaire fonctionnel** | Paulo Esteves — Responsable Prestataires (usage informel) |
| **Comptes estimés** | 34 (détectés via analyse DNS — non déclarés) |
| **Comptes admin** | Inconnu |
| **MFA activé** | Inconnu |
| **SSO configuré** | Non |
| **Partage de credentials** | Suspicion (usage collaboratif de dossiers partagés) |
| **Données sensibles** | Inconnu — potentiellement documents contractuels prestataires, données clients |
| **Statut DSI** | **SHADOW IT — non déclaré à la DSI CorpB** |
| **DPA signé** | **Non** |
| **Hébergement** | Hors UE (US) par défaut sur les comptes gratuits/basiques |
| **Niveau de risque** | **ÉLEVÉ** |
| **Risques identifiés** | (1) Aucun DPA signé — violation RGPD Art. 28 potentielle si données personnelles hébergées. (2) Hébergement hors UE sans garanties documentées. (3) Contenu des dossiers partagés inconnu — impossible à auditer sans accès. (4) Si fermé brutalement, risque de perte de données actives pour les prestataires. |
| **Action Phase 0** | Contacter Paulo Esteves en tête-à-tête + évaluer le contenu avant décision (régulariser ou migrer) |

---

### B.3 — Synthèse des risques SaaS

| Niveau | Applications | Nombre |
|---|---|---|
| CRITIQUE | Salesforce, BambooHR, AS400 | 3 |
| ÉLEVÉ | SlackConnect, GitLab CE, Dropbox Biz | 3 |
| MODÉRÉ | Notion, Jira Cloud | 2 |
| FAIBLE | — | 0 |

**Risques transverses identifiés :**
- MFA absent ou partiel sur 7/8 applications
- Aucune application ne dispose d'un SSO configuré
- Shadow IT détecté (Dropbox Biz)
- Tokens d'API exposés en clair (GitLab CE) — action immédiate requise
- 2 applications avec comptes partagés (Salesforce Admin, AS400)

> Ces risques alimentent directement le script `Audit-SaaSRisk.py` (scoring automatisé)
> et la matrice de criticité `Template-CriticalityMatrix.csv`.

---

*Inventaire SaaS — `iam-ma-integration-lab` — IAM-Lab Framework*
