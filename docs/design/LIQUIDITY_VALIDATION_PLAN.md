# Liquidity Engine Statistical Validation Plan
**Version**: 1.0  
**Phase**: Phase 4.3 — Statistical Validation Planning  
**Status**: Proposal  

---

## 1. Objectives

The objective of Phase 4.3 is to validate whether the outputs of the `CLiquidityEngine` have statistical validity on historical XAUUSD data. Before designing trading models, we must prove that liquidity sweeps represent high-probability market inefficiencies rather than noise. 

This validation will:
1. Run a headless backtest of the engine pipeline over a 4-year historical window.
2. Collect raw event records for every breach.
3. Export data to `LiquidityValidation.csv`.
4. Compile statistical metrics to evaluate rejection rates, excursion depths, and breakout frequencies.

---

## 2. Test Environment & Validation Period

* **Symbol**: `XAUUSDm` (Gold)
* **Execution Timeframes**:
  * Upstream Structure / S/D / SNR / ATR: `H4`
  * Liquidity Scanning & Sweep Evaluation: `M30`
* **Validation Period**: `2022.01.01` to `2025.12.31` (4 Years / ~7,450 H4 bars and ~59,600 M30 bars).
* **Testing Mode**: `Every Tick` inside the MT5 Strategy Tester (ensures precise price data parsing).
* **Parameters Locked**:
  * `InpLiqSweepMaxSizeATR` = `1.50` (Breakout threshold)
  * `m_maxH4Bars` = `300`
  * `m_maxM30Bars` = `300`

---

## 3. Statistical Metrics to Compile

Using the exported CSV data, the validation will compile the following metrics:
* **Total Pools Created**: Unique BSL and SSL pools generated.
* **Breach Count**: Number of times price penetrated the outer boundary of active pools.
* **Rejection Count**: Number of breaches where the M30 bar closed back inside the inner boundary.
* **Rejection Rate**: Percentage of breaches that resulted in confirmed rejections ($\frac{\text{Rejection Count}}{\text{Breach Count}} \times 100\%$).
* **Average Excursion Depth**: Average volatility-adjusted distance ($bslSweepSizeATR$ / $sslSweepSizeATR$) reached by the breach.
* **Excursion Distribution**: Count and percentage of breaches falling within specific ATR bands:
  * $0.00$ to $0.25$ ATR
  * $0.25$ to $0.50$ ATR
  * $0.50$ to $1.00$ ATR
  * $1.00$ to $1.50$ ATR
  * $> 1.50$ ATR (Large Excursion / Breakout Run)
* **Large Excursion Frequency**: Percentage of breaches that exceeded the 1.50 ATR threshold ($\frac{\text{Large Excursions}}{\text{Breach Count}} \times 100\%$).

---

## 4. CSV Schema (`LiquidityValidation.csv`)

Every time `CLiquidityEngine` detects that `isBSLBreached` or `isSSLBreached` is `true` on the closed M30 bar 1, a new line will be written to `LiquidityValidation.csv`.

The CSV file will be exported in the MT5 Terminal's common files folder (`MQL5\Files\`) using the following schema:

| Column Header | Data Type | Description | Example |
|:---|:---:|:---|:---|
| `datetime` | `datetime` | Open time of the M30 bar that completed the breach | `2024.11.15 14:30:00` |
| `poolType` | `string` | Type of liquidity pool breached (`BSL` or `SSL`) | `BSL` |
| `isBreached` | `integer` | Boolean breach flag (`1` = true, `0` = false) | `1` |
| `isRejected` | `integer` | Boolean rejection confirmation (`1` = price closed inside, `0` = closed outside) | `1` |
| `sweepSizeATR` | `double` | Volatility-adjusted excursion depth in H4 ATR units | `0.4287` |
| `isLargeExcursion` | `integer` | Boolean flag indicating excursion $> 1.50$ ATR (`1` = true, `0` = false) | `0` |
| `poolStrength` | `double` | Strength score of the origin swing point (from `CSnrEngine`) | `85.50` |
| `nearestPoolDistance` | `double` | Distance in points from the bar's open price to the inner boundary | `145.20` |

---

## 5. Validation EA Design (`TestLiquidityValidation.mq5`)

The validator EA is designed strictly for event logging and statistics collection. It contains **no trading logic**, **no order placement**, and **no parameters optimization**.

### 5.1 Architecture Block Diagram
```
              OnTick() / New M30 Bar Update
                            │
              Update Upstream Engine Pipeline
              (Structure -> S/D -> SNR -> SNR Priority)
                            │
               Run CLiquidityEngine::Analyze()
                            │
          Is isBSLBreached or isSSLBreached true?
             ├─── YES ──→ Format CSV Row & Write to File
             └─── NO  ──→ Skip Logging
```

### 5.2 Key Code Components
* **Initialization (`OnInit`)**:
  * Sequentially instantiates the five engines.
  * Creates or overwrites the `LiquidityValidation.csv` file, writing the header line:
    `datetime,poolType,isBreached,isRejected,sweepSizeATR,isLargeExcursion,poolStrength,nearestPoolDistance`
* **OnTick Processing**:
  * Uses the new-bar gating protocol to check for new M30 bar completions.
  * Runs the upstream engines.
  * Computes bid/ask pricing and H4 ATR.
  * Runs `gLiquidityEngine.Analyze()`.
  * Checks the resulting `LiquidityPriorityContract`:
    ```mq5
    LiquidityPriorityContract contract = gLiquidityEngine.GetContract();
    if(contract.isBSLBreached)
    {
       LogEvent("BSL", contract.isBSLBreached, contract.isBSLRejected, contract.bslSweepSizeATR, contract.isLargeExcursion, contract.nearestBSL.liquidityStrength, MathAbs(OpenPrice - contract.nearestBSL.priceLow));
    }
    if(contract.isSSLBreached)
    {
       LogEvent("SSL", contract.isSSLBreached, contract.isSSLRejected, contract.sslSweepSizeATR, contract.isLargeExcursion, contract.nearestSSL.liquidityStrength, MathAbs(OpenPrice - contract.nearestSSL.priceHigh));
    }
    ```
* **Deinitialization (`OnDeinit`)**:
  * Closes the CSV file handle.
  * Prints overall execution statistics (Total Breaches, Total Rejections, Rejection Rate %) to the terminal journal.
