# Liquidity Engine v1.0 - Implementation Plan

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: DESIGN FREEZE CANDIDATE (Awaiting Owner Review)  
**Target Module**: `LiquidityEngine.mqh` (Phase 4.1)  
**Dependencies**: [SnrPriorityEngine.mqh (v1.0)](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh)

---

## 1. File Layout

The implementation will introduce two new files to the workspace: a header class file and a validation test script. No other files will be modified.

1.  **Engine Interface Header**:
    *   **File Path**: `src/engines/LiquidityEngine.mqh` (NEW)
    *   **Purpose**: Contains the definition of `LiquidityPriorityContract` and the main engine class `CLiquidityEngine`.
2.  **Validation Test Expert Advisor**:
    *   **File Path**: `src/tests/TestLiquidity.mq5` (NEW)
    *   **Purpose**: Instantiates the entire trading pipeline, drives ticks through `CLiquidityEngine`, outputs logging diagnostics, renders visual markers, and validates sweep detection against historical test cases.

---

## 2. Class Design

The `CLiquidityEngine` is designed as a read-only downstream processor. It consumes the output contract of `CSnrPriorityEngine` and utilizes local price caching to prevent Strategy Tester thread synchronization errors.

```
+--------------------------------------------------------------+
|                       CLiquidityEngine                       |
+--------------------------------------------------------------+
| - m_priorityEngine : CSnrPriorityEngine*                     |
| - m_activeContract : LiquidityPriorityContract               |
| - m_cachedH4Highs[] : double                                 |
| - m_cachedH4Lows[] : double                                  |
| - m_cachedH4Closes[] : double                                 |
| - m_maxH4Bars : int                                          |
| - m_cachedM30Highs[] : double                                |
| - m_cachedM30Lows[] : double                                 |
| - m_cachedM30Closes[] : double                               |
| - m_maxM30Bars : int                                         |
| - m_sweepMaxSizeATR : double                                 |
| - m_enableLog : bool                                         |
+--------------------------------------------------------------+
| + Init(CSnrPriorityEngine*) : bool                           |
| + Deinit() : void                                            |
| + Analyze() : bool                                           |
| + GetContract() : LiquidityPriorityContract                  |
| - SyncPriceCaches() : bool                                   |
| - GetLocalH4ATR(int) : double                                |
+--------------------------------------------------------------+
```

### 2.1 Public Interface Specification (`LiquidityEngine.mqh`)

```cpp
//--- Downstream contract passed to the Entry Engine (Module 5)
struct LiquidityPriorityContract
{
   // Core boundaries copied directly from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // Real-Time Transient Triggers (Set on M30 bar closes, transient)
   bool           isBSLSweptThisBar;
   double         bslSweepSizeATR;     // Volatility-adjusted excursion depth
   
   bool           isSSLSweptThisBar;
   double         sslSweepSizeATR;     // Volatility-adjusted excursion depth
   
   // Breakout Risk Indicator (Factual structural flag, not a trade block)
   bool           isLargeExcursion;    // True if sweep size exceeds InpLiqSweepMaxSizeATR
};

class CLiquidityEngine
{
private:
   //--- Reference Pointers
   CSnrPriorityEngine*        m_priorityEngine;
   
   //--- Internal Output Contract
   LiquidityPriorityContract  m_activeContract;
   
   //--- Local Price Caches (Local Caching Protocol)
   double            m_cachedH4Highs[];
   double            m_cachedH4Lows[];
   double            m_cachedH4Closes[];
   int               m_maxH4Bars;
   
   double            m_cachedM30Highs[];
   double            m_cachedM30Lows[];
   double            m_cachedM30Closes[];
   int               m_maxM30Bars;
   
   //--- Settings
   double            m_sweepMaxSizeATR;       // Breakout threshold (Placeholder)
   bool              m_enableLog;
   
   //--- Private Helpers
   double            GetLocalH4ATR(int barIndex);
   bool              SyncPriceCaches();

public:
                     CLiquidityEngine();
                    ~CLiquidityEngine();
                    
   bool              Init(CSnrPriorityEngine* priorityEngine);
   void              Deinit();
   
   // Core scan pipeline (Evaluates M30 completed candle bar 1)
   bool              Analyze();
   
   // Contract Accessor
   LiquidityPriorityContract GetContract() const { return m_activeContract; }
};
```

---

## 3. Data Flow

Data flows unidirectionally from the prioritized SNR levels, through the local price caches, and downstream to the execution contract:

```
[SnrPriorityEngine v1.0] (H4)
           │
           ▼ (SnrPriorityContract containing nearestBSL / nearestSSL)
┌───────────────────────────────────────────────────────────┐
│                 CLiquidityEngine (M30)                    │
│                                                           │
│  [Local Caching Protocol]                                 │
│    CopyHigh/Low/Close(PERIOD_H4)  ──> m_cachedH4 arrays   │
│    CopyHigh/Low/Close(PERIOD_M30) ──> m_cachedM30 arrays  │
│                                                           │
│  [Local Volatility]                                       │
│    m_cachedH4 arrays              ──> local ATR(14)       │
│                                                           │
│  [Sweep Detection]                                        │
│    M30 Candle 1 High/Low          ──> Breach check        │
│    M30 Candle 1 Close             ──> Rejection check     │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼ (Populate Triggers & Excursions)
[LiquidityPriorityContract (M30)]
           │
           ▼
[EntryEngine (M30)] (Planned)
```

---

## 4. Build Order

The implementation will proceed in 7 sequential, verified steps:

### Step 1: Define Contracts
*   Create `src/engines/LiquidityEngine.mqh`.
*   Include `#include "SnrPriorityEngine.mqh"`.
*   Declare `LiquidityPriorityContract` struct and `CLiquidityEngine` class signature.

### Step 2: Implement Local Cache Layer
*   Write `CLiquidityEngine::SyncPriceCaches()` to copy H4 (300 bars) and M30 (300 bars) High, Low, Close price data.
*   Enforce return code validation on all `Copy*` functions; abort analysis if sync fails.
*   Write `CLiquidityEngine::GetLocalH4ATR()` to compute ATR(14) directly from the cached H4 arrays.

### Step 3: Implement Sweep Detection
*   Write the breach and rejection checks on M30 completed candle `barIdx = 1`:
    *   BSL Sweep: `High[1] > nearestBSL.priceLow` && `Close[1] < nearestBSL.priceLow`.
    *   SSL Sweep: `Low[1] < nearestSSL.priceHigh` && `Close[1] > nearestSSL.priceHigh`.

### Step 4: Implement Excursion Measurement
*   Compute raw excursion depth:
    *   BSL Excursion = `High[1] - nearestBSL.priceLow`.
    *   SSL Excursion = `nearestSSL.priceHigh - Low[1]`.
*   Convert excursion to ATR-relative units: `sweepSizeATR = Excursion / LocalH4ATR`.
*   Compare against `InpLiqSweepMaxSizeATR`. Set `isLargeExcursion = (sweepSizeATR > InpLiqSweepMaxSizeATR)`.

### Step 5: Output Contract
*   Copy boundaries (`nearestBSL`, `nearestSSL`, `hasBSL`, `hasSSL`) from `SnrPriorityContract`.
*   Populate transient triggers (`isBSLSweptThisBar`, `bslSweepSizeATR`, `isSSLSweptThisBar`, `sslSweepSizeATR`, `isLargeExcursion`).

### Step 6: Create Verification EA
*   Create `src/tests/TestLiquidity.mq5`.
*   Instantiate `CStructureEngine`, `CSupplyDemandEngine`, `CSnrEngine`, `CSnrPriorityEngine`, and `CLiquidityEngine`.
*   Implement `OnTick()` to drive the pipeline, calling `Analyze()` on new M30 bars.
*   Implement visual chart markers (e.g. `OBJ_ARROW_UP` for SSL sweeps, `OBJ_ARROW_DOWN` for BSL sweeps) to facilitate visual inspection.

### Step 7: Validation & Optimization
*   Compile all components.
*   Run the Strategy Tester backtest on `XAUUSD` M30 timeframe.
*   Execute the 10-case accuracy validation and parameter sensitivity checks.

---

## 5. Unit Test Plan

The unit test protocol inside `TestLiquidity.mq5` will validate the engine against **10 concrete historical chart cases** spanning `2024.12.29` to `2025.01.15`.

### 5.1 Historical Test Cases

| Case ID | Time (UTC) | Type | Swing Price (H4) | Expected Excursion | Expected Rejection |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **1** | 2024.12.30 08:30 | BSL Sweep | 2626.430 | High > 2626.430 | Close < 2626.430 |
| **2** | 2025.01.02 14:00 | SSL Sweep | 2618.520 | Low < 2618.520 | Close > 2618.520 |
| **3** | 2025.01.03 09:30 | BSL Sweep | 2635.800 | High > 2635.800 | Close < 2635.800 |
| **4** | 2025.01.06 18:00 | SSL Sweep | 2605.150 | Low < 2605.150 | Close > 2605.150 |
| **5** | 2025.01.07 11:30 | BSL Sweep | 2642.110 | High > 2642.110 | Close < 2642.110 |
| **6** | 2025.01.09 16:30 | SSL Sweep | 2612.300 | Low < 2612.300 | Close > 2612.300 |
| **7** | 2025.01.10 10:00 | BSL Sweep | 2650.000 | High > 2650.000 | Close < 2650.000 |
| **8** | 2025.01.13 13:30 | SSL Sweep | 2619.450 | Low < 2619.450 | Close > 2619.450 |
| **9** | 2025.01.14 09:00 | BSL Sweep | 2662.800 | High > 2662.800 | Close < 2662.800 |
| **10** | 2025.01.15 15:30 | SSL Sweep | 2630.120 | Low < 2630.120 | Close > 2630.120 |

### 5.2 Verification Assertions
*   **Assertion 1**: When a sweep occurs in the simulation, the engine must trigger `isBSLSweptThisBar = true` or `isSSLSweptThisBar = true` exactly on the open of the next M30 bar (representing completed candle evaluation of bar 1).
*   **Assertion 2**: The excursion size `bslSweepSizeATR` must match the actual candle breach distance divided by local H4 ATR down to 4 decimal places.
*   **Assertion 3**: If a breach exceeds the breakout limit (placeholder `1.50` ATR), the contract must return `isLargeExcursion = true` and keep `isBSLSweptThisBar = false` / `isSSLSweptThisBar = false`.

---

## 6. Visual Validation Plan

Manual visual verification is required to confirm that the engine is reading correct boundaries and registering sweeps accurately on the live chart interface.

1.  **Pool Boundary Lines**:
    *   `TestLiquidity.mq5` will draw horizontal dashed lines representing `nearestBSL.priceLow` (Red) and `nearestSSL.priceHigh` (Green) in real-time.
2.  **Sweep Arrows**:
    *   When a BSL sweep is registered on bar close, draw a **Red Down-Arrow** (`OBJ_ARROW_DOWN`) above the high of the sweeping bar.
    *   When an SSL sweep is registered, draw a **Green Up-Arrow** (`OBJ_ARROW_UP`) below the low of the sweeping bar.
3.  **Visual Anti-Repaint Check**:
    *   Confirm that arrow markers do not appear during the active tick of Bar 0.
    *   Confirm that once an arrow is drawn on Bar 1, it remains permanently anchored to that bar time and price, demonstrating zero repainting.

---

## 7. Compile Validation Plan

Prior to testing in the Strategy Tester, the engine must compile with absolute correctness.

1.  **Target Script**: Compile `src/tests/TestLiquidity.mq5`.
2.  **Command**: Run the MetaEditor compiler in terminal mode:
    ```powershell
    # Compile execution check
    metaeditor64.exe /compile:"c:\xauusd_chatgpt\src\tests\TestLiquidity.mq5" /log:"c:\xauusd_chatgpt\compile.log"
    ```
3.  **Success Criteria**: The `compile.log` output must show **0 errors and 0 warnings**.

---

## 8. Rollback Plan

If compiling errors occur or if validation tests fail due to unexpected bugs, the workspace must be immediately restored to its clean frozen baseline state.

1.  **Discard Header Changes**:
    *   Remove/delete the header `src/engines/LiquidityEngine.mqh`.
2.  **Discard Test Script Changes**:
    *   Remove/delete the test script `src/tests/TestLiquidity.mq5`.
3.  **Restore Git State**:
    *   Run Git discard commands to reset any accidental modifications:
        ```powershell
        git checkout -- c:\xauusd_chatgpt\src\engines\
        git checkout -- c:\xauusd_chatgpt\src\tests\
        ```
    *   Ensure `git status` reports a clean working directory (with zero modified files in existing engines).

---
*End of Phase 4.1 Implementation Plan.*
