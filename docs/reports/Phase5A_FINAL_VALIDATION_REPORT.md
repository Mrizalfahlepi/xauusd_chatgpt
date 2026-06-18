# PHASE 5A FINAL VALIDATION REPORT: H4 TREND GATE EVALUATION

**Date**: 2026-06-18  
**Phase**: Phase 5A — Minimalist Trend Gate Setup  
**Target Module**: `CEntryEngine` (v1.0) & `TestEntry.mq5`  
**Verdict**: ❌ **FAILED HYPOTHESIS (H4 Trend Gate Rejected)**  

---

## 1. Hypothesis Under Test
The primary hypothesis of Phase 5A was:
> **Hypothesis**: *Filtering stop sweep reversal signals using a macro H4 Trend Gate (blocking BSL/Short entries in a H4 Bullish trend, and blocking SSL/Long entries in a H4 Bearish trend) will eliminate or significantly reduce trending-year drawdowns (such as 2023) without destroying the trading edge in range-bound/mean-reverting years (2024–2025).*

This was evaluated using:
- **Group D Sweeps Only** (Rejection Margin $\ge 0.50$ ATR, Large Excursion Block $\le 1.50$ ATR).
- **Asymmetric Risk Profile** (SL = 1.0 ATR, TP = 2.0 ATR, 12-bar M30 time-decay exit).
- **Timeframe**: 4-year backtest (2022–2025) on `XAUUSD`, timeframe `M30` (M1 OHLC mode).

---

## 2. Validation Run Results

We executed two comparative backtest runs using the exact same virtual trade execution pipeline:

### Run 1: Trend Gate DISABLED (Baseline Group D Replication)
- **`InpEnableTrendGate`**: `false`
- **Purpose**: Verify compilation/runtime integration and reproduce the Phase 4 Group D statistical audit.

### Run 2: Trend Gate ENABLED (Trend Gate Evaluation)
- **`InpEnableTrendGate`**: `true`
- **Purpose**: Measure the impact of macro H4 trend-gating on annual expectancy and profit factors.

### Annualized Performance Comparison

| Period | Metric | Trend Gate = OFF (Baseline) | Trend Gate = ON | Net Change |
|:---:|---|:---:|:---:|:---:|
| **TOTAL** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor <br> Average R | 69 <br> 18.84% <br> +0.1954 ATR <br> 1.54 <br> +0.1954 R | 56 <br> 16.07% <br> +0.1196 ATR <br> 1.30 <br> +0.1196 R | -13 trades (-18.8%) <br> -2.77% <br> -0.0758 ATR <br> -0.24 <br> -0.0758 R |
| **2022** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor <br> Average R | 16 <br> 31.25% <br> +0.3206 ATR <br> 1.71 <br> +0.3206 R | 13 <br> 15.38% <br> -0.0669 ATR <br> 0.88 <br> -0.0669 R | -3 trades <br> -15.87% <br> **-0.3875 ATR** <br> **-0.83** <br> (Turned Net Unprofitable!) |
| **2023** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor <br> Average R | 24 <br> 8.33% <br> -0.1091 ATR <br> 0.75 <br> -0.1091 R | 17 <br> 11.76% <br> -0.1360 ATR <br> 0.72 <br> -0.1360 R | -7 trades <br> +3.43% <br> **-0.0269 ATR** <br> **-0.03** <br> (Degradation Worse!) |
| **2024** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor <br> Average R | 18 <br> 22.22% <br> +0.4599 ATR <br> 2.72 <br> +0.4599 R | 15 <br> 20.00% <br> +0.4787 ATR <br> 2.88 <br> +0.4787 R | -3 trades <br> -2.22% <br> **+0.0188 ATR** <br> **+0.16** <br> (Slightly Improved) |
| **2025** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor <br> Average R | 11 <br> 18.18% <br> +0.2452 ATR <br> 1.96 <br> +0.2452 R | 11 <br> 18.18% <br> +0.2452 ATR <br> 1.96 <br> +0.2452 R | 0 trades <br> 0.00% <br> 0.0000 ATR <br> 0.00 <br> 0.0000 R |

---

## 3. Why the H4 Trend Gate Failed

The data reveals that the H4 Trend Gate failed on two fronts:

### A. Failure to Prevent 2023 Degradation
In 2023 (a strongly trending year), Trend Gate successfully blocked **7 trades** (reducing count from 24 to 17), but the overall expectancy of the remaining trades degraded from **-0.1091 ATR to -0.1360 ATR** (Profit Factor fell from 0.75 to 0.72).
- **Reason**: In a trending year, stop hunts regularly turn into full structural breakouts. Gating entries based on macro swing trend state alone does not prevent the EA from taking range-bound style counter-trend entries *inside* periods classified as "Range" which quickly turn into strong trend continuations.

### B. Severe Damage to 2022 Performance (The Reversal Paradox)
In 2022 (a highly profitable year for sweeps), Trend Gate blocked only **3 trades**, but this turned a highly profitable year (**+0.3206 ATR**, PF 1.71) into a losing one (**-0.0669 ATR**, PF 0.88).
- **Reason**: Stop sweeps are by nature *liquidity exhaustion pivots*. A strong BSL sweep ($\ge 0.50$ ATR) often represents the exact peak of a bullish leg on H4. Under a simple H4 Trend Gate:
  - If H4 trend is strongly **Bullish**, the gate **blocks Short entries**.
  - This blocks the exact high-probability counter-trend reversals at swing peaks, which was the main driver of the $+0.32$ ATR edge in 2022.
  - Consequently, the Trend Gate ended up blocking the system's biggest winning outliers.

---

## 4. Official Decision

> [!CAUTION]
> ### **DECISION: H4 Trend Gate Rejected**
> The minimalist H4 Trend Gate filter is officially **Rejected** for production. It introduces a structural paradox that blocks outlier winners (as in 2022) while failing to protect the strategy from trending run-overs (as in 2023). Total expectancy dropped by **38.7%** (from +0.1954 to +0.1196 ATR).

### Status of Phase 5A
- **Status**: **Completed**  
- **Verdict**: **FAILED HYPOTHESIS**  
- **Code Status**: Clean integration, 0 errors, 0 warnings. The pipeline is validated and frozen. No source code modifications are required for the existing engine chain.

---

## 5. Next Steps for Phase 5B (Continuation Path)
To recover the loss-protection edge without blocking outlier winners, the next agent/phase must explore alternative, dynamic gating models:
1. **Dynamic Volatility Regime Filters**: Rather than swing-based trend classification, use ATR or Bollinger Band Expansion/Contraction ratios to block reversal trades during high-velocity breakout expansions.
2. **Breach Depth / Excursion Gating**: Block reversals if the sweep size ATR is too deep relative to H4 swings, which signals high-momentum breakouts rather than stop hunts.
3. **Execution Trailing / Risk Optimization**: Implement dynamic breakeven triggers and partial exits to capture the high median MFE12 (0.9055 ATR) before price has time to reverse at the 12-bar limit.
