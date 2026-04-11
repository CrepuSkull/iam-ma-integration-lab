# 01 — Scénario M&A : CorpA absorbe CorpB

> Wiki — `iam-ma-integration-lab`

---

## Les deux entités

### CorpA — l'absorbante

ETI du secteur services B2B. Entra ID avec MFA enforced, Conditional Access
déployé, RBAC normé, démarche ISO 27001 en cours. ~500 utilisateurs, équipe
IT de 8 personnes, RSSI à temps partiel.

**Posture IAM** : mature. Le tenant CorpA est ce vers quoi CorpB va migrer.
C'est l'environnement de référence.

### CorpB — la cible

PME de 300 personnes, rachetée pour accélération commerciale. AD on-premises
sur Windows Server 2016, deux domaines, cinq OUs. Aucun MFA déployé. Pas de
politique de révocation des comptes à la sortie des collaborateurs. Huit
applications SaaS en usage, dont une non déclarée à la DSI.

**Posture IAM** : typique d'une PME sans accompagnement spécifique.
Pas de mauvaise volonté — simplement des processus qui n'ont jamais été formalisés.

---

## Les signaux d'alerte découverts en Phase 0

Avant même de lancer le premier script, quatre signaux ont été identifiés
lors de la prise de contact avec les équipes CorpB :

- Des commerciaux partis il y a plus de 18 mois ont encore des comptes actifs
- Le compte administrateur Salesforce est partagé entre deux personnes
- Des tokens d'API sont en clair dans des dépôts GitLab
- Une application de stockage cloud (Dropbox Biz) est utilisée sans que
  la DSI en ait connaissance

Ces quatre points résument l'enjeu IAM d'une acquisition : le système
d'information de CorpB a fonctionné, mais sans les contrôles qu'une
démarche de sécurité formalisée aurait imposés.

---

## Le périmètre en chiffres

| Élément | CorpB |
|---|---|
| Domaines AD | 2 (`corpb.local`, `legacy.corpb.local`) |
| Unités organisationnelles | 5 (Direction, Commercial, Technique, RH, Prestataires) + 2 legacy (ServiceCompt, Archived) |
| Comptes AD | 312 dont 49 obsolètes, 12 de service, 5 privilégiés |
| Applications SaaS | 8 (625 comptes applicatifs) |
| MFA déployé | 0 compte |
| Shadow IT | 1 application (Dropbox Biz) |

---

## Pourquoi la migration ne peut pas être directe

Une migration directe AD → Entra ID sans préparation reviendrait à
importer tous les risques CorpB dans un environnement CorpA maîtrisé.
Les 49 comptes obsolètes deviendraient des comptes Entra ID actifs avec
MFA. Les tokens GitLab exposés seraient toujours présents. Le compte
Salesforce Admin partagé continuerait d'exister.

La séquence du lab est conçue pour éviter exactement ça :

```
Comprendre   →   Auditer   →   Nettoyer   →   Migrer   →   Gouverner
(Phase 0)       (Phase 1)     (Phase 2)     (Phase 3)    (Phases 4-5)
```

On ne migre que ce qui a été audité. On n'exécute que ce qui a été validé.

---

## Les personas du scénario

Le scénario s'appuie sur des personnages fictifs nommés pour rendre
le lab plus lisible et plus pédagogique.

| Persona | Rôle | Implication principale |
|---|---|---|
| **Sophie Arnaud** | DSI CorpA | Sponsor projet, Go/NoGo Phase 3 |
| **Karim Benali** | RSSI CorpA (temps partiel) | Validation audits, arbitrage SoD |
| **Inès Moulin** | Ingénieure IAM CorpA | Exécution technique de A à Z |
| **Marc Deschamps** | DPO CorpA | Validation base légale RGPD Phase 3 |
| **Thierry Vogt** | DSI CorpB | Validateur technique, accès AD |
| **Julien Faure** | Admin IT CorpB | Connaissance terrain de l'AD CorpB |
| **Nadège Perrin** | Responsable Commercial CorpB | Validation comptes + compte Salesforce |
| **Bastien Couture** | Lead Dev CorpB | Validation comptes + tokens GitLab |
| **Amandine Leconte** | DRH CorpB | BambooHR, données RH sensibles |
| **Paulo Esteves** | Responsable Prestataires CorpB | Dropbox Biz Shadow IT |
| **Claire Imbert** | DG CorpB | Informée Phase 0 et clôture |

---

## Ce que ce lab ne couvre pas (v1)

- Migration des boîtes mail, partages et licences applicatives
- Fédération SAML/OIDC (→ `iam-federation-lab`)
- Déploiement d'outils IGA du marché (SailPoint, Saviynt)
- Architecture Entra ID Connect en production
- Intégration API native des applications SaaS (exports CSV en v1)
- Gestion des postes de travail (jointure Entra ID, Intune)

---

*Wiki page 01 — `iam-ma-integration-lab` — IAM-Lab Framework*
