---
phase: 33-single-panel-renderer-and-interactivity
plan: 02
subsystem: htmlwidgets
tags: [geom_sf, d3, brush, interactivity]
requires:
  - phase: 33-single-panel-renderer-and-interactivity
    provides: path.geom-sf renderer contract and centroid attrs
provides:
  - Brush selector support for path.geom-sf
  - Centroid-only sf brush hit testing
  - Sanitized brush callback rows
affects: [geom_sf, brush, callbacks, shiny]
tech-stack:
  added: []
  patterns: [centroid point-in-rect hit testing for sf paths]
key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/brush.js
    - tests/testthat/test-sf-interactivity.R
key-decisions:
  - "Sf brushing uses data-cx/data-cy centroid attrs only; generic path getBBox remains only for non-sf paths."
  - "Brush callback payloads remove underscore-prefixed renderer-private fields."
patterns-established:
  - "Sf-specific path logic branches before generic path handling when semantics differ."
requirements-completed: [SFINTR-02]
duration: 3min
completed: 2026-05-20
---

# Phase 33-02: Sf Brush Selection Summary

**`geom_sf` paths can now participate in brush selection by projected centroid without exposing renderer internals.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-20T13:44:24Z
- **Completed:** 2026-05-20T13:47:18Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `path.geom-sf` to brush targets.
- Added centroid-only sf path hit testing using `data-cx` and `data-cy`.
- Preserved generic `getBBox()` path behavior for non-sf path geoms.
- Sanitized selected row data before `on_brush` callbacks see it.

## Task Commits

Each task was committed atomically:

1. **Task 1: Include sf paths in brush targets** - `912ff72` (feat)
2. **Task 2: Use centroid attrs for sf brush hit testing** - `4925b65` (feat)
3. **Task 3: Sanitize sf rows in brush callback payloads** - `0afdd22` (fix)

## Files Created/Modified

- `inst/htmlwidgets/modules/brush.js` - Adds sf brush selector, centroid hit testing, and selected-data sanitization.
- `tests/testthat/test-sf-interactivity.R` - Adds source-contract tests for sf brush selectors, centroid branch ordering, and callback sanitization.

## Decisions Made

- Kept the explicit Phase 33 centroid-only rule. No polygon-overlap logic and no sf bbox fallback were added.
- Reused the same generic underscore-field hiding approach established in tooltip code.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` - passed
- Confirmed `path.geom-sf` branch reads `data-cx`/`data-cy` before generic path `getBBox()`.
- Confirmed no polygon-overlap or sf bbox fallback was added.

## Self-Check: PASSED

## Next Phase Readiness

Wave 3 can suppress unsupported sf zoom without needing further brush changes.

---
*Phase: 33-single-panel-renderer-and-interactivity*
*Completed: 2026-05-20*
