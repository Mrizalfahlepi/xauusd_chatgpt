# SNR VISUAL SPECIFICATION

**Version**: 1.0  
**Sprint**: 3.0  
**File**: `src/tests/TestSnr.mq5`

---

## 1. SNR Level Bands

Levels are rendered as filled rectangles on the chart, color-coded by **score tier**.

### Score Tier Color Map

| Tier | Score Range | Color | MQL5 Constant | Hex | Visual Meaning |
|------|------------|-------|----------------|-----|----------------|
| **Elite** | 80–100 | Gold | `clrGold` | `#FFD700` | Highest-quality confluence zone |
| **Strong** | 60–79 | Dodger Blue | `clrDodgerBlue` | `#1E90FF` | High-confidence level |
| **Standard** | 40–59 | Medium Purple | `clrMediumPurple` | `#9370DB` | Moderate-quality level |
| **Weak** | 0–39 | Dim Gray | `clrDimGray` | `#696969` | Low-confidence level |

### Level Band Properties

| Property | Value |
|----------|-------|
| Object Type | `OBJ_RECTANGLE` |
| Fill | Yes (solid) |
| Layer | Background (`BACK = true`) |
| Start X | `level.creationTime` |
| End X | Current bar time |
| Top Y | `level.priceHigh` |
| Bottom Y | `level.priceLow` |
| Tooltip | ID, direction, score, freshness, constituents, flags |

### Score Label

| Property | Value |
|----------|-------|
| Object Type | `OBJ_TEXT` |
| Font | Arial Bold, 9pt |
| Color | Same as tier color |
| Position | Right edge of band, at `priceMid` |
| Anchor | `ANCHOR_LEFT` |

---

## 2. Neutral Node Zones

Deactivated zones where **Supply and Demand overlap**.

| Property | Value |
|----------|-------|
| Fill | **No** (outline only) |
| Border Color | Red (`clrRed` / `#FF0000`) |
| Fill Color | Dark Gray (`clrDarkGray` / `#A9A9A9`) |
| Line Style | Dash-Dot (`STYLE_DASHDOT`) |
| Line Width | 2 |
| Tag Label | `"NEUTRAL"` in red at top-left |

---

## 3. Nested Zone Labels

Zones within zones are labeled at the **top-left corner** of the level band.

| Zone Type | Label Text | Color | MQL5 Constant | Hex |
|-----------|-----------|-------|----------------|-----|
| Core (inner) | `CORE` | Aqua | `clrAqua` | `#00FFFF` |
| Macro (outer) | `MACRO` | Wheat | `clrWheat` | `#F5DEB3` |

| Property | Value |
|----------|-------|
| Object Type | `OBJ_TEXT` |
| Font | Arial Bold, 8pt |
| Anchor | `ANCHOR_LEFT_LOWER` |

---

## 4. Liquidity Pools

Dashed outline boxes representing **stop-order clusters** above swing highs or below swing lows.

### Pool Colors

| Pool Type | Status | Color | MQL5 Constant | Hex | Label |
|-----------|--------|-------|----------------|-----|-------|
| Buy Stops | Active | Deep Sky Blue | `clrDeepSkyBlue` | `#00BFFF` | `BSL` |
| Sell Stops | Active | Orange Red | `clrOrangeRed` | `#FF4500` | `SSL` |
| Any | Swept | Gray | `clrGray` | `#808080` | `xBSL` / `xSSL` |

### Pool Rectangle Properties

| Property | Value |
|----------|-------|
| Object Type | `OBJ_RECTANGLE` |
| Fill | **No** (outline only) |
| Line Style | Dashed (`STYLE_DASH`); Dotted if swept (`STYLE_DOT`) |
| Line Width | 1 |
| Layer | Foreground (`BACK = false`) |
| Tooltip | Pool ID, type, strength, swept status |

### Pool Label Properties

| Property | Value |
|----------|-------|
| Object Type | `OBJ_TEXT` |
| Font | Arial Bold, 8pt |
| Position | Right edge of pool, at `priceHigh` |
| Anchor | `ANCHOR_LEFT_LOWER` (buy) / `ANCHOR_LEFT_UPPER` (sell) |

---

## 5. Info Dashboard Panel

Fixed-position overlay panel in the **top-left corner** of the chart.

### Panel Layout

| Property | Value |
|----------|-------|
| Position | X=10, Y=30 |
| Size | 320 × 420 px |
| Background | Black (`clrBlack`) with partial transparency |
| Border | Dim Gray (`clrDimGray`), flat |
| Font | Consolas (monospace for alignment) |

### Panel Sections

```
╔══════════════════════════════════╗
║  === SNR ENGINE v1.0 ===        ║  Gold, 12pt
║  ─────────────────────────────  ║
║  Total Levels:    XX            ║  White, 10pt
║  Active Support:  XX            ║  LimeGreen, 10pt
║  Active Resist:   XX            ║  Coral, 10pt
║  ─────────────────────────────  ║
║  Elite (80+):     X             ║  Gold, 10pt
║  Strong (60-79):  X             ║  DodgerBlue, 10pt
║  Standard (40-59):X             ║  MediumPurple, 10pt
║  Weak (0-39):     X             ║  DimGray, 10pt
║  ─────────────────────────────  ║
║  Best Support:  XX.X @ XXXX.XX  ║  LimeGreen, 9pt
║  Best Resist:   XX.X @ XXXX.XX  ║  Coral, 9pt
║  ─────────────────────────────  ║
║  Fresh Levels:    X             ║  Aqua, 9pt
║  BOS Origins:     X             ║  Yellow, 9pt
║  Neutral Nodes:   X             ║  Red, 9pt
║  Core Zones:      X             ║  Aqua, 9pt
║  Macro Zones:     X             ║  Wheat, 9pt
║  ─────────────────────────────  ║
║  Liquidity Pools: XX            ║  White, 10pt
║    Buy Stops:     X             ║  DeepSkyBlue, 9pt
║    Sell Stops:    X             ║  OrangeRed, 9pt
║    Swept:         X             ║  Gray, 9pt
║  ─────────────────────────────  ║
║  Bars:300 | TF:H4 | 2026.06.13 ║  DarkGray, 8pt
╚══════════════════════════════════╝
```

---

## 6. Object Naming Convention

All chart objects use the prefix `SNR_` to enable batch cleanup.

| Object Category | Name Pattern | Example |
|----------------|-------------|---------|
| Level band | `SNR_LVL_{id}` | `SNR_LVL_0` |
| Score label | `SNR_SCR_{id}` | `SNR_SCR_0` |
| Tag label | `SNR_TAG_{id}` | `SNR_TAG_0` |
| Pool box | `SNR_POOL_{id}` | `SNR_POOL_0` |
| Pool label | `SNR_PLBL_{id}` | `SNR_PLBL_0` |
| Panel items | `SNR_PNL_{code}` | `SNR_PNL_BG` |

---

## 7. Log Output Format

Each H4 bar generates a full log dump with:

1. **Summary block** — Level/pool counts
2. **Per-level detail** — Score breakdown (5 components), price range, freshness, flags
3. **Per-pool detail** — Type, price range, strength, swept status
4. **Cluster statistics** — Width min/max/avg, constituent range, average score, fresh %, neutral count
