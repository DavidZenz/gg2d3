---
phase: 52-ci-visual-regression-foundation
plan: 03
subsystem: docs
tags: [diagnostics, ci, browser-visual-smoke, validation]

requires:
  - phase: 52-01
    provides: CI-mode browser visual helper behavior and report validation
  - phase: 52-02
    provides: dedicated browser visual smoke workflow
provides:
  - CI/local browser visual smoke documentation
  - CHROMOTE_CHROME troubleshooting guidance
  - Final source and workflow validation evidence
affects: [phase-55-release-documentation, release-validation]

tech-stack:
  added: []
  patterns: [CI-equivalent local command, explicit pixel-threshold deferral]

key-files:
  created: []
  modified:
    - vignettes/d3-drawing-diagnostics.md
    - tests/testthat/helper-browser-visual.R
    - .github/workflows/browser-visual-smoke.yaml

key-decisions:
  - "The documented CI-equivalent command inspects testthat results with as.data.frame(res) and exits nonzero on failed or error rows."
  - "Docs now distinguish local skip-friendly smoke, full local artifacts, and dedicated CI-mode execution."
  - "Golden screenshots and pixel thresholds remain explicitly deferred."

patterns-established:
  - "Use a CI-equivalent command that converts testthat_results to a data frame before checking failed/error columns."
  - "Document CHROMOTE_CHROME as a troubleshooting override rather than default behavior."

requirements-completed:
  - CI-01
  - CI-02
  - CI-03

duration: 6 min
completed: 2026-05-28
---

# Phase 52 Plan 03: Docs And Final Validation Summary

**CI/local browser visual smoke documentation with verified nonzero CI failure behavior**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-28T06:34:49Z
- **Completed:** 2026-05-28T06:40:59Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Documented the CI-equivalent local command, dedicated workflow path, artifact upload behavior, `index.html`/`index.json` roles, and `CHROMOTE_CHROME` troubleshooting.
- Documented that browser-level skips fail in dedicated CI while explicit optional `sf`/`geojsonsf` row skips may pass.
- Documented that screenshots are inspection evidence only and golden screenshots/pixel thresholds are deferred.
- Fixed the CI command to exit nonzero by converting `testthat_results` to a data frame before checking `failed` and `error`.
- Tightened CI-mode browser unavailability to hard-error rather than record a non-aborting expectation failure.

## Task Commits

1. **Task 1: Document CI, local commands, artifacts, and troubleshooting** - `6be52ba` (fix)
2. **Task 2: Run final source, workflow, and artifact-boundary checks** - `6be52ba` (fix)

## Files Created/Modified

- `vignettes/d3-drawing-diagnostics.md` - Adds CI-equivalent command, workflow reference, artifact inspection guidance, `CHROMOTE_CHROME`, and pixel/golden deferral.
- `.github/workflows/browser-visual-smoke.yaml` - Uses a result-checking Rscript command so failed/error testthat rows exit nonzero.
- `tests/testthat/helper-browser-visual.R` - Uses a hard error for CI-mode browser-level unavailability so the test run stops immediately.

## Decisions Made

- The CI-equivalent command must use `df <- as.data.frame(res)` before checking `df$failed` and `df$error`; checking `res$failed` directly does not work for `testthat_results`.
- Local browser launch failure on this machine is valid evidence that CI mode fails browser-level unavailability; it is not a phase blocker because the dedicated GitHub runner is the intended browser-available environment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made CI-mode browser failures abort control flow**
- **Found during:** Task 2 (final CI-equivalent browser command)
- **Issue:** `testthat::fail()` recorded a failure but did not abort the test body, causing later browser session setup to run and add a second error.
- **Fix:** Changed the CI branch of `browser_visual_skip_or_fail()` to `stop(message, call. = FALSE)`.
- **Files modified:** `tests/testthat/helper-browser-visual.R`
- **Verification:** CI-equivalent command now stops at the browser-level error without an additional skipped row.
- **Committed in:** `6be52ba`

**2. [Rule 3 - Blocking] Made the CI workflow exit nonzero on testthat failures**
- **Found during:** Task 2 (final CI-equivalent browser command)
- **Issue:** `testthat::test_file()` prints failures but returned exit status 0 unless the caller inspects the returned `testthat_results`.
- **Fix:** Updated the workflow and docs command to use `df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)`.
- **Files modified:** `.github/workflows/browser-visual-smoke.yaml`, `vignettes/d3-drawing-diagnostics.md`
- **Verification:** CI-equivalent local command exited with status 1 when local Chromium/chromote launch failed.
- **Committed in:** `6be52ba`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both fixes strengthen the Phase 52 CI gate without adding scope.

## Issues Encountered

- Local Chromium/chromote launch is unavailable in this environment: `Cannot find an available port` / `Chrome does not appear to be runnable on your system`. In `GG2D3_BROWSER_VISUAL_CI=true` mode this correctly fails with exit status 1. Browser-available artifact generation remains for GitHub Actions or a local environment where chromote can launch Chrome.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` - passed with one expected opt-in skip.
- `rg -n "GG2D3_BROWSER_VISUAL_CI|validate_browser_visual_rows|browser_visual_report_metadata|jsonlite::read_json|browser_visual_ci_mode" tests/testthat/helper-browser-visual.R tests/testthat/test-browser-visual-smoke.R` - passed.
- `rg -n "pull_request|workflow_dispatch|GG2D3_BROWSER_VISUAL_SMOKE|GG2D3_BROWSER_VISUAL_CI|actions/upload-artifact@v4|test_output/browser-visual-smoke|test-browser-visual-smoke\\.R|as\\.data\\.frame\\(res\\)|quit\\(status = 1\\)" .github/workflows/browser-visual-smoke.yaml` - passed.
- `rg -n "GG2D3_BROWSER_VISUAL_CI|browser-visual-smoke.yaml|CHROMOTE_CHROME|test_output/browser-visual-smoke|pixel thresholds|golden screenshots|as\\.data\\.frame\\(res\\)|quit\\(status = 1\\)" vignettes/d3-drawing-diagnostics.md` - passed.
- `Rscript --vanilla -e 'files <- c("DESCRIPTION", "tests/testthat/helper-browser-visual.R", "tests/testthat/test-browser-visual-smoke.R", "vignettes/d3-drawing-diagnostics.md", ".github/workflows/browser-visual-smoke.yaml"); pattern <- "Playwright|Puppeteer|Selenium|webshot2|pixel diff|pixel-diff|golden image|committed golden|npm|node_modules"; hits <- unlist(lapply(files[file.exists(files)], function(f) grep(pattern, readLines(f, warn=FALSE), value=TRUE))); allowed <- grep("deferred|do not introduce|not add|no pixel|golden screenshots are deferred", hits, value=TRUE, ignore.case=TRUE, invert=TRUE); if (length(allowed)) stop(paste(allowed, collapse="\\n"))'` - passed.
- `rg -n "^test_output/|^test_output$|test_output" .gitignore .Rbuildignore` - passed.
- `CHROMOTE_CHROME="/Applications/Chromium.app/Contents/MacOS/Chromium" NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-browser-visual-smoke.R"); df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)'` - failed with exit status 1 because local Chrome/chromote launch is unavailable, confirming CI-mode browser-level failures do not pass silently.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 52 has all three implementation plans complete. Phase-level verification should confirm that source, workflow, docs, and local commands satisfy CI-01, CI-02, and CI-03.

## Self-Check: PASSED

---
*Phase: 52-ci-visual-regression-foundation*
*Completed: 2026-05-28*
