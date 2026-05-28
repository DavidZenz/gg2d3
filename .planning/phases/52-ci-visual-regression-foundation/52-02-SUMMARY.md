---
phase: 52-ci-visual-regression-foundation
plan: 02
subsystem: ci
tags: [github-actions, r-lib-actions, chromote, testthat, artifacts]

requires:
  - phase: 52-01
    provides: CI-mode browser failure behavior and validated report contract
provides:
  - Dedicated browser visual smoke GitHub Actions workflow
  - Pull request and workflow_dispatch visual smoke execution
  - Always-uploaded browser visual smoke artifact bundle
affects: [phase-52-final-docs, phase-55-release-validation]

tech-stack:
  added: [actions/upload-artifact@v4]
  patterns: [dedicated PR-safe visual smoke workflow, CHROMOTE_CHROME discovery]

key-files:
  created:
    - .github/workflows/browser-visual-smoke.yaml
  modified: []

key-decisions:
  - "Browser visual smoke CI runs in a dedicated workflow separate from pkgdown publishing."
  - "The workflow sets both GG2D3_BROWSER_VISUAL_SMOKE=true and GG2D3_BROWSER_VISUAL_CI=true."
  - "The full test_output/browser-visual-smoke/ directory is uploaded on every workflow run."

patterns-established:
  - "Locate Chrome/Chromium on the runner, export CHROMOTE_CHROME, then run the existing testthat visual smoke file."
  - "Use if: always() with actions/upload-artifact@v4 so failed runs still preserve diagnostics."

requirements-completed:
  - CI-01
  - CI-02

duration: 2 min
completed: 2026-05-28
---

# Phase 52 Plan 02: Dedicated Browser Visual Smoke Workflow Summary

**Pull-request GitHub Actions workflow for chromote-backed browser visual smoke with always-uploaded artifacts**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-28T06:33:15Z
- **Completed:** 2026-05-28T06:34:49Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created `.github/workflows/browser-visual-smoke.yaml` as a dedicated workflow separate from pkgdown.
- Configured PR and manual `workflow_dispatch` triggers.
- Set `NOT_CRAN=true`, `GG2D3_BROWSER_VISUAL_SMOKE=true`, and `GG2D3_BROWSER_VISUAL_CI=true` in the workflow environment.
- Added Chrome/Chromium discovery that exports `CHROMOTE_CHROME`.
- Added `actions/upload-artifact@v4` with `if: always()` for `test_output/browser-visual-smoke/`.

## Task Commits

1. **Task 1: Add dedicated browser visual smoke workflow** - `bb5a4f0` (ci)
2. **Task 2: Validate workflow source and CI dependency boundaries** - `bb5a4f0` (ci)

## Files Created/Modified

- `.github/workflows/browser-visual-smoke.yaml` - Dedicated GitHub Actions workflow for browser visual smoke.

## Decisions Made

- The workflow is a sibling to `pkgdown.yaml`; pkgdown remains untouched.
- Chrome discovery happens in the workflow rather than vendoring/downloading a browser in test helper code.
- The artifact upload warns if no files exist, preserving failure diagnostics when the runner fails before artifact generation.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification

- `test -f .github/workflows/browser-visual-smoke.yaml` - passed.
- `rg -n "pull_request|workflow_dispatch|permissions: read-all|GG2D3_BROWSER_VISUAL_SMOKE|GG2D3_BROWSER_VISUAL_CI|CHROMOTE_CHROME|test-browser-visual-smoke\\.R|actions/upload-artifact@v4|test_output/browser-visual-smoke|retention-days: 14" .github/workflows/browser-visual-smoke.yaml` - passed.
- `rg -n "browser-visual-smoke" .github/workflows/pkgdown.yaml || true` - returned no matches, confirming pkgdown was not repurposed.
- `Rscript --vanilla -e 'txt <- readLines(".github/workflows/browser-visual-smoke.yaml", warn=FALSE); stopifnot(any(grepl("pull_request", txt, fixed=TRUE))); stopifnot(any(grepl("workflow_dispatch", txt, fixed=TRUE))); stopifnot(!any(grepl("^  push:", txt))); stopifnot(!any(grepl("pkgdown::build_site_github_pages", txt, fixed=TRUE))); stopifnot(any(grepl("test-browser-visual-smoke.R", txt, fixed=TRUE))); stopifnot(any(grepl("actions/upload-artifact@v4", txt, fixed=TRUE)))'` - passed.
- `Rscript --vanilla -e 'files <- c(".github/workflows/browser-visual-smoke.yaml", "DESCRIPTION"); pattern <- "Playwright|Puppeteer|Selenium|webshot2|pixel diff|golden|npm|node_modules"; hits <- unlist(lapply(files, function(f) grep(pattern, readLines(f, warn=FALSE), value=TRUE))); if (length(hits)) stop(paste(hits, collapse="\n"))'` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can document the CI workflow, local CI-equivalent command, artifact inspection flow, and troubleshooting behavior.

## Self-Check: PASSED

---
*Phase: 52-ci-visual-regression-foundation*
*Completed: 2026-05-28*
