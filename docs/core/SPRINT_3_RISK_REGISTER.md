# SPRINT 3.0 — PRE-IMPLEMENTATION RISK REGISTER

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED BASELINE  
**Target Module**: `SnrEngine.mqh` (Sprint 3.0)  
**Source Documents**:
- [PROJECT_GENESIS.md](../../PROJECT_GENESIS.md)
- [LESSONS_LEARNED.md](../../docs/core/LESSONS_LEARNED.md)
- [SNR_ARCHITECTURE_FREEZE.md](../design/SNR_ARCHITECTURE_FREEZE.md)
- [SNR_DESIGN_AUDIT.md](../audits/SNR_DESIGN_AUDIT.md)

---

## Purpose

This document exists to prevent Sprint 3.0 from repeating any mistake that occurred during StructureEngine (Sprint 1.0–2.0) and SupplyDemandEngine (Sprint 2.1–2.2) development.

Every risk is traced back to a historical failure, a design audit finding, or a known architectural constraint. No risk in this register is theoretical — each one has a concrete precedent in this project's history.

**This register must be consulted before writing each method in `SnrEngine.mqh`.**

---

## Risk Severity Matrix

| Probability | Impact: LOW | Impact: MEDIUM | Impact: HIGH | Impact: CRITICAL |
|-------------|------------|----------------|-------------|-----------------|
| **HIGH** | MEDIUM | HIGH | CRITICAL | CRITICAL |
| **MEDIUM** | LOW | MEDIUM | HIGH | CRITICAL |
| **LOW** | LOW | LOW | MEDIUM | HIGH |

---

## 1. Technical Risks

---

### T-01: ATR Division by Zero

| Field | Detail |
|-------|--------|
| **Description** | `CalculateLocalATR()` returns `0.0` during early bars where insufficient price history exists (fewer than 14 bars cached). Any formula dividing by ATR (`distance / ATR`, clustering tolerance `0.25 × ATR`) will produce `INF` or divide-by-zero errors. |
| **Root Cause** | The first 14 bars of a backtest have no complete ATR window. Additionally, if `CacheH4PriceData()` copies fewer bars than expected (e.g., broker provides limited history), ATR may be zero for an extended initialization period. |
| **Probability** | **HIGH** — occurs on every backtest run during the first 14 bars. |
| **Impact** | **HIGH** — unguarded division corrupts all clustering, scoring, and liquidity pool calculations. The entire output array becomes mathematically invalid. |
| **Historical Precedent** | Bug 5 (LESSONS_LEARNED §3, Bug 5): StructureEngine v2.1 received `0.0` from `iATR()` during Strategy Tester runs, classifying 56/58 swings as Minor. The entire grading system was destroyed. |
| **Detection Method** | Log `[WARNING] ATR = 0.0 at barIndex = X` for every zero-ATR event. Add assertion: if total zero-ATR warnings exceed 20 in a single backtest, flag as FAIL. |
| **Mitigation Strategy** | 1. Guard every ATR usage: `if(atr <= 0.0) continue;` or `return;`. 2. Skip all analysis for bars where ATR is invalid. 3. Mirror the exact guard pattern from [StructureEngine.mqh L447](../../src/engines/StructureEngine.mqh) and [SupplyDemandEngine.mqh L237](../../src/engines/SupplyDemandEngine.mqh). |
| **Severity** | **CRITICAL** |

---

### T-02: Array Index Out of Bounds

| Field | Detail |
|-------|--------|
| **Description** | MQL5 does not throw segmentation faults on array out-of-bounds — it silently returns 0 or corrupts adjacent memory. Incorrect loop boundaries in `ExtractLevels()`, `ClusterLevels()`, or `CalculateRejectionDistance()` may read/write past array ends. |
| **Root Cause** | Complex nested loops with multiple array sources (swing arrays, zone arrays, cached price arrays) of different sizes. A loop bound set to `ArraySize(m_rawLevels)` applied to a `m_cachedHighs` access will corrupt data silently. |
| **Probability** | **MEDIUM** — depends on careful loop construction. |
| **Impact** | **HIGH** — silent data corruption produces wrong scores, wrong cluster boundaries, and wrong liquidity pool coordinates with no visible error. |
| **Historical Precedent** | Bug 3 (LESSONS_LEARNED §3, Bug 3): `CountReactions()` scanned past the `breakBarIndex` boundary because the stop condition was not enforced, causing score leakage. |
| **Detection Method** | Add explicit bounds checks before every array access: `if(index < 0 \|\| index >= ArraySize(arr)) { LogMessage("OOB"); return; }`. Log total OOB events per backtest run. |
| **Mitigation Strategy** | 1. Every loop that accesses cached arrays must check `bar < m_cachedBarsCount`. 2. Every loop that accesses upstream arrays must check `index < Get*Count()`. 3. Use `ArraySize()` as the authoritative bound, never hardcoded values. |
| **Severity** | **HIGH** |

---

### T-03: Struct Member Initialization Failure

| Field | Detail |
|-------|--------|
| **Description** | MQL5 does not auto-initialize struct members to zero or false. If `SNRLevel` or `LiquidityPool` structs are created without explicit initialization, boolean flags (`hasMajorSwing`, `isNeutralNode`, `isSwept`) may contain garbage values from stack memory. |
| **Root Cause** | MQL5 struct constructors do not default-initialize primitive members. Unlike C++ `{}` initialization, MQL5 requires explicit assignment in the constructor. |
| **Probability** | **HIGH** — will occur unless constructors are written correctly. |
| **Impact** | **MEDIUM** — false confluence flags, incorrect neutral node detection, phantom liquidity sweeps. Subtle scoring errors that are difficult to trace. |
| **Historical Precedent** | Both `SwingPoint` ([StructureEngine.mqh L105-119](../../src/engines/StructureEngine.mqh)) and `BOSEvent` ([StructureEngine.mqh L134-144](../../src/engines/StructureEngine.mqh)) have explicit constructors initializing every member. This pattern was adopted after early garbage-value issues. |
| **Detection Method** | Code review: verify every struct has a constructor. Log initial values of newly created levels to confirm all booleans start `false` and all scores start `0.0`. |
| **Mitigation Strategy** | Write explicit constructors for `SNRLevel`, `LiquidityPool`, and `RawLevel` that initialize every member to its default value. Follow the exact pattern from upstream structs. |
| **Severity** | **HIGH** |

---

### T-04: Floating-Point Comparison Precision

| Field | Detail |
|-------|--------|
| **Description** | Direct floating-point equality checks (`swing.price == bos.brokenLevel`) will fail due to IEEE 754 rounding. BOS origin resolution, zone overlap detection, and clustering proximity checks all rely on price comparisons. |
| **Root Cause** | XAUUSD prices are stored as `double` with 15-17 significant digits. Upstream engines may store `2641.993` while the BOS event stores `2641.9930000000001` due to arithmetic operations. |
| **Probability** | **HIGH** — XAUUSD prices with 3 decimal places will frequently exhibit floating-point drift. |
| **Impact** | **MEDIUM** — BOS origin flags will be missed, zone overlaps will be undetected, clustering will produce inconsistent boundaries. |
| **Historical Precedent** | The design audit ([SNR_DESIGN_AUDIT.md §2.3](../audits/SNR_DESIGN_AUDIT.md)) identified that BOS origin resolution requires matching `swing.price` to `bos.brokenLevel`, but the structs store prices independently with no tolerance. |
| **Detection Method** | Log BOS origin matching attempts with exact price values: `"Swing=2641.993000, BOS=2641.993000, diff=0.000000, match=true/false"`. |
| **Mitigation Strategy** | Use tolerance-based comparison everywhere: `MathAbs(priceA - priceB) <= 0.01` for XAUUSD (1 cent precision). Never use `==` for `double` comparisons. Define a constant: `const double PRICE_TOLERANCE = 0.01;`. |
| **Severity** | **HIGH** |

---

## 2. Architectural Risks

---

### A-01: Private Method Access Violation

| Field | Detail |
|-------|--------|
| **Description** | `CStructureEngine::GetATRValue()` is declared `private` at [StructureEngine.mqh L296](../../src/engines/StructureEngine.mqh). Any attempt to call it from `CSnrEngine` will cause a compiler error: `cannot access private member function`. |
| **Root Cause** | The original SNR design ([SNR_ENGINE_DESIGN.md §2.2](../archive/SNR_ENGINE_DESIGN.md)) assumed the method was public. The design audit discovered it was private. |
| **Probability** | **HIGH** — will occur if the developer copies patterns from the design document without checking the amendment. |
| **Impact** | **CRITICAL** — compilation failure. Zero output. |
| **Historical Precedent** | [SNR_DESIGN_AUDIT.md §2.1](../audits/SNR_DESIGN_AUDIT.md): "Attempting to call this method inside `CSnrEngine` will cause a compiler error." Resolution: local ATR calculation was mandated. |
| **Detection Method** | Compilation will fail immediately. Additionally, grep for `m_structureEngine.GetATRValue` or `m_structureEngine->GetATRValue` in the codebase. If found, it is a violation. |
| **Mitigation Strategy** | Implement `CSnrEngine::CalculateLocalATR(int barIndex, int period=14)` using cached price arrays, mirroring the exact True Range formula from [StructureEngine.mqh L444-474](../../src/engines/StructureEngine.mqh) and [SupplyDemandEngine.mqh L445-476](../../src/engines/SupplyDemandEngine.mqh). |
| **Severity** | **CRITICAL** |

---

### A-02: Upstream Modification of Frozen Engines

| Field | Detail |
|-------|--------|
| **Description** | Under time pressure or debugging frustration, the developer may be tempted to add a `public` wrapper to `GetATRValue()` in StructureEngine, or add new fields to `SupplyDemandZone`, or modify `BOSEvent` to include origin bar indices. |
| **Root Cause** | Working around frozen engine limitations is harder than modifying the source directly. The design audit identified three workarounds required by the freeze policy. |
| **Probability** | **MEDIUM** — temptation increases when workarounds become complex. |
| **Impact** | **CRITICAL** — any modification to a frozen engine invalidates its 4-year backtest validation. The entire statistical foundation of the project is destroyed. Revalidation requires a full 4-year rerun and re-audit. |
| **Historical Precedent** | [AGENT_CONSTITUTION.md §4.1](../../AGENT_CONSTITUTION.md): "A frozen module may NOT be modified under any normal development sprint." [LESSONS_LEARNED.md §4, Frozen Engine Principle](../../docs/core/LESSONS_LEARNED.md): "Every 'small fix' to a validated engine risks introducing a regression that invalidates thousands of hours of testing." |
| **Detection Method** | Run `git diff src/engines/StructureEngine.mqh src/engines/SupplyDemandEngine.mqh` before every commit. Any non-zero diff is a violation. |
| **Mitigation Strategy** | 1. All workarounds (local ATR, rejection distance re-scan, BOS origin resolution) are pre-planned in [SNR_ARCHITECTURE_FREEZE.md](../design/SNR_ARCHITECTURE_FREEZE.md). 2. No workaround requires upstream modification. 3. If a genuine compiler block is discovered, escalate to project owner — do not modify frozen code. |
| **Severity** | **CRITICAL** |

---

### A-03: Bidirectional Dependency Introduction

| Field | Detail |
|-------|--------|
| **Description** | `CSnrEngine` might inadvertently write back to upstream engine arrays or modify upstream struct members through the pointer references (`m_structureEngine`, `m_sdEngine`). |
| **Root Cause** | MQL5 passes objects by reference. If `CSnrEngine` calls `GetZone()` and then modifies the returned struct, the modification is local (struct copy). But if the developer accesses internal arrays directly (e.g., via pointer arithmetic), upstream data could be corrupted. |
| **Probability** | **LOW** — upstream APIs return copies, not references. |
| **Impact** | **CRITICAL** — corrupted upstream data would invalidate all downstream analysis for the remainder of the backtest. Structure and S/D results would become unreliable. |
| **Historical Precedent** | [LESSONS_LEARNED.md §4, Read-Only Dependency Principle](../../docs/core/LESSONS_LEARNED.md): "Downstream engines are consumers, not producers. They read from upstream and write to their own output arrays." |
| **Detection Method** | Code review: grep for any assignment to `m_structureEngine->` or `m_sdEngine->` fields. Only `Get*()` calls are permitted. |
| **Mitigation Strategy** | 1. All upstream data is accessed exclusively through `Get*()` methods that return copies. 2. `CSnrEngine` never stores pointers to upstream array elements. 3. All output is written to `m_snrLevels[]` and `m_liquidityPools[]` — arrays owned by `CSnrEngine`. |
| **Severity** | **HIGH** |

---

## 3. Performance Risks

---

### P-01: Redundant Historical Bar Scanning

| Field | Detail |
|-------|--------|
| **Description** | Three separate engines (Structure, S/D, SNR) each perform independent chronological loops over hundreds of historical bars. SNR adds a fourth scanning layer for rejection distance calculation. Running all four on every H4 bar close during a 4-year backtest (~6,264 H4 bars × ~500 bars lookback) may cause Strategy Tester timeouts or extreme slowness. |
| **Root Cause** | Each engine is architecturally decoupled and owns its own price cache. There is no shared scanning infrastructure. The frozen status of upstream engines prevents optimization at the pipeline level. |
| **Probability** | **HIGH** — the 4-year backtest is long; Strategy Tester has finite patience. |
| **Impact** | **HIGH** — backtest may not complete within reasonable time, blocking validation. Strategy Tester optimization runs (which execute hundreds of parameter combinations) would be infeasible. |
| **Historical Precedent** | [PROJECT_GENESIS.md §7.1](../../PROJECT_GENESIS.md): "Redundant Price History Scanning" identified as the #1 open risk. [SNR_DESIGN_AUDIT.md §5.1](../audits/SNR_DESIGN_AUDIT.md): "Running multiple independent historical scanning loops inside OnTick will significantly slow down multi-year portfolio backtests." |
| **Detection Method** | Time the `Analyze()` call duration and log it: `"[CSnrEngine] Analyze() completed in X ms"`. If average exceeds 50ms per H4 bar, flag as performance concern. |
| **Mitigation Strategy** | 1. **Gate execution**: Run `Analyze()` only on new H4 bar close (not every tick). 2. **Cap rejection scan**: Limit rejection distance scan to ±20 bars from each touch point, not entire history. 3. **Delta scanning**: After the first full analysis, subsequent calls process only the delta (new bar) rather than re-scanning all history. 4. **Cache results**: Store computed rejection distances per level ID; only recompute when a new touch occurs. |
| **Severity** | **CRITICAL** |

---

### P-02: Excessive Dynamic Array Resizing

| Field | Detail |
|-------|--------|
| **Description** | Using `ArrayResize(arr, size + 1)` inside a loop (the "push_back" pattern) causes O(N²) memory allocation overhead because MQL5 reallocates the entire array on every call. |
| **Root Cause** | MQL5's `ArrayResize` does not pre-allocate spare capacity by default. Each resize copies the entire array to a new memory block. |
| **Probability** | **HIGH** — the extraction loop processes 50-200 raw levels, and the clustering loop may expand clusters iteratively. |
| **Impact** | **MEDIUM** — performance degradation proportional to N², noticeable during optimization runs with hundreds of iterations. |
| **Historical Precedent** | Both StructureEngine (L520-522) and SupplyDemandEngine (L280-281) use the `ArrayResize(arr, size + 1)` pattern. Performance was acceptable because array sizes are small (<500). SNR may have larger intermediate arrays. |
| **Detection Method** | Profile `Analyze()` execution time. If array operations dominate, the resize pattern is the cause. |
| **Mitigation Strategy** | 1. Pre-allocate arrays to estimated maximum size: `ArrayResize(m_rawLevels, 0, 200)` (reserve 200 slots). 2. Use a separate counter to track actual size, only `ArrayResize` at the end to trim. 3. If performance is still an issue, switch to fixed-size arrays with bounds checking. |
| **Severity** | **MEDIUM** |

---

## 4. Data Dependency Risks

---

### D-01: Missing Reaction Coordinates in SupplyDemandZone

| Field | Detail |
|-------|--------|
| **Description** | The `SupplyDemandZone` struct stores `reactionCount` as a simple integer. It does **not** store the bar indices or price coordinates where touches occurred. `CSnrEngine` needs the exact touch locations to compute rejection distance (price excursion after each bounce). |
| **Root Cause** | `SupplyDemandEngine v1.1` was designed before the SNR scoring model was finalized. The scoring model requires data that the upstream struct does not provide. |
| **Probability** | **CERTAIN** — the data gap is confirmed in the design audit. |
| **Impact** | **HIGH** — without touch coordinates, rejection distance cannot be computed from metadata alone. A workaround (historical re-scan) is required, introducing performance cost and code complexity. |
| **Historical Precedent** | [SNR_DESIGN_AUDIT.md §2.2](../audits/SNR_DESIGN_AUDIT.md): "CSnrEngine cannot compute the rejection distance of past touches using the zone metadata alone." |
| **Detection Method** | Not applicable — this is a known, pre-audited constraint. |
| **Mitigation Strategy** | `CSnrEngine` re-scans historical bars between `zone.impulseBarIndex` and the current bar to independently identify touch events and compute rejection distances. The scan uses the same `insideZone` state tracking pattern from [StructureEngine.mqh L701-721](../../src/engines/StructureEngine.mqh) to avoid counting consolidation as multiple touches. |
| **Severity** | **HIGH** |

---

### D-02: Missing BOS Origin Reference in BOSEvent

| Field | Detail |
|-------|--------|
| **Description** | The `BOSEvent` struct stores `brokenLevel` (the price of the broken swing) and `barIndex` (when the break occurred), but it does **not** store a reference to the original `SwingPoint` that was broken. `CSnrEngine` needs the original swing's `barIndex` to determine the BOS origin location for confluence scoring. |
| **Root Cause** | `StructureEngine v2.2` was designed before BOS origin scoring was conceptualized. The BOS event records the break, not the broken swing's identity. |
| **Probability** | **CERTAIN** — the data gap is confirmed in the design audit. |
| **Impact** | **MEDIUM** — without the origin swing reference, `hasBOSOrigin` flags may have false negatives (missed matches). The workaround (price-matching with tolerance) may produce false positives in extreme edge cases. |
| **Historical Precedent** | [SNR_DESIGN_AUDIT.md §2.3](../audits/SNR_DESIGN_AUDIT.md): "CSnrEngine must query the major swing arrays to find the invalidated swing whose price matches `brokenLevel`." |
| **Detection Method** | Log every BOS origin resolution attempt: `"BOS at bar X, brokenLevel=Y, matched swing at bar Z (diff=D)"`. Review logs for ambiguous multi-matches. |
| **Mitigation Strategy** | 1. Iterate through major swing arrays. 2. Match `swing.price` to `bos.brokenLevel` within `PRICE_TOLERANCE = 0.01`. 3. Verify `swing.isInvalidated == true` and `swing.breakBarIndex` matches the BOS event index. 4. If multiple swings match (rare), use the one with the closest `breakBarIndex`. |
| **Severity** | **MEDIUM** |

---

### D-03: Invalidated Zone Lookback Window Sensitivity

| Field | Detail |
|-------|--------|
| **Description** | The design spec mandates including invalidated zones created within the last 150 bars for `S_SD = 30` scoring. The `150` value is a tunable parameter. If set too low, valid invalidated zones are excluded; if set too high, stale zones pollute the level map. |
| **Root Cause** | The optimal lookback window was not empirically validated. The value `150` was chosen based on the average zone lifetime (~124.73 H4 bars) plus a safety buffer. |
| **Probability** | **MEDIUM** — the value is reasonable but may not be optimal for all market conditions. |
| **Impact** | **LOW** — wrong lookback affects scoring accuracy but not system correctness. Under-inclusion produces lower S_SD scores; over-inclusion produces cluttered levels. |
| **Historical Precedent** | [SNR_DESIGN_AUDIT.md §3.1](../audits/SNR_DESIGN_AUDIT.md): "The clustering step must be modified to extract both active zones and recently invalidated zones (within the lookback window)." |
| **Detection Method** | Log the count of invalidated zones included vs. excluded per analysis cycle. Compare score distributions with 100, 150, and 200 bar lookbacks. |
| **Mitigation Strategy** | Make `InpInvalidatedLookback` a configurable input parameter (default: 150). This allows optimization during Strategy Tester parameter sweeps without code changes. |
| **Severity** | **LOW** |

---

## 5. Historical Bug Risks

These risks are direct re-occurrence vectors of bugs discovered in Sprints 1.0–2.2.

---

### H-01: Bar 0 Repainting in SNR Level Creation

| Field | Detail |
|-------|--------|
| **Description** | If `Analyze()` processes Bar 0 (the active, uncompleted candle), SNR levels may appear and disappear as ticks arrive. Levels created from Bar 0 price data constitute repainting — the most dangerous defect in a trading system. |
| **Root Cause** | Bar 0's high, low, and close change with every tick during the H4 candle. Any structural decision based on these values is provisional and may reverse before the candle closes. |
| **Probability** | **HIGH** — the default instinct is to include Bar 0 for "latest data." |
| **Impact** | **CRITICAL** — repainting levels produce phantom trade signals. A backtest using repainting signals shows artificially high performance that does not reproduce in live trading. The entire validation becomes worthless. |
| **Historical Precedent** | Bug 2 (LESSONS_LEARNED §3, Bug 2): StructureEngine v2.1 BOS repainting. "A BOS would trigger when a tick broke a swing level during the active candle, then vanish if the price retraced before the candle closed." Fix: gate loop to `barIdx >= 1`. |
| **Detection Method** | 1. Grep for `barIdx = 0` or `barIdx >= 0` in all scan loops. 2. Log the minimum `barIndex` processed per analysis cycle. If any log shows `barIndex=0`, it is a violation. |
| **Mitigation Strategy** | 1. All scan loops: `for(int bar = startBar; bar >= 1; bar--)`. 2. `Analyze()` is gated by `IsNewBar()` which fires once per completed H4 bar. 3. All upstream data (swings, zones) is already from completed bars (guaranteed by frozen engines). |
| **Severity** | **CRITICAL** |

---

### H-02: Cumulative State Accumulation in Scoring

| Field | Detail |
|-------|--------|
| **Description** | If scoring components accumulate values across multiple analysis cycles without resetting, the scores will grow monotonically and never reflect current market conditions. |
| **Root Cause** | In StructureEngine v2.1, the trend classification used cumulative HH/HL/LH/LL counting across 300 bars. Once bullish labels accumulated, the trend was permanently locked. |
| **Probability** | **MEDIUM** — depends on whether `m_snrLevels[]` is cleared at the start of each `Analyze()` call. |
| **Impact** | **HIGH** — stale levels with inflated scores dominate the rankings. Fresh institutional activity is buried under historical noise. |
| **Historical Precedent** | Bug 1 (LESSONS_LEARNED §3, Bug 1): "Once TREND_BULLISH was confirmed, the trend state became permanently locked." Fix: reset to RANGE when consecutive pattern is interrupted. |
| **Detection Method** | Verify that `Analyze()` begins with `ArrayResize(m_snrLevels, 0)` and `ArrayResize(m_liquidityPools, 0)`. No level from a previous cycle should persist into the current cycle. |
| **Mitigation Strategy** | 1. `Analyze()` clears all output arrays at the start of every call. 2. Every level is reconstructed from scratch on each H4 bar close. 3. No `static` or persistent scoring state between analysis cycles. |
| **Severity** | **HIGH** |

---

### H-03: Reaction Count Inflation During Consolidation

| Field | Detail |
|-------|--------|
| **Description** | If the rejection distance scanner counts every consecutive bar touching a level as an independent rejection event, the rejection score will be inflated during sideways consolidation periods. |
| **Root Cause** | A 25-bar consolidation around a level would produce 25 "rejection" events, each with a near-zero excursion distance, deflating the average rejection distance to near-zero. This is the inverse of the original inflation bug — instead of inflating count, it deflates the average quality. |
| **Probability** | **HIGH** — XAUUSD frequently consolidates around institutional levels for extended periods. |
| **Impact** | **MEDIUM** — rejection scores are systematically biased. Fresh, strongly rejected levels have low scores because their single strong bounce is averaged with dozens of consolidation micro-bounces. |
| **Historical Precedent** | Bug 4 (LESSONS_LEARNED §3, Bug 4): "Swing points in sideways consolidation ranges accumulated absurdly high reaction counts (25 reactions) because every consecutive bar touching the price level was counted as an independent reaction event." Fix: `insideZone` state tracker. |
| **Detection Method** | Log rejection distance calculations: touch count, individual distances, and average. If any level shows >10 touches with average distance <0.1 ATR, consolidation grouping is not working. |
| **Mitigation Strategy** | Implement the identical `insideZone` boolean state tracker from [StructureEngine.mqh L701-721](../../src/engines/StructureEngine.mqh): count only zone re-entries, not consecutive touches. |
| **Severity** | **HIGH** |

---

### H-04: Age Subtraction Direction Error

| Field | Detail |
|-------|--------|
| **Description** | If freshness or age decay uses `currentBarIdx - zone.impulseBarIndex`, the result will be negative (in MT5's reverse-ordered index system), causing all zones to appear brand new. |
| **Root Cause** | MT5 bar indices are reverse-ordered: index 0 = current bar, index N = N bars ago. `currentBarIdx` (≈1) minus `impulseBarIndex` (≈100) = -99, clamped to 0. |
| **Probability** | **MEDIUM** — the correct direction (`impulseBarIndex - currentBarIdx`) is now documented, but a developer writing fresh code may not consult the lessons learned. |
| **Impact** | **HIGH** — all freshness-related scoring becomes non-functional. Every level appears equally fresh regardless of actual age. |
| **Historical Precedent** | Bug 6 (LESSONS_LEARNED §3, Bug 6): "All supply/demand zones maintained a flat 100% Age Score throughout their entire lifespan." Fix: reversed subtraction to `zone.impulseBarIndex - currentBarIdx`. |
| **Detection Method** | Log age values for all levels. If all ages are 0 or negative, the subtraction direction is wrong. Expected: ages range from 1 to 400+. |
| **Mitigation Strategy** | 1. Use `age = sourceBarIndex - currentBarIdx` consistently. 2. Add assertion: `if(age < 0) LogMessage("WARNING: Negative age detected")`. 3. Test with a concrete example: zone at bar 100, current bar 1 → age should be 99. |
| **Severity** | **HIGH** |

---

### H-05: Inclusive Boundary in Rejection Scan

| Field | Detail |
|-------|--------|
| **Description** | If the rejection distance scanner includes the invalidation bar in its scan range, the breach candle's price excursion will be counted as a "rejection," inflating the rejection distance for every invalidated zone by one data point. |
| **Root Cause** | The breach candle passes through the zone boundary (by definition). Its excursion distance is the break distance, not a rejection bounce. Including it in the average corrupts the metric. |
| **Probability** | **MEDIUM** — boundary handling is a known pitfall in this project. |
| **Impact** | **MEDIUM** — inflated rejection scores for invalidated zones, causing dead zones to rank higher than they should. |
| **Historical Precedent** | Bug 7 (LESSONS_LEARNED §3, Bug 7): "Every invalidated zone had its reaction count inflated by exactly +1 touch." Fix: `zone.invalidatedBar + 1` exclusive boundary. |
| **Detection Method** | Compare rejection data for invalidated vs. active zones. If invalidated zones systematically show higher rejection distances, the boundary is likely inclusive. |
| **Mitigation Strategy** | Use exclusive stop bar for all invalidated zones: `int stopBar = zone.isInvalidated ? zone.invalidatedBar + 1 : 1;`. The scanner processes down to `stopBar` but never touches the invalidation bar itself. |
| **Severity** | **MEDIUM** |

---

## 6. Validation Risks

---

### V-01: Worked Example Score Mismatch

| Field | Detail |
|-------|--------|
| **Description** | The architecture freeze document provides three worked examples with expected scores (50.0, 80.0, 63.0). If the implementation produces different scores, it is unclear whether the code or the spec is wrong. |
| **Root Cause** | The worked examples assume specific market conditions (zone creation times, reaction counts, ATR values) that may not exactly reproduce during a 4-year backtest. Additionally, the rejection distance formula in Example 3 uses a denominator of 2.0 ATR (not 1.0), which may be a typographical error. |
| **Probability** | **MEDIUM** — minor floating-point differences are expected; large deviations indicate bugs. |
| **Impact** | **MEDIUM** — if scores deviate by >5 points, the scoring formula implementation must be audited. |
| **Historical Precedent** | [LESSONS_LEARNED.md §4, Evidence Over Theory Principle](../../docs/core/LESSONS_LEARNED.md): "Analytical projections are hypotheses. Parser output from raw data is evidence." The 33.52% vs. 2.27% false positive discrepancy showed that projected calculations can be wildly wrong. |
| **Detection Method** | Identify the exact zones from worked examples in the backtest log. Compare computed scores against expected values. Allow ±2 point tolerance for rounding. |
| **Mitigation Strategy** | 1. Log full scoring breakdown per level: `S_Struct=X, S_SD=Y, S_Fresh=Z, S_Reject=W, S_Confl=V, Total=T`. 2. If deviation exceeds ±2 points, investigate each component score individually. 3. If the spec formula is ambiguous (Example 3 denominator), document the interpretation chosen. |
| **Severity** | **MEDIUM** |

---

### V-02: Backtest Does Not Complete (Crash or Timeout)

| Field | Detail |
|-------|--------|
| **Description** | The 4-year backtest (2022-2025, ~6,264 H4 bars) may crash or timeout if `Analyze()` takes too long per bar, or if a runtime error (divide-by-zero, array OOB) terminates the EA. |
| **Root Cause** | Performance risks (P-01, P-02) combined with unguarded edge cases (T-01, T-02) can cascade into a non-completing backtest. |
| **Probability** | **MEDIUM** — dependent on implementation quality. |
| **Impact** | **CRITICAL** — no backtest = no validation = no freeze. Sprint 3.0 cannot be completed. |
| **Historical Precedent** | [PROJECT_GENESIS.md §4.5](../../PROJECT_GENESIS.md): "Strategy Tester suffered severe lag or sync crashes during volatility calls." The ATR sync error caused functional failures during backtesting. |
| **Detection Method** | Run a short backtest first (2024.01.01 to 2025.12.31 — 2 years) to validate stability before the full 4-year run. Monitor for `ExpertRemove()` calls or Strategy Tester error messages. |
| **Mitigation Strategy** | 1. Test with 2-year backtest first. 2. Add try/catch-equivalent guards (MQL5: check return values, not exceptions) around all critical paths. 3. Log `Analyze()` execution time. 4. If timeout risk is high, reduce `InpInvalidatedLookback` from 150 to 100. |
| **Severity** | **CRITICAL** |

---

### V-03: Statistical Report Parser Mismatch

| Field | Detail |
|-------|--------|
| **Description** | The PowerShell/Python parser used to extract metrics from Strategy Tester logs may not correctly parse the new log format from `CSnrEngine`. If the parser misreads level counts, score distributions, or cluster widths, the validation report will be based on wrong numbers. |
| **Root Cause** | Each engine introduces its own log format. The parser must be updated to recognize `[CSnrEngine]` prefixed messages and the new field formats. |
| **Probability** | **MEDIUM** — parser updates are routine but error-prone. |
| **Impact** | **HIGH** — an incorrect statistical report could lead to freezing a buggy engine or rejecting a correct one. |
| **Historical Precedent** | [LESSONS_LEARNED.md §2, Lesson 2](../../docs/core/LESSONS_LEARNED.md): "The initial SupplyDemand report projected a 33.52% false positive rate. The actual verified rate was 2.27%." The projection error was caused by analytical methodology, not parser bugs, but the lesson applies: parser accuracy is critical. |
| **Detection Method** | Manually verify 5-10 log entries against parser output. Cross-check totals (e.g., parser reports 150 levels vs. manual count from log file). |
| **Mitigation Strategy** | 1. Use consistent log format: `[CSnrEngine] LEVEL | id=X score=Y.Y struct=Z sd=W fresh=V reject=U confl=T`. 2. Write the parser before the backtest. 3. Test the parser against synthetic log samples. |
| **Severity** | **HIGH** |

---

## 7. Regression Risks

---

### R-01: StructureEngine Output Change Detection

| Field | Detail |
|-------|--------|
| **Description** | If StructureEngine's output changes due to an accidental modification (even a whitespace change that recompiles), the SNR engine's input data changes, making all Sprint 3.0 validation non-reproducible. |
| **Root Cause** | The Git commit hash is the only mechanism ensuring source integrity. If the developer opens StructureEngine.mqh to "inspect" it and accidentally saves a change, the freeze is broken. |
| **Probability** | **LOW** — but the impact is catastrophic. |
| **Impact** | **CRITICAL** — all upstream statistical baselines (97.73% retest reliability, 246 zones, etc.) are invalidated. Sprint 3.0 validation numbers become meaningless. |
| **Historical Precedent** | [AGENT_CONSTITUTION.md §4](../../AGENT_CONSTITUTION.md): Frozen components require formal hotfix audit with 4-year revalidation to modify. |
| **Detection Method** | Before starting Sprint 3.0 coding, record SHA-256 hashes of both frozen engine files. Before every commit, verify hashes match: `Get-FileHash src\engines\StructureEngine.mqh`. |
| **Mitigation Strategy** | 1. Record file hashes in the Sprint 3.0 commit message. 2. Make upstream files read-only: `attrib +R src\engines\StructureEngine.mqh`. 3. Run `git diff src/engines/StructureEngine.mqh src/engines/SupplyDemandEngine.mqh` before every commit. |
| **Severity** | **CRITICAL** |

---

### R-02: TestStructure.mq5 / TestSupplyDemand.mq5 Integration Failure

| Field | Detail |
|-------|--------|
| **Description** | TestSnr.mq5 must include all three engines. If the include chain introduces naming conflicts (e.g., duplicate `input` parameter names) or compilation warnings from the frozen test EAs, the new test may not compile cleanly. |
| **Root Cause** | MQL5 `input` parameters are global. If StructureEngine declares `input int InpATRPeriod = 14;` and SnrEngine also declares a parameter with the same name, the compiler will reject the duplicate. |
| **Probability** | **HIGH** — both upstream engines have `input` parameters for ATR period, logging, etc. |
| **Impact** | **HIGH** — compilation failure or unintended parameter shadowing. A shadowed parameter means SnrEngine's ATR period silently uses StructureEngine's value. |
| **Historical Precedent** | Both StructureEngine (L218) and SupplyDemandEngine (implicitly via include) define `InpATRPeriod`. Adding a third engine with the same parameter name will cause a `duplicate declaration` error. |
| **Detection Method** | Compile immediately after Step 1 (scaffold with includes). If duplicate parameter errors appear, they will be caught at the earliest possible stage. |
| **Mitigation Strategy** | 1. Use unique prefixed input names for all SNR parameters: `InpSnr*` prefix (e.g., `InpSnrClusterToleranceATR`, `InpSnrEnableLog`). 2. Never re-declare parameters that already exist in upstream headers. 3. Compile after every step to catch conflicts early. |
| **Severity** | **HIGH** |

---

### R-03: Scoring Weight Sum Deviation

| Field | Detail |
|-------|--------|
| **Description** | The 5-weight scoring formula requires weights to sum to exactly 1.00 (`0.20 + 0.30 + 0.20 + 0.20 + 0.10 = 1.00`). If the weights are configurable inputs, a user may enter values that don't sum to 1.00, producing scores outside the [0, 100] range. |
| **Root Cause** | Exposing scoring weights as `input` parameters allows Strategy Tester optimization to explore weight combinations, but there is no runtime constraint enforcing the sum. |
| **Probability** | **MEDIUM** — during normal usage, defaults sum to 1.00. During optimization, random combinations will not. |
| **Impact** | **MEDIUM** — scores exceed 100 (false high confidence) or fall below theoretical minimum (missed levels). Comparison across runs with different weight sums is meaningless. |
| **Historical Precedent** | StructureEngine uses `InpScoreWeightDisplace + InpScoreWeightReaction + InpScoreWeightAge = 100` (sum to 100, then divide by total). This normalizes regardless of input values. |
| **Detection Method** | Assert at `Init()`: `if(MathAbs(totalWeight - 1.0) > 0.001) LogMessage("WARNING: Scoring weights do not sum to 1.00")`. |
| **Mitigation Strategy** | Normalize weights at runtime: `double totalW = W_Struct + W_SD + W_Fresh + W_Reject + W_Confl;` then divide each component by `totalW`. This guarantees scores in [0, 100] regardless of input values. Follow the pattern from [StructureEngine.mqh L728-729](../../src/engines/StructureEngine.mqh). |
| **Severity** | **MEDIUM** |

---

## Risk Summary Dashboard

| ID | Risk | Category | Probability | Impact | Severity |
|----|------|----------|-------------|--------|----------|
| **T-01** | ATR Division by Zero | Technical | HIGH | HIGH | **CRITICAL** |
| **T-02** | Array Index Out of Bounds | Technical | MEDIUM | HIGH | **HIGH** |
| **T-03** | Struct Member Initialization | Technical | HIGH | MEDIUM | **HIGH** |
| **T-04** | Floating-Point Precision | Technical | HIGH | MEDIUM | **HIGH** |
| **A-01** | Private Method Access | Architectural | HIGH | CRITICAL | **CRITICAL** |
| **A-02** | Frozen Engine Modification | Architectural | MEDIUM | CRITICAL | **CRITICAL** |
| **A-03** | Bidirectional Dependency | Architectural | LOW | CRITICAL | **HIGH** |
| **P-01** | Redundant Bar Scanning | Performance | HIGH | HIGH | **CRITICAL** |
| **P-02** | Dynamic Array Resizing | Performance | HIGH | MEDIUM | **MEDIUM** |
| **D-01** | Missing Reaction Coordinates | Data Dependency | CERTAIN | HIGH | **HIGH** |
| **D-02** | Missing BOS Origin Reference | Data Dependency | CERTAIN | MEDIUM | **MEDIUM** |
| **D-03** | Invalidated Zone Lookback | Data Dependency | MEDIUM | LOW | **LOW** |
| **H-01** | Bar 0 Repainting | Historical Bug | HIGH | CRITICAL | **CRITICAL** |
| **H-02** | Cumulative State Accumulation | Historical Bug | MEDIUM | HIGH | **HIGH** |
| **H-03** | Consolidation Reaction Inflation | Historical Bug | HIGH | MEDIUM | **HIGH** |
| **H-04** | Age Subtraction Direction | Historical Bug | MEDIUM | HIGH | **HIGH** |
| **H-05** | Inclusive Boundary in Scan | Historical Bug | MEDIUM | MEDIUM | **MEDIUM** |
| **V-01** | Worked Example Mismatch | Validation | MEDIUM | MEDIUM | **MEDIUM** |
| **V-02** | Backtest Crash/Timeout | Validation | MEDIUM | CRITICAL | **CRITICAL** |
| **V-03** | Parser Mismatch | Validation | MEDIUM | HIGH | **HIGH** |
| **R-01** | Upstream File Change | Regression | LOW | CRITICAL | **HIGH** |
| **R-02** | Input Parameter Naming Conflict | Regression | HIGH | HIGH | **HIGH** |
| **R-03** | Scoring Weight Sum | Regression | MEDIUM | MEDIUM | **MEDIUM** |

---

## CRITICAL Risk Count: 6

| # | Risk | Pre-Coding Guard |
|---|------|-----------------|
| 1 | T-01: ATR = 0 | `if(atr <= 0.0) continue;` on every ATR usage |
| 2 | A-01: Private access | Local ATR — never call `m_structureEngine.GetATRValue()` |
| 3 | A-02: Frozen modification | `git diff` before every commit; read-only file attributes |
| 4 | P-01: Performance | Gate by `IsNewBar()`; cap rejection scan; delta processing |
| 5 | H-01: Bar 0 repainting | All loops `barIdx >= 1`; never process uncompleted candles |
| 6 | V-02: Backtest crash | 2-year stability test before full 4-year run; guard all divisions |

---

> **This risk register must be consulted before writing each method.**
>
> Every CRITICAL risk has a pre-coding guard that must be implemented.
> Every HIGH risk has a detection method that must be verified in testing.
> Every historical bug risk has a corresponding lesson from LESSONS_LEARNED.md.
>
> **No code may be written until the project owner approves this risk register.**
