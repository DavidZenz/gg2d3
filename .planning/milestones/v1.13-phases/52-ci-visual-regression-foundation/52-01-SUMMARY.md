---
phase: 52-ci-visual-regression-foundation
plan: 01
subsystem: testing
tags: [testthat, chromote, ci, browser-visual-smoke, reports]

requires:
  - phase: 48-browser-visual-smoke-coverage
    provides: deterministic browser visual smoke helper and fixture matrix
provides:
  - CI-mode browser visual smoke failure behavior
  - Browser visual report metadata
  - Browser visual row validation
affects: [phase-52-ci-workflow, browser-visual-smoke, phase-55-release-validation]

tech-stack:
  added: []
  patterns: [explicit CI env mode, structured artifact report validation]

key-files:
  created: []
  modified:
    - tests/testthat/helper-browser-visual.R
    - tests/testthat/test-browser-visual-smoke.R

key-decisions:
  - "Dedicated CI browser failure behavior is controlled by GG2D3_BROWSER_VISUAL_CI, not generic CI=true."
  - "index.json now carries CI/run/browser metadata and validates rows before writing."
  - "Spatial optional dependency skips remain allowed in CI only when explicit sf row skip reasons identify missing optional dependencies."

patterns-established:
  - "Use browser_visual_skip_or_fail() for browser-level checks that should skip locally but fail in dedicated CI."
  - "Use validate_browser_visual_rows() before writing or trusting browser visual report rows."

requirements-completed:
  - CI-01
  - CI-02
  - CI-03

duration: 24 min
completed: 2026-05-28
---

# Phase 52 Plan 01: Report Contract And CI Mode Summary

**CI-aware browser visual smoke helper with structured report metadata and row validation**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-28T06:09:00Z
- **Completed:** 2026-05-28T06:33:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `GG2D3_BROWSER_VISUAL_CI` mode so local browser visual smoke remains skip-friendly while the dedicated CI workflow can fail browser-level unavailability.
- Added browser and GitHub Actions metadata for visual smoke reports.
- Added `validate_browser_visual_rows()` so malformed rows, missing artifacts, missing reasons, and disallowed CI skips fail before `index.json` is trusted.
- Updated the visual smoke runner to validate rows and assert report metadata exists.

## Task Commits

1. **Task 1: Add CI-mode browser gate and report metadata helpers** - `ed4028e` (feat)
2. **Task 2: Validate report rows and include metadata in the index** - `ed4028e` (feat)

## Files Created/Modified

- `tests/testthat/helper-browser-visual.R` - Adds CI-mode skip/fail routing, report metadata, browser metadata, row validation, and metadata output in `index.json` / `index.html`.
- `tests/testthat/test-browser-visual-smoke.R` - Validates rows before writing the index and checks metadata in the generated JSON report.

## Decisions Made

- `GG2D3_BROWSER_VISUAL_CI=true` is the dedicated CI-mode switch. Generic `CI=true` does not change local skip behavior.
- Browser-level missing dependencies fail in CI mode; explicit `sf-` optional dependency row skips may still pass when their reason starts with `Missing optional dependencies:`.
- Screenshots remain artifact evidence only; no pixel comparison logic was added.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); source("tests/testthat/helper-browser-visual.R"); stopifnot(is.function(browser_visual_ci_mode)); stopifnot(is.function(browser_visual_skip_or_fail)); stopifnot(is.function(browser_visual_browser_metadata)); stopifnot(is.function(browser_visual_report_metadata)); md <- browser_visual_report_metadata(); stopifnot(all(c("ci_mode", "github_sha", "browser_visual_ci", "browser") %in% names(md)))'` - passed.
- `rg -n "GG2D3_BROWSER_VISUAL_CI|browser_visual_ci_mode|browser_visual_skip_or_fail|browser_visual_browser_metadata|browser_visual_report_metadata|github_sha|chromote session launch unavailable|Chrome/Chromium not available" tests/testthat/helper-browser-visual.R` - passed.
- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); source("tests/testthat/helper-browser-visual.R"); stopifnot(is.function(validate_browser_visual_rows)); tmp <- tempfile(); writeLines("x", tmp); row <- list(id="fixture", category="cartesian", status="passed", html=tmp, screenshot=tmp, dom_summary=tmp, browser_log=tmp, skip_reason=NULL, error=NULL); validate_browser_visual_rows(list(row)); cat("row validation ok\n")'` - passed.
- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` - passed with one expected opt-in skip.
- `rg -n "validate_browser_visual_rows|metadata = browser_visual_report_metadata|jsonlite::read_json|browser_visual_smoke|Missing optional dependencies:" tests/testthat/helper-browser-visual.R tests/testthat/test-browser-visual-smoke.R` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can create the dedicated GitHub Actions workflow using `GG2D3_BROWSER_VISUAL_CI=true` and upload the validated artifact bundle.

## Self-Check: PASSED

---
*Phase: 52-ci-visual-regression-foundation*
*Completed: 2026-05-28*
