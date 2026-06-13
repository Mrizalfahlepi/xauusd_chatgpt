//+------------------------------------------------------------------+
//|                                                  SnrEngine.mqh   |
//|                        XAUUSD SNR Engine                         |
//|                        Version 1.0 - Sprint 3.0                  |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Consolidate swing points and supply/demand zones into scored   |
//|   Support/Resistance levels and map liquidity pools.              |
//|                                                                  |
//| RESPONSIBILITIES:                                                |
//|   1. Extract levels from upstream engines (read-only)            |
//|   2. Cluster nearby levels using ATR-relative proximity          |
//|   3. Merge same-type overlapping zones with freshness reset      |
//|   4. Deactivate conflicting Supply/Demand overlaps (Neutral)     |
//|   5. Detect nested zones (Core vs. Macro)                        |
//|   6. Score consolidated levels using 5-weight linear model       |
//|   7. Map buy/sell stop liquidity pools above/below swing highs   |
//|                                                                  |
//| FROZEN UPSTREAM DEPENDENCIES (read-only):                        |
//|   - StructureEngine.mqh v2.2                                     |
//|   - SupplyDemandEngine.mqh v1.1                                  |
//|                                                                  |
//| ARCHITECTURAL RULES:                                             |
//|   - Local ATR(14) computation (no upstream private access)       |
//|   - All analysis on completed bars only (barIdx >= 1)            |
//|   - No upstream engine modification                              |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

#include "SupplyDemandEngine.mqh"

//=========================================================
// INTERNAL STRUCT: Raw level for pre-clustering extraction
//=========================================================
struct RawLevel
{
   double    price;              // Center price
   double    priceHigh;          // Top boundary
   double    priceLow;           // Bottom boundary
   bool      isBullish;          // true=Support/Demand, false=Resistance/Supply
   int       sourceType;         // 0=MajorSwing, 1=MinorSwing, 2=ActiveZone, 3=InvalidatedZone
   int       sourceIndex;        // Index into upstream array
   datetime  sourceTime;         // Creation time from upstream
   bool      isInvalidated;      // Zone invalidation state
   double    impulseRange;       // Zone impulse range (for merge dominance)
   double    bodyDominance;      // Zone body dominance (for merge dominance)
   int       reactionCount;      // Upstream reaction count
   int       impulseBarIndex;    // Bar index for rejection scan start

   RawLevel()
   {
      price           = 0.0;
      priceHigh       = 0.0;
      priceLow        = 0.0;
      isBullish       = false;
      sourceType      = 0;
      sourceIndex     = 0;
      sourceTime      = 0;
      isInvalidated   = false;
      impulseRange    = 0.0;
      bodyDominance   = 0.0;
      reactionCount   = 0;
      impulseBarIndex = -1;
   }
};

//=========================================================
// OUTPUT STRUCT: Consolidated Support/Resistance Level
//=========================================================
struct SNRLevel
{
   int       id;                 // Unique identifier
   double    priceHigh;          // Top boundary
   double    priceLow;           // Bottom boundary
   double    priceMid;           // Median price (entry reference)
   bool      isBullish;          // true=Support/Demand, false=Resistance/Supply
   bool      isFresh;            // true = 0 reactions
   int       reactionCount;      // Touch count
   double    scoreTotal;         // Quality score (0-100)

   //--- Confluence Flags
   bool      hasMajorSwing;      // Overlaps Major Swing
   bool      hasMinorSwing;      // Overlaps Minor Swing
   bool      hasActiveZone;      // Overlaps active S/D Zone
   bool      hasBOSOrigin;       // Aligned with BOS origin bar
   int       constituentCount;   // Number of overlapping elements
   datetime  creationTime;       // Oldest element time (or reset time)

   //--- Scoring Components
   double    scoreStruct;        // S_Struct (0-100)
   double    scoreSD;            // S_SD (0-100)
   double    scoreFresh;         // S_Fresh (0-100)
   double    scoreReject;        // S_Reject (0-100)
   double    scoreConfl;         // S_Confl (0-100)

   //--- Conflict State
   bool      isNeutralNode;      // Deactivated: Supply/Demand overlap
   bool      isCoreZone;         // Inner nested zone
   bool      isMacroZone;        // Outer nested zone
   bool      hasInvalidatedZone; // Overlaps invalidated S/D Zone

   SNRLevel()
   {
      id               = 0;
      priceHigh        = 0.0;
      priceLow         = 0.0;
      priceMid         = 0.0;
      isBullish        = false;
      isFresh          = true;
      reactionCount    = 0;
      scoreTotal       = 0.0;
      hasMajorSwing    = false;
      hasMinorSwing    = false;
      hasActiveZone    = false;
      hasBOSOrigin     = false;
      constituentCount = 0;
      creationTime     = 0;
      scoreStruct      = 0.0;
      scoreSD          = 0.0;
      scoreFresh       = 0.0;
      scoreReject      = 0.0;
      scoreConfl       = 0.0;
      isNeutralNode    = false;
      isCoreZone       = false;
      isMacroZone      = false;
      hasInvalidatedZone = false;
   }
};

//=========================================================
// OUTPUT STRUCT: Liquidity Pool (Stop Order Cluster)
//=========================================================
struct LiquidityPool
{
   int       id;                 // Unique identifier
   double    priceHigh;          // Top boundary
   double    priceLow;           // Bottom boundary
   bool      isBuyLiquidity;     // true=Buy Stops above highs
   double    liquidityStrength;  // Strength rating
   bool      isSwept;            // Whether price has run this pool
   datetime  sweptTime;          // Time of sweep

   LiquidityPool()
   {
      id                = 0;
      priceHigh         = 0.0;
      priceLow          = 0.0;
      isBuyLiquidity    = false;
      liquidityStrength = 0.0;
      isSwept           = false;
      sweptTime         = 0;
   }
};

//=========================================================
// INPUT PARAMETERS (InpSnr* prefix to avoid conflicts)
//=========================================================

//--- Clustering
input double InpSnrClusterToleranceATR = 0.25;    // SNR: Cluster tolerance (ATR mult)
input double InpSnrMaxClusterWidthATR  = 1.50;    // SNR: Max cluster width (ATR mult)

//--- Zone Merge
input double InpSnrMergeOverlapRatio   = 0.50;    // SNR: Min overlap for merge
input double InpSnrFreshnessResetPct   = 0.20;    // SNR: New zone dominance threshold

//--- Level Extraction
input int    InpSnrInvalidatedLookback = 150;      // SNR: Invalidated zone lookback (bars)

//--- Scoring Weights (normalized at runtime)
input double InpSnrWeightStruct        = 0.20;    // SNR: W_Struct
input double InpSnrWeightSD            = 0.30;    // SNR: W_SD
input double InpSnrWeightFresh         = 0.20;    // SNR: W_Fresh
input double InpSnrWeightReject        = 0.20;    // SNR: W_Reject
input double InpSnrWeightConfl         = 0.10;    // SNR: W_Confl

//--- Liquidity
input double InpSnrLiquidityTolATR     = 0.10;    // SNR: Pool boundary tolerance (ATR)

//--- Logging
input bool   InpSnrEnableLog           = true;     // SNR: Enable logging

//=========================================================
// CONSTANTS
//=========================================================
const double SNR_PRICE_TOLERANCE = 0.01;  // XAUUSD pip tolerance for price matching
const int    SNR_REJECT_SCAN_BARS = 20;   // Max bars to scan for rejection after touch
const int    SNR_ATR_PERIOD = 14;         // ATR period

//=========================================================
// CLASS: CSnrEngine
//=========================================================
class CSnrEngine
{
private:
   //--- Upstream dependencies (read-only pointers)
   CStructureEngine*      m_structureEngine;
   CSupplyDemandEngine*   m_sdEngine;

   //--- Output arrays
   SNRLevel               m_snrLevels[];
   LiquidityPool          m_liquidityPools[];

   //--- Internal working arrays
   RawLevel               m_rawLevels[];

   //--- Cached H4 price data (for local ATR and rejection scan)
   double                 m_cachedHighs[];
   double                 m_cachedLows[];
   double                 m_cachedCloses[];
   double                 m_cachedOpens[];
   datetime               m_cachedTimes[];
   int                    m_cachedBarsCount;

   //--- State
   int                    m_nextLevelId;
   int                    m_nextPoolId;
   bool                   m_initialized;
   datetime               m_lastBarTime;

   //--- Settings (cached from inputs)
   double                 m_clusterToleranceATR;
   double                 m_maxClusterWidthATR;
   double                 m_mergeOverlapRatio;
   double                 m_freshnessResetPct;
   int                    m_invalidatedLookback;
   double                 m_wStruct;
   double                 m_wSD;
   double                 m_wFresh;
   double                 m_wReject;
   double                 m_wConfl;
   double                 m_liquidityTolATR;
   bool                   m_enableLog;

   //--- Private methods: data ingestion
   void                   CacheH4PriceData(int maxBars);
   double                 CalculateLocalATR(int barIndex);

   //--- Private methods: level extraction
   int                    ExtractLevels();

   //--- Private methods: sorting
   void                   SortLevelsByPrice();

   //--- Private methods: clustering
   int                    ClusterLevels();
   void                   FinalizeCluster(int startIdx, int endIdx, double high, double low);

   //--- Private methods: conflict resolution
   void                   HandleNeutralNodes();
   void                   DetectNestedZones();

   //--- Private methods: scoring helpers
   double                 CalculateRejectionDistance(double zoneHigh, double zoneLow,
                                                     int startBar, bool isBullish);
   bool                   ResolveBOSOrigin(double levelHigh, double levelLow);
   void                   ScoreLevels();

   //--- Private methods: liquidity
   int                    MapLiquidityPools();

   //--- Private methods: utility
   void                   LogMessage(string message);

public:
   //--- Constructor / Destructor
                          CSnrEngine();
                         ~CSnrEngine();

   //--- Initialization
   bool                   Init(CStructureEngine* structEngine, CSupplyDemandEngine* sdEngine);
   void                   Deinit();

   //--- Core analysis pipeline
   int                    Analyze(int maxBars = 300);

   //--- Accessors: SNR Levels
   int                    GetLevelCount() const { return ArraySize(m_snrLevels); }
   bool                   GetLevel(int index, SNRLevel &level);
   int                    GetActiveLevelCount(bool isBullish);
   bool                   GetHighestScoredLevel(bool isBullish, SNRLevel &level);

   //--- Accessors: Liquidity Pools
   int                    GetPoolCount() const { return ArraySize(m_liquidityPools); }
   bool                   GetPool(int index, LiquidityPool &pool);
   int                    GetActivePoolCount(bool isBuyLiquidity);

   //--- New bar detection
   bool                   IsNewBar();
};

//=========================================================
// CONSTRUCTOR
//=========================================================
CSnrEngine::CSnrEngine()
{
   m_structureEngine      = NULL;
   m_sdEngine             = NULL;
   m_cachedBarsCount      = 0;
   m_nextLevelId          = 0;
   m_nextPoolId           = 0;
   m_initialized          = false;
   m_lastBarTime          = 0;
   m_clusterToleranceATR  = InpSnrClusterToleranceATR;
   m_maxClusterWidthATR   = InpSnrMaxClusterWidthATR;
   m_mergeOverlapRatio    = InpSnrMergeOverlapRatio;
   m_freshnessResetPct    = InpSnrFreshnessResetPct;
   m_invalidatedLookback  = InpSnrInvalidatedLookback;
   m_wStruct              = InpSnrWeightStruct;
   m_wSD                  = InpSnrWeightSD;
   m_wFresh               = InpSnrWeightFresh;
   m_wReject              = InpSnrWeightReject;
   m_wConfl               = InpSnrWeightConfl;
   m_liquidityTolATR      = InpSnrLiquidityTolATR;
   m_enableLog            = InpSnrEnableLog;
}

//=========================================================
// DESTRUCTOR
//=========================================================
CSnrEngine::~CSnrEngine()
{
   Deinit();
}

//=========================================================
// INIT
//=========================================================
bool CSnrEngine::Init(CStructureEngine* structEngine, CSupplyDemandEngine* sdEngine)
{
   if(structEngine == NULL || sdEngine == NULL)
   {
      Print("[CSnrEngine] ERROR: Upstream dependency pointer is NULL");
      return false;
   }
   m_structureEngine = structEngine;
   m_sdEngine = sdEngine;

   ArrayResize(m_snrLevels, 0);
   ArrayResize(m_liquidityPools, 0);
   ArrayResize(m_rawLevels, 0);

   m_initialized = true;
   LogMessage("SnrEngine v1.0 initialized"
              + " | ClusterTol=" + DoubleToString(m_clusterToleranceATR, 2) + " ATR"
              + " | MaxWidth=" + DoubleToString(m_maxClusterWidthATR, 2) + " ATR"
              + " | Weights=" + DoubleToString(m_wStruct,2) + "/"
              + DoubleToString(m_wSD,2) + "/" + DoubleToString(m_wFresh,2) + "/"
              + DoubleToString(m_wReject,2) + "/" + DoubleToString(m_wConfl,2));
   return true;
}

//=========================================================
// DEINIT
//=========================================================
void CSnrEngine::Deinit()
{
   ArrayFree(m_snrLevels);
   ArrayFree(m_liquidityPools);
   ArrayFree(m_rawLevels);
   ArrayFree(m_cachedHighs);
   ArrayFree(m_cachedLows);
   ArrayFree(m_cachedCloses);
   ArrayFree(m_cachedOpens);
   ArrayFree(m_cachedTimes);
   m_initialized = false;
}

//=========================================================
// ISNEWBAR
//=========================================================
bool CSnrEngine::IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_H4, 0);
   if(currentBarTime == 0) return false;
   if(currentBarTime != m_lastBarTime)
   {
      m_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//=========================================================
// CACHE H4 PRICE DATA
//=========================================================
void CSnrEngine::CacheH4PriceData(int maxBars)
{
   ArraySetAsSeries(m_cachedOpens, true);
   ArraySetAsSeries(m_cachedHighs, true);
   ArraySetAsSeries(m_cachedLows, true);
   ArraySetAsSeries(m_cachedCloses, true);
   ArraySetAsSeries(m_cachedTimes, true);

   int copied = CopyOpen(_Symbol, PERIOD_H4, 0, maxBars, m_cachedOpens);
   CopyHigh(_Symbol, PERIOD_H4, 0, maxBars, m_cachedHighs);
   CopyLow(_Symbol, PERIOD_H4, 0, maxBars, m_cachedLows);
   CopyClose(_Symbol, PERIOD_H4, 0, maxBars, m_cachedCloses);
   CopyTime(_Symbol, PERIOD_H4, 0, maxBars, m_cachedTimes);

   m_cachedBarsCount = (copied > 0) ? copied : 0;
}

//=========================================================
// LOCAL ATR(14) - Synchronous, no platform handle dependency
//=========================================================
double CSnrEngine::CalculateLocalATR(int barIndex)
{
   if(m_cachedBarsCount <= barIndex + SNR_ATR_PERIOD) return 0.0;

   double sumTR = 0.0;
   int count = 0;

   for(int i = 0; i < SNR_ATR_PERIOD; i++)
   {
      int idx = barIndex + i;
      if(idx >= m_cachedBarsCount - 1) break;

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

//=========================================================
// EXTRACT LEVELS: Swing points + S/D zones -> RawLevel[]
//=========================================================
int CSnrEngine::ExtractLevels()
{
   ArrayResize(m_rawLevels, 0, 200);  // Pre-allocate capacity
   int rawCount = 0;
   double atr = CalculateLocalATR(1);
   double swingTol = (atr > 0.0) ? 0.10 * atr : 1.0;  // Swing band tolerance

   //--- 1. Extract Major Swing Highs (Resistance)
   int majorHighCount = m_structureEngine.GetMajorHighCount();
   for(int i = 0; i < majorHighCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetMajorHigh(i, swing)) continue;

      RawLevel rl;
      rl.price         = swing.price;
      rl.priceHigh     = swing.price + swingTol;
      rl.priceLow      = swing.price - swingTol;
      rl.isBullish     = false;  // Swing High = Resistance
      rl.sourceType    = 0;      // Major Swing
      rl.sourceIndex   = i;
      rl.sourceTime    = swing.barTime;
      rl.reactionCount = swing.reactionCount;
      rl.impulseBarIndex = swing.barIndex;

      ArrayResize(m_rawLevels, rawCount + 1);
      m_rawLevels[rawCount] = rl;
      rawCount++;
   }

   //--- 2. Extract Major Swing Lows (Support)
   int majorLowCount = m_structureEngine.GetMajorLowCount();
   for(int i = 0; i < majorLowCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetMajorLow(i, swing)) continue;

      RawLevel rl;
      rl.price         = swing.price;
      rl.priceHigh     = swing.price + swingTol;
      rl.priceLow      = swing.price - swingTol;
      rl.isBullish     = true;   // Swing Low = Support
      rl.sourceType    = 0;      // Major Swing
      rl.sourceIndex   = i;
      rl.sourceTime    = swing.barTime;
      rl.reactionCount = swing.reactionCount;
      rl.impulseBarIndex = swing.barIndex;

      ArrayResize(m_rawLevels, rawCount + 1);
      m_rawLevels[rawCount] = rl;
      rawCount++;
   }

   //--- 3. Extract Minor Swings (both directions)
   int swingHighCount = m_structureEngine.GetSwingHighCount();
   for(int i = 0; i < swingHighCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetSwingHigh(i, swing)) continue;
      if(swing.grade != SWING_GRADE_MINOR) continue;  // Skip Major (already extracted)

      RawLevel rl;
      rl.price         = swing.price;
      rl.priceHigh     = swing.price + swingTol;
      rl.priceLow      = swing.price - swingTol;
      rl.isBullish     = false;  // Swing High = Resistance
      rl.sourceType    = 1;      // Minor Swing
      rl.sourceIndex   = i;
      rl.sourceTime    = swing.barTime;
      rl.impulseBarIndex = swing.barIndex;

      ArrayResize(m_rawLevels, rawCount + 1);
      m_rawLevels[rawCount] = rl;
      rawCount++;
   }

   int swingLowCount = m_structureEngine.GetSwingLowCount();
   for(int i = 0; i < swingLowCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetSwingLow(i, swing)) continue;
      if(swing.grade != SWING_GRADE_MINOR) continue;

      RawLevel rl;
      rl.price         = swing.price;
      rl.priceHigh     = swing.price + swingTol;
      rl.priceLow      = swing.price - swingTol;
      rl.isBullish     = true;   // Swing Low = Support
      rl.sourceType    = 1;      // Minor Swing
      rl.sourceIndex   = i;
      rl.sourceTime    = swing.barTime;
      rl.impulseBarIndex = swing.barIndex;

      ArrayResize(m_rawLevels, rawCount + 1);
      m_rawLevels[rawCount] = rl;
      rawCount++;
   }

   //--- 4. Extract S/D Zones (active + invalidated within lookback)
   int zoneCount = m_sdEngine.GetZoneCount();
   for(int i = 0; i < zoneCount; i++)
   {
      SupplyDemandZone zone;
      if(!m_sdEngine.GetZone(i, zone)) continue;

      // Skip invalidated zones beyond lookback window
      if(zone.isInvalidated && zone.impulseBarIndex > m_invalidatedLookback)
         continue;

      RawLevel rl;
      rl.price         = (zone.zoneHigh + zone.zoneLow) / 2.0;
      rl.priceHigh     = zone.zoneHigh;
      rl.priceLow      = zone.zoneLow;
      rl.isBullish     = (zone.zoneType == ZONE_DEMAND);
      rl.sourceType    = zone.isInvalidated ? 3 : 2;  // 2=Active, 3=Invalidated
      rl.sourceIndex   = i;
      rl.sourceTime    = zone.impulseTime;
      rl.isInvalidated = zone.isInvalidated;
      rl.impulseRange  = zone.impulseRange;
      rl.bodyDominance = zone.bodyDominance;
      rl.reactionCount = zone.reactionCount;
      rl.impulseBarIndex = zone.impulseBarIndex;

      ArrayResize(m_rawLevels, rawCount + 1);
      m_rawLevels[rawCount] = rl;
      rawCount++;
   }

   LogMessage("ExtractLevels | Total=" + IntegerToString(rawCount)
              + " | MajorSwings=" + IntegerToString(majorHighCount + majorLowCount)
              + " | Zones=" + IntegerToString(zoneCount));
   return rawCount;
}

//=========================================================
// SORT LEVELS BY PRICE (ascending, insertion sort)
//=========================================================
void CSnrEngine::SortLevelsByPrice()
{
   int count = ArraySize(m_rawLevels);
   for(int i = 1; i < count; i++)
   {
      RawLevel key = m_rawLevels[i];
      double keyPrice = (key.priceHigh + key.priceLow) / 2.0;
      int j = i - 1;
      while(j >= 0)
      {
         double jPrice = (m_rawLevels[j].priceHigh + m_rawLevels[j].priceLow) / 2.0;
         if(jPrice <= keyPrice) break;
         m_rawLevels[j + 1] = m_rawLevels[j];
         j--;
      }
      m_rawLevels[j + 1] = key;
   }
}

//=========================================================
// FINALIZE CLUSTER: Create SNRLevel from raw levels range
//=========================================================
void CSnrEngine::FinalizeCluster(int startIdx, int endIdx, double high, double low)
{
   SNRLevel level;
   level.id = m_nextLevelId++;
   level.priceHigh = high;
   level.priceLow = low;
   level.priceMid = (high + low) / 2.0;
   level.constituentCount = endIdx - startIdx + 1;

   //--- Scan constituents to set flags
   int bullishCount = 0;
   int bearishCount = 0;
   bool hasSupplyZone = false;
   bool hasDemandZone = false;
   int mergedReactions = 0;
   datetime oldestTime = D'2099.01.01';
   datetime newestTime = 0;
   double newestImpulse = 0.0;
   double newestDominance = 0.0;
   double oldestImpulse = 0.0;
   double oldestDominance = 0.0;
   int bestZoneStartBar = -1;

   for(int i = startIdx; i <= endIdx; i++)
   {
      RawLevel rl = m_rawLevels[i];

      if(rl.isBullish) bullishCount++;
      else bearishCount++;

      //--- Swing flags
      if(rl.sourceType == 0)  // Major Swing
      {
         if(rl.isBullish) level.hasMajorSwing = true;
         else level.hasMajorSwing = true;
      }
      if(rl.sourceType == 1)  // Minor Swing
         level.hasMinorSwing = true;

      //--- Zone flags
      if(rl.sourceType == 2)  // Active Zone
      {
         level.hasActiveZone = true;
         if(rl.isBullish) hasDemandZone = true;
         else hasSupplyZone = true;
      }
      if(rl.sourceType == 3)  // Invalidated Zone
      {
         level.hasInvalidatedZone = true;
         if(rl.isBullish) hasDemandZone = true;
         else hasSupplyZone = true;
      }

      //--- Zone merge data: track reactions and timestamps
      if(rl.sourceType == 2 || rl.sourceType == 3)
      {
         mergedReactions += rl.reactionCount;

         if(rl.sourceTime < oldestTime)
         {
            oldestTime = rl.sourceTime;
            oldestImpulse = rl.impulseRange;
            oldestDominance = rl.bodyDominance;
         }
         if(rl.sourceTime > newestTime)
         {
            newestTime = rl.sourceTime;
            newestImpulse = rl.impulseRange;
            newestDominance = rl.bodyDominance;
         }
         if(bestZoneStartBar < 0 || rl.impulseBarIndex < bestZoneStartBar)
            bestZoneStartBar = rl.impulseBarIndex;
      }

      //--- Track earliest time across all constituents
      if(rl.sourceTime < level.creationTime || level.creationTime == 0)
         level.creationTime = rl.sourceTime;
   }

   //--- Apply zone merge rules (freshness reset)
   if(mergedReactions > 3) mergedReactions = 3;  // Cap at 3
   level.reactionCount = mergedReactions;

   // Freshness reset: if newer zone dominates older by >= 20%
   if(newestTime > oldestTime && oldestTime > 0)
   {
      bool impulseReset = (oldestImpulse > 0.0 &&
                          newestImpulse > oldestImpulse * (1.0 + m_freshnessResetPct));
      bool dominanceReset = (oldestDominance > 0.0 &&
                            newestDominance > oldestDominance * (1.0 + m_freshnessResetPct));

      if(impulseReset || dominanceReset)
      {
         level.creationTime = newestTime;
         level.reactionCount = 0;
         LogMessage("FreshnessReset | Level #" + IntegerToString(level.id)
                    + " | NewImpulse=" + DoubleToString(newestImpulse, 2)
                    + " OldImpulse=" + DoubleToString(oldestImpulse, 2));
      }
   }

   level.isFresh = (level.reactionCount == 0);

   //--- Determine direction
   level.isBullish = (bullishCount >= bearishCount);

   //--- Neutral node detection: Supply + Demand zone overlap
   if(hasSupplyZone && hasDemandZone)
   {
      level.isNeutralNode = true;
      LogMessage("NeutralNode | Level #" + IntegerToString(level.id)
                 + " at " + DoubleToString(level.priceMid, 3)
                 + " | Supply+Demand overlap");
   }

   //--- Append to output array
   int sz = ArraySize(m_snrLevels);
   ArrayResize(m_snrLevels, sz + 1);
   m_snrLevels[sz] = level;
}

//=========================================================
// CLUSTER LEVELS: Group nearby levels by ATR proximity
//=========================================================
int CSnrEngine::ClusterLevels()
{
   int rawCount = ArraySize(m_rawLevels);
   if(rawCount == 0) return 0;

   // Reset output
   ArrayResize(m_snrLevels, 0);
   m_nextLevelId = 0;

   double atr = CalculateLocalATR(1);
   if(atr <= 0.0)
   {
      LogMessage("WARNING: ATR=0 at bar 1, skipping clustering");
      return 0;
   }

   double tolerance = m_clusterToleranceATR * atr;
   double maxWidth  = m_maxClusterWidthATR * atr;

   int clusterStart = 0;
   double clusterHigh = m_rawLevels[0].priceHigh;
   double clusterLow  = m_rawLevels[0].priceLow;

   for(int i = 1; i < rawCount; i++)
   {
      double gap = m_rawLevels[i].priceLow - clusterHigh;
      double proposedHigh = MathMax(clusterHigh, m_rawLevels[i].priceHigh);
      double proposedLow  = MathMin(clusterLow, m_rawLevels[i].priceLow);
      double proposedWidth = proposedHigh - proposedLow;

      if(gap > tolerance || proposedWidth > maxWidth)
      {
         // Finalize current cluster
         FinalizeCluster(clusterStart, i - 1, clusterHigh, clusterLow);
         // Start new cluster
         clusterStart = i;
         clusterHigh  = m_rawLevels[i].priceHigh;
         clusterLow   = m_rawLevels[i].priceLow;
      }
      else
      {
         // Expand cluster
         clusterHigh = proposedHigh;
         clusterLow  = proposedLow;
      }
   }
   // Finalize last cluster
   FinalizeCluster(clusterStart, rawCount - 1, clusterHigh, clusterLow);

   int levelCount = ArraySize(m_snrLevels);
   LogMessage("ClusterLevels | Clusters=" + IntegerToString(levelCount)
              + " from " + IntegerToString(rawCount) + " raw levels"
              + " | ATR=" + DoubleToString(atr, 3)
              + " | Tolerance=" + DoubleToString(tolerance, 3));
   return levelCount;
}

//=========================================================
// HANDLE NEUTRAL NODES: Detect opposing level overlaps
// (Additional pass for levels that weren't in same cluster
//  but still overlap spatially)
//=========================================================
void CSnrEngine::HandleNeutralNodes()
{
   int count = ArraySize(m_snrLevels);
   for(int i = 0; i < count; i++)
   {
      if(m_snrLevels[i].isNeutralNode) continue;  // Already flagged in cluster

      for(int j = i + 1; j < count; j++)
      {
         if(m_snrLevels[j].isNeutralNode) continue;
         if(m_snrLevels[i].isBullish == m_snrLevels[j].isBullish) continue;

         // Check price overlap between different-direction levels
         double overlapHigh = MathMin(m_snrLevels[i].priceHigh, m_snrLevels[j].priceHigh);
         double overlapLow  = MathMax(m_snrLevels[i].priceLow, m_snrLevels[j].priceLow);

         if(overlapHigh > overlapLow)
         {
            // Only flag as neutral if both have zone backing
            bool iHasZone = (m_snrLevels[i].hasActiveZone || m_snrLevels[i].hasInvalidatedZone);
            bool jHasZone = (m_snrLevels[j].hasActiveZone || m_snrLevels[j].hasInvalidatedZone);

            if(iHasZone && jHasZone)
            {
               m_snrLevels[i].isNeutralNode = true;
               m_snrLevels[j].isNeutralNode = true;
               LogMessage("NeutralNode (cross-cluster) | Levels #"
                          + IntegerToString(m_snrLevels[i].id) + " & #"
                          + IntegerToString(m_snrLevels[j].id));
            }
         }
      }
   }
}

//=========================================================
// DETECT NESTED ZONES: Core (inner) vs Macro (outer)
//=========================================================
void CSnrEngine::DetectNestedZones()
{
   int count = ArraySize(m_snrLevels);
   for(int i = 0; i < count; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         // Same direction only
         if(m_snrLevels[i].isBullish != m_snrLevels[j].isBullish) continue;

         // Check if j is inside i
         if(m_snrLevels[j].priceHigh <= m_snrLevels[i].priceHigh &&
            m_snrLevels[j].priceLow  >= m_snrLevels[i].priceLow)
         {
            m_snrLevels[j].isCoreZone  = true;
            m_snrLevels[i].isMacroZone = true;
         }
         // Check if i is inside j
         else if(m_snrLevels[i].priceHigh <= m_snrLevels[j].priceHigh &&
                 m_snrLevels[i].priceLow  >= m_snrLevels[j].priceLow)
         {
            m_snrLevels[i].isCoreZone  = true;
            m_snrLevels[j].isMacroZone = true;
         }
      }
   }
}

//=========================================================
// CALCULATE REJECTION DISTANCE (ATR-relative bounce)
//=========================================================
double CSnrEngine::CalculateRejectionDistance(double zoneHigh, double zoneLow,
                                              int startBar, bool isBullish)
{
   if(startBar < 1 || startBar >= m_cachedBarsCount) return 0.0;

   double totalRejection = 0.0;
   int touchCount = 0;
   bool insideZone = false;
   int stopBar = 1;  // Never process Bar 0

   for(int bar = startBar - 1; bar >= stopBar; bar--)
   {
      if(bar >= m_cachedBarsCount) continue;

      bool touch = (m_cachedHighs[bar] >= zoneLow && m_cachedLows[bar] <= zoneHigh);

      if(touch)
      {
         if(!insideZone)
         {
            // New touch event — measure rejection
            insideZone = true;
            double maxExcursion = 0.0;
            int scanLimit = MathMin(bar - 1, bar - SNR_REJECT_SCAN_BARS);
            if(scanLimit < 1) scanLimit = 1;

            for(int fb = bar - 1; fb >= scanLimit; fb--)
            {
               if(fb >= m_cachedBarsCount) continue;

               double excursion = 0.0;
               if(isBullish)
                  excursion = m_cachedHighs[fb] - zoneHigh;  // Bounce up from support
               else
                  excursion = zoneLow - m_cachedLows[fb];    // Bounce down from resistance

               if(excursion > maxExcursion) maxExcursion = excursion;
            }

            if(maxExcursion > 0.0)
            {
               totalRejection += maxExcursion;
               touchCount++;
            }
         }
      }
      else
      {
         insideZone = false;
      }
   }

   if(touchCount == 0) return 0.0;
   return totalRejection / (double)touchCount;
}

//=========================================================
// RESOLVE BOS ORIGIN: Cross-reference BOS events with swings
//=========================================================
bool CSnrEngine::ResolveBOSOrigin(double levelHigh, double levelLow)
{
   int bosCount = m_structureEngine.GetBOSCount();

   for(int b = 0; b < bosCount; b++)
   {
      BOSEvent bos;
      if(!m_structureEngine.GetBOSEvent(b, bos)) continue;

      // Find the invalidated swing whose price matches the BOS broken level
      int majorHighCount = m_structureEngine.GetMajorHighCount();
      for(int s = 0; s < majorHighCount; s++)
      {
         SwingPoint swing;
         if(!m_structureEngine.GetMajorHigh(s, swing)) continue;
         if(!swing.isInvalidated) continue;

         // Match: swing price matches BOS broken level
         if(MathAbs(swing.price - bos.brokenLevel) <= SNR_PRICE_TOLERANCE)
         {
            // Check if the BOS origin swing falls within this SNR level
            if(swing.price >= levelLow - SNR_PRICE_TOLERANCE &&
               swing.price <= levelHigh + SNR_PRICE_TOLERANCE)
            {
               return true;
            }
         }
      }

      int majorLowCount = m_structureEngine.GetMajorLowCount();
      for(int s = 0; s < majorLowCount; s++)
      {
         SwingPoint swing;
         if(!m_structureEngine.GetMajorLow(s, swing)) continue;
         if(!swing.isInvalidated) continue;

         if(MathAbs(swing.price - bos.brokenLevel) <= SNR_PRICE_TOLERANCE)
         {
            if(swing.price >= levelLow - SNR_PRICE_TOLERANCE &&
               swing.price <= levelHigh + SNR_PRICE_TOLERANCE)
            {
               return true;
            }
         }
      }
   }
   return false;
}

//=========================================================
// SCORE LEVELS: Apply 5-weight linear model
//=========================================================
void CSnrEngine::ScoreLevels()
{
   double atr = CalculateLocalATR(1);
   // Normalize weights
   double totalW = m_wStruct + m_wSD + m_wFresh + m_wReject + m_wConfl;
   if(totalW <= 0.0) totalW = 1.0;

   double nStruct = m_wStruct / totalW;
   double nSD     = m_wSD / totalW;
   double nFresh  = m_wFresh / totalW;
   double nReject = m_wReject / totalW;
   double nConfl  = m_wConfl / totalW;

   int count = ArraySize(m_snrLevels);
   for(int i = 0; i < count; i++)
   {
      SNRLevel lvl = m_snrLevels[i];

      //--- 1. Structure Score (S_Struct)
      if(lvl.hasMajorSwing)
         lvl.scoreStruct = 100.0;
      else if(lvl.hasMinorSwing)
         lvl.scoreStruct = 50.0;
      else
         lvl.scoreStruct = 0.0;

      //--- 2. Supply/Demand Score (S_SD)
      if(lvl.hasActiveZone)
         lvl.scoreSD = 100.0;
      else if(lvl.hasInvalidatedZone)
         lvl.scoreSD = 30.0;
      else
         lvl.scoreSD = 0.0;

      //--- 3. Freshness Score (S_Fresh)
      if(lvl.reactionCount == 0)
         lvl.scoreFresh = 100.0;
      else if(lvl.reactionCount == 1)
         lvl.scoreFresh = 60.0;
      else if(lvl.reactionCount == 2)
         lvl.scoreFresh = 30.0;
      else
         lvl.scoreFresh = 0.0;

      //--- 4. Rejection Score (S_Reject)
      // Find the earliest impulse bar from constituents for scan start
      int scanStart = -1;
      for(int r = 0; r < ArraySize(m_rawLevels); r++)
      {
         double rMid = (m_rawLevels[r].priceHigh + m_rawLevels[r].priceLow) / 2.0;
         if(rMid >= lvl.priceLow && rMid <= lvl.priceHigh)
         {
            if(m_rawLevels[r].impulseBarIndex > 0)
            {
               if(scanStart < 0 || m_rawLevels[r].impulseBarIndex > scanStart)
                  scanStart = m_rawLevels[r].impulseBarIndex;
            }
         }
      }

      lvl.scoreReject = 0.0;
      if(scanStart > 1 && lvl.reactionCount > 0 && atr > 0.0)
      {
         double avgRejectDist = CalculateRejectionDistance(
            lvl.priceHigh, lvl.priceLow, scanStart, lvl.isBullish);
         double rejectATR = avgRejectDist / atr;
         lvl.scoreReject = MathMin(100.0, rejectATR * 50.0);
      }

      //--- 5. Confluence Score (S_Confl)
      lvl.scoreConfl = 0.0;
      if((lvl.hasActiveZone || lvl.hasInvalidatedZone) && lvl.hasMajorSwing)
         lvl.scoreConfl = 100.0;                    // S/D + Major Swing
      else if(lvl.constituentCount >= 2 &&
              (lvl.hasActiveZone || lvl.hasInvalidatedZone))
         lvl.scoreConfl = 100.0;                    // Multiple zones overlap
      else if(lvl.hasMajorSwing && lvl.hasBOSOrigin)
         lvl.scoreConfl = 70.0;                     // Major Swing + BOS Origin
      else if((lvl.hasActiveZone || lvl.hasInvalidatedZone) && lvl.hasMinorSwing)
         lvl.scoreConfl = 50.0;                     // S/D + Minor Swing
      else
         lvl.scoreConfl = 0.0;

      //--- Total Score
      lvl.scoreTotal = (nStruct * lvl.scoreStruct)
                     + (nSD     * lvl.scoreSD)
                     + (nFresh  * lvl.scoreFresh)
                     + (nReject * lvl.scoreReject)
                     + (nConfl  * lvl.scoreConfl);

      //--- Clamp to [0, 100]
      if(lvl.scoreTotal < 0.0) lvl.scoreTotal = 0.0;
      if(lvl.scoreTotal > 100.0) lvl.scoreTotal = 100.0;

      //--- Write back
      m_snrLevels[i] = lvl;

      LogMessage("LEVEL | id=" + IntegerToString(lvl.id)
                 + " score=" + DoubleToString(lvl.scoreTotal, 1)
                 + " struct=" + DoubleToString(lvl.scoreStruct, 0)
                 + " sd=" + DoubleToString(lvl.scoreSD, 0)
                 + " fresh=" + DoubleToString(lvl.scoreFresh, 0)
                 + " reject=" + DoubleToString(lvl.scoreReject, 1)
                 + " confl=" + DoubleToString(lvl.scoreConfl, 0)
                 + " | " + DoubleToString(lvl.priceLow, 3) + "-" + DoubleToString(lvl.priceHigh, 3)
                 + " | " + (lvl.isBullish ? "SUPPORT" : "RESISTANCE")
                 + (lvl.isNeutralNode ? " [NEUTRAL]" : "")
                 + (lvl.isCoreZone ? " [CORE]" : "")
                 + (lvl.isMacroZone ? " [MACRO]" : ""));
   }
}

//=========================================================
// MAP LIQUIDITY POOLS: Buy/sell stops above/below swings
//=========================================================
int CSnrEngine::MapLiquidityPools()
{
   ArrayResize(m_liquidityPools, 0);
   m_nextPoolId = 0;
   double atr = CalculateLocalATR(1);
   if(atr <= 0.0) return 0;

   double poolTol = m_liquidityTolATR * atr;

   //--- Buy stops above Major Swing Highs (un-invalidated)
   int majorHighCount = m_structureEngine.GetMajorHighCount();
   for(int i = 0; i < majorHighCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetMajorHigh(i, swing)) continue;
      if(swing.isInvalidated) continue;

      LiquidityPool pool;
      pool.id = m_nextPoolId++;
      pool.priceHigh = swing.price + poolTol;
      pool.priceLow  = swing.price;
      pool.isBuyLiquidity = true;
      pool.liquidityStrength = swing.strengthScore;

      // Sweep detection: check if any closed H4 bar's high exceeded pool
      pool.isSwept = false;
      for(int bar = 1; bar < m_cachedBarsCount; bar++)
      {
         if(bar >= m_cachedBarsCount) break;
         if(m_cachedTimes[bar] <= swing.barTime) break;  // Only check bars after swing creation
         if(m_cachedHighs[bar] > pool.priceHigh)
         {
            pool.isSwept = true;
            pool.sweptTime = m_cachedTimes[bar];
            break;
         }
      }

      int sz = ArraySize(m_liquidityPools);
      ArrayResize(m_liquidityPools, sz + 1);
      m_liquidityPools[sz] = pool;
   }

   //--- Sell stops below Major Swing Lows (un-invalidated)
   int majorLowCount = m_structureEngine.GetMajorLowCount();
   for(int i = 0; i < majorLowCount; i++)
   {
      SwingPoint swing;
      if(!m_structureEngine.GetMajorLow(i, swing)) continue;
      if(swing.isInvalidated) continue;

      LiquidityPool pool;
      pool.id = m_nextPoolId++;
      pool.priceHigh = swing.price;
      pool.priceLow  = swing.price - poolTol;
      pool.isBuyLiquidity = false;
      pool.liquidityStrength = swing.strengthScore;

      // Sweep detection
      pool.isSwept = false;
      for(int bar = 1; bar < m_cachedBarsCount; bar++)
      {
         if(bar >= m_cachedBarsCount) break;
         if(m_cachedTimes[bar] <= swing.barTime) break;
         if(m_cachedLows[bar] < pool.priceLow)
         {
            pool.isSwept = true;
            pool.sweptTime = m_cachedTimes[bar];
            break;
         }
      }

      int sz = ArraySize(m_liquidityPools);
      ArrayResize(m_liquidityPools, sz + 1);
      m_liquidityPools[sz] = pool;
   }

   LogMessage("LiquidityPools | Total=" + IntegerToString(ArraySize(m_liquidityPools))
              + " | BuyStops=" + IntegerToString(GetActivePoolCount(true))
              + " | SellStops=" + IntegerToString(GetActivePoolCount(false)));
   return ArraySize(m_liquidityPools);
}

//=========================================================
// ANALYZE: Master pipeline (new H4 bar close only)
//=========================================================
int CSnrEngine::Analyze(int maxBars)
{
   if(!m_initialized) return 0;
   if(m_structureEngine == NULL || m_sdEngine == NULL) return 0;

   //--- Step 1: Cache H4 price data locally
   CacheH4PriceData(maxBars);
   if(m_cachedBarsCount < SNR_ATR_PERIOD + 2)
   {
      LogMessage("WARNING: Insufficient bars for analysis (" + IntegerToString(m_cachedBarsCount) + ")");
      return 0;
   }

   //--- Step 2: Verify ATR is valid
   double atr = CalculateLocalATR(1);
   if(atr <= 0.0)
   {
      LogMessage("WARNING: ATR=0.0 at bar 1, skipping analysis");
      return 0;
   }

   //--- Step 3: Extract raw levels from upstream engines
   int rawCount = ExtractLevels();
   if(rawCount == 0)
   {
      LogMessage("No levels extracted, analysis complete with 0 levels");
      ArrayResize(m_snrLevels, 0);
      ArrayResize(m_liquidityPools, 0);
      return 0;
   }

   //--- Step 4: Sort by price ascending (deterministic clustering)
   SortLevelsByPrice();

   //--- Step 5: Cluster nearby levels
   int clusterCount = ClusterLevels();

   //--- Step 6: Handle neutral nodes (cross-cluster supply/demand overlap)
   HandleNeutralNodes();

   //--- Step 7: Detect nested zones (Core vs. Macro)
   DetectNestedZones();

   //--- Step 8: Resolve BOS origins
   int levelCount = ArraySize(m_snrLevels);
   for(int i = 0; i < levelCount; i++)
   {
      m_snrLevels[i].hasBOSOrigin = ResolveBOSOrigin(
         m_snrLevels[i].priceHigh, m_snrLevels[i].priceLow);
   }

   //--- Step 9: Score all levels
   ScoreLevels();

   //--- Step 10: Map liquidity pools
   MapLiquidityPools();

   LogMessage("Analyze COMPLETE | Levels=" + IntegerToString(ArraySize(m_snrLevels))
              + " | Pools=" + IntegerToString(ArraySize(m_liquidityPools))
              + " | ATR=" + DoubleToString(atr, 3));
   return ArraySize(m_snrLevels);
}

//=========================================================
// ACCESSORS
//=========================================================
bool CSnrEngine::GetLevel(int index, SNRLevel &level)
{
   if(index < 0 || index >= ArraySize(m_snrLevels)) return false;
   level = m_snrLevels[index];
   return true;
}

int CSnrEngine::GetActiveLevelCount(bool isBullish)
{
   int active = 0;
   int total = ArraySize(m_snrLevels);
   for(int i = 0; i < total; i++)
   {
      if(!m_snrLevels[i].isNeutralNode && m_snrLevels[i].isBullish == isBullish)
         active++;
   }
   return active;
}

bool CSnrEngine::GetHighestScoredLevel(bool isBullish, SNRLevel &level)
{
   int total = ArraySize(m_snrLevels);
   double bestScore = -1.0;
   int bestIdx = -1;

   for(int i = 0; i < total; i++)
   {
      if(m_snrLevels[i].isNeutralNode) continue;
      if(m_snrLevels[i].isBullish != isBullish) continue;
      if(m_snrLevels[i].scoreTotal > bestScore)
      {
         bestScore = m_snrLevels[i].scoreTotal;
         bestIdx = i;
      }
   }

   if(bestIdx >= 0)
   {
      level = m_snrLevels[bestIdx];
      return true;
   }
   return false;
}

bool CSnrEngine::GetPool(int index, LiquidityPool &pool)
{
   if(index < 0 || index >= ArraySize(m_liquidityPools)) return false;
   pool = m_liquidityPools[index];
   return true;
}

int CSnrEngine::GetActivePoolCount(bool isBuyLiquidity)
{
   int active = 0;
   int total = ArraySize(m_liquidityPools);
   for(int i = 0; i < total; i++)
   {
      if(!m_liquidityPools[i].isSwept && m_liquidityPools[i].isBuyLiquidity == isBuyLiquidity)
         active++;
   }
   return active;
}

//=========================================================
// LOG MESSAGE
//=========================================================
void CSnrEngine::LogMessage(string message)
{
   if(m_enableLog)
      Print("[CSnrEngine] ", message);
}
