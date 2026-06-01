---
phase: 57-generated-site-validation-gate
plan: "01"
subsystem: tests
tags: [pkgdown, generated-site, testthat, validation]
requires:
  - phase: 56-pkgdown-content-and-widget-build-contract
    provides: generated pkgdown evidence and focused marker tests
provides:
  - Shared generated-site validation helper
  - Focused canonical pkgdown-site test entrypoint
affects: [pkgdown, docs, release-evidence]
tech-stack:
  added: []
  patterns: [testthat helper extraction, marker-specific generated-site checks, sf outcome classification]
key-files:
  created:
    - tests/testthat/helper-pkgdown-site.R
    - .planning/phases/57-generated-site-validation-gate/57-01-SUMMARY.md
  modified:
    - tests/testthat/test-pkgdown-site.R
key-decisions:
  - "Kept testthat as the canonical generated-site gate while making the validation logic reusable by scripts."
  - "Classified sf article output as rendered, classified_skip, or missing, with strict rendered-sf enforcement controlled by require_rendered_sf."
patterns-established:
  - "Generated pkgdown validation lives in `tests/testthat/helper-pkgdown-site.R` and is called by focused tests."
requirements-completed: [SITE-01]
duration: 2 min
completed: 2026-06-01
---

# Phase 57-01: Shared Generated-Site Validation Helper Summary

The focused pkgdown-site checks now delegate to a reusable helper while preserving file/marker-specific failure messages.

## Performance

- **Started:** 2026-06-01T07:05:12Z
- **Completed:** 2026-06-01T07:07:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `tests/testthat/helper-pkgdown-site.R` with reusable text/path resolution, generated-site marker checks, widget asset checks, and sf outcome classification.
- Refactored `tests/testthat/test-pkgdown-site.R` so it calls helper entrypoints instead of owning duplicate marker and file-reader logic.
- Added `pkgdown_site_validate_quick(require_rendered_sf = FALSE)` as the canonical quick validation core for the Phase 57 command wrapper.

## Task Commits

1. **Task 1: Extract reusable generated-site validation helper functions** - `9db4175`
2. **Task 2: Refactor the focused test to use the helper as canonical source of truth** - `04823b2`

## Verification

- `rtk Rscript --vanilla -e 'parse("tests/testthat/helper-pkgdown-site.R"); cat("helper parses\n")'` - passed.
- `rtk rg -n "pkgdown_site_validate_quick|pkgdown_site_sf_outcome|pkgdown_site_spatial_loadable|classified_skip|require_rendered_sf" tests/testthat/helper-pkgdown-site.R` - passed.
- `rtk rg -n "pkgdown_site_validate_source_contract|pkgdown_site_validate_quick" tests/testthat/test-pkgdown-site.R` - passed.
- `rtk rg -n "read_text_file <-|expect_text_contains <-|expect_existing_path <-" tests/testthat/test-pkgdown-site.R` - passed with no matches.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` - passed with 42 expectations.
- `rtk Rscript --vanilla -e 'devtools::test(filter = "pkgdown-site")'` - passed with 42 expectations.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Next Phase Readiness

Wave 2 can build the maintainer/CI command wrapper on top of `pkgdown_site_validate_quick()` and the sf outcome helpers.

## Self-Check: PASSED
