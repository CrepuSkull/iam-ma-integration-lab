# ⚖️ Compliance-RGPD-Migration.md — Conformité RGPD en contexte M&A IAM

> `iam-ma-integration-lab` / docs
> DPIA simplifiée · Base légale · Registre des traitements · Rétention des logs
> Langue : Français | Cible : DPO, RSSI, DSI, consultant IAM

---

## Avertissement préalable

> Ce document est un **cadre méthodologique de démonstration**.
> Il ne constitue pas un avis juridique. Tout déploiement en contexte réel
> nécessite une validation par un DPO qualifié et, selon les cas,
> un conseil juridique spécialisé en droit des données personnelles.

---

## 1. Pourquoi le RGPD s'applique à ce projet

La migration des identités AD CorpB vers Entra ID CorpA constitue un
**traitement de données personnelles** au sens de l'article 4 du RGPD :
les noms, prénoms, identifiants, adresses email, données de connexion
et attributs professionnels des collaborateurs CorpB sont des données
personnelles dès lors qu'ils permettent d'identifier une personne physique.

Trois changements juridiques surviennent lors de l'acquisition :

1. **Changement de responsable de traitement** : CorpA devient responsable
   du traitement des données des collaborateurs CorpB
2. **Transfert de données** entre deux entités juridiques distinctes
3. **Nouveaux sous-traitants** : les applications SaaS de CorpB deviennent
   des sous-traitants de CorpA au sens de l'Art. 28

---

## 2. Analyse d'impact (DPIA) simplifiée

### 2.1 Critères de déclenchement d'une DPIA complète

Selon les lignes directrices CNIL/CEPD, une DPIA est obligatoire si
le traitement présente au moins deux des critères suivants :

| Critère | Présent dans ce projet ? |
|---|---|
| Évaluation / notation de personnes | Non |
| Décision automatisée avec effet significatif | Non |
| Surveillance systématique | Non |
| Données sensibles (Art. 9) | Partiellement (données RH BambooHR) |
| Données à grande échelle | Non (312 personnes — PME) |
| Croisement de bases de données | Oui (AD CorpB + SaaS + Entra ID CorpA) |
| Personnes vulnérables | Non |
| Usage innovant ou nouvelle technologie | Non |
| Transfert hors UE | Potentiel (selon hébergement SaaS) |

**Conclusion :** le seuil de DPIA obligatoire n'est pas atteint pour
un projet standard CorpA/CorpB de cette taille. Une **analyse de risque
simplifiée** (ci-dessous) est suffisante et recommandée.

> Si l'une des entités est dans un secteur réglementé (santé, banque,
> assurance) ou si le volume dépasse 5 000 personnes, une DPIA complète
> est nécessaire.

### 2.2 Analyse de risque simplifiée — matrice

| Risque | Probabilité | Impact | Mesure d'atténuation | Risque résiduel |
|---|---|---|---|---|
| Accès non autorisé aux données pendant migration | Faible | Élevé | Scripts lecture seule + DryRun + scellage Phase 5 | Faible |
| Perte ou corruption de données personnelles | Faible | Élevé | Rollback documenté + fichiers source conservés | Faible |
| Migration de données vers un pays hors UE | Moyen | Élevé | Vérification hébergement SaaS + tenant Entra ID UE | Moyen |
| Traitement de données au-delà de la finalité | Faible | Moyen | Minimisation — seuls les attributs nécessaires migrés | Faible |
| Accès par un tiers non autorisé (SaaS) | Moyen | Élevé | DPA vérifiés — Dropbox Biz régularisé avant migration | Faible |
| Absence d'information des personnes concernées | Fort | Élevé | Communication OCM Phase 0 — Art. 13/14 respecté | Faible |

### 2.3 Mesures techniques et organisationnelles (MTO)

Conformément à l'Art. 32 RGPD, les mesures suivantes sont implémentées :

**Pseudonymisation :** les rapports d'audit sont produits avec les
sAMAccountName (identifiants techniques) — les noms complets ne sont
présents que dans les CSV de validation transmis aux managers concernés.

**Minimisation :** seuls les attributs nécessaires à la migration sont
traités (9 attributs AD vs les 40+ disponibles). Les données RH (salaires,
évaluations) ne sont jamais incluses dans le périmètre de migration AD.

**Intégrité :** scellage SHA-256 de tous les rapports en Phase 5.

**Confidentialité :** le fichier de mots de passe temporaires est marqué
SENSIBLE — transmission par canal sécurisé uniquement, non versionné dans Git.

**Traçabilité :** logs d'exécution horodatés avec identifiant du validateur
pour chaque action de remédiation.

---

## 3. Base légale du traitement

### 3.1 Choix de la base légale

En contexte M&A, trois bases légales sont envisageables pour la migration
des données personnelles des collaborateurs :

| Base légale | Art. RGPD | Applicable ? | Conditions |
|---|---|---|---|
| Exécution du contrat de travail | 6(1)(b) | Oui (partielle) | Valide pour les données nécessaires à l'exécution du contrat |
| Intérêt légitime | 6(1)(f) | Oui (principale) | Intérêt légitime CorpA + test de balance des intérêts |
| Obligation légale | 6(1)(c) | Non | Pas d'obligation légale spécifique de migrer les identités |
| Consentement | 6(1)(a) | Non recommandé | Difficile à obtenir librement dans le contexte employeur |

**Base légale retenue : intérêt légitime (Art. 6(1)(f))**

**Argumentaire :**
- CorpA a un intérêt légitime à intégrer les systèmes d'information
  de l'entité acquise dans son environnement de sécurité
- La migration est nécessaire et proportionnée à cet objectif
- Les droits et libertés des collaborateurs ne sont pas remis en cause
  (pas de traitement décisionnel, pas de profilage)
- L'impact sur les individus est limité et temporaire

**Test de balance des intérêts (résumé) :**
- Intérêt CorpA : sécurité, conformité, continuité d'activité — légitime
- Impact sur les personnes : changement d'identifiant, configuration MFA — mineur
- Mesures d'atténuation : information préalable, continuité d'accès garantie

**Validation requise :** le DPO doit confirmer cette base légale par écrit
avant le démarrage de la Phase 3. Cette validation est un jalon bloquant
dans le tableau de bord projet (`PLAYBOOK.md` — Jalon J4).

### 3.2 Cas particulier : données RH (BambooHR)

Les données hébergées dans BambooHR (salaires, évaluations, arrêts maladie)
peuvent constituer des données sensibles au sens de l'Art. 9 (données relatives
à la santé). Leur traitement nécessite :

- Une base légale spécifique (Art. 9(2)(b) — traitement nécessaire pour
  l'exécution des obligations employeur)
- Une consultation du comité social et économique (CSE) si applicable
- Une information spécifique des salariés sur ce traitement

**Action requise :** le traitement des données BambooHR est hors périmètre
du lab technique — il doit faire l'objet d'un sous-projet RH/DPO distinct.

---

## 4. Information des personnes concernées (Art. 13/14)

### 4.1 Obligations d'information

Deux situations créent une obligation d'information :

**Art. 13 (collecte directe) :** lorsque CorpA provisionne des comptes
Entra ID pour les collaborateurs CorpB, il collecte leurs données personnelles
— une information doit leur être fournie.

**Art. 14 (collecte indirecte) :** lorsque CorpA obtient les données
depuis l'AD CorpB (collecte indirecte), une information doit être fournie
dans un délai raisonnable.

### 4.2 Contenu de l'information

L'information doit couvrir :
- L'identité et les coordonnées du nouveau responsable de traitement (CorpA)
- Les finalités et la base légale du traitement
- Les catégories de données traitées
- La durée de conservation
- Les droits des personnes (accès, rectification, effacement, portabilité)
- L'existence de sous-traitants SaaS

### 4.3 Intégration dans l'OCM

La communication J-10 (`OCM-Phase0-Communication.md`) intègre
les éléments d'information réglementaires. Pour un projet réel,
cette communication doit être validée par le DPO avant envoi et
compléter la politique de confidentialité de CorpA.

---

## 5. Registre des traitements (Art. 30)

### 5.1 Entrée à créer dans le registre CorpA

```
REGISTRE DES TRAITEMENTS — Entrée à créer post-acquisition

Traitement : Gestion des identités et accès (IAM) — collaborateurs CorpB intégrés
Responsable : [Nom DSI CorpA] — [email]
DPO : [Nom DPO] — [email]
Finalité : Gestion des accès au SI CorpA pour les collaborateurs issus de CorpB
Base légale : Art. 6(1)(f) — Intérêt légitime
Catégories de personnes : Collaborateurs CorpB (312 personnes)
Catégories de données : Identité (nom, prénom), identifiants techniques,
                        adresse email professionnelle, données de connexion,
                        appartenance aux groupes de sécurité
Durée de conservation : Durée du contrat de travail + 5 ans (logs d'audit)
Destinataires : Équipe IT CorpA, managers CorpA, sous-traitants SaaS listés
Sous-traitants : Microsoft (Entra ID), [liste des SaaS retenus]
Transferts hors UE : Aucun si tenant Entra ID hébergé en UE
Mesures de sécurité : Chiffrement en transit, MFA enforced, scellage preuves d'audit
```

### 5.2 Mise à jour des entrées existantes

L'acquisition de CorpB peut impacter des entrées existantes du registre CorpA :
- Si CorpA traite déjà des données de clients CorpB → mettre à jour le registre
- Si des flux de données CorpA → CorpB existaient → réviser leur base légale

---

## 6. Sous-traitants SaaS — obligations Art. 28

### 6.1 Vérification des DPA

Chaque application SaaS de CorpB devient un sous-traitant de CorpA.
Les DPA existants (signés avec CorpB) doivent être revus ou renégociés.

| Application | DPA existant | Action requise |
|---|---|---|
| Salesforce | Oui (Salesforce DPA standard) | Mettre à jour pour refléter CorpA comme responsable |
| SlackConnect | Oui | Vérifier que la politique de rétention messages est conforme |
| GitLab CE | N/A (on-premises) | Inventorier les données personnelles dans les repos |
| Notion | Oui | Vérifier hébergement UE activé |
| BambooHR | Oui | DPA spécifique données RH — voir section 3.2 |
| AS400 | N/A (on-premises) | Documenter les données personnelles traitées |
| Jira Cloud | Oui (Atlassian DPA) | Mettre à jour pour refléter CorpA |
| Dropbox Biz | **NON** | Régulariser ou migrer les données avant Phase 3 |

### 6.2 Cas Dropbox Biz (Shadow IT)

Dropbox Biz n'a pas de DPA signé. Si des données personnelles y sont
stockées (coordonnées prestataires, documents RH partagés), CorpA est
en violation de l'Art. 28 dès la prise de contrôle de CorpB.

**Action requise avant Phase 3 :**
1. Inventorier le contenu avec Paulo Esteves (responsable prestataires)
2. Migrer les données vers SharePoint CorpA (approuvé, DPA existant)
3. Fermer le compte Dropbox Biz
4. Documenter l'action dans le rapport de clôture Phase 5

---

## 7. Rétention des logs et preuves d'audit

### 7.1 Durées de conservation recommandées

| Type de donnée | Durée | Base |
|---|---|---|
| Logs d'audit Phase 1-4 (CSV scellés) | 5 ans | ISO 27001 A.5.33 + pratique CNIL |
| CSV de validation (noms validateurs) | 5 ans | Traçabilité des décisions |
| Fichier mots de passe temporaires | **Destruction immédiate après J+30** | Minimisation Art. 5(1)(c) |
| Logs de connexion Entra ID | 90 jours (défaut Entra ID P1) / 180 jours (P2) | Microsoft policy |
| Manifest de scellage Phase 5 | 5 ans | Opposabilité |
| Rapport de clôture projet | 10 ans | Archive légale M&A |

### 7.2 Procédure de destruction sécurisée

À J+30, le fichier `phase3-migration-credentials_*.csv` (mots de passe
temporaires) doit être détruit de façon sécurisée :

```powershell
# Écrasement sécurisé avant suppression (Windows)
$file = ".\reports\phase3-migration-credentials_*.csv"
$content = Get-Content $file
$zeros = "0" * ($content | Out-String).Length
$zeros | Set-Content $file
Remove-Item $file -Force
Write-Host "[OK] Fichier credentials détruit de façon sécurisée"
```

### 7.3 Archivage long terme des preuves

Le dossier `/reports/evidence/` (manifest + empreintes SHA-256) doit être
archivé sur un support distinct du SI courant :

- Stockage immuable (Azure Immutable Blob Storage, AWS S3 Object Lock)
- Ou archivage physique chiffré (clé USB chiffrée en coffre)
- Accès restreint : DSI + RSSI + DPO uniquement

---

## 8. Droits des personnes concernées

Les collaborateurs CorpB conservent l'ensemble de leurs droits RGPD
après la migration. CorpA doit être en mesure de les exercer.

| Droit | Art. | Mise en œuvre dans ce lab |
|---|---|---|
| Accès | 15 | Via portail Entra ID MyAccount (myaccount.microsoft.com) |
| Rectification | 16 | Via IT CorpA (helpdesk) ou self-service Entra ID |
| Effacement | 17 | Processus de départ (LEAVER dans JML) — voir iam-identity-lifecycle-lab |
| Portabilité | 20 | Export des données via Microsoft Graph |
| Opposition | 21 | Recours possible si base légale = intérêt légitime |
| Limitation | 18 | Blocage compte sans suppression |

**Point d'attention :** le droit d'opposition (Art. 21) est applicable
puisque la base légale retenue est l'intérêt légitime. En pratique, un
collaborateur qui s'opposerait à la migration de ses données dans Entra ID
CorpA poserait une question RH/juridique qui dépasse le périmètre technique.
Ce cas doit être escaladé au DPO et au service juridique.

---

## 9. Checklist RGPD — jalons projet

| Jalon | Moment | Responsable | Statut |
|---|---|---|---|
| Base légale validée par DPO | Phase 0 — J0 | DPO | [ ] |
| Information Art. 13/14 rédigée et validée DPO | Phase 0 — J-14 | DPO + Chef projet | [ ] |
| DPA SaaS vérifiés et mis à jour | Phase 0 — J-7 | DPO + DSI | [ ] |
| Dropbox Biz régularisé ou fermé | Avant Phase 3 | IT + Paulo Esteves | [ ] |
| Registre des traitements mis à jour | Phase 3 — J-Day | DPO | [ ] |
| Fichier credentials détruit | J+30 | Ingénieur IAM | [ ] |
| BambooHR — sous-projet RH/DPO lancé | Phase 4 | DPO + DRH | [ ] |
| Logs d'audit archivés (stockage immuable) | Phase 5 | DSI | [ ] |

---

*Compliance-RGPD-Migration.md — `iam-ma-integration-lab` — IAM-Lab Framework*
*Version 1.0 — Cadre méthodologique, pas un avis juridique*
