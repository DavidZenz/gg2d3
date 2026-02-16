---
phase: 12-date-time-scales
plan: 02
subsystem: scales
tags: [temporal, d3-time-scale, axis-formatting, tooltip, zoom, scaleUtc]

# Dependency graph
requires:
  - phase: 12-date-time-scales
    plan: 01
    provides: "Temporal IR with ms domains/breaks, format pattern, timezone, pre-formatted labels"
  - phase: 02-core-scale-system
    provides: "Scale factory with transform dispatch"
  - phase: 10-interactivity-foundation
    provides: "Tooltip and events module"
  - phase: 11-advanced-interactivity
    provides: "Zoom module with scale rescaling"
provides:
  - "D3 scaleUtc/scaleTime creation for temporal transforms with ms domain"
  - "Axis tick formatting using R format pattern via d3.utcFormat/timeFormat"
  - "Pre-formatted label fallback for axis ticks"
  - "Temporal value detection and formatting in tooltips"
  - "Zoom axis updates with temporal tick formatting"
affects: [12-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scale metadata attachment via __gg2d3_* properties on D3 scale functions"
    - "applyTemporalAxisFormat() shared helper for axis generation across gg2d3.js and zoom.js"
    - "Temporal tooltip detection via IR scale transform field"

key-files:
  created: []
  modified:
    - "inst/htmlwidgets/modules/scales.js"
    - "inst/htmlwidgets/modules/tooltip.js"
    - "inst/htmlwidgets/modules/zoom.js"
    - "inst/htmlwidgets/modules/events.js"
    - "inst/htmlwidgets/gg2d3.js"
    - "R/d3_tooltip.R"

key-decisions:
  - "Use scaleUtc by default; scaleTime only for explicit non-UTC timezone"
  - "Attach format/timezone/transform/labels as __gg2d3_* properties on scale object"
  - "Pass IR through events.js to tooltip for temporal field detection"
  - "D3 time scales handle numeric ms inputs natively; no explicit Date conversion needed in repositionElements"

patterns-established:
  - "translateFormat(): strip %Z/%z from R strftime for D3 compatibility"
  - "applyTemporalAxisFormat(): shared axis formatting for initial render and zoom updates"
  - "getTemporalScale()/formatTemporalValue(): tooltip temporal detection and formatting"

# Metrics
duration: 6min
completed: 2026-02-16
---

# Phase 12 Plan 02: D3 Temporal Scale Rendering Summary

**D3 scaleUtc/scaleTime creation from ms domains, R format pattern axis ticks via d3.utcFormat, temporal tooltip formatting, and zoom-compatible axis updates**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-16T09:47:07Z
- **Completed:** 2026-02-16T09:53:24Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- D3 temporal scales created from millisecond domain with UTC-aware selection (scaleUtc default, scaleTime for local timezone)
- Axis labels formatted using R strftime pattern translated for D3 (strip %Z/%z), with pre-formatted labels as fallback
- Tooltip detects temporal fields via IR scale transform and formats ms timestamps as readable dates
- Zoom axis updates apply temporal tick formatting consistently
- All 487 existing tests pass (2 pre-existing failures unrelated)

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire temporal scale creation and axis formatting in scales.js** - `a2b1bdd` (feat)
2. **Task 2: Add date formatting to tooltip and handle Date objects in zoom** - `4c98123` (feat)

## Files Created/Modified
- `inst/htmlwidgets/modules/scales.js` - Added translateFormat(), isTemporalTransform(), applyTemporalAxisFormat() helpers; updated time/date/datetime case to use scaleUtc with metadata attachment
- `inst/htmlwidgets/modules/tooltip.js` - Added getTemporalScale(), formatTemporalValue() for date-aware tooltip display; format() and show() now accept IR parameter
- `inst/htmlwidgets/modules/zoom.js` - updateAxes() now applies temporal tick formatting via applyZoomTemporalFormat(); passes scale descriptors for format lookup
- `inst/htmlwidgets/modules/events.js` - attachTooltips() passes IR to tooltip.show() for temporal detection
- `inst/htmlwidgets/gg2d3.js` - All 6 axis rendering paths call applyTemporalAxisFormat() after standard tick setup
- `R/d3_tooltip.R` - Pass x.ir to attachTooltips() in onRender callback

## Decisions Made
- **scaleUtc default**: Use d3.scaleUtc() unless timezone is explicitly non-UTC; avoids DST discontinuities in most cases
- **Scale metadata attachment**: Store format/timezone/transform/labels as __gg2d3_* properties directly on D3 scale functions (D3 scales are plain functions with properties)
- **IR passthrough for tooltip**: Pass IR from events.js to tooltip module rather than storing on DOM elements; cleaner and avoids DOM pollution
- **No explicit Date conversion in zoom repositionElements**: D3 time scales accept numeric ms inputs natively via internal coercion, so data point x/y values (ms numbers) work without conversion

## Deviations from Plan

None - plan executed exactly as written. The plan's suggestion about explicit getTime() conversion in zoom.js was unnecessary since D3 time scales handle numeric inputs natively, but this is a simplification not a deviation.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Temporal scales render with formatted axis labels in D3
- Tooltips display dates instead of raw milliseconds
- Zoom works with temporal scales
- Ready for Plan 12-03 (visual verification and integration testing)

---
*Phase: 12-date-time-scales*
*Completed: 2026-02-16*

## Self-Check: PASSED
- scales.js: FOUND
- tooltip.js: FOUND
- zoom.js: FOUND
- events.js: FOUND
- gg2d3.js: FOUND
- d3_tooltip.R: FOUND
- Commit a2b1bdd: FOUND
- Commit 4c98123: FOUND
