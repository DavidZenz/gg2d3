---
phase: 45-rect-and-tile-edge-closure
verified: 2026-05-24T19:59:56Z
status: passed
requirements: [RECT-01, RECT-02]
---

# Phase 45: Rect And Tile Edge Closure Verification

## Goal Achievement

Phase 45 closes the v1.10 deferred rect/tile out-of-bounds item with focused evidence. Plan 45-01 built the fixture matrix and classification artifact. Plan 45-02 fixed the confirmed D3-boundary mismatches and kept ggplot2-compatible behavior closed as tested non-issues.

Confirmed fixes:

- `inst/htmlwidgets/modules/geoms/rect.js`: categorical tiles use band center values for position and `bandwidth()` for dimensions; rects also honor stroke/linewidth accessors.
- `inst/htmlwidgets/modules/geom-registry.js`: `rect.geom-rect` updates now have explicit band-scale and `coord_flip()` branches matching the rect renderer.

Closed non-issues:

- Scale-limit censoring can produce `NA` bounds before rendering and is preserved by `as_d3_ir()`.
- `coord_cartesian()` preserves finite bounds for SVG clipping.
- Reversed-scale and faceted rect/tile cases retain finite IR/source contracts without requiring screenshot or browser-only evidence.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RECT-01 | Complete | `tests/testthat/test-rect-tile-ir.R` covers continuous scale limits, `coord_cartesian()` limits, discrete `geom_tile()` limits, reversed scales, `coord_flip()`, and facets. |
| RECT-02 | Complete | `tests/testthat/test-rect-tile-renderer.R`, `rect.js`, `geom-registry.js`, and `45-RECT-TILE-CLASSIFICATION.md` record the fixes and tested non-issue closures. |

Detailed classification source: `45-RECT-TILE-CLASSIFICATION.md`.

## Commands Run

| Command | Status | Notes |
|---------|--------|-------|
| `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | PASS | Targeted IR/source suite passed after Task 1. |
| `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | PASS | Task 2 browser-smoke disposition source test passed. |
| `rtk env NOT_CRAN=true Rscript --vanilla -e 'if (file.exists("tests/testthat/test-rect-tile-browser.R")) { pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-browser.R") }'` | PASS | No browser file was created because the classification had no remaining browser-required case; command exited cleanly. |
| `rtk rg -n "Phase 45\|RECT-02\|45-RECT-TILE-CLASSIFICATION\|screenshot/perceptual\|Transformed scales" vignettes/d3-drawing-diagnostics.md .planning/phases/45-rect-and-tile-edge-closure/45-VERIFICATION.md` | PASS | Documentation markers are present in diagnostics and verification notes. |

## Classification Outcome

| Case | Outcome |
|------|---------|
| continuous_scale_limits | closed as non-issue with tests |
| coord_cartesian_limits | closed as non-issue with tests |
| discrete_tile_grid_limits | fixed in rect.js |
| reversed_scale_rect | closed as non-issue with tests |
| coord_flip_rect | fixed in geom-registry.js |
| faceted_rect_tile | closed as non-issue with tests |

Screenshot/perceptual diffs were not introduced per D-08. Browser DOM smoke was not added because source/IR tests resolved the remaining questions and the classification contains no unresolved browser-smoke gate.

Transformed scales remain skipped per D-03. The Phase 45 evidence did not pull transformed-scale expansion into the rect/tile closure scope.

## Residual Risks

- Phase 45 does not claim broad transformed-scale rect/tile parity; that remains outside this phase unless future evidence reopens it.
- Phase 47 is still responsible for broader README/public documentation wording for the v1.11 geometry-parity support contract.
- Browser availability was not required for this plan because no live-DOM-only question remained after renderer/update source fixes.
