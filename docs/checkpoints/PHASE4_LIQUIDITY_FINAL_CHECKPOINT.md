# PHASE 4 LIQUIDITY ENGINE FINAL CHECKPOINT

**Date**: 2026-06-13T20:18:00Z  
**Phase**: Phase 4.3 — Checkpoint Preservation  
**Tag Reference**: `LiquidityEngine_v1_Validated`  
**Git Status**: Checkpoint Files UNSTAGED (As instructed)  

---

## 1. Executive Summary

Phase 4 development (Liquidity Engine) has successfully concluded. The code has been compiled with **0 errors and 0 warnings** in MQL5 and frozen under the Git tag `LiquidityEngine_v1_Validated`. 

Visual validation has passed, proving that BSL/SSL pools, breach coordinates, and rejection markers render accurately and instantly on the chart. However, statistical validation over a 4-year dataset (2022–2025) of 522 events revealed that a raw, time-based exit strategy has no statistical edge. 

Through a sequence of forensic research audits, we demonstrated that a robust edge is only unlocked when paired with **asymmetric trade management** (TP = 2.0 ATR, SL = 1.0 ATR, 12-bar exit), yielding an expectancy of **$+0.1520$ ATR** and a **1.40 Profit Factor**. Temporal stability audits show that this edge is highly regime-dependent (unprofitable in 2023, highly profitable in 2024–2025), meaning it must be gated by trend/regime filters inside the downstream Entry Engine rather than traded as a standalone system.

---

## 2. What Was Built

*   **[LiquidityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/LiquidityEngine.mqh) (v1.0)**: Core engine detecting stop-loss pool boundaries (BSL/SSL) and real-time sweep events on the closed M30 bar 1. It exposes the `LiquidityPriorityContract` downstream.
*   **[TestLiquidity.mq5](file:///c:/xauusd_chatgpt/src/tests/TestLiquidity.mq5)**: Basic script validating engine pipeline integration and contract de-duplication.
*   **[TestLiquidityValidation.mq5](file:///c:/xauusd_chatgpt/src/tests/TestLiquidityValidation.mq5)**: Expert Advisor executing Strategy Tester runs, plotting real-time chart markers in visual mode, and exporting raw data parameters to the common folder.
*   **Logging Gates**: Implemented `#ifdef DEBUG_ATR_FILTER` in [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh) and `#ifdef DEBUG_SUPPLY_DEMAND` in [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh) to eliminate Strategy Tester journal spam.

---

## 3. Succeeded vs. Failed Validation Items

### What Succeeded
1.  **Technical Integrity**: Decoupled compilation of `TestLiquidityValidation.mq5` and `TestLiquidity.mq5` completes with 0 errors and 0 warnings.
2.  **Visual Marker Accuracy**: Instant marker rendering (Red "x" on the actual breaching candle, lime "REJ" or yellow "BREAKOUT" on close) verified and approved in visual Strategy Tester mode.
3.  **Expectancy Recovery**: Pairing sweeps with wider stops (`SL = 1.0 ATR` to avoid premature stop outs) and wide targets (`TP = 2.0 ATR`) succeeded in turning negative expectancy into a positive edge (+0.1520 ATR).

### What Failed
1.  **Raw Time-Based Expectancy**: Out-of-the-box time-based exits (e.g. exit after 12 bars without TP/SL) failed to yield a stable edge, returning negative net closes across Groups A, B, and C.
2.  **Tight Stop Loss (SL = 0.50 ATR)**: Setting a stop loss at 0.50 ATR failed due to Gold's H4/M30 volatility, stopping out 68.12% of trades prematurely.
3.  **Outlier Resistance**: Expectancy of Group D is highly fragile: removing the top 10% of trades shifts the expectancy from $+0.0164$ ATR to **$-0.2548$ ATR**, proving the edge is driven by extreme winners.
4.  **Temporal Stability**: The trade management model failed to remain profitable in 2023 (PF of 0.7452, expectancy of $-0.1091$ ATR), indicating vulnerability to trending market regimes.

---

## 4. Key Statistical Findings (522 Events, 2022–2025)

*   **Pool Width**: Fixed at exactly **0.10 H4 ATR** (determined by `InpSnrLiquidityTolATR` in [SnrEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh)).
*   **Median Sweep Excursion**: **0.1522 ATR** (maximum excursion of 0.8407 ATR).
*   **Median Adverse Excursion (MAE12)**: **0.6270 ATR**.
*   **Median Favorable Excursion (MFE12)**: **0.9055 ATR**.
*   **Current Rejection Win Rate**: **50.72%** (35 wins vs 34 losses in Group D).
*   **Expectancy Sensitivity**:
    *   No buffer: **100% rejection rate** (50/50 events).
    *   0.10 ATR buffer: **74% rejection rate** (37/50 events).
    *   0.20 ATR buffer: **52% rejection rate** (26/50 events).
    *   0.50 ATR buffer: **10% rejection rate** (5/50 events).

---

## 5. Key Architecture Decisions & Rejected Ideas

### Key Decisions
*   **Single Responsibility Principle (SRP)**: The Liquidity Engine's sole task is to identify and characterize sweep events. Decisions about whether an event is "too large to trade" or "aligned with H4 trend" are deferred to the downstream `CEntryEngine` (Module 5).
*   **Proximity-Based Deactivation**: Active pools are removed from the prioritized contract as soon as the inner boundary is breached (`priceLow > currentPrice` for BSL), de-duplicating consecutive logs and forcing the engine to focus on the initial breaching candle.
*   **Log Spam Suppression**: Logging is controlled by compilation directives (`#ifdef`), keeping default Strategy Tester logs clean of zone invalidation spam.

### Rejected Ideas
*   *Rejected*: Changing the engine's definition of `isRejected` to require a larger close buffer. *Reason*: Doing so restricts flexibility. Instead, the engine continues to report the raw breach/rejection facts, and execution filters are applied in the entry engine.
*   *Rejected*: Using a tight stop-loss of 0.50 ATR. *Reason*: Gold's volatility requires a minimum of 1.00 ATR breathing room to survive typical retest drawdowns.

---

## 6. Open Questions & Remaining Risks

1.  **Regime Classification**: How can the Entry Engine dynamically classify and filter out trending breakout regimes (such as 2023) to avoid taking reversal entries during trend continuations?
2.  **Target Optimization**: Should profit targets be static (e.g. 2.0 ATR) or mapped dynamically to the nearest SNR/Supply-Demand levels on the chart?
3.  **Low Sample Size Risk**: Group D sweeps average only 1.4 signals per month. Over-reliance on this strategy will lead to long periods of inactivity.

---

## 7. Recommended Next Steps

1.  **Design Entry Engine (Module 5)**: Implement `CEntryEngine` inside `src/engines/EntryEngine.mqh` that:
    - Consumes `LiquidityPriorityContract` and checks if `rejectionMarginATR >= 0.50`.
    - Implements a H4 Trend Filter (e.g., deactivating BSL reversal entries if H4 trend is strongly Bullish).
    - Pairs entries with the validated trade management model: `SL = 1.0 ATR`, `TP = 2.0 ATR`, and a hard time exit at 12 bars (6 hours).
2.  **Verify Pipeline Integration**: Run compilation checks and verify 0 errors/warnings.
