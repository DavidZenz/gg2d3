# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — Choropleth Map Research

**Shipped:** 2026-05-18
**Phases:** 4 v1.7 research (27-30) + 1 cross-milestone distribution (31) | **Plans:** 10
**Timeline:** 45 days (2026-04-04 → 2026-05-18) | **Git range:** cc31fad → c7a5c22 (30 files, +1897/-164)

### What Was Built
- R sf extraction pipeline: `R/sf_utils.R` + GeomSf/CoordSf dispatch in `as_d3_ir.R` + IR schema doc + 26 tests
- D3 sf renderer prototype: `inst/htmlwidgets/modules/geoms/sf.js` (113 lines) with `geoIdentity().reflectY().fitExtent()`, `fill-rule="evenodd"` for holes, centroid data attrs
- SF interactivity design contract: 29-01-SF-INTERACTIVITY-DESIGN.md (654 lines, 11 D-NN decisions) — tooltip/brush/zoom for `path.geom-sf`
- Implementation blueprint: 30-01-BLUEPRINT.md (734 lines) — three edge cases empirically resolved, three explicit anti-features, Build Phase A/B/C plan with file/line specificity
- pkgdown + GitHub Pages: live site at https://davidzenz.github.io/gg2d3/ with 44 interactive widget divs in the Get Started vignette (Phase 31)

### What Worked
- **Research-before-build sequencing.** Splitting the choropleth feature into a research milestone first (v1.7) ahead of an implementation milestone (v1.8 IMPL-04) surfaced the per-panel-bbox finding for faceted sf and the centroid-vs-polygon brush rejection rationale before any production code commits.
- **File/line-anchored design docs.** Both 29-01 and 30-01 cite the exact files and line numbers (`sf.js:99-104`, `as_d3_ir.R:711-721`, `brush.js:29-49`) the build phase must touch — verifiers can grep, build executors don't need to re-research.
- **Verifier scripts as completeness gates.** `29-interactivity-design/verify-design-doc.sh` (24 grep assertions) catches missing D-NN sections automatically — separates programmatic completeness from subjective human read.
- **Empirical edge-case investigation.** Phase 30 ran actual R scripts for each edge case rather than reasoning hypothetically — produced the EC3 per-panel-bbox finding that no amount of armchair design would have surfaced.
- **Anti-features as a first-class artifact.** Naming three durable anti-features (tile basemaps, JS reprojection, slippy zoom) with rationale and distinguishing them from merely-deferred items inoculates the build milestone against scope creep.

### What Was Inefficient
- **Phase 31 missing verification artifacts.** No 31-VERIFICATION.md and no 31-04-SUMMARY.md exist despite the site being live and human-approved. Future cross-milestone phases should still produce the standard artifacts even when work is orthogonal.
- **Phase 29 human-UAT items left pending at close.** The 4 subjective design-doc reads in 29-HUMAN-UAT.md were not formally completed; deferred via STATE.md. Either run the human UAT inline before closing or explicitly waive it as a class for design-only phases.
- **Phase 31 pkgdown loop took 3 CI runs to deploy a non-empty site.** Iterating against live GitHub Actions to debug vignette-eval and DESCRIPTION-Imports issues is slow. A local `pkgdown::build_site()` smoke that mirrors the CI environment would have caught both in one cycle.
- **Centroid attribute inconsistency (`data-centroid` vs `data-cx/data-cy`) shipped from Phase 28 into Phase 29 before resolution.** Caught by 29's Critical Inconsistency Resolution section — but it shouldn't have crossed phase boundaries unresolved. Cross-phase contract changes need a flag at execute-phase time.

### Patterns Established
- **Research milestone format:** sequence research phases as IR → renderer → interactivity → blueprint, terminating in a build-ready handoff document (BLUEPRINT.md), not in production code.
- **Verifier shell scripts** alongside design docs (`verify-*.sh`) as a lightweight completeness gate distinct from subjective human reads.
- **Three-source requirement coverage cross-reference** (REQUIREMENTS.md + VERIFICATION.md + SUMMARY frontmatter) — gives milestone audits an evidence chain rather than checkbox theater.
- **Optional-dependency Suggests pattern for heavy spatial deps** (sf, geojsonsf, rnaturalearth) with `requireNamespace()` guards and `skip_if_not_installed()` in tests — keeps base install lean and CI matrix tractable.

### Key Lessons
1. **Verification artifact discipline applies to cross-milestone phases too.** Phase 31 satisfied DOCS-02 substantively but produced no formal VERIFICATION.md — distribution phases should follow the same artifact discipline as feature phases, or the milestone audit becomes a guessing game.
2. **Pin the canonical attribute name early.** When R-side IR emits an attribute later consumed by a JS module, lock the name in the research phase (or earlier) — a renamed attribute mid-stream creates a documented "migration task" that propagates into the build milestone for no reason.
3. **Run human-UAT inline at execute-phase time, not deferred to audit.** Subjective reads ("is this design doc clear enough?") are easier to evaluate when the doc is fresh; deferring them creates verification gaps that linger until milestone close.
4. **Empirical investigation beats armchair design for edge cases.** EC3's per-panel-bbox finding was invisible from reading code — only running `gg_build()` on a faceted sf plot revealed it. Bake "run the actual scenario" into research-phase task lists.
5. **CI-only smoke loops are expensive.** When a workflow only runs in GitHub Actions (pkgdown deploy), invest 30 minutes upfront in a local reproducer that mirrors the CI environment before pushing iteration #2.

### Cost Observations
- Model mix: not measured this milestone (consider adding for v1.8)
- Sessions: spans 27 (Apr 4) → 30 (May 18); multiple sessions per phase
- Notable: research-phase planning was front-loaded — Phase 27's RESEARCH.md drove most of the milestone's design decisions, with later phases extending rather than reopening

---

## Milestone: v1.6 — Advanced Geoms & API Polish

**Shipped:** 2026-04-04
**Phases:** 3 | **Plans:** 4

### What Was Built
- 5 specialized D3 renderers (dotplot, rug, errorbar, linerange, pointrange)
- Standardized onRender pattern across all d3_* interactivity functions
- Full interactivity wiring for all new geoms (hover, tooltip, brush, zoom)
- Scoped interval updateGeoms handler with flip-aware coordinate logic
- Regenerated README.md documenting all 25 geoms and composable interactivity API

### What Worked
- Milestone audit caught integration gaps (INTERACTIVE_SELECTORS, updateGeoms stub) before shipping
- Gap closure phase (26) cleanly addressed all audit findings with minimal scope
- Parallel executor agents completed both Wave 1 plans simultaneously
- Research phase accurately identified all insertion points by line number

### What Was Inefficient
- Phase 24 shipped geom renderers without wiring interactivity, requiring Phase 26 gap closure
- Audit status remained `gaps_found` even after gap closure phase completed (stale audit)
- README.Rmd was updated in Phase 25 but `build_readme()` wasn't run until Phase 26

### Patterns Established
- Milestone audits before completion catch integration gaps that per-phase verification misses
- INTERACTIVE_SELECTORS arrays must be updated whenever new geom CSS classes are introduced
- updateGeoms handlers need scoped selectors per geom sub-type to prevent cross-contamination

### Key Lessons
1. New geom implementation should include interactivity wiring in the same phase — rendering and interaction are not independent concerns
2. Documentation generation (`build_readme()`) should be a task in the phase that changes README.Rmd, not deferred

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Pattern |
|-----------|--------|-------|-------------|
| v1.6 | 3 | 4 | Milestone audit → gap closure phase |
| v1.7 | 4 + 1 distribution | 10 | Research milestone format: IR → renderer → interactivity → blueprint; verifier shell scripts |

### Recurring Issues

- Integration gaps when features span multiple modules (selectors, handlers, renderers)
- Documentation regeneration deferred and forgotten
- Verification artifact discipline lapses on cross-milestone / distribution / user-setup plans (v1.7 Phase 31)
- Cross-phase attribute-name contracts shipped unresolved into downstream phases (v1.7 `data-centroid` vs `data-cx/data-cy`)

### What to Watch

- As geom count grows (25+), INTERACTIVE_SELECTORS maintenance becomes a scaling concern — consider auto-registration pattern
- The v1.7 blueprint includes a planned `data-cx/data-cy → data-centroid` migration in IMPL-04 — track that it actually lands when v1.8 executes, otherwise interactivity wiring will inherit the inconsistency
- Optional-Suggests + `skip_if_not_installed()` pattern (sf, geojsonsf, rnaturalearth) needs a one-time CI matrix entry that does install the spatial stack to exercise the production paths — otherwise sf-related regressions could slip through
