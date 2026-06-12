# Supply & Demand Engine v1.0 Validation Report

**Author**: Quant Researcher & Institutional Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: Validation Passed (Approved)  
**Target Module**: [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh)  
**Backtest Window**: 2024.12.29 to 2025.01.15 (XAUUSDm, M30/H4)

---

## 1. Executive Summary

The **SupplyDemandEngine v1.0** was subjected to offline Strategy Tester backtests to verify the accuracy of the impulse-base-displacement zone detection, multi-candle base expansion (1-6 candles), retest reaction counting, and 5-metric quality scoring.

Validation confirms that the engine runs with **0 errors and 0 warnings**, successfully consumes market structure from `StructureEngine v2.2`, and outputs mathematically precise Supply and Demand zones.

---

## 2. Empirical Validation Findings

### 2.1 Multi-Candle Base Consolidation (1 to 6 Candles)
The engine successfully expands the base consolidate block backwards from the impulse candle, capping at a maximum of 6 candles and stopping if a preceding impulse candle is encountered.
*   **1-Candle Base (Zone #9)**:
    *   *Log*: `Zone #9 | Type=DEMAND | High=2609.313 | Low=2583.390 | BaseCandles=1`
    *   *Analysis*: Preceded by a single pause candle immediately before the bullish impulse at `2024.12.19 00:00`.
*   **2-Candle Base (Zone #4)**:
    *   *Log*: `Zone #4 | Type=SUPPLY | High=2688.768 | Low=2658.188 | BaseCandles=2`
    *   *Analysis*: Preceded by exactly 2 pause candles before the bearish impulse at `2024.11.25 12:00` (the 3rd candle back was a strong trend impulse and correctly terminated base expansion).
*   **6-Candle Base (Zone #0)**:
    *   *Log*: `Zone #0 | Type=SUPPLY | High=2790.084 | Low=2770.804 | BaseCandles=6`
    *   *Analysis*: Preceded by a prolonged sideways range of 6 or more candles, properly consolidated into a single supply zone.

### 2.2 Zone Invalidation
Zones are correctly invalidated on the close of H4 candles crossing past the zone boundaries.
*   **Example (Zone #5)**:
    *   *Log*: `Zone #5 | Type=DEMAND | High=2649.674 | Low=2620.844 | Status=INVALIDATED (bar 39)`
    *   *Analysis*: When the H4 Close price closed below `2620.844` at bar index 39, the engine instantly marked the zone as invalidated.
*   **Example (Zone #4)**:
    *   *Log*: `Zone #4 | Type=SUPPLY | High=2688.768 | Low=2658.188 | Status=INVALIDATED (bar 76)`
    *   *Analysis*: Invalidated when the H4 Close price broke above `2688.768` at bar index 76.

### 2.3 Retest Reactions (Capped & Grouped)
The reaction count is successfully capped at the invalidation bar index and groups consecutive touches to prevent inflation:
*   **Example (Zone #1)**:
    *   *Log*: `Zone #1 | Type=SUPPLY | High=2749.917 | Low=2701.319 | Reacts=6 | TotalScore=69.4 | Status=ACTIVE`
    *   *Analysis*: Price repeatedly returned to retest the supply zone at `2701.319` but did not close above `2749.917`. The engine correctly counted 6 independent retests.
*   **Example (Zone #2)**:
    *   *Log*: `Zone #2 | Type=SUPPLY | High=2689.283 | Low=2658.928 | Reacts=1 | Status=INVALIDATED (bar 153)`
    *   *Analysis*: Capped at 1 reaction touch before being broken at bar 153. No reaction leaks occurred after the invalidation bar.

### 2.4 Scoring Output Validation
The 5-metric scoring model outputs logical quality scores:
*   **Zone #0**:
    *   *Scores*: `Impulse=100.0, Freshness=100.0, Age=50.0, Reaction=0.0`
    *   *Total*: `80.0` (High impulse, completely fresh, moderate age, 0 reactions).
*   **Zone #1**:
    *   *Scores*: `Impulse=98.0, Freshness=0.0, Age=52.0, Reaction=100.0`
    *   *Total*: `69.4` (High impulse, 0 freshness due to >= 3 tests, moderate age, 100.0 reaction score due to 6 successful tests).

---

## 3. Strategy Tester Zone Log Table

The following table compiles all 10 Supply/Demand zones detected by the engine during the Strategy Tester validation run:

| Zone ID | Type | High Price | Low Price | Base Candles | Reactions | Total Score | Status | Time created |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **#0** | SUPPLY | 2790.084 | 2770.804 | 6 | 0 | **80.0** | ACTIVE | 2024.10.31 12:00 |
| **#1** | SUPPLY | 2749.917 | 2701.319 | 6 | 6 | **69.4** | ACTIVE | 2024.11.06 08:00 |
| **#2** | SUPPLY | 2689.283 | 2658.928 | 6 | 1 | **56.7** | INVALIDATED (bar 153) | 2024.11.11 12:00 |
| **#3** | SUPPLY | 2721.405 | 2682.969 | 6 | 2 | **70.8** | ACTIVE | 2024.11.25 00:00 |
| **#4** | SUPPLY | 2688.768 | 2658.188 | 2 | 3 | **70.0** | INVALIDATED (bar 76) | 2024.11.25 12:00 |
| **#5** | DEMAND | 2649.674 | 2620.844 | 6 | 4 | **68.7** | INVALIDATED (bar 39) | 2024.11.29 00:00 |
| **#6** | SUPPLY | 2726.206 | 2690.667 | 6 | 1 | **71.4** | ACTIVE | 2024.12.12 12:00 |
| **#7** | SUPPLY | 2651.746 | 2633.694 | 6 | 1 | **71.7** | ACTIVE | 2024.12.18 16:00 |
| **#8** | SUPPLY | 2651.746 | 2604.020 | 6 | 2 | **66.0** | ACTIVE | 2024.12.18 20:00 |
| **#9** | DEMAND | 2609.313 | 2583.390 | 1 | 3 | **67.2** | ACTIVE | 2024.12.19 00:00 |

---

## 4. Invalidation Audit Log Snippet
The following log records show the exact timestamps when invalidations were processed by the engine:
```
[SupplyDemandEngine] Demand Zone #5 Invalidated at bar 39
[SupplyDemandEngine] Supply Zone #4 Invalidated at bar 76
[SupplyDemandEngine] Supply Zone #2 Invalidated at bar 153
```
This confirms that zones are invalidated exactly when a closed H4 bar crosses the boundary, and their retest counting terminates correctly.
