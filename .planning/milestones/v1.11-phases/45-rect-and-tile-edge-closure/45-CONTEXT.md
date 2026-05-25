# Phase 45: Rect And Tile Edge Closure - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 45 closes the deferred `geom_rect()` / `geom_tile()` out-of-bounds behavior from the v1.10 diagnostics work. Maintainers should get a focused reproduction matrix, classify the observed behavior against ggplot2, and either fix confirmed renderer/IR mismatches or explicitly close the issue as a verified non-issue with regression tests and rationale. This phase does not broaden into tile-map engines, transformed-scale research, screenshot-diff infrastructure, or general geometry rewrites.

</domain>

<decisions>
## Implementation Decisions

### Fixture Matrix
- **D-01:** Cover continuous scale limits, `coord_cartesian()` limits, discrete `geom_tile()` grids, reversed scales, `coord_flip()`, and facets.
- **D-02:** Treat scale limits and coordinate limits as distinct behaviors to classify, because ggplot2 drops/clips data differently across those paths.
- **D-03:** Skip transformed scales by default unless research/planning finds an existing high-risk fixture or source-level evidence that they are part of the deferred mismatch.

### Fix vs Non-Issue Threshold
- **D-04:** Fix only behavior that is visibly or DOM-measurably mismatched against ggplot2's expected rect/tile behavior.
- **D-05:** If a suspected issue is compatible with ggplot2 behavior, or is intentionally handled by SVG panel clipping, close it as a non-issue with tests and documented rationale.
- **D-06:** Keep fixes at the renderer or IR boundary implied by the evidence; avoid broad scale or coordinate refactors unless the matrix proves they are necessary.

### Validation Shape
- **D-07:** Use focused IR tests, JavaScript/source contract tests, and optional browser DOM smoke coverage for representative rect/tile cases.
- **D-08:** Do not introduce screenshot or perceptual-diff validation for this phase.
- **D-09:** Browser smoke, if used, should remain CRAN-compatible and optional in the same spirit as prior chromote/browser coverage.

### Closure Documentation
- **D-10:** Update `vignettes/d3-drawing-diagnostics.md` and Phase 45 verification notes so the v1.10 deferred item is closed cleanly.
- **D-11:** Leave broader README/vignette/public documentation updates to Phase 47 unless Phase 45 changes the user-facing support contract.

### Agent Discretion
- Exact fixture names, helper split, and test-file placement are left to research/planning.
- Planner may decide whether browser DOM smoke is part of plan 45-01, plan 45-02, or a later verification step.
- Planner may choose the precise documentation wording as long as it records whether the issue was fixed or verified as non-reproducible/non-issue.

</decisions>

<specifics>
## Specific Ideas

- The primary deliverable is classification plus closure evidence, not a renderer rewrite.
- The matrix should make it easy to tell apart data dropped by scale limits, visual clipping by coordinate limits, panel clipping, and actual SVG geometry defects.
- Rect/tile edge behavior should be assessed for both initial render and update paths when the same issue could appear in `geom-registry.js`.
- A valid outcome is "no fix needed" only when tests lock the observed behavior and notes explain why it matches ggplot2 or intended clipping.

</specifics>

<canonical_refs>
## Canonical References

### Milestone and phase scope
- `.planning/ROADMAP.md` - Phase 45 scope, success criteria, dependency context, and two expected plan files.
- `.planning/REQUIREMENTS.md` - RECT-01 and RECT-02 define the reproduction/fix-or-close contract.
- `.planning/PROJECT.md` - v1.11 current state and active geometry-parity requirements.
- `.planning/STATE.md` - current focus and resume context for Phase 45.

### Existing deferred note and codebase concerns
- `vignettes/d3-drawing-diagnostics.md` - current deferred rect/tile edge-case note that Phase 45 must resolve or revise.
- `.planning/codebase/CONCERNS.md` - known rect/tile categorical and scale/domain fragility concerns.
- `.planning/codebase/TESTING.md` - existing testthat and browser-smoke testing patterns.

### Implementation surfaces
- `R/as_d3_ir.R` - rect/tile IR mapping and preserved boundary fields such as `xmin`, `xmax`, `ymin`, and `ymax`.
- `inst/htmlwidgets/modules/geoms/rect.js` - primary rect/tile renderer.
- `inst/htmlwidgets/modules/geom-registry.js` - update path for `rect.geom-rect` nodes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/as_d3_ir.R` maps `GeomRect` and `GeomTile` to the `"rect"` geom and keeps rectangle boundary columns in the general layer data path.
- `inst/htmlwidgets/modules/geoms/rect.js` already distinguishes band scales from continuous scales and renders rect/tile marks as `rect.geom-rect`.
- `inst/htmlwidgets/modules/geom-registry.js` updates existing `rect.geom-rect` nodes and should be checked if fixes affect dynamic updates.
- `inst/htmlwidgets/modules/brush.js` already treats `rect.geom-rect` as selectable by SVG bounding-box overlap.
- Prior phase validation patterns support IR assertions, JavaScript/source assertions, and optional browser DOM smoke without screenshot diffs.

### Established Patterns
- Tests should live under `tests/testthat/` and favor small fixtures that explain the renderer contract.
- Browser-oriented checks should skip cleanly when required optional dependencies or browser capabilities are unavailable.
- Generated exploratory HTML belongs under ignored output locations such as `test_output/`, not committed source.
- Documentation changes should be narrow and tied to the evidence gathered during the phase.

### Integration Points
- R layer: inspect built data and IR boundaries for rect/tile rows under scale and coordinate limits.
- JS renderer: verify `x`, `y`, `width`, and `height` calculations for rect/tile marks at and beyond panel/domain edges.
- Update path: keep initial render and dynamic update behavior aligned for `rect.geom-rect`.
- Diagnostics: revise the deferred note in `vignettes/d3-drawing-diagnostics.md` once classification/fix work is complete.

</code_context>

<deferred>
## Deferred Ideas

- Transformed-scale fixture expansion, unless Phase 45 research finds existing evidence that it belongs in the core matrix.
- Broad public docs, README, roxygen, and vignette updates, covered by Phase 47 unless Phase 45 changes the user-facing support contract.
- Tile basemaps, slippy-map semantics, GIS topology, and non-ggplot map-engine behavior.
- Screenshot or perceptual visual regression infrastructure.

</deferred>

---

*Phase: 45-rect-and-tile-edge-closure*
*Context gathered: 2026-05-24*
