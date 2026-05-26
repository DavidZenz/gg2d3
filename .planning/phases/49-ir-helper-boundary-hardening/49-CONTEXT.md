# Phase 49: IR Helper Boundary Hardening - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-selected recommended defaults from `$gsd-next` continuation

<domain>
## Phase Boundary

Phase 49 hardens selected R-side `as_d3_ir()` boundaries so maintainers can change high-risk IR extraction responsibilities through focused helpers without representative IR drift.

This phase is architecture hardening, not a broad rewrite. It should split or isolate a small number of high-risk responsibilities, add helper-level characterization tests, and prove that representative non-sf, sf, facet, scale, and annotation IR remains unchanged except for intentional documented differences.

Out of scope: renderer wiring cleanup, interaction payload registry changes, visual screenshot infrastructure beyond reusing Phase 48 as confidence support, and geometry behavior fixes. Those belong to Phases 50 and 51.

</domain>

<decisions>
## Implementation Decisions

### Boundary Selection
- **D-01:** Prefer a narrow set of helper boundaries over a sweeping `as_d3_ir()` rewrite. The phase should reduce near-term maintenance risk without destabilizing the pipeline.
- **D-02:** Prioritize responsibilities that are currently large, duplicated, or hard to test inside the monolithic function: layer row/aesthetic extraction, scale/domain/break metadata, facet/panel metadata, and theme/coord metadata.
- **D-03:** Keep existing sf helper boundaries intact. sf extraction already has focused helper contracts; Phase 49 may add characterization around their integration but should not churn them unless required to preserve the selected boundaries.

### Drift Policy
- **D-04:** Representative IR output must be preserved byte-for-byte or structurally equal for covered fixtures unless a difference is intentional, documented in the plan/summary, and verified against the phase success criteria.
- **D-05:** Tests should compare stable IR subsets where full-object equality would be brittle because of environment-specific labels, package-version details, or optional dependencies.
- **D-06:** If an extracted helper exposes a pre-existing inconsistency, prefer documenting the inconsistency and adding a focused guard before fixing behavior, unless the fix is tiny and clearly within the phase boundary.

### Characterization Coverage
- **D-07:** Cover non-sf core IR, sf integration, facets, scales, and annotations. The coverage does not need to exhaust every geom; it needs to represent the high-risk boundaries selected for extraction.
- **D-08:** Helper-level tests should fail near the implicated boundary. A failure should name whether rowization/aesthetic mapping, scale extraction, facet panel construction, theme/coord extraction, or sf integration changed.
- **D-09:** Reuse existing test fixtures where possible: `test-ir.R`, `test-facets.R`, `test-facet-grid.R`, `test-date-scales.R`, `test-sf-ir.R`, `test-sf-annotations-ir.R`, and Phase 48 visual smoke artifacts.

### Refactor Shape
- **D-10:** Keep helpers internal and conservative. Do not introduce a public API or exported extension point in this phase.
- **D-11:** Favor small pure-ish helpers with explicit inputs from `ggplot_build()` state and plain-list outputs that match existing IR structure.
- **D-12:** Avoid new package dependencies for structural comparison unless the codebase already uses them. testthat equality and small local normalizers are acceptable.

### the agent's Discretion
- Exact helper names, file split, fixture selection, and number of plans are left to planning.
- The planner may choose whether helpers stay in `R/as_d3_ir.R` initially or move to a new internal R file, as long as source organization improves maintainability without weakening current tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone scope
- `.planning/ROADMAP.md` — Phase 49 goal, dependency on Phase 48, and success criteria.
- `.planning/REQUIREMENTS.md` — ARCH-01 acceptance scope.
- `.planning/PROJECT.md` — v1.12 architecture hardening goals and known `as_d3_ir()` debt.
- `.planning/RETROSPECTIVE.md` — v1.11 lessons around helper boundaries, optional dependency behavior, and evidence-driven fixes.
- `.planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md` — Phase 48 artifact/visual confidence contract that Phase 49 can reuse as a local smoke safety net.

### R-side IR implementation
- `R/as_d3_ir.R` — Current monolithic IR generator and primary refactor target.
- `R/ggplot2_compat.R` — Existing compatibility wrappers around ggplot2 internals; keep private API handling quarantined here where possible.
- `R/sf_utils.R` — Existing sf extraction helper boundary and integration contract.
- `R/validate_ir.R` — IR schema guard that should continue to pass after helper extraction.

### Representative tests
- `tests/testthat/test-ir.R` — Core non-sf IR behavior.
- `tests/testthat/test-facets.R` and `tests/testthat/test-facet-grid.R` — facet and panel metadata.
- `tests/testthat/test-date-scales.R` — temporal scale/domain/break metadata.
- `tests/testthat/test-theme-inheritance.R` and `tests/testthat/test-layout.R` — theme/layout metadata.
- `tests/testthat/test-sf-ir.R` — sf helper integration, bbox contracts, skipped rows, and validation.
- `tests/testthat/test-sf-annotations-ir.R` — sf text/label annotation IR contracts.
- `tests/testthat/test-browser-visual-smoke.R` — optional browser visual smoke gate for post-refactor confidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Current Structure
- `as_d3_ir()` currently performs many responsibilities in one body: `ggplot_build()`, coordinate detection, rowization, discrete mapping, geom name dispatch, sf payload integration, temporal conversions, scale extraction, theme extraction, coord metadata, guide extraction, facet/panel construction, reverse aesthetic mapping, and final validation.
- There are nested helpers inside `as_d3_ir()` such as `map_discrete()`, `extract_theme_element()`, `to_rows()`, `validate_log_domain()`, `get_scale_transform()`, and `get_scale_info()`.
- Some logic is repeated between global scale extraction and facet panel extraction, especially temporal range/break conversion and per-panel axis handling.
- sf helper boundaries already exist and are actively tested, including stacked/faceted bbox contracts in `test-sf-ir.R`.

### Reusable Assets
- `validate_ir()` gives a final schema check and should remain part of the pipeline.
- Existing IR tests already cover many representative surfaces; Phase 49 can add helper-level characterization tests around selected boundaries instead of inventing entirely new fixture families.
- Phase 48 browser visual smoke can be run locally as an optional rendered-output sanity check after R-side refactors.

### Risks To Preserve
- ggplot2 version differences can affect build output, labels, and theme internals. Characterization should focus on stable, meaningful IR fields.
- Optional `sf` availability varies by environment. sf tests must retain existing skip behavior and not make browser/spatial dependencies mandatory.
- The final IR is consumed by the JS renderer, so even small field-name or type changes can be user-visible.

</code_context>

<specifics>
## Specific Ideas

- Recommended first extraction: scale/domain/break helpers, because scale handling is repeated and Phase 51 depends on transformed rect/tile classification.
- Recommended second extraction: layer row/aesthetic/var-name assembly, because it is central to most geoms and tooltip/interactivity payloads.
- Recommended third extraction: facet/panel metadata helpers, because they are lengthy, contain repeated temporal conversion, and are easy to characterize with existing facet tests.
- Keep theme extraction as a possible small follow-up if planning finds it can be isolated safely without expanding the phase.

</specifics>

<deferred>
## Deferred Ideas

- Full `as_d3_ir()` modularization remains broader than Phase 49. This phase should make a meaningful first slice and leave a clearer path for future cleanup.
- Renderer registry/update-handler cleanup belongs to Phase 50.
- Behavior changes for transformed rect/tile, polygon topology, and text/label placement belong to Phase 51 unless Phase 49 uncovers a tiny, unavoidable correctness fix.
- Public IR extension APIs remain future work; Phase 49 helpers are internal.

</deferred>

---

*Phase: 49-ir-helper-boundary-hardening*
*Context gathered: 2026-05-26*
