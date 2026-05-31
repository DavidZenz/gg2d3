# Phase 54: Geometry Polish Closure - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 54 closes the remaining v1.13 geometry-polish candidates by either shipping bounded renderer/IR improvements or documenting source-backed non-goals with implementation-ready evidence. The phase covers ordinary `geom_label()` boxes, ordinary `geom_polygon()` subgroup/hole behavior, transformed rect/tile scale semantics, and text-placement triage.

This phase should not expand gg2d3 into a general GIS topology repair library, a ggrepel clone, or a pixel-golden visual regression project. Focused source, IR, renderer, DOM, and diagnostics evidence should distinguish shipped support from explicit future work.

</domain>

<decisions>
## Implementation Decisions

### `geom_label()` Box Behavior
- **D-01:** Attempt bounded ordinary `geom_label()` SVG label boxes in Phase 54 rather than diagnostics-only closure.
- **D-02:** The bounded target is rect + text rendering for ordinary `geom_label()` with useful support for fill, colour/stroke, alpha, text size, and basic padding.
- **D-03:** Keep the scope ordinary and renderer-local; do not pursue rich text, collision avoidance, path-following, or full ggrepel behavior under the label-box work.
- **D-04:** If implementation reveals that a polished label box path is not small and safe, planning may pivot to source-backed diagnostics, but it should first characterize the fixture boundary clearly.

### Polygon Subgroup And Hole Boundary
- **D-05:** Build focused fixtures for `geom_polygon(subgroup = ...)` / hole-style input and use them to decide whether a tiny ggplot-compatible subset is obvious.
- **D-06:** Default posture is explicit non-goal documentation for subgroup/hole topology unless research finds a very small, low-risk implementation path.
- **D-07:** Do not add broad GIS topology repair, ring containment inference, invalid-polygon repair, or arbitrary hole winding logic.
- **D-08:** If subgroup metadata is preserved, it should serve a concrete bounded rendering/test purpose; do not preserve extra IR metadata just as speculative future cargo.

### Transformed Rect/Tile Closure
- **D-09:** Treat the current direct transformed-bound scaling path as the likely release boundary.
- **D-10:** Strengthen fixtures and evidence around log/sqrt/reverse rect and tile behavior, including render/update consistency and shared scale/renderer seams.
- **D-11:** Fix only confirmed shared scale/render drift. Avoid a broad scale/rect refactor unless tests expose a real mismatch.
- **D-12:** If no drift is found, Phase 54 should produce narrower implementation-ready evidence and diagnostics explaining the boundary rather than reopening the full transformed-scale parity problem.

### Text Placement Triage
- **D-13:** Attempt small parity wins for ordinary text/label `hjust`, `vjust`, and `angle` where they can be implemented without destabilizing existing text rendering.
- **D-14:** Consider font family only if it falls naturally out of the same text renderer parameter path; it is secondary to justification and rotation.
- **D-15:** Explicitly defer collision avoidance, ggrepel-compatible placement, path-following text, and rich text.
- **D-16:** Documentation should separate shipped small text-placement support from deferred algorithmic placement features so users do not infer unsupported parity.

### The Agent's Discretion
- Planning may choose the exact split between characterization, implementation, browser smoke, and documentation plans as long as each GEOM requirement is traceable.
- Planner/researcher may decide whether label-box and text-placement work share one renderer plan or split into separate plans based on file blast radius.
- Browser visual smoke may be used as downstream confidence, but source/IR/DOM checks should remain the primary gates.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Scope
- `.planning/ROADMAP.md` - Phase 54 goal, dependency, success criteria, and GEOM requirement mapping.
- `.planning/REQUIREMENTS.md` - `GEOM-01`, `GEOM-02`, `GEOM-03`, `GEOM-04`, plus future deferrals `FUT-05` and `FUT-06`.
- `.planning/PROJECT.md` - Current milestone context, validated geometry history, and known tech debt.
- `.planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md` - Carry-forward architecture/test posture: source-level contracts, browser smoke as downstream confidence, no pixel goldens.

### Existing Geometry Diagnostics
- `vignettes/d3-drawing-diagnostics.md` - Current public diagnostics for `geom_label()`, polygon topology/hole boundaries, transformed rect/tile parity, and text-placement anti-features.
- `README.md` - User-facing support/limitation summary that Phase 54 may need to keep aligned.
- `README.Rmd` - Source for README support/limitation text if README updates are needed.

### Text And Label Rendering
- `R/ir_layer_helpers.R` - Geom name mapping currently maps `GeomLabel` to `"text"`.
- `inst/htmlwidgets/modules/geoms/text.js` - Ordinary text renderer; current home for text size, anchor, baseline, fill, opacity, and potential bounded label/text placement work.
- `tests/testthat/test-text-label-polish.R` - Existing characterization tests for ordinary text/label support and explicit non-goals.
- `inst/htmlwidgets/modules/geom-contracts.js` - Renderer contract entries that must stay aligned if label/text renderer selectors or aliases change.
- `tests/testthat/test-renderer-wiring-contracts.R` - Source-level contract checks for renderer selector/load-order drift.

### Polygon Boundary
- `R/as_d3_ir.R` - IR extraction path and kept layer columns; relevant for subgroup preservation/classification.
- `R/ir_layer_helpers.R` - Layer aesthetic field preservation and geom dispatch.
- `inst/htmlwidgets/modules/geoms/polygon.js` - Ordinary grouped closed-path polygon renderer.
- `tests/testthat/test-polygon-ir.R` - Existing ordinary polygon IR and subgroup/hole classification coverage.
- `tests/testthat/test-polygon-renderer.R` - Source contract tests for ordinary polygon renderer behavior.
- `tests/testthat/test-polygon-browser.R` - Optional DOM/browser smoke for ordinary polygon marks.
- `.planning/milestones/v1.11-phases/44-ordinary-geom-polygon-support/44-CONTEXT.md` - Original ordinary polygon boundary decisions.
- `.planning/milestones/v1.11-phases/44-ordinary-geom-polygon-support/44-RESEARCH.md` - Prior subgroup/hole research and explicit Phase 44 deferral rationale.
- `.planning/milestones/v1.11-phases/44-ordinary-geom-polygon-support/44-PATTERNS.md` - Established polygon renderer/test patterns.

### Rect/Tile Transformed Scale Boundary
- `inst/htmlwidgets/modules/geoms/rect.js` - Rect/tile renderer geometry and style path.
- `inst/htmlwidgets/modules/geom-registry.js` - Rect/tile update geometry path.
- `inst/htmlwidgets/modules/scales.js` - Shared D3 scale factory for log/sqrt/reverse transforms.
- `tests/testthat/test-rect-tile-ir.R` - Existing rect/tile IR classification and transformed-bound fixtures.
- `tests/testthat/test-rect-tile-renderer.R` - Existing rect/tile source contract tests.
- `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md` - Prior rect/tile classification evidence.
- `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-SUMMARY.md` - Prior rect/tile closure summary and residual transformed-scale boundary.

### Browser/Visual Evidence
- `tests/testthat/test-browser-visual-smoke.R` - Current artifact-producing browser visual smoke matrix.
- `tests/testthat/helper-browser-visual.R` - Browser visual smoke helpers, report metadata, and skip/fail behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inst/htmlwidgets/modules/geoms/text.js`: Renders ordinary text with centered `dominant-baseline`, `text-anchor`, mapped size, fill, and opacity. It is the likely renderer seam for bounded label/text placement work.
- `tests/testthat/test-text-label-polish.R`: Already characterizes ordinary `geom_label()` as text-only and asserts no collision/path-following implementation. This can become the failing-first target for label boxes and placement triage.
- `inst/htmlwidgets/modules/geoms/polygon.js`: Renders one closed SVG path per group and keeps private `_polygonPoints` for update/interactivity. It intentionally does not implement topology semantics today.
- `tests/testthat/test-polygon-ir.R`: Already includes subgroup/hole classification tests showing ggplot2 built data has `subgroup` while gg2d3 IR currently drops it.
- `tests/testthat/test-rect-tile-ir.R` and `tests/testthat/test-rect-tile-renderer.R`: Already cover log/sqrt/reverse transformed bounds, direct scale use, render/update consistency, and prior browser-smoke non-requirement for rect/tile closure.
- `tests/testthat/test-browser-visual-smoke.R`: Can provide downstream visual evidence if Phase 54 adds/updates fixtures, but it should not become the sole contract gate.

### Established Patterns
- Geometry work is source-first: characterize ggplot2 built data and IR/renderer behavior before changing implementation.
- Ordinary polygon support preserves built row order and grouped closed paths; topology inference is explicitly avoided unless a bounded ggplot-compatible subset is proven.
- Renderer updates should remain aligned with `geom-contracts.js` and the source-level contract tests from Phase 53.
- Diagnostics are kept in `vignettes/d3-drawing-diagnostics.md`, while user-facing support claims are mirrored through README sources when needed.

### Integration Points
- Label/text changes likely touch `R/ir_layer_helpers.R`, `inst/htmlwidgets/modules/geoms/text.js`, `inst/htmlwidgets/modules/geom-contracts.js`, `tests/testthat/test-text-label-polish.R`, and possibly browser visual smoke fixtures.
- Polygon subgroup/hole work connects `R/ir_layer_helpers.R` / `R/as_d3_ir.R`, `inst/htmlwidgets/modules/geoms/polygon.js`, polygon IR/source/browser tests, and diagnostics.
- Rect/tile transformed-scale closure connects `inst/htmlwidgets/modules/geoms/rect.js`, `inst/htmlwidgets/modules/geom-registry.js`, `inst/htmlwidgets/modules/scales.js`, rect/tile IR/source tests, and diagnostics.
- Final documentation should update diagnostics first, then README/Rmd only if shipped support or public limitation text changes.

</code_context>

<specifics>
## Specific Ideas

- The user accepted the recommended path for all four gray areas.
- Label boxes should be attempted in bounded form, not deferred immediately.
- Polygon subgroup/hole work should be fixture-led, with non-goal documentation as the default unless a tiny safe path is found.
- Transformed rect/tile work should strengthen evidence around the current boundary and fix only confirmed drift.
- Text placement should pursue small `hjust`/`vjust`/`angle` wins while explicitly deferring collision avoidance and path-following.

</specifics>

<deferred>
## Deferred Ideas

- Full ggrepel-compatible collision avoidance remains future work (`FUT-05`).
- Path-following text, rich text, and broad label-placement algorithms remain out of Phase 54.
- Broad GIS-style polygon topology repair remains future work (`FUT-06`).
- Pixel thresholds and committed golden screenshots remain deferred until visual artifacts prove stable across environments.

</deferred>

---

*Phase: 54-geometry-polish-closure*
*Context gathered: 2026-05-28*
