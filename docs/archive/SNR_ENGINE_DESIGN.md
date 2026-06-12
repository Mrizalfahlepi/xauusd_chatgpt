# SNR Engine v1.0 Architectural Design Document

**Author**: Quant Researcher & Market Structure Architect  
**Date**: June 12, 2026  
**Status**: DRAFT DESIGN  
**Target Module**: `SnrEngine.mqh` (Sprint 3.0)  
**Dependencies**: [StructureEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh) (v2.2), [SupplyDemandEngine.mqh](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh) (v1.1)

---

## 1. Introduction & Objectives

The **SNR Engine (Support, Resistance & Liquidity Module)** is Module 3 in the XAUUSD Institutional EA architecture. It sits between the `SupplyDemandEngine` (Module 2) and the `EntryEngine` (Module 4). 

The primary objective of the SNR Engine is to process raw structural swing points and order block zones into discrete, ranked, and high-probability **horizontal support/resistance bands** (SNR Levels) and **liquidity pools**, establishing an institutional map of the market.

```
+---------------------+     +--------------------------+     +------------------+
|   StructureEngine   | --> |    SupplyDemandEngine    | --> |    SnrEngine     |
|     (Version 2.2)   |     |      (Version 1.1)       |     |   (Version 1.0)  |
+---------------------+     +--------------------------+     +------------------+
```

---

## 2. Upstream Integration & Feeding Mechanism

The SNR Engine consumes data directly from both frozen upstream engines. It maintains pointers to the instantiated engines and queries them during its execution cycle:

### 2.1 Upstream Engine Reference Pointers
Inside the `CSnrEngine` class definition, pointers to the dependencies are initialized during EA startup:
```cpp
private:
   CStructureEngine*    m_structureEngine; // Upstream structure source
   CSupplyDemandEngine* m_sdEngine;        // Upstream supply/demand source
```

During initialization of the SNR Engine, references are passed and validated:
```cpp
bool CSnrEngine::Init(CStructureEngine* structEngine, CSupplyDemandEngine* sdEngine)
{
   if(structEngine == NULL || sdEngine == NULL)
   {
      Print("[CSnrEngine] ERROR: Upstream dependency pointer is NULL");
      return false;
   }
   m_structureEngine = structEngine;
   m_sdEngine = sdEngine;
   return true;
}
```

### 2.2 Data Ingestion Pipeline
During the H4 `CSnrEngine::Analyze()` cycle, the SNR Engine polls the upstream engines using their public interfaces:

1. **Structure Source (`CStructureEngine`)**:
   * Retrieves volatility (ATR): `m_structureEngine.GetATRValue(barIndex)`
   * Retrieves Major/Minor Swings and BOS details by querying structure arrays or public accessors.

2. **Supply & Demand Source (`CSupplyDemandEngine v1.1`)**:
   * The SNR Engine feeds on Supply & Demand zones by polling the total zone array size:
     `int totalZones = m_sdEngine.GetZoneCount();`
   * It loops sequentially through the zones using:
     `SupplyDemandZone zone; bool success = m_sdEngine.GetZone(i, zone);`
   * Active zones are filtered using `!zone.isInvalidated`, which provides the current trading levels.
   * Invalidated zones (`zone.isInvalidated == true`) are inspected for historical context, reaction touch coordinates, and retest performance to inform the scoring model.
   * Specific attributes read from each `SupplyDemandZone` include:
     * Price boundaries: `zone.zoneHigh` and `zone.zoneLow`
     * Retest reaction metrics: `zone.reactionCount` and `zone.invalidatedTime`
     * Time parameters for decay: `zone.impulseTime` and `zone.baseStartTime`

By utilizing these read-only accessors, the SNR Engine remains a decoupled synthesis layer that does not duplicate or modify the state of the upstream modules.

---

## 3. Support & Resistance Clustering Rules

Raw swing points and S/D zone boundaries often lie close to each other. To avoid visual clutter and duplicate trading levels, the SNR Engine groups overlapping or nearby levels using an **ATR-relative Clustering Algorithm**.

### 3.1 Clustering Algorithm Steps
1.  **Grading**: Extract all active S/D zones and the last $N$ swing points (e.g. 50 bars lookback).
2.  **Projection**: Project the price levels onto the vertical price axis:
    *   S/D Zone boundaries: `zoneHigh`, `zoneLow`
    *   Swing points: `swingPrice`
3.  **Proximity Check**: Group any two projected levels $A$ and $B$ into the same cluster if their distance is less than the clustering tolerance:
$$\text{Distance}(A, B) \le \text{InpSnrClusterToleranceATR} \times \text{ATR}$$
    *   *Default Parameter*: `InpSnrClusterToleranceATR = 0.25` (H4 ATR).
4.  **Cluster Boundary Definition**: The cluster price band is defined by the outermost elements:
$$\text{ClusterHigh} = \max(A_{\text{High}}, B_{\text{High}})$$
$$\text{ClusterLow} = \min(A_{\text{Low}}, B_{\text{Low}})$$
5.  **Cluster Constraint**: To prevent a cluster from expanding indefinitely in trending markets, a cluster is capped at a maximum width:
$$\text{ClusterWidth} \le \text{InpMaxClusterWidthATR} \times \text{ATR}$$
    *   *Default Parameter*: `InpMaxClusterWidthATR = 1.50`.
    *   If a level would cause the cluster to exceed this width, it is rejected from the cluster and starts a new one.

---

## 4. Zone Merge Rules

When the `SupplyDemandEngine` detects multiple S/D zones of the **same type** (e.g., two Supply zones) that overlap, they are merged under the following rules to maintain structural integrity:

1.  **Overlap Condition**: Two zones $Z_1$ and $Z_2$ are merged if their overlapping price height exceeds 50% of the height of the smaller zone:
$$\frac{\min(Z_{1\text{High}}, Z_{2\text{High}}) - \max(Z_{1\text{Low}}, Z_{2\text{Low}})}{\min(Z_{1\text{Height}}, Z_{2\text{Height}})} \ge 0.50$$
2.  **Merged Coordinates**:
$$\text{MergedHigh} = \max(Z_{1\text{High}}, Z_{2\text{High}})$$
$$\text{MergedLow} = \min(Z_{1\text{Low}}, Z_{2\text{Low}})$$
3.  **Merged Metadata**:
    *   **Creation Time**: Inherits the **older** creation time of the two zones to ensure conservative Age Score decay.
    *   **Reaction Count**: Sum of both zone reactions, capped at 3 (representing full depletion of orders).

---

## 5. Overlap & Conflict Handling

When different structural elements overlap, the SNR Engine resolves conflicts systematically:

### 5.1 Supply vs. Resistance & Demand vs. Support (Confluence)
*   **Behavior**: When a Supply zone overlaps a Major Swing High, or a Demand zone overlaps a Major Swing Low:
*   **Resolution**: They are treated as a single high-confluence SNR Level. The S/D boundaries define the level's high/low coordinates. A **Confluence Score of 100** ($S_{\text{Confl}} = 100$) is assigned, contributing a full 10.0 points to the total score under the Confluence Weight ($W_{\text{Confl}} = 0.10$).

### 5.2 Nested Zones
*   **Behavior**: A narrower S/D zone lies completely inside a wider S/D zone of the same type.
*   **Resolution**: Both are retained. The SNR Engine flags the nested zone as the **Core Zone** and the outer zone as the **Macro Zone**. The `EntryEngine` will use the Macro Zone to trigger execution alerts and the Core Zone for placing limit orders with tight stops.

### 5.3 Conflicting Zones (Supply vs. Demand Overlap)
*   **Behavior**: In tight range consolidations, a bearish Supply zone and a bullish Demand zone may overlap.
*   **Resolution**: This price band is flagged as a **Neutral Decision Node**.
    *   **Action**: Both S/D zones are temporarily deactivated for trading entries. No buy or sell setups are permitted within this overlapping range.
    *   **Release**: The system remains neutral until a completed H4 candle closes cleanly above the Supply High (activating bullish bias) or below the Demand Low (activating bearish bias).

---

## 6. Target MQL5 Data Structures

The SNR Engine will utilize the following structures to manage SNR Levels and Liquidity Pools:

```cpp
//--- Represents a consolidated support/resistance level
struct SNRLevel
{
   int       id;                 // Unique identifier
   double    priceHigh;          // Top boundary of the level
   double    priceLow;           // Bottom boundary of the level
   double    priceMid;           // Median price (entry reference)
   bool      isBullish;          // true = Support/Demand, false = Resistance/Supply
   bool      isFresh;            // true = 0 reactions/touches
   int       reactionCount;      // Number of touch reactions
   double    scoreTotal;         // Quality score (0-100)
   
   //--- Confluence Flags
   bool      hasMajorSwing;      // Overlaps Major Swing
   bool      hasMinorSwing;      // Overlaps Minor Swing
   bool      hasActiveZone;      // Overlaps active S/D Zone
   bool      hasBOSOrigin;       // Aligned with a BOS origin bar
   int       constituentCount;   // Number of overlapping elements
   datetime  creationTime;       // Oldest element time
};

//--- Represents a high-density area of stop orders (Liquidity Pool)
struct LiquidityPool
{
   int       id;                 // Unique identifier
   double    priceHigh;          // Top boundary of pool
   double    priceLow;           // Bottom boundary of pool
   bool      isBuyLiquidity;     // true = Buy Stops (above highs), false = Sell Stops (below lows)
   double    liquidityStrength;  // Strength rating (based on swing scores and age)
   bool      isSwept;            // Whether price has run this pool
   datetime  sweptTime;          // Time of sweep
};
```

---

## 7. Next Steps for Implementation

Upon design approval, the development of `SnrEngine.mqh` will follow:
1.  Initialize empty array lists for `SNRLevel` and `LiquidityPool`.
2.  Implement local price projection arrays for clustering.
3.  Write the H4 visual indicator script to draw confluenced zones and liquidity pools.
