# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)
- ✅ **v1.8 Production geom_sf Polygon MVP** — Phases 32-35 (shipped 2026-05-20)
- 🚧 **v1.9 sf Robustness and Expansion** — Phases 36-39 (in progress)

## Active Milestone

### 🚧 v1.9 sf Robustness and Expansion

**Milestone Goal:** Strengthen the `geom_sf` foundation with automated browser validation, non-polygon sf geometry support, and core package hardening.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (36.1, 36.2): Urgent insertions, if needed

- [x] **Phase 36: Browser sf Smoke Harness** - Developers can validate rendered sf widgets in a real browser before changing sf geometry behavior.
- [x] **Phase 37: Non-Polygon sf IR And Renderer** - Users can render polygon, point, and line sf families with shared projection and row identity contracts.
- [ ] **Phase 38: sf Interaction, Facet, And Documentation Hardening** - Users can rely on sf point/line interactivity, facet behavior, and documentation matching the v1.9 contract.
- [ ] **Phase 39: Package Internals Hardening** - Maintainers can evolve sf and core rendering internals behind regression coverage and focused helper boundaries.

## Phase Details

### Phase 36: Browser sf Smoke Harness
**Goal**: Developers can repeatedly validate live browser sf rendering before expanding geometry support.
**Depends on**: Phase 35
**Requirements**: BRSF-01, BRSF-02, BRSF-03
**Success Criteria** (what must be TRUE):
  1. Developer can run automated browser smoke tests that open saved sf widgets and assert live `path.geom-sf` DOM nodes, non-empty path data, stable row ids, finite anchor attributes, and no page or console errors.
  2. Polygon sf fixtures prove choropleth, stacked overlay, faceted panel, skipped-row filtering, sanitized tooltip/handler payload, centroid brush, and zoom-suppression regressions are caught.
  3. Browser fixture generation produces non-self-contained htmlwidgets output, skips cleanly when optional browser or spatial dependencies are unavailable, and leaves useful local failure artifacts.
**Plans**: 3 plans
Plans:
- [x] 36-01-PLAN.md — Add optional chromote dependency, extract shared sf fixtures, and create browser smoke helpers.
- [x] 36-02-PLAN.md — Add live browser DOM assertions for the Phase 35 polygon sf fixture matrix.
- [x] 36-03-PLAN.md — Add browser runtime error, sanitized payload, brush, and zoom-suppression assertions.
**UI hint**: yes

### Phase 37: Non-Polygon sf IR And Renderer
**Goal**: Users can render point and line `geom_sf()` layers without weakening existing polygon sf behavior.
**Depends on**: Phase 36
**Requirements**: SFGEOM-01, SFGEOM-02, SFGEOM-03, SFGEOM-04
**Success Criteria** (what must be TRUE):
  1. User can pass `POINT` and `MULTIPOINT` `geom_sf()` layers to `gg2d3()` and see visible sf point paths with source row identity, CRS normalization, diagnostics, finite anchors, and panel bbox metadata.
  2. User can pass `LINESTRING` and `MULTILINESTRING` `geom_sf()` layers to `gg2d3()` and see ordered sf line paths with source row identity, diagnostics, finite anchors, and line-oriented no-fill behavior.
  3. Polygon, point, and line sf families render as `path.geom-sf` with family-specific classes, stable row ids, and representative anchors that remain compatible with existing selectors.
  4. Mixed accepted sf families in stacked and faceted panels share panel-scoped projection/bbox behavior while skipped-row alignment and existing polygon rendering remain stable.
**Plans**: 4 plans
Plans:
- [x] 37-01-PLAN.md — Expand R-side sf IR acceptance, family metadata, diagnostics, and validation for point and line geometries.
- [x] 37-02-PLAN.md — Render sf polygon, point, and line families with shared projection, classes, anchors, and visible styling.
- [x] 37-03-PLAN.md — Wire sf point and line marks into tooltip, hover, handler, and brush interactivity with source-row deduplication.
- [x] 37-04-PLAN.md — Extend browser smoke fixtures and DOM assertions for point, line, mixed overlay, skipped-row, and faceted sf behavior.
**UI hint**: yes

### Phase 38: sf Interaction, Facet, And Documentation Hardening
**Goal**: Users can trust sf point and line interactivity, facet behavior, and documentation as the public v1.9 support contract.
**Depends on**: Phase 37
**Requirements**: SFXDOC-01, SFXDOC-02, SFXDOC-03
**Success Criteria** (what must be TRUE):
  1. User can use tooltip, hover, custom handler, Shiny handler, and brush behavior on sf point and line paths with sanitized source-row payloads.
  2. User can view `facet_wrap()` and `facet_grid()` sf widgets containing point, line, polygon, mixed-family, and empty-panel cases with panel-local counts and bbox/projection isolation.
  3. Browser validation covers stacked overlays, sf family interactivity, faceted and empty-panel behavior, and continued sf zoom suppression.
  4. README, vignettes, diagnostics docs, roxygen source, and generated help describe the polygon/point/line support contract, unsupported geometries, representative-anchor brushing, browser validation, zoom suppression, and map anti-features.
**Plans**: TBD
**UI hint**: yes

### Phase 39: Package Internals Hardening
**Goal**: Maintainers can continue sf expansion and renderer maintenance with lower regression risk in high-risk internals.
**Depends on**: Phase 38
**Requirements**: HARD-01, HARD-02, HARD-03
**Success Criteria** (what must be TRUE):
  1. Maintainer can inspect `as_d3_ir()` and see sf layer preparation and panel bbox assembly delegated to focused helper boundaries without changed non-sf behavior.
  2. Maintainer can find private ggplot2 theme/layout API access centralized behind tested compatibility helpers or protected by explicit characterization tests.
  3. Regression coverage protects representative non-sf plots, polygon sf, point sf, line sf, facets, legends, date scales, coord_flip, and known renderer edge cases after hardening changes.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 36 → 37 → 38 → 39

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 36. Browser sf Smoke Harness | 3/3 | Complete    | 2026-05-21 |
| 37. Non-Polygon sf IR And Renderer | 4/4 | Complete   | 2026-05-21 |
| 38. sf Interaction, Facet, And Documentation Hardening | 0/TBD | Not started | - |
| 39. Package Internals Hardening | 0/TBD | Not started | - |

## Archived Milestones

<details>
<summary>✅ v1.8 Production geom_sf Polygon MVP (Phases 32-35) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.8-ROADMAP.md` for full details.

Delivered production-safe polygon-family `geom_sf()` support: R-side sf extraction, WGS84 normalization, skipped-row diagnostics, D3 `path.geom-sf` rendering, tooltip/hover/handler interactivity, centroid brushing, sf zoom suppression, shared stacked-layer projection, faceted panel projection, and documentation/browser validation hardening.

Known deferred item at close: a future DOM-level browser smoke test would further reduce regression risk for rendered sf paths and brush behavior. See `.planning/milestones/v1.8-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.7-ROADMAP.md` for full details.

Delivered the `geom_sf` research handoff: R extraction feasibility, D3 polygon rendering prototype, interactivity design, and future implementation blueprint.

</details>

<details>
<summary>✅ Distribution: pkgdown and GH Pages Publishing (Phase 31) — SHIPPED 2026-05-17</summary>

Phase 31 was orthogonal to the v1.7 choropleth stream. It ported the pkgdown/GitHub Pages publishing work from the v1.1 `stupefied-austin` branch.

See `.planning/milestones/v1.7-ROADMAP.md` and phase history for distribution details.

</details>

<details>
<summary>✅ v1.0-v1.6 Previous Milestones — SHIPPED 2026-02-16 to 2026-04-04</summary>

See `.planning/milestones/` and archived roadmap files for full details on the MVP, interactive exploration, transitions, facets, theme parity, non-Cartesian systems, and advanced geom milestones.

</details>

---
*Roadmap updated: 2026-05-21 after completing Phase 36*
