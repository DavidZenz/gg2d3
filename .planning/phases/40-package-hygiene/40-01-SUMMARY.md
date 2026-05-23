---
phase: 40-package-hygiene
plan: 01
subsystem: package-metadata
tags: [r-package, description, dependencies, suggests]
requires: []
provides:
  - "Direct dependency audit for package code, tests, helpers, README, and vignettes"
  - "DESCRIPTION declarations for optional test, browser, vignette, and visual-check dependencies"
affects: [release-hardening, validation-gate, documentation]
tech-stack:
  added: [devtools, htmltools, knitr, maps, mgcv, rmarkdown, scales, V8]
  patterns: [description-audit, optional-dependency-classification]
key-files:
  created:
    - .planning/phases/40-package-hygiene/40-DEPENDENCY-AUDIT.md
  modified:
    - DESCRIPTION
key-decisions:
  - "Kept crosstalk, sf, geojsonsf, and chromote in Suggests because their runtime/test paths remain optional and guarded."
  - "Added VignetteBuilder: knitr to match vignette engine usage."
patterns-established:
  - "Every direct optional dependency in tests, visual checks, README, and vignettes is represented in Suggests or documented as no-action."
requirements-completed: [HYG-01]
duration: 12min
completed: 2026-05-23
---

# Phase 40: Package Hygiene Summary

**Dependency metadata now covers direct runtime, test, browser, visual-check, README, and vignette package usage.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-23T12:33:00Z
- **Completed:** 2026-05-23T12:45:25Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Created an auditable direct dependency scan with DESCRIPTION classification.
- Added missing optional dependency declarations for `htmltools`, `V8`, `knitr`, `rmarkdown`, `scales`, `mgcv`, `maps`, and `devtools`.
- Preserved optional runtime behavior by keeping `crosstalk`, `sf`, `geojsonsf`, and `chromote` in `Suggests`.

## Task Commits

This inline execution commit contains all plan 40-01 tasks.

## Files Created/Modified

- `DESCRIPTION` - Adds missing `Suggests` entries and `VignetteBuilder: knitr`.
- `.planning/phases/40-package-hygiene/40-DEPENDENCY-AUDIT.md` - Records scan commands, direct usage, classification, and no-action/deferred decisions.

## Decisions Made

- `crosstalk` stays in `Suggests`; package code guards all direct use with `requireNamespace()`.
- `sf` and `geojsonsf` stay in `Suggests`; `geom_sf()` conversion produces explicit optional-dependency errors and tests skip when absent.
- No Node browser tooling was added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used a corrected DESCRIPTION presence check**
- **Found during:** Task 2 verification
- **Issue:** The plan's sample R check used `\\b` with base R's default regex engine and vectorized `grepl()` in a way that did not actually detect DESCRIPTION entries.
- **Fix:** Verified the same required packages with a per-package fixed-string check.
- **Files modified:** None beyond planned files.
- **Verification:** `rtk Rscript --vanilla -e 'd <- read.dcf("DESCRIPTION"); suggests <- d[1, "Suggests"]; required <- c("testthat", "chromote", "pkgload", "rprojroot", "sf", "geojsonsf", "rnaturalearth", "htmltools", "V8", "knitr", "rmarkdown", "scales", "mgcv", "maps"); missing <- required[!vapply(required, function(pkg) grepl(pkg, suggests, fixed = TRUE), logical(1))]; if (length(missing)) stop(paste("Missing Suggests:", paste(missing, collapse = ", "))); cat("DESCRIPTION dependencies ok\n")'`

---

**Total deviations:** 1 auto-fixed (blocking verification command issue).
**Impact on plan:** No behavioral scope change; dependency metadata and audit criteria were verified.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 40-02 can audit optional skip behavior against a DESCRIPTION that now declares all direct optional tooling.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'read.dcf("DESCRIPTION"); cat("DESCRIPTION parse ok\n")'` passed.
- `rtk rg -n "chromote|pkgload|rprojroot|htmltools|V8|knitr|rmarkdown|scales|mgcv|maps" DESCRIPTION` found the expected entries.
- `rtk rg -n "## DESCRIPTION Classification|Added to Imports|Added to Suggests|No action|Deferred" .planning/phases/40-package-hygiene/40-DEPENDENCY-AUDIT.md` passed.

---
*Phase: 40-package-hygiene*
*Completed: 2026-05-23*
