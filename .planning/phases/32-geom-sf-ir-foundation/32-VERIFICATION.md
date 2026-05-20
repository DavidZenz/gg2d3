---
phase: 32-geom-sf-ir-foundation
status: passed
verified: 2026-05-20
requirements: [SFIR-01, SFIR-02, SFIR-03]
automated_checks:
  passed: 3
  failed: 0
human_verification: []
gaps: []
---

# Phase 32 Verification

## Verdict

Phase 32 achieved its goal: the R-side `geom_sf` IR path now extracts polygon-family sf layers into stable, validated gg2d3 IR with WGS84 normalization, bbox metadata, skipped-row diagnostics, and row/geometry alignment.

## Requirement Verification

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SFIR-01 | Passed | `R/as_d3_ir.R` routes `geom_sf` through `prepare_sf_geometry_ir()`, emits `geometries`, `data`, `geom_type`, CRS metadata, and `sf_diagnostics`; `tests/testthat/test-sf-ir.R` covers NC multipolygons and mixed polygon/non-polygon sf input. |
| SFIR-02 | Passed | `prepare_sf_geometry_ir()` normalizes accepted known-CRS geometries through `normalize_to_wgs84()` and warns/serializes as-is for missing CRS; helper and IR tests assert both behaviors. |
| SFIR-03 | Passed | `prepare_sf_geometry_ir()` skips unsupported, empty, invalid, or missing geometries, records `accepted_rows`, `skipped_rows`, skipped reasons, and unsupported geometry types, and preserves original source `row_id` values. |

## Must-Have Verification

- `prepare_sf_geometry_ir()` exists in `R/sf_utils.R` with `supported_types = c("POLYGON", "MULTIPOLYGON")`.
- Helper filtering uses `sf::st_geometry_type(..., by_geometry = TRUE)`, `sf::st_is_empty()`, and `sf::st_is_valid()`.
- `as_d3_ir()` uses helper-returned `data`, `geometries`, `crs`, `geom_type`, and `sf_diagnostics` for sf layers.
- sf `row_id` values are sourced from helper-filtered data and are not renumbered after unsupported rows are skipped.
- `validate_ir()` checks sf layer `geometries`, geometry/data length parity, and required diagnostics fields.
- sf `coord$bbox` is computed from accepted helper geometries only, so skipped unsupported geometry does not distort map fitting.

## Automated Checks

Passed:

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R")'`
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R")'`
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE); ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf()); validate_ir(ir); stopifnot(ir$layers[[1]]$geom == "sf")'`

Full-suite note:

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); devtools::test()'` was run. Phase 32 sf contexts passed. The suite still has unrelated existing failures in interactivity opacity, coord_trans/coord_fixed expectations, and theme legend margin extraction.

## Code Review

Status: clean after one review-found fix.

Resolved issue:

- `coord$bbox` initially still included raw skipped sf geometries. Fixed in `R/as_d3_ir.R` and covered by `tests/testthat/test-sf-ir.R`.

## Open Gaps

None.

## Human Verification

None required. Browser rendering and visual validation are deferred to Phase 33+.

---
*Phase: 32-geom-sf-ir-foundation*
*Verified: 2026-05-20*
