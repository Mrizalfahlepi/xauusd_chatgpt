# XAUUSD MARKET DEFINITIONS

Version: 1.0

=========================================================
PURPOSE
=======

Dokumen ini menjadi sumber kebenaran tunggal (Single Source of Truth).

Semua modul EA wajib mengikuti definisi yang ada di dokumen ini.

Tidak diperbolehkan membuat definisi baru tanpa revisi dokumen ini.

=========================================================
MARKET
======

Instrument:
XAUUSD

Execution:
MT5

Primary Analysis TF:
H4

Execution TF:
M30

Confirmation TF:
M15

=========================================================
MARKET STATES
=============

Market hanya memiliki 3 kondisi.

1. Bullish
2. Bearish
3. Range

=========================================================
BULLISH STRUCTURE
=================

Syarat:

Higher High (HH)
dan
Higher Low (HL)

minimal 2 siklus valid.

Contoh:

HL1
HH1

HL2
HH2

Status:
Bullish

=========================================================
BEARISH STRUCTURE
=================

Syarat:

Lower High (LH)
dan
Lower Low (LL)

minimal 2 siklus valid.

Contoh:

LH1
LL1

LH2
LL2

Status:
Bearish

=========================================================
RANGE STRUCTURE
===============

Jika tidak ditemukan bullish atau bearish structure yang valid.

Status:
Range

=========================================================
SWING DEFINITION
================

Swing High:

High tertinggi yang memiliki minimal:

N candle kiri
N candle kanan

default:

N = 3

Swing Low:

Low terendah yang memiliki minimal:

N candle kiri
N candle kanan

default:

N = 3

=========================================================
BREAK OF STRUCTURE (BOS)
========================

Bullish BOS:

Close candle H4

harus menutup di atas swing high terakhir.

Valid jika:

Break Distance >= 0.25 ATR(14)

Bearish BOS:

Close candle H4

harus menutup di bawah swing low terakhir.

Valid jika:

Break Distance >= 0.25 ATR(14)

=========================================================
MARKET STRUCTURE SHIFT (MSS)
============================

Bullish MSS:

Trend bearish
+
BOS bullish pertama

Bearish MSS:

Trend bullish
+
BOS bearish pertama

=========================================================
IMPULSE DEFINITION
==================

Impulse Move:

Pergerakan harga yang memiliki:

Range >= 2 ATR(14)

dan

Body Dominance >= 60%

=========================================================
DEMAND ZONE
===========

Demand Zone:

Base terakhir

sebelum bullish impulse.

Zone High:
high base

Zone Low:
low base

=========================================================
SUPPLY ZONE
===========

Supply Zone:

Base terakhir

sebelum bearish impulse.

Zone High:
high base

Zone Low:
low base

=========================================================
LIQUIDITY
=========

Equal High:

2 atau lebih high

dengan toleransi:

0.15 ATR

Equal Low:

2 atau lebih low

dengan toleransi:

0.15 ATR

=========================================================
LIQUIDITY SWEEP
===============

Bullish Sweep:

harga mengambil equal low

kemudian kembali close di atas area tersebut.

Bearish Sweep:

harga mengambil equal high

kemudian kembali close di bawah area tersebut.

=========================================================
VOLATILITY
==========

ATR Period:

14

ATR Timeframe:

H4

=========================================================
PRICE SOURCE
============

Open
High
Low
Close

Volume Tick

Tidak menggunakan indikator lagging.
