//+------------------------------------------------------------------+
//|                                                    TestEntry.mq5 |
//|                   Backtest Validator for EntryEngine             |
//|                        Version 1.0 - Phase 5A                    |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Evaluate EntryEngine v1.0 performance with and without the H4  |
//|   Trend Gate on historical XAUUSD data from 2022 to 2025.        |
//|                                                                  |
//| USAGE:                                                           |
//|   Run in Strategy Tester on XAUUSD, M30 timeframe, 2022-2025.    |
//|   Results will be printed directly to the Strategy Tester log.    |
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
#include "../engines/EntryEngine.mqh"

//====================================================================
// INPUT PARAMETERS
//====================================================================
input int InpTestMaxBars = 300; // Test: Max bars to analyze

//====================================================================
// VIRTUAL TRADE STRUCT
//====================================================================
struct VirtualTrade
{
   bool     isBuy;
   double   entryPrice;
   double   stopLoss;
   double   takeProfit;
   double   atr;
   datetime entryTime;
   int      barsElapsed;
   bool     isClosed;
   double   exitPrice;
   string   exitReason; // "TP", "SL", "TIME", or "FORCE_CLOSE"
   int      entryYear;
};

//--- Pipeline Engines
CStructureEngine    gStructureEngine;
CSupplyDemandEngine gSDEngine;
CSnrEngine          gSnrEngine;
CSnrPriorityEngine  gPriorityEngine;
CLiquidityEngine    gLiquidityEngine;
CEntryEngine        gEntryEngine;

//--- State variables
bool                gFirstRun = true;
VirtualTrade        g_trades[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestEntry Validation EA Starting ===");

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
   if(!gEntryEngine.Init(&gStructureEngine, &gLiquidityEngine))
   {
      Print("ERROR: Failed to initialize EntryEngine");
      return INIT_FAILED;
   }

   gFirstRun = true;
   ArrayResize(g_trades, 0);

   Print("TestEntry Validation EA initialized successfully.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Force close any remaining active virtual trades at backtest end
   ForceCloseAllActive();

   // Print final validation report
   PrintReport();

   gEntryEngine.Deinit();
   gLiquidityEngine.Deinit();
   gSnrEngine.Deinit();
   gSDEngine.Deinit();
   gStructureEngine.Deinit();

   Print("=== TestEntry Validation EA Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Track bar updates on M30 timeframe
   static datetime lastM30Time = 0;
   datetime currentM30Time = iTime(_Symbol, PERIOD_M30, 0);
   if(currentM30Time == 0) return;

   bool isNewM30Bar = (currentM30Time != lastM30Time);
   if(!isNewM30Bar && !gFirstRun) return;

   lastM30Time = currentM30Time;
   gFirstRun = false;

   //--- 1. Update running outcomes for existing active virtual trades using closed M30 bar 1
   UpdateActiveTrades();

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

   //--- 4. Run Entry Engine to validate filters
   if(gEntryEngine.Analyze())
   {
      EntrySignal signal = gEntryEngine.GetSignal();
      if(signal.isValid)
      {
         RegisterNewVirtualTrade(signal, atr);
      }
   }
}

//+------------------------------------------------------------------+
//| RegisterNewVirtualTrade: Store trade in database                 |
//+------------------------------------------------------------------+
void RegisterNewVirtualTrade(const EntrySignal &signal, double atr)
{
   // Check for duplicate signals on the same timestamp
   int size = ArraySize(g_trades);
   for(int i = 0; i < size; i++)
   {
      if(g_trades[i].entryTime == signal.signalTime && g_trades[i].isBuy == signal.isBuy)
         return; // Duplicate
   }

   MqlDateTime dt;
   TimeToStruct(signal.signalTime, dt);

   ArrayResize(g_trades, size + 1);
   g_trades[size].isBuy              = signal.isBuy;
   g_trades[size].entryPrice         = signal.entryPrice;
   g_trades[size].stopLoss           = signal.stopLossPrice;
   g_trades[size].takeProfit         = signal.takeProfitPrice;
   g_trades[size].atr                = atr;
   g_trades[size].entryTime          = signal.signalTime;
   g_trades[size].barsElapsed        = 0;
   g_trades[size].isClosed           = false;
   g_trades[size].exitPrice          = 0.0;
   g_trades[size].exitReason         = "";
   g_trades[size].entryYear          = dt.year;

   Print("[TestEntry] Virtual Trade OPENED: ", (signal.isBuy ? "BUY" : "SELL"),
         " | Entry: ", DoubleToString(signal.entryPrice, _Digits),
         " | SL: ", DoubleToString(signal.stopLossPrice, _Digits),
         " | TP: ", DoubleToString(signal.takeProfitPrice, _Digits),
         " | Year: ", dt.year);
}

//+------------------------------------------------------------------+
//| UpdateActiveTrades: Check outcomes on closed M30 Bar 1           |
//+------------------------------------------------------------------+
void UpdateActiveTrades()
{
   int size = ArraySize(g_trades);
   if(size == 0) return;

   double highVal  = iHigh(_Symbol, PERIOD_M30, 1);
   double lowVal   = iLow(_Symbol, PERIOD_M30, 1);
   double closeVal = iClose(_Symbol, PERIOD_M30, 1);

   for(int i = 0; i < size; i++)
   {
      if(g_trades[i].isClosed)
         continue;

      g_trades[i].barsElapsed++;

      if(g_trades[i].isBuy)
      {
         // Buy trade check
         bool tpTup = (highVal >= g_trades[i].takeProfit);
         bool slTup = (lowVal <= g_trades[i].stopLoss);

         if(tpTup && slTup)
         {
            // Both hit in the same bar, assume SL (conservative)
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].stopLoss;
            g_trades[i].exitReason = "SL";
         }
         else if(slTup)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].stopLoss;
            g_trades[i].exitReason = "SL";
         }
         else if(tpTup)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].takeProfit;
            g_trades[i].exitReason = "TP";
         }
         else if(g_trades[i].barsElapsed >= 12)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = closeVal;
            g_trades[i].exitReason = "TIME";
         }
      }
      else
      {
         // Sell trade check
         bool tpTup = (lowVal <= g_trades[i].takeProfit);
         bool slTup = (highVal >= g_trades[i].stopLoss);

         if(tpTup && slTup)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].stopLoss;
            g_trades[i].exitReason = "SL";
         }
         else if(slTup)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].stopLoss;
            g_trades[i].exitReason = "SL";
         }
         else if(tpTup)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = g_trades[i].takeProfit;
            g_trades[i].exitReason = "TP";
         }
         else if(g_trades[i].barsElapsed >= 12)
         {
            g_trades[i].isClosed = true;
            g_trades[i].exitPrice = closeVal;
            g_trades[i].exitReason = "TIME";
         }
      }

      if(g_trades[i].isClosed)
      {
         double pPoints = g_trades[i].isBuy ? (g_trades[i].exitPrice - g_trades[i].entryPrice) : (g_trades[i].entryPrice - g_trades[i].exitPrice);
         double pATR = pPoints / g_trades[i].atr;
         
         Print("[TestEntry] Virtual Trade CLOSED: ", (g_trades[i].isBuy ? "BUY" : "SELL"),
               " | Exit: ", DoubleToString(g_trades[i].exitPrice, _Digits),
               " | Reason: ", g_trades[i].exitReason,
               " | Profit: ", DoubleToString(pATR, 4), " ATR",
               " | Bars Held: ", g_trades[i].barsElapsed);
      }
   }
}

//+------------------------------------------------------------------+
//| ForceCloseAllActive: Close open trades at tester end             |
//+------------------------------------------------------------------+
void ForceCloseAllActive()
{
   int size = ArraySize(g_trades);
   double lastClose = iClose(_Symbol, PERIOD_M30, 0);
   for(int i = 0; i < size; i++)
   {
      if(!g_trades[i].isClosed)
      {
         g_trades[i].isClosed = true;
         g_trades[i].exitPrice = lastClose;
         g_trades[i].exitReason = "FORCE_CLOSE";
      }
   }
}

//+------------------------------------------------------------------+
//| PrintReport: Annualized metrics summary                         |
//+------------------------------------------------------------------+
void PrintReport()
{
   Print("==========================================================================================");
   Print("                         PHASE 5A ENTRY ENGINE VALIDATION REPORT                          ");
   Print("==========================================================================================");
   Print("Parameters: MinRejectionMargin = ", DoubleToString(InpMinRejectionMarginATR, 2), " ATR");
   Print("            EnableTrendGate      = ", InpEnableTrendGate ? "YES" : "NO");
   Print("------------------------------------------------------------------------------------------");
   Print("YEAR   | TRADES | WIN RATE | EXPECTANCY (ATR) | PROFIT FACTOR | AVERAGE R ");
   Print("------------------------------------------------------------------------------------------");
   
   PrintYearStats(-1);   // TOTAL
   PrintYearStats(2022); // 2022
   PrintYearStats(2023); // 2023
   PrintYearStats(2024); // 2024
   PrintYearStats(2025); // 2025
   Print("==========================================================================================");
}

//+------------------------------------------------------------------+
//| PrintYearStats: Compute and output year metrics                  |
//+------------------------------------------------------------------+
void PrintYearStats(int targetYear)
{
   int tradeCount = 0;
   int winCount = 0;
   double totalProfitATR = 0.0;
   double grossProfitATR = 0.0;
   double grossLossATR = 0.0;
   
   int size = ArraySize(g_trades);
   for(int i = 0; i < size; i++)
   {
      if(targetYear != -1 && g_trades[i].entryYear != targetYear)
         continue;
         
      tradeCount++;
      double profitPoints = g_trades[i].isBuy ? (g_trades[i].exitPrice - g_trades[i].entryPrice) : (g_trades[i].entryPrice - g_trades[i].exitPrice);
      double profitATR = profitPoints / g_trades[i].atr;
      
      totalProfitATR += profitATR;
      
      if(profitATR > 0.0)
      {
         grossProfitATR += profitATR;
      }
      else
      {
         grossLossATR += MathAbs(profitATR);
      }
      
      if(g_trades[i].exitReason == "TP")
      {
         winCount++;
      }
   }
   
   string label = (targetYear == -1) ? "TOTAL" : IntegerToString(targetYear);
   
   double winRate = (tradeCount > 0) ? ((double)winCount / tradeCount * 100.0) : 0.0;
   double expectancy = (tradeCount > 0) ? (totalProfitATR / tradeCount) : 0.0;
   double profitFactor = (grossLossATR > 0.0) ? (grossProfitATR / grossLossATR) : (grossProfitATR > 0.0 ? 99.99 : 0.0);
   double avgR = expectancy; // Since SL is exactly 1.0 ATR
   
   Print(StringFormat("%-6s |  %-5d |  %6.2f%% |      %+.4f      |     %6.2f    |  %+.4f R",
                      label, tradeCount, winRate, expectancy, profitFactor, avgR));
}
