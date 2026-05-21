# Phase 37: Non-Polygon sf IR And Renderer - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 37 expands `geom_sf()` beyond polygon-family geometries so users can render `POINT`, `MULTIPOINT`, `LINESTRING`, and `MULTILINESTRING` sf layers through the existing gg2d3 R-to-IR-to-D3 pipeline.

The phase must preserve the v1.8/v1.9 polygon contract: R-side CRS normalization, source row identity, skipped-row diagnostics, panel-scoped `sf_bbox`, browser-visible `geom-sf` selectors, finite representative anchors, sanitized callback payloads, centroid/anchor brushing semantics, and continued suppression of Cartesian `d3_zoom()` for sf widgets.

The phase should not add `GEOMETRYCOLLECTION`, `geom_sf_text()`, `geom_sf_label()`, basemaps, slippy-map controls, JavaScript CRS reprojection, true geometry-overlap brushing, screenshot-diff gates, or large-map performance guarantees.

</domain>

<decisions>
## Implementation Decisions

### SVG Mark Contract
- **D-01:** Keep `.geom-sf` as the shared selector for every accepted sf family so existing tooltip, hover, handler, brush, and browser smoke infrastructure can target sf marks uniformly.
- **D-02:** Render point-family sf geometries as visible SVG circle marks with classes like `geom-sf geom-sf-point`.
- **D-03:** Render line-family sf geometries as SVG paths with classes like `geom-sf geom-sf-line`.
- **D-04:** Preserve polygon-family rendering as SVG paths and add or retain a family-specific polygon class such as `geom-sf-polygon` without breaking the existing `path.geom-sf` compatibility contract for polygons.
- **D-05:** All sf marks need stable `data-row-id` plus finite `data-cx` and `data-cy` representative anchor attributes when the geometry can produce an anchor.

### Multipoint And Multiline Identity
- **D-06:** Public behavior is source-row-oriented. `MULTIPOINT` and `MULTILINESTRING` may draw multiple child marks or subpaths internally, but tooltip, handler, and brush payloads should expose the original source row rather than per-child synthetic rows.
- **D-07:** If the renderer creates multiple DOM children for one source row, callback and brush results should deduplicate public rows so one source feature is reported once.
- **D-08:** Diagnostics should continue to report accepted and skipped source rows, accepted geometry types, unsupported geometry types, missing CRS, and skip reasons. Add accepted geometry families only if it makes validation clearer.

### Point And Line Styling
- **D-09:** Phase 37 should lock visible core styling parity for point and line sf families, not just make them technically present.
- **D-10:** Point-family sf marks should honor core point aesthetics where available: `colour`/`color`, `fill`, `alpha`, and `size`/radius behavior consistent with existing gg2d3 point conventions where practical.
- **D-11:** Line-family sf marks should honor core line aesthetics where available: `colour`/`color`, `alpha`, `linewidth`, `linetype`, and explicit no-fill behavior (`fill="none"` or equivalent).
- **D-12:** Subtle edge-case parity can be left for Phase 38 documentation/interactivity hardening, but Phase 37 output must be visibly useful and not misleading.

### Mixed And Faceted Validation
- **D-13:** Required validation fixtures should cover point-only, line-only, polygon+point overlay, polygon+line overlay, mixed accepted/skipped rows, facets, and empty-panel behavior where feasible.
- **D-14:** Validate Phase 37 at the IR/source level and reuse the Phase 36 browser smoke harness where it is cheap and reliable. Browser coverage should prove at least representative point and line DOM marks render nonblank with row ids and finite anchors.
- **D-15:** Mixed accepted sf families in stacked and faceted panels must share the same panel-scoped projection/bbox behavior without regressing polygon alignment or skipped-row filtering.
- **D-16:** Existing polygon fixtures and Phase 36 browser smoke contracts remain regression gates while implementing non-polygon sf support.

### the agent's Discretion
- Exact helper names, internal family-classification shape, whether point/multipoint expansion happens in R IR or in the JS renderer, and fixture file naming are left to research and planning, provided the decisions above and SFGEOM requirements are satisfied.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Requirements
- `.planning/ROADMAP.md` - Phase 37 goal, dependency on Phase 36, success criteria, and v1.9 phase order.
- `.planning/REQUIREMENTS.md` - SFGEOM-01 through SFGEOM-04 requirements plus out-of-scope sf exclusions.
- `.planning/PROJECT.md` - project value, v1.9 target features, constraints, and key decisions carried forward from previous sf phases.
- `.planning/STATE.md` - current milestone position and recent Phase 36 decisions.
- `.planning/research/FEATURES.md` - v1.9 sf feature landscape, non-polygon user contracts, anti-features, and recommended IR/renderer contracts.

### Prior Phase Contracts
- `.planning/phases/36-browser-sf-smoke-harness/36-CONTEXT.md` - browser harness decisions, fixture matrix, DOM assertion strategy, and no-Node browser tooling decision.
- `.planning/phases/36-browser-sf-smoke-harness/36-VERIFICATION.md` - Phase 36 verification evidence and residual risk around live Chrome execution.
- `.planning/phases/36-browser-sf-smoke-harness/36-REVIEW.md` - advisory follow-ups that may affect Phase 37 tests: direct `pkgload`/`rprojroot` Suggests and facet panel identity assertion tightening.

### R IR And sf Utilities
- `R/sf_utils.R` - current geometry filtering, CRS normalization, GeoJSON serialization, diagnostics, bbox helpers, and polygon-only `supported_types` default.
- `R/as_d3_ir.R` - sf layer assembly, panel-scoped `sf_bbox` accumulation, layer data/geometry parallelism, and final IR construction.
- `R/validate_ir.R` - sf layer and panel validation checks.
- `R/gg2d3.R` - public roxygen support note that currently describes polygon-family `geom_sf()`.

### Renderer And Interactivity
- `inst/htmlwidgets/modules/geoms/sf.js` - current sf renderer, `path.geom-sf`, `data-row-id`, `data-cx`, `data-cy`, `d3.geoIdentity().reflectY(true).fitExtent()`, and polygon path styling.
- `inst/htmlwidgets/modules/brush.js` - existing sf centroid/anchor brushing behavior and selector list.
- `inst/htmlwidgets/modules/events.js` - tooltip, hover, and custom handler selector integration plus payload sanitization.
- `inst/htmlwidgets/modules/tooltip.js` - tooltip payload handling and sanitization.
- `R/d3_zoom.R` - continued sf zoom suppression warning and unchanged-widget behavior.

### Existing Tests And Fixtures
- `tests/testthat/test-sf-ir.R` - current sf IR tests for row identity, CRS, diagnostics, skipped rows, and panel `sf_bbox`.
- `tests/testthat/test-sf-renderer.R` - source-level sf renderer and panel metadata assertions.
- `tests/testthat/test-sf-interactivity.R` - source-level sf interactivity selector, payload sanitization, brush, and zoom suppression assertions.
- `tests/testthat/helper-sf-fixtures.R` - reusable Phase 35 polygon fixture builders that Phase 37 should extend rather than replace.
- `tests/testthat/helper-browser-sf.R` - Phase 36 browser helper infrastructure for deterministic local artifacts, chromote skips, DOM polling, and browser error logs.
- `tests/testthat/test-sf-browser.R` - Phase 36 live DOM smoke tests and patterns for point/line browser checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `prepare_sf_geometry_ir()` already centralizes sf geometry column detection, source-row identity, supported-type filtering, CRS normalization, GeoJSON serialization, diagnostics, and accepted-geometry return values. Phase 37 should extend this seam instead of adding a parallel sf path.
- `sf_bbox_values()` already calculates panel bboxes from accepted geometries. Phase 37 needs it to include accepted point, line, and polygon families across stacked and faceted panels.
- The Phase 36 browser helpers already save non-self-contained widgets, open them in chromote, poll `geom-sf` DOM marks, collect console/page errors, and write failure artifacts.
- `.phase35_sf_fixture_set()` provides stable polygon regression fixtures. Phase 37 should add point/line fixtures beside this pattern rather than mutating the polygon fixtures beyond what is necessary.

### Established Patterns
- sf geometry support is opt-in through optional `sf` and `geojsonsf` dependencies, with clean skips in tests.
- The renderer uses one panel-level D3 geoIdentity projection derived from `options.sfBBox` or layer geometries.
- Existing interactivity modules rely on CSS selectors and sanitized public row payloads. Renderer-private `_geom` and `_centroid` fields must not leak.
- Existing line renderers use no-fill paths and stroke-oriented aesthetics; existing point renderers use circles. Phase 37 should mirror these familiar SVG conventions for sf families.

### Integration Points
- R-side geometry acceptance starts in `R/sf_utils.R`, then flows through the `gname == "sf"` branch in `R/as_d3_ir.R`.
- JS-side family dispatch belongs in `inst/htmlwidgets/modules/geoms/sf.js`, while shared selectors may also need updates in `brush.js`, `events.js`, and tooltip/hover/handler code.
- Validation should extend `tests/testthat/test-sf-ir.R`, `test-sf-renderer.R`, `test-sf-interactivity.R`, helper sf fixtures, and browser smoke tests.

</code_context>

<specifics>
## Specific Ideas

The user selected areas 1-4 and accepted the recommended options for all of them. That locks the recommended Phase 37 path:

- Circles for sf points, paths for sf lines/polygons, shared `.geom-sf`, and family-specific classes.
- Source-row-oriented public behavior for multipoint and multiline geometries, with deduplicated callbacks/brush payloads if child marks are rendered.
- Core visible styling now for points and lines.
- Broad point/line/mixed/facet/empty-panel validation with browser smoke coverage where Phase 36 makes it practical.

</specifics>

<deferred>
## Deferred Ideas

- `GEOMETRYCOLLECTION` support remains deferred until atomic point, line, and polygon families are stable.
- `geom_sf_text()` and `geom_sf_label()` remain deferred to a future label/annotation phase.
- Basemaps, slippy-map controls, projection-aware map zoom/pan, and JavaScript CRS reprojection remain out of scope.
- True polygon/line overlap brushing remains deferred; v1.9 continues representative-anchor brushing.
- Large-map performance guarantees and geometry simplification guidance remain deferred.
- Full styling edge-case parity may be completed in Phase 38 if Phase 37 covers the visible core.

</deferred>

---

*Phase: 37-non-polygon-sf-ir-and-renderer*
*Context gathered: 2026-05-21*
