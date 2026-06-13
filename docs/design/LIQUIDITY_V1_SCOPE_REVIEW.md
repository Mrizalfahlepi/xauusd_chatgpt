# Liquidity Engine v1.0 - V1 Scope Review

**Author**: Market Structure & Architecture Team  
**Date**: June 13, 2026  
**Status**: SUBMITTED FOR REVIEW  
**Workspace**: `c:\xauusd_chatgpt`  
**Reference Design**: [LIQUIDITY_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_ARCHITECTURE_FREEZE.md)  
**Reference Justification**: [LIQUIDITY_PARAMETER_JUSTIFICATION.md](file:///c:/xauusd_chatgpt/docs/design/LIQUIDITY_PARAMETER_JUSTIFICATION.md)

---

## 1. Executive Summary

This document conducts a rigorous review of Phase 4 (Liquidity Engine) features to define the **Minimum Viable Architecture** for Version 1. 

In accordance with the project's core philosophy of correctness, recoverability, and simplicity, we evaluate every planned feature of `CLiquidityEngine` and classify it into one of three tiers:
*   **REQUIRED FOR V1 (A)**: Essential for core functionality, trading safety, or Strategy Tester stability.
*   **OPTIONAL FOR V1 (B)**: Non-critical features that can be disabled or bypassed to simplify code.
*   **REMOVE/DEFER FROM V1 (C)**: Features that introduce unnecessary memory overhead, duplicate upstream calculations, or add redundant complexity without statistical justification.

By stripping out optional and deferred components, we define a highly focused, bulletproof V1 engine that meets all roadmap criteria with the smallest possible footprint.

---

## 2. Feature Classification Matrix

| Feature / Component | Classification | Evidence & Architectural Rationale | Impact on Code Complexity |
|:---|:---:|:---|:---|
| **M30 Intraday Monitoring** | **REQUIRED (A)** | [01_MARKET_DEFINITIONS.md:L28](file:///c:/xauusd_chatgpt/docs/core/01_MARKET_DEFINITIONS.md#L28) defines the execution timeframe as M30. Scanning H4 pools on H4 closes introduces a 4-hour execution lag, ruining the R:R ratio on Gold. | High (requires multi-timeframe caching). |
| **Local Caching Protocol** | **REQUIRED (A)** | [LESSONS_LEARNED.md:L219-254](file:///c:/xauusd_chatgpt/docs/core/LESSONS_LEARNED.md#L219-L254) (Bug 5) documents that MT5 Strategy Tester cross-timeframe calls are asynchronous. Caching arrays locally is mandatory for tester stability. | High (required for stability). |
| **Sweep Detection** | **REQUIRED (A)** | [SYSTEM_ROADMAP.md:L38](file:///c:/xauusd_chatgpt/SYSTEM_ROADMAP.md#L38) defines the core phase target: "Tracks sweep events when price runs these pools." | Low (basic boundary comparison). |
| **Breakout Filter** | **REQUIRED (A)** | Reversal trading systems face catastrophic losses during momentum-driven trend breakouts. Filtering out deep breaches is a mandatory safety gate. | Low (single-parameter threshold comparison). |
| **Local H4 ATR Calculation** | **REQUIRED (A)** | Necessary to scale the excursion depth of sweeps relative to H4 volatility for breakout filtering. | Low (local mathematical function). |
| **Sweep Min Size Filter** | **OPTIONAL (B)** | Meant to filter spread-noise, but evaluating sweeps strictly on *closed M30 bars* (`barIdx >= 1`) naturally filters out noise without needing a size parameter. | Low (removes `InpLiqSweepMinSizeATR`). |
| **Event History Array** | **OPTIONAL (B)** | Downstream engines only require transient signal triggers (`isBSLSweptThisBar`) for execution. Storing all historical sweeps in memory is non-critical. | Moderate (removes array resizing and memory management). |
| **Sweep Classification** | **DEFER (C)** | Classifying sweeps into Minor/Medium/Major brackets adds arbitrary thresholds with zero trade-performance justification. Downstream can evaluate raw double values. | Low (removes classification logic). |
| **Liquidity Freshness Decay** | **REMOVE (C)** | [LIQUIDITY_RESPONSIBILITY_AUDIT.md:Section 3](file:///c:/xauusd_chatgpt/docs/audits/LIQUIDITY_RESPONSIBILITY_AUDIT.md#L3) forbids recalculating pool strength or decay, which is already locked in `CSnrEngine`. | Moderate (prevents duplicate loops and variables). |

---

## 3. Tier-by-Tier Detail

### 3.1 Required Features (Tier A)
*   **M30 Intraday Scanning**: Evaluates the H4-defined boundaries against M30 completed candles (`barIdx = 1`). Captures stop runs within 30 minutes of occurrence instead of 4 hours.
*   **Local Caching Protocol**: Synchronously caches H4 and M30 price history into private arrays. Eliminates Strategy Tester thread synchronization errors (Local ATR Principle).
*   **Core Sweep Detection**: Compares closed M30 High/Low against pool coordinates (`nearestBSL.priceLow` for BSL, and `nearestSSL.priceHigh` for SSL) to detect price penetrations and closes back outside the level.
*   **Breakout Filter**: Disables sweep signals and sets `isTrendBreakoutActive = true` if the ATR-relative sweep size exceeds the maximum limit (placeholder `1.50` H4 ATR).

### 3.2 Optional Features (Tier B)
*   **Sweep Min Size Filter (`InpLiqSweepMinSizeATR`)**: 
    *   *Simplification*: The closed-candle rejection requirement naturally filters out ticks and minor penetrations that fail to hold. V1 can treat any closed-candle breach as a valid sweep, simplifying parameter management.
*   **Persistent Sweep Event History (`m_sweepEvents[]`)**: 
    *   *Simplification*: Downstream execution does not read past sweep history. The engine only needs to expose transient triggers for the *current completed M30 bar*. Storing historical sweeps can be deferred to a future logging/analytics update.

### 3.3 Deferred/Removed Features (Tier C)
*   **Sweep Classification Brackets (Minor/Medium/Major)**:
    *   *Simplification*: Rather than hardcoding arbitrary brackets (Minor $\le 0.25$ ATR, etc.), `CLiquidityEngine` will simply output the raw double value `bslSweepSizeATR`. The downstream Entry Engine can construct its own filters dynamically.
*   **Liquidity Decay & Strength Recalculation**:
    *   *Simplification*: Prohibited by the Responsibility Audit. The engine consumes pre-decayed strength coordinates from `SnrPriorityContract` and focuses solely on price action triggers.

---

## 4. Recommended Minimal V1 Scope

The recommended minimal viable architecture for `CLiquidityEngine` is a **Single-Pass Transient Sweep State Machine**:

### 4.1 Simplified Data Flow
```
[SnrPriorityContract (H4)] ──> [CLiquidityEngine (M30)] ──> [LiquidityPriorityContract (M30)]
                               (Local price caches)          (Transient sweep triggers only)
```

### 4.2 Reduced MQL5 Data Contract
The public output contract is stripped of brackets and classifications, containing only boundaries and immediate triggers:
```cpp
struct LiquidityPriorityContract
{
   // 1. Boundaries copied directly from SnrPriorityContract
   LiquidityPool  nearestBSL;
   bool           hasBSL;
   
   LiquidityPool  nearestSSL;
   bool           hasSSL;
   
   // 2. Real-Time Transient Triggers (Set on M30 bar closes)
   bool           isBSLSweptThisBar;
   double         bslSweepSizeATR;     // Raw excursion depth
   
   bool           isSSLSweptThisBar;
   double         sslSweepSizeATR;     // Raw excursion depth
   
   // 3. Breakout Filter State (Transient)
   bool           isTrendBreakoutActive; // True if sweep size exceeds InpLiqSweepMaxSizeATR
};
```

### 4.3 Reduced Class Interface (`CLiquidityEngine`)
The class interface is simplified: it includes only one upstream dependency (`CSnrPriorityEngine*`), removes historical sweep arrays, and eliminates redundant helper methods.

```cpp
class CLiquidityEngine
{
private:
   CSnrPriorityEngine*        m_priorityEngine;       // Single upstream dependency
   LiquidityPriorityContract  m_activeContract;       // Exposed output contract
   
   // Synchronous price caches for Strategy Tester safety
   double            m_cachedH4Highs[];
   double            m_cachedH4Lows[];
   double            m_cachedH4Closes[];
   int               m_maxH4Bars;
   
   double            m_cachedM30Highs[];
   double            m_cachedM30Lows[];
   double            m_cachedM30Closes[];
   int               m_maxM30Bars;
   
   // Single configuration parameter
   double            m_sweepMaxSizeATR;       // Breakout filter threshold (Placeholder)
   bool              m_enableLog;
   
   // Helper methods
   double            GetLocalH4ATR(int barIndex);
   bool              SyncPriceCaches();

public:
                     CLiquidityEngine();
                    ~CLiquidityEngine();
                    
   bool              Init(CSnrPriorityEngine* priorityEngine);
   void              Deinit();
   
   // Evaluates price action on closed M30 bar 1
   bool              Analyze();
   
   LiquidityPriorityContract GetContract() const { return m_activeContract; }
};
```

---
*End of V1 Scope Review.*
