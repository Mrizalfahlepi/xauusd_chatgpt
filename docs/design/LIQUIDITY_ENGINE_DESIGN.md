# Liquidity Engine v1.0 — Architectural Design Freeze Candidate

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: DESIGN FREEZE CANDIDATE (Awaiting Owner Review)  
**Target Module**: `LiquidityEngine.mqh` (Module 4 v1.0)  
**Dependencies**: [StructureEngine.mqh (v2.2)](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh), [SupplyDemandEngine.mqh (v1.1)](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh), [SnrEngine.mqh (v1.0)](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh), [SnrPriorityEngine.mqh (v1.0)](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh)

---

## 1. Introduction & Core Concept

The Liquidity Engine is the fourth component in the unidirectional trading pipeline. It is responsible for identifying stop-loss clusters (liquidity pools) residing above major swing highs and below major swing lows, and detecting stop-run (sweep) events.

Retail trading strategies default to placing stop-losses just beyond recent swing high and low pivot points. Institutional market makers exploit these clusters by driving price into them to execute large-volume orders (exit liquidity). By mapping these pools and detecting when they are swept, the EA can trigger high-probability entry signals *with* institutional order flow rather than against it.

---

## 2. Liquidity Definitions & Pool Calculations

### 2.1 Liquidity Pool Boundaries
A **Liquidity Pool** is defined as a price zone situated immediately adjacent to a confirmed Major Swing Point (derived from `CStructureEngine` v2.2):

*   **Buy Stop Liquidity (BSL) Pool**: Resides above a confirmed Major Swing High.
    *   *Lower Bound*: $SwingHigh_{\text{Price}}$
    *   *Upper Bound*: $SwingHigh_{\text{Price}} + (InpSnrLiquidityTolATR \times ATR)$
*   **Sell Stop Liquidity (SSL) Pool**: Resides below a confirmed Major Swing Low.
    *   *Upper Bound*: $SwingLow_{\text{Price}}$
    *   *Lower Bound*: $SwingLow_{\text{Price}} - (InpSnrLiquidityTolATR \times ATR)$

*Note: The default pool width is scaled using a local H4 ATR(14) calculation ($InpSnrLiquidityTolATR = 0.10$ H4 ATR).*

### 2.2 Liquidity Strength
Not all liquidity pools carry equal weight. The engine assigns a **Liquidity Strength** score (0–100) based on:
1.  **Swing Point Type**: Swings classified as Major by Module 1 carry a baseline strength of 100. Minor swings (if configured for inclusion) carry a baseline strength of 50.
2.  **Touch Reactions**: Each time price approaches but does not breach the swing price (reaction counts cached by Module 1), more stops are assumed to accumulate.
$$\text{Strength}_{\text{Base}} = \min(100.0, \text{Baseline} + (\text{ReactionCount} \times 20))$$
3.  **Freshness & Age Decay**: Old pools gradually lose relevance as traders adjust their positions or orders expire. Strength decays linearly:
$$\text{Strength}_{\text{Final}} = \text{Strength}_{\text{Base}} \times \max\left(0.10, 1.0 - \frac{CurrentBar - SwingBar}{InpLiquidityDecayBars}\right)$$
    *   *Default Parameter*: `InpLiquidityDecayBars = 300` H4 bars (~50 trading days).

---

## 3. Liquidity Types

The engine maps two distinct types of stop-loss liquidity:

```
                            [Buy Stop Liquidity (BSL) Pool]
                            -------------------------------  <-- Upper Boundary (Price + 0.10 ATR)
                            ===============================  <-- Swing High Price Pivot (Resist)
                                      /\
                                     /  \
                                    /    \
  ---------------------------------/------\------------------------------------------- Price Action
                                  /        \
                                 /          \
                                /            \
                            ===============================  <-- Swing Low Price Pivot (Support)
                            -------------------------------  <-- Lower Boundary (Price - 0.10 ATR)
                            [Sell Stop Liquidity (SSL) Pool]
```

### 3.1 Buy Stop Liquidity (BSL)
*   **Source**: Accumulates above Swing High pivots. Represents buy-stops of retail short sellers (stop-losses) and breakout buy orders.
*   **Impact**: When swept, triggers a rapid series of market buy orders which are matched by institutional sell limits.

### 3.2 Sell Stop Liquidity (SSL)
*   **Source**: Accumulates below Swing Low pivots. Represents sell-stops of retail buyers (stop-losses) and breakout sell orders.
*   **Impact**: When swept, triggers a rapid series of market sell orders which are matched by institutional buy limits.

---

## 4. Sweep (Stop Run) Definitions

A **Liquidity Sweep (Stop Run)** is defined as a price excursion that breaches a liquidity boundary, triggers the stop-loss orders contained within the pool, but fails to maintain the breakout, closing back inside the range.

### 4.1 Mathematical Conditions for Sweeps
Sweeps are evaluated strictly on completed candles (`barIdx >= 1`) to eliminate repainting.

#### Buy Stop Liquidity (BSL) Sweep:
1.  **Breach**: The high of the sweeping bar exceeds the swing high pivot price:
$$High[\text{barIdx}] > SwingHigh_{\text{Price}}$$
2.  **Rejection**: The close of the sweeping bar returns below the swing high pivot price:
$$Close[\text{barIdx}] < SwingHigh_{\text{Price}}$$
3.  **Invalidation**: The pool is marked as `isSwept = true`, and the `sweptTime` is set to the bar's open time.

#### Sell Stop Liquidity (SSL) Sweep:
1.  **Breach**: The low of the sweeping bar drops below the swing low pivot price:
$$Low[\text{barIdx}] < SwingLow_{\text{Price}}$$
2.  **Rejection**: The close of the sweeping bar returns above the swing low pivot price:
$$Close[\text{barIdx}] > SwingLow_{\text{Price}}$$
3.  **Invalidation**: The pool is marked as `isSwept = true`, and the `sweptTime` is set to the bar's open time.

### 4.2 Sweep Size Classification
Sweeps are classified by depth of excursion (breach distance relative to local ATR):
*   **Minor Sweep**: Excursion $\le 0.25 \times ATR$. Typical of tight stop runs.
*   **Medium Sweep**: $0.25 \times ATR <$ Excursion $\le 0.75 \times ATR$. Standard institutional grab.
*   **Major Sweep**: Excursion $> 0.75 \times ATR$. Significant volatility spike; represents deep stop runs or failed trend breakouts.

### 4.3 Timeframe Resolution
*   **Primary Scanner**: Runs on the **H4 timeframe** to map major structural sweeps.
*   **Intraday Scanner**: Evaluated on the **M30 timeframe** to capture micro-structure sweeps within H4 pools, feeding immediate entry execution criteria.

---

## 5. Inputs & Configuration Parameters

To ensure no global scope conflicts, parameters are prefixed with `InpLiq*`:

```cpp
//--- Liquidity Pool Mapping Parameters
input double InpLiqPoolWidthATR     = 0.10;    // Liquidity: Pool width (H4 ATR multiplier)
input int    InpLiqDecayBars        = 300;     // Liquidity: Pool strength decay lookback (H4 bars)
input bool   InpLiqIncludeMinor     = false;   // Liquidity: Include Minor Swings as pools

//--- Sweep Detection Parameters
input double InpLiqSweepMinSizeATR  = 0.05;    // Liquidity: Minimum sweep excursion depth
input double InpLiqSweepMaxSizeATR  = 1.50;    // Liquidity: Maximum sweep excursion depth (filters trend breaks)
input bool   InpLiqEnableLog        = true;    // Liquidity: Enable print diagnostics
```

---

## 6. Target MQL5 Data Contracts

The Liquidity Engine uses data structures that align with the priority contract outputs:

### 6.1 `LiquidityPool` Struct
*(Stored in `SnrEngine.mqh` and utilized backward-compatibly)*
```cpp
struct LiquidityPool
{
   int       id;                 // Unique identifier
   double    priceHigh;          // Top boundary of the pool
   double    priceLow;           // Bottom boundary of the pool
   bool      isBuyLiquidity;     // true = Buy Stops (above highs), false = Sell Stops (below lows)
   double    liquidityStrength;  // Strength rating (0-100)
   bool      isSwept;            // Whether price has run this pool
   datetime  sweptTime;          // Timestamp of sweep event
};
```

### 6.2 `LiquiditySweepEvent` Struct
*(Holds historical details of completed stop runs on bar close)*
```cpp
struct LiquiditySweepEvent
{
   int       poolId;             // Unique ID of the swept pool
   double    sweepPrice;         // Maximum price depth reached during the sweep
   double    closePrice;         // Close price of the sweeping bar
   double    sweepSizeATR;       // Excursion distance relative to ATR
   datetime  sweepTime;          // Open time of the sweeping bar
   bool      isBuyStopSweep;     // true = BSL swept (reversals short), false = SSL swept (reversals long)
   int       sweepBarIndex;      // Bar index where sweep occurred (H4 or M30)
};
```

### 6.3 Downstream Integration Contract (`LiquidityPriorityContract`)
Exposed to `CEntryEngine` to dictate entry filters:
```cpp
struct LiquidityPriorityContract
{
   // Active (unswept) pools closest to current price
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // Immediate sweep trigger (populated on the bar close when a sweep completes)
   bool           isBSLSweptThisBar;
   double         bslSweepSize;
   
   bool           isSSLSweptThisBar;
   double         sslSweepSize;
   
   // High-volume breakout filter
   bool           isTrendBreakoutActive; // true if sweep size exceeds InpLiqSweepMaxSizeATR (no reversal)
};
```

---

## 7. Dependency Map & Data Pipeline

The pipeline is strictly unidirectional. The Liquidity Engine reads from frozen upstream components and passes its outputs down to the Entry and Risk layers:

```
                  +-----------------------------------+
                  |      StructureEngine v2.2         |
                  +-----------------+-----------------+
                                    |
                                    | (Major/Minor Swings)
                                    v
                  +-----------------+-----------------+
                  |         SnrEngine v1.0            |
                  |     (CSnrPriorityEngine)          |
                  +-----------------+-----------------+
                                    |
                                    | (SnrPriorityContract)
                                    v
+-----------------+       +---------+---------+
| H4/M30 OHLC     | ----> |  LiquidityEngine  |
| Price Data      |       |      v1.0         |
+-----------------+       +---------+---------+
                                    |
                                    | (LiquidityPriorityContract)
                                    v
                  +-----------------+-----------------+
                  |        EntryEngine (M30)          |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------+-----------------+
                  |        RiskEngine (M30)           |
                  +-----------------------------------+
```

---

## 8. Verification & Validation Protocol

Before this specification is frozen and implementation commences, the design must survive the following verification checks:

1.  **Contract Compatibility Check**: Verify that `LiquidityPool` structure definitions compiled in `SnrEngine.mqh` align exactly with the members required by `LiquidityEngine.mqh`.
2.  **No Upstream Modification**: Confirm that `CLiquidityEngine` accesses swings via `m_structureEngine.GetMajorHigh()` and `m_structureEngine.GetMajorLow()`. It must not alter any upstream array or private states.
3.  **Local ATR Integrity**: `CLiquidityEngine` must implement local ATR calculations from cached price arrays, complying with the **Local ATR Principle** to prevent strategy tester sync lag.
