# Liquidity Engine v1.0 - Architectural Design Freeze

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: DESIGN FREEZE CANDIDATE (Awaiting Owner Review)  
**Target Module**: `LiquidityEngine.mqh` (Phase 4 v1.0)  
**Dependencies**: [SnrPriorityEngine.mqh (v1.0)](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh)

---

## 1. Introduction & Objectives

This document establishes the final, authoritative architectural design freeze specification for the **Phase 4 Liquidity Engine (Liquidity Engine v1.0)**. It synthesizes the approved findings and recommendations from [LIQUIDITY_RESPONSIBILITY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_RESPONSIBILITY_AUDIT.md) and [LIQUIDITY_TIMEFRAME_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_TIMEFRAME_AUDIT.md).

The Liquidity Engine acts as the bridge between the frozen H4 market structure/SNR mapping and the tactical M30 trade entry logic. Its primary mission is to scan M30 price data in real-time, detect stop runs (sweeps) occurring inside H4-defined Buy Stop Liquidity (BSL) and Sell Stop Liquidity (SSL) pools, classify their depth, and output trade signal coordinates downstream.

---

## 2. Module Responsibilities

To maintain modular boundaries and protect frozen upstream code, responsibilities are strictly separated between the newly planned class `CLiquidityEngine` and existing frozen engines.

### 2.1 Approved Scope (Phase 4 Active Target)
1.  **Intraday Sweep Scanning**: Scan M30 price history synchronously on every M30 bar close and tick to detect price penetrations inside active H4 liquidity pools.
2.  **Sweep Depth & Size Classification**: Measure stop-run excursion depths relative to local H4 ATR(14) and classify them (Minor, Medium, Major).
3.  **Real-Time State Tracking**: Maintain transient sweep indicators (e.g. `isBSLSweptThisBar`) that populate on the close of the sweeping M30 bar and clear on the next bar open.
4.  **Event Generation**: Compile details of completed sweeps into transient `LiquiditySweepEvent` structures to feed downstream entry logic.
5.  **Momentum Breakout Filtering**: Filter out high-volatility trend continuation breakouts (where stop runs fail to reject) to prevent entering counter-trend reversal trades.

### 2.2 Forbidden Scope (Sprint 3 SNR Preserved)
The following features are **strictly forbidden** to be implemented, recalculated, or modified in the Phase 4 engine, as they are already locked in the frozen Sprint 3 pipeline:
1.  **Liquidity Pool Boundary Calculation**: Identifying swing price levels and applying ATR tolerances to define the boundaries of BSL and SSL pools. (Locked in `CSnrEngine::MapLiquidityPools()`).
2.  **Liquidity Pool Strength Assignment**: Assigning baseline and decay scoring to liquidity pools. (Locked in `CSnrEngine::MapLiquidityPools()`).
3.  **Historical H4 Sweep Scanning**: Determining if closed H4 candles have previously run historical pools. (Locked in `CSnrEngine::MapLiquidityPools()`).
4.  **Nearest Active Pool Extraction**: Searching and exposing the active BSL/SSL pools nearest to current price. (Locked in `CSnrPriorityEngine::Process()`).
5.  **Upstream Modification**: Modifying private states, array dimensions, or public outputs of the Structure, SupplyDemand, SNR, or SNR Priority Engines.

---

## 3. Data Dependencies & Downstream Integration

The data pipeline is strictly unidirectional. `CLiquidityEngine` consumes the prioritized contract of Module 3 and outputs a specialized contract to feed Module 5:

```
[SnrPriorityEngine v1.0] (H4)
           │
           ▼ (Read-Only SnrPriorityContract)
+───────────────────────────────────────────────────────+
|                 CLiquidityEngine (v1.0)               | <─── (H4/M30 Price Feeds via Caching)
+───────────────────────────────────────────────────────+
           │
           ▼ (Expose LiquidityPriorityContract)
[EntryEngine (M30)] (Planned Module 5)
```

### 3.1 Input Dependency (`SnrPriorityContract`)
`CLiquidityEngine` imports the boundaries of the nearest active pools directly from the frozen contract exposed by the SNR Priority Engine:
*   `nearestBSL`: Mapped `LiquidityPool` structure representing the active buy stop pool residing above the nearest H4 swing high.
*   `hasBSL`: Boolean flag indicating if an active BSL pool exists.
*   `nearestSSL`: Mapped `LiquidityPool` structure representing the active sell stop pool residing below the nearest H4 swing low.
*   `hasSSL`: Boolean flag indicating if an active SSL pool exists.

### 3.2 Output Contract (`LiquidityPriorityContract`)
The Liquidity Engine packages the copied pool boundaries together with real-time sweep indicators and breakout signals into the `LiquidityPriorityContract` struct:

```cpp
//--- Downstream contract passed to the Entry Engine (Module 5)
struct LiquidityPriorityContract
{
   // 1. Core Boundaries copied from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // 2. Real-Time Sweep Triggers (Set on M30 bar closes, transient)
   bool           isBSLSweptThisBar;
   double         bslSweepSizeATR;     // Excursion depth relative to H4 ATR
   
   bool           isSSLSweptThisBar;
   double         sslSweepSizeATR;     // Excursion depth relative to H4 ATR
   
   // 3. Breakout Filter State (Transient)
   bool           isTrendBreakoutActive; // True if sweep size exceeds InpLiqSweepMaxSizeATR
};
```

---

## 4. Timeframe Interaction Model (H4/M30)

To resolve the asynchronous Strategy Tester synchronization delay inherent in MetaTrader 5 (as documented in the [LIQUIDITY_TIMEFRAME_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_TIMEFRAME_AUDIT.md)), `CLiquidityEngine` must implement the **Local Caching Protocol**.

### 4.1 The Local Caching Protocol
*   **Asynchronous Handle Prohibition**: The class `CLiquidityEngine` is **forbidden** from creating or calling platform indicator handles (`iATR`, `iMA`, etc.) for the H4 timeframe.
*   **Synchronous Price Cache Arrays**: The class must maintain internal private arrays to cache price history. During initialization and on each new M30 bar, the engine must copy H4 price data (`High`, `Low`, `Close`, `Time`) and M30 price data into these caches.
*   **Integrity Verification**:
    ```cpp
    // Ensure all data copies succeed before executing analysis
    if(CopyHigh(_Symbol, PERIOD_H4, 0, m_maxH4Bars, m_cachedH4Highs) <= 0 ||
       CopyTime(_Symbol, PERIOD_H4, 0, m_maxH4Bars, m_cachedH4Times) <= 0 ||
       CopyHigh(_Symbol, PERIOD_M30, 0, m_maxM30Bars, m_cachedM30Highs) <= 0 ||
       CopyClose(_Symbol, PERIOD_M30, 0, m_maxM30Bars, m_cachedM30Closes) <= 0)
    {
       if(m_enableLog) Print("[CLiquidityEngine] WARNING: H4/M30 Price Cache synchronization pending...");
       return false; // Abort tick execution, prevent stale calculations
    }
    ```
*   **Local Volatility Calculation**: ATR(14) on the H4 timeframe must be computed locally from `m_cachedH4Highs`, `m_cachedH4Lows`, and `m_cachedH4Closes` in memory to eliminate tester synchronization lag.

---

## 5. Sweep Detection Rules (Stop Runs)

Stop runs are scanned on closed M30 candles (`barIdx >= 1`) to eliminate repainting. 

```
BSL SWEEP DETECTION (STOP RUN REJECTION)
         
         High[barIdx] ──>  /\
  =========================│========================== nearestBSL.priceLow (Swing High Pivot)
                          /  \
                         /    \
         Close[barIdx] ──>───  \
                        /       \
  ---------------------/---------\-------------------- Price Action
                      /           \
```

### 5.1 Buy Stop Liquidity (BSL) Sweep Rules
A BSL sweep is confirmed on a completed M30 candle if:
1.  **Level Exceeded**: The high of the closed M30 bar exceeds the lower boundary of the nearest active BSL pool (which is the swing high pivot):
$$High[\text{barIdx}] > nearestBSL.priceLow$$
2.  **Price Rejected**: The close of the M30 bar returns below the swing high pivot price:
$$Close[\text{barIdx}] < nearestBSL.priceLow$$
3.  **Excursion and Size Computation**:
    *   *Excursion Depth*: $Excursion = High[\text{barIdx}] - nearestBSL.priceLow$
    *   *ATR-Relative Sweep Size*: 
$$SweepSize_{\text{ATR}} = \frac{Excursion}{ATR_{\text{H4}}}$$

### 5.2 Sell Stop Liquidity (SSL) Sweep Rules
An SSL sweep is confirmed on a completed M30 candle if:
1.  **Level Exceeded**: The low of the closed M30 bar drops below the upper boundary of the nearest active SSL pool (which is the swing low pivot):
$$Low[\text{barIdx}] < nearestSSL.priceHigh$$
2.  **Price Rejected**: The close of the M30 bar returns above the swing low pivot price:
$$Close[\text{barIdx}] > nearestSSL.priceHigh$$
3.  **Excursion and Size Computation**:
    *   *Excursion Depth*: $Excursion = nearestSSL.priceHigh - Low[\text{barIdx}]$
    *   *ATR-Relative Sweep Size*: 
$$SweepSize_{\text{ATR}} = \frac{Excursion}{ATR_{\text{H4}}}$$

### 5.3 Sweep Classification
Sweeps are classified to provide grading signals to downstream engines:
*   **Minor Sweep**: $SweepSize_{\text{ATR}} \le 0.25$
*   **Medium Sweep**: $0.25 < SweepSize_{\text{ATR}} \le 0.75$
*   **Major Sweep**: $0.75 < SweepSize_{\text{ATR}} \le InpLiqSweepMaxSizeATR$

---

## 6. Breakout Filter Rules

Reversal systems run the risk of trading directly into strong, momentum-driven trends (where stop runs fail to reject). To protect trading capital, the engine implements a breakout filter:

*   **Breakout Threshold**: Controlled by the input parameter `InpLiqSweepMaxSizeATR` (default = `1.50` H4 ATR). 
    > [!IMPORTANT]
    > **Status**: *Placeholder - Requires Validation*. No statistical evidence currently exists for this threshold. It must undergo empirical sensitivity analysis during testing to determine its optimal value.
*   **Trigger Condition**: If the ATR-relative sweep size on a closed M30 candle exceeds the breakout threshold:
$$SweepSize_{\text{ATR}} > InpLiqSweepMaxSizeATR$$
*   **Action**: The sweep is classified as a **Momentum Breakout** rather than a rejection. 
    *   `isTrendBreakoutActive` is set to `true`.
    *   Transient sweep triggers (`isBSLSweptThisBar`, `isSSLSweptThisBar`) are suppressed.
    *   This state blocks Module 5 from generating counter-trend reversal orders.
*   **Lifespan**: The breakout filter remains active for the duration of the current bar and resets on the next bar close.

---

## 7. Target MQL5 Data Structures

### 7.1 `LiquiditySweepEvent` Struct
Used to record confirmed stop-run events for logging, stats analysis, and downstream confirmation:
```cpp
struct LiquiditySweepEvent
{
   int       poolId;             // Unique ID of the swept pool
   double    sweepPrice;         // Maximum price depth reached (High/Low)
   double    closePrice;         // Close price of the sweeping bar
   double    sweepSizeATR;       // Excursion distance relative to H4 ATR
   datetime  sweepTime;          // Open time of the sweeping bar
   bool      isBuyStopSweep;     // true = BSL swept, false = SSL swept
   int       sweepBarIndex;      // M30 bar index where sweep occurred
};
```

---

## 8. Public Interface (`CLiquidityEngine`)

The class `CLiquidityEngine` will be implemented inside `src/engines/LiquidityEngine.mqh` using the following public API structure:

```cpp
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

#include "SnrPriorityEngine.mqh"

//=========================================================
// INPUT PARAMETERS
//=========================================================
input double InpLiqSweepMinSizeATR  = 0.05;   // Minimum sweep excursion (ATR)
input double InpLiqSweepMaxSizeATR  = 1.50;   // Maximum sweep excursion (Placeholder - Requires Validation)
input bool   InpLiqEnableLog        = true;   // Enable print diagnostics

//=========================================================
// CLASS: CLiquidityEngine
//=========================================================
class CLiquidityEngine
{
private:
   //--- Reference Pointers
   CSnrPriorityEngine*  m_priorityEngine;
   
   //--- Internal State
   LiquidityPriorityContract m_activeContract;
   LiquiditySweepEvent       m_sweepEvents[];  // Registered sweep history
   
   //--- Local Price Caches (Local Caching Protocol)
   double            m_cachedH4Highs[];
   double            m_cachedH4Lows[];
   double            m_cachedH4Closes[];
   datetime          m_cachedH4Times[];
   int               m_maxH4Bars;
   
   double            m_cachedM30Highs[];
   double            m_cachedM30Lows[];
   double            m_cachedM30Closes[];
   datetime          m_cachedM30Times[];
   int               m_maxM30Bars;
   
   //--- Settings
   double            m_sweepMinSizeATR;
   double            m_sweepMaxSizeATR;
   bool              m_enableLog;
   
   //--- Private Utility Methods
   double            GetLocalH4ATR(int barIndex);
   bool              SyncPriceCaches();
   void              RegisterSweepEvent(int poolId, double sweepPrice, double close, 
                                        double sizeATR, datetime time, bool isBSL, int barIdx);
   void              LogMessage(string message);

public:
                     CLiquidityEngine();
                    ~CLiquidityEngine();
                    
   //--- Initialization / Deinitialization
   bool              Init(CSnrPriorityEngine* priorityEngine);
   void              Deinit();
   
   //--- Core Scan Pipeline (Called on every tick / M30 bar)
   bool              Analyze(int barsToCache = 300);
   
   //--- Accessors
   LiquidityPriorityContract GetContract() const { return m_activeContract; }
   int                       GetSweepEventCount() const { return ArraySize(m_sweepEvents); }
   bool                      GetSweepEvent(int index, LiquiditySweepEvent &event);
};
```

---

## 9. Verification & Validation Protocol

Before Module 4 can be frozen and approved for integration, the implementation must pass the following verification and validation protocols:

### 9.1 Technical Compiler Verification
*   **Test Script**: Build `src/tests/TestLiquidity.mq5` which instantiates the downstream pipeline (`CStructureEngine` $\rightarrow$ `CSupplyDemandEngine` $\rightarrow$ `CSnrEngine` $\rightarrow$ `CSnrPriorityEngine` $\rightarrow$ `CLiquidityEngine` without passing the structure engine pointer directly to the liquidity engine).
*   **Verification Rule**: Compilation must result in **0 errors and 0 warnings** in the MetaEditor.

### 9.2 Synchronization & Stability Tests
*   **Asynchronous Check**: Run `TestLiquidity` inside the MT5 Strategy Tester under tick simulation on `XAUUSD` M30 timeframe.
*   **Validation Rule**: The tester logs must show zero ATR failure warnings and zero array out-of-range errors. Price cache checks must return `true` on 100% of processed ticks.

### 9.3 Sweep Detection Accuracy Verification
The engine's scan outputs will be audited against a validation set of **10 concrete historical chart cases** spanning `2024.12.29` to `2025.01.15`.
1.  **Excursion Precision**: The computed `sweepPrice` and `closePrice` in `LiquiditySweepEvent` must match the MT5 chart OHLC values down to 3 decimal places.
2.  **Breakout Block Validation**: In the event of a high-momentum breach exceeding the breakout threshold, logs must verify that `isTrendBreakoutActive = true` was set, and `isBSLSweptThisBar`/`isSSLSweptThisBar` were correctly set to `false`.
3.  **Breakout Filter Optimization Requirement**: A sensitivity analysis must be executed during Phase 4.1 testing. The breakout filter `InpLiqSweepMaxSizeATR` must be tested across a range of values (e.g. `0.75` ATR to `2.00` ATR in increments of `0.25`) to empirically determine the optimal threshold that filters out genuine breakouts while retaining stop run reversals.

---
*End of Phase 4.0B Architectural Freeze Document.*
