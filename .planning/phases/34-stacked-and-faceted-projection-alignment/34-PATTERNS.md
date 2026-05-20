---
phase: 34
slug: stacked-and-faceted-projection-alignment
status: complete
created: 2026-05-20
source: inline-pattern-mapping
---

# Phase 34 - Pattern Mapping

## Files and Closest Analogs

| Target File | Role | Closest Existing Pattern | Notes |
|-------------|------|--------------------------|-------|
| `R/as_d3_ir.R` | IR assembly and panel metadata | Existing facet `panels_ir` construction and current `sf_coord_geometries` collection | Extend panel entries with `sf_bbox`; preserve `coord$bbox`. |
| `R/sf_utils.R` | sf helper logic | `prepare_sf_geometry_ir()` | Add small bbox helper(s) rather than scattering `sf::st_bbox()` and empty guards through `as_d3_ir.R`. |
| `R/validate_ir.R` | IR contract validation | Existing sf layer and panel validation branches | Validate `sf_bbox` shape only for sf panels where present; keep Cartesian x/y exemptions. |
| `inst/htmlwidgets/gg2d3.js` | Panel-level rendering orchestration | Existing `renderPanel()` row filtering and `geomRegistry.render()` option passing | Filter `layer.data` and `layer.geometries` as pairs for sf; pass `sfBBox`/`panelData` in options. |
| `inst/htmlwidgets/modules/geoms/sf.js` | D3 sf path renderer | Existing layer FeatureCollection `fitExtent()` path | Keep projection mechanics but fit from panel bbox metadata when available. |
| `tests/testthat/test-sf-ir.R` | sf IR contract tests | Existing `skip_if_not_installed()` sf tests | Add stacked single-panel bbox metadata assertions. |
| `tests/testthat/test-sf-renderer.R` | JS source contract tests | Existing renderer contract tests | Assert shared bbox option consumption and geometry/data pair filtering. |
| `tests/testthat/test-facets.R` | facet_wrap tests | Existing panel metadata assertions | Add sf `facet_wrap()` panel bbox isolation tests. |
| `tests/testthat/test-facet-grid.R` | facet_grid tests | Existing layout and missing-combination assertions | Add sf grid layout, per-panel bbox, and empty panel tests. |

## Existing Local Conventions

- R-side tests use `testthat`, `pkgload::load_all(quiet = TRUE)`, and targeted `test_file()` commands.
- Optional spatial tests guard with `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")`.
- JS source-contract tests read module files with `readLines()` and assert critical strings/patterns.
- IR panel metadata is stored in `ir$panels` keyed by integer `PANEL`.
- Geom renderers accept `(layer, g, xScale, yScale, options)` and read extra renderer context from `options`.

## Implementation Constraints

- Do not introduce JS-side CRS reprojection.
- Do not add global-comparison projection mode for facets.
- Do not use non-sf layers as inputs to sf projection bboxes.
- Do not change Phase 33 tooltip, brush, handler, or zoom suppression contracts.
- Do not move existing facet layout fields or break non-sf facet tests.

## Suggested Fixtures

R helper pattern for small polygons:

```r
sf_square <- function(xmin, ymin, xmax, ymax) {
  sf::st_polygon(list(matrix(
    c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
    ncol = 2,
    byrow = TRUE
  )))
}
```

Use far-apart coordinates such as `0..1`, `100..101`, and `200..201` so bbox leakage is obvious from numeric assertions.
