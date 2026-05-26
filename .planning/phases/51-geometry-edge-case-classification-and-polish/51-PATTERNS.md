# Phase 51: Geometry Edge-Case Classification And Polish - Patterns

**Mapped:** 2026-05-26
**Scope:** Plan-shaping conventions for rect/tile, polygon, text/label, and validation evidence.

## Key Patterns

- Rect/tile work should extend the existing ggplot-build-vs-IR fixture matrix in `tests/testthat/test-rect-tile-ir.R` and the JavaScript source-contract checks in `tests/testthat/test-rect-tile-renderer.R`.
- Polygon topology work should preserve the existing grouped closed-path contract: one `path.geom-polygon` per built `group`, vertices in ggplot2 built row order, no sorting, no GIS topology repair.
- Text/label polish should follow the ordinary renderer/source-test pattern, with sf annotation helpers used only as local analogs for alignment, size, and font-style handling.
- Optional browser proof should reuse the Phase 48 visual smoke conventions: opt-in via `GG2D3_BROWSER_VISUAL_SMOKE=true`, generated artifacts under ignored `test_output/`, and explicit skip reasons for Chrome/Chromote or optional spatial dependencies.
- Phase 51 plans should follow recent Phase 50 plan shape: frontmatter with requirement coverage, XML-ish task blocks, concrete `read_first` files, automated verification commands, a threat model, final verification, and summary-file output.

## Existing Test Analogues

| Surface | Closest Existing Pattern | Phase 51 Use |
|---------|--------------------------|--------------|
| Rect/tile IR classification | `tests/testthat/test-rect-tile-ir.R` | Add log/sqrt/reverse transformed-scale fixtures that compare `ggplot_build()` rows with `as_d3_ir()` rows. |
| Rect/tile renderer source contract | `tests/testthat/test-rect-tile-renderer.R` | Guard any D3-boundary change in both initial render and `updateGeoms()` paths. |
| Polygon IR contract | `tests/testthat/test-polygon-ir.R` | Add subgroup/hole/ring-order classification fixtures and lock supported grouped-path semantics. |
| Polygon renderer contract | `tests/testthat/test-polygon-renderer.R` | Keep no-sort, closed-path, finite-point, and update-path guarantees explicit. |
| Polygon browser proof | `tests/testthat/test-polygon-browser.R` | Optional DOM evidence for supported polygon cases, not the only proof. |
| Text/label renderer | `inst/htmlwidgets/modules/geoms/text.js` plus source tests | Add a focused text/label polish test file if implementing ordinary text size/alignment/angle. |
| sf annotation analogs | `inst/htmlwidgets/modules/geoms/sf.js` | Borrow small helper ideas for text alignment/style only when source-local. |
| Final evidence | Phase 50 `50-VALIDATION.md` | Record commands, pass/skip outcomes, and the final geometry support/non-goal contract. |

## File Naming

- Plan files: `51-01-PLAN.md`, `51-02-PLAN.md`, `51-03-PLAN.md`, `51-04-PLAN.md`.
- Summary files: `51-01-SUMMARY.md` through `51-04-SUMMARY.md`.
- Validation file: `51-VALIDATION.md`.
- Generated HTML/smoke artifacts: keep under `test_output/`, preferably using `phase51-...` prefixes.

## Local Corrections

The Phase 51 context mentions stale helper names:

- Use `R/ir_scale_helpers.R`, not `R/ir_helpers_scales.R`.
- Use `R/ir_layer_helpers.R`, not `R/ir_helpers_layers.R`.

## Planning Implications

1. Rect/tile transformed scales should be classified before changing scale or renderer code. If the evidence points to double-transform behavior, the fix must cover both initial rendering and zoom/update paths or be documented as too broad for Phase 51.
2. Polygon holes and subgroups must not be described as supported unless tests prove both IR preservation and renderer behavior. Unsupported topology is an acceptable outcome when recorded explicitly.
3. Text/label work should attempt at most one small improvement. Current evidence suggests ordinary text `size` is lower risk than true `geom_label()` boxes, collision avoidance, or path-following labels.
4. Final validation should be a separate dependent slice so parallel classification plans can finish before documentation and evidence are consolidated.

## PATTERN MAPPING COMPLETE
