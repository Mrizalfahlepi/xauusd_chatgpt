# 08_AGENT_ONBOARDING.md

Version: 1.0  
Date: 2026-06-12  
Status: Active  

---

## Welcome, Agent!

This document is your guide to understanding, compiling, testing, and expanding the **XAUUSD Institutional Structure EA** codebase. As an agentic coding assistant, you must be extremely thorough, maintain strict documentation integrity, and follow our architectural boundaries.

---

## 1. Project Orientation & Philosophy

Before you touch any code, you must understand our core philosophy:
1.  **No Lagging Indicators**: The EA reads the market structure directly using price actions: fractal swings, breakouts, order blocks, and liquidity pools. Traditional indicators (RSI, MACD, Stochastic) are prohibited for entry decisions.
2.  **Order of Execution**: Market Structure → Supply Demand → SNR → Entry → Risk → Execution.
3.  **Strict Boundaries**: Do not start building a module until its preceding module is completed and verified. Currently:
    *   **Module 1 (Market Structure Engine)**: Completed, validated, and signed off in version 2.2.
    *   **Module 2 (Supply & Demand Engine)**: The next authorized module to build.

---

## 2. File Layout & Workspace Structure

### Core Files
*   [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh): The primary market structure engine module. It handles swing detection, grading, BOS/MSS, reactions, and trend state calculations.
*   [TestStructure.mq5](file:///c:/xauusd_chatgpt/src/tests/TestStructure.mq5): The visual test Expert Advisor. It includes the engine, processes ticks, draws structural lines (swings, BOS, MSS) on the H4 chart, and logs summaries.

### Specifications & Single Source of Truth (SSOT)
*   [PROJECT_MEMORY.md](file:///c:/xauusd_chatgpt/docs/core/PROJECT_MEMORY.md): The living memory of the project. Read this first to align on decisions, status, and priorities.
*   [01_MARKET_DEFINITIONS.md](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md): The mathematical definitions of swings, BOS, MSS, impulse, base, and zones.
*   [02_SYSTEM_ARCHITECTURE.md](file:///c:/xauusd_chatgpt/docs/core/02_SYSTEM_ARCHITECTURE.md): The system diagram, data flow, and module layouts.
*   [03_CODING_RULES.md](file:///c:/xauusd_chatgpt/docs/core/03_CODING_RULES.md): The strict coding standards (variable naming, function sizes, magic numbers, performance constraints).
*   [04_DESIGN_DECISIONS.md](file:///c:/xauusd_chatgpt/docs/core/04_DESIGN_DECISIONS.md): Records the root causes and implementations of all major architectural fixes.
*   [05_CURRENT_STATUS.md](file:///c:/xauusd_chatgpt/docs/core/05_CURRENT_STATUS.md): Current phase, roadmap, parameters, and tester verification metrics.
*   [STRUCTURE_ENGINE_V22_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/STRUCTURE_ENGINE_V22_AUDIT.md): Detailed verification audit log showing evidence for the v2.2 sign-off.

---

## 3. The Development & Test Cycle

We compile and run backtests using PowerShell scripts that coordinate with MetaEditor and MetaTrader 5. All temporary scripts, configurations, and logs are kept in the scratch folder:
`C:\Users\rositapermata33\.gemini\antigravity-ide\scratch`

### Step 1: Modify Workspace
When modifying [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh) or [TestStructure.mq5](file:///c:/xauusd_chatgpt/src/tests/TestStructure.mq5), work directly inside the workspace folder `c:\xauusd_chatgpt`.

### Step 2: Copy & Compile
To sync your changes to the MT5 terminal folder and compile the EA, execute the copy-and-compile script:
```powershell
powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\copy_and_compile.ps1
```
*What this script does*:
1. Copies `StructureEngine.mqh` to the terminal's `MQL5\Experts\` and `MQL5\Include\` folders.
2. Copies `TestStructure.mq5` to the terminal's `MQL5\Experts\` folder.
3. Launches MetaEditor synchronously (`/compile` and `/log` switches) and waits for compilation.
4. Copies the compiler log from `Terminal\logs\metaeditor.log` to `scratch\compile.log` so you can verify `0 errors, 0 warnings`.

### Step 3: Run Backtest
To execute the MT5 Strategy Tester offline and generate structural data logs, run:
```powershell
powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\run_backtest.ps1
```
*What this script does*:
1. Launches MT5 Terminal with the configuration from `scratch\tester_config.ini`.
2. Runs the backtest on XAUUSD, M30 from `2024.12.29` to `2025.01.15`.
3. Shuts down the terminal automatically when the backtest completes.
4. Searches the tester agent logs (`20260612.log` or matching current date) in the agent log directory, sorts by write time to find the newest run, and copies it to `scratch\latest_run.log`.

### Step 4: Parse & Audit Logs
To format, filter, and inspect the structural output summaries from your backtest, run:
```powershell
powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\parse_new_logs.ps1
```
*What this script does*:
1. Parses `scratch\latest_run.log` and extracts analysis summaries.
2. Formats trend transitions, swing highs/lows, reaction counts, and BOS events.
3. Saves a clean summary to `scratch\parsed_new_logs_summary.txt`.
4. Check this file to audit swing counts, verify consecutive trend states, and verify that no BOS repaints on Bar 0.

---

## 4. Key Implementation Rules for Future Work

When you begin writing **Module 2 (Supply & Demand Engine)**:
1.  **Read SSOT First**: Read [01_MARKET_DEFINITIONS.md](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md#L166-L210) to review the definitions of Impulse, Demand Zone, and Supply Zone.
2.  **Maintain Local Synchronous Calculations**: Do not create external timeframe handles or use lagging indicators. Read high-low-close data synchronously from the cached arrays built in `Analyze()`.
3.  **Strict Performance Constraints**: Do not scan the entire lookback history on every tick. Cache structural states and update incrementally on new bar arrival.
4.  **No Repainting**: Only finalize supply/demand zones when the forming H4 bar closes. Zones should not trigger or paint based on active uncompleted Bar 0 ticks.
5.  **Clean Log Statements**: Use the engine's `LogMessage()` method to document key structural events (e.g. `DEMAND ZONE CREATED`, `ZONE INVALIDATED`).

---

## 5. Verification Checklists

Before declaring any future work complete, you must:
- `[ ]` Compile the EA and verify `0 errors, 0 warnings` in `compile.log`.
- `[ ]` Run a Strategy Tester backtest using the PowerShell runner.
- `[ ]` Inspect the agent logs via the log parser.
- `[ ]` Confirm that no signals repaint (no Bar 0 triggers).
- `[ ]` Document your findings, log outputs, and verification metrics in an updated audit report.
