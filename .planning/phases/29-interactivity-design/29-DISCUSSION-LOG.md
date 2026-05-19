# Phase 29: Interactivity Design - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-19
**Phase:** 29-interactivity-design
**Areas discussed:** Tooltip and hover contract, Brush selection semantics, Zoom architecture

---

## Tooltip and Hover Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Mapped vars | Show original ggplot mapped variables when available, matching existing tooltip behavior. | yes |
| Aesthetic rows | Show raw IR/aesthetic fields like `fill`, `colour`, `row_id`, and `group`. | |
| Region label first | Require or strongly prefer a label/name field first, then mapped values. | |

**User's choice:** Recommended path via "go".
**Notes:** Tooltip behavior should stay consistent with existing `tooltip.js` `aes_by_var` support.

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse `d3_hover()` | Add `path.geom-sf` to existing selectors, dim non-hovered regions, optionally apply configured stroke. | yes |
| Stroke only | Highlight just the hovered region outline without dimming the rest. | |
| Map-specific hover | Design a separate sf hover behavior with region-specific rules and styling. | |

**User's choice:** Recommended path via "go".
**Notes:** The future build should extend existing behavior, not add a new sf-specific API.

| Option | Description | Selected |
|--------|-------------|----------|
| Bound row + `row_id` | Use bound row as tooltip source, with `data-row-id` as a stable DOM/debug join key. | yes |
| DOM attrs only | Require tooltip fields to be copied onto `data-*` attributes on each path. | |
| Both fully | Keep bound row data and duplicate all tooltip-relevant fields as DOM attributes. | |

**User's choice:** Recommended path via "go".
**Notes:** DOM attributes should not become the primary data transport for tooltips.

---

## Brush Selection Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Centroid inside brush | A region is selected when its stored `data-cx`/`data-cy` falls inside the brush rectangle. | yes |
| Any polygon overlap | A region is selected when any part of its polygon overlaps the brush rectangle. | |
| Disabled for sf | Brush is documented as unsupported for map regions. | |

**User's choice:** Recommended path via "go".
**Notes:** This matches Phase 28's centroid prep and the existing pixel-rectangle brush architecture.

| Option | Description | Selected |
|--------|-------------|----------|
| Document clearly | Say brush selection is centroid-based, not spatial-overlap selection. | yes |
| Quiet behavior | Implement centroid selection but do not emphasize the limitation. | |
| Warn at runtime | Show a console warning whenever brush is attached to sf. | |

**User's choice:** Recommended path via "go".
**Notes:** The limitation should be visible in docs rather than noisy at runtime.

| Option | Description | Selected |
|--------|-------------|----------|
| Existing bound rows | Selected sf regions return the same row objects as other geoms. | yes |
| Row IDs only | Callbacks receive stable IDs and downstream code looks up data. | |
| GeoJSON included | Callbacks include geometry payloads too. | |

**User's choice:** Recommended path via "go".
**Notes:** Returning GeoJSON would bloat callback data and diverge from existing interactivity behavior.

---

## Zoom Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Suppress for now | Detect sf panels, do not attach Cartesian zoom, and document this as a deliberate first-build limitation. | yes |
| SVG group transform | Zoom/pan the sf path group with `transform`, accepting that stroke widths scale. | |
| Projection re-render | Store projection/path generator and recompute every path's `d` during zoom. | |

**User's choice:** Recommended path via "Go".
**Notes:** Suppression avoids a broken Cartesian zoom path while leaving room for real map zoom later.

| Option | Description | Selected |
|--------|-------------|----------|
| R-side warning | `d3_zoom()` warns when attached to a widget containing `geom_sf`. | yes |
| Silent no-op | Skip zoom without user-facing noise. | |
| Browser console warning | Only warn in JS when rendering. | |

**User's choice:** Recommended path via "Go".
**Notes:** R-side warning catches the issue where users compose the widget.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit deferral | First build skips map zoom; future candidate is projection re-render. | yes |
| Hard anti-feature | Say gg2d3 will not support map zoom. | |
| Research spike required | Block planning until SVG-transform vs re-render is tested. | |

**User's choice:** Recommended path via "Go".
**Notes:** Projection re-render is the favored future approach; SVG transform is not preferred because it scales strokes.

---

## the agent's Discretion

- Exact warning text for zoom suppression.
- Exact documentation location for centroid-brush semantics.
- Whether selector-list duplication is cleaned up during a future refactor.

## Deferred Ideas

- Map-specific zoom/pan via projection re-rendering.
- Polygon-overlap or point-in-polygon brush selection.
- Tile/slippy-map behavior.
