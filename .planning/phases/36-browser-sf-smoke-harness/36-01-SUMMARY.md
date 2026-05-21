---
phase: 36-browser-sf-smoke-harness
plan: 01
subsystem: testing
tags: [r, testthat, chromote, htmlwidgets, geom-sf]

# Dependency graph
requires:
  - phase: 35-geom-sf-docs-and-validation-hardening
    provides: Phase 35 polygon sf fixture matrix and visual validation helpers
provides:
  - Optional chromote Suggests dependency for browser smoke tests
  - Shared Phase 35 polygon sf fixture builders
  - Reusable chromote browser smoke helper contracts
affects: [36-browser-sf-smoke-harness, 37-non-polygon-sf-ir-and-renderer]

# Tech tracking
tech-stack:
  added: [chromote]
  patterns: [testthat helper extraction, non-self-contained browser fixture artifacts, chromote DOM polling]

key-files:
  created:
    - tests/testthat/helper-sf-fixtures.R
    - tests/testthat/helper-browser-sf.R
  modified:
    - DESCRIPTION
    - tests/testthat/test-sf-visual.R

key-decisions:
  - "Kept browser automation optional by adding chromote only to Suggests."
  - "Centralized Phase 35 polygon sf fixtures in helper-sf-fixtures.R for reuse by browser smoke tests."
  - "Stored browser fixture artifacts under test_output/browser-sf with non-self-contained htmlwidgets output."

patterns-established:
  - "Browser smoke tests should use skip_browser_sf_smoke() before launching Chrome."
  - "Live sf DOM assertions should poll path.geom-sf through wait_for_sf_paths() before reading row and centroid attributes."
  - "Browser console and exception events should be collected before navigation and checked with assert_no_browser_errors()."

requirements-completed: [BRSF-01, BRSF-02, BRSF-03]

# Metrics
duration: 6m13s
completed: 2026-05-21
---

# Phase 36 Plan 01: Browser sf Smoke Harness Foundation Summary

**Chromote-backed sf smoke-test foundation with shared polygon fixtures, deterministic browser artifacts, DOM polling, and browser error capture helpers**

## Performance

- **Duration:** 6m13s
- **Started:** 2026-05-21T07:02:49Z
- **Completed:** 2026-05-21T07:09:02Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `chromote (>= 0.5.1)` as an optional `Suggests` dependency without adding Node, Playwright, Puppeteer, Selenium, or browser tooling to `Imports`.
- Extracted Phase 35 polygon sf fixture generation into `tests/testthat/helper-sf-fixtures.R` while keeping the existing six fixture names and helper function names stable.
- Added `tests/testthat/helper-browser-sf.R` with skip guards, chromote session lifecycle, `Runtime$evaluate(..., returnByValue = TRUE)`, `path.geom-sf` polling, console/exception collection, and failure artifact writing under `test_output/browser-sf`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add optional chromote and extract shared sf fixtures** - `ec58c8f` (`feat`)
2. **Task 2: Create reusable chromote browser smoke helpers** - `46b5e91` (`feat`)

## Files Created/Modified

- `DESCRIPTION` - Adds optional `chromote (>= 0.5.1)` in `Suggests`.
- `tests/testthat/helper-sf-fixtures.R` - Hosts shared Phase 35 sf fixture builders and non-self-contained widget save helper.
- `tests/testthat/test-sf-visual.R` - Delegates Phase 35 fixture generation to testthat helper functions while preserving fixture assertions.
- `tests/testthat/helper-browser-sf.R` - Provides reusable chromote skip, artifact, navigation/eval, DOM wait, log assertion, and failure artifact helpers.

## Decisions Made

- Followed D-01/D-02 by keeping the browser runner in R/testthat through `chromote` and avoiding Node-based browser stacks.
- Kept Phase 35 fixture helper names unchanged so existing tests and future browser smoke tests can share the same fixtures.
- Returned browser logs through a collector closure so tests can check errors at the end while callbacks keep accumulating runtime events.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added local null-coalescing helper for browser log callbacks**
- **Found during:** Task 2 (Create reusable chromote browser smoke helpers)
- **Issue:** Browser log formatting used `%||%`, which is not attached in direct helper-source contexts.
- **Fix:** Added a local `%||%` helper inside `helper-browser-sf.R`.
- **Files modified:** `tests/testthat/helper-browser-sf.R`
- **Verification:** Browser helper source check and minimal chromote evaluation/log collection smoke passed.
- **Committed in:** `46b5e91`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was required for direct `test_file()` and helper-source use; no scope was added.

## Issues Encountered

None affecting completion. A `rg` check for forbidden browser tooling returned exit code 1 because there were no matches, which is the expected result.

## User Setup Required

None. `chromote`, `sf`, `geojsonsf`, and Chrome are optional runtime requirements guarded by `skip_browser_sf_smoke()`.

## Verification

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-visual.R")'` - passed, 64 assertions.
- `rtk Rscript --vanilla -e 'source("tests/testthat/helper-sf-fixtures.R"); source("tests/testthat/helper-browser-sf.R"); stopifnot(is.function(skip_browser_sf_smoke), is.function(browser_sf_artifact_dir), is.function(wait_for_sf_paths), is.function(assert_no_browser_errors))'` - passed.
- `rtk rg -n "chromote \\(>= 0\\.5\\.1\\)" DESCRIPTION` - one match under `Suggests`.
- `rtk rg -n "playwright|puppeteer|selenium|node" DESCRIPTION` - no matches.

## Known Stubs

None. The stub-pattern scan only found a Chrome-unavailable skip message and the intentional `session = NULL` optional parameter in `write_browser_failure_artifacts()`.

## Next Phase Readiness

Plan 02 can add live browser DOM assertions against the shared Phase 35 fixture matrix using `save_browser_sf_widget()`, `with_chromote_session()`, `browser_console_collector()`, and `wait_for_sf_paths()`.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/36-browser-sf-smoke-harness/36-01-SUMMARY.md`.
- Created helper files exist at `tests/testthat/helper-sf-fixtures.R` and `tests/testthat/helper-browser-sf.R`.
- Task commits exist in git history: `ec58c8f` and `46b5e91`.

---
*Phase: 36-browser-sf-smoke-harness*
*Completed: 2026-05-21*
