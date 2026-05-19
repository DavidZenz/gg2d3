---
phase: 29
slug: interactivity-design
status: draft
created: 2026-05-19
---

# Phase 29 - Interactivity Design Contract

This phase produces implementation guidance only; it must not modify production R or JavaScript source files.

## INTR-01 - Tooltip and Hover Contract

### Future implementation hooks

Future build work should extend the existing selector-based interactivity model instead of introducing a map-specific tooltip or hover API. Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS` in `inst/htmlwidgets/modules/events.js` so `d3_tooltip()` and `d3_hover()` attach to sf region paths through the same event flow used by other geoms. This covers D-01 and D-02.

| Hook | Future build action | Decision |
|------|---------------------|----------|
| `inst/htmlwidgets/modules/events.js` | Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS` for tooltip, hover, and custom event attachment. | D-02 |
| `inst/htmlwidgets/modules/tooltip.js` | Keep formatting based on the bound row object and existing `ir.aes_by_var` enrichment. | D-01, D-03 |
| `inst/htmlwidgets/modules/geoms/sf.js` | Continue binding one row object to each `path.geom-sf` and keeping `data-row-id` as a join/debug key. | D-03, D-04 |

### Tooltip data flow

`d3_tooltip()` uses the bound row `d` passed to `window.gg2d3.tooltip.show(event, d, config, ir)`. The tooltip source of truth is the row object bound to each `path.geom-sf`, not DOM attributes. `tooltip.js` should continue to prefer `ir.aes_by_var` so tooltip fields use original ggplot mapped variable names when available. This preserves D-01 and D-03.

The expected flow is:

1. User hovers a `path.geom-sf`.
2. `events.js` matches the path through `INTERACTIVE_SELECTORS`.
3. The mouseover handler calls `window.gg2d3.tooltip.show(event, d, config, ir)`.
4. `tooltip.js` formats the bound row `d`, enriches it with `ir.aes_by_var`, and renders the tooltip.

### Hover behavior

`d3_hover()` should reuse the existing hover behavior after `path.geom-sf` is added to the selector list. The same opacity dimming, hovered-element opacity restoration, and optional configured hover stroke/stroke-width rules apply to sf paths. No separate geographic hover state is required for the first build. This implements D-02 without changing the public API.

### Rejected tooltip DOM model

`data-row-id` is only a stable join/debug key for `path.geom-sf`; it is not the primary tooltip source. Tooltip values must not be duplicated into DOM `data-*` attributes. D-04 rejects copying every tooltip-relevant value into attributes because the bound row and `ir.aes_by_var` already provide the canonical tooltip data contract.

## INTR-02 - Brush Selection Semantics

`d3_brush()` should use centroid-based selection semantics for sf regions in the first build. A path.geom-sf region is selected when numeric data-cx and data-cy attributes fall inside the normalized brush pixel rectangle. This is a deliberate region-selection rule, not polygon-overlap or spatial-intersection selection, and preserves D-05 and D-06.

| Approach | Selection rule | Runtime cost | Fit with gg2d3 | Decision |
|----------|----------------|--------------|----------------|----------|
| Centroid inside brush | Select a `path.geom-sf` when its numeric `data-cx` and `data-cy` centroid coordinates are inside the normalized brush pixel rectangle. | O(n) coordinate checks over matched paths. | Reuses the existing pixel-position brush architecture and Phase 28 centroid attributes. | Recommended |
| Polygon overlap / hit-testing | Select a region when any polygon area overlaps the brush rectangle or passes a point-in-polygon/spatial intersection test. | O(n * vertices) or custom spatial indexing, with higher drag-time cost. | Poor first-build fit because gg2d3 brush currently checks element pixel positions, not polygon geometry. | Rejected for first build |
| Disable brush | Do not allow `d3_brush()` to affect `path.geom-sf` regions. | No selection cost. | Too conservative because Phase 28 already emits centroid hooks and linked selection remains valuable. | Rejected |

### Future implementation hooks

`brush.js` should add `'path.geom-sf'` to its module-local `INTERACTIVE_SELECTORS`. Duplicated selector lists remain an accepted current pattern; this update is separate from the `events.js` selector update documented for INTR-01.

Update `isElementInPixelRect()` so `node.matches('path.geom-sf')` prefers `data-cx` and `data-cy` before falling back to bounding-box center behavior for other path geoms. Invalid, missing, or non-numeric centroid attributes should return `false` for sf paths rather than silently selecting by a misleading bounding box. This implements D-08.

### Callback data shape

`collectSelectedData()` should preserve the current callback contract by returning bound row objects for selected sf regions. `d3_brush()` callbacks must not return GeoJSON payloads for sf paths; geometry internals such as `_geom` are implementation details attached to the row for rendering, while the callback shape remains the selected row object. This covers D-07.

## INTR-03 - Zoom Architecture Decision

For the first sf build, d3_zoom() is suppressed for widgets containing sf layers. `R/d3_zoom.R` is the primary guard location because it can prevent broken zoom attachment before `htmlwidgets::onRender()` registers `window.gg2d3.zoom.attach(...)`. The R warning text should be `d3_zoom() is not supported for geom_sf layers yet; zoom was not attached.` This covers D-09 and D-10.

SVG group transform is rejected because it scales stroke widths, which conflicts with gg2d3's existing Cartesian zoom principle of preserving mark stroke widths. The deferred future candidate is projection/path re-rendering: update the map projection and recompute each `path.geom-sf` `d` attribute rather than applying a scaled SVG wrapper. This preserves D-11 and D-12.

`inst/htmlwidgets/modules/zoom.js` may later add a JavaScript fallback guard, but the first-build contract is R-visible suppression through `R/d3_zoom.R` so users are warned at the API call site and no broken zoom state is attached.

## Implementation Hook Checklist

- `inst/htmlwidgets/modules/events.js`: add `'path.geom-sf'` to `INTERACTIVE_SELECTORS` so `d3_tooltip()` and `d3_hover()` attach to sf paths.
- `inst/htmlwidgets/modules/tooltip.js`: keep `format(d, config, ir)` centered on the bound row and `ir.aes_by_var`; do not add sf-specific DOM attribute tooltip parsing.
- `inst/htmlwidgets/modules/brush.js`: add `'path.geom-sf'` to the module-local selector list and update `isElementInPixelRect()` to prefer numeric `data-cx` and `data-cy` for `node.matches('path.geom-sf')`.
- `inst/htmlwidgets/modules/zoom.js`: treat any future sf support as projection/path re-rendering work; do not apply SVG group transform zoom to sf paths.
- `inst/htmlwidgets/modules/geoms/sf.js`: continue binding row objects to paths and emitting `data-row-id`, `data-cx`, and `data-cy` attributes for future interactivity modules.
- `R/d3_zoom.R`: detect sf layers before setting `widget$x$interactivity$zoom`, warn with `d3_zoom() is not supported for geom_sf layers yet; zoom was not attached.`, and return without attaching zoom.

## Decision Traceability

| Decision | Requirement | Status |
|----------|-------------|--------|
| D-01 - Tooltip prioritizes mapped variables through `ir.aes_by_var`. | INTR-01 | Covered |
| D-02 - Hover reuses existing behavior with `path.geom-sf` selectors. | INTR-01 | Covered |
| D-03 - Tooltip content comes from bound row objects; `data-row-id` is not primary tooltip data. | INTR-01 | Covered |
| D-04 - Tooltip values are not duplicated into DOM `data-*` attributes. | INTR-01 | Covered |
| D-05 - Brush selects sf regions by centroid. | INTR-02 | Covered |
| D-06 - Centroid-based selection is documented instead of polygon-overlap selection. | INTR-02 | Covered |
| D-07 - Brush callbacks return bound row objects, not GeoJSON payloads. | INTR-02 | Covered |
| D-08 - `brush.js` prefers `data-cx` and `data-cy` for `path.geom-sf`. | INTR-02 | Covered |
| D-09 - First build suppresses `d3_zoom()` for sf panels. | INTR-03 | Covered |
| D-10 - Zoom suppression is visible from R as a warning. | INTR-03 | Covered |
| D-11 - Map zoom is deferred to projection/path re-rendering. | INTR-03 | Covered |
| D-12 - SVG group transform is rejected because it scales stroke widths. | INTR-03 | Covered |

## Checker Sign-Off

- [ ] INTR-01 covered
- [ ] INTR-02 covered
- [ ] INTR-03 covered
- [ ] D-01 through D-12 covered
- [ ] No production source edits required
- [ ] Map zoom deferred to projection/path re-rendering candidate
