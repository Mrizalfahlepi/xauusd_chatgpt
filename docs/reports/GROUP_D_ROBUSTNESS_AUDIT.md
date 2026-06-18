# GROUP D REJECTION ROBUSTNESS AUDIT

**Date**: 2026-06-13T20:10:00Z  
**Phase**: Phase 4.3 — Robustness & Outlier Audit  
**Target Dataset**: [LiquidityValidation.csv](file:///c:/xauusd_chatgpt/src/tests/LiquidityValidation.csv) (522 events, 2022–2025)  
**Output Report**: `docs/reports/GROUP_D_ROBUSTNESS_AUDIT.md`  
**Git Status**: UNSTAGED (As instructed)  

---

## 1. Executive Summary

In our previous edge analysis, we discovered that **Group D (Rejection Margin $\ge 0.50$ ATR)** was the only group to achieve a positive net expectancy (**$+0.0164$ ATR**) and a strong Edge Ratio (**1.1656**) at the 12-bar M30 horizon.

This robustness audit evaluates whether this positive edge is a stable property of high-strength rejections, or if it is an artifact dominated by a small number of extreme outliers (extreme winners). By listing all 69 Group D events, calculating median metrics, and sequentially removing the top 10% and 20% best-performing events, we prove that the edge is **highly fragile and entirely dependent on a few outlier winners**.

---

## 2. Group D Event Breakdown

* **Total Event Count**: **69** (13.22% of the 522 total breaches)
* **BSL Count**: **34** (49.28% of Group D)
* **SSL Count**: **35** (50.72% of Group D)

---

## 3. Complete Event Log (Group D)

Below is the complete list of all 69 events in Group D, showing their parameters and 12-bar outcomes:

| Event # | Datetime | Pool Type | Rejection Margin (ATR) | Sweep Size (ATR) | MFE12 (ATR) | MAE12 (ATR) | Net Close 12 (ATR) |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 2022.01.25 15:00 | BSL | 0.5578 | 0.5114 | 0.0603 | 1.4214 | -0.6149 |
| 2 | 2022.02.03 15:00 | SSL | 0.8349 | 0.6982 | 1.4483 | 0.0536 | 0.9431 |
| 3 | 2022.02.10 13:30 | SSL | 1.2918 | 0.6189 | 2.4545 | 1.1467 | -0.1586 |
| 4 | 2022.03.29 13:30 | SSL | 1.0813 | 0.1171 | 1.1969 | 0.1606 | 1.0213 |
| 5 | 2022.04.12 13:30 | BSL | 0.8223 | 0.3196 | 0.0493 | 1.7120 | -0.7653 |
| 6 | 2022.06.10 12:30 | SSL | 1.4300 | 0.4880 | 5.4781 | 1.4480 | 5.1302 |
| 7 | 2022.06.29 10:00 | SSL | 0.5217 | 0.1177 | 2.2516 | 0.6070 | 0.0247 |
| 8 | 2022.06.29 13:30 | BSL | 1.8743 | 0.2258 | 0.2747 | 0.5177 | -0.2445 |
| 9 | 2022.07.13 14:00 | SSL | 0.5294 | 0.3304 | 2.2686 | 0.1428 | 0.9962 |
| 10 | 2022.07.13 15:00 | BSL | 0.6728 | 0.1743 | 0.8404 | 0.2140 | 0.4101 |
| 11 | 2022.08.09 14:30 | BSL | 0.5414 | 0.2130 | 0.1240 | 1.0110 | -0.4747 |
| 12 | 2022.08.26 14:00 | SSL | 0.5242 | 0.1620 | 0.2174 | 1.7370 | -1.1797 |
| 13 | 2022.09.21 18:00 | SSL | 0.8037 | 0.8092 | 3.1262 | 1.2019 | -0.8907 |
| 14 | 2022.11.02 18:30 | BSL | 2.1695 | 0.3022 | 2.1968 | 0.3342 | 1.4194 |
| 15 | 2022.11.23 13:30 | SSL | 0.5981 | 0.8592 | 2.2927 | 0.1656 | 2.1060 |
| 16 | 2022.11.30 13:30 | BSL | 1.1382 | 0.1303 | 1.3632 | 1.8087 | -1.6680 |
| 17 | 2023.01.12 14:30 | BSL | 0.5988 | 1.1528 | 0.2899 | 2.4578 | -2.2891 |
| 18 | 2023.02.07 18:00 | BSL | 0.7807 | 0.1197 | 0.6082 | 0.5021 | -0.3780 |
| 19 | 2023.02.14 13:30 | BSL | 0.5847 | 0.5139 | 2.6217 | 0.5214 | 0.9336 |
| 20 | 2023.02.23 13:30 | SSL | 0.8863 | 0.2256 | 0.6118 | 0.9474 | -0.3389 |
| 21 | 2023.03.10 09:30 | BSL | 0.5282 | 0.2098 | 0.1002 | 5.0444 | -4.4275 |
| 22 | 2023.03.12 22:00 | BSL | 0.6682 | 0.4590 | 1.2196 | 0.5995 | 0.0597 |
| 23 | 2023.05.01 14:00 | BSL | 0.7231 | 0.2407 | 1.0027 | 0.0434 | 0.8310 |
| 24 | 2023.05.17 14:00 | SSL | 0.6795 | 0.4737 | 0.1902 | 0.5404 | -0.1520 |
| 25 | 2023.06.09 12:30 | BSL | 0.8750 | 0.3071 | 0.7698 | 0.6244 | 0.1742 |
| 26 | 2023.06.13 12:30 | SSL | 1.8640 | 0.2004 | 0.6721 | 3.2091 | -3.1741 |
| 27 | 2023.06.21 13:30 | SSL | 0.5382 | 0.8646 | 1.2842 | 0.6270 | 0.6869 |
| 28 | 2023.06.29 14:00 | SSL | 0.8532 | 0.4434 | 0.5795 | 0.4950 | -0.1501 |
| 29 | 2023.07.05 13:30 | BSL | 0.9429 | 0.2607 | 1.7354 | 0.1531 | 1.6194 |
| 30 | 2023.07.11 07:00 | BSL | 0.5805 | 0.2516 | 0.3432 | 1.2026 | -0.1584 |
| 31 | 2023.08.15 12:30 | SSL | 0.6487 | 0.9161 | 1.7756 | 0.7416 | -0.1797 |
| 32 | 2023.08.23 12:30 | BSL | 0.6015 | 0.1849 | 0.1318 | 2.8259 | -2.2078 |
| 33 | 2023.09.01 13:30 | BSL | 1.2237 | 0.5482 | 2.2343 | 0.0000 | 0.7834 |
| 34 | 2023.09.13 12:30 | SSL | 1.0059 | 0.4277 | 0.6655 | 0.8256 | -0.5869 |
| 35 | 2023.09.26 15:00 | SSL | 0.5666 | 0.1155 | 0.3957 | 0.9979 | -0.4946 |
| 36 | 2023.10.05 13:00 | SSL | 0.5365 | 0.1590 | 0.3965 | 0.6536 | 0.1416 |
| 37 | 2023.10.06 14:30 | BSL | 0.8252 | 0.3351 | 0.0000 | 1.6507 | -1.2230 |
| 38 | 2023.10.25 14:00 | BSL | 0.7476 | 0.3716 | 1.6218 | 1.0976 | -0.3214 |
| 39 | 2023.11.03 13:00 | BSL | 0.5174 | 1.3018 | 0.1607 | 1.5610 | -0.6248 |
| 40 | 2023.11.07 13:30 | SSL | 0.5313 | 0.5338 | 0.5196 | 0.9712 | 0.1485 |
| 41 | 2024.01.11 13:30 | BSL | 1.7649 | 0.8211 | 2.2739 | 0.7664 | 0.4184 |
| 42 | 2024.01.25 13:30 | SSL | 1.0170 | 0.2055 | 0.7493 | 0.8566 | -0.1951 |
| 43 | 2024.02.02 14:30 | SSL | 0.6318 | 0.1199 | 0.3410 | 0.6902 | 0.0637 |
| 44 | 2024.02.08 09:30 | SSL | 0.7932 | 0.1289 | 0.5388 | 2.5284 | -0.5578 |
| 45 | 2024.02.08 14:00 | SSL | 0.8603 | 0.4245 | 1.0975 | 0.1155 | 0.7494 |
| 46 | 2024.02.22 09:00 | BSL | 0.5594 | 0.1218 | 1.8989 | 0.2927 | 1.7560 |
| 47 | 2024.03.20 18:00 | BSL | 0.5462 | 0.3521 | 0.9388 | 6.2171 | -4.8987 |
| 48 | 2024.04.23 02:00 | SSL | 0.5431 | 0.2662 | 0.1528 | 0.7769 | -0.2662 |
| 49 | 2024.05.03 13:30 | SSL | 0.6512 | 0.3320 | 0.9470 | 0.5313 | 0.8193 |
| 50 | 2024.05.17 15:00 | BSL | 0.9943 | 0.1123 | 0.2249 | 1.6353 | -1.2704 |
| 51 | 2024.07.05 12:30 | SSL | 2.7780 | 0.3792 | 2.6278 | 0.1834 | 2.4283 |
| 52 | 2024.08.14 12:30 | BSL | 0.7779 | 0.2056 | 2.6808 | 0.0703 | 1.8374 |
| 53 | 2024.08.15 13:00 | SSL | 1.1117 | 0.5075 | 0.9211 | 1.2836 | 0.8169 |
| 54 | 2024.08.15 13:30 | SSL | 0.5534 | 0.1719 | 1.4793 | 0.0000 | 0.9577 |
| 55 | 2024.09.18 18:30 | BSL | 1.3120 | 0.9904 | 2.7320 | 0.0351 | 1.9448 |
| 56 | 2024.10.03 14:00 | SSL | 0.7339 | 0.2668 | 1.0995 | 0.2989 | 0.6515 |
| 57 | 2024.10.10 12:30 | SSL | 1.4064 | 0.1673 | 0.3242 | 0.6481 | 0.0974 |
| 58 | 2024.12.12 01:00 | BSL | 0.5424 | 0.3689 | 1.0831 | 0.4649 | -0.3564 |
| 59 | 2025.04.07 01:00 | SSL | 0.9959 | 0.1553 | 0.9055 | 0.1410 | 0.0041 |
| 60 | 2025.06.11 12:30 | BSL | 0.6869 | 0.6419 | 0.9680 | 0.5868 | -0.3965 |
| 61 | 2025.06.23 17:00 | BSL | 0.5326 | 0.1456 | 2.5768 | 0.4655 | 1.6954 |
| 62 | 2025.06.26 13:30 | SSL | 0.5175 | 0.1255 | 1.0682 | 0.5174 | 0.7331 |
| 63 | 2025.07.17 14:00 | SSL | 0.6150 | 0.1196 | 0.6728 | 0.0334 | 0.5466 |
| 64 | 2025.09.17 18:00 | BSL | 1.2869 | 0.2742 | 2.2634 | 0.1429 | 1.7217 |
| 65 | 2025.09.29 01:00 | BSL | 0.5638 | 0.2476 | 0.1733 | 2.3734 | -2.0920 |
| 66 | 2025.10.21 14:30 | SSL | 0.9189 | 0.1847 | 0.2220 | 0.8615 | -0.2581 |
| 67 | 2025.12.03 14:30 | BSL | 0.6034 | 0.3529 | 0.5696 | 0.5575 | 0.2102 |
| 68 | 2025.12.18 17:00 | BSL | 0.9075 | 0.6027 | 0.2190 | 0.5858 | -0.1422 |
| 69 | 2025.12.29 07:00 | SSL | 0.7178 | 0.1024 | 0.5278 | 1.1526 | -0.6162 |

---

## 4. Robustness Questions & Forensic Answers

### Question 1: Is the Group D sample size statistically meaningful?
**Answer**: **On the border of significance.**  
A sample size of 69 events over a 4-year backtest period (2022–2025) is relatively small, averaging only **1.4 events per month**. While statisticians often consider $n > 30$ sufficient for basic parametric tests, 69 signals are highly susceptible to market regime shifts and data noise. More importantly, this low frequency makes it commercially impractical to trade as a standalone system unless integrated with other components.

### Question 2: Are the results dominated by a few outliers?
**Answer**: **Yes, overwhelmingly.**  
The initial positive expectancy of **$+0.0164$ ATR** is entirely dependent on a tiny handful of extreme winners:
- The single largest winning trade (Event #6 on 2022.06.10) generated **$+5.1302$ ATR**. This trade alone accounts for nearly **4.5 times** the net cumulative expectancy of the entire group!
- The win rate is a coin flip: **50.72% wins** (35 events) vs. **49.28% losses** (34 events).
- As shown below, removing just 7 top-performing trades wipes out the positive edge completely, causing expectancy to crash into significant losses.

### Question 3: What is the median MFE12 and median MAE12?
**Answer**:
* **Median MFE12**: **0.9055 ATR**
* **Median MAE12**: **0.6270 ATR**

*Insight*: The median E-ratio is favorable ($0.9055 / 0.6270 = 1.4442$). This indicates that price typically makes a significant intraday excursion in the trade direction prior to the 12-bar mark. However, despite this intraday volatility bias, the final close at the 12-bar mark frequently retraces back into losses for the average trade.

### Question 4: Remove the top 10% best events and recalculate expectancy.
* **Events Removed**: 7 best events (highest positive `cls12` values).
* **Initial Expectancy**: `+0.0164` ATR
* **Recalculated Expectancy**: **$-0.2548$ ATR**
* **Change**: Plunges by **$-0.2712$ ATR** into a substantial net loss.

### Question 5: Remove the top 20% best events and recalculate expectancy.
* **Events Removed**: 14 best events.
* **Initial Expectancy**: `+0.0164` ATR
* **Recalculated Expectancy**: **$-0.4445$ ATR**
* **Change**: Plunges by **$-0.4609$ ATR** into a severe net loss.

---

## 5. Strategic Recommendations

1. **Rejection Edge is a Mirage**:
   Do not build an entry model assuming that strong rejections represent a robust, steady edge. The positive expectancy is an outlier-driven illusion. If those 7 large V-reversal spikes are missing (or if execution slippage cuts them short), the system will bleed capital at a rate of $-0.25$ to $-0.44$ ATR per trade.
   
2. **Shift Focus to Trailing Execution**:
   Because the **median MFE12 is high (0.9055 ATR)** compared to the **median MAE12 (0.6270 ATR)**, the trade *does* go in our favor in the majority of cases before reversing. The failure lies in the fixed-time exit (12 bars). To extract value from stop runs:
   - Implement **aggressive break-even triggers** once price moves in favor.
   - Use **tight trailing stops** or exit on MFE targets (e.g., take profit at 0.50 to 0.75 ATR) rather than holding for a fixed duration.
