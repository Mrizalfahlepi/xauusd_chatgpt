# PROJECT_MEMORY.md

Version: 1.0

=========================================================
PROJECT
=======

Project Name:

XAUUSD Institutional Structure EA

Purpose:

Membangun EA MQL5 yang membaca market menggunakan:

* Market Structure
* BOS
* MSS
* Supply Demand
* SNR Scoring

Tujuan akhir:

Mencari statistical edge yang dapat dibuktikan melalui backtest dan forward test.

Bukan membuat EA berdasarkan indikator lagging.

=========================================================
CORE PHILOSOPHY
===============

EA harus membaca market terlebih dahulu.

Urutan:

Market Structure
→ Supply Demand
→ SNR
→ Entry
→ Risk
→ Execution

Bukan:

Indicator
→ Entry

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

Tidak menggunakan:

Support Resistance berbasis swing semata.

=========================================================
APPROVED CONCEPTS
=================

Market Structure

Menggunakan:

* HH
* HL
* LH
* LL
* BOS
* MSS

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

01_MARKET_DEFINITIONS.md

02_SYSTEM_ARCHITECTURE.md

03_CODING_RULES.md

StructureEngine.mqh

TestStructure.mq5

=========================================================
CURRENT ENGINE STATUS
=====================

Version:

Structure Engine v2.1

Features:

* Swing Detection
* Major Swing
* Minor Swing
* HH HL LH LL
* BOS Detection
* MSS Detection
* Trend Detection
* Swing Score

=========================================================
KNOWN ISSUES
============

Issue #1

Major Swing masih terlalu banyak.

Target:

6-12 major highs

6-12 major lows

untuk 300 H4 bars.

Current:

~23 major highs

~24 major lows

=========================================================

Issue #2

BOS Events terlalu banyak.

Current:

~20 BOS

untuk 300 H4 bars.

Perlu audit.

=========================================================

Issue #3

MSS Events terlalu banyak.

Current:

~9 MSS

untuk 300 H4 bars.

Perlu audit.

=========================================================

Issue #4

Hubungan antara:

Swing
→ BOS
→ MSS
→ Trend

belum tervalidasi penuh.

=========================================================
DECISIONS ALREADY MADE
======================

Decision #1

Tidak menggunakan ZigZag.

Menggunakan Fractal Swing.

=========================================================

Decision #2

Menggunakan ATR Filter.

=========================================================

Decision #3

Menggunakan Major dan Minor Swing.

=========================================================

Decision #4

Structure Engine harus selesai
sebelum membuat Supply Demand.

=========================================================

Decision #5

Supply Demand harus selesai
sebelum membuat SNR.

=========================================================
NEXT PRIORITY
=============

Audit penuh:

Swing
→ BOS
→ MSS
→ Trend

Pastikan:

* BOS valid
* MSS valid
* Trend valid

Sebelum membuat modul baru.

=========================================================
DO NOT DO
=========

Jangan membuat:

* Entry Engine
* Risk Engine
* Trade Manager
* SNR Engine
* Supply Demand Engine

sebelum Structure Engine tervalidasi.

=========================================================
SUCCESS CRITERIA
================

Structure Engine:

* Stable
* Explainable
* Testable

Supply Demand:

* Reproducible

SNR:

* Scored

Final Strategy:

Profit Factor > 1.30

Max Drawdown < 15%

Backtest Multi-Year

Forward Test Required

=========================================================
END OF MEMORY
=============
