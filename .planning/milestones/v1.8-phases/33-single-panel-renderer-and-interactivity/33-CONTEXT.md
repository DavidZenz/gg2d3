# Phase 33: Single-Panel Renderer and Interactivity - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 33 delivers single-panel `geom_sf` polygon rendering and interactivity. It hardens the existing D3 `path.geom-sf` renderer, connects sf paths to the existing tooltip and hover APIs, updates brush selection to use sf centroid attributes, and makes `d3_zoom()` warn/suppress unsupported sf zoom behavior. Stacked sf layer projection alignment, faceted sf maps, JavaScript-side reprojection, tile basemaps, slippy-map controls, polygon-overlap brushing, and documentation hardening remain later-phase or out-of-scope work.

</domain>

<decisions>
## Implementation Decisions

### Renderer Hardening
- **D-01:** Harden the existing `inst/htmlwidgets/modules/geoms/sf.js` renderer rather than redesigning it in Phase 33.
- **D-02:** Keep the established `d3.geoIdentity().reflectY(true).fitExtent()` projection path for single-panel maps.
- **D-03:** Preserve `path.geom-sf`, `fill-rule="evenodd"`, fill/stroke aesthetic passthrough, `data-row-id`, and centroid attributes as the renderer contract.
- **D-04:** Any renderer cleanup should be conservative and serve Phase 33 correctness; broader projection helper extraction belongs to Phase 34 if needed.

### Tooltip and Hover Behavior
- **D-05:** Reuse the existing tooltip and hover APIs by adding `path.geom-sf` to the interactive selector architecture.
- **D-06:** Tooltip data should use the bound sf row data as the source, while hiding internal geometry/projection helper fields such as `_geom`, `_centroid`, and any other renderer-only fields.
- **D-07:** Hover should behave like other geoms: dim siblings, highlight the hovered polygon, and honor existing configured stroke/stroke-width behavior.
- **D-08:** Do not introduce a new sf-specific tooltip API in this phase.

### Brush Selection
- **D-09:** Brush selection for sf paths is centroid-only in Phase 33, using `data-cx` and `data-cy` attributes on `path.geom-sf`.
- **D-10:** Brush callbacks/Shiny outputs should collect and return the same bound row data used by tooltips.
- **D-11:** Do not use polygon overlap or path bounding-box selection for sf maps in Phase 33. Bounding-box selection remains acceptable for non-sf paths.
- **D-12:** If a centroid is missing or invalid, the corresponding sf path should not be selected by a brush rather than falling back to misleading geometry bounds.

### Zoom Suppression
- **D-13:** If any sf layer is present in the widget IR, `d3_zoom()` should warn and suppress zoom for the whole widget in Phase 33.
- **D-14:** Suppression should leave the widget otherwise usable and should not attach misleading Cartesian zoom behavior.
- **D-15:** Mixed sf/non-sf zoom behavior is deferred; Phase 33 prioritizes truthful behavior over partial zoom attachment.
- **D-16:** Browser-side zoom no-op behavior is not the primary mechanism; suppression should be visible from the R API where the user opts into `d3_zoom()`.

### the agent's Discretion
- Exact warning text for `d3_zoom()` may be chosen by the planner, as long as it clearly mentions `geom_sf`/sf and unsupported zoom suppression.
- Exact internal helper names for selector filtering and centroid checks are up to the planner.
- Test organization may be split across existing sf renderer, interactivity, brush, and zoom test files as long as Phase 33 requirements are covered.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Scope
- `.planning/PROJECT.md` — Current v1.8 state, sf milestone decisions, and anti-features.
- `.planning/ROADMAP.md` — Phase 33 goal, success criteria, dependencies, and likely files.
- `.planning/REQUIREMENTS.md` — SFREND-01 and SFINTR-01/02/03 requirement definitions and traceability.

### Upstream Phase 32 Contract
- `.planning/phases/32-geom-sf-ir-foundation/32-VERIFICATION.md` — Verified sf IR contract for filtered rows, CRS, bbox, diagnostics, and row alignment.
- `.planning/phases/32-geom-sf-ir-foundation/32-01-SUMMARY.md` — Helper-level sf filtering and diagnostics summary.
- `.planning/phases/32-geom-sf-ir-foundation/32-02-SUMMARY.md` — `as_d3_ir()` and `validate_ir()` sf integration summary.

### Existing Code and Tests
- `inst/htmlwidgets/modules/geoms/sf.js` — Existing sf path renderer to harden.
- `inst/htmlwidgets/modules/events.js` — Tooltip, hover, custom handlers, and interactive selector architecture.
- `inst/htmlwidgets/modules/brush.js` — Brush selection logic and callback collection.
- `inst/htmlwidgets/modules/zoom.js` — Existing JS zoom behavior; should not be attached to sf widgets in Phase 33.
- `R/d3_zoom.R` — R API for zoom configuration and warning/suppression behavior.
- `tests/testthat/test-sf-renderer.R` — Existing sf row-id and data/geometry alignment checks.
- `tests/testthat/test-sf-visual.R` — Existing sf HTML visual fixture generation.
- `tests/testthat/test-zoom-brush.R` — Existing R-side zoom and brush API tests.
- `tests/testthat/test-interactivity.R` — Existing tooltip/hover/handler tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inst/htmlwidgets/modules/geoms/sf.js`: Already renders sf geometries as `path.geom-sf` using `d3.geoPath()` and `d3.geoIdentity().reflectY(true).fitExtent()`, sets `fill-rule="evenodd"`, stores `data-row-id`, and computes `data-cx`/`data-cy`.
- `inst/htmlwidgets/modules/events.js`: Central selector arrays drive tooltips, hover, custom handlers, legend state, and linked interactions. Adding `path.geom-sf` here is the natural integration point.
- `inst/htmlwidgets/modules/brush.js`: Existing brush code normalizes selections to pixel rectangles and collects selected bound data. It needs sf-specific centroid checking for `path.geom-sf`.
- `R/d3_zoom.R`: Existing R-side zoom API can inspect `widget$x$ir$layers` before adding zoom config and onRender callbacks.
- `tests/testthat/test-sf-visual.R`: Already creates NC and world sf HTML fixtures and can be extended for single-panel renderer verification.

### Established Patterns
- Interactivity modules use explicit CSS selector arrays rather than broad SVG selectors.
- R interactivity APIs are pipe-composable and mutate `widget$x$interactivity`.
- Widget JavaScript reattaches tooltip/hover/custom handlers after redraw/resize via existing event hooks.
- Optional sf tests use `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")`.
- Visual sf tests write HTML fixtures to project-root `test_output/`.

### Integration Points
- `path.geom-sf` must be added wherever interactive marks are enumerated for tooltip, hover, brush, handlers, legend state, and selected-data collection if applicable.
- `brush.js` should branch sf path selection through `data-cx`/`data-cy` while preserving existing bbox/midpoint behavior for non-sf paths.
- `R/d3_zoom.R` should suppress zoom before adding JS callbacks when `widget$x$ir` contains any layer with `geom == "sf"`.
- Renderer tests should assert stable path class/attributes and use the Phase 32 IR row-id contract.

</code_context>

<specifics>
## Specific Ideas

- Recommended defaults accepted for all selected gray areas.
- The desired implementation posture is conservative: make the existing prototype production-safe for single-panel maps instead of redesigning the sf renderer.
- Tooltips and hover should feel like existing gg2d3 interactions, not like a separate map subsystem.
- Brush behavior should be honest and predictable: centroid containment only, no polygon-overlap or bbox approximation for sf polygons.

</specifics>

<deferred>
## Deferred Ideas

- Shared projection/bbox alignment for multiple sf layers in the same panel — Phase 34.
- Faceted sf map projection and `PANEL` filtering behavior — Phase 34.
- Package-facing documentation, diagnostics vignette updates, and broader browser validation hardening — Phase 35.
- Mixed sf/non-sf zoom behavior — deferred beyond Phase 33 unless a later plan explicitly scopes it.
- Polygon-overlap brushing, tile basemaps, slippy map controls, JavaScript-side CRS reprojection, and large-map performance guarantees remain out of scope for v1.8.

</deferred>

---

*Phase: 33-single-panel-renderer-and-interactivity*
*Context gathered: 2026-05-20*
