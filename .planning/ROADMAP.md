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
- ✅ **v1.11 Geometry Parity** — Phases 44-47 (shipped 2026-05-25)
- 🚧 **v1.12 Quality & Architecture Hardening** — Phases 48-51 (active)

## Active Milestone

### 🚧 v1.12 Quality & Architecture Hardening

**Milestone Goal:** Make gg2d3 easier to trust and extend by adding visual/browser regression coverage, reducing renderer/IR maintenance burden, and closing high-value geometry polish gaps.

**Requirements:** 9 total, 9 mapped
**Phases:** 4
**Starting phase:** 48

## Phases

**Phase Numbering:**
- Integer phases (48, 49, 50, 51): Planned milestone work
- Decimal phases (48.1, 48.2): Urgent insertions, if needed

- [x] **Phase 48: Browser Visual Smoke Coverage** - Maintainers can generate deterministic browser-rendered visual artifacts for representative gg2d3 surfaces, with explicit optional-dependency skip behavior.
- [x] **Phase 49: IR Helper Boundary Hardening** - Maintainers can change selected high-risk `as_d3_ir()` responsibilities through focused helpers without representative IR drift.
- [x] **Phase 50: Renderer Wiring And Interaction Contracts** - Supported geoms have less duplication-prone renderer/update/interactivity wiring, with tests guarding missing wiring and public payload sanitization.
- [ ] **Phase 51: Geometry Edge-Case Classification And Polish** - Maintainers have verified outcomes for transformed rect/tile behavior, ordinary polygon topology, and text/label placement candidates.

## Phase Details

### Phase 48: Browser Visual Smoke Coverage
**Goal**: Maintainers can generate deterministic browser-rendered visual artifacts for representative gg2d3 surfaces, with explicit optional-dependency skip behavior.
**Depends on**: v1.11 archive
**Requirements**: VIS-01, VIS-02, VIS-03
**Success Criteria** (what must be TRUE):
  1. A documented local command renders representative gg2d3 plots into inspectable image artifacts under an ignored local output directory.
  2. The visual smoke set covers Cartesian geoms, facets, interactivity-facing marks, sf marks, ordinary polygons, and sf annotations.
  3. Browser visual validation skips with explicit messages when Chrome, chromote, sf, geojsonsf, or equivalent optional dependencies are unavailable.
  4. Failure artifacts give maintainers enough local evidence to inspect what rendered without committing generated outputs.
**Plans**: 3 plans

Plans:
- [x] 48-01-PLAN.md — Shared browser visual smoke helper and artifact/report contract.
- [x] 48-02-PLAN.md — Opt-in visual smoke fixture matrix and runner.
- [x] 48-03-PLAN.md — Maintainer diagnostics documentation and final source hygiene checks.

### Phase 49: IR Helper Boundary Hardening
**Goal**: Maintainers can change selected high-risk `as_d3_ir()` responsibilities through focused helpers without representative IR drift.
**Depends on**: Phase 48
**Requirements**: ARCH-01
**Success Criteria** (what must be TRUE):
  1. Selected high-risk IR responsibilities are isolated behind named internal helpers with clear inputs and outputs.
  2. Representative non-sf, sf, facet, scale, and annotation IR fixtures remain unchanged except for intentional documented differences.
  3. Failures in helper-level characterization tests identify the affected IR boundary rather than only the monolithic `as_d3_ir()` path.
**Plans**: 3 plans

Plans:
- [x] 49-01-PLAN.md — Scale, axis break, transform, and temporal metadata helper boundary.
- [x] 49-02-PLAN.md — Layer rowization, geom naming, aesthetic maps, and non-sf layer assembly helper boundary.
- [x] 49-03-PLAN.md — Facet/panel metadata helper boundary and final Phase 49 validation.

### Phase 50: Renderer Wiring And Interaction Contracts
**Goal**: Supported geoms have less duplication-prone renderer/update/interactivity wiring, with tests guarding missing wiring and public payload sanitization.
**Depends on**: Phase 49
**Requirements**: ARCH-02, ARCH-03
**Success Criteria** (what must be TRUE):
  1. Geom registration, update handlers, and interactivity selectors are expressed through a less duplication-prone source of truth or validation gate.
  2. Tests fail when a supported geom lacks expected renderer registration, update handling, or interaction selector coverage.
  3. Public tooltip, hover, brush, and handler payloads consistently omit renderer-private fields across registered geoms.
  4. Ordinary polygons and sf text/label annotations are included in the interaction sanitization coverage.
**Plans**:
- [x] 50-01-PLAN.md — Internal geom contract plus renderer registration and update coverage source tests.
- [x] 50-02-PLAN.md — Events, brush, and crosstalk selector contract coverage with explicit module-specific differences.
- [x] 50-03-PLAN.md — Shared public payload sanitizer, private-field contract coverage, and final validation notes.

### Phase 51: Geometry Edge-Case Classification And Polish
**Goal**: Maintainers have verified outcomes for transformed rect/tile behavior, ordinary polygon topology, and text/label placement candidates.
**Depends on**: Phase 50
**Requirements**: GEOM-01, GEOM-02, GEOM-03
**Success Criteria** (what must be TRUE):
  1. Transformed-scale rect/tile behavior is classified with focused fixtures and either fixed at the implicated boundary or documented as an explicit non-goal with evidence.
  2. Ordinary polygon topology, hole, and subgroup behavior is characterized against ggplot2 output with supported cases locked by tests.
  3. Unsupported polygon topology cases are documented without implying full GIS topology repair.
  4. Text and label collision/path-following candidates have either a small verified improvement or an implementation-ready deferral note with evidence.
  5. Diagnostics or validation notes summarize the final geometry-polish contract for future milestone planning.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 48 → 49 → 50 → 51

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 48. Browser Visual Smoke Coverage | VIS-01, VIS-02, VIS-03 | 3/3 | Complete | 2026-05-26 |
| 49. IR Helper Boundary Hardening | ARCH-01 | 3/3 | Complete | 2026-05-26 |
| 50. Renderer Wiring And Interaction Contracts | ARCH-02, ARCH-03 | 3/3 | Complete | 2026-05-26 |
| 51. Geometry Edge-Case Classification And Polish | GEOM-01, GEOM-02, GEOM-03 | 4/4 | In progress | - |

## Archived Milestones

<details>
<summary>✅ v1.11 Geometry Parity (Phases 44-47) — SHIPPED 2026-05-25</summary>

See `.planning/milestones/v1.11-ROADMAP.md`, `.planning/milestones/v1.11-REQUIREMENTS.md`, and `.planning/milestones/v1.11-phases/` for full details.

Delivered ordinary `geom_polygon()` IR/rendering/interactivity, rect/tile edge closure with source-backed renderer fixes and classification evidence, `geom_sf_text()` / `geom_sf_label()` projected-anchor rendering with sanitized interaction contracts, and public docs/generated help/validation evidence for the v1.11 geometry support contract.

</details>

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
*Roadmap updated: 2026-05-25 after creating v1.12 Quality & Architecture Hardening*
