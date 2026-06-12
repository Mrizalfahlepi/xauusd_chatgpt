# PROJECT GENESIS - Master Project Bible

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED & FROZEN BASELINE  
**Current Version**: 2.3  
**Target Platform**: MetaTrader 5 (MQL5)

---

# SECTION 1 — PROJECT IDENTITY

*   **Project Name**: XAUUSD Institutional Structure EA
*   **Project Purpose**: Build an algorithmic trading system based purely on fractal price action, market structure, supply/demand zones, and support/resistance scoring.
*   **Current Version**: 2.3 (Post-Refactoring & SNR Design Freeze)
*   **Repository Structure**: Normalized modular layout:
    *   `/docs/core/`: General specifications, definitions, and onboarding guides.
    *   `/docs/design/`: Module-specific design files and freeze specifications.
    *   `/docs/audits/`: Comprehensive audits for codebase logic.
    *   `/docs/reports/`: Statistical reports and validation backtest logs.
    *   `/docs/archive/`: Obsolete, temporary, or superseded files.
    *   `/src/engines/`: Production-ready MQL5 engine classes (`.mqh` files).
    *   `/src/tests/`: Visual chart validator Expert Advisors (`.mq5` files).
*   **Primary Market**: Spot Gold
*   **Primary Symbol**: `XAUUSD` / `XAUUSDm`
*   **Primary Timeframe**: H4 (for market structure, S/D detection, and SNR mapping)
*   **Execution Timeframe**: M30 (for entry triggers, structural confirmations, and risk execution)
*   **Technology Stack**: Pure MQL5 (no lagging indicators, no external DLL dependencies)
*   **Development Environment**: MetaEditor 64 + MetaTrader 5 Terminal (Build 4300+)
*   **Git Workflow**: Linear staging. Staged changes must compile cleanly (0 errors, 0 warnings) before commit.
*   **Repository URL**: `https://github.com/Mrizalfahlepi/xauusd_chatgpt.git`

---

# SECTION 2 — PROJECT NORTH STAR

### Ultimate Mission
To eliminate emotional trading bias by building a fully automated institutional trading system that exploits order blocks and structural liquidity pools. 

### Why This EA Exists
Traditional retail Expert Advisors rely on lagging indicators (e.g. Moving Averages, RSI, MACD) which fail during regime shifts. Retail traders are consistently liquidated at key support/resistance levels due to a lack of volume and institutional order flow visualization. This EA exists to map institutional order blocks and liquidity pools, executing trades alongside market makers rather than against them.

### Final Production Vision
A set of decoupled, high-performance engines communicating via clean public interfaces to run on a single chart thread without causing thread latency. The final system must autonomously perform the following:
1.  Map major structure on H4, establishing the bias (Bullish/Bearish/Range).
2.  Identify active, high-volume Supply and Demand zones.
3.  Synthesize swings and zones into ranked, scored SNR levels.
4.  Track buy/sell liquidity pools (stop-loss clusters) where major sweeps are highly probable.
5.  Refine bias on the M30 execution timeframe.
6.  Execute limit or market orders with mathematically calculated stop-losses and dynamic take-profits, ensuring a minimum Risk-to-Reward ratio of 1:2.
7.  Manage portfolio risk dynamically, maintaining a maximum drawdown threshold of 10% on live trading accounts.

```
DEVELOPMENT LIFECYCLE:
[Research Phase] (Define rules) -> [Backtest Phase] (Validate mathematically) 
  -> [Forward Test Phase] (Verify execution) -> [Live Trading Phase] (Production)
```

---

# SECTION 3 — SYSTEM PHILOSOPHY

Every developer and AI agent joining this project must adhere to these non-negotiable engineering principles:

1.  **Evidence Before Assumptions**: No coding may begin without visual tester proof, logs, or mathematical validation.
2.  **No Repainting**: Signals must be computed on completed H4/M30 bar closes. The active uncompleted candle (Bar 0) must never write permanent structural states.
3.  **Statistical Validation Before Freeze**: A module is only frozen after running a multi-year backtest (2022-2025) and verifying its predictive power.
4.  **Decoupled Modular Architecture**: Engines are isolated classes. They consume outputs of upstream engines but cannot write back to them or modify their internal state.
5.  **Independent Engine Testing**: Every engine must have a dedicated `.mq5` validator script to draw its outputs on the chart, allowing instant visual auditing in the Strategy Tester.
6.  **No Hidden Future Data**: Retest scanning, reaction scoring, and trend evaluations must scan chronologically (from oldest to newest) to prevent leaks of future information.
7.  **Document Every Architectural Decision**: Major bugs and their resolutions must be logged in the design decision logs to prevent regression.

---

# SECTION 4 — COMPLETE PROJECT TIMELINE

### Sprint 1.0 — Market Structure Engine Baseline
*   **Objective**: Detect fractal swings and classify them as Major or Minor.
*   **Files Created**: `StructureEngine.mqh`, `TestStructure.mq5`.
*   **Problems Discovered**: Visual repainting of BOS lines on active ticks; trend classification locked to Bullish after a long run.
*   **Solutions**: Restructured trend classification; deferred BOS detection to Bar 1.
*   **Outcome**: Initial structural mapping established.

### Sprint 1.5 — Quality Auditing & Bug Fixes
*   **Objective**: Fix the repainting, reaction scoring leaks, and tester lag.
*   **Files Modified**: `StructureEngine.mqh`, `TestStructure.mq5`.
*   **Problems Discovered**: Unused ATR handles causing Strateger Tester lag; reaction count inflation inside thick consolidations.
*   **Solutions**: Excluded Bar 0 from BOS loop; terminated reaction counting at break bar index; implemented local synchronous ATR(14) calculations; introduced `insideZone` state tracker for touch grouping.
*   **Validation**: Clean compile, trend transitions successfully tested.
*   **Outcome**: Version 2.2 signed off and frozen.

### Sprint 2.0 — Supply & Demand Engine Baseline
*   **Objective**: Detect institutional S/D zones based on base-impulse logic.
*   **Files Created**: `SupplyDemandEngine.mqh`, `TestSupplyDemand.mq5`, `SUPPLY_DEMAND_DESIGN.md`, `SUPPLY_DEMAND_VALIDATION.md`.
*   **Problems Discovered**: Zone age score remained 100 due to negative subtraction; invalidation candle was counted as a retest, inflating reactions.
*   **Solutions**: Deferred code changes for verification phase.
*   **Outcome**: Phase baseline built.

### Sprint 2.2 — Statistical Hotfixes & Revalidation
*   **Objective**: Fix the two anomalies identified in the 4-year backtest.
*   **Files Modified**: `SupplyDemandEngine.mqh`.
*   **Files Created**: `SUPPLY_DEMAND_VERIFICATION_REPORT.md`, `SUPPLY_DEMAND_V11_AUDIT.md`, `UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md`.
*   **Problems Discovered**: Verified negative age score calculation and reaction inflation (+1 touch on breach candle).
*   **Solutions**: Corrected age bar subtraction (`zone.impulseBarIndex - currentBarIdx`); excluded invalidation bar from retest loop (`stopBar = invalidatedBar + 1`).
*   **Outcome**: True false positive rate verified at 2.27% (down from 33.52% projection error). Version 1.1 frozen.

### Sprint 2.3 — Repository Refactor & SNR Design Freeze
*   **Objective**: Organize the repository root and freeze the SNR specification.
*   **Files Created**: `REPOSITORY_ARCHITECTURE_AUDIT.md`, `REPOSITORY_REFACTOR_PLAN.md`, `REPOSITORY_REFACTOR_EXECUTION_REPORT.md`, `SNR_DESIGN_AUDIT.md`, `SNR_ARCHITECTURE_FREEZE.md`.
*   **Files Relocated**: All 29 files moved to target subdirectories (e.g. `/docs/core`, `/src/engines`).
*   **Outcome**: Compiler validation successful (0 errors, 0 warnings). SNR specs frozen.

---

# SECTION 5 — FROZEN COMPONENTS

The following components are locked. No modification to their logic is permitted:

### 5.1 Structure Engine (v2.2)
*   **Freeze Date**: June 11, 2026.
*   **Purpose**: Detects fractal swing points (N=3), grades major/minor swings via ATR, identifies non-repainting BOS and MSS, and tracks market trend.
*   **Inputs**: H4 Price data (Open, High, Low, Close, Time).
*   **Outputs**: `m_majorHighs`, `m_majorLows`, `m_bosEvents`, `m_mssEvents`, `m_currentTrend`.
*   **Validation**: 4-year backtest verified trend transition responsiveness and zero repainting.

### 5.2 Supply & Demand Engine (v1.1)
*   **Freeze Date**: June 12, 2026.
*   **Purpose**: Detects base-impulse structures, tracks zone invalidations on closed H4 candles, and calculates zone quality scores (Impulse, Freshness, Age, Reactions).
*   **Inputs**: `CStructureEngine` outputs, H4 Price data.
*   **Outputs**: `SupplyDemandZone` array.
*   **Validation**: Revalidated over 4 years; 246 unique zones, 97.73% retest reliability, 2.27% true false positive rate.

### 5.3 SNR Architecture Specification (v1.0)
*   **Freeze Date**: June 12, 2026.
*   **Purpose**: Design freeze specifying ATR-relative clustering, 20% newer-zone merge priority, nested core/macro handling, neutral consolidation zones, and the 5-weight linear scoring model.
*   **Document Link**: [SNR_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/SNR_ARCHITECTURE_FREEZE.md).

---

# SECTION 6 — ARCHITECTURAL DECISIONS

### Decision #1 — Fractal Swings Over ZigZag
*   **Problem**: ZigZag repaints its final leg, causing look-ahead bias.
*   **Decision**: Use fractal swing point detection with lookback N=3. Finalized on bar close.
*   **Status**: Frozen.

### Decision #2 — Local Synchronous ATR
*   **Problem**: MT5 `iATR` indicator handle is asynchronous, causing Strategy Tester sync lag and compile mismatches during backtests.
*   **Decision**: Compute ATR(14) locally and synchronously from cached price arrays in the Analyze loop.
*   **Status**: Frozen.

### Decision #3 — Invalidation Excluded from S/D Reactions
*   **Problem**: The candle that invalidates an S/D zone overlaps the zone, inflating reactions by +1.
*   **Decision**: Terminate retest touch loop at `invalidatedBar + 1`, ignoring the invalidation candle.
*   **Status**: Frozen.

### Decision #4 — Neutral Decision Nodes for Overlapping S/D
*   **Problem**: In tight consolidations, opposing Supply and Demand zones overlap, causing whipsaw losses.
*   **Decision**: Deactivate both zones for entry inside the overlapping range until a clean H4 candle closes outside.
*   **Status**: Frozen.

---

# SECTION 7 — CURRENT REPOSITORY MAP

```
/xauusd_chatgpt
│   .gitignore                              [FINAL] [CORE] Git ignore configuration
│   PROJECT_GENESIS.md                      [FINAL] [CORE] Master project bible (This File)
│   GENESIS_COMPLETENESS_AUDIT.md           [FINAL] [AUDIT] Verification sheet for PROJECT_GENESIS.md
│   REPOSITORY_ARCHITECTURE_AUDIT.md        [FINAL] [AUDIT] Classification audit of all files
│   REPOSITORY_REFACTOR_EXECUTION_REPORT.md [FINAL] [REPORT] Refactoring compile & link validation
│   REPOSITORY_REFACTOR_PLAN.md             [FINAL] [DESIGN] Folder restructure specifications
│
├───docs
│   ├───archive
│   │       SNR_DATA_FLOW.md                [SUPERSEDED] Replaced by SNR_ARCHITECTURE_FREEZE.md
│   │       SNR_ENGINE_DESIGN.md            [SUPERSEDED] Replaced by SNR_ARCHITECTURE_FREEZE.md
│   │       SNR_SCORING_MODEL.md            [SUPERSEDED] Replaced by SNR_ARCHITECTURE_FREEZE.md
│   │       structure_engine_audit.md       [SUPERSEDED] Replaced by STRUCTURE_ENGINE_V22_AUDIT.md
│   │       STRUCTURE_ENGINE_EVIDENCE_REPORT.md [TEMPORARY] Diagnostic files for v2.2
│   │       STRUCTURE_ENGINE_FINAL_VALIDATION.md [ARCHIVE] Historical log logs for v2.2
│   │       SUPPLY_DEMAND_AUDIT.md          [SUPERSEDED] Replaced by SUPPLY_DEMAND_V11_AUDIT.md
│   │       SUPPLY_DEMAND_STATISTICAL_REPORT.md [SUPERSEDED] Replaced by UPDATED_S_D_REPORT.md
│   │       SUPPLY_DEMAND_VALIDATION.md     [ARCHIVE] Historical log logs for v1.0
│   │       SUPPLY_DEMAND_VERIFICATION_REPORT.md [ARCHIVE] Verification logs for Sprint 2.2
│   │
│   ├───audits
│   │       SNR_DESIGN_AUDIT.md             [FINAL] [AUDIT] Design consistency audit of SNR specs
│   │       STRUCTURE_ENGINE_V22_AUDIT.md   [FINAL] [AUDIT] Audit logs for Structure v2.2
│   │       SUPPLY_DEMAND_CONSISTENCY_AUDIT.md [FINAL] [AUDIT] Verification of engine vs parser fixes
│   │       SUPPLY_DEMAND_V11_AUDIT.md      [FINAL] [AUDIT] Audit logs for Supply Demand v1.1
│   │
│   ├───core
│   │       01_MARKET_DEFINITIONS.md        [FINAL] [CORE] Definitions of market structures
│   │       02_SYSTEM_ARCHITECTURE.md        [FINAL] [CORE] System diagram and layout
│   │       03_CODING_RULES.md              [FINAL] [CORE] Strict coding standards
│   │       04_DESIGN_DECISIONS.md          [FINAL] [CORE] Log of design choices
│   │       05_CURRENT_STATUS.md            [FINAL] [CORE] Active project scope
│   │       08_AGENT_ONBOARDING.md          [FINAL] [CORE] Onboarding instructions for new agents
│   │       PROJECT_MEMORY.md               [FINAL] [CORE] Chronological project memory log
│   │       PROJECT_STATE_REVIEW.md         [FINAL] [CORE] High-level state status review
│   │
│   ├───design
│   │       SNR_ARCHITECTURE_FREEZE.md      [ACTIVE] [DESIGN] Staged authoritative spec for Module 3
│   │       SUPPLY_DEMAND_DESIGN.md         [FINAL] [DESIGN] Specifications for Module 2
│   │
│   └───reports
│           UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md [FINAL] [REPORT] Final metrics over 4 years
│
└───src
    ├───engines
    │       StructureEngine.mqh            [FROZEN] [ENGINE] Production Structure Engine v2.2
    │       SupplyDemandEngine.mqh         [FROZEN] [ENGINE] Production SupplyDemand Engine v1.1
    │
    └───tests
            TestStructure.mq5              [ACTIVE] [TEST] Visual EA for Structure Engine
            TestSupplyDemand.mq5           [ACTIVE] [TEST] Visual EA for SupplyDemand Engine
```

---

# SECTION 8 — ENGINE ECOSYSTEM

The system's execution pipeline flows in a strictly unidirectional sequence:

```
[StructureEngine v2.2]
       │ (Grades Swings, Detects BOS/MSS, Calculates Trend)
       ▼
[SupplyDemandEngine v1.1]
       │ (Detects Base-Impulse Zones, Calculates Quality Scores)
       ▼
[SnrEngine v1.0 (Planned)]
       │ (Aggregates Swings & Zones, Pre-sorts, Groups via ATR-Clustering)
       ▼
[LiquidityEngine (Planned)]
       │ (Identifies buy/sell stop liquidity pools above/below swing clusters)
       ▼
[ConfluenceEngine (Planned)]
       │ (Refines bias across timeframes, aligns multiple structural triggers)
       ▼
[TradeDecisionEngine (Planned)]
       │ (Filters setups, determines entry price, targets, and trigger conditions)
       ▼
[RiskEngine (Planned)]
       │ (Calculates lot size based on account balance, target % risk, and SL)
       ▼
[ExecutionEngine (Planned)]
       │ (Sends orders, handles slippage, executes trailing stops, manages exits)
       ▼
[Live EA] (Deployable compilation target)
```

---

# SECTION 9 — LONG TERM ROADMAP

### Sprint 3.0 — Support, Resistance & Liquidity Engine (SNR Engine)
*   **Goal**: Implement clustering and consolidation of levels, scoring them based on structural confluence.
*   **Expected Deliverables**: `SnrEngine.mqh`, `TestSnr.mq5`.
*   **Validation**: Visual EA on chart; compile check (0 errors, 0 warnings).
*   **Freeze Criteria**: Correct ATR clustering and 5-weight score calculations verified in backtests.

### Sprint 4.0 — Liquidity & Sweep Engine
*   **Goal**: Map buy/sell stop pools; identify sweep-and-reverse zones.
*   **Expected Deliverables**: `LiquidityEngine.mqh`, `TestLiquidity.mq5`.
*   **Validation**: Correct drawing of liquidity bars and sweep event logs.

### Sprint 5.0 — Confluence & Multi-Timeframe Engine
*   **Goal**: Align H4 structure and zones with M30 micro-impulses to confirm entries.
*   **Expected Deliverables**: `ConfluenceEngine.mqh`, `TestConfluence.mq5`.

### Sprint 6.0 — Entry & Trade Decision Engine
*   **Goal**: Define entry triggers (limit orders vs. market execution on engulfing patterns).
*   **Expected Deliverables**: `EntryEngine.mqh`, `TestEntry.mq5`.

### Sprint 7.0 — Risk Management Engine
*   **Goal**: Calculate lot sizes based on stop-loss distance, maintaining a strict 1% risk per trade.
*   **Expected Deliverables**: `RiskEngine.mqh`.

### Sprint 8.0 — Order Execution & Trade Manager
*   **Goal**: Manage order execution, slippage limits, partial profit-taking, and trailing stops.
*   **Expected Deliverables**: `ExecutionEngine.mqh`, `TradeManager.mqh`.

### Sprint 9.0 — Integration & Visual Dashboard
*   **Goal**: Integrate all engines into a single master Expert Advisor with an on-chart control panel.
*   **Expected Deliverables**: `XAUUSD_Institutional_EA.mq5`.

### Sprint 10.0 — Production Validation & Release
*   **Goal**: Run a 4-year portfolio backtest on live ticks; verify drawdown does not exceed 10%.
*   **Expected Deliverables**: Comprehensive validation report. Freeze codebase for live deploy.

---

# SECTION 10 — KNOWN RISKS

1.  **Redundant Price History Scanning**:
    *   *Risk*: All three modules (Structure, S/D, and SNR) perform separate historical price loops to calculate reactions or rejection distances. If run on every tick, Strategy Tester performance will degrade.
    *   *Mitigation*: Gate engine logic strictly by new H4 bar closes; cache coordinates to avoid duplicate scanning of historical bars.
2.  **ATR Volatility Compression/Expansion**:
    *   *Risk*: Swing grading depends on ATR. During extremely tight consolidations, ATR shrinks, causing noise to be classified as Major swings.
    *   *Mitigation*: Establish an absolute minimum ATR floor (e.g. 50 pips) inside `StructureEngine.mqh` below which swings cannot be graded as Major.
3.  **Order-Dependence in Clustering**:
    *   *Risk*: If levels are not pre-sorted before ATR projection, clustering boundaries will be inconsistent.
    *   *Mitigation*: Mandate price-ascending sorting prior to executing the clustering loop.

---

# SECTION 11 — HANDOVER GUIDE (FOR NEW DEVELOPERS / AIs)

### 11.1 Where to Start
1.  Read the **[PROJECT_GENESIS.md](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md)** (this file) to understand history and rules.
2.  Read the coding standards in **[03_CODING_RULES.md](file:///c:/xauusd_chatgpt/docs/core/03_CODING_RULES.md)**.
3.  Inspect the frozen engine files inside `/src/engines/`.

### 11.2 Authority Levels
*   **Authoritative Files**: `/src/engines/StructureEngine.mqh` and `/src/engines/SupplyDemandEngine.mqh`. **Do not modify these files.**
*   **Active Specifications**: [docs/design/SNR_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/SNR_ARCHITECTURE_FREEZE.md).

### 11.3 How to Compile & Verify
1.  Run the copy-and-compile script:
    ```powershell
    powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\copy_and_compile.ps1
    ```
2.  Inspect `C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\compile.log` using:
    ```powershell
    Get-Content C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\compile.log
    ```
    Verify it outputs `0 errors, 0 warnings`.
3.  Run a tester simulation using:
    ```powershell
    powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\run_backtest.ps1
    ```
4.  Parse and audit logs using:
    ```powershell
    powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\parse_new_logs.ps1
    ```

---

# SECTION 12 — CURRENT PROJECT STATUS

*   **Completed**:
    *   Market Structure Engine (v2.2)
    *   Supply & Demand Engine (v1.1)
    *   Repository Refactoring and Document Relocation
*   **Frozen**:
    *   `StructureEngine.mqh` (v2.2)
    *   `SupplyDemandEngine.mqh` (v1.1)
*   **Approved**:
    *   SNR Architecture Design Freeze (`SNR_ARCHITECTURE_FREEZE.md`)
*   **Under Design**:
    *   Liquidity Engine (conceptual mapping)
*   **Not Started**:
    *   Sprints 4 through 10
*   **Next Sprint**:
    *   **Sprint 3.0 (SNR Engine Implementation)**
*   **Next Action**:
    *   Initialize `src/engines/SnrEngine.mqh` based on `SNR_ARCHITECTURE_FREEZE.md` specs.

---

# SECTION 13 — EXECUTIVE SUMMARY (5-MINUTE READING GUIDE)

This repository contains a modular, institutional-grade trading system for Gold (`XAUUSD`) on the H4 timeframe, written in pure MQL5. The codebase is organized into isolated engines to guarantee thread safety and prevent repainting. 

*   **Market Structure Engine (v2.2)** uses fractal calculations to detect major structural pivots (HH/HL/LH/LL) and trend transitions.
*   **Supply & Demand Engine (v1.1)** tracks institutional order block bases (1-6 candles) preceding large momentum impulse candles, calculating zone freshness and reactions.
*   **SNR Engine (v1.0)** is the planned next module. It consolidates nearby levels using volatility-relative ATR clustering, resolves zone overlaps, and scores support/resistance bands on a scale of 0-100 using a 5-weight linear model.
*   **System Integrity**: All calculations run synchronously on completed H4 candles to eliminate look-ahead bias. The code is structured under `/src/engines/` and validated visually using EAs in `/src/tests/`. Compilation requires `0 errors, 0 warnings`.
