# 08_AGENT_ONBOARDING.md

Version: 2.4  
Date: 2026-06-13  
Status: Active  

---

## Welcome, Agent!

This document is your guide to understanding, compiling, testing, and expanding the **XAUUSD Institutional Structure EA** codebase. As an agentic coding assistant, you must be extremely thorough, maintain strict documentation integrity, and follow our architectural boundaries.

---

## 1. Project Orientation & Philosophy

Before you touch any code, you must understand our core philosophy:
1.  **No Lagging Indicators**: The EA reads the market structure directly using price actions: fractal swings, breakouts, order blocks, consolidated SNR levels, and liquidity pools. Traditional indicators (RSI, MACD, Stochastic) are prohibited for entry decisions.
2.  **Order of Execution**: Market Structure → Supply Demand → SNR & Prioritizer → Liquidity (Stop Runs) → Entry → Risk → Execution.
3.  **Strict Boundaries**: Do not start building a module until its preceding module is completed and verified.
    *   **Module 1 (Market Structure Engine)**: Completed, validated, and frozen in version 2.2.
    *   **Module 2 (Supply & Demand Engine)**: Completed, validated, and frozen in version 1.1.
    *   **Module 3 (SNR Engine & Prioritizer)**: Completed, validated, and frozen in version 1.0 (exposing the stable `SnrPriorityContract`).
    *   **Module 4 (Liquidity Engine)**: **The next authorized module to build.**

---

## 2. File Layout & Workspace Structure

### Core Files
*   [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh): Swing point detection, ATR swings grading, BOS/MSS, and trend calculations.
*   [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh): Impulse-base-displacement order blocks, decay, and reactions tracking.
*   [SnrEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh): Level clustering and 5-weight consolidated scoring.
*   [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh): Implements `CSnrPriorityEngine` and output contract `SnrPriorityContract` (proximity sorting, Quality + ATR distance filtering, neutral node deactivation, SSL/BSL target mapping, and fallback bypasses).
*   [TestSnr.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSnr.mq5): Visual test EA for testing the entire 3-engine pipeline. Supports visual display modes (`DISPLAY_DEV`, `DISPLAY_ANALYST`, and `DISPLAY_TRADER`).

### Specifications & Single Source of Truth (SSOT)
*   [PROJECT_GENESIS.md](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md): Master project bible.
*   [PROJECT_MEMORY.md](file:///c:/xauusd_chatgpt/docs/core/PROJECT_MEMORY.md): Living memory of the project (status, resolved issues, rejected concepts, decisions).
*   [SYSTEM_ROADMAP.md](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md): Roadmap of development phases.
*   [MILESTONE_SPRINT_3_FREEZE.md](file:///c:/xauusd_chatgpt/MILESTONE_SPRINT_3_FREEZE.md): Detailed freeze snapshot of Sprint 3.

---

## 3. The Development & Test Cycle

We compile and run backtests using PowerShell scripts that coordinate with MetaEditor and MetaTrader 5. All temporary scripts, configurations, and logs are kept in the scratch folder:
`C:\Users\rositapermata33\.gemini\antigravity-ide\scratch`

### Step 1: Sync & Compile
To sync your changes to the MT5 terminal folder and compile the EAs, execute the copy-and-compile script:
```powershell
powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\copy_and_compile.ps1
```
*What this script does*:
1. Copies all modified engine header files from `src/engines/` to the terminal MQL5 workspace under `Include/engines/`.
2. Copies all test EAs from `src/tests/` to the terminal MQL5 workspace under `Experts/tests/`.
3. Launches MetaEditor synchronously (`/compile` and `/log` switches) and waits for compilation.
4. Copies the compiler log from `Terminal\logs\metaeditor.log` to `scratch\compile.log`.

### Step 2: Run Backtest
To execute the MT5 Strategy Tester offline and generate structural data logs, run:
```powershell
powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\run_snr_backtest.ps1
```
*What this script does*:
1. Launches MT5 Terminal with the configuration from `scratch\tester_config_snr.ini`.
2. Runs the backtest on XAUUSDm, H4, from `2025.10.01` to `2025.12.31`.
3. Shuts down the terminal automatically and copies the latest agent log file to `scratch\latest_snr_run.log`.

---

## 4. Key Implementation Rules for Future Work

When you begin writing **Module 4 (Liquidity Engine)**:
1.  **Read the Contracts**: Read `SnrPriorityContract` definition in [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh) and verify its usage.
2.  **No Redesign**: Under no circumstances should you modify the scoring weights, the priority engine calculations, or the contract structure of Sprint 3. All modules are frozen.
3.  **Strict Performance Constraints**: Keep price history scans bounded. Gate calculations strictly on H4 bar closes to prevent Strategy Tester lag.
4.  **Preserve Backward Compatibility**: Ensure that includes work cleanly and do not trigger MQL5 compiler errors in upstream test scripts.

---

## 5. Verification Checklists

Before declaring any future work complete, you must:
- `[ ]` Compile the EA and verify `0 errors, 0 warnings` in `compile.log`.
- `[ ]` Run a Strategy Tester backtest using the PowerShell runner.
- `[ ]` Inspect the agent logs to verify math.
- `[ ]` Confirm that no signals repaint (no Bar 0 ticks triggering state changes).
- `[ ]` Document your findings, log outputs, and verification metrics in an updated walkthrough or audit report.
