---
phase: 30-edge-cases-and-blueprint
plan: 01
deliverable: SF Edge Cases and Build-Phase Blueprint (combined BLPR-01/02/03)
status: blueprint-locked
created: 2026-05-18
implements: [BLPR-01, BLPR-02, BLPR-03]
build_phase_target: IMPL-04+ (v1.8+ milestone)
---

# Phase 30 — SF Edge Cases and Build-Phase Blueprint

## Overview

This document is the Phase 30 deliverable. It locks edge-case findings
(BLPR-01), anti-features (BLPR-02), and a file/line-specific phase-by-phase
implementation plan (BLPR-03) for `geom_sf` support in gg2d3. It is a
**documentation-only artifact**; no production R or JavaScript code is
modified in Phase 30. All implementation lands in the v1.8+ build milestone
(IMPL-04+).

Phase 30 is the final deliverable of the v1.7 Choropleth Map Research
milestone. Phase 27 established the R-side IR extraction contract (sf layer
dispatch, WGS84 normalization, `geometries[]`/`coord.bbox` fields). Phase 28
built and visually verified the D3 renderer. Phase 29 locked the interactivity
design (tooltip, brush, zoom). Phase 30 closes the research milestone by
investigating three edge cases empirically, declaring exactly three
anti-features, and compiling a build-phase execution plan detailed enough
that `/gsd-plan-phase` for the v1.8+ milestone can execute without new
research.

The three BLPR requirements are covered in one combined document (per
CONTEXT.md D-08) following the precedent of `29-01-SF-INTERACTIVITY-DESIGN.md`,
which covered INTR-01/02/03 in one file. The edge cases, anti-features, and
implementation plan share enough cross-references (edge-case findings drive
build-phase C plans; anti-features define what implementation plan must NOT
do) that separation would force duplication.

---

## Edge Cases (BLPR-01)

Each edge case was investigated with an empirical R prototype script (per
CONTEXT.md D-01) run from `test_output/` (gitignored per D-02). Scripts are
NOT committed; their findings — the actual IR shape, any errors, and what the
pipeline does — are synthesized here as the durable record. The run logs are
referenced by filename for traceability.

## Edge Case 1: Mixed Geometry Types in a Single Layer

**Case:** A single `geom_sf()` layer whose underlying sf data frame contains
heterogeneous geometry types in the same geometry column — for example,
one POLYGON feature and one POINT feature in the same layer call.

**Empirical finding** (from `test_output/30-edge-mixed-run.log`):
The pipeline **succeeds** without errors for a two-row sf data frame containing
POLYGON + POINT features. Key observations:

- `detect_dominant_geom_type()` returns `"GEOMETRY"` (not `"POLYGON"` or
  `"POINT"`) when the input contains heterogeneous types. This is the sf
  package's own geometry-type string for a mixed-type `sfc` column.
- `ir$layers[[1]]$geom_type` is `"GEOMETRY"` — the sentinel that signals
  heterogeneity rather than a concrete type.
- `length(ir$layers[[1]]$geometries)` equals the number of input features (2)
  — all features are serialized into the `geometries` array, including both the
  POLYGON and the POINT.
- Parsing the GeoJSON strings confirms both feature types are preserved: the
  first geometry is a `"Polygon"` GeoJSON object, the second is a `"Point"`.
- No features are dropped. No crash occurs.

**What this means for the D3 renderer:** `sf.js` uses `d3.geoPath().projection(proj)`
to draw each geometry as an SVG path. `d3.geoPath` can render Point geometry
as a circle (or zero-size path without a point radius), Line geometry as an
open path, and Polygon geometry as a filled path. Mixed-type layers will render
all features but with potentially surprising visual behavior — Point features
will render as zero-size (invisible) paths unless `d3.geoPath().pointRadius()`
is configured.

**Recommended build-phase handling:** Document `"GEOMETRY"` as the indicator
of a mixed-type layer. The renderer (sf.js) need not be modified — `d3.geoPath`
handles all GeoJSON types. The build phase should add a **developer warning**
in the R extraction path: when `detect_dominant_geom_type()` returns
`"GEOMETRY"`, `as_d3_ir()` should issue `warning("geom_sf layer contains mixed
geometry types; non-polygon features may not render visibly")`. This gives
users actionable feedback without crashing or dropping data.

**Rationale for "warn, do not drop" approach:** Dropping features would
silently lose data, which is worse than a slightly surprising visual. Crashing
would break plots that happen to have a stray POINT in a POLYGON layer
(possible in real data). Warning preserves fidelity while alerting the user.

---

## Edge Case 2: Multi-Layer SF Stacking

**Case:** Two `geom_sf()` calls in the same plot — for example, a county-level
choropleth fill layer (100 MULTIPOLYGON features) stacked with a state-boundary
overlay layer (1 MULTIPOLYGON feature, stroke-only, `fill = NA`).

**Empirical finding** (from `test_output/30-edge-multi-run.log`):
The pipeline **succeeds** for a two-layer NC counties + state-boundary plot.
Key observations:

- `length(ir$layers)` is 2 — the pipeline produces one layer descriptor per
  `geom_sf()` call, in source order (back-to-front render order matches
  `ir$layers` array order).
- Layer 1: `geom_type = "MULTIPOLYGON"`, 100 geometries (NC counties), `crs.epsg = 4326`.
- Layer 2: `geom_type = "MULTIPOLYGON"`, 1 geometry (state boundary),
  `crs.epsg = 4326`.
- `ir$coord$type` is `"sf"`.
- `ir$coord$bbox` is `[-84.3238, 33.8822, -75.4566, 36.5898]` — this is the
  WGS84 bounding box of **all** features across both layers combined (verified
  against the R source at `as_d3_ir.R` lines 711–721, which iterates `b$data`
  across all layers and calls `sf::st_bbox()` on the union).
- CRS is consistent across both layers (`epsg = 4326`); per-layer WGS84
  normalization in the R sf branch ensures this.

**What the current pipeline already handles correctly:**
1. Multi-layer sf stacking produces separate layer descriptors — ✓ correct.
2. Render order is preserved (back-to-front = `ir$layers[1]` first) — ✓ correct.
3. `coord.bbox` is the union bbox of all sf layers — ✓ correct (already
   implemented in Phase 27 via the `do.call(c, ...)` union at lines 711–721).
4. CRS consistency is enforced per-layer — ✓ correct (each layer independently
   normalizes to WGS84).

**Recommended build-phase handling:** No special multi-layer handling is needed
in the R extraction path — the existing implementation is correct. The build
phase should:

1. Add an explicit assertion or comment in `as_d3_ir.R` at the bbox computation
   (lines 711–721) documenting that the bbox covers ALL sf layers, not just the
   first. This prevents future regressions where a refactor breaks the union.
2. Add a multi-layer sf integration test in `tests/testthat/test-sf-ir.R`
   confirming `length(ir$layers) == 2` and that `coord.bbox` spans the union
   of both layers.
3. Confirm `sf.js` render-order semantics: the existing geom layer loop in the
   D3 renderer iterates `ir.layers` in array order, so back-to-front stacking
   is automatic.

---

## Edge Case 3: Faceted SF Maps

**Case:** `geom_sf()` combined with `facet_wrap(~category)` — for example,
NC counties (100 features) faceted by a synthetic 3-level region column
(A/B/C), producing 3 panels.

**Empirical finding** (from `test_output/30-edge-faceted-run.log`):
The pipeline **succeeds** for both `facet_wrap(~region)` (fixed scales) and
`facet_wrap(~region, scales="free")`. Key observations:

- `length(ir$panels)` is 3 — correct panel count.
- `ir$facets$type` is `"wrap"` — facets engine routes to the correct branch.
- Strip metadata IS present in `ir$facets$strips` — the panel strip labels
  (A, B, C) are included in the IR.
- **Critical finding 1:** Panel `x_range`/`y_range` are **NOT NULL** in the
  faceted sf case. They contain the ggplot2 Cartesian coordinate ranges
  (`[-84.77, -75.01]` and `[33.75, 36.73]`). This contradicts the Phase 27
  expectation that sf panels use `NULL` x_range/y_range. The reason: the
  non-faceted sf branch in `as_d3_ir.R` (line 916–918) explicitly sets
  `x_range = NULL, y_range = NULL`, but the faceted branches (lines 865–888
  for `FacetWrap`, 897–910 for `FacetGrid`) do NOT check `is_sf_coord` and
  always populate Cartesian ranges. The D3 renderer must not use these ranges
  for sf projection — it uses `coord.bbox` + `d3.geoIdentity` regardless.
- **Critical finding 2:** Per-panel `bbox` DOES NOT EXIST in any panel's IR
  object (`ir$panels[[i]]$bbox` is `NULL` for all three panels). There is only
  a single global `ir$coord$bbox` shared across all panels.
- **Critical finding 3:** `scales="free"` produces the same `x_range`/`y_range`
  values per panel as `scales="fixed"` — the sf coordinate system does not
  differentiate, because geographic extents are feature-driven, not scale-driven.

**The LOCKED decision (D-03):** The build phase must add **per-panel
`coord.bbox`** so that `sf.js` can call `d3.geoIdentity().reflectY(true).fitExtent()`
once per panel, fitting each panel to its own geographic subset. Without
per-panel bbox, all three facet panels would project identically (fitting the
global NC extent), defeating the purpose of faceting a geographic map.

**What the build phase must do for per-panel bbox:**
- In `as_d3_ir.R`, the `FacetWrap` panel iteration (lines 865–888) must be
  extended with an `is_sf_coord` branch that, for each panel `p`:
  1. Identifies the features assigned to panel `p` (using the PANEL column
     in `b$data[[i]]`).
  2. Extracts and normalizes to WGS84 the geometry column for those features.
  3. Computes `sf::st_bbox()` on the panel subset.
  4. Adds a `bbox` field to `ir$panels[[p]]` holding the 4-element numeric
     vector `[xmin, ymin, xmax, ymax]`.
- In `sf.js`, the `fitExtent()` call must be conditioned: if a per-panel
  `bbox` exists on the panel descriptor, use it instead of `ir.coord.bbox`.

**Build-phase verification items (D-04 flagged unknowns):**
The following questions are NOT resolved in Phase 30. They are flagged
for empirical verification during the build phase.

- **Panel strip rendering:** sf panels use ggplot2's `CoordSf` which suppresses
  Cartesian axes. Do facet strip boxes (the "A", "B", "C" labels above each
  panel) render correctly alongside sf panels, or does axis suppression interact
  with strip layout?
- **Axis suppression per panel:** In single-panel sf plots, the sf coordinate
  system typically suppresses numeric Cartesian axes and shows graticule lines
  instead (or no axes). In the D3 renderer, axes are drawn from `x_range` /
  `y_range`. For faceted sf, these are now confirmed non-NULL. The build phase
  must verify whether the D3 renderer should suppress axis rendering on sf panels
  (matching ggplot2 sf behavior) and, if so, where that suppression lives
  (sf.js, the layout engine, or a per-panel flag in the IR).
- **Interaction with `coord_sf(xlim=, ylim=)` per panel:** ggplot2 supports
  passing explicit geographic extent limits to `coord_sf()`. In a faceted plot,
  these limits apply globally. The build phase must verify whether per-panel
  bbox computation correctly handles a plot where `coord_sf()` carries
  user-supplied `xlim`/`ylim`, and whether the per-panel subset bbox should
  be intersected with those limits or ignored.
- **`facet_wrap(scales=)` mirroring:** The empirical finding above shows that
  `scales="free"` produces the same panel x_range/y_range as `scales="fixed"`
  for sf coords — geographic extent is feature-driven, not scale-driven.
  However, ggplot2's `scales="free"` for sf facets allows each panel to zoom
  to its own geographic extent. The build phase must verify whether per-panel
  bbox (D-03) is sufficient to implement "free"-like behavior, or whether
  additional ggplot2 scale state must be inspected.

---

## Anti-Features (BLPR-02)

Anti-features are capabilities that are **explicitly out of scope forever**,
as distinct from deferred ideas. A deferred idea is "not now, possibly later";
an anti-feature is a deliberate rejection with a rationale that should survive
future contributor revisits. The four items surfaced during Phases 27–29
(centroid-fallback brush, semantic zoom, GeomPolygon orphan resurrection,
multi-CRS-per-layer) are NOT in this list per CONTEXT.md D-06 — they remain
in CONTEXT.md's `<deferred>` section as "not now, possibly later" candidates.
This list contains only the three charter-named items that are out of scope
permanently.

### Anti-Feature 1: Tile Basemaps

Slippy-tile basemaps (OSM, Mapbox, etc.) rendered under sf layers are out of
scope because gg2d3 renders ggplot output, and basemap composition is a
separate authoring concern that belongs in a tool like Leaflet.

### Anti-Feature 2: JS-Side Reprojection

Any projection logic in D3 stays out of scope because Phase 27 locked
R-side `sf::st_transform` to WGS84 before serialization, preserving the
single-source-of-truth contract that gg2d3 renders exactly what ggplot2
computes.

### Anti-Feature 3: Slippy Zoom / Leaflet-Style Pan

Tile-loading slippy zoom is out of scope, distinct from the Phase 29 SVG-group-transform
zoom, to keep gg2d3's zoom uniform across geom types and avoid forking the
zoom architecture.

---

## Implementation Plan (BLPR-03)

This plan is consumed by `/gsd-plan-phase` for the v1.8+ build milestone.
Each Build Phase below corresponds to one `/gsd-plan-phase` invocation;
each Plan within a phase is one `PLAN.md`. Every change names a specific
file AND either a line number, a function name with line range, or a named
code construct — matching the file/line granularity of
`29-01-SF-INTERACTIVITY-DESIGN.md` (D-07). Requirement IDs reference
`REQUIREMENTS.md` IMPL-03/IMPL-04/IMPL-05 where they map cleanly.

**Note on confirmed line numbers:** All line numbers cited below were
verified against the worktree source at time of blueprint creation
(2026-05-18). The source files are:
`inst/htmlwidgets/modules/geoms/sf.js` (113 lines),
`inst/htmlwidgets/modules/events.js` (715 lines),
`inst/htmlwidgets/modules/brush.js` (413 lines),
`inst/htmlwidgets/modules/zoom.js` (521 lines).

---

### Build Phase A: SF Core Rendering Wire-Up (IMPL-03 + IMPL-04 attribute work)

**Goal:** Land the Phase 29 design-locked DOM changes in `sf.js` and the
R-side IR additions. This phase is the prerequisite for all interactivity
phases (B, C) because the attribute and group structure must be in place
before event registration is wired.

#### Plan A.1 — `data-centroid` migration and path attribute additions

**File:** `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104

Replace the two-attribute `data-cx` / `data-cy` emission (Phase 28 interim)
with the single `data-centroid="x,y"` attribute (Phase 29 D-02). Current code
at lines 99–104:

```javascript
.attr("data-cx", function(d) {
  return isFinite(d._centroid[0]) ? d._centroid[0] : null;
})
.attr("data-cy", function(d) {
  return isFinite(d._centroid[1]) ? d._centroid[1] : null;
})
```

Replacement:

```javascript
.attr("data-centroid", function(d) {
  return (isFinite(d._centroid[0]) && isFinite(d._centroid[1]))
    ? d._centroid[0] + "," + d._centroid[1]
    : null;
})
```

**File:** `inst/htmlwidgets/modules/geoms/sf.js` — add `vector-effect` attribute

After the `.attr("fill-rule", "evenodd")` call (currently line 98), add:

```javascript
.attr("vector-effect", "non-scaling-stroke")
```

Per Phase 29 D-09: this MUST be a SVG **presentation attribute** (not a CSS
property) so it survives `htmlwidgets::saveWidget()` CSS stripping during
serialization.

**File:** `inst/htmlwidgets/modules/geoms/sf.js` line 84 — wrap paths in sf-zoom-layer group

Replace the current flat group:

```javascript
var sfGroup = g.append("g").attr("class", "geom-sf-group");
```

with a nested structure (Phase 29 D-08):

```javascript
var sfZoomLayer = g.append("g").attr("class", "sf-zoom-layer");
var sfGroup = sfZoomLayer.append("g").attr("class", "geom-sf-group");
```

The `sf-zoom-layer` group is the target for the `zoom.js` group-transform
(Plan B.3). The inner `geom-sf-group` preserves the existing path selection
behavior.

#### Plan A.2 — Add `default_label_col` to sf layer descriptor (IR)

**File:** `R/as_d3_ir.R` sf branch — lines 359–368 (the `list(...)` at the end
of the `if (gname == "sf")` block)

After the `df[["row_id"]] <- seq_along(sf_geom_strings)` line (currently
line 358), add extraction of the default label column (Phase 29 D-01):

```r
sf_default_label_col <- setdiff(names(sf_df), attr(sf_df, "sf_column"))[[1]] %||% NULL
# Note: use the pre-join sf_df, not the post-to_rows() df
```

Add `default_label_col = sf_default_label_col` to the layer descriptor list
(the `list(geom = "sf", ...)` at lines 359–368).

The tooltip module uses `ir.layers[i].default_label_col` to determine which
data column to use as the tooltip headline for sf regions (Phase 29 D-01).
For NC counties, this would be `"NAME"` (the first non-geometry column).

**File:** `tests/testthat/test-sf-ir.R` — extend with `default_label_col` assertion

Add a test asserting that for the NC counties fixture:

```r
expect_equal(ir$layers[[1]]$default_label_col, "AREA")  # first non-geometry column
```

(The exact first column depends on NC shp field order; test should use
`names(nc)[1]` dynamically rather than hardcoding `"AREA"`.)

---

### Build Phase B: SF Interactivity Wire-Up (IMPL-04)

**Goal:** Land the Phase 29 design-locked registry and dispatch additions
across `events.js`, `brush.js`, `tooltip.js`, `hover.js`, and `zoom.js`.
This phase requires Build Phase A to be complete (the `data-centroid`,
`sf-zoom-layer`, and `path.geom-sf` class must exist before event wiring).

#### Plan B.1 — Tooltip and hover registry entry

**File:** `inst/htmlwidgets/modules/events.js` lines 23–43

Add `'path.geom-sf'` to the `INTERACTIVE_SELECTORS` array (per Phase 29 D-03).
The array currently ends at line 42 with `'circle.pointrange-point'`. Add
`'path.geom-sf'` as the next entry after line 42. This single addition gates
all event dispatch for sf elements — hover, tooltip, click, and brush pickup
all read from this selector.

**File:** `inst/htmlwidgets/modules/tooltip.js`

Extend tooltip content resolution to use `ir.layers[i].default_label_col`
when the matched element is a `path.geom-sf` (Phase 29 D-01). The tooltip
module currently dispatches on element tag/class to determine what data
attribute to use for the headline. Add one new branch: if the element matches
`path.geom-sf`, read the `data-row-id` attribute to identify the feature,
then look up the value of `ir.layers[i].default_label_col` in that feature's
data row.

Do NOT add a per-geom `format()` branch — the existing content format pipeline
applies unchanged (Phase 29 D-01 explicitly rejects per-geom format branches).

**File:** `inst/htmlwidgets/modules/hover.js`

No change expected. Hover dispatch fires on all elements matching
`INTERACTIVE_SELECTORS`; once `path.geom-sf` is in that array (events.js),
hover pickup is automatic. Verify (but do not modify) that the hover
module's `mouseover`/`mouseout` handlers fire correctly on `path.geom-sf`
elements during manual testing in Plan B.1 visual checkpoint.

#### Plan B.2 — Brush selection wiring (centroid hit-test)

**File:** `inst/htmlwidgets/modules/brush.js` lines 29–49

Add `'path.geom-sf'` to the `INTERACTIVE_SELECTORS` array (per Phase 29 D-05),
parallel to the events.js addition in Plan B.1. The array starts at line 29
and currently ends with `'circle.pointrange-point'` at line 48.

**File:** `inst/htmlwidgets/modules/brush.js` — `isElementInPixelRect()` function

Add a new sf branch after the `tagName === 'circle'` branch (currently ending
at line 268) and before the existing `tagName === 'rect'` branch. The new
branch (per Phase 29 D-05):

```javascript
if (node.classList && node.classList.contains('geom-sf')) {
  // Centroid-based hit-test: read data-centroid="x,y"
  var centroidAttr = node.getAttribute('data-centroid');
  if (!centroidAttr) return false;
  var parts = centroidAttr.split(',');
  var cx = parseFloat(parts[0]);
  var cy = parseFloat(parts[1]);
  if (!isFinite(cx) || !isFinite(cy)) return false;
  return cx >= rect.px0 && cx <= rect.px1 &&
         cy >= rect.py0 && cy <= rect.py1;
}
```

This branch must come BEFORE the generic path/line fallback to ensure sf paths
use centroid testing rather than any generic path geometry test.

#### Plan B.3 — Zoom integration (SVG group transform)

**File:** `inst/htmlwidgets/modules/zoom.js` near line 126 — `zoomed()` function

Add a new pre-branch at the top of the `zoomed(event)` function body
(line 126), after the existing `clearBrush(panelGroup)` call at line 130,
and before the continuous scale-rescaling block at line 133 (per Phase 29 D-11):

```javascript
// SF zoom: apply transform directly to sf-zoom-layer group (Phase 29 D-11)
// This preserves geographic projection; axes still rescale via xScaleCurrent/yScaleCurrent
var sfLayer = panelGroup.select('.sf-zoom-layer');
if (!sfLayer.empty()) {
  sfLayer.attr('transform', transform.toString());
  return;  // Do NOT rescale Cartesian axes for sf panels
}
```

The `return` early exit prevents the standard axis-rescaling code from running
on sf panels, where Cartesian x/y scales are meaningless (the panel has no
visible Cartesian axes). For non-sf panels, `sfLayer.empty()` is true and the
standard path continues unchanged.

---

### Build Phase C: SF Edge Case Handling (IMPL-05)

**Goal:** Land the BLPR-01 edge case handling — multi-layer rendering
correctness assurance, faceted sf with per-panel bbox, mixed-geometry
developer warnings, and the D-04 flagged unknowns verification.

#### Plan C.1 — Multi-layer sf rendering correctness

**File:** `R/as_d3_ir.R` lines 711–721 — `sf_coord_meta` computation

Add an explicit inline comment documenting the union-bbox behavior:

```r
# sf coord metadata: compute WGS84 bounding box from ALL sf layers (not just first).
# Per Phase 30 Edge Case 2: coord.bbox must be union of all layers so multi-layer
# plots (e.g., county fill + state boundary overlay) fit correctly.
```

No logic change is needed — the existing `do.call(c, Filter(Negate(is.null), lapply(...)))` 
already iterates all layers. The comment prevents a future refactor from
inadvertently breaking the union by replacing the iteration with a single-layer read.

**File:** `inst/htmlwidgets/modules/geoms/sf.js`

Add an inline comment above the `fitExtent` call (currently line 56–58):

```javascript
// Per Phase 30 Edge Case 2: for multi-layer sf plots, coord.bbox is the
// union of all layers' extents (computed in R). Use ir.coord.bbox here,
// not the individual layer's feature collection bounds, to ensure all
// layers project to the same coordinate space.
```

**File:** `tests/testthat/test-sf-ir.R`

Add a multi-layer sf integration test:

```r
test_that("multi-layer sf produces two layer descriptors with union bbox", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  state <- sf::st_sf(geometry = sf::st_sfc(sf::st_union(nc), crs = sf::st_crs(nc)))
  p <- ggplot2() + geom_sf(data = nc, aes(fill = BIR74)) +
    geom_sf(data = state, fill = NA, color = "black")
  ir <- as_d3_ir(p)
  expect_equal(length(ir$layers), 2L)
  expect_equal(ir$layers[[1]]$geom, "sf")
  expect_equal(ir$layers[[2]]$geom, "sf")
  expect_length(ir$coord$bbox, 4L)
  # bbox must span both layers (wider than either alone)
  expect_true(!is.null(ir$coord$bbox))
})
```

#### Plan C.2 — Faceted sf with per-panel bbox

**File:** `R/as_d3_ir.R` — `FacetWrap` panel iteration (lines 865–888)

The `panels_ir` computation inside `is_facet_wrap` must check `is_sf_coord`
and, when TRUE, add a per-panel bbox instead of (or in addition to) the
Cartesian `x_range`/`y_range`. Insert before the closing `list(PANEL = ...,
x_range = ..., ...)` return at line 887:

```r
# Per Phase 30 D-03: sf facets need per-panel bbox for geoIdentity.fitExtent
if (is_sf_coord) {
  # Identify which features belong to panel p
  panel_features <- lapply(seq_along(b$data), function(li) {
    df_i <- b$data[[li]]
    gcol <- names(df_i)[vapply(df_i, inherits, logical(1L), "sfc")][1L]
    if (!is.na(gcol)) {
      panel_rows <- df_i[df_i$PANEL == p, , drop = FALSE]
      if (nrow(panel_rows) > 0L) normalize_to_wgs84(panel_rows[[gcol]]) else NULL
    } else NULL
  })
  panel_geoms <- do.call(c, Filter(Negate(is.null), panel_features))
  panel_bbox <- if (!is.null(panel_geoms) && length(panel_geoms) > 0L)
    unname(as.numeric(sf::st_bbox(panel_geoms))) else NULL
  # Return sf panel descriptor with per-panel bbox
  list(PANEL = as.integer(p), x_range = NULL, y_range = NULL,
       x_breaks = NULL, y_breaks = NULL, bbox = panel_bbox)
} else {
  list(PANEL = ...) # existing Cartesian logic unchanged
}
```

**File:** `inst/htmlwidgets/modules/geoms/sf.js` — per-panel bbox lookup

In the `renderSf` function, the `options` parameter already carries per-panel
context. The renderer must be updated to receive the per-panel `bbox` (if
present) and use it in the `fitExtent` call:

```javascript
// Per Phase 30 D-03: use per-panel bbox if available; fall back to global coord.bbox
var bboxSrc = (options.panel && options.panel.bbox) ? options.panel.bbox : options.coord.bbox;
var bboxLL = bboxSrc; // [xmin, ymin, xmax, ymax] in WGS84
var bboxFC = {
  type: "Feature",
  geometry: {
    type: "Polygon",
    coordinates: [[
      [bboxLL[0], bboxLL[1]], [bboxLL[2], bboxLL[1]],
      [bboxLL[2], bboxLL[3]], [bboxLL[0], bboxLL[3]],
      [bboxLL[0], bboxLL[1]]
    ]]
  }
};
var proj = d3.geoIdentity().reflectY(true).fitExtent([[padding, padding], [w - padding, h - padding]], bboxFC);
```

This replaces the current `fitExtent([[padding, padding], [w - padding, h - padding]], fc)` 
which fits to the actual features (correct for single-panel, but wrong for
faceted panels where each panel should zoom to its geographic subset, not its
rendered feature set).

**File:** `tests/testthat/test-sf-visual.R`

Add a faceted sf visual test that writes HTML to `test_output/` and requires
a human-verify checkpoint:

```r
test_that("faceted sf renders with per-panel geographic zoom [visual]", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  nc$region <- ifelse(seq_len(nrow(nc)) %% 3 == 0, "A",
               ifelse(seq_len(nrow(nc)) %% 3 == 1, "B", "C"))
  p <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) +
    ggplot2::geom_sf() + ggplot2::facet_wrap(~region)
  w <- gg2d3(p)
  htmlwidgets::saveWidget(w, "test_output/faceted-sf-panels.html", selfcontained = TRUE)
  # Human verify: each panel should show only its region's counties,
  # zoomed to that region's geographic extent (not the full NC extent)
})
```

#### Plan C.3 — Faceted-sf flagged unknowns verification

This plan is a spike: empirically verify each of the four D-04 unknowns
(CONTEXT.md) and land findings as either fixes or documented limitations.

1. **Panel strip rendering:** Run faceted sf through the D3 renderer with
   strips enabled. Verify strip boxes render above each panel. If facets engine
   places strips in the wrong location (e.g., overlapping the map), fix the
   layout engine's strip-position calculation for sf panels.
   - File coverage: `inst/htmlwidgets/gg2d3.js` — facets layout section
     (strip placement uses `panel.y + panel.height + stripHeight`).

2. **Axis suppression per panel:** Verify that sf panel `x_range = NULL` and
   `y_range = NULL` (after Plan C.2) causes the D3 renderer to skip axis
   generation on sf panels. If the renderer errors on `null` range, add an
   explicit sf-coord guard at the axis-drawing call site.
   - File coverage: `inst/htmlwidgets/gg2d3.js` — `buildAxes()` or equivalent
     function that reads `panel.x_range`.

3. **`coord_sf(xlim=, ylim=)` per panel:** Build a test with `coord_sf(xlim=c(-83,-76), ylim=c(34,37))` 
   and a facet. Verify whether per-panel bbox computation clips correctly to
   the user-supplied limits. If ggplot2 applies `xlim`/`ylim` before
   `ggplot_build()`, the feature rows themselves are clipped, so per-panel bbox
   naturally inherits the clipping. If not, the bbox may need to be intersected.
   - File coverage: `R/as_d3_ir.R` — per-panel bbox logic (Plan C.2 addition).

4. **`facet_wrap(scales=)` mirroring:** Confirm empirically that per-panel bbox
   (Plan C.2) provides "free"-like behavior by default (each panel zooms to its
   own features). If `scales="fixed"` is requested and should force all panels
   to the global `coord.bbox`, add a check in `sf.js` that selects between
   per-panel bbox and `ir.coord.bbox` based on `ir.facets.scales`.
   - File coverage: `inst/htmlwidgets/modules/geoms/sf.js` — `bboxSrc` selection
     in Plan C.2 renderer update.

#### Plan C.4 — Mixed geometry types in single layer

**Recommended approach from Edge Case 1 finding:** Emit a developer warning
when `geom_type == "GEOMETRY"` (the mixed-type sentinel).

**File:** `R/as_d3_ir.R` sf branch — after `detect_dominant_geom_type()` call
(currently line 356)

Add immediately after line 356:

```r
if (sf_layer_gtype == "GEOMETRY") {
  warning(
    "geom_sf layer contains mixed geometry types (e.g., POLYGON + POINT). ",
    "Non-polygon features may not render visibly in D3. ",
    "Consider separating geometry types into distinct geom_sf() layers.",
    call. = FALSE
  )
}
```

**File:** `tests/testthat/test-sf-ir.R`

Add a mixed-geometry regression test:

```r
test_that("mixed geometry sf layer succeeds with GEOMETRY geom_type and warning", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  sf_mixed <- sf::st_sf(
    name = c("poly", "pt"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(c(0,0), c(1,0), c(1,1), c(0,1), c(0,0)))),
      sf::st_point(c(0.5, 0.5)),
      crs = 4326
    )
  )
  p <- ggplot2::ggplot(sf_mixed) + ggplot2::geom_sf()
  expect_warning(ir <- as_d3_ir(p), "mixed geometry types")
  expect_equal(ir$layers[[1]]$geom_type, "GEOMETRY")
  expect_equal(length(ir$layers[[1]]$geometries), 2L)
})
```

---

## Build-Phase Implementation Reference (IMPL-04+)

Summary table for `/gsd-plan-phase` — maps each concrete change to its file,
code construct, and decision/requirement source.

| Build Phase | Plan | File | Concrete Change | Decision/Requirement Ref |
|-------------|------|------|-----------------|--------------------------|
| A | A.1 | `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104 | Replace `data-cx`/`data-cy` with single `data-centroid="x,y"`; emit only when both finite | Phase 29 D-02 |
| A | A.1 | `inst/htmlwidgets/modules/geoms/sf.js` after line 98 | Add `.attr("vector-effect", "non-scaling-stroke")` as SVG presentation attribute | Phase 29 D-09 |
| A | A.1 | `inst/htmlwidgets/modules/geoms/sf.js` line 84 | Wrap paths in `<g class="sf-zoom-layer">` before `geom-sf-group` | Phase 29 D-08 |
| A | A.2 | `R/as_d3_ir.R` sf branch lines 358–368 | Add `default_label_col = setdiff(names(sf_df), attr(sf_df, "sf_column"))[[1]]` to layer descriptor | Phase 29 D-01 |
| A | A.2 | `tests/testthat/test-sf-ir.R` | Assert `ir$layers[[1]]$default_label_col == names(nc)[1]` for NC fixture | Phase 29 D-01 |
| B | B.1 | `inst/htmlwidgets/modules/events.js` lines 23–43 | Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS` array after line 42 | Phase 29 D-03 |
| B | B.1 | `inst/htmlwidgets/modules/tooltip.js` | Add `default_label_col` lookup for `path.geom-sf` matched elements | Phase 29 D-01 |
| B | B.1 | `inst/htmlwidgets/modules/hover.js` | Verify (no code change) hover fires on `path.geom-sf` via events.js registry | Phase 29 D-03 |
| B | B.2 | `inst/htmlwidgets/modules/brush.js` lines 29–49 | Add `'path.geom-sf'` to `INTERACTIVE_SELECTORS` array | Phase 29 D-05 |
| B | B.2 | `inst/htmlwidgets/modules/brush.js` after line 268 | Add sf centroid branch in `isElementInPixelRect()` reading `data-centroid` | Phase 29 D-05 |
| B | B.3 | `inst/htmlwidgets/modules/zoom.js` near line 126 | Add sf-zoom-layer group-transform branch at top of `zoomed()` with early return | Phase 29 D-11 |
| C | C.1 | `R/as_d3_ir.R` lines 711–721 | Add comment documenting union-bbox behavior; no logic change | Phase 30 EC-2 |
| C | C.1 | `inst/htmlwidgets/modules/geoms/sf.js` near line 56 | Add comment documenting union-bbox contract for multi-layer plots | Phase 30 EC-2 |
| C | C.1 | `tests/testthat/test-sf-ir.R` | Add multi-layer sf test: 2 layers, union bbox, CRS consistent | Phase 30 EC-2 |
| C | C.2 | `R/as_d3_ir.R` lines 865–888 (`FacetWrap` panel loop) | Add `is_sf_coord` branch: per-panel bbox from panel-subset features; return `x_range = NULL, bbox = panel_bbox` | Phase 30 D-03 |
| C | C.2 | `inst/htmlwidgets/modules/geoms/sf.js` | Update `fitExtent` to use `options.panel.bbox` when present, else `ir.coord.bbox` | Phase 30 D-03 |
| C | C.2 | `tests/testthat/test-sf-visual.R` | Add faceted sf visual test with human-verify checkpoint | Phase 30 D-03 |
| C | C.3 | `inst/htmlwidgets/gg2d3.js` | Verify strip/axis suppression for sf panels; fix if needed (scope determined by spike) | Phase 30 D-04 |
| C | C.4 | `R/as_d3_ir.R` sf branch after line 356 | Add `warning()` when `sf_layer_gtype == "GEOMETRY"` (mixed types) | Phase 30 EC-1 |
| C | C.4 | `tests/testthat/test-sf-ir.R` | Add mixed-geometry regression test: expect_warning + GEOMETRY geom_type | Phase 30 EC-1 |

---

## Success Rubric

Self-check checklist for reviewer and for `/gsd-plan-phase` consumption.
Check each box against the document contents before marking the blueprint
as accepted.

- [ ] All three edge cases (mixed geometry, multi-layer stacking, faceted sf) have their own `## Edge Case N:` section with empirical-run-log citation
- [ ] Edge Case 1 section cites `test_output/30-edge-mixed-run.log` and reports `detect_dominant_geom_type()` returning `"GEOMETRY"`
- [ ] Edge Case 2 section cites `test_output/30-edge-multi-run.log` and reports two-layer IR with union `coord.bbox`
- [ ] Edge Case 3 section cites `test_output/30-edge-faceted-run.log` and reports the critical finding that per-panel `bbox` DOES NOT EXIST today
- [ ] Faceted-sf section explicitly locks per-panel `coord.bbox` via `d3.geoIdentity().reflectY(true).fitExtent()` per panel (D-03)
- [ ] Faceted-sf section enumerates the four D-04 build-phase verification items as a bulleted list (strip rendering, axis suppression, `coord_sf(xlim=,ylim=)`, `facet_wrap(scales=)` mirroring)
- [ ] Anti-Features section has exactly THREE subsections — Tile Basemaps, JS-Side Reprojection, Slippy Zoom — each one sentence
- [ ] Anti-Features section distinguishes anti-features from deferred ideas (D-06 protection); explicitly lists the four D-06 items NOT in the anti-features list
- [ ] Implementation Plan has three Build Phases (A, B, C) corresponding to core rendering, interactivity, and edge-case handling
- [ ] Every plan in Implementation Plan names at least one specific file AND a line number or named code construct (D-07 enforcement)
- [ ] All five integration-surface JS files are named with file/line callouts: `brush.js` lines 29–49 and near line 268; `sf.js` lines 84, 98–104; `events.js` lines 23–43; `zoom.js` near line 126; `tooltip.js`
- [ ] R-side integration (`as_d3_ir.R` sf branch) covered for `default_label_col` (lines 358–368), multi-layer bbox union (lines 711–721), and per-panel bbox (lines 865–888)
- [ ] `data-centroid`, `vector-effect`, `sf-zoom-layer`, and `INTERACTIVE_SELECTORS` all appear as named tokens (Phase 29 design-locked DOM vocabulary)
- [ ] Final summary table maps each change to file + concrete change + decision/requirement reference
- [ ] All three BLPR-01 edge cases get build plans in Phase C (multi-layer in C.1, faceted in C.2/C.3, mixed-geometry in C.4)
