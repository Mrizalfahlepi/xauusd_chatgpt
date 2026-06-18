# PROJECT_MEMORY.md

Version: 2.6
Last Updated: 2026-06-18

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
* Liquidity Engine (LiquidityPriorityContract)

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
* Stop-loss ketat (< 1.0 ATR) pada trade pembalikan likuiditas
* Fixed time-based exits tanpa target SL/TP pelindung

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

Liquidity Engine & Reversal Filtering
Berbasis:
* Volatility-adjusted sweep size ATR
* Breach vs. Rejection separation in contract
* Asymmetric Risk-to-Reward models (SL = 1.0 ATR, TP = 2.0 ATR)
* Time-decay exits (hard close at 12 M30 bars / 6 hours)
* Downstream Entry Engine regime filters
* Sweep Efficiency Filter gating (excluding $2.0 \le \text{Efficiency} \le 2.5$)

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
* [TestStructure.mq5](file:///c:/xauusd_chatgpt/src/tests/TestStructure.mq5) (Compiler Verified)
* [STRUCTURE_ENGINE_V22_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/STRUCTURE_ENGINE_V22_AUDIT.md)
* [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh) (Version 1.1) [FROZEN]
* [TestSupplyDemand.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSupplyDemand.mq5) (Compiler Verified)
* [SUPPLY_DEMAND_DESIGN.md](file:///c:/xauusd_chatgpt/docs/design/SUPPLY_DEMAND_DESIGN.md)
* [SUPPLY_DEMAND_V11_AUDIT.md](file:///c:/xauusd_chatgpt/docs/audits/SUPPLY_DEMAND_V11_AUDIT.md)
* [UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md)
* [SnrEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrEngine.mqh) (Version 1.0) [FROZEN]
* [SnrPriorityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SnrPriorityEngine.mqh) (Version 1.0) [FROZEN]
* [TestSnr.mq5](file:///c:/xauusd_chatgpt/src/tests/TestSnr.mq5) (Compiler Verified)
* [MILESTONE_SPRINT_3_FREEZE.md](file:///c:/xauusd_chatgpt/MILESTONE_SPRINT_3_FREEZE.md)
* [LiquidityEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/LiquidityEngine.mqh) (Version 1.0) [FROZEN]
* [TestLiquidity.mq5](file:///c:/xauusd_chatgpt/src/tests/TestLiquidity.mq5) (Compiler Verified)
* [TestLiquidityValidation.mq5](file:///c:/xauusd_chatgpt/src/tests/TestLiquidityValidation.mq5) (Compiler Verified)
* [EntryEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/EntryEngine.mqh) (Version 1.0) [FROZEN]
* [TestEntry.mq5](file:///c:/xauusd_chatgpt/src/tests/TestEntry.mq5) (Compiler Verified)
* [PHASE5B_FINAL_VALIDATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/PHASE5B_FINAL_VALIDATION_REPORT.md)
* [Phase5A_FINAL_VALIDATION_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/Phase5A_FINAL_VALIDATION_REPORT.md)

=========================================================
CURRENT ENGINE STATUS
=====================

Version:
* Structure Engine v2.2 (Production-Ready) [FROZEN]
* Supply & Demand Engine v1.1 (Production-Ready) [FROZEN]
* SNR Engine v1.0 (Production-Ready) [FROZEN]
* SNR Priority Engine v1.0 (Production-Ready) [FROZEN]
* Liquidity Engine v1.0 (Production-Ready) [FROZEN]
* Entry Engine v1.0 (Phase 5B Completed & Frozen, Variant D Approved)

Features:
* Fractal-based Swing Detection (N=3)
* ATR-relative Major/Minor Swing Grading
* Strict Consecutive Trend State Detection (Bullish/Bearish/Range)
* Non-repainting BOS Detection (Capped at Bar 1)
* Chronological BOS & MSS Processing
* Capped Swing Strength Score (Clipped at Break Bar Index)
* Consolidation-grouped Reaction Count
* Local Synchronous ATR(14) Calculator
* Chronological Supply/Demand zone creation and invalidation tracking
* 1-6 base candle consolidation expansion
* 5-metric zone quality scoring framework with active age decay and non-inflated retest reaction counts
* consolidated SNR bands calculated using reaction, rejection, and freshness scores
* Proximity-based structural vs. tradable levels sorting and Quality Score + ATR distance filtering
* Neutral conflict nodes detection and helper checks
* Nearest BSL/SSL pools mapping
* Volatility-adjusted sweep size calculation on closed M30 bar 1
* Decoupled liquidity detection and downstream contract output
* Sweep Efficiency Filter gating (`VARIANT_D_EFF_OUTSIDE`) to filter out the 2.0-2.5 transitional trap.

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
* **Issue #9: Visual Marker Timing Latency (Resolved in Phase 4.3)**
  * *Finding*: Marker baru tergambar beberapa lilin setelah event terdeteksi. Diperbaiki dengan menggambar marker visual secara instan pada candle pendeteksi breach, bukan saat event ditutup atau saat flush data.
* **Issue #10: Strategy Tester Journal Spam (Resolved in Phase 4.3)**
  * *Finding*: Log dari prioritas ATR filter dan invalidasi supply/demand membanjiri jurnal tester. Diperbaiki dengan menambahkan gate kompilasi `#ifdef` di file masing-masing.
* **Issue #11: H4 Trend Gate Paradox (Resolved in Phase 5A)**
  * *Finding*: Minimalist H4 Trend Gate memblokir setup pembalikan counter-trend tepat pada puncak tren H4 leg (seperti di 2022) dan gagal memitigasi drawdown trending year (2023). Filter secara resmi ditolak.
* **Issue #12: Transitional Gray Zone Reversal Trap (Resolved in Phase 5B)**
  * *Finding*: Trade dengan efisiensi 2.0 - 2.5 adalah 100% BSL short setup patologis yang bertindak sebagai jebakan breakout selama akumulasi pasar. Diselesaikan dengan menyaring efisiensi gray zone ini (Variant D).

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
* **Decision #14**: Memisahkan terminologi Breach dan Rejection dalam kontrak likuiditas. Breach adalah penembusan batas luar pool; Rejection adalah kembalinya Close melewati batas dalam pool.
* **Decision #15**: Melakukan pemeriksaan breach likuiditas pada batas luar pool (outer boundary) untuk BSL (`High > priceHigh`) dan SSL (`Low < priceLow`) guna menghindari sinyal palsu akibat penembusan parsial.
* **Decision #16**: Marker visual digambar secara instan pada candle pendeteksi breach untuk memfasilitasi forensic validation yang akurat secara kronologis.
* **Decision #17**: Mempertahankan logika Liquidity Engine murni bersifat faktual (hanya melaporkan kejadian). Filter trading seperti pembatasan ukuran breach didelegasikan sepenuhnya ke Entry/Risk Engine hilir.
* **Decision #18**: Memotong pesan debug yang tidak penting menggunakan gate `#ifdef` untuk mencegah disk write bottleneck selama pengujian Strategy Tester.
* **Decision #19**: Menolak model exit berbasis waktu murni tanpa stop/target pengaman. Menggunakan SL = 1.0 ATR (di atas median MAE 0.627 ATR) dan TP = 2.0 ATR untuk mengekstrak profit dari V-reversals yang ekstrem secara asimetris.
* **Decision #20**: Mengakui ketidakstabilan temporal dari pembalikan likuiditas murni (merugi di 2023, untung besar di 2024). Mengharuskan Entry Engine hilir mengintegrasikan trend-filter guna menghindari entry saat tren H4 sangat kuat.
* **Decision #21**: Penolakan H4 Trend Gate filter (Phase 5A). Evaluasi statistik membuktikan filter ini menurunkan total expectancy dari +0.1954 ATR ke +0.1196 ATR, serta merusak performa tahun 2022 (berubah dari profit ke rugi).
* **Decision #22**: Penerimaan dan Pembekuan Variant D (Phase 5B). Menggunakan Sweep Efficiency filter untuk memblokir rentang efisiensi $2.0 \le \text{Efficiency} \le 2.5$. Pilihan ini meningkatkan total expectancy dari +0.1954 ATR menjadi +0.2688 ATR dan Profit Factor dari 1.54 menjadi 1.85.

=========================================================
NEXT PRIORITY
=============

Phase 6 — Risk Management Engine
* Merumuskan dynamical lot sizing berbasis ukuran Stop Loss untuk mempertahankan risiko akun tetap 1% per trade.
* Merancang safety layers untuk integrasi portofolio.

Do Not Do:
* Jangan memodifikasi model deteksi likuiditas beku di `CLiquidityEngine`.
* Jangan mendesain ulang scoring dan prioritizer level SNR.

=========================================================
SUCCESS CRITERIA
================
* **Risk Management Engine**: Mampu melakukan kalkulasi lot dinamis berdasarkan balance dan SL dengan presisi tinggi di MT5.

=========================================================
END OF MEMORY
=======================================
