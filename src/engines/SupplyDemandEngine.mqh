//+------------------------------------------------------------------+
//|                                           SupplyDemandEngine.mqh |
//|                        XAUUSD Supply & Demand Zone Engine        |
//|                        Version 1.0 - Sprint 2.0                  |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Detect institutional supply and demand zones on H4 timeframe.  |
//|   Consumes market structure from StructureEngine v2.2.           |
//|                                                                  |
//| RESPONSIBILITIES:                                                |
//|   1. Detect Impulse candles (Range >= 2.0 ATR, Body >= 60%)      |
//|   2. Form consolidation bases (1 to 6 candles preceding impulse) |
//|   3. Create and track active Supply and Demand zones             |
//|   4. Track zone invalidation on closed candles (Close past Low/High)|
//|   5. Count zone reactions (retests) with consolidation grouping  |
//|   6. Calculate zone quality score (Impulse, Freshness, Age, React)|
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

#include "StructureEngine.mqh"

//=========================================================
// ENUMS & STRUCTS
//=========================================================

//--- Supply/Demand Zone type
enum ENUM_ZONE_TYPE
{
   ZONE_DEMAND = 0,     // Demand Zone (Bullish Impulse Origin)
   ZONE_SUPPLY = 1      // Supply Zone (Bearish Impulse Origin)
};

//--- Represents a single Supply/Demand zone
struct SupplyDemandZone
{
   int               id;              // Unique identifier
   ENUM_ZONE_TYPE    zoneType;        // ZONE_DEMAND or ZONE_SUPPLY
   int               baseStartBar;    // Oldest bar index of the base (e.g. X + N)
   int               baseEndBar;      // Newest bar index of the base (e.g. X + 1)
   int               impulseBarIndex; // Bar index of the impulse candle (e.g. X)
   int               baseCandleCount; // Number of base candles (1-6)
   datetime          baseStartTime;   // Time of baseStartBar
   datetime          baseEndTime;     // Time of baseEndBar
   datetime          impulseTime;     // Time of impulseBarIndex
   double            zoneHigh;        // High price of the base
   double            zoneLow;         // Low price of the base
   double            impulseRange;    // Range of the impulse candle (High - Low)
   double            bodyDominance;   // Body dominance (0.0 to 1.0)
   bool              isInvalidated;   // Whether zone has been broken
   int               invalidatedBar;  // Bar index where invalidation occurred
   datetime          invalidatedTime; // Time where invalidation occurred
   int               reactionCount;   // Number of touches before invalidation
   
   //--- Scoring Framework
   double            scoreImpulse;    // Impulse strength score (0-100)
   double            scoreFreshness;  // Freshness score (0-100)
   double            scoreAge;        // Age score (0-100)
   double            scoreReaction;   // Reaction score (0-100)
   double            scoreTotal;      // Weighted total score (0-100)
};

//=========================================================
// CLASS DEFINITION
//=========================================================
class CSupplyDemandEngine
{
private:
   SupplyDemandZone  m_zones[];            // List of detected zones
   CStructureEngine* m_structureEngine;    // Pointer to StructureEngine v2.2
   
   //--- Settings (cached from inputs)
   int               m_atrPeriod;          // ATR period
   double            m_minImpulseATR;      // Impulse range multiplier
   double            m_minBodyDominance;    // Min body/range ratio
   double            m_reactionTolerance;  // Reaction tolerance (ATR)
   bool              m_enableLog;          // Enable logging
   
   //--- Cached H4 price data
   double            m_cachedOpens[];
   double            m_cachedHighs[];
   double            m_cachedLows[];
   double            m_cachedCloses[];
   datetime          m_cachedTimes[];
   int               m_cachedBarsCount;
   
   //--- Private helpers
   double            GetATRValue(int barIndex);
   void              LogMessage(string message);
   int               CountZoneReactions(const SupplyDemandZone &zone);
   void              ScoreZone(SupplyDemandZone &zone, int currentBarIdx);

public:
                     CSupplyDemandEngine();
                    ~CSupplyDemandEngine();
                    
   bool              Init(CStructureEngine* structEngine);
   void              Deinit();
   
   //--- Core detection pipeline
   int               Analyze(int maxBars = 300);
   
   //--- Accessors
   int               GetZoneCount() const { return ArraySize(m_zones); }
   bool              GetZone(int index, SupplyDemandZone &zone);
   int               GetActiveZoneCount(ENUM_ZONE_TYPE type);
   bool              GetNearestActiveZone(double price, ENUM_ZONE_TYPE type, SupplyDemandZone &zone);
};

//=========================================================
// CONSTRUCTOR / DESTRUCTOR
//=========================================================
CSupplyDemandEngine::CSupplyDemandEngine()
{
   m_structureEngine   = NULL;
   m_atrPeriod         = 14;
   m_minImpulseATR     = 2.0;
   m_minBodyDominance   = 0.60;
   m_reactionTolerance = 0.15;
   m_enableLog         = true;
   m_cachedBarsCount   = 0;
}

CSupplyDemandEngine::~CSupplyDemandEngine()
{
}

//=========================================================
// INITIALIZATION
//=========================================================
bool CSupplyDemandEngine::Init(CStructureEngine* structEngine)
{
   if(structEngine == NULL)
   {
      LogMessage("ERROR: StructureEngine pointer is NULL");
      return false;
   }
   m_structureEngine = structEngine;
   LogMessage("Engine initialized successfully");
   return true;
}

void CSupplyDemandEngine::Deinit()
{
   ArrayFree(m_zones);
   ArrayFree(m_cachedOpens);
   ArrayFree(m_cachedHighs);
   ArrayFree(m_cachedLows);
   ArrayFree(m_cachedCloses);
   ArrayFree(m_cachedTimes);
}

//=========================================================
// CORE ANALYSIS PIPELINE
//=========================================================
int CSupplyDemandEngine::Analyze(int maxBars)
{
   if(m_structureEngine == NULL)
      return 0;
      
   int barsToAnalyze = maxBars;
   if(barsToAnalyze <= 0)
      barsToAnalyze = 300;
      
   //--- Cache H4 price data locally (prevents tester sync lag)
   ArraySetAsSeries(m_cachedOpens, true);
   ArraySetAsSeries(m_cachedHighs, true);
   ArraySetAsSeries(m_cachedLows, true);
   ArraySetAsSeries(m_cachedCloses, true);
   ArraySetAsSeries(m_cachedTimes, true);
   
   if(CopyOpen(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedOpens) <= 0 ||
      CopyHigh(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedHighs) <= 0 ||
      CopyLow(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedLows) <= 0 ||
      CopyClose(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedCloses) <= 0 ||
      CopyTime(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedTimes) <= 0)
   {
      LogMessage("ERROR: Failed to copy H4 price data");
      return 0;
   }
   m_cachedBarsCount = barsToAnalyze;
   
   //--- Clear previous zones
   ArrayResize(m_zones, 0);
   int zoneIdCounter = 0;
   
   //--- Find oldest bar we can analyze
   int oldestBar = m_cachedBarsCount - 8; // Leave room for ATR & Base expansion
   if(oldestBar < 1)
      return 0;
      
   //--- Chronological Single Pass: Oldest -> Newest
   for(int barIdx = oldestBar; barIdx >= 1; barIdx--)
   {
      //--- 1. Update Invalidation on Existing Active Zones
      int activeCount = ArraySize(m_zones);
      for(int z = 0; z < activeCount; z++)
      {
         if(m_zones[z].isInvalidated)
            continue;
            
         double currentClose = m_cachedCloses[barIdx];
         if(m_zones[z].zoneType == ZONE_DEMAND)
         {
            if(currentClose < m_zones[z].zoneLow)
            {
               m_zones[z].isInvalidated = true;
               m_zones[z].invalidatedBar = barIdx;
               m_zones[z].invalidatedTime = m_cachedTimes[barIdx];
               LogMessage("Demand Zone #" + IntegerToString(m_zones[z].id) + " Invalidated at bar " + IntegerToString(barIdx));
            }
         }
         else if(m_zones[z].zoneType == ZONE_SUPPLY)
         {
            if(currentClose > m_zones[z].zoneHigh)
            {
               m_zones[z].isInvalidated = true;
               m_zones[z].invalidatedBar = barIdx;
               m_zones[z].invalidatedTime = m_cachedTimes[barIdx];
               LogMessage("Supply Zone #" + IntegerToString(m_zones[z].id) + " Invalidated at bar " + IntegerToString(barIdx));
            }
         }
      }
      
      //--- 2. Detect New Impulse Candle
      double high  = m_cachedHighs[barIdx];
      double low   = m_cachedLows[barIdx];
      double open  = m_cachedOpens[barIdx];
      double close = m_cachedCloses[barIdx];
      
      double candleRange = high - low;
      double candleBody  = MathAbs(close - open);
      double atrValue    = GetATRValue(barIdx);
      
      if(atrValue <= 0.0)
         continue;
         
      bool isImpulse = (candleRange >= m_minImpulseATR * atrValue) && 
                       ((candleBody / candleRange) >= m_minBodyDominance);
                       
      if(isImpulse)
      {
         ENUM_ZONE_TYPE zType = (close > open) ? ZONE_DEMAND : ZONE_SUPPLY;
         
         //--- Expand Preceding Base (1-6 candles)
         int baseStart = barIdx + 1;
         int baseEnd   = barIdx + 1;
         int baseCount = 1;
         double zHigh  = m_cachedHighs[baseStart];
         double zLow   = m_cachedLows[baseStart];
         
         for(int b = 2; b <= 6; b++)
         {
            int prevIdx = barIdx + b;
            if(prevIdx >= m_cachedBarsCount)
               break;
               
            double pHigh  = m_cachedHighs[prevIdx];
            double pLow   = m_cachedLows[prevIdx];
            double pOpen  = m_cachedOpens[prevIdx];
            double pClose = m_cachedCloses[prevIdx];
            double pRange = pHigh - pLow;
            double pBody  = MathAbs(pClose - pOpen);
            double pAtr   = GetATRValue(prevIdx);
            
            bool isPrevImpulse = (pAtr > 0.0) && (pRange >= m_minImpulseATR * pAtr) && 
                                 ((pBody / pRange) >= m_minBodyDominance);
            if(isPrevImpulse)
               break; // Stop base consolidation block expansion
               
            baseCount++;
            baseStart = prevIdx;
            if(pHigh > zHigh) zHigh = pHigh;
            if(pLow < zLow)   zLow = pLow;
         }
         
         //--- Create Zone Object
         int index = ArraySize(m_zones);
         ArrayResize(m_zones, index + 1);
         
         m_zones[index].id              = zoneIdCounter++;
         m_zones[index].zoneType        = zType;
         m_zones[index].baseStartBar    = baseStart;
         m_zones[index].baseEndBar      = baseEnd;
         m_zones[index].impulseBarIndex = barIdx;
         m_zones[index].baseCandleCount = baseCount;
         m_zones[index].baseStartTime   = m_cachedTimes[baseStart];
         m_zones[index].baseEndTime     = m_cachedTimes[baseEnd];
         m_zones[index].impulseTime     = m_cachedTimes[barIdx];
         m_zones[index].zoneHigh        = zHigh;
         m_zones[index].zoneLow         = zLow;
         m_zones[index].impulseRange    = candleRange;
         m_zones[index].bodyDominance   = candleBody / candleRange;
         m_zones[index].isInvalidated   = false;
         m_zones[index].invalidatedBar  = -1;
         m_zones[index].invalidatedTime = 0;
         m_zones[index].reactionCount   = 0;
         
         LogMessage("New " + ((zType == ZONE_DEMAND) ? "Demand" : "Supply") + " Zone #" + 
                    IntegerToString(m_zones[index].id) + " created at bar " + IntegerToString(barIdx) + 
                    " | Base candles=" + IntegerToString(baseCount));
      }
   }
   
   //--- 3. Calculate Reaction Counts and Scores
   int totalZones = ArraySize(m_zones);
   for(int z = 0; z < totalZones; z++)
   {
      m_zones[z].reactionCount = CountZoneReactions(m_zones[z]);
      ScoreZone(m_zones[z], 1); // Score relative to index 1 (newest completed bar)
   }
   
   return totalZones;
}

//=========================================================
// ZONE REACTIONS COUNT (Capped at invalidation, Grouped)
//=========================================================
int CSupplyDemandEngine::CountZoneReactions(const SupplyDemandZone &zone)
{
   int reactions = 0;
   bool insideZone = false;
   int stopBar = zone.isInvalidated ? zone.invalidatedBar + 1 : 1;
   
   // Scan from the candle after impulse down to stopBar
   for(int bar = zone.impulseBarIndex - 1; bar >= stopBar; bar--)
   {
      if(bar >= m_cachedBarsCount)
         continue;
         
      // Touch is defined as candle high/low range overlapping zone boundaries
      bool touch = (m_cachedHighs[bar] >= zone.zoneLow && m_cachedLows[bar] <= zone.zoneHigh);
      if(touch)
      {
         if(!insideZone)
         {
            reactions++;
            insideZone = true;
         }
      }
      else
      {
         insideZone = false;
      }
   }
   return reactions;
}

//=========================================================
// SCORING FRAMEWORK
//=========================================================
void CSupplyDemandEngine::ScoreZone(SupplyDemandZone &zone, int currentBarIdx)
{
   // 1. Impulse Strength Score (0-100)
   double atr = GetATRValue(zone.impulseBarIndex);
   double impulseATRRatio = (atr > 0.0) ? (zone.impulseRange / atr) : 2.0;
   double scoreImp = MathMin(100.0, (impulseATRRatio / 2.0) * 50.0 + (zone.bodyDominance * 50.0));
   
   // 2. Freshness Score (0-100)
   double scoreFresh = 100.0;
   if(zone.isInvalidated)
      scoreFresh = 0.0;
   else if(zone.reactionCount == 1)
      scoreFresh = 50.0;
   else if(zone.reactionCount == 2)
      scoreFresh = 25.0;
   else if(zone.reactionCount >= 3)
      scoreFresh = 0.0;
      
   // 3. Age Score (0-100)
   int age = zone.impulseBarIndex - currentBarIdx;
   if(age < 0) age = 0;
   double scoreA = MathMax(0.0, 100.0 - age * 0.25); // Drops to 0 at 400 bars
   
   // 4. Reaction Score (0-100)
   double scoreReact = MathMin(100.0, zone.reactionCount * 33.3); // Caps at 3 touches
   
   // 5. Total Score (0-100)
   double scoreTot = (scoreImp * 0.30) + (scoreFresh * 0.30) + (scoreA * 0.20) + (scoreReact * 0.20);
   
   zone.scoreImpulse   = scoreImp;
   zone.scoreFreshness = scoreFresh;
   zone.scoreAge       = scoreA;
   zone.scoreReaction  = scoreReact;
   zone.scoreTotal     = scoreTot;
}

//=========================================================
// ACCESSORS
//=========================================================
bool CSupplyDemandEngine::GetZone(int index, SupplyDemandZone &zone)
{
   int count = ArraySize(m_zones);
   if(index < 0 || index >= count)
      return false;
   zone = m_zones[index];
   return true;
}

int CSupplyDemandEngine::GetActiveZoneCount(ENUM_ZONE_TYPE type)
{
   int activeCount = 0;
   int total = ArraySize(m_zones);
   for(int i = 0; i < total; i++)
   {
      if(!m_zones[i].isInvalidated && m_zones[i].zoneType == type)
         activeCount++;
   }
   return activeCount;
}

bool CSupplyDemandEngine::GetNearestActiveZone(double price, ENUM_ZONE_TYPE type, SupplyDemandZone &zone)
{
   int total = ArraySize(m_zones);
   double minDiff = DBL_MAX;
   int bestIndex = -1;
   
   for(int i = 0; i < total; i++)
   {
      if(m_zones[i].isInvalidated || m_zones[i].zoneType != type)
         continue;
         
      double zoneMidPrice = (m_zones[i].zoneHigh + m_zones[i].zoneLow) / 2.0;
      double diff = MathAbs(price - zoneMidPrice);
      if(diff < minDiff)
      {
         minDiff = diff;
         bestIndex = i;
      }
   }
   
   if(bestIndex >= 0)
   {
      zone = m_zones[bestIndex];
      return true;
   }
   return false;
}

//=========================================================
// PRIVATE UTILITY FUNCTIONS
//=========================================================
double CSupplyDemandEngine::GetATRValue(int barIndex)
{
   int period = m_atrPeriod;
   if(m_cachedBarsCount <= barIndex + period)
      return 0.0;
      
   double sumTR = 0.0;
   int count = 0;
   
   for(int i = 0; i < period; i++)
   {
      int idx = barIndex + i;
      if(idx >= m_cachedBarsCount - 1)
         break;
         
      double high      = m_cachedHighs[idx];
      double low       = m_cachedLows[idx];
      double closePrev = m_cachedCloses[idx + 1];
      
      double tr  = high - low;
      double tr2 = MathAbs(high - closePrev);
      double tr3 = MathAbs(low - closePrev);
      
      double maxTR = tr;
      if(tr2 > maxTR) maxTR = tr2;
      if(tr3 > maxTR) maxTR = tr3;
      
      sumTR += maxTR;
      count++;
   }
   return (count > 0) ? (sumTR / count) : 0.0;
}

void CSupplyDemandEngine::LogMessage(string message)
{
   if(m_enableLog)
      Print("[SupplyDemandEngine] ", message);
}
