# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.14 — Pkgdown Site Verification

**Shipped:** 2026-06-01
**Phases:** 3 | **Plans:** 9

### What Was Built
- The source and generated pkgdown site now describe the same sf/widget support contract, with visible optional spatial dependency classification instead of silent disappearance.
- The generated-site validation gate and publication inspector now check stale content, htmlwidget scaffolding, widget dependencies/assets, sf outcomes, and Crosstalk evidence across local and downloaded site roots.
- The pkgdown GitHub Actions workflow now uploads a validated site artifact before Pages deploy, so release evidence can inspect the exact public-site payload.
- The main articles now include rendered sf and linked Crosstalk examples; final follow-up fixes made Crosstalk linked brushing update both panels and preserved sf source fields for `NAME`/`AREA` tooltips.

### What Worked
- Treating pkgdown as a release surface, not disposable output, made stale docs and missing widget payloads visible as testable failures.
- Artifact inspection was a strong complement to local docs validation because local `sf` remains broken while CI can render the spatial example.
- User browser UAT found two publication-quality issues that static markers missed: linked Crosstalk behavior and sf tooltip source-field fidelity.

### What Was Inefficient
- Local `sf` cannot load because its GDAL dynamic library is missing, so CI artifacts had to carry the rendered sf proof.
- The first closeout evidence was stale after follow-up Crosstalk and tooltip fixes, requiring a final ledger refresh before archive.
- `gsd-sdk query milestone.complete` still misroutes arguments; the direct `gsd-tools.cjs` fallback remains necessary for archive creation.

### Patterns Established
- Pkgdown validation should check both source/generation freshness and actual widget payload/asset presence.
- Publication evidence should include downloaded artifact inspection, not only local generated `docs/`.
- Browser UAT should be used for interactive docs examples whose behavior cannot be proven by payload markers alone.

### Key Lessons
1. A rendered widget in pkgdown is not enough; linked-view examples need behavioral browser checks.
2. Tooltip fields for sf layers must preserve source attributes separately from rendered aesthetics, especially when users request original field names.
3. Optional dependency skips are acceptable locally only when CI artifact inspection proves the fully rendered path.

### Cost Observations
- Model mix: not tracked.
- Sessions: one concentrated GSD run across Phase 56-58 execution, publication artifact inspection, user browser UAT, and closeout from 2026-05-31 to 2026-06-01.
- Notable: Most rework came from publication-surface truthfulness and environment differences, not from the core validation architecture.

---

## Milestone: v1.13 — Regression & Release Polish

**Shipped:** 2026-05-31
**Phases:** 4 | **Plans:** 14

### What Was Built
- CI-ready browser visual smoke coverage now has GitHub Actions wiring, deterministic report metadata, always-uploaded artifacts, and stable row validation for local and CI inspection.
- Renderer and IR contracts now guard geom modules, load order, update/interaction selectors, public payload sanitization, theme extraction, and geom parameter routing.
- Geometry polish closed bounded ordinary `geom_label()` boxes and text placement fields, clarified ordinary polygon topology non-goals, and added transformed rect/tile finite-bound filtering.
- Release-facing documentation, generated help, v1.13 NEWS, release-gate evidence, and final verification now agree on the shipped support contract and future deferrals.

### What Worked
- CI/browser confidence came first, so later renderer and geometry work had inspectable artifacts instead of relying only on source greps.
- Source-contract tests were again the right tool for JavaScript renderer wiring and IR helper boundaries that do not require live browser execution.
- The final release gate was useful because it forced installed-package test behavior, documentation generation, browser skip classification, and `R CMD check` evidence into one auditable record.

### What Was Inefficient
- Local browser execution still depends on Chrome/chromote behavior; the milestone had to rely on accepted local skips plus fallback CI artifact evidence.
- `gsd-sdk query milestone.complete` misrouted milestone arguments, requiring direct `gsd-tools.cjs` fallback for archive creation.
- The open-artifact audit reported a passed UAT file with 0 pending scenarios as requiring a closeout decision, which needed manual interpretation.

### Patterns Established
- Release gates should summarize command outcomes, artifact classes, skip classifications, and NOTE classes without committing raw logs or generated browser/package-check artifacts.
- Renderer support claims should be source-first across README, vignette, diagnostics, roxygen, generated help, NEWS, and verification evidence.
- Future work should remain explicit as FUT requirements when a milestone deliberately stops short of pixel thresholds, full IR modularization, generated renderer docs, repelled labels, or broad topology repair.

### Key Lessons
1. Installed-package checks catch source-tree assumptions that ordinary `devtools::test()` can miss; tests that read `inst/` files need `system.file()` fallbacks.
2. A browser local skip can be acceptable release evidence only when paired with clear skip semantics and a known-good CI artifact.
3. Milestone closeout is still a hybrid: SDK helpers move archives, but ROADMAP collapse, PROJECT evolution, MILESTONES polish, and retrospective writing need deliberate review.

### Cost Observations
- Model mix: not tracked.
- Sessions: one concentrated GSD run across Phase 52-55 execution, release validation, and closeout from 2026-05-28 to 2026-05-31.
- Notable: Most rework came from local browser/tooling and milestone archive quirks rather than feature uncertainty.

---

## Milestone: v1.12 — Quality & Architecture Hardening

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 13

### What Was Built
- Deterministic opt-in browser visual smoke coverage now produces local HTML, screenshot, DOM summary, browser-log, and report artifacts with explicit optional dependency skip behavior.
- High-risk `as_d3_ir()` responsibilities now have focused helper boundaries for scale metadata, layer rowization, and facet/panel metadata while preserving representative IR behavior.
- Renderer registration, update handlers, interactivity selectors, and public payload sanitization now have source-contract coverage across registered geoms, ordinary polygons, and sf text/label annotations.
- Geometry edge cases were classified and polished: transformed rect/tile behavior is documented at the shared scale semantics boundary, ordinary polygon subgroup/topology behavior is tested without overclaiming GIS repair, and ordinary `geom_text(size=...)` now renders through the D3 text renderer.

### What Worked
- Starting with browser visual smoke coverage gave later architecture and geometry work a concrete rendered-artifact safety net.
- Source-contract tests were a good fit for JavaScript wiring and renderer boundary checks that do not need live browser execution.
- Evidence-first classification kept Phase 51 from turning broad topology and label-placement ideas into accidental support claims.

### What Was Inefficient
- The milestone close still needed manual cleanup because `gsd-sdk query milestone.complete` is miswired for this command and the direct CJS fallback only handles the mechanical archive portion.
- The open-artifact audit reported a passed UAT file as an item requiring a decision, which needed interpretation before closeout.
- Requirements and state metadata lagged behind completed Phase 50 until the final Phase 51 closeout pass corrected them.

### Patterns Established
- Browser smoke should stay opt-in locally until artifact stability and optional dependency behavior are boring enough for CI.
- Renderer/interactivity wiring benefits from an internal geom contract table plus source tests that catch omissions early.
- Geometry polish phases should separate "shipped support" from "classified non-goal" in tests, diagnostics, and validation notes.

### Key Lessons
1. Milestone close should treat passed UAT artifacts with zero pending scenarios as resolved, even if the audit tool reports their presence.
2. SDK archive helpers are useful but not sufficient; ROADMAP collapse, PROJECT evolution, and retrospective writing need a deliberate pass.
3. Small renderer improvements, such as ordinary text size, are safest when they follow an already-shipped convention from a neighboring renderer.

### Cost Observations
- Model mix: not tracked.
- Sessions: one concentrated GSD run across Phase 48-51 execution and closeout from 2026-05-25 to 2026-05-27.
- Notable: Most rework came from planning metadata and archive tooling quirks rather than code uncertainty.

---

## Milestone: v1.11 — Geometry Parity

**Shipped:** 2026-05-25
**Phases:** 4 | **Plans:** 11

### What Was Built
- Ordinary `geom_polygon()` support now covers IR recognition, grouped closed-path D3 rendering, facets, styling, zoom/update behavior, sanitized interaction payloads, browser smoke coverage, and grouped/faceted crosstalk key binding.
- Rect/tile edge behavior was classified against ggplot2 built data, with categorical tile and update-path mismatches fixed at the D3 boundary and transformed-scale expansion explicitly deferred.
- `geom_sf_text()` and `geom_sf_label()` now extract label IR, render projected anchors in single-panel/stacked/faceted sf plots, and reuse the existing `.geom-sf` tooltip, hover, brush, handler, and crosstalk contracts.
- README, vignettes, diagnostics docs, roxygen source, generated help, and validation evidence now describe the v1.11 geometry support contract and residual risks.

### What Worked
- Grouping ordinary polygon, rect/tile edge closure, and sf annotations into one geometry-parity milestone kept related renderer/IR/interactivity risks visible together.
- Source-contract tests were fast and effective for renderer/update behavior that did not require live browser execution.
- Optional browser/spatial skips were recorded as explicit validation outcomes, which kept local dependency gaps from being mistaken for missing source evidence.

### What Was Inefficient
- The final milestone close still required manual cleanup around stale state counters, roadmap collapse, and PROJECT wording after SDK helpers did their mechanical work.
- Browser smoke remained dependent on optional local `chromote`, Chrome, and `sf` availability, so some evidence had to be recorded as explicit skips.
- Generated documentation work surfaced dependency-version notes that were useful context but not milestone blockers.

### Patterns Established
- Geometry renderer phases should validate three surfaces together: IR extraction, D3 source/update contracts, and public interaction payload sanitization.
- Rect/tile and other edge-behavior questions should be classified against ggplot2 built data before changing renderer behavior.
- Documentation closure should be source-first, with generated README/help committed only after source wording and caveats are stable.

### Key Lessons
1. Public support docs need adjacent caveats, not distant limitations, when behavior is newly shipped but intentionally scoped.
2. Optional browser/spatial dependency skips are acceptable milestone evidence when source/unit coverage passes and skip messages are explicit.
3. Milestone archive helpers are good for moving files, but final state, roadmap, and project narrative still need a deliberate human-shaped pass.

### Cost Observations
- Model mix: not tracked.
- Sessions: one concentrated GSD run from Phase 44 through Phase 47 completion and archive across 2026-05-24 to 2026-05-25.
- Notable: Most rework was closeout/documentation consistency, not core renderer implementation.

---

## Milestone: v1.10 — Release Hardening

**Shipped:** 2026-05-23
**Phases:** 4 | **Plans:** 10

### What Was Built
- Package metadata, optional dependency classification, generated artifact ignores, and local validation output paths were hardened for release-facing work.
- Release-blocking debt was triaged across dependency/facet advisories, ordinary `geom_polygon()` support signaling, and rect/tile out-of-bounds behavior.
- A two-tier local release validation gate was documented and run with expected optional browser/spatial skips and actionable artifact paths.
- README, vignettes, diagnostics docs, roxygen source, generated help, and release notes now describe the shipped polygon/point/line `geom_sf()` contract and residual risks.

### What Worked
- Phase-level release gates made the final release notes factual rather than speculative.
- Treating optional skips as explicit evidence kept CRAN-friendly behavior from looking like missing coverage.
- Source-first documentation edits kept generated README/help aligned with package code.

### What Was Inefficient
- Some context questions remained open until milestone close, even though later phase artifacts had effectively resolved them.
- Closeout tooling still required manual polish around roadmap collapse and state wording.
- Documentation generation surfaced advisory package-version notes (`bslib`, `cpp11`) that were useful context but not release blockers.

### Patterns Established
- Release evidence should summarize outcomes and point to artifact locations rather than copy local logs into release-facing docs.
- Generated browser, visual, and check artifacts need predictable ignored paths before broad validation is comfortable.
- Expected optional skips are part of the validation contract when their messages are clear and tested.

### Key Lessons
1. Mark context questions resolved when phase decisions are made, not only at milestone close.
2. Docs-only phases still need source/generated parity checks and scans for accidental tooling or renderer changes.
3. Milestone completion helpers are useful for canonical archives, but roadmap and project narrative still need deliberate review.

---

## Milestone: v1.8 — Production geom_sf Polygon MVP

**Shipped:** 2026-05-20
**Phases:** 4 | **Plans:** 11

### What Was Built
- Production `geom_sf()` polygon-family IR extraction with CRS normalization, skipped-row diagnostics, accepted-geometry bbox metadata, and source-row alignment.
- Single-panel D3 `path.geom-sf` renderer with multipolygon hole support, row ids, centroid attributes, and sf-specific interactivity hooks.
- Tooltip, hover, custom handler, Shiny handler, brush, and zoom behavior integrated with the existing interactivity APIs while sanitizing renderer-private fields.
- Shared panel-level projection metadata for stacked sf layers plus facet-aware per-panel bbox/projection behavior for `facet_wrap()` and `facet_grid()`.
- Documentation, diagnostics, generated help, automated tests, and browser fixtures that describe and validate the polygon-first support contract.

### What Worked
- The v1.7 research handoff made v1.8 implementation unusually direct: each production phase could trace back to a concrete blueprint, anti-feature list, and validation gate.
- Keeping unsupported geometries explicit turned a risky edge case into a clear public contract with warnings, diagnostics, and row-alignment tests.
- The final verifier caught a subtle missing-geometry coverage gap before archive, and the fix improved both behavior and tests.

### What Was Inefficient
- Manual browser fixture review was useful, but the project still lacks automated DOM-level smoke coverage for rendered sf paths.
- `phase.complete` and `milestone.complete` needed manual cleanup around stale state fields, duplicate progress counting, and noisy accomplishment extraction.
- `selfcontained = TRUE` in htmlwidgets fixtures initially pulled in Pandoc unnecessarily; switching fixtures to non-self-contained HTML removed that dependency.

### Patterns Established
- Spatial renderer features should validate three boundaries: R helper diagnostics, IR/data alignment, and JS source-contract behavior.
- Faceted sf support needs panel-scoped geometry metadata rather than global or layer-local fitting.
- Milestone audits should distinguish blocking requirement gaps from non-blocking validation hardening debt.

### Key Lessons
1. Missing sf geometries should be tested at the helper boundary because literal `NA` geometry rows can fail inside ggplot2/sf before gg2d3 sees them.
2. For htmlwidgets validation fixtures, non-self-contained output is usually the better smoke-test artifact because it avoids Pandoc and keeps dependencies inspectable.
3. Source-contract tests are valuable for modular JavaScript renderers, but browser DOM smoke tests are the next step for higher confidence.

### Cost Observations
- Model mix: not tracked.
- Sessions: one concentrated GSD run across Phase 32-35 execution and closeout on 2026-05-20.
- Notable: Research/spec artifacts paid off; most rework came from closeout tooling quirks rather than core implementation uncertainty.

---

## Milestone: v1.7 — Choropleth Map Research

**Shipped:** 2026-05-20
**Phases:** 4 | **Plans:** 6

### What Was Built
- R-side `geom_sf` extraction feasibility, including `geojsonsf::sfc_geojson()` serialization, WGS84 normalization, CRS metadata, and sf IR schema.
- D3 `geom_sf` polygon renderer prototype using `geoIdentity().reflectY(true).fitExtent()`, `fill-rule="evenodd"`, row IDs, centroids, and visual test artifacts.
- Interactivity design contract for `path.geom-sf` tooltip, hover, centroid brush, and first-build zoom suppression.
- Final edge-case and implementation blueprint covering mixed geometries, stacked sf layers, faceted sf maps, anti-features, future phases, file targets, and validation gates.

### What Worked
- Research-first sequencing kept production implementation choices from leaking into a research milestone.
- Human visual checkpoints were valuable for multipolygon holes and choropleth fidelity where CLI checks cannot prove the rendered shape.
- The Phase 30 blueprint successfully consolidated Phase 27-29 findings into a build-ready handoff.

### What Was Inefficient
- Older validation metadata in Phase 28 remained marked non-Nyquist even after the phase was verified and human-approved.
- Some GSD SDK wrappers misparsed named flags, requiring direct CLI/manual corrections for state and milestone operations.
- One Phase 28 summary used a literal `One-liner:` label that needed cleanup during milestone archiving.

### Patterns Established
- For spatial features, split feasibility, renderer proof, interactivity design, and implementation blueprint into separate phases before production build work.
- Anti-features should include revisit conditions, not just “out of scope” labels.
- Future build blueprints should name exact files, validation gates, and unresolved edge cases before implementation begins.

### Key Lessons
1. `geom_sf` support should remain polygon-first until shared projection, facets, and unsupported geometry behavior are stable.
2. Browser reprojection, slippy maps, tile basemaps, polygon-overlap brushing, and large-map guarantees are different product categories from ggplot parity and need explicit deferral.
3. Milestone closeout should check stale top-level roadmap/status lines before archiving; summaries can be complete while overview prose lags behind.

### Cost Observations
- Model mix: not tracked.
- Sessions: multiple short GSD sessions across April and May.
- Notable: Docs-only design phases were quick once prior research artifacts were clean and specific.

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
| v1.12 | 4 | 13 | Visual smoke → helper boundaries → renderer contracts → geometry classification |
| v1.11 | 4 | 11 | Geometry parity bundle → source contracts → docs/validation handoff |
| v1.10 | 4 | 10 | Release hardening → evidence-driven docs → archive hygiene |
| v1.8 | 4 | 11 | Research handoff → production implementation → docs/validation hardening |
| v1.7 | 4 | 6 | Research → prototype → design contract → implementation blueprint |
| v1.6 | 3 | 4 | Milestone audit → gap closure phase |

### Recurring Issues

- Integration gaps when features span multiple modules (selectors, handlers, renderers)
- Documentation regeneration deferred and forgotten
- Validation metadata can become stale even when phase verification passes
- Milestone closeout tooling can leave stale state or noisy summaries that need human review before archive commits
- Optional browser/spatial dependencies need explicit skip semantics to avoid ambiguity in milestone evidence
- SDK query wrappers may lag direct CJS commands; inspect the underlying workflow/tool before assuming an archive failure means the task is blocked

### What to Watch

- As geom count grows (25+), INTERACTIVE_SELECTORS maintenance becomes a scaling concern — consider auto-registration pattern
- Spatial support should not expand into GIS-engine behavior without explicit product intent and validation budget
- Browser visual smoke artifacts are now available locally; the next risk frontier is whether they are stable enough for CI-hosted screenshot or DOM regression checks
- Generated documentation changes should be paired with stale-claim scans before milestone close
