# ⚖️ REGULATORY-MAPPING.md — Matrice de couverture réglementaire

> Lab : `iam-ma-integration-lab` — IAM-Lab Framework
> Référentiels : **ISO 27001:2022**, **NIS2 (Directive UE 2022/2555)**, **RGPD / CNIL**
> Périmètre : intégration des identités CorpB (AD + SaaS) dans le tenant Entra ID CorpA

---

## 1. Principe de lecture

Ce document établit la correspondance entre chaque **phase du lab** et les **exigences réglementaires** applicables. Il couvre le périmètre étendu au SaaS et à l'accompagnement au changement.

> Ce mapping est produit dans une logique de **démonstration méthodologique**.
> Il ne constitue pas un avis juridique ni une certification de conformité.

---

## 2. Matrice synthétique — AD + SaaS + OCM

| Phase | Action IAM | ISO 27001:2022 | NIS2 | RGPD/CNIL |
|---|---|---|---|---|
| **Phase 0** | Cartographie parties prenantes | A.5.15, A.5.16 | Art. 21 §2(i) | Art. 30 |
| **Phase 0** | Inventaire SaaS (Shadow IT inclus) | A.5.15, A.8.8 | Art. 21 §2(a) | Art. 30, Art. 5(1)(c) |
| **Phase 0** | Matrice de criticité accès/fonction | A.5.15, A.5.18 | Art. 21 §2(i) | Art. 25 |
| **Phase 0 OCM** | Plan de communication pré-migration | A.6.3 | Art. 21 §2(g) | Art. 13/14 |
| **Phase 1** | Inventaire comptes AD | A.5.15, A.8.5 | Art. 21 §2(i) | Art. 30 |
| **Phase 1** | Détection comptes obsolètes AD | A.8.5 | Art. 21 §2(e) | Art. 5(1)(e) |
| **Phase 1** | Audit comptes privilégiés | A.8.2 | Art. 21 §2(a) | — |
| **Phase 1** | Audit SaaS — comptes orphelins | A.5.15, A.5.18 | Art. 21 §2(e) | Art. 5(1)(c)(e) |
| **Phase 1** | Audit SaaS — MFA absent | A.8.5, A.8.6 | Art. 21 §2(a) | — |
| **Phase 1** | Audit SaaS — partage de credentials | A.8.2, A.5.3 | Art. 21 §2(a) | — |
| **Phase 2** | Désactivation comptes obsolètes | A.5.15, A.8.5 | Art. 21 §2(e) | Art. 5(1)(c)(e) |
| **Phase 2** | Revue comptes privilégiés | A.8.2 | Art. 21 §2(a) | — |
| **Phase 2** | Nettoyage groupes orphelins | A.5.15 | Art. 21 §2(i) | — |
| **Phase 3** | Checklist pré-migration | A.5.15, A.5.16 | Art. 21 §2(i) | Art. 25 |
| **Phase 3** | Provisioning Entra ID | A.5.16, A.5.18 | Art. 21 §2(i) | Art. 25, Art. 28 |
| **Phase 3** | Vérification Conditional Access | A.8.6 | Art. 21 §2(a) | — |
| **Phase 3 OCM** | Guide utilisateur J-Day | A.6.3 | Art. 21 §2(g) | Art. 13 |
| **Phase 4** | Détection orphelins post-fusion (AD) | A.5.15 | Art. 21 §2(e) | Art. 5(1)(c)(e) |
| **Phase 4** | Audit conflits RBAC / SoD | A.5.3, A.5.15 | Art. 21 §2(a) | — |
| **Phase 4** | Gouvernance comptes SaaS post-fusion | A.5.15, A.5.18 | Art. 21 §2(i) | Art. 28, Art. 5(1)(c) |
| **Phase 4** | Enforcement SSO sur SaaS critiques | A.8.5, A.8.6 | Art. 21 §2(a) | — |
| **Phase 5** | Scellage SHA-256 rapports | A.5.28, A.5.33 | Art. 21 §2(f) | Art. 5(2) |
| **Phase 5** | Horodatage RFC 3161 | A.5.28 | Art. 21 §2(f) | Art. 5(2) |

---

## 3. Détail ISO 27001:2022

| Contrôle | Intitulé | Phase(s) lab |
|---|---|---|
| **A.5.3** | Séparation des tâches | Phase 1 (SaaS) — Phase 4 (RBAC) |
| **A.5.15** | Contrôle d'accès | Toutes les phases |
| **A.5.16** | Gestion des identités | Phases 0, 3, 4 |
| **A.5.18** | Droits d'accès | Phases 0, 3, 4 |
| **A.5.28** | Collecte de preuves | Phase 5 |
| **A.5.33** | Protection des enregistrements | Phase 5 |
| **A.6.3** | Sensibilisation et formation | OCM Phases 0, 3, 4 |
| **A.8.2** | Accès privilégiés | Phases 1, 2 |
| **A.8.5** | Authentification sécurisée | Phases 1 (SaaS MFA), 2 |
| **A.8.6** | Gestion des capacités d'accès | Phases 1, 3, 4 |
| **A.8.8** | Gestion des vulnérabilités techniques | Phase 0 — Shadow IT |

### Focus : SaaS et Shadow IT (A.5.15, A.8.8)

Le Shadow IT constitue un angle mort fréquent dans les audits IAM M&A. Une application non déclarée à la DSI (ex : Dropbox Biz dans CorpB) :

- échappe aux politiques de contrôle d'accès (A.5.15)
- peut héberger des données sensibles sans classification ni protection
- est invisible des outils de surveillance (A.8.8)

La Phase 0 du lab traite explicitement ce point via l'inventaire SaaS Shadow IT.

---

## 4. Détail NIS2 (Directive UE 2022/2555)

### Article 21 — Mesures de gestion des risques

| Paragraphe | Exigence | Phase(s) lab |
|---|---|---|
| **§2(a)** | Politiques d'analyse des risques et de sécurité des SI | Phases 0, 1, 2 |
| **§2(e)** | Sécurité dans l'acquisition et maintenance des systèmes | Phases 1, 2, 4 |
| **§2(f)** | Évaluation de l'efficacité des mesures | Phase 5 |
| **§2(g)** | Pratiques de cyberhygiène et formation | OCM Phases 0, 3, 4 |
| **§2(i)** | Politiques de gestion des accès | Phases 0, 1, 3, 4 |

### Pertinence M&A et SaaS

NIS2 impose une gestion des risques étendue à **l'ensemble de la chaîne d'approvisionnement numérique**, incluant les applications SaaS. L'absorption d'une entité avec un portefeuille SaaS non gouverné introduit des risques tiers directs dans le périmètre NIS2 de l'entité absorbante.

La Phase 0 (inventaire SaaS) et la Phase 4 (gouvernance post-fusion des comptes SaaS) répondent directement à cette exigence.

---

## 5. Détail RGPD / CNIL

### Articles couverts

| Article | Exigence | Phase(s) lab |
|---|---|---|
| **Art. 5(1)(c)** | Minimisation des données | Phases 0, 1, 2, 4 |
| **Art. 5(1)(e)** | Limitation de la conservation | Phases 1, 2, 4 |
| **Art. 5(2)** | Responsabilité (accountability) | Phase 5 |
| **Art. 13/14** | Information des personnes concernées | OCM Phase 0 |
| **Art. 25** | Protection dès la conception | Phases 0, 3 |
| **Art. 28** | Sous-traitants | Phases 3, 4 (SaaS) |
| **Art. 30** | Registre des traitements | Phases 0, 1 |

### Extension SaaS — sous-traitants (Art. 28)

Chaque application SaaS utilisée par CorpB constitue un **sous-traitant au sens de l'Art. 28 RGPD**. L'absorption de CorpB par CorpA transfère la responsabilité de ces relations de sous-traitance.

Points d'attention spécifiques par application :

| Application | Enjeu RGPD | Action requise |
|---|---|---|
| **BambooHR** | Données RH sensibles (catégorie particulière potentielle) | Vérifier DPA, localisation hébergement, durée conservation |
| **Salesforce** | Données clients — potentielle base UE | Vérifier clauses contractuelles types si stockage hors UE |
| **GitLab CE** | On-premises — sous contrôle direct | Inventorier les données personnelles stockées dans les repos |
| **Dropbox Biz** | Shadow IT — aucun DPA signé | Régulariser ou migrer avant Phase 3 |
| **SlackConnect** | Données de communication | Vérifier politique de rétention des messages |

### Points d'attention spécifiques M&A

**Licéité du traitement post-acquisition**
La migration des données personnelles de CorpB vers les systèmes CorpA doit reposer sur une base légale. En contexte M&A, la base retenue est généralement l'**intérêt légitime** (Art. 6(1)(f)) ou l'**exécution du contrat de travail**. Ce point doit être validé par le DPO avant la Phase 3.

**Information des personnes concernées (Art. 13/14)**
Les collaborateurs de CorpB doivent être informés du changement de responsable de traitement. Cette obligation est traitée dans le livrable **OCM-Phase0-Communication.md** du dossier `/ocm/`.

**Transfert hors UE**
Si le tenant Entra ID CorpA ou les SaaS hébergent des données hors UE, les garanties appropriées (clauses contractuelles types) doivent être documentées avant la Phase 3.

---

## 6. Références normatives

| Document | Source |
|---|---|
| ISO/IEC 27001:2022 | [iso.org](https://www.iso.org/standard/82875.html) |
| Directive NIS2 (UE 2022/2555) | [eur-lex.europa.eu](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32022L2555) |
| RGPD (UE 2016/679) | [eur-lex.europa.eu](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679) |
| Guide ANSSI — Maîtrise des accès SI | [ssi.gouv.fr](https://www.ssi.gouv.fr) |
| CNIL — Gestion des habilitations | [cnil.fr](https://www.cnil.fr) |
| CNIL — Sous-traitance et RGPD | [cnil.fr/sous-traitants](https://www.cnil.fr/fr/les-sous-traitants) |

---

*Document de référence réglementaire — `iam-ma-integration-lab` — IAM-Lab Framework*
