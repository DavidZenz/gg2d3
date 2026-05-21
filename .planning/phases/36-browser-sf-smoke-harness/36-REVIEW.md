---
phase: 36-browser-sf-smoke-harness
reviewed: 2026-05-21T08:12:55Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - DESCRIPTION
  - tests/testthat/helper-sf-fixtures.R
  - tests/testthat/helper-browser-sf.R
  - tests/testthat/test-sf-visual.R
  - tests/testthat/test-sf-browser.R
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 36: Code Review Report

**Reviewed:** 2026-05-21T08:12:55Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the sf visual/browser smoke-test harness, shared fixtures, and package DESCRIPTION. No security issues were found. Two test-maintenance issues need attention: newly used test helper namespaces are not declared directly, and one browser facet assertion discards panel identity before comparing counts.

## Warnings

### WR-01: Direct test helper dependencies are not declared

**File:** `DESCRIPTION:20`
**Issue:** The reviewed helpers call `pkgload::load_all()` in `tests/testthat/helper-sf-fixtures.R:4`, `tests/testthat/helper-browser-sf.R:4`, and `tests/testthat/test-sf-browser.R:4`, and call `rprojroot::find_package_root_file()` in `tests/testthat/helper-sf-fixtures.R:10`. Neither `pkgload` nor `rprojroot` is declared in `DESCRIPTION`. On this machine they are available transitively through `testthat`, but direct `::` usage should be listed explicitly so clean test environments do not depend on another package's dependency graph.
**Fix:**
```r
Suggests:
    testthat (>= 3.0.0),
    pkgload,
    rprojroot,
    chromote (>= 0.5.1),
    crosstalk,
    sf (>= 1.0.0),
    geojsonsf (>= 2.0.0),
    rnaturalearth
```

### WR-02: Facet panel-count test loses panel identity

**File:** `tests/testthat/test-sf-browser.R:255`
**Issue:** The test named "faceted sf fixtures keep panel-local path counts" sorts `panel_counts` before comparison. That only verifies the multiset of empty/non-empty panels, so a regression that renders the sf paths into the wrong facet panels can still pass as long as two panels contain one path and two panels contain none.
**Fix:**
```r
expected_panel_counts <- list(
  "phase35-sf-facet-wrap.html" = c(1L, 1L),
  "phase35-sf-facet-grid.html" = c(1L, 0L, 0L, 1L)
)

expect_equal(panel_counts, expected_panel_counts[[fixture_name]])
```

Use the renderer's documented DOM panel order for the expected vector if it differs from row-major order.

---

_Reviewed: 2026-05-21T08:12:55Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
