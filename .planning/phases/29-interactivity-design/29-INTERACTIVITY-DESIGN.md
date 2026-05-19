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
