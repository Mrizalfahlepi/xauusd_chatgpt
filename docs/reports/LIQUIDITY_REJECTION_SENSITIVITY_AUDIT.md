# LIQUIDITY ENGINE v1.0 - REJECTION SENSITIVITY AUDIT

**Date**: 2026-06-13T20:07:00Z  
**Phase**: Phase 4.3 — Forensic Research (Rejection Sensitivity)  
**Target File**: [LiquidityValidation.csv](file:///c:/xauusd_chatgpt/src/tests/LiquidityValidation.csv)  
**Output Report**: `docs/reports/LIQUIDITY_REJECTION_SENSITIVITY_AUDIT.md`  
**Git Status**: UNSTAGED (As instructed)  

---

## 1. Executive Summary

This forensic audit evaluates the sensitivity of the `CLiquidityEngine`'s rejection rate to changes in the rejection definition. In the current engine implementation, a breach event is classified as a **Rejection** if the bar Close simply crosses back past the inner boundary of the pool (`Close < priceLow` for BSL; `Close > priceHigh` for SSL). Because the pool width is extremely narrow (fixed at `0.10` H4 ATR), this condition has led to an empirically high rejection rate of 99.62% in the 4-year validation dataset.

To understand the impact of the rejection threshold, this audit extracts the **first 50 events** from `LiquidityValidation.csv` and analyzes the distribution of four critical metrics: pool width, breach distance, close distance, and rejection margin. Finally, we answer how the rejection rate would change if we required the close to penetrate beyond the inner boundary by varying ATR distances.

---

## 2. Mathematical Definitions & Formulas

For each event, the following metrics are calculated using the closed M30 breaching bar's OHLC, the pool boundaries, and the H4 ATR value:

1. **Pool Width ATR**: The vertical height of the mapped liquidity pool.
   $$\text{PoolWidth}_{\text{ATR}} = \frac{PriceHigh - PriceLow}{ATR}$$
2. **Breach Distance ATR**: The distance the price swept beyond the outer boundary of the pool.
   - For BSL: $\text{BreachDist}_{\text{ATR}} = \frac{High - PriceHigh}{ATR}$
   - For SSL: $\text{BreachDist}_{\text{ATR}} = \frac{PriceLow - Low}{ATR}$
3. **Close Distance ATR**: The distance of the closed bar from the outer boundary of the pool.
   - For BSL: $\text{CloseDist}_{\text{ATR}} = \frac{PriceHigh - Close}{ATR}$
   - For SSL: $\text{CloseDist}_{\text{ATR}} = \frac{Close - PriceLow}{ATR}$
4. **Rejection Margin ATR**: The margin by which the close exceeded the inner boundary in the rejection direction.
   - For BSL: $\text{RejMargin}_{\text{ATR}} = \frac{PriceLow - Close}{ATR}$
   - For SSL: $\text{RejMargin}_{\text{ATR}} = \frac{Close - PriceHigh}{ATR}$

*Note: Since the pool width is exactly $0.10$ ATR, the relationship between these variables is:*
$$\text{RejMargin}_{\text{ATR}} = \text{CloseDist}_{\text{ATR}} - \text{PoolWidth}_{\text{ATR}}$$
$$\text{RejMargin}_{\text{ATR}} = \text{CloseDist}_{\text{ATR}} - 0.10$$

---

## 3. Raw Calculations (First 50 Events)

Below is the complete dataset of the first 50 events extracted from [LiquidityValidation.csv](file:///c:/xauusd_chatgpt/src/tests/LiquidityValidation.csv), with each metric calculated to 4 decimal places.

| Event # | Datetime | Type | Pool Width (ATR) | Breach Dist (ATR) | Close Dist (ATR) | Rejection Margin (ATR) | Rejection Status |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 2022.01.05 08:00 | BSL | 0.1000 | 0.0043 | 0.1609 | 0.0609 | REJ |
| 2 | 2022.01.06 10:00 | SSL | 0.1001 | 0.2137 | 0.4190 | 0.3189 | REJ |
| 3 | 2022.01.06 14:00 | SSL | 0.1000 | 0.1693 | 0.1453 | 0.0453 | REJ |
| 4 | 2022.01.06 15:00 | SSL | 0.1000 | 0.0572 | 0.2747 | 0.1747 | REJ |
| 5 | 2022.01.07 13:30 | SSL | 0.1000 | 0.4059 | 0.4619 | 0.3619 | REJ |
| 6 | 2022.01.12 13:30 | BSL | 0.0999 | 0.1692 | 0.4126 | 0.3127 | REJ |
| 7 | 2022.01.12 14:30 | BSL | 0.0999 | 0.0721 | 0.3181 | 0.2182 | REJ |
| 8 | 2022.01.13 16:00 | SSL | 0.1000 | 0.2433 | 0.4150 | 0.3150 | REJ |
| 9 | 2022.01.14 08:00 | BSL | 0.1000 | 0.0571 | 0.3504 | 0.2504 | REJ |
| 10 | 2022.01.24 09:00 | BSL | 0.1001 | 0.0412 | 0.1394 | 0.0394 | REJ |
| 11 | 2022.01.25 15:00 | BSL | 0.1000 | 0.4113 | 0.6578 | 0.5578 | REJ |
| 12 | 2022.01.26 14:00 | SSL | 0.1001 | 0.2814 | 0.1738 | 0.0737 | REJ |
| 13 | 2022.01.26 14:30 | SSL | 0.1001 | 0.4133 | 0.2888 | 0.1887 | REJ |
| 14 | 2022.01.26 19:00 | SSL | 0.1000 | 0.3296 | 0.5807 | 0.4807 | REJ |
| 15 | 2022.01.27 13:00 | SSL | 0.1000 | 0.0409 | 0.1707 | 0.0707 | REJ |
| 16 | 2022.02.02 15:00 | BSL | 0.1001 | 0.2210 | 0.4325 | 0.3325 | REJ |
| 17 | 2022.02.03 15:00 | SSL | 0.0999 | 0.5983 | 0.9348 | 0.8349 | REJ |
| 18 | 2022.02.07 13:30 | BSL | 0.1001 | 0.2132 | 0.2377 | 0.1377 | REJ |
| 19 | 2022.02.07 14:00 | BSL | 0.1001 | 0.0778 | 0.1413 | 0.0413 | REJ |
| 20 | 2022.02.07 14:30 | BSL | 0.1001 | 0.0117 | 0.2382 | 0.1381 | REJ |
| 21 | 2022.02.08 14:00 | BSL | 0.1001 | 0.0434 | 0.3811 | 0.2811 | REJ |
| 22 | 2022.02.10 13:30 | SSL | 0.0999 | 0.5190 | 1.3917 | 1.2918 | REJ |
| 23 | 2022.02.11 07:00 | SSL | 0.1000 | 0.0413 | 0.5031 | 0.4031 | REJ |
| 24 | 2022.02.15 15:00 | SSL | 0.1000 | 0.1399 | 0.1256 | 0.0256 | REJ |
| 25 | 2022.02.23 09:30 | SSL | 0.1001 | 0.0923 | 0.3394 | 0.2394 | REJ |
| 26 | 2022.02.24 19:00 | SSL | 0.1000 | 0.0077 | 0.2882 | 0.1882 | REJ |
| 27 | 2022.03.11 13:30 | SSL | 0.1000 | 0.0102 | 0.1498 | 0.0498 | REJ |
| 28 | 2022.03.15 14:30 | SSL | 0.1000 | 0.3595 | 0.2866 | 0.1865 | REJ |
| 29 | 2022.03.16 14:00 | SSL | 0.1000 | 0.1646 | 0.2676 | 0.1676 | REJ |
| 30 | 2022.03.29 09:00 | SSL | 0.1000 | 0.0178 | 0.1633 | 0.0633 | REJ |
| 31 | 2022.03.29 12:30 | SSL | 0.1000 | 0.2970 | 0.3072 | 0.2072 | REJ |
| 32 | 2022.03.29 13:00 | SSL | 0.1000 | 0.0712 | 0.2938 | 0.1938 | REJ |
| 33 | 2022.03.29 13:30 | SSL | 0.1000 | 0.0170 | 1.1813 | 1.0813 | REJ |
| 34 | 2022.03.31 13:30 | BSL | 0.1000 | 0.2463 | 0.1708 | 0.0708 | REJ |
| 35 | 2022.04.05 14:00 | BSL | 0.1000 | 0.8407 | 0.4809 | 0.3809 | REJ |
| 36 | 2022.04.07 14:00 | BSL | 0.1000 | 0.0085 | 0.2712 | 0.1713 | REJ |
| 37 | 2022.04.07 15:00 | BSL | 0.1000 | 0.3225 | 0.3372 | 0.2373 | REJ |
| 38 | 2022.04.08 14:30 | BSL | 0.1000 | 0.3255 | 0.2726 | 0.1725 | REJ |
| 39 | 2022.04.11 12:30 | BSL | 0.1000 | 0.2957 | 0.4431 | 0.3431 | REJ |
| 40 | 2022.04.12 13:30 | BSL | 0.1000 | 0.2197 | 0.9223 | 0.8223 | REJ |
| 41 | 2022.04.13 10:30 | BSL | 0.1000 | 0.0747 | 0.2285 | 0.1285 | REJ |
| 42 | 2022.04.19 13:00 | SSL | 0.1000 | 0.2740 | 0.3782 | 0.2782 | REJ |
| 43 | 2022.04.19 13:30 | SSL | 0.1000 | 0.0135 | 0.4287 | 0.3287 | REJ |
| 44 | 2022.04.22 15:00 | SSL | 0.1000 | 0.0513 | 0.5369 | 0.4369 | REJ |
| 45 | 2022.04.25 01:00 | SSL | 0.1000 | 0.0188 | 0.1780 | 0.0780 | REJ |
| 46 | 2022.04.27 08:00 | SSL | 0.1000 | 0.3937 | 0.4658 | 0.3658 | REJ |
| 47 | 2022.04.27 08:30 | SSL | 0.1000 | 0.0055 | 0.3048 | 0.2048 | REJ |
| 48 | 2022.04.28 04:30 | SSL | 0.1000 | 0.0536 | 0.1540 | 0.0540 | REJ |
| 49 | 2022.04.28 06:30 | SSL | 0.1000 | 0.1712 | 0.5500 | 0.4500 | REJ |
| 50 | 2022.04.29 07:00 | BSL | 0.1000 | 0.1090 | 0.1317 | 0.0317 | REJ |

---

## 4. Distribution Tables

Below are the percentile-based distribution tables for the calculated metrics across the first 50 events.

### 4.1 Breach Distance ATR Distribution
- **Mean**: `0.1847` ATR
- **StdDev**: `0.1772` ATR

| Percentile | Value (ATR) | Interpretation |
|:---|:---:|:---|
| **0% (Min)** | `0.0043` | Extremely shallow breach; barely penetrated the outer boundary. |
| **10%** | `0.0116` | Shallow breach. |
| **25%** | `0.0418` | Minor stop run. |
| **50% (Median)** | `0.1522` | Standard sweep excursion depth. |
| **75%** | `0.2921` | Deep stop run. |
| **90%** | `0.4064` | Very deep sweep. |
| **100% (Max)** | `0.8407` | Maximum breach excursion (well below the 1.50 ATR breakout threshold). |

### 4.2 Close Distance ATR Distribution
- **Mean**: `0.3777` ATR
- **StdDev**: `0.2577` ATR

| Percentile | Value (ATR) | Interpretation |
|:---|:---:|:---|
| **0% (Min)** | `0.1256` | Close lands 0.1256 ATR inside the outer boundary. |
| **10%** | `0.1494` | Moderate pull-back. |
| **25%** | `0.1906` | Clear reversal close. |
| **50% (Median)** | `0.3060` | Deep rejection close. |
| **75%** | `0.4405` | Large rejection body. |
| **90%** | `0.5884` | Very large reversal body. |
| **100% (Max)** | `1.3917` | Massive reversal candle. |

### 4.3 Rejection Margin ATR Distribution
- **Mean**: `0.2777` ATR
- **StdDev**: `0.2577` ATR

| Percentile | Value (ATR) | Interpretation |
|:---|:---:|:---|
| **0% (Min)** | `0.0256` | Minimal rejection margin; closed just 0.0256 ATR beyond the inner boundary. |
| **10%** | `0.0494` | Weak rejection margin. |
| **25%** | `0.0906` | Stable rejection margin. |
| **50% (Median)** | `0.2060` | Strong rejection margin (average rejection lands 2x the pool width inside). |
| **75%** | `0.3404` | Very strong rejection. |
| **90%** | `0.4884` | Dominant reversal close. |
| **100% (Max)** | `1.2918` | Maximum rejection margin. |

---

## 5. Rejection Sensitivity Analysis

The key question analyzed is:  
**Would the rejection rate materially change if rejection required the close to land beyond the inner boundary by a set ATR tolerance ($0.10$, $0.20$, $0.30$, $0.50$ ATR) instead of the current $0.00$ ATR definition?**

Applying these varying buffers to the first 50 events yields the following sensitivity table:

| Required Rejection Margin (ATR) | Rejected Events Count | Rejection Rate (%) | Impact on Classification |
|:---:|:---:|:---:|:---|
| **0.00 ATR (Current)** | 50 / 50 | **100.00%** | All 50 events classified as Rejections. |
| **0.10 ATR** | 37 / 50 | **74.00%** | 13 events reclassified as Breakouts (26% reduction). |
| **0.20 ATR** | 26 / 50 | **52.00%** | 24 events reclassified as Breakouts (48% reduction). |
| **0.30 ATR** | 18 / 50 | **36.00%** | 32 events reclassified as Breakouts (64% reduction). |
| **0.50 ATR** | 5 / 50 | **10.00%** | 45 events reclassified as Breakouts (90% reduction). |

### Forensic Answers & Insights

1. **Materiality of Changes**: Yes, the rejection rate is **extremely sensitive** to the required rejection margin. Simply requiring a buffer of **$0.10$ ATR** (which is equal to the pool tolerance itself) decreases the rejection rate from **100.00% to 74.00%**. Requiring **$0.20$ ATR** drops it to a near-coin-flip **52.00%**, and a **$0.50$ ATR** requirement renders rejections rare, capturing only the most extreme reversals (10.00%).
2. **Causal Mechanics**: 
   - Under the current definition, any close that crosses the inner boundary (`rejectionMargin > 0.00 ATR`) is classified as a rejection. Because the pool is only $0.10$ ATR wide ($1.15 in Gold), a candle merely needs to close $1.15 past the swing high/low to be classified as a rejection. 
   - A typical M30 candle on Gold easily traverses $2 to $5 (0.15 to 0.45 ATR). Therefore, normal candle bodies that close slightly below the swing point are automatically flagged as "rejections."
   - Introducing an ATR-based rejection margin (such as `0.10` or `0.20` ATR) forces the engine to distinguish between minor overlaps (which are likely to lead to range continuation or consolidation inside the pool) and high-velocity rejections (where price aggressively snaps back inside).
3. **Strategic Conclusion**: The 99.62% rejection rate in the 4-year backtest is indeed a mathematical artifact of the extremely narrow pool width (`0.10` ATR) coupled with a $0.00$ ATR rejection buffer. Implementing a rejection threshold filter inside downstream execution engines (such as the Entry Engine) will be essential to select high-probability trade setups rather than treating every minor breach pullback as a valid trade entry.
