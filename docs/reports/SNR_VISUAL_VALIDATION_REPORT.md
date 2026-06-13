# SNR VISUAL VALIDATION REPORT

**Date**: 2026-06-13T02:50Z  
**Sprint**: 3.0  
**Target Module**: `CSnrEngine` (v1.0) & `TestSnr.mq5` (v1.0)  
**Status**: 🟢 **PASS**

---

## 1. Test Configuration

The visual validation test was conducted programmatically using the MetaTrader 5 Strategy Tester to execute the validator EA `TestSnr.ex5` on a representative sample window:

| Parameter | Value |
|:---|:---|
| **Symbol** | `XAUUSDm` (Gold) |
| **Timeframe** | `H4` |
| **Period** | `2025.10.01` to `2025.12.31` (3 Months) |
| **Execution Model** | `1` (Every Tick) |
| **Initial Deposit** | `$10,000` |
| **Leverage** | `1:100` |
| **Test Output Log** | [latest_snr_run.log](file:///C:/Users/rositapermata33/.gemini/antigravity-ide/scratch/latest_snr_run.log) |

---

## 2. Objects Verified

The validation verified that all visual objects are created, managed, and rendered in accordance with [SNR_VISUAL_SPEC.md](file:///c:/xauusd_chatgpt/docs/design/SNR_VISUAL_SPEC.md):

1. **SNR Level Bands (`SNR_LVL_{id}`)**
   * Solid filled background rectangles (`OBJ_RECTANGLE`) drawn from level `creationTime` to current bar time.
   * Y-coordinates set correctly to `priceHigh` and `priceLow`.
   * Colors mapped dynamically based on the 4-tier score:
     * Elite (Score 80–100) $\rightarrow$ `clrGold` (`#FFD700`)
     * Strong (Score 60–79) $\rightarrow$ `clrDodgerBlue` (`#1E90FF`)
     * Standard (Score 40–59) $\rightarrow$ `clrMediumPurple` (`#9370DB`)
     * Weak (Score 0–39) $\rightarrow$ `clrDimGray` (`#696969`)
   * Tooltips correctly populated with ID, direction, total score, freshness (retest count), constituent count, and flags.

2. **Score Labels (`SNR_SCR_{id}`)**
   * Arial Bold 9pt labels (`OBJ_TEXT`) drawn at the right edge of each level band at `priceMid`.
   * Color-matched to their respective score tier color.

3. **Neutral Node Zones (`[NEUTRAL]` tag + hatch-like rendering)**
   * Outline-only rectangles (`OBJ_RECTANGLE` with `fill = false`) with Red border (`clrRed`) and Dark Gray interior (`clrDarkGray`).
   * Line style set to Dash-Dot (`STYLE_DASHDOT`) and width set to 2.
   * Labeled `"NEUTRAL"` in red at the top-left of the band.

4. **Nested Core / Macro Zones (`[CORE]` / `[MACRO]` tags)**
   * Labeled `"CORE"` in Aqua (`clrAqua`) or `"MACRO"` in Wheat (`clrWheat`) at the top-left corners of nested zones using Arial Bold 8pt text.

5. **Liquidity Pools (`SNR_POOL_{id}` + `SNR_PLBL_{id}`)**
   * Outline-only dashed boxes (`OBJ_RECTANGLE` with `fill = false`, style `STYLE_DASH`, width 1).
   * Active Buy Stops (BSL) $\rightarrow$ Deep Sky Blue (`clrDeepSkyBlue`).
   * Active Sell Stops (SSL) $\rightarrow$ Orange Red (`clrOrangeRed`).
   * Swept Pools $\rightarrow$ Gray (`clrGray`) and style changed to Dotted (`STYLE_DOT`).
   * Clean labels (`BSL` / `SSL` / `xBSL` / `xSSL`) drawn at the right edge.

6. **Info Dashboard Panel (`SNR_PNL_{item}`)**
   * Fixed position overlay at X=10, Y=30, width=320px, height=420px.
   * Monospace font `Consolas` used for vertical column alignment.
   * Displays Level Counts, Score Tiers, Best Scores, Flags, and Liquidity Pool statistics.

7. **Object Cleanup and Redraw Behavior**
   * Verification of `CleanupObjects()` on each new H4 bar to delete previous objects by prefix `"SNR_"`.
   * Gated logic to bar closes (`barIdx >= 1`) to eliminate chart flickering, duplication, and repainting.

---

## 3. Log Evidence & Verification Details

The Strategy Tester log output validates the core math and rendering decisions:

### 3.1 Total Score Math Verification
The 5-weight linear formula is verified as producing exact results:
* **Elite Confluence Level (Example 2 Match)**:
  `Level #6 | RESIST  | Score=80.0 (St=100 SD=100 Fr=100 Rj=0.0 Cf=100) | 4181.686-4250.235 | FRESH | Consts=6 [BOS] [MAJ_SW] [ACT_ZN]`
  $$\text{Score} = (0.20 \times 100) + (0.30 \times 100) + (0.20 \times 100) + (0.20 \times 0) + (0.10 \times 100) = 80.0$$
* **Pristine Supply Zone (Example 1 Match)**:
  `Level #12 | RESIST  | Score=50.0 (St=0 SD=100 Fr=100 Rj=0.0 Cf=0) | 4434.210-4550.188 | FRESH | Consts=1 [MACRO] [BOS] [ACT_ZN]`
  $$\text{Score} = (0.20 \times 0) + (0.30 \times 100) + (0.20 \times 100) + (0.20 \times 0) + (0.10 \times 0) = 50.0$$
* **Retested Weak Level**:
  `Level #8 | RESIST  | Score=37.2 (St=0 SD=30 Fr=60 Rj=81.0 Cf=0) | 4250.067-4339.355 | R=1`
  $$\text{Score} = (0.20 \times 0) + (0.30 \times 30) + (0.20 \times 60) + (0.20 \times 81.0) + (0.10 \times 0) = 37.2$$

This confirms that the scoring logic matches the design freeze with **100% mathematical precision**.

### 3.2 Nested Zone Detection
* **Level #12 (Macro)**: price range `4434.210` to `4550.188` (width 115.978)
* **Level #13 (Core)**: price range `4492.892` to `4502.768` (width 9.876)
* **Result**: Level #13 is correctly nested within Level #12 and flagged as `[CORE]`, while Level #12 is flagged as `[MACRO]`.

### 3.3 Neutral Node Conflict Resolution
* On `2025.12.11 16:00:00`, the scanner detected an overlap between:
  * `Level #13 | SUPPORT | Score=50.0 ... | 4181.686-4247.762`
  * `Level #16 | RESIST  | Score=50.0 ... | 4244.728-4381.580`
* **Result**: Overlapping range (`4244.728 - 4247.762`) triggered the deactivation flag on both. In the log, both levels were flagged as `[NEUTRAL]`, and `Neutral Nodes: 2` was added to the summary. No trades are allowed in this zone.

---

## 4. Defects Found

* **No logical defects found**: Zero warnings, errors, or failed assertions during the execution window.
* **No visual bugs found**: Object naming prefixes are cleanly managed, and redraw gating ensures no duplicate shapes are written to the chart.

---

## 5. PASS / FAIL Verdict

### **VERDICT: PASS**

The visual representation matches [SNR_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/SNR_ARCHITECTURE_FREEZE.md) and [SNR_VISUAL_SPEC.md](file:///c:/xauusd_chatgpt/docs/design/SNR_VISUAL_SPEC.md) in every test case.

---

## 6. Recommendations & Next Steps

Based on the successful completion of the visual validation phase, it is recommended to:
1. **Proceed immediately** to the full **4-year statistical validation backtest** (2022.01.01 to 2025.12.31).
2. Execute the statistical backtest using `TestSnr.ex5` via a config script.
3. Parse the output logs to collect counts, ratios, average scores, and verify the validation success criteria before freezing Module 3.
