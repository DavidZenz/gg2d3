# Requirements: gg2d3 v1.12 Quality & Architecture Hardening

**Defined:** 2026-05-25
**Core Value:** Any ggplot2 plot should render identically in D3 -- same visual output, but now interactive and web-native.

## v1.12 Requirements

### Visual Validation

- [ ] **VIS-01**: Maintainers can run a deterministic browser visual smoke command that renders representative gg2d3 plots to inspectable screenshot or image artifacts under an ignored local output directory.
- [ ] **VIS-02**: Visual smoke coverage includes representative core surfaces: Cartesian geoms, facets, interactivity-facing marks, sf geometry marks, and the newly shipped polygon/sf-annotation geometry paths.
- [ ] **VIS-03**: Visual/browser validation skips cleanly with explicit messages when optional local dependencies such as Chrome, chromote, sf, or geojsonsf are unavailable.

### Architecture Maintainability

- [ ] **ARCH-01**: High-risk `as_d3_ir()` responsibilities are split or isolated behind focused helper boundaries without changing representative IR output.
- [ ] **ARCH-02**: Geom registration, update handlers, and interactivity selectors are less duplication-prone, with tests that fail when a supported geom is missing expected renderer or interaction wiring.
- [ ] **ARCH-03**: Public interaction payload sanitization remains consistent across registered geoms, including ordinary polygons and sf text/label annotations.

### Geometry Polish

- [ ] **GEOM-01**: Transformed-scale rect/tile behavior is classified with focused fixtures and either fixed at the implicated boundary or documented as an explicit non-goal with evidence.
- [ ] **GEOM-02**: Ordinary polygon topology and hole/subgroup behavior is characterized against ggplot2 output, with supported cases locked by tests and unsupported cases documented without overclaiming.
- [ ] **GEOM-03**: Text and label geometry polish candidates, including collision avoidance and path-following placement, are either scoped into a small verified improvement or explicitly deferred with implementation-ready evidence.

## Future Requirements

Deferred beyond v1.12.

### Browser And Visual Validation

- **FUT-01**: Add CI-hosted browser screenshot/perceptual regression execution once local smoke artifacts are stable and dependency behavior is predictable.
- **FUT-02**: Add pixel-diff thresholds against committed reference images if visual output proves stable enough across operating systems and graphics stacks.

### Architecture

- **FUT-03**: Complete broader `as_d3_ir()` modularization beyond the high-risk helper boundaries selected for v1.12.
- **FUT-04**: Move more renderer metadata into declarative geom descriptors if the v1.12 registration hardening proves useful.

### Geometry

- **FUT-05**: Add full ggrepel-compatible label placement if demand justifies the dependency and complexity.
- **FUT-06**: Add projection-aware map interactions beyond ggplot parity if gg2d3 intentionally expands toward GIS-style map tooling.

## Out of Scope

| Feature | Reason |
|---------|--------|
| CI-enforced screenshot diffs | v1.12 should first establish deterministic local artifacts and skip semantics before adding cross-platform CI thresholds. |
| Full rewrite of `as_d3_ir()` | Too broad for one milestone; v1.12 should isolate high-risk boundaries while preserving behavior. |
| Tile basemaps and slippy controls | Still outside gg2d3's SVG/htmlwidgets ggplot parity focus. |
| Full GIS topology repair | gg2d3 should render ggplot2 output, not become a spatial data cleaning library. |
| Full ggrepel clone | Collision avoidance may be classified or lightly improved, but a complete ggrepel implementation is too broad for v1.12. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| VIS-01 | TBD | Pending |
| VIS-02 | TBD | Pending |
| VIS-03 | TBD | Pending |
| ARCH-01 | TBD | Pending |
| ARCH-02 | TBD | Pending |
| ARCH-03 | TBD | Pending |
| GEOM-01 | TBD | Pending |
| GEOM-02 | TBD | Pending |
| GEOM-03 | TBD | Pending |

**Coverage:**
- v1.12 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after initial definition*
