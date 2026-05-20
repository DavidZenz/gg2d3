---
phase: 30
slug: edge-cases-and-blueprint
status: draft
created: 2026-05-20
---

# Phase 30 - Edge Cases and Implementation Blueprint

This phase produces implementation guidance only; it must not modify production R or JavaScript source files.

## Scope

This blueprint is the final v1.7 `geom_sf` handoff document. It turns Phase 27 extraction findings, Phase 28 renderer contracts, Phase 29 interactivity decisions, and Phase 30 edge-case decisions into a future build roadmap for production `geom_sf` work.

The first future build should stay intentionally narrow: polygon-family choropleths, existing gg2d3 SVG/htmlwidgets rendering, existing interactivity APIs, explicit unsupported behavior, and validation gates that prove correctness before scope expands.

## BLPR-01 - Edge Case Matrix

D-01 requires a representative edge-case suite, not an exhaustive GIS catalog. The first implementation milestone should cover the required cases deeply, then carry only nearby risks that materially change file targets or validation. D-02 narrows first-build geometry support to `POLYGON` and `MULTIPOLYGON`. D-03 requires a shared per-panel projection for stacked sf layers. D-04 requires faceted sf maps to fit each panel from its own data. D-14 and D-15 turn those choices into validation evidence.

| Edge case | Required first-build behavior | Future file targets | Validation evidence |
|-----------|-------------------------------|---------------------|---------------------|
| Mixed geometry types | Accept `POLYGON` and `MULTIPOLYGON` only. Non-polygon geometries warn or skip predictably rather than rendering best-effort points, lines, or geometry collections. | `R/sf_utils.R` detects polygon-family compatibility; `R/as_d3_ir.R` records accepted rows and warning state; `tests/testthat/test-sf-ir.R` covers mixed unsupported cases. | R IR tests create mixed `sfc` inputs and assert polygon rows remain usable while `POINT`, `LINESTRING`, `MULTIPOINT`, `MULTILINESTRING`, and `GEOMETRYCOLLECTION` receive explicit unsupported handling. |
| Stacked geom_sf layers | All sf layers in the same panel use a shared per-panel projection/bbox so overlays align. Per-layer `fitExtent()` is rejected because it can scale overlays differently. | `R/as_d3_ir.R` emits panel-level bbox/projection inputs; `inst/htmlwidgets/gg2d3.js` builds or passes panel projection state; `inst/htmlwidgets/modules/geoms/sf.js` consumes shared projection state instead of fitting each layer independently. | JavaScript structure checks assert `renderSf()` can receive shared panel projection/bbox state; visual checks render polygon base plus overlay and confirm alignment. |
| Faceted sf maps | Each facet panel filters rows by `PANEL` and fits its projection from that panel's sf features unless a later explicit global-comparison mode is designed. | `R/as_d3_ir.R` emits per-panel sf bbox metadata; `R/validate_ir.R` validates sf panel metadata; `inst/htmlwidgets/gg2d3.js` preserves `PANEL` filtering while passing panel-specific projection data; `tests/testthat/test-facets.R` and `tests/testthat/test-facet-grid.R` cover panel contracts. | IR tests assert panel bbox/projection metadata by `PANEL`; DOM/fixture checks assert each panel renders only matching rows; visual comparisons inspect at least one facet wrap and one facet grid map. |
| CRS normalization and missing CRS | Continue R-side WGS84 normalization for known CRS. Missing CRS should be documented and warned because JavaScript-side reprojection is not part of the first build. | `R/sf_utils.R` keeps `normalize_to_wgs84()` as source of truth; `R/as_d3_ir.R` preserves CRS metadata; future docs explain missing-CRS behavior. | R tests assert EPSG:4326 output for transformable data and clear warning/error behavior for missing CRS cases. |
| Missing or invalid geometries | Invalid, empty, or `NULL` geometries are skipped predictably and do not break row/geometry alignment for valid polygon rows. | `R/sf_utils.R` and `R/as_d3_ir.R` define skip/warn behavior; `inst/htmlwidgets/modules/geoms/sf.js` keeps malformed GeoJSON guards; `tests/testthat/test-sf-renderer.R` checks row and geometry alignment. | R tests assert valid polygons keep `row_id`; JavaScript checks assert malformed geometry strings do not throw and do not create misleading selectable paths. |

## BLPR-02 - Anti-Features

D-09 requires the first future build to name explicit anti-features. D-10 requires each deferral to carry rationale and revisit conditions, not a vague "later" note. D-11 keeps tiled map behavior out of scope because gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity. D-12 defers large-map performance guarantees until the renderer has measured polygon baselines.

| Anti-feature | First-build behavior | Rationale | Revisit condition |
|--------------|----------------------|-----------|-------------------|
| tile basemaps | Do not render raster or vector tile backgrounds. | Tile basemaps are out of scope because gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity, not a Leaflet or Mapbox-style tiled map system. | Revisit only if ggplot parity requires a static annotation-map contract that can still render inside the existing SVG/htmlwidgets widget boundary. |
| slippy zoom/pan | `d3_zoom() remains suppressed` for sf output in the first build. | Slippy zoom/pan implies map-engine behavior, tile coordination, and transform semantics that exceed the polygon MVP. | Revisit after polygon rendering, shared projection state, and faceted projection semantics pass visual comparison gates. |
| JavaScript-side reprojection | Do not reproject coordinates in the browser; consume R-normalized WGS84 polygon GeoJSON only. | R-side `sf` normalization is already the project boundary, while browser reprojection would add a second geospatial engine and harder CRS diagnostics. | Revisit only if a future requirement needs multiple CRS inputs that cannot be normalized reliably before serialization. |
| polygon-overlap brushing | `centroid brush remains the first-build behavior`; true polygon-overlap brushing is deferred. | Centroid brushing preserves the existing interactivity contract from Phase 29 without introducing computational geometry in JavaScript. | Revisit after hover/tooltip/centroid selection is stable and a specific user workflow proves overlap semantics are necessary. |
| large-map performance guarantees | Provide correctness-first behavior for representative polygon fixtures, but make no guarantee for large or highly detailed maps. | Performance limits are unknown until the SVG path renderer has measured real polygon counts and path complexity. | Revisit after benchmark fixtures exist and performance budgets are tied to concrete map sizes, simplification choices, or progressive rendering designs. |
