# PHASE 5 ENTRY ENGINE — DESIGN REVIEW SPRINT

**Author**: Design Review Agent  
**Date**: 2026-06-18  
**Phase**: Phase 5.0 — Pre-Implementation Design Review  
**Status**: AWAITING OWNER REVIEW  
**Prerequisite**: All Phase 4 checkpoint documentation read and validated  

> [!IMPORTANT]
> This document contains **zero code**, **zero implementation**, and **zero modifications** to frozen modules.  
> It is a pure analytical design review based exclusively on existing Phase 4 research findings.

---

## 1. REGIME HYPOTHESIS — Why Was 2023 Unprofitable While 2024 Was Highly Profitable?

### 1.1 The Core Evidence

From [GROUP_D_TEMPORAL_STABILITY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/reports/GROUP_D_TEMPORAL_STABILITY_AUDIT.md):

| Year | Events | Win Rate (Hit TP) | Expectancy (ATR) | Profit Factor | Verdict |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 2022 | 16 | 25.00% | +0.1331 | 1.2584 | ✅ Profitable |
| **2023** | **24** | **8.33%** | **-0.1091** | **0.7452** | **❌ Unprofitable** |
| **2024** | **18** | **22.22%** | **+0.4599** | **2.7181** | **✅ Outlier Year** |
| 2025 | 11 | 18.18% | +0.2452 | 1.9644 | ✅ Profitable |

The critical contrast: **2023 had the highest event count (24) but the lowest win rate (8.33%)**, meaning only 2 out of 24 Group D sweeps successfully hit the 2.0 ATR take-profit. In contrast, **2024 had 4 of 18 events hit TP (22.22%)**, with a profit factor nearly 4× higher.

### 1.2 Hypotheses Ranked by Probability

#### Hypothesis 1: H4 Trend Persistence (PROBABILITY: VERY HIGH — ~80%)

**Evidence**:
- The [GROUP_D_TEMPORAL_STABILITY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/reports/GROUP_D_TEMPORAL_STABILITY_AUDIT.md) Section 4.3 explicitly states: *"2023 was a trending year for Gold, where stop sweeps frequently failed and turned into continuation breakouts, whereas 2024 was highly mean-reverting, making sweeps highly profitable."*
- Gold rose from ~$1830 to ~$2065 in 2023 (directional expansion of >12%) before continuing to ~$2750 by end-2024. However, 2023's rally was largely unidirectional (Q1–Q4 steady climb), while 2024 featured large swings within a broader uptrend (corrections of $100–200 followed by new highs).
- The [PHASE4_EXECUTIVE_SUMMARY.md](file:///c:/xauusd_chatgpt/docs/checkpoints/PHASE4_EXECUTIVE_SUMMARY.md) Section 6 confirms: *"The 1.50 ATR breakout threshold in CLiquidityEngine is insufficient to protect trading capital from trending moves."*
- In a persistent H4 trend, BSL sweeps (shorts against the uptrend) get run over by continuation moves. The SL = 1.0 ATR gets hit rapidly because the sweep does not reverse — it accelerates. With 2023's strong bullish persistence, the majority of the 24 events would have been BSL sweeps producing counter-trend short entries that were immediately overwhelmed.

**Mechanism**: When H4 trend is persistently directional, liquidity sweeps above swing highs (BSL) are not stop hunts — they are genuine breakout continuations. The reversal trade enters short, and price continues expanding upward, hitting the 1.0 ATR stop loss. The rejection margin (≥ 0.50 ATR) is satisfied because the closing bar pulls back initially, but the *subsequent* 12 bars trend strongly against the position.

**Architectural Implication**: A filter that checks `CStructureEngine::GetCurrentTrend()` and blocks entries counter to the dominant H4 trend would have prevented the majority of 2023 losses.

---

#### Hypothesis 2: Mean-Reversion vs. Directional Expansion Environment (PROBABILITY: HIGH — ~70%)

**Evidence**:
- The [LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md) proves that the edge decays rapidly: Group D expectancy is +0.0164 ATR at 12 bars but drops to -0.1857 ATR at 24 bars. This decay pattern is consistent with a mean-reversion microstructure that only works when price oscillates around structural levels (range environment) and fails when price trends directionally away from the entry.
- The [GROUP_D_ROBUSTNESS_AUDIT.md](file:///c:/xauusd_chatgpt/docs/reports/GROUP_D_ROBUSTNESS_AUDIT.md) shows the median MFE12 is 0.9055 ATR (favorable) vs. median MAE12 of 0.6270 ATR (adverse). This 1.44 median E-ratio indicates that in typical conditions, price does initially move in the reversal direction — but in trending periods, the adverse excursion overwhelms the favorable one.

**Mechanism**: In mean-reverting years (2024), price sweeps liquidity and then oscillates back toward the mean, hitting the 2.0 ATR TP on the reversal spike. In trending years (2023), the initial rejection bounce is shallow and short-lived; price then continues in the trend direction, hitting the 1.0 ATR SL.

**Distinction from Hypothesis 1**: This hypothesis focuses on the *character* of price movement (oscillatory vs. directional) rather than just the H4 trend label. A market can be technically "bullish" on H4 trend classification yet still be mean-reverting if bullish swings oscillate around a climbing mean. The distinction matters for filter design.

---

#### Hypothesis 3: Volatility Regime Differences (PROBABILITY: MODERATE — ~50%)

**Evidence**:
- The [LIQUIDITY_REJECTION_SENSITIVITY_AUDIT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_REJECTION_SENSITIVITY_AUDIT.md) shows pool width is fixed at 0.10 ATR, and ATR values vary by year. If ATR was lower in 2023, the absolute pool width would have been narrower, potentially producing more false rejection signals.
- The [LIQUIDITY_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_STATISTICAL_REPORT.md) pool width in price points ranged from 0.4030 to 5.2660, confirming ATR varied substantially. Lower-volatility periods produce tighter absolute stops (SL = 1.0 ATR in a low-ATR environment = fewer points of buffer), which could be insufficient against trending excursions.

**Limitation**: We lack per-year ATR distribution data in the existing documentation. The hypothesis is plausible but cannot be ranked higher without direct evidence. The ATR normalization should in theory neutralize this effect (all metrics are ATR-relative), which weakens the hypothesis.

---

#### Hypothesis 4: Directional Sweep Asymmetry (PROBABILITY: MODERATE — ~40%)

**Evidence**:
- The [LIQUIDITY_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_STATISTICAL_REPORT.md) shows a slight SSL bias overall (54.60% SSL vs. 45.40% BSL). However, we lack per-year BSL/SSL splits.
- The [LIQUIDITY_OUTCOME_VALIDATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_OUTCOME_VALIDATION_REPORT.md) reveals a critical asymmetry: **BSL reversals (shorts) decay rapidly** (E-ratio 0.9451 at 12 bars, 0.8202 at 24 bars), while **SSL reversals (longs) remain stable** (E-ratio 0.9850 at 12 bars, 0.9886 at 48 bars).
- In a strongly bullish year (2023), the system would have generated many BSL sweep signals (shorting against the trend) with the weaker E-ratio profile, while the more robust SSL signals (which align with the bullish trend) were underrepresented.

**Mechanism**: In an uptrending year, stop pools above swing highs (BSL) are constantly swept by genuine breakouts. The system enters short, and the structurally weaker BSL reversal profile (rapid E-ratio decay) causes most trades to fail. Meanwhile, the few SSL sweeps that do form (dips into demand) would have been profitable, but insufficient to compensate.

---

#### Hypothesis 5: Liquidity Behavioral Regime Change (PROBABILITY: LOW-MODERATE — ~30%)

**Evidence**:
- The 2 non-rejected events in the entire 522-event dataset (both from 2022) show E-ratios of 3.56–6.46, proving that genuine breakouts are extremely powerful.
- In trending years, it is plausible that a higher proportion of sweeps that *technically* satisfy the rejection margin threshold (≥ 0.50 ATR on the closing bar) subsequently fail to sustain the reversal. The initial closing bar rejection is "real" but the follow-through reversal is not.
- The robustness audit proves the edge is dominated by 7 extreme V-reversal winners. If 2023's market microstructure produced fewer violent V-reversals (because trends were steady rather than choppy), the strategy would have bled.

**Limitation**: Without tick-level or per-event microstructure data from 2023 vs. 2024, this remains speculative.

---

### 1.3 Regime Hypothesis Summary

| Rank | Hypothesis | Probability | Testable with Existing Data? | Filter Implication |
|:---:|:---|:---:|:---:|:---|
| 1 | H4 Trend Persistence | ~80% | **Yes** — `GetCurrentTrend()` available | Block counter-trend entries |
| 2 | Mean-Reversion vs. Directional | ~70% | **Partially** — via BOS/MSS frequency | Require range or early-shift conditions |
| 3 | Volatility Regime | ~50% | **No** — per-year ATR data not in docs | ATR band filters |
| 4 | Directional Sweep Asymmetry | ~40% | **Partially** — BSL/SSL split per year not in docs | Direction-specific gating |
| 5 | Liquidity Behavioral Shift | ~30% | **No** — requires microstructure data | N/A |

---

## 2. ENTRY FILTER CANDIDATES

Below is every realistic filter candidate that could explain the difference between profitable and unprofitable periods, derived from the documented evidence.

---

### Filter 1: H4 Trend State Gate

| Attribute | Detail |
|:---|:---|
| **Rationale** | The `CStructureEngine` exposes `GetCurrentTrend()` → `TREND_BULLISH`, `TREND_BEARISH`, or `TREND_RANGE`. In bullish trend, BSL sweeps (shorts) are counter-trend and highly likely to fail; in bearish trend, SSL sweeps (longs) are counter-trend. Blocking counter-trend entries would have eliminated most 2023 losses. |
| **Expected Effect** | Remove ~50% of losing trades in trending years. Reduce signal frequency by ~30–50%. Dramatically improve PF in trending years (from 0.74 toward 1.5+). May slightly reduce profits in range years by occasionally blocking valid reversals near range boundaries. |
| **Architectural Location** | Entry Engine (`CEntryEngine`) — filter applied *before* generating a trade signal. |
| **Required Upstream Data** | `CStructureEngine::GetCurrentTrend()` — already available via frozen public interface. No modifications to frozen modules required. |
| **Implementation Complexity** | **LOW**. Single conditional check: `if(trend == TREND_BULLISH && sweepType == BSL) → block`. |

---

### Filter 2: Rejection Margin Threshold (≥ 0.50 ATR)

| Attribute | Detail |
|:---|:---|
| **Rationale** | The only group with positive expectancy. Groups A, B, and C all have negative expectancy across all horizons. This filter is already validated by [LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_EDGE_BY_REJECTION_STRENGTH.md). |
| **Expected Effect** | Reduces signal count from 522 to 69 events (87% reduction). Converts negative raw expectancy to +0.0164 ATR (pre-TP/SL) and +0.1520 ATR (with Model 5 TP/SL). |
| **Architectural Location** | Entry Engine (`CEntryEngine`) — computed from `LiquidityPriorityContract.bslSweepSizeATR` and pool boundaries. |
| **Required Upstream Data** | `LiquidityPriorityContract` fields: `bslSweepSizeATR`, `sslSweepSizeATR`, pool boundary coordinates, and current Close price. The rejection margin must be calculated as `closeDist - poolWidth`. |
| **Implementation Complexity** | **LOW**. Arithmetic calculation from existing contract fields. |

---

### Filter 3: Large Excursion Block (`isLargeExcursion`)

| Attribute | Detail |
|:---|:---|
| **Rationale** | The single large excursion event (>1.50 ATR sweep size) in 4 years suffered an E-ratio of 0.0975 (48-bar) and a net loss of -6.06 ATR. These are momentum breakouts, not reversals. [LIQUIDITY_OUTCOME_VALIDATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_OUTCOME_VALIDATION_REPORT.md) Section 2.3 provides mathematical proof. |
| **Expected Effect** | Blocks ~0.19% of events (extremely rare). Prevents catastrophic single-trade losses when a genuine breakout occurs. |
| **Architectural Location** | Entry Engine (`CEntryEngine`). |
| **Required Upstream Data** | `LiquidityPriorityContract.isLargeExcursion` — already exposed by frozen contract. |
| **Implementation Complexity** | **TRIVIAL**. Single boolean check. |

---

### Filter 4: Directional Alignment Filter (BSL vs. SSL E-ratio Asymmetry)

| Attribute | Detail |
|:---|:---|
| **Rationale** | BSL reversals (shorts) have a rapidly decaying E-ratio (0.9451 → 0.8202 → 0.8549 across horizons), while SSL reversals (longs) remain stable and strong (0.9850 → 0.9670 → 0.9886). This suggests shorts should be held for shorter durations or require stricter entry conditions. [LIQUIDITY_OUTCOME_VALIDATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/LIQUIDITY_OUTCOME_VALIDATION_REPORT.md) Section 2.1. |
| **Expected Effect** | Could improve system stability by applying asymmetric exit rules (shorter hold for shorts) or higher rejection margin thresholds for BSL entries. Risk: insufficient sample size per direction in Group D (34 BSL / 35 SSL) makes directional sub-analysis fragile. |
| **Architectural Location** | Entry Engine — different exit parameters or thresholds per sweep direction. |
| **Required Upstream Data** | Sweep type (BSL/SSL) already in `LiquidityPriorityContract`. |
| **Implementation Complexity** | **LOW-MODERATE**. Requires direction-dependent parameter branches. |

---

### Filter 5: BOS/MSS Recency Filter (Structural Freshness)

| Attribute | Detail |
|:---|:---|
| **Rationale** | A recent MSS (Market Structure Shift) indicates the H4 trend has just reversed. Sweeps that occur shortly after an MSS may represent the first leg of a new trend rather than a tradable reversal. Conversely, sweeps that occur deep inside an established trend (many bars since last BOS) are more likely to be genuine exhaustion sweeps. |
| **Expected Effect** | Uncertain. No direct statistical evidence in existing documentation. Would require new data collection to validate. |
| **Architectural Location** | Entry Engine — query `CStructureEngine::GetBOSEvent()` / `GetMSSEvent()` for recency. |
| **Required Upstream Data** | BOS/MSS event arrays from `CStructureEngine` — available via frozen public interface. |
| **Implementation Complexity** | **MODERATE**. Requires calculating temporal distance between sweep event time and most recent BOS/MSS. |

---

### Filter 6: Session/Time-of-Day Filter

| Attribute | Detail |
|:---|:---|
| **Rationale** | Gold exhibits different volatility and liquidity profiles across trading sessions (Asian, London, New York). Sweeps during the Asian session (low liquidity) may produce different reversal characteristics than sweeps during the NY session overlap (high liquidity). The [GROUP_D_ROBUSTNESS_AUDIT.md](file:///c:/xauusd_chatgpt/docs/reports/GROUP_D_ROBUSTNESS_AUDIT.md) event log shows timestamps spanning all sessions. |
| **Expected Effect** | Uncertain. No session-stratified analysis exists in current documentation. Could reduce noise but also reduce an already thin signal count (1.4/month). |
| **Architectural Location** | Entry Engine — time-based check on the sweep bar timestamp. |
| **Required Upstream Data** | Sweep bar `datetime` from `LiquidityPriorityContract` or from internal M30 bar time. No upstream modification needed. |
| **Implementation Complexity** | **LOW**. Simple hour-range check. |

---

### Filter 7: Dynamic TP Based on Nearest SNR Level

| Attribute | Detail |
|:---|:---|
| **Rationale** | The static TP = 2.0 ATR may overshoot in cases where a strong SNR resistance/support level exists between the entry and the TP target. A dynamic TP mapped to the nearest tradable SNR level could capture more wins (higher hit rate) at the cost of lower per-trade profit. [PHASE4_LIQUIDITY_FINAL_CHECKPOINT.md](file:///c:/xauusd_chatgpt/docs/checkpoints/PHASE4_LIQUIDITY_FINAL_CHECKPOINT.md) Section 6 raises this as an open question. |
| **Expected Effect** | Potentially increases win rate from 17.39% while reducing per-win ATR gain. Net effect on expectancy is unknown without simulation. Risk of overfitting to structural level placement. |
| **Architectural Location** | Entry Engine or Risk Engine — requires querying `SnrPriorityContract` for tradable levels. |
| **Required Upstream Data** | `SnrPriorityContract.tradableSupport[]` / `tradableResistance[]` — available via frozen interface. |
| **Implementation Complexity** | **MODERATE-HIGH**. Requires distance calculations between entry and multiple SNR levels, fallback logic when no levels exist within range. |

---

### Filter 8: ATR Absolute Magnitude Filter (Volatility Gate)

| Attribute | Detail |
|:---|:---|
| **Rationale** | If absolute H4 ATR drops below a threshold, the absolute dollar-value of TP/SL targets becomes too small to overcome spread and slippage costs. Conversely, extremely high ATR could indicate news-driven volatility where mean-reversion patterns break down. |
| **Expected Effect** | Uncertain. The ATR normalization in all existing research should neutralize this, but real execution involves fixed spreads in dollar terms. |
| **Architectural Location** | Entry Engine — check H4 ATR against min/max bounds. |
| **Required Upstream Data** | H4 ATR from `SnrPriorityContract.atr`. |
| **Implementation Complexity** | **LOW**. Simple range check. |

---

### Filter Summary Matrix

| # | Filter | Evidence Strength | Expected Impact | Complexity | Overfitting Risk |
|:---:|:---|:---:|:---:|:---:|:---:|
| 1 | H4 Trend State Gate | **Strong** | **High** | Low | Low |
| 2 | Rejection Margin ≥ 0.50 ATR | **Very Strong** | **Critical** | Low | Low |
| 3 | Large Excursion Block | **Very Strong** | Defensive | Trivial | None |
| 4 | Directional Alignment | Moderate | Moderate | Low-Moderate | Moderate |
| 5 | BOS/MSS Recency | Weak (no data) | Unknown | Moderate | High |
| 6 | Session/Time Filter | Weak (no data) | Unknown | Low | High |
| 7 | Dynamic TP via SNR | Speculative | Unknown | Moderate-High | High |
| 8 | ATR Magnitude Gate | Weak | Low | Low | Moderate |

---

## 3. ENTRY ENGINE RESPONSIBILITY REVIEW

### 3.1 Strict Responsibility Boundary

The Entry Engine is the **decision-making gatekeeper** between factual upstream intelligence (what happened) and actionable trade signals (what to do). It must enforce the boundary between observation and action.

| Responsibility | Belongs in Entry Engine? | Justification |
|:---|:---:|:---|
| **Trend Gating** | **YES** | The `CStructureEngine` reports the current trend state as a fact. The *decision* to block or allow entries based on trend is a trading decision, not a structural observation. This is the Entry Engine's core value-add over the raw liquidity signals. |
| **Rejection Margin Filter** | **YES** | The `CLiquidityEngine` reports the raw sweep size and breach/rejection status as facts. The *decision* to only trade sweeps ≥ 0.50 ATR is a trading parameter, not a detection parameter. The Liquidity Engine correctly reports all sweeps regardless of strength. |
| **TP Selection** | **YES** (target level) / **NO** (order execution) | The Entry Engine should determine the target price level (whether static 2.0 ATR or dynamic SNR-mapped). However, the actual order placement, modification, and management belongs in the Risk/Portfolio Engine (Phase 6/7). The Entry Engine outputs a `targetPrice`, not an `OrderSend()` call. |
| **SL Selection** | **YES** (stop level) / **NO** (order execution) | Same as TP. The Entry Engine determines the stop-loss price level (1.0 ATR from entry) and includes it in the output signal. Order execution is downstream. |
| **Session Filters** | **YES, if implemented** | Time-based gating is a trading decision. It does not belong in any upstream factual engine. However, implementing a session filter without statistical evidence is premature and risks overfitting. |
| **Volatility Filters** | **YES, if implemented** | ATR-based gating is a trading decision. Same caveat about evidence. |
| **Large Excursion Block** | **YES** | The Liquidity Engine reports `isLargeExcursion` as a factual flag. The *decision* to block entry on this flag is the Entry Engine's responsibility. |
| **12-Bar Time Exit** | **SPLIT** | The *trigger logic* (has 12 bars elapsed?) belongs in the Entry Engine or Trade Management. The *execution* (close the position at market) belongs in the Portfolio/Execution layer (Phase 7). |

### 3.2 What Does NOT Belong in Entry Engine

| Responsibility | Why NOT Entry Engine | Where It Belongs |
|:---|:---|:---|
| Sweep detection logic | Frozen in `CLiquidityEngine` | Phase 4 (Frozen) |
| Pool boundary calculation | Frozen in `CSnrEngine` | Phase 3 (Frozen) |
| Trend classification algorithm | Frozen in `CStructureEngine` | Phase 1 (Frozen) |
| Lot sizing | Risk management domain | Phase 6 (Risk Engine) |
| Order placement (`OrderSend`) | Execution domain | Phase 7 (Portfolio Layer) |
| Trailing stop management | Trade management domain | Phase 7 (Portfolio Layer) |
| Spread/commission calculations | Execution cost domain | Phase 6/7 |

### 3.3 Entry Engine Output Contract (Conceptual)

The Entry Engine should output a struct containing:

```
EntrySignal
{
   bool      isValid;              // Is this a tradable signal?
   bool      isBuy;                // Long or Short?
   double    entryPrice;           // Recommended entry price
   double    stopLossPrice;        // SL price (entry ± 1.0 ATR)
   double    takeProfitPrice;      // TP price (entry ± 2.0 ATR)
   int       maxBarsToHold;        // Time-decay exit (12 bars)
   datetime  signalTime;           // When the signal was generated
   string    signalReason;         // Human-readable trigger description
   double    rejectionMarginATR;   // For logging/audit purposes
   ENUM_TREND_STATE trendAtEntry;  // For post-trade analysis
}
```

This struct is consumed by the Risk Engine (Phase 6) to size the position and by the Portfolio Layer (Phase 7) to place and manage the order.

---

## 4. PHASE 5 DESIGN OPTIONS

### Option A: Minimalist

**Philosophy**: Implement only what has strong statistical backing. No speculative filters.

| Attribute | Detail |
|:---|:---|
| **Filters Included** | (1) Rejection Margin ≥ 0.50 ATR, (2) Large Excursion Block, (3) H4 Trend Gate (binary: block counter-trend) |
| **TP/SL** | Static: TP = 2.0 ATR, SL = 1.0 ATR |
| **Time Exit** | Hard 12-bar close |
| **No filters** | No session, no volatility gate, no dynamic TP, no BOS/MSS recency, no directional asymmetry |

| Assessment | Detail |
|:---|:---|
| **Advantages** | Fastest to implement and validate. Minimal overfitting risk. All three filters have strong documented evidence. Maintains the spirit of the project's anti-lagging-indicator philosophy. Clean, auditable, minimal parameters. |
| **Disadvantages** | Does not exploit the BSL/SSL E-ratio asymmetry. Does not address low signal frequency (~1.4/month before trend filter, possibly <1/month after). Does not account for nuanced regime differences beyond binary trend state. |
| **Overfitting Risk** | **VERY LOW**. Only uses 3 well-documented filters with clear causal mechanisms. |
| **Expected Signal Frequency** | ~0.7–1.0 signals/month (the trend gate will eliminate ~30–50% of the already thin 1.4/month Group D events). |

---

### Option B: Balanced

**Philosophy**: Include evidence-backed filters plus one structurally justified enhancement.

| Attribute | Detail |
|:---|:---|
| **Filters Included** | All of Option A, plus: (4) Directional Alignment (different exit rules for BSL vs. SSL based on E-ratio asymmetry) |
| **TP/SL** | Static baseline: TP = 2.0 ATR, SL = 1.0 ATR. SSL (longs) may use extended hold window (up to 24 bars) based on the stable E-ratio documented in the outcome validation report. |
| **Time Exit** | BSL reversals: 12-bar exit. SSL reversals: 18–24-bar exit (exploiting the more durable E-ratio). |
| **No filters** | No session, no volatility gate, no dynamic TP, no BOS/MSS recency |

| Assessment | Detail |
|:---|:---|
| **Advantages** | Exploits the documented BSL/SSL asymmetry (BSL E-ratio decays fast; SSL E-ratio stays stable). Could increase the capture rate on SSL reversals (which are structurally more robust) without increasing risk. Adds minimal complexity over Option A. |
| **Disadvantages** | The directional asymmetry evidence comes from the full 522-event dataset (not Group D specifically). Applying full-dataset statistics to a 69-event subset introduces risk. The BSL/SSL split within Group D is nearly even (34/35), so the sub-sample is tiny per direction (~17 events per direction). |
| **Overfitting Risk** | **LOW-MODERATE**. The directional asymmetry is documented but not validated at the Group D level specifically. One additional parameter (exit duration per direction) adds a degree of freedom. |
| **Expected Signal Frequency** | Same as Option A (~0.7–1.0/month). The extended hold window for SSL does not create new signals; it modifies trade management on existing ones. |

---

### Option C: Research-Oriented

**Philosophy**: Build an instrumented Entry Engine that collects data for filter validation, but does not trade aggressively. Designed for forward-validation, not immediate profit.

| Attribute | Detail |
|:---|:---|
| **Filters Included** | All of Option A. Additionally, **logs but does not act on**: (4) Session metadata, (5) BOS/MSS recency, (6) ATR magnitude, (7) Nearest SNR distance to TP target |
| **TP/SL** | Static: TP = 2.0 ATR, SL = 1.0 ATR (conservative) |
| **Time Exit** | Hard 12-bar close |
| **Data Collection** | Exports a comprehensive CSV on every signal (accepted or rejected) containing: trend state, BOS/MSS recency, session hour, ATR value, nearest SNR distance, rejection margin, sweep direction, and 12/24/48-bar outcomes. |

| Assessment | Detail |
|:---|:---|
| **Advantages** | Produces the dataset needed to statistically validate Filters 4–8 before committing to them. Prevents premature optimization. Respects the project's evidence-driven philosophy. After a 6–12 month forward collection period, the data can be analyzed to decide which additional filters actually improve the edge. |
| **Disadvantages** | Delays the full deployment of the trading system. Does not exploit potentially valid enhancements. The low signal frequency (1.4/month) means 6–12 months yields only ~8–17 data points, which is still statistically thin. The system is essentially a research tool, not a trading tool, during this period. |
| **Overfitting Risk** | **LOWEST**. The trading logic is identical to Option A. Data collection adds no parameters. |
| **Expected Signal Frequency** | Same as Option A for actual trades (~0.7–1.0/month). All events (including blocked ones) are logged for research. |

---

### Design Options Comparison Table

| Dimension | Option A (Minimalist) | Option B (Balanced) | Option C (Research) |
|:---|:---:|:---:|:---:|
| Filters | 3 | 4 | 3 active + 4 logged |
| Parameters | 4 (margin threshold, TP, SL, exit bars) | 6 (+direction-specific exits) | 4 active + CSV columns |
| Overfitting Risk | Very Low | Low-Moderate | Lowest |
| Time to Implement | ~1–2 days | ~2–3 days | ~3–4 days |
| Time to Validate | Immediate (backtest) | Immediate (backtest) | 6–12 months (forward) |
| Signal Frequency | ~0.7–1.0/month | ~0.7–1.0/month | ~0.7–1.0/month |
| Data Collection | None | None | **Full instrumentation** |
| Trading Readiness | **Immediate** | **Immediate** | Delayed |

---

## 5. GO / NO-GO REVIEW

### Should Entry Engine Implementation Begin Immediately?

**CONDITIONAL GO.**

Entry Engine implementation should begin, but with a **specific scope restriction**.

### Justification

#### Evidence Supporting GO:

1. **Phase 4 issued an explicit GO decision** ([PHASE4_EXECUTIVE_SUMMARY.md](file:///c:/xauusd_chatgpt/docs/checkpoints/PHASE4_EXECUTIVE_SUMMARY.md) Section 9).

2. **Three filters have overwhelming statistical evidence** and require no additional research:
   - Rejection Margin ≥ 0.50 ATR (documented across 5 research reports)
   - Large Excursion Block (mathematical proof in outcome validation report)
   - H4 Trend Gate (the single highest-probability regime hypothesis, supported by multiple documents)

3. **All required upstream data is available** through frozen public interfaces:
   - `CStructureEngine::GetCurrentTrend()` → `ENUM_TREND_STATE`
   - `LiquidityPriorityContract` fields (breach/rejection/sweep size/large excursion)
   - `SnrPriorityContract` fields (pool boundaries for margin calculation)

4. **No frozen modules need modification.** The Entry Engine is a new class consuming existing contracts.

#### Evidence Requiring Caution:

1. **The edge is not robustly validated as a standalone system.** The temporal stability audit proved that the first half (2022–2023) was net unprofitable, and the edge is outlier-dependent. The trend gate is hypothesized — not proven — to solve this.

2. **Signal frequency will be extremely low.** After trend gating, the system may produce fewer than 1 signal per month. This is commercially impractical as a standalone strategy but acceptable as one component of a larger system.

3. **Filters 4–8 lack statistical validation.** Implementing them without evidence violates the project's evidence-driven philosophy.

### Recommendation

> [!IMPORTANT]
> **Implement Option A (Minimalist) as the v1.0 Entry Engine, combined with Option C's data collection instrumentation.**

This means:
- **Trade with**: Rejection Margin ≥ 0.50 ATR + Large Excursion Block + H4 Trend Gate
- **Collect data for**: Session, BOS/MSS recency, ATR magnitude, SNR proximity (logged but not acted on)
- **Do NOT implement**: Directional asymmetry exits, dynamic TP, session filters, or any other speculative filter

This approach:
- Respects the evidence boundary (only proven filters trade real capital)
- Builds the dataset needed to validate future enhancements
- Is implementable in 2–3 days
- Can be backtested immediately against the existing 4-year dataset
- Adds zero overfitting risk to the trading logic

### What Unresolved Uncertainty Still Exists

| Uncertainty | Impact | Mitigation |
|:---|:---|:---|
| Trend gate effectiveness is hypothesized, not proven | Could reduce profits in range years while not fully preventing trending-year losses | Backtest Option A against 2022–2025 data before going live |
| Signal frequency after trend gating is unknown | Could drop below commercial viability | Accept as research finding; do not relax filters to artificially increase frequency |
| BSL/SSL asymmetry at Group D level is unknown | May be leaving value on the table by not exploiting it | Collect directional outcome data in Option C instrumentation |
| Dynamic TP effectiveness is unknown | Static TP may overshoot SNR barriers | Log nearest SNR distance for future analysis |
| The dataset (69 events) is too small for sub-stratification | Any additional filter risks overfitting to noise | Keep filter count minimal; rely on forward data collection |

---

*End of Phase 5.0 Design Review Sprint.*
