# 📋 OCM-Phase5-ClosureReport.md — Rapport de clôture projet

> `iam-ma-integration-lab` / ocm
> Livrable OCM final — Clôture du projet d'intégration IAM M&A
> Destinataires : CODIR CorpA, DSI, RSSI, DPO
> Langue : Français

---

## Section A — Template générique

### A.1 — Objectif du rapport de clôture

Le rapport de clôture remplit trois fonctions :

1. **Bilan** : ce qui a été fait, ce qui fonctionne, ce qui reste ouvert
2. **Traçabilité** : preuves que le projet a respecté les engagements (qualité, délais, conformité)
3. **Mémoire** : leçons apprises pour les prochains projets similaires

> Ce document est destiné à la direction — pas à des techniciens.
> Il doit tenir sur 2-3 pages maximum.

### A.2 — Structure du rapport

```
1. Résumé exécutif (10 lignes max)
2. Objectifs vs réalisé (tableau)
3. Métriques clés du projet
4. Points résolus / Points ouverts
5. Conformité réglementaire — synthèse
6. Leçons apprises
7. Recommandations pour la suite
8. Validation et signatures
```

### A.3 — Template résumé exécutif

```
Le projet d'intégration IAM [Entreprise cible] dans [Entreprise absorbante]
est terminé. [X] collaborateurs ont été migrés vers l'environnement
[Entreprise absorbante] en [X] semaines.

Points forts :
→ Migration réalisée sans interruption de service
→ [X] comptes à risque détectés et traités avant migration
→ Conformité ISO 27001 / NIS2 / RGPD maintenue tout au long du projet

Points d'attention restants :
→ [X] éléments en cours de traitement (listés en Section 4)

Prochaine étape : gouvernance continue — revue trimestrielle des accès.
```

---

## Section B — Exemple CorpA/CorpB

### B.1 — Résumé exécutif

**Projet** : Intégration IAM CorpB dans CorpA
**Période** : [date début] → [date fin]
**Chef de projet** : Sophie Arnaud, DSI CorpA
**Référent sécurité** : Karim Benali, RSSI CorpA

---

Le projet d'intégration des identités informatiques de CorpB dans l'environnement CorpA est terminé. **263 collaborateurs** ont été migrés vers le tenant Entra ID CorpA en 16 semaines, sans interruption de service le jour de la bascule.

L'audit initial a révélé **49 comptes obsolètes** et **5 comptes privilégiés** non documentés dans l'AD CorpB — tous traités avant migration. Le portefeuille SaaS de CorpB (8 applications, 625 comptes applicatifs) a été cartographié et les actions de gouvernance engagées.

Le projet a respecté ses trois engagements fondamentaux : **aucune action sans validation humaine**, **traçabilité complète** de chaque décision, **continuité de service** pour les collaborateurs.

Trois points restent en cours de traitement : le plan de migration de l'AS400, la fermeture de Dropbox Biz Shadow IT, et la transition de l'instance GitLab CE on-premises.

---

### B.2 — Objectifs vs réalisé

| Objectif | Cible | Réalisé | Statut |
|---|---|---|---|
| Migration comptes AD CorpB | 263 comptes | 263 comptes | ✅ |
| Comptes obsolètes traités avant migration | 100% | 100% (49/49) | ✅ |
| Comptes privilégiés documentés | 100% | 100% (5/5) | ✅ |
| MFA activé sur comptes migrés | 100% | > 92% (J+7) | ✅ |
| Aucune interruption de service J-Day | < 5% tickets | 3,2% tickets | ✅ |
| Cartographie SaaS complète | 8 apps | 8 apps | ✅ |
| Shadow IT identifié et traité | 100% | En cours (Dropbox) | 🔶 |
| AS400 — plan de migration | Plan validé | En cours de définition | 🔶 |
| GitLab CE → GitLab CorpA | Migration terminée | Planifiée Q2 | 🔶 |
| Conformité ISO 27001 maintenue | Oui | Oui — preuves scellées | ✅ |

---

### B.3 — Métriques clés du projet

**Volume traité**

| Indicateur | Valeur |
|---|---|
| Comptes AD migrés | 263 |
| Comptes AD traités (désactivés/archivés) | 49 |
| Comptes de service inventoriés | 12 |
| Comptes privilégiés audités | 5 |
| Groupes de sécurité audités | 18 |
| Groupes orphelins traités | 4 |
| Applications SaaS cartographiées | 8 |
| Comptes SaaS inventoriés | 625 |
| Comptes SaaS à désactiver | 67 |
| Tokens d'API révoqués | 3 |

**Qualité opérationnelle**

| Indicateur | Valeur |
|---|---|
| Tickets support J-Day (8h-18h) | 9 (3,4% des utilisateurs) |
| MFA activé J+7 | 92,4% |
| Comptes non connectés J+14 | 4 (en cours de vérification) |
| Incidents de sécurité liés à la migration | 0 |
| Actions effectuées sans validation CSV | 0 |
| Rollbacks nécessaires | 0 |

**Conformité**

| Indicateur | Valeur |
|---|---|
| Rapports produits | 15 CSV + 3 rapports texte |
| Rapports scellés (SHA-256) | 15/15 |
| CSV de validation retournés par managers | 5/5 (100%) |
| Base légale RGPD validée par DPO | Oui |

---

### B.4 — Points ouverts

| Point | Responsable | Délai | Impact si non traité |
|---|---|---|---|
| AS400 — plan de migration ERP | Direction Finance + IT CorpA | Q3 | Mainteneur risque opérationnel et sécuritaire |
| Dropbox Biz — fermeture Shadow IT | Paulo Esteves + IT | Dans 30 jours | Données sans gouvernance, RGPD Art. 28 non conforme |
| GitLab CE on-prem → GitLab CorpA | Bastien Couture + IT | Q2 | Instance legacy sans support, surface d'attaque |
| 4 comptes non connectés J+14 | Inès Moulin | J+7 | Potentiels orphelins — à désactiver si non justifiés |
| Revue comptes invités pré-fusion | Managers CorpA concernés | J+14 | 3 comptes avec accès données sensibles |

---

### B.5 — Synthèse conformité réglementaire

| Référentiel | Contrôles couverts | Preuves disponibles | Statut |
|---|---|---|---|
| **ISO 27001:2022** | A.5.15, A.5.16, A.5.18, A.8.2, A.5.3, A.5.28 | 15 rapports scellés | ✅ Conforme |
| **NIS2** | Art. 21 §2(a)(e)(f)(g)(i) | Rapports + logs exécution | ✅ Aligné |
| **RGPD / CNIL** | Art. 5, 13, 25, 28, 30 | DPA vérifiés, base légale validée DPO | ✅ Conforme sauf Dropbox |

> L'intégralité des preuves techniques est archivée et scellée dans `/reports/evidence/`.
> Manifest JSON signé disponible sur demande.

---

### B.6 — Leçons apprises

**Ce qui a bien fonctionné**

La Phase 0 (préparation) a été le différenciateur le plus important. Avoir cartographié les parties prenantes et le périmètre SaaS avant de démarrer l'audit a permis d'identifier des risques (tokens GitLab, compte Salesforce partagé) qui auraient été découverts trop tard dans un projet classique.

Le principe des **livrables duaux** (technique + humain à chaque phase) a réduit les résistances. Bastien Couture, identifié comme profil potentiellement résistant en Phase 0, a finalement joué un rôle actif dans la validation des comptes Technique.

Le **mode DryRun systématique** avant toute exécution a évité deux erreurs potentielles détectées à la relecture des simulations.

**Ce qui aurait pu être mieux**

La collecte des CSV de validation en Phase 2 a pris 3 jours de plus que prévu. Le délai d'une semaine était trop court pour des managers qui n'avaient pas anticipé le temps nécessaire. Prévoir 10 jours la prochaine fois.

L'AS400 aurait dû faire l'objet d'un plan de migration dès la Phase 0. Il a été identifié comme risque mais sans plan d'action concret — ce qui génère un point ouvert en clôture.

**Ce qu'on ferait différemment**

Intégrer un **référent SaaS dédié** dans l'équipe projet dès Phase 0 pour les projets avec plus de 5 applications SaaS. La gouvernance SaaS post-fusion a nécessité autant de travail que l'audit AD.

---

### B.7 — Recommandations pour la suite

**Gouvernance continue (immédiat)**
- Activer la revue trimestrielle des accès via [`iam-governance-lab`](https://github.com/CrepuSkull/iam-governance-lab)
- Dissoudre les groupes `GRP_CorpB_*_Migrated` dans 3 mois après validation managers
- Intégrer les ex-collaborateurs CorpB dans le cycle JML standard CorpA

**Court terme (< 3 mois)**
- Fermer Dropbox Biz — migrer les contenus vers SharePoint CorpA
- Résoudre les 4 comptes non connectés J+14
- Finaliser le plan de migration AS400

**Moyen terme (< 6 mois)**
- Migrer l'instance GitLab CE on-premises vers GitLab CorpA
- Revoir les DPA de toutes les applications SaaS CorpB sous la bannière CorpA
- Proposer à Julien Faure un rôle d'IT Local Coordinator CorpA Normandie

---

### B.8 — Validation et signatures

| Rôle | Nom | Validation | Date |
|---|---|---|---|
| DSI CorpA | Sophie Arnaud | [ ] Lu et approuvé | |
| RSSI CorpA | Karim Benali | [ ] Lu et approuvé | |
| DPO CorpA | Marc Deschamps | [ ] Lu et approuvé | |
| DG CorpA | [À COMPLÉTER] | [ ] Lu et approuvé | |

---

*Ce rapport de clôture et l'ensemble des rapports techniques sont archivés
et scellés dans `/reports/evidence/`. Manifest SHA-256 disponible sur demande.*

---

*OCM Phase 5 — Rapport de clôture — `iam-ma-integration-lab` — IAM-Lab Framework*
