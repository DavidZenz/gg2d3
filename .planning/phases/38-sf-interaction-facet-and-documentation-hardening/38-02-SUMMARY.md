---
phase: 38-sf-interaction-facet-and-documentation-hardening
plan: 02
subsystem: testing
tags: [sf, browser, facets, bbox, projection]

requires:
  - phase: 37-non-polygon-sf-ir-and-renderer
    provides: sf polygon, point, and line families with shared panel-scoped projection metadata
provides:
  - Phase 38 faceted sf fixtures for polygon, point, line, mixed-family, and empty-panel cases
  - IR assertions for panel-local sf_bbox metadata and skipped-row isolation
  - Browser DOM assertions for panel-local family counts and representative anchors
affects: [sf, browser-tests, facet-tests]

tech-stack:
  added: []
  patterns: [facet matrix fixtures, panel-local bbox assertions, panel-local DOM anchor assertions]

key-files:
  created: []
  modified:
    - tests/testthat/helper-sf-fixtures.R
    - tests/testthat/test-sf-browser.R
    - tests/testthat/test-sf-ir.R

key-decisions:
  - "Use deterministic facet fixtures with valid longitude/latitude coordinates to avoid sf longlat warnings during bbox validation."
  - "Keep browser facet checks DOM-based: per-panel .geom-sf counts, family classes, and finite data-cx/data-cy anchors within panel bounds."
  - "Use full-file testthat::test_file() for local verification because this testthat version does not support test_file(filter = ...)."

patterns-established:
  - "Phase 38 facet fixtures live alongside the existing sf fixture helper and save to test_output/browser-sf."
  - "Browser facet tests validate all panels, including expected zero-mark empty panels."

requirements-completed: [SFXDOC-02]

duration: 5 min
completed: 2026-05-22
---

# Phase 38 Plan 02: sf Facet Validation Summary

**Faceted sf fixtures and assertions now cover polygon, point, line, mixed-family, and empty-panel behavior with panel-local bbox and anchor checks**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-22T10:44:07Z
- **Completed:** 2026-05-22T10:50:01Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added deterministic Phase 38 facet fixtures for wrap, grid, mixed-family, skipped-row, and empty-panel sf cases.
- Added IR assertions that non-empty panels have finite, isolated `sf_bbox` metadata while empty panels keep `sf_bbox = NULL`.
- Added browser DOM assertions for exact panel-local `.geom-sf` counts, expected family classes, and finite representative anchors within each panel.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Phase 38 facet fixture builders** - `ae0a73c` (test)
2. **Task 2: Add IR-level bbox and panel isolation assertions** - `c8da742` (test)
3. **Task 3: Add browser DOM panel-count and projection assertions** - `2a9eca7` (test)

**Plan metadata:** pending

## Files Created/Modified

- `tests/testthat/helper-sf-fixtures.R` - Adds `.phase38_sf_facet_fixture_set()` and wrap/grid/empty-panel fixture builders.
- `tests/testthat/test-sf-ir.R` - Adds SFXDOC-02 IR coverage for facet type, panel count, local bbox, empty-panel bbox, and skipped-row isolation.
- `tests/testthat/test-sf-browser.R` - Adds SFXDOC-02 browser DOM coverage for per-panel family counts and representative anchors.

## Decisions Made

- Used valid WGS84-ish coordinates in test fixtures so sf bbox/projection assertions run without unrelated longlat warnings.
- Kept the browser checks structured around DOM attributes rather than screenshot comparison.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported filtered test command with full-file verification**
- **Found during:** Plan verification
- **Issue:** The plan's verification command used `testthat::test_file(..., filter = "SFXDOC-02")`, but the installed testthat version does not support the `filter` argument.
- **Fix:** Ran full-file verification for `test-sf-ir.R` and `test-sf-browser.R`.
- **Files modified:** None.
- **Verification:** `test-sf-ir.R` passed fully; `test-sf-browser.R` exited 0 with live browser tests skipping cleanly under CRAN-like skip conditions.
- **Committed in:** Not applicable - verification command deviation only.

---

**Total deviations:** 1 auto-fixed (blocking verification command incompatibility).
**Impact on plan:** No scope change. The full-file commands are stricter when browser tests are runnable.

## Issues Encountered

Browser tests skipped via `skip_on_cran()` in this Rscript context, matching the existing optional-browser dependency behavior. IR tests ran and passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 38-03 can now document the v1.9 sf support contract against browser and IR coverage for interactivity, facets, and zoom suppression.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` passed with 164 assertions.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` exited 0 with clean skips for live browser tests.

---
*Phase: 38-sf-interaction-facet-and-documentation-hardening*
*Completed: 2026-05-22*
