# Requirements: gg2d3 v1.15 Release Confidence And Maintenance

**Defined:** 2026-06-02
**Core Value:** Any ggplot2 plot should render identically in D3 -- same visual output, but now interactive and web-native.

## v1.15 Requirements

### Release Hygiene

- [x] **REL-01**: Maintainers can run the pkgdown and browser-visual workflows without unresolved GitHub Actions runtime advisories, or with a documented, tested mitigation when upstream actions still emit advisory noise.
- [x] **REL-02**: Maintainers can diagnose and repair local `sf`/GDAL dynamic-library failures well enough to convert local sf validation from `classified_skip` to rendered evidence when the spatial stack is available.
- [ ] **REL-03**: Release-readiness evidence includes an updated package-check, generated-help, pkgdown artifact, browser visual, and residual-risk ledger for v1.15.

### Visual Regression

- [ ] **VIS-01**: Maintainers can capture representative pkgdown article screenshots or equivalent browser evidence for pages that include core widgets, sf examples, Crosstalk examples, and visual-smoke links.
- [ ] **VIS-02**: The visual evidence gate detects blank, missing, or visibly stale widget regions in selected pkgdown pages before release.
- [ ] **VIS-03**: Visual-regression artifacts remain deterministic, ignored from package builds, and documented with clear local/CI skip behavior.

### Geometry Polish

- [ ] **GEOM-01**: At least one deferred geometry gap is selected through source-backed classification and closed with implementation, explicit non-goal documentation, or a verified non-issue outcome.
- [ ] **GEOM-02**: Geometry polish changes preserve existing tooltip, hover, brush, Crosstalk, facet, and update-path contracts for affected geoms.
- [ ] **GEOM-03**: Public documentation names the shipped geometry polish and adjacent non-goals without implying broad GIS topology repair, ggrepel, rich text, or basemap support.

### Architecture Cleanup

- [ ] **ARCH-01**: One additional high-risk `as_d3_ir()` or sf/source-data responsibility is extracted behind focused helpers with characterization tests.
- [ ] **ARCH-02**: Renderer/interactivity contract tests cover any new or changed helper boundaries, selector behavior, and public payload shape.
- [ ] **ARCH-03**: Private ggplot2 compatibility risks and helper boundaries are re-audited so release notes can distinguish known fragility from new regressions.

## Future Requirements

Deferred beyond v1.15.

### Future Visual And Geometry Work

- **FUT-01**: Add full perceptual-diff thresholds for a broad browser matrix after representative screenshot capture is stable.
- **FUT-02**: Implement compound-path polygon holes or topology repair if a bounded ggplot2 parity case justifies it.
- **FUT-03**: Add rich text, ggrepel-style collision avoidance, or path-following labels as separate scoped milestones.
- **FUT-04**: Add external uptime or freshness monitoring for the public pkgdown site after release workflows are stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New broad geom families | v1.15 is release confidence and maintenance, not a new feature-expansion milestone. |
| Tile basemaps/slippy-map controls | Still outside gg2d3's SVG/htmlwidgets ggplot parity focus. |
| Full GIS polygon topology repair | Too broad for a release-confidence tranche; classify and close only bounded parity cases. |
| Mandatory wide-matrix pixel thresholds | First deepen representative visual evidence before enforcing broad perceptual thresholds. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 59 | Complete |
| REL-02 | Phase 59 | Complete |
| REL-03 | Phase 62 | Pending |
| VIS-01 | Phase 60 | Pending |
| VIS-02 | Phase 60 | Pending |
| VIS-03 | Phase 60 | Pending |
| GEOM-01 | Phase 61 | Pending |
| GEOM-02 | Phase 61 | Pending |
| GEOM-03 | Phase 61 | Pending |
| ARCH-01 | Phase 62 | Pending |
| ARCH-02 | Phase 62 | Pending |
| ARCH-03 | Phase 62 | Pending |

**Coverage:**

- v1.15 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-06-02*
*Last updated: 2026-06-02 during v1.15 roadmap creation*
