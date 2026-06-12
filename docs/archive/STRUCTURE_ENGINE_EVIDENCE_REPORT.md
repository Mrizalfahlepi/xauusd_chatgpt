# Structure Engine Evidence Report

**Author**: Quant Researcher & Institutional Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: Validation Phase (Log & Code Evidence)

---

## Executive Summary

This report provides concrete, empirical evidence of bugs and structural flaws in **StructureEngine v2.1** based on the MQL5 Tester logs generated during backtests of **TestStructure.mq5** (running on XAUUSD, Timeframe H4, 300 bars lookback, ending on 2025.01.13). 

No assumptions or opinions are included. All findings are derived directly from the MQL5 code and tester logs.

---

## 1. Audit of Identified Bugs & Logic Flaws

### Bug 1: Trend Classification Logic Bug (Critical)

#### 1. Exact Chart / Log Example
At the final analysis timestamp of `2025.01.13 16:00:00`, the engine outputs:
```
[StructureEngine] === ANALYSIS v2.1 COMPLETE === | Trend=BULLISH | Major=48 | HH=12 | HL=12 | LH=12 | LL=10 | BOS=20 | MSS=9
```
The engine declares the current trend state as **BULLISH**.

#### 2. Exact Swings Involved
Looking at the most recent major swings leading up to `2025.01.13`:
*   **Most Recent Swing Lows**:
    *   Low `#22`: LL | Price = `2583.390` | Time = `2024.12.18 20:00`
    *   Low `#21`: LL | Price = `2632.966` | Time = `2024.12.17 12:00`
    *   Low `#20`: LL | Price = `2643.523` | Time = `2024.12.16 00:00`
    *(All three most recent swing lows are Lower Lows)*
*   **Most Recent Swing Highs**:
    *   High `#21`: LH | Price = `2649.515` | Time = `2025.01.06 08:00`
    *   High `#22`: HH | Price = `2664.264` | Time = `2025.01.07 12:00`
    *   High `#23`: HH | Price = `2678.333` | Time = `2025.01.09 12:00`
    *   High `#24`: HH | Price = `2698.026` | Time = `2025.01.10 12:00`

#### 3. Exact BOS Involved
The most recent BOS events before `2025.01.13` are:
*   `BOS #15 | Dir=BEARISH | Close=2604.543 | Level=2632.966 | Time=2024.12.18 16:00`
*   `BOS #16 | Dir=BULLISH | Close=2630.230 | Level=2626.430 | Time=2024.12.23 04:00`
*   `BOS #17 | Dir=BULLISH | Close=2626.893 | Level=2621.472 | Time=2024.12.26 00:00`

#### 4. Exact MSS Involved
*   `MSS #7 | Dir=BULLISH | Prev=BEARISH | Price=2626.893 | Time=2024.12.26 00:00`

#### 5. Why It Is Wrong
At `2025.01.13`, the three most recent major lows on the chart are **LL** (`2643.523`, `2632.966`, and `2583.390`). The market has structurally broken key lows (BOS #15). 
A trend cannot be classified as `BULLISH` when the market is making consecutive Lower Lows (LL) in its recent swing structure. 
The engine outputs `BULLISH` because the loop in `DetectTrendState()` accumulates *all* HH and HL labels in the entire 300-bar major arrays (finding 12 HHs and 12 HLs historically) without checking if they are consecutive or recent. Since the `TREND_BULLISH` check is evaluated first, it permanently locks the trend to `BULLISH` as long as the cumulative count of HH and HL is $\ge 2$.

#### 6. Expected Behaviour
The trend should be classified as `RANGE` or `BEARISH` because the recent low structure is making Lower Lows. The trend classification must only look at the consecutive sequence of recent labels (e.g., if the last 2 highs are HH and the last 2 lows are HL $\rightarrow$ BULLISH. If the sequence is mixed or LL $\rightarrow$ BEARISH/RANGE).

#### 7. Code Location
In [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L1155-L1173) inside `DetectTrendState()`:
```mql5
   int mhc = ArraySize(m_majorHighs);
   for(int i = mhc - 1; i >= 0; i--)
   {
      if(m_majorHighs[i].label == LABEL_HH) recentHH++;
      else if(m_majorHighs[i].label == LABEL_LH) recentLH++;
      else break;
   }

   int mlc = ArraySize(m_majorLows);
   for(int i = mlc - 1; i >= 0; i--)
   {
      if(m_majorLows[i].label == LABEL_HL) recentHL++;
      else if(m_majorLows[i].label == LABEL_LL) recentLL++;
      else break;
   }
```

#### 8. Proposed Fix
Implement a tracker that resets opposite counts and breaks immediately when a sequence of the same direction is broken, checking only the most recent major swings:
```mql5
   int recentHH = 0, recentHL = 0;
   int recentLH = 0, recentLL = 0;

   int mhc = ArraySize(m_majorHighs);
   for(int i = mhc - 1; i >= 0; i--)
   {
      if(m_majorHighs[i].label == LABEL_HH) { recentHH++; recentLH = 0; }
      else if(m_majorHighs[i].label == LABEL_LH) { recentLH++; recentHH = 0; }
      else break; 
   }

   int mlc = ArraySize(m_majorLows);
   for(int i = mlc - 1; i >= 0; i--)
   {
      if(m_majorLows[i].label == LABEL_HL) { recentHL++; recentLL = 0; }
      else if(m_majorLows[i].label == LABEL_LL) { recentLL++; recentHL = 0; }
      else break;
   }

   if(recentHH >= 1 && recentHL >= 1)      m_currentTrend = TREND_BULLISH;
   else if(recentLH >= 1 && recentLL >= 1) m_currentTrend = TREND_BEARISH;
   else                                    m_currentTrend = TREND_RANGE;
```

---

### Bug 2: Repainting Risk in BOS Detection (High)

#### 1. Exact Chart / Log Example
The loop scans all indices including `barIdx = 0`.
During a live H4 bar, the current close is changing constantly.

#### 2. Exact Swing Involved
Any active major swing level being approached by the current price.

#### 3. Exact BOS Involved
Any BOS event registered at `barIdx = 0`.

#### 4. Exact MSS Involved
Any MSS event triggered by a BOS at `barIdx = 0`.

#### 5. Why It Is Wrong
A candle must close to confirm a Break of Structure. In MQL5, `closes[0]` is the live price. If the live price ticks above the active swing high, `closes[0] > swingPrice` is evaluated as true, triggering a BOS, invalidating the swing, and setting `activeHighIdx = -1`. If the price then falls back before the H4 candle closes, the BOS will disappear on the next bar, causing a repaint.

#### 6. Expected Behaviour
A BOS can only be confirmed on a closed candle. Therefore, the loop must only scan completed bars (`barIdx >= 1`).

#### 7. Code Location
In [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L914) inside `DetectBOS()`:
```mql5
   for(int barIdx = startBar; barIdx >= 0; barIdx--)
```

#### 8. Proposed Fix
Modify the loop boundary to stop at `barIdx = 1`:
```mql5
   for(int barIdx = startBar; barIdx >= 1; barIdx--)
```

---

### Bug 3: Reaction Scoring Leak (Medium)

#### 1. Exact Chart / Log Example
Major Swing High `#15` (Price = `2626.430` | Time = `2024.12.19 08:00`) has `React = 10`.
It was broken by `BOS #16` at `2024.12.23 04:00` (which is 15 bars later).

#### 2. Exact Swing Involved
Major Swing High `#15`.

#### 3. Exact BOS Involved
`BOS #16 | Dir=BULLISH | Close=2630.230 | Level=2626.430 | Time=2024.12.23 04:00`

#### 4. Exact MSS Involved
`MSS #6 | Dir=BULLISH | Prev=BEARISH | Price=2630.230 | Time=2024.12.23 04:00`

#### 5. Why It Is Wrong
Major Swing High `#15` was broken and invalidated by `BOS #16` on `2024.12.23`. However, the engine counted `React = 10` (10 touches) across all 300 bars, including bars *after* the level was broken. Once a level is broken by a BOS, it is no longer an active resistance level; counting subsequent touches as "reactions" is a logical leak that inflates the swing's strength score.

#### 6. Expected Behaviour
The reaction counter should stop counting touches of a swing level as soon as a BOS event breaks that level.

#### 7. Code Location
In [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L1247-L1258) inside `Analyze()`:
```mql5
   //--- Step 4: Strength Scores
   CalculateStrengthScores();
   ...
   //--- Step 7: Detect BOS (Active Level tracking)
   result.bosCount = DetectBOS(m_cachedCloses, m_cachedTimes, barsToAnalyze);
```
And inside `CountReactions()` at [L675-L692](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L675-L692).

#### 8. Proposed Fix
Re-order the pipeline in `Analyze()` so that `DetectBOS()` runs *before* `CalculateStrengthScores()`. Pass the BOS bar index to `CountReactions()` and terminate the loop at the break bar index instead of `0`:
```mql5
int CStructureEngine::CountReactions(double level, double tolerance,
                                      int swingBarIndex, int breakBarIndex, ENUM_SWING_TYPE swingType)
{
   int reactions = 0;
   int stopBar = (breakBarIndex >= 0) ? breakBarIndex : 0;
   
   for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
   {
      ...
   }
   return reactions;
}
```

---

### Bug 4: Reaction Inflation during Consolidations (Medium)

#### 1. Exact Chart / Log Example
Major Swing High `#6` (Price = `2641.993` | Time = `2024.11.26 12:00`) has `React = 25`.
Major Swing High `#8` (Price = `2649.674` | Time = `2024.11.28 08:00`) has `React = 25`.

#### 2. Exact Swing Involved
Major Swing Highs `#6` and `#8`.

#### 3. Exact BOS Involved
`BOS #8` and `BOS #9`.

#### 5. Why It Is Wrong
A reaction count of 25 in a 300-bar window means 25 separate H4 bars touched this price level. This occurred because price consolidated in a tight range near `2641.993` and `2649.674` between `2024.11.26` and `2024.11.30`. Rather than counting 25 independent tests (rejections) of the level, the engine counted 25 consecutive bars of a sideways consolidation. This inflates the swing score to its maximum and distorts the true historical significance of the level.

#### 6. Expected Behaviour
Consecutive bars touching a level should be grouped as a single reaction event. A new reaction should only be counted if price moves away from the level (outside the tolerance zone) and then returns to test it again.

#### 7. Code Location
In [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L675-L692) inside `CountReactions()`:
```mql5
      if(swingType == SWING_HIGH)
      {
         if(MathAbs(m_cachedHighs[bar] - level) <= tolerance) reactions++;
      }
```

#### 8. Proposed Fix
Track the state of the touch. Only increment the reaction counter when price exits the zone and re-enters it:
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

---

## 2. Parameter Sensitivity Audit (BOS & MSS Count)

### 1. BOS Count Audit
*   **Total BOS Events Detected**: 20 in 300 H4 bars.
*   **Why It Is Too High**: A BOS represents a macro structural break. 20 BOS events in 10 weeks means structure breaks every 2.5 days. This is caused by `InpBOSBreakMultiplier = 0.25` (in [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L217)), which requires a break of only 0.25 ATR. At an ATR of 15 USD on Gold, this is a break of just 3.75 USD, which is frequently hit by minor volatility or wicks.
*   **Proposed Fix**: Increase `InpBOSBreakMultiplier` to `0.50` or `0.75` to filter out minor breakouts.

### 2. MSS Count Audit
*   **Total MSS Events Detected**: 9 in 300 H4 bars.
*   **Why It Is Too High**: An MSS represents a major shift in trend direction. 9 MSS events means the trend shifts every 5.5 days. 
*   **Proposed Fix**: Increase `InpMinSwingDistATR` from `0.50` to `1.25` or `1.50` (in [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L220)). This will reduce the number of major swings, filtering out minor swing points and reducing the resulting BOS/MSS counts.

---

## 3. What Is Correct, Wrong, and Uncertain

### What Is Correct
*   **Chronological BOS Processing**: `DetectBOS` successfully orders the BOS events chronologically.
*   **Active Swing Invalidation**: `isInvalidated` flag is set correctly on the active swings when broken by a BOS.
*   **ATR Volatility Scaling**: Jarak and break thresholds successfully scale with ATR.

### What Is Wrong
*   **Trend Classification**: Cumulative counting instead of consecutive recent counting (Bug 1).
*   **BOS Repainting**: Scanning of bar 0 causing live repainting (Bug 2).
*   **Reaction Score Leak**: Scanning reactions after a swing has been broken (Bug 3).
*   **Reaction Score Inflation**: Sideways consolidation counted as multiple touches (Bug 4).

### What Is Uncertain
*   **Alternating High/Low Swings**: The engine processes highs and lows as independent arrays. If the market makes multiple Major Highs without an intervening Major Low (due to ATR filter mismatches), the trend labels may become misaligned. Enforcing an alternating check (High $\rightarrow$ Low $\rightarrow$ High $\rightarrow$ Low) requires further test data.

---

## 4. Recommended Changes Ranked by Impact

| Rank | Change | Impact | Target Component |
|---|---|---|---|
| **1** | Fix Trend Classification Logic (Consecutive) | Critical | `DetectTrendState()` |
| **2** | Exclude Bar 0 from BOS Scan | High | `DetectBOS()` |
| **3** | Re-order Analyze Pipeline & Stop Reaction Leak | Medium | `Analyze()`, `CountReactions()` |
| **4** | Group Consolidation Touches as Single Reaction | Medium | `CountReactions()` |
| **5** | Increase `InpMinSwingDistATR` to 1.25 and `InpSwingLookback` to 5 | High | Input Parameters |
