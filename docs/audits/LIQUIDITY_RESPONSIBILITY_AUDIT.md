# Liquidity Responsibility Audit

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: APPROVED & COMPLETE  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Executive Summary

This audit establishes the exact architectural boundary of **Phase 4 (Liquidity Engine)**. A deep review of the frozen Sprint 3 pipeline (`CSnrEngine` v1.0 and `CSnrPriorityEngine` v1.0) reveals that liquidity pool mapping, boundary calculations, and historical H4 sweep detection have already been completed and frozen.

To prevent duplicate sources of truth, redundant performance overhead, and circular dependencies, this audit defines which responsibilities are **forbidden** for Phase 4 (already solved in the freeze) and which are **approved** (unsolved real-time sweep tracking and event generation).

---

## 2. Liquidity Responsibility Evidence Matrix

| Engine Module | Solved Liquidity Features | Code References | Architectural Output |
|:---|:---|:---|:---|
| **Structure Engine** | Swing point identification, reaction counting, baseline strength, and invalidation status. | [StructureEngine.mqh L105-119](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L105-L119) | `SwingPoint` array containing `price`, `reactionCount`, `strengthScore`, and `isInvalidated`. |
| **SnrEngine** | Definition of `LiquidityPool` structure, boundary calculations (swing $\pm$ tolerance), and historical H4 sweep detection. | [SnrEngine.mqh L136-156](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh#L136-L156)<br>[SnrEngine.mqh L1086-1167](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh#L1086-L1167) | `m_liquidityPools` array representing all mapped and historically swept BSL and SSL pools. |
| **SnrPriorityEngine** | Separation and tracking of the nearest active (unswept) BSL and SSL pools relative to price. | [SnrPriorityEngine.mqh L37-43](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh#L37-L43)<br>[SnrPriorityEngine.mqh L476-512](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh#L476-512) | Bounded `nearestBSL` and `nearestSSL` fields inside the frozen `SnrPriorityContract`. |

---

## 3. Existing & Forbidden Responsibilities (Phase 3 Resolved)

The following responsibilities are **already solved** in the frozen Sprint 3 pipeline and are **strictly forbidden** to be rebuilt or modified in Phase 4:

1.  **Pool Boundary Calculation**: Calculating upper/lower bounds of stop clusters based on ATR (e.g. `swing.price` $\pm$ `0.10 × ATR`). This is locked in `CSnrEngine::MapLiquidityPools()`.
2.  **Pool Strength Assignment**: Calculating strength based on constituent swing scores and age. This is locked in `CSnrEngine::MapLiquidityPools()`.
3.  **Historical H4 Sweep Scanning**: Checking if closed H4 bars have already swept a pool in the past. This is locked in `CSnrEngine::MapLiquidityPools()`.
4.  **Nearest Active Pool Extraction**: Finding and exposing the nearest active BSL (above price) and SSL (below price) boundaries. This is locked in `CSnrPriorityEngine::Process()`.

---

## 4. Unsolved & Approved Responsibilities (Phase 4 Active Target)

The following responsibilities are **unsolved** by the frozen pipeline and represent the **only approved scope** for Phase 4:

1.  **Intraday Sweep Detection**: Scanning the **M30 timeframe** ticks and completed M30 candles to detect stop runs *within* the H4-defined BSL/SSL pools before the H4 bar closes.
2.  **Sweep Size & Excursion Classification**: Measuring the depth of the price sweep relative to ATR and classifying it (Minor vs. Medium vs. Major sweep).
3.  **Real-time Sweep State Tracking**: Setting and clearing transient sweep flags (e.g. `isBSLSweptThisBar`) that reset on subsequent bar closes.
4.  **Liquidity Event Generation**: Generating a transient `LiquiditySweepEvent` structure (containing pool ID, sweep size, excursion price, close price, and timeframe) to feed the Entry Engine reversal triggers.
5.  **Breakout Filtering**: Analyzing sweep sizes to flag if a breach is a breakout (trend continuation) rather than a sweep (reversal), blocking entries on high-volatility breaks.

---

## 5. Dependency Diagram

The data flow is strictly unidirectional. The Liquidity Engine consumes the frozen contract from the Priority Engine and exposes sweep events downstream:

```
[StructureEngine v2.2]
        │
        ▼ (Major Swings)
[SupplyDemandEngine v1.1]
        │
        ▼ (Active/Invalidated Zones)
[SnrEngine v1.0] 
        │
        ▼ (All mapped LiquidityPools)
[SnrPriorityEngine v1.0]
        │
        ▼ (SnrPriorityContract containing nearestBSL / nearestSSL)
+-----------------------+
|  CLiquidityEngine     | <─── (H4/M30 Price Feeds)
|  [Active Phase 4]     |
+-----------+-----------+
            │
            ▼ (LiquidityPriorityContract containing sweep events)
[EntryEngine (M30)] (Planned)
```

---

## 6. Recommended Phase 4 Scope v1.0

### Architectural Ruling: **Option B (Consume and Generate Events)**

It is formally ruled that the Liquidity Engine **must not create liquidity pools**. It must act as a downstream consumer of the `SnrPriorityContract`, reading the pre-calculated boundaries of the nearest BSL and SSL pools, and focus on monitoring price action to detect and classify sweeps.

### Interface Specification: `CLiquidityEngine`

The Liquidity Engine will expose the following interface to downstream modules:

```mql5
//--- Represents a stop-run execution event
struct LiquiditySweepEvent
{
   int       poolId;             // Unique ID of the swept pool
   double    sweepPrice;         // Maximum price depth reached during sweep
   double    closePrice;         // Close price of the sweeping bar
   double    sweepSizeATR;       // Excursion distance relative to ATR
   datetime  sweepTime;          // Timestamp of sweep event
   bool      isBuyStopSweep;     // true = BSL swept, false = SSL swept
   int       sweepBarIndex;      // Bar index where sweep closed
};

//--- Contract passed to downstream Entry Engine
struct LiquidityPriorityContract
{
   // Active boundaries copied from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   LiquidityPool  nearestSSL;
   bool           hasSSL;

   // Sweep events registered on the current bar close
   bool           isBSLSweptThisBar;
   double         bslSweepSizeATR;
   
   bool           isSSLSweptThisBar;
   double         sslSweepSizeATR;

   // Breakout filter (True if sweep size exceeds threshold, e.g., 1.50 ATR)
   bool           isBreakoutActive;
};
```

---
*Audit completed, validated, and locked on June 13, 2026.*
