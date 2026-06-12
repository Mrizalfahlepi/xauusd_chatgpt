//+------------------------------------------------------------------+
//|                                           TestStructure.mq5      |
//|                   Visual Test for StructureEngine.mqh v2.0       |
//|                   Version 2.0                                     |
//+------------------------------------------------------------------+
//| PURPOSE:                                                          |
//|   Visualize StructureEngine v2.0 outputs on the H4 chart.        |
//|                                                                   |
//|   Displays MAJOR SWINGS ONLY:                                     |
//|   - Major Swing Highs (arrows + labels: HH / LH + score)         |
//|   - Major Swing Lows  (arrows + labels: HL / LL + score)          |
//|   - BOS lines (horizontal dashed lines)                           |
//|   - MSS markers (large arrows with text)                          |
//|   - Info panel (trend, major/minor counts, scores)                |
//|                                                                   |
//| USAGE:                                                            |
//|   Attach as Expert Advisor on XAUUSD H4 chart.                   |
//|   Run in visual backtest mode for best results.                   |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "2.10"
#property strict

//--- Include the Structure Engine
#include "StructureEngine.mqh"

//=========================================================
// INPUT PARAMETERS
//=========================================================
input int    InpTestMaxBars       = 300;     // Test: Max bars to analyze
input bool   InpShowSwings        = true;    // Show Major swing arrows
input bool   InpShowLabels        = true;    // Show HH/HL/LH/LL labels
input bool   InpShowScores        = true;    // Show strength scores
input bool   InpShowInvalidated   = true;    // Show invalidated swings (gray)
input bool   InpShowBOS           = true;    // Show BOS lines
input bool   InpShowMSS           = true;    // Show MSS markers
input bool   InpShowPanel         = true;    // Show info panel
input color  InpColorHH           = clrDodgerBlue;    // Color: HH
input color  InpColorHL           = clrDeepSkyBlue;   // Color: HL
input color  InpColorLH           = clrOrangeRed;     // Color: LH
input color  InpColorLL           = clrCrimson;        // Color: LL
input color  InpColorMajorHigh    = clrRoyalBlue;     // Color: Major Swing High
input color  InpColorMajorLow     = clrTomato;        // Color: Major Swing Low
input color  InpColorBOSBull      = clrLime;          // Color: Bullish BOS
input color  InpColorBOSBear      = clrRed;           // Color: Bearish BOS
input color  InpColorMSSBull      = clrGold;          // Color: Bullish MSS
input color  InpColorMSSBear      = clrMagenta;       // Color: Bearish MSS

//=========================================================
// GLOBALS
//=========================================================
CStructureEngine structureEngine;
string           gObjectPrefix = "TST_";
bool             gFirstRun     = true;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestStructure v2.0 Starting ===");

   if(!structureEngine.Init())
   {
      Print("ERROR: Failed to initialize StructureEngine");
      return INIT_FAILED;
   }

   gFirstRun = true;

   Print("TestStructure v2.0 initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CleanupObjects();
   structureEngine.Deinit();
   Print("=== TestStructure v2.0 Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!gFirstRun && !structureEngine.IsNewBar())
      return;

   gFirstRun = false;

   //--- Clean previous visualization
   CleanupObjects();

   //--- Run full analysis
   StructureResult result = structureEngine.Analyze(InpTestMaxBars);

   if(!result.isValid)
   {
      Print("WARNING: Structure analysis returned invalid result");
      return;
   }

   //--- Draw MAJOR swings only
   if(InpShowSwings || InpShowLabels || InpShowScores)
      DrawMajorSwingPoints();

   if(InpShowBOS)
      DrawBOSEvents();

   if(InpShowMSS)
      DrawMSSEvents();

   if(InpShowPanel)
      DrawInfoPanel(result);

   //--- Print summary
   PrintSummary(result);

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

//+------------------------------------------------------------------+
//| DrawMajorSwingPoints: Draw ONLY Major swing arrows & labels      |
//|   Shows HH/HL/LH/LL label + strength score                      |
//+------------------------------------------------------------------+
void DrawMajorSwingPoints()
{
   //--- Draw Major Swing Highs
   int majorHighCount = structureEngine.GetMajorHighCount();
   for(int hIdx = 0; hIdx < majorHighCount; hIdx++)
   {
      SwingPoint swing;
      if(!structureEngine.GetMajorHigh(hIdx, swing))
         continue;

      string arrowName = gObjectPrefix + "MH_" + IntegerToString(hIdx);
      string labelName = gObjectPrefix + "MHL_" + IntegerToString(hIdx);
      string scoreName = gObjectPrefix + "MHS_" + IntegerToString(hIdx);

      //--- Determine color and label text
      color  pointColor = InpColorMajorHigh;
      string labelText  = "SH";

      if(swing.label == LABEL_HH)
      {
         pointColor = InpColorHH;
         labelText  = "HH";
      }
      else if(swing.label == LABEL_LH)
      {
         pointColor = InpColorLH;
         labelText  = "LH";
      }

      //--- Invalidated swing: dim color + 'x' prefix
      if(swing.isInvalidated)
      {
         if(!InpShowInvalidated) continue;
         pointColor = clrGray;
         labelText  = "x" + labelText;
      }

      //--- Draw arrow above the bar
      if(InpShowSwings)
      {
         CreateArrow(arrowName, swing.barTime, swing.price, 218,
                     pointColor, ANCHOR_BOTTOM, 10);
      }

      //--- Draw structure label
      if(InpShowLabels)
      {
         CreateTextLabel(labelName, swing.barTime, swing.price, labelText,
                         pointColor, ANCHOR_LOWER, 12);
      }

      //--- Draw strength score below label
      if(InpShowScores && swing.strengthScore > 0.0)
      {
         string scoreText = "(" + IntegerToString((int)MathRound(swing.strengthScore)) + ")";
         //--- Offset the score slightly by adding to an offset time
         CreateScoreLabel(scoreName, swing.barTime, swing.price, scoreText,
                          pointColor, true);
      }
   }

   //--- Draw Major Swing Lows
   int majorLowCount = structureEngine.GetMajorLowCount();
   for(int lIdx = 0; lIdx < majorLowCount; lIdx++)
   {
      SwingPoint swing;
      if(!structureEngine.GetMajorLow(lIdx, swing))
         continue;

      string arrowName = gObjectPrefix + "ML_" + IntegerToString(lIdx);
      string labelName = gObjectPrefix + "MLL_" + IntegerToString(lIdx);
      string scoreName = gObjectPrefix + "MLS_" + IntegerToString(lIdx);

      color  pointColor = InpColorMajorLow;
      string labelText  = "SL";

      if(swing.label == LABEL_HL)
      {
         pointColor = InpColorHL;
         labelText  = "HL";
      }
      else if(swing.label == LABEL_LL)
      {
         pointColor = InpColorLL;
         labelText  = "LL";
      }

      //--- Invalidated swing: dim color + 'x' prefix
      if(swing.isInvalidated)
      {
         if(!InpShowInvalidated) continue;
         pointColor = clrGray;
         labelText  = "x" + labelText;
      }

      //--- Draw arrow below the bar
      if(InpShowSwings)
      {
         CreateArrow(arrowName, swing.barTime, swing.price, 217,
                     pointColor, ANCHOR_TOP, 10);
      }

      //--- Draw structure label
      if(InpShowLabels)
      {
         CreateTextLabel(labelName, swing.barTime, swing.price, labelText,
                         pointColor, ANCHOR_UPPER, 12);
      }

      //--- Draw strength score above label
      if(InpShowScores && swing.strengthScore > 0.0)
      {
         string scoreText = "(" + IntegerToString((int)MathRound(swing.strengthScore)) + ")";
         CreateScoreLabel(scoreName, swing.barTime, swing.price, scoreText,
                          pointColor, false);
      }
   }
}

//+------------------------------------------------------------------+
//| DrawBOSEvents: Draw horizontal lines for BOS events              |
//+------------------------------------------------------------------+
void DrawBOSEvents()
{
   int bosCount = structureEngine.GetBOSCount();

   for(int bIdx = 0; bIdx < bosCount; bIdx++)
   {
      BOSEvent bos;
      if(!structureEngine.GetBOSEvent(bIdx, bos))
         continue;

      string lineName   = gObjectPrefix + "BOS_" + IntegerToString(bIdx);
      string labelName  = gObjectPrefix + "BOSL_" + IntegerToString(bIdx);

      color bosColor = (bos.direction == BOS_BULLISH) ? InpColorBOSBull : InpColorBOSBear;
      string bosText = (bos.direction == BOS_BULLISH) ? "BOS ^" : "BOS v";

      datetime startTime = bos.barTime;

      int endBarShift = bos.barIndex - 5;
      if(endBarShift < 0) endBarShift = 0;

      datetime endTime = iTime(_Symbol, PERIOD_H4, endBarShift);
      if(endTime == 0) endTime = startTime;

      CreateTrendLine(lineName, startTime, bos.brokenLevel,
                      endTime, bos.brokenLevel, bosColor, STYLE_DASH, 2);

      CreateTextLabel(labelName, bos.barTime, bos.breakPrice, bosText,
                      bosColor, (bos.direction == BOS_BULLISH) ? ANCHOR_LOWER : ANCHOR_UPPER, 10);
   }
}

//+------------------------------------------------------------------+
//| DrawMSSEvents: Draw large markers for MSS events                 |
//+------------------------------------------------------------------+
void DrawMSSEvents()
{
   int mssCount = structureEngine.GetMSSCount();

   for(int mIdx = 0; mIdx < mssCount; mIdx++)
   {
      MSSEvent mss;
      if(!structureEngine.GetMSSEvent(mIdx, mss))
         continue;

      string arrowName = gObjectPrefix + "MSS_" + IntegerToString(mIdx);
      string labelName = gObjectPrefix + "MSSL_" + IntegerToString(mIdx);

      color mssColor = (mss.direction == MSS_BULLISH) ? InpColorMSSBull : InpColorMSSBear;
      string mssText = (mss.direction == MSS_BULLISH) ? "MSS ^" : "MSS v";

      int arrowCode = (mss.direction == MSS_BULLISH) ? 233 : 234;

      CreateArrow(arrowName, mss.barTime, mss.breakPrice, arrowCode,
                  mssColor, (mss.direction == MSS_BULLISH) ? ANCHOR_BOTTOM : ANCHOR_TOP, 16);

      CreateTextLabel(labelName, mss.barTime, mss.brokenLevel, mssText,
                      mssColor, ANCHOR_LEFT, 14);
   }
}

//+------------------------------------------------------------------+
//| DrawInfoPanel: On-chart information panel                        |
//+------------------------------------------------------------------+
void DrawInfoPanel(StructureResult &result)
{
   //--- Panel background
   CreateRectLabel(gObjectPrefix + "PANEL_BG", 10, 30, 300, 350, clrBlack, 200);

   //--- Title
   CreateChartLabel(gObjectPrefix + "PANEL_TITLE", 20, 40,
                    "=== STRUCTURE ENGINE v2.1 ===", clrGold, 11);

   //--- Trend State
   string trendText = "Trend: " + structureEngine.TrendToString(result.currentTrend);
   color trendColor = clrYellow;

   if(result.currentTrend == TREND_BULLISH)
      trendColor = clrLime;
   else if(result.currentTrend == TREND_BEARISH)
      trendColor = clrRed;

   CreateChartLabel(gObjectPrefix + "PANEL_TREND", 20, 62, trendText, trendColor, 14);

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PANEL_SEP1", 20, 84,
                    "-----------------------------", clrDimGray, 9);

   //--- Total swing counts
   CreateChartLabel(gObjectPrefix + "PANEL_TOTAL", 20, 97,
                    "Total Swings: " + IntegerToString(result.swingHighCount + result.swingLowCount),
                    clrDarkGray, 9);

   //--- Major swing counts
   CreateChartLabel(gObjectPrefix + "PANEL_MAJOR", 20, 115,
                    "MAJOR  H:" + IntegerToString(result.majorHighCount)
                    + "  L:" + IntegerToString(result.majorLowCount),
                    clrWhite, 11);

   //--- Minor swing counts
   CreateChartLabel(gObjectPrefix + "PANEL_MINOR", 20, 135,
                    "Minor  H:" + IntegerToString(result.minorHighCount)
                    + "  L:" + IntegerToString(result.minorLowCount),
                    clrGray, 10);

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PANEL_SEP2", 20, 152,
                    "-----------------------------", clrDimGray, 9);

   //--- HH/HL
   CreateChartLabel(gObjectPrefix + "PANEL_HHHL", 20, 165,
                    "HH: " + IntegerToString(result.hhCount)
                    + "   HL: " + IntegerToString(result.hlCount),
                    clrDeepSkyBlue, 11);

   //--- LH/LL
   CreateChartLabel(gObjectPrefix + "PANEL_LHLL", 20, 185,
                    "LH: " + IntegerToString(result.lhCount)
                    + "   LL: " + IntegerToString(result.llCount),
                    clrOrangeRed, 11);

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PANEL_SEP3", 20, 202,
                    "-----------------------------", clrDimGray, 9);

   //--- BOS
   CreateChartLabel(gObjectPrefix + "PANEL_BOS", 20, 215,
                    "BOS Events: " + IntegerToString(result.bosCount),
                    clrLime, 10);

   //--- MSS
   CreateChartLabel(gObjectPrefix + "PANEL_MSS", 20, 235,
                    "MSS Events: " + IntegerToString(result.mssCount),
                    clrGold, 10);

   //--- Invalidated
   CreateChartLabel(gObjectPrefix + "PANEL_INVALID", 20, 255,
                    "Invalid  H:" + IntegerToString(result.invalidHighCount)
                    + "  L:" + IntegerToString(result.invalidLowCount),
                    clrGray, 10);

   //--- Separator
   CreateChartLabel(gObjectPrefix + "PANEL_SEP4", 20, 275,
                    "-----------------------------", clrDimGray, 9);

   //--- Top scoring swings
   string topHighScore = "---";
   string topLowScore  = "---";

   int majorHighCnt = structureEngine.GetMajorHighCount();
   double bestHighScore = 0.0;
   for(int thIdx = 0; thIdx < majorHighCnt; thIdx++)
   {
      SwingPoint tempSwing;
      if(structureEngine.GetMajorHigh(thIdx, tempSwing))
      {
         if(tempSwing.strengthScore > bestHighScore)
         {
            bestHighScore = tempSwing.strengthScore;
            topHighScore = IntegerToString((int)MathRound(bestHighScore));
         }
      }
   }

   int majorLowCnt = structureEngine.GetMajorLowCount();
   double bestLowScore = 0.0;
   for(int tlIdx = 0; tlIdx < majorLowCnt; tlIdx++)
   {
      SwingPoint tempSwing;
      if(structureEngine.GetMajorLow(tlIdx, tempSwing))
      {
         if(tempSwing.strengthScore > bestLowScore)
         {
            bestLowScore = tempSwing.strengthScore;
            topLowScore = IntegerToString((int)MathRound(bestLowScore));
         }
      }
   }

   CreateChartLabel(gObjectPrefix + "PANEL_SCORE", 20, 290,
                    "Best Score  H:" + topHighScore + "  L:" + topLowScore,
                    clrAqua, 10);

   //--- Filter info
   CreateChartLabel(gObjectPrefix + "PANEL_FILTER", 20, 310,
                    "Filter: >= 0.5 ATR | Score: 0-100",
                    clrDarkGray, 8);

   //--- Bars & Timestamp
   CreateChartLabel(gObjectPrefix + "PANEL_INFO", 20, 328,
                    "Bars:" + IntegerToString(InpTestMaxBars)
                    + " | TF:H4 | "
                    + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES),
                    clrDarkGray, 8);
}

//+------------------------------------------------------------------+
//| PrintSummary: Print analysis summary to Experts log              |
//+------------------------------------------------------------------+
void PrintSummary(StructureResult &result)
{
   Print("====================================================");
   Print("     STRUCTURE ENGINE v2.1 SUMMARY");
   Print("====================================================");
   Print("  Trend:        ", structureEngine.TrendToString(result.currentTrend));
   Print("  ---");
   Print("  Total Highs:  ", result.swingHighCount,
         "  (Major:", result.majorHighCount, " Minor:", result.minorHighCount, ")");
   Print("  Total Lows:   ", result.swingLowCount,
         "  (Major:", result.majorLowCount, " Minor:", result.minorLowCount, ")");
   Print("  Invalid:      H:", result.invalidHighCount, "  L:", result.invalidLowCount);
   Print("  ---");
   Print("  HH:           ", result.hhCount);
   Print("  HL:           ", result.hlCount);
   Print("  LH:           ", result.lhCount);
   Print("  LL:           ", result.llCount);
   Print("  ---");
   Print("  BOS:          ", result.bosCount);
   Print("  MSS:          ", result.mssCount);
   Print("====================================================");

   //--- Print Major Swing details with scores
   int majorHighCount = structureEngine.GetMajorHighCount();
   if(majorHighCount > 0)
   {
      Print("--- Major Swing Highs ---");
      for(int hIdx = 0; hIdx < majorHighCount; hIdx++)
      {
         SwingPoint swing;
         if(structureEngine.GetMajorHigh(hIdx, swing))
         {
            Print("  #", hIdx,
                  " | ", structureEngine.LabelToString(swing.label),
                  " | Price=", DoubleToString(swing.price, (int)_Digits),
                  " | Score=", IntegerToString((int)MathRound(swing.strengthScore)),
                  " | React=", swing.reactionCount,
                  " | Age=", swing.barAge,
                  " | Time=", TimeToString(swing.barTime));
         }
      }
   }

   int majorLowCount = structureEngine.GetMajorLowCount();
   if(majorLowCount > 0)
   {
      Print("--- Major Swing Lows ---");
      for(int lIdx = 0; lIdx < majorLowCount; lIdx++)
      {
         SwingPoint swing;
         if(structureEngine.GetMajorLow(lIdx, swing))
         {
            Print("  #", lIdx,
                  " | ", structureEngine.LabelToString(swing.label),
                  " | Price=", DoubleToString(swing.price, (int)_Digits),
                  " | Score=", IntegerToString((int)MathRound(swing.strengthScore)),
                  " | React=", swing.reactionCount,
                  " | Age=", swing.barAge,
                  " | Time=", TimeToString(swing.barTime));
         }
      }
   }

   //--- Print BOS details
   int bosCount = structureEngine.GetBOSCount();
   if(bosCount > 0)
   {
      Print("--- BOS Details ---");
      for(int bIdx = 0; bIdx < bosCount; bIdx++)
      {
         BOSEvent bos;
         if(structureEngine.GetBOSEvent(bIdx, bos))
         {
            Print("  BOS #", bIdx,
                  " | Dir=", structureEngine.BOSDirectionToString(bos.direction),
                  " | Close=", DoubleToString(bos.breakPrice, (int)_Digits),
                  " | Level=", DoubleToString(bos.brokenLevel, (int)_Digits),
                  " | Dist=", DoubleToString(bos.breakDistance, (int)_Digits),
                  " | Time=", TimeToString(bos.barTime));
         }
      }
   }

   //--- Print MSS details
   int mssCount = structureEngine.GetMSSCount();
   if(mssCount > 0)
   {
      Print("--- MSS Details ---");
      for(int mIdx = 0; mIdx < mssCount; mIdx++)
      {
         MSSEvent mss;
         if(structureEngine.GetMSSEvent(mIdx, mss))
         {
            Print("  MSS #", mIdx,
                  " | Dir=", structureEngine.MSSDirectionToString(mss.direction),
                  " | Prev=", structureEngine.TrendToString(mss.previousTrend),
                  " | Price=", DoubleToString(mss.breakPrice, (int)_Digits),
                  " | Time=", TimeToString(mss.barTime));
         }
      }
   }
}

//=========================================================
// CHART OBJECT HELPER FUNCTIONS
//=========================================================

//+------------------------------------------------------------------+
//| CreateArrow: Draw an arrow on the chart                          |
//+------------------------------------------------------------------+
void CreateArrow(string name, datetime time, double price, int arrowCode,
                 color clr, ENUM_ARROW_ANCHOR anchor, int size)
{
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, size > 10 ? 3 : 2);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateTextLabel: Draw text anchored to price/time                |
//+------------------------------------------------------------------+
void CreateTextLabel(string name, datetime time, double price, string text,
                     color clr, ENUM_ANCHOR_POINT anchor, int fontSize)
{
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateScoreLabel: Draw strength score near a swing point         |
//|   isHigh=true → above the swing, isHigh=false → below           |
//+------------------------------------------------------------------+
void CreateScoreLabel(string name, datetime time, double price, string text,
                      color clr, bool isHigh)
{
   //--- Offset the score slightly from the main label
   double atrOffset = 0.0;
   int atrHandle = iATR(_Symbol, PERIOD_H4, 14);
   if(atrHandle != INVALID_HANDLE)
   {
      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuf) > 0)
         atrOffset = atrBuf[0] * 0.15;
      IndicatorRelease(atrHandle);
   }

   double offsetPrice = isHigh ? (price + atrOffset) : (price - atrOffset);
   ENUM_ANCHOR_POINT anchor = isHigh ? ANCHOR_LOWER : ANCHOR_UPPER;

   ObjectCreate(0, name, OBJ_TEXT, 0, time, offsetPrice);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateTrendLine: Draw a trend line between two points            |
//+------------------------------------------------------------------+
void CreateTrendLine(string name, datetime time1, double price1,
                     datetime time2, double price2,
                     color clr, ENUM_LINE_STYLE style, int width)
{
   ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateRectLabel: Draw a rectangle label (panel background)       |
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
//| CreateChartLabel: Draw a label anchored to chart corner          |
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
