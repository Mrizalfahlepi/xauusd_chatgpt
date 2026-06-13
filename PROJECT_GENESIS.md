# PROJECT GENESIS - Master Project Bible

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED & FROZEN BASELINE  
**Current Version**: 2.3  
**Target Platform**: MetaTrader 5 (MQL5)

---

## 1. Vision

The XAUUSD Institutional Structure EA exists to eliminate the emotional bias and lagging latency of retail trading indicators. By mapping price action through institutional order blocks, structural swing points, support/resistance clustering, and liquidity pools, the EA aligns its execution with market makers and liquidity providers rather than against them. 

---

## 2. End Goal

The final production target is a fully automated portfolio execution system comprising a series of decoupled engines operating on a unidirectional data pipeline:

```
[StructureEngine] (H4)
       │ (Fractal swings, BOS/MSS, Trend classification)
       ▼
[SupplyDemandEngine] (H4)
       │ (Base-impulse consolidation blocks, Zone quality grading)
       ▼
[SnrEngine] (H4)
       │ (ATR-relative price clustering, Node conflict deactivation, 5-weight S/R scoring)
       ▼
[LiquidityEngine] (H4/M30) (Planned)
       │ (Identifies buy/sell stop liquidity pools above/below swing clusters)
       ▼
[EntryEngine] (M30) (Planned)
       │ (Refines H4 bias, validates entry setups e.g. engulfing, executes limits/market)
       ▼
[RiskEngine] (M30) (Planned)
       │ (Computes lot sizes based on stop-loss distance to maintain a fixed 1% account risk)
       ▼
[ExecutionEngine] (M30) (Planned)
       │ (Manages order routing, trailing stops, partial closes, and slippage controls)
       ▼
[Live Trading Deployment] (Production EA)
```

---

## 3. Architecture Evolution

### 3.1 StructureEngine v1.0
*   *Purpose*: Establish the baseline fractal-based swing point detection and basic trend classification.
*   *Why it existed*: To prove that H4 market structure could be mapped without ZigZag repainting.

### 3.2 StructureEngine v2.2 (Frozen)
*   *Purpose*: Eliminate repainting, reaction score leakage, and Strategy Tester lag.
*   *Why it existed*: Validation tests of v1.0 exposed critical bugs (BOS repainting on active ticks, trend lock, reaction count leaks). v2.2 corrected these, providing a stable, mathematically verified structure foundation.

### 3.3 SupplyDemandEngine v1.0
*   *Purpose*: Implement order block zone detection using impulse-base-displacement logic.
*   *Why it existed*: To locate institutional origin candles where major order flows enter the market.

### 3.4 SupplyDemandEngine v1.1 (Frozen)
*   *Purpose*: Resolve statistical anomalies discovered in the 4-year validation backtest.
*   *Why it existed*: Backtests of v1.0 revealed that age decay was inactive (negative age score capped at 0) and retest reactions were inflated by the invalidation candle. v1.1 resolved these issues, validating a 97.73% retest reliability rate.

### 3.5 Repository Refactor (Sprint 2.3)
*   *Purpose*: Normalize and clean up the root directory.
*   *Why it existed*: Sprints had generated diagnostic, temporary, and superseded documents. Refactoring organized these files into subdirectories (`/docs/core`, `/src/engines`, `/src/tests`), updating relative includes and links.

### 3.6 SNR Design Freeze
*   *Purpose*: Freeze the Support, Resistance, and Liquidity mapping architecture before coding.
*   *Why it existed*: To mathematically specify level clustering, zone merging, conflict node deactivation, and the 5-weight scoring model before writing a single line of MQL5.

---

## 4. Major Bugs Discovered

### 4.1 Trend Classification Locked to BULLISH (Structure v2.1)
*   **Problem**: Once `TREND_BULLISH` was confirmed, the trend state got permanently locked and never returned to `TREND_RANGE` or `TREND_BEARISH`.
*   **Root Cause**: The classification loop accumulated state cumulatively across all historical swings instead of tracking the consecutive nature of trend changes.
*   **Fix**: Rewrote the loop to check consecutive structures; trend resets to `RANGE` immediately when a swing breaks the consecutive pattern.
*   **Impact**: Responsiveness of trend classification is 100% accurate under live testing.

### 4.2 BOS/MSS Repainting on Bar 0 (Structure v2.1)
*   **Problem**: Break of Structure (BOS) lines repainted during live tests.
*   **Root Cause**: The scanner analyzed the active uncompleted H4 bar (`barIdx = 0`), which updates with every tick.
*   **Fix**: Gated the scan loop to completed bars only (`barIdx >= 1`).
*   **Impact**: Look-ahead and repainting biases are completely eliminated.

### 4.3 Swing Reaction Score Leak (Structure v2.1)
*   **Problem**: Invalidated swings continued to accumulate touches and strength scores after being broken.
*   **Root Cause**: `CountReactions()` scanned down to bar 1 regardless of invalidation, instead of stopping at the breaking candle index.
*   **Fix**: Reordered execution to run `DetectBOS` first, and terminated the retest scanner at the swing's `breakBarIndex`.
*   **Impact**: Score distribution is corrected; invalidated swings do not dominate rankings.

### 4.4 Reaction Score Inflation during Consolidation (Structure v2.1)
*   **Problem**: Retest counts inflated (e.g., to 15) when price consolidated around a swing level.
*   **Root Cause**: Every consecutive bar touching the level incremented the counter.
*   **Fix**: Implemented an `insideZone` state tracker to group consecutive touches into a single event.
*   **Impact**: Touch counts reflect true independent institutional retests.

### 4.5 MT5 Strategy Tester ATR Sync Error (Structure v2.1)
*   **Problem**: strategy Tester suffered severe lag or sync crashes during volatility calls.
*   **Root Cause**: Asynchronous calls to MetaTrader's `iATR` indicator handle bypassed local memory caches.
*   **Fix**: Coded a local synchronous ATR(14) calculator using cached H4 High/Low/Close arrays.
*   **Impact**: Strategy Tester runs smoothly and compiles with 100% data sync.

### 4.6 SupplyDemand Age Score Decay Defect (SupplyDemand v1.0)
*   **Problem**: Stale zones retained a flat 100% Age Score throughout their lifespan.
*   **Root Cause**: Age was calculated as `currentBarIdx - zone.impulseBarIndex` (resulting in negative age, which capped at 0).
*   **Fix**: Reversed the subtraction to `zone.impulseBarIndex - currentBarIdx`.
*   **Impact**: Active linear age decay is fully operational.

### 4.7 SupplyDemand Invalidation Bar Reaction Inflation (SupplyDemand v1.0)
*   **Problem**: Invalidated zones had their reaction count inflated by +1.
*   **Root Cause**: The retest scanner scanned down to `zone.invalidatedBar` (inclusive), counting the breach candle as a touch.
*   **Fix**: Stopped the scanner at `zone.invalidatedBar + 1` (exclusive).
*   **Impact**: Exposed the true 2.27% false positive rate (97.73% retest reliability).

---

## 5. Design Decisions

1.  **Fractal Swing Point Detection**: Abandoned ZigZag; implemented lookback N=3 fractal pivots finalized on bar close to prevent repainting.
2.  **ATR-relative Swing Grading**: Swings are classified as Major if their distance from the previous Major Swing exceeds $0.50 \times ATR$. All other swings are Minor (noise).
3.  **Local Synchronous ATR**: All engines calculate ATR locally to bypass MT5 tester asynchronous lag.
4.  **Base Consolidation Block**: Supply/Demand zones are drawn from 1 to 6 base candles preceding the impulse. Expansion stops if a previous impulse candle is hit.
5.  **Neutral Decision Nodes**: If a bearish Supply zone and a bullish Demand zone overlap, buy and sell entries are deactivated within that range until a closed H4 candle breaks outside.
6.  **New Volume Merge Priority**: When same-type zones merge, the creation time is reset to the newer zone if its impulse range or body dominance exceeds the old zone's metrics by $\ge 20\%$.

---

## 6. Current State

*   **Completed & Frozen**:
    *   Market Structure Engine (Module 1 v2.2) [FROZEN]
    *   Supply & Demand Engine (Module 2 v1.1) [FROZEN]
    *   SNR Consolidation Engine (Module 3 v1.0) [FROZEN]
    *   SNR Output Prioritization Engine (`CSnrPriorityEngine` v1.0) [FROZEN]
    *   Approved interface contract `SnrPriorityContract` [STABLE]
*   **Active**:
    *   Phase 4 — Liquidity Engine
*   **Next**:
    *   Build `LiquidityEngine.mqh` (Module 4 v1.0) to track swing liquidity pools and detect sweep run events.

---

## 7. Open Risks

1.  **Redundant Price History Scanning**:
    *   *Risk*: Multiple modules performing duplicate historical H4 scans can degrade Strategy Tester performance.
    *   *Mitigation*: Gate engine operations strictly on new H4 bar closes and cache results in memory.
2.  **ATR Volatility Compression**:
    *   *Risk*: Tight consolidations shrink ATR, causing minor pivots to be graded as Major swings.
    *   *Mitigation*: Enforce an absolute minimum ATR floor inside the logic.

---

## 8. Next Sprint

**Phase 4: Liquidity Engine Implementation**
*   **Goal**: Detect stop-loss pools residing above major swing highs (BSL) and below major swing lows (SSL) on H4/M30.
*   **Action**: Create `src/engines/LiquidityEngine.mqh` implementing:
    *   Tracking of active/swept BSL and SSL pools.
    *   Sweep detection logic (price breaks outer boundary and pulls back on close).
    *   Mapping results to downstream Entry Engine execution filters.
    *   Preserve backward compatibility with `SnrPriorityContract` inclusion.
