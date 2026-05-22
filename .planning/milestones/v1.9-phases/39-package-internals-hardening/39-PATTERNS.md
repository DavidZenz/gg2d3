---
phase: 39-package-internals-hardening
status: complete
created: 2026-05-22
mapper: inline-codex
---

# Phase 39 Pattern Map

## Files and Roles

| File | Current Role | Phase 39 Pattern |
|------|--------------|------------------|
| `R/as_d3_ir.R` | Main ggplot2-to-IR orchestration function | Keep orchestration; delegate sf assembly and ggplot2 compatibility details to helpers. |
| `R/sf_utils.R` | Existing sf geometry prep utilities | Extend with internal sf layer/panel assembly helpers; do not duplicate geometry filtering. |
| `R/ggplot2_compat.R` | New internal helper file | Centralize ggplot2 private/version-sensitive access and fallback behavior. |
| `tests/testthat/test-sf-utils.R` | Unit tests for sf helpers | Add HARD-01 helper-level tests before refactor behavior changes. |
| `tests/testthat/test-sf-ir.R` | End-to-end sf IR contracts | Add/retain assertions proving extraction has no IR drift. |
| `tests/testthat/test-ggplot2-compat.R` | New compatibility tests | Characterize wrappers and fallback semantics around theme/panel extraction. |
| `tests/testthat/test-regression-core.R` | New broad regression contract | Exercise representative non-sf, sf, facet, legend, date, coord_flip, and renderer-edge IR surfaces. |

## Existing Helper Style

R helpers in this package are plain functions, often unexported unless user
facing. `R/sf_utils.R` already mixes exported compatibility helpers
(`extract_sf_geometries()`, `normalize_to_wgs84()`) with internal noRd helpers
(`prepare_sf_geometry_ir()`, `sf_bbox_values()`). Phase 39 should continue that
pattern: internal assembly helpers should not be exported unless documentation
already exposes them.

## Existing Test Style

Tests use `testthat::test_file()` directly, `skip_if_not_installed()` for
optional spatial/browser dependencies, and precise structural expectations
rather than broad snapshots. New tests should follow that style.

## Closest Analogs

- `prepare_sf_geometry_ir()` is the analog for new sf assembly helpers: it
  returns structured data, diagnostics, and geometry with row identity.
- `validate_ir()` tests are the analog for broad regression guardrails:
  deliberately mutate IR and assert warnings.
- `test-layout.R`, `test-legends.R`, `test-date-scales.R`, and `test-coord-flip.R`
  are the analogs for ggplot2 compatibility characterization.

## Recommended Names

- `sf_layer_ir_payload()`
- `sf_panel_geometry_map()`
- `attach_sf_panel_bboxes()`
- `gg2d3_plot_theme()`
- `gg2d3_calc_element()`
- `gg2d3_panel_axis()`
- `gg2d3_continuous_range()`
- `gg2d3_panel_labels()`

These names are intentionally private-style but readable in `as_d3_ir()`.

