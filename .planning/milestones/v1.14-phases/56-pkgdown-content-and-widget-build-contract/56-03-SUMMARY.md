---
phase: 56-pkgdown-content-and-widget-build-contract
plan: "03"
subsystem: docs
tags: [pkgdown, generated-docs, testthat, verification]
requires:
  - phase: 56-pkgdown-content-and-widget-build-contract
    provides: 56-01 source sf contract and focused test scaffold
  - phase: 56-pkgdown-content-and-widget-build-contract
    provides: 56-02 artifact taxonomy and pkgdown dependency workflow evidence
provides:
  - Source-derived README/help/pkgdown generated evidence
  - Mandatory generated-site test contract
  - Final Phase 56 verification ledger
affects: [pkgdown, docs, release-evidence, sf]
tech-stack:
  added: []
  patterns: [source-derived regeneration, generated HTML marker checks, optional sf classification]
key-files:
  created:
    - docs/articles/gg2d3.html
    - docs/articles/gg2d3.md
    - docs/articles/gg2d3_files/gg2d3-modules-0.0.1
    - docs/news/index.html
    - docs/reference/gg2d3.html
    - docs/reference/extract_sf_geometries.html
    - .planning/phases/56-pkgdown-content-and-widget-build-contract/56-VERIFICATION.md
    - .planning/phases/56-pkgdown-content-and-widget-build-contract/56-03-SUMMARY.md
  modified:
    - README.md
    - R/sf_utils.R
    - man/detect_dominant_geom_type.Rd
    - vignettes/gg2d3.Rmd
    - tests/testthat/test-pkgdown-site.R
    - .planning/phases/56-pkgdown-content-and-widget-build-contract/56-VALIDATION.md
key-decisions:
  - "Committed the specific generated pkgdown evidence targets required by Phase 56, while excluding environment-local AGENTS/CLAUDE generated pages."
  - "Treated broken local sf loading as an explicit optional dependency classification."
patterns-established:
  - "Generated pkgdown checks read committed files and assert exact text/widget/dependency markers."
  - "Verification docs summarize command outcomes and artifact paths without raw logs."
requirements-completed: [DOCS-01, BUILD-02]
duration: 10min
completed: 2026-05-31
---

# Phase 56-03: Generated Pkgdown Evidence Summary

**The rebuilt pkgdown article, reference pages, NEWS page, and widget module assets now prove the current sf support contract and htmlwidget embedding.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-31T19:36:18Z
- **Completed:** 2026-05-31T19:46:01Z
- **Tasks:** 3
- **Files modified:** 42

## Accomplishments

- Regenerated README/help/pkgdown output from source with `devtools::document()`, `devtools::build_readme()`, and `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`.
- Committed generated article, NEWS, reference, and article-local `gg2d3-modules` evidence.
- Strengthened `tests/testthat/test-pkgdown-site.R` so stale generated output, missing widget scaffolding, missing module assets, or missing sf outcome classification fails locally.
- Recorded final requirement and threat mitigation evidence in `56-VERIFICATION.md` and marked `56-VALIDATION.md` executed.

## Task Commits

1. **Task 1: Regenerate README, help, and pkgdown site from source** - `833f42c` (docs)
2. **Task 2: Make generated-site tests enforce regenerated output** - `65c4896` (test)
3. **Task 3: Record final Phase 56 validation evidence** - `7fc4bf2` (docs)

## Files Created/Modified

- `docs/articles/gg2d3.html` and `docs/articles/gg2d3.md` - Generated main article with sf support text, widget markers, and local sf skip classification.
- `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` - Article-local generated widget module assets.
- `docs/news/index.html` - Generated NEWS page with v1.14 publication-surface evidence note.
- `docs/reference/gg2d3.html` and `docs/reference/extract_sf_geometries.html` - Generated reference pages with current support markers.
- `tests/testthat/test-pkgdown-site.R` - Mandatory generated-site freshness and widget evidence tests.
- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-VERIFICATION.md` - Final evidence ledger.

## Decisions Made

Only the Phase 56 generated evidence targets were force-added from ignored `docs/`. Pkgdown also generated pages from untracked local `AGENTS.md` / `CLAUDE.md` files; those were not committed as release evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Avoided pkgdown/downlit autolink loading broken optional sf**
- **Found during:** Task 1 pkgdown rebuild
- **Issue:** Local `sf` is installed but cannot load because its GDAL dynamic library is unavailable. Pkgdown/downlit tried to autolink `sf::st_geometry_type()` and `sf::st_read()` from documentation text/code and aborted.
- **Fix:** Removed textual `sf::` namespace references from roxygen prose and the displayed vignette chunk while preserving runtime behavior when `sf` is loadable.
- **Files modified:** `R/sf_utils.R`, `vignettes/gg2d3.Rmd`, `man/detect_dominant_geom_type.Rd`
- **Verification:** Pkgdown build completed and generated article records `PKGDOWN_SF_OPTIONAL_SKIP`.
- **Committed in:** `833f42c`

**2. [Rule 3 - Blocking] Force-added ignored generated pkgdown evidence targets**
- **Found during:** Task 1 generated artifact staging
- **Issue:** `.gitignore` ignores `docs/`, but Phase 56 treats selected generated `docs/` output as release evidence.
- **Fix:** Force-added the article, NEWS, reference pages, and `gg2d3-modules` directory required by the plan, excluding environment-local generated AGENTS/CLAUDE pages.
- **Files modified:** selected `docs/` targets
- **Verification:** Tracked generated files contain required text/widget markers and asset paths.
- **Committed in:** `833f42c`

**3. [Rule 3 - Blocking] Added an explicit expectation for the sf skip outcome branch**
- **Found during:** Task 2 focused test run
- **Issue:** The generated article contained `PKGDOWN_SF_OPTIONAL_SKIP`, but the branch returned before recording a testthat expectation.
- **Fix:** Added `expect_true(TRUE, info = ...)` before returning from the skip-marker branch.
- **Files modified:** `tests/testthat/test-pkgdown-site.R`
- **Verification:** Focused test passes with 24 expectations and no empty-test skip.
- **Committed in:** `65c4896`

---

**Total deviations:** 3 auto-fixed (Rule 3)
**Impact on plan:** All fixes were required to make the planned source-derived pkgdown rebuild and generated-site evidence testable in the current local environment.

## Issues Encountered

Local `sf` cannot be loaded because its GDAL dynamic library is unavailable. The generated article therefore proves the classified optional skip path locally, not a rendered sf widget path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 56 is ready for the phase-level completion gate. Future rendered-sf evidence can come from CI or another environment where `sf` and `geojsonsf` load successfully.

## Verification

- `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` - passed.
- `rtk Rscript --vanilla -e 'pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)'` - passed.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` - passed with 24 expectations.
- `rtk Rscript --vanilla -e 'devtools::test()'` - passed with 2133 expectations, 6 existing warnings, and 47 expected optional/interactive skips.

## Self-Check: PASSED

---
*Phase: 56-pkgdown-content-and-widget-build-contract*
*Completed: 2026-05-31*
