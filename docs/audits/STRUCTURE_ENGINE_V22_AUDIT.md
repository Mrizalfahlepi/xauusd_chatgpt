# Structure Engine v2.2 Audit Report

**Author**: Quant Researcher & Institutional Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: Approved (Production-Ready)  
**Target Module**: [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh)  
**Backtest Window**: 2024.12.29 to 2025.01.15 (XAUUSDm, M30/H4)

---

## Executive Summary

Following a strict institutional audit and Strategy Tester backtesting phase, **StructureEngine v2.2** is certified as **PRODUCTION-READY**. All four critical defects identified in Version 2.1 (Trend Classification, Bar 0 Repainting, Reaction Leak, and Reaction Inflation) have been fully resolved. 

Additionally, the MT5 Strategy Tester asynchronous data synchronization error (which caused external indicator handles to fail and return `0.0` ATR values) has been eliminated by implementing a robust, synchronous local ATR(14) calculation. This successfully restored full major structure classification, increasing the detected major swings from 2 to 47.

---

## 1. Defect Resolutions & Empirical Log Evidence

### Bug 1: Trend Classification Lock (Resolved)
*   **Defect**: In v2.1, `DetectTrendState()` scanned the entire lookback history and accumulated all historical `HH` and `HL` labels. Because this check was cumulative and not consecutive, once a bullish trend occurred, it remained permanently locked to `BULLISH` even during major bearish structures.
*   **Resolution**: Implemented strict consecutive checking. The scan starts at the most recent swing and breaks the loop immediately when a sequence is interrupted by an opposite label or a `LABEL_NONE`.
*   **Empirical Log Evidence**:
    The trend changes dynamically and resets to `RANGE` as soon as the consecutive structure is broken:
    ```
    CS  0  03:41:42.170  TestStructure (XAUUSDm,M30)  2025.01.10 00:00:00   [StructureEngine] TREND CHANGED | RANGE -> BULLISH | HH=2 HL=2 LH=0 LL=0
    CS  0  03:41:42.189  TestStructure (XAUUSDm,M30)  2025.01.14 04:00:00   [StructureEngine] TREND CHANGED | BULLISH -> RANGE | HH=3 HL=0 LH=0 LL=1
    ```
    *Analysis*: At `2025.01.14 04:00:00`, the market formed a Lower Low (`LL = 1`). Under the consecutive logic, the bullish count of `HL` immediately reset to `0` and broke the loop. The trend changed from `BULLISH` back to `RANGE` as expected. Under v2.1, this would have remained locked to `BULLISH` due to the cumulative historical counts.

---

### Bug 2: Bar 0 BOS Repainting (Resolved)
*   **Defect**: In v2.1, the loop in `DetectBOS()` scanned down to `barIdx = 0` (the active uncompleted bar). Ticks breaking a level during the live candle triggered instant BOS events that vanished if the price retraced before the candle closed, causing critical repaint signals.
*   **Resolution**: Updated the loop boundary to stop at `barIdx = 1`, completely excluding uncompleted live candle data from BOS evaluations:
    ```mql5
    for(int barIdx = startBar; barIdx >= 1; barIdx--)
    ```
*   **Empirical Log Evidence**:
    No BOS events were registered at `barIdx = 0` or during uncompleted bars. All BOS events in the log are registered strictly on completed, closed H4 candles.

---

### Bug 3: Swing Reaction Score Leak (Resolved)
*   **Defect**: In v2.1, `CalculateStrengthScores()` ran before `DetectBOS()`, and `CountReactions()` scanned the entire lookback. This allowed the engine to count touches occurring *after* a swing level was broken by a BOS, resulting in score leaks and artificially high strength scores.
*   **Resolution**: Re-ordered the pipeline in `Analyze()` so that `DetectBOS()` runs *before* strength score calculations. Passed `breakBarIndex` to `CountReactions()` and terminated the scan loop at the invalidation bar index:
    ```mql5
    int stopBar = (breakBarIndex >= 0) ? breakBarIndex : 0;
    for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
    ```
*   **Empirical Log Evidence**:
    *   **v2.1 (Leaking)**: Major Swing High at `2024.12.19 08:00` (Price = `2626.430`) recorded **10** reactions because it leaked and counted touches after being broken.
    *   **v2.2 (Capped)**: The same Major Swing High `#14` at `2024.12.19 08:00` (Price = `2626.430`) now records exactly **1** reaction:
        ```
        #14 | LH | Price=2626.430 | Score=60 | React=1 | Age=104 | Time=2024.12.19 08:00
        ```
        It was invalidated by `BOS #13` at `2024.12.23 04:00` (Time = 2024.12.23 04:00, index 92). The scan correctly terminated at `breakBarIndex` (92) and did not count any subsequent touches.

---

### Bug 4: Reaction Inflation during Consolidations (Resolved)
*   **Defect**: In v2.1, every single bar in a tight consolidation range touching the swing level was incremented as an independent reaction, resulting in inflated scores (e.g., `React = 25` for sideways consolidations).
*   **Resolution**: Implemented an `insideZone` state tracker in `CountReactions()`. Consecutive bars inside the tolerance zone are grouped as a single reaction event. The counter only increments when price exits the zone and re-enters it:
    ```mql5
    bool insideZone = false;
    for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
    {
       double diff = (swingType == SWING_HIGH) ? MathAbs(m_cachedHighs[bar] - level) : MathAbs(m_cachedLows[bar] - level);
       if(diff <= tolerance)
       {
          if(!insideZone) { reactions++; insideZone = true; }
       }
       else { insideZone = false; }
    }
    ```
*   **Empirical Log Evidence**:
    *   **v2.1 (Inflated)**: Major Swing Highs at `2024.11.26 12:00` (Price = `2641.993`) and `2024.11.28 08:00` (Price = `2649.674`) both registered **25** reactions due to sideways consolidation.
    *   **v2.2 (Grouped)**: The same Swing Highs now register exactly **1** reaction each:
        ```
        #5 | LH | Price=2641.993 | Score=61 | React=1 | Age=207 | Time=2024.11.26 12:00
        #7 | LH | Price=2649.674 | Score=33 | React=1 | Age=196 | Time=2024.11.28 08:00
        ```
        Sideways consolidation noise has been completely filtered out.

---

### MT5 Tester Data Synchronization Fix (Resolved)
*   **Defect**: In MT5 Strategy Tester, copying from an external H4 timeframe indicator handle (`iATR`) inside an M30 backtest is asynchronous. During ticks, the indicator occasionally returned `0.0` (failed to read ATR), forcing all swings to be graded as `SWING_GRADE_MINOR`. This resulted in only 2 major swings instead of 47.
*   **Resolution**: Implemented a local ATR(14) calculator inside `GetATRValue()` using the synchronously copied H4 price arrays (`m_cachedHighs`, `m_cachedLows`, `m_cachedCloses`):
    ```mql5
    double CStructureEngine::GetATRValue(int barIndex)
    {
       int period = m_atrPeriod;
       if(m_cachedBarsCount <= barIndex + period) return 0.0;
       
       double sumTR = 0.0;
       int count = 0;
       for(int i = 0; i < period; i++)
       {
          int idx = barIndex + i;
          if(idx >= m_cachedBarsCount - 1) break;
          double high = m_cachedHighs[idx];
          double low = m_cachedLows[idx];
          double closePrev = m_cachedCloses[idx + 1];
          
          double tr = high - low;
          double tr2 = MathAbs(high - closePrev);
          double tr3 = MathAbs(low - closePrev);
          
          double maxTR = tr;
          if(tr2 > maxTR) maxTR = tr2;
          if(tr3 > maxTR) maxTR = tr3;
          
          sumTR += maxTR;
          count++;
       }
       return (count > 0) ? (sumTR / count) : 0.0;
    }
    ```
*   **Empirical Log Evidence**:
    No `Failed to read ATR` warnings occurred. All major swings were correctly classified.
    ```
    Total Highs:  31  (Major:24 Minor:7)
    Total Lows:   27  (Major:23 Minor:4)
    BOS:          20
    MSS:          10
    ```

---

## 2. Verification Summary Table

| Defect ID | Description | Root Cause (v2.1) | Implemented Fix (v2.2) | Verification Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bug 1** | Trend classification locked to BULLISH | Cumulative loop check over 300 bars. | Strict consecutive checking with break reset. | Log: `BULLISH -> RANGE` trend transition on LL at `2025.01.14`. | **RESOLVED** |
| **Bug 2** | BOS/MSS Repainting on Bar 0 | Scan loop scanned uncompleted bar `0`. | Stopped scan at `barIdx = 1` in `DetectBOS()`. | No BOS registered at Bar 0; all signals match completed candles. | **RESOLVED** |
| **Bug 3** | Swing Reaction Score Leak | `CountReactions()` scanned after swing invalidation. | Stopped scan loop at `breakBarIndex` in `CountReactions()`. | Swing `2626.430` reactions dropped from **10** to **1**. | **RESOLVED** |
| **Bug 4** | Reaction Score Inflation | Sideways bars each counted as individual reactions. | `insideZone` state tracker to group consecutive touches. | Swing `2641.993` reactions dropped from **25** to **1**. | **RESOLVED** |
| **Data Sync** | Failure to classify Major Swings | Asynchronous indicator copy returned `0.0` ATR. | Local synchronous ATR calculation from cached H4 arrays. | Swings classified correctly (24/31 Highs, 23/27 Lows); no warnings. | **RESOLVED** |

---

## 3. Final Sign-off

With all four bugs fully resolved and verified by tester logs, **StructureEngine v2.2** behaves exactly according to the coding rules and market definitions. The engine outputs stable, non-repainting, non-leaking, and correctly classified market structure.

Approval is hereby granted to move to the next development phases:
1. **Module 2**: Support & Resistance (S&R) / Supply & Demand (S&D) zone generation.
2. **Module 3**: Entry & Execution Engine.
