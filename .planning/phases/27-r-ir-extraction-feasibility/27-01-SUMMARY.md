---
phase: 27-r-ir-extraction-feasibility
plan: "01"
subsystem: spatial
tags: [sf, geojsonsf, CRS, WGS84, geom_sf, GeoJSON, sfc]

# Dependency graph
requires: []
provides:
  - "R/sf_utils.R with four exported sf geometry extraction functions"
  - "FEAS-01 gate verified: ggplot_build() preserves sfc geometry column"
  - "FEAS-02 verified: geojsonsf::sfc_geojson() produces valid character vector of GeoJSON strings"
  - "FEAS-03 verified: st_transform normalization works for EPSG:4267 and EPSG:3857"
  - "Test suite covering NC shapefile, rnaturalearth world borders, and projected CRS data (D-06)"
  - "DESCRIPTION updated with sf/geojsonsf/rnaturalearth in Suggests"
affects:
  - "27-02: IR schema integration — sf_utils.R is the extraction layer 27-02 dispatches to"
  - "28-d3-rendering: consumes geometries[] character vector from IR"
  - "30-zoom-architecture: will use sfc extraction pattern for feature hit-testing"

# Tech tracking
tech-stack:
  added:
    - "geojsonsf 2.0.3: C++-backed sfc -> GeoJSON character vector serialization"
    - "sf 1.1.0 (already installed): CRS detection/normalization via st_transform()"
    - "rnaturalearth: test dataset for complex multipolygon coverage"
  patterns:
    - "requireNamespace('sf') guard: all sf_utils functions fail gracefully when sf/geojsonsf absent"
    - "D-12 dynamic column detection: attr(df, 'sf_column') with fallback to inherits('sfc') scan"
    - "D-11 unconditional WGS84 normalization: normalize_to_wgs84() called inside extract_sf_geometries() always"
    - "D-10 geojsonsf serialization: geojsonsf::sfc_geojson() not jsonlite::toJSON"

key-files:
  created:
    - "R/sf_utils.R: four exported sf geometry extraction functions"
    - "tests/testthat/test-sf-utils.R: 26 tests across three datasets (NC, world, EPSG:3857)"
  modified:
    - "DESCRIPTION: sf/geojsonsf/rnaturalearth added to Suggests"

key-decisions:
  - "geojsonsf locked for serialization per D-10 — installed cleanly (sf 1.1.0 + Rcpp already present)"
  - "sf_column attribute is NULL after ggplot_build() — class-based fallback is the real primary detection path (D-12 empirically confirmed)"
  - "Unconditional normalize_to_wgs84() call inside extract_sf_geometries() ensures D-11 compliance without caller burden"

patterns-established:
  - "TDD RED-GREEN pattern: failing tests committed first (7cfba7b), implementation second (d5d610a)"
  - "Three-dataset coverage pattern for sf tests: NC (baseline), world (complex), projected CRS (normalization)"

requirements-completed: [FEAS-01, FEAS-02, FEAS-03]

# Metrics
duration: 10min
completed: 2026-04-04
---

# Phase 27 Plan 01: sf_utils.R — GeoJSON extraction, CRS normalization, and FEAS gate verification

**Four sf geometry utility functions shipping geojsonsf::sfc_geojson() serialization with unconditional WGS84 normalization, dynamic sfc column detection, and 26 tests covering NC shapefile, rnaturalearth world borders, and EPSG:3857 projected CRS**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-04T16:13:54Z
- **Completed:** 2026-04-04T16:18:59Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- FEAS-01 gate passed empirically: `ggplot_build()` preserves sfc geometry column in `b$data[[1]]` for `geom_sf` layers
- Four exported functions implemented in `R/sf_utils.R` with full `requireNamespace()` guards and D-12 dynamic column detection
- 26 tests pass across three datasets (NC shapefile EPSG:4267, rnaturalearth world small, NC EPSG:3857) per D-06

## Task Commits

Each task was committed atomically:

1. **Task 1: Install geojsonsf and update DESCRIPTION** - `cd63307` (chore)
2. **Task 2: Write tests for sf_utils functions (RED phase)** - `7cfba7b` (test)
3. **Task 3: Implement R/sf_utils.R to pass all tests (GREEN phase)** - `d5d610a` (feat)

## Files Created/Modified

- `R/sf_utils.R` - Four exported functions: `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, `get_layer_crs()`
- `tests/testthat/test-sf-utils.R` - 26 tests: FEAS-01 gate, extraction, CRS normalization, geometry type detection, error handling, three-dataset coverage
- `DESCRIPTION` - Added `sf (>= 1.0.0)`, `geojsonsf (>= 2.0.0)`, `rnaturalearth` to Suggests

## Decisions Made

- **geojsonsf installed cleanly** — sf 1.1.0 and Rcpp were already present; geojsonsf 2.0.3 installed without issue. D-10 production path is fully available.
- **sf_column attribute is NULL post-ggplot_build** — The D-12 pattern `attr(df, "sf_column")` returns NULL after `ggplot_build()` processing (confirmed empirically in research). The fallback `names(df)[vapply(df, inherits, logical(1L), "sfc")]` is therefore the actual primary detection path in all tests.
- **Unconditional normalize_to_wgs84() call** — Called inside `extract_sf_geometries()` rather than forcing callers to invoke it separately. Ensures D-11 compliance by default.

## Deviations from Plan

None — plan executed exactly as written. FEAS-01 gate passed (geometry column survives ggplot_build), so the D-04 fallback investigation was not needed.

## Issues Encountered

None. geojsonsf installed cleanly on first attempt. All 26 tests passed on the first implementation run.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `R/sf_utils.R` extraction layer is complete and tested; Plan 02 can add `GeomSf` dispatch to `as_d3_ir.R` and call these functions
- IR schema extension (annotated JSON per D-08/D-09) is Plan 02's responsibility
- `validate_ir.R` will warn on `"sf"` geom type until Plan 02 updates `known_geoms` — not a blocker

---
*Phase: 27-r-ir-extraction-feasibility*
*Completed: 2026-04-04*
