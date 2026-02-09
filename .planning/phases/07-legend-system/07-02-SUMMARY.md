---
phase: 07-legend-system
plan: 02
subsystem: legend-rendering
status: complete
tags: [legend, d3-rendering, colorbar, discrete-legend, layout-integration]

dependency_graph:
  requires:
    - 07-01 (guide IR extraction)
    - 06-03 (layout engine with text estimation)
    - 02-01 (scale system with convertColor)
    - 01-02 (constants module with ptToPx)
  provides:
    - Legend rendering functions (discrete and colorbar)
    - Pre-render dimension estimation for layout
    - Theme-based legend styling
  affects:
    - Future: gg2d3.js main rendering pipeline (will call renderLegends)
    - Future: 07-03 (layout integration - will use estimateLegendDimensions)

tech_stack:
  added:
    - D3 symbol generators (for shape legends)
    - SVG linearGradient (for colorbars)
    - IIFE module pattern for legend namespace
  patterns:
    - Theme-based sizing (no hardcoded pixel values)
    - Pure dimension estimation (no DOM measurement)
    - Orchestrator pattern (renderLegends delegates to specific renderers)

key_files:
  created:
    - inst/htmlwidgets/modules/legend.js: "Legend rendering module (507 lines)"
  modified:
    - inst/htmlwidgets/gg2d3.yaml: "Added legend.js to module load order"

decisions:
  - id: shape-fill-vs-stroke
    title: "Filled shapes use fill, open shapes use stroke"
    rationale: "ggplot2 shape codes 0-5 are open (stroke only), 15-19 are filled"
    impact: "Legend shape rendering matches ggplot2 visual appearance"

  - id: colorbar-gradient-direction
    title: "Colorbar gradient goes bottom-to-top"
    rationale: "ggplot2 colorbars render low values at bottom, high at top"
    impact: "SVG linearGradient y1=100% to y2=0% for correct orientation"

  - id: merged-guide-aesthetics
    title: "Single guide can represent multiple aesthetics"
    rationale: "ggplot2 merges guides when guides(colour = guide_legend()) specified"
    impact: "renderDiscreteLegend checks guide.aesthetics array and combines symbols"

metrics:
  duration: 114
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  lines_added: 508
  commits: 2
  completed_date: 2026-02-09
---

# Phase 7 Plan 2: D3 Legend Renderers

**One-liner:** Legend rendering module with discrete legends (color/size/shape symbols), colorbars (SVG gradients), and pre-render dimension estimation.

## Objective

Create the D3 legend rendering module that takes guide IR specifications (from Plan 07-01) and renders them as SVG groups. Provides dimension estimation for layout engine integration.

## Summary of Changes

Created `legend.js` module with four main functions:

1. **estimateLegendDimensions(guides, theme)** - Calculates total legend dimensions before rendering using text estimation from layout module. Handles multiple guides with correct spacing.

2. **renderDiscreteLegend(svg, guide, x, y, theme)** - Renders guide_legend with:
   - Color/fill swatches (rectangles)
   - Size circles (varying radii)
   - Shape symbols (D3 symbol generators with ggplot2 shape code mapping)
   - Text labels with theme-based styling
   - Title if present

3. **renderColorbar(svg, guide, x, y, theme)** - Renders guide_colorbar with:
   - SVG linearGradient from color stops
   - Gradient rectangle (bar)
   - Tick marks at break points
   - Labels positioned proportionally by value

4. **renderLegends(svg, guides, layout, theme)** - Orchestrator that positions and renders all guides based on layout box.

**Key implementation details:**

- **Theme-driven sizing:** All dimensions derived from theme elements (legend.key.size, legend.text, legend.title) via ptToPx conversion
- **Color conversion:** All R color names converted via convertColor() from scales module
- **Text estimation:** Uses layout.estimateTextWidth/Height for pre-render sizing (no DOM measurement)
- **Shape mapping:** Maps ggplot2 shape codes (0-19) to D3 symbol types with correct fill/stroke behavior
- **Gradient direction:** Colorbar uses y1="100%" to y2="0%" for bottom-to-top gradient matching ggplot2
- **Module load order:** Positioned after layout.js (depends on text estimation) and before geom-registry.js in YAML

## Deviations from Plan

None - plan executed exactly as written.

## Key Decisions Made

1. **Shape fill vs stroke logic:** Implemented helper `isFilledShape()` to distinguish ggplot2 open shapes (0-5) from filled shapes (15-19). Open shapes render with stroke only, filled shapes use fill. This matches ggplot2's visual appearance.

2. **Colorbar gradient direction:** Used SVG linearGradient with y1="100%" (bottom) to y2="0%" (top) to match ggplot2's convention of low values at bottom, high at top.

3. **Merged guide aesthetics:** Legend renderer checks `guide.aesthetics` array to determine which visual properties to render. Supports guides that represent multiple aesthetics (e.g., colour + shape combined).

## Tasks Completed

| Task | Type | Files | Commit |
|------|------|-------|--------|
| 1. Create legend.js module | auto | inst/htmlwidgets/modules/legend.js | 7127edc |
| 2. Add legend.js to YAML | auto | inst/htmlwidgets/gg2d3.yaml | 242f331 |

## Testing Notes

Module verification completed via grep checks:
- ✓ All 4 exported functions present
- ✓ Uses ptToPx from constants (10 references)
- ✓ Uses estimateTextWidth/Height from layout (6 references)
- ✓ Uses convertColor from scales (14 references)
- ✓ YAML load order correct (legend.js after layout.js, before geom-registry.js)

Visual verification pending full integration in Plan 07-03.

## Dependencies

**Requires:**
- Plan 07-01: Guide IR extraction (provides guide objects with keys, colors, title)
- Phase 6: Layout engine (provides text estimation functions)
- Phase 2: Scale system (provides convertColor)
- Phase 1: Constants module (provides ptToPx, mmToPxRadius)

**Enables:**
- Plan 07-03: Layout integration (can now call estimateLegendDimensions)
- Plan 07-04: Main rendering integration (can now call renderLegends)

## Self-Check: PASSED

```bash
# Verify created files exist
[ -f "inst/htmlwidgets/modules/legend.js" ] && echo "FOUND: legend.js"
# FOUND: legend.js

# Verify commits exist
git log --oneline --all | grep -q "7127edc" && echo "FOUND: 7127edc"
# FOUND: 7127edc

git log --oneline --all | grep -q "242f331" && echo "FOUND: 242f331"
# FOUND: 242f331
```

All files created and commits exist as documented.

## Next Steps

Plan 07-03 will integrate legend dimension estimation into the layout engine, and Plan 07-04 will wire renderLegends() into the main gg2d3.js rendering pipeline.
