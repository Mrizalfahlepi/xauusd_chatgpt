# PHASE 4 LIQUIDITY ENGINE — RESEARCH INDEX

This index summarizes the purpose, key findings, and final conclusions of the five forensic research audit reports generated during Phase 4 validation. These reports document the statistical properties, trading edge, robustness, and trade management profiles of liquidity sweeps on Gold (`XAUUSDm` M30) over the 4-year validation dataset (2022–2025).

---

## 1. LIQUIDITY_REJECTION_SENSITIVITY_AUDIT.md
*   **Path**: `docs/reports/LIQUIDITY_REJECTION_SENSITIVITY_AUDIT.md` (Untracked)
*   **Purpose**: Evaluate the sensitivity of the Liquidity Engine's empirical rejection rate to changes in the rejection definition (requiring the closed M30 bar to clear the inner boundary by a set H4 ATR tolerance).
*   **Key Findings**:
    - The raw engine configuration (0.00 ATR buffer) yields a **100% rejection rate** for the first 50 events.
    - Requiring a **0.10 ATR buffer** reduces the rejection rate to **74.00%** (13/50 events reclassified as breakouts).
    - Requiring a **0.20 ATR buffer** reduces the rejection rate to **52.00%**.
    - Requiring a **0.50 ATR buffer** drops the rejection rate to **10.00%**.
*   **Final Conclusion**: The baseline 99.62% rejection rate is a mathematical artifact of the extremely narrow pool tolerance (0.10 ATR / ~$1.15 in Gold). Downstream filters must enforce a rejection margin buffer to separate minor overlaps from high-velocity reversal sweeps.

---

## 2. LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md
*   **Path**: `docs/reports/LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md` (Untracked)
*   **Purpose**: Evaluate the expectancy (average net close excursion) and Edge Ratio (E-ratio) of liquidity sweeps across 12, 24, and 48 bar horizons for different rejection strength thresholds.
*   **Key Findings**:
    - **Groups A, B, and C** (rejection margin $\ge 0.10$, $\ge 0.20$, and $\ge 0.30$ ATR) return **negative net close expectancy** across all three horizons.
    - **Group D** (rejection margin $\ge 0.50$ ATR, 69 events) achieves a **positive net expectancy (+0.0164 ATR)** and a strong E-ratio of **1.1656** at the 12-bar horizon.
    - Edge decays rapidly after 12 bars: Group D expectancy turns to **$-0.1857$ ATR** at 24 bars and **$-0.4192$ ATR** at 48 bars.
*   **Final Conclusion**: A positive structural edge is only present on strong sweeps ($\ge 0.50$ ATR) and decays quickly. Reversal trades must be executed as short-term scalps (exited within 12 bars / 6 hours).

---

## 3. GROUP_D_ROBUSTNESS_AUDIT.md
*   **Path**: `docs/reports/GROUP_D_ROBUSTNESS_AUDIT.md` (Untracked)
*   **Purpose**: Verify if the positive expectancy of Group D sweeps is a stable, system-wide property or an illusion dominated by a small number of extreme outlier winners.
*   **Key Findings**:
    - Win rate at 12 bars is a coin flip: **50.72% wins** (35 events) vs. **49.28% losses** (34 events).
    - Removing the top **10%** of best events (7 trades) drops expectancy to **$-0.2548$ ATR**.
    - Removing the top **20%** of best events (14 trades) drops expectancy to **$-0.4445$ ATR**.
    - Performance is heavily dominated by a single trade on 2022.06.10 returning **$+5.1302$ ATR**.
    - Median MFE12 is **0.9055 ATR**; Median MAE12 is **0.6270 ATR**.
*   **Final Conclusion**: The raw close expectancy is an outlier-driven illusion. However, the fact that median MFE significantly exceeds median MAE indicates a favorable intraday volatility bias, suggesting a tradable edge can be unlocked via active trade management.

---

## 4. GROUP_D_RISK_REWARD_AUDIT.md
*   **Path**: `docs/reports/GROUP_D_RISK_REWARD_AUDIT.md` (Untracked)
*   **Purpose**: Determine whether pairing Group D sweeps with fixed Take Profit (TP) and Stop Loss (SL) models can protect the account and generate a robust, positive expectancy.
*   **Key Findings**:
    - Tight stops (`SL = 0.50 ATR`) are unprofitable (expectancy of $-0.18$ to $-0.06$ ATR) because they are below the median MAE of $0.627$ ATR, causing premature stop outs.
    - Stops set at `SL = 1.00 ATR` protect the account from trending breakout runs while giving the trade breathing room.
    - Asymmetric targets (`TP = 2.00 ATR`) capture the extreme V-reversal moves.
    - **Model 5** (`TP = 2.00 ATR`, `SL = 1.00 ATR`, 12-bar exit) achieves the highest expectancy of **$+0.1520$ ATR** and a Profit Factor of **1.4011**.
*   **Final Conclusion**: Liquidity rejections possess a tradable edge when paired with asymmetric trade management that caps downside risk while allowing outlier wins to run.

---

## 5. GROUP_D_TEMPORAL_STABILITY_AUDIT.md
*   **Path**: `docs/reports/GROUP_D_TEMPORAL_STABILITY_AUDIT.md` (Untracked)
*   **Purpose**: Analyze the stability of the optimal trade management model (`TP = 2.0 ATR`, `SL = 1.0 ATR`, 12-bar exit) across years and rolling periods.
*   **Key Findings**:
    - Expectancy is highly unstable: **2023 was unprofitable (PF 0.74)**, while **2024 was highly profitable (PF 2.71)**.
    - The **First Half (2022–2023)** of the backtest block was net **unprofitable (PF 0.97)**.
    - All positive edge was generated in the **Second Half (2024–2025)** (PF 2.44).
    - Even years were highly profitable (PF 1.79), whereas odd years were flat (PF 1.00).
*   **Final Conclusion**: The strategy is highly vulnerable to market regime shifts (losing in trending years like 2023, winning in range-bound/mean-reverting years like 2024). Downstream trend-gating filters are required inside the Entry Engine to ensure long-term stability.
