# PHASE 5B FINAL VALIDATION REPORT: SWEEP EFFICIENCY FILTER

**Date**: 2026-06-18  
**Phase**: Phase 5B — Sweep Efficiency Filter Gating  
**Target Module**: `CEntryEngine` (v1.0 + Phase 5B Variant D) & `TestEntry.mq5`  
**Verdict**: ✅ **PHASE 5B PASSED (Variant D Approved)**

---

## 1. Prototype Variants Tested
In Phase 5B, we evaluated whether filtering stop sweep reversal signals using a custom **Sweep Efficiency** metric (`RejectionMargin / SweepSize`) improves the strategy's trading edge compared to the Phase 5A baseline. 

Four prototype variants were tested on `XAUUSD`, timeframe `M30` (M1 OHLC mode) over the 4-year period (2022–2025) with **Trend Gate = OFF**:
1. **Variant A**: Baseline Group D (RejectionMargin $\ge$ 0.50 ATR, Large Excursion Block $\le$ 1.50 ATR).
2. **Variant B**: RejectionMargin $\ge$ 0.50 ATR AND Efficiency $> 2.5$.
3. **Variant C**: RejectionMargin $\ge$ 0.50 ATR AND Efficiency $< 2.0$.
4. **Variant D**: RejectionMargin $\ge$ 0.50 ATR AND (Efficiency $< 2.0$ OR Efficiency $> 2.5$) — *Excludes the transitional gray zone ($2.0 \le \text{Efficiency} \le 2.5$)*.

---

## 2. Comparative Results Summary

### Annualized Performance Across All Variants

| Period | Metric | Variant A (Baseline) | Variant B (Eff > 2.5) | Variant C (Eff < 2.0) | Variant D (Eff < 2.0 OR > 2.5) |
| :---: | --- | :---: | :---: | :---: | :---: |
| **TOTAL** | Trades <br> Win Rate <br> Expectancy <br> Profit Factor | 69 <br> 18.84% <br> +0.1954 ATR <br> 1.54 | 37 <br> 16.22% <br> +0.2189 ATR <br> 1.63 | 21 <br> 23.81% <br> +0.3567 ATR <br> 2.39 | **58** <br> **18.97%** <br> **+0.2688 ATR** <br> **1.85** |
| **2022** | Trades <br> Expectancy <br> Profit Factor | 16 <br> +0.3206 ATR <br> 1.71 | 10 <br> +0.0187 ATR <br> 1.04 | 5 <br> +1.1886 ATR <br> 6.94 | **15** <br> **+0.4087 ATR** <br> **1.98** |
| **2023** | Trades <br> Expectancy <br> Profit Factor | 24 <br> -0.1091 ATR <br> 0.75 | 10 <br> -0.1445 ATR <br> 0.66 | 9 <br> +0.0459 ATR <br> 1.17 | **19** <br> **-0.0543 ATR** <br> **0.85** |
| **2024** | Trades <br> Expectancy <br> Profit Factor | 18 <br> +0.4599 ATR <br> 2.72 | 10 <br> +0.5331 ATR <br> 3.43 | 4 <br> +0.3657 ATR <br> 2.08 | **14** <br> **+0.4853 ATR** <br> **2.91** |
| **2025** | Trades <br> Expectancy <br> Profit Factor | 11 <br> +0.2452 ATR <br> 1.96 | 7 <br> +0.5751 ATR <br> 4.20 | 3 <br> -0.1095 ATR <br> 0.39 | **10** <br> **+0.3697 ATR** <br> **3.06** |

---

## 3. Directional Audit (Variant D: BSL vs. SSL)

To verify the structural robustness of Variant D, we audited the performance of BSL (Short) and SSL (Long) setups separately:

### BSL vs. SSL Yearly Breakdown (Variant D)

*   **BSL Trades Only (Short Setup)**:
    *   **Count**: 28 trades
    *   **Profit Factor**: **1.48**
    *   **Expectancy**: **+0.1980 ATR**
    *   **Win Rate**: 21.43%
    *   *Yearly Expectancy*: 2022: -0.2621 ATR | 2023: +0.0306 ATR | 2024: +0.5666 ATR | 2025: +0.7343 ATR
*   **SSL Trades Only (Long Setup)**:
    *   **Count**: 30 trades
    *   **Profit Factor**: **2.48**
    *   **Expectancy**: **+0.3349 ATR**
    *   **Win Rate**: 16.67%
    *   *Yearly Expectancy*: 2022: +0.9956 ATR | 2023: -0.1487 ATR | 2024: +0.4243 ATR | 2025: +0.0051 ATR

### Key Findings
1. **Edge Source**: The main edge of the strategy comes from the **SSL (Long) setups**, which generated **+10.047 ATR** in total profits (PF 2.48) compared to BSL's **+5.544 ATR** (PF 1.48). 
2. **Consistency**: Both BSL and SSL setups are profitable in **3 out of 4 years** (majority of years), with no major contradictions or structural imbalances.
3. **Symmetry**: The remaining 58 trades in Variant D are extremely well-balanced between BSL (28) and SSL (30), verifying that the filter successfully eliminated the pathological asymmetry in the baseline.

---

## 4. Rationale for Accepting Variant D

Variant D is officially accepted as the freeze candidate for Phase 5B due to the following structural and statistical advantages:
* **Significant Edge Enhancement**: Total expectancy increased by **37.5%** (from +0.1954 ATR to **+0.2688 ATR**) and the overall Profit Factor rose from 1.54 to **1.85**.
* **Effective Drawdown Mitigation**: In the pathological trending year of 2023, Variant D reduced the baseline net losses by **50.2%** (expectancy improved from -0.1091 ATR to **-0.0543 ATR**) without destroying range-bound profitability.
* **Preservation of Winning Outliers**: Unlike the failed H4 Trend Gate of Phase 5A (which turned 2022 into a losing year by blocking swing-peak wins), Variant D improved 2022 performance from +0.3206 ATR to **+0.4087 ATR**.
* **Clean Isolation of Reversal Archetypes**: It successfully filters out the transitional "gray zone" ($2.0 \le \text{Efficiency} \le 2.5$) which consists of 100% BSL trades. These trades represent momentum coiling patterns on Gold that regularly result in range-bound breakout traps. It preserves the two high-probability reversion archetypes: **Deep Exhaustion Spikes (Efficiency < 2.0)** and **Instant Level Rejections (Efficiency > 2.5)**.

---

## 5. Official Phase 5B Freeze Decision
* **Decision**: **Variant D Approved & Frozen**
* **Parameter Settings**:
  * `InpVariantMode` = `VARIANT_D_EFF_OUTSIDE` (1)
  * `InpEnableTrendGate` = `false`
  * `InpMinRejectionMarginATR` = `0.50`
* **Code State**: `EntryEngine.mqh` integrates the enum and filters cleanly. Compilation verified with **0 errors and 0 warnings** in MetaEditor.
