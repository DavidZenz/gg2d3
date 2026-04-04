# Requirements: gg2d3

**Defined:** 2026-04-04
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.7 Requirements

Requirements for choropleth map research milestone. Each maps to roadmap phases.

### Feasibility

- [x] **FEAS-01**: Empirically verify that `ggplot_build()` preserves the `sfc` geometry list-column for `geom_sf` layers
- [x] **FEAS-02**: Prototype R-side extraction of sf geometries to GeoJSON strings via `geojsonsf::sfc_geojson()`
- [x] **FEAS-03**: Verify CRS normalization path (`st_transform` to WGS84) works for common projected CRS inputs
- [ ] **FEAS-04**: Design IR schema extension for sf layers (geometries array, coord type, bbox)

### Rendering

- [ ] **REND-01**: Prototype D3 `geoPath` + `geoIdentity().reflectY(true).fitExtent()` rendering of GeoJSON polygons
- [ ] **REND-02**: Verify winding order fix (`fill-rule="evenodd"`) handles multipolygons with holes
- [ ] **REND-03**: Validate fill/stroke aesthetic passthrough from IR to SVG path elements

### Interactivity

- [ ] **INTR-01**: Document hover/tooltip extension strategy for `path.geom-sf` elements
- [ ] **INTR-02**: Evaluate brush selection approach (centroid-based vs polygon hit-testing)
- [ ] **INTR-03**: Determine zoom architecture for sf panels (suppress, SVG group transform, or geoPath re-render)

### Blueprint

- [ ] **BLPR-01**: Document edge cases: mixed geometry types, multi-layer stacking, faceted sf maps
- [ ] **BLPR-02**: Define explicit anti-features with rationale (tile basemaps, JS-side projection, slippy zoom)
- [ ] **BLPR-03**: Produce phase-by-phase implementation plan with concrete file changes for a future build milestone

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
| FEAS-04 | Phase 27 | Pending |
| REND-01 | Phase 28 | Pending |
| REND-02 | Phase 28 | Pending |
| REND-03 | Phase 28 | Pending |
| INTR-01 | Phase 29 | Pending |
| INTR-02 | Phase 29 | Pending |
| INTR-03 | Phase 29 | Pending |
| BLPR-01 | Phase 30 | Pending |
| BLPR-02 | Phase 30 | Pending |
| BLPR-03 | Phase 30 | Pending |

**Coverage:**
- v1.7 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-04*
*Last updated: 2026-04-04 — traceability populated after roadmap creation*
