---
phase: 11-advanced-interactivity
plan: 04
subsystem: interactivity
tags: [testing, visual-verification, bug-fixes, zoom, brush, hover, composition]
dependency_graph:
  requires:
    - 11-01 (zoom module)
    - 11-02 (brush module)
    - 11-03 (crosstalk module)
  provides:
    - Unit tests for all Phase 11 features
    - Visual verification of zoom, brush, and feature composition
    - Bug fixes for zoom, brush, and hover interactions
  affects:
    - zoom.js (major rewrite: axes update, zoom filter, brush clearing)
    - brush.js (major rewrite: pixel-position highlighting, 1D selection format)
    - events.js (hover respects brush state)
    - gg2d3.js (axis classes for zoom targeting)
tech_stack:
  patterns:
    - Pixel-position element matching (not data-domain comparison)
    - Selection format normalization (1D/2D to pixelRect)
    - Feature state coordination via data attributes (data-brush-active)
    - Zoom filter for event isolation (wheel vs drag-pan)
    - Module cross-references (__gg2d3_brush on panel node)
key_files:
  created:
    - tests/testthat/test-zoom-brush.R (42 tests)
    - tests/testthat/test-crosstalk.R (8 tests)
  modified:
    - inst/htmlwidgets/modules/zoom.js (major rewrite)
    - inst/htmlwidgets/modules/brush.js (major rewrite)
    - inst/htmlwidgets/modules/events.js (hover brush-awareness)
    - inst/htmlwidgets/gg2d3.js (axis classes)
decisions:
  - id: pixel-position-highlighting
    title: Use pixel-position checking for brush highlight instead of data-domain comparison
    rationale: Data-domain comparison fails for categorical scales (ggplot_build stores numeric positions but scale domain has string labels)
    impact: Brush highlighting works for all scale types without data format concerns
  - id: brush-behind-data
    title: Insert brush group before clipped data group in DOM
    rationale: Data elements on top receive tooltip/hover events; brush overlay behind data still captures brush gestures via pointer capture
    impact: Tooltip and hover coexist with brush without event blocking
  - id: hover-respects-brush
    title: Skip hover dimming when brush selection is active
    rationale: Hover's dim-all-others behavior overwrites brush's selected/unselected opacity state
    impact: Brush highlighting stays stable while tooltips still show on hover
  - id: zoom-clears-brush
    title: Clear brush selection when zoom starts
    rationale: Brush selection rectangle becomes stale/misaligned after data repositions during zoom
    impact: Clean state transitions between zoom and brush modes
  - id: zoom-filter-data-elements
    title: Zoom drag-pan only from panel background, wheel zoom from anywhere
    rationale: Without filter, clicking data points for tooltip/hover would start unwanted pan gestures
    impact: Clean separation of zoom pan, tooltip/hover, and brush events
  - id: axes-group-classes
    title: Tag axes with .axes-group, .axis-bottom, .axis-left classes
    rationale: Zoom needs to find and update existing axes; original code used generic .axis class
    impact: Zoom can find and call D3 axis generators on correct groups with theme reapplication
metrics:
  duration: ~180 minutes (including 3 visual verification rounds)
  tasks_completed: 2
  files_created: 2
  files_modified: 4
  lines_added: ~600
  commits: 2
  completed_date: 2026-02-16
---

# Phase 11 Plan 04: Testing + Visual Verification Summary

**One-liner:** Comprehensive unit testing and iterative visual verification with 3 rounds of bug fixes for zoom, brush, and feature composition.

## What Was Built

### Unit Tests (Task 1)

Created 50 unit tests across two test files:

**tests/testthat/test-zoom-brush.R (42 tests):**
- d3_zoom(): input validation, default config, custom parameters, pipe composition, class preservation
- d3_brush(): input validation, defaults, direction modes, custom fill/opacity, pipe composition
- Full composition: gg2d3(p) |> d3_zoom() |> d3_brush() |> d3_tooltip() |> d3_hover()

**tests/testthat/test-crosstalk.R (8 tests):**
- SharedData detection in gg2d3() function
- Correct key and group extraction
- Crosstalk HTML dependency attachment
- Backward compatibility (non-SharedData data)

### Visual Verification Bug Fixes (Task 2)

Three rounds of visual verification uncovered and fixed critical interactivity bugs:

**Round 1 — Zoom broken, brushX broken, categorical brush broken:**

1. **Zoom not working:** Original zoom.js inserted overlay rect as `:first-child`, hidden behind panel background. Fix: Apply zoom directly to panel group via `panelGroup.call(zoom)`.

2. **brushX highlighting broken:** `d3.brushX()` returns `[x0, x1]` (1D), but code assumed `[[x0,y0],[x1,y1]]` (2D). Fix: `normalizeSelection()` converts all formats to `{px0, py0, px1, py1}`.

3. **Categorical brush not highlighting:** Data values are numeric positions but `invertSelection` produced string labels — comparison always failed. Fix: Switch from data-domain comparison to pixel-position checking using SVG element attributes directly.

**Round 2 — Zoom creates duplicate axes, unwanted panning:**

4. **Duplicate axes on zoom:** `redrawAxesAndGrid` selected `.axis-x, .axis-y` but actual axes had class `"axis"` — originals never removed, duplicates added. Fix: Tagged axes in gg2d3.js with `.axes-group`, `.axis-bottom`, `.axis-left`; zoom.js updates them in-place with D3 axis generators.

5. **Graph moves without clicking:** Zoom captured mousedown on data elements, triggering unwanted pan when user clicked points for tooltip. Fix: Zoom filter allows wheel from anywhere but drag-pan only from panel background rect.

**Round 3 — Hover breaks brush highlighting:**

6. **Hover overwrites brush state:** Hover's "dim all others" reset brush's "dim non-selected" opacity. Fix: Hover checks `data-brush-active` attribute on panel; skips dimming when brush is active.

7. **Brush + zoom composition:** Brush rectangle became stale after zoom reposition. Fix: Zoom handler calls `clearBrush()` which triggers brush's end event to restore opacities.

## Technical Details

### Pixel-Position Highlighting (brush.js)

Instead of comparing data values against inverted scale domains (which breaks for categorical scales), the brush now checks SVG element positions directly:

- **circle**: `cx, cy` point-in-rect
- **rect**: overlap check (`x+w > sel.x0 && x < sel.x1`)
- **path**: bounding box center in rect
- **text**: `x, y` point-in-rect
- **line**: midpoint or endpoint in rect

### Feature State Coordination

The three modules (zoom, brush, hover) coordinate via:

- `data-brush-active` attribute on panel group (set by brush, read by hover)
- `__gg2d3_brush` property on panel DOM node (stores brush behavior/group reference, read by zoom for clearing)
- D3 event namespacing (`.tooltip`, `.hover`, `.zoom`, `.brush`) prevents handler clobbering

### Zoom Filter

```javascript
zoom.filter(function(event) {
  if (event.type === 'wheel') return true;  // wheel zoom anywhere
  return event.target === bgRect;            // pan only from background
});
```

## Deviations from Plan

- Plan specified creating test HTML files in working directory; tests saved to `test_output/11-04_checkpoint/` per project convention
- Three visual verification rounds required instead of one (expected for browser interactivity)
- Bug fixes required significant rewrites of zoom.js and brush.js beyond what the plan anticipated

## Commits

| Hash | Message |
|------|---------|
| 052531e | test(11-04): add unit tests for zoom, brush, and crosstalk |
| 8023def | fix(11-04): resolve zoom, brush, and hover interaction bugs |

## Key Files Changed

| File | Change | Purpose |
|------|--------|---------|
| tests/testthat/test-zoom-brush.R | Created (42 tests) | Unit tests for zoom and brush pipe functions |
| tests/testthat/test-crosstalk.R | Created (8 tests) | Unit tests for crosstalk SharedData integration |
| inst/htmlwidgets/modules/zoom.js | Major rewrite | Axes update, zoom filter, brush clearing |
| inst/htmlwidgets/modules/brush.js | Major rewrite | Pixel-position highlighting, 1D selection format |
| inst/htmlwidgets/modules/events.js | Modified | Hover respects brush state |
| inst/htmlwidgets/gg2d3.js | Modified | Axis classes for zoom targeting |

## Visual Verification Results

All 5 scenarios approved by user:

1. **Zoom** — Wheel zooms with axis update, drag-pan from background, tooltip on hover, double-click reset
2. **Brush** — Selection rect, highlight/dim, tooltip works alongside brush, double-click clears
3. **Brush X** — Horizontal band selection with tooltip
4. **All features** — Zoom + brush + tooltip + hover coexist; zoom clears brush
5. **Brush bars** — Categorical bar chart brush with tooltip and hover

## Self-Check: PASSED

All tests pass (487 pass, 2 pre-existing Phase 5 warnings).
All visual verification scenarios approved.
