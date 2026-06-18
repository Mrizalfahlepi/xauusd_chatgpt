//+------------------------------------------------------------------+
//|                                                  EntryEngine.mqh |
//|                        XAUUSD Entry Engine                       |
//|                        Version 1.0 - Phase 5A                    |
//+------------------------------------------------------------------+
#ifndef ENTRY_ENGINE_MQH
#define ENTRY_ENGINE_MQH

#include "StructureEngine.mqh"
#include "LiquidityEngine.mqh"

//====================================================================
// ENUMS
//====================================================================
enum ENUM_VARIANT_MODE
{
   VARIANT_A_BASELINE = 0,    // Variant A: Baseline (No Efficiency Filter)
   VARIANT_B_EFF_GT_2_5 = 1,  // Variant B: Efficiency > 2.5
   VARIANT_C_EFF_LT_2_0 = 2,  // Variant C: Efficiency < 2.0
   VARIANT_D_EFF_OUTSIDE = 3  // Variant D: Efficiency < 2.0 OR Efficiency > 2.5
};

//====================================================================
// INPUT PARAMETERS
//====================================================================
input double            InpMinRejectionMarginATR = 0.50;               // Entry: Min rejection margin (ATR)
input bool              InpEnableTrendGate       = true;               // Entry: Enable H4 Trend Gate
input ENUM_VARIANT_MODE InpVariantMode           = VARIANT_A_BASELINE; // Entry: Phase 5B Variant Mode

//====================================================================
// OUTPUT STRUCT: Trade Entry Signal Contract
//====================================================================
struct EntrySignal
{
   bool              isValid;              // Is this a tradable signal?
   bool              isBuy;                // true=Long, false=Short
   double            entryPrice;           // Entry price (close of bar 1)
   double            stopLossPrice;        // SL price level
   double            takeProfitPrice;      // TP price level
   int               maxBarsToHold;        // Maximum hold duration (12 bars)
   datetime          signalTime;           // Bar time when signal generated
   string            signalReason;         // Trigger identifier
   double            rejectionMarginATR;   // Logged rejection margin
   ENUM_TREND_STATE  trendAtEntry;         // H4 trend at entry
   double            efficiency;           // Logged sweep efficiency
};

//====================================================================
// CLASS: CEntryEngine
//====================================================================
class CEntryEngine
{
private:
   //--- Reference Pointers
   CStructureEngine*    m_structureEngine;
   CLiquidityEngine*    m_liquidityEngine;
   
   //--- Internal Signal Cache
   EntrySignal          m_activeSignal;
   
   //--- Configs
   double               m_slATRMult;
   double               m_tpATRMult;
   int                  m_maxHoldBars;
   double               m_maxSweepSizeATR;
   bool                 m_enableLog;

public:
                        CEntryEngine();
                       ~CEntryEngine();
                       
   //--- Lifecycle
   bool                 Init(CStructureEngine* structureEngine, CLiquidityEngine* liquidityEngine);
   void                 Deinit();
   void                 Reset();
   
   //--- Core logic run on closed M30 Bar 1
   bool                 Analyze();
   
   //--- Accessor
   EntrySignal          GetSignal() const { return m_activeSignal; }
   
   //--- Parameter Setters (if needed in code, though inputs are global)
   void                 SetSLMultiplier(double mult) { m_slATRMult = mult; }
   void                 SetTPMultiplier(double mult) { m_tpATRMult = mult; }
   void                 SetMaxHoldBars(int bars) { m_maxHoldBars = bars; }
   void                 SetEnableLog(bool enable) { m_enableLog = enable; }
};

//====================================================================
// CONSTRUCTOR
//====================================================================
CEntryEngine::CEntryEngine()
{
   m_structureEngine = NULL;
   m_liquidityEngine = NULL;
   m_slATRMult       = 1.0;
   m_tpATRMult       = 2.0;
   m_maxHoldBars     = 12;
   m_maxSweepSizeATR = 1.50; // Hard Large Excursion Block
   m_enableLog       = true;
   Reset();
}

//====================================================================
// DESTRUCTOR
//====================================================================
CEntryEngine::~CEntryEngine()
{
   Deinit();
}

//====================================================================
// INITIALIZATION
//====================================================================
bool CEntryEngine::Init(CStructureEngine* structureEngine, CLiquidityEngine* liquidityEngine)
{
   if(structureEngine == NULL || liquidityEngine == NULL)
   {
      if(m_enableLog) Print("[CEntryEngine] ERROR: Upstream engine references are NULL");
      return false;
   }
   m_structureEngine = structureEngine;
   m_liquidityEngine = liquidityEngine;
   Reset();
   
   if(m_enableLog) Print("[CEntryEngine] Initialized successfully. Scope: Phase 5A Minimal.");
   return true;
}

//====================================================================
// DEINITIALIZATION
//====================================================================
void CEntryEngine::Deinit()
{
   m_structureEngine = NULL;
   m_liquidityEngine = NULL;
}

//====================================================================
// RESET STATE
//====================================================================
void CEntryEngine::Reset()
{
   m_activeSignal.isValid            = false;
   m_activeSignal.isBuy              = false;
   m_activeSignal.entryPrice         = 0.0;
   m_activeSignal.stopLossPrice      = 0.0;
   m_activeSignal.takeProfitPrice    = 0.0;
   m_activeSignal.maxBarsToHold      = 0;
   m_activeSignal.signalTime         = 0;
   m_activeSignal.signalReason       = "";
   m_activeSignal.rejectionMarginATR = 0.0;
   m_activeSignal.trendAtEntry       = TREND_RANGE;
   m_activeSignal.efficiency         = 0.0;
}

//====================================================================
// ANALYZE PIPELINE (Run on M30 ticks)
//====================================================================
bool CEntryEngine::Analyze()
{
   Reset();
   
   if(m_structureEngine == NULL || m_liquidityEngine == NULL)
      return false;
      
   // 1. Fetch current contracts and H4 ATR
   LiquidityPriorityContract contract;
   m_liquidityEngine.GetContract(contract);
   
   double h4ATR = m_liquidityEngine.GetH4ATR();
   if(h4ATR <= 0.0)
      return false;
      
   ENUM_TREND_STATE currentTrend = m_structureEngine.GetCurrentTrend();
   double m30Close = iClose(_Symbol, PERIOD_M30, 1);
   datetime m30Time = iTime(_Symbol, PERIOD_M30, 1);
   
   // 2. Evaluate Buy Stop Liquidity (BSL) Sweep -> Short Setup
   if(contract.isBSLBreached && contract.isBSLRejected && contract.hasBSL)
   {
      // Calculate Rejection Margin (inner boundary priceLow - close) / H4 ATR
      double rejMargin = (contract.nearestBSL.priceLow - m30Close) / h4ATR;
      
      // Filter 1: Rejection Margin Threshold
      if(rejMargin >= InpMinRejectionMarginATR)
      {
         // Filter 2: Large Excursion Block
         bool isLargeEx = (contract.isLargeExcursion || contract.bslSweepSizeATR > m_maxSweepSizeATR);
         if(!isLargeEx)
         {
            // Filter 3: Trend Gate (Bullish Trend blocks Short)
            bool trendBlocked = false;
            if(InpEnableTrendGate && currentTrend == TREND_BULLISH)
               trendBlocked = true;
               
            // Filter 4: Sweep Efficiency Filter
            double sweepSize = contract.bslSweepSizeATR;
            double efficiency = (sweepSize > 0.0) ? (rejMargin / sweepSize) : 0.0;
            bool effBlocked = false;
            if(InpVariantMode == VARIANT_B_EFF_GT_2_5 && efficiency <= 2.5)
               effBlocked = true;
            else if(InpVariantMode == VARIANT_C_EFF_LT_2_0 && efficiency >= 2.0)
               effBlocked = true;
            else if(InpVariantMode == VARIANT_D_EFF_OUTSIDE && (efficiency >= 2.0 && efficiency <= 2.5))
               effBlocked = true;
               
            if(!trendBlocked && !effBlocked)
            {
               m_activeSignal.isValid            = true;
               m_activeSignal.isBuy              = false;
               m_activeSignal.entryPrice         = m30Close;
               m_activeSignal.stopLossPrice      = m30Close + m_slATRMult * h4ATR;
               m_activeSignal.takeProfitPrice    = m30Close - m_tpATRMult * h4ATR;
               m_activeSignal.maxBarsToHold      = m_maxHoldBars;
               m_activeSignal.signalTime         = m30Time;
               m_activeSignal.signalReason       = "BSL Rejection Margin Swept";
               m_activeSignal.rejectionMarginATR = rejMargin;
               m_activeSignal.trendAtEntry       = currentTrend;
               m_activeSignal.efficiency         = efficiency;
               
               if(m_enableLog)
               {
                  Print("[CEntryEngine] SIGNAL: SHORT entry generated at ", DoubleToString(m30Close, _Digits),
                        " | RejMargin: ", DoubleToString(rejMargin, 4), " ATR",
                        " | SweepSize: ", DoubleToString(sweepSize, 4), " ATR",
                        " | Efficiency: ", DoubleToString(efficiency, 4),
                        " | Trend: ", m_structureEngine.TrendToString(currentTrend));
               }
               return true;
            }
            else if(m_enableLog)
            {
               if(trendBlocked)
                  Print("[CEntryEngine] BLOCKED: BSL sweep Short entry blocked by Trend Gate (H4 trend is BULLISH)");
               if(effBlocked)
                  Print("[CEntryEngine] BLOCKED: BSL sweep Short entry blocked by Efficiency Filter (Eff: ", 
                        DoubleToString(efficiency, 4), " for Mode ", EnumToString(InpVariantMode), ")");
            }
         }
         else if(m_enableLog)
         {
            Print("[CEntryEngine] BLOCKED: BSL sweep Short entry blocked by Large Excursion (Sweep size: ", 
                  DoubleToString(contract.bslSweepSizeATR, 4), " ATR)");
         }
      }
   }
   
   // 3. Evaluate Sell Stop Liquidity (SSL) Sweep -> Long Setup
   if(contract.isSSLBreached && contract.isSSLRejected && contract.hasSSL)
   {
      // Calculate Rejection Margin (close - inner boundary priceHigh) / H4 ATR
      double rejMargin = (m30Close - contract.nearestSSL.priceHigh) / h4ATR;
      
      // Filter 1: Rejection Margin Threshold
      if(rejMargin >= InpMinRejectionMarginATR)
      {
         // Filter 2: Large Excursion Block
         bool isLargeEx = (contract.isLargeExcursion || contract.sslSweepSizeATR > m_maxSweepSizeATR);
         if(!isLargeEx)
         {
            // Filter 3: Trend Gate (Bearish Trend blocks Long)
            bool trendBlocked = false;
            if(InpEnableTrendGate && currentTrend == TREND_BEARISH)
               trendBlocked = true;
               
            // Filter 4: Sweep Efficiency Filter
            double sweepSize = contract.sslSweepSizeATR;
            double efficiency = (sweepSize > 0.0) ? (rejMargin / sweepSize) : 0.0;
            bool effBlocked = false;
            if(InpVariantMode == VARIANT_B_EFF_GT_2_5 && efficiency <= 2.5)
               effBlocked = true;
            else if(InpVariantMode == VARIANT_C_EFF_LT_2_0 && efficiency >= 2.0)
               effBlocked = true;
            else if(InpVariantMode == VARIANT_D_EFF_OUTSIDE && (efficiency >= 2.0 && efficiency <= 2.5))
               effBlocked = true;
               
            if(!trendBlocked && !effBlocked)
            {
               m_activeSignal.isValid            = true;
               m_activeSignal.isBuy              = true;
               m_activeSignal.entryPrice         = m30Close;
               m_activeSignal.stopLossPrice      = m30Close - m_slATRMult * h4ATR;
               m_activeSignal.takeProfitPrice    = m30Close + m_tpATRMult * h4ATR;
               m_activeSignal.maxBarsToHold      = m_maxHoldBars;
               m_activeSignal.signalTime         = m30Time;
               m_activeSignal.signalReason       = "SSL Rejection Margin Swept";
               m_activeSignal.rejectionMarginATR = rejMargin;
               m_activeSignal.trendAtEntry       = currentTrend;
               m_activeSignal.efficiency         = efficiency;
               
               if(m_enableLog)
               {
                  Print("[CEntryEngine] SIGNAL: LONG entry generated at ", DoubleToString(m30Close, _Digits),
                        " | RejMargin: ", DoubleToString(rejMargin, 4), " ATR",
                        " | SweepSize: ", DoubleToString(sweepSize, 4), " ATR",
                        " | Efficiency: ", DoubleToString(efficiency, 4),
                        " | Trend: ", m_structureEngine.TrendToString(currentTrend));
               }
               return true;
            }
            else if(m_enableLog)
            {
               if(trendBlocked)
                  Print("[CEntryEngine] BLOCKED: SSL sweep Long entry blocked by Trend Gate (H4 trend is BEARISH)");
               if(effBlocked)
                  Print("[CEntryEngine] BLOCKED: SSL sweep Long entry blocked by Efficiency Filter (Eff: ", 
                        DoubleToString(efficiency, 4), " for Mode ", EnumToString(InpVariantMode), ")");
            }
         }
         else if(m_enableLog)
         {
            Print("[CEntryEngine] BLOCKED: SSL sweep Long entry blocked by Large Excursion (Sweep size: ", 
                  DoubleToString(contract.sslSweepSizeATR, 4), " ATR)");
         }
      }
   }
   
   return false;
}

#endif
