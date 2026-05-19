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
