---
phase: 06-layout-engine
plan: 01
subsystem: layout-engine
tags: [layout, spatial-calculation, ir-extraction, pure-function]
dependency_graph:
  requires:
    - theme.js (theme accessor for margins, font sizes)
    - constants.js (unit conversion ptToPx)
  provides:
    - calculateLayout() for spatial allocation
    - Layout metadata in IR (tickLabels, legend.position, subtitle, caption, x2/y2)
  affects:
    - Plan 06-02 (will integrate layout engine into gg2d3.js)
    - Plan 07-* (legend rendering uses reserved space)
tech_stack:
  added: []
  patterns:
    - Pure function layout calculation (no DOM dependency)
    - Subtraction-based spatial allocation (outside-in)
    - Text dimension estimation (0.6x font size heuristic)
    - Box manipulation utilities
key_files:
  created:
    - inst/htmlwidgets/modules/layout.js (470 lines)
  modified:
    - R/as_d3_ir.R (added layout metadata extraction)
    - inst/htmlwidgets/gg2d3.yaml (added layout.js to module load order)
decisions:
  - id: estimation-based-layout
    summary: Use font-size-based text estimation instead of DOM measurement
    rationale: Layout engine must be pure function; estimation is fast and accurate enough for typical numeric labels
    alternatives: DOM-based measurement with getComputedTextLength (would require SVG container)
  - id: secondary-axis-detection
    summary: Detect secondary axes via scale.secondary.axis field, not panel_params
    rationale: panel_params always has .sec ViewScale objects; only scales with actual secondary.axis are enabled
    impact: Correctly reserves space only when secondary axes are present
  - id: legend-space-zero-default
    summary: Legend width/height default to 0 until Phase 7
    rationale: Prevents empty gaps when legend rendering doesn't exist yet
    impact: No visual changes in Phase 6; space reserved when Phase 7 provides dimensions
metrics:
  duration: 4 minutes
  tasks_completed: 2
  commits: 2
  files_created: 1
  files_modified: 2
  lines_added: 517
  completed_date: 2026-02-09
---

# Phase 6 Plan 1: Layout Engine Foundation Summary

**One-liner:** Created calculateLayout() pure function and extracted layout metadata (tickLabels, legend.position, subtitle, caption, secondary axes) into IR.

## What Was Built

### R-Side IR Extraction (Task 1)
Added layout metadata to the intermediate representation in `R/as_d3_ir.R`:

1. **Tick label strings** - Extracted from panel_params for text width estimation in JS
2. **Subtitle and caption text** - From plot labels
3. **Secondary axis detection** - Checks `scale.secondary.axis` field (not panel_params)
4. **Legend position** - From theme via `calc_element("legend.position")`
5. **Theme elements** - Added plot.subtitle and plot.caption to theme IR

All extractions wrapped in `tryCatch` for graceful error handling.

### JavaScript Layout Engine (Task 2)
Created `inst/htmlwidgets/modules/layout.js` with:

**Box manipulation utilities (pure functions):**
- `shrinkBox(box, margin)` - Inset by margin amounts
- `sliceTop/Bottom/Left/Right(box, amount)` - Slice portions from edges
- `sliceSide(box, position, width, height)` - Dispatch to slice functions

**Text estimation (no DOM dependency):**
- `estimateTextHeight(fontSizePx)` - 1.2x font size
- `estimateTextWidth(text, fontSizePx)` - 0.6x font size per character
- `estimateMaxTextWidth(labels, fontSizePx)` - Max across array

**Theme extraction helpers:**
- `getPlotMargin(theme)` - Returns {top, right, bottom, left} in px
- `getTitleSize(theme)` - Font sizes for title/subtitle/caption
- `getAxisTextSize(theme)` - Axis tick label sizes (x/y specific)
- `getAxisTitleSize(theme)` - Axis title sizes
- `getTickLength(theme)` - Tick length in px (default 3.67px)

**calculateLayout(config) - Main function:**
Subtraction-based algorithm allocating space outside-in:
1. Start with full widget dimensions
2. Subtract plot margins
3. Reserve title/subtitle area (top)
4. Reserve caption area (bottom)
5. Reserve legend space (if position != "none" and dimensions > 0)
6. Calculate axis space (tick labels + ticks + titles + gaps)
7. Panel gets remaining space (clamped to 50x50 minimum)
8. Apply coord_fixed aspect ratio constraint with centering offsets

Returns `LayoutResult` with pixel positions for:
- panel (x, y, w, h, offsetX, offsetY)
- axes (bottom, left, top, right)
- titles (title, subtitle, caption)
- axisLabels (x, y with rotation)
- legend area
- clipId for panel clipping
- secondaryAxes flags

### Integration
Updated `inst/htmlwidgets/gg2d3.yaml` to load `layout.js` after `theme.js` and before `geom-registry.js`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed secondary axis detection logic**
- **Found during:** Task 1 verification
- **Issue:** Initial implementation checked `panel_params[[1]]$x.sec` which is always a ViewScale object (never null), resulting in false positives for secondary axes
- **Fix:** Changed to check `panel_scales_x[[1]]$secondary.axis` which is only set when `sec.axis` parameter is provided to scale
- **Files modified:** R/as_d3_ir.R
- **Commit:** 5d45506
- **Impact:** Correctly detects secondary axes only when actually present; prevents reserving space for non-existent axes

No other deviations - plan executed as written.

## Key Technical Details

### IR Schema Changes
New top-level fields:
```json
{
  "subtitle": "string",
  "caption": "string",
  "axes": {
    "x": {
      "tickLabels": ["2", "3", "4", "5"]
    },
    "y": {
      "tickLabels": ["10", "15", "20", "25", "30", "35"]
    },
    "x2": {"enabled": true} | null,
    "y2": {"enabled": true} | null
  },
  "legend": {
    "position": "right" | "left" | "top" | "bottom" | "inside" | "none"
  },
  "theme": {
    "text": {
      "subtitle": {...},
      "caption": {...}
    }
  }
}
```

### LayoutResult Structure
```javascript
{
  total: {w, h},
  plotMargin: {top, right, bottom, left},
  title: {x, y, visible},
  subtitle: {x, y, visible},
  caption: {x, y, visible},
  panel: {x, y, w, h, offsetX, offsetY},
  clipId: "panel-clip-abc123",
  axes: {
    bottom: {x, y, w},
    left: {x, y, h},
    top: {x, y, w} | null,
    right: {x, y, h} | null
  },
  axisLabels: {
    x: {x, y, visible},
    y: {x, y, rotation: -90, visible}
  },
  legend: {x, y, w, h, position},
  panels: null,          // Future: facets
  strips: null,          // Future: facet strips
  secondaryAxes: {
    top: boolean,
    right: boolean
  }
}
```

### Text Estimation Accuracy
- Character width heuristic: 0.6x font size works well for sans-serif numeric labels
- Height heuristic: 1.2x font size accounts for line height
- Intentionally conservative (slight overestimation prevents clipping)

### coord_fixed Handling
When aspect ratio is specified:
1. Calculate constrained panel dimensions maintaining ratio
2. Center constrained panel in available space
3. Store offsets in `panel.offsetX` and `panel.offsetY`
4. Geom renderers apply offsets when rendering

## Verification

### R-Side Tests
```r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() +
     labs(title = "Test", subtitle = "Sub", caption = "Cap")
ir <- as_d3_ir(p)

# Verified:
# - ir$subtitle == "Sub"
# - ir$caption == "Cap"
# - ir$legend$position == "right"
# - length(ir$axes$x$tickLabels) == 4
# - length(ir$axes$y$tickLabels) == 6
# - is.null(ir$axes$x2) == TRUE (no secondary axis)
# - is.null(ir$axes$y2) == TRUE
```

### JavaScript Module Structure
```bash
# Verified:
# - calculateLayout function exists (3 occurrences)
# - shrinkBox utility exists (3 occurrences)
# - estimateTextWidth utility exists (3 occurrences)
# - window.gg2d3.layout namespace export (1 occurrence)
# - layout.js in YAML load order after theme.js
```

## Performance Notes

- Layout calculation is O(1) - constant time regardless of data size
- No DOM access means no reflow/repaint during calculation
- Text estimation adds negligible overhead vs. DOM measurement

## Next Steps (Plan 06-02)

1. Integrate `calculateLayout()` into `gg2d3.js` draw function
2. Replace hardcoded padding calculations with layout result
3. Update all rendering functions to consume LayoutResult positions
4. Deprecate `calculatePadding()` in theme.js

## Self-Check: PASSED

### Created files verified:
```bash
[ -f "inst/htmlwidgets/modules/layout.js" ] && echo "FOUND: layout.js"
```
✓ FOUND: layout.js

### Commits verified:
```bash
git log --oneline --all | grep -q "5d45506" && echo "FOUND: 5d45506"
git log --oneline --all | grep -q "553c93e" && echo "FOUND: 553c93e"
```
✓ FOUND: 5d45506 (R IR metadata extraction)
✓ FOUND: 553c93e (layout.js module creation)

### Key IR fields verified:
```r
# All fields present in IR output:
# - subtitle, caption, axes.x.tickLabels, axes.y.tickLabels
# - legend.position, axes.x2, axes.y2
```
✓ All layout metadata fields present

### Module exports verified:
```bash
grep -q "window.gg2d3.layout" inst/htmlwidgets/modules/layout.js
```
✓ Namespace export confirmed

### YAML integration verified:
```bash
grep -q "layout.js" inst/htmlwidgets/gg2d3.yaml
```
✓ Module load order correct

All verification checks passed. Layout engine foundation is complete and ready for integration.
