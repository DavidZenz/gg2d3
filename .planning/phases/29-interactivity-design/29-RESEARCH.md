# Phase 29: Interactivity Design — Research

**Researched:** 2026-05-18
**Domain:** Design-documentation phase for `geom_sf` interactivity extension (tooltip/hover, brush, zoom)
**Confidence:** HIGH (design decisions locked in CONTEXT.md; integration surface fully verified in code)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**INTR-01 (Tooltip / hover extension):**
- **D-01:** Default tooltip headline (region label) sourced from the **first non-geometry column** of the layer's sf data frame (e.g., `NAME` for `nc.shp`). Fall back to row index if no non-geometry columns exist. Zero-config; deterministic.
- **D-02:** Each rendered `<path class="geom-sf">` carries exactly two data attributes:
  - `data-row-id` — integer row index into the layer's data frame.
  - `data-centroid` — projected pixel centroid as `"x,y"`.
- **D-03:** `tooltip.js` and `hover.js` integration is by **registry entry**, not new code paths. Add `'path.geom-sf'` to the same selector lookup the other geoms use.
- **D-04:** No `data-fill` / `data-color` / `data-bbox` on the path. Aesthetic values are looked up via `data-row-id`.

**INTR-02 (Brush selection algorithm):**
- **D-05:** Brush selection for sf regions uses **centroid-only pixel-position testing**. `brush.js` adds `'path.geom-sf'` to `INTERACTIVE_SELECTORS`, reads `data-centroid` from each path, tests whether the centroid pixel lies within the normalized brush extent.
- **D-06:** **Polygon hit-testing is explicitly rejected.** Required rationale in INTR-02 design doc: (a) memory cost of sampled polygon coords; (b) compute cost of re-sampling + `d3.polygonContains` per brush event breaks 60fps; (c) choropleth UX is lasso-style cluster selection, not precision selection.
- **D-07:** **Document the centroid limitation:** regions whose centroid lies outside the brush rectangle are not selected even when the brush visually intersects the region body. Mitigation deferred.

**INTR-03 (Zoom architecture):**
- **D-08:** sf panels use an **SVG group transform** for zoom — wrap all sf paths in `<g class="sf-zoom-layer">` and apply the d3.zoom event's transform as the `transform` attribute on the group.
- **D-09:** Stroke-width scaling mitigated by `vector-effect="non-scaling-stroke"` on each `path.geom-sf` element.
- **D-10:** This **diverges from the existing element-repositioning pattern** used by `zoom.js`. INTR-03 design doc must document the divergence and rationale (geoPath re-projection cost).
- **D-11:** Zoom event integration: existing `zoom.js` continues to own the d3.zoom behavior on the panel; when a panel contains sf layers, the handler applies the transform to `.sf-zoom-layer` instead of recomputing per-element x/y. Axes (if present via `coord_sf(xlim=, ylim=)`) update via the existing axis-rescale path.

### Claude's Discretion
- Exact filename and location of the three design docs in `.planning/phases/29-interactivity-design/` (one combined doc covering INTR-01/02/03, or split per requirement — planner decides based on doc length).
- Inclusion of small ASCII diagrams or example DOM snippets in the design docs for clarity.

### Deferred Ideas (OUT OF SCOPE)
- **Centroid-first + bbox-fallback brush** — defer to later milestone.
- **Semantic zoom for choropleth** — distinct feature, own milestone.
- **Slippy-map basemap tiles under sf layers** — explicit anti-feature.
- **JS-side reprojection** — R-side `st_transform` to WGS84 stays locked.
- **Implementation code** — Phase 29 is design only; build lands in v1.8+ (IMPL-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTR-01 | Document hover/tooltip extension strategy for `path.geom-sf` elements | §"Integration Surface — Tooltip & Hover" maps locked decisions D-01..D-04 to the exact selector arrays, R API, and `format()` lookup path that the design doc must specify. |
| INTR-02 | Evaluate brush selection approach (centroid-based vs polygon hit-testing) | §"Integration Surface — Brush" plus §"Centroid vs Polygon Hit-Test Comparison Matrix" — provides the comparison table the design doc renders, anchored in the existing `isElementInPixelRect()` pattern. |
| INTR-03 | Determine zoom architecture for sf panels | §"Integration Surface — Zoom" plus §"Zoom Architecture Divergence Rationale" — documents the existing element-repositioning loop (`zoom.js` lines 365–494) that INTR-03 explicitly does NOT follow, with the geoPath re-projection cost evidence required by D-10. |
</phase_requirements>

## Summary

Phase 29 produces **three written design documents** locking the interactivity strategy for `geom_sf` map regions. It produces **no implementation code** — that lands in a v1.8+ build milestone (IMPL-04). The CONTEXT.md has fully locked all eleven design decisions (D-01..D-11) ahead of planning, so this research is overwhelmingly about **verifying the integration surface in existing code** and surfacing the **one critical inconsistency** the planner must address.

The existing interactivity infrastructure is well-factored. `events.js`, `brush.js`, and `tooltip.js` all gate participation on a single `INTERACTIVE_SELECTORS` array — adding `geom_sf` requires only one new entry per file plus an attribute-emission tweak in `sf.js`. The harder design decisions are around **what to write in the design docs**, not what code to design: each doc must include the rejected alternative's rationale (centroid vs polygon hit-test; SVG-transform vs element-repositioning) at sufficient depth that a future build phase developer doesn't relitigate them.

**Primary recommendation:** Plan a single combined design document (`29-01-PLAN.md` → `29-01-SF-INTERACTIVITY-DESIGN.md` or similar) covering INTR-01/02/03. The three requirements are tightly coupled (D-02's `data-centroid` is consumed by D-05's brush algorithm; D-08's zoom-layer wraps the same paths D-03 selects on), and splitting them risks duplication of the shared DOM/attribute spec. However, the planner must explicitly flag the **`data-cx` / `data-cy` vs `data-centroid` inconsistency** described below as a Phase 29 deliverable to resolve in the design doc itself.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| sf path attribute emission (data-row-id, data-centroid, vector-effect) | Browser / D3 (`inst/htmlwidgets/modules/geoms/sf.js`) | — | Renderer owns DOM creation; attributes encode information the interactivity modules consume. |
| Tooltip content resolution | Browser / D3 (`inst/htmlwidgets/modules/tooltip.js` + `events.js`) | R API (`R/d3_tooltip.R` for default-label config plumbing) | Content rendered client-side from layer data table; R surface only chooses defaults and serializes config. |
| Centroid-based brush selection | Browser / D3 (`inst/htmlwidgets/modules/brush.js`) | — | Pixel-position test runs entirely in the browser using `data-centroid` already on the DOM. |
| Zoom transform on sf paths | Browser / D3 (`inst/htmlwidgets/modules/zoom.js`) | — | SVG group transform is a browser-side rendering optimization; no R-side change. |
| sf data flowing to JS | R IR builder (`R/as_d3_ir.R`) | — | Already complete in Phase 28; the `row_id` field added to sf IR rows is the join key D-04 depends on. |
| Documenting design decisions | Planning artifact (markdown) | — | This phase produces docs, not code. |

[VERIFIED: codebase grep] All Browser-tier files exist at the listed paths; R-tier API exists at `R/d3_tooltip.R` and `R/d3_hover.R`.

## Standard Stack

### Core (already in repo — no new dependencies for Phase 29 design docs)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| d3 | v7 (vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`) | Projection (`d3.geoIdentity`), path generation (`d3.geoPath`), centroid (`pathGen.centroid()`), brush (`d3.brush`), zoom (`d3.zoom`) | Already the rendering substrate; v7 is current major. |

### Build-phase additions (NOT installed in Phase 29 — listed for design-doc context)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| (none) | All required D3 modules are bundled in `d3.v7.min.js` (d3-geo, d3-brush, d3-zoom, d3-selection). | No new vendoring needed for INTR-01/02/03. |

[VERIFIED: `inst/htmlwidgets/lib/d3/d3.v7.min.js` is bundled; d3-geo's `geoIdentity().fitExtent()` and `geoPath().centroid()` already used by `sf.js` (Phase 28).]

**Installation:** N/A. Phase 29 produces markdown only.

**Version verification:** Not applicable for design phase. `d3.v7.min.js` is already vendored.

## Architecture Patterns

### System Architecture — sf Interactivity Data Flow

```
                      ┌──────────────────────────────────────┐
                      │ R-side IR build (R/as_d3_ir.R)       │
                      │  • sf branch adds row_id to df       │  ← Phase 28 done
                      │  • emits geometries[] + data[]       │
                      └──────────────┬───────────────────────┘
                                     │  IR (JSON) via htmlwidgets
                                     ▼
                      ┌──────────────────────────────────────┐
                      │ sf.js renderer (modules/geoms/sf.js) │
                      │  geoIdentity().reflectY().fitExtent()│
                      │  pathGen.centroid() per feature      │
                      │  emit <path class="geom-sf">         │
                      │   • data-row-id (D-04)               │  ← TWEAK in build phase
                      │   • data-centroid="x,y" (D-02)       │  ← (Phase 29 specifies, build phase implements)
                      │   • vector-effect=non-scaling-stroke │
                      │  wrap in <g class="sf-zoom-layer">   │
                      └─────┬───────────┬─────────────┬──────┘
                            │           │             │
                ┌───────────▼──┐  ┌─────▼─────┐  ┌────▼──────────┐
                │ events.js    │  │ brush.js  │  │ zoom.js       │
                │ tooltip.js   │  │ INTER...  │  │ if has sf →   │
                │  add         │  │  add      │  │ transform     │
                │ 'path.geom-  │  │ 'path.    │  │  .sf-zoom-    │
                │  sf' to      │  │  geom-sf' │  │  layer        │
                │  selector    │  │ read      │  │ else → exist- │
                │  array (D-03)│  │ data-     │  │  ing element- │
                │              │  │ centroid  │  │  repositioning│
                │              │  │ (D-05)    │  │  loop         │
                └──────────────┘  └───────────┘  └───────────────┘
                                                 (D-08, D-10, D-11)
```

[VERIFIED: data flow follows the pattern established by existing geoms; the three module files contain the exact `INTERACTIVE_SELECTORS` arrays referenced.]

### Component Responsibilities

| Component | Path | Responsibility |
|-----------|------|----------------|
| sf IR branch | `R/as_d3_ir.R` (sf branch, Phase 27/28) | Emit `geometries[]`, `data[]` with `row_id`, `coord.bbox`. **No change in Phase 29.** Build phase will add `default_label_col` (D-01) per `<specifics>` in CONTEXT. |
| sf renderer | `inst/htmlwidgets/modules/geoms/sf.js` | Emit `<path class="geom-sf">` with `data-cx`/`data-cy`/`data-row-id` **today**; design doc INTR-01 specifies switching to `data-centroid="x,y"` and adding `vector-effect="non-scaling-stroke"` + zoom-layer group wrapper. |
| Tooltip module | `inst/htmlwidgets/modules/tooltip.js` | Singleton tooltip; `format(d, config, ir)` resolves content from row data + `ir.aes_by_var`. **No new code paths.** |
| Events module | `inst/htmlwidgets/modules/events.js` | `INTERACTIVE_SELECTORS` array (lines 23–43) dispatches `mouseover.tooltip`, `mouseover.hover`, etc. Add `'path.geom-sf'` to enable. |
| Brush module | `inst/htmlwidgets/modules/brush.js` | `INTERACTIVE_SELECTORS` array (lines 29–49) drives `highlightSelection()` and `collectSelectedData()`. `isElementInPixelRect()` (lines 259–319) per-tag dispatcher — `path` branch today uses `getBBox()` center; sf override reads `data-centroid` instead. |
| Zoom module | `inst/htmlwidgets/modules/zoom.js` | `zoomed()` handler (line 126) currently calls `geomRegistry.updateGeoms()` (element repositioning). Design doc INTR-03 specifies new branch: if panel contains `.sf-zoom-layer`, apply `event.transform` to it; otherwise existing path. |
| R API surface | `R/d3_tooltip.R`, `R/d3_hover.R` | Pipe-friendly config setters. **No new signature** required for INTR-01 — adding `geom_sf` is transparent at the API level. |

### Recommended File Layout (for Phase 29 output)
```
.planning/phases/29-interactivity-design/
├── 29-CONTEXT.md                          # exists
├── 29-DISCUSSION-LOG.md                   # exists
├── 29-RESEARCH.md                         # this file
├── 29-01-PLAN.md                          # planner creates
└── 29-01-SF-INTERACTIVITY-DESIGN.md       # the deliverable (or split per req)
```

Planner discretion (per CONTEXT): may split into `29-01-TOOLTIP-DESIGN.md`, `29-02-BRUSH-DESIGN.md`, `29-03-ZOOM-DESIGN.md` if combined doc would exceed ~600 lines.

### Pattern 1: Selector-Registry Extension
**What:** Each interactivity module (`events.js`, `brush.js`) gates participation on a hardcoded `INTERACTIVE_SELECTORS` array. New geom support = one new string entry.
**When to use:** Always, for any new geom that needs tooltip/hover/brush.
**Example (from `inst/htmlwidgets/modules/brush.js` lines 29–49):**
```javascript
var INTERACTIVE_SELECTORS = [
  'circle.geom-point',
  'rect.geom-bar',
  // ... existing geoms ...
  'circle.pointrange-point'
  // INTR-01/02 build phase adds: 'path.geom-sf'
];
```
[VERIFIED: file:inst/htmlwidgets/modules/brush.js lines 29–49 and inst/htmlwidgets/modules/events.js lines 23–43.]

### Pattern 2: Row-ID Lookup over Attribute Embedding
**What:** Every geom emits a sparse `data-row-id`; tooltip/hover resolve full row data by looking up in the bound D3 datum (or, for sf, in `layer.data[row_id]`).
**When to use:** Always; never stuff JSON onto DOM attributes.
**Example (from `inst/htmlwidgets/modules/geoms/sf.js` line 105):**
```javascript
.attr("data-row-id", function(d) {
  return d.row_id != null ? d.row_id : null;
});
```
[VERIFIED: file:inst/htmlwidgets/modules/geoms/sf.js line 105.]

### Pattern 3: Pixel-Position Selection Testing
**What:** Brush selection uses element pixel positions (cx/cy, x/y/width/height) rather than data-domain inversion. Avoids categorical-scale failures documented in project MEMORY.md.
**When to use:** Any geom participating in brush; centroids serve the same role for sf as `cx`/`cy` for points.
**Example (from `inst/htmlwidgets/modules/brush.js` lines 262–268):**
```javascript
if (tagName === 'circle') {
  var cx = parseFloat(node.getAttribute('cx'));
  var cy = parseFloat(node.getAttribute('cy'));
  return cx >= rect.px0 && cx <= rect.px1 &&
         cy >= rect.py0 && cy <= rect.py1;
}
```
For sf, the analogous code reads `data-centroid`, splits on `","`, parses two floats, tests against `rect`. [VERIFIED: file:inst/htmlwidgets/modules/brush.js lines 262–268.]

### Anti-Patterns to Avoid
- **Per-geom branching inside `format()` / `attachTooltips()`** — these are dispatch tables; new geoms add an array entry, not a switch case. The locked D-03 explicitly forbids new code paths.
- **JSON-embedded DOM attributes** — `data-properties='{...}'` pattern is rejected (D-04). DOM stays lean; row data lives in the JS-side layer table.
- **Re-projecting GeoJSON via `d3.geoPath` per zoom event** — explicit anti-pattern per D-08; the cost cliff at ~1k features breaks the 60fps target.
- **Inverting brush pixel rect to data domain for selection logic** — locked-out by Pattern 3; only used for Shiny callback output (`invertSelection()` in `brush.js` lines 324–364).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Polygon centroid computation | Custom polygon area + weighted vertex average | `d3.geoPath().centroid(feature)` (already in use, `sf.js` line 65) | Handles spherical, planar, multi-polygon, holes correctly; one line. |
| Brush pixel-rect intersection | Custom `pointInRect()` helper | Existing `isElementInPixelRect()` dispatcher in `brush.js` lines 259–319 | Already handles five tag types correctly; sf only needs one new branch. |
| Tooltip positioning | Custom edge-detection | `window.gg2d3.tooltip.position()` (`tooltip.js` lines 336–365) | Viewport-aware with flip-on-overflow already implemented. |
| sf-specific zoom transform math | Custom scale + translate matrix builder | `d3.zoomTransform` (event.transform.toString()) applied directly as SVG `transform` attribute | D3 zoom emits a `d3.ZoomTransform` whose `toString()` is a valid SVG transform; one assignment. |
| "First non-geometry column" detection (D-01) | Custom column-filter loop | R-side `setdiff(names(sf_df), attr(sf_df, "sf_column"))[1]` per `<specifics>` in CONTEXT | One-liner using sf's own attribute convention. |

**Key insight:** Phase 29 deliverable is a *design doc*, not code. The "don't hand-roll" guidance flows into the build-phase implementation (IMPL-04), but the design doc should still call out the recommended primitives so the future implementer doesn't reinvent.

## Centroid vs Polygon Hit-Test Comparison Matrix

> The INTR-02 design doc must include a rigorous comparison. Below is the evidence/structure the planner should require the doc to render.

| Dimension | Centroid (chosen, D-05) | Polygon hit-test (rejected, D-06) |
|-----------|-------------------------|------------------------------------|
| Storage per region | 2 floats in `data-centroid` (~12 bytes) | Sampled boundary array (~50–500 points × 2 floats) = 0.4–4 KB per region, often more for coastline-heavy MULTIPOLYGON |
| Per-brush-event compute | O(regions): one point-in-rect test per centroid (~5 µs/region) | O(regions × brush corners) for AABB pre-filter + O(regions × sample-points) for `d3.polygonContains` per hit; tens of ms at 1k regions = sub-60fps |
| Implementation surface | One new branch in `isElementInPixelRect()`; ~5 LOC | New polygon-sampling pass at render time; new dispatch in `isElementInPixelRect()`; possibly a Web Worker to keep main thread free at high region counts |
| UX failure mode | Crescent-shaped or multi-island regions whose centroid lies outside brush body are missed (D-07) | None for selection accuracy; but laggy brushing UX **is** a failure mode for choropleth scale |
| Recovery path | Click-to-select individual region; or future bbox-fallback (Deferred) | N/A |
| Precedent in repo | Matches `circle.geom-point` (cx/cy point-in-rect) — established pattern | Would be the **only** geom doing polygon-sampled hit-testing |

[VERIFIED: Storage and compute estimates derived from existing `sf.js` (12 bytes per centroid is precise) and known O() complexity of `d3.polygonContains`. The "tens of ms at 1k regions" figure is order-of-magnitude estimate consistent with established D3 perf data.] [ASSUMED for the specific 5 µs/region figure — actual depends on JS engine; the design doc should not commit to a precise µs figure unless benchmarked.]

## Zoom Architecture Divergence Rationale

> Required content for the INTR-03 design doc (per D-10). Anchors below give the planner the concrete evidence to cite.

**Current pattern (every non-sf geom, `zoom.js` lines 365–494):**
For each zoom event, iterate over each geom selector, read bound datum `d`, recompute `cx`/`cy` (or x/y/width/height, or path `d` attribute for line/area) using the new zoom-rescaled scales. Each geom type gets its own update branch in `repositionElements()`.

**Why sf cannot reuse this pattern:**
1. **No equivalent of `xScale(d.x)`** — sf path geometry is GeoJSON, projected through `d3.geoIdentity().reflectY(true).fitExtent()`. To "reposition" under zoom, you must rebuild the projection with the zoomed bbox and re-run `pathGen()` per feature. For MULTIPOLYGON with thousands of vertices, this is hundreds of milliseconds per wheel tick.
2. **The geoPath's `fitExtent` is bbox-driven, not transform-driven** — there is no `geoPath.rescale(zoomTransform)` analog to `transform.rescaleX(scale)`.
3. **SVG group transform is free at the GPU level** — browsers composite transformed SVG groups via the same path as CSS transforms; cost is independent of feature count.

**Stroke-width caveat and mitigation (D-09):**
- Default SVG behavior: a group transform scales stroke-width along with geometry. At 4× zoom, a 0.5px stroke becomes 2px — visually wrong for cartographic line work.
- `vector-effect="non-scaling-stroke"` is a presentation attribute on `<path>` that instructs the renderer to keep stroke-width in screen pixels regardless of any ancestor transform.
- **Support:** All evergreen browsers (Chrome, Firefox, Safari, Edge). [CITED: MDN — SVG vector-effect attribute, https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vector-effect — supported across all browsers since 2014.]
- **Serialization:** As a presentation attribute (not a CSS rule), it survives `htmlwidgets::saveWidget(selfcontained=TRUE)` and pkgdown vignette serialization. Required for the gh-pages "Get started" article example (DOCS-02 context).

**Axes under sf zoom:**
- sf panels typically suppress axes (`coord_sf` default), in which case axis update is a no-op.
- When `coord_sf(xlim=, ylim=)` shows axes, the existing axis-rescale path in `zoom.js` (`updateAxes()` lines 189–242) works unchanged — it operates on the panel's xScale/yScale, which remain valid because the SVG transform doesn't invalidate the scale domain.

**Brush coordination:**
- Existing `clearBrush()` (line 352) runs on every zoom event. sf inherits this for free.
- Future caveat (note in design doc): brush extents are in panel pixel space; after a zoom transform on `.sf-zoom-layer`, the centroid pixel positions of sf paths are still measured in untransformed space. The brush still operates correctly because `data-centroid` is the pre-transform pixel position, and the brush rect is also in pre-transform pixel space. If a user expects "brush after zoom" to select what's visually under the rect, that's a UX question to flag for the design doc (not a Phase 29 implementation gap).

## Critical Inconsistency for Planner to Resolve

**Issue:** CONTEXT.md D-02 specifies a single `data-centroid="x,y"` attribute. The existing Phase 28 `sf.js` (lines 99–104) emits **two separate attributes** `data-cx` and `data-cy`.

**Evidence:**
- CONTEXT.md line 27: `data-centroid` — projected pixel centroid as `"x,y"`.
- `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104:
  ```javascript
  .attr("data-cx", function(d) { return isFinite(d._centroid[0]) ? d._centroid[0] : null; })
  .attr("data-cy", function(d) { return isFinite(d._centroid[1]) ? d._centroid[1] : null; })
  ```
- Phase 28-01-SUMMARY.md confirms: "Writes `data-cx`/`data-cy` centroid attributes with `isFinite()` guard (D-11, Phase 29 prep)".
- STATE.md "Accumulated Decisions" line 64: "store centroids as `data-cx`/`data-cy` on path elements in Phase 28".

**What the planner must do:**
The Phase 29 deliverable is a design doc, so this is **not a code change in Phase 29** — but the design doc must make a deliberate decision and document it explicitly:

1. **Option A (recommended):** Spec D-02 as written in CONTEXT.md (single `data-centroid="x,y"`) and explicitly note in the design doc that the build phase (IMPL-04) will rename `data-cx`/`data-cy` → `data-centroid`. Justify: matches the locked decision; one attribute read per region in brush.js is marginally faster than two.
2. **Option B:** Override D-02 with the existing `data-cx`/`data-cy` convention. Justify: zero build-phase migration; two attributes already exist; brush reads two `parseFloat()` calls instead of one `split(',')`. Requires updating CONTEXT.md decision.

**Recommendation for the planner:** Treat this as a Phase 29 design-doc deliverable. The design doc must pick one and document the rationale. If it picks Option A, the design doc also documents the build-phase rename. The planner SHOULD NOT silently spec one or the other without acknowledging the discrepancy.

[VERIFIED: file:inst/htmlwidgets/modules/geoms/sf.js lines 99–104; file:.planning/phases/28-d3-renderer-prototyping/28-01-SUMMARY.md line ~57; file:.planning/STATE.md line 64.]

## Common Pitfalls

### Pitfall 1: Design doc writes "implementation TBD" for any locked decision
**What goes wrong:** Future build-phase developer re-opens the decision.
**Why it happens:** Researcher/planner under-specifies on the assumption that the build phase will "figure it out."
**How to avoid:** Every D-01..D-11 decision in CONTEXT.md must have a corresponding spec-level statement in the design doc with enough detail that no further design work is needed. For example, D-01 must specify the exact R code path (`setdiff(names(sf_df), attr(sf_df, "sf_column"))[1]`), the IR field name (`default_label_col`), and the fallback behavior (row index, formatted as `"Region N"` or similar).
**Warning signs:** Phrases like "implementer decides", "TBD", "see Phase X build doc."

### Pitfall 2: Design doc omits the rejection rationale for INTR-02
**What goes wrong:** Future contributor implements polygon hit-testing as an "optimization," breaking the established UX trade-off.
**Why it happens:** Rejection rationales feel like negative documentation and get dropped.
**How to avoid:** INTR-02 design doc MUST include the comparison matrix (above) verbatim, with the memory/compute/UX columns. D-06 is explicit that the rationale must appear in the doc.
**Warning signs:** Reviewer says "this just says do centroid — why?"

### Pitfall 3: Design doc treats `vector-effect` as a CSS rule
**What goes wrong:** Rendered SVG works in the browser but fails in saved standalone HTML (pkgdown vignette).
**Why it happens:** Confusing the SVG presentation attribute with the equivalent CSS property.
**How to avoid:** Spec MUST say "presentation attribute on each `<path>`", not "CSS class on the zoom layer." Per `<specifics>` in CONTEXT line 109.
**Warning signs:** Spec mentions a `.geom-sf { vector-effect: ... }` style block.

### Pitfall 4: Brush coordinate-space confusion under zoom
**What goes wrong:** After SVG group transform, brush rect coordinates and `data-centroid` values are in different reference frames; selection appears off.
**Why it happens:** Two coordinate systems (pre-transform panel-pixel, post-transform screen-pixel) coexist.
**How to avoid:** Design doc must explicitly state that both `data-centroid` AND brush rect remain in **pre-transform panel pixel coordinates**. If the user wants "WYSIWYG brush after zoom," that's a deferred enhancement (note in Deferred Ideas if not already there).
**Warning signs:** Spec mentions inverting the zoom transform inside the brush handler.

### Pitfall 5: Tooltip default label rule applied to non-sf layers
**What goes wrong:** D-01's "first non-geometry column" rule accidentally affects all geom tooltips.
**Why it happens:** Implementer puts the rule in a shared code path instead of the sf-specific tooltip dispatch.
**How to avoid:** Design doc must specify that D-01's default-label resolution only fires when the matched selector is `path.geom-sf` (or equivalently, when `ir.layers[i].geom_type === 'sf'`).
**Warning signs:** R-side code adds `default_label_col` to the IR root rather than to the sf layer descriptor.

## Code Examples

> These are reference patterns the design doc should embed as illustrative DOM/code snippets. Marked as design intent, not Phase 29 commits.

### Expected DOM after build-phase implementation (illustrative)
```html
<g class="panel panel-0" transform="translate(60,30)">
  <rect width="500" height="400" fill="white"/>
  <g class="sf-zoom-layer">                           <!-- D-08 -->
    <g class="geom-sf-group">
      <path class="geom-sf"
            d="M..."
            fill="#deebf7" stroke="#08519c" stroke-width="0.5"
            fill-rule="evenodd"
            vector-effect="non-scaling-stroke"        <!-- D-09 -->
            data-row-id="0"                            <!-- D-02 -->
            data-centroid="123.4,256.7"/>              <!-- D-02; resolves the Critical Inconsistency above -->
      <!-- ... more paths ... -->
    </g>
  </g>
  <g class="brush-overlay"><!-- d3.brush --></g>
  <!-- axes group (typically empty for coord_sf) -->
</g>
```

### Brush selector array addition (illustrative, NOT applied in Phase 29)
```javascript
// inst/htmlwidgets/modules/brush.js INTERACTIVE_SELECTORS — IMPL-04 adds:
'path.geom-sf'

// inst/htmlwidgets/modules/brush.js isElementInPixelRect() — IMPL-04 adds a sf-first branch:
if (tagName === 'path' && node.classList.contains('geom-sf')) {
  var c = node.getAttribute('data-centroid');
  if (!c) return false;
  var parts = c.split(',');
  var cx = parseFloat(parts[0]);
  var cy = parseFloat(parts[1]);
  return cx >= rect.px0 && cx <= rect.px1 &&
         cy >= rect.py0 && cy <= rect.py1;
}
// falls through to existing path-bbox branch for non-sf paths (geom-line, etc.)
```

### Zoom handler branch (illustrative, NOT applied in Phase 29)
```javascript
// inst/htmlwidgets/modules/zoom.js zoomed() — IMPL-04 adds:
function zoomed(event) {
  var transform = event.transform;
  clearBrush(panelGroup);

  // NEW: sf branch (D-08, D-11)
  var sfLayer = panelGroup.select('.sf-zoom-layer');
  if (!sfLayer.empty()) {
    sfLayer.attr('transform', transform.toString());
  }

  // Existing path: rescale + reposition non-sf geoms (unchanged)
  if (canZoomX && ...) { xScaleCurrent = transform.rescaleX(xScaleOriginal); }
  if (canZoomY && ...) { yScaleCurrent = transform.rescaleY(yScaleOriginal); }
  window.gg2d3.geomRegistry.updateGeoms(panelGroup, xScaleCurrent, yScaleCurrent, { flip: flip });
  updateAxes(...);  // axes still update if coord_sf shows them
}
```

[VERIFIED: snippets follow existing patterns in `zoom.js` and `brush.js`; serve as reference for the build phase, not for Phase 29 to commit.]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `data-cx` + `data-cy` separate (Phase 28) | `data-centroid="x,y"` single (D-02, Phase 29) | Phase 29 design doc | Build-phase rename required; one attr instead of two. **Resolution required — see Critical Inconsistency.** |
| Element-repositioning for all geoms (Phase 11) | SVG group transform for sf only (D-08) | Phase 29 design doc | Deliberate divergence; not a regression. INTR-03 must document. |
| No interactivity on `geom_sf` (Phase 28) | Tooltip + hover + centroid-brush + group-transform-zoom (Phase 29 design → IMPL-04 build) | Phase 29 (design) | Establishes the integration; build phase implements. |

**Deprecated/outdated:** None in this scope.

## Project Constraints (from CLAUDE.md)

| Constraint | Source | Phase 29 relevance |
|------------|--------|--------------------|
| Three-layer pipeline: R IR → JSON → D3 JS | CLAUDE.md "Architecture" | Design doc must respect tier boundaries; no JS-side reprojection or R-side rendering logic. |
| Key file `inst/htmlwidgets/gg2d3.js` is the D3 rendering engine; module files in `inst/htmlwidgets/modules/` | CLAUDE.md "Key Files" | All build-phase changes specified in design doc must land in these paths. |
| Tests live in `tests/testthat/` | CLAUDE.md "Development Commands" | If Phase 29 plans any verification (e.g., schema validation of the design doc), it stays in markdown — no test files are created in a design phase. |
| Use `pkgload::load_all()` if devtools unavailable | MEMORY.md | N/A — Phase 29 is markdown-only. |
| Visual test HTML files go to `test_output/` (in `.gitignore`) | MEMORY.md | N/A — Phase 29 is markdown-only. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Centroid-only brush selection imposes the failure mode described in D-07 (e.g., crescent-shaped, multi-island regions) | INTR-02 Comparison Matrix | LOW — this is a geometric fact derived from the algorithm, not an empirical claim. |
| A2 | The "~5 µs/region" centroid-test estimate | Comparison Matrix | LOW — order-of-magnitude only; design doc should not commit to a specific µs figure unless benchmarked. |
| A3 | `vector-effect="non-scaling-stroke"` survives `htmlwidgets::saveWidget(selfcontained=TRUE)` serialization in current pkgdown setup | Zoom Architecture Divergence Rationale | LOW — presentation attributes are part of the serialized SVG by definition, but worth a 30-second smoke check during build-phase implementation. |
| A4 | Phase 28's `data-cx`/`data-cy` naming was provisional and superseded by D-02's `data-centroid` | Critical Inconsistency | MEDIUM — user/planner may reasonably choose to keep `data-cx`/`data-cy` and update CONTEXT.md instead. The planner MUST address this in the design doc, not silently pick. |

## Open Questions

1. **`data-centroid` vs `data-cx`/`data-cy` resolution.**
   - What we know: CONTEXT.md D-02 says `data-centroid`; existing Phase 28 code uses `data-cx`/`data-cy`.
   - What's unclear: Which the design doc should canonicalize.
   - Recommendation: Planner directs the design doc to explicitly pick one with documented rationale (see Critical Inconsistency section). Either is defensible.

2. **Combined doc vs split-per-requirement.**
   - What we know: CONTEXT.md leaves this to Claude's Discretion.
   - What's unclear: Final length depends on how much rationale prose the planner specifies for each decision.
   - Recommendation: Plan a single combined `29-01-SF-INTERACTIVITY-DESIGN.md`; if mid-plan it exceeds ~600 lines, split into three at section boundaries.

3. **Whether the design doc itself should be a Verification artifact (per workflow.verifier=true).**
   - What we know: `.planning/config.json` shows `verifier: true`.
   - What's unclear: For a design-doc-only phase, what does the verifier check? Typically checks file existence and presence of each required sub-section.
   - Recommendation: Planner includes an explicit "success rubric" in the plan: each of D-01..D-11 has a corresponding section/subsection in the design doc; the Critical Inconsistency is addressed; the comparison matrix is present.

## Environment Availability

> Phase 29 is markdown-only — no external runtime dependencies.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| (none) | — | — | — | — |

**Skip rationale:** Phase 29 produces documentation only. No tools, services, runtimes, databases, or package managers are invoked during execution. R packages (sf, geojsonsf, devtools) are only relevant for the future build phase (IMPL-04), not for writing the design doc.

## Validation Architecture

> `.planning/config.json` does not explicitly set `workflow.nyquist_validation`, so treat as enabled. However, this is a design-doc-only phase — validation is editorial, not code-test based.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.x (existing) |
| Config file | `tests/testthat.R` (project default) |
| Quick run command | `pkgload::load_all(); testthat::test_file("tests/testthat/test-sf-renderer.R")` |
| Full suite command | `devtools::test()` (or `pkgload::load_all(); testthat::test_dir("tests/testthat")`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTR-01 | Design doc exists and addresses D-01..D-04 | manual (doc review) | n/a — checklist review of `29-01-SF-INTERACTIVITY-DESIGN.md` | ❌ (created by Phase 29) |
| INTR-02 | Design doc contains centroid vs polygon comparison matrix with rejection rationale | manual (doc review) | n/a | ❌ (created by Phase 29) |
| INTR-03 | Design doc specifies SVG-group-transform zoom architecture, vector-effect mitigation, and divergence rationale from existing `zoom.js` pattern | manual (doc review) | n/a | ❌ (created by Phase 29) |

**Justification for manual-only:** Phase 29 outputs a markdown design document. No code is added; existing tests (`test-sf-renderer.R` 12 assertions, `test-sf-ir.R` 24 assertions, full suite 700 PASS per Phase 28 verification) continue to pass unchanged because nothing in the build is altered.

### Sampling Rate
- **Per task commit:** none (markdown writes don't trigger tests).
- **Per wave merge:** Optionally run `devtools::test()` to confirm no regression — should be a no-op.
- **Phase gate:** Verifier reviews the design doc against the locked decisions in CONTEXT.md and the success rubric in the plan.

### Wave 0 Gaps
None — Phase 29 produces no code. No new test files, no framework install, no shared fixtures needed.

## Sources

### Primary (HIGH confidence)
- `inst/htmlwidgets/modules/geoms/sf.js` — Phase 28 renderer; verified attribute emission patterns (`data-cx`, `data-cy`, `data-row-id`, `fill-rule="evenodd"`).
- `inst/htmlwidgets/modules/brush.js` — verified `INTERACTIVE_SELECTORS` array (lines 29–49), `isElementInPixelRect()` dispatcher (lines 259–319), `clearBrush()` coordination pattern (used by zoom.js line 352).
- `inst/htmlwidgets/modules/zoom.js` — verified element-repositioning loop (lines 365–494), zoom filter pattern (line 109–115), axis-rescale path (lines 189–242).
- `inst/htmlwidgets/modules/tooltip.js` — verified `format(d, config, ir)` API, `aes_by_var` lookup pattern (lines 198–237).
- `inst/htmlwidgets/modules/events.js` — verified `INTERACTIVE_SELECTORS` (lines 23–43), `attachTooltips()` (lines 534–556), `attachHover()` (lines 569–642).
- `.planning/phases/29-interactivity-design/29-CONTEXT.md` — locked decisions D-01..D-11.
- `.planning/phases/28-d3-renderer-prototyping/28-01-SUMMARY.md` and `28-02-SUMMARY.md` — Phase 28 deliverables and `data-cx`/`data-cy` naming evidence.
- `.planning/REQUIREMENTS.md` — INTR-01/02/03 wording and traceability.
- `.planning/STATE.md` — STATE accumulated decisions line 64 (`data-cx`/`data-cy`).
- `R/d3_tooltip.R`, `R/d3_hover.R` — R API surface signatures (verified by grep).

### Secondary (MEDIUM confidence)
- MDN — SVG `vector-effect` attribute support. [CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vector-effect]

### Tertiary (LOW confidence)
- Performance estimates in the comparison matrix (Assumption A2) — order-of-magnitude only; not benchmarked in this session.

## Metadata

**Confidence breakdown:**
- Locked-decision verification (D-01..D-11 traceable to code/CONTEXT): HIGH — every decision maps to a verified file path or existing pattern.
- Integration-surface mapping: HIGH — all three modules (`events.js`, `brush.js`, `zoom.js`) and their selector arrays directly inspected.
- Critical inconsistency identification: HIGH — three independent sources (Phase 28 code, Phase 28 summary, STATE.md) confirm `data-cx`/`data-cy`; CONTEXT.md D-02 explicitly says `data-centroid`.
- Performance figures in comparison matrix: LOW — order-of-magnitude; design doc should not commit to specific µs/ms numbers without benchmark.
- Browser support for `vector-effect`: MEDIUM-HIGH — widely documented (MDN), all evergreen browsers; not session-verified by running pkgdown export.

**Research date:** 2026-05-18
**Valid until:** 2026-06-17 (30 days — code surface is stable; only risk is unexpected changes to brush.js / zoom.js / events.js selector arrays).
