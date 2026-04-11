# 10 — Mapping réglementaire

> Wiki — `iam-ma-integration-lab`
> Synthèse — document complet : `REGULATORY-MAPPING.md` à la racine du repo

---

## Les trois référentiels couverts

Ce lab couvre trois cadres réglementaires applicables à un projet d'intégration
IAM en contexte M&A dans l'espace européen.

---

## ISO 27001:2022 — vue par phase

| Contrôle | Intitulé | Phases lab |
|---|---|---|
| A.5.3 | Séparation des tâches (SoD) | Phase 4 — Audit-RBACConflicts |
| A.5.15 | Contrôle d'accès | Toutes les phases |
| A.5.16 | Gestion des identités | Phase 0, 3, 4 |
| A.5.18 | Droits d'accès | Phase 0, 3, 4 |
| A.5.28 | Collecte de preuves | Phase 5 |
| A.5.33 | Protection des enregistrements | Phase 5 |
| A.6.3 | Sensibilisation et formation | OCM Phases 0, 3, 4 |
| A.8.2 | Accès privilégiés | Phase 1, 2 |
| A.8.5 | Authentification sécurisée | Phase 1 (SaaS MFA), 2 |
| A.8.8 | Gestion des vulnérabilités | Phase 0 (Shadow IT) |

---

## NIS2 — Article 21 §2

La directive NIS2 impose des mesures de gestion des risques cyber aux
entités essentielles et importantes. Quatre paragraphes sont directement
couverts par ce lab.

| §2 | Exigence résumée | Phases lab |
|---|---|---|
| (a) | Analyse des risques et sécurité des SI | Phase 0, 1, 2 |
| (e) | Sécurité dans l'acquisition et maintenance | Phase 1, 2, 4 |
| (f) | Évaluation de l'efficacité des mesures | Phase 5 |
| (g) | Cyberhygiène et formation | OCM Phases 0, 3, 4 |
| (i) | Gestion des accès | Phase 0, 1, 3, 4 |

**Pertinence M&A spécifique :** NIS2 impose une continuité des mesures
lors des changements organisationnels majeurs dont les fusions-acquisitions.
L'absorption d'une entité non conforme dans le périmètre d'une entité
conforme nécessite une évaluation documentée du risque d'entrée — c'est
l'objet de la Phase 1.

---

## RGPD / CNIL — points critiques M&A

### Base légale de la migration (Art. 6)

La migration des données personnelles des collaborateurs CorpB vers les
systèmes CorpA doit reposer sur une base légale. En contexte M&A, l'option
habituelle est l'intérêt légitime (Art. 6(1)(f)) ou l'exécution du contrat
de travail. Ce point est validé par le DPO en Phase 0 (Marc Deschamps dans
le scénario).

### Information des personnes concernées (Art. 13/14)

Les collaborateurs CorpB doivent être informés du changement de responsable
de traitement. Cette obligation est traitée dans `OCM-Phase0-Communication.md`
(communication J-10 aux collaborateurs).

### Sous-traitants SaaS (Art. 28)

Chaque application SaaS CorpB est un sous-traitant au sens de l'Art. 28.
L'absorption de CorpB transfère la responsabilité de ces relations de
sous-traitance vers CorpA. Points d'attention spécifiques :

| Application | Enjeu RGPD |
|---|---|
| BambooHR | Données RH sensibles — vérifier DPA et localisation |
| Dropbox Biz | Shadow IT — aucun DPA signé — violation Art. 28 potentielle |
| Salesforce | Données clients — vérifier clauses contractuelles types si stockage hors UE |
| GitLab CE | On-premises — inventorier les données personnelles dans les repos |

### Minimisation et limitation de conservation (Art. 5)

Les 49 comptes obsolètes CorpB actifs au moment de l'audit correspondent
exactement au principe de violation de l'Art. 5(1)(c) (minimisation) et
5(1)(e) (limitation de conservation). La Phase 2 les traite directement.

---

## Ce mapping est une démonstration méthodologique

> Ce document ne constitue pas un avis juridique ni une certification de conformité.
> Tout déploiement en contexte réel nécessite une validation par un conseil qualifié.

---

*Wiki page 10 — `iam-ma-integration-lab` — IAM-Lab Framework*
