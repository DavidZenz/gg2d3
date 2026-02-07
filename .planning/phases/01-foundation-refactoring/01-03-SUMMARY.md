---
phase: 01-foundation-refactoring
plan: 03
subsystem: rendering-engine
tags: [architecture, refactoring, geoms]
completed: 2026-02-07
duration: 2.43
dependencies:
  requires: ["01-01", "01-02"]
  provides: ["geom-registry", "geom-renderers"]
  affects: ["rendering-pipeline", "geom-extensibility"]
tech_stack:
  added: ["geom-registry-pattern"]
  patterns: ["IIFE-self-registration", "dispatch-pattern"]
key_files:
  created:
    - inst/htmlwidgets/modules/geom-registry.js
    - inst/htmlwidgets/modules/geoms/point.js
    - inst/htmlwidgets/modules/geoms/line.js
    - inst/htmlwidgets/modules/geoms/bar.js
    - inst/htmlwidgets/modules/geoms/rect.js
    - inst/htmlwidgets/modules/geoms/text.js
  modified: []
decisions:
  - id: geom-dispatch-pattern
    title: Use registry-based dispatch for geom rendering
    rationale: Enables adding new geoms without modifying core code; each geom is self-contained
    impact: All future geoms follow this pattern; main draw() function will be simplified
  - id: makeColorAccessors-utility
    title: Centralize color accessor creation in registry module
    rationale: All geoms need identical color/fill/opacity logic; avoid duplication
    impact: Consistent color handling across all geoms; easier to maintain
  - id: geom-self-registration
    title: Each geom renderer self-registers on load
    rationale: No central registration list to maintain; adding geom = create file + load in YAML
    impact: More maintainable; clear separation of concerns
metrics:
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  lines_added: 683
  commits: 2
---

# Phase 01 Plan 03: Geom Renderer Extraction Summary

**One-liner:** Registry-based geom rendering system with 5 self-registering renderer modules covering all 8 geom types

## Objective Achieved

Extracted all geom rendering logic from the monolithic draw() function into individual renderer files with a central registry for dispatch. This architectural change enables adding new geoms without modifying core rendering code.

## What Was Built

### 1. Geom Registry Module (`geom-registry.js`)
- **Central dispatch system**: `register()`, `render()`, `has()`, `list()` API
- **makeColorAccessors() utility**: Creates consistent color/fill/opacity accessors for all geoms
- **Geom Renderer Interface**: JSDoc-documented contract for all renderer functions
- **Namespace**: `window.gg2d3.geomRegistry`

### 2. Five Geom Renderer Modules

Each follows IIFE pattern with self-registration:

**point.js**
- Renders circles with mm->px size conversion
- Handles ggplot2 fill=NA behavior (solid points)
- Color/fill/stroke aesthetics with proper defaults
- **Registers**: `point`

**line.js**
- Renders paths with grouping support
- Sorts by x for `geom_line` but not `geom_path`
- Linewidth mm->px conversion
- **Registers**: `line`, `path`

**bar.js**
- Renders rectangles with automatic baseline calculation
- Supports stacked bars (ymin/ymax)
- ggplot2 colour=NA default (no outline)
- Categorical and continuous x scales
- **Registers**: `bar`, `col`

**rect.js**
- Renders rectangles using xmin/xmax/ymin/ymax aesthetics
- Bandwidth support for categorical scales
- **Registers**: `rect`, `tile`

**text.js**
- Renders text elements with label aesthetic
- Centered positioning (middle baseline, text-anchor)
- Color and opacity support
- **Registers**: `text`

### Coverage

**8 geom types** covered by **5 renderer files**:
- point → point.js
- line, path → line.js
- bar, col → bar.js
- rect, tile → rect.js
- text → text.js

## Technical Details

### Renderer Interface Contract

```javascript
/**
 * @param {Object} layer - Layer from IR (data, aes, params, geom)
 * @param {d3.Selection} g - D3 plot group
 * @param {Function} xScale - D3 x scale
 * @param {Function} yScale - D3 y scale
 * @param {Object} options - Rendering options (colorScale, plotWidth, plotHeight)
 * @returns {number} Number of marks drawn
 */
function renderGeom(layer, g, xScale, yScale, options) { ... }
```

### Color Accessor Pattern

All renderers use `makeColorAccessors()` utility:

```javascript
const { strokeColor, fillColor, opacity } =
  window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
```

This ensures consistent handling of:
- Direct color values (hex, named)
- Color scale mapping
- Static parameters (params.colour, params.fill)
- Aesthetic mappings (aes.color, aes.fill, aes.alpha)
- R color conversion (grey0-grey100)

### Self-Registration Pattern

Each geom file ends with:

```javascript
window.gg2d3.geomRegistry.register(['line', 'path'], renderLine);
```

No central registration list needed; adding a new geom requires:
1. Create renderer file
2. Call `register()` at end
3. Add to `gg2d3.yaml` dependencies

## Verification

All rendering logic is **identical** to original `gg2d3.js` lines 436-662:
- Point: lines 436-493
- Line/Path: lines 495-529
- Bar/Col: lines 531-599
- Rect: lines 601-634
- Text: lines 636-661

Verified by side-by-side code comparison.

## Deviations from Plan

None - plan executed exactly as written.

## Dependencies & Integration

**Requires:**
- 01-01: Constants module (mmToPxRadius, mmToPxLinewidth, helpers.*)
- 01-02: Theme module (namespace pattern example)
- scales.js: convertColor function

**Provides:**
- `window.gg2d3.geomRegistry.register(names, renderer)`
- `window.gg2d3.geomRegistry.render(layer, g, xScale, yScale, options)`
- `window.gg2d3.geomRegistry.has(name)`
- `window.gg2d3.geomRegistry.list()`
- `window.gg2d3.geomRegistry.makeColorAccessors(layer, options)`

**Affects:**
- Next step (01-05): Main gg2d3.js will be refactored to use this registry
- Future geom additions: Simple one-file-per-geom pattern established

## Next Phase Readiness

**Ready for:**
- 01-05: Refactor main gg2d3.js to use geom registry
- Future: Add new geoms (polygon, segment, ribbon, etc.) as standalone modules

**Blockers:** None

**Technical Debt:** None - clean architecture with clear interfaces

## Self-Check: PASSED

**Files created:**
```
FOUND: inst/htmlwidgets/modules/geom-registry.js
FOUND: inst/htmlwidgets/modules/geoms/point.js
FOUND: inst/htmlwidgets/modules/geoms/line.js
FOUND: inst/htmlwidgets/modules/geoms/bar.js
FOUND: inst/htmlwidgets/modules/geoms/rect.js
FOUND: inst/htmlwidgets/modules/geoms/text.js
```

**Commits:**
```
FOUND: 5a6348d
FOUND: cfb714d
```

All claims verified. Plan complete.
