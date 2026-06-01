---
phase: 57-generated-site-validation-gate
plan: "02"
subsystem: tooling
tags: [pkgdown, validation, ci, generated-site]
requires:
  - phase: 57-generated-site-validation-gate
    provides: 57-01 shared validation helper
provides:
  - Maintainer quick/release/ci validation command
  - CI pkgdown validation step before deploy
affects: [pkgdown, github-actions, release-evidence]
tech-stack:
  added: []
  patterns: [Rscript validation wrapper, shared testthat helper reuse, post-build CI gate]
key-files:
  created:
    - tools/validate-pkgdown-site.R
    - .planning/phases/57-generated-site-validation-gate/57-02-SUMMARY.md
  modified:
    - .github/workflows/pkgdown.yaml
key-decisions:
  - "Quick mode validates committed generated docs without rebuilding."
  - "Release mode rebuilds README/help/pkgdown outputs before validating."
  - "CI mode validates the just-built pkgdown site and requires rendered sf only when spatial packages are loadable."
patterns-established:
  - "The maintainer command sources `tests/testthat/helper-pkgdown-site.R` instead of duplicating validation logic."
requirements-completed: [SITE-01]
duration: 2 min
completed: 2026-06-01
---

# Phase 57-02: Generated Site Validation Command Summary

The generated pkgdown site now has a local/CI validation command and the pkgdown workflow runs it before deploy.

## Performance

- **Started:** 2026-06-01T07:07:02Z
- **Completed:** 2026-06-01T07:09:09Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `tools/validate-pkgdown-site.R` with `--mode quick`, `--mode release`, and `--mode ci`.
- Quick mode validates committed generated `docs/` and currently reports `sf outcome: classified_skip`.
- Release mode runs `devtools::document()`, `devtools::build_readme()`, and `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` before validation.
- CI mode validates the just-built site without rebuilding.
- Added `.github/workflows/pkgdown.yaml` step `Validate generated pkgdown site` after `Build site` and before deploy.

## Task Commits

1. **Task 1: Add the quick/release/ci validation script** - `b9b6ecd`
2. **Task 2: Add the CI validation step before pkgdown deploy** - `deda3a6`
3. **Task 3: Verify the command/test integration** - covered by verification below; no code changes.

## Verification

- `rtk Rscript --vanilla -e 'parse("tools/validate-pkgdown-site.R"); cat("script parses\n")'` - passed.
- `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` - passed with `sf outcome: classified_skip`.
- `rtk rg -n "quick|release|ci|devtools::document\\(\\)|devtools::build_readme\\(\\)|pkgdown::build_site_github_pages" tools/validate-pkgdown-site.R` - passed.
- `rtk rg -n "pkgdown_site_validate_source_contract|pkgdown_site_validate_quick|pkgdown_site_spatial_loadable" tools/validate-pkgdown-site.R` - passed.
- `rtk rg -n "Verify website dependencies|Build site|Validate generated pkgdown site|Rscript tools/validate-pkgdown-site.R --mode ci|Deploy to GitHub pages" .github/workflows/pkgdown.yaml` - passed.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` - passed with 42 expectations.
- `rtk Rscript --vanilla -e 'devtools::test(filter = "pkgdown-site")'` - passed with 42 expectations.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Next Phase Readiness

Plan 57-03 can document the command and record final SITE-01 evidence.

## Self-Check: PASSED
