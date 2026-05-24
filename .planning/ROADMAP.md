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
- ✅ **v1.9 sf Robustness and Expansion** — Phases 36-39 (shipped 2026-05-22)
- ✅ **v1.10 Release Hardening** — Phases 40-43 (shipped 2026-05-23)
- 🚧 **v1.11 Geometry Parity** — Phases 44-47 (in progress)

## Active Milestone

### 🚧 v1.11 Geometry Parity

**Milestone Goal:** Close the remaining geometry-parity gaps around ordinary polygons, rect/tile edge behavior, and sf annotations.

**Requirements:** 9 total, 9 mapped
**Phases:** 4
**Starting phase:** 44

## Phases

**Phase Numbering:**
- Integer phases (44, 45, 46, 47): Planned milestone work
- Decimal phases (44.1, 44.2): Urgent insertions, if needed

- [x] **Phase 44: Ordinary geom_polygon Support** - Users can render ordinary `geom_polygon()` layers as grouped D3 paths with representative styling, facets, and existing interactivity hooks.
- [ ] **Phase 45: Rect And Tile Edge Closure** - Maintainers have reproduced and fixed, or explicitly closed with evidence, the deferred rect/tile out-of-bounds behavior.
- [ ] **Phase 46: sf Text And Label Annotations** - Users can render `geom_sf_text()` and `geom_sf_label()` at projected anchors aligned with existing sf panel projections.
- [ ] **Phase 47: Geometry Parity Docs And Validation** - Users and maintainers have current docs, validation coverage, and support-contract notes for v1.11 geometry parity.

## Phase Details

### Phase 44: Ordinary geom_polygon Support
**Goal**: Users can render ordinary `geom_polygon()` layers as grouped D3 paths with representative styling, facets, and existing interactivity hooks.
**Depends on**: v1.10 archive
**Requirements**: POLY-01, POLY-02, POLY-03
**Success Criteria** (what must be TRUE):
  1. `as_d3_ir()` recognizes `GeomPolygon` layers and preserves group/order, x/y coordinates, and supported aesthetics.
  2. D3 renders each ordinary polygon group as a closed SVG path with ggplot2-like fill, stroke, alpha, clipping, and facet placement.
  3. Polygon marks participate in tooltip, hover, brush, and handler APIs through stable selectors and sanitized payloads.
  4. Representative unit/source checks cover single-panel, grouped, faceted, and interactivity-facing polygon behavior.
**Plans**: 3 plans
Plans:
- [x] 44-01-PLAN.md — Add ordinary `geom_polygon()` IR extraction and validation fixtures.
- [x] 44-02-PLAN.md — Implement D3 grouped polygon path rendering with styling, clipping, and facet coverage.
- [x] 44-03-PLAN.md — Wire polygon interactivity selectors, sanitized payloads, and regression coverage.

### Phase 45: Rect And Tile Edge Closure
**Goal**: Maintainers have reproduced and fixed, or explicitly closed with evidence, the deferred rect/tile out-of-bounds behavior.
**Depends on**: Phase 44
**Requirements**: RECT-01, RECT-02
**Success Criteria** (what must be TRUE):
  1. A focused fixture matrix covers rect/tile behavior under relevant scale limits and coordinate limits.
  2. Any confirmed mismatch is fixed at the renderer or IR boundary with regression tests.
  3. If the suspected mismatch is not reproducible, the non-issue is locked with tests and documented rationale.
  4. The outcome is recorded in diagnostics or validation notes so the v1.10 deferred item is closed cleanly.
**Plans**: 2 plans
Plans:
- [ ] 45-01-PLAN.md — Build the rect/tile out-of-bounds reproduction matrix and classify observed behavior.
- [ ] 45-02-PLAN.md — Fix confirmed mismatches or document and test the verified non-issue path.

### Phase 46: sf Text And Label Annotations
**Goal**: Users can render `geom_sf_text()` and `geom_sf_label()` at projected anchors aligned with existing sf panel projections.
**Depends on**: Phase 45
**Requirements**: SFANN-01, SFANN-02, SFANN-03
**Success Criteria** (what must be TRUE):
  1. R-side sf annotation extraction captures labels, supported aesthetics, geometry anchors, panel membership, and skipped-row diagnostics.
  2. D3 renders sf text and label marks at projected anchors for single-panel, stacked-layer, and faceted sf plots.
  3. sf annotation marks reuse existing tooltip, hover, brush, and handler contracts where meaningful without leaking private geometry metadata.
  4. Representative tests cover polygon, point, line, skipped-row, and faceted sf annotation cases.
**Plans**: 3 plans
Plans:
- [ ] 46-01-PLAN.md — Add `geom_sf_text()` and `geom_sf_label()` IR extraction, anchors, aesthetics, and diagnostics.
- [ ] 46-02-PLAN.md — Implement sf text/label D3 rendering against existing panel projection metadata.
- [ ] 46-03-PLAN.md — Harden sf annotation interactivity, facets, skipped rows, and regression coverage.

### Phase 47: Geometry Parity Docs And Validation
**Goal**: Users and maintainers have current docs, validation coverage, and support-contract notes for v1.11 geometry parity.
**Depends on**: Phase 46
**Requirements**: DOCVAL-01
**Success Criteria** (what must be TRUE):
  1. README, vignettes, diagnostics docs, roxygen source, and generated help describe the v1.11 polygon, rect/tile, and sf annotation contract.
  2. Validation notes link representative tests or browser smoke coverage for ordinary polygons, rect/tile edge behavior, and sf annotations.
  3. Deferred/future geometry items remain explicit and scoped rather than implied as shipped support.
**Plans**: 2 plans
Plans:
- [ ] 47-01-PLAN.md — Sweep source and generated documentation for v1.11 geometry parity language.
- [ ] 47-02-PLAN.md — Record validation evidence, residual risks, and next-milestone candidates.

## Progress

**Execution Order:**
Phases execute in numeric order: 44 → 45 → 46 → 47

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 44. Ordinary geom_polygon Support | POLY-01, POLY-02, POLY-03 | 3/3 | Complete | 2026-05-24 |
| 45. Rect And Tile Edge Closure | RECT-01, RECT-02 | 0/2 | Not started | — |
| 46. sf Text And Label Annotations | SFANN-01, SFANN-02, SFANN-03 | 0/3 | Not started | — |
| 47. Geometry Parity Docs And Validation | DOCVAL-01 | 0/2 | Not started | — |

## Archived Milestones

<details>
<summary>✅ v1.10 Release Hardening (Phases 40-43) — SHIPPED 2026-05-23</summary>

See `.planning/milestones/v1.10-ROADMAP.md`, `.planning/milestones/v1.10-REQUIREMENTS.md`, and `.planning/milestones/v1.10-phases/` for full details.

Delivered package dependency and artifact hygiene, optional browser/spatial skip hardening, release-blocking debt triage, repeatable release-gate evidence, release-facing documentation polish, and v1.10 release notes with residual-risk handoff.

</details>

<details>
<summary>✅ v1.9 sf Robustness and Expansion (Phases 36-39) — SHIPPED 2026-05-22</summary>

See `.planning/milestones/v1.9-ROADMAP.md` and `.planning/milestones/v1.9-REQUIREMENTS.md` for full details.

Delivered automated browser sf smoke harnessing, point-family and line-family `geom_sf()` IR/rendering/interactivity, hardened sf facet/documentation coverage, and package internals hardening around sf helper boundaries, ggplot2 compatibility wrappers, and regression gates.

</details>

<details>
<summary>✅ v1.8 Production geom_sf Polygon MVP (Phases 32-35) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.8-ROADMAP.md` for full details.

Delivered production-safe polygon-family `geom_sf()` support: R-side sf extraction, WGS84 normalization, skipped-row diagnostics, D3 `path.geom-sf` rendering, tooltip/hover/handler interactivity, centroid brushing, sf zoom suppression, shared stacked-layer projection, faceted panel projection, and documentation/browser validation hardening.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.7-ROADMAP.md` for full details.

Delivered the `geom_sf` research handoff: R extraction feasibility, D3 polygon rendering prototype, interactivity design, and future implementation blueprint.

</details>

<details>
<summary>✅ Distribution: pkgdown and GH Pages Publishing (Phase 31) — SHIPPED 2026-05-17</summary>

Phase 31 was orthogonal to the v1.7 choropleth stream. It ported the pkgdown/GitHub Pages publishing work from the v1.1 `stupefied-austin` branch.

</details>

<details>
<summary>✅ v1.0-v1.6 Previous Milestones — SHIPPED 2026-02-16 to 2026-04-04</summary>

See `.planning/milestones/` and archived roadmap files for full details on the MVP, interactive exploration, transitions, facets, theme parity, non-Cartesian systems, and advanced geom milestones.

</details>

---
*Roadmap updated: 2026-05-24 after creating v1.11 Geometry Parity*
