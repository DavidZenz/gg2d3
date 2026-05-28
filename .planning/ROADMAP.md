# Roadmap: gg2d3

## Milestones

- 🚧 **v1.13 Regression & Release Polish** — Phases 52-55 (active)
- ✅ **v1.12 Quality & Architecture Hardening** — Phases 48-51 (shipped 2026-05-27)
- ✅ **v1.11 Geometry Parity** — Phases 44-47 (shipped 2026-05-25)
- ✅ **v1.10 Release Hardening** — Phases 40-43 (shipped 2026-05-23)
- ✅ **v1.9 sf Robustness and Expansion** — Phases 36-39 (shipped 2026-05-22)
- ✅ **v1.8 Production geom_sf Polygon MVP** — Phases 32-35 (shipped 2026-05-20)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)
- ✅ **v1.0-v1.6 Previous Milestones** — Phases 1-26 (shipped 2026-02-16 to 2026-04-04)

## Active Milestone

### 🚧 v1.13 Regression & Release Polish

**Milestone Goal:** Turn the new validation and architecture foundations into release-ready regression confidence while closing the next practical geometry polish gaps.

**Requirements:** 13 total, 13 mapped
**Phases:** 4
**Starting phase:** 52

## Phases

**Phase Numbering:**
- Integer phases (52, 53, 54, 55): Planned milestone work
- Decimal phases (52.1, 52.2): Urgent insertions, if needed

- [x] **Phase 52: CI Visual Regression Foundation** - Maintainers can run CI-safe browser visual smoke coverage with inspectable artifacts and stable non-pixel assertions.
- [ ] **Phase 53: Renderer And IR Contract Consolidation** - Renderer wiring and selected IR responsibilities are governed by clearer source-of-truth contracts with actionable drift tests.
- [ ] **Phase 54: Geometry Polish Closure** - Label, polygon topology, transformed rect/tile, and text-placement candidates are either shipped in bounded form or deferred with implementation-ready evidence.
- [ ] **Phase 55: Release Documentation And Validation Gate** - v1.13 support, validation commands, release checks, and residual risks are documented and verified from source through generated artifacts.

## Phase Details

### Phase 52: CI Visual Regression Foundation

**Goal**: Maintainers can run CI-safe browser visual smoke coverage with inspectable artifacts and stable non-pixel assertions.
**Depends on**: v1.12 archive
**Requirements**: CI-01, CI-02, CI-03
**Success Criteria** (what must be TRUE):
  1. CI or CI-equivalent browser visual smoke command preserves the v1.12 opt-in and optional dependency skip semantics.
  2. Browser visual outputs include deterministic paths for HTML, screenshot, DOM summary, browser log, JSON index, and human-readable report artifacts.
  3. Stable DOM/metadata assertions catch missing marks, empty fixtures, selector drift, and runtime browser errors without requiring committed golden screenshots.
  4. Documentation explains how to inspect CI/local artifacts and why pixel thresholds remain deferred.
**Plans**: TBD

### Phase 53: Renderer And IR Contract Consolidation

**Goal**: Renderer wiring and selected IR responsibilities are governed by clearer source-of-truth contracts with actionable drift tests.
**Depends on**: Phase 52
**Requirements**: ARCH-01, ARCH-02, ARCH-03
**Success Criteria** (what must be TRUE):
  1. Geom registration, update selector, interaction selector, and public payload expectations are derived from or validated against a single internal geom contract source.
  2. Additional high-risk `as_d3_ir()` responsibilities are isolated behind focused helpers while representative IR fixtures remain unchanged.
  3. Contract tests fail with clear messages when a supported geom lacks renderer metadata, module loading, update handling, or interaction payload sanitization coverage.
  4. Diagnostics or architecture notes describe the remaining modularization boundary and future migration path.
**Plans**: 3 plans
Plans:
- [ ] 53-01-PLAN.md - Renderer contract hardening for modules, selectors, exceptions, and public payload drift.
- [ ] 53-02-PLAN.md - IR helper boundary hardening for theme extraction and geom parameter routing.
- [ ] 53-03-PLAN.md - Diagnostics and consolidated Phase 53 validation evidence.

### Phase 54: Geometry Polish Closure

**Goal**: Label, polygon topology, transformed rect/tile, and text-placement candidates are either shipped in bounded form or deferred with implementation-ready evidence.
**Depends on**: Phase 53
**Requirements**: GEOM-01, GEOM-02, GEOM-03, GEOM-04
**Success Criteria** (what must be TRUE):
  1. Ordinary `geom_label()` box/padding/fill/stroke behavior is implemented for a bounded renderer path or documented as a source-backed non-goal with diagnostics.
  2. Ordinary `geom_polygon()` subgroup/hole behavior has focused ggplot2 comparison fixtures and either bounded support or an explicit non-goal contract.
  3. Transformed rect/tile scale semantics are resolved at a shared boundary or narrowed to an implementation-ready follow-up with stronger evidence than v1.12.
  4. Collision avoidance, path-following text, rotation, and justification candidates are triaged without implying unsupported label-placement parity.
  5. Focused tests and diagnostics distinguish shipped support from future geometry requirements.
**Plans**: TBD

### Phase 55: Release Documentation And Validation Gate

**Goal**: v1.13 support, validation commands, release checks, and residual risks are documented and verified from source through generated artifacts.
**Depends on**: Phase 54
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. README, vignettes, diagnostics docs, roxygen source, and generated help describe the same v1.13 validation, architecture, and geometry support contract.
  2. A repeatable release-readiness gate records package tests, documentation generation, browser visual smoke behavior, optional dependency skips, and package check evidence.
  3. v1.13 release notes summarize shipped support, validation commands, artifact locations, residual risks, and future candidates without publishing local logs.
  4. Final validation evidence maps every v1.13 requirement to source, tests, docs, and release-gate outcomes.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 52 → 53 → 54 → 55

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 52. CI Visual Regression Foundation | CI-01, CI-02, CI-03 | 3/3 | Complete    | 2026-05-28 |
| 53. Renderer And IR Contract Consolidation | ARCH-01, ARCH-02, ARCH-03 | 0/? | Not started | - |
| 54. Geometry Polish Closure | GEOM-01, GEOM-02, GEOM-03, GEOM-04 | 0/? | Not started | - |
| 55. Release Documentation And Validation Gate | REL-01, REL-02, REL-03 | 0/? | Not started | - |

## Archived Milestones

<details>
<summary>✅ v1.12 Quality & Architecture Hardening (Phases 48-51) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.12-ROADMAP.md`, `.planning/milestones/v1.12-REQUIREMENTS.md`, and `.planning/milestones/v1.12-phases/` for full details.

Delivered deterministic opt-in browser visual smoke coverage, high-risk IR helper boundaries, renderer/update/interactivity contract coverage, public payload sanitization coverage, and evidence-driven geometry polish for transformed rect/tile behavior, ordinary polygon topology boundaries, and ordinary text sizing.

</details>

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
<summary>✅ v1.9 and Earlier Milestones — SHIPPED 2026-02-16 to 2026-05-22</summary>

See `.planning/MILESTONES.md` and `.planning/milestones/` for full details.

</details>

---
*Roadmap updated: 2026-05-27 after creating v1.13 Regression & Release Polish*
