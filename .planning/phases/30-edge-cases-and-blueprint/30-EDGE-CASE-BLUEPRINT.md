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

## BLPR-03 - Future Build Roadmap

D-05 makes this blueprint a build-phase roadmap, D-06 requires exact file targets, D-07 defines the first production-safe milestone, D-08 requires mixed automated and visual validation, D-13 allows lightweight checks without turning this into a prototype, and D-16 requires no unresolved implementation choices.

### 1. geom_sf polygon MVP

- Goal: Implement single-panel polygon choropleths with tooltip, hover, centroid brush, and zoom suppression.
- Files: `R/as_d3_ir.R`, `R/sf_utils.R`, `R/d3_zoom.R`, `inst/htmlwidgets/modules/geoms/sf.js`, `inst/htmlwidgets/modules/events.js`, `inst/htmlwidgets/modules/brush.js`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-renderer.R`, `tests/testthat/test-sf-visual.R`.
- Concrete changes: Gate sf extraction to `POLYGON` and `MULTIPOLYGON`, keep row/geometry arrays parallel, emit `path.geom-sf` with `data-row-id`, `data-cx`, and `data-cy`, add `path.geom-sf` selectors for tooltip and hover, add centroid brush selection, and suppress `d3_zoom()` with the Phase 29 warning.
- Automated validation: R IR tests for polygon-family acceptance, non-polygon warning/skip behavior, `row_id` stability, CRS normalization, and zoom suppression.
- Visual/manual validation: Browser visual comparison for an NC-style single-panel choropleth with fill, stroke, tooltip, hover, and centroid brush behavior.
- Still deferred: Stacked sf alignment, facets, tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees.

### 2. stacked sf projection alignment

- Goal: Make multiple sf layers in one panel share the same panel projection/bbox so overlays align.
- Files: `R/as_d3_ir.R`, `R/sf_utils.R`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/geoms/sf.js`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-renderer.R`, `tests/testthat/test-sf-visual.R`.
- Concrete changes: Emit or derive panel-level sf bbox metadata, build one panel projection from all sf features in that panel, pass shared projection state through `gg2d3.js`, and make `sf.js` consume the provided projection instead of fitting each layer independently.
- Automated validation: R IR tests for combined sf bbox metadata and JavaScript structure checks that `renderSf()` accepts shared projection or bbox state.
- Visual/manual validation: Browser visual comparison with a base polygon layer and an overlay polygon layer that must stay aligned.
- Still deferred: Faceted sf projection, non-polygon rendering, tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees.

### 3. faceted sf maps

- Goal: Render sf facets by fitting each panel from its own `PANEL` rows while preserving facet layout, strips, and per-panel data filtering.
- Files: `R/as_d3_ir.R`, `R/validate_ir.R`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/geoms/sf.js`, `tests/testthat/test-facets.R`, `tests/testthat/test-facet-grid.R`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-visual.R`.
- Concrete changes: Add per-panel sf bbox/projection metadata, validate sf panel metadata, preserve existing `PANEL` filtering in `gg2d3.js`, and pass panel-specific projection inputs into sf rendering for both facet wrap and facet grid.
- Automated validation: R IR tests for facet layout, `PANEL` preservation, per-panel sf bbox metadata, and DOM-oriented structure checks that each panel receives only matching rows.
- Visual/manual validation: Browser visual comparison for at least one facet wrap map and one facet grid map, confirming panel-specific fitting and no cross-panel leakage.
- Still deferred: Global-comparison projection mode, tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees.

### 4. unsupported geometry and documentation hardening

- Goal: Make unsupported sf behavior explicit, tested, and documented after the polygon MVP and panel projection paths are stable.
- Files: `R/sf_utils.R`, `R/as_d3_ir.R`, `R/validate_ir.R`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-renderer.R`, `vignettes/geom-sf-blueprint.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `README.Rmd`, `man/gg2d3.Rd`.
- Concrete changes: Centralize unsupported geometry detection, document warning/skip behavior for `POINT`, `MULTIPOINT`, `LINESTRING`, `MULTILINESTRING`, and `GEOMETRYCOLLECTION`, add diagnostics docs for anti-features, and update package-facing examples and help text.
- Automated validation: R tests for unsupported geometry warnings/skips, documentation checks for required status text, and generated help checks after roxygen updates.
- Visual/manual validation: Browser smoke checks proving unsupported geometry rows do not create misleading selectable paths while valid polygon rows still render.
- Still deferred: Non-polygon rendering, tiled map engines, slippy-map controls, browser reprojection, polygon-overlap brushing, and large-map performance guarantees.

## File-by-File Checklist

| File | Concrete future change |
|------|------------------------|
| `R/as_d3_ir.R` | Add polygon-family gating, unsupported geometry warnings/skips, panel sf bbox metadata, shared projection inputs, and facet-aware `PANEL` sf metadata. |
| `R/sf_utils.R` | Add helpers for polygon-family detection, missing/invalid geometry handling, per-panel bbox computation, and CRS warning text. |
| `R/validate_ir.R` | Extend validation to check sf panel metadata, shared projection inputs, and facet bbox consistency. |
| `R/d3_zoom.R` | Suppress `d3_zoom()` for widgets containing sf layers and warn before attaching browser zoom behavior. |
| `inst/htmlwidgets/gg2d3.js` | Preserve `PANEL` filtering and pass shared per-panel projection/bbox state into sf layer rendering. |
| `inst/htmlwidgets/modules/geoms/sf.js` | Consume shared projection state, keep `path.geom-sf`, `data-row-id`, `data-cx`, and `data-cy`, and guard malformed geometry rows. |
| `inst/htmlwidgets/modules/events.js` | Add `path.geom-sf` to interactive selectors for tooltip and hover reuse. |
| `inst/htmlwidgets/modules/brush.js` | Add `path.geom-sf` to brush selectors and prefer centroid attributes for selection. |
| `tests/testthat/test-sf-ir.R` | Cover polygon-family acceptance, mixed unsupported geometry behavior, CRS normalization, per-panel bbox metadata, and zoom suppression inputs. |
| `tests/testthat/test-sf-renderer.R` | Cover geometry/data alignment, malformed geometry guards, row id stability, and shared projection handoff shape. |
| `tests/testthat/test-sf-visual.R` | Generate visual fixtures for single-panel choropleths, stacked overlays, and faceted sf maps. |
| `tests/testthat/test-facets.R` | Add facet wrap sf tests for `PANEL` filtering and per-panel bbox/projection metadata. |
| `tests/testthat/test-facet-grid.R` | Add facet grid sf tests for panel layout, missing combinations, and panel-specific projection metadata. |
| `vignettes/geom-sf-blueprint.Rmd` | Add a new sf blueprint vignette or article explaining supported polygon behavior, interactivity, validation, and deferred features. |
| `vignettes/d3-drawing-diagnostics.md` | Update diagnostics with sf anti-features, unsupported geometry behavior, and known map-performance limits. |
| `README.Rmd` | Add README example/status updates for first-build `geom_sf` polygon support and clear deferrals. |
| `man/gg2d3.Rd` | Regenerate help text from future roxygen updates after package-facing sf status documentation changes. |

## Validation Gates

| Gate | Required evidence |
|------|-------------------|
| R IR tests | Test polygon-family acceptance, unsupported geometry warnings/skips, CRS normalization, `row_id` alignment, per-panel bbox metadata, and `PANEL` filtering. |
| JavaScript structure checks | Check shared projection handoff, `path.geom-sf` output, `data-row-id`, `data-cx`, `data-cy`, malformed geometry guards, and selector coverage. |
| documentation checks | Check the sf blueprint vignette, diagnostics anti-features, README support status, and generated `man/gg2d3.Rd` help text. |
| human/browser visual comparisons | Compare single-panel choropleths, stacked overlays, facet wrap maps, and facet grid maps in a browser before declaring future sf builds complete. |
