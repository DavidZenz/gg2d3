---
phase: 32
slug: geom-sf-ir-foundation
status: complete
created: 2026-05-20
---

# Phase 32 Research — geom_sf IR Foundation

## Research Question

What does the executor need to know to harden the R-side `geom_sf` IR path without drifting into D3 rendering, interactivity, stacked projection, or facet projection scope?

## Existing Implementation

Phase 32 starts from a working v1.7 prototype rather than from blank slate:

- `R/sf_utils.R` already contains `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, and `get_layer_crs()`.
- `R/as_d3_ir.R` already maps `GeomSf` to `"sf"`, normalizes geometry columns to WGS84, serializes GeoJSON, emits `row_id`, stores CRS metadata, and computes `coord$bbox`.
- `R/validate_ir.R` already recognizes `"sf"` as a known geom and suppresses Cartesian panel range warnings for `coord$type == "sf"`.
- `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-utils.R`, and `tests/testthat/test-sf-renderer.R` already cover the happy path, CRS normalization, bbox shape, and data/geometry parallelism.

## Key Findings

### 1. Filtering Belongs Before Serialization

Unsupported, empty, invalid, or missing geometries should be classified while they are still `sfc` objects. That lets the code use `sf::st_geometry_type()`, `sf::st_is_empty()`, and `sf::st_is_valid()` before converting rows to GeoJSON strings.

The safest shape is a helper that returns both the filtered geometry column and diagnostics, for example:

- accepted row positions
- skipped row positions
- skipped geometry types/reasons
- missing CRS flag
- normalized CRS metadata

The exact helper name is flexible, but the behavior must keep `data` and `geometries` parallel after filtering.

### 2. Missing CRS Should Warn, Not Block

`normalize_to_wgs84()` currently leaves missing CRS inputs unchanged because `sf::st_crs()` is `NA`. That is consistent with the Phase 32 context, but it is silent. The production behavior should warn clearly when CRS is missing and then serialize as-is.

Test expectation should assert a warning pattern such as `"missing CRS"` rather than exact punctuation.

### 3. Diagnostics Should Be Layer-Local

Phase 32 should not implement the richer panel projection model reserved for Phase 34. It should, however, expose sf diagnostics at the layer level so future renderer and docs phases can inspect what happened.

Recommended IR shape:

```r
layer$sf_diagnostics <- list(
  accepted_rows = <integer vector>,
  skipped_rows = <integer vector>,
  skipped = <list of row/type/reason entries>,
  missing_crs = <TRUE/FALSE>,
  accepted_geometry_types = <character vector>,
  unsupported_geometry_types = <character vector>
)
```

The planner/executor can choose exact field names, but tests should prove equivalent visibility exists.

### 4. `row_id` Should Represent Source Row Identity

The current prototype sets `row_id <- seq_along(sf_geom_strings)`. Once unsupported rows are skipped, this would lose source row identity. To keep interactivity and diagnostics stable, `row_id` should refer to the original built-data row number. If rows 2 and 4 are skipped, valid rows should retain `row_id` values like `1, 3, 5`, not be renumbered to `1, 2, 3`.

This still keeps `data` and `geometries` arrays parallel because both arrays contain only accepted rows in the same order.

### 5. Tests Should Use Real sf Objects

Existing sf tests use real `sf` and `geojsonsf` behavior with `skip_if_not_installed()` guards. Continue this pattern. Useful fixtures:

- `sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)` for `MULTIPOLYGON`.
- Small synthetic `sfc` vectors for mixed `POLYGON`, `POINT`, empty, invalid, and missing CRS cases.
- Existing EPSG:3857 transform test for WGS84 normalization.

## Validation Architecture

### Test Types

- **Unit/helper tests:** `tests/testthat/test-sf-utils.R`
  - polygon-family classification
  - unsupported geometry diagnostics
  - missing CRS warning
  - valid geometry retention

- **IR integration tests:** `tests/testthat/test-sf-ir.R`
  - `as_d3_ir()` filters unsupported rows
  - `row_id` preserves source row identity
  - `data` and `geometries` remain parallel
  - layer diagnostics exist and include skipped row details
  - known CRS still normalizes to EPSG:4326

- **Validation tests:** `tests/testthat/test-sf-ir.R` or a small addition to existing validation coverage
  - `validate_ir()` accepts sf layers with diagnostics
  - malformed sf diagnostics produce clear warnings/errors if validation is extended

### Recommended Commands

Quick feedback:

```r
testthat::test_file("tests/testthat/test-sf-utils.R")
testthat::test_file("tests/testthat/test-sf-ir.R")
```

Full package feedback:

```r
devtools::test()
```

### Manual Validation

No browser/manual validation is required for Phase 32. Browser validation belongs to renderer/interactivity phases after D3 behavior changes.

## Planning Recommendation

Use two sequential plans:

1. **Helper hardening:** update `R/sf_utils.R` and helper tests so polygon-family filtering, missing CRS warnings, and diagnostics are available.
2. **IR integration:** update `R/as_d3_ir.R`, `R/validate_ir.R`, and IR tests so filtered sf rows and diagnostics flow into production IR.

This sequence lets Plan 2 consume helper behavior from Plan 1 and avoids splitting overlapping edits to `R/as_d3_ir.R`.
