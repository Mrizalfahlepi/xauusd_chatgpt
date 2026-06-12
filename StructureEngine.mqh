//+------------------------------------------------------------------+
//|                                           StructureEngine.mqh    |
//|                        XAUUSD Market Structure Engine            |
//|                        Version 2.1 - Active Level + Invalidation |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Detect market structure on H4 timeframe for XAUUSD.            |
//|   This module is the first stage in the EA data flow pipeline.   |
//|                                                                  |
//| VERSION 2.1 FIXES (from audit):                                  |
//|   P1.1  Fixed BOS premature exit bug                             |
//|   P1.2  BOS events now chronologically ordered                   |
//|   P1.3  Active Structure Level: only last unbroken swing = BOS   |
//|   P1.4  Swing invalidation when broken by BOS                    |
//|                                                                  |
//| RESPONSIBILITIES:                                                |
//|   1. Detect Swing High / Swing Low (fractal-based, N candles)    |
//|   2. Classify swings as Major or Minor (ATR distance filter)     |
//|   3. Classify Major swings as HH, HL, LH, LL                    |
//|   4. Detect Break of Structure (BOS) via Active Level tracking   |
//|   5. Detect Market Structure Shift (MSS)                         |
//|   6. Determine current Trend State (Bullish/Bearish/Range)       |
//|   7. Calculate Strength Score for each Major Swing               |
//|   8. Track swing invalidation state                              |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "2.10"
#property strict

//=========================================================
// ENUMS
//=========================================================

//--- Market trend state
enum ENUM_TREND_STATE
{
   TREND_BULLISH = 0,   // Bullish: HH + HL confirmed
   TREND_BEARISH = 1,   // Bearish: LH + LL confirmed
   TREND_RANGE   = 2    // Range: no confirmed structure
};

//--- Swing point type
enum ENUM_SWING_TYPE
{
   SWING_HIGH = 0,      // Swing High point
   SWING_LOW  = 1       // Swing Low point
};

//--- Swing grade (Major vs Minor)
enum ENUM_SWING_GRADE
{
   SWING_GRADE_NONE  = 0,  // Not yet classified
   SWING_GRADE_MAJOR = 1,  // Major: distance >= threshold ATR
   SWING_GRADE_MINOR = 2   // Minor: distance < threshold ATR (noise)
};

//--- Structure label for a swing point
enum ENUM_STRUCTURE_LABEL
{
   LABEL_NONE = 0,      // Not yet classified
   LABEL_HH   = 1,      // Higher High
   LABEL_HL   = 2,      // Higher Low
   LABEL_LH   = 3,      // Lower High
   LABEL_LL   = 4       // Lower Low
};

//--- BOS direction
enum ENUM_BOS_DIRECTION
{
   BOS_NONE    = 0,     // No BOS
   BOS_BULLISH = 1,     // Bullish BOS (close above swing high)
   BOS_BEARISH = 2      // Bearish BOS (close below swing low)
};

//--- MSS direction
enum ENUM_MSS_DIRECTION
{
   MSS_NONE    = 0,     // No MSS
   MSS_BULLISH = 1,     // Bullish MSS (bearish trend + bullish BOS)
   MSS_BEARISH = 2      // Bearish MSS (bullish trend + bearish BOS)
};

//=========================================================
// STRUCTS
//=========================================================

//--- Represents a single swing point (High or Low)
struct SwingPoint
{
   int                  barIndex;        // Bar index where swing was detected
   datetime             barTime;         // Time of the swing bar
   double               price;           // Price level of the swing
   ENUM_SWING_TYPE      swingType;       // SWING_HIGH or SWING_LOW
   ENUM_STRUCTURE_LABEL label;           // HH, HL, LH, LL, or NONE
   ENUM_SWING_GRADE     grade;           // MAJOR or MINOR
   double               strengthScore;   // Score 0-100 (only for Major)
   double               distanceFromPrev;// ATR-distance from previous major swing
   int                  reactionCount;   // Times price reacted at this level
   int                  barAge;          // Age in bars from current bar
   bool                 isInvalidated;   // true if swing broken by BOS

   //--- Constructor
   SwingPoint()
   {
      barIndex         = -1;
      barTime          = 0;
      price            = 0.0;
      swingType        = SWING_HIGH;
      label            = LABEL_NONE;
      grade            = SWING_GRADE_NONE;
      strengthScore    = 0.0;
      distanceFromPrev = 0.0;
      reactionCount    = 0;
      barAge           = 0;
      isInvalidated    = false;
   }
};

//--- Represents a BOS event
struct BOSEvent
{
   int                  barIndex;         // Bar where BOS occurred
   datetime             barTime;          // Time of BOS bar
   double               breakPrice;       // Close price that caused the break
   double               brokenLevel;      // The swing level that was broken
   double               breakDistance;     // Distance of the break
   double               atrValue;         // ATR(14) at the time
   double               minBreakDistance;  // Minimum required break distance
   ENUM_BOS_DIRECTION   direction;        // Bullish or Bearish

   BOSEvent()
   {
      barIndex         = -1;
      barTime          = 0;
      breakPrice       = 0.0;
      brokenLevel      = 0.0;
      breakDistance     = 0.0;
      atrValue         = 0.0;
      minBreakDistance  = 0.0;
      direction        = BOS_NONE;
   }
};

//--- Represents an MSS event
struct MSSEvent
{
   int                  barIndex;         // Bar where MSS occurred
   datetime             barTime;          // Time of MSS
   ENUM_MSS_DIRECTION   direction;        // Bullish or Bearish MSS
   ENUM_TREND_STATE     previousTrend;    // Trend before the shift
   double               breakPrice;       // Price that caused the shift
   double               brokenLevel;      // Level that was broken

   MSSEvent()
   {
      barIndex      = -1;
      barTime       = 0;
      direction     = MSS_NONE;
      previousTrend = TREND_RANGE;
      breakPrice    = 0.0;
      brokenLevel   = 0.0;
   }
};

//--- Complete structure analysis result
struct StructureResult
{
   ENUM_TREND_STATE  currentTrend;        // Current market trend
   int               swingHighCount;      // Total swing highs detected
   int               swingLowCount;       // Total swing lows detected
   int               majorHighCount;      // Major swing highs
   int               majorLowCount;       // Major swing lows
   int               minorHighCount;      // Minor swing highs
   int               minorLowCount;       // Minor swing lows
   int               bosCount;            // Number of BOS events
   int               mssCount;            // Number of MSS events
   int               invalidHighCount;    // Major highs broken by BOS
   int               invalidLowCount;     // Major lows broken by BOS
   int               hhCount;             // HH count (from Major only)
   int               hlCount;             // HL count (from Major only)
   int               lhCount;             // LH count (from Major only)
   int               llCount;             // LL count (from Major only)
   bool              isValid;             // Whether analysis completed

   StructureResult()
   {
      currentTrend     = TREND_RANGE;
      swingHighCount   = 0;
      swingLowCount    = 0;
      majorHighCount   = 0;
      majorLowCount    = 0;
      minorHighCount   = 0;
      minorLowCount    = 0;
      bosCount         = 0;
      mssCount         = 0;
      invalidHighCount = 0;
      invalidLowCount  = 0;
      hhCount          = 0;
      hlCount          = 0;
      lhCount          = 0;
      llCount          = 0;
      isValid          = false;
   }
};

//=========================================================
// INPUT PARAMETERS
//=========================================================

//--- Swing detection
input int    InpSwingLookback       = 3;      // Swing N: candles left/right
input int    InpMaxBarsAnalyze      = 500;    // Max bars to analyze

//--- ATR settings
input int    InpATRPeriod           = 14;     // ATR period
input double InpBOSBreakMultiplier  = 0.25;   // BOS min break = multiplier * ATR

//--- Major/Minor swing filter
input double InpMinSwingDistATR     = 0.50;   // Major Swing: min distance from prev (ATR)

//--- Strength Score weights (must sum to 100)
input int    InpScoreWeightDisplace = 40;     // Score weight: ATR displacement (%)
input int    InpScoreWeightReaction = 35;     // Score weight: reaction count (%)
input int    InpScoreWeightAge      = 25;     // Score weight: age (%)
input double InpReactionTolerance   = 0.15;   // Reaction detection tolerance (ATR)

//--- Logging
input bool   InpEnableStructureLog  = true;   // Enable structure logging

//=========================================================
// CLASS: CStructureEngine
//=========================================================
class CStructureEngine
{
private:
   //--- Storage: ALL detected swings
   SwingPoint        m_swingHighs[];      // All swing highs (major + minor)
   SwingPoint        m_swingLows[];       // All swing lows  (major + minor)
   SwingPoint        m_allSwings[];       // All swings sorted by time

   //--- Storage: MAJOR swings only (used for structure)
   SwingPoint        m_majorHighs[];      // Major swing highs
   SwingPoint        m_majorLows[];       // Major swing lows

   //--- Structure events
   BOSEvent          m_bosEvents[];       // BOS events (chronological order)
   MSSEvent          m_mssEvents[];       // MSS events

   //--- Cached price data (for scoring/reactions)
   double            m_cachedHighs[];
   double            m_cachedLows[];
   double            m_cachedCloses[];
   datetime          m_cachedTimes[];
   int               m_cachedBarsCount;

   //--- State
   ENUM_TREND_STATE  m_currentTrend;
   StructureResult   m_lastResult;
   datetime          m_lastBarTime;
   int               m_atrHandle;
   bool              m_initialized;

   //--- Settings (cached from inputs)
   int               m_swingLookback;
   double            m_bosBreakMultiplier;
   int               m_atrPeriod;
   int               m_maxBars;
   bool              m_enableLog;
   double            m_minSwingDistATR;
   int               m_scoreWeightDisplace;
   int               m_scoreWeightReaction;
   int               m_scoreWeightAge;
   double            m_reactionTolerance;

   //--- Private methods: swing detection
   bool              IsSwingHigh(const double &highs[], int index, int lookback, int totalBars);
   bool              IsSwingLow(const double &lows[], int index, int lookback, int totalBars);
   void              InsertSwingSorted(SwingPoint &swing);

   //--- Private methods: grade classification
   void              ClassifySwingGrades();
   void              BuildMajorSwingArrays();

   //--- Private methods: strength scoring
   void              CalculateStrengthScores();
   int               CountReactions(double level, double tolerance,
                                    int swingBarIndex, ENUM_SWING_TYPE swingType);

   //--- Private methods: invalidation
   void              SyncInvalidationToArrays();

   //--- Private methods: utility
   double            GetATRValue(int barIndex);
   void              LogMessage(string message);

public:
   //--- Constructor / Destructor
                     CStructureEngine();
                    ~CStructureEngine();

   //--- Initialization
   bool              Init();
   void              Deinit();

   //--- Core analysis functions
   int               DetectSwings(const double &highs[], const double &lows[],
                                  const datetime &times[], int totalBars);
   int               DetectHHHL();
   int               DetectLHLL();
   int               DetectBOS(const double &closes[], const datetime &times[], int totalBars);
   int               DetectMSS();
   ENUM_TREND_STATE  DetectTrendState();

   //--- Full analysis pipeline
   StructureResult   Analyze(int maxBars = 0);

   //--- Accessors: ALL swings
   ENUM_TREND_STATE  GetCurrentTrend()    const { return m_currentTrend; }
   int               GetSwingHighCount()  const { return ArraySize(m_swingHighs); }
   int               GetSwingLowCount()   const { return ArraySize(m_swingLows); }
   int               GetAllSwingCount()   const { return ArraySize(m_allSwings); }
   bool              GetSwingHigh(int index, SwingPoint &swing);
   bool              GetSwingLow(int index, SwingPoint &swing);
   bool              GetSwing(int index, SwingPoint &swing);

   //--- Accessors: MAJOR swings only
   int               GetMajorHighCount()  const { return ArraySize(m_majorHighs); }
   int               GetMajorLowCount()   const { return ArraySize(m_majorLows); }
   bool              GetMajorHigh(int index, SwingPoint &swing);
   bool              GetMajorLow(int index, SwingPoint &swing);

   //--- Accessors: events
   int               GetBOSCount()        const { return ArraySize(m_bosEvents); }
   int               GetMSSCount()        const { return ArraySize(m_mssEvents); }
   bool              GetBOSEvent(int index, BOSEvent &bos);
   bool              GetMSSEvent(int index, MSSEvent &mss);
   StructureResult   GetLastResult() const { return m_lastResult; }

   //--- Utility: to-string
   string            TrendToString(ENUM_TREND_STATE trend);
   string            LabelToString(ENUM_STRUCTURE_LABEL label);
   string            GradeToString(ENUM_SWING_GRADE grade);
   string            BOSDirectionToString(ENUM_BOS_DIRECTION dir);
   string            MSSDirectionToString(ENUM_MSS_DIRECTION dir);

   //--- New bar detection
   bool              IsNewBar();
};

//=========================================================
// CONSTRUCTOR
//=========================================================
CStructureEngine::CStructureEngine()
{
   m_currentTrend        = TREND_RANGE;
   m_lastBarTime         = 0;
   m_atrHandle           = INVALID_HANDLE;
   m_initialized         = false;
   m_cachedBarsCount     = 0;
   m_swingLookback       = InpSwingLookback;
   m_bosBreakMultiplier  = InpBOSBreakMultiplier;
   m_atrPeriod           = InpATRPeriod;
   m_maxBars             = InpMaxBarsAnalyze;
   m_enableLog           = InpEnableStructureLog;
   m_minSwingDistATR     = InpMinSwingDistATR;
   m_scoreWeightDisplace = InpScoreWeightDisplace;
   m_scoreWeightReaction = InpScoreWeightReaction;
   m_scoreWeightAge      = InpScoreWeightAge;
   m_reactionTolerance   = InpReactionTolerance;
}

//=========================================================
// DESTRUCTOR
//=========================================================
CStructureEngine::~CStructureEngine()
{
   Deinit();
}

//=========================================================
// Init
//=========================================================
bool CStructureEngine::Init()
{
   m_atrHandle = iATR(_Symbol, PERIOD_H4, m_atrPeriod);

   if(m_atrHandle == INVALID_HANDLE)
   {
      LogMessage("ERROR: Failed to create ATR indicator handle");
      return false;
   }

   ArrayResize(m_swingHighs, 0);
   ArrayResize(m_swingLows, 0);
   ArrayResize(m_allSwings, 0);
   ArrayResize(m_majorHighs, 0);
   ArrayResize(m_majorLows, 0);
   ArrayResize(m_bosEvents, 0);
   ArrayResize(m_mssEvents, 0);

   m_initialized = true;
   LogMessage("StructureEngine v2.1 initialized"
              + " | Lookback=" + IntegerToString(m_swingLookback)
              + " | ATR=" + IntegerToString(m_atrPeriod)
              + " | BOS_Mult=" + DoubleToString(m_bosBreakMultiplier, 2)
              + " | MajorDist=" + DoubleToString(m_minSwingDistATR, 2) + " ATR");
   return true;
}

//=========================================================
// Deinit
//=========================================================
void CStructureEngine::Deinit()
{
   if(m_atrHandle != INVALID_HANDLE)
   {
      IndicatorRelease(m_atrHandle);
      m_atrHandle = INVALID_HANDLE;
   }
   m_initialized = false;
}

//=========================================================
// IsNewBar
//=========================================================
bool CStructureEngine::IsNewBar()
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
// GetATRValue
//=========================================================
double CStructureEngine::GetATRValue(int barIndex)
{
   if(m_atrHandle == INVALID_HANDLE) return 0.0;
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if(CopyBuffer(m_atrHandle, 0, barIndex, 1, atrBuffer) <= 0)
   {
      LogMessage("WARNING: Failed to read ATR at bar " + IntegerToString(barIndex));
      return 0.0;
   }
   return atrBuffer[0];
}

//=========================================================
// IsSwingHigh
//=========================================================
bool CStructureEngine::IsSwingHigh(const double &highs[], int index,
                                    int lookback, int totalBars)
{
   if(index < lookback || index >= totalBars - lookback) return false;
   double centerHigh = highs[index];
   for(int i = 1; i <= lookback; i++)
   {
      if(highs[index - i] >= centerHigh) return false;
   }
   for(int i = 1; i <= lookback; i++)
   {
      if(highs[index + i] >= centerHigh) return false;
   }
   return true;
}

//=========================================================
// IsSwingLow
//=========================================================
bool CStructureEngine::IsSwingLow(const double &lows[], int index,
                                   int lookback, int totalBars)
{
   if(index < lookback || index >= totalBars - lookback) return false;
   double centerLow = lows[index];
   for(int i = 1; i <= lookback; i++)
   {
      if(lows[index - i] <= centerLow) return false;
   }
   for(int i = 1; i <= lookback; i++)
   {
      if(lows[index + i] <= centerLow) return false;
   }
   return true;
}

//=========================================================
// InsertSwingSorted
//=========================================================
void CStructureEngine::InsertSwingSorted(SwingPoint &swing)
{
   int size = ArraySize(m_allSwings);
   ArrayResize(m_allSwings, size + 1);
   m_allSwings[size] = swing;
}

//=========================================================
// DetectSwings: Find ALL swing points (major + minor)
//=========================================================
int CStructureEngine::DetectSwings(const double &highs[], const double &lows[],
                                    const datetime &times[], int totalBars)
{
   ArrayResize(m_swingHighs, 0);
   ArrayResize(m_swingLows, 0);
   ArrayResize(m_allSwings, 0);
   int swingCount = 0;

   for(int barIdx = totalBars - 1 - m_swingLookback; barIdx >= m_swingLookback; barIdx--)
   {
      if(IsSwingHigh(highs, barIdx, m_swingLookback, totalBars))
      {
         SwingPoint sh;
         sh.barIndex  = barIdx;
         sh.barTime   = times[barIdx];
         sh.price     = highs[barIdx];
         sh.swingType = SWING_HIGH;
         int sz = ArraySize(m_swingHighs);
         ArrayResize(m_swingHighs, sz + 1);
         m_swingHighs[sz] = sh;
         InsertSwingSorted(sh);
         swingCount++;
      }

      if(IsSwingLow(lows, barIdx, m_swingLookback, totalBars))
      {
         SwingPoint sl;
         sl.barIndex  = barIdx;
         sl.barTime   = times[barIdx];
         sl.price     = lows[barIdx];
         sl.swingType = SWING_LOW;
         int sz = ArraySize(m_swingLows);
         ArrayResize(m_swingLows, sz + 1);
         m_swingLows[sz] = sl;
         InsertSwingSorted(sl);
         swingCount++;
      }
   }

   LogMessage("DetectSwings | Highs=" + IntegerToString(ArraySize(m_swingHighs))
              + " | Lows=" + IntegerToString(ArraySize(m_swingLows)));
   return swingCount;
}

//=========================================================
// ClassifySwingGrades: Major/Minor via ATR distance
//   Compare against last MAJOR swing (not last swing).
//   First swing is always Major.
//=========================================================
void CStructureEngine::ClassifySwingGrades()
{
   int highCount = ArraySize(m_swingHighs);
   int lastMajorHighIdx = -1;

   for(int hIdx = 0; hIdx < highCount; hIdx++)
   {
      if(lastMajorHighIdx == -1)
      {
         m_swingHighs[hIdx].grade = SWING_GRADE_MAJOR;
         m_swingHighs[hIdx].distanceFromPrev = 0.0;
         lastMajorHighIdx = hIdx;
         continue;
      }
      double atrVal = GetATRValue(m_swingHighs[hIdx].barIndex);
      double dist = MathAbs(m_swingHighs[hIdx].price - m_swingHighs[lastMajorHighIdx].price);
      m_swingHighs[hIdx].distanceFromPrev = dist;
      if(atrVal > 0.0 && dist >= m_minSwingDistATR * atrVal)
      {
         m_swingHighs[hIdx].grade = SWING_GRADE_MAJOR;
         lastMajorHighIdx = hIdx;
      }
      else
      {
         m_swingHighs[hIdx].grade = SWING_GRADE_MINOR;
      }
   }

   int lowCount = ArraySize(m_swingLows);
   int lastMajorLowIdx = -1;

   for(int lIdx = 0; lIdx < lowCount; lIdx++)
   {
      if(lastMajorLowIdx == -1)
      {
         m_swingLows[lIdx].grade = SWING_GRADE_MAJOR;
         m_swingLows[lIdx].distanceFromPrev = 0.0;
         lastMajorLowIdx = lIdx;
         continue;
      }
      double atrVal = GetATRValue(m_swingLows[lIdx].barIndex);
      double dist = MathAbs(m_swingLows[lIdx].price - m_swingLows[lastMajorLowIdx].price);
      m_swingLows[lIdx].distanceFromPrev = dist;
      if(atrVal > 0.0 && dist >= m_minSwingDistATR * atrVal)
      {
         m_swingLows[lIdx].grade = SWING_GRADE_MAJOR;
         lastMajorLowIdx = lIdx;
      }
      else
      {
         m_swingLows[lIdx].grade = SWING_GRADE_MINOR;
      }
   }

   //--- Sync grades to m_allSwings
   int allCount = ArraySize(m_allSwings);
   for(int aIdx = 0; aIdx < allCount; aIdx++)
   {
      if(m_allSwings[aIdx].swingType == SWING_HIGH)
      {
         for(int h2 = 0; h2 < highCount; h2++)
         {
            if(m_allSwings[aIdx].barIndex == m_swingHighs[h2].barIndex)
            { m_allSwings[aIdx].grade = m_swingHighs[h2].grade; break; }
         }
      }
      else
      {
         for(int l2 = 0; l2 < lowCount; l2++)
         {
            if(m_allSwings[aIdx].barIndex == m_swingLows[l2].barIndex)
            { m_allSwings[aIdx].grade = m_swingLows[l2].grade; break; }
         }
      }
   }

   int mH = 0; int mL = 0;
   for(int c = 0; c < highCount; c++) if(m_swingHighs[c].grade == SWING_GRADE_MAJOR) mH++;
   for(int c = 0; c < lowCount; c++)  if(m_swingLows[c].grade == SWING_GRADE_MAJOR) mL++;
   LogMessage("ClassifyGrades | MajorH=" + IntegerToString(mH) + " MajorL=" + IntegerToString(mL)
              + " | Filter=" + DoubleToString(m_minSwingDistATR, 2) + " ATR");
}

//=========================================================
// BuildMajorSwingArrays
//=========================================================
void CStructureEngine::BuildMajorSwingArrays()
{
   ArrayResize(m_majorHighs, 0);
   ArrayResize(m_majorLows, 0);

   int hc = ArraySize(m_swingHighs);
   for(int i = 0; i < hc; i++)
   {
      if(m_swingHighs[i].grade == SWING_GRADE_MAJOR)
      {
         int sz = ArraySize(m_majorHighs);
         ArrayResize(m_majorHighs, sz + 1);
         m_majorHighs[sz] = m_swingHighs[i];
      }
   }

   int lc = ArraySize(m_swingLows);
   for(int i = 0; i < lc; i++)
   {
      if(m_swingLows[i].grade == SWING_GRADE_MAJOR)
      {
         int sz = ArraySize(m_majorLows);
         ArrayResize(m_majorLows, sz + 1);
         m_majorLows[sz] = m_swingLows[i];
      }
   }

   LogMessage("BuildMajor | Highs=" + IntegerToString(ArraySize(m_majorHighs))
              + " | Lows=" + IntegerToString(ArraySize(m_majorLows)));
}

//=========================================================
// CountReactions
//=========================================================
int CStructureEngine::CountReactions(double level, double tolerance,
                                      int swingBarIndex, ENUM_SWING_TYPE swingType)
{
   int reactions = 0;
   for(int bar = swingBarIndex - 1; bar >= 0; bar--)
   {
      if(bar >= m_cachedBarsCount) continue;
      if(swingType == SWING_HIGH)
      {
         if(MathAbs(m_cachedHighs[bar] - level) <= tolerance) reactions++;
      }
      else
      {
         if(MathAbs(m_cachedLows[bar] - level) <= tolerance) reactions++;
      }
   }
   return reactions;
}

//=========================================================
// CalculateStrengthScores
//=========================================================
void CStructureEngine::CalculateStrengthScores()
{
   double totalW = (double)(m_scoreWeightDisplace + m_scoreWeightReaction + m_scoreWeightAge);
   if(totalW <= 0.0) totalW = 100.0;

   int mhc = ArraySize(m_majorHighs);
   for(int i = 0; i < mhc; i++)
   {
      double atr = GetATRValue(m_majorHighs[i].barIndex);
      double disp = m_majorHighs[i].distanceFromPrev;
      double atrS = (atr > 0.0) ? MathMin(100.0, (disp / atr) * 50.0) : 0.0;

      double tol = m_reactionTolerance * atr;
      int react = CountReactions(m_majorHighs[i].price, tol, m_majorHighs[i].barIndex, SWING_HIGH);
      m_majorHighs[i].reactionCount = react;
      double reactS = MathMin(100.0, react * 25.0);

      int age = m_majorHighs[i].barIndex;
      m_majorHighs[i].barAge = age;
      double ageS = MathMax(0.0, 100.0 - age * 0.25);

      m_majorHighs[i].strengthScore = (atrS * m_scoreWeightDisplace
         + reactS * m_scoreWeightReaction + ageS * m_scoreWeightAge) / totalW;

      //--- Sync to m_swingHighs
      int shc = ArraySize(m_swingHighs);
      for(int s = 0; s < shc; s++)
      {
         if(m_swingHighs[s].barIndex == m_majorHighs[i].barIndex)
         {
            m_swingHighs[s].strengthScore = m_majorHighs[i].strengthScore;
            m_swingHighs[s].reactionCount = react;
            m_swingHighs[s].barAge = age;
            break;
         }
      }
   }

   int mlc = ArraySize(m_majorLows);
   for(int i = 0; i < mlc; i++)
   {
      double atr = GetATRValue(m_majorLows[i].barIndex);
      double disp = m_majorLows[i].distanceFromPrev;
      double atrS = (atr > 0.0) ? MathMin(100.0, (disp / atr) * 50.0) : 0.0;

      double tol = m_reactionTolerance * atr;
      int react = CountReactions(m_majorLows[i].price, tol, m_majorLows[i].barIndex, SWING_LOW);
      m_majorLows[i].reactionCount = react;
      double reactS = MathMin(100.0, react * 25.0);

      int age = m_majorLows[i].barIndex;
      m_majorLows[i].barAge = age;
      double ageS = MathMax(0.0, 100.0 - age * 0.25);

      m_majorLows[i].strengthScore = (atrS * m_scoreWeightDisplace
         + reactS * m_scoreWeightReaction + ageS * m_scoreWeightAge) / totalW;

      int slc = ArraySize(m_swingLows);
      for(int s = 0; s < slc; s++)
      {
         if(m_swingLows[s].barIndex == m_majorLows[i].barIndex)
         {
            m_swingLows[s].strengthScore = m_majorLows[i].strengthScore;
            m_swingLows[s].reactionCount = react;
            m_swingLows[s].barAge = age;
            break;
         }
      }
   }

   LogMessage("StrengthScores | MajorHighs=" + IntegerToString(mhc)
              + " | MajorLows=" + IntegerToString(mlc));
}

//=========================================================
// DetectHHHL: Classify MAJOR swings only.
//=========================================================
int CStructureEngine::DetectHHHL()
{
   int hhCount = 0;
   int hlCount = 0;

   int mhc = ArraySize(m_majorHighs);
   for(int i = 1; i < mhc; i++)
   {
      if(m_majorHighs[i].price > m_majorHighs[i - 1].price)
      { m_majorHighs[i].label = LABEL_HH; hhCount++; }
      else
      { m_majorHighs[i].label = LABEL_LH; }
   }

   int mlc = ArraySize(m_majorLows);
   for(int i = 1; i < mlc; i++)
   {
      if(m_majorLows[i].price > m_majorLows[i - 1].price)
      { m_majorLows[i].label = LABEL_HL; hlCount++; }
      else
      { m_majorLows[i].label = LABEL_LL; }
   }

   //--- Sync labels to m_swingHighs
   int shc = ArraySize(m_swingHighs);
   for(int mi = 0; mi < mhc; mi++)
   {
      for(int si = 0; si < shc; si++)
      {
         if(m_swingHighs[si].barIndex == m_majorHighs[mi].barIndex)
         { m_swingHighs[si].label = m_majorHighs[mi].label; break; }
      }
   }

   //--- Sync labels to m_swingLows
   int slc = ArraySize(m_swingLows);
   for(int mi = 0; mi < mlc; mi++)
   {
      for(int si = 0; si < slc; si++)
      {
         if(m_swingLows[si].barIndex == m_majorLows[mi].barIndex)
         { m_swingLows[si].label = m_majorLows[mi].label; break; }
      }
   }

   //--- Sync labels to m_allSwings
   int asc = ArraySize(m_allSwings);
   for(int ai = 0; ai < asc; ai++)
   {
      if(m_allSwings[ai].swingType == SWING_HIGH)
      {
         for(int mi = 0; mi < mhc; mi++)
         {
            if(m_allSwings[ai].barIndex == m_majorHighs[mi].barIndex)
            { m_allSwings[ai].label = m_majorHighs[mi].label; break; }
         }
      }
      else
      {
         for(int mi = 0; mi < mlc; mi++)
         {
            if(m_allSwings[ai].barIndex == m_majorLows[mi].barIndex)
            { m_allSwings[ai].label = m_majorLows[mi].label; break; }
         }
      }
   }

   LogMessage("DetectHHHL | HH=" + IntegerToString(hhCount) + " | HL=" + IntegerToString(hlCount));
   return hhCount + hlCount;
}

//=========================================================
// DetectLHLL: Count LH and LL from Major swings.
//=========================================================
int CStructureEngine::DetectLHLL()
{
   int lhCount = 0;
   int llCount = 0;

   int mhc = ArraySize(m_majorHighs);
   for(int i = 0; i < mhc; i++)
      if(m_majorHighs[i].label == LABEL_LH) lhCount++;

   int mlc = ArraySize(m_majorLows);
   for(int i = 0; i < mlc; i++)
      if(m_majorLows[i].label == LABEL_LL) llCount++;

   LogMessage("DetectLHLL | LH=" + IntegerToString(lhCount) + " | LL=" + IntegerToString(llCount));
   return lhCount + llCount;
}

//=========================================================
// DetectBOS v2.1 — Active Structure Level tracking
//
//   DESIGN:
//   - Single chronological pass from oldest to newest bar
//   - Tracks 1 "active" swing high + 1 "active" swing low
//   - Active = the most recent Major swing (per spec: "terakhir")
//   - BOS fires ONLY when the active level is broken
//   - Broken swings are invalidated (never reused)
//   - BOS events are naturally chronological
//
//   FIXES vs v2.0:
//   - No premature exit: if ATR check fails, continue scanning
//   - No per-swing separate loops: single unified scan
//   - Chronological output: no separate sort needed
//=========================================================
int CStructureEngine::DetectBOS(const double &closes[], const datetime &times[],
                                 int totalBars)
{
   ArrayResize(m_bosEvents, 0);

   int majorHighCount = ArraySize(m_majorHighs);
   int majorLowCount  = ArraySize(m_majorLows);

   if(majorHighCount == 0 && majorLowCount == 0)
      return 0;

   int bosCount = 0;

   //--- Active structure levels (index into m_majorHighs / m_majorLows)
   //    -1 = no active level yet (waiting for first swing)
   int activeHighIdx = -1;
   int activeLowIdx  = -1;

   //--- Merge-pointers: track which Major swing to process next
   //    Arrays are stored oldest-first (largest barIndex = index 0)
   int highPtr = 0;
   int lowPtr  = 0;

   //--- Find the oldest Major swing bar as scan start
   int startBar = 0;
   if(majorHighCount > 0)
      startBar = MathMax(startBar, m_majorHighs[0].barIndex);
   if(majorLowCount > 0)
      startBar = MathMax(startBar, m_majorLows[0].barIndex);

   //--- Single pass: oldest bar → newest bar
   //    ORDER: (1) check BOS against current active, (2) update active
   //    This ensures BOS fires against the PREVIOUS active, not a new swing
   for(int barIdx = startBar; barIdx >= 0; barIdx--)
   {
      if(barIdx >= totalBars)
         continue;

      //=== STEP 1: Check Bullish BOS ===
      //    Close > active swing high, validated by ATR distance
      if(activeHighIdx >= 0)
      {
         double swingPrice = m_majorHighs[activeHighIdx].price;
         double closePrice = closes[barIdx];

         if(closePrice > swingPrice)
         {
            double atrValue  = GetATRValue(barIdx);
            double breakDist = closePrice - swingPrice;
            double minBreak  = m_bosBreakMultiplier * atrValue;

            if(atrValue > 0.0 && breakDist >= minBreak)
            {
               BOSEvent bos;
               bos.barIndex        = barIdx;
               bos.barTime         = times[barIdx];
               bos.breakPrice      = closePrice;
               bos.brokenLevel     = swingPrice;
               bos.breakDistance    = breakDist;
               bos.atrValue        = atrValue;
               bos.minBreakDistance = minBreak;
               bos.direction       = BOS_BULLISH;

               int bosSize = ArraySize(m_bosEvents);
               ArrayResize(m_bosEvents, bosSize + 1);
               m_bosEvents[bosSize] = bos;
               bosCount++;

               //--- INVALIDATE the broken swing
               m_majorHighs[activeHighIdx].isInvalidated = true;
               activeHighIdx = -1;   // Wait for next swing

               LogMessage("BOS BULLISH | Close=" + DoubleToString(closePrice, (int)_Digits)
                          + " > ActiveHigh=" + DoubleToString(swingPrice, (int)_Digits)
                          + " | Dist=" + DoubleToString(breakDist, (int)_Digits)
                          + " | Time=" + TimeToString(times[barIdx]));
            }
            //--- FIX P1.1: NO break here!
            //    If ATR fails, active level stays. Continue scanning next bars.
         }
      }

      //=== STEP 2: Check Bearish BOS ===
      //    Close < active swing low, validated by ATR distance
      if(activeLowIdx >= 0)
      {
         double swingPrice = m_majorLows[activeLowIdx].price;
         double closePrice = closes[barIdx];

         if(closePrice < swingPrice)
         {
            double atrValue  = GetATRValue(barIdx);
            double breakDist = swingPrice - closePrice;
            double minBreak  = m_bosBreakMultiplier * atrValue;

            if(atrValue > 0.0 && breakDist >= minBreak)
            {
               BOSEvent bos;
               bos.barIndex        = barIdx;
               bos.barTime         = times[barIdx];
               bos.breakPrice      = closePrice;
               bos.brokenLevel     = swingPrice;
               bos.breakDistance    = breakDist;
               bos.atrValue        = atrValue;
               bos.minBreakDistance = minBreak;
               bos.direction       = BOS_BEARISH;

               int bosSize = ArraySize(m_bosEvents);
               ArrayResize(m_bosEvents, bosSize + 1);
               m_bosEvents[bosSize] = bos;
               bosCount++;

               m_majorLows[activeLowIdx].isInvalidated = true;
               activeLowIdx = -1;

               LogMessage("BOS BEARISH | Close=" + DoubleToString(closePrice, (int)_Digits)
                          + " < ActiveLow=" + DoubleToString(swingPrice, (int)_Digits)
                          + " | Dist=" + DoubleToString(breakDist, (int)_Digits)
                          + " | Time=" + TimeToString(times[barIdx]));
            }
            //--- FIX P1.1: NO break here!
         }
      }

      //=== STEP 3: Update active levels if new Major swing at this bar ===
      //    New swing REPLACES the previous active (it is now the "terakhir")
      if(highPtr < majorHighCount && m_majorHighs[highPtr].barIndex == barIdx)
      {
         activeHighIdx = highPtr;
         highPtr++;
      }

      if(lowPtr < majorLowCount && m_majorLows[lowPtr].barIndex == barIdx)
      {
         activeLowIdx = lowPtr;
         lowPtr++;
      }
   }

   LogMessage("DetectBOS v2.1 | BOS=" + IntegerToString(bosCount) + " | Chronological=YES");
   return bosCount;
}

//=========================================================
// SyncInvalidationToArrays: Propagate isInvalidated from
//   m_majorHighs/m_majorLows to m_swingHighs, m_swingLows,
//   and m_allSwings.
//=========================================================
void CStructureEngine::SyncInvalidationToArrays()
{
   int mhc = ArraySize(m_majorHighs);
   int shc = ArraySize(m_swingHighs);
   int asc = ArraySize(m_allSwings);

   for(int mi = 0; mi < mhc; mi++)
   {
      if(!m_majorHighs[mi].isInvalidated)
         continue;

      int targetBar = m_majorHighs[mi].barIndex;

      for(int si = 0; si < shc; si++)
      {
         if(m_swingHighs[si].barIndex == targetBar)
         { m_swingHighs[si].isInvalidated = true; break; }
      }
      for(int ai = 0; ai < asc; ai++)
      {
         if(m_allSwings[ai].barIndex == targetBar && m_allSwings[ai].swingType == SWING_HIGH)
         { m_allSwings[ai].isInvalidated = true; break; }
      }
   }

   int mlc = ArraySize(m_majorLows);
   int slc = ArraySize(m_swingLows);

   for(int mi = 0; mi < mlc; mi++)
   {
      if(!m_majorLows[mi].isInvalidated)
         continue;

      int targetBar = m_majorLows[mi].barIndex;

      for(int si = 0; si < slc; si++)
      {
         if(m_swingLows[si].barIndex == targetBar)
         { m_swingLows[si].isInvalidated = true; break; }
      }
      for(int ai = 0; ai < asc; ai++)
      {
         if(m_allSwings[ai].barIndex == targetBar && m_allSwings[ai].swingType == SWING_LOW)
         { m_allSwings[ai].isInvalidated = true; break; }
      }
   }

   int invH = 0; int invL = 0;
   for(int i = 0; i < mhc; i++) if(m_majorHighs[i].isInvalidated) invH++;
   for(int i = 0; i < mlc; i++) if(m_majorLows[i].isInvalidated) invL++;

   LogMessage("SyncInvalidation | InvalidH=" + IntegerToString(invH)
              + " | InvalidL=" + IntegerToString(invL));
}

//=========================================================
// DetectMSS: Now receives chronologically-sorted BOS
//=========================================================
int CStructureEngine::DetectMSS()
{
   ArrayResize(m_mssEvents, 0);
   int bosCount = ArraySize(m_bosEvents);
   if(bosCount == 0) return 0;

   int mssCount = 0;
   ENUM_TREND_STATE runningTrend = TREND_RANGE;
   int consecutiveBull = 0;
   int consecutiveBear = 0;

   for(int i = 0; i < bosCount; i++)
   {
      if(m_bosEvents[i].direction == BOS_BULLISH)
      {
         consecutiveBull++;
         consecutiveBear = 0;

         if(runningTrend == TREND_BEARISH)
         {
            MSSEvent mss;
            mss.barIndex      = m_bosEvents[i].barIndex;
            mss.barTime       = m_bosEvents[i].barTime;
            mss.direction     = MSS_BULLISH;
            mss.previousTrend = TREND_BEARISH;
            mss.breakPrice    = m_bosEvents[i].breakPrice;
            mss.brokenLevel   = m_bosEvents[i].brokenLevel;
            int sz = ArraySize(m_mssEvents);
            ArrayResize(m_mssEvents, sz + 1);
            m_mssEvents[sz] = mss;
            mssCount++;
            LogMessage("MSS BULLISH | BEARISH -> BULLISH | Time=" + TimeToString(mss.barTime));
         }

         if(consecutiveBull >= 2) runningTrend = TREND_BULLISH;
      }
      else if(m_bosEvents[i].direction == BOS_BEARISH)
      {
         consecutiveBear++;
         consecutiveBull = 0;

         if(runningTrend == TREND_BULLISH)
         {
            MSSEvent mss;
            mss.barIndex      = m_bosEvents[i].barIndex;
            mss.barTime       = m_bosEvents[i].barTime;
            mss.direction     = MSS_BEARISH;
            mss.previousTrend = TREND_BULLISH;
            mss.breakPrice    = m_bosEvents[i].breakPrice;
            mss.brokenLevel   = m_bosEvents[i].brokenLevel;
            int sz = ArraySize(m_mssEvents);
            ArrayResize(m_mssEvents, sz + 1);
            m_mssEvents[sz] = mss;
            mssCount++;
            LogMessage("MSS BEARISH | BULLISH -> BEARISH | Time=" + TimeToString(mss.barTime));
         }

         if(consecutiveBear >= 2) runningTrend = TREND_BEARISH;
      }
   }

   LogMessage("DetectMSS | MSS=" + IntegerToString(mssCount));
   return mssCount;
}

//=========================================================
// DetectTrendState: From MAJOR swings only.
//=========================================================
ENUM_TREND_STATE CStructureEngine::DetectTrendState()
{
   int recentHH = 0, recentHL = 0, recentLH = 0, recentLL = 0;

   int mhc = ArraySize(m_majorHighs);
   for(int i = mhc - 1; i >= 0; i--)
   {
      if(m_majorHighs[i].label == LABEL_HH) recentHH++;
      else if(m_majorHighs[i].label == LABEL_LH) recentLH++;
      else break;
   }

   int mlc = ArraySize(m_majorLows);
   for(int i = mlc - 1; i >= 0; i--)
   {
      if(m_majorLows[i].label == LABEL_HL) recentHL++;
      else if(m_majorLows[i].label == LABEL_LL) recentLL++;
      else break;
   }

   ENUM_TREND_STATE prev = m_currentTrend;

   if(recentHH >= 2 && recentHL >= 2)      m_currentTrend = TREND_BULLISH;
   else if(recentLH >= 2 && recentLL >= 2) m_currentTrend = TREND_BEARISH;
   else                                    m_currentTrend = TREND_RANGE;

   if(prev != m_currentTrend)
   {
      LogMessage("TREND CHANGED | " + TrendToString(prev) + " -> " + TrendToString(m_currentTrend)
                 + " | HH=" + IntegerToString(recentHH) + " HL=" + IntegerToString(recentHL)
                 + " LH=" + IntegerToString(recentLH) + " LL=" + IntegerToString(recentLL));
   }

   return m_currentTrend;
}

//=========================================================
// Analyze: Full pipeline v2.1
//=========================================================
StructureResult CStructureEngine::Analyze(int maxBars)
{
   StructureResult result;

   if(!m_initialized)
   {
      LogMessage("ERROR: StructureEngine not initialized.");
      return result;
   }

   int barsToAnalyze = (maxBars > 0) ? maxBars : m_maxBars;
   int availableBars = iBars(_Symbol, PERIOD_H4);
   if(availableBars < barsToAnalyze) barsToAnalyze = availableBars;

   if(barsToAnalyze < m_swingLookback * 2 + 1)
   {
      LogMessage("ERROR: Not enough bars.");
      return result;
   }

   //--- Step 0: Cache price data
   ArraySetAsSeries(m_cachedHighs, true);
   ArraySetAsSeries(m_cachedLows, true);
   ArraySetAsSeries(m_cachedCloses, true);
   ArraySetAsSeries(m_cachedTimes, true);

   if(CopyHigh(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedHighs) <= 0 ||
      CopyLow(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedLows) <= 0 ||
      CopyClose(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedCloses) <= 0 ||
      CopyTime(_Symbol, PERIOD_H4, 0, barsToAnalyze, m_cachedTimes) <= 0)
   {
      LogMessage("ERROR: Failed to copy H4 price data");
      return result;
   }
   m_cachedBarsCount = barsToAnalyze;

   LogMessage("=== ANALYSIS v2.1 START === Bars=" + IntegerToString(barsToAnalyze));

   //--- Step 1: Detect ALL swings
   DetectSwings(m_cachedHighs, m_cachedLows, m_cachedTimes, barsToAnalyze);
   result.swingHighCount = ArraySize(m_swingHighs);
   result.swingLowCount  = ArraySize(m_swingLows);

   //--- Step 2: Classify Major/Minor
   ClassifySwingGrades();

   //--- Step 3: Build Major arrays
   BuildMajorSwingArrays();
   result.majorHighCount = ArraySize(m_majorHighs);
   result.majorLowCount  = ArraySize(m_majorLows);
   result.minorHighCount = result.swingHighCount - result.majorHighCount;
   result.minorLowCount  = result.swingLowCount  - result.majorLowCount;

   //--- Step 4: Strength Scores
   CalculateStrengthScores();

   //--- Step 5: Classify HH/HL (Major only)
   DetectHHHL();

   //--- Step 6: Count LH/LL (Major only)
   DetectLHLL();

   //--- Step 7: Detect BOS (Active Level tracking)
   result.bosCount = DetectBOS(m_cachedCloses, m_cachedTimes, barsToAnalyze);

   //--- Step 7b: Sync invalidation to all arrays
   SyncInvalidationToArrays();

   //--- Step 8: Determine trend state
   result.currentTrend = DetectTrendState();

   //--- Step 9: Detect MSS (BOS is now chronological)
   result.mssCount = DetectMSS();

   //--- Count labels from Major swings
   result.hhCount = 0; result.hlCount = 0;
   result.lhCount = 0; result.llCount = 0;

   int majorHighCount = ArraySize(m_majorHighs);
   for(int i = 0; i < majorHighCount; i++)
   {
      if(m_majorHighs[i].label == LABEL_HH) result.hhCount++;
      if(m_majorHighs[i].label == LABEL_LH) result.lhCount++;
   }

   int majorLowCount = ArraySize(m_majorLows);
   for(int i = 0; i < majorLowCount; i++)
   {
      if(m_majorLows[i].label == LABEL_HL) result.hlCount++;
      if(m_majorLows[i].label == LABEL_LL) result.llCount++;
   }

   //--- Count invalidated swings
   result.invalidHighCount = 0;
   result.invalidLowCount  = 0;
   for(int i = 0; i < majorHighCount; i++)
      if(m_majorHighs[i].isInvalidated) result.invalidHighCount++;
   for(int i = 0; i < majorLowCount; i++)
      if(m_majorLows[i].isInvalidated) result.invalidLowCount++;

   result.isValid = true;
   m_lastResult = result;

   LogMessage("=== ANALYSIS v2.1 COMPLETE ==="
              + " | Trend=" + TrendToString(result.currentTrend)
              + " | Major=" + IntegerToString(result.majorHighCount + result.majorLowCount)
              + " | Invalid=" + IntegerToString(result.invalidHighCount + result.invalidLowCount)
              + " | HH=" + IntegerToString(result.hhCount)
              + " | HL=" + IntegerToString(result.hlCount)
              + " | LH=" + IntegerToString(result.lhCount)
              + " | LL=" + IntegerToString(result.llCount)
              + " | BOS=" + IntegerToString(result.bosCount)
              + " | MSS=" + IntegerToString(result.mssCount));

   return result;
}

//=========================================================
// DATA ACCESSORS
//=========================================================

bool CStructureEngine::GetSwingHigh(int index, SwingPoint &swing)
{
   if(index < 0 || index >= ArraySize(m_swingHighs)) return false;
   swing = m_swingHighs[index]; return true;
}
bool CStructureEngine::GetSwingLow(int index, SwingPoint &swing)
{
   if(index < 0 || index >= ArraySize(m_swingLows)) return false;
   swing = m_swingLows[index]; return true;
}
bool CStructureEngine::GetSwing(int index, SwingPoint &swing)
{
   if(index < 0 || index >= ArraySize(m_allSwings)) return false;
   swing = m_allSwings[index]; return true;
}
bool CStructureEngine::GetMajorHigh(int index, SwingPoint &swing)
{
   if(index < 0 || index >= ArraySize(m_majorHighs)) return false;
   swing = m_majorHighs[index]; return true;
}
bool CStructureEngine::GetMajorLow(int index, SwingPoint &swing)
{
   if(index < 0 || index >= ArraySize(m_majorLows)) return false;
   swing = m_majorLows[index]; return true;
}
bool CStructureEngine::GetBOSEvent(int index, BOSEvent &bos)
{
   if(index < 0 || index >= ArraySize(m_bosEvents)) return false;
   bos = m_bosEvents[index]; return true;
}
bool CStructureEngine::GetMSSEvent(int index, MSSEvent &mss)
{
   if(index < 0 || index >= ArraySize(m_mssEvents)) return false;
   mss = m_mssEvents[index]; return true;
}

//=========================================================
// STRING UTILITIES
//=========================================================

string CStructureEngine::TrendToString(ENUM_TREND_STATE trend)
{
   switch(trend)
   {
      case TREND_BULLISH: return "BULLISH";
      case TREND_BEARISH: return "BEARISH";
      case TREND_RANGE:   return "RANGE";
      default:            return "UNKNOWN";
   }
}

string CStructureEngine::LabelToString(ENUM_STRUCTURE_LABEL label)
{
   switch(label)
   {
      case LABEL_HH:   return "HH";
      case LABEL_HL:   return "HL";
      case LABEL_LH:   return "LH";
      case LABEL_LL:   return "LL";
      case LABEL_NONE: return "NONE";
      default:         return "UNKNOWN";
   }
}

string CStructureEngine::GradeToString(ENUM_SWING_GRADE grade)
{
   switch(grade)
   {
      case SWING_GRADE_MAJOR: return "MAJOR";
      case SWING_GRADE_MINOR: return "MINOR";
      case SWING_GRADE_NONE:  return "NONE";
      default:                return "UNKNOWN";
   }
}

string CStructureEngine::BOSDirectionToString(ENUM_BOS_DIRECTION dir)
{
   switch(dir)
   {
      case BOS_BULLISH: return "BULLISH";
      case BOS_BEARISH: return "BEARISH";
      case BOS_NONE:    return "NONE";
      default:          return "UNKNOWN";
   }
}

string CStructureEngine::MSSDirectionToString(ENUM_MSS_DIRECTION dir)
{
   switch(dir)
   {
      case MSS_BULLISH: return "BULLISH";
      case MSS_BEARISH: return "BEARISH";
      case MSS_NONE:    return "NONE";
      default:          return "UNKNOWN";
   }
}

//=========================================================
// LogMessage
//=========================================================
void CStructureEngine::LogMessage(string message)
{
   if(m_enableLog)
      Print("[StructureEngine] ", message);
}

//+------------------------------------------------------------------+
