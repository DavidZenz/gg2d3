---
phase: 39-package-internals-hardening
status: passed
verified: 2026-05-22
requirements: [HARD-01, HARD-02, HARD-03]
---

# Phase 39 Verification

## Verdict

PASS. Phase 39 hardens gg2d3 package internals by extracting sf assembly
boundaries, quarantining ggplot2 private/theme/layout access behind compatibility
helpers, and adding a bounded cross-surface regression suite for representative
IR and sf renderer behavior.

## Requirement Coverage

- HARD-01: PASS. `as_d3_ir()` now delegates sf layer payload assembly to
  `sf_layer_ir_payload()` and panel bbox attachment to
  `attach_sf_panel_bboxes()`. Helper-level and end-to-end tests cover row
  identity, skipped rows, stacked sf layers, faceted sf panels, and empty-panel
  `sf_bbox` behavior.
- HARD-02: PASS. Raw private ggplot2 theme access has been removed from
  `R/as_d3_ir.R`; the unavoidable private calls are isolated in
  `R/ggplot2_compat.R` with inline comments explaining the exported-alternative
  gap. Compatibility tests cover theme, element fallback, panel axis, range,
  and label extraction.
- HARD-03: PASS. `tests/testthat/test-regression-core.R` covers representative
  non-sf geoms, sf polygon/point/line/mixed families, facets, legends, date
  scales, coord_flip, and sf renderer/interactivity source contracts.

## Evidence

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R")'`
  exited 0.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-ir.R")'`
  exited 0.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ggplot2-compat.R"); testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R")'`
  exited 0 with the expected visual-only date-scale skip.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ir.R"); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R"); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'`
  exited 0. Browser-only tests skipped cleanly under CRAN-like conditions.
- `rtk /Users/davidzenz/.codex/get-shit-done/bin/gsd-tools.cjs verify phase-completeness 39`
  reported 3 plans, 3 summaries, and no incomplete plans.
- `rtk /Users/davidzenz/.codex/get-shit-done/bin/gsd-tools.cjs verify schema-drift 39`
  reported no schema drift.
- `39-REVIEW.md` reports a clean inline code review.

## Residual Risk

Live Chrome execution was not exercised because `test-sf-browser.R` skips
CRAN-gated browser tests in this environment. The optional browser path is still
present and skip-clean; full live DOM validation depends on running the browser
suite in a non-CRAN local context with Chrome/chromote available.
