# Liquidity Engine Outcome Validation Design
**Version**: 1.0  
**Phase**: Phase 4.3 — Outcome Validation Planning  
**Status**: Proposal  

---

## 1. Objectives & Philosophy

To determine if `CLiquidityEngine` outputs have predictive trading value, we must measure what happens *after* a liquidity breach occurs. Measuring breach frequencies alone (event statistics) is insufficient; we must measure the post-event price trajectory (outcome statistics) to mathematically prove the existence of an execution edge.

Following the proven methodology of the Phase 3 SNR outcome validation, this design adds forward-looking metrics:
1. **Maximum Favorable Excursion (MFE)**: The maximum price run in the predicted reversal direction.
2. **Maximum Adverse Excursion (MAE)**: The maximum price run against the predicted reversal direction.
3. **E-Ratio (Edge Ratio)**: The ratio of MFE to MAE to prove positive expectancy.

---

## 2. Outcome Window Horizons

Instead of a single fixed window, we evaluate forward outcome metrics across three distinct horizons after the breach event to determine the optimal holding period empirically:
* **Short Horizon**: **12 M30 bars** (exactly **6 hours** of trading).
* **Medium Horizon**: **24 M30 bars** (exactly **12 hours** of trading).
* **Long Horizon**: **48 M30 bars** (exactly **24 hours** of trading).

---

## 3. MFE / MAE / Close Calculation Rules

All forward outcomes are calculated relative to the **Entry Reference Price ($P_{\text{Entry}}$)**, defined as the **Close of the Breach Bar (M30 Bar 1)**.

For each horizon $N \in \{12, 24, 48\}$:

### 3.1 BSL Breach Outcomes (Short Reversal Expectancy)
* **Favorable Direction**: Price moves *down* (below $P_{\text{Entry}}$).
* **Adverse Direction**: Price moves *up* (above $P_{\text{Entry}}$).

$$\text{MFE}_{\text{Raw}, N} = P_{\text{Entry}} - \min_{t=1}^{N} (Low_t)$$
$$\text{MAE}_{\text{Raw}, N} = \max_{t=1}^{N} (High_t) - P_{\text{Entry}}$$
$$\text{Close}_{\text{Raw}, N} = P_{\text{Entry}} - Close_N$$

### 3.2 SSL Breach Outcomes (Long Reversal Expectancy)
* **Favorable Direction**: Price moves *up* (above $P_{\text{Entry}}$).
* **Adverse Direction**: Price moves *down* (below $P_{\text{Entry}}$).

$$\text{MFE}_{\text{Raw}, N} = \max_{t=1}^{N} (High_t) - P_{\text{Entry}}$$
$$\text{MAE}_{\text{Raw}, N} = P_{\text{Entry}} - \min_{t=1}^{N} (Low_t)$$
$$\text{Close}_{\text{Raw}, N} = Close_N - P_{\text{Entry}}$$

---

## 4. ATR Normalization Method

All raw point distances for each horizon $N$ are normalized by the H4 ATR ($ATR_{H4}$) at the moment of the breach:

$$\text{MFE}_{\text{ATR}, N} = \frac{\text{MFE}_{\text{Raw}, N}}{ATR_{H4}}$$
$$\text{MAE}_{\text{ATR}, N} = \frac{\text{MAE}_{\text{Raw}, N}}{ATR_{H4}}$$
$$\text{Close}_{\text{ATR}, N} = \frac{\text{Close}_{\text{Raw}, N}}{ATR_{H4}}$$

---

## 5. CSV Schema Extensions (`LiquidityValidation.csv`)

To log these research variables, the validation EA will track each breach over 48 bars before writing the finalized record. All classification steps are removed.

We propose the following CSV schema:

```
datetime,poolType,isBreached,isRejected,sweepSizeATR,isLargeExcursion,poolStrength,nearestPoolDistance,mfe12_ATR,mae12_ATR,close12_ATR,mfe24_ATR,mae24_ATR,close24_ATR,mfe48_ATR,mae48_ATR,close48_ATR
```

---

## 6. Statistical Metrics to Evaluate Reversal Edge

Once the backtest completes, we will analyze the raw variables to evaluate the trading edge:

### 6.1 Edge Ratio (E-Ratio) by Horizon
For each horizon $N \in \{12, 24, 48\}$:
$$E_N = \frac{\sum \text{MFE}_{\text{ATR}, N}}{\sum \text{MAE}_{\text{ATR}, N}}$$
* **Optimum Horizon**: The horizon $N$ that maximizes $E_N$ represents the optimal trade execution length.

### 6.2 Net Move Expectancy
The average of `close12_ATR`, `close24_ATR`, and `close48_ATR` will be calculated to identify the average net profit/loss at the end of each window.

### 6.3 Rejection vs. Non-Rejection Edge
Compare E-ratios for breaches with `isRejected == true` vs `isRejected == false` across all three horizons.

### 6.4 Excursion Size Threshold Optimality
Evaluate E-ratios for sweeps with `isLargeExcursion == true` vs `isLargeExcursion == false` to verify if 1.50 ATR is the optimal threshold for blocking reversal trades.
