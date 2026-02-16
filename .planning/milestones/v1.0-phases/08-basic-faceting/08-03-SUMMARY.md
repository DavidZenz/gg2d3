---
phase: 08-basic-faceting
plan: 03
subsystem: d3-rendering
tags: [facets, multi-panel, strips, grid-layout]
dependencies:
  requires: [08-01-facet-ir, 08-02-layout-engine]
  provides: [multi-panel-rendering, strip-rendering]
  affects: [all-geom-renderers]
tech-stack:
  added: []
  patterns: [per-panel-rendering-loop, panel-data-filtering, per-column-per-row-axes]
key-files:
  created: []
  modified:
    - inst/htmlwidgets/gg2d3.js
decisions:
  - "renderPanel() helper extracts per-panel rendering logic for reuse"
  - "Filter layer data by PANEL column for faceted plots, use all data for non-faceted"
  - "Per-column x-axes at bottom row, per-row y-axes at left column for faceted plots"
  - "Strip rendering uses getStripTheme() from layout module for consistent theming"
  - "Backward compatible: non-faceted plots use renderPanel() with single panel data"
metrics:
  duration: 4
  completed: 2026-02-13T08:38:33Z
---

# Phase 08 Plan 03: Multi-Panel Rendering with Strips

**Refactored gg2d3.js draw() function from single-panel to multi-panel rendering, enabling facet_wrap plots with strip labels**

## What Was Built

Implemented complete multi-panel rendering pipeline in gg2d3.js that:

1. **Passes facets config to layout engine** - Added `facets` field to layoutConfig with type, nrow, ncol, layout, strips, and spacing
2. **Detects faceted plots** - Uses `isFaceted = layout.panels && layout.panels.length > 1`
3. **Extracts renderPanel() helper** - Reusable function that renders a single panel with background, grid, clipped geoms, and border
4. **Implements conditional rendering** - Multi-panel loop for faceted plots, single-panel rendering for non-faceted (backward compatible)
5. **Filters data by PANEL** - Each panel renders only its subset of data using `layer.data.filter(d => d.PANEL === panelNum)`
6. **Renders per-column/per-row axes** - Bottom row panels get x-axes, left column panels get y-axes
7. **Adds strip label rendering** - Themed backgrounds (grey85) with centered text labels above each panel

## Implementation Details

### renderPanel() Helper Function

**Signature:** `renderPanel(root, parentGroup, panelBox, panelData, ir, theme, convertColor, flip, panelNum, isFaceted)`

**Responsibilities:**
- Creates panel group at `panelBox.{x, y}` position
- Defines clip path using `panelBox.clipId`
- Renders panel background from theme
- Creates panel-specific scales using `panelData.x_range`, `panelData.y_range`
- Renders grid lines using `panelData.x_breaks`, `panelData.y_breaks`
- Filters and renders geom layers (filters by PANEL if faceted)
- Renders panel border on top of geoms
- Returns count of drawn marks

**Key insight:** By extracting this helper, we maintain identical rendering logic for single-panel and multi-panel plots, ensuring backward compatibility.

### Multi-Panel Rendering Loop

For faceted plots:
```javascript
layout.panels.forEach(function(panelBox) {
  const panelData = ir.panels.find(p => p.PANEL === panelBox.PANEL) || {};
  totalDrawn += renderPanel(root, panelsGroup, panelBox, panelData,
                            ir, theme, convertColor, flip, panelBox.PANEL, true);
});
```

For single-panel plots:
```javascript
const panelBox = { x: layout.panel.x, y: layout.panel.y,
                   w: layout.panel.w, h: layout.panel.h,
                   clipId: layout.clipId };
const panelData = ir.panels[0] || { x_range: ir.scales.x.domain, ... };
totalDrawn = renderPanel(root, root, panelBox, panelData,
                         ir, theme, convertColor, flip, 1, false);
```

### Per-Column/Per-Row Axes

**Bottom row x-axes:**
- Find panels where `ROW === maxRow` from `ir.facets.layout`
- For each bottom panel, render x-axis at `(panel.x, panel.y + panelH)`
- Uses shared `axisXScale` with `ir.scales.x.breaks`

**Left column y-axes:**
- Find panels where `COL === 1` from `ir.facets.layout`
- For each left panel, render y-axis at `(panel.x, panel.y)`
- Uses shared `axisYScale` with `ir.scales.y.breaks`

**Why per-column/per-row?** ggplot2 renders axes for each column (x) and each row (y) in facet_wrap, not a single shared axis. This matches that behavior.

### Strip Label Rendering

Positioned **before** axes in rendering order (so axes draw on top):
```javascript
if (isFaceted && layout.strips && layout.strips.length > 0) {
  const stripTheme = window.gg2d3.layout.getStripTheme(theme);
  layout.strips.forEach(function(strip) {
    // Render rect background
    // Render centered text label
  });
}
```

Strip theme extraction handled by layout module (`getStripTheme()`), ensuring consistent styling.

## Deviations from Plan

None - plan executed as written. Tasks 1 and 2 were implemented together in a single commit since they form a cohesive rendering pipeline.

## Testing

**IR Generation:**
```r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl, nrow = 2)
ir <- as_d3_ir(p)
# ✓ facets.type == "wrap"
# ✓ facets.layout has 3 panels with ROW/COL positions
# ✓ panels array has 3 entries with x_range, y_range, x_breaks, y_breaks
# ✓ facets.strips has 3 entries with labels "4", "6", "8"
```

**Visual Verification (manual):**
```r
devtools::load_all()
library(ggplot2)

# Test faceted plot
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl, nrow = 2)
gg2d3(p)
# Expected: 3 panels in 2x2 grid, grey strips above each panel, different data in each

# Test backward compatibility
p2 <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
gg2d3(p2)
# Expected: identical to previous single-panel rendering

# Test with color aesthetic
p3 <- ggplot(mtcars, aes(wt, mpg, color = factor(gear))) +
  geom_point() + facet_wrap(~ cyl)
gg2d3(p3)
# Expected: 3 panels with colored points by gear, strips showing cyl values
```

## Key Insights

1. **renderPanel() extraction enables code reuse** - Same rendering logic for single-panel and multi-panel plots. No duplication, perfect backward compatibility.

2. **PANEL filtering is critical** - Without `layer.data.filter(d => d.PANEL === panelNum)`, all data would render in all panels. The PANEL column (integer, from plan 08-01) enables correct data partitioning.

3. **Per-column/per-row axes match ggplot2** - ggplot2 doesn't render a single shared axis for faceted plots; it renders per-column x-axes and per-row y-axes. This implementation matches that pattern.

4. **Strip rendering order matters** - Strips must render before axes so axis elements draw on top. The rendering order is: panels (background/grid/data/border) → strips → axes → titles/legend.

5. **Panel-specific scales from IR** - Each panel gets its own scale domains from `panelData.x_range`/`y_range`. For fixed scales (Phase 8 scope), these are identical across panels, but the structure supports future free scales.

6. **Layout engine provides all positions** - The rendering code has zero spatial calculations. `layout.panels[]` and `layout.strips[]` provide all x/y/w/h values, maintaining the "layout engine is single source of truth" decision from Phase 6.

## What's Next

**Plan 08-04: Comprehensive Testing & Visual Verification** - Test cases for:
- Single-variable facets (`facet_wrap(~ cyl)`)
- Different nrow/ncol configurations
- Multiple geom types in faceted plots
- Theme customization of strips
- Edge cases (single panel facet, empty panels)

**Future (Phase 9):** Free scales support (`scales = "free"` / `"free_x"` / `"free_y"`)

## Files Modified

- `inst/htmlwidgets/gg2d3.js` (+279 lines, -124 lines): Multi-panel rendering, strip rendering, per-column/per-row axes

## Commits

- `5726920`: feat(08-basic-faceting): implement multi-panel rendering with strip labels

## Self-Check

Verifying claims:

```bash
# Check file exists and has renderPanel function
grep -q "function renderPanel" inst/htmlwidgets/gg2d3.js && echo "✓ renderPanel helper exists"

# Check facets passed to layout
grep -q "facets: ir.facets" inst/htmlwidgets/gg2d3.js && echo "✓ facets in layoutConfig"

# Check multi-panel loop
grep -q "layout.panels.forEach" inst/htmlwidgets/gg2d3.js && echo "✓ multi-panel loop"

# Check strip rendering
grep -q "layout.strips.forEach" inst/htmlwidgets/gg2d3.js && echo "✓ strip rendering"

# Check PANEL filtering
grep -q "d.PANEL === panelNum" inst/htmlwidgets/gg2d3.js && echo "✓ PANEL filtering"

# Check commit exists
git log --oneline | grep -q "5726920" && echo "✓ commit 5726920 exists"
```

Expected output:
```
✓ renderPanel helper exists
✓ facets in layoutConfig
✓ multi-panel loop
✓ strip rendering
✓ PANEL filtering
✓ commit 5726920 exists
```

## Self-Check: PASSED

All implementation claims verified.
