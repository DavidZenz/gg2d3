# Requirements: gg2d3

**Defined:** 2026-05-24
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.11 Requirements

Requirements for the Geometry Parity milestone. Each maps to exactly one roadmap phase.

### Ordinary Polygon Rendering

- [x] **POLY-01**: `as_d3_ir()` recognizes ordinary `geom_polygon()` layers and preserves grouped polygon row order, x/y coordinates, and mapped fill, stroke, alpha, linewidth, and linetype aesthetics.
- [x] **POLY-02
**: The D3 renderer draws ordinary `geom_polygon()` groups as closed SVG paths that match ggplot2 positioning, fill/stroke styling, clipping, and facet panel placement for representative Cartesian plots.
- [ ] **POLY-03**: Existing tooltip, hover, brush, and custom handler APIs can target ordinary polygon marks with stable classes, row identity, and sanitized callback payloads.

### Rect And Tile Edge Behavior

- [ ] **RECT-01**: Maintainers have a focused regression fixture that reproduces the deferred rect/tile out-of-bounds behavior across the relevant scale-limit and coordinate-limit cases, or proves the suspected mismatch is no longer present.
- [ ] **RECT-02**: Confirmed rect/tile out-of-bounds mismatches are fixed in the renderer or IR boundary, while non-issues are locked with tests and documented rationale.

### sf Text And Label Annotations

- [ ] **SFANN-01**: `geom_sf_text()` and `geom_sf_label()` inputs are extracted into IR with label text, supported aesthetics, geometry anchors, panel membership, and explicit skip diagnostics for unsupported, empty, invalid, or missing geometries.
- [ ] **SFANN-02**: The D3 renderer places sf text and labels at projected anchors that align with existing polygon/point/line sf panel projections in single-panel, stacked-layer, and faceted plots.
- [ ] **SFANN-03**: sf text and label marks support the existing tooltip, hover, brush, and handler contracts where meaningful without exposing renderer-private geometry metadata.

### Documentation And Validation

- [ ] **DOCVAL-01**: README, vignettes, diagnostics docs, roxygen source, generated help, and validation notes describe the v1.11 ordinary polygon, rect/tile edge, and sf annotation support contract with representative tests or browser smoke coverage.

## Future Requirements

Deferred beyond v1.11.

### Larger Geometry And Validation Work

- **FUT-01**: Add advanced ordinary polygon behavior such as explicit hole/subgroup support if representative ggplot2 use cases require more than grouped closed paths.
- **FUT-02**: Add `GEOMETRYCOLLECTION` support once polygon, point, line, and annotation contracts are stable.
- **FUT-03**: Add `ggrepel`-style label placement or collision avoidance for text and label geoms.
- **FUT-04**: Add projection-aware map interactions beyond the current SVG/htmlwidgets ggplot parity scope.
- **FUT-05**: Add screenshot or perceptual regression testing once DOM/source guards remain stable across recent geometry expansions.

## Out of Scope

Explicit exclusions for this milestone.

| Feature | Reason |
|---------|--------|
| Tile basemaps, slippy-map controls, or JavaScript CRS reprojection | gg2d3 remains a ggplot-to-SVG/htmlwidgets renderer, not a tiled map engine. |
| Full GIS topology operations or polygon repair | v1.11 should render ggplot2 output, not become a spatial data cleaning library. |
| `ggrepel` collision avoidance | Useful later, but too broad for the first sf text/label contract. |
| New non-geometry interactivity APIs | v1.11 should reuse the existing tooltip, hover, brush, zoom, and handler APIs. |
| Large-dataset performance budgets | Important future work, but separate from closing the selected geometry parity gaps. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| POLY-01 | Phase 44 | Complete |
| POLY-02 | Phase 44 | Complete |
| POLY-03 | Phase 44 | Pending |
| RECT-01 | Phase 45 | Pending |
| RECT-02 | Phase 45 | Pending |
| SFANN-01 | Phase 46 | Pending |
| SFANN-02 | Phase 46 | Pending |
| SFANN-03 | Phase 46 | Pending |
| DOCVAL-01 | Phase 47 | Pending |

**Coverage:**
- v1.11 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after creating v1.11 roadmap*
