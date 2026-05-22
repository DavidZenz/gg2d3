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
- 🚧 **v1.10 Release Hardening** — Phases 40-43 (in progress)

## Active Milestone

### 🚧 v1.10 Release Hardening

**Milestone Goal:** Prepare gg2d3 for a cleaner release-quality checkpoint by closing package hygiene gaps, validating the release surface, and documenting known residual risks.

**Requirements:** 10 total, 10 mapped
**Phases:** 4
**Starting phase:** 40

## Phases

**Phase Numbering:**
- Integer phases (40, 41, 42): Planned milestone work
- Decimal phases (40.1, 40.2): Urgent insertions, if needed

- [ ] **Phase 40: Package Hygiene** - Maintainers can run tests, examples, docs, and optional validation tooling without undeclared dependencies or source-tree artifact noise.
- [ ] **Phase 41: Release-Blocking Debt Triage** - Maintainers have fixed or explicitly deferred known release-facing debt with rationale.
- [ ] **Phase 42: Release Validation Gate** - Maintainers can run and interpret a repeatable local release gate covering tests, docs, checks, and browser validation behavior.
- [ ] **Phase 43: Documentation And Release Notes** - Users and maintainers have current docs, release notes, residual-risk notes, and next-milestone candidates.

## Phase Details

### Phase 40: Package Hygiene
**Goal**: Maintainers can run tests, examples, docs, and optional validation tooling without undeclared dependencies or source-tree artifact noise.
**Depends on**: v1.9 archive
**Requirements**: HYG-01, HYG-02, HYG-03
**Success Criteria** (what must be TRUE):
  1. DESCRIPTION declares every direct runtime, test/helper, documentation, browser, and spatial package used by release-facing code in the correct field.
  2. Optional browser and spatial validation paths skip cleanly with clear messages when local tooling is unavailable.
  3. Generated fixtures, logs, check outputs, and smoke artifacts land in predictable ignored paths and do not pollute package sources.
**Plans**: 3 plans
Plans:
- [ ] 40-01-PLAN.md — Audit and fix DESCRIPTION/package metadata for direct dependencies used by tests, helpers, docs, browser tooling, and spatial validation.
- [ ] 40-02-PLAN.md — Harden optional dependency skip paths for browser and spatial validation without changing CRAN-friendly behavior.
- [ ] 40-03-PLAN.md — Normalize generated artifact paths and ignore rules for browser fixtures, logs, and local release outputs.

### Phase 41: Release-Blocking Debt Triage
**Goal**: Maintainers have fixed or explicitly deferred known release-facing debt with rationale.
**Depends on**: Phase 40
**Requirements**: DEBT-01, DEBT-02
**Success Criteria** (what must be TRUE):
  1. Recent advisory follow-ups are resolved or classified, including direct `pkgload`/`rprojroot` dependency declarations and facet browser panel identity assertions.
  2. Stale `GeomPolygon` references and rect out-of-bounds behavior are triaged, fixed when release-blocking, or documented as deferred non-blockers.
  3. Deferred debt has explicit rationale and next-step guidance rather than disappearing into vague notes.
**Plans**: 2 plans
Plans:
- [ ] 41-01-PLAN.md — Resolve or classify recent advisory follow-ups from review and verification artifacts.
- [ ] 41-02-PLAN.md — Triage stale renderer/documentation debt around `GeomPolygon` and rect out-of-bounds behavior.

### Phase 42: Release Validation Gate
**Goal**: Maintainers can run and interpret a repeatable local release gate covering tests, docs, checks, and browser validation behavior.
**Depends on**: Phase 41
**Requirements**: VAL-01, VAL-02, VAL-03
**Success Criteria** (what must be TRUE):
  1. A documented release gate runs package tests, documentation generation, and an `R CMD check`-style package check with expected optional skips.
  2. Representative non-sf plots, polygon/point/line sf plots, facet/legend/date/coord_flip behavior, and browser smoke behavior remain covered by the gate or by explicitly linked checks.
  3. Validation failures leave actionable logs or artifacts, and the release-gate documentation tells maintainers where to inspect them.
**Plans**: 3 plans
Plans:
- [ ] 42-01-PLAN.md — Define the local release gate commands and expected skip behavior.
- [ ] 42-02-PLAN.md — Run the release gate, repair release-blocking failures, and record the verification evidence.
- [ ] 42-03-PLAN.md — Document validation failure artifacts and browser smoke debugging paths.

### Phase 43: Documentation And Release Notes
**Goal**: Users and maintainers have current docs, release notes, residual-risk notes, and next-milestone candidates.
**Depends on**: Phase 42
**Requirements**: DOC-01, DOC-02
**Success Criteria** (what must be TRUE):
  1. README, vignettes, diagnostics docs, roxygen source, and generated help consistently describe the shipped polygon/point/line `geom_sf()` contract and optional browser validation.
  2. Stale milestone language is removed or updated across release-facing docs.
  3. A v1.10 release checklist or notes artifact records checks run, residual risks, deferred non-blockers, and recommended next-milestone candidates.
**Plans**: 2 plans
Plans:
- [ ] 43-01-PLAN.md — Sweep README, vignettes, diagnostics docs, roxygen source, and generated help for release-consistent language.
- [ ] 43-02-PLAN.md — Create v1.10 release checklist/notes with residual risks and next-milestone candidates.

## Progress

**Execution Order:**
Phases execute in numeric order: 40 → 41 → 42 → 43

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 40. Package Hygiene | HYG-01, HYG-02, HYG-03 | 0/3 | Pending | - |
| 41. Release-Blocking Debt Triage | DEBT-01, DEBT-02 | 0/2 | Pending | - |
| 42. Release Validation Gate | VAL-01, VAL-02, VAL-03 | 0/3 | Pending | - |
| 43. Documentation And Release Notes | DOC-01, DOC-02 | 0/2 | Pending | - |

## Archived Milestones

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
*Roadmap updated: 2026-05-22 after creating v1.10 Release Hardening*
