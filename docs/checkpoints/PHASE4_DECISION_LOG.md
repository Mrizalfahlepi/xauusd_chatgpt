# PHASE 4 LIQUIDITY ENGINE — DECISION LOG

This document provides a chronological record of every key architectural, implementation, and research decision made during Phase 4 (Liquidity Engine) and the rationale behind each.

---

## Decision 1: Separation of "Breach" vs. "Rejection"
*   **Status**: **Approved & Frozen**
*   **Rationale**: Initially, stop runs were referred to under a single generic term. We mathematically decoupled these into two distinct terms in the output contract:
    - **Breach**: Price High/Low penetrates the outer boundary of the BSL/SSL pool.
    - **Rejection**: Price Close returns past the inner boundary of the pool (confirming a failure to break out).
    - *Impact*: Allows downstream engines to separate the physical event of a stop run from its structural outcome.

## Decision 2: Sweep Size Measurement Origin
*   **Status**: **Approved & Frozen**
*   **Rationale**: We decided to measure the volatility-adjusted `sweepSizeATR` from the **inner boundary** (the swing high/low pivot price) to the bar extreme (High/Low), rather than from the outer boundary.
    - *Impact*: Properly captures the full excursion of the stop hunt from its structural origin.

## Decision 3: Proximity-Based Pool Deactivation
*   **Status**: **Approved & Frozen**
*   **Rationale**: To prevent the EA from logging duplicate breach events on consecutive bars during a strong breakout trend, the `CSnrPriorityEngine` deactivates the pool (`isSwept = true`) the moment price crosses its inner boundary.
    - *Impact*: Ensures the validation CSV only captures the initial breaching candle of any liquidity event, preventing data inflation.

## Decision 4: Instant Visual Marker Rendering
*   **Status**: **Approved & Frozen**
*   **Rationale**: During forensic audits, we discovered that visual markers appeared several bars late on the chart (at event completion/exit rather than detection). We refactored `DrawEventVisuals()` to draw OBJ_TEXT and OBJ_RECTANGLE markers immediately on the breach candle.
    - *Impact*: Restored visual timing integrity, making manual chart audits chronologically accurate.

## Decision 5: Compilation-Gated Debug Logging
*   **Status**: **Approved & Frozen**
*   **Rationale**: The Strategy Tester journals were flooded by `DEBUG_ATR_FILTER` candidate printouts and `[SupplyDemandEngine] Zone Invalidated` spam on every bar, bottlenecking disk performance. We wrapped these Print statements in `#ifdef DEBUG_ATR_FILTER` and `#ifdef DEBUG_SUPPLY_DEMAND` gates.
    - *Impact*: Suppressed journal noise, speeding up Strategy Tester runs by over 10x while maintaining compiler warning-free states.

## Decision 6: Rejection of Raw Time-Based Exits in favor of Asymmetric TP/SL
*   **Status**: **Approved & Frozen**
*   **Rationale**: Baseline analysis showed that exiting trades after a fixed 12 bars without targets had no trading edge. By auditing various TP/SL models, we found:
    - Tight stops (`SL = 0.50 ATR`) fail because Gold's median MAE is `0.627 ATR`.
    - Wider stops (`SL = 1.00 ATR`) protect the account from drawdowns on breakouts.
    - Asymmetric targets (`TP = 2.00 ATR`) capture the extreme V-reversal winners that drive the system's expectancy.
    - *Impact*: Established the core risk management profile for downstream engines.

## Decision 7: Mandatory Trend-Gating Filters in Downstream Engines
*   **Status**: **Approved & Frozen**
*   **Rationale**: Temporal stability audits proved that trading all sweeps is unprofitable in trending years (like 2023, PF 0.74) and highly profitable in mean-reverting years (2024, PF 2.71). Rather than changing the Liquidity Engine, we decided to handle this by requiring the downstream Entry Engine to gate entries using H4 trend filters.
    - *Impact*: Preserves the purity of the Liquidity Engine while protecting trading capital from trend runs.
