# Phase 34: Stacked and Faceted Projection Alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 34-stacked-and-faceted-projection-alignment
**Areas discussed:** shared projection source, empty/skipped sf rows, facet projection behavior, IR and renderer contract

---

## Shared Projection Source

| Option | Description | Selected |
|--------|-------------|----------|
| Per-layer fit | Keep fitting each sf layer from its own geometries. | |
| Panel union fit | Build one panel bbox from accepted sf features across all sf layers in that panel. | ✓ |
| Include non-sf layers | Let non-sf data influence map projection metadata. | |

**User's choice:** recommendations are fine
**Notes:** Accepted the recommendation to use the union of accepted sf polygon-family features across sf layers, with non-sf layers excluded from projection metadata.

---

## Empty or Skipped sf Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Global fallback | If a panel has no accepted geometries, fall back to a global bbox. | |
| Blank with diagnostics | Render blank for empty sf panels/layers and preserve diagnostics/warnings. | ✓ |
| Error hard | Treat any empty sf panel as a hard IR/rendering error. | |

**User's choice:** recommendations are fine
**Notes:** Accepted the recommendation to avoid global fallback so empty panels do not hide facet leakage or unsupported-geometry filtering bugs.

---

## Facet Projection Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Per-panel fit | Fit each facet panel from only that panel's `PANEL` rows. | ✓ |
| Global fit | Fit all facet panels from all sf rows for comparison. | |
| Scale-dependent fit | Use per-panel only for free scales and global for fixed scales. | |

**User's choice:** recommendations are fine
**Notes:** Accepted the recommendation that both `facet_wrap()` and `facet_grid()` use per-panel sf projection metadata even when facet scales are fixed.

---

## IR and Renderer Contract

| Option | Description | Selected |
|--------|-------------|----------|
| R-owned panel metadata | R computes panel sf bbox/projection metadata and JS passes it into sf renderers. | ✓ |
| JS recomputation | JS recomputes shared panel metadata from all layers on every render. | |
| Layer-local metadata | Each sf layer carries its own fit metadata and the renderer reconciles it. | |

**User's choice:** recommendations are fine
**Notes:** Accepted the recommendation that R owns shared panel metadata, `gg2d3.js` resolves the panel-specific state, and `sf.js` consumes that state instead of fitting each sf layer independently.

---

## the agent's Discretion

- User delegated all four gray areas to the recommended defaults.

## Deferred Ideas

- Global-comparison facet projection mode remains deferred beyond v1.8.
- Polygon-overlap brushing and large-map performance budgets remain deferred.
