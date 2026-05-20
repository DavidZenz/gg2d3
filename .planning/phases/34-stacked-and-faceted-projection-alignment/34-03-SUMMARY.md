---
phase: 34-stacked-and-faceted-projection-alignment
plan: 03
subsystem: tests
tags: [geom_sf, facets, projection, regression-tests]
requires:
  - phase: 34-stacked-and-faceted-projection-alignment
    plan: 01
    provides: panel-keyed sf_bbox metadata
  - phase: 34-stacked-and-faceted-projection-alignment
    plan: 02
    provides: sf renderer bbox handoff
provides:
  - facet_wrap sf bbox isolation regression coverage
  - facet_grid sf layout and empty-panel regression coverage
  - targeted Phase 34 test suite verification
affects: [geom_sf, facets, testthat]
tech-stack:
  added: []
  patterns: [far-apart sf facet fixtures, optional spatial package skips]
key-files:
  created: []
  modified:
    - tests/testthat/test-facets.R
    - tests/testthat/test-facet-grid.R
key-decisions:
  - "Facet sf tests use far-apart valid lon/lat polygons so bbox leakage is numerically obvious without projection warnings."
  - "Empty facet_grid panels assert NULL sf_bbox rather than inheriting global geometry."
patterns-established:
  - "Panel lookup helpers keep facet assertions tied to facet labels instead of panel ordering assumptions."
requirements-completed: [SFREND-02, SFREND-03]
duration: unknown
completed: 2026-05-20
---

# Phase 34-03: Faceted sf Regression Coverage Summary

Plan 03 locked Phase 34 behavior with regression tests for stacked and faceted sf projection alignment.

## Accomplishments

- Added `facet_wrap()` sf coverage with two far-apart panels and per-panel `sf_bbox` assertions.
- Added `facet_grid()` sf coverage with a missing panel, integer layout assertions, per-panel `sf_bbox` assertions, and `NULL` bbox behavior for the empty panel.
- Kept the tests guarded by optional `sf` and `geojsonsf` skips.
- Ran the targeted Phase 34 suite across IR, renderer, wrap facet, and grid facet tests.

## Task Commits

| Task | Commit | Notes |
|------|--------|-------|
| 1-3 | `0c2c311` | Added facet regression tests and verified the targeted Phase 34 suite together. |

## Deviations from Plan

**[Scope] No `test-sf-visual.R` changes** - Existing visual fixture coverage already includes `geom_sf`, and browser/DOM visual hardening is the explicit scope of Phase 35. Phase 34 stayed focused on automated IR/source-contract coverage.

**Total deviations:** 1 scope note. **Impact:** Low; automated Phase 34 requirements are covered and visual QA remains planned.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-facets.R")'` - passed
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-facet-grid.R")'` - passed
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R")'` - passed

## Self-Check: PASSED

---
*Phase: 34-stacked-and-faceted-projection-alignment*
*Completed: 2026-05-20*
