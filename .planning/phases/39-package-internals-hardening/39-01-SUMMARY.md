---
phase: 39-package-internals-hardening
plan: 01
subsystem: internals
tags: [sf, ir, ggplot2, regression]
requires:
  - phase: 38-sf-documentation-and-examples
    provides: "documented sf behavior and smoke-test expectations"
provides:
  - "sf layer IR assembly delegated to internal helpers"
  - "panel sf_bbox attachment delegated to internal helpers"
  - "characterization tests for mixed sf row identity and panel bbox contracts"
affects: [as_d3_ir, sf_utils, sf, coord]
tech-stack:
  added: []
  patterns: ["internal sf helper boundaries", "helper-level sf IR characterization"]
key-files:
  created: []
  modified:
    - R/as_d3_ir.R
    - R/sf_utils.R
    - tests/testthat/test-sf-utils.R
    - tests/testthat/test-sf-ir.R
key-decisions:
  - "Kept sf helpers internal and roxygen-free so no new public helper documentation is generated."
  - "Updated stale custom-supported-types tests to distinguish default point/line support from explicit polygon-only filtering."
patterns-established:
  - "sf_layer_ir_payload() owns sf layer payload assembly while as_d3_ir() owns layer orchestration."
  - "attach_sf_panel_bboxes() owns panel-local sf bbox attachment."
requirements-completed: [HARD-01]
duration: 25min
completed: 2026-05-22
---

# Phase 39 Plan 01: Sf Helper Extraction Summary

**Internal sf layer and panel bbox assembly helpers with behavior-preserving sf and core IR coverage**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-22T11:05:00Z
- **Completed:** 2026-05-22T11:29:57Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added HARD-01 characterization tests for mixed sf row identity, skipped rows, stacked sf bbox, and empty facet panel bbox behavior.
- Extracted `sf_layer_ir_payload()` and `attach_sf_panel_bboxes()` into `R/sf_utils.R`.
- Preserved sf renderer, sf IR, and core IR behavior after the extraction.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add sf assembly characterization tests** - `57f49e7` (test)
2. **Task 2: Extract sf layer and panel bbox helpers** - `a218933` (refactor)
3. **Task 3: Verify sf extraction causes no IR drift** - `ea98b57` (fix)

## Files Created/Modified

- `R/sf_utils.R` - Added internal helpers for sf layer payload rowization, panel geometry grouping, and panel bbox attachment.
- `R/as_d3_ir.R` - Replaced inline sf assembly and panel bbox logic with helper calls.
- `tests/testthat/test-sf-utils.R` - Added HARD-01 row identity diagnostics coverage and corrected stale polygon-only test setup.
- `tests/testthat/test-sf-ir.R` - Added explicit stacked and faceted sf bbox contract coverage.

## Decisions Made

- Kept helper visibility internal to avoid creating accidental public API surface.
- Treated ggplot2 4.x `coord_fixed()`/`coord_trans()` class drift as a bounded compatibility fix because the Phase 39 verification gate exposed it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored ggplot2 4.x coordinate metadata detection**
- **Found during:** Task 3 (Verify sf extraction causes no IR drift)
- **Issue:** `test-ir.R` failed because ggplot2 4.x reports transformed coordinates as `CoordTransform` and fixed coordinates as `CoordCartesian` with a `ratio` field.
- **Fix:** Updated `as_d3_ir()` to detect `CoordTransform` and ratio-bearing `CoordCartesian` coordinates.
- **Files modified:** `R/as_d3_ir.R`
- **Verification:** `test-sf-ir.R`, `test-sf-renderer.R`, and `test-ir.R` exit 0.
- **Committed in:** `ea98b57`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Bounded compatibility fix required for the planned no-IR-drift gate. No unrelated cleanup.

## Issues Encountered

- Existing sf utility tests assumed point and line geometries were unsupported by default. They were updated to pass `supported_types = c("POLYGON", "MULTIPOLYGON")` when testing explicit filtering.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can now centralize ggplot2 private/theme/layout access behind compatibility helpers on top of the extracted sf boundaries.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R")'`
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-ir.R")'`
- `rtk rg -n "sf_layer_ir_payload\\(|attach_sf_panel_bboxes\\(" R/as_d3_ir.R`
- `rtk rg -n "sf_layer_ir_payload|attach_sf_panel_bboxes" man` found no matches.

---
*Phase: 39-package-internals-hardening*
*Completed: 2026-05-22*
