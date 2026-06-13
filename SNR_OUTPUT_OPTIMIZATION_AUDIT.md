# SNR ENGINE v1.0 - OUTPUT OPTIMIZATION & TRADING USABILITY AUDIT

**Date**: 2026-06-13T03:15Z  
**Phase**: Sprint 3.1 — Output Optimization & Usability Audit (Detailed Analysis)  
**Auditor**: Antigravity Agent  
**Target Module**: `CSnrEngine` (v1.0) & `TestSnr.mq5` (v1.0)  
**Data Evaluated**: 4-Year Backtest Logs (7,451 H4 Bars / 176,701 Level Observations)  
**Verdict**: 🔴 **PASS WITH IMPROVEMENTS (REFINE SPRINT 3.2 IS REQUIRED BEFORE FREEZE)**

---

## 1. Score Distribution Audit

The scoring engine maps level quality on a scale of `0` to `100` using a 5-weight linear model. A detailed binning analysis reveals a massive clustering of scores in a narrow range:

### 1.1 Score Frequency Histogram (5-Point Bins)

| Score Band | Count (Observations) | Percentage | Visual Histogram |
|:---|:---:|:---:|:---|
| **0 – 14** | `0` | `0.00%` | |
| **15 – 19** | `172` | `0.10%` | |
| **20 – 24** | `645` | `0.37%` | |
| **25 – 29** | `4,201` | `2.38%` | █ |
| **30 – 34** | `5,029` | `2.85%` | █ |
| **35 – 39** | `2,772` | `1.57%` | █ |
| **40 – 44** | `57,417` | **32.49%** | ████████████████████████████████ |
| **45 – 49** | `74,452` | **42.13%** | ██████████████████████████████████████████ |
| **50 – 54** | `14,998` | `8.49%` | ████████ |
| **55 – 59** | `5,439` | `3.08%` | ███ |
| **60 – 64** | `4,504` | `2.55%` | ██ |
| **65 – 69** | `1,077` | `0.61%` | |
| **70 – 74** | `807` | `0.46%` | |
| **75 – 79** | `377` | `0.21%` | |
| **80 – 84** | `4,232` | `2.40%` | ██ |
| **85 – 89** | `343` | `0.19%` | |
| **90 – 94** | `236` | `0.13%` | |
| **95 – 100** | `0` | `0.00%` | |

### 1.2 Clustering Detection
* **The 40–49 Peak**: A staggering **74.62%** of all levels are clustered in the narrow range between **40 and 49 points** (32.49% in 40–44 and 42.13% in 45–49).
* **Root Cause**: The clustering around 40-49 points occurs because a typical level in `CSnrEngine` overlaps with a Major Swing ($S_{\text{Struct}} = 100 \rightarrow$ contribution: 20 points) and is Fresh ($S_{\text{Fresh}} = 100 \rightarrow$ contribution: 20 points), but has no active S/D zone ($S_{\text{SD}} = 0$), no rejection history ($S_{\text{Reject}} = 0$), and no confluence ($S_{\text{Confl}} = 0$). This yields a baseline score of exactly:
  $$\text{Score} = (0.20 \times 100) + (0.20 \times 100) = 40.0 \text{ points}$$
  If a minor confluence is detected, the score rises slightly to `47.0` (adding $0.10 \times 70 = 7.0$ points), creating the secondary peak.
* **Implication**: Nearly three-quarters of the levels represent baseline, unconfirmed support and resistance points. Rendering all of them creates massive clutter.

---

## 2. Level Density Audit

The level density measures how many horizontal bands are active on the H4 chart at any given moment.

### 2.1 Overall Density Metrics
* **Average Levels per Bar**: `23.72` levels
* **Median Levels per Bar**: `23` levels
* **P95 (95th Percentile) Levels**: `33` levels (95% of the bars have 33 or fewer active levels)
* **Maximum Levels on Bar**: `42` levels

### 2.2 Density by Market Regime

We cross-referenced level counts with the market trend state classified by the upstream `StructureEngine`:

| Market Regime | Bar Count | Average Levels | Median Levels | Max Levels |
|:---|:---:|:---:|:---:|:---:|
| **BULLISH Trend** | `1,474` | `22.76` | `22` | `38` |
| **BEARISH Trend** | `768` | `23.91` | `23` | `38` |
| **RANGE Consolidation** | `5,209` | `23.96` | `24` | `42` |

* **Regime Analysis**: Level density is extremely consistent across all market phases (ranging from 22.76 in Bullish to 23.96 in Range). This indicates that the density is a permanent structural property of the engine's clustering rules (which extract all available historical zones and swings within a 300-bar window) and is not a temporary anomaly of sideways consolidations.

---

## 3. Decision Utility Audit

This audit evaluates the practical value of levels for discretionary traders and the upcoming `EntryEngine` (Phase 5).

### 3.1 Visual Usability Analysis
* **discretionary Trader View**: With a median of 23 active bands on a H4 chart, price action is obscured. A trader looking at the chart sees a "grid" of lines, making it impossible to identify high-probability zones.
* **Entry Engine View**: If all 23 levels are exposed, the Entry Engine will evaluate minor levels that have low score quality. This increases computational overhead and, more critically, leads to **setup dilution**—where low-quality levels trigger losing trades, degrading the overall win rate.

### 3.2 Level Comparison

| Output Group | Size (Avg) | Computational Overhead | Noise Level | Trading Utility |
|:---|:---:|:---|:---|:---|
| **All Levels** | `23.72` | 100% (High) | Extreme (Floorboard grid) | **LOW** (Overwhelming) |
| **Top 10** | `10.00` | 42% (Medium) | High | **MEDIUM** (Still cluttered) |
| **Top 5** | `5.00` | 21% (Low) | Low | **HIGH** (Shows key macro boundaries) |
| **Top 3** | `3.00` | 12.6% (Low) | Minimal | **EXCELLENT** (Highly focused trade triggers) |
| **Top 1** | `1.00` | 4.2% (Minimal) | None | **HIGH** (Best single key level) |

---

## 4. Information Compression Audit

To determine if compressing the level output discards critical data, we measured the percentage of **Score Weight** and **Constituent Volume** (the raw historical swings and zones) retained when filtering the level array:

| Compression Mode | Score Weight Retained (%) | Constituent Volume Covered (%) | Information Lost (%) |
|:---|:---:|:---:|:---:|
| **All Levels (Avg: 23.72)** | `100.00%` | `100.00%` | `0.00%` |
| **Top 10 Levels** | `48.00%` | `53.64%` | `52.00%` |
| **Top 6 Levels** | `30.65%` | `29.48%` | `69.35%` |
| **Top 5 Levels** | `26.18%` | `23.83%` | `73.82%` |
| **Top 4 Levels** | `21.58%` | `18.56%` | `78.42%` |
| **Top 3 Levels** | `16.76%` | `14.02%` | `83.24%` |
| **Top 1 Level** | `6.16%` | `5.26%` | `93.84%` |

### 4.1 Interpretation of Compression Data
* **The Information Trade-off**: Compressing the chart to the **Top 4 levels** retains **21.58%** of the score weight and covers **18.56%** of the raw constituents, resulting in a theoretical information loss of **78.42%**.
* **Is the Lost Information Useful?**: No. As established in the Score Distribution Audit (§1.1), **81.89% of all level observations have scores below 50 points**. These represent minor, isolated price reactions or old, weakened zones. 
* **Conclusion**: The "lost" information is primarily **noise**. Compressing the output to a Top-4 or Top-6 array discards the noise while retaining the highest-quality, high-confluence institutional levels (the 6.53% of levels with score $\ge 60.0$).

---

## 5. Human Readability Audit

A discretionary trader requires an interface that respects the limits of human cognitive load.

* **Cognitive Overload**: A trader cannot track 23 levels. The human brain can comfortably monitor 3 to 7 items simultaneously. A chart with 23 bands triggers "decision paralysis".
* **Visual Interference**: Because MQL5 rectangles drawn on the background layer block the MT5 grid, 23 bands completely obscure the chart structure. The trader loses sight of candles, swing geometries, and minor price patterns.
* **Entry Engine Suitability**: The future `EntryEngine` requires a clean signal-to-noise ratio. Passing 23 coordinates will result in conflicting setups (e.g. price touching a minor support level while inside a neutral node), making automated execution rules overly complex and error-prone.

---

## 6. Recommendations & Path Forward

### **Usability Verdict**: 🟡 **PASS WITH IMPROVEMENTS (REFINE SPRINT 3.2 REQUIRED)**

The SNR Engine in its current state is mathematically sound but **operationally un-usable for automated execution or live trading**. Proceeding directly to Phase 4 (Liquidity) without addressing this output density will pass a cluttered data layer to the Entry Engine, complicating all future development.

### **Recommendation: Implement Sprint 3.2 (Output Prioritization)**
Do **not** freeze Sprint 3. Instead, execute a short **Sprint 3.2 Output Prioritization Sprint** before freezing. 

This sprint will introduce a **3-tier filtering and compression layer** inside the MQL5 class:

1. **Score Threshold filter (`InpMinScoreShow`)**: Suppress all levels with scores below 50.0. This immediately filters out 81.89% of the noise.
2. **Top-N per Side (`InpMaxLevelsPerSide`)**: Limit active arrays to the Top 3 Support and Top 3 Resistance levels, ensuring the chart never displays more than 6 levels.
3. **Proximity Sorting (`InpSortByProximity`)**: Sort output levels by proximity to current price, ensuring the Entry Engine is fed the levels that price is closest to, rather than distant historical levels.
