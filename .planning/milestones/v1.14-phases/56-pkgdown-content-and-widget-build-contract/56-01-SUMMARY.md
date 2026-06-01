---
phase: 56-pkgdown-content-and-widget-build-contract
plan: "01"
subsystem: docs
tags: [pkgdown, sf, testthat, htmlwidgets]
requires:
  - phase: 56-pkgdown-content-and-widget-build-contract
    provides: Phase context, research, validation strategy, and pattern map
provides:
  - Focused pkgdown marker test contract
  - Visible optional sf dependency classification in the main article source
affects: [pkgdown, docs, sf, generated-site-validation]
tech-stack:
  added: []
  patterns: [source-first docs, generated marker tests, visible optional dependency skips]
key-files:
  created:
    - tests/testthat/test-pkgdown-site.R
  modified:
    - vignettes/gg2d3.Rmd
    - tests/testthat/test-pkgdown-site.R
key-decisions:
  - "Keep the sf article chunk evaluated in all environments and branch inside the chunk."
  - "Use exact text markers so generated-site freshness checks can fail loudly."
patterns-established:
  - "Pkgdown file checks use path-specific failure messages."
  - "Optional spatial dependency gaps emit PKGDOWN_SF_OPTIONAL_SKIP in rendered article output."
requirements-completed: [DOCS-02, BUILD-03]
duration: 5min
completed: 2026-05-31
---

# Phase 56-01: Pkgdown sf Source Contract Summary

**The main pkgdown article source now names the sf support contract and visibly classifies missing optional spatial dependencies.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-31T19:29:00Z
- **Completed:** 2026-05-31T19:33:56Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `tests/testthat/test-pkgdown-site.R` with file readers, marker checks, and generated-site marker constants.
- Replaced the silent sf chunk-level `eval = requireNamespace(...)` gate with in-chunk dependency classification.
- Verified the source-level contract with `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'`.

## Task Commits

1. **Task 1: Create the Phase 56 pkgdown marker test contract** - `d5494c4` (test)
2. **Task 2: Make sf article optional-dependency classification visible** - `c82cf22` (docs)

## Files Created/Modified

- `tests/testthat/test-pkgdown-site.R` - Focused marker helpers and source/generated pkgdown contract checks.
- `vignettes/gg2d3.Rmd` - Evaluated sf example chunk with `PKGDOWN_SF_OPTIONAL_SKIP` fallback.

## Decisions Made

The sf support sentence now includes the literal `geom_sf() supports polygon-family` marker without Markdown backticks around `geom_sf()` so exact source and generated checks can find it reliably.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made test file path resolution robust**
- **Found during:** Task 2 focused test run
- **Issue:** `testthat::test_file()` evaluated from a test working directory and could not find `vignettes/gg2d3.Rmd`.
- **Fix:** `read_text_file()` and `expect_existing_path()` now also resolve paths through `../..`.
- **Files modified:** `tests/testthat/test-pkgdown-site.R`
- **Verification:** Focused pkgdown test exits 0.
- **Committed in:** `c82cf22`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope change; the fix makes the planned source/generated file checks portable across focused and full test runs.

## Issues Encountered

The exact `geom_sf() supports polygon-family` marker was initially interrupted by Markdown code backticks. The source text was adjusted so exact marker checks match the prose users see after rendering.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 56-02 can add the artifact taxonomy and workflow dependency evidence. Plan 56-03 can later activate mandatory generated-output checks against rebuilt `docs/`.

## Self-Check: PASSED

---
*Phase: 56-pkgdown-content-and-widget-build-contract*
*Completed: 2026-05-31*
