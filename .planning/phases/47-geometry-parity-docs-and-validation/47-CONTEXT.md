# Phase 47: Geometry Parity Docs And Validation - Context

**Gathered:** 2026-05-25T10:10:14+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 47 delivers the documentation and validation evidence sweep for the v1.11 geometry parity milestone. It updates public and maintainer-facing docs so ordinary `geom_polygon()`, rect/tile edge behavior, and `geom_sf_text()` / `geom_sf_label()` annotations are described as shipped support with explicit limitations.

This phase does not add new renderer behavior. New geometry features, new interactivity APIs, screenshot/perceptual test infrastructure, map basemaps, JavaScript-side CRS reprojection, topology repair, and ggrepel-style collision or path-following annotation behavior remain out of scope.

</domain>

<decisions>
## Implementation Decisions

### Public Support Wording
- **D-01:** Use a balanced support table or equivalent structured wording in public docs: mark v1.11 polygon, rect/tile, and sf annotation features as supported while keeping limitations visible next to the support statement.
- **D-02:** Avoid both over-cautious stale wording and broad "everything matches ggplot2" claims. The docs should say what is supported, what evidence backs it, and where exact parity remains deferred.
- **D-03:** Replace now-stale statements that ordinary `geom_polygon()` lacks a renderer and that `geom_sf_text()` / `geom_sf_label()` are unsupported.

### Validation Evidence Shape
- **D-04:** Record validation evidence as a feature matrix mapping each geometry area to representative test files, useful commands, browser smoke coverage, and skip semantics.
- **D-05:** The matrix should distinguish source/IR/unit coverage from optional browser DOM smoke coverage. Optional skips are acceptable when local dependencies such as `sf`, `chromote`, or Chrome are unavailable, but the notes should explain what the skipped tests would cover.
- **D-06:** Keep the validation notes representative rather than exhaustive. Link the important tests and smoke fixtures; do not turn the docs into a full test index.

### Deferred Scope Placement
- **D-07:** Put concise limitations in README, vignettes, and help pages where users encounter support claims.
- **D-08:** Put detailed caveats and residual risks in `vignettes/d3-drawing-diagnostics.md`, then link or reference that diagnostics doc from concise public notes.
- **D-09:** Keep future/deferred geometry items explicit: polygon topology/hole repair beyond the supported grouped-path contract, full rect/tile transformed-scale edge parity, tile basemaps, slippy controls, JavaScript-side CRS reprojection, ggrepel collision avoidance, rich text, rotation parity, and path-following annotation placement are not shipped by Phase 47.

### Generated Documentation Policy
- **D-10:** Update source docs first: `README.Rmd`, vignettes, and roxygen comments.
- **D-11:** Regenerate generated artifacts in this phase when sources change, including `README.md` and affected `man/*.Rd`.
- **D-12:** Do not manually patch generated help as the primary source of truth. If a generated file needs different wording, change its roxygen source and regenerate.

### the agent's Discretion
- Planners may choose the exact layout of support tables and validation matrices as long as the feature-to-evidence mapping is easy to scan.
- Planners may decide whether validation notes live in a dedicated new file, in diagnostics, or both, provided the roadmap success criteria are covered and canonical docs link to the evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Contract
- `.planning/ROADMAP.md` — Phase 47 goal, success criteria, and two planned work areas.
- `.planning/REQUIREMENTS.md` — `DOCVAL-01`, the acceptance requirement for docs, generated help, and validation notes.
- `.planning/PROJECT.md` — Current v1.11 milestone framing and target features.

### Prior Phase Contracts
- `.planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md` — Ordinary polygon support boundary, interactivity expectations, and deferred topology behavior.
- `.planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md` — Rect/tile edge behavior boundary and diagnostics expectations.
- `.planning/phases/46-sf-text-and-label-annotations/46-CONTEXT.md` — sf annotation support boundary, styling/interactivity expectations, and deferred annotation behavior.

### Documentation Surfaces
- `README.Rmd` — Source for README support tables and user-facing contract wording.
- `README.md` — Generated README that should be refreshed after `README.Rmd` changes.
- `vignettes/gg2d3.Rmd` — Main package vignette with geom support and examples.
- `vignettes/gg2d3-interactivity.Rmd` — Interactivity vignette that should mention geometry targets consistently when relevant.
- `vignettes/d3-drawing-diagnostics.md` — Detailed diagnostics, residual risks, and deferred geometry items.
- `R/gg2d3.R` — Main roxygen help source for `gg2d3()`.
- `R/d3_tooltip.R`, `R/d3_brush.R`, `R/d3_handlers.R`, `R/d3_hover.R`, `R/d3_crosstalk.R` — Roxygen sources for interactivity contracts that mention geometry target support.
- `R/sf_utils.R` — Roxygen source for sf geometry extraction helpers.
- `man/gg2d3.Rd`, `man/d3_tooltip.Rd`, `man/d3_brush.Rd`, `man/d3_handlers.Rd`, `man/d3_hover.Rd`, `man/d3_crosstalk.Rd`, `man/extract_sf_geometries.Rd` — Generated help surfaces to verify after roxygen regeneration.

### Representative Validation Evidence
- `tests/testthat/test-polygon-ir.R` — Ordinary polygon IR extraction, row order, panels, and aesthetics.
- `tests/testthat/test-polygon-renderer.R` — Ordinary polygon renderer source contracts.
- `tests/testthat/test-polygon-interactivity.R` — Ordinary polygon interactivity source contracts.
- `tests/testthat/test-polygon-browser.R` — Optional browser DOM smoke for polygon rendering, facets, styling, sanitized payloads, and crosstalk keys.
- `tests/testthat/test-rect-tile-ir.R` — Rect/tile IR fixture matrix for scale limits, coord limits, discrete tiles, reversed scales, coord flip, and facets.
- `tests/testthat/test-rect-tile-renderer.R` — Rect/tile renderer source contracts and classification-backed behavior.
- `.planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md` — Rect/tile classification notes referenced by renderer tests.
- `tests/testthat/test-sf-annotations-ir.R` — sf text/label IR extraction, anchors, facets, diagnostics, and skipped rows.
- `tests/testthat/test-sf-annotations-renderer.R` — sf annotation renderer source contracts.
- `tests/testthat/test-sf-annotations-interactivity.R` — sf annotation interactivity source contracts and sanitized payload expectations.
- `tests/testthat/test-sf-annotations-browser.R` — Optional browser DOM smoke for sf text/label marks and interaction payloads.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `README.Rmd` already contains a geom support table and support caveats; Phase 47 should revise this rather than inventing a separate support taxonomy.
- `vignettes/d3-drawing-diagnostics.md` already hosts geometry diagnostics and residual risk notes; it is the natural home for detailed v1.11 caveats.
- Existing optional browser tests already encode skip behavior for local dependency gaps; validation notes should document those skips instead of requiring all contributors to have spatial/browser dependencies installed.

### Established Patterns
- R package documentation is source-first: roxygen sources and `README.Rmd` drive generated `man/*.Rd` and `README.md`.
- Tests use `testthat`, with optional browser smoke guarded by helper skips. Phase 47 should preserve CRAN-compatible skip behavior.
- The project has favored source/DOM assertions over screenshot or perceptual diffing for geometry parity.

### Integration Points
- Public user support claims should be consistent across `README.Rmd`, `vignettes/gg2d3.Rmd`, `vignettes/gg2d3-interactivity.Rmd`, and `R/gg2d3.R`.
- Interactivity contracts should stay consistent across helper docs (`d3_tooltip`, `d3_brush`, `d3_handlers`, `d3_hover`, `d3_crosstalk`) and the implemented geometry target classes.
- Validation notes should point to the representative test files and commands planners/executors actually run during Phase 47.

</code_context>

<specifics>
## Specific Ideas

- User selected the recommended defaults for all four gray areas: balanced public support wording, feature-to-evidence validation matrix, concise public limitations plus detailed diagnostics, and source-first regeneration of generated docs.
- README and diagnostics currently contain stale language that should be corrected during planning/execution: ordinary `geom_polygon()` is no longer unsupported, and `geom_sf_text()` / `geom_sf_label()` are now part of the v1.11 support contract.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 47-geometry-parity-docs-and-validation*
*Context gathered: 2026-05-25*
