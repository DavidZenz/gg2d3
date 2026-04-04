# Requirements: gg2d3

**Defined:** 2026-03-31
**Milestone:** v1.6 Advanced Geoms & API Polish
**Core Value:** Any ggplot2 plot should render identically in D3 - same visual output, but now interactive and web-native.

## v1 Requirements

Requirements committed for milestone v1.6.

### Additional Geoms

- [ ] **GEOM-20**: User can render `geom_dotplot` with correct dot stacking and orientation.
- [ ] **GEOM-21**: User can render `geom_rug` for axis-aligned data density markers.
- [ ] **GEOM-22**: User can render `geom_errorbar`, `geom_linerange`, and `geom_pointrange`.

### API & Performance

- [ ] **API-01**: Developer can use a simplified internal helper for adding new geoms.
- [x] **API-02**: User sees comprehensive documentation for all `d3_*` interactivity functions.
- [ ] **PERF-01**: User sees improved rendering performance for plots with >5000 points.

## Completed Requirements

Successfully delivered in previous milestones.

### Non-Cartesian & Advanced Stats (v1.5)
- [x] **COORD-03..04**: Polar coordinates and radial axis labeling.
- [x] **GEOM-18..19**: Density and smooth (loess/gam) geoms.

### Theme Parity & Reference Geoms (v1.4)
- [x] **THEME-01..03**: Theme inheritance and detailed styling.
- [x] **GEOM-16..17**: hline, vline, and abline support.

### Facet Polish & Custom Interactivity (v1.3)
- [x] **FACE-01..02**: Nested facets and theme-aware labels.
- [x] **INT-01..02**: Custom handlers and Shiny sync.

### Smooth Transitions & Scale Parity (v1.2)
- [x] **TRAN-01..04**: Transitions and motion preferences.
- [x] **SCALE-01..03**: Advanced scale configuration.

### Interactive Legends (v1.1)
- [x] **LEG-01..04**: Discrete legend interactivity.

### Date/Time Parity (v1.1)
- [x] **DATE-01..03**: Date/datetime axis parity.

### Coordinate Hardening (v1.1)
- [x] **COORD-01..02**: coord_flip correctness.

## Traceability

Updated during v1.6 roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GEOM-20 | Phase 24 (render) + Phase 26 (interactivity) | Pending |
| GEOM-21 | Phase 24 (render) + Phase 26 (interactivity) | Pending |
| GEOM-22 | Phase 24 (render) + Phase 26 (interactivity + zoom) | Pending |
| API-01 | Phase 25 | Complete |
| API-02 | Phase 25 (source) + Phase 26 (regenerate) | Complete |
| PERF-01 | Phase 25 | Complete |

**Coverage:**
- v1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements updated: 2026-04-03*
