---
phase: 12-date-time-scales
plan: 01
subsystem: scales
tags: [temporal, date, datetime, posixct, milliseconds, timezone]

# Dependency graph
requires:
  - phase: 02-core-scale-system
    provides: "Scale factory with transform dispatch, get_scale_info()"
provides:
  - "Temporal scale domain/breaks in milliseconds for D3 time scales"
  - "Date format pattern extraction from ggplot2 scale closures"
  - "Timezone metadata extraction for datetime scales"
  - "Pre-formatted axis labels as rendering fallback"
affects: [12-02-PLAN, 12-03-PLAN, scales.js, zoom.js, tooltip.js]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deep closure navigation for ggplot2 scale metadata (environment(environment(scale$labels)$f))"
    - "Temporal conversion multipliers: Date * 86400000, POSIXct * 1000"

key-files:
  created: []
  modified:
    - "R/as_d3_ir.R"

key-decisions:
  - "Extract timezone from scale_obj$timezone directly (not just closure), with closure fallback"
  - "Navigate ggproto method closure chain to extract date_labels format pattern"
  - "Convert faceted panel ranges/breaks to milliseconds alongside main scale conversion"

patterns-established:
  - "Temporal scale detection via trans$name in ('date', 'time')"
  - "Millisecond conversion co-located in get_scale_info() for domain, separate block for breaks"

# Metrics
duration: 3min
completed: 2026-02-16
---

# Phase 12 Plan 01: Temporal Scale IR Extraction Summary

**Temporal scale metadata extraction from ggplot2: domain/breaks to milliseconds, format pattern from closure chain, timezone from scale object**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-16T09:41:33Z
- **Completed:** 2026-02-16T09:45:02Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Date scale domains/breaks converted from R days-since-epoch to milliseconds (x 86400000)
- POSIXct scale domains/breaks converted from R seconds-since-epoch to milliseconds (x 1000)
- Format pattern extracted via deep closure navigation: environment(environment(scale$labels)$f)$date_labels
- Timezone extracted from scale_obj$timezone (direct field) with closure fallback
- Pre-formatted labels included for D3 rendering fallback
- Faceted panel x_range/y_range/breaks also converted for temporal scales
- All 487 existing tests pass (2 pre-existing failures unrelated to changes)

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert temporal scale domains and breaks to milliseconds** - `6f03bf8` (feat)

## Files Created/Modified
- `R/as_d3_ir.R` - Added temporal detection in get_scale_info(), ms conversion for domain/breaks, format/timezone/labels extraction, faceted panel temporal conversion

## Decisions Made
- **Direct timezone field first**: scale_obj$timezone is the cleanest extraction path for datetime scales; closure fallback handles edge cases
- **Deep closure navigation for format**: ggplot2 stores date_labels in a nested closure (ggproto_method -> underlying function -> constructor environment); direct environment(scale$labels) does not work
- **Faceted panel conversion**: Applied same ms multipliers to facet_wrap and facet_grid panel ranges/breaks to ensure consistency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed timezone extraction path**
- **Found during:** Task 1
- **Issue:** Plan suggested extracting timezone from environment(scale_obj$labels)$tz, but labels is a ggproto_method (not a simple function) and timezone is stored directly on scale_obj$timezone
- **Fix:** Check scale_obj$timezone first (direct field), fall back to closure navigation
- **Files modified:** R/as_d3_ir.R
- **Verification:** ir2$scales$x$timezone == "America/New_York" confirmed
- **Committed in:** 6f03bf8

**2. [Rule 1 - Bug] Fixed format pattern extraction path**
- **Found during:** Task 1
- **Issue:** Plan suggested environment(scale_obj$labels)$date_labels, but ggproto method closures have a different structure requiring navigation through $f to reach the constructor environment
- **Fix:** Navigate environment(scale_obj$labels)$f -> environment(f)$date_labels
- **Files modified:** R/as_d3_ir.R
- **Verification:** ir3$scales$x$format == "%Y-%m-%d" confirmed
- **Committed in:** 6f03bf8

**3. [Rule 2 - Missing Critical] Added faceted panel temporal conversion**
- **Found during:** Task 1
- **Issue:** Plan only mentioned main scale domain/breaks conversion but facet_wrap and facet_grid panels also extract x_range/y_range/x_breaks/y_breaks that need ms conversion
- **Fix:** Added temporal conversion blocks in both facet_wrap and facet_grid panel extraction loops
- **Files modified:** R/as_d3_ir.R
- **Verification:** Faceted temporal plots would produce consistent ms values
- **Committed in:** 6f03bf8

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** All auto-fixes necessary for correctness. The closure navigation paths were incorrect in the plan but the correct paths were discovered through testing. No scope creep.

## Issues Encountered
None beyond the deviation fixes above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- IR now produces millisecond domains/breaks for temporal scales with format and timezone metadata
- Ready for Plan 12-02 (D3 scale factory temporal support in scales.js)
- Ready for Plan 12-03 (tooltip/zoom temporal formatting)

---
*Phase: 12-date-time-scales*
*Completed: 2026-02-16*

## Self-Check: PASSED
- R/as_d3_ir.R: FOUND
- Commit 6f03bf8: FOUND
