# 📋 Phase 0 — Préparation

> `iam-ma-integration-lab` / phase0-preparation
> Langue : Français | Cible : consultant IAM, chef de projet M&A, RSSI

---

## Pourquoi cette phase existe

La majorité des projets d'intégration IAM en contexte M&A échouent ou accumulent les retards pour une raison simple : **ils démarrent trop tôt**.

Ouvrir PowerShell avant d'avoir cartographié les parties prenantes, avant de savoir quelles applications SaaS existent, avant d'établir qui valide quoi — c'est auditer dans le vide. Les rapports produits seront incomplets, les remédiations partielles, et les équipes CorpB percevront l'opération comme une contrainte imposée plutôt qu'une démarche accompagnée.

La Phase 0 répond à une seule question : **est-ce qu'on sait dans quoi on met les pieds ?**

Elle ne produit aucun script. Elle produit de la **connaissance structurée** qui conditionne la qualité de toutes les phases suivantes.

---

## Objectifs

1. Identifier les parties prenantes CorpB (référents métier, BA, chefs de service, DSI)
2. Cartographier le périmètre SaaS réel de CorpB (y compris Shadow IT)
3. Établir la matrice de criticité des accès par fonction métier
4. Produire le plan de communication initial (→ OCM)

---

## Livrables

| Livrable | Fichier | Nature |
|---|---|---|
| Matrice des parties prenantes | `Collect-StakeholderMatrix.md` | Template + exemple CorpA/CorpB |
| Inventaire SaaS | `Collect-SaaSInventory.md` | Template + catalogue fictif CorpB |
| Analyse des risques SaaS | `Audit-SaaSRisk.py` | Script Python — scoring automatisé |
| Matrice de criticité | `Template-CriticalityMatrix.csv` | Template CSV à compléter |
| Plan de communication | `../ocm/OCM-Phase0-Communication.md` | Livrable OCM associé |

---

## Prérequis

- Accès à une liste des applications utilisées par CorpB (DSI CorpB, ou analyse DNS/proxy)
- Contact établi avec au moins un référent IT CorpB
- Validation de la direction que le projet M&A IAM est officiellement lancé
- Python 3.10+ pour exécuter `Audit-SaaSRisk.py`

> Aucun accès AD ni Entra ID requis à ce stade.

---

## Déroulé opérationnel

### Étape 1 — Identification des parties prenantes (J-14 avant audit)

Utiliser `Collect-StakeholderMatrix.md` pour cartographier :
- Les **référents métier** par département CorpB (Commercial, Technique, RH, Direction, Prestataires)
- Les **décideurs** côté CorpA (RSSI, DSI, DRH, Directeur M&A)
- Les **validateurs techniques** (admin AD CorpB, responsable IT CorpB)

> Ces personnes seront impliquées à trois moments clés :
> - Phase 0 : fourniture d'informations (inventaire SaaS, accès critiques)
> - Phase 2 : validation des CSV de remédiation
> - Phase 4 : réception des documents de passation

### Étape 2 — Collecte de l'inventaire SaaS (J-10 avant audit)

Utiliser `Collect-SaaSInventory.md` pour documenter chaque application :
- Nom, catégorie, fournisseur
- Propriétaire fonctionnel chez CorpB
- Nombre estimé de comptes
- Présence ou absence de SSO / MFA
- Statut Shadow IT (déclaré DSI / non déclaré)

**Méthodes de collecte recommandées :**

| Méthode | Avantage | Limite |
|---|---|---|
| Entretien DSI CorpB | Fiable sur les apps officielles | Blind spot sur Shadow IT |
| Analyse logs proxy/DNS | Détecte le Shadow IT | Nécessite accès infrastructure |
| Questionnaire auto-déclaratif (managers) | Rapide, couverture large | Peut sous-estimer |
| Export facturation IT | Exhaustif sur apps payantes | Ne couvre pas les freemium |

> En lab : le catalogue fictif CorpB est pré-rempli dans `Collect-SaaSInventory.md`.

### Étape 3 — Scoring des risques SaaS (J-7 avant audit)

Exécuter `Audit-SaaSRisk.py` sur le fichier d'inventaire produit à l'étape 2.

```bash
python Audit-SaaSRisk.py --input corpb-saas-inventory.csv --output saas-risk-report.csv
```

Le script calcule un **score de risque composite** par application selon 5 critères :
- Absence de MFA
- Comptes partagés détectés
- Statut Shadow IT
- Données sensibles hébergées (RH, clients, code source)
- Absence de DPA / contrat sous-traitant signé

### Étape 4 — Matrice de criticité (J-5 avant audit)

Croiser les résultats SaaS avec les fonctions métier via `Template-CriticalityMatrix.csv`.

Niveaux de criticité retenus :
- **CRITIQUE** : accès interrompus = arrêt d'activité (ex : AS400 ERP, Salesforce pour les commerciaux)
- **ÉLEVÉ** : accès interrompus = perte de productivité significative (ex : Jira, Notion)
- **MODÉRÉ** : impact limité, solutions de contournement disponibles
- **FAIBLE** : usage marginal, impact négligeable

### Étape 5 — Validation et passation à la Phase 1

La Phase 0 est considérée terminée lorsque :

- [ ] Matrice des parties prenantes complétée et validée par le chef de projet
- [ ] Inventaire SaaS couvrant 100% des applications connues
- [ ] Rapport de risques SaaS produit et relu par le RSSI CorpA
- [ ] Matrice de criticité validée par au moins un référent métier CorpB
- [ ] Plan de communication OCM validé et calendrier de diffusion établi

---

## Mapping réglementaire

| Action | ISO 27001:2022 | NIS2 | RGPD |
|---|---|---|---|
| Inventaire SaaS (Shadow IT) | A.5.15, A.8.8 | Art. 21 §2(a) | Art. 30, Art. 5(1)(c) |
| Matrice parties prenantes | A.5.15, A.5.16 | Art. 21 §2(i) | Art. 30 |
| Matrice de criticité | A.5.15, A.5.18 | Art. 21 §2(i) | Art. 25 |
| Plan de communication | A.6.3 | Art. 21 §2(g) | Art. 13/14 |

---

## Livrable OCM associé

> [`../ocm/OCM-Phase0-Communication.md`](../ocm/OCM-Phase0-Communication.md)
>
> Plan de communication pré-migration — destinataires : DRH et managers CorpB.
> Produit en parallèle de cette phase. À valider avant tout démarrage de la Phase 1.

---

## Phase suivante

➜ [`../phase1-audit/README-phase1.md`](../phase1-audit/README-phase1.md)

---

*Phase 0 — Préparation — `iam-ma-integration-lab` — IAM-Lab Framework*
