# 🔀 iam-ma-integration-lab

> **IAM-Lab Framework — Lab #6**
> Identity & Access Management in a Merger & Acquisition context.
> CorpA (Entra ID) absorbs CorpB (Active Directory on-premises + SaaS ecosystem).

---

## 📌 Purpose

This lab simulates the **full IAM integration lifecycle** that occurs when an organization using Microsoft Entra ID acquires a company running a legacy on-premises Active Directory and an unmanaged SaaS ecosystem.

It is designed for:
- **CISOs / CIOs** evaluating a structured IAM integration methodology
- **IAM consultants** building a reproducible, documented approach
- **Security engineers** looking for a reference architecture for M&A identity scenarios

> This is a **demonstration lab**. All data is fictional. No production environment is required.
> Scripts are read-only by default. All remediation requires explicit human validation via CSV.

---

## 🏢 Scenario

| | CorpA (Acquirer) | CorpB (Target) |
|---|---|---|
| **Identity platform** | Microsoft Entra ID | Active Directory on-premises |
| **SaaS ecosystem** | Governed, SSO-enforced | Unmanaged — 8 apps, Shadow IT detected |
| **MFA** | Enforced (Conditional Access) | Not deployed |
| **User base** | ~500 accounts | ~312 accounts (simulated) |
| **Structure** | Single tenant, RBAC enforced | Multi-domain, multi-OU |
| **Compliance posture** | ISO 27001 aligned | Unknown / undocumented |

**Integration objective:** Migrate CorpB identities — AD and SaaS — into CorpA's governed environment, while eliminating risk, maintaining audit traceability, and supporting people through change.

---

## 🗂️ Lab Structure

```
iam-ma-integration-lab/
│
├── README.md                        ← You are here
├── SCENARIO.md                      ← Full M&A narrative (FR) + integration logic
├── REGULATORY-MAPPING.md            ← ISO 27001 / NIS2 / RGPD coverage matrix
│
├── /seed/                           ← Fictitious AD + SaaS data generation (CorpB)
├── /phase0-preparation/             ← Stakeholder mapping, SaaS inventory, criticality matrix
├── /phase1-audit/                   ← AD + SaaS risk mapping (CorpB)
├── /phase2-remediation/             ← Pre-migration cleanup (stale, privileged, groups)
├── /phase3-migration/               ← Provisioning to Entra ID (CorpA tenant)
├── /phase4-governance/              ← Post-integration governance (orphans, RBAC, guests, SaaS)
├── /phase5-evidence/                ← Cryptographic sealing of audit reports
├── /ocm/                            ← Change management — transverse across all phases
├── /reporting/                      ← Python-based consolidated reporting
└── /wiki/                           ← Full GitHub Wiki (12 pages)
```

---

## ⚙️ Methodology

This lab follows the **IAM 360° method** (Technical × Organizational × Human), structured in **6 sequential phases** with a **transverse change management layer (OCM)**.

```
[PHASE 0]        [PHASE 1]        [PHASE 2]        [PHASE 3]        [PHASE 4]        [PHASE 5]
PREPARATION  →    AUDIT      →  REMEDIATION   →  MIGRATION    →  GOVERNANCE    →   EVIDENCE

Understand        Map what         Fix what         Migrate what     Govern what      Seal what
the context       exists           is broken        is clean         was integrated   was done
(AD + SaaS        (AD + SaaS)      (AD source)      (→ Entra ID)     (post-fusion)    (reports)
 + stakeholders)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OCM LAYER  → [Communicate] → [Brief stakeholders] → [Notify] → [Guide users] → [Hand over] → [Close]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Dual deliverable principle

Every phase produces **two types of output**:

| Type | Nature | Audience |
|---|---|---|
| **Technical** | Script, CSV, audit report | IT / Security engineer |
| **Human (OCM)** | Communication, briefing, guide | Manager, end user, CISO |

The `/ocm/` folder is the **managerial backbone** of the project.
Each phase README cross-references its OCM counterpart.

---

## 🌐 SaaS Scope

CorpB's identity perimeter extends well beyond Active Directory.
Eight SaaS applications are simulated, each carrying distinct identity risks:

| Application | Category | Key risk simulated |
|---|---|---|
| **Salesforce** | CRM | Shared admin account, former staff still active |
| **SlackConnect** | Collaboration | External channels already open toward CorpA |
| **GitLab CE** | Dev / SCM | Personal tokens, untransferred private repos |
| **Notion** | Knowledge / Doc | Workspaces shared with personal accounts |
| **BambooHR** | HR | Sensitive HR data, unrevoked DRH-level access |
| **AS400** | ERP Legacy | Shared service accounts, no MFA capability |
| **Jira Cloud** | ITSM | Cross-company projects, unattached agents |
| **Dropbox Biz** | Cloud Storage | Confirmed Shadow IT, unclassified data |

> SaaS accounts are **invisible to Active Directory**.
> Phase 0 surfaces them. Phase 1 audits them. Phase 4 governs them post-integration.

---

## 🔗 Cross-references to IAM-Lab Framework

| Component | Source lab | Usage in this lab |
|---|---|---|
| AD audit scripts | [`iam-foundation-lab`](https://github.com/CrepuSkull/iam-foundation-lab) | Phase 1 — adapted for M&A inventory |
| JML onboarding logic | [`IAM-Lab-Identity-Lifecycle`](https://github.com/CrepuSkull/IAM-Lab-Identity-Lifecycle) | Phase 4 — CorpB users lifecycle |
| Recertification controls | [`iam-governance-lab`](https://github.com/CrepuSkull/iam-governance-lab) | Phase 4 — post-integration access review |
| Cryptographic sealing | [`iam-evidence-sealer`](https://github.com/CrepuSkull/iam-evidence-sealer) | Phase 5 — audit report integrity |
| Auth & CA audit | [`iam-federation-lab`](https://github.com/CrepuSkull/iam-federation-lab) | Phase 3/4 — Conditional Access verification |

> Principle: no duplication of existing work. This lab **orchestrates, contextualizes and extends**.

---

## 🛡️ Safety Principles

| Principle | Implementation |
|---|---|
| **Read-only audits** | All `Audit-*.ps1` scripts perform no writes |
| **DryRun by default** | All `Remediate-*.ps1` require `-DryRun:$false` to execute |
| **Human validation gate** | CSV intermediate mandatory — `Valider: OUI` (exact, uppercase) triggers execution |
| **Shadow mode** | Migration scripts observe and compare before any provisioning |
| **Rollback < 15 min** | Each remediation phase documents a rollback procedure |
| **Evidence integrity** | All reports sealed with SHA-256 before archiving |

---

## 📋 Prerequisites

### Environment
- Windows PowerShell 5.1+ or PowerShell 7+
- Read access to CorpB AD (or seed environment)
- Microsoft Graph PowerShell SDK (`Install-Module Microsoft.Graph`)
- Python 3.10+ (reporting + SaaS risk analysis)

### Permissions (minimum)
- CorpB AD: `Domain Users` + `Read` on all OUs
- CorpA Entra ID: `User.Read.All`, `Group.Read.All` (audit) / `User.ReadWrite.All` (migration, explicit)
- SaaS apps: read-only API access or manual CSV export (Phase 0 guide covers both paths)

### Seed environment (lab only)
> No production AD required.
> Use `/seed/Seed-CorpB-AD.ps1` to generate a full fictitious CorpB AD environment.
> Use `/seed/corpb-saas-accounts.csv` as the SaaS account dataset.
> See [`/seed/README-seed.md`](./seed/README-seed.md) for setup instructions.

---

## 🗺️ Regulatory Coverage

| Framework | Key controls covered |
|---|---|
| **ISO 27001:2022** | A.5.15, A.5.16, A.5.18, A.8.2, A.5.3 (SoD), A.5.28, A.5.33 |
| **NIS2** | Art. 21 §2(a)(e)(f)(i) |
| **RGPD / CNIL** | Art. 5(1)(c)(e), Art. 25, Art. 28 (SaaS sub-processors), Art. 30 |

Full mapping: [`REGULATORY-MAPPING.md`](./REGULATORY-MAPPING.md)

---

## 📊 Lab Metrics

| Indicator | Value |
|---|---|
| Phases | 6 + OCM transverse |
| Scripts / tools (new) | 9 |
| Scripts (cross-reference) | 6 |
| OCM deliverables | 7 |
| Simulated AD accounts (CorpB) | 312 |
| Simulated SaaS applications | 8 |
| Wiki pages | 12 |
| Regulatory frameworks | 3 |

---

## 🚀 Getting Started

```powershell
# Step 1 — Clone the repo
git clone https://github.com/CrepuSkull/iam-ma-integration-lab.git
cd iam-ma-integration-lab

# Step 2 — Read context documents first (recommended)
# SCENARIO.md             → understand the M&A narrative
# ocm/OCM-Framework.md   → understand the change management posture

# Step 3 — Run Phase 0 (before any script)
cd phase0-preparation
# Follow README-phase0.md
# Complete stakeholder matrix + SaaS inventory before proceeding

# Step 4 — Generate fictitious CorpB environment (lab only)
cd ..\seed
.\Seed-CorpB-AD.ps1 -DryRun

# Step 5 — Proceed phase by phase
# Each phase README contains detailed instructions + its OCM counterpart reference
```

---

## 📁 Part of the IAM-Lab Framework

```
IAM-Lab Framework (6 repos)
├── iam-foundation-lab          AD audit → Entra ID migration → Federation
├── IAM-Lab-Identity-Lifecycle  JML automation, RBAC, LDIF
├── iam-governance-lab          Periodic controls, recertification, scored audit
├── iam-evidence-sealer         Cryptographic sealing (SHA-256, X.509, RFC 3161)
├── iam-federation-lab          Hybrid federation audit & remediation
└── iam-ma-integration-lab  ◀   M&A identity integration (this repo)
```

---

## ⚠️ Disclaimer

> Scripts marked `démonstration/test uniquement` use self-signed certificates.
> These do not carry legal probative value. For regulatory-grade evidence,
> use a commercial CA with RFC 3161 timestamping as documented in
> [`iam-evidence-sealer`](https://github.com/CrepuSkull/iam-evidence-sealer).

---

*IAM-Lab Framework — Open source, reproducible, documented.*
*Author: [Arnaud Montcho](https://github.com/CrepuSkull) — IAM/IGA Consultant*
