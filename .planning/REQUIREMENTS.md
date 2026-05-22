# Requirements: gg2d3

**Defined:** 2026-05-20
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.9 Requirements

Requirements for the sf Robustness and Expansion milestone. Each maps to exactly one roadmap phase.

### Browser Validation

- [x] **BRSF-01**: Automated browser smoke tests render saved sf widgets and assert live DOM `path.geom-sf` nodes, non-empty path data, row ids, finite anchor attributes, and no page or console errors.
- [x] **BRSF-02**: Browser smoke tests cover polygon regressions for choropleths, stacked overlays, faceted panels, skipped-row filtering, tooltip/handler payload sanitization, centroid brushing, and sf zoom suppression.
- [x] **BRSF-03**: Browser fixture generation uses non-self-contained htmlwidgets output, skips cleanly when optional browser/spatial dependencies are unavailable, and leaves useful failure artifacts for local debugging.

### Non-Polygon SF Geometry

- [ ] **SFGEOM-01**: `gg2d3()` accepts `POINT` and `MULTIPOINT` `geom_sf()` geometries into sf IR with source row identity, family-aware diagnostics, CRS normalization, and panel bbox metadata.
- [ ] **SFGEOM-02**: `gg2d3()` accepts `LINESTRING` and `MULTILINESTRING` `geom_sf()` geometries into sf IR with ordered geometry serialization, source row identity, family-aware diagnostics, CRS normalization, and panel bbox metadata.
- [ ] **SFGEOM-03**: The D3 sf renderer draws polygon, point, and line sf families as `path.geom-sf` nodes with family-specific classes, visible point radius behavior, line no-fill behavior, stable row ids, and finite representative anchors.
- [ ] **SFGEOM-04**: Mixed accepted sf families in stacked and faceted panels share panel-scoped projection/bbox behavior without breaking existing polygon rendering or skipped-row alignment.

### SF Interactivity And Documentation

- [x] **SFXDOC-01**: Tooltip, hover, custom handler, Shiny handler, and brush behavior work for sf point and line paths using sanitized source-row payloads and documented representative-anchor brushing semantics.
- [x] **SFXDOC-02**: `facet_wrap()` and `facet_grid()` browser/automated validation covers point, line, polygon, mixed-family, and empty-panel sf cases with panel-local counts and bbox/projection isolation.
- [ ] **SFXDOC-03**: README, vignettes, diagnostics docs, roxygen source, and generated help describe the v1.9 sf support contract for polygon, point, and line families, unsupported geometries, zoom suppression, browser validation, and map anti-features.

### Package Hardening

- [ ] **HARD-01**: Sf IR assembly is extracted behind focused helper boundaries so `as_d3_ir()` delegates sf layer preparation and panel bbox assembly without changing existing non-sf behavior.
- [ ] **HARD-02**: Private ggplot2 API access used by theme/layout extraction is centralized behind tested compatibility helpers or otherwise characterized with regression tests before additional refactoring.
- [ ] **HARD-03**: Regression coverage protects representative non-sf plots, polygon sf, point sf, line sf, facets, legends, date scales, coord_flip, and known renderer edge cases after hardening changes.

## Future Requirements

Deferred beyond v1.9.

### Advanced SF And Map Behavior

- **SFNEXT-01**: Support `GEOMETRYCOLLECTION` after atomic sf geometry handling remains stable.
- **SFNEXT-02**: Support `geom_sf_text()` and `geom_sf_label()` with deliberate label placement or representative point extraction.
- **SFNEXT-03**: Design projection-aware map zoom/pan behavior instead of Cartesian zoom suppression.
- **SFNEXT-04**: Evaluate true polygon/line overlap brushing if representative-anchor brushing proves insufficient.
- **SFNEXT-05**: Establish performance budgets, simplification guidance, or alternate rendering strategies for large or highly detailed sf layers.

## Out of Scope

Explicit exclusions for this milestone.

| Feature | Reason |
|---------|--------|
| Tile or raster basemaps | gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity, not a map engine. |
| Slippy map zoom/pan controls | Requires projection-aware map interaction design beyond v1.9's representative-anchor brushing and zoom-suppression contract. |
| JavaScript-side CRS reprojection | CRS normalization stays in R via sf; the browser renderer consumes normalized GeoJSON. |
| Geometry-overlap brushing | v1.9 keeps centroid/representative-anchor brushing to avoid adding computational geometry to JavaScript. |
| `GEOMETRYCOLLECTION` | Recursive mixed geometry semantics would complicate row identity and renderer behavior before atomic families are stable. |
| `geom_sf_text()` / `geom_sf_label()` | Requires separate label placement and collision/interior-point design. |
| Screenshot-diff visual regression as the primary gate | DOM behavior assertions are more stable and directly tied to the sf renderer contracts for this milestone. |
| Large-map performance guarantees | Correctness and regression coverage for point/line/polygon sf families come before performance budgets. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRSF-01 | Phase 36 | Complete |
| BRSF-02 | Phase 36 | Complete |
| BRSF-03 | Phase 36 | Complete |
| SFGEOM-01 | Phase 37 | Pending |
| SFGEOM-02 | Phase 37 | Pending |
| SFGEOM-03 | Phase 37 | Pending |
| SFGEOM-04 | Phase 37 | Pending |
| SFXDOC-01 | Phase 38 | Complete |
| SFXDOC-02 | Phase 38 | Complete |
| SFXDOC-03 | Phase 38 | Pending |
| HARD-01 | Phase 39 | Pending |
| HARD-02 | Phase 39 | Pending |
| HARD-03 | Phase 39 | Pending |

**Coverage:**
- v1.9 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-05-20*
