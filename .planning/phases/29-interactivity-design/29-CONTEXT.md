# Phase 29: Interactivity Design - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 29 produces **three written design documents** that lock the interactivity extension strategy for `geom_sf` map regions:

- A tooltip/hover extension spec (INTR-01)
- A brush selection algorithm decision with rejection rationale (INTR-02)
- A zoom architecture decision (INTR-03)

**In scope:** design docs detailed enough that a future build phase implements without re-deciding.
**Out of scope:** implementing tooltip/brush/zoom for sf in code. Implementation lands in a later milestone (per ROADMAP v1.7 charter — this milestone is research-only).

</domain>

<decisions>
## Implementation Decisions

### INTR-01: Tooltip / hover extension

- **D-01:** The default tooltip headline (region label) is sourced from the **first non-geometry column** of the layer's sf data frame (e.g., `NAME` for `nc.shp`). If no non-geometry columns exist, fall back to row index. Zero-config for the common case; deterministic.
- **D-02:** Each rendered `<path class="geom-sf">` carries exactly two data attributes:
  - `data-row-id` — integer row index into the layer's data frame. Consumers (tooltip, hover, brush) look up any column on demand via the shared layer-data table that already exists post-Phase 28-01. Keeps DOM lean (one int per path, not embedded JSON).
  - `data-centroid` — projected pixel centroid as `"x,y"`. Required by INTR-02 brush algorithm; cheap to compute once at render time via `d3.geoPath().centroid(feature)` and stash on the element.
- **D-03:** `tooltip.js` and `hover.js` integration is by **registry entry**, not new code paths. Add `'path.geom-sf'` to the same selector lookup the other geoms use; tooltip content resolution reads `data-row-id` and queries the layer table for label + any mapped aesthetics (fill, color).
- **D-04:** No `data-fill` / `data-color` / `data-bbox` on the path. Aesthetic values are looked up via `data-row-id` like every other consumer; bbox is computable via `getBBox()` if ever needed (not on a hot path).

### INTR-02: Brush selection algorithm

- **D-05:** Brush selection for sf regions uses **centroid-only pixel-position testing**. `brush.js` adds `'path.geom-sf'` to `INTERACTIVE_SELECTORS`, reads `data-centroid` from each path, and tests whether the centroid pixel lies within the normalized brush extent — same pattern as the other geoms.
- **D-06:** **Polygon hit-testing is explicitly rejected.** Rationale that must appear in the INTR-02 design doc: (a) memory cost — storing sampled polygon coords for complex multipolygons (e.g., census tracts, coastline-heavy regions) bloats the IR by kilobytes per region; (b) compute cost — re-sampling from path SVG on every brush event, then `d3.polygonContains` over each region's outline, is O(regions × brushPolygonPoints × regionSamples) per event, which breaks 60fps even for moderate region counts; (c) the choropleth UX is dominated by lasso-style "select a cluster of regions" rather than precision selection of a single irregular shape — centroid loss for one large region is recoverable by users via click selection.
- **D-07:** **Document the centroid limitation** in the INTR-02 design doc: regions whose centroid lies outside the brush rectangle are not selected, even when the brush visually intersects the region's body (e.g., crescent-shaped or multi-island regions). Mitigation deferred — if user reports surface, revisit with a centroid-first + bbox-fallback algorithm in a later milestone (logged in Deferred Ideas).

### INTR-03: Zoom architecture

- **D-08:** sf panels use an **SVG group transform** for zoom — wrap all sf paths in `<g class="sf-zoom-layer">` and apply the d3.zoom event's `transform` as the `transform` attribute on the group. 60fps trivially; avoids re-projecting GeoJSON via `d3.geoPath` per wheel tick (the cost cliff that hits at ~1k features).
- **D-09:** Stroke-width scaling caveat is mitigated by setting `vector-effect="non-scaling-stroke"` on each `path.geom-sf` element. Widely supported (all modern browsers); keeps stroke pixel-width constant under transform — matches user expectation for vector graphics.
- **D-10:** This **diverges from the existing element-repositioning pattern** used by `zoom.js` for scatter/bar/rect/text geoms. The INTR-03 design doc must document the divergence and rationale (geoPath re-projection cost) so the build phase doesn't try to retrofit sf into the existing pattern.
- **D-11:** Zoom event integration: the existing `zoom.js` continues to own the d3.zoom behavior on the panel. When a panel contains sf layers, the zoom handler applies the transform to the `.sf-zoom-layer` group instead of recomputing per-element x/y. Axes (if any — sf panels typically suppress them, but `coord_sf(xlim=, ylim=)` may show them) update via the existing axis-rescale path, unchanged.

### Claude's Discretion

- Exact filename and location of the three design docs in `.planning/phases/29-interactivity-design/` (e.g., `29-01-PLAN.md` covering INTR-01/02/03 in one doc, or split per requirement — planner decides based on doc length).
- Inclusion of small ASCII diagrams or example DOM snippets in the design docs for clarity.

### Folded Todos

None — no pending todos in `.planning/todos/pending/`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 29 charter
- `.planning/ROADMAP.md` § "Phase 29: Interactivity Design" — goal, success criteria, INTR-01/02/03 requirement mapping
- `.planning/REQUIREMENTS.md` — INTR-01, INTR-02, INTR-03 requirement statements

### Upstream design constraints (Phase 27 / 28)
- `.planning/phases/27-r-ir-extraction-feasibility/27-02-SUMMARY.md` — sf IR schema (fields: `geometries[]`, `crs`, `geom_type`, `coord.type`, `coord.bbox`) that path elements derive from
- `.planning/phases/28-d3-renderer-prototyping/28-01-SUMMARY.md` — `sf.js` geom renderer module, `row_id` addition (D-02 depends on this), `geoIdentity().reflectY(true).fitExtent()` projection setup
- `.planning/phases/28-d3-renderer-prototyping/28-02-SUMMARY.md` — visual verification of REND-01/02/03; baseline that interactivity layers on top of

### Existing interactivity modules (the integration surface)
- `inst/htmlwidgets/modules/tooltip.js` — tooltip wiring; INTR-01 extends, not replaces
- `inst/htmlwidgets/modules/brush.js` — `INTERACTIVE_SELECTORS` array (line 27ff) is the single point of extension for D-05; `data-brush-active` coordination attribute pattern
- `inst/htmlwidgets/modules/zoom.js` — element-repositioning pattern that INTR-03 explicitly diverges from; the divergence rationale must reference this file
- `inst/htmlwidgets/modules/events.js` — cross-module event coordination (hover skips dimming when brush active, etc.); sf must respect the same protocol
- `inst/htmlwidgets/modules/geoms/sf.js` — Phase 28 renderer that owns path emission; the place where `data-row-id`, `data-centroid`, and `vector-effect="non-scaling-stroke"` will be added in the build phase

### Cross-cutting patterns established in earlier phases (per project memory)
- Pixel-position highlighting (not data-domain inversion) — established in Phase 11 work on categorical scales; underwrites D-05
- DOM-attribute cross-module coordination (`data-brush-active`) — established in Phase 11; sf must continue the pattern, not invent a new one
- Zoom event isolation via `zoom.filter()` — established in `zoom.js`; sf zoom-layer transform respects the same filter

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inst/htmlwidgets/modules/geoms/sf.js` (Phase 28-01) — already emits `<path class="geom-sf">` per feature with `row_id` available. The three INTR additions are: `data-row-id` attribute (rename/promote `row_id`), `data-centroid` attribute (one new line in the path-builder), `vector-effect="non-scaling-stroke"` attribute (one new line).
- `inst/htmlwidgets/modules/brush.js` `INTERACTIVE_SELECTORS` (lines 27–45) — single-line addition of `'path.geom-sf'` enables sf participation in brush. No new selection algorithm code; pixel-position test already exists.
- `inst/htmlwidgets/modules/tooltip.js` — content resolution via row-id lookup pattern. sf joins by adding the selector to the dispatch table; no per-geom branching needed.
- `d3.geoPath().centroid(feature)` — built into d3; centroids are a one-pass computation alongside the `d` attribute that the renderer already produces.

### Established Patterns
- **Lookup-by-row-id over attribute-embedding** — every geom in the codebase uses a sparse `data-row-id` and a shared layer table. INTR-01 follows the pattern, not the alternative of stuffing JSON onto the DOM.
- **Hardcoded selector registries** — brush.js and zoom.js both gate participation on a hardcoded selector list. New geom support = new entry. Predictable; intentional.
- **Element-repositioning zoom for non-projected geoms** — `zoom.js` lines 373ff iterate per-geom and reset x/y. INTR-03 SVG-group-transform is a deliberate exception, not a pattern change.

### Integration Points
- Phase 28's `sf.js` is the single file where path attribute additions land (build phase, not Phase 29).
- `brush.js` line 27 (`INTERACTIVE_SELECTORS`) is where sf participation in brush is enabled.
- `zoom.js` zoom handler gains a branch: if panel has sf layers, route transform to `.sf-zoom-layer` group; otherwise existing element-repositioning loop.

</code_context>

<specifics>
## Specific Ideas

- `vector-effect="non-scaling-stroke"` — explicit SVG attribute, not a CSS rule, so it survives serialization to standalone HTML widgets and pkgdown vignettes.
- The "first non-geometry column" rule for labels: implement as `setdiff(names(sf_df), attr(sf_df, "sf_column"))[1]` on the R side, surface to IR as `default_label_col`.

</specifics>

<deferred>
## Deferred Ideas

- **Centroid-first + bbox-fallback brush** — if users surface the "large region not selected" limitation as painful, revisit with a fallback that runs a cheap bbox-intersection test when centroid misses. Out of scope for v1.7; revisit in a later interactivity milestone.
- **Semantic zoom for choropleth** (e.g., switch label density at zoom levels, swap county→tract resolution) — distinct feature, belongs in its own milestone.
- **Slippy-map basemap tiles under sf layers** — explicit anti-feature per Phase 30 charter; do not implement.
- **JS-side reprojection** — Phase 27 locked R-side `st_transform` to WGS84 before serialization; JS-side projection stays out of scope.

</deferred>

---

*Phase: 29-interactivity-design*
*Context gathered: 2026-05-18*
