# Phase 37 Research: Non-Polygon sf IR And Renderer

**Researched:** 2026-05-21T10:00:26Z
**Status:** Complete

## Executive Summary

Phase 37 should extend the existing sf path, not create a parallel map renderer. The safest implementation path is to expand `prepare_sf_geometry_ir()` to accept point and line families, add explicit family metadata to the IR, and teach `inst/htmlwidgets/modules/geoms/sf.js` to dispatch rendering by GeoJSON geometry type while preserving the shared `.geom-sf` selector and source-row payload contract.

The main risks are `MULTIPOINT`/`MULTILINESTRING` row identity, point sizing semantics, line no-fill behavior, and keeping mixed stacked/faceted panels on one panel-scoped projection. These should become separate plans so each risk has focused tests and can be executed in dependency order.

## Current Implementation Facts

### R IR

- `R/sf_utils.R` currently defaults `prepare_sf_geometry_ir()` to `supported_types = c("POLYGON", "MULTIPOLYGON")`.
- The helper already detects the `sfc` column, filters missing/empty/invalid/unsupported rows, preserves source row ids, normalizes accepted geometries to WGS84, serializes with `geojsonsf::sfc_geojson()`, computes CRS metadata, and emits `sf_diagnostics`.
- `R/as_d3_ir.R` calls `prepare_sf_geometry_ir(df)` in the `gname == "sf"` branch and stores `geom_type`, `geometries`, `data`, `crs`, and diagnostics on the sf layer.
- `R/as_d3_ir.R` accumulates accepted sf geometries by panel into `sf_panel_geometries`, then assigns `panel$sf_bbox <- sf_bbox_values(...)`.
- `validate_ir()` already accepts sf layers and validates panel `sf_bbox` shape/finite values.

### JavaScript Renderer

- `inst/htmlwidgets/modules/geoms/sf.js` renders all accepted sf rows as `path.geom-sf`.
- The renderer parses layer GeoJSON, builds a per-panel `d3.geoIdentity().reflectY(true).fitExtent(...)` projection from `options.sfBBox` or layer features, computes path centroids, attaches `_geom` and `_centroid` internally, and writes `data-row-id`, `data-cx`, and `data-cy`.
- Polygon styling currently uses `fillColor(d)`, `strokeColor(d)`, a single layer-level `stroke-width`, opacity, and `fill-rule="evenodd"`.
- The existing renderer comment says it handles other GeoJSON geometry types, but the R IR currently filters them out.

### Browser Harness

- Phase 36 added reusable browser helpers and DOM smoke tests that can be extended for point and line fixtures.
- Browser tests currently query `path.geom-sf`, so Phase 37 tests must account for non-path point marks while keeping polygon compatibility.

## Recommended IR Contract

Extend accepted atomic geometry types:

- Polygon family: `POLYGON`, `MULTIPOLYGON`
- Point family: `POINT`, `MULTIPOINT`
- Line family: `LINESTRING`, `MULTILINESTRING`

Recommended fields:

- Keep `geom = "sf"`, `geom_type`, `geometries`, `data`, `crs`, and `sf_diagnostics`.
- Add `sf_family` for homogeneous layers: `"polygon"`, `"point"`, `"line"`, or `"mixed"`.
- Add a row-level family field in each accepted data row, such as `.sf_family`, when accepted rows may contain mixed families.
- Add `accepted_geometry_families` to `sf_diagnostics` if practical; this makes validation clearer without replacing `accepted_geometry_types`.

Do not split source rows in R solely for `MULTIPOINT` or `MULTILINESTRING` unless the renderer cannot preserve callback identity otherwise. Keeping one GeoJSON geometry per source row is the clearest row-identity contract.

## Recommended Renderer Contract

Use one projection per panel and dispatch mark creation by GeoJSON geometry type:

- Polygons: keep SVG paths, keep `path.geom-sf`, add `geom-sf-polygon`.
- Lines: SVG paths with `geom-sf geom-sf-line`, non-empty `d`, `fill="none"`, stroke-oriented aesthetics.
- Points: SVG circles with `geom-sf geom-sf-point`, `cx`, `cy`, `r`, `data-row-id`, `data-cx`, and `data-cy`.

Multipoint options:

1. Draw one circle for each coordinate child, all bound to copied public row data with the same source `row_id`.
2. Deduplicate public callback/brush payloads by `row_id` in shared interactivity paths if multiple children are selected.

Multiline options:

1. Prefer one path per source `MULTILINESTRING` GeoJSON geometry when D3 `geoPath` produces a valid path. This preserves source-row identity naturally.
2. If subpath splitting is needed later, follow the multipoint approach: child DOM marks share source row id and public callbacks dedupe.

Representative anchors:

- Points: projected point coordinates are the natural anchor.
- Multipoints: a representative projected centroid from `geoPath.centroid()` is acceptable for `data-cx`/`data-cy`; child circles should also have real `cx`/`cy`.
- Lines/multilines: `geoPath.centroid()` is acceptable for Phase 37 anchor brushing; true line-intersection brushing remains out of scope.
- Polygons: preserve existing centroid behavior.

## Styling Guidance

Point-family core styling:

- `colour`/`color`: stroke or primary color, following existing gg2d3 point conventions where practical.
- `fill`: circle fill when available.
- `alpha`: opacity.
- `size`: visible radius. Use existing point sizing conventions as the closest analog; tests should assert size changes are reflected rather than exact full ggplot2 parity for every shape.

Line-family core styling:

- `colour`/`color`: stroke.
- `linewidth`: stroke width. Use existing line linewidth conversion if available in renderer helpers.
- `linetype`: stroke dasharray via existing helper conventions.
- `alpha`: opacity.
- `fill`: explicitly `none`.

Polygon-family:

- Preserve current fill/stroke/fill-rule behavior.
- Add family class without breaking existing tests.

## Validation Architecture

Phase 37 should create a layered validation suite:

1. R IR tests
   - POINT and MULTIPOINT accepted with row identity, diagnostics, CRS metadata, finite bbox.
   - LINESTRING and MULTILINESTRING accepted with row identity, diagnostics, CRS metadata, finite bbox.
   - Mixed polygon/point/line accepted families produce expected `accepted_geometry_types` and no skipped accepted rows.
   - Unsupported `GEOMETRYCOLLECTION`, empty, invalid, missing geometries still skip with warnings and diagnostics.
   - Stacked and faceted mixed families compute panel `sf_bbox` from all accepted families.

2. Renderer/source tests
   - `sf.js` contains dispatch paths for `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, and `MultiPolygon`.
   - Family classes exist: `geom-sf-point`, `geom-sf-line`, `geom-sf-polygon`.
   - Point marks expose `cx`, `cy`, `r`, `data-cx`, `data-cy`, and `data-row-id`.
   - Line marks expose non-empty `d`, `fill="none"`, `data-cx`, `data-cy`, and `data-row-id`.
   - Interactivity selectors include shared `.geom-sf` or family selectors as needed for circle and path marks.

3. Browser smoke tests
   - Add deterministic point-only and line-only fixtures.
   - Add polygon+point and polygon+line overlays to prove shared projection alignment.
   - Add mixed accepted/skipped fixture with unsupported rows absent.
   - Add faceted or empty-panel fixture where feasible.
   - Assert no browser console/page errors, visible DOM marks, stable row ids, and finite anchors.

4. Regression tests
   - Re-run Phase 35/36 polygon fixture tests to ensure polygon behavior does not regress.

## Suggested Plan Breakdown

### Plan 37-01: R IR Family Expansion

Focus:

- Extend `R/sf_utils.R` to classify geometry families and accept point/line atomic types.
- Add IR tests for point, multipoint, line, multiline, mixed accepted/skipped rows, diagnostics, CRS, and bbox metadata.
- Preserve existing polygon tests unchanged.

Likely files:

- `R/sf_utils.R`
- `R/as_d3_ir.R`
- `R/validate_ir.R` if needed for new metadata
- `tests/testthat/test-sf-ir.R`

### Plan 37-02: D3 Renderer Family Dispatch

Focus:

- Update `inst/htmlwidgets/modules/geoms/sf.js` to render point circles, line paths, and polygon paths from the same projection.
- Add family classes and required attributes.
- Apply core point/line styling.
- Update source tests for renderer contracts.

Likely files:

- `inst/htmlwidgets/modules/geoms/sf.js`
- `tests/testthat/test-sf-renderer.R`
- potentially renderer helper modules if existing styling helpers need reuse

### Plan 37-03: Interactivity And Browser Fixture Coverage

Focus:

- Ensure tooltip, hover, handlers, and brush target point circles and line paths through shared `.geom-sf` or family selectors.
- Add or extend sf fixture helpers for point-only, line-only, polygon+point, polygon+line, mixed accepted/skipped, facets, and empty panels.
- Add browser smoke assertions for visible point/line marks, row ids, anchors, no errors, and polygon regression stability.

Likely files:

- `inst/htmlwidgets/modules/brush.js`
- `inst/htmlwidgets/modules/events.js`
- `inst/htmlwidgets/modules/tooltip.js` if selector handling requires adjustment
- `tests/testthat/helper-sf-fixtures.R`
- `tests/testthat/test-sf-browser.R`
- `tests/testthat/test-sf-interactivity.R`

## Threat Model Inputs

Security risk is low because this phase renders local data into an htmlwidget, but plans should still include threat-model blocks:

- Renderer-private fields `_geom`, `_centroid`, and any new child-geometry fields must not leak into user callback payloads.
- Browser tests load local generated HTML; avoid adding remote network dependencies or arbitrary external script sources.
- No new runtime browser automation dependency should be added for package users.
- Avoid unsafe string injection in generated JavaScript snippets or test helpers.

## Planner Pitfalls

- Do not satisfy the roadmap phrase "visible sf point paths" by forcing points into path syntax if the context says circles are the chosen SVG mark. The compatibility requirement is shared `.geom-sf`, not literally making points path-only.
- Do not break existing `path.geom-sf` polygon tests when adding family classes.
- Do not let multipoint child marks create duplicate public callback rows.
- Do not let line marks inherit polygon fills.
- Do not compute panel bboxes from only the first sf layer or only polygon geometries.
- Do not make browser automation a runtime dependency.
- Do not expand to `GEOMETRYCOLLECTION`, sf labels, map zoom/pan, or true geometry brushing.

## RESEARCH COMPLETE
