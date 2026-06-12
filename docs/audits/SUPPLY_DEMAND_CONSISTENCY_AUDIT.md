# Supply & Demand Engine v1.1 - Consistency Audit Report

**Author**: Quant Researcher & Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: COMPLETE  
**Target File**: [SUPPLY_DEMAND_CONSISTENCY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/SUPPLY_DEMAND_CONSISTENCY_AUDIT.md)

---

## 1. Executive Summary

This consistency audit isolates the source of the statistical shift from the **33.52% projected false positive rate** in the first report to the **2.27% verified false positive rate** in the updated report. 

By running the **exact same parser version** ([compile_statistics.ps1](file:///C:/Users/rositapermata33/.gemini/antigravity-ide/scratch/compile_statistics.ps1)) against the raw logs of `SupplyDemandEngine v1.0` (pre-hotfix) and `SupplyDemandEngine v1.1` (post-hotfix), we mathematically prove:
1.  The change from **0% to 2.27%** in raw reporting is 100% caused by the **engine hotfixes**.
2.  The difference between the projected **33.52%** and the verified **2.27%** is caused by the **analytical projection error** in our first report (which over-estimated false positives by failing to account for consecutive touch grouping).

---

## 2. Side-by-Side Comparison

The table below presents the side-by-side comparison using the **EXACT same parser script** on the isolated runs of the two engine versions:

| Metric | Version 1.0 (Pre-Hotfix) | Version 1.1 (Post-Hotfix) | Net Change | Source of Change |
| :--- | :---: | :---: | :---: | :--- |
| **Total Zones** | 246 | 246 | 0 | - |
| **Invalidated Zones** | 176 | 176 | 0 | - |
| **Zones with 0 Reactions** | 0 | **4** | **+4** | **Engine Hotfix (Fix B)** |
| **False Positive Rate** | 0.00% | **2.27%** | **+2.27%** | **Engine Hotfix (Fix B)** |
| **Average Reactions** | 2.86 | **2.82** | **-0.04** | **Engine Hotfix (Fix B)** |
| **Average Zone Score** | 76.90 | **75.01** | **-1.89** | **Engine Hotfix (Fix A - Age Decay)** |

---

## 3. Quantification of Effects

To answer the core audit question: *"How much of the statistical improvement came from fixing the engine, and how much came from fixing the reporting pipeline?"* we break down the two effects:

### Effect A: Engine Hotfix Only (Raw Parser vs. Raw Parser)
Comparing the raw parsed results of Version 1.0 vs. Version 1.1 reveals the pure effect of the MQL5 engine corrections:
*   **False Positive Discovery**: Increased from **0% to 2.27%** (+4 zones). The hotfix successfully stopped the invalidation bar from being counted, exposing the 4 zones that were broken immediately with 0 prior reactions.
*   **Average Reaction Correction**: Reduced from **2.86 to 2.82** (-0.04). The hotfix removed the +1 inflated reaction on the 4 false positives and 3 other zones (two went from 2 to 1 touch, and one went from 4 to 3 touches).
*   **Age Decay Activation**: The average zone score decreased from **76.90 to 75.01** (-1.89), proving that the age subtraction correction activated the linear decay of older zones.

### Effect B: Reporting Pipeline Correction (Analytical Projection vs. Raw Parser)
Comparing the first report's analytical projection (33.52%) to the verified post-fix rate (2.27%) reveals the reporting projection error:
*   **The Projection Assumption**: In the first report, we assumed that *every* invalidated zone with `MaxReacts = 1` had its only touch at the invalidation bar, estimating 59 false positives.
*   **The Reality**: The revalidation proved that **55 of those 59 zones** actually had a real, independent touch on the bar immediately preceding the invalidation (`invalidatedBar + 1`). Because the touch was consecutive to the invalidation, the engine's built-in *consolidation grouping* (`insideZone` tracking) prevented the invalidation bar from adding a second touch.
*   **The Reporting Error**: The analytical projection overestimated false positives by **55 zones (31.25% error)** because it neglected consecutive touch grouping.

---

## 4. Conclusion & Audit Statement

1.  **The engine fixes are 100% responsible** for the shift in verified false positives (from 0 to 4 zones) and the activation of score decay.
2.  **The reporting pipeline projection was corrected** by replacing the analytical estimate (33.52%) with the revalidated raw parser output (2.27%).
3.  **The consolidation grouping logic is highly robust**, protecting 169 out of 176 zones from reaction inflation during historical simulation.

**AUDIT CONCLUSION**:  
The changes are mathematically consistent and verified. `SupplyDemandEngine v1.1` is confirmed as correct and ready for integration.
