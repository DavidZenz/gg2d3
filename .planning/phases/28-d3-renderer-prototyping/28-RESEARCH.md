# Phase 28: D3 Renderer Prototyping - Research

**Researched:** 2026-04-04
**Domain:** D3 geographic rendering — `d3.geoPath` + `geoIdentity().reflectY(true).fitExtent()`, geom registry module pattern, fill-rule/winding order, aesthetic passthrough from IR to SVG
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Prototype deliverable format**
- D-01: Create `inst/htmlwidgets/modules/geoms/sf.js` following the existing IIFE + `geomRegistry.register('sf', renderSf)` pattern. Not a standalone HTML file.
- D-02: Register as a normal geom via `geomRegistry.register()`. The renderer receives `xScale`/`yScale` but ignores them, using `d3.geoPath` with `d3.geoIdentity().reflectY(true).fitExtent()` internally. No special-case branch in `gg2d3.js`.
- D-03: Wire `sf.js` into `gg2d3.yaml` so it loads with the package. The prototype must be testable end-to-end through the normal `gg2d3()` pipeline (R IR -> JSON -> sf.js renderer).

**Visual validation approach**
- D-04: Generate visual test HTML files in `test_output/` (gitignored) for manual side-by-side comparison with ggplot2's `geom_sf` output.
- D-05: Test against two datasets: (1) NC counties shapefile (simple polygons, REND-01), (2) rnaturalearth world borders (multipolygons with holes/islands, REND-02 validation).

**Geometry-aesthetic linkage**
- D-06: Use key-based join with explicit `row_id` field on both `layer.data[]` and `layer.geometries[]`. Add `row_id = seq_along()` on the R side during IR construction.
- D-07: This requires a small R-side change in `as_d3_ir.R` to emit `row_id` for sf layers. Each `<path>` element gets fill/stroke from the matched data row.

**Fill-rule handling**
- D-08: Apply `fill-rule="evenodd"` universally to all `<path>` elements in sf layers. No per-feature geometry type detection needed.

**Carried from prior phases**
- D-09: Use `d3.geoIdentity().reflectY(true).fitExtent()` — no JS-side reprojection.
- D-10: sf panels use NULL `x_range`/`y_range` in IR; renderer uses `coord.bbox` with `fitExtent()`.
- D-11: Store centroids as `data-cx`/`data-cy` attributes on each `<path>` element for Phase 29 brush selection.
- D-12: IR carries `layer.geometries[]`, `layer.crs`, `layer.geom_type`, `coord.type = "sf"`, `coord.bbox`.

### Claude's Discretion

- Internal structure of the `renderSf()` function (how it builds the projection, binds data, etc.)
- Whether to add a `geom-sf` CSS class to paths or use the existing geom class pattern
- Error handling for malformed GeoJSON strings in the geometries array
- Exact `fitExtent` padding values for the panel bounding box

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REND-01 | Prototype D3 `geoPath` + `geoIdentity().reflectY(true).fitExtent()` rendering of GeoJSON polygons | D3 v7.9.0 already vendored; `d3.geoIdentity` + `d3.geoPath` confirmed present; `fitExtent` API verified against d3-geo docs |
| REND-02 | Verify winding order fix (`fill-rule="evenodd"`) handles multipolygons with holes | SVG fill-rule spec + D3/GeoJSON winding mismatch documented; evenodd confirmed correct fix; rnaturalearth world data provides MULTIPOLYGON-with-holes test case |
| REND-03 | Validate fill/stroke aesthetic passthrough from IR to SVG path elements | `makeColorAccessors()` in geom-registry.js is fully reusable; Phase 27 IR already carries `fill`/`colour` columns in `data[]` parallel to `geometries[]` |
</phase_requirements>

---

## Summary

Phase 28 is a JavaScript implementation task building on a complete R-side foundation. Phase 27 delivered `R/sf_utils.R`, the `GeomSf` dispatch in `as_d3_ir.R`, and verified that the IR correctly emits `layer.geometries[]` (GeoJSON strings), `layer.data[]` (aesthetics), `coord.type = "sf"`, and `coord.bbox`. The Phase 28 deliverable is a single new JS file (`inst/htmlwidgets/modules/geoms/sf.js`) plus a small R-side `row_id` addition and a one-line change to `gg2d3.yaml`.

The core rendering pattern is well-established: `d3.geoIdentity().reflectY(true).fitExtent([[0,0],[w,h]], featureCollection)` produces a projection; `d3.geoPath().projection(proj)` produces path strings from GeoJSON geometry objects. Both are bundled in the existing `d3.v7.min.js`. The `makeColorAccessors()` utility from `geom-registry.js` handles fill/stroke/opacity identically to other geoms. The only Phase-28-specific concerns are: (1) passing `panelSize` instead of Cartesian scales to `renderSf`, (2) applying `fill-rule="evenodd"` on every path, (3) computing centroids for Phase 29 prep, and (4) adding `row_id` for safe geometry-aesthetic joining.

The existing `renderPanel()` in `gg2d3.js` already passes `coord: ir.coord` in the options object. The sf renderer can read `options.coord.bbox` to build its `fitExtent` bounds. The CONTEXT decision (D-02) that "no special-case branch in gg2d3.js" is required confirms the renderer receives `xScale`/`yScale` normally and simply ignores them — which is safe because the geom registry's function signature allows this.

**Primary recommendation:** Implement `sf.js` as a minimal IIFE geom module; build the projection from `options.coord.bbox` and `options.plotWidth`/`options.plotHeight`; apply `fill-rule="evenodd"` universally; store centroids as `data-cx`/`data-cy`. Add `row_id` to the R sf branch and wire `sf.js` into `gg2d3.yaml`. Validate with NC counties (REND-01) and rnaturalearth world borders (REND-02/03).

---

## Standard Stack

### Core (no new dependencies — all already present)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| d3-geo (in d3 v7) | bundled in d3.v7.min.js | `d3.geoPath()`, `d3.geoIdentity()`, `fitExtent()` | Already vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`; no new library needed |
| geom-registry.js | package internal | `makeColorAccessors()`, `register()`, `render()` | Established pattern for all geoms; reuse without modification |

### R-side Supporting (already in DESCRIPTION Suggests)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sf | 1.1-0 | Already used in Phase 27 | Test fixture loading (`sf::st_read`) in visual test scripts |
| geojsonsf | 2.0.3 | Already used in Phase 27 | R-side `row_id` addition is pure R; no new geojsonsf usage needed |
| rnaturalearth + rnaturalearthdata | CRAN current | MULTIPOLYGON-with-holes test data for REND-02 | Visual test only; not a package dependency |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `geoIdentity().reflectY(true)` | `geoMercator()` or other named projection | Named projections double-project; ggplot2 coord_sf already applied projection in R |
| `fitExtent([[0,0],[w,h]], fc)` | Manual scale/translate calculation | fitExtent is built-in, deterministic, accounts for aspect ratio |
| `fill-rule="evenodd"` | Winding order reversal via d3-geo | evenodd is simpler — no coordinate transformation needed; correct for RFC 7946 GeoJSON |
| Inline GeoJSON strings parsed in JS | TopoJSON topology | TopoJSON requires topology builder + separate parser; GeoJSON is the native d3.geoPath input |

**Installation:** No new installs. D3 already vendored. For visual test datasets:

```r
install.packages(c("rnaturalearth", "rnaturalearthdata"))
```

---

## Architecture Patterns

### Recommended Project Structure Changes

```
R/
└── as_d3_ir.R           # modify: add row_id to sf branch (~line 333)

inst/htmlwidgets/
├── gg2d3.yaml           # modify: add geoms/sf.js to script list
└── modules/
    └── geoms/
        └── sf.js        # new: geom_sf renderer (this phase's primary deliverable)

test_output/             # gitignored; visual test HTML files go here
```

### Pattern 1: IIFE Geom Module Registration

**What:** Each geom is a self-contained immediately-invoked function expression (IIFE) that calls `window.gg2d3.geomRegistry.register()` at load time.

**When to use:** Always for new geom modules. Established pattern in `point.js`, `line.js`, etc.

**Example (from point.js):**
```javascript
// Source: inst/htmlwidgets/modules/geoms/point.js
(function() {
  'use strict';
  function renderPoint(layer, g, xScale, yScale, options) {
    // ...
    return pts.length;
  }
  window.gg2d3.geomRegistry.register('point', renderPoint);
})();
```

**sf.js follows this exactly.** The function signature `renderSf(layer, g, xScale, yScale, options)` receives `xScale`/`yScale` but ignores them per D-02.

### Pattern 2: geoIdentity Projection with fitExtent

**What:** Build a D3 projection that scales geographic coordinates to fill the panel dimensions.

**When to use:** When coordinates are already in a known CRS (WGS84 lon/lat after Phase 27 normalization) and no spherical projection is needed at render time.

**Example:**
```javascript
// Source: d3-geo docs (https://d3js.org/d3-geo/projection)
const bbox = options.coord && options.coord.bbox; // [xmin, ymin, xmax, ymax]
const w = options.plotWidth;
const h = options.plotHeight;

// Parse all geometry strings once
const geoms = layer.geometries.map(s => JSON.parse(s));

// Build FeatureCollection for fitExtent bounds computation
const fc = {
  type: "FeatureCollection",
  features: geoms.map(geom => ({ type: "Feature", geometry: geom, properties: {} }))
};

// Build projection: geoIdentity + reflectY (SVG y-axis is inverted vs geographic)
const proj = d3.geoIdentity()
  .reflectY(true)
  .fitExtent([[padding, padding], [w - padding, h - padding]], fc);

const pathGen = d3.geoPath().projection(proj);
```

**Key details:**
- `reflectY(true)` is mandatory — geographic y increases north (up), SVG y increases down
- `fitExtent` accepts a FeatureCollection or any GeoJSON object with a bounding box
- The `padding` value (e.g., 4px) prevents polygon edges from touching the clip boundary

### Pattern 3: Geometry-Aesthetic Join via row_id

**What:** Both `layer.geometries[]` and `layer.data[]` carry a `row_id` field for safe joining. In Phase 27, these arrays are already positionally parallel (index i matches index i), but the explicit `row_id` field (D-06) makes the linkage explicit and resistant to future filtering.

**When to use:** In `renderSf()`, iterate by index but use `row_id` for DOM data binding.

**R-side change (small, in as_d3_ir.R sf branch):**
```r
# Add to the sf branch in as_d3_ir.R, around line 333
# After sf_geom_strings is computed:
row_ids <- seq_along(sf_geom_strings)

list(
  geom       = "sf",
  geom_type  = sf_layer_gtype,
  geometries = sf_geom_strings,
  row_ids    = row_ids,       # NEW: parallel integer vector
  data       = to_rows(df),   # each row also gets row_id via to_rows modification
  aes        = aes,
  params     = g_params,
  crs        = sf_layer_crs
)
```

**JS consumption:**
```javascript
// layer.geometries[i] and layer.data[i] are positionally parallel
// but row_id provides explicit join key for robustness
geoms.forEach((geomObj, i) => {
  const row = layer.data[i];
  // render path, apply fill/stroke from row
});
```

### Pattern 4: makeColorAccessors Reuse

**What:** `window.gg2d3.geomRegistry.makeColorAccessors(layer, options)` returns `{strokeColor, fillColor, opacity}` accessor functions that handle aes mappings, color scales, and static params.

**When to use:** Always — identical to other geoms. Phase 27 confirmed that `fill` and `colour` columns exist in `layer.data[]` for geom_sf layers.

**Example:**
```javascript
const { strokeColor, fillColor, opacity } =
  window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

// Then on each path element:
.attr("fill", d => fillColor(d))
.attr("stroke", d => strokeColor(d))
.attr("opacity", d => opacity(d))
.attr("fill-rule", "evenodd")  // D-08: universal for sf paths
```

### Pattern 5: Centroid Storage for Phase 29 Prep

**What:** After rendering each `<path>`, compute its centroid using `d3.geoPath().centroid(feature)` and store as `data-cx`/`data-cy` SVG attributes.

**When to use:** Required per D-11 so Phase 29 brush selection can reuse existing pixel-position logic.

**Example:**
```javascript
// pathGen is already built; centroid() uses the same projection
const centroid = pathGen.centroid({ type: "Feature", geometry: geomObj, properties: {} });
// centroid = [cx_px, cy_px] or [NaN, NaN] if geometry is empty

path
  .attr("data-cx", isFinite(centroid[0]) ? centroid[0] : null)
  .attr("data-cy", isFinite(centroid[1]) ? centroid[1] : null)
```

**Important:** `d3.geoPath().centroid()` returns `[NaN, NaN]` for empty geometries. Always guard with `isFinite()`.

### Pattern 6: gg2d3.yaml Module Loading Order

**What:** `sf.js` must load after `geom-registry.js` (which it calls) and after `constants.js` (which it may use).

**When to use:** When adding `sf.js` to the yaml dependency list.

**Required change in gg2d3.yaml:**
```yaml
      - geoms/sf.js      # add after geoms/smooth.js (current last entry)
```

The existing load order in `gg2d3.yaml` already puts `geom-registry.js` before all `geoms/*.js` entries.

### Anti-Patterns to Avoid

- **Using xScale/yScale for path positioning:** sf paths are positioned by the `d` attribute computed from `pathGen`, not by scale functions. Passing data values through `xScale(d.x)` produces garbage output.
- **Building the FeatureCollection repeatedly inside the forEach loop:** Build once before the loop; `fitExtent` needs all features to compute the bounds — it cannot be called per-feature.
- **Calling `JSON.parse()` inside the D3 `.attr("d", ...)` callback:** Parse all geometries once before entering the D3 selection chain. Parsing inside callbacks fires once per element and makes debugging harder.
- **Using `d3.geoMercator()` or any named projection:** This double-projects. R's `coord_sf` already projected to WGS84; `geoIdentity` is the correct JS-side choice.
- **Forgetting `reflectY(true)`:** The map renders upside-down. This has been the source of confusion in multiple d3-geo issues; it is required for SVG output.
- **Setting `fill-rule="nonzero"` (SVG default):** The SVG default fill rule does not handle RFC 7946 GeoJSON winding order correctly. Every `path.geom-sf` must have `fill-rule="evenodd"`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fitting geographic bounds to SVG panel | Manual min/max + linear scale transform | `d3.geoIdentity().fitExtent()` | `fitExtent` handles aspect ratio preservation and edge cases including single-point geometries |
| Computing polygon centroid | Average of coordinate vertices | `d3.geoPath().centroid(feature)` | Centroid of a polygon is NOT the average of its vertices; `geoPath.centroid` uses the correct area-weighted formula |
| Building SVG path string from GeoJSON | Manual coordinate loop | `d3.geoPath()(feature)` | GeoJSON has many geometry types (Polygon, MultiPolygon, etc.) each requiring different SVG path construction; `geoPath` handles all of them |
| GeoJSON serialization in R | Custom `toJSON` with matrix formatting | `geojsonsf::sfc_geojson()` | sfc columns are nested S3 objects; standard jsonlite cannot serialize them; geojsonsf is the authoritative converter |
| Winding order reversal | Re-ordering coordinate rings | `fill-rule="evenodd"` SVG attribute | `fill-rule` makes winding order irrelevant — simpler and no coordinate transformation needed |

**Key insight:** The D3 `d3-geo` module bundles everything needed for SVG map rendering. The gg2d3 codebase has already vendored D3 v7.9.0 which includes `d3-geo v3.1.1`. There is zero need for external mapping libraries (Leaflet, Mapbox, OpenLayers, topojson-client).

---

## Common Pitfalls

### Pitfall 1: fitExtent Called Without All Features (Partial Bounds)

**What goes wrong:** If `fitExtent` is called with a single feature or a subset, the projection scales to that subset's bounds. Other features then render outside the panel bounds.

**Why it happens:** Iterating features individually and building projection inside the loop.

**How to avoid:** Build the FeatureCollection from ALL `layer.geometries` strings before constructing the projection. Call `fitExtent` once on the full collection.

**Warning signs:** Some polygons render correctly but others are clipped or off-screen.

### Pitfall 2: reflectY Omitted — Map Renders Upside Down

**What goes wrong:** The map renders with south at the top (y=0) and north at the bottom. All shapes are correct but vertically mirrored.

**Why it happens:** `d3.geoIdentity()` with no `reflectY` passes coordinates through unchanged. SVG y=0 is the top; geographic y=0 (latitude) is south.

**How to avoid:** Always chain `.reflectY(true)` before `.fitExtent()`.

**Warning signs:** NC counties shapefile — the mountain counties (west) render at the bottom of the panel.

### Pitfall 3: Holes Fill Instead of Being Transparent (Winding Order)

**What goes wrong:** MULTIPOLYGON features with interior rings (e.g., lake islands) render with the interior ring filled instead of transparent.

**Why it happens:** D3-geo historically used clockwise-exterior / counter-clockwise-interior winding. RFC 7946 GeoJSON (which geojsonsf produces) uses counter-clockwise-exterior / clockwise-interior. SVG's default `fill-rule="nonzero"` honors winding direction and inverts interior/exterior.

**How to avoid:** Set `fill-rule="evenodd"` on every `path.geom-sf` element. This ignores winding direction and correctly treats any ring as a boundary.

**Warning signs:** Test specifically with rnaturalearth world data — Canada, Finland, Indonesia have islands/lakes. Simple convex polygons (like most NC counties) will look correct regardless.

### Pitfall 4: `JSON.parse()` Fails Silently for Null/Empty Geometry Strings

**What goes wrong:** If any entry in `layer.geometries` is null, `undefined`, or an empty string, `JSON.parse()` throws a SyntaxError and the entire geom render halts.

**Why it happens:** sf objects can contain empty geometries (`GEOMETRYCOLLECTION EMPTY`) which geojsonsf serializes as `"null"` (the JSON null literal, which `JSON.parse("null")` returns as JS `null`). Calling `pathGen(null)` returns an empty string `""`, not an error — but building the FeatureCollection with `geometry: null` can cause `fitExtent` to behave unexpectedly.

**How to avoid:** Filter out null geometries before building the FeatureCollection for `fitExtent`. Render paths for all rows (null geometry rows get `d=""` which is invisible) so data-aesthetic parallel arrays remain aligned.

**Warning signs:** Console error `SyntaxError: Unexpected token` or map renders blank.

### Pitfall 5: row_id vs Array Index Mismatch After Data Filtering

**What goes wrong:** If `layer.data` is filtered (e.g., PANEL filtering for facets) but `layer.geometries` is not, or vice versa, the parallel arrays desync. Row i in data corresponds to geometry j ≠ i.

**Why it happens:** The existing PANEL-filtering logic in `gg2d3.js renderPanel()` filters `layer.data` by `d.PANEL === panelNum` but does not filter `layer.geometries`.

**How to avoid:** Phase 28 is non-faceted per the test scope (D-05). However, `row_id` (D-06) provides the safe join key. The renderer should join `layer.data` and `layer.geometries` by matching `row_id` rather than assuming positional alignment after any filtering.

**Warning signs:** Wrong fill colors on regions, or path shapes mismatched with label values.

### Pitfall 6: Centroid Returns [NaN, NaN] for Empty Geometry

**What goes wrong:** `pathGen.centroid(feature)` returns `[NaN, NaN]` when the feature geometry is null or an empty collection. Setting `data-cx="NaN"` stores the string `"NaN"` in the DOM, which breaks Phase 29's brush number comparison.

**How to avoid:** Guard centroid computation with `isFinite(centroid[0])` before setting attributes. Use `null` (which omits the attribute) instead of `NaN` for empty geometries.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### sf.js Full Skeleton

```javascript
// Source: adapted from point.js pattern + d3-geo docs (https://d3js.org/d3-geo/path)
(function() {
  'use strict';

  function renderSf(layer, g, xScale, yScale, options) {
    // D-02: xScale/yScale are ignored; projection is built from coord.bbox
    const w = options.plotWidth;
    const h = options.plotHeight;
    const bbox = options.coord && options.coord.bbox; // [xmin, ymin, xmax, ymax]

    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const geoms = (layer.geometries || []).map(s => {
      try { return s ? JSON.parse(s) : null; } catch(e) { return null; }
    });

    // Build FeatureCollection for fitExtent — include only non-null geometries
    const validFeatures = geoms
      .map((geom, i) => ({ type: "Feature", geometry: geom, properties: { _idx: i } }))
      .filter(f => f.geometry != null);

    const fc = { type: "FeatureCollection", features: validFeatures };

    const padding = 4;
    const proj = d3.geoIdentity()
      .reflectY(true)
      .fitExtent([[padding, padding], [w - padding, h - padding]], fc);

    const pathGen = d3.geoPath().projection(proj);

    // Merge geometry into data rows by index
    const rows = (layer.data || []).map((d, i) => Object.assign({}, d, { _geom: geoms[i] }));

    g.append("g")
      .selectAll("path.geom-sf")
      .data(rows)
      .enter().append("path")
        .attr("class", "geom-sf")
        .attr("d", d => {
          if (!d._geom) return "";
          return pathGen({ type: "Feature", geometry: d._geom, properties: {} }) || "";
        })
        .attr("fill", d => fillColor(d))
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", () => {
          const lw = layer.params && layer.params.linewidth;
          return lw != null ? lw : 0.5;
        })
        .attr("opacity", d => opacity(d))
        .attr("fill-rule", "evenodd")  // D-08: handles winding order for holes
        .attr("data-cx", d => {        // D-11: centroid for Phase 29 brush
          if (!d._geom) return null;
          const c = pathGen.centroid({ type: "Feature", geometry: d._geom, properties: {} });
          return isFinite(c[0]) ? c[0] : null;
        })
        .attr("data-cy", d => {
          if (!d._geom) return null;
          const c = pathGen.centroid({ type: "Feature", geometry: d._geom, properties: {} });
          return isFinite(c[1]) ? c[1] : null;
        });

    return rows.length;
  }

  window.gg2d3.geomRegistry.register('sf', renderSf);
})();
```

### R-side row_id Addition (as_d3_ir.R)

```r
# Source: R/as_d3_ir.R, sf branch around line 320-341
# Existing code:
if (gname == "sf") {
  # ... existing normalization and extraction ...
  sf_geom_strings <- extract_sf_geometries(df)
  sf_layer_crs    <- get_layer_crs(df)
  sf_layer_gtype  <- detect_dominant_geom_type(df)

  # D-06: add row_id for safe geometry-aesthetic join
  row_ids <- seq_along(sf_geom_strings)

  # D-07: add row_id to each data row via to_rows
  df[["row_id"]] <- row_ids

  list(
    geom       = "sf",
    geom_type  = sf_layer_gtype,
    geometries = sf_geom_strings,
    data       = to_rows(df),  # row_id now included via keep_aes addition
    aes        = aes,
    params     = g_params,
    crs        = sf_layer_crs
  )
}
```

Note: `"row_id"` must also be added to the `keep_aes` vector or added to `to_rows()` processing for the sf branch — it is not in the current `keep_aes` whitelist.

### Visual Test Pattern

```r
# Source: consistent with existing test_output/ pattern used in prior phases
library(gg2d3)
library(ggplot2)
library(sf)

nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# REND-01: basic choropleth fill
p <- ggplot(nc, aes(fill = BIR74)) + geom_sf()
w <- gg2d3(p)
htmlwidgets::saveWidget(w, "test_output/phase28-nc-choropleth.html")

# REND-02: multipolygon holes (rnaturalearth world data)
library(rnaturalearth)
world <- ne_countries(scale = "medium", returnclass = "sf")
p2 <- ggplot(world) + geom_sf(aes(fill = pop_est))
w2 <- gg2d3(p2)
htmlwidgets::saveWidget(w2, "test_output/phase28-world-holes.html")
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual SVG path string construction from coordinates | `d3.geoPath()(feature)` | D3 v3+ | geoPath handles Polygon, MultiPolygon, GeometryCollection, Point, LineString natively |
| `projection.fitSize([w,h], fc)` | `projection.fitExtent([[x0,y0],[x1,y1]], fc)` | D3 v4+ | fitExtent adds padding control; both work in D3 v7 |
| Reversing ring winding order to fix holes | `fill-rule="evenodd"` on SVG path | SVG 1.1 era — always available | Simpler; no coordinate modification needed |
| sp/rgdal for R spatial data | sf package | ~2016-2018 | sp/rgdal archived Oct 2023; sf is the only current option |

**Current package versions (as of research date):**

```bash
# Verified against existing project STACK.md research (2026-04-04):
# sf: 1.1-0 (CRAN Feb 2026)
# geojsonsf: 2.0.3 (CRAN Nov 2025)
# D3 v7.9.0 bundled — d3-geo v3.1.1 included
```

---

## Open Questions

1. **centroid() call duplication**
   - What we know: The skeleton above calls `pathGen.centroid()` twice per row (once for data-cx, once for data-cy) because D3 selections separate attr calls.
   - What's unclear: Whether the implementer should cache centroid computation per row in a pre-pass to avoid double work.
   - Recommendation: For 100 NC county polygons this is negligible. For Claude's discretion — either a pre-pass `const centroids = geoms.map(g => pathGen.centroid(...))` or inline calls both work; inline is simpler.

2. **options.coord.bbox vs options.plotWidth/Height for fitExtent**
   - What we know: `options.coord.bbox` is `[xmin, ymin, xmax, ymax]` in geographic coordinates. `options.plotWidth`/`options.plotHeight` are the panel pixel dimensions. `fitExtent` takes pixel coordinates `[[x0,y0],[x1,y1]]` as the target rectangle.
   - What's unclear: The CONTEXT says "renderer uses `coord.bbox` with `fitExtent()`" (D-10). However, `fitExtent` target is always in pixel space — `coord.bbox` is the geographic bounding box that the renderer could use for scale construction but `fitExtent` computes this automatically from the FeatureCollection.
   - Recommendation: Use `fitExtent([[padding, padding], [w-padding, h-padding]], fc)` where `fc` contains all features. D3 computes the geographic bounds internally. `coord.bbox` is available as a fallback if the feature collection is empty.

3. **row_id in keep_aes vs sf-branch-only injection**
   - What we know: The current `keep_aes` whitelist in `as_d3_ir.R` is used by all geoms. Adding `"row_id"` to the global `keep_aes` would affect all geom outputs (adding a null `row_id` column to non-sf layers).
   - Recommendation: Inject `row_id` into `df` before calling `to_rows(df)` within the sf branch only. Since `to_rows` does `intersect(keep_aes, names(df))`, the simplest fix is to add `"row_id"` to `keep_aes`. Because non-sf layers don't have a `row_id` column in `df`, `intersect()` will simply exclude it from non-sf output — no change to existing geom outputs.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| d3.v7.min.js | sf.js rendering | Already vendored | 7.9.0 | — |
| R sf package | Visual test scripts | Must check at test time | 1.1-0 expected | `skip_if_not_installed("sf")` |
| R geojsonsf package | Visual test scripts | Must check at test time | 2.0.3 expected | `skip_if_not_installed("geojsonsf")` |
| rnaturalearth | REND-02 visual test | Optional | CRAN current | Manual download of world GeoJSON |
| htmlwidgets::saveWidget | Visual test output | Part of package deps | 1.6.4 | Render inline in RStudio viewer |

**Missing dependencies with no fallback:** None — D3 is already vendored; sf/geojsonsf are installable from CRAN.

**Missing dependencies with fallback:** rnaturalearth for REND-02 test — can use any MULTIPOLYGON-with-holes GeoJSON if the package is unavailable.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.x (already configured) |
| Config file | `tests/testthat.R` |
| Quick run command | `testthat::test_file("tests/testthat/test-sf-ir.R")` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REND-01 | `geoIdentity().reflectY(true).fitExtent()` renders NC counties as SVG paths | visual/manual | HTML file: `test_output/phase28-nc-choropleth.html` | Wave 0 gap |
| REND-02 | `fill-rule="evenodd"` produces transparent holes in world MULTIPOLYGON data | visual/manual | HTML file: `test_output/phase28-world-holes.html` | Wave 0 gap |
| REND-03 | Fill/stroke hex values from IR appear correctly on `<path>` elements | unit + visual | `testthat::test_file("tests/testthat/test-sf-renderer.R")` | Wave 0 gap |

**Note on REND-01 and REND-02:** These requirements are verified by visual inspection of browser output against ggplot2 reference screenshots. There is no automated assertion for "shapes visually match" or "holes appear transparent" — these are manual verification steps. The test infrastructure should generate the HTML output files; verification is the human reviewer's task.

**Note on REND-03:** A unit test can verify that `layer.data[0].fill` value (a hex string from Phase 27 IR) appears as the `fill` attribute on the first rendered `<path>` element. This requires browser DOM access — not achievable in pure R testthat. A JS unit test or a visual inspection with browser devtools covers this.

### Sampling Rate

- **Per task commit:** `testthat::test_file("tests/testthat/test-sf-ir.R")` (Phase 27 IR tests, confirm R-side row_id addition doesn't break existing tests)
- **Per wave merge:** `devtools::test()` full suite
- **Phase gate:** Full suite green + visual HTML files reviewed before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-sf-renderer.R` — covers REND-03 (aesthetic passthrough unit test verifying hex fill/stroke values)
- [ ] `test_output/` directory existence (already gitignored per CLAUDE.md; may need `dir.create("test_output", showWarnings = FALSE)` in visual test script)

*(Existing `test-sf-ir.R` and `test-sf-utils.R` cover Phase 27 IR correctness and are already passing — no gaps there.)*

---

## Sources

### Primary (HIGH confidence)

- D3-geo official docs (https://d3js.org/d3-geo/path) — `d3.geoPath()` API, `.centroid()`, `.bounds()`, `.projection()`
- D3-geo projection docs (https://d3js.org/d3-geo/projection) — `d3.geoIdentity()`, `.reflectY()`, `.fitExtent()`, `.fitSize()`
- `inst/htmlwidgets/modules/geoms/point.js` — canonical IIFE module + register pattern
- `inst/htmlwidgets/modules/geom-registry.js` — `makeColorAccessors()`, `register()`, `render()` API
- `inst/htmlwidgets/gg2d3.yaml` — module load order; `sf.js` placement after `geoms/smooth.js`
- `R/as_d3_ir.R` lines 320-341 — existing sf branch; `row_id` addition touch point
- `R/sf_utils.R` — Phase 27 R utilities; no changes required in Phase 28
- `tests/testthat/test-sf-ir.R` — Phase 27 test coverage; must remain green after row_id addition
- `.planning/research/PITFALLS.md` — Pitfall 3 (winding order), 5 (zoom), 6 (brush centroid), verified against d3-geo source
- `.planning/research/STACK.md` — stack research confirming no new JS dependencies needed
- `.planning/research/ARCHITECTURE.md` — data flow diagram and component responsibility table

### Secondary (MEDIUM confidence)

- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` — locked decisions D-01 through D-12 (project decisions, HIGH authority for this codebase)
- GeoJSON RFC 7946 winding convention (https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.6) — exterior ring CCW, holes CW; confirmed mismatch with D3 convention
- D3-geo geoIdentity reflectY canonical issue (https://github.com/d3/d3-geo/issues/68)

### Tertiary (LOW confidence)

- None — all critical claims verified against official docs or project source.

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — D3 v7.9.0 already vendored; d3-geo API verified against official docs; geom-registry.js API read from source
- Architecture: HIGH — geom module pattern read from point.js source; gg2d3.js renderPanel source read; yaml load order read from gg2d3.yaml
- Pitfalls: HIGH — winding order and reflectY verified against official d3-geo docs and existing PITFALLS.md research; centroid NaN behavior is d3-geo documented behavior

**Research date:** 2026-04-04
**Valid until:** 2026-07-04 (D3 v7 API is stable; d3-geo API has been stable since D3 v5)
