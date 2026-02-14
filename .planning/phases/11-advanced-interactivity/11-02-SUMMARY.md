---
phase: 11-advanced-interactivity
plan: 02
subsystem: interactivity
tags: [brush, selection, d3-brush, highlighting, shiny]
dependency_graph:
  requires: [d3-events, d3-scales, d3-zoom]
  provides: [d3_brush, brush-selection, data-highlighting]
  affects: [all-geoms]
tech_stack:
  added: [d3.brush, d3.brushX, d3.brushY]
  patterns: [scale-inversion, band-filtering, opacity-highlighting]
key_files:
  created:
    - R/d3_brush.R
    - inst/htmlwidgets/modules/brush.js
    - man/d3_brush.Rd
  modified:
    - NAMESPACE
    - inst/htmlwidgets/gg2d3.yaml
decisions:
  - id: brush-end-only
    title: Fire highlighting on brush end, not during drag
    rationale: Continuous updates during drag cause performance issues
    impact: Selection highlighting only applies when user completes the drag
  - id: scale-invert-vs-band-filter
    title: Use scale.invert() for continuous, band center filtering for categorical
    rationale: Categorical scales don't have invert(); filter domain by band center position
    impact: Brush works correctly on both continuous and categorical axes
  - id: independent-facet-brushing
    title: Independent brush on each facet panel
    rationale: Users may want to select different subsets in different facets
    impact: Each panel gets its own brush overlay and highlighting
metrics:
  duration: 2m 43s
  tasks_completed: 2
  files_created: 3
  files_modified: 2
  commits: 2
  completed_date: 2026-02-14
---

# Phase 11 Plan 02: Brush Selection Summary

**One-liner:** D3 brush selection with data highlighting, scale inversion for continuous/categorical axes, and Shiny integration.

## Objective

Implemented `d3_brush()` pipe function enabling rectangular brush selection on gg2d3 plots with visual highlighting of selected data.

## What Was Built

### R/d3_brush.R
- Pipe function following d3_tooltip/d3_hover pattern
- Parameters: `direction` (xy/x/y), `on_brush` callback, `fill` color, `opacity` for dimmed elements
- Validates widget class, stores config in `widget$x$interactivity$brush`
- Uses htmlwidgets::onRender with setTimeout(0) pattern
- Calls `window.gg2d3.brush.attach(el, config, ir)` to initialize D3 behavior

### inst/htmlwidgets/modules/brush.js
- IIFE module registered on `window.gg2d3.brush` namespace
- `attach(el, config, ir)` function detects single vs. faceted plots
- `attachToPanel()` creates brush overlay per panel:
  - Reconstructs x/y scales from IR using window.gg2d3.scales.createScale()
  - Chooses d3.brush()/brushX()/brushY() based on config.direction
  - Sets brush extent to panel dimensions
  - Styles brush overlay with config.fill and opacity
- Brush end event handler:
  - Inverts pixel selection to data domain via `invertSelection()`
  - Continuous scales: `scale.invert()` → data range
  - Categorical/band scales: filter domain values whose band center falls within selection pixels
  - Highlights selected elements (opacity 1.0), dims non-selected (config.opacity)
  - Sends brush coordinates to Shiny via `Shiny.onInputChange(el.id + '_brush', bounds)`
  - Calls user `on_brush` callback if provided
- Double-click clears brush: `brushGroup.call(brush.move, null)`
- Uses `.brush` event namespace to avoid conflicts with other features
- For faceted plots: independent brush on each panel

### Integration
- Added brush.js to gg2d3.yaml after zoom.js, before geom-registry.js
- Exported d3_brush in NAMESPACE
- Generated man/d3_brush.Rd documentation

## Implementation Notes

### Scale Inversion Strategy
Continuous scales have `scale.invert()` to convert pixels back to data values. Categorical/band scales don't have invert, so we filter the domain by checking if each value's band center (position + bandwidth/2) falls within the selection pixels.

### Highlighting Implementation
Reuses INTERACTIVE_SELECTORS from events.js to target all geom elements. For each element, checks if bound data falls within brush bounds by comparing data fields (d.x, d.y) against inverted domain. Selected elements get opacity 1.0, non-selected get config.opacity (default 0.15).

### Faceted Plot Behavior
Each panel gets its own brush overlay and highlighting scope. Selection in one panel doesn't affect other panels. This allows users to select different subsets in different facets for independent exploration.

### Shiny Integration
When `HTMLWidgets.shinyMode` is true, sends brush coordinates via `Shiny.onInputChange(el.id + '_brush', {xmin, xmax, ymin, ymax})`. When brush is cleared, sends null. This enables reactive expressions in Shiny apps: `input$myplot_brush`.

### Flip Coordinate Support
Like zoom.js, brush.js respects coord_flip by swapping which data field (x vs y) corresponds to which pixel dimension when checking element selection.

## Verification Results

All verification steps passed:

1. `pkgload::load_all()` succeeds
2. `d3_brush` exported in NAMESPACE
3. `node -c inst/htmlwidgets/modules/brush.js` passes
4. `Rscript -e "pkgload::load_all(); w <- gg2d3(ggplot2::ggplot(mtcars, ggplot2::aes(mpg,wt)) + ggplot2::geom_point()) |> d3_brush(); cat('OK\n')"` outputs OK
5. Static rendering unchanged (brush overlay only appears on interaction)

## Deviations from Plan

None - plan executed exactly as written.

## Task Breakdown

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create d3_brush() R function and brush.js module | ebdad93 | R/d3_brush.R, inst/htmlwidgets/modules/brush.js, man/d3_brush.Rd, NAMESPACE |
| 2 | Wire brush.js into YAML and verify integration | 6ea6e39 | inst/htmlwidgets/gg2d3.yaml |

## Self-Check

Verifying created files exist:

```bash
[ -f "R/d3_brush.R" ] && echo "FOUND: R/d3_brush.R" || echo "MISSING: R/d3_brush.R"
[ -f "inst/htmlwidgets/modules/brush.js" ] && echo "FOUND: inst/htmlwidgets/modules/brush.js" || echo "MISSING: inst/htmlwidgets/modules/brush.js"
[ -f "man/d3_brush.Rd" ] && echo "FOUND: man/d3_brush.Rd" || echo "MISSING: man/d3_brush.Rd"
```

Verifying commits exist:

```bash
git log --oneline --all | grep -q "ebdad93" && echo "FOUND: ebdad93" || echo "MISSING: ebdad93"
git log --oneline --all | grep -q "6ea6e39" && echo "FOUND: 6ea6e39" || echo "MISSING: 6ea6e39"
```

## Self-Check: PASSED

All files created and all commits verified.
