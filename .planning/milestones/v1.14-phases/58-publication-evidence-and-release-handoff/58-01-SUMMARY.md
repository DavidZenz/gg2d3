---
phase: 58-publication-evidence-and-release-handoff
plan: "01"
subsystem: ci
tags: [pkgdown, publication, github-actions, artifacts, testthat]
requires:
  - phase: 57-generated-site-validation-gate
    provides: reusable generated-site validation helpers and CI gate
provides:
  - Validation-backed pkgdown workflow artifact upload
  - Publication-root inspector for downloaded artifacts and deploy checkouts
  - Shared helper support for repository docs layout and publication-root layout
affects: [pkgdown, release-evidence, github-pages]
tech-stack:
  added: []
  patterns: [validation-backed artifact upload, shared publication-root validation, maintainer Rscript inspector]
key-files:
  created:
    - tools/inspect-pkgdown-publication.R
    - .planning/phases/58-publication-evidence-and-release-handoff/58-01-SUMMARY.md
  modified:
    - .github/workflows/pkgdown.yaml
    - tests/testthat/helper-pkgdown-site.R
    - tests/testthat/test-pkgdown-site.R
key-decisions:
  - "Publication inspection reuses the Phase 57 marker and sf outcome contract instead of duplicating expected text in the command wrapper."
  - "The pkgdown artifact upload runs after generated-site validation and before deploy so the downloaded evidence is validation-backed."
patterns-established:
  - "Use `pkgdown_site_validate_publication(site_root = ...)` for downloaded artifacts and `gh-pages` checkouts."
  - "Name pkgdown workflow artifacts `pkgdown-site-${{ github.run_id }}` and retain them for 14 days."
requirements-completed: [SITE-02]
duration: 11 min
completed: 2026-06-01
---

# Phase 58-01: Publication Artifact Inspection Summary

The pkgdown workflow now emits a validation-backed downloadable site artifact, and maintainers have a local inspector for artifact or deploy-root checks.

## Performance

- **Started:** 2026-06-01T08:12:00Z
- **Completed:** 2026-06-01T08:23:26Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Extended the canonical pkgdown-site helper so the same marker contract validates both `docs/` repository layout and publication-root layout.
- Added `tools/inspect-pkgdown-publication.R` with `--site-root` and `--require-rendered-sf true|false|auto`.
- Added a `pkgdown-site-${{ github.run_id }}` upload-artifact step after site validation and before GitHub Pages deploy.

## Task Commits

1. **Task 1: Extend pkgdown validation helpers for site-root inspection** - `631001a`
2. **Task 2: Add the publication inspection command** - `b5a92bc`
3. **Task 3: Upload the validated pkgdown site as a workflow artifact** - `b78283b`

## Verification

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` - passed with 60 expectations.
- `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` - passed with `sf outcome: classified_skip`.
- `rtk rg -n 'Upload pkgdown site artifact|actions/upload-artifact@v4|pkgdown-site-\$\{\{ github.run_id \}\}|path: docs' .github/workflows/pkgdown.yaml` - passed.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

Local sf remains classified as skipped because the local GDAL dynamic library is unavailable. This is expected for the local machine and is carried forward as classified optional-dependency evidence, not a site-generation failure.

## Next Phase Readiness

Plan 58-02 can document the trigger/list/download/inspect workflow and point public docs to the new publication inspector.

## Self-Check: PASSED
