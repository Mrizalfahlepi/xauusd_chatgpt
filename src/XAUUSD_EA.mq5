//+------------------------------------------------------------------+
//|                                                   XAUUSD_EA.mq5   |
//|   QUAD-STRATEGY v4: Core + Breakout + SessionBO + VWAP-Rev      |
//|                        Version 4.0                              |
//+------------------------------------------------------------------+
//| FILOSOFI (portofolio 4 strategi BERKORELASI RENDAH):            |
//|                                                                  |
//|   MESIN A "CORE"     = FADE liquidity sweep (Variant D). M30.    |
//|       Menang di market ranging / saat sweep gagal. Jarang trade. |
//|                                                                  |
//|   MESIN B "BREAKOUT" = MOMENTUM ikut BOS H4. M30.               |
//|       Menang di market TRENDING. Jarang trade.                  |
//|                                                                  |
//|   MESIN C "SESSION"  = RANGE BREAKOUT sesi Asia, M5.            |
//|       Entry saat overlap London-NY (12-16 UTC) tembus range      |
//|       Asia. -> FREKUENSI HARIAN (aktivitas tiap hari).          |
//|                                                                  |
//|   MESIN D "VWAP"     = MEAN-REVERSION thd VWAP sesi, M5.        |
//|       Fade saat harga melar dari VWAP + filter ADX (matikan saat |
//|       trending). -> sinyal harian, korelasi rendah ke C.        |
//|                                                                  |
//|   C & D = mesin AKTIVITAS HARIAN (timeframe kecil M5).          |
//|   A & B = mesin EDGE jarang tapi berkualitas (M30/H4).         |
//|   Magic terpisah -> P&L tiap mesin terukur & bisa dimatikan.   |
//|                                                                  |
//| PENTING TUNING: JANGAN tuning pakai data 2026 (itu OOS).        |
//|   Tuning di 2021-2025, validasi terpisah di 2026.              |
//| SETUP WAJIB Core: InpVariantMode=3, InpEnableTrendGate=true.    |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property version   "4.00"
#property strict

#include <Trade/Trade.mqh>
#include "engines/StructureEngine.mqh"
#include "engines/SupplyDemandEngine.mqh"
#include "engines/SnrEngine.mqh"
#include "engines/SnrPriorityEngine.mqh"
#include "engines/LiquidityEngine.mqh"
#include "engines/EntryEngine.mqh"
#include "engines/SessionBreakoutEngine.mqh"
#include "engines/VwapReversionEngine.mqh"

//====================================================================
input group "=== Pipeline ==="
input int    InpMaxBars            = 300;    // Max bars dianalisa engine

input group "=== MESIN A: CORE (Variant D - FADE) ==="
input bool   InpEnableCore         = true;   // Aktifkan Core
input double InpCoreRiskPercent    = 1.0;    // Core: risk per trade (%)
input double InpCoreTP_ATR         = 2.0;    // Core: TP (x ATR); SL 1.0 ATR dari engine
input long   InpCoreMagic          = 880118; // Core: magic

input group "=== MESIN B: BREAKOUT SCALPER (MOMENTUM) ==="
input bool   InpEnableBreakout     = true;   // Aktifkan Breakout
input double InpBoRiskPercent      = 0.25;   // Breakout: risk per trade (%) - KECIL
input double InpBoTP_ATR           = 0.80;   // Breakout: TP (x ATR) - profit kecil cepat
input double InpBoSL_ATR           = 0.80;   // Breakout: SL (x ATR) - ketat
input int    InpBoMaxBars          = 6;      // Breakout: forced exit (bar M30)
input bool   InpBoRequireTrend     = true;   // Breakout: hanya searah tren H4 (filter kualitas)
input double InpBoMinBreakATR      = 0.10;   // Breakout: jarak break minimum (x ATR) agar valid
input long   InpBoMagic            = 880120; // Breakout: magic (BEDA)

input group "=== MESIN C: SESSION RANGE BREAKOUT (M5 harian) ==="
input bool   InpEnableSession      = true;   // Aktifkan Session Breakout
input double InpSessRiskPercent    = 0.25;   // Session: risk per trade (%)
input int    InpSessAsiaStart      = 22;     // Jam mulai range Asia (server/UTC)
input int    InpSessAsiaEnd        = 6;      // Jam selesai range Asia
input int    InpSessWinStart       = 12;     // Jam mulai window entry (overlap)
input int    InpSessWinEnd         = 16;     // Jam selesai window entry
input double InpSessMinBreakUSD    = 0.50;   // Jarak tembus minimum (USD)
input double InpSessSLBufferUSD    = 0.50;   // Buffer SL di luar range (USD)
input double InpSessRR             = 1.20;   // Risk:Reward (TP = SL*RR)
input double InpSessATRSLCap       = 1.50;   // Cap SL maks = x ATR (proteksi range lebar)
input int    InpSessMaxBars        = 24;     // Forced exit (bar M5) ~2 jam
input long   InpSessMagic          = 880122; // Session: magic

input group "=== MESIN D: VWAP MEAN-REVERSION (M5 harian) ==="
input bool   InpEnableVwap         = true;   // Aktifkan VWAP Reversion
input double InpVwapRiskPercent    = 0.25;   // VWAP: risk per trade (%)
input double InpVwapBandSD         = 1.80;   // Entry bila |harga-VWAP| >= x SD
input double InpVwapStopSD         = 2.80;   // SL = x SD dari VWAP (lebih jauh)
input double InpVwapMaxADX         = 28.0;   // Matikan reversion bila ADX > ini
input int    InpVwapADXPeriod      = 14;     // Periode ADX (M5)
input int    InpVwapWinStart       = 7;      // Jam mulai aktif VWAP
input int    InpVwapWinEnd         = 20;     // Jam selesai aktif VWAP
input int    InpVwapMaxBars        = 18;     // Forced exit (bar M5) ~1.5 jam
input long   InpVwapMagic          = 880124; // VWAP: magic

input group "=== Risk Guards (global) ==="
input double InpDailyLossCapPct    = 3.0;    // Stop entry bila rugi harian > X% equity
input int    InpMaxTotalPositions  = 4;      // Maks total posisi serentak (semua mesin)
input double InpMaxLot             = 5.0;    // Cap lot
input double InpMinLot             = 0.01;   // Lot minimum
input double InpMaxSpreadPoints    = 500;    // Skip entry bila spread > X points
input bool   InpUseEquityRisk      = true;   // Risk dari Equity
input int    InpSlippagePoints     = 30;     // Slippage (points)

//====================================================================
CStructureEngine       gStructureEngine;
CSupplyDemandEngine    gSDEngine;
CSnrEngine             gSnrEngine;
CSnrPriorityEngine     gPriorityEngine;
CLiquidityEngine       gLiquidityEngine;
CEntryEngine           gEntryEngine;
CSessionBreakoutEngine gSessionEngine;
CVwapReversionEngine   gVwapEngine;
CTrade                 gTrade;

bool                gFirstRun = true;
datetime            gCurrentDay = 0;
double              gDayStartEquity = 0.0;
bool                gDayTradingHalted = false;
datetime            gLastBOSTimeTraded = 0;  // anti-duplikat BOS

//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== XAUUSD_EA v4.0 (QUAD: Core+Breakout+Session+VWAP) ===");
   if(InpVariantMode != VARIANT_D_EFF_OUTSIDE)
      Print("WARNING: InpVariantMode bukan 3 (Variant D). Set ke 3 untuk Core = SETD.");

   if(!gStructureEngine.Init())                                  { Print("ERR Structure"); return INIT_FAILED; }
   if(!gSDEngine.Init(&gStructureEngine))                        { Print("ERR SD");        return INIT_FAILED; }
   if(!gSnrEngine.Init(&gStructureEngine, &gSDEngine))           { Print("ERR Snr");       return INIT_FAILED; }
   if(!gLiquidityEngine.Init(&gPriorityEngine))                  { Print("ERR Liquidity"); return INIT_FAILED; }
   if(!gEntryEngine.Init(&gStructureEngine, &gLiquidityEngine))  { Print("ERR Entry");     return INIT_FAILED; }

   //--- Mesin C: Session Breakout (M5)
   gSessionEngine.Configure(InpSessAsiaStart, InpSessAsiaEnd, InpSessWinStart, InpSessWinEnd,
                            InpSessMinBreakUSD, InpSessSLBufferUSD, InpSessRR, InpSessATRSLCap);
   gSessionEngine.Init();

   //--- Mesin D: VWAP Reversion (M5)
   gVwapEngine.Configure(InpVwapBandSD, InpVwapStopSD, InpVwapMaxADX, InpVwapADXPeriod,
                         InpVwapWinStart, InpVwapWinEnd);
   if(!gVwapEngine.Init()) { Print("ERR VWAP"); return INIT_FAILED; }

   gTrade.SetDeviationInPoints(InpSlippagePoints);
   gTrade.SetTypeFillingBySymbol(_Symbol);
   gTrade.LogLevel(LOG_LEVEL_ERRORS);

   gFirstRun = true; gCurrentDay = 0; gDayTradingHalted = false; gLastBOSTimeTraded = 0;
   Print("Core=", (InpEnableCore?"ON":"OFF"), " | Breakout=", (InpEnableBreakout?"ON":"OFF"),
         " | Session=", (InpEnableSession?"ON":"OFF"), " | VWAP=", (InpEnableVwap?"ON":"OFF"));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   gVwapEngine.Deinit();
   gEntryEngine.Deinit(); gLiquidityEngine.Deinit(); gSnrEngine.Deinit();
   gSDEngine.Deinit(); gStructureEngine.Deinit();
   Print("=== XAUUSD_EA v4.0 Stopped ===");
}

//+------------------------------------------------------------------+
void OnTick()
{
   //=== GATE M5 -> mesin aktivitas harian (C Session, D VWAP) ===
   static datetime lastM5Time = 0;
   datetime currentM5Time = iTime(_Symbol, PERIOD_M5, 0);
   bool isNewM5Bar = (currentM5Time != 0 && currentM5Time != lastM5Time);
   if(isNewM5Bar || gFirstRun)
   {
      lastM5Time = currentM5Time;
      UpdateDailyTracker();
      ManageOpenPositions();
      if(!gDayTradingHalted)
         RunM5Engines(currentM5Time);
   }

   //=== GATE M30 -> mesin edge berkualitas (A Core, B Breakout) ===
   static datetime lastM30Time = 0;
   datetime currentM30Time = iTime(_Symbol, PERIOD_M30, 0);
   if(currentM30Time == 0) return;
   bool isNewM30Bar = (currentM30Time != lastM30Time);
   if(!isNewM30Bar && !gFirstRun) { gFirstRun = false; return; }
   lastM30Time = currentM30Time; gFirstRun = false;

   if(gDayTradingHalted) return;

   //--- Pipeline (identik SETD)
   StructureResult structRes = gStructureEngine.Analyze(InpMaxBars);
   if(!structRes.isValid) return;
   gSDEngine.Analyze(InpMaxBars);
   gSnrEngine.Analyze(InpMaxBars);

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(currentPrice <= 0.0) currentPrice = iClose(_Symbol, PERIOD_H4, 0);
   double atr = gSnrEngine.GetLocalATR(1);
   if(atr <= 0.0) return;

   if(!gPriorityEngine.Process(GetPointer(gSnrEngine), currentPrice, atr)) return;
   if(!gLiquidityEngine.Analyze()) return;

   //--- Spread guard global
   double spreadPts = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spreadPts > InpMaxSpreadPoints) return;
   if(TotalPositions() >= InpMaxTotalPositions) return;

   //=== MESIN A: CORE (FADE - Variant D) ===
   if(InpEnableCore && gEntryEngine.Analyze())
   {
      EntrySignal sig = gEntryEngine.GetSignal();
      if(sig.isValid && CountPositions(InpCoreMagic) == 0
         && !HasPositionAtTime(InpCoreMagic, sig.signalTime))
      {
         double atrUnit = MathAbs(sig.entryPrice - sig.stopLossPrice); // 1 ATR
         if(atrUnit > 0.0)
         {
            double tp = sig.isBuy ? sig.entryPrice + InpCoreTP_ATR*atrUnit
                                  : sig.entryPrice - InpCoreTP_ATR*atrUnit;
            OpenTrade(sig.isBuy, sig.stopLossPrice, tp, InpCoreRiskPercent, InpCoreMagic, "CORE_VarD");
         }
      }
   }

   //=== MESIN B: BREAKOUT (MOMENTUM - ikut BOS) ===
   if(InpEnableBreakout)
      TryBreakoutEntry(structRes.currentTrend, atr);
}

//+------------------------------------------------------------------+
//| MESIN C & D: dievaluasi tiap bar M5 (aktivitas harian)          |
//+------------------------------------------------------------------+
void RunM5Engines(datetime now)
{
   double spreadPts = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spreadPts > InpMaxSpreadPoints) return;

   //--- ATR M5 untuk cap SL session
   static int atrM5Handle = INVALID_HANDLE;
   if(atrM5Handle == INVALID_HANDLE) atrM5Handle = iATR(_Symbol, PERIOD_M5, 14);
   double atrM5 = 0.0; double atrBuf[];
   if(atrM5Handle != INVALID_HANDLE && CopyBuffer(atrM5Handle,0,1,1,atrBuf) > 0)
      atrM5 = atrBuf[0];

   //=== MESIN C: SESSION RANGE BREAKOUT ===
   if(InpEnableSession)
   {
      SessionBreakoutSignal cs = gSessionEngine.Evaluate(now, atrM5);
      if(cs.isValid && CountPositions(InpSessMagic) == 0
         && TotalPositions() < InpMaxTotalPositions)
      {
         if(OpenTrade(cs.isBuy, cs.slPrice, cs.tpPrice, InpSessRiskPercent, InpSessMagic, "SESSION"))
            gSessionEngine.MarkTraded(cs.isBuy);
      }
   }

   //=== MESIN D: VWAP MEAN-REVERSION ===
   if(InpEnableVwap)
   {
      VwapReversionSignal vs = gVwapEngine.Evaluate(now);
      if(vs.isValid && CountPositions(InpVwapMagic) == 0
         && TotalPositions() < InpMaxTotalPositions)
      {
         OpenTrade(vs.isBuy, vs.slPrice, vs.tpPrice, InpVwapRiskPercent, InpVwapMagic, "VWAP");
      }
   }
   else gVwapEngine.UpdateVWAP(now); // tetap akumulasi VWAP
}

//+------------------------------------------------------------------+
//| BREAKOUT: entry searah BOS terbaru (momentum)                    |
//+------------------------------------------------------------------+
void TryBreakoutEntry(ENUM_TREND_STATE trend, double atr)
{
   int bosCount = gStructureEngine.GetBOSCount();
   if(bosCount <= 0) return;

   //--- Ambil BOS paling baru (index terakhir)
   BOSEvent bos;
   if(!gStructureEngine.GetBOSEvent(bosCount - 1, bos)) return;
   if(bos.direction == BOS_NONE) return;

   //--- Anti-duplikat: jangan entry dua kali untuk BOS yang sama
   if(bos.barTime == gLastBOSTimeTraded) return;

   //--- Filter jarak break minimum (buang BOS lemah)
   double breakDistATR = (atr > 0.0) ? (bos.breakDistance / atr) : 0.0;
   if(breakDistATR < InpBoMinBreakATR) return;

   bool isBuy = (bos.direction == BOS_BULLISH);

   //--- Filter tren: hanya breakout searah tren H4 (kualitas)
   if(InpBoRequireTrend)
   {
      if(isBuy  && trend != TREND_BULLISH) return;
      if(!isBuy && trend != TREND_BEARISH) return;
   }

   if(CountPositions(InpBoMagic) > 0) return;

   //--- Eksekusi momentum dari harga pasar
   double entryRef = SymbolInfoDouble(_Symbol, isBuy ? SYMBOL_ASK : SYMBOL_BID);
   if(entryRef <= 0.0) return;
   double sl = isBuy ? entryRef - InpBoSL_ATR*atr : entryRef + InpBoSL_ATR*atr;
   double tp = isBuy ? entryRef + InpBoTP_ATR*atr : entryRef - InpBoTP_ATR*atr;

   if(OpenTrade(isBuy, sl, tp, InpBoRiskPercent, InpBoMagic, "BREAKOUT"))
      gLastBOSTimeTraded = bos.barTime;
}

//+------------------------------------------------------------------+
bool OpenTrade(bool isBuy, double slPrice, double tpPrice, double riskPct, long magic, string tag)
{
   double entryRef = SymbolInfoDouble(_Symbol, isBuy ? SYMBOL_ASK : SYMBOL_BID);
   double lots = CalcLotByRisk(entryRef, slPrice, riskPct);
   if(lots <= 0.0) { Print("SKIP ", tag, ": lot invalid"); return false; }

   gTrade.SetExpertMagicNumber(magic);
   bool ok = isBuy ? gTrade.Buy(lots, _Symbol, 0.0, slPrice, tpPrice, tag)
                   : gTrade.Sell(lots, _Symbol, 0.0, slPrice, tpPrice, tag);
   if(ok)
      Print("[", tag, "] OPEN ", (isBuy?"BUY":"SELL"), " lots=", DoubleToString(lots,2),
            " SL=", DoubleToString(slPrice,_Digits), " TP=", DoubleToString(tpPrice,_Digits));
   else
      Print("[", tag, "] GAGAL: ", gTrade.ResultRetcode(), " ", gTrade.ResultRetcodeDescription());
   return ok;
}

//+------------------------------------------------------------------+
double CalcLotByRisk(double entryPrice, double slPrice, double riskPct)
{
   double capital = InpUseEquityRisk ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = capital * (riskPct / 100.0);
   double slDist = MathAbs(entryPrice - slPrice);
   if(slDist <= 0.0) return 0.0;
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0) return 0.0;
   double lossPerLot = (slDist / tickSize) * tickValue;
   if(lossPerLot <= 0.0) return 0.0;
   double lots = riskMoney / lossPerLot;
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = MathMax(InpMinLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   double maxLot  = MathMin(InpMaxLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   if(lotStep > 0.0) lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   datetime curM30 = iTime(_Symbol, PERIOD_M30, 0);
   datetime curM5  = iTime(_Symbol, PERIOD_M5, 0);
   int secM30 = PeriodSeconds(PERIOD_M30);
   int secM5  = PeriodSeconds(PERIOD_M5);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      int maxBars = 0; ENUM_TIMEFRAMES tf = PERIOD_M30;
      if(magic == InpCoreMagic)         { maxBars = 12;             tf = PERIOD_M30; }
      else if(magic == InpBoMagic)      { maxBars = InpBoMaxBars;   tf = PERIOD_M30; }
      else if(magic == InpSessMagic)    { maxBars = InpSessMaxBars; tf = PERIOD_M5;  }
      else if(magic == InpVwapMagic)    { maxBars = InpVwapMaxBars; tf = PERIOD_M5;  }
      else continue;
      datetime curBar = (tf == PERIOD_M5) ? curM5 : curM30;
      int barSecs     = (tf == PERIOD_M5) ? secM5 : secM30;
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      datetime openBar  = (datetime)((long)openTime - ((long)openTime % barSecs));
      int barsElapsed = (int)((curBar - openBar) / barSecs);
      if(barsElapsed >= maxBars)
      {
         gTrade.SetExpertMagicNumber(magic);
         if(gTrade.PositionClose(ticket))
            Print("[EXIT] forced-time magic=", magic, " bars=", barsElapsed);
      }
   }
}

//+------------------------------------------------------------------+
void UpdateDailyTracker()
{
   datetime curBar = iTime(_Symbol, PERIOD_M30, 0);
   datetime day = (datetime)((long)curBar - ((long)curBar % 86400));
   if(day != gCurrentDay)
   {
      gCurrentDay = day;
      gDayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      gDayTradingHalted = false;
   }
   if(gDayStartEquity > 0.0 && InpDailyLossCapPct > 0.0)
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double lossPct = (gDayStartEquity - eq) / gDayStartEquity * 100.0;
      if(lossPct >= InpDailyLossCapPct && !gDayTradingHalted)
      {
         gDayTradingHalted = true;
         Print("[GUARD] Daily loss cap ", DoubleToString(lossPct,2), "% -> stop entry hari ini.");
      }
   }
}

//+------------------------------------------------------------------+
datetime iTimeOfBar(datetime t) { int s=PeriodSeconds(PERIOD_M30); return (datetime)((long)t-((long)t%s)); }

int CountPositions(long magic)
{
   int c=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t=PositionGetTicket(i);
      if(t==0||!PositionSelectByTicket(t))continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic)continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue; c++; }
   return c;
}
int TotalPositions()
{
   int c=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t=PositionGetTicket(i);
      if(t==0||!PositionSelectByTicket(t))continue;
      long m=PositionGetInteger(POSITION_MAGIC);
      if((m==InpCoreMagic||m==InpBoMagic||m==InpSessMagic||m==InpVwapMagic)
         &&PositionGetString(POSITION_SYMBOL)==_Symbol)c++; }
   return c;
}
bool HasPositionAtTime(long magic, datetime signalTime)
{
   datetime sBar=iTimeOfBar(signalTime);
   for(int i=PositionsTotal()-1;i>=0;i--){ ulong t=PositionGetTicket(i);
      if(t==0||!PositionSelectByTicket(t))continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic)continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue;
      if(iTimeOfBar((datetime)PositionGetInteger(POSITION_TIME))==sBar)return true; }
   return false;
}
//+------------------------------------------------------------------+
