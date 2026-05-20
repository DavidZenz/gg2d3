# Phase 35: geom_sf Docs and Validation Hardening - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 35 locks down the production support story for the v1.8 `geom_sf` polygon MVP. It updates package-facing documentation, diagnostics guidance, generated help output, automated tests, and browser/manual validation fixtures for behavior already implemented in Phases 32-34.

This phase does not add new map capabilities. It documents and verifies the current polygon-family contract: `POLYGON`/`MULTIPOLYGON` extraction, R-side CRS normalization, unsupported/empty/invalid/missing geometry diagnostics, D3 `path.geom-sf` rendering, tooltip/hover/handler support, centroid brushing, zoom suppression, stacked sf shared projection, and facet-aware per-panel projection.

</domain>

<decisions>
## Implementation Decisions

### Public Support Story
- **D-01:** Present `geom_sf` as supported for polygon-family choropleths and polygon overlays, not as general-purpose sf/map support.
- **D-02:** Update the support story in user-facing places: `README.Rmd`, generated `README.md`, the main vignette, diagnostics/limitations docs, and generated help where relevant.
- **D-03:** Keep README coverage concise and confidence-building: one short feature bullet plus one small example or reference to the vignette. Put detailed caveats and validation examples in vignette/diagnostics docs.
- **D-04:** Make `README.md` generated from `README.Rmd`; do not hand-edit the generated file except as an output of `devtools::build_readme()`.

### Truthful Boundaries
- **D-05:** Be explicit and blunt about supported geometry scope: only `POLYGON` and `MULTIPOLYGON` render in v1.8.
- **D-06:** Document unsupported sf rows as warn-and-skip behavior, preserving valid polygon rows where possible.
- **D-07:** Document missing CRS behavior honestly: known CRS inputs are normalized to WGS84 in R; missing CRS emits a warning and serializes coordinates as-is.
- **D-08:** Document `d3_zoom()` suppression for sf widgets as intentional truthful behavior, not a bug.
- **D-09:** Keep explicit anti-features visible: no tile basemaps, no slippy map controls, no JavaScript-side CRS reprojection, no polygon-overlap brushing, no non-polygon sf rendering, and no large-map performance guarantees.
- **D-10:** Replace stale documentation that lists `geom_sf` as unsupported now that polygon-family support exists.

### Validation Fixture Set
- **D-11:** Treat the canonical validation set as: single-panel choropleth, stacked sf overlay, `facet_wrap()` sf map, `facet_grid()` sf map, unsupported/mixed geometry rows, invalid/empty/missing geometry rows, missing CRS warning, tooltip/hover/handler smoke, centroid brush smoke, and zoom suppression.
- **D-12:** Prefer focused automated checks for contracts that can be asserted in R/source tests: warnings, diagnostics fields, row identity, `sf_bbox`, geometry/data alignment, selector inclusion, callback payload sanitization, centroid attributes, and zoom suppression.
- **D-13:** Use browser/manual HTML fixtures for visual confidence in map rendering and composition, written to project-root `test_output/` per existing convention.
- **D-14:** Guard optional spatial fixture tests with `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and additional package skips such as `rnaturalearth` where needed.
- **D-15:** Do not let invalid or skipped sf rows become misleading selectable paths; tests should prove skipped rows do not appear as interactive marks.

### Browser Verification Depth
- **D-16:** Phase 35 should add lightweight browser/manual validation fixtures and structural assertions, not a full pixel visual regression system.
- **D-17:** Accept manual HTML inspection artifacts for rendered visual checks, supported by automated IR/source/HTML-existence assertions.
- **D-18:** If a cheap browser smoke check is available locally, it may verify that generated sf HTML contains non-empty `path.geom-sf` output and expected attributes, but full screenshot diffing is out of scope.
- **D-19:** Keep the validation harness small and maintainable; Phase 35 should harden confidence without introducing heavy new infrastructure.

### the agent's Discretion
- The planner may decide the exact documentation section names and whether to create a dedicated `geom_sf` vignette or add a focused section to an existing vignette, as long as the public support story is discoverable.
- The planner may choose exact fixture names and file organization within existing test conventions.
- The planner may choose exact warning text references in docs, but docs must stay consistent with actual warnings in `R/sf_utils.R` and `R/d3_zoom.R`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Scope
- `.planning/PROJECT.md` — Current v1.8 state, validated sf behavior, key decisions, and out-of-scope map anti-features.
- `.planning/ROADMAP.md` — Phase 35 goal, requirements, success criteria, dependencies, and likely files.
- `.planning/REQUIREMENTS.md` — `SFDOC-01` and `SFDOC-02` requirement definitions and traceability.
- `.planning/STATE.md` — Current workflow state showing Phase 35 as next focus.

### Prior Phase Contracts
- `.planning/phases/32-geom-sf-ir-foundation/32-CONTEXT.md` — R-side sf extraction, CRS, diagnostics, and row-alignment decisions.
- `.planning/phases/32-geom-sf-ir-foundation/32-VERIFICATION.md` — Verified Phase 32 IR contract.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-CONTEXT.md` — Single-panel renderer, tooltip/hover, centroid brush, and zoom suppression decisions.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-VERIFICATION.md` — Verified Phase 33 renderer/interactivity contract.
- `.planning/phases/34-stacked-and-faceted-projection-alignment/34-CONTEXT.md` — Stacked and faceted projection alignment decisions.
- `.planning/phases/34-stacked-and-faceted-projection-alignment/34-VERIFICATION.md` — Verified Phase 34 shared/faceted projection contract.

### User-Facing Documentation Targets
- `README.Rmd` — Source for README feature/support story; edit this before regenerating `README.md`.
- `README.md` — Generated README output; should reflect `README.Rmd`.
- `vignettes/gg2d3.Rmd` — Main package vignette and likely place for a focused `geom_sf` usage section.
- `vignettes/gg2d3-interactivity.Rmd` — Interactivity vignette; may need sf tooltip/hover/brush/zoom notes if planning chooses.
- `vignettes/d3-drawing-diagnostics.md` — Existing known-limitations doc currently stale for `geom_sf`; must be updated.
- `R/gg2d3.R` — Roxygen source for `gg2d3()` help.
- `R/sf_utils.R` — Roxygen source and actual warnings/helper behavior for sf extraction, CRS normalization, and diagnostics.
- `R/d3_zoom.R` — Roxygen source and actual zoom suppression behavior.
- `man/gg2d3.Rd` — Generated help output from roxygen.
- `man/d3_zoom.Rd` — Generated help output from roxygen.

### Validation and Test Targets
- `tests/testthat/test-sf-ir.R` — Existing IR, diagnostics, missing CRS, malformed `sf_bbox`, stacked bbox, and row-alignment tests.
- `tests/testthat/test-sf-utils.R` — Existing helper tests for normalization, geometry filtering, invalid/empty/skipped rows, and diagnostics.
- `tests/testthat/test-sf-renderer.R` — Existing renderer/source-contract tests for path attributes, `sfBBox`, and data/geometry filtering.
- `tests/testthat/test-sf-interactivity.R` — Existing sf interactivity tests.
- `tests/testthat/test-sf-visual.R` — Existing manual HTML fixture generation for sf rendering; should be expanded for Phase 35 fixtures.
- `tests/testthat/test-facets.R` — Existing `facet_wrap()` sf bbox isolation coverage.
- `tests/testthat/test-facet-grid.R` — Existing `facet_grid()` sf bbox/layout/empty-panel coverage.
- `tests/testthat/test-zoom-brush.R` — Existing zoom suppression and brush API tests.
- `test_output/` — Project-root location for generated manual visual check HTML files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `README.Rmd`: Source of truth for the README; already has feature tables and troubleshooting sections that can absorb a concise `geom_sf` support note.
- `vignettes/gg2d3.Rmd`: Main user guide already has interactivity and error-handling sections; it can host a practical `geom_sf` example and support boundary note.
- `vignettes/d3-drawing-diagnostics.md`: Existing limitations doc has stale `geom_sf` language and should become the truthful map-support boundary document.
- `R/sf_utils.R`: Contains actual warnings and diagnostics behavior that docs must match.
- `R/d3_zoom.R`: Contains actual sf zoom suppression behavior that docs must match.
- `tests/testthat/test-sf-visual.R`: Already writes sf manual HTML fixtures to `test_output/` and can be extended for stacked/faceted/unsupported validation artifacts.

### Established Patterns
- Generated docs come from source files: `README.md` from `README.Rmd`, `.Rd` files from roxygen comments.
- Tests use real ggplot2 and sf objects rather than mocks.
- Optional spatial dependency tests use `skip_if_not_installed()` guards.
- Manual visual fixtures are saved under project-root `test_output/`, not `/tmp`.
- Existing validation leans on focused R/source assertions plus manual HTML visual inspection, not screenshot diff infrastructure.

### Integration Points
- Documentation should describe the same behavior exposed by `prepare_sf_geometry_ir()`, `validate_ir()`, `sf.js`, `events.js`, `brush.js`, and `d3_zoom()`.
- Automated tests should guard user-visible contracts: diagnostics, warning behavior, skipped rows, absence of misleading interactive paths, `path.geom-sf` attributes, and generated fixture existence.
- Browser/manual fixture generation should use `gg2d3()` and existing htmlwidgets save conventions so contributors can inspect the actual rendered widget.

</code_context>

<specifics>
## Specific Ideas

- Recommended defaults accepted for all gray areas.
- The docs should feel like a clear support contract, not a marketing claim that implies full GIS/map support.
- The validation work should be broad enough to cover the v1.8 sf story, but deliberately avoid building a heavy visual regression framework.
- The stale diagnostics doc currently saying `geom_sf` is unsupported should be corrected as part of the phase.

</specifics>

<deferred>
## Deferred Ideas

- Full screenshot/pixel visual regression infrastructure — future testing infrastructure phase if needed.
- Global-comparison projection mode for faceted sf maps — future requirement `SFNEXT-04`.
- Non-polygon sf rendering for points, lines, and geometry collections — future requirements `SFNEXT-01`, `SFNEXT-02`, and `SFNEXT-03`.
- Polygon-overlap brushing — future requirement `SFNEXT-05`.
- Large-map simplification/performance budgets — future requirement `SFNEXT-06`.
- Tile basemaps, slippy map controls, and JavaScript-side CRS reprojection remain out of scope for v1.8.

</deferred>

---

*Phase: 35-geom-sf-docs-and-validation-hardening*
*Context gathered: 2026-05-20*
