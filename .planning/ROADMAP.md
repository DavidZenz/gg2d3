# Roadmap: gg2d3

## Milestones

- 🚧 **v1.14 Pkgdown Site Verification** — Phases 56-58 (active)
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

### 🚧 v1.14 Pkgdown Site Verification

**Milestone Goal:** Make the generated and published pkgdown site reflect the current gg2d3 sf/widget support contract, with repeatable evidence that site articles render representative widgets and do not silently go stale after source documentation changes.

**Requirements:** 9 total, 9 mapped
**Phases:** 3
**Starting phase:** 56

## Phases

**Phase Numbering:**
- Integer phases (56, 57, 58): Planned milestone work
- Decimal phases (56.1, 56.2): Urgent insertions, if needed

- [x] **Phase 56: Pkgdown Content And Widget Build Contract** - Generated pkgdown content and build configuration expose the current sf/widget support contract with representative rendered widgets.
- [x] **Phase 57: Generated Site Validation Gate** - A repeatable validation command detects stale generated-site content, missing sf sections, missing widget scaffolding, and missing widget assets.
- [ ] **Phase 58: Publication Evidence And Release Handoff** - GitHub Pages/pkgdown artifacts are inspectable, current, and folded into the release-readiness evidence path.

## Phase Details

### Phase 56: Pkgdown Content And Widget Build Contract

**Goal**: Generated pkgdown content and build configuration expose the current sf/widget support contract with representative rendered widgets.
**Depends on**: v1.13 archive
**Requirements**: DOCS-01, DOCS-02, DOCS-03, BUILD-01, BUILD-02, BUILD-03
**Success Criteria** (what must be TRUE):
  1. Source vignette, README, roxygen/generated help, NEWS, and generated pkgdown article/reference pages describe the same current sf/widget support contract.
  2. Local pkgdown build produces generated article pages with `gg2d3` htmlwidget scaffolding and dependencies for representative examples.
  3. The sf article chunk renders when `sf` and `geojsonsf` are available, or emits an explicit classified skip/failure that maintainers can see.
  4. Documentation explains which artifacts are source docs, generated `docs/`, GitHub Pages output, and browser visual smoke reports.
**Plans**: 3 plans
Plans:
- [x] 56-01-PLAN.md — Make sf article optional-dependency classification visible and create focused pkgdown marker tests.
- [x] 56-02-PLAN.md — Document artifact taxonomy and add visible website dependency evidence to the pkgdown workflow.
- [x] 56-03-PLAN.md — Regenerate README/help/pkgdown outputs and record final Phase 56 validation evidence.

### Phase 57: Generated Site Validation Gate

**Goal**: A repeatable validation command detects stale generated-site content, missing sf sections, missing widget scaffolding, and missing widget assets.
**Depends on**: Phase 56
**Requirements**: SITE-01
**Success Criteria** (what must be TRUE):
  1. A local or CI-suitable validation command checks generated pkgdown pages for current support-contract text, sf content, widget containers, and widget dependency assets.
  2. The validation gate fails with actionable messages when `docs/` is stale relative to source docs or when representative widget output is missing.
  3. Optional spatial dependency outcomes are classified separately from true site-generation failures.
  4. Maintainer diagnostics document how to run, interpret, and repair the generated-site validation gate.
**Plans**: 3 plans
Plans:
- [x] 57-01-PLAN.md — Extract the generated-site validation core into reusable helper functions and keep focused testthat checks canonical.
- [x] 57-02-PLAN.md — Add the maintainer/CI validation command and run it after pkgdown build before deploy.
- [x] 57-03-PLAN.md — Document the gate and record final SITE-01 validation evidence.

### Phase 58: Publication Evidence And Release Handoff

**Goal**: GitHub Pages/pkgdown artifacts are inspectable, current, and folded into the release-readiness evidence path.
**Depends on**: Phase 57
**Requirements**: SITE-02, SITE-03
**Success Criteria** (what must be TRUE):
  1. The pkgdown/GitHub Pages workflow can be triggered or inspected and its artifact/deployed output can be downloaded or checked for current sf/widget evidence.
  2. Release-readiness evidence records pkgdown source/build/deploy validation alongside tests, generated help, browser visual smoke, optional skips, and package check outcomes.
  3. NEWS or maintainer handoff notes describe the v1.14 publication-surface fix without implying new rendering support.
  4. Final validation maps every v1.14 requirement to source, generated site, workflow/artifact evidence, and residual-risk handoff.
**Plans**: 3 plans
Plans:
- [x] 58-01-PLAN.md - Make pkgdown workflow output downloadable and add publication-root inspection.
- [ ] 58-02-PLAN.md - Document publication artifact inspection and release messaging boundaries.
- [ ] 58-03-PLAN.md - Record final publication evidence and close release-readiness handoff.

## Progress

**Execution Order:**
Phases execute in numeric order: 56 → 57 → 58

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 56. Pkgdown Content And Widget Build Contract | DOCS-01, DOCS-02, DOCS-03, BUILD-01, BUILD-02, BUILD-03 | 3/3 | Complete | 2026-05-31 |
| 57. Generated Site Validation Gate | SITE-01 | 3/3 | Complete | 2026-06-01 |
| 58. Publication Evidence And Release Handoff | SITE-02, SITE-03 | 1/3 | In Progress | - |

## Archived Milestones

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
<summary>✅ v1.10 Release Hardening (Phases 40-43) — SHIPPED 2026-05-23</summary>

See `.planning/milestones/v1.10-ROADMAP.md`, `.planning/milestones/v1.10-REQUIREMENTS.md`, and `.planning/milestones/v1.10-phases/` for full details.

Delivered package dependency and artifact hygiene, optional browser/spatial skip hardening, release-blocking debt triage, repeatable release-gate evidence, release-facing documentation polish, and v1.10 release notes with residual-risk handoff.

</details>

<details>
<summary>✅ v1.9 and Earlier Milestones — SHIPPED 2026-02-16 to 2026-05-22</summary>

See `.planning/MILESTONES.md` and `.planning/milestones/` for full details.

</details>

---
*Roadmap updated: 2026-05-31 after starting v1.14 Pkgdown Site Verification*
