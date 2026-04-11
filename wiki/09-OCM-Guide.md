# 09 — OCM : Accompagnement au changement

> Wiki — `iam-ma-integration-lab`

---

## OCM n'est pas une phase

L'accompagnement au changement (OCM — Organizational Change Management)
n'intervient pas après les phases techniques. Il les précède, les accompagne
et les prolonge. Le traiter comme une étape terminale, c'est arriver trop tard.

Dans ce lab, l'OCM est un **fil conducteur transverse** représenté par
sept livrables dans le dossier `/ocm/`.

---

## Les sept livrables OCM

| Fichier | Phase | Destinataires |
|---|---|---|
| `OCM-Framework.md` | Transverse | Chef de projet M&A |
| `OCM-Phase0-Communication.md` | Phase 0 | DRH + managers CorpB |
| `OCM-Phase1-StakeholderBriefing.md` | Phase 1 | RSSI CorpA + référents CorpB |
| `OCM-Phase2-RemediationNotice.md` | Phase 2 | Managers CorpB concernés |
| `OCM-Phase3-MigrationGuide.md` | Phase 3 | Tous collaborateurs CorpB |
| `OCM-Phase4-GovernanceHandover.md` | Phase 4 | Managers CorpA |
| `OCM-Phase5-ClosureReport.md` | Phase 5 | CODIR CorpA |

Chaque fichier contient deux sections : un template générique avec
placeholders `[À COMPLÉTER]` (Section A) et un exemple entièrement rédigé
dans le contexte CorpA/CorpB (Section B).

---

## Le principe des livrables duaux

Chaque phase technique produit deux types de sortie :

```
Phase X
  ├── Livrable technique   → Script, CSV, rapport d'audit
  └── Livrable OCM         → Communication, briefing, guide utilisateur
```

Les deux livrables sont produits **en parallèle**, pas en séquence.
Un rapport d'audit envoyé sans livrable OCM associé génère de l'anxiété.
Un livrable OCM sans rapport technique associé manque de substance.

---

## Gérer les résistances par profil

Le lab documente cinq profils de résistance fréquents en contexte M&A IAM :

**L'admin IT de l'entreprise absorbée** (Julien Faure dans le scénario)
perd son rôle d'administrateur AD avec la migration. Réponse : l'associer
à la Phase 4, lui proposer la montée en compétence Entra ID.

**Le responsable applicatif SaaS** (Nadège Perrin pour Salesforce) a créé
des usages qui dévient des bonnes pratiques (compte Admin partagé). Réponse :
aborder en tête-à-tête, proposer la solution en même temps que le constat.

**Le développeur attaché à son autonomie** (Bastien Couture pour GitLab)
perçoit l'audit comme une intrusion dans son espace de travail. Réponse :
montrer le DryRun en direct, expliquer que l'objectif est la protection
de ses dépôts, pas le contrôle de son activité.

**Le manager non-technique** ne comprend pas ce qu'on lui demande de valider.
Réponse : `README-validation.md` écrit en langage non-technicien, appel de
30 minutes proposé systématiquement.

**La DRH sensible aux données personnelles** (Amandine Leconte pour BambooHR).
Réponse : impliquer le DPO dès Phase 0, expliquer la base légale RGPD
avant de parler des actions techniques.

---

## Le calendrier OCM sur 16 semaines

```
S1-S2    Phase 0     Communication DG-to-DG + briefing managers
S3-S4    Phase 1     Restitution audit aux référents CorpB (48h après)
S5-S6    Phase 2     Notices validation avant exécution + confirmation après
S7       J-Day       Guide utilisateur envoyé J-3 + communication J-Day
S7       J+1         Confirmation post-bascule
S8-S10   Phase 4     Passation gouvernance aux managers CorpA
S14-S16  Clôture     Rapport CODIR
```

---

## Ce que l'OCM mesure

Cinq indicateurs permettent d'évaluer la qualité de l'accompagnement :

| Indicateur | Cible |
|---|---|
| Taux de retour des CSV de validation | 100% des managers sollicités |
| Taux d'activation MFA J+5 | > 90% |
| Tickets support J-Day | < 5% des utilisateurs |
| Satisfaction collaborateurs CorpB J+30 | > 3,5/5 |
| Escalades Phase 2 non résolues | 0 |

---

*Wiki page 09 — `iam-ma-integration-lab` — IAM-Lab Framework*
