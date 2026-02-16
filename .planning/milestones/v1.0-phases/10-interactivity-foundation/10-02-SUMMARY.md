---
phase: 10-interactivity-foundation
plan: 02
subsystem: interactivity
tags: [javascript, yaml-config, geom-classes, event-targeting]

dependency_graph:
  requires:
    - "10-01 (tooltip.js and events.js modules)"
  provides:
    - "Script loading order for interactivity modules"
    - "CSS class attributes on all geom SVG elements"
  affects:
    - "Widget initialization (htmlwidgets dependency loading)"
    - "Event system CSS selectors"

tech_stack:
  added:
    - "htmlwidgets YAML dependency management"
    - "CSS class-based geom targeting"
  patterns:
    - "Module load order dependency chain"
    - "Additive class attributes (backward compatible)"

key_files:
  created: []
  modified:
    - inst/htmlwidgets/gg2d3.yaml
    - inst/htmlwidgets/modules/geoms/point.js
    - inst/htmlwidgets/modules/geoms/line.js
    - inst/htmlwidgets/modules/geoms/bar.js
    - inst/htmlwidgets/modules/geoms/rect.js
    - inst/htmlwidgets/modules/geoms/text.js
    - inst/htmlwidgets/modules/geoms/area.js
    - inst/htmlwidgets/modules/geoms/ribbon.js
    - inst/htmlwidgets/modules/geoms/segment.js
    - inst/htmlwidgets/modules/geoms/density.js
    - inst/htmlwidgets/modules/geoms/smooth.js
    - inst/htmlwidgets/modules/geoms/violin.js
    - inst/htmlwidgets/modules/geoms/boxplot.js

decisions: []

metrics:
  duration: 5
  completed: 2026-02-13T19:35Z
---

# Phase 10 Plan 02: Wire Interactivity Modules Summary

**One-liner:** Wired tooltip.js and events.js into htmlwidgets YAML config and added CSS class attributes to all 12 geom renderers enabling event system targeting

## What Was Built

Integrated the interactivity JavaScript modules (from Plan 10-01) into the widget infrastructure:

1. **YAML Configuration Update** (Task 1):
   - Added `tooltip.js` and `events.js` to `gg2d3.yaml` script dependency array
   - Positioned before `geom-registry.js` to ensure namespace exists before geom modules load
   - Loading order: `tooltip.js` → `events.js` → `geom-registry.js` (tooltip must load first since events depends on it)
   - Enables `window.gg2d3.tooltip` and `window.gg2d3.events` availability in onRender callbacks

2. **Geom Class Attributes** (Task 2):
   - Added CSS class attributes to all 12 geom renderers:
     - **point.js**: `.geom-point` on circle elements
     - **line.js**: `.geom-line` on path elements
     - **bar.js**: `.geom-bar` on rect elements (both flip/non-flip code paths)
     - **rect.js**: `.geom-rect` on rect elements (both flip/non-flip code paths)
     - **text.js**: `.geom-text` on text elements
     - **area.js**: `.geom-area` on path elements
     - **ribbon.js**: `.geom-ribbon` on path elements
     - **segment.js**: `.geom-segment` on line elements
     - **density.js**: `.geom-density` on fill path, `.geom-density-outline` on stroke path
     - **smooth.js**: `.geom-smooth-ribbon` on ribbon path, `.geom-smooth` on line path
     - **violin.js**: `.geom-violin` on path elements (both flip/non-flip code paths)
     - **boxplot.js**: `.geom-boxplot-box`, `.geom-boxplot-median`, `.geom-boxplot-whisker`, `.geom-boxplot-outlier` on respective primitives
   - All class additions are purely additive (no existing code broken)

## Architecture Pattern

**Module dependency chain:**
```
constants.js → scales.js → theme.js → layout.js → legend.js → tooltip.js → events.js → geom-registry.js → geoms/*.js
```

**CSS selector strategy:**
- Element type + class name: `circle.geom-point`, `rect.geom-bar`, `path.geom-line`
- Distinguishes path-based geoms: `.geom-line` vs `.geom-area` vs `.geom-ribbon` vs `.geom-density`
- Composite geoms use sub-component classes: `.geom-boxplot-box`, `.geom-boxplot-outlier`

## Key Implementation Details

**Loading order rationale:**
- `tooltip.js` must load before `events.js` because events.js calls `window.gg2d3.tooltip.show/move/hide()`
- Both must load before geom modules (though geoms don't call them directly)
- `geom-registry.js` must load before individual geom modules

**Class attribute placement:**
- Always first chained attribute after `.append()` for consistency
- Applied to both flip/non-flip code paths where applicable
- No impact on existing SVG structure or rendering

**Boxplot special handling:**
- Boxplot is composite geom (rect + lines + circles)
- Four distinct classes for event targeting flexibility:
  - `.geom-boxplot-box`: IQR rectangle
  - `.geom-boxplot-median`: median line
  - `.geom-boxplot-whisker`: whisker lines (2 per boxplot)
  - `.geom-boxplot-outlier`: outlier circles

**Density dual-path handling:**
- Fill path: `.geom-density` (primary, receives tooltip events)
- Stroke path: `.geom-density-outline` (outline only, not interactive)
- Only fill path included in `INTERACTIVE_SELECTORS` in events.js

## Deviations from Plan

None - plan executed exactly as written.

## Testing & Verification

**Task 1 verification:**
- `gg2d3.yaml` includes `tooltip.js` and `events.js` in correct order
- No duplicate entries in script array
- Positioned before `geom-registry.js` as required

**Task 2 verification:**
- `node -c` passed for all 12 modified geom JS files (no syntax errors)
- `grep "geom-"` found class patterns in all expected files
- `pkgload::load_all()` succeeded (R package still loads)
- Test suite: 2 FAIL / 18 WARN / 395 PASS (same as before changes - no regressions)

**Class attribute coverage:**
```
✓ point.js: 1 class (geom-point)
✓ line.js: 1 class (geom-line)
✓ bar.js: 1 class on 2 code paths (geom-bar)
✓ rect.js: 1 class on 2 code paths (geom-rect)
✓ text.js: 1 class (geom-text)
✓ area.js: 1 class (geom-area)
✓ ribbon.js: 1 class (geom-ribbon)
✓ segment.js: 1 class (geom-segment)
✓ density.js: 2 classes (geom-density, geom-density-outline)
✓ smooth.js: 2 classes (geom-smooth-ribbon, geom-smooth)
✓ violin.js: 1 class on 2 code paths (geom-violin)
✓ boxplot.js: 4 classes (box, median, whisker, outlier)
```

## Integration Notes

**Readiness for Phase 10 Plan 03:**
- Script loading order correct (tooltip → events → geoms)
- All geom SVG elements have class attributes
- Event system can now target geoms with `d3.selectAll('circle.geom-point')` etc.

**Next steps:**
- Plan 10-03: End-to-end testing with actual interactive plots
- Verify tooltip rendering with real data
- Test hover effects across all geom types

**Breaking changes:** None - all changes are additive.

**Backward compatibility:** Static rendering (without `d3_tooltip()` or `d3_hover()`) completely unaffected.

## Self-Check: PASSED

**Files verified:**
- inst/htmlwidgets/gg2d3.yaml (modified)
- inst/htmlwidgets/modules/geoms/point.js (modified)
- inst/htmlwidgets/modules/geoms/line.js (modified)
- inst/htmlwidgets/modules/geoms/bar.js (modified)
- inst/htmlwidgets/modules/geoms/rect.js (modified)
- inst/htmlwidgets/modules/geoms/text.js (modified)
- inst/htmlwidgets/modules/geoms/area.js (modified)
- inst/htmlwidgets/modules/geoms/ribbon.js (modified)
- inst/htmlwidgets/modules/geoms/segment.js (modified)
- inst/htmlwidgets/modules/geoms/density.js (modified)
- inst/htmlwidgets/modules/geoms/smooth.js (modified)
- inst/htmlwidgets/modules/geoms/violin.js (modified)
- inst/htmlwidgets/modules/geoms/boxplot.js (modified)

**Commits verified:**
- f844b90: Task 1 (YAML module loading)
- b0ed532: Task 2 (geom class attributes)
