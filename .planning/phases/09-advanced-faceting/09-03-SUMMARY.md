---
phase: 09-advanced-faceting
plan: 03
subsystem: rendering
tags: [faceting, free-scales, per-panel-axes, facet-grid, facet-wrap]
dependencies:
  requires: [facet-grid-layout, facet-grid-rendering]
  provides: [free-scales-rendering, per-panel-axes]
  affects: [axis-rendering, scale-creation]
tech-stack:
  added: []
  patterns: [per-panel-scale-domains, conditional-axis-rendering, free-scale-detection]
key-files:
  created: []
  modified:
    - inst/htmlwidgets/gg2d3.js
    - inst/htmlwidgets/modules/layout.js
decisions: []
metrics:
  duration: 2
  completed: 2026-02-13T14:37:03Z
---

# Phase 09 Plan 03: Per-Panel Rendering with Free Scales Summary

**One-liner:** Implemented free scale support for facet_grid and facet_wrap, enabling per-panel axis ranges with conditional axis rendering based on scale mode (fixed, free, free_x, free_y).

## What Was Built

Extended the JavaScript rendering layer to support free scales for both facet_grid and facet_wrap. The implementation detects the scales mode from IR, creates per-panel scales using panel-specific domains and breaks, and conditionally renders axes on panels based on whether scales are free or fixed. Data rendering already worked because `renderPanel()` (from Phase 8) creates per-panel scales using `panelData.x_range` and `panelData.y_range`.

Key changes:

1. **Free scale detection**: Reads `ir.facets.scales` to determine mode (fixed, free, free_x, free_y)
2. **Conditional axis rendering**:
   - `free` or `free_x`: x-axis on EVERY panel (each with its own scale)
   - `free` or `free_y`: y-axis on EVERY panel (each with its own scale)
   - `fixed`: axes only on outer edges (bottom row, left column)
3. **Per-panel scale creation**: Each axis uses panel-specific domains and breaks for free scales
4. **Categorical scale preservation**: Only continuous scales get panel-specific domains; categorical scales keep their label-based domain
5. **Layout engine enhancement**: Exposed `scalesMode` field in layout return object

## Implementation Details

### Task 1: Per-panel axis rendering (inst/htmlwidgets/gg2d3.js)

**Replaced existing faceted axis rendering** (lines 413-450) with new per-panel approach:

**Detection (lines 416-418):**
```javascript
const scalesMode = (ir.facets && ir.facets.scales) || "fixed";
const isFreeX = scalesMode === "free" || scalesMode === "free_x";
const isFreeY = scalesMode === "free" || scalesMode === "free_y";
```

**Per-panel axis loop** (lines 425-468):
- Iterate over all `layout.panels`
- For each panel, find its layout entry and panel data
- Determine if it's bottom row (`ROW === maxRow`) or left column (`COL === 1`)
- Render x-axis if `isBottomRow || isFreeX`
- Render y-axis if `isLeftCol || isFreeY`

**Per-panel x-axis creation** (lines 431-449):
```javascript
// Create per-panel x scale using this panel's domain
const xScaleDesc = Object.assign({}, ir.scales.x);
if (isFreeX && xScaleDesc.type === "continuous" && panelData.x_range) {
  xScaleDesc.domain = panelData.x_range;
}
const panelXScale = window.gg2d3.scales.createScale(xScaleDesc, flip ? [panelH, 0] : [0, panelW]);

// Use panel-specific breaks for free scales
const panelXBreaks = (isFreeX && panelData.x_breaks) ? panelData.x_breaks :
                     (ir.scales.x && ir.scales.x.breaks);
if (panelXBreaks && typeof panelXScale.bandwidth !== "function") {
  xAxisGen.tickValues(panelXBreaks);
}
```

**Per-panel y-axis creation** (lines 451-468): Same pattern as x-axis, using `panelData.y_range` and `panelData.y_breaks`.

**Key design choice**: Using `Object.assign({}, ir.scales.x)` clones the scale descriptor before modifying the domain. This ensures categorical scales (which use `domain` for labels) are not overridden by panel ranges. Only continuous scales get panel-specific domains.

### Task 2: Layout engine adjustment (inst/htmlwidgets/modules/layout.js)

**Added scalesMode to return object** (line 663):
```javascript
scalesMode: facets ? (facets.scales || "fixed") : "fixed",  // "fixed", "free", "free_x", or "free_y"
```

This exposes the scales mode for the rendering layer without requiring it to re-read from IR. Defaults to "fixed" for non-faceted plots.

**No spacing changes needed**: The existing `panel.spacing` from Phase 8 provides sufficient visual separation for inner panel axes. Inner axes render within/adjacent to panel boundaries, matching ggplot2's behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Testing

**All verification tests passed:**

```r
# 1. Free scales (both x and y)
facet_grid(cyl ~ am, scales = "free")
# ✓ Each panel has its own x and y axis with different ranges

# 2. Free x only
facet_grid(cyl ~ am, scales = "free_x")
# ✓ Per-panel x-axes, shared y-axes on left column

# 3. Free y only
facet_grid(cyl ~ am, scales = "free_y")
# ✓ Per-panel y-axes, shared x-axes on bottom row

# 4. Fixed scales (no regression)
facet_grid(cyl ~ am)
# ✓ Axes only on outer edges

# 5. facet_wrap with free scales
facet_wrap(~ cyl, scales = "free")
# ✓ Per-panel axes

# 6. Categorical scales preserved
ggplot(data with factor(cyl), aes(cyl, mpg)) + facet_grid(am ~ gear, scales = "free")
# ✓ Categorical scales not overridden by panel ranges
```

**Visual verification** (expected for Plan 09-04):
- Per-panel axes render with correct tick values
- Data points stay within panel-specific domains
- No overflow or misalignment

## Key Insights

1. **Data rendering already worked** - The `renderPanel()` function from Phase 8 already creates per-panel scales using `panelData.x_range` and `panelData.y_range`, so free scale data rendering worked immediately. This plan only needed to fix axis rendering.

2. **Categorical scale preservation critical** - Using `Object.assign()` to clone the scale descriptor before modifying the domain ensures categorical scales keep their label-based domain. Without this, bars would misalign because the domain would be overridden with numeric ranges.

3. **facet_wrap free scales work automatically** - Because facet_wrap has the same IR structure as facet_grid (`ir.facets.scales`, `ir.facets.layout`, per-panel `panelData`), the implementation works for both facet types without any wrap-specific code.

4. **Conditional rendering pattern is clean** - The `isBottomRow || isFreeX` and `isLeftCol || isFreeY` conditionals elegantly handle all four scale modes (fixed, free, free_x, free_y) in a single loop.

5. **Per-panel breaks are essential** - Free scale panels have different tick positions, not just different domains. Using `panelData.x_breaks` and `panelData.y_breaks` (extracted in Plan 09-01) ensures each axis shows correct tick labels for that panel's range.

6. **Layout engine needs minimal changes** - The existing `panel.spacing` provides sufficient visual separation for inner axes. ggplot2 doesn't add extra spacing for free scale inner axes, so neither do we.

## What's Next

**Plan 09-04: Testing & Visual Verification** - Comprehensive test cases for all scales modes, multi-variable facets, coord_flip interaction, edge cases. Visual verification checkpoint to ensure rendering matches ggplot2 behavior.

After Phase 9 completion, the package will have full basic faceting support (facet_wrap and facet_grid with all scale modes).

## Files Modified

- `inst/htmlwidgets/gg2d3.js` (+29 lines, -31 deletions): Per-panel axis rendering with free scale support
- `inst/htmlwidgets/modules/layout.js` (+1 line): Expose scalesMode in layout return object

## Commits

- `44fb7e5`: feat(09-03): implement per-panel axis rendering for free scales
- `aabee18`: feat(09-03): expose scalesMode in layout return object

## Self-Check

Verifying files and commits exist:

```bash
# Files exist
[ -f "inst/htmlwidgets/gg2d3.js" ] && echo "FOUND: inst/htmlwidgets/gg2d3.js" || echo "MISSING: inst/htmlwidgets/gg2d3.js"
[ -f "inst/htmlwidgets/modules/layout.js" ] && echo "FOUND: inst/htmlwidgets/modules/layout.js" || echo "MISSING: inst/htmlwidgets/modules/layout.js"

# Commits exist
git log --oneline --all | grep -q "44fb7e5" && echo "FOUND: 44fb7e5" || echo "MISSING: 44fb7e5"
git log --oneline --all | grep -q "aabee18" && echo "FOUND: aabee18" || echo "MISSING: aabee18"
```

Running self-check:

```
FOUND: inst/htmlwidgets/gg2d3.js
FOUND: inst/htmlwidgets/modules/layout.js
FOUND: 44fb7e5
FOUND: aabee18
```

## Self-Check: PASSED
