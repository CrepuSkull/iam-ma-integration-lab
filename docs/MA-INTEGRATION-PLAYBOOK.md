# Playbook M&A IAM — Déroulé intégral de la démarche

> `iam-ma-integration-lab` / docs
> De l'étude préliminaire à la finalisation
> Langue : Français | Cible : chef de projet M&A, DSI, RSSI, consultant IAM

---

## Introduction

Ce playbook retrace le déroulé complet d'un projet d'intégration IAM
en contexte M&A. Il couvre la période allant de la **due diligence**
(avant même que l'acquisition soit finalisée) jusqu'à la **clôture**
et au retour d'expérience.

Il est structuré en **5 grandes étapes** qui encadrent les 6 phases
techniques du lab. Certaines étapes sont antérieures au lab et
d'autres le prolongent.

```
ÉTAPE 1          ÉTAPE 2          ÉTAPE 3          ÉTAPE 4          ÉTAPE 5
─────────────    ─────────────    ─────────────    ─────────────    ──────────
DUE DILIGENCE    LANCEMENT        EXÉCUTION        BASCULE          CLÔTURE
IAM              PROJET           PHASES 0-3       J-DAY            PHASES 4-5

Avant signing    Après signing    Semaines 1-10    Jour de          Semaines
ou pendant       de l'accord      (prépa, audit,   migration        11-16
la négociation                    remédiation,
                                  migration)
```

---

## Étape 1 — Due diligence IAM (avant signing)

### Contexte

La due diligence IAM intervient pendant la phase de négociation de
l'acquisition, avant que l'accord soit signé. Son objectif est d'évaluer
le **risque IAM de l'entreprise cible** pour informer la négociation
(valorisation, clauses de garantie, conditions suspensives).

Cette étape est souvent négligée. Elle peut pourtant révéler des risques
qui impactent significativement la valeur ou les conditions de la transaction.

### Périmètre d'investigation

**Annuaire et identités :**
- Type d'annuaire (AD on-prem, Entra ID, LDAP, aucun)
- Nombre de comptes, taux d'obsolescence estimé
- Politique de mots de passe et MFA
- Présence ou absence de processus de révocation des départs

**Applications SaaS :**
- Inventaire des applications principales
- Présence de Shadow IT
- Gouvernance des accès applicatifs

**Conformité réglementaire :**
- RGPD : DPO nommé ? Registre des traitements ? DPA avec les SaaS ?
- ISO 27001 ou équivalent : certification, alignement, état d'avancement
- NIS2 : entité concernée ? Mesures en place ?

**Posture sécurité :**
- Incidents de sécurité passés liés aux identités
- Comptes partagés documentés ou non
- Tokens d'API, clés d'accès non révoqués

### Livrables de due diligence

| Livrable | Contenu | Destinataire |
|---|---|---|
| Rapport de risque IAM | Synthèse des risques identifiés, niveau (CRITIQUE/ÉLEVÉ/MODÉRÉ) | Direction, DAF, conseil |
| Estimation du coût d'intégration | Effort humain + outils estimé pour le projet IAM | DAF, direction |
| Recommandations contractuelles | Clauses de garantie suggérées si risques CRITIQUE identifiés | Conseil juridique |

### Points de vigilance due diligence

Un accès à l'AD et aux applications SaaS n'est généralement pas possible
pendant la due diligence — les informations sont collectées via questionnaire
auprès de la direction IT de l'entreprise cible.

Ce questionnaire est distinct du questionnaire post-acquisition (Phase 0).
Son niveau de détail est délibérément plus limité pour ne pas révéler
une intention d'acquisition avant signing.

---

## Étape 2 — Lancement du projet IAM (J0 — après signing)

### J0 à J+7 — Constitution de l'équipe projet

```
Rôle                    Profil                    Responsabilité
────────────────────    ─────────────────────     ─────────────────────────
Chef de projet IAM      DSI ou RSSI CorpA         Pilotage, Go/NoGo
Ingénieur IAM           Consultant ou interne     Exécution technique A→Z
Référent sécurité       RSSI CorpA                Validation audits
DPO                     Interne ou externe        Base légale RGPD
Relais CorpB            DSI CorpB                 Accès et connaissance terrain
```

### J+7 — Kick-off projet

**Ordre du jour type :**

1. Présentation de la méthodologie IAM 360° à toutes les parties prenantes
2. Validation du périmètre (AD + SaaS + OUs concernées)
3. Validation du calendrier global (16 semaines standard)
4. Identification des référents métier CorpB par département
5. Établissement du canal de communication et des outils de suivi
6. Première revue du questionnaire d'état des lieux (voir Document 3)

**Décisions à prendre en kick-off :**
- Fenêtre de maintenance J-Day (contraintes métier à éviter)
- Politique de traitement des comptes de service (cas par cas ou règle générale)
- Seuil d'inactivité retenu pour la qualification d'un compte obsolète (90 jours standard)
- Mode de transmission des mots de passe temporaires (SMS, email chiffré, en main propre)

### J+14 — Validation RGPD et base légale

Avant tout démarrage des scripts, le DPO valide par écrit :
- La base légale retenue pour la migration des données personnelles
- La liste des sous-traitants SaaS identifiés avec leur DPA
- La nécessité ou non d'une notification CNIL (transfert de données)
- Le calendrier d'information des personnes concernées (Art. 13/14)

Cette validation est une condition bloquante pour la Phase 3.

---

## Étape 3 — Exécution des phases 0 à 3 (Semaines 1 à 10)

### Semaine 1-2 — Phase 0 : Préparation

**Objectif :** constituer la base de connaissance avant tout script.

| Jour | Action | Livrable |
|---|---|---|
| S1-J1 | Communication DG-to-DG (lancement officiel) | Email formel |
| S1-J2 | Entretien DSI CorpB (cartographie technique) | Notes d'entretien |
| S1-J3 | Questionnaire managers CorpB (SaaS + accès critiques) | Questionnaire complété |
| S1-J4 | Analyse DNS/proxy (détection Shadow IT) | Liste apps détectées |
| S1-J5 | Consolidation inventaire SaaS | `Collect-SaaSInventory.md` complété |
| S2-J1 | Scoring risque SaaS | `Audit-SaaSRisk.py` exécuté |
| S2-J2 | Matrice des parties prenantes finalisée | `Collect-StakeholderMatrix.md` |
| S2-J3 | Briefing managers CorpB (réunion 45 min) | `OCM-Phase0-Communication.md` |
| S2-J4 | Matrice de criticité validée | `Template-CriticalityMatrix.csv` |
| S2-J5 | Validation Phase 0 — Go pour Phase 1 | Checklist Phase 0 complète |

**Signaux GO Phase 1 :**
- Matrice parties prenantes validée avec au moins un validateur par département
- Inventaire SaaS couvrant 100% des applications connues
- Briefing managers CorpB effectué avec accusé de réception

### Semaine 3-4 — Phase 1 : Audit

**Objectif :** photographie complète de l'existant CorpB.

| Jour | Script | Sortie |
|---|---|---|
| S3-J1 | `Audit-ADInventory.ps1` | Vue d'ensemble 312 comptes |
| S3-J2 | `Audit-StaleAccounts.ps1` | 49 comptes obsolètes identifiés |
| S3-J3 | `Audit-PrivilegedAccounts.ps1` | 5 comptes privilégiés dont 2 non documentés |
| S3-J4 | `Audit-GroupMembership.ps1` | 4 groupes orphelins identifiés |
| S3-J5 | `Audit-PasswordPolicy.ps1` | 4 écarts de conformité |
| S4-J1 | Restitution OCM aux référents CorpB | `OCM-Phase1-StakeholderBriefing.md` |
| S4-J2 | Revue RSSI CorpA — validation des rapports | Email de validation |
| S4-J3 | Préparation CSV de validation Phase 2 | CSV pré-remplis par département |
| S4-J4 | Envoi CSV aux managers + instructions | `README-validation.md` |
| S4-J5 | Validation Phase 1 — Go pour Phase 2 | Rapports signés RSSI |

**Point d'attention Phase 1 :**
Si des risques CRITIQUE sont identifiés (tokens exposés, comptes Admin partagés),
ne pas attendre la Phase 2 pour alerter. Ces cas font l'objet d'un traitement
accéléré dès la restitution OCM Phase 1.

### Semaine 5-6 — Phase 2 : Remédiation

**Objectif :** assainir l'AD CorpB. Ne migrer que des identités propres.

| Jour | Action | Acteur |
|---|---|---|
| S5-J1 | Relance managers pour retour CSV (délai : vendredi) | Chef de projet |
| S5-J2-J4 | Collecte et vérification des CSV retournés | Ingénieur IAM |
| S5-J5 | Scellage SHA-256 des CSV validés | Ingénieur IAM |
| S6-J1 | DryRun des trois scripts de remédiation | Ingénieur IAM |
| S6-J2 | Relecture DryRun avec RSSI CorpA | RSSI |
| S6-J3 | Exécution `Remediate-StaleAccounts.ps1 -DryRun:$false` | Ingénieur IAM |
| S6-J3 | Exécution `Remediate-PrivilegedReview.ps1 -DryRun:$false` | Ingénieur IAM |
| S6-J4 | Exécution `Remediate-GroupCleanup.ps1 -DryRun:$false` | Ingénieur IAM |
| S6-J4 | Communication post-remédiation aux managers | `OCM-Phase2-RemediationNotice.md` |
| S6-J5 | Validation Phase 2 — Go pour Phase 3 | DSI CorpA |

**Gestion des CSV non retournés :**
Si un manager ne retourne pas son CSV dans le délai imparti, une relance unique
est envoyée. Si aucune réponse sous 48h supplémentaires, escalade au DSI CorpB.
Les comptes concernés sont conservés sans action jusqu'à validation.

### Semaine 7-9 — Phase 3 : Migration

**Objectif :** provisionner les identités validées dans Entra ID CorpA.

| Semaine | Action | Acteur |
|---|---|---|
| S7-J1 | `Audit-PreMigrationChecklist.ps1` — vérification GO | Ingénieur IAM |
| S7-J2 | Validation DPO — base légale RGPD confirmée | DPO |
| S7-J3 | DryRun migration — simulation complète | Ingénieur IAM |
| S7-J4 | Relecture DryRun — validation DSI CorpA (Go/NoGo J-Day) | DSI CorpA |
| S7-J5 | Envoi `OCM-Phase3-MigrationGuide.md` aux collaborateurs CorpB | Chef de projet |
| S8-J1 | Migration Shadow Mode (`-ShadowMode`) | Ingénieur IAM |
| S8-J2 | `Audit-PostMigrationDelta.ps1` — vérification delta | Ingénieur IAM |
| S8-J2 | Correction delta si nécessaire (re-provisioning ciblé) | Ingénieur IAM |
| S8-J3 | **J-Day** — `ActivateShadowAccounts` + désactivation AD source | Ingénieur IAM |
| S8-J3 | Communication J-Day (pendant la bascule) | Chef de projet |
| S8-J4 | Suivi connexions J+1 — traitement des cas bloqués | Ingénieur IAM + IT CorpB |
| S8-J5 | Communication J+1 post-bascule — confirmation | DSI CorpA |
| S9 | Suivi activation MFA (cible > 90% J+7) | Ingénieur IAM |

---

## Étape 4 — J-Day : protocole de bascule

### Avant J-Day (J-5 à J-1)

- [ ] Checklist GO/NoGo validée (tous les points CRITIQUE en GO)
- [ ] Communication J-3 envoyée à tous les collaborateurs CorpB
- [ ] Briefing managers J-4 effectué
- [ ] Migration Shadow Mode exécutée sans erreur
- [ ] Delta post-migration = 0 (ou delta accepté et documenté)
- [ ] Fichier mots de passe temporaires préparé et sécurisé
- [ ] Fenêtre de maintenance confirmée avec les équipes métier
- [ ] Équipe support IT en astreinte (8h-18h J-Day)
- [ ] Canal de communication d'urgence activé (téléphone direct IT)
- [ ] Plan de rollback documenté et accessible

### J-Day — protocole heure par heure

```
H-1   Vérification finale infrastructure Entra ID CorpA
      Confirmation astreinte IT CorpB (Julien Faure)

H0    Activation comptes Shadow Mode
      (.\Migrate-UsersToEntraID.ps1 -ActivateShadowAccounts)

H0+15 Vérification des premiers logs de connexion Entra ID
      Traitement immédiat des erreurs bloquantes

H0+30 SMS mots de passe temporaires envoyés aux collaborateurs
      (si mode SMS retenu)

H1    Ouverture canal support dédié
      Premier point de situation (nb connexions réussies)

H4    Point de situation intermédiaire — décision de poursuite ou rollback
      Seuil rollback : > 20% de tickets bloquants non résolus

H8    Clôture J-Day — synthèse des connexions
      Communication J+1 préparée

H+24  Communication J+1 envoyée
      Bilan provisoire tickets support
```

### Critères de rollback J-Day

Le rollback est déclenché si l'une des conditions suivantes est réunie :

- Plus de 20% des utilisateurs signalent un blocage total d'accès
- Une application critique (AS400, Salesforce) est inaccessible
  pour plus de 10% de ses utilisateurs habituels
- Un incident de sécurité est détecté (connexion non autorisée, token compromis)

Le rollback Phase 3 est documenté dans `README-phase3.md` et exécutable
en moins de 30 minutes pour 300 comptes.

---

## Étape 5 — Clôture (Semaines 10 à 16)

### Semaine 10-12 — Phase 4 : Gouvernance

| Moment | Action | Script |
|---|---|---|
| J+1 | Audit orphelins post-migration | `Audit-OrphanAccounts.ps1` |
| J+7 | Audit conflits RBAC | `Audit-RBACConflicts.ps1` |
| J+7 | Audit comptes invités | `Audit-GuestAccounts.ps1` |
| J+14 | Passation gouvernance aux managers CorpA | `OCM-Phase4-GovernanceHandover.md` |
| J+14 | Session accompagnement IT CorpB (Julien Faure) | 1h avec ingénieur IAM |
| J+30 | Audit SaaS post-fusion | `Audit-SaaSPostFusion.py` |
| J+30 | Actions de gouvernance SaaS (désactivations, régularisations) | Suivi chef de projet |
| J+90 | Recertification managériale — voir `iam-governance-lab` | Managers CorpA |

### Semaine 13-14 — Phase 5 : Scellage

| Action | Acteur |
|---|---|
| `Invoke-EvidenceSealer.ps1 -DryRun` — vérification liste rapports | Ingénieur IAM |
| `Invoke-EvidenceSealer.ps1 -DryRun:$false` — scellage réel | Ingénieur IAM |
| Vérification manifest JSON — signature RSSI | RSSI CorpA |
| Archivage sécurisé du dossier `/reports/evidence/` | DSI CorpA |

### Semaine 15-16 — Rapport de clôture et retour d'expérience

| Action | Acteur | Livrable |
|---|---|---|
| Rédaction rapport de clôture | Chef de projet | `OCM-Phase5-ClosureReport.md` |
| Relecture métriques — vérification des indicateurs | RSSI + DSI | — |
| Présentation CODIR | DSI CorpA | Rapport clôture |
| Session retour d'expérience équipe projet | Chef de projet | Notes REX |
| Traitement des points ouverts résiduels | Ingénieur IAM | Suivi |
| Envoi questionnaire post-migration collaborateurs CorpB | Chef de projet | Questionnaire (voir Document 3) |

---

## Tableau de bord du projet — 20 jalons

| # | Jalon | Phase | Semaine | Validateur |
|---|---|---|---|---|
| J1 | Accord signing — lancement officiel | Avant | S0 | Direction |
| J2 | Équipe projet constituée | Lancement | S1 | DSI CorpA |
| J3 | Kick-off effectué | Lancement | S1 | Chef projet |
| J4 | Validation RGPD — base légale confirmée | Lancement | S2 | DPO |
| J5 | Phase 0 terminée — matrice + SaaS + communication | Phase 0 | S2 | Chef projet |
| J6 | Phase 1 terminée — rapports signés RSSI | Phase 1 | S4 | RSSI |
| J7 | Restitution OCM Phase 1 effectuée | Phase 1 | S4 | Chef projet |
| J8 | CSV de validation retournés (100% managers) | Phase 2 | S5 | Chef projet |
| J9 | Phase 2 terminée — log sans erreur critique | Phase 2 | S6 | DSI CorpA |
| J10 | Checklist Phase 3 — tous CRITIQUE en GO | Phase 3 | S7 | Ingénieur IAM |
| J11 | Go/NoGo J-Day validé — DSI CorpA | Phase 3 | S8 | DSI CorpA |
| J12 | Migration Shadow Mode — log sans erreur | Phase 3 | S8 | Ingénieur IAM |
| J13 | Delta post-migration = 0 | Phase 3 | S8 | Ingénieur IAM |
| J14 | **J-DAY** — bascule effectuée | Phase 3 | S8 | DSI CorpA |
| J15 | MFA > 90% J+7 | Phase 3 | S9 | Ingénieur IAM |
| J16 | Passation gouvernance managers CorpA | Phase 4 | S11 | Chef projet |
| J17 | Gouvernance SaaS post-fusion traitée | Phase 4 | S12 | Ingénieur IAM |
| J18 | Scellage complet — manifest validé RSSI | Phase 5 | S13 | RSSI |
| J19 | Rapport clôture présenté CODIR | Clôture | S15 | DSI CorpA |
| J20 | Questionnaire collaborateurs — retours analysés | Clôture | S16 | Chef projet |

---

## Durées indicatives par configuration

| Configuration | Durée estimée | Facteurs d'allongement |
|---|---|---|
| PME < 100 personnes, 3-4 apps SaaS | 8-10 semaines | Absence de RSSI CorpB, Shadow IT important |
| PME 100-300 personnes, 5-8 apps SaaS | 12-16 semaines | Retards CSV validation, delta migration |
| ETI 300-500 personnes, 8-12 apps SaaS | 16-20 semaines | Multi-domaines, AS400 ou ERP legacy |
| ETI > 500 personnes | Sur devis | Nécessite outillage IGA dédié |

---

*Playbook M&A IAM — `iam-ma-integration-lab` — IAM-Lab Framework*
*Version 1.0 — Auteur : Arnaud Montcho — consultant IAM/IGA hybride*
