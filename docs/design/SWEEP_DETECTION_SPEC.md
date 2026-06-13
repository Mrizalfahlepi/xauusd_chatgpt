# Liquidity Sweep Detection Specification
**Version**: 1.0  
**Phase**: Phase 4.2 Step 4 — Sweep Detection Specification  
**Status**: Proposal  

---

## 1. Architectural Context

The `CLiquidityEngine` (Module 5) sits downstream of the `CSnrPriorityEngine` (Module 4) and upstream of the Entry Engine (Module 6). Its primary responsibility is to provide real-time sweep intelligence on closed M30 bars without making trading decisions. 

```
+------------------------+      +--------------------+      +-------------------------+
|   CSnrPriorityEngine   | ---> |  CLiquidityEngine  | ---> |       Entry Engine      |
|  (Nearest BSL / SSL)   |      |  (Sweep Detection) |      | (Trading Decision/Block)|
+------------------------+      +--------------------+      +-------------------------+
```

---

## 2. Open Questions & Recommendations

### Question 1: Which boundary defines a sweep?
**Recommendation**: **B. Outer boundary**
* **Evidence**: In the frozen `SnrEngine.mqh` (lines 1105–1106 and 1139–1140), liquidity pools are defined with a volatility-adjusted buffer `poolTol = m_liquidityTolATR * atr` where:
  * **BSL Boundaries**: `priceLow = swing.price` (inner boundary), `priceHigh = swing.price + poolTol` (outer boundary).
  * **SSL Boundaries**: `priceHigh = swing.price` (inner boundary), `priceLow = swing.price - poolTol` (outer boundary).
  The upstream sweep check in `SnrEngine.mqh` (lines 1116 and 1150) explicitly checks if the price breaks the outer boundary (`high > priceHigh` for BSL, `low < priceLow` for SSL).
* **Justification**: 
  1. **Order Flow Reality**: Stop orders are clustered slightly beyond the exact swing levels, not exactly on them. The outer boundary represents the full execution of the stop cluster.
  2. **Architectural Consistency**: Downstream engines must align with upstream classifications. If the upstream engine requires an outer boundary breach to mark a pool as `isSwept = true`, the downstream engine must do the same to prevent logic conflicts.

### Question 2: Is a 1-point penetration enough to qualify as a sweep?
**Recommendation**: 
* Relative to the **inner boundary** (swing price): **No**. The price must penetrate the inner boundary by at least the volatility-adjusted buffer distance (`poolTol = 0.10 * ATR`) to reach the outer boundary.
* Relative to the **outer boundary**: **Yes**. A 1-point (or >= 1 point) penetration beyond the outer boundary is sufficient.
* **Justification**: The outer boundary already includes a `0.10 * ATR` filter to absorb market noise and spreads. Once the outer boundary is breached, the stop-loss cluster is engaged. Applying another threshold beyond the outer boundary would be redundant.

### Question 3: Should sweep detection produce binary events or observation metrics?
**Recommendation**: **Observation Metrics**
* **Justification**: Downstream modules (e.g., Entry Engine) require quantitative context to differentiate between a **rejection sweep** (ideal for mean-reversion) and a **breakout run** (risk of trend continuation). Simply sending a binary `true/false` flag hides critical parameters.
* **Contract Output**: The engine must supply:
  * `isBSLSweptThisBar` / `isSSLSweptThisBar` (binary indicators)
  * `bslSweepSizeATR` / `sslSweepSizeATR` (continuous excursion depth in ATR units)
  * `isLargeExcursion` (breakout filter threshold check)

---

## 3. Mathematical Definitions

Let $P_{BSL}$ and $P_{SSL}$ be the active nearest liquidity pools retrieved from the `SnrPriorityContract`. Let $H$ be the High price, $L$ be the Low price, and $C$ be the Close price of the evaluated closed M30 bar. Let $ATR_{H4}$ be the 14-period H4 ATR.

### 3.1 BSL Sweep Detection (Buy Stops Swept)
A BSL sweep occurs when the high of the closed M30 bar exceeds the outer boundary of the BSL pool:
$$\text{Sweep Detected (BSL)} \iff H_{M30} > P_{BSL}.priceHigh$$

* **Raw Excursion Depth** ($D_{BSL}$): The distance from the swing high (inner boundary) to the bar high:
  $$D_{BSL} = H_{M30} - P_{BSL}.priceLow$$
* **Volatility-Adjusted Excursion** ($\text{Excursion}_{ATR}$):
  $$\text{Excursion}_{ATR} = \frac{D_{BSL}}{ATR_{H4}}$$

### 3.2 SSL Sweep Detection (Sell Stops Swept)
An SSL sweep occurs when the low of the closed M30 bar falls below the outer boundary of the SSL pool:
$$\text{Sweep Detected (SSL)} \iff L_{M30} < P_{SSL}.priceLow$$

* **Raw Excursion Depth** ($D_{SSL}$): The distance from the swing low (inner boundary) to the bar low:
  $$D_{SSL} = P_{SSL}.priceHigh - L_{M30}$$
* **Volatility-Adjusted Excursion** ($\text{Excursion}_{ATR}$):
  $$\text{Excursion}_{ATR} = \frac{D_{SSL}}{ATR_{H4}}$$

### 3.3 Large Excursion (Breakout Risk)
If the volatility-adjusted excursion exceeds the maximum allowed sweep size parameter ($InpLiqSweepMaxSizeATR = 1.50$), it is classified as a breakout run rather than a mean-reverting sweep:
$$\text{isLargeExcursion} \iff \text{Excursion}_{ATR} > InpLiqSweepMaxSizeATR$$

### 3.4 Rejection Confirmation
A sweep is confirmed as "rejected" if the bar closes back inside the inner boundary:
* **BSL Rejection**: $C_{M30} < P_{BSL}.priceLow$
* **SSL Rejection**: $C_{M30} > P_{SSL}.priceHigh$

---

## 4. Examples and Edge Cases

### 4.1 Examples
Assume:
* $ATR_{H4} = 10.0$ USD
* $InpLiqSweepMaxSizeATR = 1.50$
* $P_{BSL}$ boundaries: $priceLow = 2000.0$ (swing price), $priceHigh = 2001.0$ ($poolTol = 0.10 \times 10.0 = 1.0$)

* **Case 1: Standard Rejection Sweep**
  * M30 Bar: $High = 2002.5$, $Close = 1999.0$
  * *Result*: $2002.5 > 2001.0 \implies \text{BSL Swept = true}$.
  * *Excursion*: $2002.5 - 2000.0 = 2.5$ points ($0.25 \times ATR$).
  * *Breakout Filter*: $0.25 \le 1.50 \implies \text{isLargeExcursion = false}$.
  * *Rejection*: $1999.0 < 2000.0 \implies \text{Confirmed Rejection = true}$.

* **Case 2: Violent Breakout**
  * M30 Bar: $High = 2018.0$, $Close = 2016.5$
  * *Result*: $2018.0 > 2001.0 \implies \text{BSL Swept = true}$.
  * *Excursion*: $2018.0 - 2000.0 = 18.0$ points ($1.80 \times ATR$).
  * *Breakout Filter*: $1.80 > 1.50 \implies \text{isLargeExcursion = true}$ (High breakout risk).
  * *Rejection*: $2016.5 > 2000.0 \implies \text{Confirmed Rejection = false}$.

### 4.2 Edge Cases
* **Double Sweep**: A single M30 bar with extreme range sweeps both $P_{BSL}$ and $P_{SSL}$.
  * *Handling*: The engine evaluates both boundaries independently. Both `isBSLSweptThisBar` and `isSSLSweptThisBar` will be set to `true` with their respective excursion depths.
* **Already Swept Upstream**: The $P_{BSL}$ or $P_{SSL}$ has its `isSwept` flag set to `true` by `CSnrPriorityEngine`.
  * *Handling*: The engine will not detect new sweeps on already swept pools to prevent double-counting.

### 4.3 Invalid Cases (No Sweep)
* **Shadow Penetration**: M30 Bar $High = 2000.5$ (penetrates swing price, but fails to reach outer boundary $2001.0$).
  * *Result*: $2000.5 \le 2001.0 \implies \text{BSL Swept = false}$.
  * *Reasoning*: Price tested the level but did not trigger stop orders.

---

## 5. Recommended V1 Implementation Plan

1. **Active Pool Extraction**:
   Read `nearestBSL` and `nearestSSL` boundaries from `SnrPriorityContract`.
2. **Evaluate Closed Bar 1**:
   Query the closed M30 bar (index 1 in the rates cache).
3. **Compare High/Low Boundaries**:
   * If `hasBSL == true` and `nearestBSL.isSwept == false`:
     * If `m_m30Rates[1].high > nearestBSL.priceHigh`:
       * Set `isBSLSweptThisBar = true`
       * Calculate `bslSweepSizeATR = (m_m30Rates[1].high - nearestBSL.priceLow) / m_h4ATR`
       * Set `isLargeExcursion = (bslSweepSizeATR > m_sweepMaxSizeATR)`
   * If `hasSSL == true` and `nearestSSL.isSwept == false`:
     * If `m_m30Rates[1].low < nearestSSL.priceLow`:
       * Set `isSSLSweptThisBar = true`
       * Calculate `sslSweepSizeATR = (nearestSSL.priceHigh - m_m30Rates[1].low) / m_h4ATR`
       * Set `isLargeExcursion = (sslSweepSizeATR > m_sweepMaxSizeATR)`
