---
phase: 37-non-polygon-sf-ir-and-renderer
plan: 04
status: complete
completed: 2026-05-21
requirements: [SFGEOM-01, SFGEOM-02, SFGEOM-03, SFGEOM-04]
commits:
  - 2004941 test(37-04): add sf browser fixtures
  - 0b40f1d test(37-04): add sf browser DOM mark coverage
---

# Plan 37-04 Summary

Added deterministic Phase 37 browser fixtures for point-only, line-only, polygon+point overlay, polygon+line overlay, mixed skipped rows, and faceted empty-panel sf plots. The browser helper now polls all `.geom-sf` marks and returns path/circle DOM attributes for live smoke assertions while keeping the older `wait_for_sf_paths()` polygon helper intact.

Declared direct test helper dependencies `pkgload` and `rprojroot` in `Suggests`, preserved optional `chromote`, and avoided new runtime browser dependencies.

## Verification

- `rtk Rscript --vanilla -e 'source("tests/testthat/helper-sf-fixtures.R"); fixtures <- .phase37_sf_fixture_set(); stopifnot(length(fixtures) == 6L, all(file.exists(unlist(fixtures))))'` passed.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` completed cleanly with browser skips in this environment.
- Full Phase 37 suite passed: IR, renderer, interactivity, and browser tests.

## Self-Check

PASSED. Browser fixture coverage now represents point, line, mixed, overlay, skipped-row, facet, and polygon regression behavior without introducing new browser tooling.
