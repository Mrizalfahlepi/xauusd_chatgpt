# CODING RULES

Version: 1.0

=========================================================
GENERAL RULES
=============

Code Style:

MQL5 Native

No External DLL

No Repaint Logic

No Future Leak

No Look Ahead Bias

=========================================================
ARCHITECTURE RULES
==================

Setiap modul harus independen.

Setiap modul harus dapat diuji sendiri.

Tidak boleh ada coupling berlebihan.

=========================================================
FUNCTION RULES
==============

1 fungsi

1 tugas

Maximum:

100 lines

Ideal:

20-50 lines

=========================================================
VARIABLE RULES
==============

Dilarang:

a
b
x
tmp

Gunakan:

currentATR

nearestDemand

currentTrend

=========================================================
MAGIC NUMBER RULE
=================

Tidak boleh ada magic number.

Salah:

if(distance > 25)

Benar:

if(distance > InpMinBreakDistance)

=========================================================
LOGGING RULE
============

Semua keputusan penting harus dicatat.

Contoh:

Trend Changed

BOS Detected

Demand Zone Created

Trade Opened

Trade Closed

=========================================================
TESTABILITY RULE
================

Semua fungsi harus dapat diuji.

Contoh:

TestDetectBOS()

TestBuildDemandZone()

TestLiquiditySweep()

=========================================================
PERFORMANCE RULE
================

Tidak boleh scan 10.000 candle setiap tick.

Gunakan:

New Bar Detection

Cache

Incremental Update

=========================================================
TRADING RULE
============

Tidak boleh entry tanpa:

Risk Calculation

Tidak boleh entry tanpa:

SL

Tidak boleh entry tanpa:

TP

=========================================================
OPTIMIZATION RULE
=================

Parameter harus configurable.

Gunakan:

input

untuk semua setting utama.

=========================================================
FORBIDDEN
=========

RSI Entry

MACD Entry

Martingale

Grid

Averaging Down

Infinite Recovery

Lot Multiplier

Tanpa alasan matematis yang jelas.

=========================================================
GOAL
====

Membangun EA profesional yang:

Robust

Explainable

Testable

Maintainable

Scalable
