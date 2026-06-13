//+------------------------------------------------------------------+
//|                                                   TestSnr.mq5    |
//|                   Visual Test for SnrEngine.mqh v1.0             |
//|                   Version 1.0 - Sprint 3.0                       |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Visualize SNR Engine v1.0 outputs on the H4 chart.             |
//|   Displays:                                                      |
//|   - SNR Levels (color-coded rectangles by score tier)            |
//|   - Liquidity Pools (dashed boxes above/below swings)            |
//|   - Neutral Nodes (hatched deactivated zones)                    |
//|   - Nested Zones (Core/Macro annotations)                       |
//|   - Score labels per level                                       |
//|   - Info dashboard panel                                         |
//|                                                                  |
//| USAGE:                                                            |
//|   Attach as Expert Advisor on XAUUSD H4 chart.                  |
//|   Run in visual backtest mode for best results.                  |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

//--- Include Engine Chain
#include "../engines/SnrEngine.mqh"
#include "../engines/SnrPriorityEngine.mqh"

//=========================================================
// INPUT PARAMETERS
//=========================================================
input int    InpTestMaxBars       = 300;           // Test: Max bars to analyze

//--- Visibility Toggles
input bool   InpShowLevels        = true;          // Show SNR level bands
input bool   InpShowScores        = true;          // Show score labels
input bool   InpShowLiquidity     = true;          // Show liquidity pools
input bool   InpShowNeutral       = true;          // Show neutral nodes
input bool   InpShowNested        = true;          // Show core/macro labels
input bool   InpShowPanel         = true;          // Show info dashboard

//--- Output Prioritization Parameters
input double InpMinPriorityScore        = 50.0;          // Priority: Minimum Quality Score (0-100)
input double InpMaxTradableDistanceATR  = 5.0;           // Priority: Maximum Tradable Distance (ATR)

//--- Display Profiles
enum ENUM_DISPLAY_MODE
{
   DISPLAY_DEV,      // Developer Mode: Render all details for debugging
   DISPLAY_ANALYST,  // Analyst Mode: Render all key levels (Score >= 50)
   DISPLAY_TRADER    // Trader Mode: Render only prioritized Top 3 levels and nearest BSL/SSL
};
input ENUM_DISPLAY_MODE InpDisplayMode  = DISPLAY_TRADER; // SNR: Visual display mode

//--- SNR Level Color Tiers (by score range)
input color  InpColorTier1        = clrGold;       // Score 80-100 (Elite)
input color  InpColorTier2        = clrDodgerBlue;  // Score 60-79 (Strong)
input color  InpColorTier3        = clrMediumPurple; // Score 40-59 (Standard)
input color  InpColorTier4        = clrDimGray;    // Score 0-39 (Weak)

//--- Direction Colors
input color  InpColorSupport      = clrLimeGreen;  // Support bias tint
input color  InpColorResistance   = clrCoral;      // Resistance bias tint

//--- Neutral Node
input color  InpColorNeutral      = clrDarkGray;   // Deactivated neutral
input color  InpColorNeutralBorder= clrRed;        // Neutral border

//--- Liquidity Pool Colors
input color  InpColorBuyPool      = clrDeepSkyBlue; // Buy-stop liquidity
input color  InpColorSellPool     = clrOrangeRed;   // Sell-stop liquidity
input color  InpColorSweptPool    = clrGray;        // Swept pool

//--- Nested Zone Colors
input color  InpColorCore         = clrAqua;       // Core zone label
input color  InpColorMacro        = clrWheat;      // Macro zone label

//=========================================================
// GLOBALS
//=========================================================
CStructureEngine    gStructureEngine;
CSupplyDemandEngine gSDEngine;
CSnrEngine          gSnrEngine;
CSnrPriorityEngine  gPriorityEngine;
string              gObjectPrefix = "SNR_";
bool                gFirstRun     = true;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestSnr v1.0 Starting ===");

   //--- Step 1: Initialize StructureEngine
   if(!gStructureEngine.Init())
   {
      Print("ERROR: Failed to initialize StructureEngine");
      return INIT_FAILED;
   }

   //--- Step 2: Initialize SupplyDemandEngine (depends on StructureEngine)
   if(!gSDEngine.Init(&gStructureEngine))
   {
      Print("ERROR: Failed to initialize SupplyDemandEngine");
      return INIT_FAILED;
   }

   //--- Step 3: Initialize SnrEngine (depends on both upstream engines)
   if(!gSnrEngine.Init(&gStructureEngine, &gSDEngine))
   {
      Print("ERROR: Failed to initialize SnrEngine");
      return INIT_FAILED;
   }

   gFirstRun = true;
   Print("TestSnr v1.0 initialized successfully");
   Print("  StructureEngine:    OK");
   Print("  SupplyDemandEngine: OK");
   Print("  SnrEngine:          OK");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CleanupObjects();
   gSnrEngine.Deinit();
   gSDEngine.Deinit();
   gStructureEngine.Deinit();
   Print("=== TestSnr v1.0 Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Only process on new H4 bars (or first run)
   if(!gFirstRun && !gStructureEngine.IsNewBar())
      return;

   gFirstRun = false;

   //--- Clean previous visualization
   CleanupObjects();

   //--- Step 1: Run upstream StructureEngine
   StructureResult structRes = gStructureEngine.Analyze(InpTestMaxBars);
   if(!structRes.isValid)
   {
      Print("WARNING: StructureEngine returned invalid result");
      return;
   }

   //--- Step 2: Run upstream SupplyDemandEngine
   gSDEngine.Analyze(InpTestMaxBars);

   //--- Step 3: Run SNR Engine
   int levelCount = gSnrEngine.Analyze(InpTestMaxBars);

   //--- Step 3.5: Run SNR Priority Engine
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(currentPrice <= 0.0)
      currentPrice = iClose(_Symbol, PERIOD_H4, 0);
   double atr = gSnrEngine.GetLocalATR(1);
   gPriorityEngine.Process(GetPointer(gSnrEngine), currentPrice, atr, InpMinPriorityScore, InpMaxTradableDistanceATR);

   //--- Step 4: Draw all SNR visualizations
   if(InpShowLevels)
      DrawSNRLevels();

   if(InpShowLiquidity)
      DrawLiquidityPools();

   if(InpShowPanel)
      DrawInfoPanel();

   //--- Step 5: Print detailed summary to log
   PrintSummary();

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| CleanupObjects: Remove all objects with our prefix               |
//+------------------------------------------------------------------+
void CleanupObjects()
{
   int totalObjects = ObjectsTotal(0, -1, -1);
   for(int objIdx = totalObjects - 1; objIdx >= 0; objIdx--)
   {
      string objectName = ObjectName(0, objIdx, -1, -1);
      if(StringFind(objectName, gObjectPrefix) == 0)
         ObjectDelete(0, objectName);
   }
}

//=========================================================
// DRAWING FUNCTIONS
//=========================================================

//+------------------------------------------------------------------+
//| DrawLevelHelper: Render a single SNR Level                       |
//+------------------------------------------------------------------+
void DrawLevelHelper(const SNRLevel &level, bool isAnalystNeutral = false)
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_H4, 0);
   if(currentBarTime == 0) return;

   string rectName  = gObjectPrefix + "LVL_" + IntegerToString(level.id);
   string scoreName = gObjectPrefix + "SCR_" + IntegerToString(level.id);
   string tagName   = gObjectPrefix + "TAG_" + IntegerToString(level.id);

   //--- Determine color by score tier
   color levelColor = GetScoreTierColor(level.scoreTotal);

   //--- Override for neutral nodes
   bool fillRect = true;
   ENUM_LINE_STYLE lineStyle = STYLE_SOLID;
   int lineWidth = 1;
   color borderColor = levelColor;

   if(level.isNeutralNode)
   {
      if(!InpShowNeutral) return;
      levelColor = InpColorNeutral;
      if(isAnalystNeutral)
      {
         borderColor = clrLightGray; // analyst mode: light border
         lineStyle = STYLE_DASH;
         lineWidth = 1;
      }
      else
      {
         borderColor = InpColorNeutralBorder;
         lineStyle = STYLE_DASHDOT;
         lineWidth = 2;
      }
      fillRect = false;
   }

   //--- Calculate start time: use creation time or current window
   datetime startTime = level.creationTime;
   if(startTime == 0) startTime = iTime(_Symbol, PERIOD_H4, InpTestMaxBars - 1);

   //--- Draw the level band rectangle
   if(ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, level.priceHigh,
                   currentBarTime, level.priceLow))
   {
      ObjectSetInteger(0, rectName, OBJPROP_COLOR, borderColor);
      ObjectSetInteger(0, rectName, OBJPROP_FILL, fillRect);
      ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
      ObjectSetInteger(0, rectName, OBJPROP_STYLE, lineStyle);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);

      //--- Build tooltip
      string tipDirection = level.isBullish ? "SUPPORT" : "RESISTANCE";
      string tipFresh     = level.isFresh ? "FRESH" : ("Reacts=" + IntegerToString(level.reactionCount));
      string tipFlags     = "";
      if(level.isNeutralNode)    tipFlags += " [NEUTRAL]";
      if(level.isCoreZone)       tipFlags += " [CORE]";
      if(level.isMacroZone)      tipFlags += " [MACRO]";
      if(level.hasBOSOrigin)     tipFlags += " [BOS]";

      ObjectSetString(0, rectName, OBJPROP_TOOLTIP,
         "SNR #" + IntegerToString(level.id) +
         " | " + tipDirection +
         " | Score=" + DoubleToString(level.scoreTotal, 1) +
         " | " + tipFresh +
         " | Consts=" + IntegerToString(level.constituentCount) +
         tipFlags);
   }

   //--- Draw score label at the right edge of the level band
   if(InpShowScores && !level.isNeutralNode)
   {
      string scoreText = DoubleToString(level.scoreTotal, 1);
      double labelPrice = level.priceMid;

      if(ObjectCreate(0, scoreName, OBJ_TEXT, 0, currentBarTime, labelPrice))
      {
         ObjectSetString(0, scoreName, OBJPROP_TEXT, scoreText);
         ObjectSetInteger(0, scoreName, OBJPROP_COLOR, levelColor);
         ObjectSetInteger(0, scoreName, OBJPROP_FONTSIZE, 9);
         ObjectSetString(0, scoreName, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, scoreName, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, scoreName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, scoreName, OBJPROP_HIDDEN, true);
      }
   }

   //--- Draw direction + special tag labels
   if(InpShowNested || InpShowNeutral)
   {
      string tagText = "";

      if(level.isNeutralNode)
         tagText = "NEUTRAL";
      else if(level.isCoreZone && InpShowNested)
         tagText = "CORE";
      else if(level.isMacroZone && InpShowNested)
         tagText = "MACRO";

      if(tagText != "")
      {
         color tagColor = clrWhite;
         if(level.isNeutralNode)    tagColor = InpColorNeutralBorder;
         else if(level.isCoreZone)  tagColor = InpColorCore;
         else if(level.isMacroZone) tagColor = InpColorMacro;

         if(ObjectCreate(0, tagName, OBJ_TEXT, 0, startTime, level.priceHigh))
         {
            ObjectSetString(0, tagName, OBJPROP_TEXT, tagText);
            ObjectSetInteger(0, tagName, OBJPROP_COLOR, tagColor);
            ObjectSetInteger(0, tagName, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, tagName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, tagName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
            ObjectSetInteger(0, tagName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, tagName, OBJPROP_HIDDEN, true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| DrawSNRLevels: Render SNR level bands based on display profile    |
//+------------------------------------------------------------------+
void DrawSNRLevels()
{
   if(InpDisplayMode == DISPLAY_DEV)
   {
      int count = gSnrEngine.GetLevelCount();
      for(int i = 0; i < count; i++)
      {
         SNRLevel level;
         if(gSnrEngine.GetLevel(i, level))
            DrawLevelHelper(level, false);
      }
   }
   else if(InpDisplayMode == DISPLAY_ANALYST)
   {
      int count = gSnrEngine.GetLevelCount();
      for(int i = 0; i < count; i++)
      {
         SNRLevel level;
         if(gSnrEngine.GetLevel(i, level))
         {
            if(level.isNeutralNode)
               DrawLevelHelper(level, true);
            else if(level.scoreTotal >= InpMinPriorityScore)
               DrawLevelHelper(level, false);
         }
      }
   }
   else if(InpDisplayMode == DISPLAY_TRADER)
   {
      int supportCount = gPriorityEngine.GetSupportCount();
      for(int i = 0; i < supportCount; i++)
      {
         SNRLevel level;
         if(gPriorityEngine.GetSupport(i, level))
            DrawLevelHelper(level, false);
      }

      int resistanceCount = gPriorityEngine.GetResistanceCount();
      for(int i = 0; i < resistanceCount; i++)
      {
         SNRLevel level;
         if(gPriorityEngine.GetResistance(i, level))
            DrawLevelHelper(level, false);
      }
   }
}

//+------------------------------------------------------------------+
//| DrawPoolHelper: Render a single Liquidity Pool                   |
//+------------------------------------------------------------------+
void DrawPoolHelper(const LiquidityPool &pool)
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_H4, 0);
   if(currentBarTime == 0) return;

   string rectName  = gObjectPrefix + "POOL_" + IntegerToString(pool.id);
   string labelName = gObjectPrefix + "PLBL_" + IntegerToString(pool.id);

   //--- Determine color
   color poolColor = pool.isBuyLiquidity ? InpColorBuyPool : InpColorSellPool;
   ENUM_LINE_STYLE poolStyle = STYLE_DASH;

   if(pool.isSwept)
   {
      poolColor = InpColorSweptPool;
      poolStyle = STYLE_DOT;
   }

   //--- Determine time boundaries
   datetime endTime = pool.isSwept ? pool.sweptTime : currentBarTime;

   // Use a lookback window for the start time
   datetime startTime = iTime(_Symbol, PERIOD_H4, MathMin(InpTestMaxBars - 1, iBars(_Symbol, PERIOD_H4) - 1));
   if(startTime == 0) startTime = currentBarTime;

   //--- Draw pool rectangle (outline only, no fill)
   if(ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, pool.priceHigh,
                   endTime, pool.priceLow))
   {
      ObjectSetInteger(0, rectName, OBJPROP_COLOR, poolColor);
      ObjectSetInteger(0, rectName, OBJPROP_FILL, false);
      ObjectSetInteger(0, rectName, OBJPROP_BACK, false);
      ObjectSetInteger(0, rectName, OBJPROP_STYLE, poolStyle);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);

      string poolType = pool.isBuyLiquidity ? "BUY STOPS" : "SELL STOPS";
      string sweptStr = pool.isSwept ? " [SWEPT]" : "";
      ObjectSetString(0, rectName, OBJPROP_TOOLTIP,
         "Pool #" + IntegerToString(pool.id) +
         " | " + poolType +
         " | Strength=" + DoubleToString(pool.liquidityStrength, 1) +
         sweptStr);
   }

   //--- Draw pool type label
   string lblText = pool.isBuyLiquidity ? "BSL" : "SSL";
   if(pool.isSwept) lblText = "x" + lblText;

   if(ObjectCreate(0, labelName, OBJ_TEXT, 0, endTime, pool.priceHigh))
   {
      ObjectSetString(0, labelName, OBJPROP_TEXT, lblText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, poolColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR,
         pool.isBuyLiquidity ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| DrawLiquidityPools: Render liquidity pools based on display mode |
//+------------------------------------------------------------------+
void DrawLiquidityPools()
{
   if(InpDisplayMode == DISPLAY_DEV)
   {
      int poolCount = gSnrEngine.GetPoolCount();
      for(int i = 0; i < poolCount; i++)
      {
         LiquidityPool pool;
         if(gSnrEngine.GetPool(i, pool))
            DrawPoolHelper(pool);
      }
   }
   else if(InpDisplayMode == DISPLAY_ANALYST)
   {
      int poolCount = gSnrEngine.GetPoolCount();
      for(int i = 0; i < poolCount; i++)
      {
         LiquidityPool pool;
         if(gSnrEngine.GetPool(i, pool))
         {
            if(!pool.isSwept)
               DrawPoolHelper(pool);
         }
      }
   }
   else if(InpDisplayMode == DISPLAY_TRADER)
   {
      LiquidityPool pool;
      if(gPriorityEngine.GetNearestBSL(pool))
         DrawPoolHelper(pool);
      if(gPriorityEngine.GetNearestSSL(pool))
         DrawPoolHelper(pool);
   }
}

//+------------------------------------------------------------------+
//| GetScoreTierColor: Map score to color tier                       |
//+------------------------------------------------------------------+
color GetScoreTierColor(double score)
{
   if(score >= 80.0) return InpColorTier1;      // Elite: Gold
   if(score >= 60.0) return InpColorTier2;      // Strong: DodgerBlue
   if(score >= 40.0) return InpColorTier3;      // Standard: MediumPurple
   return InpColorTier4;                         // Weak: DimGray
}

//+------------------------------------------------------------------+
//| DrawInfoPanel: On-chart information dashboard                    |
//+------------------------------------------------------------------+
void DrawInfoPanel()
{
   int panelX = 10;
   int panelY = 30;
   int panelW = 320;
   int panelH = 420;

   //--- Panel Background
   CreateRectLabel(gObjectPrefix + "PNL_BG", panelX, panelY, panelW, panelH,
                   clrBlack, 210);

   int x = panelX + 10;
   int y = panelY + 10;
   int dy = 18;

   //--- Title
   CreateChartLabel(gObjectPrefix + "PNL_T0", x, y,
      "=== SNR ENGINE v1.0 ===", clrGold, 12);
   y += dy + 6;

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PNL_S1", x, y,
      "-------------------------------", clrDimGray, 8);
   y += dy;

   //--- Level Counts
   int totalLevels  = gSnrEngine.GetLevelCount();
   int activeSup    = gSnrEngine.GetActiveLevelCount(true);
   int activeRes    = gSnrEngine.GetActiveLevelCount(false);

   CreateChartLabel(gObjectPrefix + "PNL_LC", x, y,
      "Total Levels:    " + IntegerToString(totalLevels), clrWhite, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_AS", x, y,
      "Active Support:  " + IntegerToString(activeSup), clrLimeGreen, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_AR", x, y,
      "Active Resist:   " + IntegerToString(activeRes), clrCoral, 10);
   y += dy + 4;

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PNL_S2", x, y,
      "-------------------------------", clrDimGray, 8);
   y += dy;

   //--- Score Tiers
   int tier1 = 0, tier2 = 0, tier3 = 0, tier4 = 0;
   int neutralCount = 0, coreCount = 0, macroCount = 0;
   int bosOriginCount = 0, freshCount = 0;

   for(int i = 0; i < totalLevels; i++)
   {
      SNRLevel lvl;
      if(!gSnrEngine.GetLevel(i, lvl)) continue;

      if(lvl.scoreTotal >= 80.0)      tier1++;
      else if(lvl.scoreTotal >= 60.0) tier2++;
      else if(lvl.scoreTotal >= 40.0) tier3++;
      else                             tier4++;

      if(lvl.isNeutralNode)   neutralCount++;
      if(lvl.isCoreZone)      coreCount++;
      if(lvl.isMacroZone)     macroCount++;
      if(lvl.hasBOSOrigin)    bosOriginCount++;
      if(lvl.isFresh)         freshCount++;
   }

   CreateChartLabel(gObjectPrefix + "PNL_T1", x, y,
      "Elite (80+):     " + IntegerToString(tier1), InpColorTier1, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_T2", x, y,
      "Strong (60-79):  " + IntegerToString(tier2), InpColorTier2, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_T3", x, y,
      "Standard (40-59):" + IntegerToString(tier3), InpColorTier3, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_T4", x, y,
      "Weak (0-39):     " + IntegerToString(tier4), InpColorTier4, 10);
   y += dy + 4;

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PNL_S3", x, y,
      "-------------------------------", clrDimGray, 8);
   y += dy;

   //--- Highest Scores
   SNRLevel bestSup, bestRes;
   string bestSupStr = "---";
   string bestResStr = "---";

   if(gSnrEngine.GetHighestScoredLevel(true, bestSup))
      bestSupStr = DoubleToString(bestSup.scoreTotal, 1) + " @ " +
                   DoubleToString(bestSup.priceMid, _Digits);

   if(gSnrEngine.GetHighestScoredLevel(false, bestRes))
      bestResStr = DoubleToString(bestRes.scoreTotal, 1) + " @ " +
                   DoubleToString(bestRes.priceMid, _Digits);

   CreateChartLabel(gObjectPrefix + "PNL_BS", x, y,
      "Best Support:  " + bestSupStr, clrLimeGreen, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_BR", x, y,
      "Best Resist:   " + bestResStr, clrCoral, 9);
   y += dy + 4;

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PNL_S4", x, y,
      "-------------------------------", clrDimGray, 8);
   y += dy;

   //--- Confluence & Special Flags
   CreateChartLabel(gObjectPrefix + "PNL_FR", x, y,
      "Fresh Levels:    " + IntegerToString(freshCount), clrAqua, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_BO", x, y,
      "BOS Origins:     " + IntegerToString(bosOriginCount), clrYellow, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_NN", x, y,
      "Neutral Nodes:   " + IntegerToString(neutralCount), InpColorNeutralBorder, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_CZ", x, y,
      "Core Zones:      " + IntegerToString(coreCount), InpColorCore, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_MZ", x, y,
      "Macro Zones:     " + IntegerToString(macroCount), InpColorMacro, 9);
   y += dy + 4;

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PNL_S5", x, y,
      "-------------------------------", clrDimGray, 8);
   y += dy;

   //--- Liquidity Pools
   int totalPools     = gSnrEngine.GetPoolCount();
   int activeBuyPools = gSnrEngine.GetActivePoolCount(true);
   int activeSellPools= gSnrEngine.GetActivePoolCount(false);
   int sweptPools     = totalPools - activeBuyPools - activeSellPools;

   CreateChartLabel(gObjectPrefix + "PNL_PL", x, y,
      "Liquidity Pools: " + IntegerToString(totalPools), clrWhite, 10);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_BP", x, y,
      "  Buy Stops:     " + IntegerToString(activeBuyPools), InpColorBuyPool, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_SP", x, y,
      "  Sell Stops:    " + IntegerToString(activeSellPools), InpColorSellPool, 9);
   y += dy;

   CreateChartLabel(gObjectPrefix + "PNL_SW", x, y,
      "  Swept:         " + IntegerToString(sweptPools), InpColorSweptPool, 9);
   y += dy + 4;

   //--- Footer
   CreateChartLabel(gObjectPrefix + "PNL_FT", x, y,
      "Bars:" + IntegerToString(InpTestMaxBars) + " | TF:H4 | " +
      TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES), clrDarkGray, 8);
}

//=========================================================
// LOG OUTPUT
//=========================================================

//+------------------------------------------------------------------+
//| PrintSummary: Print full analysis summary to Experts log         |
//+------------------------------------------------------------------+
void PrintSummary()
{
   int levelCount = gSnrEngine.GetLevelCount();
   int poolCount  = gSnrEngine.GetPoolCount();

   Print("====================================================");
   Print("     SNR ENGINE v1.0 SUMMARY");
   Print("====================================================");
   Print("  Total Levels:    ", levelCount);
   Print("  Active Support:  ", gSnrEngine.GetActiveLevelCount(true));
   Print("  Active Resist:   ", gSnrEngine.GetActiveLevelCount(false));
   Print("  ---");
   Print("  Total Pools:     ", poolCount);
   Print("  Active Buy:      ", gSnrEngine.GetActivePoolCount(true));
   Print("  Active Sell:     ", gSnrEngine.GetActivePoolCount(false));
   Print("====================================================");

   //--- Print per-level details
   if(levelCount > 0)
   {
      Print("--- SNR Level Details ---");
      for(int i = 0; i < levelCount; i++)
      {
         SNRLevel lvl;
         if(!gSnrEngine.GetLevel(i, lvl)) continue;

         string dirStr    = lvl.isBullish ? "SUPPORT" : "RESIST ";
         string freshStr  = lvl.isFresh ? "FRESH" : ("R=" + IntegerToString(lvl.reactionCount));
         string flagStr   = "";
         if(lvl.isNeutralNode)    flagStr += " [NEUTRAL]";
         if(lvl.isCoreZone)       flagStr += " [CORE]";
         if(lvl.isMacroZone)      flagStr += " [MACRO]";
         if(lvl.hasBOSOrigin)     flagStr += " [BOS]";
         if(lvl.hasMajorSwing)    flagStr += " [MAJ_SW]";
         if(lvl.hasActiveZone)    flagStr += " [ACT_ZN]";

         Print("  #", lvl.id,
               " | ", dirStr,
               " | Score=", DoubleToString(lvl.scoreTotal, 1),
               " (St=", DoubleToString(lvl.scoreStruct, 0),
               " SD=", DoubleToString(lvl.scoreSD, 0),
               " Fr=", DoubleToString(lvl.scoreFresh, 0),
               " Rj=", DoubleToString(lvl.scoreReject, 1),
               " Cf=", DoubleToString(lvl.scoreConfl, 0), ")",
               " | ", DoubleToString(lvl.priceLow, _Digits),
               "-", DoubleToString(lvl.priceHigh, _Digits),
               " | ", freshStr,
               " | Consts=", lvl.constituentCount,
               flagStr);
      }
   }

   //--- Print per-pool details
   if(poolCount > 0)
   {
      Print("--- Liquidity Pool Details ---");
      for(int i = 0; i < poolCount; i++)
      {
         LiquidityPool pool;
         if(!gSnrEngine.GetPool(i, pool)) continue;

         string typeStr  = pool.isBuyLiquidity ? "BUY_STOP" : "SELL_STOP";
         string sweptStr = pool.isSwept ?
            ("SWEPT @ " + TimeToString(pool.sweptTime, TIME_DATE | TIME_MINUTES)) : "ACTIVE";

         Print("  Pool #", pool.id,
               " | ", typeStr,
               " | ", DoubleToString(pool.priceLow, _Digits),
               "-", DoubleToString(pool.priceHigh, _Digits),
               " | Str=", DoubleToString(pool.liquidityStrength, 1),
               " | ", sweptStr);
      }
   }

   //--- Cluster statistics
   if(levelCount > 0)
   {
      Print("--- Cluster Statistics ---");

      double minWidth = 99999.0, maxWidth = 0.0, sumWidth = 0.0;
      int minConst = 999, maxConst = 0;
      double sumScore = 0.0;
      int freshLevels = 0, neutralLevels = 0;

      for(int i = 0; i < levelCount; i++)
      {
         SNRLevel lvl;
         if(!gSnrEngine.GetLevel(i, lvl)) continue;

         double width = lvl.priceHigh - lvl.priceLow;
         if(width < minWidth) minWidth = width;
         if(width > maxWidth) maxWidth = width;
         sumWidth += width;

         if(lvl.constituentCount < minConst) minConst = lvl.constituentCount;
         if(lvl.constituentCount > maxConst) maxConst = lvl.constituentCount;

         sumScore += lvl.scoreTotal;
         if(lvl.isFresh) freshLevels++;
         if(lvl.isNeutralNode) neutralLevels++;
      }

      double avgWidth = sumWidth / levelCount;
      double avgScore = sumScore / levelCount;

      Print("  Cluster Width:  min=", DoubleToString(minWidth, 3),
            "  max=", DoubleToString(maxWidth, 3),
            "  avg=", DoubleToString(avgWidth, 3));
      Print("  Constituents:   min=", minConst, "  max=", maxConst);
      Print("  Avg Score:      ", DoubleToString(avgScore, 1));
      Print("  Fresh Levels:   ", freshLevels, " / ", levelCount,
            " (", DoubleToString(100.0 * freshLevels / levelCount, 1), "%)");
      Print("  Neutral Nodes:  ", neutralLevels);
   }

   //--- Print SNR Priority Contract details
   SnrPriorityContract contract;
   gPriorityEngine.GetContract(contract);

   Print("====================================================");
   Print("     SNR PRIORITY CONTRACT SUMMARY");
   Print("====================================================");
   Print("  Current Price:   ", DoubleToString(contract.currentPrice, _Digits));
   Print("  ATR (14):        ", DoubleToString(contract.atr, 4));
   Print("  ---");
   Print("  Prioritized Structural Support (Count=", contract.supportCount, "):");
   for(int i = 0; i < contract.supportCount; i++)
   {
      double dist = MathAbs(contract.supportLevels[i].priceMid - contract.currentPrice);
      double distATR = (contract.atr > 0) ? dist / contract.atr : 0;
      Print("    #", i, " | ID=", contract.supportLevels[i].id,
            " | Mid=", DoubleToString(contract.supportLevels[i].priceMid, _Digits),
            " | Score=", DoubleToString(contract.supportLevels[i].scoreTotal, 1),
            " | Dist=", DoubleToString(dist, _Digits),
            " (", DoubleToString(distATR, 2), " ATR)");
   }
   Print("  Prioritized Structural Resistance (Count=", contract.resistanceCount, "):");
   for(int i = 0; i < contract.resistanceCount; i++)
   {
      double dist = MathAbs(contract.resistanceLevels[i].priceMid - contract.currentPrice);
      double distATR = (contract.atr > 0) ? dist / contract.atr : 0;
      Print("    #", i, " | ID=", contract.resistanceLevels[i].id,
            " | Mid=", DoubleToString(contract.resistanceLevels[i].priceMid, _Digits),
            " | Score=", DoubleToString(contract.resistanceLevels[i].scoreTotal, 1),
            " | Dist=", DoubleToString(dist, _Digits),
            " (", DoubleToString(distATR, 2), " ATR)");
   }
   Print("  ---");
   Print("  Prioritized Tradable Support (Count=", contract.tradableSupportCount, "):");
   for(int i = 0; i < contract.tradableSupportCount; i++)
   {
      double dist = MathAbs(contract.tradableSupport[i].priceMid - contract.currentPrice);
      double distATR = (contract.atr > 0) ? dist / contract.atr : 0;
      Print("    #", i, " | ID=", contract.tradableSupport[i].id,
            " | Mid=", DoubleToString(contract.tradableSupport[i].priceMid, _Digits),
            " | Score=", DoubleToString(contract.tradableSupport[i].scoreTotal, 1),
            " | Dist=", DoubleToString(dist, _Digits),
            " (", DoubleToString(distATR, 2), " ATR)");
   }
   Print("  Prioritized Tradable Resistance (Count=", contract.tradableResistanceCount, "):");
   for(int i = 0; i < contract.tradableResistanceCount; i++)
   {
      double dist = MathAbs(contract.tradableResistance[i].priceMid - contract.currentPrice);
      double distATR = (contract.atr > 0) ? dist / contract.atr : 0;
      Print("    #", i, " | ID=", contract.tradableResistance[i].id,
            " | Mid=", DoubleToString(contract.tradableResistance[i].priceMid, _Digits),
            " | Score=", DoubleToString(contract.tradableResistance[i].scoreTotal, 1),
            " | Dist=", DoubleToString(dist, _Digits),
            " (", DoubleToString(distATR, 2), " ATR)");
   }
   Print("  ---");
   Print("  Liquidity Targets:");
   if(contract.hasBSL)
      Print("    BSL: Pool #", contract.nearestBSL.id,
            " | Range=", DoubleToString(contract.nearestBSL.priceLow, _Digits),
            "-", DoubleToString(contract.nearestBSL.priceHigh, _Digits),
            " | Strength=", DoubleToString(contract.nearestBSL.liquidityStrength, 1));
   else
      Print("    BSL: None");

   if(contract.hasSSL)
      Print("    SSL: Pool #", contract.nearestSSL.id,
            " | Range=", DoubleToString(contract.nearestSSL.priceLow, _Digits),
            "-", DoubleToString(contract.nearestSSL.priceHigh, _Digits),
            " | Strength=", DoubleToString(contract.nearestSSL.liquidityStrength, 1));
   else
      Print("    SSL: None");
   Print("  ---");
   Print("  Neutral Nodes (Count=", contract.neutralCount, "):");
   for(int i = 0; i < contract.neutralCount; i++)
   {
      double dist = MathAbs(contract.neutralNodes[i].priceMid - contract.currentPrice);
      Print("    #", i, " | ID=", contract.neutralNodes[i].id,
            " | Mid=", DoubleToString(contract.neutralNodes[i].priceMid, _Digits),
            " | Range=", DoubleToString(contract.neutralNodes[i].priceLow, _Digits),
            "-", DoubleToString(contract.neutralNodes[i].priceHigh, _Digits),
            " | Dist=", DoubleToString(dist, _Digits));
   }
   Print("====================================================");
}

//=========================================================
// CHART OBJECT HELPER FUNCTIONS
//=========================================================

//+------------------------------------------------------------------+
//| CreateRectLabel: Draw panel background                           |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int posX, int posY, int sizeX, int sizeY,
                     color bgColor, int transparency)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, posX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, posY);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, sizeX);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, sizeY);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateChartLabel: Draw text anchored to chart corner              |
//+------------------------------------------------------------------+
void CreateChartLabel(string name, int posX, int posY, string text,
                      color clr, int fontSize)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, posX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, posY);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
