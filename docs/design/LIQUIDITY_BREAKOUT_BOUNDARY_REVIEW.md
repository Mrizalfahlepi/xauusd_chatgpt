# Liquidity Breakout Boundary Review

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: SUBMITTED FOR REVIEW  
**Workspace**: `c:\xauusd_chatgpt`  
**Reference Design**: [LIQUIDITY_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ARCHITECTURE_FREEZE.md)  
**Reference Roadmap**: [SYSTEM_ROADMAP.md](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md)

---

## 1. Executive Summary

This boundary review resolves a critical architectural question for Phase 4: **Does the Liquidity Engine provide liquidity intelligence, or does it make trading decisions?**

Specifically, we evaluate the boundary of the **Breakout Filter**. Currently, the freeze candidate defines the filter as an execution block that directly suppresses sweep events within `CLiquidityEngine`. This review compares this model (Option B: Direct Suppression) against a decoupled intelligence model (Option A: Exposure of Liquidity Metrics) to ensure strict adherence to the **Single Responsibility Principle (SRP)**.

Based on a review of the system's genesis files and design memory, this document recommends a clean decoupling where the Liquidity Engine remains a pure data provider, and the Entry Engine remains the sole trade decision module.

---

## 2. Option A: Liquidity Engine Provides Liquidity Intelligence
In this model, `CLiquidityEngine` acts strictly as an intelligence and measurement layer. It detects breaches, measures volatility-adjusted excursion depths, and flags high-volatility events as properties of the liquidity contract, leaving all trade-blocking decisions to downstream modules.

```
+--------------------------+                         +----------------------+
|  CLiquidityEngine (M30)  | ──(Exposes Metrics)───> |  CEntryEngine (M30)  |
|  - Tracks Sweep Events   |                         |  - Reads Excursion  |
|  - Measures Excursion    |                         |  - Evaluates Filter  |
|  - Flags Large Excursion |                         |  - Decides Trade Block|
+--------------------------+                         +----------------------+
```

### Arguments for Option A
1.  **Strict Adherence to SRP**: The Liquidity Engine's single responsibility is to identify and characterize liquidity events. Whether an event is "too large to trade" is an execution rule, not a liquidity mapping property. Option A keeps execution rules strictly inside `CEntryEngine`.
2.  **Decoupled Optimization**: The optimal threshold for filtering breakouts (e.g. 1.25 ATR vs 1.75 ATR) might vary depending on entry validation candle setups. If the Entry Engine receives the raw metrics, it can apply dynamic execution rules (e.g., blocking 1.0 ATR excursions for weak pinbars, but accepting up to 1.5 ATR excursions for strong engulfing rejections).
3.  **Consistency with Upstream Modules**: 
    *   `CStructureEngine` identifies BOS but does not decide trade bias.
    *   `CSupplyDemandEngine` scores zones but does not decide entry parameters.
    *   `CSnrPriorityEngine` groups and ranks levels but does not filter signals.
    *   Following this pipeline architecture, `CLiquidityEngine` should expose stop-run events and their physical dimensions, allowing downstream modules to decide trade eligibility.

---

## 3. Option B: Liquidity Engine Directly Blocks Reversal Setups
In this model, `CLiquidityEngine` acts as an active gatekeeper. It evaluates the breakout filter internally (`SweepSize > InpLiqSweepMaxSizeATR`). If exceeded, it suppresses the sweep signals (setting `isBSLSweptThisBar = false`) or flags an active execution block, directly preventing trade execution downstream.

```
+--------------------------+                         +----------------------+
|  CLiquidityEngine (M30)  | ──(Swept = false)─────> |  CEntryEngine (M30)  |
|  - Evaluates Threshold   |                         |  - Blind to Sweep    |
|  - Suppresses Event      |                         |  - No Trade Triggered|
+--------------------------+                         +----------------------+
```

### Arguments for Option B
1.  **Contract Simplicity**: Downstream engines do not need to parse multiple low-level variables (such as raw excursion prices, ATR volatility ratios, or risk levels). The contract is reduced to a simple binary state (swept or not swept).
2.  **Encapsulation of Volatility Mathematics**: All calculations involving ATR-relative ratios and boundaries are kept local to the engine that holds the price caches. The Entry Engine is shielded from physical market structure math and only processes execution-ready triggers.

---

## 4. Genesis Consistency Analysis

To resolve the boundary, we trace the structural roles defined at the project's inception (Version 1.0):

*   **Market SSoT**: In [01_MARKET_DEFINITIONS.md](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md), no trade filters or breakout thresholds are defined at the market definition level. 
*   **System Architecture SSoT**: In [02_SYSTEM_ARCHITECTURE.md:L141-180](file:///c:/xauusd_chatgpt/docs/core/02_SYSTEM_ARCHITECTURE.md#L141-L180):
    *   `MODULE 5 LIQUIDITY ENGINE` outputs: `Liquidity Map`, `Equal High`, `Equal Low`, and `Sweep Events`.
    *   `MODULE 6 ENTRY ENGINE` consumes these outputs and is defined as the module that validates reversal setups.
    *   *Finding*: The SSoT lists the output of the Liquidity Engine as factual **events** (`Sweep Events`), not filtered signals or trade blocks. The Entry Engine is the module tasked with validating the confluence of those events with zones.
*   **Project Roadmap SSoT**: In [SYSTEM_ROADMAP.md](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md):
    *   `Phase 4 — Liquidity Engine` purpose: "Identifies stop-loss clusters... Tracks sweep events when price runs these pools."
    *   `Phase 5 — Trade Entry Engine` purpose: "Refines the H4 structural bias... Validates entry setups... and places limit or market orders."
    *   *Finding*: Mapping and tracking are designated to Phase 4; validation and setup verification are designated to Phase 5. Suppressing a sweep event because the excursion was "too large" is a trade setup validation function.

---

## 5. Recommended Final Boundary

We recommend **Option A**. The Liquidity Engine must focus strictly on **liquidity intelligence**, providing raw stop-run metrics and breakout-risk indicators, while the Entry Engine remains the sole **trade decision module** that decides whether to block entries.

To preserve parameter encapsulation while respecting the Single Responsibility Principle, we define the following interface boundary:

### 5.1 Factual Metric Exposure (No Direct Suppression)
*   `CLiquidityEngine` will **never** suppress a sweep event. If price breaches a pool and closes outside, the engine must register `isBSLSweptThisBar = true` and record the event, regardless of how deep the excursion traveled.
*   The engine will calculate and expose the physical volatility-adjusted size of the sweep:
$$\text{sweepSizeATR} = \frac{\text{Excursion}}{\text{ATR}_{\text{H4}}}$$
*   The engine will compare this size to `InpLiqSweepMaxSizeATR` and expose a boolean flag `isLargeExcursion` (formerly `isTrendBreakoutActive`). This flag represents a factual structural condition (the stop run was exceptionally deep), not a trade block.

### 5.2 Decoupled Downstream Decision
*   The downstream Entry Engine (Module 5) will consume `isBSLSweptThisBar`, `bslSweepSizeATR`, and `isLargeExcursion`.
*   The Entry Engine's input parameters will control how to act on this intelligence:
    *   If `isLargeExcursion == true`, the Entry Engine's reversal logic will block the entry signal.
    *   If `bslSweepSizeATR` exceeds the Entry Engine's volatility parameters, the signal is blocked.
*   This preserves the single responsibility of each module: the Liquidity Engine measures the physical characteristics of the sweep, and the Entry Engine makes the final trading decision.

### 5.3 Updated Data Contract Specification
The `LiquidityPriorityContract` struct is updated to reflect this boundary:

```cpp
struct LiquidityPriorityContract
{
   // 1. Boundaries copied from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // 2. Real-Time Sweep Intelligence (Factual, never suppressed)
   bool           isBSLSweptThisBar;
   double         bslSweepSizeATR;     // Raw volatility-adjusted excursion depth
   
   bool           isSSLSweptThisBar;
   double         sslSweepSizeATR;     // Raw volatility-adjusted excursion depth
   
   // 3. Breakout Risk Indicator (Factual structural flag, not a trade block)
   bool           isLargeExcursion;    // True if sweep size exceeds InpLiqSweepMaxSizeATR
};
```

---
*End of Breakout Boundary Review.*
