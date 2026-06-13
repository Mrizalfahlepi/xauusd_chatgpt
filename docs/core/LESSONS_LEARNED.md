# LESSONS LEARNED — Institutional Engineering Memory

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED BASELINE  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Purpose of This Document

This file exists to preserve hard-earned engineering knowledge.

Every lesson documented here was paid for in debugging hours, failed backtests, broken assumptions, and repeated analysis cycles. None of these lessons were obvious at the time. All of them became obvious only after the damage was discovered.

**Future agents must read this document before implementing any new engine.**

This is not a technical specification. This is not an audit report. This is the **institutional memory** of the project — the record of what went wrong, why it went wrong, and what we now know because of it.

If you skip this document, you will repeat our mistakes.

---

## 2. Core Project Lessons

### Lesson 1 — Verification is More Important Than Implementation

The fastest way to fail is to write code before understanding the problem. Every frozen engine in this project exists because we wrote code, discovered it was broken, then rewrote it with verified logic. The time spent verifying v2.2 exceeded the time spent writing v1.0. The result was a production-grade engine instead of a prototype full of hidden bugs.

### Lesson 2 — Statistical Evidence is More Important Than Intuition

When the initial SupplyDemand report projected a 33.52% false positive rate, the team's intuition said the zones were broken. The actual verified rate was 2.27%. The difference was caused by an analytical projection error that overestimated false positives by 55 zones. The lesson: **run the parser against the raw data.** Never accept projected statistics when raw verification is possible.

### Lesson 3 — Assumptions Must Always Be Audited

Every major bug in this project was caused by an assumption that felt correct but was not. "Bar 0 won't cause repainting" — it did. "Age subtraction is straightforward" — the direction was reversed. "Invalidation bars don't affect reaction counts" — they inflated every broken zone by +1. The only defense against wrong assumptions is formal auditing.

### Lesson 4 — Every Frozen Engine Exists Because a Previous Mistake Was Discovered and Fixed

StructureEngine v2.2 is not v1.0 with features added. It is v1.0 with **five critical bugs removed**. SupplyDemandEngine v1.1 is not v1.0 with features added. It is v1.0 with **two statistical anomalies corrected**. Engines are frozen not because they were written correctly the first time, but because their defects were found, proven, fixed, and revalidated.

### Lesson 5 — Documentation is a System Component

When the project outgrew a single chat conversation, the team discovered that undocumented decisions vanished. Agent context was lost between sessions. Architecture decisions had to be re-derived from first principles. The creation of PROJECT_GENESIS.md, AGENT_CONSTITUTION.md, and the full recovery package was not optional — it was a survival requirement. Documentation is not overhead. It is infrastructure.

---

## 3. Engineering Failure History

---

### Bug 1 — Trend Classification Locked to BULLISH

**Engine**: StructureEngine  
**Version Affected**: v2.1  
**Discovered During**: Strategy Tester backtest validation  
**Audit Reference**: [STRUCTURE_ENGINE_V22_AUDIT.md](../audits/STRUCTURE_ENGINE_V22_AUDIT.md)

#### Problem

Once `TREND_BULLISH` was confirmed, the trend state became **permanently locked** and never transitioned to `TREND_RANGE` or `TREND_BEARISH`, regardless of subsequent market structure changes. The engine reported a bullish market through entire bearish reversals.

#### Wrong Assumption

The team assumed that scanning the entire lookback history and accumulating all HH/HL/LH/LL labels would produce a correct trend classification. The assumption was that the historical weight of bullish structures would naturally decay as bearish structures appeared.

#### Root Cause

`DetectTrendState()` used a **cumulative accumulation loop** across all 300 historical bars. Once a sufficient number of HH and HL labels had been counted historically, the bullish threshold was permanently exceeded. New bearish labels (LH, LL) could never overcome the accumulated bullish weight because the historical count was never reset.

#### Fix

Replaced the cumulative accumulation with **strict consecutive checking**. The scan starts from the most recent swing and breaks immediately when a label interrupts the consecutive pattern. The trend resets to `RANGE` the moment a swing breaks the sequence.

#### Validation

Strategy Tester logs confirmed dynamic transitions:
```
2025.01.10 00:00:00  TREND CHANGED | RANGE -> BULLISH | HH=2 HL=2 LH=0 LL=0
2025.01.14 04:00:00  TREND CHANGED | BULLISH -> RANGE | HH=3 HL=0 LH=0 LL=1
```
At `2025.01.14`, a Lower Low (LL=1) broke the consecutive bullish pattern, immediately resetting HL to 0 and transitioning the trend back to `RANGE`.

#### Permanent Lesson

**Never use cumulative historical counting for state classification.** Trend is a present-tense condition defined by the most recent consecutive structures, not by the sum of all historical labels. State machines must reset when the defining sequence is interrupted.

---

### Bug 2 — BOS Repainting on Bar 0

**Engine**: StructureEngine  
**Version Affected**: v2.1  
**Discovered During**: Live tick simulation in Strategy Tester  
**Audit Reference**: [STRUCTURE_ENGINE_V22_AUDIT.md](../audits/STRUCTURE_ENGINE_V22_AUDIT.md)

#### Problem

Break of Structure (BOS) signals appeared and disappeared during live testing. A BOS would trigger when a tick broke a swing level during the active candle, then vanish if the price retraced before the candle closed. This constituted **repainting** — the most dangerous defect in a trading system.

#### Wrong Assumption

The team assumed that including Bar 0 (the active, uncompleted candle) in the scan loop was safe because BOS detection only checks if a price level has been exceeded. The assumption was that a genuine break would hold by close.

#### Root Cause

The `DetectBOS()` loop scanned down to `barIdx = 0`. During the active H4 candle, every tick that temporarily exceeded a swing level registered as a confirmed BOS event. When the candle closed below the level, the BOS was already written to the event array and could not be undone.

#### Fix

Gated the scan loop to completed bars only:
```mql5
for(int barIdx = startBar; barIdx >= 1; barIdx--)
```
By stopping at `barIdx = 1`, only finalized, closed H4 candles are evaluated for structural breaks.

#### Validation

No BOS events were registered at `barIdx = 0` in the full backtest. All BOS events in the logs correspond to completed, closed candles.

#### Permanent Lesson

**Never evaluate structural events on uncompleted candles.** Any analysis that writes permanent state from Bar 0 data will repaint. This applies to BOS, MSS, zone creation, zone invalidation, and any future engine that produces tradeable signals. **Bar 0 is noise. Bar 1 is fact.**

---

### Bug 3 — Swing Reaction Score Leak

**Engine**: StructureEngine  
**Version Affected**: v2.1  
**Discovered During**: Statistical analysis of swing strength scores  
**Audit Reference**: [STRUCTURE_ENGINE_V22_AUDIT.md](../audits/STRUCTURE_ENGINE_V22_AUDIT.md)

#### Problem

Invalidated swing points continued to accumulate reaction touches and strength scores **after** being broken by a BOS event. Swings that should have been dead were ranking as the strongest levels in the system.

#### Wrong Assumption

The team assumed that running `CalculateStrengthScores()` before `DetectBOS()` was harmless because the score calculation and the BOS detection were independent operations. The assumption was that execution order within `Analyze()` did not matter.

#### Root Cause

Two failures combined:
1. `CalculateStrengthScores()` ran **before** `DetectBOS()`, so the `breakBarIndex` was not yet populated when scores were calculated.
2. `CountReactions()` scanned the entire lookback from the swing bar down to bar 1, with no stop condition at the invalidation point.

Result: A swing broken at bar 92 continued counting touches from bar 91 down to bar 1, accumulating post-invalidation reactions.

#### Fix

1. Reordered the pipeline: `DetectBOS()` now runs **before** `CalculateStrengthScores()`.
2. Passed `breakBarIndex` to `CountReactions()` as a stop boundary:
```mql5
int stopBar = (breakBarIndex >= 0) ? breakBarIndex : 0;
for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
```

#### Validation

Major Swing High at `2024.12.19 08:00` (Price = 2626.430):
- **v2.1**: 10 reactions (leaked past invalidation)
- **v2.2**: 1 reaction (stopped at `breakBarIndex = 92`)

#### Permanent Lesson

**Execution order inside the analysis pipeline is critical.** Invalidation detection must always run before scoring. Any metric that uses a boundary condition (like `breakBarIndex`) must receive that boundary from a step that has already completed. **Pipeline ordering is not cosmetic — it is logical correctness.**

---

### Bug 4 — Reaction Score Inflation During Consolidation

**Engine**: StructureEngine  
**Version Affected**: v2.1  
**Discovered During**: Anomalous reaction counts (25+) in backtest logs  
**Audit Reference**: [STRUCTURE_ENGINE_V22_AUDIT.md](../audits/STRUCTURE_ENGINE_V22_AUDIT.md)

#### Problem

Swing points in sideways consolidation ranges accumulated absurdly high reaction counts (e.g., 25 reactions) because every consecutive bar touching the price level was counted as an independent reaction event.

#### Wrong Assumption

The team assumed that each bar touching a swing level within the tolerance zone represented a genuine institutional retest. The assumption was that touch count equals demand validation.

#### Root Cause

`CountReactions()` had no state tracking. Every bar whose high or low fell within the ATR tolerance zone of the swing level incremented the counter by 1. During a 25-bar consolidation around a swing level, all 25 bars were counted as 25 separate reactions. In reality, this was a single prolonged consolidation event.

#### Fix

Implemented an `insideZone` boolean state tracker:
```mql5
bool insideZone = false;
for(int bar = swingBarIndex - 1; bar >= stopBar; bar--)
{
   double diff = MathAbs(price[bar] - level);
   if(diff <= tolerance)
   {
      if(!insideZone) { reactions++; insideZone = true; }
   }
   else { insideZone = false; }
}
```
The counter increments only when price **re-enters** the zone after having left it. Consecutive touches within the zone are grouped as a single event.

#### Validation

Swing Highs at `2024.11.26 12:00` (Price = 2641.993):
- **v2.1**: 25 reactions (every consolidation bar counted)
- **v2.2**: 1 reaction (entire consolidation grouped as one event)

#### Permanent Lesson

**Consecutive touches are not independent events.** When price stays in a zone, it is consolidating — not retesting. Any future engine that counts reactions or retests must implement zone-entry state tracking to group consecutive touches. **Count transitions, not ticks.**

---

### Bug 5 — MT5 Strategy Tester ATR Synchronization Error

**Engine**: StructureEngine  
**Version Affected**: v2.1  
**Discovered During**: Strategy Tester runs returning only 2 major swings instead of 47  
**Audit Reference**: [STRUCTURE_ENGINE_V22_AUDIT.md](../audits/STRUCTURE_ENGINE_V22_AUDIT.md)

#### Problem

The Strategy Tester classified nearly all swings as Minor (only 2 out of 58 were Major). Swing grading was effectively non-functional, making the entire structure engine useless for distinguishing institutional levels from noise.

#### Wrong Assumption

The team assumed that MT5's built-in `iATR()` indicator handle would return reliable values during Strategy Tester execution, just as it does during live chart execution. The assumption was that the platform's indicator system works identically in all contexts.

#### Root Cause

In MT5 Strategy Tester, copying from an external H4 timeframe indicator handle (`iATR`) inside an M30 backtest is **asynchronous**. During ticks, the handle occasionally returned `0.0` because the indicator data for the H4 timeframe had not yet been synchronized to the tester's internal clock. With ATR = 0, the grading threshold (`0.50 × ATR`) became zero, but the comparison logic defaulted to Minor when ATR was invalid.

#### Fix

Implemented a fully local, synchronous ATR(14) calculator inside `GetATRValue()` using the already-cached H4 price arrays (`m_cachedHighs`, `m_cachedLows`, `m_cachedCloses`). The calculation computes True Range directly from memory without calling any platform indicator handle.

#### Validation

After the fix:
```
Total Highs:  31  (Major:24  Minor:7)
Total Lows:   27  (Major:23  Minor:4)
```
No `Failed to read ATR` warnings. All major swings correctly classified. This became the **Local ATR Principle** (see Section 4).

#### Permanent Lesson

**Never depend on asynchronous platform indicator handles inside the Strategy Tester.** External timeframe handles (`iATR`, `iMA`, etc.) are unreliable in backtesting contexts. Any engine that needs derived values (ATR, moving averages) must compute them **locally and synchronously** from cached price arrays. **If you can compute it yourself, do not delegate it to the platform.**

---

### Bug 6 — SupplyDemand Age Score Decay Defect

**Engine**: SupplyDemandEngine  
**Version Affected**: v1.0  
**Discovered During**: 4-year backtest statistical analysis  
**Audit Reference**: [SUPPLY_DEMAND_V11_AUDIT.md](../audits/SUPPLY_DEMAND_V11_AUDIT.md)

#### Problem

All supply/demand zones maintained a flat 100% Age Score throughout their entire lifespan. Zones created 300+ bars ago (months old) had the same age score as zones created 1 bar ago. The scoring engine could not distinguish fresh institutional activity from stale historical remnants.

#### Wrong Assumption

The team assumed the age calculation `age = currentBarIdx - zone.impulseBarIndex` would produce a positive number representing the zone's age. The assumption was that bar index subtraction is directionally intuitive.

#### Root Cause

In MT5, bar indices are **reverse-ordered**: index 0 is the current bar, and indices increase into the past. A zone created at impulse bar index 100 evaluated at current bar index 1 produces: `age = 1 - 100 = -99`. The safety floor clamped negative values to 0, making every zone appear brand new.

#### Fix

Reversed the subtraction order:
```mql5
int age = zone.impulseBarIndex - currentBarIdx;
```
Now `age = 100 - 1 = 99`, correctly representing a zone that is 99 bars old.

#### Validation

The average zone score dropped from 76.90 to 75.01. The score distribution shifted: 24 zones moved from the 61-80 bracket into the 41-60 bracket, proving that old zones were now decaying. Stale zones from 2022 and 2023 were eliminated from the Top 20 ranking, replaced by fresh zones from late 2024 and 2025.

#### Permanent Lesson

**MT5 bar indices are reverse-ordered.** Index 0 = now, index N = N bars ago. Any calculation involving bar index arithmetic must be tested for directional correctness. The fact that subtraction "looks right" in code does not mean the result is mathematically correct. **Always verify the sign of time-based calculations with a concrete example.**

---

### Bug 7 — Invalidation Bar Reaction Inflation

**Engine**: SupplyDemandEngine  
**Version Affected**: v1.0  
**Discovered During**: 4-year backtest — zones with 0 reactions were showing 1 reaction  
**Audit Reference**: [SUPPLY_DEMAND_V11_AUDIT.md](../audits/SUPPLY_DEMAND_V11_AUDIT.md)

#### Problem

Every invalidated zone had its reaction count inflated by exactly +1 touch. Zones that were broken immediately with zero prior retests appeared to have 1 reaction, masking the true false positive rate. The reported false positive rate was 0.00% — an impossibly perfect number.

#### Wrong Assumption

The team assumed that the retest scan loop boundary at `zone.invalidatedBar` (inclusive) was correct because the invalidation bar marks the end of the zone's life. The assumption was that including the boundary bar was conservative and harmless.

#### Root Cause

The retest scanner processed bars down to `zone.invalidatedBar` (inclusive). The candle that breaks a zone almost always overlaps the zone boundary (opening inside or crossing through). This overlap was counted as a reaction touch, inflating every broken zone's count by +1.

#### Fix

Excluded the invalidation bar from the scan:
```mql5
int stopBar = zone.isInvalidated ? zone.invalidatedBar + 1 : 1;
```
The scanner now stops one bar before the breach candle, counting only genuine pre-invalidation retests.

#### Validation

After the fix:
- 4 zones correctly identified as having 0 reactions (true false positives)
- False positive rate: 2.27% (4/176 broken zones)
- Retest reliability: 97.73% (172/176 broken zones had ≥ 1 genuine retest)
- The previously "perfect" 0.00% false positive rate was exposed as a measurement artifact

#### Permanent Lesson

**Boundary bars must be treated with extreme care.** The bar that invalidates a zone is not a retest — it is a destruction event. Any loop that processes historical events must clearly distinguish between the final valid observation and the termination event. **Inclusive vs. exclusive boundary conditions are not implementation details — they are correctness requirements.**

---

### Design Audit Finding — SNR Scoring Name Collision

**Engine**: SNR Engine (Design Phase)  
**Discovered During**: Pre-implementation design consistency audit  
**Audit Reference**: [SNR_DESIGN_AUDIT.md](../audits/SNR_DESIGN_AUDIT.md)

#### Problem

The initial SNR design documents used `S_React` (Reaction Score) to measure price rejection **distance** — how far price bounced away from a level. But `SupplyDemandEngine` already uses `scoreReaction` to count how many **times** price touched a zone. Same name, completely different meaning.

#### Root Cause

The design documents were written without cross-referencing the naming conventions of the frozen upstream engines. The term "reaction" was overloaded to mean both "number of touches" and "bounce distance."

#### Fix

Formally renamed the SNR component from `S_React` to `S_Reject` (Rejection Strength Score) in the frozen architecture specification [SNR_ARCHITECTURE_FREEZE.md](../design/SNR_ARCHITECTURE_FREEZE.md).

#### Permanent Lesson

**Variable names must be unique across the entire engine pipeline.** When building a multi-module system, naming collisions between upstream and downstream components create cognitive friction and eventual bugs. **Audit naming conventions before writing code, not after.**

---

## 4. Design Lessons

---

### The Local ATR Principle

**Why every engine computes ATR locally.**

MetaTrader 5's `iATR()` indicator handle is asynchronous. In the Strategy Tester, cross-timeframe indicator handles may return 0.0 during initialization or during tick processing because the platform has not yet synchronized the indicator data. This caused StructureEngine v2.1 to classify 56 of 58 swings as Minor, destroying the entire grading system.

The fix — computing ATR(14) locally from cached price arrays — was so effective that it became a permanent architectural rule. Every engine in this project computes its own ATR from raw High/Low/Close data. No engine depends on platform indicator handles.

**Rule**: If a value can be computed from cached price data, compute it locally. Never delegate to asynchronous platform services.

---

### The Read-Only Dependency Principle

**Why downstream engines cannot modify upstream engines.**

The data pipeline is strictly unidirectional:

```
Structure → Supply Demand → SNR → Entry → Risk → Execution
```

Each engine consumes the outputs of its upstream dependencies through **read-only public accessors** (`GetZone()`, `GetMajorHigh()`, `GetSwingHigh()`). No downstream engine may modify upstream data structures, call upstream private methods, or inject data back into the pipeline.

This rule exists because:
1. Frozen engines cannot be altered. If SNR needed to modify Structure, the freeze would break.
2. Bidirectional dependencies create circular update loops that are impossible to debug.
3. Each engine's correctness is validated independently. Upstream modification invalidates that validation.

**Rule**: Downstream engines are consumers, not producers. They read from upstream and write to their own output arrays.

---

### The Frozen Engine Principle

**Why validated engines become frozen.**

A frozen engine is one that has been:
1. Implemented according to a design specification
2. Compiled with 0 errors and 0 warnings
3. Validated through a 4-year backtest (2022-2025) on XAUUSD H4
4. Audited in a formal document with empirical log evidence
5. Approved by the project owner

Once frozen, the engine may **not** be modified under any normal sprint. A freeze can only be broken if:
1. A critical defect is **mathematically proven** with Strategy Tester log traces
2. An audit plan is drafted and approved
3. Changes are isolated to the proven defect only
4. The full 4-year revalidation backtest confirms zero regression

This policy exists because every "small fix" to a validated engine risks introducing a regression that invalidates thousands of hours of testing. The cost of re-validation exceeds the cost of working around limitations.

**Rule**: Once frozen, an engine is treated as infrastructure. Build around it, not through it.

---

### The Audit Before Coding Principle

**Why design audits happen before implementation.**

The SNR Design Consistency Audit ([SNR_DESIGN_AUDIT.md](../audits/SNR_DESIGN_AUDIT.md)) discovered **two impossible data dependencies** and **three logical contradictions** in the design documents — before a single line of MQL5 was written:

1. **Private Access Violation**: The design assumed `CSnrEngine` could call `GetATRValue()` from `CStructureEngine`, but that method is `private` in the frozen code. This would have caused a compiler error.
2. **Missing Reaction Coordinates**: The design assumed zone metadata included touch bar indices, but the `SupplyDemandZone` struct only stores a count. The SNR engine would have been unable to compute rejection distances.
3. **Invalidated Zone Exclusion**: The clustering algorithm excluded invalidated zones, but the scoring model awarded 30 points for invalidated zone overlap — a logically unreachable score.

All three issues were resolved in the design phase at zero cost. Had they been discovered during implementation, they would have required refactoring frozen specifications, rewriting partially complete code, and re-auditing the entire design chain.

**Rule**: Audit the design for impossible dependencies, access violations, and logical contradictions before writing code. The cost of a design fix is minutes. The cost of a code fix is days.

---

### The Evidence Over Theory Principle

**Why statistical reports override assumptions.**

The first SupplyDemand statistical report projected a 33.52% false positive rate based on analytical reasoning. The consistency audit ([SUPPLY_DEMAND_CONSISTENCY_AUDIT.md](../audits/SUPPLY_DEMAND_CONSISTENCY_AUDIT.md)) proved the actual rate was 2.27%. The difference — 31.25 percentage points — was caused by an analytical projection error that assumed every zone with `MaxReacts = 1` was a false positive. In reality, 55 of those 59 zones had a legitimate touch on the bar immediately preceding invalidation.

The lesson was clear: **analytical projections are hypotheses. Parser output from raw data is evidence.** When the two disagree, the evidence wins.

**Rule**: Never accept statistical projections when raw verification is available. Always run the parser against the actual logs.

---

## 5. Repository Lessons

---

### The Root Directory Problem

During Sprints 1.0 through 2.2, every new audit report, validation document, statistical analysis, and design specification was created in the root directory. By the time Sprint 2.3 began, the root contained **over 15 documents** with no organizational hierarchy. It was impossible to distinguish:

- Temporary validation logs from permanent specifications
- Superseded reports from current baselines
- Design documents from audit results

### The Normalization Solution

Sprint 2.3 was dedicated entirely to repository architecture:

```
/docs/core/       ← Permanent definitions, architecture, onboarding
/docs/design/     ← Frozen design specifications
/docs/audits/     ← Completed audit reports
/docs/reports/    ← Statistical validation reports
/docs/archive/    ← Superseded and historical documents
/src/engines/     ← Frozen engine source code
/src/tests/       ← EA validator scripts
```

### The Classification Rule

Every file must be classified as one of:
- **FINAL**: Permanent, authoritative document
- **ACTIVE DESIGN**: Specification being used for current sprint
- **ACTIVE ENGINE**: Source code under development or frozen
- **ARCHIVE**: Superseded by a newer version
- **TEMPORARY**: Diagnostic or validation artifact

### Permanent Lessons

1. **Create folder structure before the first audit, not after the fifteenth.** Repository chaos is progressive — by the time you notice it, the cleanup cost is significant.
2. **Root directory is for entrypoints only.** A new agent or developer opening the repository should see 5-6 navigation documents, not a wall of 15+ unclassified files.
3. **Every file relocation must update all markdown links.** Broken links in documentation are as harmful as broken imports in code.

---

## 6. Recovery Lessons

---

### The Context Fragility Problem

This project was developed across multiple AI conversation sessions. Each session had a limited context window. Key discoveries included:

1. **Long chat histories are fragile.** As conversations grow, earlier messages are compressed or dropped. Decisions made in message #10 may be invisible by message #500.
2. **Agents can be replaced.** A new conversation starts with zero knowledge of what happened before. If the project state exists only in chat memory, it is effectively lost.
3. **Memory can be lost entirely.** A browser crash, a session timeout, or a model switch can wipe the entire conversational context. There is no undo.
4. **Verbal agreements are not contracts.** Saying "we decided to freeze v2.2" in a chat is not a freeze. Writing `Status: FROZEN` in a committed markdown file is a freeze.

### The Recovery Solution

The team created a multi-layered recovery package:

| Document | Purpose |
|----------|---------|
| **PROJECT_GENESIS.md** | Complete project history from day zero — the "bible" |
| **AGENT_CONSTITUTION.md** | Permanent operating rules and forbidden actions |
| **MILESTONE_GENESIS_FREEZE.md** | Exact snapshot of repository state at freeze point |
| **PROJECT_RECOVERY_PROTOCOL.md** | Step-by-step onboarding for new agents |
| **SYSTEM_ROADMAP.md** | Phase-by-phase development plan |
| **README.md** | GitHub entry point with mandatory reading order |

### Permanent Lessons

1. **Documentation must be sufficient for complete recovery.** If a new agent cannot reconstruct the project state from the repository alone, the documentation has failed.
2. **The repository is the source of truth, not the conversation.** Every decision, every freeze, every architectural rule must be committed to a file. Chat-only decisions do not exist.
3. **Recovery documents must be tested.** The RECOVERY_REPORT.md exercise proved that the recovery package works — a new agent with zero chat history could understand the project at 95% confidence.

---

## 7. NEVER REPEAT THESE MISTAKES

1. **Never trust assumptions without validation.** Every major bug was a "reasonable assumption" that turned out to be wrong.
2. **Never modify frozen engines casually.** The freeze-break conditions exist for a reason. One careless edit can invalidate months of validation.
3. **Never skip backtests.** A clean compilation is not validation. Only a 4-year backtest with parsed statistics proves correctness.
4. **Never skip statistical verification.** Projected statistics (33.52%) can differ from verified statistics (2.27%) by an order of magnitude.
5. **Never rely on chat history.** Conversations are ephemeral. Repository documentation is permanent.
6. **Never bypass documentation.** An undocumented decision is a decision that will be forgotten and repeated.
7. **Never include Bar 0 in structural analysis.** Uncompleted candles produce repainting signals. Bar 1 is the earliest safe evaluation point.
8. **Never use cumulative counting for state classification.** Trend detection, reaction counting, and any state-dependent metric must use consecutive or transition-based logic.
9. **Never depend on asynchronous platform handles in backtesting.** Compute derived values locally from cached arrays.
10. **Never assume boundary conditions are "just implementation details."** Inclusive vs. exclusive loop boundaries caused two separate bugs in two separate engines.
11. **Never use the same variable name for different concepts across modules.** Naming collisions create cognitive friction and eventual bugs.
12. **Never let the root directory become a dumping ground.** Organize files from the start, not after the cleanup becomes painful.

---

## 8. WHAT THIS PROJECT TAUGHT US

This project succeeded not because we wrote perfect code on the first attempt. It succeeded because we built a culture of **verification before implementation**, **evidence over assumption**, and **institutional memory over individual recall**.

Every frozen engine is a monument to mistakes that were found, understood, and permanently corrected. StructureEngine v2.2 exists because v2.1 had five critical bugs. SupplyDemandEngine v1.1 exists because v1.0 had two statistical anomalies. The SNR design freeze exists because the pre-implementation audit caught two impossible dependencies and three logical contradictions before a single line of code was written.

**Audits matter** because they catch errors that intuition misses. The design audit saved weeks of debugging by finding a `private` access violation and a missing data dependency in the specification phase. The consistency audit proved that a 33.52% projected failure rate was actually 2.27% — a 14x error that would have derailed the project's confidence.

**Frozen components exist** because re-validation is expensive and regression is catastrophic. Once an engine passes a 4-year backtest with verified statistics, the cost of protecting it (via freeze policy) is far lower than the cost of accidentally breaking it.

**Recovery documents exist** because this project will outlive any single conversation, any single agent, and any single developer. The repository must be self-explanatory. The documentation must be sufficient for a complete stranger — human or AI — to understand the project's history, current state, and future direction without access to any prior context.

**Future agents must respect this process** not because it is bureaucratic, but because every rule was written in response to a real failure. The constitution is not theoretical governance — it is a scar map. Every clause corresponds to a mistake that cost time, trust, or correctness.

The philosophy that emerged from this development history is simple:

> **Build slowly. Verify ruthlessly. Document everything. Freeze what works. Never repeat what failed.**

This is the institutional memory of the XAUUSD project. Guard it.
