# Phase 15-01 Summary: coord_flip Correctness Hardening

## Status
- **Plan:** 01 of 01
- **Type:** Execute
- **Status:** COMPLETED
- **Date:** 2026-03-31

## Key Accomplishments
- **Bug Fix (COORD-01 & COORD-02):** Fixed a critical bug in `renderPanel` (JS) where flipped axes in faceted plots were rendered on the wrong sides. Swapped `d3.axis` generators correctly when `flip` is true.
- **R Consolidation:** Simplified `as_d3_ir.R` by moving `is_flip` detection to the top and removing redundant checks.
- **Discrete Scale Robustness:** Improved `as_d3_ir` to correctly handle discrete scales in panel metadata (`panels_ir`), ensuring that categorical levels are preserved for layout calculations.
- **Validation Hardening:** Updated `validate_ir.R` to allow categorical domains of any length, preventing false-positive warnings for discrete scales.
- **Regression Coverage:** Created `tests/testthat/test-coord-flip.R` with 19 new assertions covering single-panel, `facet_wrap`, and `facet_grid` scenarios with `coord_flip`.
- **Geom Consistency:** Unified `GeomCol` and `GeomBar` treatment by mapping both to "bar" in the IR for consistent orientation handling.

## Verification Results
- **Automated Tests:** `devtools::test(filter = 'coord-flip')` passed with 19 successful assertions and 0 warnings.
- **JS Syntax:** Validated `inst/htmlwidgets/gg2d3.js` for syntax correctness.
- **Visual Artifacts:** Generated `test_output/test_coord_flip_combined.html` confirming correct axis placement for both wrapped and grid facets.

## Discovered Issues & Fixes
- **Discrete Scale Class:** Found that `inherits(s, "ScaleDiscrete")` is not reliable; switched to `s$is_discrete()` for all scale type checks.
- **Invalid X-Range Warning:** Discovered that `validate_ir` was too strict about range lengths; relaxed it to support categorical level vectors.

## Final Review
- `coord_flip` now produces visually correct and test-verified output across all supported layout modes.
- Milestone v1.1 Interactive Exploration is now functionally complete.
