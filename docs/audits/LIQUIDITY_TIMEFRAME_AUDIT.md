# Liquidity Timeframe Audit

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: COMPLETE  
**Workspace**: `c:\xauusd_chatgpt`  
**Reference Design**: [LIQUIDITY_ENGINE_DESIGN.md](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md)  
**Reference Audit**: [LIQUIDITY_RESPONSIBILITY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_RESPONSIBILITY_AUDIT.md)

---

## 1. Executive Summary

This design consistency audit resolves the origin and architectural justification of the **M30 timeframe dependency** in the **Phase 4 Liquidity Engine** prior to the finalization of the Phase 4 Architecture Freeze. 

A thorough audit of the project repository reveals that the M30 dependency is a **formally approved project decision** and an **implied dependency** established at the project's genesis (Version 1.0) within the master Single Source of Truth (SSoT) files. It is **not** a new recommendation. 

This document traces the evidence of this timeframe decision, evaluates the architectural necessity of a dual-timeframe model (H4+M30) versus an H4-only model, analyzes the technical complexity impact of multi-timeframe synchronization inside MetaTrader 5, and provides a formal recommendation for the timeframe model.

---

## 2. Timeframe Traceability Matrix (Evidence)

The M30 timeframe dependency is deeply rooted in the system's baseline architecture. Below is the compiled evidence of its origin across all design, roadmap, memory, and freeze documents:

| Source Document | Path & Code Reference | Context & Architectural Role | Status |
|:---|:---|:---|:---|
| **01_MARKET_DEFINITIONS.md** | [01_MARKET_DEFINITIONS.md:L25-33](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md#L25-L33) | Defines `Primary Analysis TF: H4`, `Execution TF: M30`, and `Confirmation TF: M15`. Established as the Single Source of Truth (SSoT). | **FROZEN (v1.0)** |
| **02_SYSTEM_ARCHITECTURE.md** | [02_SYSTEM_ARCHITECTURE.md:L145-149](file:///c:/xauusd_chatgpt/docs/core/02_SYSTEM_ARCHITECTURE.md#L145-L149) | Explicitly lists inputs for `MODULE 5 LIQUIDITY ENGINE` (numbered 5 in architecture SSoT, 4 in roadmap) as: `H4`, `M30`. | **FROZEN (v1.0)** |
| **PROJECT_GENESIS.md** | [PROJECT_GENESIS.md:L31-40](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md#L31-L40)<br>[PROJECT_GENESIS.md:L162](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md#L162) | Graphically diagrams `[LiquidityEngine] (H4/M30)` and downstream execution modules `[EntryEngine] (M30)`, `[RiskEngine] (M30)`, and `[ExecutionEngine] (M30)`. Sets the Phase 4 goal to detect stop-loss pools on `H4/M30`. | **FINAL (SSoT)** |
| **SYSTEM_ROADMAP.md** | [SYSTEM_ROADMAP.md:L46-50](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md#L46-L50) | Outlines `Phase 5 — Trade Entry Engine` as the component that "refines the H4 structural bias on the M30 execution timeframe" and validates entry setups on M30. | **APPROVED BASELINE** |
| **RECOVERY_REPORT.md** | [RECOVERY_REPORT.md:L12-16](file:///c:/xauusd_chatgpt/docs/reports/RECOVERY_REPORT.md#L12-L16) | States the system's permanent mission is to trade Gold on the `H4` and `M30` timeframes to exploit order blocks and liquidity sweeps. | **FINAL** |
| **LIQUIDITY_ENGINE_DESIGN.md** | [LIQUIDITY_ENGINE_DESIGN.md:L101-104](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L101-L104) | Specifies that the `Primary Scanner` runs on H4 to map major structure, while the `Intraday Scanner` runs on M30 to detect micro-structure sweeps. | **FREEZE CANDIDATE** |
| **LIQUIDITY_RESPONSIBILITY_AUDIT.md** | [LIQUIDITY_RESPONSIBILITY_AUDIT.md:L43](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_RESPONSIBILITY_AUDIT.md#L43) | Defines **Intraday Sweep Detection** as an approved Phase 4 scope: scanning M30 ticks/candles to detect stop runs *within* H4-defined pools before H4 close. | **APPROVED & COMPLETE** |

> [!NOTE]  
> **Verdict**: The M30 timeframe is a **formally approved project decision** and an **implied dependency** of the downstream execution engines. It is not a new recommendation.

---

## 3. Timeframe Model Architectural Comparison

To validate the engineering rationale behind the approved model, this section compares an **H4-Only Architecture** against the approved **H4+M30 Dual Timeframe Architecture**.

### 3.1 Architectural Layouts

```
H4-ONLY ARCHITECTURE (Simple but Lagging)
[H4 Market Structure] ──> [H4 Supply/Demand] ──> [H4 SNR Priority] ──> [H4 Liquidity Sweep] ──> [H4 Entry Signal]
                                                                                                 (Execution delayed)

H4+M30 DUAL TIMEFRAME ARCHITECTURE (High-Precision Execution)
[H4 Market Structure] ──> [H4 Supply/Demand] ──> [H4 SNR Priority] (Nearest BSL/SSL Pools)
                                                          │
                                                          ▼ (Read Pool Coordinates)
                                               [M30 Liquidity Scanner] (Intraday Sweeps) ──> [M30 Entry Setup]
                                                                                             (Immediate Execution)
```

### 3.2 Feature-by-Feature Comparison Matrix

| Architectural Dimension | H4-Only Architecture | H4+M30 Dual Timeframe Architecture | Rationale & Trade-off |
|:---|:---|:---|:---|
| **Entry Precision** | Low. Sweep signals are only processed on H4 candle closes (once every 4 hours). | High. Sweep signals are processed on M30 candle closes (once every 30 minutes). | Intraday price spikes are captured and capitalized on immediately rather than waiting hours. |
| **Risk-to-Reward (R:R) Ratio** | Poor. Reversal entries occur far from the sweep origin after the H4 candle closes, resulting in wider stop-losses. | Excellent. Entries occur near the sweep origin on M30, enabling tight stop-losses and higher R:R. | Gold is highly volatile; a 4-hour delay can erase the entire profit margin of a reversal setup. |
| **Wick Sweep Capture** | Failed. Wicks that sweep a level and pull back within a single H4 candle are invisible to closed H4 scans. | Successful. M30 scanner captures intraday candle closures and excursions within the H4 pool boundaries. | The majority of institutional stop runs are short-lived wicks on H4 that are represented as bodies/closes on M30. |
| **Execution Latency** | High (up to 4 hours). | Low (maximum 30 minutes). | Direct alignment with the system's execution goals. |
| **Downstream Compatibility** | Incompatible. Downstream entry and risk engines are designed to execute on M30. | Compatible. Feeds real-time M30 sweep events directly to the entry validation layers. | Downstream modules expect M30 inputs; H4-only would force a redesign of the entire entry/execution logic. |
| **Strategy Tester Complexity** | None. No cross-timeframe data synchronization required. | Moderate to High. Multi-timeframe data alignment requires strict caching rules. | High execution edge is paid for with technical complexity (mitigation is required). |
| **Performance Overhead** | Minimal. Runs once per H4 bar close (6 times/day). | Moderate. Runs on M30 bar closes and ticks. | Negligible difference on modern hardware; M30 execution is highly optimized. |

---

## 4. Complexity Analysis & MQL5 Technical Risks

Implementing a dual-timeframe (H4+M30) model in MetaTrader 5 introduces specific engineering risks that were previously exposed during the validation of the Structure Engine. These risks must be resolved in the design of the Liquidity Engine.

### 4.1 The MT5 Strategy Tester Synchronization Risk

As documented in [LESSONS_LEARNED.md:L219-254](file:///c:/xauusd_chatgpt/docs/core/LESSONS_LEARNED.md#L219-L254) (Bug 5), copying data from a timeframe other than the tester's active chart timeframe is **asynchronous** in MT5. 

If the EA is running backtests on M30 (which is required since execution is on M30), accessing H4 data via platform indicator handles (e.g. `iATR` or `iTime` on `PERIOD_H4`) will occasionally return `0.0` or fail to synchronize during tick updates. This occurs because the Strategy Tester runs multi-timeframe engines on separate threads, and the H4 historical database may not have synchronized to the active M30 tester clock at the moment of the tick.

### 4.2 Mitigation Rules (The Local Caching Protocol)

To resolve the multi-timeframe complexity and prevent repainting or synchronization failures, the `CLiquidityEngine` must implement the following **Local Caching Protocol**:

1.  **Eliminate Asynchronous Indicator Handles**:
    *   `CLiquidityEngine` must **never** create indicator handles (`iATR`, etc.) for the H4 timeframe.
    *   All ATR calculations for H4 must be done **locally and synchronously** using raw cached H4 OHLC price data, complying with the *Local ATR Principle*.
2.  **Synchronous Price Data Caching**:
    *   During initialization and at the open of each new bar, the engine must copy H4 price history (`Open[]`, `High[]`, `Low[]`, `Close[]`, `Time[]`) and M30 price history into **local private arrays**.
    *   The return values of `CopyHigh()`, `CopyLow()`, `CopyClose()`, and `CopyTime()` must be strictly verified. If the returned count is less than the requested bars, the engine must abort execution for that tick and wait for the next tick to prevent processing unaligned data.
3.  **Strict Bar Alignment**:
    *   When mapping an M30 sweep event to an H4-defined pool, the engine must use `iBarShift()` or synchronous time comparison to locate the exact H4 bar index that corresponds to the sweeping M30 bar. This ensures that the age decay calculation remains directionally correct.
4.  **No Upstream Modification**:
    *   `CLiquidityEngine` is a **downstream consumer**. It reads from `SnrPriorityContract` (supplied by the frozen `CSnrPriorityEngine`) and the cached price arrays. It must never attempt to modify the state of the Structure, SupplyDemand, or SNR engines.

---

## 5. Final Conclusion & Architectural Recommendation

### 5.1 Approved Timeframe Model

The approved timeframe model for the trading system is the **Dual-Timeframe Analysis and Execution Model**:

*   **Primary Analysis Timeframe (H4)**: Used for market structure trend classification, Supply/Demand zone identification, and SNR level prioritization (identifying the boundaries of the nearest BSL and SSL pools).
*   **Execution Timeframe (M30)**: Used for real-time liquidity sweep (stop run) detection, entry trigger validation (e.g., engulfing, pinbars), lot size computation, and trade execution management.

```
+-------------------------------------------------------------+
|                     DUAL-TIMEFRAME PIPELINE                 |
+-------------------------------------------------------------+
|                                                             |
| H4 TIMEFRAME (Structural Mapping)                           |
|   - Market Structure (HH/HL/LH/LL, BOS, MSS)                |
|   - Supply & Demand Zone Inception & Quality                |
|   - SNR Priority Contract (Nearest BSL/SSL Boundaries)      |
|                                                             |
|                          │                                  |
|                          ▼ (Pass Pool Boundaries)           |
|                                                             |
| M30 TIMEFRAME (Tactical Execution)                          |
|   - Real-time Liquidity Sweep Scanner (Within H4 Pools)      |
|   - Reversal Entry Signal Generation (Engulfing/Pinbar)     |
|   - Fixed 1% Risk Lot Sizing & Order Routing                |
|                                                             |
+-------------------------------------------------------------+
```

### 5.2 Evidence Summary
*   **Genesis Intent**: The dual-timeframe pipeline (H4 analysis with M30 execution) was written into the project's baseline files (`01_MARKET_DEFINITIONS.md`, `02_SYSTEM_ARCHITECTURE.md`, `PROJECT_GENESIS.md`) during Version 1.0. 
*   **Responsibility Boundary**: The recently approved `LIQUIDITY_RESPONSIBILITY_AUDIT.md` explicitly designated "Intraday Sweep Detection" on the M30 timeframe as an active target for Phase 4.

### 5.3 Architectural Impact
*   **Execution Advantage**: Capturing sweeps on M30 preserves a tight stop-loss and maximizes the R:R ratio on Gold. It captures intraday wicks that are completely invisible on H4 candle closes.
*   **Complexity Handling**: Requires the implementation of local price caching and synchronous copy validation in `CLiquidityEngine` to eliminate Strategy Tester asynchronous lags, preventing MT5 platform defects from corrupting swing grading and sweep detection.

### 5.4 Final Recommendation

1.  **Approve the M30 Dependency**: Formally confirm that the Liquidity Engine must monitor both the H4 timeframe (for pool coordinates) and the M30 timeframe (for intraday sweep detection).
2.  **Enforce the Local Caching Protocol**: Require that the implementation of `CLiquidityEngine` use local, synchronous price caches and direct ATR calculations. The architecture freeze candidate must explicitly include these caching parameters and copy checks.
3.  **Downstream Signal Alignment**: Ensure that the `LiquidityPriorityContract` outputs transient flags (e.g. `isBSLSweptThisBar`) that correspond to closed M30 bars, enabling the downstream Entry Engine to execute setups on the M30 chart.

---
*Audit completed, validated, and signed on June 13, 2026.*
