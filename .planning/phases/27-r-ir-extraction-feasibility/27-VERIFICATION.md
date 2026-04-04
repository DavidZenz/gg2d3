---
phase: 27-r-ir-extraction-feasibility
verified: 2026-04-04T16:31:32Z
status: passed
score: 11/11 must-haves verified
re_verification: false
human_verification:
  - test: "Render ggplot(nc) + geom_sf() as an HTML widget in a browser"
    expected: "North Carolina county polygons render as a choropleth map; fill color responds to aes(fill=BIR74)"
    why_human: "D3 rendering layer (Phase 28) not yet implemented — visual output cannot be verified programmatically"
---

# Phase 27: R IR Extraction Feasibility — Verification Report

**Phase Goal:** Validate that ggplot_build() preserves sfc geometry columns and that a viable R-to-IR extraction pipeline exists for geom_sf layers
**Verified:** 2026-04-04T16:31:32Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | extract_sf_geometries() returns a character vector of valid GeoJSON strings from an sfc column | VERIFIED | `R/sf_utils.R` line 44: `as.character(geojsonsf::sfc_geojson(geom_col))`; spot-check: first geometry starts with `{"type":"MultiP` |
| 2 | normalize_to_wgs84() transforms any projected CRS to EPSG:4326 | VERIFIED | `R/sf_utils.R` line 73: `sf::st_transform(geom_col, 4326L)`; spot-check: crs epsg returns 4326 after extraction |
| 3 | detect_dominant_geom_type() returns the geometry type string from an sfc column | VERIFIED | `R/sf_utils.R` line 108: `as.character(sf::st_geometry_type(...))`; spot-check: returns "MULTIPOLYGON" for NC data |
| 4 | get_layer_crs() returns a list with epsg and wkt fields from an sfc column | VERIFIED | `R/sf_utils.R` lines 143-146: returns `list(epsg=..., wkt=...)`; spot-check: crs epsg = 4326 |
| 5 | All sf_utils functions fail gracefully when sf/geojsonsf packages are missing | VERIFIED | All four functions have `requireNamespace()` guards with informative stop() messages |
| 6 | ggplot_build() preserves sfc geometry column (FEAS-01 gate) | VERIFIED | `test-sf-utils.R` line 11 FEAS-01 gate test passes; confirmed empirically in SUMMARY-01 |
| 7 | ggplot(nc) + geom_sf() produces a valid IR with geom='sf' layer via as_d3_ir() | VERIFIED | Spot-check: `ir$layers[[1]]$geom == "sf"`, `ir$coord$type == "sf"`, 100 geometries |
| 8 | IR contains layer.geometries[] as character vector of GeoJSON parallel to layer.data[] | VERIFIED | Spot-check: geometries count = 100; test-sf-ir.R test 14 checks parallel arrays |
| 9 | IR contains coord.type='sf' and coord.bbox with 4 numeric values | VERIFIED | Spot-check: bbox = -84.32, 33.88, -75.46, 36.59 (4 values, valid NC range) |
| 10 | validate_ir() does not warn on sf layers or sf panels | VERIFIED | Spot-check: validate_ir(ir) completed silently; is_sf bypass in validate_ir.R lines 149-158 |
| 11 | An annotated IR schema document shows all new sf fields with real data | VERIFIED | `IR-SCHEMA-SF.md` (269 lines) documents coord.type, coord.bbox, layer.geom, geom_type, geometries, crs fields with real NC output |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/sf_utils.R` | sf geometry extraction utilities | VERIFIED | 147 lines; four exported functions with requireNamespace guards and D-12 dynamic column detection |
| `tests/testthat/test-sf-utils.R` | Unit tests covering 3 datasets (min 100 lines) | VERIFIED | 217 lines; 14 test_that blocks (26 expect_ assertions) across NC, world borders, EPSG:3857 |
| `DESCRIPTION` | sf and geojsonsf in Suggests | VERIFIED | Lines 18-20: `sf (>= 1.0.0)`, `geojsonsf (>= 2.0.0)`, `rnaturalearth` |
| `R/as_d3_ir.R` | GeomSf dispatch and CoordSf detection | VERIFIED | GeomSf at line 214, extract_sf_geometries at line 330, is_sf_coord at line 663, sf_coord_meta at line 684 |
| `R/validate_ir.R` | "sf" in known_geoms, sf panel bypass | VERIFIED | "sf" added to known_geoms (line 19); is_sf bypass on x_range (line 150) and y_range (line 155) |
| `tests/testthat/test-sf-ir.R` | Integration tests for sf IR (min 60 lines) | VERIFIED | 101 lines; 14 test_that blocks covering basic sf, aes-mapped, geom_type, crs, bbox, parallel arrays, validate_ir silence |
| `.planning/phases/27-r-ir-extraction-feasibility/IR-SCHEMA-SF.md` | Annotated IR schema with geometries, bbox, coord.type fields | VERIFIED | 269 lines; documents all 6 new sf fields with real NC data examples and D3 renderer usage notes |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `R/sf_utils.R` | `sf::st_transform` | `normalize_to_wgs84` function | VERIFIED | Line 73: `sf::st_transform(geom_col, 4326L)` |
| `R/sf_utils.R` | `geojsonsf::sfc_geojson` | `extract_sf_geometries` function | VERIFIED | Line 44: `geojsonsf::sfc_geojson(geom_col)` |
| `R/as_d3_ir.R` | `R/sf_utils.R` | `extract_sf_geometries()` call in sf layer branch | VERIFIED | Lines 328-332: normalize_to_wgs84, extract_sf_geometries, get_layer_crs, detect_dominant_geom_type all called |
| `R/as_d3_ir.R` | `R/validate_ir.R` | `validate_ir(ir)` call at end of as_d3_ir | VERIFIED | Pattern present; validate_ir called at end of as_d3_ir pipeline |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `R/as_d3_ir.R` sf branch | `sf_geom_strings` | `extract_sf_geometries(df)` → `geojsonsf::sfc_geojson()` on real ggplot_build sfc column | Yes — 100 GeoJSON strings from NC shapefile confirmed by spot-check | FLOWING |
| `R/as_d3_ir.R` sf branch | `ir$coord$bbox` | `sf::st_bbox()` on all_sf_geoms derived from b$data | Yes — `[-84.32, 33.88, -75.46, 36.59]` confirmed by spot-check | FLOWING |
| `R/as_d3_ir.R` sf branch | `sf_layer_crs` | `get_layer_crs(df)` on WGS84-normalized df | Yes — epsg=4326, wkt string confirmed | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `as_d3_ir(ggplot(nc) + geom_sf())` produces sf IR | `Rscript -e "pkgload::load_all(); ir <- as_d3_ir(...); cat(ir$layers[[1]]$geom)"` | `sf` | PASS |
| coord.type is "sf" | same run | `sf` | PASS |
| geometries count == 100 | same run | `100` | PASS |
| geom_type is "MULTIPOLYGON" | same run | `MULTIPOLYGON` | PASS |
| crs.epsg is 4326 | same run | `4326` | PASS |
| bbox has 4 values in NC range | same run | `-84.32, 33.88, -75.46, 36.59` | PASS |
| validate_ir() silent on sf IR | `Rscript -e "... withCallingHandlers(validate_ir(ir), warning=...)"` | no warnings | PASS |
| aes-mapped sf plot succeeds | same run | `ir$layers[[1]]$geom == "sf"` | PASS |
| panels x_range/y_range are NULL | same run | `TRUE TRUE` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FEAS-01 | 27-01, 27-02 | Empirically verify ggplot_build() preserves sfc geometry list-column for geom_sf layers | SATISFIED | test-sf-utils.R FEAS-01 gate test at line 11; empirically confirmed: `b$data[[1]]$geometry` is class sfc |
| FEAS-02 | 27-01 | Prototype R-side extraction of sf geometries to GeoJSON strings via geojsonsf::sfc_geojson() | SATISFIED | extract_sf_geometries() in sf_utils.R; 26 tests pass; spot-check confirms valid GeoJSON output |
| FEAS-03 | 27-01 | Verify CRS normalization path (st_transform to WGS84) works for common projected CRS inputs | SATISFIED | normalize_to_wgs84() in sf_utils.R; tests cover EPSG:4267 (NC native) and EPSG:3857 (Web Mercator) |
| FEAS-04 | 27-02 | Design IR schema extension for sf layers (geometries array, coord type, bbox) | SATISFIED | IR-SCHEMA-SF.md documents all fields; as_d3_ir() produces IR with geometries[], coord.type="sf", coord.bbox |

No orphaned requirements — all four FEAS IDs in REQUIREMENTS.md are mapped to Phase 27 and all are satisfied.

### Anti-Patterns Found

No TODO/FIXME/PLACEHOLDER patterns found in any phase-modified file. No empty implementations or stub returns detected.

**Minor documentation gap (warning level):**

| File | Issue | Severity | Impact |
|------|-------|----------|--------|
| `NAMESPACE` | Four sf_utils functions have `@export` tags in sf_utils.R but NAMESPACE was not regenerated — functions are not listed as public exports | Warning | No functional impact (functions work within package; all tests pass); external users cannot call `gg2d3::extract_sf_geometries()` until `devtools::document()` is run |

### Human Verification Required

#### 1. D3 Geographic Rendering

**Test:** Load `gg2d3(ggplot(nc, aes(fill=BIR74)) + geom_sf())` in a browser
**Expected:** North Carolina county polygons render as a filled choropleth map using d3.geoPath(); fill color maps BIR74 values to a color scale
**Why human:** Phase 28 (D3 rendering layer) has not been implemented yet — the IR is correct and complete but no D3 renderer exists to consume the `geometries[]` array and `coord.bbox` fields

### Gaps Summary

No gaps found. All 11 must-have truths are verified, all 7 artifacts pass all three verification levels (exists, substantive, wired), all 4 key links are confirmed wired, data flows through the full pipeline producing real GeoJSON data, and all 4 FEAS requirements are satisfied.

The only notable item is a minor documentation gap: `devtools::document()` was not run after adding `@export` tags to sf_utils.R, so NAMESPACE does not list the four functions as public exports. This has no functional impact on the phase goal — all functions are accessible within the package namespace and all 40 tests pass. This can be resolved by running `devtools::document()` before Phase 28 work begins.

---

_Verified: 2026-04-04T16:31:32Z_
_Verifier: Claude (gsd-verifier)_
