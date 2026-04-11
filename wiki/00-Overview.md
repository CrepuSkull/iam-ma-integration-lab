# 00 — Vue d'ensemble du lab

> Wiki — `iam-ma-integration-lab` | IAM-Lab Framework
> Page d'entrée — lire en premier

---

## Ce que ce lab simule

Une entreprise (CorpA) utilisant Microsoft Entra ID rachète une PME (CorpB)
qui tourne sur Active Directory on-premises. Ce lab modélise l'intégralité
du cycle d'intégration IAM qui suit cette acquisition : de la préparation
humaine jusqu'au scellage des preuves d'audit.

Ce n'est pas un lab de déploiement infrastructure. C'est un lab de
**méthodologie** : comment conduire une intégration IAM M&A de façon
structurée, traçable, humainement accompagnée et réglementairement documentée.

---

## Pourquoi ce lab existe

Les projets d'intégration IAM en contexte M&A échouent pour trois raisons
récurrentes :

1. **Ils démarrent trop tôt** — l'audit technique commence avant que
   quiconque ait cartographié les parties prenantes ou le périmètre SaaS
2. **Ils ignorent l'humain** — les collaborateurs de l'entreprise absorbée
   découvrent le changement le jour J, sans préparation
3. **Ils ne produisent pas de preuves** — les actions effectuées ne sont
   pas traçables, ce qui fragilise la posture de conformité

Ce lab répond à ces trois problèmes avec une méthode reproductible.

---

## Structure globale

```
iam-ma-integration-lab/
│
├── 📄 README.md                  Vue d'ensemble (EN)
├── 📄 SCENARIO.md                Narrative M&A complète (FR)
├── 📄 REGULATORY-MAPPING.md      Matrice ISO 27001 / NIS2 / RGPD
│
├── 🌱 /seed/                     Données fictives CorpB (312 comptes AD + 625 SaaS)
├── 📋 /phase0-preparation/       Préparation — parties prenantes + SaaS
├── 🔍 /phase1-audit/             Audit AD + SaaS — lecture seule
├── 🔧 /phase2-remediation/       Remédiation AD — validation CSV obligatoire
├── 🚀 /phase3-migration/         Migration vers Entra ID — Shadow Mode
├── 🏛️ /phase4-governance/        Gouvernance post-fusion — AD + SaaS
├── 🔐 /phase5-evidence/          Scellage cryptographique des rapports
├── 🔄 /ocm/                      Accompagnement au changement — fil conducteur
└── 📊 /reporting/                Reporting Python agrégé
```

---

## Les 6 phases + OCM

| Phase | Nom | Nature | Script pivot |
|---|---|---|---|
| **0** | Préparation | Collecte — aucun script | `Collect-StakeholderMatrix.md` |
| **1** | Audit | Lecture seule | `Audit-ADInventory.ps1` |
| **2** | Remédiation | Écriture — DryRun défaut | `Remediate-StaleAccounts.ps1` |
| **3** | Migration | Écriture — Shadow Mode | `Migrate-UsersToEntraID.ps1` |
| **4** | Gouvernance | Lecture seule | `Audit-RBACConflicts.ps1` |
| **5** | Evidence | Scellage | `Invoke-EvidenceSealer.ps1` |
| **OCM** | Fil conducteur | Templates + exemples | `OCM-Framework.md` |

---

## Principes non négociables

**Lecture seule d'abord.** Aucun script d'audit ne modifie quoi que ce soit.
Les scripts de remédiation et de migration ont le `-DryRun` activé par défaut
et ne s'exécutent qu'avec `-DryRun:$false` explicite.

**Validation humaine obligatoire.** Toute action de remédiation passe par
un CSV intermédiaire. La colonne `Valider: OUI` (exact, majuscules) est
le seul déclencheur d'exécution.

**Preuve avant action.** Le CSV validé est scellé (SHA-256) avant exécution.
Toute modification post-scellage invalide l'opération.

**OCM transverse.** Chaque phase produit un livrable technique ET un livrable
humain. L'accompagnement au changement n'est pas une phase — c'est une posture.

---

## Navigation dans le wiki

| Page | Contenu |
|---|---|
| [[01-Scenario-MA]] | Narrative CorpA/CorpB — contexte détaillé |
| [[02-Seed-Setup]] | Générer l'environnement fictif CorpB |
| [[03-Phase0-Preparation]] | Parties prenantes, SaaS, criticité |
| [[04-Phase1-Audit]] | Audit AD et SaaS — mode d'emploi |
| [[05-Phase2-Remediation]] | Flux de validation CSV — mode d'emploi |
| [[06-Phase3-Migration]] | Shadow Mode, J-Day, rollback |
| [[07-Phase4-Governance]] | Gouvernance continue post-fusion |
| [[08-Phase5-Evidence]] | Scellage des preuves |
| [[09-OCM-Guide]] | Accompagnement au changement — synthèse |
| [[10-Regulatory-Mapping]] | Matrice réglementaire détaillée |
| [[11-Troubleshooting]] | Erreurs fréquentes et solutions |

---

## Prérequis pour démarrer

```powershell
# PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ActiveDirectory   # Si RSAT non installé

# Python
pip install pandas tabulate colorama --break-system-packages

# Cloner le repo
git clone https://github.com/CrepuSkull/iam-ma-integration-lab.git
cd iam-ma-integration-lab

# Générer les données fictives CorpB
cd seed
python generate-corpb-users.py
python generate-corpb-saas.py
```

---

*Wiki — `iam-ma-integration-lab` — IAM-Lab Framework*
