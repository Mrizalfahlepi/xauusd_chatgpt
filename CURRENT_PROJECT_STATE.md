# CURRENT PROJECT STATE

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: ACTIVE — SPRINT 3.5A NORMALIZATION  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Project Phase & Module Status

This project constructs an institutional-grade, fully automated trading system for Gold (`XAUUSD`/`XAUUSDm`) on MetaTrader 5 using MQL5. Development proceeds sequentially through 8 decoupled engines on a unidirectional data pipeline.

### Pipeline Status Overview

| Phase | Module | Timeframe | Version | Status | Key Output / Contracts |
|:---:|---|:---:|:---:|:---:|---|
| **1** | **Structure Engine** | H4 | v2.2 | ❄️ **FROZEN** | Major/Minor Swings, BOS/MSS events |
| **2** | **Supply Demand Engine** | H4 | v1.1 | ❄️ **FROZEN** | Base-Impulse Zones, Retests |
| **3** | **SNR Engine & Prioritizer** | H4 | v1.0 | ❄️ **FROZEN** | `SnrPriorityContract`, Neutral Nodes |
| **4** | **Liquidity Engine** | H4/M30 | — | 🎯 **ACTIVE TARGET** | Stop runs, BSL/SSL sweeps |
| **5** | **Entry Engine** | M30 | — | ⚪ Planned | H4 bias alignment, M30 limit/market orders |
| **6** | **Risk Engine** | M30 | — | ⚪ Planned | Lot sizing, fixed 1% account risk |
| **7** | **Portfolio / Execution** | M30 | — | ⚪ Planned | Order trailing, partials, news filters |
| **8** | **Live Validation** | — | — | ⚪ Planned | Live demo/micro account validation |

---

## 2. Frozen Interfaces & Code Contracts

Downstream engines (Phase 4 and 5) must consume the outputs of preceding engines strictly through the following frozen contract, defined in [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh):

```mql5
struct SnrPriorityContract
{
   double         currentPrice;
   double         atr;

   // 1. Structural Levels (Sorted by price distance ascending)
   SNRLevel       supportLevels[3];
   int            supportCount;

   SNRLevel       resistanceLevels[3];
   int            resistanceCount;

   // 2. Tradable Levels (Floors & Ceilings, sorted by price distance ascending)
   SNRLevel       tradableSupport[3];
   int            tradableSupportCount;

   SNRLevel       tradableResistance[3];
   int            tradableResistanceCount;

   // Safety blocking coordinates (sorted by distance ascending)
   SNRLevel       neutralNodes[6];
   int            neutralCount;

   // Immediate liquidity boundaries
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;

   //--- Entry Engine Helper Methods ---
   bool IsInsideNeutralZone(double price) const;
   double DistanceToNearestNeutral(double price) const;
};
```

---

## 3. Active Sprint: Sprint 3.5A — Repository Normalization

The target of the active sprint is to clean the root directory to only 10 entrypoint files and `.gitignore`, moving all other documents into appropriate `/docs/` subdirectories. No modifications are permitted to MQL5 source code or the engine logic.

### Normalized Directory Mapping

* **Root**: Permanent entrypoint documents providing orientation and project state checkpoints.
* **docs/archive/**: Superseded specifications, historical articles, or templates.
* **docs/audits/**: Code audits, design audits, compile check verification reports, and checkpoints.
* **docs/core/**: Permanent design principles, definitions, and institutional engineering memory.
* **docs/design/**: Frozen design specifications, parameters, and visual guidelines.
* **docs/reports/**: Performance validation logs, statistical backtest reports, and raw CSV files.

---

## 4. Key Documentation Entrypoints

For new agents or developers onboarding from a cold start, consult documentation in the following mandatory reading order:

1. **[RECOVERY_ENTRYPOINT.md](file:///c:/xauusd_chatgpt/RECOVERY_ENTRYPOINT.md)**: AI agent recovery entrypoint and onboarding validation.
2. **[PROJECT_GENESIS.md](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md)**: Authoritative project history, vision, and bugs log (Source of Truth #1).
3. **[AGENT_CONSTITUTION.md](file:///c:/xauusd_chatgpt/AGENT_CONSTITUTION.md)**: Permanent AI operating rules and boundaries.
4. **[docs/core/LESSONS_LEARNED.md](file:///c:/xauusd_chatgpt/docs/core/LESSONS_LEARNED.md)**: Capture of engineering failures, design decisions, and rules.
5. **[docs/reports/RECOVERY_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/RECOVERY_REPORT.md)**: Latest recovery validation status and open risks.
6. **[MILESTONE_SPRINT_3_FREEZE.md](file:///c:/xauusd_chatgpt/MILESTONE_SPRINT_3_FREEZE.md)**: Verification checklist and compilation state for Phase 3 SNR completion.
7. **[SYSTEM_ROADMAP.md](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md)**: Phase roadmap specifications.
