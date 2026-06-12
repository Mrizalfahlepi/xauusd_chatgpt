# SNR Level scoring Model Specification

**Author**: Quant Researcher & Market Structure Architect  
**Date**: June 12, 2026  
**Status**: APPROVED DESIGN  
**Target Module**: `SnrEngine.mqh` (Sprint 3.0)

---

## 1. Introduction

The **SNR Scoring Model** evaluates the quality, reliability, and institutional weight of each Support, Resistance, and Liquidity band on a scale of **0 to 100**. 

Higher scores represent major structural levels backed by both institutional order blocks (Supply/Demand zones) and historical price pivots (Major Swings), which have high probability of holding price on future retests.

---

## 2. The Scoring Formula

The Total SNR Score is a weighted sum of five quality parameters:

$$\text{Score}_{\text{SNR}} = (W_{\text{Struct}} \times S_{\text{Struct}}) + (W_{\text{SD}} \times S_{\text{SD}}) + (W_{\text{Fresh}} \times S_{\text{Fresh}}) + (W_{\text{React}} \times S_{\text{React}}) + (W_{\text{Confl}} \times S_{\text{Confl}})$$

*   *Capping*: Since all weights sum to exactly $1.00$ ($0.20 + 0.30 + 0.20 + 0.20 + 0.10 = 1.00$) and each component score is bounded in $[0, 100]$, the output is mathematically guaranteed to be bounded in $[0, 100]$ without requiring an arbitrary capping function.
*   *Weights Definition*:
    *   $W_{\text{Struct}} = 0.20$ (Structure Weight)
    *   $W_{\text{SD}} = 0.30$ (Supply/Demand Weight)
    *   $W_{\text{Fresh}} = 0.20$ (Freshness Weight)
    *   $W_{\text{React}} = 0.20$ (Reaction Weight)
    *   $W_{\text{Confl}} = 0.10$ (Confluence Weight)

---

## 3. Parameter Score Definitions

### 3.1 Structure Score ($S_{\text{Struct}}$)
Evaluates the historical swing points residing within the SNR price band:
*   Level contains at least one **Major Swing High/Low**: `100` points.
*   Level contains only **Minor Swing High/Low**: `50` points.
*   Level contains **no swing points** (pure S/D base): `0` points.

### 3.2 Supply/Demand Score ($S_{\text{SD}}$)
Evaluates the institutional order block footprint:
*   Level overlaps with an **Active/Valid S/D zone**: `100` points.
*   Level overlaps only with an **Invalidated S/D zone**: `30` points.
*   Level has **no S/D zone footprint**: `0` points.

### 3.3 Freshness Score ($S_{\text{Fresh}}$)
Decays as the number of retests increases, representing order depletion:
*   **0 touches (Fresh)**: `100` points.
*   **1 touch**: `60` points.
*   **2 touches**: `30` points.
*   **$\ge 3$ touches (depleted)**: `0` points.

### 3.4 Reaction Score ($S_{\text{React}}$)
Measures the average strength of price rejection (bounce distance) away from the level:
*   Formula:
$$S_{\text{React}} = \min\left(100.0, \frac{\text{AvgRejectionDistance}}{\text{ATR}} \times 50.0\right)$$
    *   If average rejection is 2.0 ATR or greater, score is 100.
    *   If average rejection is 1.0 ATR, score is 50.
    *   For untouched levels (0 reactions), $S_{\text{React}} = 0$.

### 3.5 Confluence Score ($S_{\text{Confl}}$)
Measures structural alignment across different market elements:
*   **S/D Zone + Major Swing Overlap**: `100` points (contributes 10.0 to total).
*   **Multiple S/D Zones Overlap**: `100` points (contributes 10.0 to total).
*   **Major Swing + BOS Origin Overlap**: `70` points (contributes 7.0 to total).
*   **S/D Zone + Minor Swing Overlap**: `50` points (contributes 5.0 to total).
*   **No Overlap (Single Element)**: `0` points.

---

## 4. Worked Examples (Using Real Zones from Backtest)

Here are three worked examples using real zones extracted from the 4-year backtest log file:

### Example 1: SUPPLY-4550.188-4434.21 (Pristine Supply Zone)
*   **Context**: Created at `2025.12.29 12:00` at the all-time high. No historical swing points exist in this price range.
*   **Metrics**:
    *   $S_{\text{Struct}} = 0$ (No swings)
    *   $S_{\text{SD}} = 100$ (Active S/D zone)
    *   $S_{\text{Fresh}} = 100$ (0 reactions)
    *   $S_{\text{React}} = 0$ (0 reactions)
    *   $S_{\text{Confl}} = 0$ (No confluence)
*   **Score Calculation**:
$$\text{Score}_{\text{SNR}} = (0.20 \times 0) + (0.30 \times 100) + (0.20 \times 100) + (0.20 \times 0) + (0.10 \times 0) = 0 + 30 + 20 + 0 + 0 = 50.0$$
*   **Audit Comment**: A pure supply zone with no historical price action has a solid base score of **50.0**. It represents a valid but unconfirmed resistance area.

### Example 2: SUPPLY-2659.206-2628.487 (High-Confluence Major Resistance)
*   **Context**: Created at `2024.10.08 12:00`, aligned with a Bearish BOS origin bar and a Major Swing High.
*   **Metrics (Evaluated when active, 10 bars after creation)**:
    *   $S_{\text{Struct}} = 100$ (Overlaps Major Swing High)
    *   $S_{\text{SD}} = 100$ (Active S/D zone)
    *   $S_{\text{Fresh}} = 100$ (0 reactions)
    *   $S_{\text{React}} = 0$ (0 reactions)
    *   $S_{\text{Confl}} = 100$ (S/D + Major Swing)
*   **Score Calculation**:
$$\text{Score}_{\text{SNR}} = (0.20 \times 100) + (0.30 \times 100) + (0.20 \times 100) + (0.20 \times 0) + (0.10 \times 100) = 20 + 30 + 20 + 0 + 10 = 80.0$$
*   **Audit Comment**: The overlap of institutional supply and major market structure creates a premium SNR level of **80.0**, representing a high-probability sell area.

### Example 3: DEMAND-1994.276-1965.416 (Retested Demand Level)
*   **Context**: Created at `2023.11.21 12:00` overlapping with a Minor Swing Low. Price has touched the zone 2 times since creation, with an average rejection distance of 1.2 ATR.
*   **Metrics**:
    *   $S_{\text{Struct}} = 50$ (Overlaps Minor Swing Low)
    *   $S_{\text{SD}} = 100$ (Active S/D zone)
    *   $S_{\text{Fresh}} = 30$ (2 touches)
    *   $S_{\text{React}} = 60$ (Rejection score: $\frac{1.2}{2.0} \times 100 = 60.0$)
    *   $S_{\text{Confl}} = 50$ (S/D + Minor Swing)
*   **Score Calculation**:
$$\text{Score}_{\text{SNR}} = (0.20 \times 50) + (0.30 \times 100) + (0.20 \times 30) + (0.20 \times 60) + (0.10 \times 50) = 10 + 30 + 6 + 12 + 5 = 63.0$$
*   **Audit Comment**: The level has good structural backing, but its freshness score has depleted due to 2 retests, resulting in a moderate score of **63.0**.
