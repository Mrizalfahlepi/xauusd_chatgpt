<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1f6feb,50:8957e5,100:FFD700&height=220&section=header&text=XAUUSD%20Institutional%20Structure%20EA&fontSize=38&fontColor=ffffff&fontAlignY=38&desc=Trade%20the%20structure.%20Respect%20the%20freeze.%20Manage%20the%20risk.&descAlignY=60&descSize=18" width="100%" alt="XAUUSD Institutional Structure EA"/>

### A multi-engine algorithmic trading system that reads the market like a market maker — not a retail indicator.

<br/>

![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-1f6feb?style=for-the-badge&logo=tradingview&logoColor=white)
![Language](https://img.shields.io/badge/Language-MQL5-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Instrument](https://img.shields.io/badge/Instrument-XAUUSD%20(Gold)-FFD700?style=for-the-badge&logo=bitcoinsv&logoColor=black)
![Timeframe](https://img.shields.io/badge/Bias-H4-8957e5?style=for-the-badge)

![Status](https://img.shields.io/badge/Genesis-FROZEN%20BASELINE%20v2.4-2ea043?style=flat-square)
![Module 1](https://img.shields.io/badge/Structure%20Engine-v2.2%20FROZEN-2ea043?style=flat-square)
![Module 2](https://img.shields.io/badge/Supply%2FDemand-v1.1%20FROZEN-2ea043?style=flat-square)
![Module 3](https://img.shields.io/badge/SNR%20Engine-v1.0%20FROZEN-2ea043?style=flat-square)
![Module 3.4](https://img.shields.io/badge/Priority%20Engine-v1.0%20FROZEN-2ea043?style=flat-square)

</div>

---

## ❄️ CURRENT PROJECT STATUS

> [!IMPORTANT]
> **Current Phase**: Phase 4 — Liquidity Engine  
> **Frozen Modules**:  
> * `StructureEngine` (v2.2)  
> * `SupplyDemandEngine` (v1.1)  
> * `SnrEngine` (v1.0)  
> * `CSnrPriorityEngine` (v1.0)  
>
> **Stable Interface Contract**: `SnrPriorityContract`  
> **Next Milestone**: Phase 4 — Liquidity Engine  
>
> **CRITICAL ARCHITECTURAL CONSTRAINTS**:  
> 1. **Sprint 3 (Consolidation & Prioritization) is strictly frozen.** No redesign or modifications allowed for the scoring logic or engine code.  
> 2. **No redesign of `SnrPriorityContract`.** Its interface is locked.  
> 3. **Backward compatibility is mandatory** for all includes and data contracts.

---

> [!NOTE]
> **TL;DR** — This project builds a fully automated XAUUSD trading system for MetaTrader 5 out of a chain of small, decoupled, mathematically-verified engines. Each engine does **one** job, passes its output to the next, and is **frozen** only after it survives a multi-year validation backtest. No magic indicators. No emotional bias. Just market structure, supply/demand, liquidity, and disciplined risk.

---

## 📖 The Story Behind the Code

Most retail trading bots fail for the same reason: they chase **lagging indicators** (RSI, MACD, moving-average crossovers) that describe what already happened. By the time they fire, the institutional move is over — and the retail trader is the exit liquidity.

This EA flips the table. Instead of reacting to indicators, it **maps the footprints of the market makers**:

- Where did the big orders enter the market? → **Order Blocks (Supply & Demand)**
- Where is the market structurally heading? → **Swing structure, BOS & MSS**
- Where are the stop-losses piled up waiting to be hunted? → **Liquidity Pools**
- How much can we afford to lose if we are wrong? → **Fixed-risk position sizing**

The goal is alignment: trade **with** the liquidity providers, not against them.

---

## 🎯 Vision & End Goal

The final production target is a fully automated portfolio execution system built as a **unidirectional data pipeline** — each engine consumes the output of the one above it and produces a cleaner, higher-level signal for the one below.

```
                    ┌──────────────────────────┐
   Raw H4 OHLC ───► │   1. StructureEngine (H4) │  Fractal swings · BOS/MSS · Trend
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │ 2. SupplyDemandEngine (H4)│  Order blocks · Zone quality grading
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │   3. SnrEngine (H4)       │  ATR clustering · 5-weight S/R scoring
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │ 4. LiquidityEngine (H4/M30)│ Buy/sell-stop pools · Sweep events
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │   5. EntryEngine (M30)    │  Bias refinement · Setup validation
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │   6. RiskEngine (M30)     │  Lot sizing · Fixed 1% account risk
                    └────────────┬─────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │ 7. ExecutionEngine (M30)  │  Order routing · Trailing · Partials
                    └────────────┬─────────────┘
                                 ▼
                       🚀  Live Trading Deployment
```

---

## 🧩 The Engine Pipeline

| # | Engine | Timeframe | Responsibility | Status |
|:-:|--------|:---------:|----------------|:------:|
| 1 | **Structure Engine** | H4 | Fractal swing detection, ATR-graded major/minor swings, non-repainting BOS & MSS, trend classification | 🟢 **Frozen v2.2** |
| 2 | **Supply & Demand Engine** | H4 | Impulse-base-displacement order blocks, invalidation tracking, retest counting, quality scoring | 🟢 **Frozen v1.1** |
| 3 | **SNR Engine & Prioritizer** | H4 | Cluster swings + order blocks into consolidated bands, filter by Quality Score and ATR distance, output bounded contract | 🟢 **Frozen v1.0** |
| 4 | **Liquidity Engine** | H4/M30 | Detect stop-loss clusters above/below swings, track sweep events, stop run tagging | 🟡 **Active Phase** |
| 5 | **Entry Engine** | M30 | Refine H4 bias, validate setups (engulfing, pinbar), place limit/market orders | ⚪ Planned |
| 6 | **Risk Engine** | M30 | Compute lot size from SL distance to maintain fixed 1% risk | ⚪ Planned |
| 7 | **Portfolio / Trade Mgmt** | M30 | Trailing stops, break-even, partial closes, news deactivation | ⚪ Planned |
| 8 | **Live Validation** | — | Forward testing on demo/micro accounts, drawdown ≤ 10% | ⚪ Planned |

---

## 🔬 Engineering Philosophy: Freeze What Works

This is not "vibe-coded and hope." Every engine goes through a brutal lifecycle:

```
  DESIGN  ──►  BUILD  ──►  VALIDATE (multi-year backtest)  ──►  FIX BUGS  ──►  ❄️ FREEZE
```

Once an engine is **frozen**, it becomes part of the immutable foundation. New work builds *on top* of it, never *inside* it. The repository even treats its own documentation as the **Source of Truth** — chat history is explicitly *not* authoritative.

> [!IMPORTANT]
> **Why freezing matters:** in a pipeline architecture, an unstable lower engine corrupts every signal above it. Freezing guarantees that when the Entry Engine misbehaves, the bug is in the Entry Engine — not silently leaking from Structure three layers down.

---

## 🐛 Battle Scars: Bugs Hunted & Killed

Real systems are forged by the bugs they survive. A few highlights from the validation phase:

| Bug | Symptom | Root Cause | Fix |
|-----|---------|-----------|-----|
| **Trend lock** | Trend stuck on `BULLISH` forever | State accumulated cumulatively across all swings | Track *consecutive* structure; reset to `RANGE` on a break |
| **BOS repaint** | Break-of-structure lines redrawn live | Scanner read the active, unfinished bar 0 | Gate scan to completed bars (`barIdx >= 1`) |
| **Reaction leak** | Dead swings kept gaining strength | Retest scan ignored invalidation | Run `DetectBOS` first, stop scan at break bar |
| **Reaction inflation** | Retest count ballooned to 15 in consolidation | Every touching bar incremented the counter | `insideZone` tracker groups touches into one event |
| **ATR sync crash** | Strategy Tester lagged / crashed | Async calls to MT5's `iATR` handle | Local synchronous ATR(14) from cached arrays |
| **Age decay defect** | Stale zones held a flat 100% age score | `currentBar - impulseBar` went negative, capped at 0 | Reversed subtraction → real linear decay |

The Supply/Demand fixes alone exposed the true **2.27% false-positive rate**, validating a **97.73% retest reliability** across a 4-year backtest.

---

## 🧠 Key Design Decisions

- **Fractal swings, not ZigZag** — lookback `N=3` pivots finalized on bar close, killing repainting at the root.
- **ATR-relative grading** — a swing is *Major* only if its distance from the previous major swing exceeds `0.50 × ATR`; everything else is noise.
- **Local synchronous ATR** — every engine computes ATR itself to dodge MT5 tester async lag.
- **Base consolidation blocks** — supply/demand zones drawn from 1–6 base candles before the impulse, stopping if a prior impulse is hit.
- **Neutral decision nodes** — when a supply and demand zone overlap, *both* buy and sell entries deactivate until an H4 candle closes outside the conflict.
- **Freshness-weighted merging** — when same-type zones merge, creation time resets to the newer zone if its impulse range dominates by ≥ 20%.

---

## 📊 Verified Metrics (Strategy Tester)

> Backtest on `XAUUSDm`, H4 structure / M30 ticks, 300-bar lookback.

| Metric | Value |
|--------|:-----:|
| Swing Highs detected | **31** (24 Major / 7 Minor) |
| Swing Lows detected | **27** (23 Major / 4 Minor) |
| BOS events | **20** |
| MSS events | **10** |
| ATR sync warnings | **0** |
| S/D retest reliability | **97.73%** |

---

## 🗂️ Repository Map

```
ROOT/
├── PROJECT_GENESIS.md           ← Master project bible (single source of truth)
├── AGENT_CONSTITUTION.md        ← Permanent operating law for AI agents
├── MILESTONE_SPRINT_3_FREEZE.md  ← Current frozen-state snapshot (Sprint 3)
├── SYSTEM_ROADMAP.md            ← 8-phase development roadmap
├── README.md                    ← Recovery entrypoint (read-first protocol)
├── ARTICLE.md                   ← You are here 📍
│
├── docs/
│   ├── core/      ← Definitions, architecture, coding rules, status
│   ├── design/    ← Frozen design specs (SNR, Supply/Demand)
│   ├── audits/    ← Independent engine audit reports
│   ├── reports/   ← Statistical & validation reports
│   └── archive/   ← Superseded historical docs
│
└── src/
    ├── engines/   ← StructureEngine.mqh · SupplyDemandEngine.mqh · SnrEngine.mqh · SnrPriorityEngine.mqh
    └── tests/     ← TestStructure.mq5 · TestSupplyDemand.mq5 · TestSnr.mq5
```

---

## 🤖 Built for AI-Agent Collaboration

This repo is unusual: it's engineered so that **any AI assistant can be onboarded from a cold start**. Before writing a single line of code, an agent must read the Genesis documents and produce a `RECOVERY_REPORT.md` proving it understands:

- ✅ **WHY** the project exists
- ✅ **WHAT** is already complete and frozen
- ✅ **WHAT** must never be modified
- ✅ **WHERE** the project stands today
- ✅ **WHAT** the next sprint should be

> [!CAUTION]
> First responsibility of any contributor (human or AI) is **understanding, not coding**. Implementation is unlocked only after recovery is approved.

---

## 🚀 Next Phase — Phase 4: Liquidity Engine

Build the Liquidity Engine to detect and process order stops above and below swing points:
- **Liquidity sweeps (Stop Runs)**: Track when price invalidates major swing highs (BSL) or major swing lows (SSL) and then rapidly returns.
- **BSL/SSL targets**: Expose active liquidity pools to the Entry Engine.
- **Stable Interface**: Integrate with and consume the frozen `SnrPriorityContract`.

---

<div align="center">

### 📚 Start Here

[**PROJECT_GENESIS.md**](PROJECT_GENESIS.md) · [**AGENT_CONSTITUTION.md**](AGENT_CONSTITUTION.md) · [**SYSTEM_ROADMAP.md**](SYSTEM_ROADMAP.md) · [**MILESTONE_SPRINT_3_FREEZE.md**](MILESTONE_SPRINT_3_FREEZE.md)

🤖 **AI agents / contributors start here →** [**RECOVERY_ENTRYPOINT.md**](RECOVERY_ENTRYPOINT.md)

<br/>

*Built with discipline for XAUUSD on MetaTrader 5.*
*Trade the structure. Respect the freeze. Manage the risk.*

</div>
