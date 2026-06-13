# Liquidity Engine Parameter Justification

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: SUBMITTED FOR REVIEW  
**Workspace**: `c:\xauusd_chatgpt`  
**Reference Design**: [LIQUIDITY_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ARCHITECTURE_FREEZE.md)

---

## 1. Executive Summary

This document provides the mathematical and architectural justification for every numerical parameter and threshold defined in the **Phase 4 Liquidity Engine**. In alignment with the project's strict engineering protocol, every threshold is categorized under one of four classifications:

1.  **Validated**: Mathematically validated through historical backtests, empirical audits, or locked in upstream frozen engine code.
2.  **Placeholder - Requires Validation**: Values inserted for structural completeness that have zero statistical backing and must undergo sensitivity analysis.
3.  **Hypothesis**: Theoretical parameters based on market structure concepts that require testing under simulation to verify their statistical edge.
4.  **Future Optimization**: Parameters governing execution performance, memory overhead, or caching windows that will be tuned after integration.

No parameter may be treated as an approved system decision unless classified as **Validated**.

---

## 2. Parameter Justification Matrix

| Parameter / Threshold | Default Value | Classification | Source & Reference | Architectural Purpose |
|:---|:---|:---|:---|:---|
| **`InpSnrLiquidityTolATR`** | `0.10` H4 ATR | **Validated / Frozen** | [SnrEngine.mqh:L181](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh#L181) | Multiplier determining the vertical width of BSL/SSL pools (e.g., `swing.price` $\pm$ `0.10 × ATR`). Calculated and frozen in Module 3. |
| **`InpLiqSweepMinSizeATR`** | `0.05` H4 ATR | **Hypothesis** | [LIQUIDITY_ENGINE_DESIGN.md:L118](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L118) | The minimum price penetration depth required to register a sweep, filtering out micro-tick noise and spread variations. |
| **`InpLiqSweepMaxSizeATR`** | `1.50` H4 ATR | **Placeholder - Requires Validation** | [LIQUIDITY_ARCHITECTURE_FREEZE.md:L213](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ARCHITECTURE_FREEZE.md#L213) | The maximum excursion depth allowed for a sweep. Excursions exceeding this trigger the breakout filter, blocking reversal entry signals. |
| **`InpLiqDecayBars`** | `300` H4 Bars | **Hypothesis** | [LIQUIDITY_ENGINE_DESIGN.md:L114](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L114) | The lookback window over which a pool's strength decays linearly to `10%` (~50 trading days). |
| **`InpLiqIncludeMinor`** | `false` | **Validated / Frozen** | [SnrEngine.mqh:L1100-1130](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh#L1100-L1130) | Dictates whether Minor Swings are mapped as pools. Locked as `false` because the frozen SNR engine only processes Major Swings. |
| **`ATR Period`** | `14` | **Validated / Frozen** | [StructureEngine.mqh:L218](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L218) | Standard indicator lookback used to calculate local price volatility. |
| **Minor Sweep Bracket** | $\le 0.25$ H4 ATR | **Hypothesis** | [LIQUIDITY_ENGINE_DESIGN.md:L97](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L97) | Excursion depth bracket representing tight stop runs. |
| **Medium Sweep Bracket** | $0.25$ to $0.75$ ATR | **Hypothesis** | [LIQUIDITY_ENGINE_DESIGN.md:L98](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L98) | Excursion depth bracket representing standard institutional stop grabs. |
| **Major Sweep Bracket** | $> 0.75$ ATR | **Hypothesis** | [LIQUIDITY_ENGINE_DESIGN.md:L99](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ENGINE_DESIGN.md#L99) | Excursion depth bracket representing deep stop runs. |
| **`barsToCache`** | `300` Bars | **Future Optimization** | [LIQUIDITY_ARCHITECTURE_FREEZE.md:L264](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ARCHITECTURE_FREEZE.md#L264) | Lookback window size for caching H4 and M30 price history locally. |

---

## 3. Parameter-by-Parameter Analysis

### 3.1 `InpSnrLiquidityTolATR = 0.10`
*   **Analysis**: This value determines the vertical price height of the stop-loss cluster pool. It is an input parameter for Module 3 (`CSnrEngine`) and is mathematically frozen. The 4-year statistical validation of SNR levels ([SNR_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/SNR_STATISTICAL_REPORT.md)) demonstrated a **98.15% Liquidity Sweep Rate** using this `0.10` ATR tolerance, proving that pools mapped at this width represent highly accurate targets for price sweeps.
*   **Verdict**: **Validated / Frozen**.

### 3.2 `InpLiqSweepMinSizeATR = 0.05`
*   **Analysis**: When trading Gold, spread expansions and minor price fluctuations at H4 swing highs/lows can trigger false break signals. A minimum filter of `0.05` ATR (equivalent to ~5-10 pips depending on volatility) is proposed to ensure price has genuinely penetrated the swing price. However, this is a theoretical threshold. If set too high, it may miss valid, low-slippage sweeps; if set too low, it may trigger on spread noise.
*   **Verdict**: **Hypothesis**. Must be verified in Phase 4.1.

### 3.3 `InpLiqSweepMaxSizeATR = 1.50`
*   **Analysis**: This is the most critical parameter for trade safety. If a stop run goes too deep (e.g. exceeding 1.50 H4 ATR), price is highly likely to be in a strong trend continuation breakout rather than a reversal sweep. Reversal entries must be blocked in this scenario. The value `1.50` ATR was selected as a conceptual default based on Module 3's maximum cluster width cap (`InpSnrMaxClusterWidthATR = 1.50`), but it has no empirical statistical backing for breakout filtering.
*   **Verdict**: **Placeholder - Requires Validation**.

### 3.4 `InpLiqDecayBars = 300`
*   **Analysis**: Linear decay models the assumption that order books decay over time as orders expire, positions are closed, or stop-losses are moved. A 300-bar lookback (~50 trading days) is a common heuristic for swing point relevance. However, no statistical analysis has been conducted on the relationship between pool age and sweep profitability on Gold.
*   **Verdict**: **Hypothesis**.

### 3.5 `InpLiqIncludeMinor = false`
*   **Analysis**: Under the **Read-Only Dependency Principle**, `CLiquidityEngine` can only process liquidity pools that are mapped and exposed by the upstream SNR engines. The frozen SNR Engine ([SnrEngine.mqh:L1100-1130](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh#L1100-L1130)) only scans major swings. Minor swings are excluded at compilation. Thus, setting `InpLiqIncludeMinor` to `true` is structurally impossible without breaking the Phase 3 freeze.
*   **Verdict**: **Validated / Frozen** (locked as `false`).

### 3.6 Sweep Excursion Brackets (Minor, Medium, Major)
*   **Analysis**: These brackets categorize stop runs into volatility classes. The classification is designed to feed downstream entry logic (e.g., a Major Sweep might require a stronger candle rejection setup like an engulfing, whereas a Minor Sweep might accept a pinbar). These ranges are based on standard deviation heuristics and have not been validated against historical reversal trade win rates.
*   **Verdict**: **Hypothesis**.

### 3.7 Caching Window (`barsToCache = 300`)
*   **Analysis**: Controls the length of local price arrays (`m_cachedH4Highs`, etc.). Caching 300 bars is sufficient to calculate H4 ATR(14) and align M30/H4 price history. While functional, this value is a placeholder and can be optimized down to reduce memory footprint if backtesting shows a smaller lookback (e.g. 100 bars) produces identical ATR and alignment results.
*   **Verdict**: **Future Optimization / Placeholder**.

---

## 4. Validation Protocol Mandate

To satisfy the **Optimality and Correctness Principle**, the validation phase of Module 4 (Phase 4.1) must execute the following validation tasks before any code is marked as frozen:

1.  **Sensitivity Analysis for Breakout Filter (`InpLiqSweepMaxSizeATR`)**:
    *   *Range to Test*: `0.50` to `2.00` H4 ATR, in increments of `0.25` ATR.
    *   *Target Metric*: Maximize the Sharpe Ratio of reversal setups while maintaining a false positive breakout classification rate below `5.0%`.
2.  **Validation of Minimum Sweep Filter (`InpLiqSweepMinSizeATR`)**:
    *   *Range to Test*: `0.00` (no filter) to `0.15` ATR, in increments of `0.02` ATR.
    *   *Target Metric*: Filter out spread-noise triggers without sacrificing entry precision on genuine stop runs.
3.  **Validation of Decay Window (`InpLiqDecayBars`)**:
    *   *Range to Test*: `100`, `200`, `300`, `500` bars.
    *   *Target Metric*: Measure the win rate of sweeps occurring in pools older than 150 bars to verify if linear strength decay matches actual market behavior.

---
*End of Parameter Justification Document.*
