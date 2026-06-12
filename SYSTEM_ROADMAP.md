# SYSTEM ROADMAP

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED BASELINE  
**Workspace**: `c:\xauusd_chatgpt`

---

## Phase 1 — Structure Engine
*   **Purpose**: Detects fractal swing points (lookback N=3), grades major/minor swings via ATR price distance, identifies non-repainting BOS and MSS, and classifies market trend.
*   **Inputs**: Raw H4 price data (Open, High, Low, Close, Time).
*   **Outputs**: Graded swing points, BOS details, MSS events, current trend, and local H4 ATR(14) values.
*   **Dependencies**: None (baseline data ingestion layer).
*   **Status**: **FROZEN & VALIDATED (Version 2.2)**.

---

## Phase 2 — Supply Demand Engine
*   **Purpose**: Identifies institutional order block zones based on impulse-base-displacement logic. Tracks zone invalidation on closed H4 candles and counts retest reactions.
*   **Inputs**: `CStructureEngine` output arrays, H4 price data.
*   **Outputs**: `SupplyDemandZone` structures (boundaries, type, reactions, freshness, age decay, quality scores).
*   **Dependencies**: `CStructureEngine` (Module 1).
*   **Status**: **FROZEN & VALIDATED (Version 1.1)**.

---

## Phase 3 — SNR Engine
*   **Purpose**: Groups nearby swings and order blocks into consolidated horizontal support/resistance levels. Resolves zone conflicts and scores bands on a scale of 0-100.
*   **Inputs**: Active/invalidated swings from `CStructureEngine`, active/invalidated zones from `CSupplyDemandEngine`, and local ATR.
*   **Outputs**: Array of consolidated `SNRLevel` structures (sorted by score quality).
*   **Dependencies**: `CStructureEngine` (Module 1), `CSupplyDemandEngine` (Module 2).
*   **Status**: **APPROVED DESIGN FREEZE (Sprint 3.0 Next Implementation)**.

---

## Phase 4 — Liquidity Engine
*   **Purpose**: Identifies stop-loss clusters (liquidity pools) residing above major swing highs and below major swing lows. Tracks sweep events when price runs these pools.
*   **Inputs**: Major swings from `CStructureEngine`, H4 price data, and local ATR.
*   **Outputs**: Array of `LiquidityPool` structures (strength, coordinates, swept status).
*   **Dependencies**: `CStructureEngine` (Module 1).
*   **Status**: **PLANNED**.

---

## Phase 5 — Trade Entry Engine
*   **Purpose**: Refines the H4 structural bias on the M30 execution timeframe. Validates entry setups (e.g. engulfing, pinbars) and places limit or market orders.
*   **Inputs**: Consolidated `SNRLevel` array, H4 trend state, M30 price data, and current Bid/Ask.
*   **Outputs**: Trade signal coordinates (entry price, stop-loss, take-profit, and trigger type).
*   **Dependencies**: `CSnrEngine` (Module 3), `CLiquidityEngine` (Module 4).
*   **Status**: **PLANNED**.

---

## Phase 6 — Risk Management Engine
*   **Purpose**: Performs portfolio safety calculations. Determines lot sizes based on stop-loss distance, maintaining a fixed 1% risk per trade.
*   **Inputs**: Account balance, target risk percentage, trade entry signal, and stop-loss distance.
*   **Outputs**: Dynamic lot size (double).
*   **Dependencies**: `CEntryEngine` (Module 5).
*   **Status**: **PLANNED**.

---

## Phase 7 — Portfolio Layer
*   **Purpose**: Manages multiple trade coordinates. Handles trailing stops, break-even adjustments, partial profit-taking, and news-release deactivations.
*   **Inputs**: Account state, active MT5 positions, news calendar, and market ticks.
*   **Outputs**: Modification commands for active positions (SL/TP updates, partial closes).
*   **Dependencies**: `CRiskEngine` (Module 6).
*   **Status**: **PLANNED**.

---

## Phase 8 — Live Trading Validation
*   **Purpose**: Conducts extensive out-of-sample forward testing on demo and live micro-accounts. Verifies execution latency and confirms maximum drawdown does not exceed 10%.
*   **Inputs**: Integrated Master EA (`.mq5`), live broker feeds.
*   **Outputs**: Forward performance audit logs, equity curves.
*   **Dependencies**: All modules integrated.
*   **Status**: **PLANNED**.
