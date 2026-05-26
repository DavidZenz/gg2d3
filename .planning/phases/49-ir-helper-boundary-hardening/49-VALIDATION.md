---
phase: 49-ir-helper-boundary-hardening
created: 2026-05-26
status: executed
source: 49-RESEARCH.md
---

# Phase 49 Validation Strategy

## Validation Architecture

Phase 49 validates helper-boundary hardening through three layers:

1. **Boundary-level characterization tests** in `tests/testthat/test-ir-helper-boundaries.R`.
2. **Existing representative IR suites** covering non-sf, facets, date/time scales, sf, and annotations.
3. **Optional rendered smoke confidence** through Phase 48 browser visual smoke when local browser dependencies can launch.

## Required Checks

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R"); testthat::test_file("tests/testthat/test-date-scales.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

## Pass Conditions

- Named internal helper files exist and are called by `as_d3_ir()`.
- Representative IR tests pass without undocumented field or type changes.
- New helper-boundary tests fail close to the implicated boundary when scale, layer, or facet contracts change.
- Optional sf/browser checks skip explicitly when dependencies are unavailable and pass when available.

## Known Skip Conditions

- `sf` / `geojsonsf` may be unavailable locally.
- Browser visual smoke is opt-in and skips unless `GG2D3_BROWSER_VISUAL_SMOKE=true`.
- Chromote may be unable to launch inside sandboxed environments; that skip is acceptable when the message names the launch failure.

## Phase 49 Execution Notes

The required command families remain unchanged after implementation:

- Helper-boundary tests: `tests/testthat/test-ir-helper-boundaries.R`
- Core IR/facet/date tests: `test-ir.R`, `test-facets.R`, `test-facet-grid.R`, and `test-date-scales.R`
- sf/sf-annotation tests: `test-sf-ir.R` and `test-sf-annotations-ir.R`
- Browser visual smoke skip path: `test-browser-visual-smoke.R`

Local execution observed explicit `{sf}` skips where sf-dependent tests were reached without the optional dependency available.
