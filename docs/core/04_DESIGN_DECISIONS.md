# 04_DESIGN_DECISIONS.md

Version: 1.0  
Date: 2026-06-12  
Status: Approved  

---

## Purpose
This document records the design decisions and architectural fixes implemented in **StructureEngine v2.2** to resolve critical issues identified during validation of version 2.1. Future agents must respect these decisions and maintain these implementations to prevent regression.

---

## 1. Trend Classification Redesign (Strict Consecutive Logic)

*   **Problem**: In ranging or bearish market structures, the trend classification occasionally got locked in `TREND_BULLISH` (or `TREND_BEARISH`), failing to respond to new market structure shifts.
*   **Root Cause**: `DetectTrendState()` scanned backwards from the newest swing and accumulated *all* historical `HH`/`HL` labels in the lookback array. It was a cumulative count (`recentHH >= 2 && recentHL >= 2`) rather than a consecutive check. Because historical bullish swings remained in the array, the bullish check always evaluated to true first, locking the trend.
*   **Solution**: Converted the scan to a strict consecutive check. The engine starts at the newest swing and counts backwards, but breaks immediately as soon as a sequence of the same label direction is interrupted by an opposite label or a `LABEL_NONE`:
    ```mql5
    ENUM_STRUCTURE_LABEL targetLabel = m_majorHighs[mhc - 1].label;
    for(int i = mhc - 1; i >= 0; i--)
    {
       if(m_majorHighs[i].label == targetLabel)
       {
          if(targetLabel == LABEL_HH) recentHH++;
          else if(targetLabel == LABEL_LH) recentLH++;
       }
       else break;
    }
    ```
*   **Reasoning**: Trend classification must reflect the *recent* active structure. If the market breaks recent structures (e.g. prints a `LL`), the consecutive sequence of `HL` is broken and the trend must reset to `TREND_RANGE` or change direction. Consecutive checks ensure the trend filter remains responsive to current market conditions.
*   **Status**: Completed & Tester Verified. Trend changes dynamically from `BULLISH` to `RANGE` immediately when a LL breaks the HL sequence.

---

## 2. BOS Close-Candle Validation (Bar 0 Exclusion)

*   **Problem**: Break of Structure (BOS) and Market Structure Shift (MSS) events would trigger and then disappear (repaint) during live trading.
*   **Root Cause**: The scan loop in `DetectBOS()` iterated down to `barIdx = 0`. In MQL5, `closes[0]` is the live uncompleted candle price. If the live price ticked above a swing level, a BOS was registered instantly. If the price subsequently retraced before the candle closed, the next call to `Analyze()` found no break, deleting the BOS event and restoring the swing.
*   **Solution**: Modified the scan loop boundary in `DetectBOS()` to terminate at `barIdx = 1` instead of `0`:
    ```mql5
    for(int barIdx = startBar; barIdx >= 1; barIdx--)
    ```
*   **Reasoning**: A breakout of structure can only be mathematically confirmed when the candle closes. Restricting the loop to closed bars (`barIdx >= 1`) guarantees that all registered BOS events are permanent and non-repainting.
*   **Status**: Completed & Tester Verified. Zero BOS events occur at Bar 0.

---

## 3. ATR Local Calculation (Tester Synchronization Fix)

*   **Problem**: In the MT5 Strategy Tester, the engine failed to grade swings as Major, grading almost all swings as Minor and rendering the engine non-functional (major swings count dropped from 47 to 2).
*   **Root Cause**: Grader logic relied on the `iATR` indicator handle on H4. Since the backtest was run on M30, copying from an external timeframe indicator handle across threads during backtest ticks is asynchronous in MT5. The copy regularly failed, returning `0.0` ATR. When ATR was `0.0`, all swings failed the `dist >= 0.5 * ATR` filter.
*   **Solution**: Implemented a local, synchronous ATR(14) calculator inside `GetATRValue()` using the H4 price arrays (`m_cachedHighs`, `m_cachedLows`, `m_cachedCloses`) that are copied synchronously:
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
          ...
       }
       return (count > 0) ? (sumTR / count) : 0.0;
    }
    ```
*   **Reasoning**: Local calculation is 100% synchronous and has no external dependencies. This ensures ATR is always calculated reliably, bypassing MT5 Strategy Tester synchronization gaps and maintaining consistent swing grading.
*   **Status**: Completed & Tester Verified. Zero ATR errors; Major Swings and BOS counts successfully restored to correct mathematical levels.

---

## 4. Reaction Scoring Leak Fix

*   **Problem**: Swing levels that had been broken by a BOS continued to accumulate reactions, resulting in artificially high strength scores for invalid levels.
*   **Root Cause**: The pipeline in `Analyze()` calculated strength scores *before* detecting BOS, meaning the invalidation bar index (`breakBarIndex`) was not populated yet. Furthermore, `CountReactions()` scanned the entire lookback array down to `0` regardless of whether the level had been broken.
*   **Solution**:
    1.  Re-ordered the pipeline in `Analyze()` to run `DetectBOS()` and `SyncInvalidationToArrays()` before `CalculateStrengthScores()`.
    2.  Modified `CountReactions()` to terminate scanning at the `breakBarIndex` where the swing was broken:
        ```mql5
        int stopBar = (breakBarIndex >= 0) ? breakBarIndex : 0;
        for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
        ```
*   **Reasoning**: Once a swing level is broken by a closed candle (BOS), it is structurally invalidated. Any touches occurring after the break represent tests of new structure, not the old level. Restricting the reaction scan prevents historical leaks.
*   **Status**: Completed & Tester Verified. Swings broken by BOS stop accumulating reactions at the breakout bar index.

---

## 5. Reaction Inflation Fix (Consolidation Touch Grouping)

*   **Problem**: Price consolidating sideways near a swing level caused the reaction count to inflate to maximum levels (e.g. `React = 25`), distorting the significance of the level.
*   **Root Cause**: In `CountReactions()`, every single bar whose high/low fell within the ATR-relative tolerance zone of the swing level was counted as an independent reaction, even if price simply moved sideways in a tight range without leaving the level.
*   **Solution**: Implemented an `insideZone` state tracker. Consecutive bars touching the level are grouped into a single reaction event. The counter only increments when price leaves the zone and returns to test it:
    ```mql5
    bool insideZone = false;
    for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
    {
       double diff = (swingType == SWING_HIGH) ? MathAbs(m_cachedHighs[bar] - level) : MathAbs(m_cachedLows[bar] - level);
       if(diff <= tolerance)
       {
          if(!insideZone)
          {
             reactions++;
             insideZone = true;
          }
       }
       else
       {
          insideZone = false;
       }
    }
    ```
*   **Reasoning**: Sideways consolidation represents a single structural interaction with the level. Counting every bar within a consolidation range inflates rejections. True rejections require price to move away from the level before returning.
*   **Status**: Completed & Tester Verified. Consolidation touches are grouped correctly. Reaction counts in tight ranges are reduced to 1.
