# SNR Engine v1.0 - Design Consistency Audit Report

**Author**: Quant Researcher & Market Structure Auditor  
**Date**: June 12, 2026  
**Status**: COMPLETE  
**Target Module**: `SnrEngine.mqh` (Sprint 3.0 Design Phase)  
**Dependencies Reviewed**: 
*   [StructureEngine.mqh (v2.2)](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh)
*   [SupplyDemandEngine.mqh (v1.1)](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh)
*   [SNR_ENGINE_DESIGN.md](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md)
*   [SNR_SCORING_MODEL.md](file:///c:/xauusd_chatgpt/docs/archive/SNR_SCORING_MODEL.md)
*   [SNR_DATA_FLOW.md](file:///c:/xauusd_chatgpt/docs/archive/SNR_DATA_FLOW.md)
*   [UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md](file:///c:/xauusd_chatgpt/docs/reports/UPDATED_SUPPLY_DEMAND_STATISTICAL_REPORT.md)

---

## 1. Executive Summary

This Design Consistency Audit evaluates the readiness of the **SNR Engine v1.0** design package before coding begins. The goal is to identify logical contradictions, impossible data dependencies, circular dependencies, duplicated scoring concepts, and future performance risks across the integration boundaries of the frozen `StructureEngine v2.2` and `SupplyDemandEngine v1.1` modules.

### Audit Verdict: **PASSED WITH RESERVATIONS**
The architectural flow and mathematical scoring weights are conceptually sound and provide a solid basis for institutional mapping. However, **two critical compilation blocks (impossible data dependencies)** and **three logical contradictions** have been identified. These issues must be formally resolved and documented in this audit report before the architecture is frozen and any MQL5 code is written.

---

## 2. Impossible Data Dependencies

A data dependency is classified as "impossible" if the target engine's design assumes access to variables, methods, or structs that are either private or not stored in the upstream frozen modules.

### 2.1 Private Access Violation: `GetATRValue()`
*   **Design Claim**: [SNR_ENGINE_DESIGN.md: Section 2.2](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md#L45) states that `CSnrEngine` retrieves local volatility (ATR) by calling `m_structureEngine.GetATRValue(barIndex)`.
*   **Code Reality**: In [StructureEngine.mqh:L296](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L296), the method `GetATRValue(int barIndex)` is declared in the `private:` section of the class. It is not accessible from external classes.
*   **Compilation Impact**: Attempting to call this method inside `CSnrEngine` will cause a compiler error: `cannot access private member function`.
*   **Resolution Strategy**: Since `StructureEngine.mqh` is frozen, `CSnrEngine` must implement its own local, synchronous ATR(14) calculation using cached price arrays (mirroring the logic in `StructureEngine.mqh` but operating within its own scope), or we must define a public wrapper. To preserve the frozen status of Module 1, **local calculation within `CSnrEngine` is the mandated path**.

### 2.2 Missing Reaction Coordinates in `SupplyDemandZone`
*   **Design Claim**: [SNR_SCORING_MODEL.md: Section 3.4](file:///c:/xauusd_chatgpt/docs/archive/SNR_SCORING_MODEL.md#L55) defines the Reaction Score ($S_{\text{React}}$) based on the **Average Rejection Distance (in ATRs)** of the price bounces away from the level.
*   **Code Reality**: The [SupplyDemandZone](file:///c:/xauusd_chatgpt/src/engines/SupplyDemandEngine.mqh#L37) struct stores `reactionCount` as a simple integer. It **does not store** the bar indices or price coordinates where these touches occurred.
*   **Execution Impact**: `CSnrEngine` cannot compute the rejection distance of past touches using the zone metadata alone.
*   **Resolution Strategy**: To calculate rejection distance, `CSnrEngine` must re-scan the historical bars between `zone.impulseBarIndex` and the current bar to identify the exact bars that touched the zone boundaries, find the maximum price excursion (rejection bounce) following each touch, and calculate the ATR-relative distance. This introduces a minor performance penalty due to redundant scanning.

### 2.3 Missing BOS Origin Association in `BOSEvent`
*   **Design Claim**: [SNR_ENGINE_DESIGN.md: Section 6](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md#L115) defines `bool hasBOSOrigin` in the `SNRLevel` struct to flag alignment with a BOS origin bar.
*   **Code Reality**: The [BOSEvent](file:///c:/xauusd_chatgpt/src/engines/StructureEngine.mqh#L123) struct only contains the price level (`brokenLevel`) and the break time/index. It does not store a reference or index to the original `SwingPoint` that was broken.
*   **Resolution Strategy**: `CSnrEngine` must query the major swing arrays (`m_structureEngine.GetMajorHigh()` / `GetMajorLow()`) to find the invalidated swing whose price matches `brokenLevel` and whose `breakBarIndex` matches the BOS event index. The original swing's `barIndex` then serves as the BOS origin.

---

## 3. Logical Contradictions

### 3.1 Invalidated Zone Exclusion vs. Scoring
*   **Contradiction**: [SNR_ENGINE_DESIGN.md: Section 3.1](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md#L41) (Clustering Steps) states: *"Extract all active S/D zones..."* (invalidated zones are ignored). However, [SNR_SCORING_MODEL.md: Section 3.2](file:///c:/xauusd_chatgpt/docs/archive/SNR_SCORING_MODEL.md#L44) states: *"Level overlaps only with an Invalidated S/D zone: 30 points."*
*   **Impact**: If the clustering algorithm ignores invalidated zones during the extraction phase, an SNR Level can never be formed around an invalidated zone, making the 30-point scoring rule mathematically unreachable.
*   **Correction**: The clustering step must be modified to extract **both active zones and recently invalidated zones (within the lookback window)** so they can participate in price projection, while their active/invalidated status is checked during the scoring phase.

### 3.2 Merge Rules Penalizing Fresh Institutional Activity
*   **Contradiction**: [SNR_ENGINE_DESIGN.md: Section 4](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md#L108) states that when two same-type zones overlap, the merged zone:
    1.  Inherits the **older** creation time of the two zones to calculate Age decay.
    2.  Sums the reaction counts of both zones (capped at 3).
*   **Impact**: If an old, heavily retested zone (e.g. 2 reactions, created 300 bars ago) overlaps with a brand new, highly dominant impulse zone (0 reactions, created 1 bar ago), the merge rules will force the consolidated level to inherit the old creation time and sum the reactions to 2. This decays the Age Score and Freshness Score of the new level to near-zero, treating a fresh institutional order block as stale and depleted.
*   **Correction**: The merge rules must prioritize fresh volume. If a new zone is merged into an old zone, the creation time should be updated to the **newest** zone's time if the new zone's impulse range or body dominance exceeds the old zone's metrics by a threshold (e.g. 20%), resetting the level's freshness.

### 3.3 Redundant Neutral Node Release Condition
*   **Contradiction**: [SNR_ENGINE_DESIGN.md: Section 5.3](file:///c:/xauusd_chatgpt/docs/archive/SNR_ENGINE_DESIGN.md#L129) defines the release of a Neutral Decision Node as: *"until a completed H4 candle closes cleanly above the Supply High or below the Demand Low."*
*   **Impact**: A closed H4 candle above the Supply High automatically invalidates the Supply zone in `SupplyDemandEngine v1.1`. Once invalidated, the overlap conflict ceases to exist, and the node is no longer neutral because only the Demand zone remains active. The custom release condition is logically redundant with the core engine's invalidation rules.

---

## 4. Duplicated Scoring Concepts

### 4.1 Dual Freshness Decay
*   `CSupplyDemandEngine v1.1` already calculates a `scoreFreshness` (100 $\rightarrow$ 50 $\rightarrow$ 25 $\rightarrow$ 0) based on `reactionCount`.
*   `CSnrEngine v1.0` re-calculates a freshness score $S_{\text{Fresh}}$ (100 $\rightarrow$ 60 $\rightarrow$ 30 $\rightarrow$ 0) based on the same `reactionCount`.
*   **Impact**: Retest decay is applied twice under slightly different parameters, wasting CPU cycles and complicating parameter tuning.

### 4.2 Reaction Score Naming Conflict
*   In `CSupplyDemandEngine`, the reaction score (`scoreReaction`) **increases** with more touches (`reactionCount * 33.3`), representing a zone that has proven its validity.
*   In `CSnrEngine`, the reaction score ($S_{\text{React}}$) measures **rejection distance**, and is independent of the touch count, while the touch count is used to **decay** freshness.
*   **Impact**: Having a variable named `Reaction Score` that increases with touches in one module, and a variable named `Reaction Score` that represents price bounce distance in another, creates cognitive friction for developers and quant researchers.
*   **Correction**: Rename $S_{\text{React}}$ in `CSnrEngine` to **Rejection Strength Score** ($S_{\text{Reject}}$) to clearly distinguish it from reaction quantity.

---

## 5. Future Performance & Implementation Risks

### 5.1 Redundant Price History Scanning
*   To calculate `reactionCount`, both `CStructureEngine` and `CSupplyDemandEngine` execute chronological loops scanning back hundreds of bars.
*   To calculate $S_{\text{React}}$ (rejection distance), `CSnrEngine` must perform another historical loop to find the highs/lows of reaction bars.
*   **Risk**: Running multiple independent historical scanning loops inside `OnTick` (even if gated by a new H4 bar) will significantly slow down multi-year portfolio backtests and optimizations.
*   **Mitigation**: Implement a local caching structure inside `CSnrEngine` that stores mapped price arrays, or optimize the loops to scan only the delta between the last analyzed bar and the current bar.

### 5.2 Order-Dependence in clustering
*   The clustering algorithm projects levels on the price axis and groups them if they are within $0.25 \times ATR$.
*   **Risk**: If the levels are not sorted in a consistent order (e.g. chronologically vs. price-ascending vs. score-descending) before clustering, the resulting boundaries will be order-dependent. For example, clustering $A \rightarrow B \rightarrow C$ may yield different coordinates than clustering $C \rightarrow B \rightarrow A$.
*   **Mitigation**: The implementation plan must mandate that all levels are sorted in **ascending price order** before the clustering projection loop is executed.

---

## 6. Conclusion & Action Items

The design package for Sprint 3.0 is highly detailed but contains critical access and logical gaps. To freeze the architecture successfully, the following adjustments are recorded as approved amendments to the design documents:

1.  **ATR Ingestion**: `CSnrEngine` will compute H4 ATR(14) locally using cached price data, avoiding calls to the private `GetATRValue()` method of upstream classes.
2.  **Clustering Input**: The extraction phase will include invalidated S/D zones created within the last 150 bars to satisfy the $S_{\text{SD}} = 30$ scoring parameter.
3.  **Naming Alignment**: The SNR scoring component $S_{\text{React}}$ is formally renamed to **Rejection Score** ($S_{\text{Reject}}$) to represent bounce distance, and the upstream zone reaction score is treated as structural validation count.
4.  **Clustering Order**: Levels must be sorted in price-ascending order prior to clustering to ensure deterministic price bands.
