---
phase: 27-r-ir-extraction-feasibility
plan: 02
subsystem: ir
tags: [sf, geom_sf, CoordSf, GeoJSON, geojsonsf, WGS84, validate_ir, testthat]

# Dependency graph
requires:
  - phase: 27-01
    provides: "sf_utils.R with extract_sf_geometries/normalize_to_wgs84/detect_dominant_geom_type/get_layer_crs"
provides:
  - "as_d3_ir() handles geom_sf plots end-to-end with geometries/geom_type/crs/coord.bbox"
  - "validate_ir() recognizes sf as known geom and skips Cartesian panel checks for sf coord"
  - "14 integration tests covering basic sf, aesthetic-mapped sf, parallel array correctness"
  - "IR-SCHEMA-SF.md annotated schema document with real NC data examples"
affects:
  - 27-03
  - 27-04
  - phase-28-d3-renderer

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pre-normalize geometry column in sf branch before calling get_layer_crs() so crs.epsg is always 4326"
    - "is_sf bypass in validate_ir() panel checks: compute once per panel loop, guard both x_range and y_range"
    - "pkgload::load_all() guard in test files for standalone testthat::test_file() compatibility"

key-files:
  created:
    - tests/testthat/test-sf-ir.R
    - .planning/phases/27-r-ir-extraction-feasibility/IR-SCHEMA-SF.md
  modified:
    - R/as_d3_ir.R
    - R/validate_ir.R

key-decisions:
  - "Normalize geometry column to WGS84 before calling get_layer_crs() in sf branch so crs.epsg is always 4326 in IR (not the original CRS like 4267/NAD27)"
  - "sf panels use NULL x_range/y_range instead of Cartesian domains; D3 renderer uses coord.bbox instead"

patterns-established:
  - "Pattern: sf layer branch in as_d3_ir normalizes geometry column, then calls extract_sf_geometries/get_layer_crs/detect_dominant_geom_type in that order"
  - "Pattern: validate_ir is_sf computed once per panel iteration to guard both range checks"

requirements-completed: [FEAS-01, FEAS-04]

# Metrics
duration: 15min
completed: 2026-04-04
---

# Phase 27 Plan 02: SF IR Integration Summary

**geom_sf extraction wired into as_d3_ir with GeomSf/CoordSf dispatch, WGS84-normalized GeoJSON geometries in IR, and validate_ir updated to recognize sf layers and skip Cartesian panel checks**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-04T16:12:00Z
- **Completed:** 2026-04-04T16:27:11Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- `as_d3_ir(ggplot(nc) + geom_sf())` produces valid IR with `layers[[1]]$geom == "sf"`, `coord$type == "sf"`, 100 GeoJSON geometries, and `coord$bbox` in NC WGS84 coordinates
- `validate_ir()` recognizes "sf" as known geom and skips x_range/y_range checks for sf coord panels — no warnings on sf IR
- 14 integration tests all pass, covering basic sf, aesthetic-mapped fill, geom_type, crs, bbox, parallel arrays, validate_ir silence
- Annotated IR schema document `IR-SCHEMA-SF.md` written with real NC county data, field-by-field annotations, D3 renderer usage pattern, and pitfall notes

## Task Commits

Each task was committed atomically:

1. **Task 1: GeomSf dispatch and CoordSf detection** - `26b3bfe` (feat)
2. **Task 2: validate_ir, integration tests, IR schema document** - `e7285e1` (feat)

## Files Created/Modified

- `R/as_d3_ir.R` - Added GeomSf dispatch, sf layer branch with extract_sf_geometries call, is_sf_coord detection, sf_coord_meta bbox, sf panels_ir with NULL ranges; also fixed bare waiver() call to ggplot2::waiver()
- `R/validate_ir.R` - Added "sf" to known_geoms vector; added is_sf bypass for x_range/y_range panel checks
- `tests/testthat/test-sf-ir.R` - 14 integration tests for full as_d3_ir sf pipeline
- `.planning/phases/27-r-ir-extraction-feasibility/IR-SCHEMA-SF.md` - Annotated schema extension document with real NC data

## Decisions Made

- Normalize the geometry column to WGS84 *before* calling `get_layer_crs()` in the sf branch so that `crs.epsg` in the IR is always 4326 (NC shapefile is originally EPSG:4267/NAD27; returning 4267 would be misleading since geometries are normalized to WGS84 in all cases)
- sf panels use `NULL` x_range/y_range rather than Cartesian domains; `coord.bbox` carries the geographic extent; D3 renderer uses `coord.bbox` with `d3.geoIdentity().reflectY(true).fitExtent()`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed get_layer_crs() returning original CRS instead of normalized CRS**
- **Found during:** Task 2 (integration test verification)
- **Issue:** `get_layer_crs(df)` was called on raw ggplot_build data (EPSG:4267 for NC), but geometries are normalized to WGS84 by `extract_sf_geometries`. The IR would show `crs.epsg: 4267` while geometries are in WGS84 — a mismatch.
- **Fix:** In the sf layer branch, normalize the geometry column in `df` to WGS84 before calling `get_layer_crs()`, ensuring the returned CRS matches the serialized geometries
- **Files modified:** R/as_d3_ir.R
- **Verification:** `ir$layers[[1]]$crs$epsg == 4326L` test passes
- **Committed in:** `e7285e1` (Task 2 commit)

**2. [Rule 1 - Bug] Fixed bare waiver() call in as_d3_ir guide title extraction**
- **Found during:** Task 2 (aes-mapped sf plot test)
- **Issue:** Line 764 called `waiver()` without namespace qualification; `waiver` is not imported from ggplot2 in the package namespace, causing "could not find function 'waiver'" error for any aesthetic-mapped plot with a guide
- **Fix:** Changed `waiver()` to `ggplot2::waiver()`
- **Files modified:** R/as_d3_ir.R
- **Verification:** `as_d3_ir(ggplot(nc, aes(fill=BIR74)) + geom_sf())` succeeds; all 688 tests pass
- **Committed in:** `e7285e1` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes essential for correctness. No scope creep. Bug 2 was pre-existing but only surfaced via the aes-mapped sf test.

## Issues Encountered

None — both bugs were found during standard test verification and fixed inline per deviation rules.

## Next Phase Readiness

- FEAS-01 confirmed: geometry column survives ggplot_build and reaches IR with correct CRS normalization
- FEAS-04 confirmed: IR schema extension fully documented with real NC data examples
- `IR-SCHEMA-SF.md` provides the field contract for Phase 28 D3 renderer implementation
- Phase 27-03 and 27-04 can proceed using the established IR structure

---
*Phase: 27-r-ir-extraction-feasibility*
*Completed: 2026-04-04*
