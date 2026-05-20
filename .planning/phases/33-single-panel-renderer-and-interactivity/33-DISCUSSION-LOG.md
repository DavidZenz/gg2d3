# Phase 33: Single-Panel Renderer and Interactivity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20T13:23:49Z
**Phase:** 33-single-panel-renderer-and-interactivity
**Areas discussed:** Renderer Hardening, Tooltip and Hover Behavior, Brush Selection, Zoom Suppression

---

## Area Selection

The user selected all proposed gray areas: `1-4`.

| Area | Description | Selected |
|------|-------------|----------|
| Renderer hardening | Existing `sf.js` already renders paths with `geoIdentity`; decide whether to harden the prototype or reshape internals. | ✓ |
| Tooltip and hover behavior | Decide field exposure and hover behavior for `path.geom-sf`. | ✓ |
| Brush selection semantics | Decide how polygon regions are selected and what callback data returns. | ✓ |
| Zoom suppression | Decide how `d3_zoom()` behaves when sf is present. | ✓ |

---

## Renderer Hardening

| Option | Description | Selected |
|--------|-------------|----------|
| Harden existing renderer | Keep `geoIdentity + reflectY + fitExtent`, fix gaps only. Recommended. | ✓ |
| Refactor renderer internals | Extract projection/path helpers now, more structure for Phase 34. | |
| Minimal test-only pass | Mostly validate existing prototype behavior. | |

**User's choice:** Recommendations are fine.
**Notes:** Locking the recommended conservative path: harden the existing single-panel sf renderer.

---

## Tooltip and Hover Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| User data only | Hide internals like geometry helpers, `_geom`, `_centroid`, diagnostics. Recommended. | ✓ |
| All bound row fields | Expose everything currently bound to paths. | |
| Same as other geoms | No sf-specific filtering unless existing tooltip code already filters. | |

**User's choice:** Recommendations are fine.
**Notes:** Locking reuse of existing APIs with user-facing data only; no new sf tooltip API.

---

## Brush Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Centroid-only | Use `data-cx`/`data-cy`; selected row data goes to callbacks/Shiny. Recommended. | ✓ |
| Bounding-box fallback | Centroid first, bbox if centroid missing. | |
| Path bbox selection | Current generic path behavior, less accurate for maps. | |

**User's choice:** Recommendations are fine.
**Notes:** Locking centroid-only selection for sf paths. Missing/invalid centroids should not select rather than falling back to misleading geometry bounds.

---

## Zoom Suppression

| Option | Description | Selected |
|--------|-------------|----------|
| Warn and suppress if any sf layer exists | Leave widget otherwise usable. Recommended. | ✓ |
| Disable only for pure-sf plots | Allow zoom if mixed sf/non-sf layers exist. | |
| Attach zoom but no-op in JS | Defer warning/suppression to browser side. | |

**User's choice:** Recommendations are fine.
**Notes:** Locking R-side warning and suppression when any sf layer is present.

---

## the agent's Discretion

- Exact warning text for sf zoom suppression.
- Exact internal helper names for interactive selector filtering and sf centroid checks.
- Test organization across existing sf renderer, visual, zoom/brush, and interactivity tests.

## Deferred Ideas

- Stacked and faceted sf projection behavior.
- Mixed sf/non-sf zoom behavior.
- Polygon-overlap brushing and slippy map behavior.
