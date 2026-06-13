# SPRINT 3.0 EXECUTION PLAN — SNR Engine v1.0

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: FINAL PLANNING GATE — AWAITING OWNER APPROVAL  
**Target Deliverables**: `src/engines/SnrEngine.mqh` + `src/tests/TestSnr.mq5`  
**Specification**: [SNR_ARCHITECTURE_FREEZE.md](docs/design/SNR_ARCHITECTURE_FREEZE.md)  
**Design Audit**: [SNR_DESIGN_AUDIT.md](docs/audits/SNR_DESIGN_AUDIT.md)

---

## 1. Exact Implementation Sequence

Sprint 3.0 follows the mandatory workflow from [AGENT_CONSTITUTION.md §6](AGENT_CONSTITUTION.md):

```
Design Freeze ✅ → Consistency Audit ✅ → Owner Approval ⏳ → Implementation → 
Compile Check → Backtest → Statistical Validation → Documentation → Code Freeze
```

### Implementation Steps (In Order)

| Step | Task | Depends On | Deliverable |
|------|------|-----------|-------------|
| **0** | Root cleanup: move `note for user.md`, `REPOSITORY_NORMALIZATION_AUDIT.md` | — | Clean root directory |
| **1** | Create `SnrEngine.mqh` scaffold (class shell, includes, input params) | Step 0 | Empty compilable class |
| **2** | Implement data structures (`SNRLevel`, `LiquidityPool`, internal structs) | Step 1 | Struct definitions |
| **3** | Implement `Init()`, `Deinit()`, upstream pointer validation | Step 2 | Initialization pipeline |
| **4** | Implement `CalculateLocalATR()` (local synchronous ATR(14)) | Step 3 | ATR computation |
| **5** | Implement `CacheH4PriceData()` (copy OHLCT arrays) | Step 4 | Cached price arrays |
| **6** | Implement `ExtractLevels()` (swing + zone extraction, filtering) | Step 5 | Raw level array |
| **7** | Implement `SortLevelsByPrice()` (ascending pre-sort) | Step 6 | Sorted level array |
| **8** | Implement `ClusterLevels()` (ATR-relative grouping with cap) | Step 7 | Clustered band array |
| **9** | Implement `MergeOverlappingZones()` (same-type merge, freshness reset) | Step 8 | Merged level array |
| **10** | Implement `HandleNeutralNodes()` (Supply vs. Demand conflict detection) | Step 9 | Neutral node flags |
| **11** | Implement `DetectNestedZones()` (Core vs. Macro flagging) | Step 10 | Nested zone flags |
| **12** | Implement `CalculateRejectionDistance()` (historical bar re-scan) | Step 11 | Rejection score data |
| **13** | Implement `ResolveBOSOrigin()` (swing/BOS cross-reference) | Step 12 | BOS origin flags |
| **14** | Implement `ScoreLevels()` (5-weight formula) | Step 13 | Scored SNR levels |
| **15** | Implement `MapLiquidityPools()` (buy/sell stop clusters) | Step 14 | Liquidity pool array |
| **16** | Implement `Analyze()` master pipeline (orchestrates Steps 4-15) | Step 15 | Complete analysis |
| **17** | Compile check: 0 errors, 0 warnings | Step 16 | Clean compile log |
| **18** | Create `TestSnr.mq5` validator EA (chart rendering, log output) | Step 17 | Test EA |
| **19** | Compile TestSnr.mq5: 0 errors, 0 warnings | Step 18 | Clean compile log |
| **20** | 4-year backtest (2022-2025, XAUUSD H4) | Step 19 | Strategy Tester logs |
| **21** | Parse logs: level counts, score distributions, cluster stats | Step 20 | Statistical report |
| **22** | Write SNR_ENGINE_V10_AUDIT.md | Step 21 | Audit document |
| **23** | Update PROJECT_MEMORY.md, commit, push, freeze | Step 22 | Frozen v1.0 |

---

## 2. Class Architecture

### 2.1 File Layout

```
src/engines/SnrEngine.mqh       ← Class definition + implementation
src/tests/TestSnr.mq5           ← Validator EA
```

### 2.2 Include Dependencies

```mql5
#include "StructureEngine.mqh"      // Provides: SwingPoint, BOSEvent, MSSEvent, CStructureEngine
#include "SupplyDemandEngine.mqh"    // Provides: SupplyDemandZone, CSupplyDemandEngine
```

### 2.3 Class Skeleton

```mql5
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
    RawLevel               m_rawLevels[];          // Pre-clustering extraction
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
    int                    m_atrPeriod;
    double                 m_clusterToleranceATR;
    double                 m_maxClusterWidthATR;
    double                 m_mergeOverlapRatio;
    double                 m_freshnessResetThreshold;
    int                    m_invalidatedZoneLookback;
    bool                   m_enableLog;

    //--- Private methods: data ingestion
    void                   CacheH4PriceData(int maxBars);
    double                 CalculateLocalATR(int barIndex, int period = 14);

    //--- Private methods: level extraction
    int                    ExtractLevels();
    void                   SortLevelsByPrice();

    //--- Private methods: clustering & merging
    int                    ClusterLevels();
    int                    MergeOverlappingZones();

    //--- Private methods: conflict resolution
    void                   HandleNeutralNodes();
    void                   DetectNestedZones();

    //--- Private methods: scoring components
    double                 CalculateStructureScore(const SNRLevel &level);
    double                 CalculateSDScore(const SNRLevel &level);
    double                 CalculateFreshnessScore(int reactionCount);
    double                 CalculateRejectionScore(const SNRLevel &level);
    double                 CalculateConfluenceScore(const SNRLevel &level);
    double                 CalculateRejectionDistance(double zoneHigh, double zoneLow,
                                                      int startBar, int endBar, bool isBullish);

    //--- Private methods: BOS origin resolution
    bool                   ResolveBOSOrigin(double priceHigh, double priceLow);

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
    int                    GetLevelCount() const;
    bool                   GetLevel(int index, SNRLevel &level);
    int                    GetActiveLevelCount(bool isBullish);
    bool                   GetHighestScoredLevel(bool isBullish, SNRLevel &level);

    //--- Accessors: Liquidity Pools
    int                    GetPoolCount() const;
    bool                   GetPool(int index, LiquidityPool &pool);
    int                    GetActivePoolCount(bool isBuyLiquidity);

    //--- Accessors: State
    bool                   IsNewBar();
};
```

---

## 3. Public Interfaces

### 3.1 CSnrEngine Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `Init` | `bool Init(CStructureEngine*, CSupplyDemandEngine*)` | Validates upstream pointers, initializes arrays |
| `Deinit` | `void Deinit()` | Releases all dynamic arrays |
| `Analyze` | `int Analyze(int maxBars = 300)` | Full analysis pipeline, returns total SNR levels |
| `GetLevelCount` | `int GetLevelCount() const` | Returns `ArraySize(m_snrLevels)` |
| `GetLevel` | `bool GetLevel(int index, SNRLevel &level)` | Copies level at index, returns false if out of bounds |
| `GetActiveLevelCount` | `int GetActiveLevelCount(bool isBullish)` | Counts non-neutral levels by direction |
| `GetHighestScoredLevel` | `bool GetHighestScoredLevel(bool isBullish, SNRLevel &level)` | Returns the highest-scored active level |
| `GetPoolCount` | `int GetPoolCount() const` | Returns `ArraySize(m_liquidityPools)` |
| `GetPool` | `bool GetPool(int index, LiquidityPool &pool)` | Copies pool at index |
| `GetActivePoolCount` | `int GetActivePoolCount(bool isBuyLiquidity)` | Counts un-swept pools by type |
| `IsNewBar` | `bool IsNewBar()` | Returns true on new H4 bar |

### 3.2 Upstream APIs Consumed (Read-Only)

#### From CStructureEngine (Frozen v2.2)

| Method | Returns | Used For |
|--------|---------|----------|
| `GetMajorHighCount()` | `int` | Loop bound for major swing extraction |
| `GetMajorLowCount()` | `int` | Loop bound for major swing extraction |
| `GetMajorHigh(int, SwingPoint&)` | `bool` | Extract major swing high data |
| `GetMajorLow(int, SwingPoint&)` | `bool` | Extract major swing low data |
| `GetSwingHighCount()` | `int` | Loop bound for minor swing extraction |
| `GetSwingLowCount()` | `int` | Loop bound for minor swing extraction |
| `GetSwingHigh(int, SwingPoint&)` | `bool` | Extract all swing high data (check grade for Minor) |
| `GetSwingLow(int, SwingPoint&)` | `bool` | Extract all swing low data (check grade for Minor) |
| `GetBOSCount()` | `int` | Loop bound for BOS origin resolution |
| `GetBOSEvent(int, BOSEvent&)` | `bool` | Extract BOS event data for origin matching |
| `GetCurrentTrend()` | `ENUM_TREND_STATE` | Context for directional bias (logging only) |

#### From CSupplyDemandEngine (Frozen v1.1)

| Method | Returns | Used For |
|--------|---------|----------|
| `GetZoneCount()` | `int` | Loop bound for zone extraction |
| `GetZone(int, SupplyDemandZone&)` | `bool` | Extract zone data (active + invalidated within 150 bars) |

---

## 4. Data Structures

### 4.1 Output Structures (From Frozen Architecture Spec)

```mql5
//--- Consolidated Support/Resistance Level
struct SNRLevel
{
    int       id;                 // Unique identifier
    double    priceHigh;          // Top boundary
    double    priceLow;           // Bottom boundary
    double    priceMid;           // Median price (entry reference)
    bool      isBullish;          // true = Support/Demand, false = Resistance/Supply
    bool      isFresh;            // true = 0 reactions
    int       reactionCount;      // Touch count
    double    scoreTotal;         // Quality score (0-100)

    //--- Confluence Flags
    bool      hasMajorSwing;      // Overlaps Major Swing
    bool      hasMinorSwing;      // Overlaps Minor Swing
    bool      hasActiveZone;      // Overlaps active S/D Zone
    bool      hasBOSOrigin;       // Aligned with BOS origin bar
    int       constituentCount;   // Number of overlapping elements
    datetime  creationTime;       // Oldest element time (or freshness-reset time)

    //--- Scoring Components (for debugging/logging)
    double    scoreStruct;        // S_Struct (0-100)
    double    scoreSD;            // S_SD (0-100)
    double    scoreFresh;         // S_Fresh (0-100)
    double    scoreReject;        // S_Reject (0-100)
    double    scoreConfl;         // S_Confl (0-100)

    //--- Conflict State
    bool      isNeutralNode;      // true = deactivated due to Supply/Demand overlap
    bool      isCoreZone;         // true = inner nested zone
    bool      isMacroZone;        // true = outer nested zone
};

//--- Liquidity Pool (Stop Order Cluster)
struct LiquidityPool
{
    int       id;                 // Unique identifier
    double    priceHigh;          // Top boundary
    double    priceLow;           // Bottom boundary
    bool      isBuyLiquidity;     // true = Buy Stops above highs
    double    liquidityStrength;  // Strength rating
    bool      isSwept;            // Whether price has run this pool
    datetime  sweptTime;          // Time of sweep event
};
```

### 4.2 Internal Working Structure

```mql5
//--- Temporary structure for pre-clustering level extraction
struct RawLevel
{
    double    price;              // Price coordinate (single point or zone boundary)
    double    priceHigh;          // Top boundary (zone or swing tolerance)
    double    priceLow;           // Bottom boundary (zone or swing tolerance)
    bool      isBullish;          // Direction
    int       sourceType;         // 0=MajorSwing, 1=MinorSwing, 2=ActiveZone, 3=InvalidatedZone
    int       sourceIndex;        // Index into upstream array
    datetime  sourceTime;         // Creation time from upstream
    bool      isInvalidated;      // Zone invalidation state
    double    impulseRange;       // Zone impulse range (for merge dominance check)
    double    bodyDominance;      // Zone body dominance (for merge dominance check)
    int       reactionCount;      // Upstream reaction count
};
```

---

## 5. Algorithm Details

### 5.1 Level Extraction Algorithm (`ExtractLevels`)

```
INPUT:  Upstream engine pointers
OUTPUT: m_rawLevels[] populated

1. FOR each Major Swing High (via m_structureEngine.GetMajorHigh()):
   → Create RawLevel: sourceType=0, isBullish=false (Resistance)
   → priceHigh = swing.price + 0.10 × ATR  (tolerance band)
   → priceLow  = swing.price - 0.10 × ATR

2. FOR each Major Swing Low (via m_structureEngine.GetMajorLow()):
   → Create RawLevel: sourceType=0, isBullish=true (Support)
   → priceHigh/priceLow with ±0.10 × ATR tolerance

3. FOR each Minor Swing (grade == SWING_GRADE_MINOR, via GetSwingHigh/GetSwingLow):
   → Create RawLevel: sourceType=1
   → Same tolerance band

4. FOR each S/D Zone (via m_sdEngine.GetZone()):
   → IF zone.isInvalidated AND (zone.impulseBarIndex > 150): SKIP
   → Create RawLevel: sourceType=2 (active) or 3 (invalidated)
   → priceHigh = zone.zoneHigh, priceLow = zone.zoneLow
   → isBullish = (zone.zoneType == ZONE_DEMAND)
```

### 5.2 Clustering Algorithm (`ClusterLevels`)

```
INPUT:  m_rawLevels[] sorted in price-ascending order
OUTPUT: m_snrLevels[] (pre-scoring)

1. Initialize cluster with first raw level
2. FOR i = 1 to ArraySize(m_rawLevels) - 1:
   a. distance = m_rawLevels[i].priceLow - currentClusterHigh
   b. IF distance <= m_clusterToleranceATR × ATR:
      - proposedHigh = max(currentClusterHigh, m_rawLevels[i].priceHigh)
      - proposedLow  = min(currentClusterLow,  m_rawLevels[i].priceLow)
      - IF (proposedHigh - proposedLow) <= m_maxClusterWidthATR × ATR:
        → Expand cluster: update boundaries, merge constituents
      - ELSE:
        → Finalize current cluster → start new cluster
   c. ELSE:
      → Finalize current cluster → start new cluster
3. Finalize last cluster
```

### 5.3 Zone Merge Algorithm (`MergeOverlappingZones`)

```
INPUT:  Constituent zones within a cluster
OUTPUT: Merged zone boundaries and metadata

FOR each pair of same-type zones (Z1, Z2) within a cluster:
1. overlapHeight = min(Z1.High, Z2.High) - max(Z1.Low, Z2.Low)
2. minHeight     = min(Z1.Height, Z2.Height)
3. overlapRatio  = overlapHeight / minHeight
4. IF overlapRatio >= 0.50:
   a. MergedHigh = max(Z1.High, Z2.High)
   b. MergedLow  = min(Z1.Low,  Z2.Low)
   c. DEFAULT: creationTime = older zone, reactionCount = sum (cap 3)
   d. FRESHNESS RESET CHECK:
      - newerImpulseRange = newer.impulseRange
      - olderImpulseRange = older.impulseRange
      - IF newerImpulseRange > olderImpulseRange × 1.20 OR
           newer.bodyDominance > older.bodyDominance × 1.20:
        → creationTime = newer.creationTime
        → reactionCount = 0
```

### 5.4 Scoring Formula

```
Score_SNR = (0.20 × S_Struct) + (0.30 × S_SD) + (0.20 × S_Fresh) + (0.20 × S_Reject) + (0.10 × S_Confl)
```

| Component | 0 pts | 30 pts | 50 pts | 60 pts | 70 pts | 100 pts |
|-----------|-------|--------|--------|--------|--------|---------|
| S_Struct | No swing | — | Minor Swing | — | — | Major Swing |
| S_SD | No zone | Invalidated zone | — | — | — | Active zone |
| S_Fresh | ≥3 touches | 2 touches | — | 1 touch | — | 0 touches (fresh) |
| S_Reject | Untouched | — | — | — | — | AvgReject/ATR × 50 (capped) |
| S_Confl | No overlap | — | S/D+Minor | — | MajorSwing+BOS | S/D+Major / Multi-zone |

### 5.5 Rejection Distance Calculation

```
FOR each SNR level with reactionCount > 0:
1. Scan bars from level.creationBar down to bar 1
2. Identify touch events: candle high/low enters level boundaries
3. For each touch:
   a. Look forward (lower bar indices) for max 10 bars
   b. Record maximum excursion away from level boundary
   c. excursionATR = excursion / ATR at touch bar
4. avgRejectionATR = sum(excursionATR) / touchCount
5. S_Reject = min(100.0, avgRejectionATR × 50.0)
```

### 5.6 BOS Origin Resolution

```
FOR each SNR level:
1. FOR each BOSEvent (via m_structureEngine.GetBOSEvent()):
   a. FOR each Major Swing matching bos.brokenLevel:
      - IF swing.price matches bos.brokenLevel (within tolerance)
        AND swing.breakBarIndex matches bos.barIndex:
        → originBar = swing.barIndex
        → IF level.priceLow <= swing.price <= level.priceHigh:
          → level.hasBOSOrigin = true
```

### 5.7 Liquidity Pool Mapping

```
FOR each Major Swing High (not invalidated):
1. poolHigh = swing.price + 0.10 × ATR
2. poolLow  = swing.price
3. isBuyLiquidity = true (buy stops above highs)
4. strength = swing.strengthScore × (1.0 - age_decay)

FOR each Major Swing Low (not invalidated):
1. poolHigh = swing.price
2. poolLow  = swing.price - 0.10 × ATR
3. isBuyLiquidity = false (sell stops below lows)

Sweep detection:
- IF any closed H4 candle's high > poolHigh (buy) or low < poolLow (sell):
  → pool.isSwept = true, pool.sweptTime = candle time
```

---

## 6. Testing Strategy

### 6.1 TestSnr.mq5 — Validator EA

| Feature | Description |
|---------|-------------|
| **Chart Rendering** | Draw horizontal bands for each SNR level (color-coded by score), boxes for liquidity pools |
| **Score Labels** | Display `Score: XX.X` next to each level band |
| **Confluence Markers** | Icons for Major Swing overlap, BOS origin, Zone overlap |
| **Neutral Node Markers** | Red cross-hatching for deactivated overlap zones |
| **Log Output** | Print full scoring breakdown per level per H4 bar |

### 6.2 Unit-Level Verification Checklist

| # | Test | Expected Outcome | How to Verify |
|---|------|-------------------|---------------|
| 1 | **Compilation** | 0 errors, 0 warnings | MetaEditor compile log |
| 2 | **ATR Locality** | No calls to upstream `GetATRValue()` | Grep source; no `m_structureEngine.GetATRValue` |
| 3 | **Sorted Input** | Levels enter clustering in price-ascending order | Log pre-sort vs. post-sort arrays |
| 4 | **Cluster Width Cap** | No cluster wider than 1.50 × ATR | Log cluster widths; assert `width <= 1.50 * atr` |
| 5 | **Merge Overlap** | Same-type merges require ≥ 50% height overlap | Log merge decisions with overlap ratios |
| 6 | **Freshness Reset** | New dominant zone resets creation time | Log merge decisions showing reset trigger |
| 7 | **Invalidated Inclusion** | Invalidated zones (within 150 bars) participate in clustering | Log extraction counts: active vs. invalidated |
| 8 | **Neutral Nodes** | Overlapping Supply/Demand zones deactivated | Log neutral node flags and zone IDs |
| 9 | **Score Range** | All scores in [0, 100] | Assert `0.0 <= scoreTotal <= 100.0` |
| 10 | **Score Formula** | Worked examples match specification (50.0, 80.0, 63.0) | Compare log output against §8 examples |
| 11 | **BOS Origin** | Levels aligned with BOS origin correctly flagged | Log `hasBOSOrigin=true` matches |
| 12 | **Liquidity Pools** | Pools mapped above highs / below lows | Visual chart verification |
| 13 | **Sweep Detection** | Swept pools flagged correctly | Log sweep events with bar/time |
| 14 | **Bar 0 Exclusion** | No analysis on uncompleted candle | Confirm all decisions at barIdx ≥ 1 |
| 15 | **Read-Only** | No upstream modification | Grep for `m_structureEngine.Set` or direct array writes |

---

## 7. Backtest Validation Strategy

### 7.1 Test Configuration

| Parameter | Value |
|-----------|-------|
| Symbol | XAUUSD (or XAUUSDm) |
| Period | 2022.01.01 to 2025.12.31 |
| Timeframe | H4 |
| Execution Timeframe | M30 (if multi-TF) |
| Model | Every Tick |
| Deposit | $10,000 (default) |
| Logging | Full (all SNR levels, scores, pools per bar) |

### 7.2 Statistical Metrics to Collect

| Metric | Source | Expected Range |
|--------|--------|---------------|
| Total SNR Levels Created | Parser | 50-200 over 4 years |
| Support vs. Resistance Ratio | Parser | ~50/50 (±10%) |
| Average Score | Parser | 40-70 |
| Score Distribution (0-20, 21-40, 41-60, 61-80, 81-100) | Parser | Bell-curve centered 40-60 |
| Levels with Major Swing overlap | Parser | >50% of levels |
| Levels with Active Zone overlap | Parser | >30% of levels |
| Neutral Nodes created | Parser | 5-20 over 4 years |
| Neutral Nodes resolved by invalidation | Parser | 100% (all resolved naturally) |
| Liquidity Pools mapped | Parser | 30-80 |
| Liquidity Pools swept | Parser | 40-70% |
| Cluster widths (min/max/avg) | Parser | Max ≤ 1.50 × ATR |
| Freshness resets triggered | Parser | 5-15% of merges |
| Rejection distances (avg ATR) | Parser | 0.5-2.0 ATR |

### 7.3 Validation Success Criteria

The sprint is validated and ready for freeze **only** if:

1. ✅ Compilation: 0 errors, 0 warnings
2. ✅ No repainting: All levels created from completed bars (barIdx ≥ 1)
3. ✅ Score range: All scores in [0.0, 100.0]
4. ✅ Worked examples: At least 2 of 3 specification examples reproduce within ±2 points
5. ✅ Cluster cap: No cluster exceeds 1.50 × ATR width
6. ✅ Neutral nodes: All resolved via upstream invalidation (no custom release needed)
7. ✅ No upstream modification: StructureEngine and SupplyDemandEngine untouched
8. ✅ Audit document: SNR_ENGINE_V10_AUDIT.md written and committed

---

## 8. Risk Assessment

### 8.1 Implementation Risks

| # | Risk | Severity | Mitigation | Source |
|---|------|----------|------------|--------|
| 1 | **ATR = 0 during early bars** | HIGH | Guard all ATR divisions with `if(atr <= 0.0) continue;`. Same pattern as StructureEngine L237. | Bug 5 (LESSONS_LEARNED) |
| 2 | **Rejection scan performance** | HIGH | Cap scan to ±20 bars from touch bar, not entire history. Cache results per level to avoid re-scanning. | SNR_DESIGN_AUDIT §5.1 |
| 3 | **Empty upstream arrays** | MEDIUM | Check `GetMajorHighCount() > 0` before extraction loop. Return 0 levels if no upstream data. | Defensive coding |
| 4 | **Order-dependent clustering** | MEDIUM | Price-ascending sort is mandated (Step 7). Add assertion log to verify sort order. | SNR_DESIGN_AUDIT §5.2 |
| 5 | **Duplicate S_React naming** | MEDIUM | Use `S_Reject` / `scoreReject` exclusively. Never use `scoreReaction` in SNR context. | SNR_DESIGN_AUDIT §4.2 |
| 6 | **Boundary bar counting** | MEDIUM | All scan loops use `barIdx >= 1` (never Bar 0). Invalidation boundaries use exclusive stop. | Bug 2 + Bug 7 (LESSONS_LEARNED) |
| 7 | **Merge freshness reset edge case** | LOW | Log every freshness reset with zone IDs, impulse ranges, and dominance ratios for post-hoc verification. | SNR_DESIGN_AUDIT §3.2 |
| 8 | **BOS origin matching tolerance** | LOW | Use `MathAbs(swing.price - bos.brokenLevel) <= 0.01` for XAUUSD pip precision. | SNR_DESIGN_AUDIT §2.3 |

### 8.2 Lessons-Learned Compliance

Each historical bug has a corresponding guard in this plan:

| Bug | Guard in Sprint 3.0 |
|-----|---------------------|
| Bug 1 (Cumulative counting) | Not applicable — SNR uses single-pass per-bar analysis |
| Bug 2 (Bar 0 repainting) | All scan loops stop at `barIdx >= 1` (Step 16, Test #14) |
| Bug 3 (Pipeline ordering) | Extraction → Sort → Cluster → Merge → Score — strict order (Steps 6-14) |
| Bug 4 (Consolidation inflation) | `insideZone` state tracker in rejection scan (Step 12) |
| Bug 5 (ATR async) | Local ATR computation only (Step 4, Test #2) |
| Bug 6 (Age subtraction) | Use `impulseBarIndex - currentBarIdx` consistently |
| Bug 7 (Boundary exclusion) | Exclusive stop bar: `invalidatedBar + 1` in all scans |

---

## 9. Input Parameters

```mql5
//--- SNR Clustering
input double InpSnrClusterToleranceATR = 0.25;    // Cluster tolerance (ATR multiplier)
input double InpMaxClusterWidthATR     = 1.50;    // Max cluster width (ATR multiplier)

//--- Zone Merge
input double InpMergeOverlapRatio      = 0.50;    // Min overlap ratio for same-type merge
input double InpFreshnessResetThresh   = 0.20;    // New zone dominance threshold (20%)

//--- Level Extraction
input int    InpInvalidatedLookback    = 150;     // Max bars for invalidated zone inclusion

//--- Scoring Weights
input double InpWeightStruct           = 0.20;    // W_Struct
input double InpWeightSD               = 0.30;    // W_SD
input double InpWeightFresh            = 0.20;    // W_Fresh
input double InpWeightReject           = 0.20;    // W_Reject
input double InpWeightConfl            = 0.10;    // W_Confl

//--- Liquidity
input double InpLiquidityToleranceATR  = 0.10;    // Pool boundary tolerance (ATR)

//--- Logging
input bool   InpEnableSnrLog           = true;    // Enable SNR logging
```

---

## 10. Execution Timeline

| Phase | Duration Estimate | Output |
|-------|-------------------|--------|
| **Step 0**: Root cleanup | 5 min | Clean root |
| **Steps 1-5**: Scaffold + data layer | 30 min | Compilable shell with ATR + caching |
| **Steps 6-7**: Extraction + sorting | 20 min | Raw level array |
| **Steps 8-9**: Clustering + merging | 45 min | Clustered level array |
| **Steps 10-11**: Conflict resolution | 20 min | Neutral nodes + nested zones |
| **Steps 12-13**: Rejection + BOS origin | 30 min | Score input data |
| **Steps 14-15**: Scoring + liquidity | 25 min | Complete scored output |
| **Step 16**: Master pipeline | 15 min | `Analyze()` orchestration |
| **Step 17**: Compile check | 5 min | 0/0 verification |
| **Steps 18-19**: TestSnr.mq5 | 30 min | Validator EA |
| **Steps 20-21**: Backtest + parsing | 30 min | Statistical report |
| **Steps 22-23**: Audit + freeze | 20 min | Documentation + commit |

**Total estimated**: ~4.5 hours

---

## 11. Definition of Done (Sprint 3.0)

Sprint 3.0 is classified as **DONE** when:

- [ ] `SnrEngine.mqh` compiles with 0 errors, 0 warnings
- [ ] `TestSnr.mq5` compiles with 0 errors, 0 warnings
- [ ] 4-year backtest runs to completion without crashes
- [ ] Score range verified: all levels in [0, 100]
- [ ] Cluster cap verified: no cluster exceeds 1.50 × ATR
- [ ] Neutral node resolution verified: all resolved via upstream invalidation
- [ ] No upstream engine modifications
- [ ] SNR_ENGINE_V10_AUDIT.md written with statistical evidence
- [ ] PROJECT_MEMORY.md updated
- [ ] All changes staged, committed, pushed to GitHub
- [ ] Module frozen: `SnrEngine.mqh v1.0 [FROZEN]`

---

> **This is the final planning gate.**
>
> No code may be written until the project owner reviews and approves this execution plan.
