# Phase 29: Interactivity Design - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-18
**Phase:** 29-interactivity-design
**Areas discussed:** Tooltip/hover extension (INTR-01), Brush approach (INTR-02), Zoom architecture (INTR-03)

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Tooltip/hover extension (INTR-01) | Data attributes on path.geom-sf; tooltip content model; label source | ✓ |
| Brush: centroid vs. polygon hit-test (INTR-02) | Pixel-position vs. d3.polygonContains tradeoffs | ✓ |
| Zoom architecture (INTR-03) | Element-repositioning vs. SVG group transform vs. deferral | ✓ |
| Let me draft all three | Skip Q&A, generate CONTEXT from memory + scout | |

**User's choice:** All three areas, interactive.

---

## INTR-01: Tooltip / hover extension

### Q1: Region label source

| Option | Description | Selected |
|--------|-------------|----------|
| First non-geometry column (Recommended) | Auto-pick first non-sfc column; fall back to row index | ✓ |
| User-mapped aesthetic only | Show only what user maps; row index otherwise | |
| Explicit `label` aesthetic required | Force `aes(label = NAME)` | |

**User's choice:** First non-geometry column.
**Notes:** Captured as D-01. Mechanic: `setdiff(names(sf_df), attr(sf_df, "sf_column"))[1]`.

### Q2: data-* attributes on path.geom-sf (multiSelect)

| Option | Description | Selected |
|--------|-------------|----------|
| data-row-id (Recommended) | Row index into layer data frame, lookup pattern | ✓ |
| data-fill / data-color | Resolved aesthetic values as attributes | |
| data-bbox | Pre-computed pixel bbox | |
| data-centroid | Pre-computed projected centroid | (promoted later — required by D-05) |

**User's choice:** `data-row-id` only.
**Notes:** `data-centroid` was added back as load-bearing for INTR-02 brush (D-02, D-05). The other two rejected to keep DOM lean and avoid duplicating aesthetic data that's already in the shared layer table.

---

## INTR-02: Brush selection algorithm

### Q3: Brush algorithm

| Option | Description | Selected |
|--------|-------------|----------|
| Centroid-only, document limitation (Recommended) | Pixel-position test on data-centroid; document that crescent/multi-island regions need brush over centroid | ✓ |
| Centroid first, BBox fallback | Two-pass: centroid then bbox-intersection if zero hits | |
| Polygon hit-test (d3.polygonContains) | Per-region sampled polygon containment | |

**User's choice:** Centroid-only.
**Notes:** Captured as D-05 (algorithm), D-06 (polygon rejection rationale — memory cost, compute cost, UX context), D-07 (documented limitation + deferred mitigation).

---

## INTR-03: Zoom architecture

### Q4: Zoom approach

| Option | Description | Selected |
|--------|-------------|----------|
| SVG group transform + non-scaling-stroke (Recommended) | Wrap sf in `<g class="sf-zoom-layer">`, apply transform; `vector-effect="non-scaling-stroke"` fixes stroke caveat | ✓ |
| Re-project via geoPath on every zoom | Match existing element-repositioning pattern; perf cliff at ~1k features | |
| Explicit deferral — zoom disabled for sf in v1.7 | Document why, punt to later milestone | |

**User's choice:** SVG group transform.
**Notes:** Captured as D-08 (group transform), D-09 (non-scaling-stroke mitigation), D-10 (documented divergence from existing pattern), D-11 (zoom.js integration point — branch on panel containing sf).

---

## Closing question

| Option | Description | Selected |
|--------|-------------|----------|
| Write CONTEXT.md | Finalize | ✓ |
| Revisit an area | Reopen one decision | |

---

## Claude's Discretion

- Splitting the three design docs across plans vs. consolidating into one (planner decides).
- Use of diagrams / DOM snippets in the design docs.

## Deferred Ideas

- Centroid-first + bbox-fallback brush (if centroid-only proves painful in real use).
- Semantic zoom for choropleth (zoom-level-dependent labels / region detail).
- Slippy-map basemap tiles (explicit anti-feature per Phase 30 charter).
- JS-side reprojection (locked out by Phase 27 — R-side `st_transform` to WGS84).
