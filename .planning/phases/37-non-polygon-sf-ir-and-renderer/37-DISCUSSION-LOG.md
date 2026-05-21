# Phase 37: Non-Polygon sf IR And Renderer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-21T09:41:12Z
**Phase:** 37-non-polygon-sf-ir-and-renderer
**Areas discussed:** SVG mark contract, MULTIPOINT/MULTILINESTRING identity, point and line styling, validation fixtures

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All 4 | Covers rendering contract, multi-geometry identity, aesthetics, and mixed/facet validation before planning. | yes |
| Core only | Discuss just SVG mark contract and point/line renderer behavior, leaving test details to the planner. | |
| Validation only | Focus on fixtures and regression gates because the implementation choices look mostly settled. | |

**User's choice:** `1-4`
**Notes:** User selected all four recommended areas.

---

## SVG Mark Contract

| Option | Description | Selected |
|--------|-------------|----------|
| A | Points render as `circle.geom-sf.geom-sf-point`; lines and polygons render as `path.geom-sf.geom-sf-line/polygon`; all keep shared `.geom-sf`. | yes |
| B | Render every sf family as `path.geom-sf` only, even points. | |
| C | Let planner decide after research. | |

**User's choice:** recommendations are fine
**Notes:** Recommended option accepted.

---

## MULTIPOINT / MULTILINESTRING Identity

| Option | Description | Selected |
|--------|-------------|----------|
| A | Public behavior is one source row; renderer may draw child marks, but callbacks/brush payloads dedupe to the original row. | yes |
| B | Every child coordinate/part becomes its own public interactive item. | |
| C | Only support simple `POINT`/`LINESTRING` now; defer multi-geometries. | |

**User's choice:** recommendations are fine
**Notes:** Recommended option accepted.

---

## Point And Line Styling

| Option | Description | Selected |
|--------|-------------|----------|
| A | Phase 37 locks visible core styling: point size/radius, color/fill/alpha, line color/linewidth/linetype, and line `fill="none"`. | yes |
| B | Minimal: just make points/lines visible, defer most styling parity to Phase 38. | |
| C | Full parity now, including every subtle ggplot2 styling edge case. | |

**User's choice:** recommendations are fine
**Notes:** Recommended option accepted.

---

## Validation Fixtures

| Option | Description | Selected |
|--------|-------------|----------|
| A | Require IR/source/browser-aware fixtures for point-only, line-only, polygon+point, polygon+line, mixed accepted/skipped rows, facets, and empty panels where feasible. | yes |
| B | Keep Phase 37 validation to IR/source tests only; browser coverage waits for Phase 38. | |
| C | Minimal validation: one point fixture and one line fixture only. | |

**User's choice:** recommendations are fine
**Notes:** Recommended option accepted.

---

## the agent's Discretion

- Exact helper names, family-classification internals, and fixture filenames are left to research and planning.
- Research/planning may choose whether multipoint/multiline expansion happens in R IR or in the JS renderer, provided public source-row identity is preserved.

## Deferred Ideas

- `GEOMETRYCOLLECTION`, sf text/labels, basemaps, slippy-map controls, JS CRS reprojection, true geometry-overlap brushing, large-map performance guarantees, and full styling edge-case parity remain out of Phase 37.
