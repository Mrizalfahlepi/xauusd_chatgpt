# GROUP D TEMPORAL STABILITY AUDIT

**Date**: 2026-06-13T20:13:40Z  
**Phase**: Phase 4.3 — Temporal Stability & Rolling Performance Audit  
**Target Dataset**: [LiquidityValidation.csv](file:///c:/xauusd_chatgpt/src/tests/LiquidityValidation.csv) (69 Group D events, 2022–2025)  
**Output Report**: `docs/reports/GROUP_D_TEMPORAL_STABILITY_AUDIT.md`  
**Git Status**: UNSTAGED (As instructed)  

---

## 1. Executive Summary

In our previous risk-reward model audit, we established that pairing Group D events (rejection margin $\ge 0.50$ ATR) with an asymmetric trade management model (`TP = 2.0 ATR`, `SL = 1.0 ATR`, and a 12-bar exit) yielded a positive expectancy of **$+0.1520$ ATR** and a Profit Factor of **1.4011**.

This audit tests the **temporal stability** of this edge across different years and rolling periods (2022–2025). Professional systematic trading standards require that a trading edge be stable across time and not driven by a single lucky period or market regime. The results below show that the edge is **highly unstable**, with 2023 returning net losses, and the performance heavily concentrated in 2024.

---

## 2. Yearly Performance Breakdown

Below is the segment evaluation of the optimal trade management model (`TP = 2.0 ATR`, `SL = 1.0 ATR`, 12-bar exit) split by year:

| Year | Event Count | Win Rate (Hit TP) | Expectancy (ATR) | Profit Factor | Gross Profit (ATR) | Gross Loss (ATR) | Verdict |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **2022** | 16 | 25.00% | +0.1331 | **1.2584** | 10.3745 | 8.2445 |  Profitable |
| **2023** | 24 | 8.33% | -0.1091 | **0.7452** | 7.6613 | 10.2802 | ❌ Unprofitable |
| **2024** | 18 | 22.22% | +0.4599 | **2.7181** | 13.0950 | 4.8177 |  **Outlier Year** |
| **2025** | 11 | 18.18% | +0.2452 | **1.9644** | 5.4940 | 2.7968 |  Profitable |

---

## 3. Rolling & Comparative Performance

To verify robustness across broader market phases, we group the years into comparative blocks:

| Rolling Segment | Event Count | Win Rate (Hit TP) | Expectancy (ATR) | Profit Factor | Gross Profit (ATR) | Gross Loss (ATR) | Verdict |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **First Half (2022–2023)** | 40 | 15.00% | -0.0122 | **0.9736** | 18.0358 | 18.5247 | ❌ Unprofitable |
| **Second Half (2024–2025)** | 29 | 20.69% | +0.3784 | **2.4413** | 18.5890 | 7.6145 |  Profitable |
| **Odd Years (2023, 2025)** | 35 | 11.43% | +0.0022 | **1.0060** | 13.1553 | 13.0770 |  Flat |
| **Even Years (2022, 2024)** | 34 | 23.53% | +0.3061 | **1.7967** | 23.4695 | 13.0622 |  Profitable |

---

## 4. Key Questions & Forensic Answers

### 4.1 Is profitability stable across years?
**No. Profitability is highly unstable.**
* **2022** was moderately profitable (+0.1331 ATR expectancy, 1.25 PF).
* **2023** was **unprofitable** (-0.1091 ATR expectancy, 0.74 PF), suffering a win rate of only 8.33% (2 wins out of 24 events).
* **2024** and **2025** were highly profitable (+0.4599 ATR and +0.2452 ATR expectancy, PF of 2.71 and 1.96 respectively).
This year-to-year variation (swinging from a net loss in 2023 to a massive profit in 2024) indicates a strong vulnerability to changing market environments.

### 4.2 Is the Profit Factor driven by one specific year?
**Yes, primarily by 2024.**
* In 2024, the model achieved a spectacular Profit Factor of **2.7181**, making up **35.7%** of the entire 4-year gross profit (13.0950 ATR out of 36.6248 ATR).
* The **First Half (2022–2023)** of the backtest was completely unprofitable (Expectancy of **-0.0122 ATR**, PF of **0.9736**). All of the net profits of the system were generated in the **Second Half (2024–2025)**, where the PF was **2.4413**.
* This indicates that the 4-year combined PF of 1.40 was heavily carried by the market regime of 2024–2025, while failing in the 2022–2023 regime.

### 4.3 Would the model still be considered robust by professional systematic trading standards?
**No, the model lacks structural robustness.**
By professional systematic trading standards, this model would be rejected for the following reasons:
1. **Regime Vulnerability**: The model went net negative over an entire 2-year block (2022–2023). A professional fund cannot deploy a strategy that bleeds or remains flat for two years.
2. **Extreme Performance Variance**: The swing in Profit Factor from **0.74 (2023) to 2.71 (2024)** is too large. It indicates the edge is highly regime-dependent rather than a stable structural property. 2023 was a trending year for Gold, where stop sweeps frequently failed and turned into continuation breakouts, whereas 2024 was highly mean-reverting, making sweeps highly profitable.
3. **Low Sample Size**: The number of signals per year is extremely low (averaging only 17 events per year). With only 11 events in 2025 and 18 in 2024, a few outliers can easily skew the performance metrics, as proven in the robustness audit.

---

## 5. Strategic Recommendations

1. **Do Not Deploy as a Standalone Reversal System**:
   The edge is too unstable and regime-dependent to be traded on its own. 
2. **Context-Gating is Required (Module 5 Transition)**:
   To make this strategy robust, the Entry Engine cannot simply enter on every Group D sweep. It must gate the entries using **market regime filters**:
   - **Trend Filter**: Avoid entering reversal trades when the H4 trend is strong (to prevent being run over in trending years like 2023).
   - **Volatility Filter**: Only trade rejections when H4 volatility/volume is high, supporting quick mean-reversion pullbacks.
3. **Dynamic Stop and Target Adaptation**:
   Instead of a static $2.0$ ATR target, the target should be scaled dynamically based on H4 trend strength or deactivated during breakout conditions.
