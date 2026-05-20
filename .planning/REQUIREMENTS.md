# Requirements: gg2d3

**Defined:** 2026-05-20
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.8 Requirements

Requirements for the production `geom_sf` polygon MVP milestone. Each maps to exactly one roadmap phase.

### SF IR

- [x] **SFIR-01**: `gg2d3()` can extract `geom_sf` layers whose geometries are `POLYGON` or `MULTIPOLYGON` into JSON-serializable sf IR.
- [x] **SFIR-02**: `gg2d3()` normalizes known sf CRS inputs to WGS84 in R before serialization and records bbox/projection metadata needed by the renderer.
- [x] **SFIR-03**: Unsupported, empty, invalid, or missing sf geometries warn or skip predictably without breaking row/geometry alignment for valid polygon rows.

### SF Rendering

- [x] **SFREND-01**: Single-panel `geom_sf` polygon choropleths render as SVG `path.geom-sf` elements with fill, stroke, and multipolygon hole behavior matching the v1.7 prototype.
- [ ] **SFREND-02**: Multiple sf layers in the same panel share a per-panel bbox/projection so polygon overlays align instead of being fitted independently.
- [ ] **SFREND-03**: Faceted sf maps render with facet-aware `PANEL` filtering and per-panel bbox/projection behavior for both `facet_wrap()` and `facet_grid()`.

### SF Interactivity

- [x] **SFINTR-01**: Existing tooltip and hover APIs work for `path.geom-sf` using bound row data and the existing selector architecture.
- [ ] **SFINTR-02**: Existing brush APIs can select `geom_sf` regions using centroid attributes (`data-cx`, `data-cy`) on sf paths.
- [ ] **SFINTR-03**: `d3_zoom()` suppresses unsupported sf zoom behavior with a clear warning instead of attaching misleading Cartesian zoom behavior.

### SF Documentation and Validation

- [ ] **SFDOC-01**: Package-facing docs describe supported `geom_sf` polygon behavior, unsupported geometry handling, and explicit map anti-features.
- [ ] **SFDOC-02**: Automated and human/browser validation fixtures cover single-panel choropleths, stacked sf overlays, faceted sf maps, unsupported geometry behavior, and interactivity smoke checks.

## Future Requirements

Deferred beyond v1.8.

### Non-Polygon SF

- **SFNEXT-01**: Render sf point and multipoint geometries with appropriate ggplot2/D3 mark semantics.
- **SFNEXT-02**: Render sf line and multiline geometries with appropriate path semantics.
- **SFNEXT-03**: Support geometry collections after atomic sf geometry handling is stable.

### Advanced Map Behavior

- **SFNEXT-04**: Provide a deliberate global-comparison projection mode for faceted sf maps.
- **SFNEXT-05**: Evaluate true polygon-overlap brushing if centroid brushing proves insufficient for real workflows.
- **SFNEXT-06**: Establish performance budgets and simplification guidance for large or highly detailed maps.

## Out of Scope

Explicit exclusions for this milestone.

| Feature | Reason |
|---------|--------|
| Tile or raster basemaps | gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity, not a Leaflet/Mapbox-style map engine. |
| Slippy map zoom/pan controls | Requires map-engine interaction semantics and conflicts with the first-build zoom suppression contract. |
| JavaScript-side CRS reprojection | CRS normalization stays in R via sf; the browser renderer consumes normalized GeoJSON. |
| Polygon-overlap brushing | Centroid brushing is the first production behavior and avoids adding computational geometry to JavaScript. |
| Large-map performance guarantees | Correctness-first polygon behavior must ship before meaningful SVG path performance budgets can be set. |
| `geom_sf_text()` / `geom_sf_label()` | Requires separate label placement/interior point extraction design beyond polygon rendering. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SFIR-01 | Phase 32 | Complete |
| SFIR-02 | Phase 32 | Complete |
| SFIR-03 | Phase 32 | Complete |
| SFREND-01 | Phase 33 | Complete |
| SFREND-02 | Phase 34 | Pending |
| SFREND-03 | Phase 34 | Pending |
| SFINTR-01 | Phase 33 | Complete |
| SFINTR-02 | Phase 33 | Pending |
| SFINTR-03 | Phase 33 | Pending |
| SFDOC-01 | Phase 35 | Pending |
| SFDOC-02 | Phase 35 | Pending |

**Coverage:**
- v1.8 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-05-20*
*Last updated: 2026-05-20 after roadmap creation*
