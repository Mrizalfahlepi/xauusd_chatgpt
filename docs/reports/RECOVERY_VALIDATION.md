# RECOVERY VALIDATION

**Agent**: Antigravity (Claude Opus 4.6)  
**Date**: June 12, 2026  
**Procedure**: Full recovery per README.md → all 7 mandatory documents read  
**Status**: VALIDATION COMPLETE — AWAITING OWNER APPROVAL

---

## 1. Project Mission

Build and deploy an **institutional-grade, fully automated Expert Advisor** for Gold (`XAUUSD`/`XAUUSDm`) on MetaTrader 5.

The system reads price action through institutional market structure — not lagging retail indicators. It maps **order block zones**, **structural swing points**, **support/resistance clusters**, and **liquidity pools** to align execution with market makers and liquidity providers.

**Core philosophy**: Market Structure → Supply Demand → SNR → Entry → Risk → Execution.

**Permanently rejected**: RSI, MACD, Stochastic (as primary entries), Martingale, Grid, Averaging Down, Recovery Systems.

---

## 2. End Goal

A fully automated portfolio execution system comprising **8 decoupled engine modules** operating on a **unidirectional data pipeline**:

```
[Module 1] StructureEngine (H4)
     │  Fractal swing detection (N=3), ATR grading, non-repainting BOS/MSS, trend classification
     │  Status: ✅ FROZEN v2.2
     ▼
[Module 2] SupplyDemandEngine (H4)
     │  Impulse-base-displacement zones (1-6 base candles), zone scoring, age decay
     │  Status: ✅ FROZEN v1.1
     ▼
[Module 3] SnrEngine (H4)
     │  ATR-relative clustering, neutral node deactivation, 5-weight scoring (0-100)
     │  Status: 🎯 DESIGN FROZEN — NEXT TO BUILD
     ▼
[Module 4] LiquidityEngine (H4/M30)
     │  Buy/sell stop liquidity pools above/below swing clusters
     │  Status: 📋 PLANNED
     ▼
[Module 5] EntryEngine (M30)
     │  H4 bias refinement, M30 trigger validation, limit/market order execution
     │  Status: 📋 PLANNED
     ▼
[Module 6] RiskEngine (M30)
     │  Dynamic lot sizing (1% fixed risk per trade)
     │  Status: 📋 PLANNED
     ▼
[Module 7] PortfolioEngine (M30)
     │  Trailing stops, break-evens, partial profits, news filters
     │  Status: 📋 PLANNED
     ▼
[Module 8] Live Deployment
     │  Forward testing on demo/live, latency verification, max drawdown ≤ 10%
     │  Status: 📋 PLANNED
```

**Final destination**: A single production `.mq5` Expert Advisor validated for live broker feeds.

---

## 3. Full System Roadmap

| Phase | Module | Purpose | Inputs | Outputs | Dependencies | Status |
|-------|--------|---------|--------|---------|-------------|--------|
| 1 | StructureEngine | Fractal swing detection, BOS/MSS, trend | Raw H4 OHLCT | Graded swings, BOS, MSS, trend, ATR | None | 🔒 FROZEN v2.2 |
| 2 | SupplyDemandEngine | Order block zone detection, scoring | Structure outputs, H4 data | Zone structs (boundaries, reactions, scores) | Module 1 | 🔒 FROZEN v1.1 |
| 3 | SnrEngine | S/R clustering, conflict resolution, scoring | Swings, zones, local ATR | `SNRLevel[]` sorted by score | Modules 1, 2 | 🎯 NEXT (Sprint 3.0) |
| 4 | LiquidityEngine | Stop-loss cluster mapping, sweep detection | Major swings, H4 data, ATR | `LiquidityPool[]` | Module 1 | 📋 PLANNED |
| 5 | EntryEngine | M30 trigger validation, order execution | SNR levels, H4 trend, M30 data | Trade signal coordinates | Modules 3, 4 | 📋 PLANNED |
| 6 | RiskEngine | Position sizing | Account balance, risk %, SL distance | Lot size | Module 5 | 📋 PLANNED |
| 7 | PortfolioEngine | Trade management | Positions, news calendar, ticks | SL/TP modifications, partial closes | Module 6 | 📋 PLANNED |
| 8 | Live Validation | Forward testing | Integrated EA, live feeds | Performance audits, equity curves | All modules | 📋 PLANNED |

**Mandatory sequential order**: No module may be started before its upstream dependencies are frozen.

---

## 4. Current Architecture

### Data Flow (Unidirectional — No Exceptions)

```
Raw H4 Price Data
        │
        ├──→ StructureEngine v2.2 [FROZEN]
        │        │ → Graded Major/Minor Swings
        │        │ → BOS & MSS Events
        │        │ → Trend State (BULLISH/BEARISH/RANGE)
        │        │ → Local ATR(14) values
        │        │
        │        ├──→ SupplyDemandEngine v1.1 [FROZEN]
        │        │        │ → Supply/Demand Zone Array
        │        │        │ → Zone Scoring (freshness, age, reactions)
        │        │        │ → Invalidation Tracking
        │        │        │
        │        │        ├──→ SnrEngine v1.0 [TO BE BUILT]
        │        │        │        │ → Consolidated SNRLevel Array
        │        │        │        │ → LiquidityPool Array
        │        │        │        │ → Scored & Sorted S/R Bands
```

### Architectural Principles

| Principle | Rule |
|-----------|------|
| **Local ATR** | Every engine computes ATR(14) locally from cached OHLC arrays. No `iATR()` calls. |
| **Read-Only Dependencies** | Downstream engines consume upstream via public accessors only. No upstream modification. |
| **Bar 1 Minimum** | No structural analysis on Bar 0 (uncompleted candles). All decisions on completed bars. |
| **H4 Bar Gate** | Engine logic executes only on new H4 bar close, not on every tick. |
| **Encapsulated Classes** | All logic in classes. No global variables, static indicators, or DLL calls. |

### Validated Statistics (SupplyDemand v1.1, 4-year backtest 2022-2025)

| Metric | Value |
|--------|-------|
| Total Zones Created | 246 |
| Supply / Demand | 124 (50.4%) / 122 (49.6%) |
| Invalidated Zones | 176 (71.5%) |
| Active Zones | 70 (28.5%) |
| True False Positive Rate | **2.27%** |
| Retest Reliability | **97.73%** |
| Average Zone Lifetime | 124.73 H4 bars (~20.8 days) |
| Average Reactions/Zone | 2.82 |

---

## 5. Frozen Components

### Code Frozen

| Component | Version | File | Features | Freeze Proof |
|-----------|---------|------|----------|-------------|
| **StructureEngine** | v2.2 | `src/engines/StructureEngine.mqh` (51,282 bytes) | Fractal N=3 swings, ATR grading, non-repainting BOS/MSS, consecutive trend, local sync ATR | 4-year backtest, [audit passed](../audits/STRUCTURE_ENGINE_V22_AUDIT.md) |
| **SupplyDemandEngine** | v1.1 | `src/engines/SupplyDemandEngine.mqh` (17,284 bytes) | Impulse-base zones (1-6 candles), H4 close invalidation, corrected age decay, excluded breach bar | 4-year backtest, 97.73% reliability, [audit passed](../audits/SUPPLY_DEMAND_V11_AUDIT.md) |

### Design Frozen

| Specification | File | Key Elements |
|---------------|------|-------------|
| **SNR Engine v1.0 Architecture** | `docs/design/SNR_ARCHITECTURE_FREEZE.md` | Clustering (0.25×ATR), zone merge (≥50% overlap, 20% freshness reset), neutral nodes, nested zones, 5-weight scoring, liquidity pools |

### Freeze-Break Policy (AGENT_CONSTITUTION §4.1)

A freeze may only be broken if ALL conditions are met:
1. Critical defect **mathematically proven** with Strategy Tester log traces
2. Audit plan **drafted and approved** by project owner
3. Changes **isolated to the proven defect** only (no refactoring)
4. Full **4-year revalidation** (2022-2025) confirms zero regression

---

## 6. Historical Bugs Learned

All 7 major bugs and 1 design-phase finding from LESSONS_LEARNED.md are confirmed understood:

### StructureEngine Bugs (5 bugs, all resolved in v2.2)

| # | Bug | Wrong Assumption | Root Cause | Fix | Permanent Lesson |
|---|-----|-----------------|------------|-----|-----------------|
| 1 | **Trend locked to BULLISH** | Cumulative counting produces correct trend | HH/HL counts accumulated across 300 bars, never reset | Strict consecutive checking; reset to RANGE on interrupted sequence | Never use cumulative counting for state classification |
| 2 | **BOS repainting on Bar 0** | Including Bar 0 is safe | `DetectBOS()` scanned uncompleted candle; ticks wrote permanent BOS events that vanished on close | Gated loop to `barIdx >= 1` | Bar 0 is noise. Bar 1 is fact. Never evaluate structural events on uncompleted candles |
| 3 | **Swing reaction score leak** | Pipeline execution order doesn't matter | `CountReactions()` ran before `DetectBOS()`; no stop at `breakBarIndex` | Reordered pipeline; terminate scan at `breakBarIndex` | Pipeline ordering is logical correctness, not cosmetic |
| 4 | **Consolidation reaction inflation** | Every bar touch = independent retest | No state tracking; 25-bar consolidation counted as 25 reactions | `insideZone` state tracker; count only re-entries | Count transitions, not ticks |
| 5 | **ATR sync error in Strategy Tester** | `iATR()` works identically in tester and live | Cross-timeframe handles are asynchronous; returned 0.0 → only 2 of 58 swings graded Major | Local synchronous ATR(14) from cached arrays | Never delegate to asynchronous platform handles |

### SupplyDemandEngine Bugs (2 bugs, all resolved in v1.1)

| # | Bug | Wrong Assumption | Root Cause | Fix | Permanent Lesson |
|---|-----|-----------------|------------|-----|-----------------|
| 6 | **Age decay defect** | `currentBarIdx - impulseBarIndex` gives positive age | MT5 bar indices are reverse-ordered (0=now); result was negative, clamped to 0 → flat 100% score | Reversed to `impulseBarIndex - currentBarIdx` | Always verify sign of bar-index arithmetic with concrete example |
| 7 | **Invalidation bar reaction inflation** | Including boundary bar is conservative | Breach candle overlaps zone → counted as +1 reaction → masked true false positives (0.00% → 2.27%) | Excluded invalidation bar: `invalidatedBar + 1` | Inclusive vs. exclusive boundaries are correctness requirements |

### Design-Phase Finding

| Finding | Issue | Resolution |
|---------|-------|-----------|
| **SNR naming collision** | `S_React` meant "bounce distance" in SNR but "touch count" in S/D | Renamed to `S_Reject` (Rejection Strength Score) |

**Confirmed**: I understand why each bug occurred, what assumption caused it, and what permanent lesson it established.

---

## 7. Current Sprint

| Sprint | Status | Description |
|--------|--------|-------------|
| Sprint 1.0 | ✅ COMPLETE | StructureEngine v1.0 baseline |
| Sprint 2.0 | ✅ COMPLETE | StructureEngine v2.2 — 5 bugs fixed, frozen |
| Sprint 2.1 | ✅ COMPLETE | SupplyDemandEngine v1.0 → v1.1 — age decay + reaction fixes |
| Sprint 2.2 | ✅ COMPLETE | Statistical hotfix revalidation — 97.73% reliability verified |
| Sprint 2.3 | ✅ COMPLETE | Repository normalization, documentation freeze, recovery package |
| **Sprint 3.0** | 🎯 **NEXT** | **SNR Engine Implementation** |

### Current Repository State

| Aspect | Status |
|--------|--------|
| Git branch | `main` (up to date with `origin/main`) |
| Working tree | 1 deleted file (`Readme.txt`), 1 untracked (`note for user.md`) |
| Engines | 2 frozen (`StructureEngine.mqh`, `SupplyDemandEngine.mqh`) |
| Tests | 2 EAs (`TestStructure.mq5`, `TestSupplyDemand.mq5`) |
| Documentation | 30+ documents in organized `/docs/` hierarchy |
| Recovery package | Complete (Genesis, Constitution, Milestone, Protocol, Roadmap, README, Lessons Learned) |
| All audits | ✅ PASSED |

---

## 8. Next Sprint Objective

### Sprint 3.0: SNR Engine Implementation

**Goal**: Translate the approved [SNR_ARCHITECTURE_FREEZE.md](../design/SNR_ARCHITECTURE_FREEZE.md) into production MQL5 code.

**Deliverables**:
- `src/engines/SnrEngine.mqh` — SNR Engine v1.0
- `src/tests/TestSnr.mq5` — Visualization EA

**Core implementation tasks**:

| Task | Specification |
|------|--------------|
| **Local ATR** | Compute ATR(14) locally (cannot call `StructureEngine.GetATRValue()` — it's `private`) |
| **Level Extraction** | Extract active swings + active zones + invalidated zones (within 150 bars) |
| **Pre-Sort** | Sort all projected levels in price-ascending order |
| **Clustering** | Group levels within 0.25 × ATR proximity; cap cluster width at 1.50 × ATR |
| **Zone Merge** | Merge same-type zones with ≥ 50% height overlap; reset freshness if new zone dominates by ≥ 20% |
| **Neutral Nodes** | Deactivate overlapping Supply + Demand zones; release via upstream invalidation |
| **Nested Zones** | Flag inner zone as Core, outer as Macro (both retained) |
| **Scoring** | 5-weight formula: W_Struct=0.20, W_SD=0.30, W_Fresh=0.20, W_Reject=0.20, W_Confl=0.10 |
| **Rejection Distance** | Re-scan historical bars to compute ATR-relative bounce distance (upstream zones lack coordinates) |
| **Liquidity Pools** | Map buy/sell stop clusters above/below swing highs/lows |

**Mandatory workflow** (per AGENT_CONSTITUTION §6):

```
Design Freeze ✅ (done) → Consistency Audit ✅ (done) → Owner Approval → Implementation →
Compile Check (0/0) → Backtest (2022-2025) → Statistical Validation → Documentation → Code Freeze
```

---

## 9. Open Risks

| # | Risk | Severity | Mitigation | Source |
|---|------|----------|------------|--------|
| 1 | **Redundant Price History Scanning** — Structure, S/D, and SNR each loop through hundreds of historical bars independently | HIGH | Gate all engine logic by new H4 bar close; implement delta-scanning in SNR to avoid re-processing | PROJECT_GENESIS §7.1 |
| 2 | **ATR Volatility Compression** — During tight consolidations, ATR shrinks, grading noise as Major swings | MEDIUM | Consider absolute minimum ATR floor (e.g. 50 pips) — but this requires StructureEngine modification (frozen), so must be addressed via SNR-level filtering | PROJECT_GENESIS §7.2 |
| 3 | **Order-Dependence in Clustering** — Unsorted levels produce inconsistent cluster boundaries | MEDIUM | Mandated in design freeze: price-ascending sort before clustering loop | SNR_DESIGN_AUDIT §5.2 |
| 4 | **Missing Reaction Coordinates** — `SupplyDemandZone` stores `reactionCount` but not touch bar indices | MEDIUM | SNR engine must re-scan historical bars to compute rejection distances (performance cost) | SNR_DESIGN_AUDIT §2.2 |
| 5 | **Independent High/Low Array Alignment** — Separate arrays may produce label misalignment in anomalous markets | LOW | Monitor during SNR integration testing | PROJECT_STATE_REVIEW §3 |
| 6 | **Dead Code (iATR handle)** — Unused `m_atrHandle` in frozen StructureEngine | LOW | Technical debt; cannot modify frozen engine | PROJECT_STATE_REVIEW §4 |
| 7 | **Hardcoded Version String** — `TestStructure.mq5` prints "v2.1" not "v2.2" | LOW | Cosmetic; cannot modify frozen test without approval | PROJECT_STATE_REVIEW §4 |
| 8 | **Root Directory Residuals** — `note for user.md` and `REPOSITORY_NORMALIZATION_AUDIT.md` at root | LOW | Relocate before Sprint 3.0 begins | RECOVERY_REPORT §8 |

---

## 10. Recovery Confidence Assessment

### Overall: **97%** ✅

| Dimension | Confidence | Evidence |
|-----------|-----------|---------|
| **WHY** the project exists | 100% | Eliminate retail indicator lag; exploit institutional order flow inefficiencies via H4 structure mapping |
| **WHAT** the end goal is | 100% | 8-module decoupled pipeline → fully automated XAUUSD EA on MT5 |
| **WHAT** has been completed | 100% | StructureEngine v2.2 + SupplyDemandEngine v1.1 — both frozen with 4-year backtest validation |
| **WHAT** is frozen | 100% | 2 code modules + 1 design specification, with 4-condition freeze-break policy |
| **WHAT** must never be modified | 100% | Frozen engines, unidirectional data flow, rejected concepts (Martingale, Grid, etc.) |
| **WHAT** bugs were discovered and how they were fixed | 100% | 7 bugs + 1 design finding documented in LESSONS_LEARNED.md with root causes, fixes, and permanent lessons |
| **WHERE** the project stands | 95% | Sprint 2.3 complete, Sprint 3.0 next. Minor root cleanup pending. Compilation not independently verified. |
| **WHAT** the next sprint should be | 100% | Sprint 3.0: SNR Engine Implementation per frozen architecture specification |
| **HOW** to avoid repeating past mistakes | 100% | 12 golden rules + 5 design principles from LESSONS_LEARNED.md absorbed |

**Deductions (-3%)**:
- Cannot independently verify MetaEditor compilation (no MetaEditor access from this agent)
- Two files at root not yet classified/relocated (`note for user.md`, `REPOSITORY_NORMALIZATION_AUDIT.md`)

---

## Documents Read During Validation

| # | Document | Status |
|---|----------|--------|
| 1 | README.md | ✅ Read |
| 2 | PROJECT_GENESIS.md | ✅ Read (171 lines) |
| 3 | AGENT_CONSTITUTION.md | ✅ Read (176 lines) |
| 4 | MILESTONE_GENESIS_FREEZE.md | ✅ Read (127 lines) |
| 5 | PROJECT_RECOVERY_PROTOCOL.md | ✅ Read (55 lines) |
| 6 | RECOVERY_REPORT.md | ✅ Read (298 lines) |
| 7 | LESSONS_LEARNED.md | ✅ Read (560 lines) |
| 8 | SYSTEM_ROADMAP.md | ✅ Read (79 lines) |

**Total lines read**: 1,576 lines across 8 documents.

---

## Agent Oath

```
I, the AI Coding Agent, solemnly swear to uphold and protect the integrity of this codebase.
I will respect the frozen boundaries of Module 1 and Module 2.
I will prioritize correctness over speed, and statistical evidence over assumptions.
I will ensure that all specifications, audits, and timelines are updated chronologically.
I will govern my actions by the Agent Constitution, ensuring that the repository remains fully
reconstructible and understandable for all future developers and agents.
```

---

> **VALIDATION COMPLETE**
>
> This agent has demonstrated full understanding of the project mission, vision, architecture, frozen components, historical bugs, current sprint, next objectives, and open risks.
>
> **Awaiting project owner approval before any implementation work begins.**
