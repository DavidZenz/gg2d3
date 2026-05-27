# Phase 50: Renderer Wiring And Interaction Contracts - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** User accepted recommended defaults

<domain>
## Phase Boundary

Phase 50 hardens JavaScript-side renderer wiring and interaction contracts so supported geoms are easier to extend without missing renderer registration, zoom/update plumbing, interaction selectors, or public payload sanitization.

This phase is architecture hardening for the D3/htmlwidgets layer. It should reduce duplicated selector and wiring knowledge, add tests that fail when a supported geom is missing expected wiring, and preserve public interactivity payload hygiene across tooltip, hover/events, brush, handlers, crosstalk, ordinary polygons, sf marks, and sf annotations.

Out of scope: R-side IR helper refactors, new geom support, new public extension APIs, geometry behavior fixes, visual-diff infrastructure, and Phase 51 geometry polish such as transformed rect/tile behavior, polygon topology/hole handling, collision avoidance, or path-following text.

</domain>

<decisions>
## Implementation Decisions

### Renderer Wiring Source Of Truth
- **D-01:** Prefer a small internal declarative geom contract/descriptor over another broad procedural refactor. The descriptor should capture supported geom names, DOM selectors/classes, renderer registration expectations, interaction participation, update expectations, and private-field behavior where useful.
- **D-02:** Keep the descriptor internal to the package's JS implementation and tests. Do not create or document a public plugin/extension API in this phase.
- **D-03:** Planning may choose whether the descriptor is used directly at runtime, only by tests, or both. Runtime reuse is welcome when low risk, but passing contract tests is the minimum requirement.

### Zoom And Update Handler Contract
- **D-04:** `geom-registry.js` update coverage should be guarded by contract tests so every supported geom has an expected update path or an explicit documented reason it does not need one.
- **D-05:** Favor incremental extraction of update metadata or small update-handler maps over a large rewrite of `updateGeoms()`. Existing zoom/update behavior should remain stable.
- **D-06:** If a geom has intentionally special update behavior, capture that in the descriptor/contract rather than relying on scattered comments.

### Interaction Selector Ownership
- **D-07:** Do not blindly force one identical selector list into all modules. `events.js`, `brush.js`, and `crosstalk.js` have related but not always identical responsibilities.
- **D-08:** Prefer one canonical geom/selector descriptor that can derive or validate module-specific selector lists for events, brush, crosstalk, and tooltip-adjacent surfaces.
- **D-09:** Tests should fail when a supported interactive geom is present in renderer registration but missing from the expected module-specific interaction coverage, unless the descriptor marks it as intentionally excluded.

### Public Payload Sanitization Rules
- **D-10:** Centralize or contract-test public datum sanitization so tooltip, event/handler callbacks, and brush callbacks consistently omit underscore-prefixed renderer-private fields.
- **D-11:** Ordinary polygon private fields such as `_polygonPoints` and `_sourceIndex`, plus sf private fields such as `_geom`, `_centroid`, `_sfFamily`, `_sfAnchor`, `_pointCoord`, and `_pointIndex`, must stay out of public callback and tooltip payloads.
- **D-12:** Crosstalk may continue to use private source-row metadata internally for key binding, but that internal use must not leak private fields into user-facing payloads.

### Validation Shape
- **D-13:** Add source-level contract tests for renderer registration, update handler coverage, interaction selector coverage, and sanitizer consistency before relying on browser smoke.
- **D-14:** Reuse Phase 48 browser visual smoke as optional confidence after wiring changes, especially for ordinary polygon, sf, and sf annotation surfaces.
- **D-15:** Keep optional browser/spatial dependency skip behavior unchanged.

### the agent's Discretion
- Exact descriptor file name, schema shape, and whether it lives under `inst/htmlwidgets/modules/` or `tests/testthat/` are left to planning.
- The planner may split the phase into small plans by contract surface: renderer/update wiring, interaction selectors, sanitizer/public payload contracts, and validation/docs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone scope
- `.planning/ROADMAP.md` — Phase 50 goal, dependency on Phase 49, and success criteria.
- `.planning/REQUIREMENTS.md` — ARCH-02 and ARCH-03 acceptance scope.
- `.planning/PROJECT.md` — v1.12 renderer maintainability goals, current support contract, and out-of-scope geometry boundaries.
- `.planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md` — Optional browser visual confidence and artifact/skip policy.
- `.planning/phases/49-ir-helper-boundary-hardening/49-CONTEXT.md` — R-side helper boundary scope and explicit deferral of renderer wiring cleanup to Phase 50.
- `.planning/phases/49-ir-helper-boundary-hardening/49-03-SUMMARY.md` — Confirms Phase 49 completion and readiness for JS-side architecture hardening.

### JavaScript renderer and interaction implementation
- `inst/htmlwidgets/modules/geom-registry.js` — Current renderer registry, `registerGeom()`, `render()`, `list()`, and centralized `updateGeoms()` implementation.
- `inst/htmlwidgets/modules/geoms/` — Existing geom renderer modules and current `registerGeom()` call sites.
- `inst/htmlwidgets/modules/events.js` — Current event/hover/handler selector list and `sanitizeEventDatum()`.
- `inst/htmlwidgets/modules/brush.js` — Current brush selector list, selection logic, centroid handling for sf, and `sanitizeSelectedDatum()`.
- `inst/htmlwidgets/modules/crosstalk.js` — Current crosstalk selector list and private `_sourceIndex` key-binding behavior.
- `inst/htmlwidgets/modules/tooltip.js` — Current tooltip field selection and `sanitizeTooltipDatum()`.
- `inst/htmlwidgets/modules/geoms/polygon.js` — Ordinary polygon private `_polygonPoints` and `_sourceIndex` behavior.
- `inst/htmlwidgets/modules/geoms/sf.js` — sf polygon/point/line and sf text/label DOM classes and private geometry/anchor fields.

### Representative tests
- `tests/testthat/test-regression-core.R` — Existing regression matrix and source-contract checks for sf renderer/interactivity.
- `tests/testthat/test-polygon-interactivity.R` — Ordinary polygon selector, sanitizer, private-field, and crosstalk-key source contracts.
- `tests/testthat/test-polygon-renderer.R` — Ordinary polygon renderer/update source checks.
- `tests/testthat/test-sf-interactivity.R` — sf selector, sanitizer, private-field, and brush contracts.
- `tests/testthat/test-sf-annotations-interactivity.R` — sf text/label selector and sanitizer compatibility contracts.
- `tests/testthat/test-zoom-path-datum.R` — Path/closed-path datum requirements for zoom updates.
- `tests/testthat/test-browser-visual-smoke.R` — Optional post-change visual smoke coverage across Cartesian, polygon, sf, and annotation fixtures.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `window.gg2d3.geomRegistry` already centralizes renderer registration and exposes `register`, `render`, `has`, `list`, and `updateGeoms`.
- Individual geom modules already self-register with `geomRegistry.register(...)`; this can seed descriptor/contract tests.
- Existing source-level tests already read JS modules as text and assert key selectors, sanitizer calls, private-field handling, and update plumbing.
- Phase 48 browser visual smoke can catch gross rendered-output regressions after contract changes.

### Established Patterns
- Interactivity modules currently maintain module-local `INTERACTIVE_SELECTORS` arrays.
- Tooltip, events, and brush each implement local sanitizers that strip underscore-prefixed fields.
- Crosstalk intentionally uses `_sourceIndex` internally for grouped polygon representative keys, but user-facing callbacks should not expose it.
- Optional browser and sf checks must skip explicitly when dependencies are unavailable.

### Integration Points
- A descriptor or contract module could live beside existing JS modules and be consumed by `events.js`, `brush.js`, `crosstalk.js`, or tests.
- A lower-risk first step is adding R/testthat source-contract tests that parse the descriptor and compare it to existing JS modules.
- Runtime consolidation is safest where behavior is already identical: sanitizer helpers and selector derivation from descriptor metadata.

</code_context>

<specifics>
## Specific Ideas

- Recommended descriptor fields: geom name/aliases, renderer module, rendered DOM selectors/classes, interaction participation by module, update coverage type, private fields, and public sanitizer expectation.
- Recommended sanitizer rule: public payloads omit all underscore-prefixed fields by default; internal modules may read private fields before sanitization.
- Recommended validation: source-contract tests first, then optional browser visual smoke for visible confidence.

</specifics>

<deferred>
## Deferred Ideas

- Public JavaScript plugin/extension API for third-party geoms remains future work.
- Geometry behavior fixes for transformed rect/tile, polygon topology/hole handling, and text/label placement remain Phase 51 work.
- CI-hosted visual diffs and committed golden screenshots remain future work after local visual smoke stabilizes.

</deferred>

---

*Phase: 50-renderer-wiring-and-interaction-contracts*
*Context gathered: 2026-05-26*
