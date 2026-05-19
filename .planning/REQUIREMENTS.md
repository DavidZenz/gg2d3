# Requirements: gg2d3

**Defined:** 2026-04-04
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.7 Requirements

Requirements for choropleth map research milestone. Each maps to roadmap phases.

### Feasibility

- [x] **FEAS-01**: Empirically verify that `ggplot_build()` preserves the `sfc` geometry list-column for `geom_sf` layers
- [x] **FEAS-02**: Prototype R-side extraction of sf geometries to GeoJSON strings via `geojsonsf::sfc_geojson()`
- [x] **FEAS-03**: Verify CRS normalization path (`st_transform` to WGS84) works for common projected CRS inputs
- [x] **FEAS-04**: Design IR schema extension for sf layers (geometries array, coord type, bbox)

### Rendering

- [x] **REND-01**: Prototype D3 `geoPath` + `geoIdentity().reflectY(true).fitExtent()` rendering of GeoJSON polygons
- [x] **REND-02**: Verify winding order fix (`fill-rule="evenodd"`) handles multipolygons with holes
- [x] **REND-03**: Validate fill/stroke aesthetic passthrough from IR to SVG path elements

### Interactivity

- [x] **INTR-01
**: Document hover/tooltip extension strategy for `path.geom-sf` elements
- [x] **INTR-02
**: Evaluate brush selection approach (centroid-based vs polygon hit-testing)
- [x] **INTR-03
**: Determine zoom architecture for sf panels (suppress, SVG group transform, or geoPath re-render)

### Blueprint

- [ ] **BLPR-01**: Document edge cases: mixed geometry types, multi-layer stacking, faceted sf maps
- [ ] **BLPR-02**: Define explicit anti-features with rationale (tile basemaps, JS-side projection, slippy zoom)
- [ ] **BLPR-03**: Produce phase-by-phase implementation plan with concrete file changes for a future build milestone

## Distribution

Cross-milestone packaging / publishing requirements, satisfied independently of the choropleth research stream.

- [x] **DOCS-02**: Public package site published to GitHub Pages, rebuilt and redeployed on every push to master (and on releases), with at least one verifiably interactive `gg2d3()` widget in the published "Get started" article. Met by Phase 31 on 2026-05-17 — site live at https://davidzenz.github.io/gg2d3/.

## Future Requirements

### Implementation (v1.8+ build milestone)

- **IMPL-01**: Implement `R/sf_utils.R` with geometry extraction, CRS normalization, GeoJSON serialization
- **IMPL-02**: Extend `as_d3_ir.R` with GeomSf dispatch and CoordSf branch
- **IMPL-03**: Implement `modules/geoms/sf.js` D3 renderer with geoPath + geoIdentity
- **IMPL-04**: Wire interactivity (hover, tooltip, brush) for geom_sf paths
- **IMPL-05**: Handle edge cases (mixed geometry, multi-layer, faceted sf maps)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Tile/raster basemaps (OSM, Mapbox) | Outside SVG-only mandate; Leaflet is the right tool |
| Full CRS projection system in JavaScript | coord_sf handles projection in R; replicating in JS is scope explosion |
| Slippy map zoom/pan | Conflicts with existing Cartesian zoom architecture |
| geom_sf_text / geom_sf_label | Scope-increasing; requires interior point extraction; defer to future |
| Real-time GeoJSON streaming | Outside htmlwidgets synchronous data model |
| Production implementation code | v1.7 is research-only; build deferred to v1.8+ |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FEAS-01 | Phase 27 | Complete |
| FEAS-02 | Phase 27 | Complete |
| FEAS-03 | Phase 27 | Complete |
| FEAS-04 | Phase 27 | Complete |
| REND-01 | Phase 28 | Complete |
| REND-02 | Phase 28 | Complete |
| REND-03 | Phase 28 | Complete |
| INTR-01 | Phase 29 | Complete |
| INTR-02 | Phase 29 | Complete |
| INTR-03 | Phase 29 | Complete |
| BLPR-01 | Phase 30 | Pending |
| BLPR-02 | Phase 30 | Pending |
| BLPR-03 | Phase 30 | Pending |
| DOCS-02 | Phase 31 | Complete |

**Coverage:**
- v1.7 requirements: 13 total — all mapped
- Cross-milestone distribution requirements: 1 (DOCS-02, Phase 31)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-04*
*Last updated: 2026-05-17 — added DOCS-02 (Phase 31 pkgdown publishing) under cross-milestone Distribution*
