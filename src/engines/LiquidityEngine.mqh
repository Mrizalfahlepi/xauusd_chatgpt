//+------------------------------------------------------------------+
//|                                              LiquidityEngine.mqh |
//|                        XAUUSD Liquidity Engine                   |
//|                        Version 1.0 - Phase 4.2 Step 1            |
//+------------------------------------------------------------------+
#ifndef LIQUIDITY_ENGINE_MQH
#define LIQUIDITY_ENGINE_MQH

#include "SnrPriorityEngine.mqh"

//====================================================================
// OUTPUT STRUCT: Downstream contract passed to Entry Engine (Module 5)
//====================================================================
struct LiquidityPriorityContract
{
   // 1. Core Boundaries copied directly from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // 2. Real-Time Sweep Intelligence (Factual, never suppressed)
   bool           isBSLBreached;
   bool           isBSLRejected;
   double         bslSweepSizeATR;     // Raw volatility-adjusted excursion depth
   
   bool           isSSLBreached;
   bool           isSSLRejected;
   double         sslSweepSizeATR;     // Raw volatility-adjusted excursion depth
   
   // 3. Breakout Risk Indicator (Factual structural flag, not a trade block)
   bool           isLargeExcursion;    // True if sweep size exceeds InpLiqSweepMaxSizeATR
};

//====================================================================
// CLASS: CLiquidityEngine
//====================================================================
class CLiquidityEngine
{
private:
   //--- Reference Pointers
   CSnrPriorityEngine*        m_priorityEngine;
   
   //--- Internal Output Contract
   LiquidityPriorityContract  m_activeContract;
   
   //--- Local Price Caches (MqlRates arrays)
   MqlRates          m_h4Rates[];
   MqlRates          m_m30Rates[];
   int               m_maxH4Bars;
   int               m_maxM30Bars;
   
   //--- Cache State & Volatility
   double            m_h4ATR;
   datetime          m_lastCacheUpdate;
   
   //--- Settings
   double            m_sweepMaxSizeATR;
   bool              m_enableLog;

public:
                      CLiquidityEngine();
                     ~CLiquidityEngine();
                     
   //--- Initialization / Deinitialization
   bool              Init(CSnrPriorityEngine* priorityEngine);
   void              Deinit();
   
   //--- Reset State
   void              Reset();
   
   //--- Cache Control Pipeline
   bool              UpdateCache();
   bool              RefreshATR();
   bool              CacheIsValid();
   
   //--- Core Scan Pipeline Stub (Evaluates closed M30 bar 1)
   bool              Analyze();
   
   //--- Accessors
   LiquidityPriorityContract GetContract() const { return m_activeContract; }
   void                      GetContract(LiquidityPriorityContract &contract) const;
   double                    GetH4ATR() const { return m_h4ATR; }
   datetime                  GetLastCacheUpdate() const { return m_lastCacheUpdate; }
   int                       GetH4RatesCount() const { return ArraySize(m_h4Rates); }
   int                       GetM30RatesCount() const { return ArraySize(m_m30Rates); }
};

//====================================================================
// CONSTRUCTOR
//====================================================================
CLiquidityEngine::CLiquidityEngine()
{
   m_priorityEngine  = NULL;
   m_maxH4Bars       = 300;
   m_maxM30Bars      = 300;
   m_sweepMaxSizeATR = 1.50; // Placeholder - Requires Validation
   m_enableLog       = true;
   m_h4ATR           = 0.0;
   m_lastCacheUpdate = 0;
   Reset();
}

//====================================================================
// DESTRUCTOR
//====================================================================
CLiquidityEngine::~CLiquidityEngine()
{
   Deinit();
}

//====================================================================
// INITIALIZATION
//====================================================================
bool CLiquidityEngine::Init(CSnrPriorityEngine* priorityEngine)
{
   if(priorityEngine == NULL)
   {
      if(m_enableLog) Print("[CLiquidityEngine] ERROR: Upstream SnrPriorityEngine pointer is NULL");
      return false;
   }
   
   m_priorityEngine = priorityEngine;
   Reset();
   
   if(m_enableLog) Print("[CLiquidityEngine] Skeleton initialized successfully.");
   return true;
}

//====================================================================
// DEINITIALIZATION
//====================================================================
void CLiquidityEngine::Deinit()
{
   m_priorityEngine = NULL;
   ArrayFree(m_h4Rates);
   ArrayFree(m_m30Rates);
}

//====================================================================
// RESET STATE
//====================================================================
void CLiquidityEngine::Reset()
{
   // Reset boundaries to empty defaults
   m_activeContract.nearestBSL.id = -1;
   m_activeContract.nearestBSL.priceHigh = 0.0;
   m_activeContract.nearestBSL.priceLow = 0.0;
   m_activeContract.nearestBSL.isBuyLiquidity = true;
   m_activeContract.nearestBSL.liquidityStrength = 0.0;
   m_activeContract.nearestBSL.isSwept = false;
   m_activeContract.nearestBSL.sweptTime = 0;
   m_activeContract.hasBSL = false;

   m_activeContract.nearestSSL.id = -1;
   m_activeContract.nearestSSL.priceHigh = 0.0;
   m_activeContract.nearestSSL.priceLow = 0.0;
   m_activeContract.nearestSSL.isBuyLiquidity = false;
   m_activeContract.nearestSSL.liquidityStrength = 0.0;
   m_activeContract.nearestSSL.isSwept = false;
   m_activeContract.nearestSSL.sweptTime = 0;
   m_activeContract.hasSSL = false;

   // Reset triggers
   m_activeContract.isBSLBreached = false;
   m_activeContract.isBSLRejected = false;
   m_activeContract.bslSweepSizeATR = 0.0;
   m_activeContract.isSSLBreached = false;
   m_activeContract.isSSLRejected = false;
   m_activeContract.sslSweepSizeATR = 0.0;
   m_activeContract.isLargeExcursion = false;
   
   // Reset caches
   m_h4ATR = 0.0;
   m_lastCacheUpdate = 0;
   ArrayFree(m_h4Rates);
   ArrayFree(m_m30Rates);
}

//====================================================================
// UPDATE CACHE
//====================================================================
bool CLiquidityEngine::UpdateCache()
{
   int h4Copied = CopyRates(_Symbol, PERIOD_H4, 0, m_maxH4Bars, m_h4Rates);
   if(h4Copied <= 0)
   {
      if(m_enableLog) Print("[CLiquidityEngine] ERROR: CopyRates for H4 failed");
      return false;
   }
   ArraySetAsSeries(m_h4Rates, true);
   
   int m30Copied = CopyRates(_Symbol, PERIOD_M30, 0, m_maxM30Bars, m_m30Rates);
   if(m30Copied <= 0)
   {
      if(m_enableLog) Print("[CLiquidityEngine] ERROR: CopyRates for M30 failed");
      return false;
   }
   ArraySetAsSeries(m_m30Rates, true);
   
   m_lastCacheUpdate = TimeCurrent();
   return true;
}

//====================================================================
// REFRESH ATR (14-period SMA of True Range starting at bar index 1)
//====================================================================
bool CLiquidityEngine::RefreshATR()
{
   int period = 14;
   int startBar = 1;
   
   int size = ArraySize(m_h4Rates);
   if(size <= startBar + period)
   {
      m_h4ATR = 0.0;
      if(m_enableLog) Print("[CLiquidityEngine] ERROR: H4 rates cache size is too small to calculate ATR");
      return false;
   }
   
   double sumTR = 0.0;
   int count = 0;
   
   for(int i = 0; i < period; i++)
   {
      int idx = startBar + i;
      if(idx >= size - 1)
         break;
         
      double high      = m_h4Rates[idx].high;
      double low       = m_h4Rates[idx].low;
      double closePrev = m_h4Rates[idx + 1].close;
      
      double tr  = high - low;
      double tr2 = MathAbs(high - closePrev);
      double tr3 = MathAbs(low - closePrev);
      
      double maxTR = tr;
      if(tr2 > maxTR) maxTR = tr2;
      if(tr3 > maxTR) maxTR = tr3;
      
      sumTR += maxTR;
      count++;
   }
   
   if(count > 0)
   {
      m_h4ATR = sumTR / count;
      return true;
   }
   
   m_h4ATR = 0.0;
   return false;
}

//====================================================================
// CACHE IS VALID
//====================================================================
bool CLiquidityEngine::CacheIsValid()
{
   if(m_lastCacheUpdate == 0)
      return false;
      
   int h4Size = ArraySize(m_h4Rates);
   int m30Size = ArraySize(m_m30Rates);
   
   if(h4Size < m_maxH4Bars || m30Size < m_maxM30Bars)
      return false;
      
   datetime currentH4Time = iTime(_Symbol, PERIOD_H4, 0);
   datetime currentM30Time = iTime(_Symbol, PERIOD_M30, 0);
   
   if(currentH4Time == 0 || currentM30Time == 0)
      return false;
      
   if(m_h4Rates[0].time != currentH4Time || m_m30Rates[0].time != currentM30Time)
      return false;
      
   return true;
}

//====================================================================
// ANALYZE PIPELINE
//====================================================================
bool CLiquidityEngine::Analyze()
{
   if(m_priorityEngine == NULL)
   {
      if(m_enableLog) Print("[CLiquidityEngine] ERROR: Engine not initialized or priority pointer NULL");
      return false;
   }
   
   // Sync/update cache when stale or invalid
   if(!CacheIsValid())
   {
      if(!UpdateCache())
      {
         if(m_enableLog) Print("[CLiquidityEngine] ERROR: Cache update failed in Analyze()");
         return false;
      }
      if(!RefreshATR())
      {
         if(m_enableLog) Print("[CLiquidityEngine] ERROR: ATR refresh failed in Analyze()");
         return false;
      }
   }
   
   // Read contract from upstream priority engine
   SnrPriorityContract priorityContract;
   m_priorityEngine.GetContract(priorityContract);
   
   // Copy boundaries
   m_activeContract.nearestBSL = priorityContract.nearestBSL;
   m_activeContract.hasBSL     = priorityContract.hasBSL;
   
   m_activeContract.nearestSSL = priorityContract.nearestSSL;
   m_activeContract.hasSSL     = priorityContract.hasSSL;
   
   // Reset transient flags to default false/0
   m_activeContract.isBSLBreached   = false;
   m_activeContract.isBSLRejected   = false;
   m_activeContract.bslSweepSizeATR  = 0.0;
   
   m_activeContract.isSSLBreached   = false;
   m_activeContract.isSSLRejected   = false;
   m_activeContract.sslSweepSizeATR  = 0.0;
   
   m_activeContract.isLargeExcursion = false;
   
   // Compute closed M30 bar index 1 sweeps (if pool is active and has not been swept in previous bars)
   if(m_activeContract.hasBSL && !m_activeContract.nearestBSL.isSwept)
   {
      // Breach check: High of M30 bar 1 exceeds outer BSL boundary
      if(m_m30Rates[1].high > m_activeContract.nearestBSL.priceHigh)
      {
         m_activeContract.isBSLBreached   = true;
         // Excursion size: distance from inner boundary (swing price priceLow) to bar high
         m_activeContract.bslSweepSizeATR  = (m_m30Rates[1].high - m_activeContract.nearestBSL.priceLow) / m_h4ATR;
         // Rejection check: Close of M30 bar 1 is back below the inner boundary
         m_activeContract.isBSLRejected   = (m_m30Rates[1].close < m_activeContract.nearestBSL.priceLow);
         
         if(m_activeContract.bslSweepSizeATR > m_sweepMaxSizeATR)
            m_activeContract.isLargeExcursion = true;
      }
   }
   
   if(m_activeContract.hasSSL && !m_activeContract.nearestSSL.isSwept)
   {
      // Breach check: Low of M30 bar 1 falls below outer SSL boundary
      if(m_m30Rates[1].low < m_activeContract.nearestSSL.priceLow)
      {
         m_activeContract.isSSLBreached   = true;
         // Excursion size: distance from inner boundary (swing price priceHigh) to bar low
         m_activeContract.sslSweepSizeATR  = (m_activeContract.nearestSSL.priceHigh - m_m30Rates[1].low) / m_h4ATR;
         // Rejection check: Close of M30 bar 1 is back above the inner boundary
         m_activeContract.isSSLRejected   = (m_m30Rates[1].close > m_activeContract.nearestSSL.priceHigh);
         
         if(m_activeContract.sslSweepSizeATR > m_sweepMaxSizeATR)
            m_activeContract.isLargeExcursion = true;
      }
   }
   
   return true;
}

//====================================================================
// GET CONTRACT (REFERENCE OUT PARAMETER)
//====================================================================
void CLiquidityEngine::GetContract(LiquidityPriorityContract &contract) const
{
   contract = m_activeContract;
}

#endif
