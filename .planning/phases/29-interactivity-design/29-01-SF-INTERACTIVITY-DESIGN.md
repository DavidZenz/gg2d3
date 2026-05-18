---
phase: 29
plan: 01
deliverable: SF Interactivity Design (combined INTR-01/02/03)
status: design-locked
created: 2026-05-18
implements: [INTR-01, INTR-02, INTR-03]
build_phase_target: IMPL-04 (v1.8+ milestone)
---

# Phase 29 — SF Interactivity Design

## Overview

This document is the Phase 29 deliverable. It locks the design for three
interactivity capabilities on `geom_sf` map regions: tooltip/hover
(INTR-01), brush selection (INTR-02), and zoom (INTR-03). It is a
documentation-only artifact; **no JavaScript, R, or test code is modified
in Phase 29**. All implementation lands in a later milestone (IMPL-04,
v1.8+).

The three capabilities are deliberately specified in a single combined
document because they share DOM and attribute surface: D-02's
`data-centroid` attribute is consumed by D-05's brush algorithm, and
D-08's zoom-layer group wraps the same `path.geom-sf` elements that
D-03's tooltip/hover dispatch selects on. Splitting per requirement
would force duplication of that shared spec. This doc collects the spec
in one place, then maps each change to its build-phase target file in
the implementation reference table.

Every locked decision from `29-CONTEXT.md` is addressed in a dedicated
section below. **D-01** (default tooltip headline rule) and **D-02**
(path data attributes) belong to INTR-01; **D-03** (registry-entry
integration) and **D-04** (no JSON attribute embedding) complete
INTR-01. **D-05** (centroid-only pixel-position brush), **D-06**
(polygon hit-test explicit rejection), and **D-07** (centroid
limitation documentation) belong to INTR-02. **D-08** (SVG group
transform for zoom), **D-09** (`vector-effect="non-scaling-stroke"`
mitigation), **D-10** (divergence from `zoom.js` element-repositioning),
and **D-11** (zoom event integration) belong to INTR-03. A separate
**Critical Inconsistency Resolution** section addresses the
`data-centroid` vs `data-cx`/`data-cy` mismatch surfaced by
`29-RESEARCH.md`.

## Critical Inconsistency Resolution: data-centroid vs data-cx/data-cy

**Statement of the inconsistency.** CONTEXT.md D-02 specifies a single
`data-centroid="x,y"` attribute. The existing Phase 28 renderer
`inst/htmlwidgets/modules/geoms/sf.js` lines 99–104 emits **two
separate attributes** `data-cx` and `data-cy`:

```javascript
.attr("data-cx", function(d) {
  return isFinite(d._centroid[0]) ? d._centroid[0] : null;
})
.attr("data-cy", function(d) {
  return isFinite(d._centroid[1]) ? d._centroid[1] : null;
})
.attr("data-row-id", function(d) {
  return d.row_id != null ? d.row_id : null;
});
```

This was flagged by `29-RESEARCH.md` as the one critical inconsistency
the planner must resolve, not silently pick. Phase 28-01-SUMMARY.md
confirms the original naming: "Writes `data-cx`/`data-cy` centroid
attributes with `isFinite()` guard (D-11, Phase 29 prep)". STATE.md
"Accumulated Decisions" line 64 also says: "store centroids as
`data-cx`/`data-cy` on path elements in Phase 28."

**Decision: Option A — canonicalize on `data-centroid="x,y"`.**

This document spec'es D-02 as written in CONTEXT.md: a single comma-joined
`data-centroid` attribute per path. The Phase 28 `data-cx`/`data-cy`
naming is treated as provisional and will be migrated in the build
phase.

**Rationale.**
- It matches the locked CONTEXT.md decision (D-02); changing CONTEXT
  would mean re-opening a sealed decision.
- One attribute read per region in `brush.js` is marginally cheaper than
  two (single `getAttribute` + one `split(',')` vs two `getAttribute`
  calls + two `parseFloat` calls). The compute delta is negligible at
  any realistic region count, but the code surface is smaller.
- A single combined attribute is simpler to grep for in tests and in
  manual DOM inspection (`data-centroid="`) than two separate names.
- The rename is a single small edit in `sf.js` (lines 99–104) — the
  centroid computation (`d3.geoPath().centroid(feature)`, already run
  on line ~65) does not change, only the way the result is stashed on
  the DOM.
- The `isFinite` guard logic transfers cleanly: emit
  `data-centroid` only when both components are finite; omit the
  attribute otherwise (matching the current null-emission behavior of
  `data-cx`/`data-cy`).

**Build-phase migration task.** IMPL-04 will modify
`inst/htmlwidgets/modules/geoms/sf.js` lines 99–104 to emit
`data-centroid` as a single comma-joined string and drop `data-cx` /
`data-cy`. The build phase commit message should reference both this
design doc and the original Phase 28 attribute introduction. No other
file currently reads `data-cx` or `data-cy`, so the rename is contained
to `sf.js`.

## INTR-01 — Tooltip and Hover Extension

INTR-01 extends the existing `tooltip.js` and `hover.js` modules so
that `path.geom-sf` participates in the same registry-driven pipeline
as every other geom. There are no new code paths: sf joins by adding
its selector to the existing `INTERACTIVE_SELECTORS` arrays and by
emitting the two attributes the existing dispatch code already knows
how to consume (`data-row-id` for content lookup, `data-centroid` for
brush-coordinated highlighting that the same path participates in).
The R-side surface contributes one new IR field for the default label
column. Aesthetic values (fill, color, mapped variables) are looked up
via the existing `data-row-id` → layer-data-table join — there are no
sf-specific aesthetic attributes on the DOM.

### D-01: Default tooltip headline from first non-geometry column

**Rule.** The default tooltip headline for a `geom_sf` region is the
value of the **first non-geometry column** in the layer's `sf` data
frame. For `nc.shp` (built-in to the `sf` package), this resolves to
`NAME`. The rule is zero-config and deterministic.

**R-side expression.** The build phase will add the following
one-liner to the sf branch of `R/as_d3_ir.R`:

```r
setdiff(names(sf_df), attr(sf_df, "sf_column"))[1]
```

`attr(sf_df, "sf_column")` is the canonical sf accessor for the
geometry column name (typically `"geometry"`, but it can be renamed by
the user via `sf::st_geometry(x) <- ...`). `setdiff` preserves order, so
"first non-geometry column" is well-defined.

**IR field name.** `default_label_col` — placed on the sf **layer
descriptor** (`ir.layers[i].default_label_col`), NOT on the IR root.
This scoping is required so the default-label rule only fires when the
matched selector is `path.geom-sf` (or equivalently, when
`ir.layers[i].geom_type === 'sf'`). Putting it on the IR root would
risk affecting tooltip resolution for non-sf layers in mixed plots,
which is the pitfall RESEARCH.md called out as Pitfall 5.

**Fallback when no non-geometry columns exist.** If the sf data frame
has only the geometry column (`length(setdiff(...)) == 0`), the
tooltip uses the row index, formatted as `"Region N"` where `N` is
`row_id + 1` (one-based, user-facing). This case is rare in practice
(any choropleth has at least one attribute column) but must be
specified so the build phase does not hit an undefined-lookup branch.

**Build-phase target files.**
- Producer: `R/as_d3_ir.R` (sf branch).
- Consumer: `inst/htmlwidgets/modules/tooltip.js` (reads
  `ir.layers[i].default_label_col` when resolving content for an sf
  hit).

### D-02: Path data attributes (data-row-id, data-centroid)

**Exact attribute spec.** Each `<path class="geom-sf">` emitted by the
build-phase `sf.js` will carry exactly two data attributes:

| Attribute        | Type     | Description                                                             | Notes                                                                                                |
|------------------|----------|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `data-row-id`    | integer  | Zero-based index into `layer.data[]` for the region's bound datum.      | Already emitted today; behavior unchanged.                                                           |
| `data-centroid`  | string   | Projected pixel centroid, comma-joined as `"x,y"` (e.g., `"123.4,256.7"`). | NEW — replaces `data-cx`/`data-cy` per the Critical Inconsistency Resolution above.                  |

**Compute path.** `d3.geoPath().centroid(feature)` already runs in
`sf.js` near line 65 to populate the in-memory `d._centroid` array.
The build-phase change is purely in how the result is stashed on the
DOM element: instead of two attribute writes, a single attribute write
with a comma-joined string.

**isFinite guard.** Preserve the existing
`isFinite(c[0]) && isFinite(c[1])` behavior. If either centroid
coordinate is non-finite (degenerate geometry, empty polygon), the
`data-centroid` attribute is omitted entirely from the path. Brush
hit-testing (D-05) treats a missing attribute as "not selectable",
matching today's behavior with `data-cx`/`data-cy` being `null`.

**Expected DOM snippet (illustrative).**

```html
<path class="geom-sf"
      d="M..."
      fill="#deebf7" stroke="#08519c" stroke-width="0.5"
      fill-rule="evenodd"
      vector-effect="non-scaling-stroke"
      data-row-id="0"
      data-centroid="123.4,256.7"/>
```

This snippet is reproduced verbatim in the INTR-03 section (D-08) to
show how `data-centroid` and `vector-effect` co-exist on the same
element inside the zoom-layer group.

### D-03: Registry-entry integration (no new code paths)

**One-line addition to `events.js`.** The build phase adds the string
`'path.geom-sf'` to the `INTERACTIVE_SELECTORS` array in
`inst/htmlwidgets/modules/events.js` (lines 23–43). The existing
dispatch in `attachTooltips()` (lines 534–556) and `attachHover()`
(lines 569–642) then automatically wires `mouseover.tooltip`,
`mouseout.tooltip`, `mouseover.hover`, and `mouseout.hover` to every
matching path.

**One-line addition to `tooltip.js` (if applicable).** `tooltip.js`
dispatches content resolution from the selector match that `events.js`
delivered. If `tooltip.js` maintains its own selector list, the same
`'path.geom-sf'` string is added there. If `tooltip.js` delegates
selector matching entirely to `events.js`, no second addition is
required. The build phase decides based on the file's actual structure
at IMPL-04 time; this design doc requires only that the final wiring
results in tooltips firing on `path.geom-sf` mouseover.

**Content resolution flow.** When a tooltip fires on a `path.geom-sf`
element, the existing `format(d, config, ir)` API is invoked with the
bound D3 datum (the layer's row at index `data-row-id`). The default
headline rule (D-01) is applied by reading
`ir.layers[i].default_label_col` and looking up that column on the
bound datum. Any user-mapped aesthetics (fill, color, custom tooltip
fields) are resolved through the same per-layer `aes_by_var` lookup
used by every other geom — no sf-specific branch in `format()`.

**Build-phase forbidden patterns.** Per the anti-patterns in
`29-RESEARCH.md`:
- **No per-geom branching inside `format()` or `attachTooltips()`** —
  these are dispatch tables; sf joins by selector entry, not by
  switch case.
- **No JSON-embedded DOM attributes** — D-04 below codifies this.

### D-04: No data-fill, data-color, data-bbox on path

**Rule.** Aesthetic values (fill, color, opacity, any user-mapped
variable) are NOT stored as DOM attributes on `path.geom-sf`. They are
looked up via `data-row-id` from the existing per-layer data table on
the JS side. The bounding box (if ever needed) is computed on demand
via `node.getBBox()`.

**Rationale.**
- **Keeps DOM lean.** A 3000-region choropleth multiplies any per-path
  attribute by 3000. Aesthetic values are already on the JS-side
  `layer.data[]` array, so duplicating them onto the DOM adds bytes
  with no consumer.
- **Matches every other geom.** No other geom in the codebase stuffs
  aesthetic values onto DOM attributes; consistency reduces cognitive
  overhead for future contributors.
- **Aesthetic values are accessible via D3 binding.** Any code holding
  the path node can read `d3.select(node).datum()` (the bound row) or
  index into `ir.layers[i].data[node.getAttribute('data-row-id')]` —
  both paths already exist and are exercised by other geoms.
- **bbox is cheap on demand.** `node.getBBox()` is a single SVG API
  call and is never invoked on a hot path (it would only matter for
  features like "fit zoom to selected region", which is a deferred
  enhancement). Pre-computing and stashing a `data-bbox` would
  pessimize for a feature that does not yet exist.

## INTR-02 — Brush Selection Algorithm

INTR-02 adds `geom_sf` to the brush-selection pipeline. The change is
two edits in `inst/htmlwidgets/modules/brush.js`: one new entry in the
`INTERACTIVE_SELECTORS` array, and one new branch in the per-tag
dispatcher `isElementInPixelRect()`. Selection is centroid-only per
D-05; the rejected polygon-hit-test alternative is documented
explicitly in D-06 so a future contributor does not relitigate it. The
known centroid limitation (regions whose centroid falls outside the
brush rectangle even when the brush visually overlaps the region body)
is documented in D-07 with a deferred mitigation path. sf brush
inherits — for free — the existing coordination protocol
(`data-brush-active` attribute, `clearBrush()` on zoom-start,
hover-dimming suppression) because participation is purely through the
registry.

### D-05: Centroid-only pixel-position testing

**New branch in `isElementInPixelRect()`.** The build phase adds the
following branch to `inst/htmlwidgets/modules/brush.js` after line 268
(after the existing `tagName === 'circle'` branch, before the existing
generic `path` branch). The branch must come before the generic `path`
branch so it is matched first for sf paths:

```javascript
if (tagName === 'path' && node.classList.contains('geom-sf')) {
  var c = node.getAttribute('data-centroid');
  if (!c) return false;
  var parts = c.split(',');
  var cx = parseFloat(parts[0]);
  var cy = parseFloat(parts[1]);
  return cx >= rect.px0 && cx <= rect.px1 &&
         cy >= rect.py0 && cy <= rect.py1;
}
// falls through to existing path-bbox branch for non-sf paths
// (e.g., geom-line that uses path elements)
```

This is structurally identical to the existing `circle` branch (lines
262–268) — pixel-position point-in-rect — differing only in how the
two coordinates are read (one attribute split vs two attributes parsed).

**One-line addition to `INTERACTIVE_SELECTORS`.** The build phase adds
the string `'path.geom-sf'` to the `INTERACTIVE_SELECTORS` array in
`brush.js` lines 29–49. This is the single point of enablement; without
it the new branch above is unreachable.

**Behavioral parity statement.** sf brush respects, without any new
code, all coordination protocols established for the existing geoms:
- The `data-brush-active` attribute on the panel suppresses hover
  dimming during an active brush.
- `clearBrush()` is invoked from `zoom.js` on zoom-start; sf brush is
  cleared the same way.
- The brush rect and `data-centroid` are both in pre-transform panel
  pixel coordinates, so no coordinate-space conversion is needed (see
  D-11 for the post-zoom caveat).

### D-06: Polygon hit-testing is explicitly rejected.

The alternative of polygon-sampled hit-testing — sampling each region's
boundary into a coordinate array at render time and running
`d3.polygonContains` against each sample point per brush event — is
explicitly rejected. The three rationales below MUST appear in any
future revisit of this decision.

#### (a) Memory cost

For complex MULTIPOLYGON regions (census tracts, coastline-heavy
counties, island chains), sampling the boundary at sufficient density
to avoid false-negatives requires roughly 50–500 coordinate pairs per
region — about 0.4–4 KB per region in IR bytes. A 3000-region
choropleth would balloon the IR by ~1–12 MB, all to support an
operation that runs once per brush event. The centroid alternative
stores 2 floats per region (~12 bytes), an O(40–400×) memory
improvement.

#### (b) Compute cost

Per brush event: polygon containment is
O(regions × brushPolygonPoints × regionSamples), because each region's
sampled boundary must be tested against the brush rectangle (or, more
generally, the brush polygon if d3.brush ever supported non-rect
brushes). At 1000 regions × 4 brush corners × 100 region samples per
boundary, that is 400k point-in-polygon tests per brush move event,
each invoking `d3.polygonContains`. This breaks the 60fps target
(~16ms budget per frame) at moderate region counts on mid-range
hardware. Centroid hit-testing is O(regions): one point-in-rect test
per region, no sample arrays, easily within budget.

#### (c) UX trade-off

Choropleth selection is dominated by lasso-style "select a cluster of
regions" usage, not precision selection of a single irregularly-shaped
region. Users rubber-band over a geographic area; centroid hit-testing
matches that mental model precisely (the region "belongs" to its
centroid). The failure mode of centroid (a large or crescent-shaped
region whose centroid lies outside the brush rect but whose body the
brush visually overlaps) is recoverable: the user can click-select the
missed region individually, or expand the brush by a few pixels. The
failure mode of polygon-sampled hit-testing (laggy brush UX) is NOT
recoverable from the user's seat.

**Comparison matrix (verbatim from `29-RESEARCH.md`).**

| Dimension                | Centroid (chosen, D-05)                                                                  | Polygon hit-test (rejected, D-06)                                                                                                                                  |
|--------------------------|------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Storage per region       | 2 floats in `data-centroid` (~12 bytes)                                                  | Sampled boundary array (~50–500 points × 2 floats) = 0.4–4 KB per region, often more for coastline-heavy MULTIPOLYGON                                              |
| Per-brush-event compute  | O(regions): one point-in-rect test per centroid                                          | O(regions × brush corners) AABB pre-filter + O(regions × sample-points) `d3.polygonContains` per hit; tens of ms at 1k regions = sub-60fps                          |
| Implementation surface   | One new branch in `isElementInPixelRect()`; ~5 LOC                                       | New polygon-sampling pass at render time; new dispatch in `isElementInPixelRect()`; possibly a Web Worker to keep main thread free at high region counts            |
| UX failure mode          | Crescent-shaped or multi-island regions whose centroid lies outside brush body are missed (D-07) | Laggy brushing UX is itself a failure mode at choropleth scale                                                                                                     |
| Recovery path            | Click-to-select individual region; or future bbox-fallback (Deferred)                    | N/A                                                                                                                                                                |
| Precedent in repo        | Matches `circle.geom-point` (cx/cy point-in-rect) — established pattern                  | Would be the **only** geom doing polygon-sampled hit-testing                                                                                                       |

### D-07: Centroid limitation documentation

**Statement of the limitation.** *Regions whose centroid lies outside
the brush rectangle are not selected, even when the brush visually
intersects the region body.*

**Example shapes that exhibit the limitation.**
- Crescent-shaped regions (where the centroid of the convex hull lies
  outside the actual polygon).
- Multi-island regions (e.g., the state of Hawaii — the centroid lies
  in the ocean between islands; coastal counties with offshore islands
  exhibit the same issue).
- Heavily concave polygons (deeply indented coastline; some river-delta
  parishes).

**User recovery.** The user can click-to-select the individual missed
region. Click selection on `path.geom-sf` is inherited automatically
through the registry (D-03), so the existing click pipeline (which
points and bars already use) covers sf without any extra wiring.

**Mitigation: explicitly deferred.** The design doc does NOT specify
a fallback algorithm. The deferred enhancement is a "centroid-first +
bbox-fallback brush": if the centroid test misses, fall back to a
cheap axis-aligned bounding-box intersection against the region's
`getBBox()`. This is logged in the Deferred Ideas section of CONTEXT.md
and the corresponding section of this document. It will be revisited
only if user surface confirms the centroid limitation is painful in
practice; introducing it speculatively would add code surface for a
problem we have no evidence of.

## INTR-03 — Zoom Architecture

INTR-03 specifies how zoom works for sf panels. sf is the only geom in
the codebase that uses SVG-group transform for zoom; every other geom
uses element-repositioning (recomputing per-element `cx`/`cy` or
`x`/`y`/`width`/`height` against a rescaled scale). The divergence is
deliberate and required: `d3.geoPath` re-projection per wheel tick
breaks 60fps at any meaningful region count, while SVG group transform
is GPU-composited at constant cost regardless of feature count. The
stroke-width side effect of group transforms is mitigated by setting
`vector-effect="non-scaling-stroke"` on each path as an SVG
**presentation attribute** (NOT a CSS rule, for serialization
reasons). The integration into the existing `zoom.js` is a single
pre-branch in `zoomed()`.

### D-08: SVG group transform for zoom

**DOM structure.** The build phase will wrap all sf paths in a single
`<g class="sf-zoom-layer">` inside the panel group. Per-feature paths
sit inside an inner `geom-sf-group` (matching the existing per-layer
group convention). The zoom transform is applied to the
`sf-zoom-layer` group, not to the inner `geom-sf-group` (so future
per-layer effects like opacity transitions can still target
`geom-sf-group` independently).

**Expected DOM (illustrative, post-build-phase).**

```html
<g class="panel panel-0" transform="translate(60,30)">
  <rect width="500" height="400" fill="white"/>
  <g class="sf-zoom-layer">                            <!-- D-08 -->
    <g class="geom-sf-group">
      <path class="geom-sf"
            d="M..."
            fill="#deebf7" stroke="#08519c" stroke-width="0.5"
            fill-rule="evenodd"
            vector-effect="non-scaling-stroke"         <!-- D-09 -->
            data-row-id="0"                            <!-- D-02 -->
            data-centroid="123.4,256.7"/>              <!-- D-02 -->
      <!-- ... more paths ... -->
    </g>
  </g>
  <g class="brush-overlay"><!-- d3.brush --></g>
  <!-- axes group (typically empty for coord_sf) -->
</g>
```

**Build-phase change in `inst/htmlwidgets/modules/geoms/sf.js`.** The
renderer must emit the wrapping `<g class="sf-zoom-layer">` before the
per-feature path append loop. The exact selection-chain change is
small (one `.append('g').attr('class', 'sf-zoom-layer')` insertion in
the panel-group setup), but the design doc requires it explicitly so
the build phase does not skip the wrapper and try to apply the
transform directly to `geom-sf-group` or to the panel.

**Why this works at the rendering layer.** Browsers composite
transformed SVG groups through the same GPU path as CSS transforms;
the cost is independent of feature count and of the per-path geometry
complexity. A 10k-feature choropleth zooms at the same frame rate as
a 100-feature one.

### D-09: vector-effect non-scaling-stroke mitigation

**Spec.** Each `<path class="geom-sf">` MUST carry
`vector-effect="non-scaling-stroke"` as an **SVG presentation
attribute** on the element itself, NOT as a CSS rule on the class.

```html
<path class="geom-sf"
      ...
      vector-effect="non-scaling-stroke"/>
```

**Why a presentation attribute (not CSS).** Presentation attributes
are serialized as part of the SVG DOM by every standard SVG
serializer, including the one used internally by
`htmlwidgets::saveWidget(selfcontained = TRUE)` and by the pkgdown
vignette pipeline (the DOCS-02 standalone-HTML use case). A CSS rule
defined in a `<style>` block (or in an external stylesheet that
`saveWidget` does not inline) would NOT survive this round-trip, with
the result that stroke-width would scale with zoom in saved HTML — a
silent visual regression visible only after deployment.

**Browser support.** All evergreen browsers (Chrome, Firefox, Safari,
Edge) have supported `vector-effect="non-scaling-stroke"` since 2014.
Citation: MDN — SVG `vector-effect` attribute,
`https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vector-effect`.

**Pitfall warning.** Per Pitfall 3 in `29-RESEARCH.md`: the design doc
MUST NOT spec this as `.geom-sf { vector-effect: non-scaling-stroke; }`
in a CSS rule. If a future PR proposes that simplification, this
section is the rejection citation.

### D-10: Divergence from existing zoom.js element-repositioning pattern

**Existing pattern.** Every non-sf geom is zoomed by
**element-repositioning**: `zoom.js` lines 365–494 (`repositionElements()`)
iterates per-geom selector and resets `cx`/`cy` (for points), `x`/`y`/
`width`/`height` (for bars/rects/tiles), or recomputes the `d`
attribute (for lines/paths). Each geom's reposition logic uses a
zoom-rescaled `xScale`/`yScale` (`transform.rescaleX(originalScale)`).

**Statement of divergence.** sf does NOT use element-repositioning. It
uses SVG group transform. This is the only geom in the codebase that
diverges from the element-repositioning pattern.

**Three reasons the existing pattern cannot be reused.**

1. **No equivalent of `xScale(d.x)` for sf geometry.** Non-sf geoms have
   scalar bound data (a numeric `d.x`, `d.y`) that flows through a
   scale function. sf geometry is GeoJSON, projected through
   `d3.geoIdentity().reflectY(true).fitExtent()`. To "reposition" an
   sf feature under zoom, one would have to rebuild the projection
   with the zoomed bounding box and re-run `pathGen()` per feature.
   For a MULTIPOLYGON with thousands of vertices, this is hundreds of
   milliseconds per wheel tick. The 60fps budget (16ms) is gone before
   the first feature is repainted.

2. **`geoPath.fitExtent` is bbox-driven, not transform-driven.** D3's
   continuous scales support `transform.rescaleX(scale)`, which
   produces a new scale on the fly without re-running domain/range
   math. `geoPath` has no analogous `geoPath.rescale(zoomTransform)`.
   The only way to "rescale" a projection is to call `.fitExtent()`
   again with new corners and re-run the path generator from scratch
   for every feature. This is by design (geoPath is a richer
   abstraction than a 1D scale) but it makes the element-repositioning
   pattern infeasible.

3. **SVG group transform is GPU-composited.** Cost is independent of
   feature count and per-feature geometry complexity. The browser
   treats the transformed group as a single composited layer; the
   transform applies in the compositor, not the rasterizer.

**Build-phase target.** `inst/htmlwidgets/modules/zoom.js`, the
`zoomed()` handler. The divergence is documented here so the build
phase does NOT try to retrofit sf into `repositionElements()` (and
will not be tempted to add a `geom_sf`-specific branch inside
`repositionElements()` that calls `pathGen` per wheel tick — which
would compile, work for tiny inputs, and silently destroy frame rate
on real choropleth data).

### D-11: Zoom event integration

**New branch in `zoomed()`.** The build phase adds the following
pre-branch in `inst/htmlwidgets/modules/zoom.js` near line 126 (at
the top of the `zoomed()` handler, after `clearBrush()` and before the
existing scale-rescaling / `repositionElements()` path):

```javascript
var sfLayer = panelGroup.select('.sf-zoom-layer');
if (!sfLayer.empty()) {
  sfLayer.attr('transform', transform.toString());
}
// Existing path continues unchanged for non-sf geoms
```

`d3.ZoomTransform.toString()` produces a valid SVG `transform` string
(`translate(tx,ty) scale(k)`), so assigning it directly to the group's
`transform` attribute is the entire integration. Non-sf geoms in the
same panel (rare but legal — e.g., an overlay `geom_point` on top of
a `geom_sf` basemap) continue to be repositioned by the existing path.

**Behavioral parity inherited from existing infrastructure.**
- `d3.zoom` behavior continues to be owned by `zoom.js` and attached
  to the panel. sf does not install its own zoom behavior.
- `clearBrush()` on zoom-start: inherited unchanged. sf brush
  coordination is correct because both `data-centroid` and the brush
  rect remain in pre-transform panel pixel coordinates (see
  coordinate-space note below).
- `zoom.filter()` event isolation: unchanged. Wheel events fire from
  anywhere in the panel; drag-pan only initiates on `event.target ===
  bgRect`. sf paths are not `bgRect` so they cannot start a drag-pan,
  which is the correct behavior (clicking a region should select it,
  not pan the panel).

**Axes under sf zoom.** sf panels typically suppress axes
(`coord_sf()` default — neither x nor y axis is drawn). When the user
explicitly opts into axes via `coord_sf(xlim = ..., ylim = ...)`, the
existing axis-rescale path (`updateAxes()` in `zoom.js` lines 189–242)
works unchanged because the SVG group transform does not invalidate
the scale domain. The scale's domain and range remain whatever
`fitExtent` produced at first render; only the rendered SVG is
transformed. Axes update against the rescaled scale exactly as for
non-sf panels.

**Coordinate-space note (Pitfall 4 from `29-RESEARCH.md`).** Both
`data-centroid` AND the brush rect remain in **pre-transform panel
pixel coordinates**. The SVG group transform changes only how pixels
are painted, not the underlying centroid values stashed on path
attributes or the brush extent stored in the brush state object.
Brush selection therefore continues to work correctly after a zoom —
selecting "what was originally there" — but it does NOT WYSIWYG-match
"what is currently visually under the rect" once a non-identity zoom
is applied. If the user requests WYSIWYG-after-zoom brush behavior,
that is a deferred enhancement: implementing it correctly requires
inverting the zoom transform inside the brush handler, which is
intentionally NOT inlined in this design to keep the brush handler
agnostic of zoom state. Flag here, do NOT add a transform inversion.

## Build-Phase Implementation Reference (IMPL-04)

The table below summarizes the build-phase changes the future IMPL-04
milestone will make, mapped to file and decision.

| Build-phase change                                                       | File                                                       | Decision refs                  |
|--------------------------------------------------------------------------|------------------------------------------------------------|--------------------------------|
| Add `default_label_col` to sf layer descriptor                           | `R/as_d3_ir.R` (sf branch)                                 | D-01                           |
| Rename `data-cx`/`data-cy` → single `data-centroid="x,y"`                | `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104        | D-02, Critical Inconsistency   |
| Wrap sf paths in `<g class="sf-zoom-layer">`                             | `inst/htmlwidgets/modules/geoms/sf.js`                     | D-08                           |
| Add `vector-effect="non-scaling-stroke"` attribute                       | `inst/htmlwidgets/modules/geoms/sf.js`                     | D-09                           |
| Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS`                          | `inst/htmlwidgets/modules/events.js` lines 23–43           | D-03                           |
| Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS`                          | `inst/htmlwidgets/modules/brush.js` lines 29–49            | D-05                           |
| Add `path` + `geom-sf` branch reading `data-centroid` to `isElementInPixelRect()` | `inst/htmlwidgets/modules/brush.js` after line 268 | D-05                           |
| Add `.sf-zoom-layer` transform branch to `zoomed()`                      | `inst/htmlwidgets/modules/zoom.js` near line 126           | D-08, D-11                     |
| (no change) tooltip content resolution                                   | `inst/htmlwidgets/modules/tooltip.js`                      | D-03, D-04                     |

## Deferred / Out of Scope

- **Centroid-first + bbox-fallback brush** — revisit if D-07
  limitation surfaces as pain. The bbox-fallback would invoke
  `node.getBBox()` only when the centroid test misses, preserving
  the centroid happy-path performance while catching crescent and
  multi-island regions. Out of scope for v1.7 and for IMPL-04.
- **Semantic zoom for choropleth** (e.g., switch label density at
  zoom levels, swap county → tract resolution) — distinct feature,
  belongs in its own milestone.
- **Slippy-map basemap tiles under sf layers** — explicit
  anti-feature per the v1.7 charter.
- **JS-side reprojection** — Phase 27 locked R-side `st_transform`
  to WGS84 before serialization; JS-side projection stays out of
  scope.
- **WYSIWYG-after-zoom brush behavior** (selection of "what is
  currently visually under the rect" after a non-identity zoom) — see
  D-11 coordinate-space note. Requires inverting the zoom transform
  inside the brush handler; intentionally deferred to keep the brush
  handler zoom-agnostic.
- **All implementation code** — Phase 29 is design-only; build lands
  in v1.8+ as IMPL-04.

## Success Rubric

A reviewer can confirm this design doc is complete by checking:

- [ ] Every D-01..D-11 has a dedicated `### D-NN` section.
- [ ] Critical Inconsistency Resolution explicitly picks one option
      (Option A — `data-centroid`) with rationale and names IMPL-04 as
      the build-phase migration owner.
- [ ] INTR-02 comparison matrix is present with memory, compute, UX,
      and recovery dimensions and lists six rows.
- [ ] INTR-03 `vector-effect` is specified as a presentation attribute
      (not CSS) with serialization rationale.
- [ ] Build-Phase Implementation Reference table maps each change to
      a file path and a decision ref.
- [ ] `verify-design-doc.sh` exits 0 against this document.
