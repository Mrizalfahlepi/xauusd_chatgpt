# XAUUSD PROJECT RECOVERY ENTRYPOINT

---

## 📋 READ FIRST (MANDATORY ORDER)

1. **[PROJECT_GENESIS.md](PROJECT_GENESIS.md)**
2. **[AGENT_CONSTITUTION.md](AGENT_CONSTITUTION.md)**
3. **[MILESTONE_GENESIS_FREEZE.md](MILESTONE_GENESIS_FREEZE.md)**

> [!CAUTION]
> **DO NOT SKIP.**
> These documents are the official **Source of Truth**.
> Chat history is **NOT** a source of truth.

---

## 🚫 FIRST TASK

Your first responsibility is **NOT coding**.

Your first responsibility is **understanding**.

**Do NOT:**

- ❌ Write code
- ❌ Modify code
- ❌ Modify engines
- ❌ Modify documentation
- ❌ Move files
- ❌ Create architecture changes

**...until recovery is completed.**

---

## ✅ RECOVERY VALIDATION

After reading all documents, create:

**`RECOVERY_REPORT.md`**

The report must contain:

| # | Section |
|---|---------|
| 1 | Project Mission |
| 2 | Project Vision |
| 3 | Current Architecture |
| 4 | Repository Structure |
| 5 | Frozen Components |
| 6 | Current Sprint |
| 7 | Current Development Status |
| 8 | Next Recommended Action |
| 9 | Open Risks |
| 10 | Recovery Confidence (%) |

---

## 🎯 SUCCESS CONDITION

Recovery is considered successful **only** if the agent can explain:

- ✅ **WHY** the project exists
- ✅ **WHAT** has already been completed
- ✅ **WHAT** is frozen
- ✅ **WHAT** must never be modified
- ✅ **WHERE** the project currently stands
- ✅ **WHAT** the next sprint should be

> [!IMPORTANT]
> **Only after recovery is approved may implementation begin.**

---

## 📁 Repository Structure

```
ROOT/
├── PROJECT_GENESIS.md              ← Project history & single source of truth
├── AGENT_CONSTITUTION.md           ← Permanent operating law
├── CURRENT_PROJECT_STATE.md        ← Authoritative project status entrypoint
├── MILESTONE_GENESIS_FREEZE.md     ← Genesis milestone state snapshot
├── MILESTONE_SPRINT_3_FREEZE.md    ← Sprint 3 milestone state snapshot
├── PROJECT_RECOVERY_PROTOCOL.md    ← Onboarding procedure
├── SYSTEM_ROADMAP.md               ← Development roadmap
├── README.md                       ← Main GitHub landing page
├── RECOVERY_ENTRYPOINT.md          ← AI Agent Recovery entry point
│
├── docs/
│   ├── core/                       ← Core documentation (Lessons Learned, Risk Register)
│   ├── design/                     ← Design specs (SNR specification, Visual specification)
│   ├── audits/                     ← Audit reports
│   ├── reports/                    ← Analysis and Validation reports (RECOVERY_REPORT.md)
│   └── archive/                    ← Historical/superseded docs (ARTICLE.md, note_for_user.md)
│
└── src/
    ├── engines/                    ← Trading engine source code (Structure, SupplyDemand, SNR)
    └── tests/                      ← Test scripts (TestStructure, TestSupplyDemand, TestSnr)
```

---

## 📌 Key Documents

| Document | Purpose | Location |
|----------|---------|----------|
| [PROJECT_GENESIS.md](PROJECT_GENESIS.md) | Complete project history | Root |
| [AGENT_CONSTITUTION.md](AGENT_CONSTITUTION.md) | Operating rules & constraints | Root |
| [CURRENT_PROJECT_STATE.md](CURRENT_PROJECT_STATE.md) | Current project status & phase | Root |
| [MILESTONE_GENESIS_FREEZE.md](MILESTONE_GENESIS_FREEZE.md) | Genesis baseline snapshot | Root |
| [MILESTONE_SPRINT_3_FREEZE.md](MILESTONE_SPRINT_3_FREEZE.md) | Sprint 3 baseline snapshot | Root |
| [PROJECT_RECOVERY_PROTOCOL.md](PROJECT_RECOVERY_PROTOCOL.md) | Onboarding steps | Root |
| [SYSTEM_ROADMAP.md](SYSTEM_ROADMAP.md) | Development plan | Root |
| [RECOVERY_REPORT.md](docs/reports/RECOVERY_REPORT.md) | Recovery verification report | `docs/reports/` |
