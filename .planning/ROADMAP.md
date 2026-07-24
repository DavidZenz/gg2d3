# Roadmap: gg2d3

## Milestones

- 🚧 **v1.15 Release Confidence And Maintenance** — Phases 59-62 (in progress)
- ✅ **v1.14 Pkgdown Site Verification** — Phases 56-58 (shipped 2026-06-01)
- ✅ **v1.13 Regression & Release Polish** — Phases 52-55 (shipped 2026-05-31)
- ✅ **v1.12 Quality & Architecture Hardening** — Phases 48-51 (shipped 2026-05-27)
- ✅ **v1.11 Geometry Parity** — Phases 44-47 (shipped 2026-05-25)
- ✅ **v1.10 Release Hardening** — Phases 40-43 (shipped 2026-05-23)
- ✅ **v1.9 sf Robustness and Expansion** — Phases 36-39 (shipped 2026-05-22)
- ✅ **v1.8 Production geom_sf Polygon MVP** — Phases 32-35 (shipped 2026-05-20)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)
- ✅ **v1.0-v1.6 Previous Milestones** — Phases 1-26 (shipped 2026-02-16 to 2026-04-04)

## Active Milestone

### 🚧 v1.15 Release Confidence And Maintenance

**Milestone Goal:** Turn the now-truthful publication surface into release-grade confidence by closing CI/release hygiene risks, deepening visual regression evidence, shipping bounded geometry polish, and continuing architecture cleanup around the highest-risk IR/rendering seams.

**Requirements:** 12 total, 12 mapped
**Phases:** 4
**Starting phase:** 59

## Phases

**Phase Numbering:**

- Integer phases (59, 60, 61, 62): Planned milestone work
- Decimal phases (59.1, 59.2): Urgent insertions, if needed

- [x] **Phase 59: Release Hygiene And Local Spatial Recovery** - Resolve or mitigate release-readiness advisories and make local spatial validation repairable. (completed 2026-07-23)
- [ ] **Phase 60: Pkgdown Visual Regression Depth** - Add representative browser visual evidence for pkgdown pages and widget regions beyond marker checks.
- [ ] **Phase 61: Bounded Geometry Polish Tranche** - Select and close evidence-backed geometry polish gaps without expanding the public support contract too broadly.
- [ ] **Phase 62: Architecture Cleanup And Release Handoff** - Extract one more high-risk helper boundary, re-audit contracts, and assemble final v1.15 release evidence.

## Phase Details

### Phase 59: Release Hygiene And Local Spatial Recovery

**Goal**: Resolve or mitigate release-readiness advisories and make local spatial validation repairable.
**Depends on**: v1.14 archive
**Requirements**: REL-01, REL-02
**Success Criteria** (what must be TRUE):

  1. GitHub Actions runtime advisories are resolved through action/runtime updates or recorded as an upstream-known mitigation with a tested workflow outcome.
  2. Local `sf`/GDAL failure mode is documented with diagnostic commands and repair guidance that explains how to turn local `classified_skip` into rendered sf evidence.
  3. Pkgdown and browser visual workflows still pass or classify skips explicitly after the release-hygiene changes.
  4. Maintainer docs distinguish local environment repair from package/runtime regressions.

**Plans**: 3 plans
Plans:

- [x] 59-01-PLAN.md — Audit GitHub Actions runtime advisories and update or mitigate workflow actions.
- [x] 59-02-PLAN.md — Document and validate local `sf`/GDAL repair diagnostics.
- [x] 59-03-PLAN.md — Re-run release hygiene gates and record Phase 59 evidence.

### Phase 60: Pkgdown Visual Regression Depth

**Goal**: Add representative browser visual evidence for pkgdown pages and widget regions beyond marker checks.
**Depends on**: Phase 59
**Requirements**: VIS-01, VIS-02, VIS-03
**Success Criteria** (what must be TRUE):

  1. A repeatable command captures screenshots or equivalent browser evidence for selected pkgdown article pages.
  2. The visual gate detects blank, missing, or stale widget regions for representative core, sf, and Crosstalk examples.
  3. Visual artifacts are deterministic enough for review, stored under ignored paths, and excluded from package builds.
  4. Documentation explains local/CI behavior, artifact locations, and expected skip classifications.

**Plans**: 3 plans
Plans:

- [ ] 60-01-PLAN.md — Tracer: chromote capture of the built pkgdown article with SVG-child blank/stale detection, sf/Crosstalk outcome branching, and PNG+JSON artifacts.
- [ ] 60-02-PLAN.md — Wire the visual capture into pkgdown.yaml CI after the site build (install chromote, non-fatal Chrome locate, step-scoped CI escalation, artifact upload).
- [ ] 60-03-PLAN.md — Document local/CI visual regression usage and skip classifications, then record validation evidence.

### Phase 61: Bounded Geometry Polish Tranche

**Goal**: Select and close evidence-backed geometry polish gaps without expanding the public support contract too broadly.
**Depends on**: Phase 60
**Requirements**: GEOM-01, GEOM-02, GEOM-03
**Success Criteria** (what must be TRUE):

  1. Deferred geometry candidates are classified against ggplot2 behavior, existing tests, and public support boundaries before implementation.
  2. At least one high-value bounded geometry gap is closed by implementation, verified non-issue classification, or explicit non-goal documentation.
  3. Affected geoms preserve tooltip, hover, brush, Crosstalk, facet, and update-path contracts.
  4. README/vignettes/diagnostics/help text name the shipped polish and adjacent non-goals accurately.

**Plans**: 3 plans
Plans:

- [ ] 61-01-PLAN.md — Classify deferred geometry candidates and choose bounded scope.
- [ ] 61-02-PLAN.md — Implement or close selected geometry polish candidate(s).
- [ ] 61-03-PLAN.md — Update documentation and record geometry-polish validation evidence.

### Phase 62: Architecture Cleanup And Release Handoff

**Goal**: Extract one more high-risk helper boundary, re-audit contracts, and assemble final v1.15 release evidence.
**Depends on**: Phase 61
**Requirements**: REL-03, ARCH-01, ARCH-02, ARCH-03
**Success Criteria** (what must be TRUE):

  1. One additional `as_d3_ir()` or sf/source-data responsibility is extracted behind focused helpers with characterization tests.
  2. Renderer/interactivity contract tests cover changed helper boundaries, selectors, and public payload shape.
  3. Private ggplot2 compatibility risks are re-audited and documented as known fragility or resolved regression risk.
  4. Final release-readiness evidence includes package tests, generated help, pkgdown artifact inspection, browser visual evidence, package check, and residual-risk handoff.

**Plans**: 3 plans
Plans:

- [ ] 62-01-PLAN.md — Extract one high-risk IR/sf helper boundary with characterization tests.
- [ ] 62-02-PLAN.md — Re-audit renderer/interactivity and ggplot2 compatibility contracts.
- [ ] 62-03-PLAN.md — Assemble final v1.15 release-readiness evidence and handoff.

## Progress

**Execution Order:**
Phases execute in numeric order: 59 → 60 → 61 → 62

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 59. Release Hygiene And Local Spatial Recovery | REL-01, REL-02 | 3/3 | Complete    | 2026-07-23 |
| 60. Pkgdown Visual Regression Depth | VIS-01, VIS-02, VIS-03 | 0/3 | Not started | - |
| 61. Bounded Geometry Polish Tranche | GEOM-01, GEOM-02, GEOM-03 | 0/3 | Not started | - |
| 62. Architecture Cleanup And Release Handoff | REL-03, ARCH-01, ARCH-02, ARCH-03 | 0/3 | Not started | - |

## Archived Milestones

<details>
<summary>✅ v1.14 Pkgdown Site Verification (Phases 56-58) — SHIPPED 2026-06-01</summary>

See `.planning/milestones/v1.14-ROADMAP.md`, `.planning/milestones/v1.14-REQUIREMENTS.md`, and `.planning/milestones/v1.14-phases/` for full details.

Delivered generated/pkgdown site freshness checks, representative widget scaffolding and asset validation, rendered sf and rendered Crosstalk artifact inspection, GitHub Pages publication evidence, linked Crosstalk browser UAT, and final sf tooltip source-field preservation.

</details>

<details>
<summary>✅ v1.13 Regression & Release Polish (Phases 52-55) — SHIPPED 2026-05-31</summary>

See `.planning/milestones/v1.13-ROADMAP.md`, `.planning/milestones/v1.13-REQUIREMENTS.md`, and `.planning/milestones/v1.13-phases/` for full details.

Delivered CI-ready browser visual smoke artifacts, renderer/IR contract hardening, bounded label and geometry polish, source-first release documentation, v1.13 NEWS, repeatable release-gate evidence, and final 13/13 requirement validation.

</details>

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
<summary>✅ v1.10 and Earlier Milestones — SHIPPED 2026-02-16 to 2026-05-23</summary>

See `.planning/MILESTONES.md` and `.planning/milestones/` for full details.

</details>

---
*Roadmap updated: 2026-06-02 after starting v1.15 Release Confidence And Maintenance*
