# Repository Refactor Plan (Sprint 3.5A)

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: APPROVED & COMPLETE  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Objective

The objective of this refactor is to normalize the repository structure by cleaning the root directory of all temporary, analytical, and audit files generated during the Sprint 3.0 SNR engine implementation. This ensures long-term maintainability and allows a future AI agent to recover project state in less than 2 minutes while preserving 100% of project history and evidence.

---

## 2. Final Repository Tree

The refactored workspace is structured as follows:

```
c:\xauusd_chatgpt\ (Root)
├── .gitignore                          ← Git configuration
├── AGENT_CONSTITUTION.md               ← Permanent operating law
├── CURRENT_PROJECT_STATE.md            ← Authoritative project status entrypoint
├── MILESTONE_GENESIS_FREEZE.md         ← Milestone snapshot of Genesis freeze
├── MILESTONE_SPRINT_3_FREEZE.md        ← Current frozen-state snapshot (Sprint 3)
├── PROJECT_GENESIS.md                  ← Project history & single source of truth
├── PROJECT_RECOVERY_PROTOCOL.md        ← Onboarding procedure
├── README.md                           ← Main GitHub entry point
├── RECOVERY_ENTRYPOINT.md              ← Recovery entry point for AI agents
├── SYSTEM_ROADMAP.md                   ← Development roadmap
│
├── docs/
│   ├── archive/                        ← Historical/superseded documents
│   │   ├── ARTICLE.md
│   │   ├── SPRINT_3_EXECUTION_PLAN.md
│   │   ├── SNR_DATA_FLOW.md
│   │   ├── SNR_ENGINE_DESIGN.md
│   │   ├── SNR_SCORING_MODEL.md
│   │   ├── STRUCTURE_ENGINE_EVIDENCE_REPORT.md
│   │   ├── STRUCTURE_ENGINE_FINAL_VALIDATION.md
│   │   ├── structure_engine_audit.md
│   │   ├── SUPPLY_DEMAND_AUDIT.md
│   │   ├── SUPPLY_DEMAND_STATISTICAL_REPORT.md
│   │   ├── SUPPLY_DEMAND_VALIDATION.md
│   │   ├── SUPPLY_DEMAND_VERIFICATION_REPORT.md
│   │   └── note_for_user.md
│   │
│   ├── audits/                         ← Audit reports
│   │   ├── AGENT_CONSTITUTION_AUDIT.md
│   │   ├── GENESIS_COMPLETENESS_AUDIT.md
│   │   ├── LESSONS_LEARNED_AUDIT.md
│   │   ├── RECOVERY_ALIGNMENT_AUDIT.md
│   │   ├── REPOSITORY_NORMALIZATION_AUDIT.md
│   │   ├── REREPOSITORY_ARCHITECTURE_AUDIT.md
│   │   ├── REPOSITORY_REFACTOR_EXECUTION_REPORT.md
│   │   ├── SNR_COMPILE_AUDIT.md
│   │   ├── SNR_DESIGN_AUDIT.md
│   │   ├── SNR_ENGINE_V10_AUDIT.md
│   │   ├── SNR_OUTPUT_OPTIMIZATION_AUDIT.md
│   │   ├── SNR_SCORE_VALIDATION_AUDIT.md
│   │   ├── SNR_VISUAL_USABILITY_AUDIT.md
│   │   ├── SPRINT_3_CHECKPOINT_AUDIT.md
│   │   ├── SPRINT_3_RECOVERY_AUDIT.md
│   │   ├── STRUCTURE_ENGINE_V22_AUDIT.md
│   │   ├── SUPPLY_DEMAND_CONSISTENCY_AUDIT.md
│   │   ├── SUPPLY_DEMAND_V11_AUDIT.md
│   │   ├── TESTSNR_COMPILE_AUDIT.md
-------------
│   │   ├── TOP_N_AUDIT_EVIDENCE.md
│   │   └── TOP_N_OPTIMALITY_AUDIT.md
│   │
│   ├── core/                           ← Core documentation & memory
│   │   ├── 01_MARKET_DEFINITIONS.md
│   │   ├── 02_SYSTEM_ARCHITECTURE.md
│   │   ├── 03_CODING_RULES.md
│   │   ├── 04_DESIGN_DECISIONS.md
│   │   ├── 05_CURRENT_STATUS.md
│   │   ├── 08_AGENT_ONBOARDING.md
│   │   ├── LESSONS_LEARNED.md
│   │   ├── PROJECT_MEMORY.md
│   │   ├── PROJECT_STATE_REVIEW.md
│   │   └── SPRINT_3_RISK_REGISTER.md
│   │
│   ├── design/                         ← Frozen specifications & plans
│   │   ├── REPOSITORY_REFACTOR_PLAN.md
│   │   ├── SNR_ARCHITECTURE_FREEZE.md
│   │   ├── SNR_VISUAL_SPEC.md
│   │   ├── SPRINT_3_4_IMPLEMENTATION_PLAN.md
│   │   └── SUPPLY_DEMAND_DESIGN.md
│   │
│   └── reports/                        ← Validation and statistical reports
│       ├── RECOVERY_REPORT.md
│       ├── RECOVERY_VALIDATION.md
│       ├── SNR_OUTCOME_VALIDATION_REPORT.md
│       ├── SNR_STATISTICAL_REPORT.md
│       ├── SNR_VISUAL_VALIDATION_REPORT.md
│       ├── UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md
│       └── top_n_raw_metrics.csv
│
└── src/                                ← Trading engine source code & tests (UNCHANGED)
    ├── engines/
    │   ├── SnrEngine.mqh
    │   ├── SnrPriorityEngine.mqh
    │   ├── StructureEngine.mqh
    │   └── SupplyDemandEngine.mqh
    └── tests/
        ├── TestSnr.ex5
        ├── TestSnr.mq5
        ├── TestStructure.mq5
        └── TestSupplyDemand.mq5
```

---

## 3. Migration Details

### Revisions Approved by Project Owner
1. **`MILESTONE_GENESIS_FREEZE.md`** was retained in the root directory as permanent baseline documentation.
2. **`RECOVERY_REPORT.md`** was moved to `docs/reports/` to keep root strictly for landing entrypoints.
3. **`SPRINT_3_RISK_REGISTER.md`** was reclassified as core project documentation and moved to `docs/core/`.
4. **`CURRENT_PROJECT_STATE.md`** was created at root as the single authoritative project status entrypoint.
5. **`note for user.md`** was renamed to `note_for_user.md` inside `docs/archive/` to standardize the naming convention.

---

## 4. Link & Import Updates

All relative markdown links and absolute links referencing the moved files were updated dynamically. No include files in `/src/` required modification as the engine and test source code hierarchy was not altered.
All tests were compiled using `copy_and_compile.ps1` to verify path integrity, returning 0 errors and 0 warnings.
