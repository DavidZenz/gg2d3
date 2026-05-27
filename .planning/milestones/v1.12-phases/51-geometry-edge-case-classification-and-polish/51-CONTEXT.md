# Phase 51: Geometry Edge-Case Classification And Polish - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** User accepted recommended defaults

<domain>
## Phase Boundary

Phase 51 delivers evidence-driven geometry polish for the known deferred edges around transformed-scale rect/tile behavior, ordinary polygon topology and hole/subgroup behavior, and text/label placement candidates.

This phase should first classify behavior against ggplot2 and existing gg2d3 contracts, then make only small, verified improvements where the implicated boundary is clear and low-risk. It should record supported and unsupported outcomes with enough evidence for future milestone planning.

Out of scope: a full GIS topology repair engine, automatic invalid polygon fixing, a full ggrepel clone, path-following text as a broad feature, CI-hosted screenshot diffs, tile basemaps/slippy controls, JavaScript CRS reprojection, and broad renderer or IR architecture refactors already handled by Phases 49 and 50.

</domain>

<decisions>
## Implementation Decisions

### Rect/Tile Transform Classification
- **D-01:** Build focused fixtures for `geom_rect()` and `geom_tile()` on transformed scales, especially log, sqrt, and reverse where applicable.
- **D-02:** Compare ggplot2 built data, gg2d3 IR, and D3-rendered behavior before changing implementation.
- **D-03:** Fix only small renderer-boundary mismatches, such as finite transformed bounds, categorical/tile placement drift, or zoom/update parity issues.
- **D-04:** If parity would require broad coordinate-system semantics or deeper ggplot2 transformation emulation, document it as an explicit non-goal with evidence rather than expanding scope.

### Polygon Topology Contract
- **D-05:** Treat ordinary `geom_polygon()` as grouped closed SVG paths that preserve ggplot2 built row order.
- **D-06:** Characterize holes, subgroups, ring order, and related edge cases against ggplot2 output before deciding whether any code change is warranted.
- **D-07:** Support only cases that can be represented honestly by grouped SVG paths without topology repair.
- **D-08:** Explicitly document unsupported full GIS-style topology repair, automatic hole inference, and invalid polygon fixing.

### Text/Label Polish Scope
- **D-09:** Attempt at most one small verified text/label improvement if it is source-local and low-risk.
- **D-10:** Good candidate improvements include basic `geom_label()` parity or better `hjust`/`vjust`/`angle` handling for ordinary `geom_text()`.
- **D-11:** Treat collision avoidance and path-following labels as classify-and-defer unless research finds a tiny, robust implementation path.
- **D-12:** Do not implement a full ggrepel clone in this phase.

### Validation Evidence
- **D-13:** Require source or IR tests for every classified behavior.
- **D-14:** Add renderer source checks when the behavior is JavaScript-boundary-specific.
- **D-15:** Use optional browser visual smoke or generated inspectable HTML for representative visual cases across rect/tile, polygon, and text/label surfaces.
- **D-16:** Record pass/skip evidence in `51-VALIDATION.md`, preserving existing optional `{sf}` and browser dependency skip policy.

### the agent's Discretion
- Exact fixture names, test-file split, generated artifact filenames, and whether a tiny improvement is worth implementing are left to research/planning.
- The planner may decide that classification-only is the right outcome for a sub-area if the evidence shows a fix would exceed the phase boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone scope
- `.planning/ROADMAP.md` - Phase 51 goal, dependency on Phase 50, and success criteria.
- `.planning/REQUIREMENTS.md` - GEOM-01, GEOM-02, and GEOM-03 acceptance scope plus out-of-scope geometry boundaries.
- `.planning/PROJECT.md` - Current v1.12 milestone goal, known geometry tech debt, and decisions around ggplot parity.
- `.planning/RETROSPECTIVE.md` - v1.11 evidence around rect/tile classification, ordinary polygons, sf annotations, and lessons about explicit anti-features.
- `.planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md` - Optional browser visual artifact and skip policy to reuse for visual evidence.
- `.planning/phases/49-ir-helper-boundary-hardening/49-CONTEXT.md` - R-side helper boundary and drift policy relevant to transformed-scale investigation.
- `.planning/phases/50-renderer-wiring-and-interaction-contracts/50-CONTEXT.md` - Renderer wiring and public payload contracts that Phase 51 should preserve.
- `.planning/phases/50-renderer-wiring-and-interaction-contracts/50-03-SUMMARY.md` - Confirms shared public sanitizer and final Phase 50 validation readiness.

### Rect/tile implementation and tests
- `inst/htmlwidgets/modules/geoms/rect.js` - Current `geom_rect()` / `geom_tile()` renderer, continuous/band scale handling, coord flip branches, and bounds-to-pixels behavior.
- `inst/htmlwidgets/modules/geom-registry.js` - Zoom/update path for rect/tile marks.
- `R/as_d3_ir.R` - IR extraction for layer data, transforms, and scale metadata.
- `R/ir_helpers_layers.R` - Layer rowization and aesthetic map helpers extracted in Phase 49.
- `R/ir_helpers_scales.R` - Scale/domain/break helper boundary used by transformed-scale classification.
- `tests/testthat/test-rect-tile-ir.R` - Existing rect/tile IR fixtures and edge-behavior tests.
- `tests/testthat/test-rect-tile-renderer.R` - Existing rect/tile renderer/update source contracts.
- `tests/testthat/test-ir.R` and `tests/testthat/test-validate-ir.R` - Existing transform extraction and log-domain validation tests.

### Polygon implementation and tests
- `inst/htmlwidgets/modules/geoms/polygon.js` - Ordinary polygon grouped closed-path renderer and private `_polygonPoints` / `_sourceIndex` behavior.
- `tests/testthat/test-polygon-ir.R` - Ordinary polygon IR recognition, row-order, facets, and styling fixtures.
- `tests/testthat/test-polygon-renderer.R` - Ordinary polygon renderer/update source contracts.
- `tests/testthat/test-polygon-interactivity.R` - Ordinary polygon interaction, sanitizer, and crosstalk source contracts.
- `tests/testthat/test-polygon-browser.R` - Optional browser smoke coverage for ordinary polygons.
- `tests/testthat/test-zoom-path-datum.R` - Closed-path private point datum requirements for zoom updates.

### Text, label, and sf annotation implementation
- `inst/htmlwidgets/modules/geoms/text.js` - Current ordinary `geom_text()` renderer and likely target for any small text-positioning polish.
- `inst/htmlwidgets/modules/geoms/sf.js` - Current `geom_sf_text()` and `geom_sf_label()` projected-anchor rendering behavior.
- `tests/testthat/test-sf-annotations-ir.R` - sf text/label annotation IR fixtures and skipped-row coverage.
- `tests/testthat/test-sf-annotations-interactivity.R` - sf annotation selector and sanitizer contracts.
- `tests/testthat/test-sf-annotations-browser.R` - Optional browser smoke coverage for sf annotations.
- `tests/testthat/test-regression-core.R` - Representative regression matrix that should stay green after geometry polish.

### Browser and visual evidence
- `tests/testthat/test-browser-visual-smoke.R` - Optional visual smoke matrix across Cartesian, facets, interactivity, ordinary polygon, sf, and annotations.
- `tests/testthat/helper-browser-visual.R` - Shared visual smoke artifact/report helper.
- `tests/testthat/helper-browser-polygon.R` - Optional ordinary polygon browser helper and failure artifact pattern.
- `tests/testthat/helper-sf-fixtures.R` - Reusable sf fixture builders and `test_output/` conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inst/htmlwidgets/modules/geoms/rect.js` already isolates rect/tile pixel placement and is the natural place for D3-boundary fixes if transformed fixtures expose a small mismatch.
- `R/ir_helpers_scales.R` and `R/ir_helpers_layers.R` give Phase 51 cleaner R-side seams for transform and layer-data characterization without reopening the full `as_d3_ir()` body.
- `inst/htmlwidgets/modules/geoms/polygon.js` already preserves row order and groups by built `group`; this is the baseline contract for topology characterization.
- `inst/htmlwidgets/modules/geoms/sf.js` already has projected-anchor helpers for sf text/label annotations, including `hjust`, `vjust`, family/font styling helpers, and label-anchor internals.
- Phase 48 browser visual smoke and older polygon/sf browser helpers can generate local HTML/screenshot/log artifacts for inspection without committing generated outputs.

### Established Patterns
- Evidence-first geometry work: classify against ggplot2, then fix only if the implicated boundary is clear.
- Optional dependencies remain optional: `{sf}`, `geojsonsf`, Chrome/Chromium, and `chromote` checks must skip explicitly when unavailable.
- Generated visual artifacts belong under ignored `test_output/`.
- Ordinary polygon rendering is not a GIS topology engine; it is ggplot2-style row-order grouped SVG path rendering.
- Public callback payload sanitization and renderer/interactivity wiring are already guarded by Phase 50 source-contract tests and should remain untouched unless tests are updated intentionally.

### Integration Points
- Rect/tile work connects R transform metadata (`R/ir_helpers_scales.R`, `R/as_d3_ir.R`) to D3 rect bounds (`inst/htmlwidgets/modules/geoms/rect.js`) and zoom/update handling (`inst/htmlwidgets/modules/geom-registry.js`).
- Polygon topology work connects IR fixture characterization (`tests/testthat/test-polygon-ir.R`) to renderer path semantics (`polygon.js`) and optional browser proof (`test-polygon-browser.R` or `test-browser-visual-smoke.R`).
- Text/label polish connects ordinary text rendering (`text.js`) and sf annotation rendering (`sf.js`) to source/IR tests and optional visual smoke fixtures.

</code_context>

<specifics>
## Specific Ideas

- Recommended plan order: transformed rect/tile classification first, polygon topology characterization second, text/label candidate classification or tiny improvement third, final validation notes last.
- For rect/tile, prefer a fixture matrix over a single example: continuous rect, categorical tile, transformed x, transformed y, and update/zoom path where relevant.
- For polygons, make unsupported cases visible and truthful rather than trying to infer holes or repair invalid shapes.
- For text/label, a small `geom_label()` or `hjust`/`vjust`/`angle` improvement is acceptable only if tests can prove it without creating a broad placement engine.

</specifics>

<deferred>
## Deferred Ideas

- Full GIS topology repair, automatic hole inference, invalid polygon fixing, and polygon-overlap brushing remain future work or explicit non-goals unless the product direction changes.
- Full ggrepel-compatible collision avoidance remains FUT-05 and should not be implemented in Phase 51.
- Broad path-following label placement remains a future feature unless a tiny, isolated classification artifact is enough.
- CI-hosted screenshot/perceptual diffs and committed golden images remain FUT-01/FUT-02 after local visual smoke stabilizes.
- Projection-aware map interactions beyond ggplot parity remain FUT-06.

</deferred>

---

*Phase: 51-geometry-edge-case-classification-and-polish*
*Context gathered: 2026-05-26*
