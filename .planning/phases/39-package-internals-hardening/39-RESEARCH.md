---
phase: 39-package-internals-hardening
status: complete
created: 2026-05-22
requirements: [HARD-01, HARD-02, HARD-03]
researcher: inline-codex
---

# Phase 39 Research: Package Internals Hardening

## Objective

Research how to plan Phase 39 so maintainers can evolve sf and core renderer
internals with lower regression risk while preserving behavior delivered in
Phases 36-38.

## Current Architecture Findings

### `as_d3_ir()` Risk Concentration

`R/as_d3_ir.R` is still the central orchestration point for ggplot build data,
scale extraction, theme extraction, guide extraction, facet/panel assembly, sf
layer preparation, and final IR assembly. The sf behavior itself is partly
extracted already:

- `R/sf_utils.R` contains `prepare_sf_geometry_ir()`, `sf_supported_geometry_types()`,
  `sf_geometry_family()`, `sf_bbox_values()`, `normalize_to_wgs84()`,
  `detect_dominant_geom_type()`, and `get_layer_crs()`.
- `R/as_d3_ir.R` still owns sf layer IR assembly, sf coordinate bbox aggregation,
  and panel-local `sf_bbox` attachment through local `sf_coord_geometries` and
  `sf_panel_geometries` state.

This means HARD-01 should not move all sf logic. It should extract the remaining
assembly boundary from `as_d3_ir()` while leaving the existing `prepare_sf_geometry_ir()`
contract intact.

### Private ggplot2 API Use

Current private API access in `R/as_d3_ir.R` includes:

- `ggplot2:::calc_element()` for theme elements, legend position, panel spacing,
  and legend key size.
- `ggplot2:::plot_theme()` to resolve the plot theme.

The code also relies on ggplot build internals such as `b$layout$panel_params`,
`b$layout$layout`, `b$layout$facet$params`, and scale object methods. These are
not all private triple-colon calls, but they are version-sensitive.

HARD-02 should centralize triple-colon access behind private wrapper helpers and
add characterization tests for the behaviors currently consumed by `as_d3_ir()`.
It should avoid changing the final IR format.

### Regression Coverage State

Existing tests already cover many pieces:

- `tests/testthat/test-sf-ir.R`, `test-sf-utils.R`, `test-sf-renderer.R`,
  `test-sf-interactivity.R`, and `test-sf-browser.R` cover sf behavior.
- `tests/testthat/test-ir.R`, `test-facets.R`, `test-legends.R`,
  `test-date-scales.R`, `test-coord-flip.R`, `test-layout.R`, and renderer
  module tests cover important non-sf behavior.

The gap for HARD-03 is not absence of tests, but lack of one explicit regression
contract that maintainers can run after internals refactors to prove broad IR
surfaces stayed stable.

## Recommended Plan Shape

### Plan 39-01: sf IR Helper Boundaries

Add characterization tests first, then extract two internal helper seams:

- `sf_layer_ir_payload(df, aes, params, var_names)` in `R/sf_utils.R`, returning
  the final sf layer IR plus accepted geometry/panel metadata needed by `as_d3_ir()`.
- `attach_sf_panel_bboxes(panels, sf_panel_geometries)` in `R/sf_utils.R`, adding
  panel-local `sf_bbox` fields.

Keep `prepare_sf_geometry_ir()` as the canonical lower-level geometry prep API.
The executor should make `as_d3_ir()` delegate assembly without changing public IR.

### Plan 39-02: ggplot2 Compatibility Helpers

Introduce `R/ggplot2_compat.R` with wrappers:

- `gg2d3_plot_theme(plot)`
- `gg2d3_calc_element(element_name, theme, default = NULL)`
- `gg2d3_panel_axis(panel_params, axis)`
- `gg2d3_continuous_range(panel_params_axis)`
- `gg2d3_panel_labels(panel_params_axis)`

Then replace direct `ggplot2:::` calls in `R/as_d3_ir.R` with the wrappers.
Add tests that verify current theme, legend position, panel spacing, tick labels,
and coord_flip/date-scale behavior stay stable.

### Plan 39-03: Cross-Surface Regression Contracts

Add a focused regression suite that builds representative plots and asserts
stable IR surfaces:

- non-sf point/line/bar/rect/text/statistical/reference geoms
- polygon, point, line, mixed sf
- facets and empty panels
- legends
- date scales
- coord_flip
- known renderer/interactivity source contracts

This should be additive test coverage, not a snapshot system that becomes noisy.

## Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Refactor changes sf row/geometry alignment | high | Add HARD-01 characterization tests before helper extraction. |
| Panel-local sf bbox aggregation regresses facets | high | Keep browser/IR facet tests in verification and add helper-specific tests. |
| ggplot2 compatibility wrappers mask errors too broadly | medium | Wrapper tests must assert both successful extraction and explicit fallback behavior. |
| Regression suite becomes slow or brittle | medium | Use small deterministic plots and existing package datasets; keep browser tests optional. |
| Broad `as_d3_ir()` cleanup changes unrelated behavior | high | Limit Phase 39 to helper extraction and characterization, not stylistic rewrite. |

## Validation Architecture

The validation strategy should use existing testthat infrastructure:

- Quick per-task commands:
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R")'`
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'`
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ir.R")'`
- Plan-level commands:
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R")'`
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R")'`
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-regression-core.R")'`
- Phase-level command:
  - `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ir.R"); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R"); testthat::test_file("tests/testthat/test-regression-core.R")'`

Browser tests remain optional and may skip via `skip_on_cran()` in this local
Rscript context.

## Planning Notes

- This phase should produce three executable plans, one per HARD requirement.
- Plans should be sequential enough that regression coverage can reference
  helper names introduced earlier.
- The implementation should avoid changing JavaScript renderer behavior unless
  tests expose a necessary source guard update.

