//+------------------------------------------------------------------+
//|                                              TestLiquidity.mq5   |
//|                   Visual/Log Test for LiquidityEngine.mqh v1.0   |
//|                   Version 1.0 - Phase 4.2 Step 2                 |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Verify CLiquidityEngine skeleton:                              |
//|   - Successful compilation                                       |
//|   - Successful initialization within the engine chain            |
//|   - Correct contract flow (data matching upstream SnrPriority)  |
//|                                                                  |
//| USAGE:                                                           |
//|   Attach as Expert Advisor on XAUUSD chart.                      |
//|   Check the Experts log for contract flow verification logs.     |
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
// GLOBALS
//====================================================================
CStructureEngine    gStructureEngine;
CSupplyDemandEngine gSDEngine;
CSnrEngine          gSnrEngine;
CSnrPriorityEngine  gPriorityEngine;
CLiquidityEngine    gLiquidityEngine;
bool                gFirstRun = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestLiquidity v1.0 Starting ===");

   //--- Step 1: Initialize StructureEngine
   if(!gStructureEngine.Init())
   {
      Print("ERROR: Failed to initialize StructureEngine");
      return INIT_FAILED;
   }

   //--- Step 2: Initialize SupplyDemandEngine
   if(!gSDEngine.Init(&gStructureEngine))
   {
      Print("ERROR: Failed to initialize SupplyDemandEngine");
      return INIT_FAILED;
   }

   //--- Step 3: Initialize SnrEngine
   if(!gSnrEngine.Init(&gStructureEngine, &gSDEngine))
   {
      Print("ERROR: Failed to initialize SnrEngine");
      return INIT_FAILED;
   }

   //--- Step 4: Initialize LiquidityEngine
   if(!gLiquidityEngine.Init(&gPriorityEngine))
   {
      Print("ERROR: Failed to initialize LiquidityEngine");
      return INIT_FAILED;
   }

   gFirstRun = true;
   Print("TestLiquidity v1.0 initialized successfully.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   gLiquidityEngine.Deinit();
   gSnrEngine.Deinit();
   gSDEngine.Deinit();
   gStructureEngine.Deinit();
   Print("=== TestLiquidity v1.0 Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Process on new H4 bars (or first run)
   if(!gFirstRun && !gStructureEngine.IsNewBar())
      return;

   gFirstRun = false;

   //--- Run Structure Engine
   StructureResult structRes = gStructureEngine.Analyze(InpTestMaxBars);
   if(!structRes.isValid)
   {
      Print("WARNING: StructureEngine returned invalid result");
      return;
   }

   //--- Run Supply & Demand Engine
   gSDEngine.Analyze(InpTestMaxBars);

   //--- Run SNR Engine
   gSnrEngine.Analyze(InpTestMaxBars);

   //--- Process Priority Engine
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(currentPrice <= 0.0)
      currentPrice = iClose(_Symbol, PERIOD_H4, 0);
   double atr = gSnrEngine.GetLocalATR(1);
   
   if(!gPriorityEngine.Process(GetPointer(gSnrEngine), currentPrice, atr))
   {
      Print("WARNING: SnrPriorityEngine failed to process");
      return;
   }

   //--- Run Liquidity Engine
   if(!gLiquidityEngine.Analyze())
   {
      Print("WARNING: LiquidityEngine failed to analyze");
      return;
   }

   //--- Retrieve contracts for comparison
   SnrPriorityContract priorityContract;
   gPriorityEngine.GetContract(priorityContract);

   LiquidityPriorityContract liquidityContract;
   gLiquidityEngine.GetContract(liquidityContract);

   //--- Output comparison logs
   Print("====================================================");
   Print("     LIQUIDITY ENGINE CONTRACT FLOW VERIFICATION");
   Print("====================================================");
   Print("  Upstream BSL ID: ", priorityContract.hasBSL ? IntegerToString(priorityContract.nearestBSL.id) : "NONE",
         " | PriceLow: ", priorityContract.hasBSL ? DoubleToString(priorityContract.nearestBSL.priceLow, _Digits) : "0.0");
   Print("  Engine BSL ID:   ", liquidityContract.hasBSL ? IntegerToString(liquidityContract.nearestBSL.id) : "NONE",
         " | PriceLow: ", liquidityContract.hasBSL ? DoubleToString(liquidityContract.nearestBSL.priceLow, _Digits) : "0.0");
   Print("  ---");
   Print("  Upstream SSL ID: ", priorityContract.hasSSL ? IntegerToString(priorityContract.nearestSSL.id) : "NONE",
         " | PriceHigh: ", priorityContract.hasSSL ? DoubleToString(priorityContract.nearestSSL.priceHigh, _Digits) : "0.0");
   Print("  Engine SSL ID:   ", liquidityContract.hasSSL ? IntegerToString(liquidityContract.nearestSSL.id) : "NONE",
         " | PriceHigh: ", liquidityContract.hasSSL ? DoubleToString(liquidityContract.nearestSSL.priceHigh, _Digits) : "0.0");
   Print("====================================================");

   // Verify mapping correctness
   bool match = true;
   if(priorityContract.hasBSL != liquidityContract.hasBSL) match = false;
   if(priorityContract.hasSSL != liquidityContract.hasSSL) match = false;
   if(priorityContract.hasBSL)
   {
      if(priorityContract.nearestBSL.id != liquidityContract.nearestBSL.id ||
         priorityContract.nearestBSL.priceLow != liquidityContract.nearestBSL.priceLow ||
         priorityContract.nearestBSL.priceHigh != liquidityContract.nearestBSL.priceHigh)
         match = false;
   }
   if(priorityContract.hasSSL)
   {
      if(priorityContract.nearestSSL.id != liquidityContract.nearestSSL.id ||
         priorityContract.nearestSSL.priceLow != liquidityContract.nearestSSL.priceLow ||
         priorityContract.nearestSSL.priceHigh != liquidityContract.nearestSSL.priceHigh)
         match = false;
   }

   if(match)
   {
      Print(">>> STATUS: CONTRACT FLOW VERIFICATION SUCCESSFUL (Perfect Match) <<<");
   }
   else
   {
      Print(">>> STATUS: CONTRACT FLOW VERIFICATION FAILED (Mismatch) <<<");
   }

   //--- Output Sweep and Rejection Details
   Print("====================================================");
   Print("     SWEEP & REJECTION METRICS VERIFICATION");
   Print("====================================================");
   Print("  BSL Breached:     ", liquidityContract.isBSLBreached ? "YES" : "NO");
   Print("  BSL Rejected:     ", liquidityContract.isBSLRejected ? "YES" : "NO");
   Print("  BSL Sweep Size:   ", DoubleToString(liquidityContract.bslSweepSizeATR, 4), " ATR");
   Print("  ---");
   Print("  SSL Breached:     ", liquidityContract.isSSLBreached ? "YES" : "NO");
   Print("  SSL Rejected:     ", liquidityContract.isSSLRejected ? "YES" : "NO");
   Print("  SSL Sweep Size:   ", DoubleToString(liquidityContract.sslSweepSizeATR, 4), " ATR");
   Print("  ---");
   Print("  Large Excursion:  ", liquidityContract.isLargeExcursion ? "YES" : "NO");
   Print("====================================================");

   //--- Verify Local Cache Layer
   Print("====================================================");
   Print("     LIQUIDITY ENGINE LOCAL CACHE LAYER VERIFICATION");
   Print("====================================================");
   
   int h4Count = gLiquidityEngine.GetH4RatesCount();
   int m30Count = gLiquidityEngine.GetM30RatesCount();
   double h4ATR = gLiquidityEngine.GetH4ATR();
   datetime lastUpdate = gLiquidityEngine.GetLastCacheUpdate();
   bool cacheValid = gLiquidityEngine.CacheIsValid();

   Print("  H4 Rates Cached Count:   ", h4Count);
   Print("  M30 Rates Cached Count:  ", m30Count);
   Print("  H4 ATR (14) Value:       ", DoubleToString(h4ATR, 4));
   Print("  Last Cache Update Time:  ", TimeToString(lastUpdate, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
   Print("  Cache Is Valid Flag:     ", cacheValid ? "YES" : "NO");

   // Cache State Validation Checks
   bool cacheValidationsOk = true;
   if(h4Count != 300) { Print("  ERROR: H4 cache size mismatch (expected 300)"); cacheValidationsOk = false; }
   if(m30Count != 300) { Print("  ERROR: M30 cache size mismatch (expected 300)"); cacheValidationsOk = false; }
   if(h4ATR <= 0.0) { Print("  ERROR: ATR value is invalid (expected > 0.0)"); cacheValidationsOk = false; }
   if(lastUpdate == 0) { Print("  ERROR: Last update time is invalid"); cacheValidationsOk = false; }
   if(!cacheValid) { Print("  ERROR: CacheIsValid returned false"); cacheValidationsOk = false; }

   //--- Force Cache Invalidation & Refresh Test
   Print("  --- Force Refresh Test ---");
   Print("  Triggering CLiquidityEngine::Reset() to invalidate cache...");
   gLiquidityEngine.Reset();
   
   int h4Reset = gLiquidityEngine.GetH4RatesCount();
   int m30Reset = gLiquidityEngine.GetM30RatesCount();
   double atrReset = gLiquidityEngine.GetH4ATR();
   bool validReset = gLiquidityEngine.CacheIsValid();
   Print("  Post-Reset Stats: H4=", h4Reset, ", M30=", m30Reset, ", ATR=", atrReset, ", Valid=", validReset ? "YES" : "NO");
   
   if(h4Reset != 0 || m30Reset != 0 || atrReset != 0.0 || validReset)
   {
      Print("  ERROR: Reset did not clear the cache properly");
      cacheValidationsOk = false;
   }

   Print("  Re-running Analyze() to trigger cache rebuild...");
   if(!gLiquidityEngine.Analyze())
   {
      Print("  ERROR: Analyze failed to rebuild cache after Reset");
      cacheValidationsOk = false;
   }

   int h4Rebuilt = gLiquidityEngine.GetH4RatesCount();
   int m30Rebuilt = gLiquidityEngine.GetM30RatesCount();
   double atrRebuilt = gLiquidityEngine.GetH4ATR();
   bool validRebuilt = gLiquidityEngine.CacheIsValid();
   Print("  Post-Rebuild Stats: H4=", h4Rebuilt, ", M30=", m30Rebuilt, ", ATR=", atrRebuilt, ", Valid=", validRebuilt ? "YES" : "NO");

   if(h4Rebuilt != 300 || m30Rebuilt != 300 || atrRebuilt <= 0.0 || !validRebuilt)
   {
      Print("  ERROR: Cache rebuild stats are invalid");
      cacheValidationsOk = false;
   }

   if(cacheValidationsOk)
   {
      Print(">>> STATUS: CACHE VALIDATION TEST SUCCESSFUL <<<");
   }
   else
   {
      Print(">>> STATUS: CACHE VALIDATION TEST FAILED <<<");
   }
   Print("====================================================");
}
