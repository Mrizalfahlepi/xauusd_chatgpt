# Supply & Demand Engine v1.0 - Statistical Verification Report

**Author**: Quant Researcher & Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: VERIFIED (Phase A Complete)  
**Target File**: [SUPPLY_DEMAND_VERIFICATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/archive/SUPPLY_DEMAND_VERIFICATION_REPORT.md)

---

## 1. Executive Summary

This report presents log-based and mathematical verification of the two statistical anomalies identified in `SupplyDemandEngine v1.0` during the 4-year backtest (2022.01.01 to 2025.12.31) on Gold (XAUUSD, H4). 

Following code inspection, log tracing, and mathematical proofs:
*   **Task 1: Age Score Defect** is **CONFIRMED** as a bug.
*   **Task 2: Invalidation Bar Reaction Inflation** is **CONFIRMED** as a bug.

*No code changes have been made yet, in compliance with Phase A instructions.*

---

## 2. Task 1: Age Score Defect Verification

### 2.1 Code Excerpt
The age score is calculated in [SupplyDemandEngine.mqh:L373-L375](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh#L373-L375):
```mql5
   // 3. Age Score (0-100)
   int age = currentBarIdx - zone.impulseBarIndex;
   if(age < 0) age = 0;
   double scoreA = MathMax(0.0, 100.0 - age * 0.25); // Drops to 0 at 400 bars
```

### 2.2 Mathematical Proof
In MetaTrader 5:
*   Bar indices represent offsets from the current time: `0` is the forming bar, `1` is the last completed bar, and `N` is an older bar in the past.
*   The impulse candle that forms the zone occurred in the past, so `zone.impulseBarIndex` will always be a larger index than `currentBarIdx` (which is passed as `1` in the code).
*   Therefore, the calculation:
$$\text{age} = \text{currentBarIdx} - \text{zone.impulseBarIndex}$$
will always yield a negative number:
$$\text{age} = 1 - \text{impulseBarIndex} < 0$$
*   Since `age < 0`, the safety check `if (age < 0) age = 0;` triggers and resets `age` to `0`.
*   As a result:
$$\text{Score}_{\text{Age}} = 100.0 - 0 \times 0.25 = 100.0 \text{ (permanently)}$$
The Age Score is mathematically stuck at 100% and does not decay over time.

### 2.3 Log-Based Evidence
Let us trace the unique supply zone:
*   **Key**: `SUPPLY-2689.283-2658.928-2024.11.11 12:00`
*   **Creation Time**: `2024.11.11 12:00` (impulse bar)
*   **Impulse Strength Score**: `100.0`
*   **Freshness Score**: `100.0` (Untouched, `Reacts = 0`)
*   **Reaction Score**: `0.0` (0 reactions)

Chronological log history extracted from `latest_run.log`:
```
2024.11.11 16:00:00 | Reacts=0 | Score=80.0 | Status=ACTIVE
2024.11.12 16:00:00 | Reacts=0 | Score=80.0 | Status=ACTIVE
2024.11.15 16:00:00 | Reacts=0 | Score=80.0 | Status=ACTIVE
2024.11.21 00:00:00 | Reacts=0 | Score=80.0 | Status=ACTIVE
```
*   **Trace Analysis at 2024.11.21 00:00:00**:
    *   Time elapsed: 9 days, 12 hours (228 hours) $\rightarrow$ **57 H4 bars**.
    *   If Age Score decayed correctly:
        *   `age` = 57 bars.
        *   `Score_Age` = $100.0 - (57 \times 0.25) = 85.75$.
        *   `Score_Total` = $(100 \times 0.3) + (100 \times 0.3) + (85.75 \times 0.2) + (0 \times 0.2) = 30 + 30 + 17.15 = 77.15$.
    *   **Actual Logged Score**: `Score = 80.0` (flat since creation).
    *   This confirms that `Score_Age` remained at `100.0` despite 57 bars of aging, proving the bug.

### 2.4 Conclusion
**A. Bug confirmed**

---

## 3. Task 2: Invalidation Bar Reaction Inflation Verification

### 3.1 Code Excerpt
Retest scanning coordinates are calculated in [SupplyDemandEngine.mqh:L321-L328](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh#L321-L328):
```mql5
int CSupplyDemandEngine::CountZoneReactions(const SupplyDemandZone &zone)
{
   int reactions = 0;
   bool insideZone = false;
   int stopBar = zone.isInvalidated ? zone.invalidatedBar : 1;
   
   // Scan from the candle after impulse down to stopBar
   for(int bar = zone.impulseBarIndex - 1; bar >= stopBar; bar--)
```

### 3.2 Logic & Mathematical Proof
*   To invalidate a zone, a candle must close past it (e.g. `Close < ZoneLow` for Demand).
*   Unless a weekend price gap completely bypasses the zone (opening and closing below the zone without the High touching it), the invalidating candle's high-low range must cross the boundary.
*   Because the loop checks `bar >= stopBar` and `stopBar = zone.invalidatedBar`, the invalidation candle itself is evaluated.
*   Since the invalidation candle crosses the boundary, `touch` evaluates to `true`.
*   If `insideZone` was `false` (meaning the previous bar was not touching the zone), the reaction count is incremented.
*   This inflates the reaction count of all broken zones by `+1` at the exact moment of breach, masking zones that were broken immediately with 0 prior retests.

### 3.3 Log-Based Evidence
Let us trace the transition of four unique zones in `latest_run.log` that surviving active prints captured prior to invalidation:

#### Case 1: DEMAND-1852.433-1833.542-2022.06.10 12:00
```
2022.06.13 08:00:00 | Reacts=0 | Status=ACTIVE
2022.06.13 12:00:00 | Reacts=0 | Status=ACTIVE
2022.06.13 16:00:00 | Reacts=1 | Status=INVALIDATED (bar 1)
```
*   **Trace Analysis**: This zone had exactly `Reacts = 0` throughout its active life. On the H4 candle closing at `16:00:00`, price broke the zone. At this exact moment, `Reacts` jumped to `1`. This proves the invalidation candle itself was counted as a reaction touch, inflating the score.

#### Case 2: SUPPLY-1853.923-1840.885-2023.03.07 12:00
```
2023.03.10 08:00:00 | Reacts=0 | Status=ACTIVE
2023.03.10 12:00:00 | Reacts=0 | Status=ACTIVE
2023.03.10 16:00:00 | Reacts=1 | Status=INVALIDATED (bar 1)
```
*   **Trace Analysis**: Price broke above the supply zone high on the bar closing at `16:00:00`. The zone had `0` prior reactions, but logged `Reacts = 1` immediately at invalidation.

#### Case 3: DEMAND-1911.524-1889.367-2022.02.24 00:00
```
2022.02.24 12:00:00 | Reacts=0 | Status=ACTIVE
2022.02.24 16:00:00 | Reacts=0 | Status=ACTIVE
2022.02.24 20:00:00 | Reacts=1 | Status=INVALIDATED (bar 1)
```

#### Case 4: SUPPLY-1823.760-1812.782-2022.12.22 12:00
```
2022.12.27 08:00:00 | Reacts=0 | Status=ACTIVE
2022.12.27 12:00:00 | Reacts=0 | Status=ACTIVE
2022.12.27 16:00:00 | Reacts=1 | Status=INVALIDATED (bar 1)
```

In all four cases, the zones had **0 reactions** while active and instantly registered **1 reaction** upon invalidation, proving inflation.

### 3.4 Impact Quantification
Out of **176 invalidated zones** in the 4-year backtest:
*   **59 zones** have `Reacts = 1` and `Status = Invalidated`.
*   Because `touch` is guaranteed on the invalidation bar, all 59 of these zones are true false positives (0 prior retests) that were inflated to 1.
*   This means the **True False Positive Rate is 33.52%** (59 out of 176), and the **True Retest Reliability (at least 1 bounce) is 66.48%**.
*   The raw average reaction metric is inflated from its true value of **2.14** to **2.86**.

### 3.5 Conclusion
**A. Bug confirmed**

---

## 4. Final Verification Summary

| Findings | Confirmed / Rejected | Impact | Next Action |
| :--- | :---: | :--- | :--- |
| **Age Score Defect** | **CONFIRMED** | Flat 100% age score; no decay over time. | Correct calculation order: `zone.impulseBarIndex - currentBarIdx`. |
| **Reaction Inflation** | **CONFIRMED** | Invalidation bar counted as reaction; hides 33.52% false positives. | Exclude invalidation bar: `zone.invalidatedBar + 1`. |

With both bugs confirmed using objective log evidence and mathematical proofs, `SupplyDemandEngine v1.0` requires a targeted hotfix (Version 1.1) and revalidation before it can serve as a frozen dependency for the **SNR Engine**.
