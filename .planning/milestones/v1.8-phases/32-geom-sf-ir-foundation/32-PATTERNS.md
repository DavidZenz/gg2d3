# Phase 32 Pattern Map — geom_sf IR Foundation

**Generated:** 2026-05-20
**Status:** Ready for planning

## File Targets and Closest Analogs

| Target file | Role in Phase 32 | Closest existing analog / pattern |
|-------------|------------------|-----------------------------------|
| `R/sf_utils.R` | Low-level sf geometry extraction, CRS normalization, geometry classification, diagnostics | Existing helper file already owns sf-specific behavior; keep this boundary rather than spreading sf helpers through `as_d3_ir.R`. |
| `R/as_d3_ir.R` | Integrates helper output into gg2d3 IR layer objects | Existing `GeomSf` branch around the current sf extraction code; keep branch localized. |
| `R/validate_ir.R` | Validates sf layer structure and diagnostics | Existing `known_geoms` and layer/panel validation patterns. |
| `tests/testthat/test-sf-utils.R` | Unit tests for sf helper behavior | Existing tests use real `sf` fixtures and optional dependency guards. |
| `tests/testthat/test-sf-ir.R` | Integration tests for `as_d3_ir()` sf output | Existing happy-path tests for `geom_sf`, bbox, CRS, and parallel arrays. |
| `tests/testthat/test-sf-renderer.R` | Existing row-id/parallelism tests; only touch if row identity expectations move out of IR tests | Current tests assert sequential `row_id`; Phase 32 may need to update this if source-row identity is preserved after filtering. |

## Existing Patterns to Reuse

### Optional Spatial Dependency Guards

Tests already start with:

```r
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")
```

Reuse this pattern for every sf-specific test so CI remains usable without GDAL/GEOS/PROJ optional packages.

### Dynamic Geometry Column Detection

`R/sf_utils.R` and `R/as_d3_ir.R` both account for `attr(df, "sf_column")` being missing after `ggplot_build()`, falling back to class-based `sfc` column detection. Preserve this behavior; it is a v1.7 finding and should not be replaced with hard-coded `"geometry"`.

### Real ggplot2 Builds

The tests use actual `ggplot2::ggplot_build()` / `as_d3_ir()` outputs rather than mocks. Keep new tests at that level for IR behavior; helper-only classification can use small synthetic `sfc` vectors.

### Warning Style

Existing code uses `warning(..., call. = FALSE)` and `stop(..., call. = FALSE)` for user-facing helper errors. New missing-CRS and unsupported-geometry messages should follow that style.

## Planning Constraints

- Do not modify D3 renderer/interactivity files in Phase 32.
- Do not implement stacked or faceted projection metadata in full; leave that to Phase 34.
- Do not add hard dependency semantics for `sf` or `geojsonsf`; keep Suggests/guarded behavior.
- Do not silently drop unsupported geometry rows; skipped rows must be represented in diagnostics and warnings.
