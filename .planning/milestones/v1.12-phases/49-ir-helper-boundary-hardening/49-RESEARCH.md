# Phase 49: IR Helper Boundary Hardening - Research

**Researched:** 2026-05-26
**Status:** Complete

## RESEARCH COMPLETE

## Executive Summary

Phase 49 should refactor `as_d3_ir()` by extracting a small number of internal helper boundaries and locking representative IR output before each extraction. The highest-value targets are:

1. Scale, axis, and temporal metadata extraction.
2. Layer row/aesthetic/geom dispatch assembly.
3. Facet and panel metadata construction.

This keeps the phase bounded while addressing the monolithic `as_d3_ir()` risk called out in v1.12. Existing sf helper boundaries in `R/sf_utils.R` are already comparatively well isolated and should be preserved rather than churned.

## Current Code Findings

### `R/as_d3_ir.R`

`as_d3_ir()` currently owns many responsibilities in one function:

- `ggplot2::ggplot_build()` orchestration.
- coordinate detection and labels.
- discrete value mapping for x/y/xmin/xmax/ymin/ymax.
- nested rowization helpers.
- geom-name dispatch, sf annotation detection, aesthetic mapping, and var-name mapping.
- temporal data conversion.
- scale transform/domain/break extraction.
- theme extraction.
- guide extraction.
- facet/panel metadata construction.
- sf coord/panel bbox attachment.
- reverse aesthetic map construction.
- final `validate_ir(ir)`.

The highest-risk duplicated logic is temporal conversion and per-panel range/break assembly, which appears both in global scale extraction and facet panel extraction.

### `R/sf_utils.R`

sf already has useful helper boundaries:

- `prepare_sf_geometry_ir()`
- `sf_layer_data_rows()`
- `sf_layer_ir_payload()`
- `sf_annotation_layer_ir_payload()`
- `sf_panel_geometries()`
- `attach_sf_panel_bboxes()`
- `sf_bbox_values()`

These helpers have focused tests in `tests/testthat/test-sf-ir.R`, including stacked/faceted bbox contracts. Phase 49 should treat sf helpers as a reference pattern and integration surface, not as the main refactor target.

### `R/ggplot2_compat.R`

Private ggplot2 calls are already quarantined:

- `gg2d3_plot_theme()`
- `gg2d3_calc_element()`
- `gg2d3_panel_axis()`
- `gg2d3_continuous_range()`
- `gg2d3_panel_labels()`

New helper boundaries should keep using these compatibility functions instead of adding direct `ggplot2:::` calls elsewhere.

## Planning Implications

### Recommended File Strategy

Create internal helper files rather than growing `R/as_d3_ir.R` further:

- `R/ir_scale_helpers.R` for scale, axis, transform, temporal, and break conversion helpers.
- `R/ir_layer_helpers.R` for rowization, geom naming, aesthetic maps, and layer payload assembly that does not already belong to sf helpers.
- `R/ir_facet_helpers.R` for facet/panel metadata and sf panel bbox attachment integration.

Keep helper signatures explicit and local to existing `ggplot_build()` objects. Do not export these helpers.

### Recommended Test Strategy

Add `tests/testthat/test-ir-helper-boundaries.R` as a focused characterization suite. It should provide small assertion helpers that identify which boundary changed:

- scale/axis boundary: continuous, transformed, date/datetime, discrete, breaks, labels.
- layer boundary: row data, geom names, aesthetic maps, var-name maps, polygon and annotation families.
- facet boundary: wrap, grid, free scales, empty panels, sf panel bboxes when sf is available.

Existing tests remain the wider regression net. The new tests should be failure-local and avoid enormous snapshots.

### Representative Fixtures

Use existing local fixture families:

- Non-sf: `mtcars` point/line/bar/rect/text/polygon.
- Scale: `scale_x_log10()`, `scale_x_date()`, `scale_x_datetime()`, discrete x scale.
- Facets: `facet_wrap(~ cyl)`, `facet_grid(am ~ cyl)`, free scale variants.
- sf: `tests/testthat/test-sf-ir.R` patterns when `sf` and `geojsonsf` are installed.
- Annotations: `tests/testthat/test-sf-annotations-ir.R` and `geom_text()`/`geom_label()` non-sf cases.

## Validation Architecture

Phase 49 validation should prove all three success criteria:

1. **Boundary existence:** grep for named helper functions in new internal R files and confirm `as_d3_ir()` calls them.
2. **No representative IR drift:** run targeted IR tests plus the package's existing IR/facet/date/sf annotation tests.
3. **Failure locality:** add tests whose expectation messages or test names identify the implicated boundary, e.g. "scale helper preserves date domains" or "facet helper preserves free-grid panel ranges."

Required verification commands:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R"); testthat::test_file("tests/testthat/test-date-scales.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The sf command may skip or partially skip in dependency-limited environments, but it must not fail because of Phase 49 changes.

## Security Notes

This phase does not add a network, filesystem, browser, or user-input surface. The main safety risk is integrity: accidental IR drift can produce incorrect browser rendering. Plans should include threat-model entries around internal helper misuse, package-version fragility, and optional dependency behavior.

## Open Questions Resolved By Context Defaults

- **How broad should the refactor be?** Narrow helper boundaries, not full rewrite.
- **Should helpers be public?** No, internal only.
- **Should sf helpers be rewritten?** No, preserve and characterize integration.
- **Should behavior fixes be included?** Only tiny unavoidable fixes; otherwise document and defer to Phase 51.

