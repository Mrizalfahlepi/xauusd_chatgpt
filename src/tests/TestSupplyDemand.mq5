//+------------------------------------------------------------------+
//|                                           TestSupplyDemand.mq5   |
//|                   Visual Test for SupplyDemandEngine.mqh v1.0    |
//|                   Version 1.0 - Sprint 2.0                       |
//+------------------------------------------------------------------+
//| PURPOSE:                                                         |
//|   Visualize Supply & Demand zones on the H4 chart.               |
//|   Displays:                                                      |
//|   - Demand Zones (green filled rectangles)                       |
//|   - Supply Zones (red filled rectangles)                         |
//|   - Invalidated zones (gray outline rectangles extending to break)|
//|   - Info panel (active counts, nearest zone scores)              |
//|                                                                  |
//| USAGE:                                                            |
//|   Attach as Expert Advisor on XAUUSD M30/H4 chart in Strategy     |
//|   Tester visual mode.                                            |
//+------------------------------------------------------------------+
#property copyright "XAUUSD EA"
#property link      ""
#property version   "1.00"
#property strict

//--- Include Engines
#include "../engines/StructureEngine.mqh"
#include "../engines/SupplyDemandEngine.mqh"

//=========================================================
// INPUT PARAMETERS
//=========================================================
input int    InpTestMaxBars         = 300;            // Test: Max bars to analyze
input double InpMinImpulseATR       = 2.0;            // Min Impulse Range (ATR multiplier)
input double InpMinBodyDominance     = 0.60;           // Min Body Dominance (ratio 0-1)
input bool   InpShowActiveZones     = true;           // Show active S/D zones
input bool   InpShowInvalidated     = true;           // Show invalidated S/D zones (gray)
input color  InpColorActiveDemand   = clrDarkSeaGreen;// Color: Active Demand
input color  InpColorActiveSupply   = clrRosyBrown;   // Color: Active Supply
input color  InpColorInvalidDemand  = clrLightGray;   // Color: Invalid Demand
input color  InpColorInvalidSupply  = clrLightGray;   // Color: Invalid Supply
input bool   InpShowPanel           = true;           // Show info panel on chart

//=========================================================
// GLOBALS
//=========================================================
CStructureEngine    structureEngine;
CSupplyDemandEngine supplyDemandEngine;
string              gObjectPrefix = "SDE_";
bool                gFirstRun     = true;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TestSupplyDemand v1.0 Starting ===");

   // Initialize Structure Engine
   if(!structureEngine.Init())
   {
      Print("ERROR: Failed to initialize StructureEngine");
      return INIT_FAILED;
   }

   // Initialize Supply & Demand Engine
   if(!supplyDemandEngine.Init(&structureEngine))
   {
      Print("ERROR: Failed to initialize SupplyDemandEngine");
      return INIT_FAILED;
   }

   // Set custom parameters (via reflection or direct access if supported)
   // For safety, we use the default settings that align with inputs
   gFirstRun = true;
   Print("TestSupplyDemand v1.0 initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CleanupObjects();
   supplyDemandEngine.Deinit();
   structureEngine.Deinit();
   Print("=== TestSupplyDemand v1.0 Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Execute only on H4 bar updates to save processing power
   if(!gFirstRun && !structureEngine.IsNewBar())
      return;

   gFirstRun = false;

   //--- Clean previous visualization objects
   CleanupObjects();

   //--- Run upstream Structure Engine
   StructureResult structRes = structureEngine.Analyze(InpTestMaxBars);
   if(!structRes.isValid)
   {
      Print("WARNING: StructureEngine returned invalid result");
      return;
   }

   //--- Run Supply & Demand Engine
   int zoneCount = supplyDemandEngine.Analyze(InpTestMaxBars);

   //--- Draw detected zones
   DrawZones();

   //--- Draw information panel
   if(InpShowPanel)
      DrawInfoPanel();

   //--- Print summary to logs
   PrintSummary();
}

//+------------------------------------------------------------------+
//| DrawZones: Render supply and demand zones as chart rectangles    |
//+------------------------------------------------------------------+
void DrawZones()
{
   int totalZones = supplyDemandEngine.GetZoneCount();
   datetime currentBarTime = iTime(_Symbol, PERIOD_H4, 0);
   if(currentBarTime == 0) return;

   for(int i = 0; i < totalZones; i++)
   {
      SupplyDemandZone zone;
      if(!supplyDemandEngine.GetZone(i, zone))
         continue;

      // Filter based on user inputs
      if(zone.isInvalidated && !InpShowInvalidated)
         continue;
      if(!zone.isInvalidated && !InpShowActiveZones)
         continue;

      string rectName = gObjectPrefix + "RECT_" + IntegerToString(zone.id);
      
      // Determine colors and fill style
      color zoneColor = clrRed;
      bool fillRectangle = false;
      int lineWidth = 1;
      ENUM_LINE_STYLE lineStyle = STYLE_SOLID;

      if(zone.zoneType == ZONE_DEMAND)
      {
         if(!zone.isInvalidated)
         {
            zoneColor = InpColorActiveDemand;
            fillRectangle = true;
         }
         else
         {
            zoneColor = InpColorInvalidDemand;
            lineStyle = STYLE_DOT;
         }
      }
      else if(zone.zoneType == ZONE_SUPPLY)
      {
         if(!zone.isInvalidated)
         {
            zoneColor = InpColorActiveSupply;
            fillRectangle = true;
         }
         else
         {
            zoneColor = InpColorInvalidSupply;
            lineStyle = STYLE_DOT;
         }
      }

      // Determine horizontal boundary (extend active zones to current bar)
      datetime endTime = zone.isInvalidated ? zone.invalidatedTime : currentBarTime;

      // Draw the rectangle
      if(ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, zone.baseStartTime, zone.zoneHigh, endTime, zone.zoneLow))
      {
         ObjectSetInteger(0, rectName, OBJPROP_COLOR, zoneColor);
         ObjectSetInteger(0, rectName, OBJPROP_FILL, fillRectangle);
         ObjectSetInteger(0, rectName, OBJPROP_BACK, true); // Behind bars
         ObjectSetInteger(0, rectName, OBJPROP_STYLE, lineStyle);
         ObjectSetInteger(0, rectName, OBJPROP_WIDTH, lineWidth);
         ObjectSetString(0, rectName, OBJPROP_TOOLTIP, 
                        "Zone #" + IntegerToString(zone.id) + 
                        " | Score: " + DoubleToString(zone.scoreTotal, 1) +
                        " | Base Candles: " + IntegerToString(zone.baseCandleCount) +
                        " | Reacts: " + IntegerToString(zone.reactionCount));
      }
   }
}

//+------------------------------------------------------------------+
//| CleanupObjects: Delete visual objects drawn by this EA            |
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
//| DrawInfoPanel: Draw dashboard displaying stats on the chart     |
//+------------------------------------------------------------------+
void DrawInfoPanel()
{
   int xStart = 20;
   int yStart = 300;
   int ySpacing = 20;

   //--- Panel background
   string panelBg = gObjectPrefix + "PANEL_BG";
   if(ObjectCreate(0, panelBg, OBJ_RECTANGLE_LABEL, 0, 0, 0, 0, 0))
   {
      ObjectSetInteger(0, panelBg, OBJPROP_XDISTANCE, xStart - 10);
      ObjectSetInteger(0, panelBg, OBJPROP_YDISTANCE, yStart - 10);
      ObjectSetInteger(0, panelBg, OBJPROP_XSIZE, 300);
      ObjectSetInteger(0, panelBg, OBJPROP_YSIZE, 150);
      ObjectSetInteger(0, panelBg, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, panelBg, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
      ObjectSetInteger(0, panelBg, OBJPROP_COLOR, clrGray);
   }

   //--- Title Label
   CreateChartLabel(gObjectPrefix + "PANEL_TITLE", xStart, yStart, 
                    "=== SUPPLY & DEMAND ENGINE v1.0 ===", clrWhite, 10, true);

   //--- Stats
   int activeDemand = supplyDemandEngine.GetActiveZoneCount(ZONE_DEMAND);
   int activeSupply = supplyDemandEngine.GetActiveZoneCount(ZONE_SUPPLY);
   int totalZones   = supplyDemandEngine.GetZoneCount();

   CreateChartLabel(gObjectPrefix + "PANEL_DEMAND", xStart, yStart + ySpacing, 
                    "Active Demand Zones:  " + IntegerToString(activeDemand), clrLimeGreen, 9, false);

   CreateChartLabel(gObjectPrefix + "PANEL_SUPPLY", xStart, yStart + ySpacing * 2, 
                    "Active Supply Zones:  " + IntegerToString(activeSupply), clrLightCoral, 9, false);

   CreateChartLabel(gObjectPrefix + "PANEL_TOTAL", xStart, yStart + ySpacing * 3, 
                    "Total Zones Created:   " + IntegerToString(totalZones), clrDarkTurquoise, 9, false);

   //--- Nearest Zone Info
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   SupplyDemandZone nearDemand, nearSupply;
   
   string demandStr = "Nearest Demand: None";
   if(supplyDemandEngine.GetNearestActiveZone(currentBid, ZONE_DEMAND, nearDemand))
      demandStr = "Near Demand: Price=" + DoubleToString(nearDemand.zoneHigh, _Digits) + 
                  " | Score=" + DoubleToString(nearDemand.scoreTotal, 1);
                  
   string supplyStr = "Nearest Supply: None";
   if(supplyDemandEngine.GetNearestActiveZone(currentBid, ZONE_SUPPLY, nearSupply))
      supplyStr = "Near Supply: Price=" + DoubleToString(nearSupply.zoneLow, _Digits) + 
                  " | Score=" + DoubleToString(nearSupply.scoreTotal, 1);

   CreateChartLabel(gObjectPrefix + "PANEL_ND", xStart, yStart + ySpacing * 5, 
                    demandStr, clrWhite, 9, false);
                    
   CreateChartLabel(gObjectPrefix + "PANEL_NS", xStart, yStart + ySpacing * 6, 
                    supplyStr, clrWhite, 9, false);
}

//+------------------------------------------------------------------+
//| CreateChartLabel: Helper to create dashboard text label          |
//+------------------------------------------------------------------+
void CreateChartLabel(string name, int x, int y, string text, color col, int fontSize, bool isBold)
{
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, col);
      ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Trebuchet MS Bold" : "Trebuchet MS");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| PrintSummary: Output analysis results to strategy tester log    |
//+------------------------------------------------------------------+
void PrintSummary()
{
   int totalZones = supplyDemandEngine.GetZoneCount();
   int activeDemand = supplyDemandEngine.GetActiveZoneCount(ZONE_DEMAND);
   int activeSupply = supplyDemandEngine.GetActiveZoneCount(ZONE_SUPPLY);

   Print("SUPPLY & DEMAND ENGINE SUMMARY");
   Print("====================================================");
   Print("  Active Demand Zones:  ", activeDemand);
   Print("  Active Supply Zones:  ", activeSupply);
   Print("  Total Zones Created:   ", totalZones);
   Print("====================================================");

   // Print details for all active zones
   for(int i = 0; i < totalZones; i++)
   {
      SupplyDemandZone zone;
      if(supplyDemandEngine.GetZone(i, zone))
      {
         string typeStr = (zone.zoneType == ZONE_DEMAND) ? "DEMAND" : "SUPPLY";
         string statusStr = zone.isInvalidated ? "INVALIDATED (bar " + IntegerToString(zone.invalidatedBar) + ")" : "ACTIVE";
         
         Print("  Zone #", zone.id, 
               " | Type=", typeStr, 
               " | High=", DoubleToString(zone.zoneHigh, _Digits), 
               " | Low=", DoubleToString(zone.zoneLow, _Digits), 
               " | BaseCandles=", zone.baseCandleCount,
               " | Reacts=", zone.reactionCount, 
               " | TotalScore=", DoubleToString(zone.scoreTotal, 1), 
               " | Status=", statusStr, 
               " | Time=", TimeToString(zone.impulseTime));
      }
   }
   Print("====================================================");
}
