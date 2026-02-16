---
phase: 12-date-time-scales
plan: 03
subsystem: testing
tags: [temporal, date, datetime, posixct, unit-tests, visual-tests, milliseconds]

# Dependency graph
requires:
  - phase: 12-date-time-scales
    plan: 01
    provides: "Temporal scale IR extraction (domain/breaks in ms, format, timezone)"
  - phase: 12-date-time-scales
    plan: 02
    provides: "D3 temporal scale rendering (scaleUtc, axis formatting, tooltip, zoom)"
provides:
  - "Comprehensive R-side temporal scale test coverage (10 test cases, 29 assertions)"
  - "Visual verification HTML for temporal scale rendering"
  - "Bug fix: layer data values now converted to milliseconds"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Temporal data column conversion after ggplot_build strips Date/POSIXct class"

key-files:
  created:
    - "tests/testthat/test-date-scales.R"
  modified:
    - "R/as_d3_ir.R"

key-decisions:
  - "Fix layer data ms conversion inline as Rule 1 bug fix (ggplot_build strips Date class)"
  - "Visual test uses fixed seed for reproducible output"

patterns-established:
  - "Temporal data conversion uses scale trans_name to identify columns needing ms multiply"

# Metrics
duration: 4min
completed: 2026-02-16
---

# Phase 12 Plan 03: Temporal Scale Testing Summary

**10 unit tests verifying Date/POSIXct IR extraction plus bug fix for layer data ms conversion and visual HTML output**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-16T09:55:41Z
- **Completed:** 2026-02-16T09:59:35Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created test-date-scales.R with 10 test cases covering Date/POSIXct scale IR, ms conversion, format extraction, timezone, y-axis dates, coord_flip, geom_line, geom_col, pre-formatted labels, and non-temporal regression
- Fixed critical bug: ggplot_build strips Date/POSIXct class from data columns, leaving plain numeric (days/seconds) while domain/breaks were in ms -- data and scale were in different units
- Generated visual test HTML (test_output/visual_test_date_scales.html) with date line+point plot including tooltip
- All 515 existing tests pass (2 pre-existing failures in geoms-phase5 unrelated to changes)

## Task Commits

Each task was committed atomically:

1. **Task 1: Unit tests + data ms conversion bug fix** - `6c2fc0a` (feat)
2. **Task 2: Visual test HTML generation** - No separate commit (visual test included in Task 1 test file; HTML output is in .gitignore)

## Files Created/Modified
- `tests/testthat/test-date-scales.R` - 10 test cases for temporal scale IR extraction plus visual test
- `R/as_d3_ir.R` - Added temporal data column conversion (x/y/xmin/xmax/xend/ymin/ymax/yend) to ms before to_rows() serialization

## Decisions Made
- **Layer data ms conversion as Rule 1 fix**: ggplot_build converts Date/POSIXct to plain numeric (days/seconds since epoch) before to_rows() sees it. The inherits() check in to_rows() never triggers. Fix: use scale trans_name to identify temporal axes and multiply data columns by 86400000 (date) or 1000 (time) before serialization.
- **Fixed seed for visual tests**: Using set.seed(42) ensures reproducible visual output across runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Layer data not converted to milliseconds**
- **Found during:** Task 1 (unit test creation)
- **Issue:** ggplot_build strips Date/POSIXct class from data columns, leaving plain numeric values in days (Date) or seconds (POSIXct). Domain and breaks were converted to ms by get_scale_info(), but data values were not, causing scale/data mismatch.
- **Fix:** Added temporal data conversion block using scale trans_name to multiply x-axis columns (x, xmin, xmax, xend, xintercept) and y-axis columns (y, ymin, ymax, yend, yintercept) by the appropriate factor before to_rows().
- **Files modified:** R/as_d3_ir.R
- **Verification:** All 29 tests pass including data value > 1e12 assertions
- **Committed in:** 6c2fc0a (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Essential fix for correct D3 rendering. Data must be in same units as domain/breaks for scale mapping to work.

## Issues Encountered
None beyond the auto-fixed bug above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 12 (Date/Time Scales) is now complete with all 3 plans executed
- Temporal scale support is fully tested: R extraction, D3 rendering, and integration tests
- Ready for next phase in roadmap

---
*Phase: 12-date-time-scales*
*Completed: 2026-02-16*
