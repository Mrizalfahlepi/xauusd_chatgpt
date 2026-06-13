# PROJECT_MEMORY.md

Version: 2.4
Last Updated: 2026-06-13

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
* SNR Scoring & Prioritizer (SnrPriorityContract)

Tujuan akhir:
Mencari statistical edge yang dapat dibuktikan melalui backtest dan forward test. Bukan membuat EA berdasarkan indikator lagging.

=========================================================
CORE PHILOSOPHY
===============

EA harus membaca market terlebih dahulu.
Urutan:
Market Structure → Supply Demand → SNR & Prioritizer → Liquidity (Stop Runs) → Entry → Risk → Execution

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

SNR & Output Prioritization
Berbasis:
* ATR clustering
* 5-factor scoring
* Proximity-based structural vs. tradable levels sorting
* Neutral Node deactivation checks
* Nearest BSL/SSL targets mapping
* Fallback bypass mechanisms

=========================================================
CURRENT PROJECT STATUS
======================

Completed & Frozen:
* [01_MARKET_DEFINITIONS.md](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md)
* [02_SYSTEM_ARCHITECTURE.md](file:///c:/xauusd_chatgpt/docs/core/02_SYSTEM_ARCHITECTURE.md)
* [03_CODING_RULES.md](file:///c:/xauusd_chatgpt/docs/core/03_CODING_RULES.md)
* [04_DESIGN_DECISIONS.md](file:///c:/xauusd_chatgpt/docs/core/04_DESIGN_DECISIONS.md)
* [05_CURRENT_STATUS.md](file:///c:/xauusd_chatgpt/docs/core/05_CURRENT_STATUS.md)
* [08_AGENT_ONBOARDING.md](file:///c:/xauusd_chatgpt/docs/core/08_AGENT_ONBOARDING.md)
* [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh) (Version 2.2) [FROZEN]
* [TestStructure.mq5](file:///c:/xauusd_chatgpt/src/tests/TestStructure.mq5) (Version 2.2 Compiler Verified)
* [STRUCTURE_ENGINE_V22_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/STRUCTURE_ENGINE_V22_AUDIT.md)
* [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh) (Version 1.1) [FROZEN]
* [TestSupplyDemand.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSupplyDemand.mq5) (Version 1.1 Compiler Verified)
* [SUPPLY_DEMAND_DESIGN.md](file:///c:/xauusd_chatgpt/docs/design/SUPPLY_DEMAND_DESIGN.md)
* [SUPPLY_DEMAND_V11_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/SUPPLY_DEMAND_V11_AUDIT.md)
* [UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md)
* [SnrEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh) (Version 1.0) [FROZEN]
* [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh) (Version 1.0) [FROZEN]
* [TestSnr.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSnr.mq5) (Version 1.0 Compiler Verified)
* [MILESTONE_SPRINT_3_FREEZE.md](file:///c:/xauusd_chatgpt/MILESTONE_SPRINT_3_FREEZE.md)

=========================================================
CURRENT ENGINE STATUS
=====================

Version:
* Structure Engine v2.2 (Production-Ready) [FROZEN]
* Supply & Demand Engine v1.1 (Production-Ready) [FROZEN]
* SNR Engine v1.0 (Production-Ready) [FROZEN]
* SNR Priority Engine v1.0 (Production-Ready) [FROZEN]

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
* consolidated SNR bands calculated using reaction, rejection, and freshness scores
* Proximity-based structural vs. tradable levels sorting and Quality Score + ATR distance filtering
* Neutral conflict nodes detection and helper checks
* Nearest BSL/SSL pools mapping

=========================================================
RESOLVED ISSUES
===============

* **Issue #1: Trend Classification Locked to BULLISH (Resolved in v2.2)**
* **Issue #2: BOS/MSS Repainting on Bar 0 (Resolved in v2.2)**
* **Issue #3: Swing Reaction Score Leak (Resolved in v2.2)**
* **Issue #4: Reaction Score Inflation during Consolidation (Resolved in v2.2)**
* **Issue #5: MT5 Strategy Tester ATR Sync Error (Resolved in v2.2)**
* **Issue #6: SupplyDemand Age Score Decay Defect (Resolved in v1.1)**
* **Issue #7: SupplyDemand Invalidation Bar Reaction Inflation (Resolved in v1.1)**
* **Issue #8: ATR Distance Filter Fallback (Resolved in Sprint 3.4)**
  * *Finding*: Kandidat `ID=18` berjarak `5.01223821` ATR correctly rejected di bawah limit `5.0` ATR. Kehadiran di contract murni karena dipicu oleh fallback mechanism untuk mencegah downstream engine "buta".

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
* **Decision #13**: Membekukan Sprint 3.4. Seluruh porsi SNR Engine dan Prioritizer telah beku dan lolos pengujian kompilasi & Strategy Tester.

=========================================================
NEXT PRIORITY
=============

Build Liquidity Engine (Module 4)
* Mengintegrasikan `SnrPriorityContract` ke dalam pipeline.
* Mendeteksi stop-loss clusters (BSL/SSL) di atas/bawah swings.
* Melacak sweep events (Stop Runs) dan menandai event likuiditas.

Do Not Do:
* **Jangan mendesain ulang Sprint 3** (scoring logic, prioritizer, atau interface contract beku).
* Jangan membangun Entry Engine sebelum Liquidity Engine selesai divalidasi penuh.

=========================================================
SUCCESS CRITERIA
================
* **Liquidity Engine**: Mampu melacak sweep events secara real-time dan mengekspos koordinat BSL/SSL secara presisi tanpa merusak backward compatibility kontrak `SnrPriorityContract`.

=========================================================
END OF MEMORY
=========================
