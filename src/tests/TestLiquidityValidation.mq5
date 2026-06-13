//+------------------------------------------------------------------+
//|                                     TestLiquidityValidation.mq5   |
//|                   Statistical Validation EA for LiquidityEngine  |
//|                   Version 1.0 - Phase 4.3 Review                 |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Run CLiquidityEngine over historical XAUUSD data.              |
//|   Collect breach events, MFE, MAE, and Close outcomes across:    |
//|   - 12 bars (6 hours)                                            |
//|   - 24 bars (12 hours)                                           |
//|   - 48 bars (24 hours)                                           |
//|   No trading, no entries, no optimizations.                       |
//|                                                                  |
//| USAGE:                                                           |
//|   Run in Strategy Tester on XAUUSD, M30 timeframe, 2022-2025.    |
//|   Output will be written to common folder LiquidityValidation.csv |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

//--- Include Engine Chain
#include "../engines/StructureEngine.mqh"
#include "../engines/SupplyDemandEngine.mqh"
#include "../engines/SnrEngine.mqh"
#include "../engines/SnrPriorityEngine.mqh"
#include "../engines/LiquidityEngine.mqh"

//====================================================================
// INPUT PARAMETERS
//====================================================================
input int InpTestMaxBars = 300; // Test: Max bars to analyze

//====================================================================
// STRUCTS & GLOBALS
//====================================================================
struct ActiveEvent
{
   datetime  eventTime;          // Open time of M30 bar 1 when breach occurred
   string    poolType;           // "BSL" or "SSL"
   bool      isBreached;
   bool      isRejected;
   double    sweepSizeATR;
   bool      isLargeExcursion;
   double    poolStrength;
   double    nearestPoolDistance;
   
   double    entryPrice;         // Close of breach bar
   double    atr;                // H4 ATR at the time
   
   double    maxFavorableMove;   // Running raw points
   double    maxAdverseMove;     // Running raw points
   int       barsElapsed;        // M30 bars elapsed
   
   double    mfe12;              // Horizon values
   double    mae12;
   double    close12;
   
   double    mfe24;
   double    mae24;
   double    close24;
   
   double    mfe48;
   double    mae48;
   double    close48;
   
   double    poolPriceHigh;
   double    poolPriceLow;
   double    barHigh;
   double    barLow;
   double    barClose;
   double    barOpen;
};

//--- Pipeline Engines
CStructureEngine    gStructureEngine;
CSupplyDemandEngine gSDEngine;
CSnrEngine          gSnrEngine;
CSnrPriorityEngine  gPriorityEngine;
CLiquidityEngine    gLiquidityEngine;

//--- State variables
bool                gFirstRun = true;
int                 g_fileHandle = INVALID_HANDLE;
ActiveEvent         g_activeEvents[];

//--- Simple Stats
int                 g_totalBreaches = 0;
int                 g_totalRejections = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestLiquidityValidation Starting ===");

   //--- Initialize Engine Chain
   if(!gStructureEngine.Init())
   {
      Print("ERROR: Failed to initialize StructureEngine");
      return INIT_FAILED;
   }
   if(!gSDEngine.Init(&gStructureEngine))
   {
      Print("ERROR: Failed to initialize SupplyDemandEngine");
      return INIT_FAILED;
   }
   if(!gSnrEngine.Init(&gStructureEngine, &gSDEngine))
   {
      Print("ERROR: Failed to initialize SnrEngine");
      return INIT_FAILED;
   }
   if(!gLiquidityEngine.Init(&gPriorityEngine))
   {
      Print("ERROR: Failed to initialize LiquidityEngine");
      return INIT_FAILED;
   }

   //--- Open CSV File in Common folder
   g_fileHandle = FileOpen("LiquidityValidation.csv", FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
   if(g_fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to open LiquidityValidation.csv for writing");
      return INIT_FAILED;
   }

   //--- Write Header
   FileWrite(g_fileHandle, 
             "datetime", "poolType", "isBreached", "isRejected", "sweepSizeATR", "isLargeExcursion", "poolStrength", "nearestPoolDistance",
             "mfe12_ATR", "mae12_ATR", "close12_ATR",
             "mfe24_ATR", "mae24_ATR", "close24_ATR",
             "mfe48_ATR", "mae48_ATR", "close48_ATR",
             "poolPriceHigh", "poolPriceLow", "barHigh", "barLow", "barClose", "barOpen", "atrVal");
   FileFlush(g_fileHandle);

   gFirstRun = true;
   g_totalBreaches = 0;
   g_totalRejections = 0;
   ArrayResize(g_activeEvents, 0);

   Print("TestLiquidityValidation initialized successfully. Exporting to common Files/LiquidityValidation.csv");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Flush any remaining active events at backtest end
   FlushAllRemainingEvents();

   if(g_fileHandle != INVALID_HANDLE)
   {
      FileClose(g_fileHandle);
      g_fileHandle = INVALID_HANDLE;
   }

   gLiquidityEngine.Deinit();
   gSnrEngine.Deinit();
   gSDEngine.Deinit();
   gStructureEngine.Deinit();

   Print("=== TestLiquidityValidation Stopped ===");
   Print("  Total Breaches Logged:   ", g_totalBreaches);
   Print("  Total Rejections Logged: ", g_totalRejections);
   if(g_totalBreaches > 0)
   {
      double rate = (double)g_totalRejections / g_totalBreaches * 100.0;
      Print("  Empirical Rejection Rate: ", DoubleToString(rate, 2), "%");
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Track bar updates on M30 timeframe (since sweep validation is on M30)
   static datetime lastM30Time = 0;
   datetime currentM30Time = iTime(_Symbol, PERIOD_M30, 0);
   if(currentM30Time == 0) return;

   bool isNewM30Bar = (currentM30Time != lastM30Time);
   if(!isNewM30Bar && !gFirstRun) return;

   lastM30Time = currentM30Time;
   gFirstRun = false;

   //--- 1. Update running outcomes for existing active events using closed M30 bar 1
   UpdateActiveEvents();

   //--- 2. Execute Upstream Engine Pipeline
   StructureResult structRes = gStructureEngine.Analyze(InpTestMaxBars);
   if(!structRes.isValid) return;

   gSDEngine.Analyze(InpTestMaxBars);
   gSnrEngine.Analyze(InpTestMaxBars);

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(currentPrice <= 0.0)
      currentPrice = iClose(_Symbol, PERIOD_H4, 0);
   double atr = gSnrEngine.GetLocalATR(1);

   if(!gPriorityEngine.Process(GetPointer(gSnrEngine), currentPrice, atr)) return;

   //--- 3. Run Liquidity Engine
   if(!gLiquidityEngine.Analyze()) return;

   //--- 4. Check for new breach events on closed M30 bar 1
   LiquidityPriorityContract contract = gLiquidityEngine.GetContract();
   double m30Open = iOpen(_Symbol, PERIOD_M30, 1);

   if(contract.isBSLBreached)
   {
      RegisterNewEvent("BSL", contract.isBSLBreached, contract.isBSLRejected, contract.bslSweepSizeATR, 
                        contract.isLargeExcursion, contract.nearestBSL.liquidityStrength, 
                        MathAbs(m30Open - contract.nearestBSL.priceLow), iClose(_Symbol, PERIOD_M30, 1), iTime(_Symbol, PERIOD_M30, 1),
                        contract.nearestBSL.priceHigh, contract.nearestBSL.priceLow,
                        iHigh(_Symbol, PERIOD_M30, 1), iLow(_Symbol, PERIOD_M30, 1), iClose(_Symbol, PERIOD_M30, 1), m30Open);
   }

   if(contract.isSSLBreached)
   {
      RegisterNewEvent("SSL", contract.isSSLBreached, contract.isSSLRejected, contract.sslSweepSizeATR, 
                        contract.isLargeExcursion, contract.nearestSSL.liquidityStrength, 
                        MathAbs(m30Open - contract.nearestSSL.priceHigh), iClose(_Symbol, PERIOD_M30, 1), iTime(_Symbol, PERIOD_M30, 1),
                        contract.nearestSSL.priceHigh, contract.nearestSSL.priceLow,
                        iHigh(_Symbol, PERIOD_M30, 1), iLow(_Symbol, PERIOD_M30, 1), iClose(_Symbol, PERIOD_M30, 1), m30Open);
   }
}

//+------------------------------------------------------------------+
//| RegisterNewEvent: Add breach to tracking array                  |
//+------------------------------------------------------------------+
void RegisterNewEvent(string poolType, bool isBreached, bool isRejected, double sweepSize, 
                      bool isLargeEx, double strength, double distance, double entryPrice, datetime eventTime,
                      double poolHigh, double poolLow, double bHigh, double bLow, double bClose, double bOpen)
{
   // Check for duplicate logs (only add if not already tracked)
   int size = ArraySize(g_activeEvents);
   for(int i = 0; i < size; i++)
   {
      if(g_activeEvents[i].eventTime == eventTime && g_activeEvents[i].poolType == poolType)
         return; // Already registered
   }

   ArrayResize(g_activeEvents, size + 1);
   g_activeEvents[size].eventTime = eventTime;
   g_activeEvents[size].poolType = poolType;
   g_activeEvents[size].isBreached = isBreached;
   g_activeEvents[size].isRejected = isRejected;
   g_activeEvents[size].sweepSizeATR = sweepSize;
   g_activeEvents[size].isLargeExcursion = isLargeEx;
   g_activeEvents[size].poolStrength = strength;
   g_activeEvents[size].nearestPoolDistance = distance;
   g_activeEvents[size].entryPrice = entryPrice;
   g_activeEvents[size].atr = gSnrEngine.GetLocalATR(1);
   g_activeEvents[size].maxFavorableMove = 0.0;
   g_activeEvents[size].maxAdverseMove = 0.0;
   g_activeEvents[size].barsElapsed = 0;
   g_activeEvents[size].poolPriceHigh = poolHigh;
   g_activeEvents[size].poolPriceLow = poolLow;
   g_activeEvents[size].barHigh = bHigh;
   g_activeEvents[size].barLow = bLow;
   g_activeEvents[size].barClose = bClose;
   g_activeEvents[size].barOpen = bOpen;
   
   // Draw visual markers immediately when the breach event is detected
   DrawEventVisuals(g_activeEvents[size]);
   
   // Print event-level log to the MT5 journal
   Print("[CLiquidityEngine] Liquidity breach detected: ", poolType, 
         " | Outcome: ", (isRejected ? "Rejection" : "Breakout"), 
         " | Time: ", TimeToString(eventTime), 
         " | Sweep Size: ", DoubleToString(sweepSize, 4), " ATR");
}

//+------------------------------------------------------------------+
//| UpdateActiveEvents: Track price excursion over subsequent bars  |
//+------------------------------------------------------------------+
void UpdateActiveEvents()
{
   int size = ArraySize(g_activeEvents);
   if(size == 0) return;

   double highVal  = iHigh(_Symbol, PERIOD_M30, 1);
   double lowVal   = iLow(_Symbol, PERIOD_M30, 1);
   double closeVal = iClose(_Symbol, PERIOD_M30, 1);

   for(int i = size - 1; i >= 0; i--)
   {
      g_activeEvents[i].barsElapsed++;
      
      double favMove = 0.0;
      double advMove = 0.0;
      
      if(g_activeEvents[i].poolType == "BSL")
      {
         // Short reversal: Favorable is down, adverse is up
         favMove = g_activeEvents[i].entryPrice - lowVal;
         advMove = highVal - g_activeEvents[i].entryPrice;
      }
      else
      {
         // Long reversal: Favorable is up, adverse is down
         favMove = highVal - g_activeEvents[i].entryPrice;
         advMove = g_activeEvents[i].entryPrice - lowVal;
      }
      
      if(favMove < 0.0) favMove = 0.0;
      if(advMove < 0.0) advMove = 0.0;
      
      g_activeEvents[i].maxFavorableMove = MathMax(g_activeEvents[i].maxFavorableMove, favMove);
      g_activeEvents[i].maxAdverseMove = MathMax(g_activeEvents[i].maxAdverseMove, advMove);
      
      // Store 12 bar horizon metrics
      if(g_activeEvents[i].barsElapsed == 12)
      {
         g_activeEvents[i].mfe12   = g_activeEvents[i].maxFavorableMove;
         g_activeEvents[i].mae12   = g_activeEvents[i].maxAdverseMove;
         g_activeEvents[i].close12 = (g_activeEvents[i].poolType == "BSL") ? (g_activeEvents[i].entryPrice - closeVal) : (closeVal - g_activeEvents[i].entryPrice);
      }
      // Store 24 bar horizon metrics
      else if(g_activeEvents[i].barsElapsed == 24)
      {
         g_activeEvents[i].mfe24   = g_activeEvents[i].maxFavorableMove;
         g_activeEvents[i].mae24   = g_activeEvents[i].maxAdverseMove;
         g_activeEvents[i].close24 = (g_activeEvents[i].poolType == "BSL") ? (g_activeEvents[i].entryPrice - closeVal) : (closeVal - g_activeEvents[i].entryPrice);
      }
      // Store 48 bar horizon metrics & Write record
      else if(g_activeEvents[i].barsElapsed == 48)
      {
         g_activeEvents[i].mfe48   = g_activeEvents[i].maxFavorableMove;
         g_activeEvents[i].mae48   = g_activeEvents[i].maxAdverseMove;
         g_activeEvents[i].close48 = (g_activeEvents[i].poolType == "BSL") ? (g_activeEvents[i].entryPrice - closeVal) : (closeVal - g_activeEvents[i].entryPrice);
         
         WriteEventToCSV(g_activeEvents[i]);
         DeleteActiveEvent(i);
      }
   }
}

//+------------------------------------------------------------------+
//| WriteEventToCSV: Write finalized record to CSV                  |
//+------------------------------------------------------------------+
void WriteEventToCSV(const ActiveEvent &ev)
{
   if(g_fileHandle == INVALID_HANDLE) return;
   
   string dtStr = TimeToString(ev.eventTime, TIME_DATE | TIME_MINUTES);
   string poolType = ev.poolType;
   int breached = ev.isBreached ? 1 : 0;
   int rejected = ev.isRejected ? 1 : 0;
   
   string sweepSize = DoubleToString(ev.sweepSizeATR, 4);
   int largeEx = ev.isLargeExcursion ? 1 : 0;
   string strength = DoubleToString(ev.poolStrength, 2);
   string dist = DoubleToString(ev.nearestPoolDistance, _Digits);
   
   double normalATR = ev.atr;
   if(normalATR <= 0.0) normalATR = 0.0001;
   
   string mfe12 = (ev.barsElapsed >= 12) ? DoubleToString(ev.mfe12 / normalATR, 4) : "0.0000";
   string mae12 = (ev.barsElapsed >= 12) ? DoubleToString(ev.mae12 / normalATR, 4) : "0.0000";
   string cls12 = (ev.barsElapsed >= 12) ? DoubleToString(ev.close12 / normalATR, 4) : "0.0000";
   
   string mfe24 = (ev.barsElapsed >= 24) ? DoubleToString(ev.mfe24 / normalATR, 4) : "0.0000";
   string mae24 = (ev.barsElapsed >= 24) ? DoubleToString(ev.mae24 / normalATR, 4) : "0.0000";
   string cls24 = (ev.barsElapsed >= 24) ? DoubleToString(ev.close24 / normalATR, 4) : "0.0000";
   
   string mfe48 = (ev.barsElapsed >= 48) ? DoubleToString(ev.mfe48 / normalATR, 4) : "0.0000";
   string mae48 = (ev.barsElapsed >= 48) ? DoubleToString(ev.mae48 / normalATR, 4) : "0.0000";
   string cls48 = (ev.barsElapsed >= 48) ? DoubleToString(ev.close48 / normalATR, 4) : "0.0000";
   
   // Handle prematurely closed events at the end of the test
   if(ev.barsElapsed < 48)
   {
      double curMFE = ev.maxFavorableMove;
      double curMAE = ev.maxAdverseMove;
      double curClose = 0.0;
      double lastClose = iClose(_Symbol, PERIOD_M30, 0);
      if(ev.poolType == "BSL")
         curClose = ev.entryPrice - lastClose;
      else
         curClose = lastClose - ev.entryPrice;
         
      if(ev.barsElapsed < 12)
      {
         mfe12 = DoubleToString(curMFE / normalATR, 4);
         mae12 = DoubleToString(curMAE / normalATR, 4);
         cls12 = DoubleToString(curClose / normalATR, 4);
      }
      if(ev.barsElapsed < 24)
      {
         mfe24 = DoubleToString(curMFE / normalATR, 4);
         mae24 = DoubleToString(curMAE / normalATR, 4);
         cls24 = DoubleToString(curClose / normalATR, 4);
      }
      mfe48 = DoubleToString(curMFE / normalATR, 4);
      mae48 = DoubleToString(curMAE / normalATR, 4);
      cls48 = DoubleToString(curClose / normalATR, 4);
   }
   
   FileWrite(g_fileHandle, 
             dtStr, poolType, breached, rejected, sweepSize, largeEx, strength, dist,
             mfe12, mae12, cls12,
             mfe24, mae24, cls24,
             mfe48, mae48, cls48,
             DoubleToString(ev.poolPriceHigh, _Digits),
             DoubleToString(ev.poolPriceLow, _Digits),
             DoubleToString(ev.barHigh, _Digits),
             DoubleToString(ev.barLow, _Digits),
             DoubleToString(ev.barClose, _Digits),
             DoubleToString(ev.barOpen, _Digits),
             DoubleToString(ev.atr, 4));
   
   // Stats accumulation
   g_totalBreaches++;
   if(ev.isRejected) g_totalRejections++;
}

//+------------------------------------------------------------------+
//| DeleteActiveEvent: Remove item from dynamic array               |
//+------------------------------------------------------------------+
void DeleteActiveEvent(int index)
{
   int size = ArraySize(g_activeEvents);
   if(size == 0 || index < 0 || index >= size) return;
   
   for(int i = index; i < size - 1; i++)
   {
      g_activeEvents[i] = g_activeEvents[i+1];
   }
   ArrayResize(g_activeEvents, size - 1);
}

//+------------------------------------------------------------------+
//| FlushAllRemainingEvents: Write pending trackers at test end     |
//+------------------------------------------------------------------+
void FlushAllRemainingEvents()
{
   int size = ArraySize(g_activeEvents);
   for(int i = size - 1; i >= 0; i--)
   {
      WriteEventToCSV(g_activeEvents[i]);
      DeleteActiveEvent(i);
   }
}

//+------------------------------------------------------------------+
//| DrawEventVisuals: Render visual markers on the chart            |
//+------------------------------------------------------------------+
void DrawEventVisuals(const ActiveEvent &ev)
{
   // Only draw if visual mode is active
   if(!MQLInfoInteger(MQL_VISUAL_MODE)) return;

   string timeStr = TimeToString(ev.eventTime, TIME_DATE | TIME_MINUTES);
   string poolType = ev.poolType;
   
   string rectName = "LiqPool_" + poolType + "_" + timeStr;
   string breachName = "LiqBreach_" + poolType + "_" + timeStr;
   string markerName = "LiqMarker_" + poolType + "_" + timeStr;
   
   color poolColor = (poolType == "BSL") ? clrDeepSkyBlue : clrOrangeRed;
   datetime startTime = ev.eventTime - 12 * 1800; // 12 M30 bars back
   
   // 1. Draw Pool Rectangle
   if(ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, ev.poolPriceHigh, ev.eventTime, ev.poolPriceLow))
   {
      ObjectSetInteger(0, rectName, OBJPROP_COLOR, poolColor);
      ObjectSetInteger(0, rectName, OBJPROP_FILL, false);
      ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
      ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
   }
   
   // 2. Draw Breach Line/Dot
   double breachPrice = (poolType == "BSL") ? ev.barHigh : ev.barLow;
   if(ObjectCreate(0, breachName, OBJ_TEXT, 0, ev.eventTime, breachPrice))
   {
      ObjectSetString(0, breachName, OBJPROP_TEXT, "x");
      ObjectSetInteger(0, breachName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, breachName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, breachName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, breachName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, breachName, OBJPROP_SELECTABLE, false);
   }
   
   // 3. Draw Rejection / Non-Rejection Marker
   string markerText = ev.isRejected ? "REJ" : "BREAKOUT";
   color markerColor = ev.isRejected ? clrLimeGreen : clrYellow;
   double markerPrice = ev.barClose;
   
   if(ObjectCreate(0, markerName, OBJ_TEXT, 0, ev.eventTime, markerPrice))
   {
      ObjectSetString(0, markerName, OBJPROP_TEXT, markerText);
      ObjectSetInteger(0, markerName, OBJPROP_COLOR, markerColor);
      ObjectSetInteger(0, markerName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, markerName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, markerName, OBJPROP_ANCHOR, (poolType == "BSL") ? ANCHOR_UPPER : ANCHOR_LOWER);
      ObjectSetInteger(0, markerName, OBJPROP_SELECTABLE, false);
   }
}
