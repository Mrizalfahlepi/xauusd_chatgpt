# Repository Refactor Plan

**Author**: Market Structure & Architecture Auditor  
**Date**: June 12, 2026  
**Status**: DRAFT PLAN (No files moved yet)  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Proposed Folder Structure

To clean up the repository root and isolate source code from documentation and testing scripts, the following unified directory tree is proposed:

```
/xauusd_chatgpt
├── .git/
├── .gitignore
├── REPOSITORY_ARCHITECTURE_AUDIT.md
├── REPOSITORY_REFACTOR_PLAN.md
├── docs/
│   ├── core/           # General specifications and system rules
│   ├── design/         # Module-specific design files (frozen specs)
│   ├── audits/         # Authoritative code audits and audits of design phases
│   ├── reports/        # Backtest statistics and analytical reports
│   └── archive/        # Superseded, temporary, and historical validation files
├── src/
│   ├── engines/        # Production MQL5 source code (.mqh files)
│   └── tests/          # Chart validation EAs (.mq5 files)
```

---

## 2. File Migration Map

The table below defines the exact relocation paths for every file in the repository. As per architectural instructions, **no file moves or deletions will be executed during this freeze stage**.

| Current Path | Proposed Relocated Path | Classification |
| :--- | :--- | :---: |
| `/.gitignore` | `/.gitignore` (No Change) | **FINAL** |
| `/REPOSITORY_ARCHITECTURE_AUDIT.md` | `/REPOSITORY_ARCHITECTURE_AUDIT.md` (No Change) | **FINAL** |
| `/REPOSITORY_REFACTOR_PLAN.md` | `/REPOSITORY_REFACTOR_PLAN.md` (No Change) | **FINAL** |
| `/01_MARKET_DEFINITIONS.md` | `/docs/core/01_MARKET_DEFINITIONS.md` | **FINAL** |
| `/02_SYSTEM_ARCHITECTURE.md` | `/docs/core/02_SYSTEM_ARCHITECTURE.md` | **FINAL** |
| `/03_CODING_RULES.md` | `/docs/core/03_CODING_RULES.md` | **FINAL** |
| `/04_DESIGN_DECISIONS.md` | `/docs/core/04_DESIGN_DECISIONS.md` | **FINAL** |
| `/05_CURRENT_STATUS.md` | `/docs/core/05_CURRENT_STATUS.md` | **FINAL** |
| `/08_AGENT_ONBOARDING.md` | `/docs/core/08_AGENT_ONBOARDING.md` | **FINAL** |
| `/PROJECT_MEMORY.md` | `/docs/core/PROJECT_MEMORY.md` | **FINAL** |
| `/PROJECT_STATE_REVIEW.md` | `/docs/core/PROJECT_STATE_REVIEW.md` | **FINAL** |
| `/SUPPLY_DEMAND_DESIGN.md` | `/docs/design/SUPPLY_DEMAND_DESIGN.md` | **FINAL** |
| `/SNR_ENGINE_DESIGN.md` | `/docs/archive/SNR_ENGINE_DESIGN.md` | **SUPERSEDED** |
| `/SNR_SCORING_MODEL.md` | `/docs/archive/SNR_SCORING_MODEL.md` | **SUPERSEDED** |
| `/SNR_DATA_FLOW.md` | `/docs/archive/SNR_DATA_FLOW.md` | **SUPERSEDED** |
| `/SNR_ARCHITECTURE_FREEZE.md` (To Be Created) | `/docs/design/SNR_ARCHITECTURE_FREEZE.md` | **ACTIVE DESIGN** |
| `/STRUCTURE_ENGINE_V22_AUDIT.md` | `/docs/audits/STRUCTURE_ENGINE_V22_AUDIT.md` | **FINAL** |
| `/SUPPLY_DEMAND_V11_AUDIT.md` | `/docs/audits/SUPPLY_DEMAND_V11_AUDIT.md` | **FINAL** |
| `/SUPPLY_DEMAND_CONSISTENCY_AUDIT.md` | `/docs/audits/SUPPLY_DEMAND_CONSISTENCY_AUDIT.md` | **FINAL** |
| `/SNR_DESIGN_AUDIT.md` | `/docs/audits/SNR_DESIGN_AUDIT.md` | **FINAL** |
| `/structure_engine_audit.md` | `/docs/archive/structure_engine_audit.md` | **SUPERSEDED** |
| `/SUPPLY_DEMAND_AUDIT.md` | `/docs/archive/SUPPLY_DEMAND_AUDIT.md` | **SUPERSEDED** |
| `/SUPPLY_DEMAND_STATISTICAL_REPORT.md` | `/docs/archive/SUPPLY_DEMAND_STATISTICAL_REPORT.md` | **SUPERSEDED** |
| `/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md` | `/docs/reports/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md` | **FINAL** |
| `/STRUCTURE_ENGINE_EVIDENCE_REPORT.md` | `/docs/archive/STRUCTURE_ENGINE_EVIDENCE_REPORT.md` | **TEMPORARY** |
| `/STRUCTURE_ENGINE_FINAL_VALIDATION.md` | `/docs/archive/STRUCTURE_ENGINE_FINAL_VALIDATION.md` | **ARCHIVE** |
| `/SUPPLY_DEMAND_VALIDATION.md` | `/docs/archive/SUPPLY_DEMAND_VALIDATION.md` | **ARCHIVE** |
| `/SUPPLY_DEMAND_VERIFICATION_REPORT.md` | `/docs/archive/SUPPLY_DEMAND_VERIFICATION_REPORT.md` | **ARCHIVE** |
| `/StructureEngine.mqh` | `/src/engines/StructureEngine.mqh` | **ACTIVE ENGINE** |
| `/SupplyDemandEngine.mqh` | `/src/engines/SupplyDemandEngine.mqh` | **ACTIVE ENGINE** |
| `/TestStructure.mq5` | `/src/tests/TestStructure.mq5` | **ACTIVE ENGINE** |
| `/TestSupplyDemand.mq5` | `/src/tests/TestSupplyDemand.mq5` | **ACTIVE ENGINE** |

---

## 3. Execution Requirements

1.  **Refactor Timing**: Refactoring must take place **after** Sprint 2.3 is approved and before *any* Sprint 3.0 MQL5 source files are initialized.
2.  **Includes Updates**: When files are moved to their respective folders, the `#include` statements in validation EAs must be adjusted:
    *   `/src/tests/TestStructure.mq5` will update `#include "StructureEngine.mqh"` to `#include "../engines/StructureEngine.mqh"`.
    *   `/src/tests/TestSupplyDemand.mq5` will update `#include "SupplyDemandEngine.mqh"` to `#include "../engines/SupplyDemandEngine.mqh"`.
    *   `/src/engines/SupplyDemandEngine.mqh` will update `#include "StructureEngine.mqh"` to `#include "StructureEngine.mqh"` (since both remain in the same `/src/engines/` directory, no relative path change is needed between them).
