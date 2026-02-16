---
phase: 04-essential-geoms
plan: 04
subsystem: geoms
tags: [testing, visual-verification, bugfixes, r-colors, clipping]

# Dependency graph
requires:
  - phase: 04-02
    provides: Area and ribbon geom renderers
  - phase: 04-03
    provides: Segment and reference line renderers
provides:
  - R-side unit tests for all Phase 4 geoms
  - R color name conversion in reference line renderers
  - R color name handling in makeColorAccessors
  - SVG panel clipping for out-of-bounds geom elements
affects: [05-statistical-geoms]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SVG clipPath for panel bounds enforcement"
    - "R color name conversion via convertColor() in all geom renderers"

key-files:
  created:
    - tests/testthat/test-geoms-phase4.R
  modified:
    - inst/htmlwidgets/gg2d3.js
    - inst/htmlwidgets/modules/geom-registry.js
    - inst/htmlwidgets/modules/geoms/reference.js

key-decisions:
  - "Add SVG clipPath to panel group to prevent geom elements from exceeding panel bounds"
  - "Create clipped sub-group after grid lines to maintain correct z-order (grid behind data)"
  - "Use convertColor() for all R color names in reference line renderers"
  - "Try R color conversion in makeColorAccessors before falling through to colorScale"

patterns-established:
  - "All geom layers render inside gClipped (clipped to panel), grid renders outside on g"
  - "R color names (greyN) must always go through convertColor() before use in SVG"

# Metrics
duration: ~15min (including bugfix iterations from visual checkpoint)
completed: 2026-02-09
---

# Phase 4 Plan 4: Unit Tests + Visual Verification + Bugfixes Summary

**Comprehensive tests for Phase 4 geoms, visual checkpoint with 8 test cases, and 3 bugfixes from visual review**

## Performance

- **Duration:** ~15 min (including checkpoint review and bugfixes)
- **Tasks:** 2 (tests + visual checkpoint with bugfixes)
- **Files modified:** 4

## Accomplishments
- 50 R-side unit tests covering all Phase 4 geom IR extraction
- Visual verification with 8 test pairs (ggplot2 PNG vs D3 HTML)
- Fixed 3 bugs discovered during visual checkpoint:
  1. R color names (e.g., "grey50") not converted to CSS hex in reference line renderers
  2. R color names (e.g., "grey70") not handled by makeColorAccessors fill/stroke accessors
  3. Abline extending beyond panel bounds (missing SVG clip-path)
  4. Grid lines rendering on top of data (incorrect SVG z-order from clip group placement)

## Task Commits

1. **Task 1: Phase 4 geom IR extraction tests** - `fc5cbaf` (test)
2. **Bugfixes from visual checkpoint** - `2bfaf39` (fix)

## Files Created/Modified
- `tests/testthat/test-geoms-phase4.R` - 50 tests covering area, ribbon, segment, hline, vline, abline
- `inst/htmlwidgets/modules/geoms/reference.js` - Added convertColor() for R color names
- `inst/htmlwidgets/modules/geom-registry.js` - makeColorAccessors tries R color conversion
- `inst/htmlwidgets/gg2d3.js` - Added SVG clipPath for panel bounds; correct z-order

## Bugs Found and Fixed

**1. R color names invisible in SVG (reference lines)**
- Root cause: ggplot2 data rows contain R color names like "grey50" which are not valid CSS colors
- Fix: Added `convertColor()` call in reference.js for all colour reads from data rows
- Impact: All reference line colours now render correctly

**2. R color names in makeColorAccessors (ribbon fill)**
- Root cause: `isValidColor("grey70")` returns false → value falls through to colorScale → wrong Tableau10 color
- Fix: Added `convertColor()` attempt before colorScale fallback in both fillColor and strokeColor
- Impact: All geoms using makeColorAccessors now handle R color names correctly

**3. Abline extending beyond panel bounds**
- Root cause: No SVG clip-path on panel group; abline endpoints beyond domain extend visually
- Fix: Added `<clipPath>` definition and clipped sub-group `gClipped` for all data layers
- Impact: All geom elements properly clipped to panel area

**4. Grid lines on top of data (z-order regression)**
- Root cause: `gClipped` was created before grid lines, so grids rendered on top
- Fix: Moved `gClipped` creation to after grid drawing
- Impact: Correct layering: panel bg → grid → data → axes

## Self-Check: PASSED

- ✓ 133 tests pass (50 new Phase 4 + 83 existing)
- ✓ 8 visual test pairs verified by user
- ✓ All 3 bugfixes committed and deployed

---
*Phase: 04-essential-geoms*
*Completed: 2026-02-09*
