# SNR VISUAL USABILITY AUDIT

**Date**: 2026-06-13T02:55Z  
**Sprint**: 3.0  
**Target Module**: `CSnrEngine` (v1.0) & `TestSnr.mq5` (v1.0)  
**Status**: 🟡 **PASS WITH IMPROVEMENTS**  
**Visual Usability Score**: **72 / 100**

---

## 1. Context & Objective

This audit evaluates the chart representation of the SNR Engine v1.0 and the `TestSnr.mq5` validator from the perspective of a discretionary trader. 

While the previous visual validation confirmed **mathematical correctness** (correct level calculations, color tiers, and nested zone labels), this audit assesses **human readability, chart clutter, information density, and trading usability**.

---

## 2. Required Analysis

### A. Price Visibility
* **Candle Readability**: Levels are correctly rendered on the background layer (`OBJPROP_BACK = true`), allowing candles to sit on top of the bands. However, because standard MQL5 rectangles do not support native alpha transparency without complex Canvas drawing, solid-filled bands (especially gold/blue) block the MT5 grid and can darken the background.
* **Zone Opacity**: The solid fills for Standard, Strong, and Elite zones create high contrast. In areas where multiple zones consolidate, the chart grid is completely invisible, reducing a trader's ability to see minor price movement details inside the band.
* **Overlay Interference**: The info panel utilizes a black background with transparency `210`, which blends well but physically obscures a fixed 320x420 px region in the top-left. Candles behind this panel are completely hidden.

### B. Level Density
* **Total Levels Displayed**: In a standard 300-bar H4 lookup, the engine renders 12–16 consolidated levels. While this maps structure accurately, it is visually overwhelming for a trader who only needs the most critical levels.
* **Low-Score Levels**: Dim gray "Weak" zones (score < 40) are shown on the chart. These zones are rarely tradeable on H4 and should be hidden by default to keep the interface clean.
* **Filtering recommendation**: Implement a **Minimum Score Threshold** (e.g. only show levels with score $\ge 40.0$) and a **Top-N Filter** (e.g. only draw the top 3 Support and top 3 Resistance levels).

### C. Label Density
* **Label Overlaps**: Score labels (`SNR_SCR_{id}`) are drawn at the current bar index on `priceMid`. If two levels are close (e.g. 10–20 pips apart), the text labels overlap, rendering the numbers unreadable.
* **Tag Overlaps**: Nested tags (`CORE`/`MACRO`) and liquidity pool labels (`BSL`/`SSL`) are placed at boundaries. When price consolidates, these text elements overlap in clusters, creating a high-noise region on the chart.
* **Hatching**: Neutral nodes are rendered outline-only with Dash-Dot styling, which is excellent for distinguishing deactivated overlapping zones.

### D. Dashboard Usability
* **Dashboard Size**: The panel's 320x420 px dimension is appropriate for visual checks but is too large for daily trading, especially on multi-chart setups.
* **Scalability**: The dashboard lists 20+ metrics. Adding future modules (Liquidity, Entry, Risk) will push the dashboard height past 600px, which is unusable on standard 1080p screens.
* **Compact Mode**: A collapsible or toggleable panel is required for trading.

### E. Future Module Compatibility
The chart will experience severe clutter as subsequent modules are developed:
1. **Liquidity Engine**: Adds swept and active stop-loss clusters (boxes and labels).
2. **Entry Engine**: Adds entry arrows, stop-loss lines, and take-profit targets.
3. **Risk Engine**: Adds risk-to-reward ratio boxes, drawdown alert lines, and dynamic position labels.
* **Cumulative Impact**: Without visibility toggles, the cumulative visual objects will completely cover price action.

---

## 3. Visual Usability Score Breakdown

| Category | Score | Primary Reason |
|:---|:---:|:---|
| **Price Visibility** | 75/100 | Solid fills hide background grid; panel blocks top-left candles. |
| **Level Density** | 70/100 | Weak zones (Score 0-39) are drawn, adding unnecessary bands. |
| **Label Readability** | 60/100 | Overlapping levels result in overlapping text labels. |
| **Dashboard Layout** | 85/100 | Monospace font is extremely readable, but panel occupies too much screen space. |
| **Future Adaptability**| 70/100 | Adding Liquidity, Entry, and Risk will cause visual clutter. |
| **Overall Score** | **72/100** | **Good foundation, but requires trader-focused refinement.** |

---

## 4. Key Usability Findings

### Major Strengths
* **Dynamic Color Hierarchy**: The 4-tier color map (Gold/Blue/Purple/Gray) instantly conveys level quality without checking numbers.
* **Hatched Neutral Zones**: Outlined neutral zones clearly show traders where to avoid placing orders.
* **No Object Leaks**: Objects are cleaned up and redrawn on each bar close, preventing residual shapes.
* **Monospace Alignment**: Consolas font keeps numbers and text perfectly aligned on the panel.

### Major Weaknesses
* **Weak Level Clutter**: Drawing dim gray bands for weak levels creates visual noise.
* **Overlapping Text**: No algorithm to prevent score labels from overlapping when levels are close.
* **Static Dashboard Size**: Taking up 320x420 px on every tick blocks important historical price action in the top-left corner.

---

## 5. Recommended Refinements

The following inputs are recommended for future implementation to improve usability:

1. **Threshold Filtering**:
   * Add input `input double InpMinScoreDraw = 40.0;` to hide weak support/resistance levels.
2. **Top-N Level Limits**:
   * Add inputs to limit active bands: `input int InpMaxLevelsDraw = 5;` (only draw top 5 highest scored levels per direction).
3. **Interactive Dashboard Toggles**:
   * Create a button object on the chart to minimize/maximize the dashboard.
   * Provide keyboard shortcuts or buttons to toggle individual layers (e.g. press `L` to toggle levels, `P` to toggle pools).
4. **Text Positioning Anti-Overlap**:
   * Implement a label offset algorithm. If `MathAbs(lvl1.priceMid - lvl2.priceMid) < 0.25 * ATR`, shift the second label to the right by 10 bars to prevent overlap.
5. **Debug vs. Trader Modes**:
   * Add `input bool InpTraderMode = false;`. When `true`, it automatically hides the dashboard, hides weak zones, and turns off detailed text annotations, showing only the elite tradeable zones.

---

## 6. Verdict & Next Step Recommendation

### **Verdict**: 🟢 **PASS WITH IMPROVEMENTS**

### **Recommendation**
The project should **proceed directly to the 4-year statistical validation backtest** using the current version of the code, rather than executing a visual refinement sprint first. 

**Rationale**:
* Visual clutter is a client-side interface concern that does **not** affect the backtester's mathematical calculations or engine performance (which runs headlessly during optimization and statistical compilation).
* Usability refinements (transparency, threshold inputs, dashboard collapse) can be batched and implemented efficiently during the **Phase 5 (Trade Entry Engine) integration** or during the **Phase 8 (Live Trading Validation) Master EA wrap-up**, rather than introducing code changes to the current frozen Sprint 3 pipeline.
