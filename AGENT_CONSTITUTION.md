# Agent Constitution

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED & FROZEN baseline OPERATING LAW  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Project Mission

The permanent mission of this project is to build and deploy an institutional-grade, fully automated trading system for Gold (`XAUUSD`/`XAUUSDm`) on the H4 and M30 timeframes. This system is designed to exploit order block inefficiencies, price imbalances, market structure shifts, and liquidity sweeps. 

The ultimate goal is to progress systematically through all roadmap phases until live production deployment is achieved, maintaining a strict risk management framework to preserve trading capital.

---

## 2. Project Vision

The target system is a decoupled multi-layer engine pipeline where each module has distinct responsibilities:

1.  **Market Structure Engine (Module 1)**: Analyzes H4 price action to detect swing high/low points, identify Break of Structure (BOS) and Market Structure Shifts (MSS), and classify trend bias.
2.  **Supply & Demand Engine (Module 2)**: Identifies institutional order blocks (consolidation bases of 1-6 candles preceding high-volume impulse candles), tracking retests and zone invalidations.
3.  **SNR Engine (Module 3)**: Consolidates swings and zones into horizontal bands using ATR-relative clustering, deactivates opposing overlap zones (Neutral Nodes), and scores levels (0-100) using a 5-weight linear model.
4.  **Liquidity Engine (Module 4)**: Maps stop-loss clusters above/below swing highs/lows and flags liquidity sweep events.
5.  **Entry Engine (Module 5)**: Aligns H4 bias with M30 micro-structure triggers (e.g. engulfing patterns) to execute limit or market orders.
6.  **Risk Engine (Module 6)**: Computes lot size dynamically to enforce a strict risk threshold (e.g. 1% per trade) based on account balance and stop-loss distance.
7.  **Portfolio Engine (Module 7)**: Manages active positions,Trailing Stops, Break-Evens, partial profit targets, and news filter blocks.
8.  **Live Deployment Layer (Module 8)**: Connects all engines into a single Expert Advisor (`.mq5`) validated for latency and execution slippage under live broker feeds.

---

## 3. Source of Truth Hierarchy

When continuing development, all developers and AI agents must strictly prioritize information according to the following hierarchy:

1.  **[PROJECT_GENESIS.md](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md)**: The authoritative project history, timeline, bugs log, and core architecture specification.
2.  **[PROJECT_RECOVERY_PROTOCOL.md](file:///c:/xauusd_chatgpt/PROJECT_RECOVERY_PROTOCOL.md)**: Onboarding instructions, reading order, and recovery steps.
3.  **[MILESTONE_GENESIS_FREEZE.md](file:///c:/xauusd_chatgpt/MILESTONE_GENESIS_FREEZE.md)**: The snapshot of repository trees, compilation, and statistical baselines.
4.  **[SYSTEM_ROADMAP.md](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md)**: The phase-by-phase development timeline.
5.  **[AGENT_CONSTITUTION.md](file:///c:/xauusd_chatgpt/AGENT_CONSTITUTION.md)**: This operating law.
6.  **Audit Documents (`/docs/audits/`)**: Detailed code reviews and consistency sheets.
7.  **Source Code (`/src/`)**: The active and frozen MQL5 files.

**CRITICAL RULE**: ChatGPT chat history and context window summaries are **NEVER** a source of truth. If a contradiction arises between the chat memory and the repository documentation, the repository documentation **MUST** prevail.

---

## 4. Frozen Components

The following modules are locked and frozen in version and logic:
*   **StructureEngine v2.2 (Frozen)**
*   **SupplyDemandEngine v1.1 (Frozen)**
*   **SNR Architecture Specification (Frozen)**

### 4.1 Modification Policy for Frozen Engines
A frozen module may **NOT** be modified under any normal development sprint. A freeze can only be broken if:
1.  A critical logical defect or execution error is mathematically proven with log traces in the Strategy Tester.
2.  An audit plan is drafted and approved by the project owner.
3.  Changes are isolated **ONLY** to the proven defect without refactoring other functional logic.
4.  The revalidation backtest is executed across the entire 4-year period (2022-2025) to confirm that no regression has occurred.

---

## 5. Development Philosophy

1.  **Correctness Before Features**: A single fully correct, non-repainting module is infinitely more valuable than an entire trading system built on untested assumptions.
2.  **Verification Before Implementation**: Do not write MQL5 code before checking design consistency, impossible data dependencies, and logical contradictions.
3.  **Audit Before Approval**: Every sprint must produce a dedicated audit document confirming the compliance of the design or code.
4.  **Statistical Validation Before Freeze**: No engine is frozen until it is run against the 4-year historical backtest (2022-2025) and compiled statistics are verified.
5.  **Reproducibility Over Assumptions**: All backtests must use the exact same broker configurations and local ATR indicators to guarantee that results are 100% reproducible.

---

## 6. Mandatory Workflow

Every sprint must follow this sequence without exception:

```
[Design Freeze] (Freeze specifications)
       │
       ▼
[Consistency Audit] (Validate inputs/outputs and dependencies)
       │
       ▼
[Owner Approval] (Confirm design baseline)
       │
       ▼
[Implementation] (Write decoupled, clean code)
       │
       ▼
[Compile Check] (0 errors, 0 warnings)
       │
       ▼
[Backtest Simulation] (Offline Strategy Tester runs)
       │
       ▼
[Statistical Validation] (Parse logs, compile metrics)
       │
       ▼
[Documentation Update] (Create audits, update memory)
       │
       ▼
[Code Freeze] (Commit and push changes)
```

---

## 7. Forbidden Actions

1.  **Modifying Frozen Engines** without a formal, approved hotfix audit.
2.  **Skipping Backtests** or compiling EAs without verifying `0 errors, 0 warnings` in the MetaEditor compiler log.
3.  **Skipping Statistical Validation** in favor of anecdotal tester screenshots.
4.  **Changing System Architecture** or relative subfolders without updating the refactor plan and link mappings.
5.  **Introducing Hidden Timeframe Dependencies** (e.g. calling asynchronous timeframe handles that crash the MT5 tester thread).
6.  **Relying on Chat Memory** or previous agent summaries instead of checking the authoritative repository documents.

---

## 8. Recovery Procedure

If a new agent or developer joins the project, or if the chat history is lost, execute this exact recovery process:

1.  **Step 1: Read the Root Entrypoints** in the mandatory reading order (Section 3).
2.  **Step 2: Initialize Workspace**: Verify the local file paths match the tree in `/MILESTONE_GENESIS_FREEZE.md`.
3.  **Step 3: Run Compiler Check**: Compile the EAs in the terminal folder and inspect `compile.log` to confirm zero warnings or errors.
4.  **Step 4: Generate Recovery Report**: Write a brief orientation summary confirming your understanding of the current sprint, frozen modules, and target task.
5.  **Step 5: Obtain Approval**: Present the recovery report to the project owner to confirm alignment before writing any new code.

---

## 9. Current System State

*   **Completed & Frozen**: 
    *   `StructureEngine.mqh` (v2.2) [FROZEN]
    *   `SupplyDemandEngine.mqh` (v1.1) [FROZEN]
*   **Design Staged & Frozen**:
    *   SNR Engine design specification ([SNR_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/SNR_ARCHITECTURE_FREEZE.md)) [FROZEN]
*   **Normalized Workspace**:
    *   Root contains only the 6 permanent entry files.
*   **Next Approved Target**:
    *   Sprint 3.0 SNR Engine Implementation (`SnrEngine.mqh`).

---

## 10. Definition of Done

A development sprint is only classified as **DONE** and ready for freeze when:
1.  The code compiles cleanly with **0 errors and 0 warnings** in the MetaEditor compiler log.
2.  A full Strategy Tester backtest has run successfully.
3.  A dedicated verification audit or validation report has been written.
4.  Hardcoded markdown links are audited and fixed.
5.  The chronological `/docs/core/PROJECT_MEMORY.md` is updated.
6.  All changes are staged, committed, and successfully pushed to GitHub.

---

## 11. Long-Term Development Rules

1.  **Stable Upstream Dependencies**: Because `StructureEngine` and `SupplyDemandEngine` are frozen, future engines (SNR, Liquidity, Entry) must consume their outputs via public accessors (`GetZone()`, `GetMajorHigh()`). They must not modify the upstream engines.
2.  **Order of Development**: Sprints must proceed sequentially down the roadmap. Do not start work on risk or trade execution engines until S/D, SNR, and Entry engines are fully frozen.
3.  **Encapsulated Logic**: All logic must be encapsulated in classes. Do not use global variables, static indicators, or unmanaged Win32 DLL calls.

---

## 12. Agent Oath

```
I, the AI Coding Agent, solemnly swear to uphold and protect the integrity of this codebase. 
I will respect the frozen boundaries of Module 1 and Module 2. 
I will prioritize correctness over speed, and statistical evidence over assumptions. 
I will ensure that all specifications, audits, and timelines are updated chronologically. 
I will govern my actions by this Constitution, ensuring that the repository remains fully 
reconstructible and understandable for all future developers and agents.
```
