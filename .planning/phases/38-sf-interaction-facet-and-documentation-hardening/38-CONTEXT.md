# Phase 38: sf Interaction, Facet, And Documentation Hardening - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 38 hardens the public v1.9 `geom_sf()` support contract after Phase 37 added non-polygon sf rendering. It should prove that sf polygon, point, and line marks work with the existing interaction system, that faceted sf widgets remain panel-local and projection-safe, and that user-facing documentation describes the supported behavior and limits honestly.

This phase should not broaden gg2d3 into a map engine. Basemaps, slippy-map controls, JavaScript CRS reprojection, true geometry-overlap brushing, large-map performance guarantees, `GEOMETRYCOLLECTION`, and sf text/label geoms remain out of scope.

</domain>

<decisions>
## Implementation Decisions

### Interaction Proof Depth
- **D-01:** Add live browser validation for sf interactions across accepted sf families, not only source-level assertions.
- **D-02:** Browser proof should cover tooltip display, hover/custom handlers, Shiny-style event handler payloads where practical, brush callbacks, sanitized source-row payloads, and continued sf zoom suppression.
- **D-03:** Interaction payloads remain source-row oriented. Renderer-private fields such as `_geom`, `_centroid`, `_sfFamily`, `_pointIndex`, and `_pointCoord` must not leak through tooltip, handlers, Shiny inputs, or brush callbacks.

### Facet Validation Matrix
- **D-04:** Treat both `facet_wrap()` and `facet_grid()` sf cases as hard gates.
- **D-05:** Cover point, line, polygon, mixed-family, and empty-panel facet fixtures.
- **D-06:** Validate panel-local mark counts and bbox/projection isolation directly in DOM/IR checks. Do not introduce screenshot diffing as the primary gate.

### Documentation Surface
- **D-07:** Update the public v1.9 sf support contract in README source/output, main vignette, diagnostics docs, roxygen source, and generated Rd/help as needed.
- **D-08:** Keep the README compact, but make it truthful enough that users do not need to discover point/line sf support only from tests.

### Public Contract Wording
- **D-09:** Use conservative, explicit wording for supported sf families: polygon-family, point-family, and line-family geometries are supported; unsupported, empty, invalid, or missing geometries are skipped with warnings.
- **D-10:** Document representative-anchor brushing semantics clearly. Brushing selects sf marks by rendered anchor/centroid attributes, not by true geometry intersection.
- **D-11:** Document zoom suppression for sf layers as intentional current behavior.
- **D-12:** Document map anti-features explicitly: no tile basemaps, no slippy map controls, no JavaScript-side CRS reprojection, no true geometry-overlap brushing, and no large-map performance guarantees.

### Codex Discretion
- Use the existing chromote/browser-sf harness and existing fixture style unless a smaller local helper makes the new tests clearer.
- Prefer direct DOM/IR assertions over visual assertions for automated gates.
- Keep documentation language consistent across surfaces, with diagnostics carrying the most detail.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Requirements
- `.planning/ROADMAP.md` - Phase 38 goal, dependency on Phase 37, success criteria, and SFXDOC requirement mapping.
- `.planning/REQUIREMENTS.md` - SFXDOC-01, SFXDOC-02, SFXDOC-03 and the remaining sf support contract.
- `.planning/PROJECT.md` - v1.9 scope, project principles, explicit out-of-scope map features.
- `.planning/STATE.md` - Current milestone progress and resume context.

### Prior Phase Context
- `.planning/phases/36-browser-sf-smoke-harness/36-CONTEXT.md` - Browser harness decisions: chromote, deterministic fixtures, DOM assertions, skip behavior.
- `.planning/phases/36-browser-sf-smoke-harness/36-VERIFICATION.md` - Browser harness verification and residual browser execution caveat.
- `.planning/phases/37-non-polygon-sf-ir-and-renderer/37-CONTEXT.md` - Locked point/line sf rendering decisions and deferred scope.
- `.planning/phases/37-non-polygon-sf-ir-and-renderer/37-VERIFICATION.md` - Phase 37 completion evidence and residual live-browser caveat.

### Existing Implementation And Tests
- `R/d3_tooltip.R` - Tooltip API roxygen source.
- `R/d3_hover.R` - Hover API roxygen source.
- `R/d3_handlers.R` - Custom/Shiny handler API roxygen source.
- `R/d3_brush.R` - Brush API roxygen source.
- `R/d3_zoom.R` - Zoom suppression behavior for sf widgets.
- `R/sf_utils.R` - sf geometry normalization, filtering, diagnostics, and bbox helpers.
- `inst/htmlwidgets/modules/geoms/sf.js` - sf renderer mark classes, row ids, anchors, and family handling.
- `inst/htmlwidgets/modules/events.js` - interactive selector list and event payload sanitization.
- `inst/htmlwidgets/modules/tooltip.js` - tooltip payload sanitization and field filtering.
- `inst/htmlwidgets/modules/brush.js` - brush selector list, sf anchor selection, callback sanitization, and row-id dedupe.
- `tests/testthat/helper-sf-fixtures.R` - Phase 35/37 reusable sf fixture builders and browser HTML output helpers.
- `tests/testthat/helper-browser-sf.R` - chromote browser helpers, console/error collection, sf mark waiting.
- `tests/testthat/test-sf-interactivity.R` - source-level interaction and sanitization assertions.
- `tests/testthat/test-sf-browser.R` - live DOM browser smoke tests for sf paths, marks, facets, payloads, and artifacts.
- `tests/testthat/test-sf-renderer.R` - renderer and IR smoke assertions for sf families, anchors, and classes.

### Documentation Surfaces
- `README.Rmd` - README source; currently still describes polygon-only sf support and needs v1.9 updates.
- `README.md` - generated README output.
- `vignettes/gg2d3.Rmd` - main vignette; currently has a v1.8 polygon-family sf section.
- `vignettes/gg2d3-interactivity.Rmd` - interaction semantics, including sf tooltip/hover/brush/zoom wording.
- `vignettes/d3-drawing-diagnostics.md` - diagnostics and known limitations; currently says non-polygon sf rendering is unsupported in v1.8.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tests/testthat/helper-sf-fixtures.R` already creates deterministic polygon, point, line, mixed, skipped-row, and empty-panel fixtures. Phase 38 should extend this instead of inventing a second fixture system.
- `tests/testthat/helper-browser-sf.R` and `tests/testthat/test-sf-browser.R` already provide chromote sessions, file URL helpers, console/page-error collection, `wait_for_sf_paths()`, and `wait_for_sf_marks()`.
- `tests/testthat/test-sf-interactivity.R` already asserts source-level sanitization for tooltip, brush, events, and zoom suppression.

### Established Patterns
- Browser tests should skip cleanly when chromote/browser dependencies are unavailable and should write deterministic failure artifacts under `test_output/browser-sf`.
- Automated browser validation should inspect live DOM state, callback globals, and console/page errors rather than comparing screenshots.
- sf renderer marks share `.geom-sf`, with family-specific classes such as `.geom-sf-polygon`, `.geom-sf-point`, and `.geom-sf-line`.
- sf marks expose `data-row-id`, `data-cx`, and `data-cy`; brush uses these rendered anchors for sf selection before falling back to generic path bbox behavior.
- Point-family sf renders as SVG circles; line-family and polygon-family sf render as SVG paths.

### Integration Points
- Interaction targets are centralized in `inst/htmlwidgets/modules/events.js` and `inst/htmlwidgets/modules/brush.js`.
- Tooltip payload filtering lives in `inst/htmlwidgets/modules/tooltip.js`; brush callback filtering and dedupe live in `inst/htmlwidgets/modules/brush.js`; handler filtering lives in `inst/htmlwidgets/modules/events.js`.
- Public docs should be updated from source files first (`README.Rmd`, vignette Rmd, roxygen R files), then generated outputs should be refreshed.

</code_context>

<specifics>
## Specific Ideas

- The user validated Phase 35/37 manual browser visuals and noted expected fixture appearances: stacked overlays show red/outline shapes inside larger blue shapes; skipped rows show only valid geometries at the left/right edges; faceted fixtures show panel-local marks with empty panels where expected.
- Phase 38 should convert that manual confidence into repeatable browser assertions where feasible.
- Keep the support contract narrow and easy to defend for v1.9: ggplot-like sf SVG rendering, not GIS/map application behavior.

</specifics>

<deferred>
## Deferred Ideas

- `GEOMETRYCOLLECTION` rendering.
- `geom_sf_text()` / `geom_sf_label()` support.
- Basemaps, slippy-map controls, and JavaScript CRS reprojection.
- True geometry-overlap brushing for polygons or lines.
- Large-map performance guarantees.
- Screenshot-diff visual regression as the primary sf browser gate.

</deferred>

---

*Phase: 38-sf-interaction-facet-and-documentation-hardening*
*Context gathered: 2026-05-22*
