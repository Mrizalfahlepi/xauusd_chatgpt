# RECOVERY REPORT

**Agent**: Antigravity (Claude Opus 4.6)  
**Date**: June 12, 2026  
**Recovery Procedure**: Executed per [README.md](README.md) instructions  
**Status**: RECOVERY COMPLETE — AWAITING OWNER APPROVAL

---

## 1. Project Mission

Build and deploy an **institutional-grade, fully automated trading system** for Gold (`XAUUSD`/`XAUUSDm`) on MetaTrader 5 using MQL5.

The system eliminates emotional bias and lagging retail indicators by mapping price action through **institutional order blocks**, **structural swing points**, **support/resistance clustering**, and **liquidity pools** — aligning execution with market makers and liquidity providers rather than against them.

**Rejected approaches**: RSI, MACD, Stochastic (as primary entries), Martingale, Grid, Averaging Down, Recovery Systems.

---

## 2. Project Vision

A fully automated portfolio execution system comprising **8 decoupled engine modules** operating on a **unidirectional data pipeline**:

```
[Module 1] StructureEngine (H4)         ← FROZEN v2.2 ✅
     │  Fractal swings, BOS/MSS, Trend classification
     ▼
[Module 2] SupplyDemandEngine (H4)      ← FROZEN v1.1 ✅
     │  Base-impulse consolidation blocks, Zone quality grading
     ▼
[Module 3] SnrEngine (H4)              ← DESIGN FROZEN, CODE NEXT 🎯
     │  ATR-relative clustering, Neutral node deactivation, 5-weight scoring
     ▼
[Module 4] LiquidityEngine (H4/M30)    ← PLANNED
     │  Buy/sell stop liquidity pools above/below swing clusters
     ▼
[Module 5] EntryEngine (M30)           ← PLANNED
     │  H4 bias refinement, entry setup validation, limit/market orders
     ▼
[Module 6] RiskEngine (M30)            ← PLANNED
     │  Dynamic lot sizing (1% fixed risk per trade)
     ▼
[Module 7] PortfolioEngine (M30)       ← PLANNED
     │  Trailing stops, break-evens, partial profits, news filters
     ▼
[Module 8] Live Deployment             ← PLANNED
     │  Forward test validation, latency verification
```

---

## 3. Architecture Summary

### Completed & Frozen Engines

| Engine | Version | Status | Key Features |
|--------|---------|--------|-------------|
| **StructureEngine** | v2.2 | 🔒 FROZEN | Lookback N=3 fractal swing detection, ATR distance grading, non-repainting BOS/MSS, consecutive trend classification, local sync ATR(14) |
| **SupplyDemandEngine** | v1.1 | 🔒 FROZEN | Impulse-base-displacement logic (1-6 base candles), H4 close invalidation, retest scanner excluding breach bar, linear age decay |

### Validated Statistics (4-year backtest 2022-2025)

| Metric | Value |
|--------|-------|
| Total Zones Created | 246 |
| Supply / Demand Ratio | 124 (50.4%) / 122 (49.6%) |
| Invalidated Zones | 176 (71.5%) |
| Active Zones | 70 (28.5%) |
| True False Positive Rate | **2.27%** |
| Retest Reliability (Win Rate) | **97.73%** |
| Average Zone Lifetime | 124.73 H4 bars (~20.8 days) |
| Average Reactions per Zone | 2.82 |

### Design Frozen (Not Yet Coded)

| Specification | Status | File |
|---------------|--------|------|
| SNR Engine v1.0 Architecture | 🔒 DESIGN FROZEN | [SNR_ARCHITECTURE_FREEZE.md](docs/design/SNR_ARCHITECTURE_FREEZE.md) |

### Unidirectional Data Flow Rule

```
Structure → Supply Demand → SNR → Entry → Risk → Execution
```

Downstream engines consume upstream outputs via **read-only public accessors** (`GetZone()`, `GetMajorHigh()`, etc.). No module may modify an upstream module's data. Each engine computes ATR(14) **locally and synchronously** to avoid MT5 tester sync issues.

---

## 4. Repository Structure

### Actual Repository Tree (Verified June 12, 2026)

```
c:\xauusd_chatgpt\
│
├── ROOT ENTRYPOINTS (Permanent)
│   ├── PROJECT_GENESIS.md              ← Master project bible (Source of Truth #1)
│   ├── AGENT_CONSTITUTION.md           ← Operating law
│   ├── MILESTONE_GENESIS_FREEZE.md     ← State snapshot
│   ├── PROJECT_RECOVERY_PROTOCOL.md    ← Onboarding procedure
│   ├── SYSTEM_ROADMAP.md               ← Phase-by-phase development plan
│   └── README.md                       ← GitHub entry point
│
├── ROOT (Residual — should be relocated)
│   ├── REPOSITORY_NORMALIZATION_AUDIT.md  ← Should be in docs/audits/
│   └── note for user.md                   ← Temporary file, needs classification
│
├── docs/
│   ├── archive/          (10 files — superseded/historical reports)
│   ├── audits/           (8 files — code reviews, consistency audits)
│   ├── core/             (8 files — definitions, architecture, onboarding)
│   ├── design/           (3 files — frozen specs, refactor plan)
│   └── reports/          (1 file — updated statistical report)
│
├── src/
│   ├── engines/
│   │   ├── StructureEngine.mqh       (51,282 bytes) [FROZEN v2.2]
│   │   └── SupplyDemandEngine.mqh    (17,284 bytes) [FROZEN v1.1]
│   └── tests/
│       ├── TestStructure.mq5         (27,014 bytes)
│       └── TestSupplyDemand.mq5      (13,435 bytes)
│
└── .gitignore
```

### Discrepancies vs. MILESTONE_GENESIS_FREEZE.md

| Finding | Detail | Severity |
|---------|--------|----------|
| `REPOSITORY_NORMALIZATION_AUDIT.md` at root | Should be in `docs/audits/` per normalization rules | LOW — cosmetic |
| `note for user.md` at root | Not classified in any milestone document | LOW — needs classification |
| `Readme.txt` deleted locally | Was committed but locally deleted; `README.md` replaces it | LOW — intentional supersession |
| Audit files relocated to `docs/audits/` | `GENESIS_COMPLETENESS_AUDIT.md`, `REPOSITORY_ARCHITECTURE_AUDIT.md`, `REPOSITORY_REFACTOR_EXECUTION_REPORT.md` moved from root since milestone freeze | NONE — correct normalization |
| `REPOSITORY_REFACTOR_PLAN.md` in `docs/design/` | Was at root in milestone tree, correctly relocated | NONE — correct normalization |

---

## 5. Frozen Components

### Code Frozen (Must Not Be Modified)

| Component | Version | File | Freeze Condition |
|-----------|---------|------|-----------------|
| Market Structure Engine | v2.2 | [StructureEngine.mqh](src/engines/StructureEngine.mqh) | Production-ready, 4-year backtest validated |
| Supply & Demand Engine | v1.1 | [SupplyDemandEngine.mqh](src/engines/SupplyDemandEngine.mqh) | Production-ready, 97.73% retest reliability validated |

### Design Frozen (Specification Locked)

| Specification | File |
|---------------|------|
| SNR Engine Architecture v1.0 | [SNR_ARCHITECTURE_FREEZE.md](docs/design/SNR_ARCHITECTURE_FREEZE.md) |

### Freeze-Break Conditions (Per AGENT_CONSTITUTION §4.1)

A frozen module may **only** be modified if:
1. A critical defect is **mathematically proven** with Strategy Tester log traces
2. An audit plan is **drafted and approved** by the project owner
3. Changes are **isolated to the proven defect** only
4. A **full 4-year revalidation backtest** (2022-2025) confirms zero regression

---

## 6. Current Sprint

| Sprint | Status | Description |
|--------|--------|-------------|
| Sprint 1.0 | ✅ COMPLETE | StructureEngine v1.0 baseline |
| Sprint 2.0 | ✅ COMPLETE | StructureEngine v2.2 (all bugs fixed, frozen) |
| Sprint 2.1 | ✅ COMPLETE | SupplyDemandEngine v1.0 → v1.1 (age decay + reaction fixes) |
| Sprint 2.2 | ✅ COMPLETE | Supply/Demand statistical hotfix & revalidation |
| Sprint 2.3 | ✅ COMPLETE | Repository refactoring & documentation freeze |
| **Sprint 3.0** | 🎯 **NEXT** | **SNR Engine Implementation** |

### Sprint 3.0 Target

- **Deliverables**: `src/engines/SnrEngine.mqh` + `src/tests/TestSnr.mq5`
- **Specification**: [SNR_ARCHITECTURE_FREEZE.md](docs/design/SNR_ARCHITECTURE_FREEZE.md) (FROZEN)
- **Core features**:
  - Ascending pre-sorting of projected levels
  - ATR-relative clustering (0.25 × ATR tolerance, capped at 1.50 × ATR width)
  - ≥ 50% height overlap zone merging with 20% new-volume freshness reset
  - Neutral consolidation node handling (Supply vs. Demand overlap → deactivate)
  - Nested zone flags (Core vs. Macro)
  - 5-weight scoring formula: W_Struct=0.20, W_SD=0.30, W_Fresh=0.20, W_Reject=0.20, W_Confl=0.10
  - Liquidity pool mapping (buy/sell stops above/below swing clusters)

---

## 7. Current Development Status

| Aspect | Status |
|--------|--------|
| **Git Branch** | `main` (up to date with `origin/main`) |
| **Working Tree** | Clean (1 deleted file: `Readme.txt` — superseded by `README.md`) |
| **Total Commits** | 7 |
| **Source Code** | 2 frozen engines + 2 test EAs, all previously compiler-verified |
| **Documentation** | 30+ documents organized in `/docs/` hierarchy |
| **Frozen Milestone** | All engines frozen, all audits passed |
| **Recovery Documents** | Complete (Genesis, Constitution, Milestone, Recovery Protocol, Roadmap) |
| **SNR Design** | FROZEN — ready for Sprint 3.0 implementation |

### 7 Resolved Critical Bugs (All Fixed in Frozen Engines)

1. ✅ Trend classification locked to BULLISH → consecutive checking fix
2. ✅ BOS/MSS repainting on Bar 0 → gated to completed bars only
3. ✅ Swing reaction score leak → terminate at breakBarIndex
4. ✅ Reaction inflation during consolidation → insideZone state tracker
5. ✅ MT5 Strategy Tester ATR sync error → local synchronous ATR
6. ✅ S/D age score decay defect → reversed subtraction order
7. ✅ S/D invalidation bar reaction inflation → excluded breach candle

---

## 8. Next Recommended Action

### Immediate (Before Sprint 3.0 Coding)

1. **Clean root directory**: Move `REPOSITORY_NORMALIZATION_AUDIT.md` to `docs/audits/` and classify `note for user.md`
2. **Stage the deleted `Readme.txt`**: Either restore it or commit the deletion (currently unstaged)
3. **Verify compilation**: Run the copy-and-compile script to confirm `StructureEngine.mqh` and `SupplyDemandEngine.mqh` compile with 0 errors/0 warnings in current MetaEditor
4. **Obtain owner approval** on this Recovery Report

### Sprint 3.0 Execution (After Approval)

1. Create feature branch: `git checkout -b feature/snr-engine`
2. Implement `src/engines/SnrEngine.mqh` per [SNR_ARCHITECTURE_FREEZE.md](docs/design/SNR_ARCHITECTURE_FREEZE.md)
3. Create `src/tests/TestSnr.mq5` validator EA
4. Compile check (0 errors, 0 warnings)
5. Run 4-year backtest (2022-2025, XAUUSD H4)
6. Parse logs and validate SNR scoring metrics
7. Write SNR validation audit document
8. Update PROJECT_MEMORY.md
9. Commit, push, and freeze

---

## 9. Open Risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| 1 | **Redundant Price History Scanning** — Structure, S/D, and SNR all perform separate historical loops. On every tick, Strategy Tester performance will degrade. | HIGH | Gate engine logic strictly by new H4 bar closes; cache coordinates to avoid duplicate scanning |
| 2 | **ATR Volatility Compression** — During tight consolidations, ATR shrinks, causing noise to be classified as Major swings | MEDIUM | Establish absolute minimum ATR floor (e.g. 50 pips) in StructureEngine |
| 3 | **Order-Dependence in Clustering** — If levels are not pre-sorted before ATR projection, clustering boundaries will be inconsistent | MEDIUM | Mandate price-ascending sorting prior to clustering loop (specified in design freeze) |
| 4 | **Independent High/Low Array Alignment** — Major highs and lows in separate arrays; multiple consecutive Major Highs without intervening Major Low may cause label misalignment | LOW | Monitor during SNR integration testing |
| 5 | **Dead Code (iATR handle)** — Unused `m_atrHandle` in StructureEngine from pre-refactor era | LOW | Technical debt; do not modify frozen engine unless critical defect |
| 6 | **Hardcoded Version String** — TestStructure.mq5 prints "v2.1" instead of "v2.2" | LOW | Cosmetic; do not modify frozen test unless approved |
| 7 | **Root Directory Residuals** — `REPOSITORY_NORMALIZATION_AUDIT.md` and `note for user.md` still at root | LOW | Relocate before Sprint 3.0 |

---

## 10. Recovery Confidence

### **95%** ✅

| Dimension | Confidence | Notes |
|-----------|-----------|-------|
| **WHY** the project exists | 100% | Eliminate retail indicator lag; align with institutional order flow |
| **WHAT** has been completed | 100% | Structure v2.2 + SupplyDemand v1.1 frozen, all audits passed |
| **WHAT** is frozen | 100% | Two engines + SNR design spec, with clear freeze-break conditions |
| **WHAT** must never be modified | 100% | Frozen engines, data flow direction, rejected concepts |
| **WHERE** the project stands | 95% | Clear: Sprint 2.3 complete, Sprint 3.0 next. Minor root cleanup pending |
| **WHAT** the next sprint should be | 100% | Sprint 3.0: SNR Engine Implementation per frozen architecture spec |

**Deduction (-5%)**: Cannot independently verify compilation status without running MetaEditor. Two minor root directory discrepancies exist vs. the normalized standard.

---

## Documents Read During Recovery

| # | Document | Path | Status |
|---|----------|------|--------|
| 1 | README.md | Root | ✅ Read |
| 2 | PROJECT_GENESIS.md | Root | ✅ Read (Mandatory #1) |
| 3 | AGENT_CONSTITUTION.md | Root | ✅ Read (Mandatory #2) |
| 4 | MILESTONE_GENESIS_FREEZE.md | Root | ✅ Read (Mandatory #3) |
| 5 | PROJECT_RECOVERY_PROTOCOL.md | Root | ✅ Read |
| 6 | SYSTEM_ROADMAP.md | Root | ✅ Read |
| 7 | PROJECT_MEMORY.md | docs/core/ | ✅ Read |
| 8 | PROJECT_STATE_REVIEW.md | docs/core/ | ✅ Read |
| 9 | SNR_ARCHITECTURE_FREEZE.md | docs/design/ | ✅ Read |

### Verification Actions Performed

- ✅ Git status checked (branch: main, up to date with origin)
- ✅ Git history reviewed (7 commits)
- ✅ Full file tree enumerated and compared against milestone freeze
- ✅ Source code file sizes verified (engines and tests present)
- ✅ Repository discrepancies identified and documented

---

> **RECOVERY COMPLETE**
>
> This agent has read all mandatory documents, understood the project architecture, identified frozen components, confirmed the current sprint position, and documented all open risks.
>
> **Awaiting project owner approval before any implementation work begins.**
