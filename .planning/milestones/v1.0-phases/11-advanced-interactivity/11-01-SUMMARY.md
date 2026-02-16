---
phase: 11-advanced-interactivity
plan: 01
subsystem: interactivity
tags: [zoom, pan, d3-behavior, scale-rescaling]
dependency_graph:
  requires:
    - 10-01 (tooltip module pattern)
    - 10-02 (events module pattern)
    - scales.js (createScale function)
  provides:
    - d3_zoom() R pipe function
    - window.gg2d3.zoom namespace
    - zoom.js module with d3.zoom() behavior
  affects:
    - All gg2d3 plots (optional interactivity layer)
tech_stack:
  added:
    - d3.zoom() API
    - d3.zoomIdentity
    - transform.rescaleX/Y methods
  patterns:
    - Scale rescaling approach (not SVG transform)
    - Synchronized zoom for faceted plots
    - Element repositioning by geom type
    - Axis and grid redrawing on zoom
key_files:
  created:
    - R/d3_zoom.R (75 lines)
    - inst/htmlwidgets/modules/zoom.js (506 lines)
    - man/d3_zoom.Rd (auto-generated)
  modified:
    - inst/htmlwidgets/gg2d3.yaml (added zoom.js to load order)
    - NAMESPACE (exported d3_zoom)
decisions:
  - id: scale-rescale-not-transform
    title: Use scale rescaling instead of SVG transform for zoom
    rationale: SVG transform would scale stroke widths and other properties; rescaling scales and repositioning elements preserves visual fidelity
    impact: More complex implementation but maintains pixel-perfect rendering
  - id: synchronized-facet-zoom
    title: Synchronized zoom across all facet panels
    rationale: Users expect coherent exploration across facets; independent zoom would be confusing
    impact: All panels zoom together when any panel is zoomed
  - id: geom-specific-repositioning
    title: Geom-specific element repositioning logic
    rationale: Different geom types store position data differently (cx/cy vs x/y vs d attribute)
    impact: Each geom type has dedicated repositioning code in zoom.js
  - id: no-zoom-out-restriction
    title: Minimum zoom scale of 1.0 (no zoom out)
    rationale: Zooming out beyond original view would show empty space; not useful for data exploration
    impact: scale_extent minimum must be >= 1.0
metrics:
  duration: 2 minutes
  tasks_completed: 2
  files_created: 3
  files_modified: 2
  lines_added: 642
  commits: 2
  completed_date: 2026-02-14
---

# Phase 11 Plan 01: Zoom and Pan Implementation Summary

**One-liner:** Interactive zoom/pan using d3.zoom() with scale rescaling for pixel-perfect fidelity during exploration.

## What Was Built

Implemented the `d3_zoom()` pipe function and `zoom.js` module to enable interactive zoom and pan on gg2d3 plots. The implementation uses D3's `d3.zoom()` behavior with a scale rescaling approach that repositions data elements and redraws axes/grids while maintaining visual fidelity.

### R Layer (R/d3_zoom.R)

Created `d3_zoom()` function following the established pattern from `d3_tooltip()` and `d3_hover()`:

- **Parameters:**
  - `scale_extent`: Numeric vector [min, max] for zoom scale factors (default 1x to 8x)
  - `direction`: Control which axes zoom ("both", "x", "y")
- **Validation:** Checks widget class, validates scale_extent range (minimum >= 1.0)
- **Config storage:** Stores settings in `widget$x$interactivity$zoom`
- **onRender callback:** Calls `window.gg2d3.zoom.attach(el, config, ir)` after SVG render

### JavaScript Layer (inst/htmlwidgets/modules/zoom.js)

Implemented comprehensive zoom module (506 lines) with support for both single-panel and faceted plots:

**Core Features:**

1. **Zoom overlay:** Invisible rect captures pointer events, applies `d3.zoom()` behavior
2. **Scale rescaling:** Uses `transform.rescaleX/Y(originalScale)` to get new scales on zoom
3. **Element repositioning:** Geom-specific logic updates element positions/dimensions:
   - `circle.geom-point`: Update `cx`, `cy`
   - `rect.geom-bar`: Update `x`, `y`, `width`, `height` (handles vertical/horizontal bars)
   - `rect.geom-rect`: Update rect bounds
   - `text.geom-text`: Update `x`, `y`
   - `line.geom-segment`: Update `x1`, `y1`, `x2`, `y2`
   - Path geoms: Regenerate `d` attribute using new scales (line, area, density, smooth, ribbon, violin)
   - Boxplot elements: Update box, whiskers, median, outliers
4. **Axis/grid redrawing:** Removes and redraws axes and grid lines with new scale domains
5. **Double-click reset:** Transitions back to `d3.zoomIdentity` over 750ms
6. **Faceted plot support:** Synchronized zoom across all panels

**Directional zoom:** Respects `direction` parameter to zoom only x, only y, or both axes.

**Theme integration:** Applies theme styling to redrawn axes and grid lines.

### Integration

Added `zoom.js` to `gg2d3.yaml` module load order after `events.js` and before `geom-registry.js`. This ensures scales.js and theme.js dependencies are loaded first.

## Technical Implementation Details

### Scale Rescaling Approach

**Why not use SVG transform?** Applying `transform="scale(...)"` to the clipped group would scale all attributes including stroke widths, making lines thicker/thinner during zoom. Instead:

1. Store original scales created from IR
2. On zoom event, use `transform.rescaleX/Y(originalScale)` to get new scales
3. Reposition each element using new scales and bound data
4. Redraw axes and grid with new scales

This preserves visual properties (linewidths, point sizes) while zooming data coordinates.

### Geom Repositioning Strategy

Each geom type has different position data structures:

- **Point-like geoms:** Single `x`, `y` coordinates → update `cx`, `cy` or `x`, `y`
- **Rect-like geoms:** Bounds as `xmin/xmax`, `ymin/ymax` → recalculate `x`, `y`, `width`, `height`
- **Path geoms:** Array of points → regenerate `d` attribute using `d3.line()` or `d3.area()`
- **Line geoms:** Two endpoints → update `x1`, `y1`, `x2`, `y2`

The module handles `coord_flip` by swapping which scale maps to which visual axis.

### Faceted Plot Synchronization

For plots with multiple panels:

1. Create zoom overlay on each panel independently
2. On zoom event in any panel, update all panels with same transform
3. Synchronize other zoom instances by calling `zoom.transform` on their overlays
4. Double-click on any panel resets all panels

This maintains coherent exploration across facets.

## Deviations from Plan

None - plan executed exactly as written.

## Testing

Verified:

1. `pkgload::load_all()` succeeds with no errors
2. `d3_zoom` exported in NAMESPACE
3. `node -c zoom.js` passes JavaScript syntax check
4. `gg2d3(p) |> d3_zoom()` creates widget successfully
5. Static rendering (without `d3_zoom()`) unchanged

## Key Files Changed

| File | Change | Purpose |
|------|--------|---------|
| R/d3_zoom.R | Created (75 lines) | R pipe function with parameter validation |
| inst/htmlwidgets/modules/zoom.js | Created (506 lines) | D3 zoom behavior implementation |
| inst/htmlwidgets/gg2d3.yaml | Modified (+1 line) | Added zoom.js to module load order |
| man/d3_zoom.Rd | Created | roxygen2-generated documentation |
| NAMESPACE | Modified | Exported d3_zoom |

## Commits

| Hash | Message |
|------|---------|
| 7639d84 | feat(11-01): add d3_zoom() R pipe function and zoom.js module |
| eb29783 | feat(11-01): wire zoom.js into YAML module load order |

## Integration Points

**Upstream dependencies:**
- scales.js: `createScale()` for reconstructing scales from IR
- theme.js: `createTheme()`, `drawGrid()` for axis/grid styling
- events.js: Pattern for event namespacing (`.zoom` namespace prevents conflicts)

**Downstream usage:**
- Can be combined with `d3_tooltip()` and `d3_hover()` via pipe chaining
- All geom types support zoom (point, line, bar, rect, text, segment, area, ribbon, density, smooth, boxplot, violin)

## Known Limitations

1. **No visual verification checkpoint:** This is an autonomous plan; visual verification will occur in Plan 11-04 (Testing + Visual Verification)
2. **Faceted plots with free scales:** Current implementation applies same zoom transform to all panels; free scales may need panel-specific transforms in future
3. **Legend not repositioned:** Legends are static; if data range changes significantly with zoom, legend may no longer reflect visible data

## Next Steps

Plan 11-02 will implement brush selection for subsetting data interactively, complementing zoom for data exploration.

## Self-Check: PASSED

Verified all created files exist:
```bash
[ -f "R/d3_zoom.R" ] && echo "FOUND: R/d3_zoom.R"
[ -f "inst/htmlwidgets/modules/zoom.js" ] && echo "FOUND: inst/htmlwidgets/modules/zoom.js"
[ -f "man/d3_zoom.Rd" ] && echo "FOUND: man/d3_zoom.Rd"
```

Verified commits exist:
```bash
git log --oneline --all | grep -q "7639d84" && echo "FOUND: 7639d84"
git log --oneline --all | grep -q "eb29783" && echo "FOUND: eb29783"
```

All files and commits verified.
