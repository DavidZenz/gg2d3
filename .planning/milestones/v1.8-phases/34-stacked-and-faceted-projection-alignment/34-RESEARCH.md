---
phase: 34
slug: stacked-and-faceted-projection-alignment
status: complete
created: 2026-05-20
source: inline-codebase-research
---

# Phase 34 - Technical Research

## Phase Goal

Extend sf projection handling so stacked sf layers align in one panel and faceted sf maps fit each panel from its own data.

## Requirement Coverage

| Requirement | Meaning | Research Outcome |
|-------------|---------|------------------|
| SFREND-02 | Stacked sf layers share one per-panel projection | Current `sf.js` fits each layer from `layer.geometries`; this must change to use panel-level bbox metadata computed across all accepted sf layers. |
| SFREND-03 | Faceted sf maps filter by `PANEL` and fit per panel | `gg2d3.js` currently filters `layer.data` by `PANEL`, but leaves `layer.geometries` unchanged. For sf this breaks positional geometry/data alignment and keeps `sf.js` fitting from the wrong feature set. |

## Codebase Findings

### R IR extraction

`R/as_d3_ir.R` already detects `CoordSf`, prepares each sf layer through `prepare_sf_geometry_ir()`, and stores a global `coord$bbox` from all accepted sf geometries:

- `prepare_sf_geometry_ir()` returns filtered `data`, serialized `geometries`, normalized accepted `geometry`, CRS metadata, and diagnostics.
- Accepted sf rows retain `PANEL`, because `PANEL` is already in `keep_aes` and `to_rows()`.
- `sf_coord_geometries` currently collects accepted geometries across layers with no panel grouping.
- `ir$panels` entries already key panel metadata by integer `PANEL`.

The natural extension is to compute `sf_bbox` per `ir$panels[[i]]` from accepted geometries grouped by `PANEL`, while preserving `coord$bbox` as an all-panel/all-layer union for backward compatibility.

### Facet rendering

`inst/htmlwidgets/gg2d3.js` renders each panel through `renderPanel()` and filters layer rows with:

```js
layer.data.filter(function(d) { return d.PANEL === panelNum; })
```

This is correct for ordinary row-only geoms. For sf, `layer.geometries` is a parallel array and must be filtered by the same original index as `layer.data`. Otherwise a faceted panel with 50 rows can still receive 100 geometries, causing paths to bind mismatched geometries and fit from cross-panel features.

### Sf renderer

`inst/htmlwidgets/modules/geoms/sf.js` currently:

- Parses all `layer.geometries`.
- Builds a FeatureCollection from that layer only.
- Calls `d3.geoIdentity().reflectY(true).fitExtent(...)` on the layer FeatureCollection.
- Computes centroids with the resulting path generator.
- Binds cloned row data with `_geom` and `_centroid` private fields.

For stacked and faceted maps, the renderer can keep this mechanics but must select its fit source differently:

- If `options.sfBBox` or `options.panelData.sf_bbox` exists, build a bbox polygon FeatureCollection and fit from that shared panel bbox.
- Otherwise keep the existing layer FeatureCollection fallback for defensive backward compatibility.
- Keep `data-cx`/`data-cy`, `data-row-id`, `fill-rule="evenodd"`, and private `_geom`/`_centroid` behavior from Phase 33.

### Validation

The fastest reliable tests are R `testthat` IR assertions plus JS source-contract assertions. The repo does not yet have a headless htmlwidgets DOM harness; Phase 35 owns broader browser validation hardening. Phase 34 should still include fixtures that make global bbox leakage obvious:

- Stacked single-panel sf layers with distant polygons should produce one panel `sf_bbox` spanning both layers.
- `facet_wrap()` with far-apart polygons should produce different `sf_bbox` values per panel even under fixed facet scales.
- `facet_grid()` with missing combinations should preserve the full panel layout while empty panels have `sf_bbox = NULL`.
- Source-contract tests should assert `gg2d3.js` filters `geometries` alongside `data` and passes panel sf bbox metadata to the renderer.

## Implementation Strategy

Split into three sequential plans:

1. Add R-side per-panel sf bbox metadata and validate the IR contract.
2. Update JS panel rendering and `sf.js` to consume shared panel bbox state while preserving geometry/data alignment.
3. Add focused stacked/facet regression fixtures for wrap, grid, and empty panel behavior.

This sequencing lets the renderer consume an explicit IR contract instead of reverse-engineering shared state from all layers in JavaScript.

## Validation Architecture

Automated validation should include:

- `tests/testthat/test-sf-ir.R` for stacked sf `sf_bbox` metadata and validation.
- `tests/testthat/test-sf-renderer.R` for JS source contracts in `gg2d3.js` and `sf.js`.
- `tests/testthat/test-facets.R` for `facet_wrap()` sf per-panel bbox isolation.
- `tests/testthat/test-facet-grid.R` for `facet_grid()` sf layout preservation and empty panels.
- `tests/testthat/test-sf-visual.R` only if adding fixture generation is lightweight; full browser QA remains Phase 35.

Recommended targeted suite:

```r
pkgload::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-sf-ir.R")
testthat::test_file("tests/testthat/test-sf-renderer.R")
testthat::test_file("tests/testthat/test-facets.R")
testthat::test_file("tests/testthat/test-facet-grid.R")
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Facet JS filters data but not geometry | Wrong polygons render in panels and panel projection leaks globally | Filter `data` and `geometries` as index pairs in `gg2d3.js`. |
| Stacked layers still fit independently | Polygon overlays do not align | R computes one `sf_bbox` per panel across all accepted sf layers; JS passes it into each sf renderer. |
| Empty panels fallback to global bbox | Missing facet combinations look valid and hide leakage | Store `sf_bbox = NULL` for panels with no accepted sf features and make `sf.js` render zero paths if its filtered layer has no valid features. |
| Non-sf facet behavior regresses | Existing facet tests fail | Keep row-only filtering path for non-sf layers; add tests around existing facet metadata. |
| Validation assumes optional sf packages are installed | CI without GDAL/GEOS/PROJ fails | Keep `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")` guards. |

## Recommended Verification Commands

```r
pkgload::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-sf-ir.R")
testthat::test_file("tests/testthat/test-sf-renderer.R")
testthat::test_file("tests/testthat/test-facets.R")
testthat::test_file("tests/testthat/test-facet-grid.R")
```
