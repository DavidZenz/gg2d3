# Phase 51: Geometry Edge-Case Classification And Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-26
**Phase:** 51-geometry-edge-case-classification-and-polish
**Areas discussed:** Rect/Tile Transform Classification, Polygon Topology Contract, Text/Label Polish Scope, Validation Evidence Shape

---

## Rect/Tile Transform Classification

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-first fixtures | Build transformed rect/tile fixtures, compare ggplot2 built data, IR, and D3 behavior before fixing. | yes |
| Aggressive parity fix | Attempt broad transformed coordinate parity for rect/tile regardless of complexity. | |
| Documentation-only | Do not attempt any fix, only document current behavior. | |

**User's choice:** Accepted recommendation.
**Notes:** Fix only small D3-boundary mismatches. Document larger coordinate-system semantics as non-goals with evidence.

---

## Polygon Topology Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped closed-path contract | Preserve row order and support only topology cases honestly represented by grouped SVG paths. | yes |
| GIS topology repair | Infer holes, repair invalid polygons, and normalize topology automatically. | |
| Leave unclassified | Keep current polygon support without explicit topology evidence. | |

**User's choice:** Accepted recommendation.
**Notes:** Characterize holes, subgroups, and ring order against ggplot2. Document unsupported full topology repair and automatic hole inference.

---

## Text/Label Polish Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Small verified improvement or classify-and-defer | Attempt one low-risk improvement if obvious; otherwise record implementation-ready deferral evidence. | yes |
| Full ggrepel clone | Implement broad collision avoidance and repelling behavior. | |
| Path-following labels | Implement broad path-following annotation support. | |

**User's choice:** Accepted recommendation.
**Notes:** Good candidates include basic `geom_label()` parity or better `hjust`/`vjust`/`angle` handling for `geom_text()`. Full ggrepel and path-following labels remain deferred.

---

## Validation Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Source/IR tests plus optional visual evidence | Test every classified behavior and use browser visual smoke or generated HTML where visual inspection matters. | yes |
| Source tests only | Avoid any browser/visual artifacts. | |
| Mandatory browser visual tests | Require live browser execution for the phase. | |

**User's choice:** Accepted recommendation.
**Notes:** Preserve optional `{sf}` and browser dependency skip behavior. Record pass/skip evidence in `51-VALIDATION.md`.

---

## the agent's Discretion

- Exact fixture names, test-file split, plan boundaries, and validation artifact naming.
- Whether a candidate text/label improvement is small enough to implement or should be deferred with evidence.

## Deferred Ideas

- Full GIS topology repair, automatic hole inference, invalid polygon fixing, and polygon-overlap brushing.
- Full ggrepel-compatible collision avoidance.
- Broad path-following label placement.
- CI-hosted screenshot/perceptual diffs and committed golden images.
