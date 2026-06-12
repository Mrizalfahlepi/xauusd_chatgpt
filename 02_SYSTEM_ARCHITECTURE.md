# EA SYSTEM ARCHITECTURE

Version: 1.0

=========================================================
CORE PHILOSOPHY
===============

EA tidak mengambil keputusan dari indikator.

EA mengambil keputusan dari:

1. Structure
2. Supply Demand
3. Liquidity
4. Risk

=========================================================
MODULE 1
MARKET STRUCTURE ENGINE
=======================

Input:

H4 OHLC

Output:

Current Trend

Bullish
Bearish
Range

Functions:

DetectSwings()

DetectHHHL()

DetectLHLL()

DetectBOS()

DetectMSS()

=========================================================
MODULE 2
SUPPLY DEMAND ENGINE
====================

Input:

Market Structure

Output:

Supply Zones
Demand Zones

Functions:

FindImpulse()

FindBase()

BuildDemandZone()

BuildSupplyZone()

=========================================================
MODULE 3
ZONE SCORING ENGINE
===================

Purpose:

Memberi score kualitas setiap zone.

Range:

0 - 100

Components:

Reaction Count

25%

Rejection Strength

25%

Distance Travelled

20%

Freshness

15%

Retest Success

15%

Output:

Zone Score

=========================================================
MODULE 4
SNR ENGINE
==========

Input:

Supply Zone
Demand Zone
BOS Origin
Liquidity

Output:

Strongest SR Levels

Maximum:

15 level

Minimum:

5 level

Rules:

Tidak boleh menggunakan semua swing.

Harus melalui proses scoring.

=========================================================
MODULE 5
LIQUIDITY ENGINE
================

Input:

H4
M30

Output:

Liquidity Map

Equal High

Equal Low

Sweep Events

=========================================================
MODULE 6
ENTRY ENGINE
============

MODE A

REVERSAL

Requirements:

Strong Demand

or

Strong Supply

*

Liquidity Sweep

*

Confirmation Candle

=========================================================

MODE B

BREAKOUT

Requirements:

Valid BOS

*

Retest

*

Momentum Candle

=========================================================
MODULE 7
RISK ENGINE
===========

Risk per Trade

0.5%
1%
2%

Configurable

Functions:

CalculateLot()

CalculateSL()

CalculateTP()

CalculateRR()

=========================================================
MODULE 8
TRADE MANAGEMENT
================

Features:

Break Even

Partial Close

Trailing Stop

Emergency Exit

Time Exit

=========================================================
MODULE 9
BACKTEST ANALYZER
=================

Metrics:

Winrate

Profit Factor

Expectancy

Drawdown

Average RR

Sharpe Ratio

=========================================================
DATA FLOW
=========

Market Data

↓

Structure Engine

↓

Supply Demand Engine

↓

Zone Scoring Engine

↓

SNR Engine

↓

Liquidity Engine

↓

Entry Engine

↓

Risk Engine

↓

Trade Execution

↓

Trade Management
