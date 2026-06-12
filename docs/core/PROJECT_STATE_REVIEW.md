# PROJECT_STATE_REVIEW.md

Version: 1.1  
Date: 2026-06-12  
Status: Complete  

---

## 1. Current Project Phase
*   **Sprint 2.2: SupplyDemand Statistical Hotfix & Revalidation (Completed)**.
*   The Market Structure Engine (Module 1) is debugged, backtest-verified, and frozen under version **v2.2**.
*   The Supply & Demand Engine (Module 2) is debugged, backtest-verified, and frozen under version **v1.1** (hotfixed for Age Score decay and Invalidation Bar reaction inflation).
*   The project is transitioning to **Sprint 3.0: SNR Engine (Phase 3)**.

---

## 2. Completed Modules
*   **Module 1: Market Structure Engine (Version 2.2)**
    *   *Features*: Fractal swing detection, ATR-relative swing grading, chronological BOS and MSS tracking, consecutive trend classification, capped/grouped swing reaction scores, and local synchronous ATR(14) calculation.
    *   *Status*: Frozen & Production-Ready.
*   **Module 2: Supply & Demand Engine (Version 1.1)**
    *   *Features*: Chronological impulse detection (ATR range >= 2.0, body >= 60%), 1-6 base candle expansion, chronological invalidation tracking on H4 candle closes, and 5-metric zone scoring framework (with corrected age decay and non-inflated retests).
    *   *Status*: Frozen & Production-Ready. Strategy Tester validation passed over a 4-year backtest (2022-2025) with a 97.73% retest reliability rate (2.82 average reactions, 2.27% true false positive rate).

---

## 3. Open Risks
*   **Time-Separation / Pro-Cyclical Swing Grading**: Swing grading is based purely on ATR price distance (`dist >= InpMinSwingDistATR * ATR`). During periods of extreme volatility compression, ATR shrinks, making the threshold small, which allows minor noise to be graded as Major swings. Conversely, during sudden volatility expansion, valid structural swings might be classified as Minor.
*   **Independent High/Low Array Alignment**: Major highs and lows are processed in separate arrays. If the market forms multiple consecutive Major Highs without an intervening Major Low, the HH/LH/HL/LL labeling depends on the chronological order. There is a risk of label misalignment in highly anomalous markets without a strict alternating check.

---

## 4. Technical Debt
*   **Unused ATR Indicator Handle**: Inside `StructureEngine.mqh`, the `iATR` indicator handle (`m_atrHandle`) is still initialized in `OnInit()` and created via `iATR()`. However, `GetATRValue()` was refactored to compute ATR locally and synchronously from cached price arrays to fix Strategy Tester sync gaps. The unused handle logic represents dead code.
*   **Hardcoded Print Versions**: In `TestStructure.mq5` (line 471), the terminal print summary statement is hardcoded to print `STRUCTURE ENGINE v2.1 SUMMARY` instead of dynamically outputting the current class version (`v2.2`).

---

## 5. What is Frozen
*   **Module 1 Core Logic (v2.2)**: Swing detection, consecutive trend classification, non-repainting BOS validations, and invalidation-capped reaction counts are frozen.
*   **Module 2 Core Logic (v1.1)**: Base consolidation block (1-6 candles), impulse verification, chronological invalidations, linear age decay, and invalidation-excluded reaction counts are frozen.
*   **Core Architectural Boundaries**: The data flow is strictly unidirectional: `Structure → Supply Demand → SNR → Entry → Risk → Execution`. Lagging indicator entries (RSI, MACD) and high-risk trading systems (Martingale, grid, averaging down) remain strictly prohibited.

---

## 6. What Can Still Change
*   **Sensitivity Parameters (Inputs)**: Swings, BOS, and MSS counts can be tuned via inputs. S/D zone detection multipliers and score weights can also be tuned if needed in later testing.
*   **Future Modules**: Modules 3 through 8 (SNR, Liquidity, Entry, Risk, Trade Management) are not yet implemented and are subject to design and code iterations.

---

## 7. Recommended Next Sprint
*   **Sprint 3.0: SNR Engine**
    *   *Objective*: Implement zone-based horizontal support/resistance levels calculated using reaction, rejection, and freshness scores.
    *   *Key Tasks*:
        1. Parse and aggregate frozen Structure v2.2 and SupplyDemand v1.1 events.
        2. Implement SNR scoring algorithms based on historical retests, depth of rejections, and freshness.
        3. Define Liquidity pool areas (high-density zone clusters).
        4. Validate SNR levels and liquidity pools using chart visualization objects.
