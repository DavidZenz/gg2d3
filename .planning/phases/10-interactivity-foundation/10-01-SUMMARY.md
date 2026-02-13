---
phase: 10-interactivity-foundation
plan: 01
subsystem: interactivity
tags: [r-api, javascript, events, tooltips, pipe-functions]

dependency_graph:
  requires: []
  provides:
    - "d3_tooltip() R pipe function"
    - "d3_hover() R pipe function"
    - "window.gg2d3.tooltip JavaScript module"
    - "window.gg2d3.events JavaScript module"
  affects:
    - "Widget interactivity API"
    - "NAMESPACE exports"

tech_stack:
  added:
    - htmlwidgets::onRender() for post-render callbacks
    - D3 v7 event handlers (.on() API)
    - Singleton tooltip pattern
  patterns:
    - "Pipe-based API: gg2d3(p) |> d3_tooltip()"
    - "IIFE module pattern with window.gg2d3 namespace"
    - "Viewport-aware tooltip positioning"

key_files:
  created:
    - R/d3_tooltip.R
    - R/d3_hover.R
    - inst/htmlwidgets/modules/tooltip.js
    - inst/htmlwidgets/modules/events.js
    - man/d3_tooltip.Rd
    - man/d3_hover.Rd
  modified:
    - NAMESPACE

decisions: []

metrics:
  duration: 2
  completed: 2026-02-13T19:28Z
---

# Phase 10 Plan 01: Interactivity Foundation Summary

**One-liner:** Pipe-based R API (d3_tooltip, d3_hover) with JavaScript event/tooltip modules enabling interactive ggplot2 visualizations via D3 event handlers

## What Was Built

Created the foundational interactivity system for gg2d3 consisting of:

1. **R Pipe Functions** (Task 1):
   - `d3_tooltip()`: Configures tooltip display with field selection and custom formatters
   - `d3_hover()`: Configures hover effects with opacity dimming and highlight strokes
   - Both functions validate input, modify `widget$x$interactivity`, attach onRender callbacks
   - Exported to NAMESPACE with full roxygen2 documentation

2. **JavaScript Modules** (Task 2):
   - `tooltip.js`: Singleton tooltip div with viewport-aware positioning
     - `getOrCreate()`: Creates or returns shared tooltip element
     - `format()`: Generates HTML from data rows with field filtering
     - `show/move/hide()`: Event handlers for tooltip lifecycle
     - `position()`: Smart viewport edge detection and placement
   - `events.js`: Event attachment system for geom elements
     - `attachTooltips()`: Binds mouseover/move/out handlers to interactive elements
     - `attachHover()`: Implements dim-others-highlight-current pattern
     - Uses INTERACTIVE_SELECTORS array for geom targeting

## Architecture Pattern

**Pipe-based API pattern:**
```r
gg2d3(plot) |> d3_tooltip(fields = c("x", "y")) |> d3_hover(opacity = 0.5)
```

**R-to-JS flow:**
1. R pipe function modifies `widget$x$interactivity` structure
2. `htmlwidgets::onRender()` defers to next event loop tick
3. JavaScript checks config existence before attaching handlers
4. D3 `.selectAll()` finds geom elements via CSS selectors
5. Event handlers access bound data via `(event, d)` signature

## Key Implementation Details

**Viewport-aware tooltip positioning:**
- Detects right edge: flips to left of cursor
- Detects bottom edge: flips above cursor
- Clamps to prevent off-screen rendering
- Uses `pointer-events: none` to prevent tooltip from intercepting mouse events

**Event selector strategy:**
- Class-based selectors distinguish path types (`.geom-line`, `.geom-area`)
- Excludes non-interactive elements (`:not(.panel-bg)`)
- Covers 10 geom types: point, bar, line, area, density, smooth, ribbon, violin, text, segment

**Hover effect pattern:**
- Stores original opacity in `data-original-opacity` attribute
- Dims all siblings to config.opacity on mouseover
- Highlights hovered element to opacity 1.0
- Restores original opacity on mouseout

## Deviations from Plan

None - plan executed exactly as written.

## Testing & Verification

**Task 1 verification:**
- `pkgload::load_all()` succeeded with no syntax errors
- `roxygen2::roxygenise()` generated NAMESPACE exports
- Both `d3_tooltip` and `d3_hover` appear in NAMESPACE
- Man pages created in man/ directory

**Task 2 verification:**
- `node -c` passed for both tooltip.js and events.js
- Both modules export to `window.gg2d3` namespace
- Key links verified:
  - `d3_tooltip.R` calls `window.gg2d3.events.attachTooltips()`
  - `d3_hover.R` calls `window.gg2d3.events.attachHover()`
  - `events.js` calls `window.gg2d3.tooltip.show/move/hide()`

## Integration Notes

**Next steps for Phase 10:**
- Plan 10-02: Wire modules into main widget YAML/JS
- Plan 10-03: Add geom class names to existing renderers
- Future: Test tooltip/hover with actual rendered plots

**Breaking changes:** None - new functionality is additive.

**Backward compatibility:** Static rendering (without pipe functions) unaffected.

## Self-Check: PASSED

**Files created:**
```bash
[ -f "R/d3_tooltip.R" ] && echo "FOUND: R/d3_tooltip.R" || echo "MISSING: R/d3_tooltip.R"
[ -f "R/d3_hover.R" ] && echo "FOUND: R/d3_hover.R" || echo "MISSING: R/d3_hover.R"
[ -f "inst/htmlwidgets/modules/tooltip.js" ] && echo "FOUND: inst/htmlwidgets/modules/tooltip.js" || echo "MISSING: inst/htmlwidgets/modules/tooltip.js"
[ -f "inst/htmlwidgets/modules/events.js" ] && echo "FOUND: inst/htmlwidgets/modules/events.js" || echo "MISSING: inst/htmlwidgets/modules/events.js"
```

**Commits verified:**
```bash
git log --oneline --all | grep -q "7beab5e" && echo "FOUND: 7beab5e" || echo "MISSING: 7beab5e"
git log --oneline --all | grep -q "83666ea" && echo "FOUND: 83666ea" || echo "MISSING: 83666ea"
```
