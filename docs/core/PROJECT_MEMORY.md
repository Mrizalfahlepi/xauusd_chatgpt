# PROJECT_MEMORY.md

Version: 2.3
Last Updated: 2026-06-12

=========================================================
PROJECT
=======

Project Name:
XAUUSD Institutional Structure EA

Purpose:
Membangun EA MQL5 yang membaca market menggunakan:
* Market Structure
* BOS (Break of Structure)
* MSS (Market Structure Shift)
* Supply Demand
* SNR Scoring

Tujuan akhir:
Mencari statistical edge yang dapat dibuktikan melalui backtest dan forward test. Bukan membuat EA berdasarkan indikator lagging.

=========================================================
CORE PHILOSOPHY
===============

EA harus membaca market terlebih dahulu.
Urutan:
Market Structure → Supply Demand → SNR → Entry → Risk → Execution

Bukan:
Indicator → Entry

=========================================================
REJECTED CONCEPTS
=================

Tidak menggunakan:
* RSI sebagai entry utama
* MACD sebagai entry utama
* Stochastic sebagai entry utama
* Martingale
* Grid
* Averaging Down
* Recovery System
* Support Resistance berbasis swing semata (tanpa scoring)

=========================================================
APPROVED CONCEPTS
=================

Market Structure
Menggunakan:
* HH (Higher High) / HL (Higher Low)
* LH (Lower High) / LL (Lower Low)
* BOS (Break of Structure)
* MSS (Market Structure Shift)

Supply Demand
Berbasis:
* Impulse Origin
* Base
* Displacement

SNR
Berbasis:
* Structure
* BOS Origin
* Supply Demand
* Liquidity

=========================================================
CURRENT PROJECT STATUS
======================

Completed:
* [01_MARKET_DEFINITIONS.md](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md)
* [02_SYSTEM_ARCHITECTURE.md](file:///c:/xauusd_chatgpt/docs/core/02_SYSTEM_ARCHITECTURE.md)
* [03_CODING_RULES.md](file:///c:/xauusd_chatgpt/docs/core/03_CODING_RULES.md)
* [04_DESIGN_DECISIONS.md](file:///c:/xauusd_chatgpt/docs/core/04_DESIGN_DECISIONS.md)
* [05_CURRENT_STATUS.md](file:///c:/xauusd_chatgpt/docs/core/05_CURRENT_STATUS.md)
* [08_AGENT_ONBOARDING.md](file:///c:/xauusd_chatgpt/docs/core/08_AGENT_ONBOARDING.md)
* [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh) (Version 2.2)
* [TestStructure.mq5](file:///c:/xauusd_chatgpt/src/tests/TestStructure.mq5) (Version 2.2 Compiler Verified)
* [STRUCTURE_ENGINE_V22_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/STRUCTURE_ENGINE_V22_AUDIT.md)
* [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh) (Version 1.1)
* [TestSupplyDemand.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSupplyDemand.mq5) (Version 1.1 Compiler Verified)
* [SUPPLY_DEMAND_DESIGN.md](file:///c:/xauusd_chatgpt/docs/design/SUPPLY_DEMAND_DESIGN.md)
* [SUPPLY_DEMAND_VALIDATION.md](file:///c:/xauusd_chatgpt/docs/archive/SUPPLY_DEMAND_VALIDATION.md)
* [SUPPLY_DEMAND_VERIFICATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/archive/SUPPLY_DEMAND_VERIFICATION_REPORT.md)
* [SUPPLY_DEMAND_V11_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/SUPPLY_DEMAND_V11_AUDIT.md)
* [UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md)

=========================================================
CURRENT ENGINE STATUS
=====================

Version:
* Structure Engine v2.2 (Production-Ready)
* Supply & Demand Engine v1.1 (Production-Ready)

Features:
* Fractal-based Swing Detection (N=3)
* ATR-relative Major/Minor Swing Grading
* Strict Consecutive Trend State Detection (Bullish/Bearish/Range)
* Non-repainting BOS Detection (Capped at Bar 1)
* Chronological BOS & MSS Processing
* Capped Swing Strength Score (Clipped at Break Bar Index)
* Consolidation-grouped Reaction Count
* Local Synchronous ATR(14) Calculator (Eliminated MT5 Tester sync issues)
* Chronological Supply/Demand zone creation and invalidation tracking
* 1-6 base candle consolidation expansion
* 5-metric zone quality scoring framework with active age decay and non-inflated retest reaction counts

==============================================RESOLVED ISSUES
===============

* **Issue #1: Trend Classification Locked to BULLISH (Resolved in v2.2)**
  * *Fix*: Converted the accumulation loop to consecutive checking. The trend immediately resets to `RANGE` when a swing breaks the consecutive pattern.
* **Issue #2: BOS/MSS Repainting on Bar 0 (Resolved in v2.2)**
  * *Fix*: Restricted `DetectBOS` loop to `barIdx >= 1` to prevent uncompleted candle ticks from writing permanent BOS events.
* **Issue #3: Swing Reaction Score Leak (Resolved in v2.2)**
  * *Fix*: Re-ordered the pipeline to run `DetectBOS` before strength scores. `CountReactions` terminates at `breakBarIndex` instead of scanning post-invalidation.
* **Issue #4: Reaction Score Inflation during Consolidation (Resolved in v2.2)**
  * *Fix*: Implemented an `insideZone` state tracker in `CountReactions` to group consecutive touches into a single reaction event.
* **Issue #5: MT5 Strategy Tester ATR Sync Error (Resolved in v2.2)**
  * *Fix*: Implemented local synchronous calculation of ATR(14) using cached H4 Close/High/Low price arrays, bypassing asynchronous indicator handles.
* **Issue #6: SupplyDemand Age Score Decay Defect (Resolved in v1.1)**
  * *Fix*: Corrected the age bar index subtraction order to `zone.impulseBarIndex - currentBarIdx` so that the result decays linearly.
* **Issue #7: SupplyDemand Invalidation Bar Reaction Inflation (Resolved in v1.1)**
  * *Fix*: Excluded the invalidation candle index from the retest touch loop (`stopBar = invalidatedBar + 1`).

=========================================================
TUNABLE PARAMETERS (BOS & MSS SENSITIVITY)
==========================================

* **Major Swing Counts (~24 Highs, ~23 Lows per 300 H4 bars)**
  * *Tuning*: Can be reduced to target 6-12 swings by increasing `InpMinSwingDistATR` from `0.50` to `1.25` or `1.50`.
* **BOS Event Counts (~20 BOS per 300 H4 bars)**
  * *Tuning*: Can be reduced by increasing `InpBOSBreakMultiplier` from `0.25` to `0.50` or `0.75`.
* **MSS Event Counts (~10 MSS per 300 H4 bars)**
  * *Tuning*: Reduces naturally with the increase of `InpMinSwingDistATR`.

=========================================================
DECISIONS ALREADY MADE
======================

* **Decision #1**: Tidak menggunakan ZigZag; menggunakan Fractal Swing (N=3).
* **Decision #2**: Menggunakan ATR Filter untuk grading swing.
* **Decision #3**: Menggunakan Major dan Minor Swing untuk memisahkan noise.
* **Decision #4**: Structure Engine harus selesai dan divalidasi sebelum membuat Supply Demand.
* **Decision #5**: Supply Demand harus selesai sebelum membuat SNR.
* **Decision #6**: Menggunakan *consecutive checking* pada trend detection untuk menghindari kondisi tren terkunci.
* **Decision #7**: Mengeluarkan Bar 0 dari loop BOS untuk menghilangkan resiko repainting.
* **Decision #8**: Menghentikan perhitungan reaksi swing pada index bar keruntuhan (`breakBarIndex`) untuk mencegah kebocoran skor.
* **Decision #9**: Mengelompokkan sentuhan berturut-turut pada zona toleransi konsolidasi sebagai satu reaksi tunggal menggunakan state tracker `insideZone`.
* **Decision #10**: Menghitung ATR(14) secara lokal dan sinkron di H4 untuk mengatasi masalah *tester synchronization error*.
* **Decision #11**: Menghitung umur zona S/D sebagai selisih bar positif (`impulseBarIndex - currentBarIdx`) untuk mengaktifkan peluruhan skor linier.
* **Decision #12**: Mengeluarkan lilin pematah (invalidation candle) dari rentang sentuhan retest S/D untuk menghindari inflasi reaksi.

=========================================================
NEXT PRIORITY
=============

Build SNR Engine (Module 3)
* Mengintegrasikan zona Supply & Demand v1.1 dan swing Structure v2.2.
* Menghitung nilai horizontal support/resistance berdasarkan reaksi retest, penolakan harga, dan tingkat kesegaran zona.
* Menentukan level Likuiditas.

Do Not Do:
* Jangan membangun Entry Engine, Risk Engine, atau Trade Manager sebelum SNR Engine divalidasi penuh.

=========================================================
SUCCESS CRITERIA
================

Structure Engine:
* Stable, Non-repainting, Non-leaking (Verified in v2.2)

Supply Demand:
* Base zones identified correctly at impulse origins; no zone overlap; correct invalidation. (Verified in v1.1)

SNR:
* Zone-based horizontal support/resistance levels calculated using reaction, rejection, and freshness scores.

=========================================================
END OF MEMORY
=========================
