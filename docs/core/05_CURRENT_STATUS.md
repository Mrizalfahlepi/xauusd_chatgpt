# 05_CURRENT_STATUS.md

Version: 2.4  
Date: 2026-06-13  
Status: Active  

---

## 1. Project Phase

### Current Phase: Phase 4 — Liquidity Engine (Active)
*   **Focus**: Implementing the Liquidity Engine to detect buy-side (BSL) and sell-side (SSL) stop-loss pools, and monitor liquidity sweep (Stop Run) events on H4 and M30.
*   **Entrance Criteria**: Complete integration, validation, and freezing of the Phase 3 SNR and Prioritization Engines (PASSED).

### Next Phase: Phase 5 — Trade Entry Engine
*   **Focus**: Building entry qualification filters, M30 setup validation (e.g. engulfing, pinbars), and signal generation.
*   **Entrance Criteria**: Liquidity Engine validation complete.

---

## 2. Engine Metrics (Strategy Tester Verification)

These metrics represent the verified output of the backtest conducted on **TestSnr.mq5** over the 3-month validation run (`2025.10.01` to `2025.12.31`):
*   **Total Consolidated Levels**: Filtered by $S_k \ge 50$ Quality Score.
*   **Prioritized Levels**: Restricted to a maximum of 3 structural support levels, 3 structural resistance levels, 3 tradable support levels (floors), and 3 tradable resistance levels (ceilings).
*   **ATR Distance Filter**: Checked and audited. Levels $> 5.0$ ATR distance correctly filtered out, or bypassed strictly via the nearest fallback mechanism.
*   **Compilation**: 0 Errors, 0 Warnings.

---

## 3. Active Parameter Configuration

These inputs govern the SNR Prioritization Layer:

```mql5
//--- Output Prioritization Parameters
input double InpMinPriorityScore        = 50.0;          // Priority: Minimum Quality Score (0-100)
input double InpMaxTradableDistanceATR  = 5.0;           // Priority: Maximum Tradable Distance (ATR)

//--- Display Profiles
enum ENUM_DISPLAY_MODE
{
   DISPLAY_DEV,      // Developer Mode: Render all details for debugging
   DISPLAY_ANALYST,  // Analyst Mode: Render all key levels (Score >= 50)
   DISPLAY_TRADER    // Trader Mode: Render only prioritized Top 3 levels and nearest BSL/SSL
};
input ENUM_DISPLAY_MODE InpDisplayMode  = DISPLAY_TRADER; // SNR: Visual display mode
```

---

## 4. Project Roadmap

```
Phase 1: Structure Engine (v2.2) ────────► 🟢 FROZEN
Phase 2: Supply & Demand Engine (v1.1) ──► 🟢 FROZEN
Phase 3: SNR Engine & Prioritizer ───────► 🟢 FROZEN (v1.0)
Phase 4: Liquidity Engine ───────────────► 🟡 ACTIVE PHASE
Phase 5: Entry Engine ───────────────────► ⚪ Planned
Phase 6: Risk Management ────────────────► ⚪ Planned
Phase 7: Portfolio Layer ────────────────► ⚪ Planned
Phase 8: Live Testing ──────────────────► ⚪ Planned
```

### Roadmap Details
1.  **Phase 1: Market Structure Engine (Complete & Frozen)**
    *   *Status*: v2.2 Frozen. Fractal Swing detection, ATR Swing grading, Trend mapping.
2.  **Phase 2: Supply & Demand Engine (Complete & Frozen)**
    *   *Status*: v1.1 Frozen. Impulse Base zones, decay, retests.
3.  **Phase 3: SNR Engine & Prioritizer (Complete & Frozen)**
    *   *Status*: v1.0 Frozen. Project levels clustered, neutral conflict nodes tracked, quality score mapped, and filtered/sorted via proximity into `SnrPriorityContract`.
4.  **Phase 4: Liquidity Engine (Active)**
    *   *Goals*: Detect stop-loss clusters (BSL/SSL) residing above/below swing points and track sweep runs.
5.  **Phase 5: Entry Engine (Planned)**
    *   *Goals*: Integrate priority contract, refine entry setups, generate execution orders.
6.  **Phase 6: Risk Management (Planned)**
    *   *Goals*: Fixed 1% risk lot size calculations.
7.  **Phase 7: Portfolio Layer (Planned)**
    *   *Goals*: Trailing stops, partial closures, break-even.
8.  **Phase 8: Live Trading Validation (Planned)**
    *   *Goals*: Demo/micro account testing.
