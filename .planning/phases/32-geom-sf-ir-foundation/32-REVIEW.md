---
phase: 32-geom-sf-ir-foundation
status: clean
depth: standard
files_reviewed: 5
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
resolved_findings: 1
created: 2026-05-20
---

# Phase 32 Code Review

Review scope:

- `R/as_d3_ir.R`
- `R/sf_utils.R`
- `R/validate_ir.R`
- `tests/testthat/test-sf-ir.R`
- `tests/testthat/test-sf-utils.R`

## Result

No open issues remain after review.

## Resolved During Review

### WR-001: `coord$bbox` included skipped sf geometries

**Severity:** warning

`as_d3_ir()` filtered unsupported sf rows through `prepare_sf_geometry_ir()`, but the sf coordinate bbox was still computed from raw `ggplot_build()` layer data. A skipped far-away `POINT` could therefore expand `coord$bbox` even though the point was absent from `layer$data` and `layer$geometries`.

**Fix:** `R/as_d3_ir.R` now accumulates accepted helper geometries during layer construction and computes sf `coord$bbox` from those accepted geometries only.

**Verification:** `tests/testthat/test-sf-ir.R` now asserts that a skipped far-away `POINT` does not expand the bbox, and both sf utility and sf IR test files pass.

## Verification Reviewed

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R")'`
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R")'`

## Residual Risk

Full package tests still have unrelated pre-existing failures outside Phase 32. The sf-specific contexts pass after the review fix.
