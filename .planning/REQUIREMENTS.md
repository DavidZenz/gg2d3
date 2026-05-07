# Requirements: gg2d3 — Milestone v1.1 Release Hardening

**Defined:** 2026-05-02
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.
**Milestone goal:** Make gg2d3 CRAN-submission ready with complete color fidelity, secondary axes, refactored internals, and robust edge case handling.

## v1.1 Requirements

Each requirement maps to exactly one phase. v1.0 requirements live in `MILESTONES.md` and the v1.0 archive.

### Packaging

- [ ] **PKG-01**: Package passes `R CMD check --as-cran` with zero ERRORs and zero WARNINGs
- [ ] **PKG-02**: DESCRIPTION declares all runtime Imports (ggplot2, htmlwidgets, and any other transitive runtime dependencies) with appropriate version floors
- [ ] **PKG-03**: Package metadata (Author, Maintainer, URL, BugReports, Title, Description) is complete and CRAN-valid

### Color

- [x] **COLOR-01
**: ggplot2 viridis, brewer, and manual color/fill scales render in D3 with the same colors ggplot2 produces (verified by visual diff against `ggplot_build()` output)
- [x] **COLOR-02
**: Continuous color scales render as a colorbar legend (gradient with axis ticks), not as a discrete key fallback

### Axes

- [ ] **AXIS-01**: `sec.axis` produces a rendered secondary axis in D3 — ticks, tick labels, and axis title — using the transformation function from the ggplot spec, not just reserved layout space

### Internals

- [x] **REFACTOR-01
**: `as_d3_ir()` is split into per-concern modules (scales, theme, facets, layers) with the top-level function under ~200 lines and each helper independently testable
- [x] **REFACTOR-02
**: `ggplot2:::calc_element()` usage is wrapped in a helper with a public-API fallback path so a private-API change in ggplot2 does not break gg2d3

### Robustness

- [ ] **ROBUST-01**: Non-finite values (`NA`, `NaN`, `Inf`, `-Inf`) in mapped aesthetics are filtered with a single warning per layer and rendered as visual gaps (no silent dropping, no blank widgets)
- [ ] **ROBUST-02**: R-side errors and JS-side runtime errors surface as a user-visible message inside the widget area instead of producing a blank output
- [ ] **ROBUST-03**: `geom_rect` clips correctly when rectangle bounds extend outside the panel limits
- [ ] **ROBUST-04**: Orphaned `GeomPolygon` reference is resolved — either a real renderer is added or the dispatch entry is removed and a graceful "unsupported geom" message is shown
- [ ] **ROBUST-05**: `coord_flip` combined with `facet_grid` renders panel axes on the correct sides (regression of v1.0 known limitation)

### Docs

- [ ] **DOCS-01**: CLAUDE.md, README, and vignettes accurately describe v1.0+ feature coverage — no stale "no legends or facets" claims, current limitations list reflects v1.1 reality

## Future Requirements

Deferred beyond v1.1 — acknowledged but not in this roadmap.

### Extensions

- **EXT-01**: Shiny reactive integration beyond basic htmlwidgets
- **EXT-02**: Support for ggplot2 extension packages (ggridges, ggrepel, ggforce)
- **EXT-03**: New geoms beyond the v1.0 set of 15

### Polish

- **POL-01**: Mobile-specific responsive sizing
- **POL-02**: Canvas/WebGL rendering path for large datasets

## Out of Scope

Explicit exclusions for v1.1 — documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Shiny integration beyond htmlwidgets | Separate future effort, not required for CRAN |
| ggplot2 extension packages (ggridges, ggrepel) | Focus on core ggplot2 first; CRAN deps explosion |
| New geoms beyond v1.0's 15 | v1.1 is hardening, not feature growth |
| Custom D3 extensions unrelated to ggplot2 mapping | Not the package's purpose |
| Mobile-specific optimizations | Web-first; mobile path is post-v1.x |
| Canvas/WebGL alternative renderer | SVG-only by design; perf path is a separate milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PKG-01 | Phase 17 | Pending |
| PKG-02 | Phase 17 | Pending |
| PKG-03 | Phase 17 | Pending |
| COLOR-01 | Phase 14 | Pending |
| COLOR-02 | Phase 14 | Pending |
| AXIS-01 | Phase 15 | Pending |
| REFACTOR-01 | Phase 13 | Complete (2026-05-04) |
| REFACTOR-02 | Phase 13 | Complete (2026-05-04) |
| ROBUST-01 | Phase 16 | Pending |
| ROBUST-02 | Phase 16 | Pending |
| ROBUST-03 | Phase 16 | Pending |
| ROBUST-04 | Phase 16 | Pending |
| ROBUST-05 | Phase 16 | Pending |
| DOCS-01 | Phase 18 | Pending |

**Coverage:**
- v1.1 requirements: 14 total
- Mapped to phases: 14 ✓
- Unmapped: 0

---
*Requirements defined: 2026-05-02*
*Last updated: 2026-05-02 — traceability populated by /gsd-roadmapper (Phases 13-18)*
