//+------------------------------------------------------------------+
//|                                             SnrPriorityEngine.mqh|
//|                        XAUUSD SNR Priority Engine                 |
//|                        Version 1.0 - Sprint 3.4                  |
//+------------------------------------------------------------------+
#ifndef SNR_PRIORITY_ENGINE_MQH
#define SNR_PRIORITY_ENGINE_MQH

#include "SnrEngine.mqh"

//====================================================================
// OUTPUT STRUCT: Priority Contract passed to Entry Engine
//====================================================================
struct SnrPriorityContract
{
   double         currentPrice;
   double         atr;

   // 1. Structural Levels (Sorted by price distance ascending)
   SNRLevel       supportLevels[3];
   int            supportCount;

   SNRLevel       resistanceLevels[3];
   int            resistanceCount;

   // 2. Tradable Levels (Floors & Ceilings, sorted by price distance ascending)
   SNRLevel       tradableSupport[3];
   int            tradableSupportCount;

   SNRLevel       tradableResistance[3];
   int            tradableResistanceCount;

   // Safety blocking coordinates (sorted by distance ascending)
   SNRLevel       neutralNodes[6];
   int            neutralCount;

   // Immediate liquidity boundaries
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;

   //--- Entry Engine Helper Methods ---
   
   // Returns true if a given price lies within any neutral node boundary
   bool IsInsideNeutralZone(double price) const
   {
      for(int i = 0; i < neutralCount; i++)
      {
         if(price >= neutralNodes[i].priceLow && price <= neutralNodes[i].priceHigh)
            return true;
      }
      return false;
   }

   // Returns the absolute distance (in price points) to the nearest neutral node midpoint
   // Returns -1.0 if there are no neutral nodes in the contract
   double DistanceToNearestNeutral(double price) const
   {
      if(neutralCount == 0) return -1.0;
      double minDist = -1.0;
      for(int i = 0; i < neutralCount; i++)
      {
         double mid = neutralNodes[i].priceMid;
         double dist = MathAbs(price - mid);
         if(minDist < 0.0 || dist < minDist)
            minDist = dist;
      }
      return minDist;
   }
};

//====================================================================
// CLASS: CSnrPriorityEngine
//====================================================================
class CSnrPriorityEngine
{
private:
   // Bounded structural arrays (sorted by distance ascending)
   SNRLevel       m_prioritySupport[3];
   int            m_supportCount;

   SNRLevel       m_priorityResistance[3];
   int            m_resistanceCount;

   // Bounded tradable arrays (sorted by distance ascending)
   SNRLevel       m_tradableSupport[3];
   int            m_tradableSupportCount;

   SNRLevel       m_tradableResistance[3];
   int            m_tradableResistanceCount;

   // Bounded neutral nodes (sorted by distance ascending)
   SNRLevel       m_neutralNodes[6];
   int            m_neutralCount;

   // Nearest active liquidity pools
   LiquidityPool  m_nearestBSL;
   bool           m_hasBSL;

   LiquidityPool  m_nearestSSL;
   bool           m_hasSSL;

   // Cached price state
   double         m_currentPrice;
   double         m_atr;

   // Internal sorting utility
   void           SortLevelsByProximity(SNRLevel &arr[], int size, double currentPrice);

public:
                  CSnrPriorityEngine();
                 ~CSnrPriorityEngine();

   // Master pipeline: Processes Raw Engine data and filters
   bool           Process(CSnrEngine* rawEngine, double currentPrice, double atr, 
                          double minScore = 50.0, double maxTradableDistATR = 5.0);

   // Populate the downstream Entry Engine contract
   void           GetContract(SnrPriorityContract &contract) const;

   // Accessors
   int            GetSupportCount() const { return m_supportCount; }
   int            GetResistanceCount() const { return m_resistanceCount; }
   int            GetTradableSupportCount() const { return m_tradableSupportCount; }
   int            GetTradableResistanceCount() const { return m_tradableResistanceCount; }
   int            GetNeutralCount() const { return m_neutralCount; }
   
   bool           GetSupport(int index, SNRLevel &level) const;
   bool           GetResistance(int index, SNRLevel &level) const;
   bool           GetTradableSupport(int index, SNRLevel &level) const;
   bool           GetTradableResistance(int index, SNRLevel &level) const;
   bool           GetNeutral(int index, SNRLevel &level) const;
   
   bool           GetNearestBSL(LiquidityPool &pool) const;
   bool           GetNearestSSL(LiquidityPool &pool) const;
};

//====================================================================
// CONSTRUCTOR
//====================================================================
CSnrPriorityEngine::CSnrPriorityEngine()
{
   m_supportCount = 0;
   m_resistanceCount = 0;
   m_tradableSupportCount = 0;
   m_tradableResistanceCount = 0;
   m_neutralCount = 0;
   m_hasBSL = false;
   m_hasSSL = false;
   m_currentPrice = 0.0;
   m_atr = 0.0;
}

//====================================================================
// DESTRUCTOR
//====================================================================
CSnrPriorityEngine::~CSnrPriorityEngine()
{
}

//====================================================================
// PROXIMITY SORTING UTILITY (Insertion Sort)
//====================================================================
void CSnrPriorityEngine::SortLevelsByProximity(SNRLevel &arr[], int size, double currentPrice)
{
   for(int i = 1; i < size; i++)
   {
      SNRLevel key = arr[i];
      double keyDist = MathAbs(key.priceMid - currentPrice);
      int j = i - 1;
      while(j >= 0 && MathAbs(arr[j].priceMid - currentPrice) > keyDist)
      {
         arr[j + 1] = arr[j];
         j--;
      }
      arr[j + 1] = key;
   }
}

//====================================================================
// MASTER PROCESS PIPELINE
//====================================================================
bool CSnrPriorityEngine::Process(CSnrEngine* rawEngine, double currentPrice, double atr, 
                                 double minScore, double maxTradableDistATR)
{
   // Reset internal state
   m_supportCount = 0;
   m_resistanceCount = 0;
   m_tradableSupportCount = 0;
   m_tradableResistanceCount = 0;
   m_neutralCount = 0;
   m_hasBSL = false;
   m_hasSSL = false;
   m_currentPrice = currentPrice;
   if(atr <= 0.0) atr = 0.0001;
   m_atr = atr;

   if(rawEngine == NULL) return false;

   int totalLevels = rawEngine.GetLevelCount();
   if(totalLevels == 0) return true;

   // Temporary arrays to hold separated raw levels
   SNRLevel tempSupport[];
   SNRLevel tempResistance[];
   SNRLevel tempNeutral[];
   
   ArrayResize(tempSupport, 0, totalLevels);
   ArrayResize(tempResistance, 0, totalLevels);
   ArrayResize(tempNeutral, 0, totalLevels);
   
   int supRawCount = 0;
   int resRawCount = 0;
   int neutRawCount = 0;

   // 1. Directional Separation
   for(int i = 0; i < totalLevels; i++)
   {
      SNRLevel lvl;
      if(!rawEngine.GetLevel(i, lvl)) continue;
      
      if(lvl.isNeutralNode)
      {
         ArrayResize(tempNeutral, neutRawCount + 1);
         tempNeutral[neutRawCount] = lvl;
         neutRawCount++;
      }
      else if(lvl.isBullish)
      {
         ArrayResize(tempSupport, supRawCount + 1);
         tempSupport[supRawCount] = lvl;
         supRawCount++;
      }
      else
      {
         ArrayResize(tempResistance, resRawCount + 1);
         tempResistance[resRawCount] = lvl;
         resRawCount++;
      }
   }

   // 2. Process Structural Support Levels
   SNRLevel filteredSupport[];
   int filteredSupCount = 0;
   ArrayResize(filteredSupport, 0, supRawCount);
   for(int i = 0; i < supRawCount; i++)
   {
      if(tempSupport[i].scoreTotal >= minScore)
      {
         ArrayResize(filteredSupport, filteredSupCount + 1);
         filteredSupport[filteredSupCount] = tempSupport[i];
         filteredSupCount++;
      }
   }
   
   if(filteredSupCount == 0)
   {
      // Fallback: Nearest active support regardless of score
      int nearestIdx = -1;
      double minDist = -1.0;
      for(int i = 0; i < supRawCount; i++)
      {
         double dist = MathAbs(tempSupport[i].priceMid - currentPrice);
         if(minDist < 0 || dist < minDist)
         {
            minDist = dist;
            nearestIdx = i;
         }
      }
      if(nearestIdx >= 0)
      {
         m_prioritySupport[0] = tempSupport[nearestIdx];
         m_supportCount = 1;
      }
   }
   else
   {
      SortLevelsByProximity(filteredSupport, filteredSupCount, currentPrice);
      m_supportCount = MathMin(3, filteredSupCount);
      for(int i = 0; i < m_supportCount; i++)
      {
         m_prioritySupport[i] = filteredSupport[i];
      }
   }

   // 3. Process Structural Resistance Levels
   SNRLevel filteredResistance[];
   int filteredResCount = 0;
   ArrayResize(filteredResistance, 0, resRawCount);
   for(int i = 0; i < resRawCount; i++)
   {
      if(tempResistance[i].scoreTotal >= minScore)
      {
         ArrayResize(filteredResistance, filteredResCount + 1);
         filteredResistance[filteredResCount] = tempResistance[i];
         filteredResCount++;
      }
   }

   if(filteredResCount == 0)
   {
      // Fallback: Nearest active resistance regardless of score
      int nearestIdx = -1;
      double minDist = -1.0;
      for(int i = 0; i < resRawCount; i++)
      {
         double dist = MathAbs(tempResistance[i].priceMid - currentPrice);
         if(minDist < 0 || dist < minDist)
         {
            minDist = dist;
            nearestIdx = i;
         }
      }
      if(nearestIdx >= 0)
      {
         m_priorityResistance[0] = tempResistance[nearestIdx];
         m_resistanceCount = 1;
      }
   }
   else
   {
      SortLevelsByProximity(filteredResistance, filteredResCount, currentPrice);
      m_resistanceCount = MathMin(3, filteredResCount);
      for(int i = 0; i < m_resistanceCount; i++)
      {
         m_priorityResistance[i] = filteredResistance[i];
      }
   }

   // 4. Process Tradable Support (Floors: isBullish = true AND priceMid < currentPrice AND dist/atr <= maxTradableDistATR)
   SNRLevel tempTradSupport[];
   int tempTradSupCount = 0;
   ArrayResize(tempTradSupport, 0, supRawCount);
   for(int i = 0; i < supRawCount; i++)
   {
      if(tempSupport[i].priceMid < currentPrice)
      {
         ArrayResize(tempTradSupport, tempTradSupCount + 1);
         tempTradSupport[tempTradSupCount] = tempSupport[i];
         tempTradSupCount++;
      }
   }

   SNRLevel filteredTradSupport[];
   int filteredTradSupCount = 0;
   ArrayResize(filteredTradSupport, 0, tempTradSupCount);
   for(int i = 0; i < tempTradSupCount; i++)
   {
      double distATR = MathAbs(tempTradSupport[i].priceMid - currentPrice) / atr;
      bool passed = (tempTradSupport[i].scoreTotal >= minScore && distATR <= maxTradableDistATR);
#ifdef DEBUG_ATR_FILTER
      Print("DEBUG_ATR_FILTER: Support Candidate ID=", tempTradSupport[i].id, 
            " | priceMid=", DoubleToString(tempTradSupport[i].priceMid, 6), 
            " | currentPrice=", DoubleToString(currentPrice, 6), 
            " | atr=", DoubleToString(atr, 6), 
            " | distATR=", DoubleToString(distATR, 8), 
            " | score=", DoubleToString(tempTradSupport[i].scoreTotal, 1),
            " | passed=", passed);
#endif
      if(passed)
      {
         ArrayResize(filteredTradSupport, filteredTradSupCount + 1);
         filteredTradSupport[filteredTradSupCount] = tempTradSupport[i];
         filteredTradSupCount++;
      }
   }

   if(filteredTradSupCount == 0)
   {
      // Fallback: Nearest active support below price regardless of score/distance
      int nearestIdx = -1;
      double minDist = -1.0;
      for(int i = 0; i < tempTradSupCount; i++)
      {
         double dist = MathAbs(tempTradSupport[i].priceMid - currentPrice);
         if(minDist < 0 || dist < minDist)
         {
            minDist = dist;
            nearestIdx = i;
         }
      }
      if(nearestIdx >= 0)
      {
         m_tradableSupport[0] = tempTradSupport[nearestIdx];
         m_tradableSupportCount = 1;
      }
   }
   else
   {
      SortLevelsByProximity(filteredTradSupport, filteredTradSupCount, currentPrice);
      m_tradableSupportCount = MathMin(3, filteredTradSupCount);
      for(int i = 0; i < m_tradableSupportCount; i++)
      {
         m_tradableSupport[i] = filteredTradSupport[i];
      }
   }

   // 5. Process Tradable Resistance (Ceilings: isBullish = false AND priceMid > currentPrice AND dist/atr <= maxTradableDistATR)
   SNRLevel tempTradResistance[];
   int tempTradResCount = 0;
   ArrayResize(tempTradResistance, 0, resRawCount);
   for(int i = 0; i < resRawCount; i++)
   {
      if(tempResistance[i].priceMid > currentPrice)
      {
         ArrayResize(tempTradResistance, tempTradResCount + 1);
         tempTradResistance[tempTradResCount] = tempResistance[i];
         tempTradResCount++;
      }
   }

   SNRLevel filteredTradResistance[];
   int filteredTradResCount = 0;
   ArrayResize(filteredTradResistance, 0, tempTradResCount);
   for(int i = 0; i < tempTradResCount; i++)
   {
      double distATR = MathAbs(tempTradResistance[i].priceMid - currentPrice) / atr;
      bool passed = (tempTradResistance[i].scoreTotal >= minScore && distATR <= maxTradableDistATR);
#ifdef DEBUG_ATR_FILTER
      Print("DEBUG_ATR_FILTER: Resistance Candidate ID=", tempTradResistance[i].id, 
            " | priceMid=", DoubleToString(tempTradResistance[i].priceMid, 6), 
            " | currentPrice=", DoubleToString(currentPrice, 6), 
            " | atr=", DoubleToString(atr, 6), 
            " | distATR=", DoubleToString(distATR, 8), 
            " | score=", DoubleToString(tempTradResistance[i].scoreTotal, 1),
            " | passed=", passed);
#endif
      if(passed)
      {
         ArrayResize(filteredTradResistance, filteredTradResCount + 1);
         filteredTradResistance[filteredTradResCount] = tempTradResistance[i];
         filteredTradResCount++;
      }
   }

   if(filteredTradResCount == 0)
   {
      // Fallback: Nearest active resistance above price regardless of score/distance
      int nearestIdx = -1;
      double minDist = -1.0;
      for(int i = 0; i < tempTradResCount; i++)
      {
         double dist = MathAbs(tempTradResistance[i].priceMid - currentPrice);
         if(minDist < 0 || dist < minDist)
         {
            minDist = dist;
            nearestIdx = i;
         }
      }
      if(nearestIdx >= 0)
      {
         m_tradableResistance[0] = tempTradResistance[nearestIdx];
         m_tradableResistanceCount = 1;
      }
   }
   else
   {
      SortLevelsByProximity(filteredTradResistance, filteredTradResCount, currentPrice);
      m_tradableResistanceCount = MathMin(3, filteredTradResCount);
      for(int i = 0; i < m_tradableResistanceCount; i++)
      {
         m_tradableResistance[i] = filteredTradResistance[i];
      }
   }

   // 6. Process Neutral Nodes (Top 6 nearest to currentPrice)
   if(neutRawCount > 0)
   {
      SortLevelsByProximity(tempNeutral, neutRawCount, currentPrice);
      m_neutralCount = MathMin(6, neutRawCount);
      for(int i = 0; i < m_neutralCount; i++)
      {
         m_neutralNodes[i] = tempNeutral[i];
      }
   }

   // 7. Map Nearest Active Liquidity Pools
   int poolCount = rawEngine.GetPoolCount();
   double minBSL = -1.0;
   double minSSL = -1.0;

   for(int i = 0; i < poolCount; i++)
   {
      LiquidityPool pool;
      if(!rawEngine.GetPool(i, pool)) continue;
      if(pool.isSwept) continue;

      if(pool.isBuyLiquidity)
      {
         if(pool.priceLow > currentPrice)
         {
            double dist = pool.priceLow - currentPrice;
            if(minBSL < 0.0 || dist < minBSL)
            {
               minBSL = dist;
               m_nearestBSL = pool;
               m_hasBSL = true;
            }
         }
      }
      else
      {
         if(pool.priceHigh < currentPrice)
         {
            double dist = currentPrice - pool.priceHigh;
            if(minSSL < 0.0 || dist < minSSL)
            {
               minSSL = dist;
               m_nearestSSL = pool;
               m_hasSSL = true;
            }
         }
      }
   }

   return true;
}

//====================================================================
// GET CONTRACT METHOD
//====================================================================
void CSnrPriorityEngine::GetContract(SnrPriorityContract &contract) const
{
   contract.currentPrice = m_currentPrice;
   contract.atr = m_atr;

   contract.supportCount = m_supportCount;
   for(int i = 0; i < 3; i++) contract.supportLevels[i] = m_prioritySupport[i];

   contract.resistanceCount = m_resistanceCount;
   for(int i = 0; i < 3; i++) contract.resistanceLevels[i] = m_priorityResistance[i];

   contract.tradableSupportCount = m_tradableSupportCount;
   for(int i = 0; i < 3; i++) contract.tradableSupport[i] = m_tradableSupport[i];

   contract.tradableResistanceCount = m_tradableResistanceCount;
   for(int i = 0; i < 3; i++) contract.tradableResistance[i] = m_tradableResistance[i];

   contract.neutralCount = m_neutralCount;
   for(int i = 0; i < 6; i++) contract.neutralNodes[i] = m_neutralNodes[i];

   contract.nearestBSL = m_nearestBSL;
   contract.hasBSL = m_hasBSL;

   contract.nearestSSL = m_nearestSSL;
   contract.hasSSL = m_hasSSL;
}

//====================================================================
// INDIVIDUAL LEVEL ACCESSORS
//====================================================================
bool CSnrPriorityEngine::GetSupport(int index, SNRLevel &level) const
{
   if(index < 0 || index >= m_supportCount) return false;
   level = m_prioritySupport[index];
   return true;
}

bool CSnrPriorityEngine::GetResistance(int index, SNRLevel &level) const
{
   if(index < 0 || index >= m_resistanceCount) return false;
   level = m_priorityResistance[index];
   return true;
}

bool CSnrPriorityEngine::GetTradableSupport(int index, SNRLevel &level) const
{
   if(index < 0 || index >= m_tradableSupportCount) return false;
   level = m_tradableSupport[index];
   return true;
}

bool CSnrPriorityEngine::GetTradableResistance(int index, SNRLevel &level) const
{
   if(index < 0 || index >= m_tradableResistanceCount) return false;
   level = m_tradableResistance[index];
   return true;
}

bool CSnrPriorityEngine::GetNeutral(int index, SNRLevel &level) const
{
   if(index < 0 || index >= m_neutralCount) return false;
   level = m_neutralNodes[index];
   return true;
}

bool CSnrPriorityEngine::GetNearestBSL(LiquidityPool &pool) const
{
   if(!m_hasBSL) return false;
   pool = m_nearestBSL;
   return true;
}

bool CSnrPriorityEngine::GetNearestSSL(LiquidityPool &pool) const
{
   if(!m_hasSSL) return false;
   pool = m_nearestSSL;
   return true;
}

#endif // SNR_PRIORITY_ENGINE_MQH
