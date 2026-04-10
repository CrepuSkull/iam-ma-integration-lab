# 🔄 OCM-Framework.md — Cadre d'accompagnement au changement

> `iam-ma-integration-lab` / ocm
> Livrable transverse — applicable à toutes les phases
> Langue : Français | Cible : chef de projet M&A, RSSI, DRH

---

## Section A — Template générique

### A.1 — Pourquoi l'OCM n'est pas une phase

L'accompagnement au changement (OCM — Organizational Change Management) est souvent pensé comme une étape terminale : on déploie la technique, puis on "communique". Cette approche arrive systématiquement trop tard.

Dans un projet d'intégration IAM post-fusion, les résistances se construisent dès l'annonce du projet. Les rumeurs circulent avant les réunions officielles. Les collaborateurs de l'entreprise absorbée vivent l'intégration de leurs comptes informatiques comme un signal fort sur leur futur statut dans la nouvelle entité.

**L'OCM dans ce lab est un fil conducteur, pas une phase.** Il précède, accompagne et prolonge chaque action technique.

### A.2 — Les trois dimensions de l'OCM en contexte IAM M&A

| Dimension | Question centrale | Outils lab |
|---|---|---|
| **Information** | Qui sait quoi, quand ? | Plans de communication par phase |
| **Compréhension** | Pourquoi ça change, quel impact concret ? | Guides utilisateurs, restitutions métier |
| **Autonomisation** | Comment s'approprier le nouvel environnement ? | Documents de passation, supports de formation |

### A.3 — Principe des livrables duaux

Chaque phase technique produit un livrable OCM associé. Les deux sont **livrés en parallèle**, pas en séquence.

| Phase | Livrable technique | Livrable OCM | Timing OCM |
|---|---|---|---|
| Phase 0 | Inventaire SaaS + matrice parties prenantes | Plan de communication initial | Avant Phase 1 |
| Phase 1 | Rapport d'audit AD + SaaS | Restitution aux référents métier | Dans les 48h après audit |
| Phase 2 | CSV de remédiation | Notice d'information managers concernés | Avant exécution remédiation |
| Phase 3 | Rapport de migration | Guide utilisateur J-Day | J-3 avant bascule |
| Phase 4 | Rapport de gouvernance | Document de passation managers | Semaine suivant la migration |
| Phase 5 | Rapports scellés | Rapport de clôture CODIR | Fin de projet |

### A.4 — Gestion des résistances

Les résistances en contexte M&A IAM sont prévisibles. Les anticiper est plus efficace que les traiter en réaction.

| Profil résistant | Crainte typique | Réponse OCM recommandée |
|---|---|---|
| Admin IT entreprise cible | Perte de rôle post-migration | Associer à la Phase 4, proposer montée en compétence Entra ID |
| Manager métier | Perte d'accès, rupture d'outil | Matrice de criticité en Phase 0, garantie de continuité |
| Collaborateur lambda | "On va surveiller mes accès" | Guide J-Day simple, message de normalisation |
| Responsable applicatif SaaS | Perte de contrôle sur "son" outil | L'associer à la validation Phase 2, pas le contourner |
| DRH | Données RH exposées | Briefing RGPD spécifique, impliquer le DPO en Phase 0 |

### A.5 — Règles d'or OCM pour un projet IAM M&A

1. **Ne jamais annoncer une action sans en expliquer la raison** — "votre compte va être désactivé" sans contexte génère de la panique. "Nous allons désactiver les comptes inactifs depuis plus de 90 jours pour sécuriser votre environnement" est audible.

2. **Associer les référents métier à la validation** — le CSV de remédiation validé en Phase 2 n'est pas qu'un mécanisme de sécurité technique. C'est aussi un outil d'OCM : le manager qui signe `OUI` en face d'un compte à désactiver est acteur de la décision, pas sujet.

3. **Distinguer l'information de la consultation** — informer est obligatoire. Consulter est un choix stratégique. Dans ce lab, les référents métier sont consultés sur les listes de remédiation (Phase 2) et les accès critiques (Phase 0). Ils ne sont pas consultés sur les choix d'architecture.

4. **Communiquer les résultats, pas seulement les actions** — après chaque phase, produire un livrable de restitution lisible par un non-technicien. Le rapport d'audit n'est pas ce livrable. La restitution OCM l'est.

5. **Documenter les refus** — si un référent refuse de valider un compte à désactiver, documenter le refus et escalader. Ne jamais contourner la validation humaine, même sous pression de calendrier.

---

## Section B — Exemple CorpA/CorpB

### B.1 — Contexte du projet

**Projet** : Intégration IAM — CorpA absorbe CorpB
**Chef de projet OCM** : Sophie Arnaud (DSI CorpA) avec appui DRH
**Durée estimée du projet** : 16 semaines (Phase 0 à Phase 5)
**Nombre de collaborateurs impactés** : 312 (CorpB) + équipes IT CorpA

---

### B.2 — Calendrier OCM global

```
SEMAINE     ACTION TECHNIQUE              LIVRABLE OCM
────────────────────────────────────────────────────────────────────
S1-S2       Phase 0 — Préparation         Communication initiale DG-to-DG
                                          Annonce projet aux managers CorpB
S3-S4       Phase 1 — Audit AD + SaaS     Restitution audit aux référents CorpB
                                          Briefing RSSI CorpA
S5-S6       Phase 2 — Remédiation         Notice validation aux managers concernés
                                          Confirmation post-remédiation
S7-S10      Phase 3 — Migration           Guide utilisateur J-Day (J-3)
                                          Communication J-Day (J-0)
                                          Message post-migration J+1
S11-S13     Phase 4 — Gouvernance         Document de passation managers CorpA
                                          Session questions/réponses IT CorpB
S14-S16     Phase 5 — Clôture             Rapport de clôture CODIR
                                          Bilan retour d'expérience équipes
```

---

### B.3 — Cartographie des messages clés

| Moment | Message central | Émetteur | Destinataires |
|---|---|---|---|
| Lancement (S1) | "L'intégration de vos systèmes informatiques est planifiée et accompagnée" | DG CorpA | Tous collaborateurs CorpB |
| Avant audit (S3) | "Un état des lieux de vos outils sera réalisé — aucune modification à ce stade" | DSI CorpA | Managers + IT CorpB |
| Avant remédiation (S5) | "Certains comptes inactifs vont être désactivés — voici la liste pour validation" | Inès Moulin | Managers CorpB concernés |
| J-Day (S7) | "Voici comment vous connecter avec vos nouveaux identifiants et activer votre MFA" | IT CorpA | Tous collaborateurs CorpB |
| Post-migration (S11) | "L'intégration est terminée — voici vos nouveaux référents IT et les ressources disponibles" | Sophie Arnaud | Tous collaborateurs CorpB |
| Clôture (S15) | "Bilan du projet, métriques, points d'amélioration" | Sophie Arnaud | CODIR CorpA |

---

### B.4 — Indicateurs de succès OCM

| Indicateur | Cible | Méthode de mesure |
|---|---|---|
| Taux de validation CSV Phase 2 | 100% des managers sollicités répondent | Suivi des CSV retournés |
| Taux d'activation MFA J+5 | > 90% des comptes CorpB migrés | Rapport Entra ID |
| Nombre de tickets "accès bloqué" J-Day | < 5% des utilisateurs CorpB | ITSM CorpA |
| Satisfaction collaborateurs CorpB (enquête J+30) | > 3,5/5 sur la qualité de l'accompagnement | Questionnaire anonyme |
| Escalades non résolues Phase 2 | 0 | Suivi chef de projet |

---

*OCM-Framework — `iam-ma-integration-lab` — IAM-Lab Framework*
