# Phase 53: Renderer And IR Contract Consolidation - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 53 consolidates renderer wiring and selected IR responsibilities so gg2d3 has clearer source-of-truth contracts and actionable drift tests. The work should govern existing supported geom behavior, interaction/public-payload expectations, and high-risk `as_d3_ir()` helper boundaries without adding new geometry capabilities or changing representative IR output.

This phase follows Phase 52's CI/browser visual smoke foundation. Browser smoke artifacts are useful downstream confidence checks, but Phase 53 is primarily an architecture and regression-contract phase.

</domain>

<decisions>
## Implementation Decisions

### Geom Contract Source Of Truth
- **D-01:** Treat `inst/htmlwidgets/modules/geom-contracts.js` as the internal renderer contract manifest for Phase 53.
- **D-02:** Strengthen validation around the existing manifest instead of introducing generated/shared contracts or public extension semantics in this phase.
- **D-03:** Keep generated renderer documentation deferred to `FUT-04` unless planning finds a tiny source-first note is needed to satisfy the diagnostics requirement.

### Contract Strictness
- **D-04:** Contract drift tests should be strict for every supported/registered geom alias.
- **D-05:** Required contract coverage includes module path/loading expectations, render selectors, update handling, interaction selectors, private renderer fields, and public payload sanitization expectations.
- **D-06:** Intentional gaps are allowed only when explicitly documented in the contract with a clear reason, such as `update.type = "explicit-none"` or a selector-surface rationale for unsupported crosstalk behavior.
- **D-07:** Test failures should name the missing geom alias, selector, module, or sanitizer surface clearly enough that maintainers know which contract entry or renderer module drifted.

### `as_d3_ir()` Helper Boundary
- **D-08:** Extract only high-risk responsibilities from `as_d3_ir()` now; do not attempt a full modularization or rewrite.
- **D-09:** Priority helper seams are theme extraction, layer preprocessing/dispatch, discrete and temporal mapping, geom parameter routing, and scale/axis metadata.
- **D-10:** Representative IR output for non-sf, sf, facet, scale, and annotation fixtures must remain unchanged except for intentional no-op structural cleanup that tests prove is equivalent.
- **D-11:** Full `as_d3_ir()` modularization remains deferred to `FUT-03`.

### Regression Fixture Strategy
- **D-12:** Use curated representative IR fixtures/checks as the primary unchanged-output contract for this phase.
- **D-13:** Fixture coverage should include non-sf layers, sf layers, facets, scale/date/time transforms, and annotations.
- **D-14:** Avoid broad brittle snapshots and committed pixel goldens in Phase 53.
- **D-15:** Continue using browser visual smoke as downstream validation, not the primary contract gate.

### The Agent's Discretion
- Planning and implementation may choose exact helper names, test organization, and source-level parser details as long as the decisions above and existing project style are preserved.
- Small diagnostic documentation placement is flexible, but the likely target is `vignettes/d3-drawing-diagnostics.md` because it already carries architecture and residual-risk notes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Scope
- `.planning/ROADMAP.md` - Phase 53 goal, dependency, and success criteria.
- `.planning/REQUIREMENTS.md` - `ARCH-01`, `ARCH-02`, `ARCH-03`, and future deferrals `FUT-03`/`FUT-04`.
- `.planning/PROJECT.md` - v1.13 milestone context and carry-forward validation posture from Phase 52.

### Renderer Contracts And Wiring
- `inst/htmlwidgets/modules/geom-contracts.js` - Existing internal geom contract manifest; Phase 53 should strengthen this source rather than replace it.
- `inst/htmlwidgets/modules/geom-registry.js` - Runtime geom registration, render dispatch, and `updateGeoms()` selector handling.
- `inst/htmlwidgets/gg2d3.yaml` - htmlwidgets dependency loading order for contract, sanitizer, registry, interaction, and geom modules.
- `inst/htmlwidgets/modules/public-data.js` - Public payload sanitization surface.
- `inst/htmlwidgets/modules/events.js` - Event selector and sanitizer integration surface.
- `inst/htmlwidgets/modules/brush.js` - Brush selector and sanitizer integration surface.
- `inst/htmlwidgets/modules/crosstalk.js` - Linked-selection selector surface with known intentional gaps.
- `inst/htmlwidgets/modules/tooltip.js` - Tooltip payload sanitization surface.

### IR Boundary And Regression Tests
- `R/as_d3_ir.R` - Main ggplot2-to-IR function and current helper seams.
- `tests/testthat/test-ir-helper-boundaries.R` - Existing focused helper-boundary tests for scales, layers, facets, sf, and annotations.
- `tests/testthat/test-renderer-wiring-contracts.R` - Existing source-level renderer contract tests to extend/harden.
- `tests/testthat/test-browser-visual-smoke.R` - Downstream browser smoke validation added in Phase 52.
- `tests/testthat/helper-browser-visual.R` - Browser smoke artifact and CI behavior helpers.
- `vignettes/d3-drawing-diagnostics.md` - Existing diagnostics/architecture notes location for remaining boundary and migration-path documentation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inst/htmlwidgets/modules/geom-contracts.js`: Already lists geom aliases, module paths, render selectors, update metadata, interaction selectors, private fields, and `publicPayload` expectations.
- `tests/testthat/test-renderer-wiring-contracts.R`: Already parses contract entries, registered aliases, update selectors, interaction selectors, private fields, and sanitizer delegation. Phase 53 can make these tests more complete and more actionable.
- `tests/testthat/test-ir-helper-boundaries.R`: Already provides a natural home for focused `as_d3_ir()` helper boundary assertions.
- `tests/testthat/test-browser-visual-smoke.R`: Provides downstream browser-level confidence after architecture changes.

### Established Patterns
- Renderer modules register aliases through `window.gg2d3.geomRegistry.register(...)`.
- Interaction modules should consume contract selectors via `selectorsFor(...)` where possible, while explicit unsupported surfaces carry reasons in the contract.
- Public interaction payloads should route through `window.gg2d3.publicData.sanitizeDatum(...)` so underscore-prefixed renderer fields do not leak.
- `as_d3_ir()` is already partially helperized; Phase 53 should continue extracting focused helper seams instead of destabilizing the full pipeline.

### Integration Points
- Contract hardening connects `geom-contracts.js`, `geom-registry.js`, `gg2d3.yaml`, interaction modules, and renderer modules under `inst/htmlwidgets/modules/geoms/`.
- IR helper extraction connects `R/as_d3_ir.R` to focused tests in `tests/testthat/test-ir-helper-boundaries.R`.
- Documentation updates should connect the architecture boundary to `vignettes/d3-drawing-diagnostics.md`.

</code_context>

<specifics>
## Specific Ideas

- The user approved the conservative recommendation for all four gray areas: keep the existing manifest, make contract tests strict with explicit exceptions, extract high-risk `as_d3_ir()` responsibilities only, and rely on curated IR checks plus browser smoke.
- No request was made to add new geom behavior in Phase 53.

</specifics>

<deferred>
## Deferred Ideas

- Generated renderer documentation from contracts remains `FUT-04`.
- Full `as_d3_ir()` modularization remains `FUT-03`.
- Committed pixel goldens and thresholds remain deferred until visual artifacts are stable enough across environments.

</deferred>

---

*Phase: 53-renderer-and-ir-contract-consolidation*
*Context gathered: 2026-05-28*
