# SNR ENGINE v1.0 - OUTPUT OPTIMIZATION & TRADING USABILITY AUDIT

**Date**: 2026-06-13T03:10Z  
**Phase**: Sprint 3.1 — Output Optimization & Usability Audit  
**Auditor**: Antigravity Agent  
**Target Module**: `CSnrEngine` (v1.0) & `TestSnr.mq5` (v1.0)  
**Status**: ⚠️ **ACTION REQUIRED — CRITICAL DENSITY BOTTLENECK DETECTED**

---

## 1. The Bottleneck: "Grid Lock" Price Action

While the 4-year statistical validation proved that `CSnrEngine` is mathematically correct and compiles cleanly, it exposed a major usability flaw: **excessive level density**.

An average of **23.72 levels active on every H4 bar** (with peaks up to **42 levels**) creates a "Grid Lock" effect. Instead of showing clear institutional support and resistance, the chart is covered in horizontal bands. 

For both a discretionary trader and the automated `EntryEngine` (Phase 5), this density is problematic:
1. **Discretionary Trader**: The price is *always* touching a level. It is impossible to determine which level is the primary key level to watch for reversals.
2. **Entry Engine**: If the Entry Engine scans all 23 levels, it will suffer from **setup dilution** (generating trades on minor levels with low win-rates) and **computational bloat** (needlessly iterating through dozens of invalid or low-quality coordinates).

---

## 2. Quantitative Distribution Analysis

The statistical data from the 4-year run provides a clear path to optimization. The table below correlates the score distributions with trading usability:

| Score Range | Count (Obs) | % of Total | Usability Grade | Recommended Action |
|:---:|:---:|:---:|:---|:---|
| **80 – 100** | `828` | **0.47%** | **Elite**: Prime institutional blocks + Major Swings | **Always Draw & Prioritize** |
| **60 – 79** | `10,704` | **6.06%** | **Strong**: Validated support/resistance zones | **Always Draw & Prioritize** |
| **40 – 59** | `97,638` | **55.26%** | **Standard**: Minor pivots; reactive but weak volume | **Filter out by default** |
| **0 – 39** | `67,349` | **38.21%** | **Weak / Noise**: Broken or stale structural leftovers | **Strictly Suppress & Hide** |

### 2.1 The Math of Noise Reduction
If we implement a **Hard Score Threshold** of $\ge 60.0$, we eliminate the Standard and Weak tiers:
$$\text{Noise Reduction} = 55.26\% + 38.21\% = 93.47\%$$

* **Impact**: The average level density drops from **23.72** to **1.55 levels per bar**!
* **Result**: The chart is instantly cleaned. Only the absolute highest-probability institutional zones are displayed and sent to downstream execution engines.

---

## 3. Entry Engine Data Consumption Requirements

The `EntryEngine` (Phase 5) does not need a full map of the historical price grid. It is designed to act on imminent price setups. 

### 3.1 Entry Engine Ingestion Rules
To prevent logic bloat, the SNR Engine must feed the Entry Engine a **curated subset** of levels based on:
1. **Directional Bias**: Only feed levels matching the current macro trend bias (e.g. if Trend = BULLISH, only look at Support levels).
2. **Quality (Score)**: Minimum score cutoff ($\ge 50.0$ or $\ge 60.0$).
3. **Proximity to Market (Top-N)**: The Entry Engine only cares about levels that price is *currently approaching*. Levels that are 500 pips away are irrelevant for M30 execution. It needs the **Top-3 Support** and **Top-3 Resistance** levels closest to the current market Bid/Ask.

### 3.2 Visual Contrast (All Levels vs. Filtered Levels)

```
[CURRENT UNFILTERED CHART]               [PROPOSED FILTERED CHART]
================================         ================================
██████████████████ (Resist Score 24)
────────────────────────────────
██████████████████ (Resist Score 42)
────────────────────────────────
================================         ================================
                                              [PRICE ACTION]
================================         ================================
██████████████████ (Support Score 35)
────────────────────────────────
██████████████████ (Support Score 82)    ██████████████████ (Support Score 82)
────────────────────────────────
██████████████████ (Support Score 48)
================================         ================================
```

---

## 4. Proposed Filtering & Optimization Framework

To resolve the density issue without breaking the mathematical engine, we propose introducing a **three-tier filtering layer** inside `CSnrEngine`:

### Tier 1: Score Threshold Filter
* **Parameter**: `input double InpMinScoreDraw = 50.0;`
* **Behavior**: Any consolidated SNR level with a final score below this value is kept in memory (for historical tracking) but is suppressed from the output arrays (`m_snrLevels`) and chart drawing.

### Tier 2: Top-N Ranking Limit
* **Parameter**: `input int InpMaxLevelsPerSide = 3;`
* **Behavior**: Restricts the maximum number of active bands returned. The engine sorts the filtered levels and returns only the top $N$ highest-scored Support and top $N$ highest-scored Resistance levels.

### Tier 3: Proximity Sorting (Distance to Market)
* **Parameter**: `input bool InpSortByProximity = true;`
* **Behavior**: For execution purposes, the engine sorts the active levels by their absolute distance to the current price (`MathAbs(level.priceMid - Bid)`). The Entry Engine is fed the levels that price is closest to, rather than the oldest or highest-scored historical levels that are far away.

---

## 5. Recommended Implementation Plan (Sprint 3.2)

We recommend executing a short **Visual Usability & Filter Refinement Sprint (Sprint 3.2)** before freezing Module 3. This sprint will implement the three-tier filtering framework in `SnrEngine.mqh` and `TestSnr.mq5`.

### Proposed Code Modifications:

1. **Add Inputs to `TestSnr.mq5`**:
   ```cpp
   input double InpMinScoreShow       = 50.0; // Minimum score to display level
   input int    InpMaxLevelsPerSide   = 3;    // Max levels to display per side (Support/Resist)
   input bool   InpFilterByProximity  = true; // Sort output by proximity to current market price
   ```

2. **Enhance `CSnrEngine::Analyze()`**:
   * Add a filtering pass after Step 9 (Scoring).
   * Filter levels into two temporary arrays: `bullishLevels[]` and `bearishLevels[]` with scores $\ge$ `InpMinScoreShow`.
   * Sort both arrays by proximity to current price or by score descending.
   * Resize the final output `m_snrLevels` to contain only the Top-N levels from each side.

3. **Verify Usability**:
   * Run the 3-month validation check with `InpMinScoreShow = 50.0` and `InpMaxLevelsPerSide = 3`.
   * Confirm that the average level count drops from **23.72** to **$\le$ 6 active levels** at any given moment, making the chart fully readable for both discretionary traders and the Entry Engine.

---

## 6. Audit Verdict

### **Verdict: PASS WITH IMPROVEMENTS (REFINE SPRINT REQUIRED)**

### **Recommendation**
Do **not** freeze Sprint 3 yet. We should execute a short visual refinement sprint (Sprint 3.2) to implement the filtering layer. This will guarantee that the output sent to downstream engines (beginning with the upcoming Liquidity and Entry Engines) is optimized, selective, and ready for high-probability execution.
