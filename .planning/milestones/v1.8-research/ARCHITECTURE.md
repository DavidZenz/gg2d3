# Architecture Research

**Domain:** gg2d3 v1.7 — geom_sf / choropleth integration into three-layer pipeline
**Researched:** 2026-04-04
**Confidence:** HIGH (pipeline mechanics verified against source), MEDIUM (ggplot_build sf output — inferred from ggplot2 source + documentation)

---

## System Overview

The existing three-layer pipeline and where geom_sf integration touches it:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         R Layer  (as_d3_ir.R)                                │
├──────────────────────────────────────────────────────────────────────────────┤
│  as_d3_ir()                                                                  │
│   ├─ ggplot_build(p) → b                                                     │
│   ├─ geom name dispatch (switch on class(gobj)[1])   ← ADD: GeomSf = "sf"   │
│   ├─ keep_aes column filter                          ← ADD: "geometry" col   │
│   ├─ to_rows() serialization                         ← CHANGE: skip geometry │
│   ├─ [NEW] extract_sf_geometries() per layer         ← NEW function          │
│   └─ [NEW] coord detection: CoordSf → map_coord IR  ← NEW branch            │
│                                                                              │
│  Output: IR JSON  ← geometry goes as GeoJSON strings, not row data          │
├──────────────────────────────────────────────────────────────────────────────┤
│                           IR Contract Layer                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│  ir = {                                                                      │
│    scales, panels, facets, coord, layers, guides, theme,                     │
│    interactivity, transitions, key_index                                     │
│  }                                                                           │
│                                                                              │
│  For sf layers, each layer object gains:                                     │
│    layer.geom = "sf"                                                         │
│    layer.geom_type = "polygon" | "multipolygon" | "point" | "linestring"    │
│    layer.geometries = [ GeoJSON geometry string, ... ]  ← per row           │
│    layer.crs = { epsg: 4326, proj4: "..." }                                 │
│    layer.data = [ { fill, colour, alpha, ... }, ... ]  ← aesthetics only    │
│                                                                              │
│  ir.coord gains:                                                             │
│    ir.coord.type = "sf"                                                      │
│    ir.coord.crs = { epsg: N, proj4: "..." }                                 │
│    ir.coord.bbox = [xmin, ymin, xmax, ymax]   ← in CRS units               │
├──────────────────────────────────────────────────────────────────────────────┤
│                    D3 Rendering + Interaction Layer                          │
├──────────────────────────────────────────────────────────────────────────────┤
│  gg2d3.js main render                                                        │
│   ├─ coord type check: if coord.type === "sf" → renderSfPanel()             │
│   └─ else → renderPanel() (existing, unchanged)                             │
│                                                                              │
│  modules/geoms/sf.js  (NEW)                                                  │
│   ├─ register("sf", renderSf)                                                │
│   ├─ d3.geoIdentity().reflectY(true).fitExtent([panel bounds], allFeatures) │
│   ├─ pathGen = d3.geoPath().projection(proj)                                 │
│   └─ SVG <path class="geom-sf"> per row                                     │
│                                                                              │
│  Interactivity modules (events.js, brush.js) ← ADD "path.geom-sf" selector │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | New vs Modified |
|-----------|----------------|-----------------|
| `as_d3_ir.R` — geom dispatch | Detect `GeomSf`, emit `"sf"` geom name | Modified (add case to switch) |
| `as_d3_ir.R` — geometry extraction | Call `geojsonsf::sfc_geojson()` on `b$data[[i]]$geometry` | New function `extract_sf_geometries()` |
| `as_d3_ir.R` — to_rows | Skip `geometry` column in aesthetic row serialization | Modified (exclude `geometry` from `keep_aes`) |
| `as_d3_ir.R` — coord extraction | Detect `CoordSf`, extract CRS + bbox for IR | Modified (add `CoordSf` branch) |
| `as_d3_ir.R` — CRS normalization | Reproject all sf layers to a common CRS before conversion | New helper (optional: use `sf::st_transform`) |
| IR contract | Add `geometries[]`, `crs`, `geom_type`, `bbox` fields on sf layers | New IR fields (additive, non-breaking) |
| `gg2d3.js` | Route `coord.type === "sf"` panels to sf render path | Modified (coord check in main render) |
| `modules/geoms/sf.js` | Parse GeoJSON strings, build D3 geoPath, render SVG paths | New file |
| `modules/events.js` | Add `path.geom-sf` to INTERACTIVE_SELECTORS | Modified |
| `modules/brush.js` | Add `path.geom-sf` to INTERACTIVE_SELECTORS | Modified |
| `modules/geom-registry.js` — `updateGeoms()` | Add sf path update for zoom (geoPath recompute) | Modified |

---

## Recommended Project Structure Changes

```
R/
├── as_d3_ir.R           # modified: GeomSf dispatch, geometry extraction, CoordSf coord
└── sf_utils.R           # new: extract_sf_geometries(), normalize_crs_for_ir()

inst/htmlwidgets/
├── gg2d3.js             # modified: sf coord routing
├── modules/
│   ├── geoms/
│   │   └── sf.js        # new: geom_sf renderer using d3.geoPath + geoIdentity
│   ├── events.js        # modified: add path.geom-sf to INTERACTIVE_SELECTORS
│   ├── brush.js         # modified: add path.geom-sf to INTERACTIVE_SELECTORS
│   └── geom-registry.js # modified: updateGeoms() sf path branch
└── gg2d3.yaml           # no changes needed (d3-geo is part of d3 v7 bundle)
```

### Structure Rationale

- **`sf_utils.R`**: Isolating sf-specific R code keeps `as_d3_ir.R` from growing further. sf is an optional dependency (Suggests, not Imports) — centralizing the `requireNamespace("sf")` and `requireNamespace("geojsonsf")` guards is cleaner.
- **`modules/geoms/sf.js`**: Follows the existing per-geom module pattern. Self-registers with `window.gg2d3.geomRegistry.register('sf', renderSf)`. Keeps geographic rendering logic isolated from Cartesian geoms.
- **No new JS dependencies**: `d3.geoPath`, `d3.geoIdentity` are in the vendored `d3.v7.min.js` already. No additional library required.

---

## Architectural Patterns

### Pattern 1: Geometry-Aesthetic Split

**What:** In the IR, geographic geometry (GeoJSON strings) and aesthetic data (fill, colour, alpha) are separated into parallel arrays rather than merged into a single row object.

**When to use:** Always for sf layers. The `geometry` column is an sfc list-column — it cannot be serialized by standard `jsonlite::toJSON()` and must be converted separately via `geojsonsf::sfc_geojson()`.

**Trade-offs:** Adds a parallel `geometries[]` array alongside `data[]`. JavaScript must zip them together by index. This is acceptable — sf layers are always positional (row i geometry matches row i aesthetics).

```r
# R extraction (in as_d3_ir.R)
extract_sf_geometries <- function(df) {
  geom_col <- df[["geometry"]]
  if (is.null(geom_col)) return(NULL)
  # Returns character vector: one GeoJSON string per row
  geojsonsf::sfc_geojson(geom_col)
}

# Layer output structure
list(
  geom      = "sf",
  geom_type = detect_dominant_geom_type(df),
  geometries = extract_sf_geometries(df),  # character vector, JSON-safe
  data      = to_rows(df),                 # aesthetics only, no geometry col
  aes       = aes,
  params    = g_params,
  crs       = list(epsg = get_epsg(df), proj4 = get_proj4(df))
)
```

```javascript
// JS consumption (in sf.js)
const geoms = layer.geometries;  // array of GeoJSON strings
const rows  = layer.data;        // array of aesthetic objects

geoms.forEach((geojsonStr, i) => {
  const geomObj = JSON.parse(geojsonStr);
  const aesthetics = rows[i];
  // render path using geomObj, style with aesthetics
});
```

### Pattern 2: geoIdentity Projection with fitExtent

**What:** Use `d3.geoIdentity().reflectY(true).fitExtent([[0,0],[w,h]], featureCollection)` to scale geographic coordinates to panel pixel dimensions, bypassing spherical projection math.

**When to use:** This is the correct approach when ggplot2's `coord_sf()` has already handled CRS projection by transforming all geometries to a common CRS. The coordinates in `b$data[[i]]$geometry` are already in the user's chosen CRS (typically EPSG:4326 lon/lat or a projected CRS). gg2d3 does not need to re-project — it just needs to fit those coordinates to the SVG panel dimensions.

**Trade-offs:**
- Simple, no spherical distortion calculation in JS
- Works for any CRS since it's purely a scale+translate fit
- Does NOT apply geographic projection effects (e.g., Mercator curvature) — acceptable because ggplot2's coord_sf already applied projection when the user specified one
- reflectY(true) is required: geographic coordinates have y increasing upward (north), SVG has y increasing downward

```javascript
// In sf.js renderSf()
function renderSf(layer, g, xScale, yScale, options) {
  const { w, h } = options.panelSize;  // panel pixel dimensions
  const geoms = layer.geometries.map(s => JSON.parse(s));

  // Build FeatureCollection for fitExtent bounds computation
  const fc = {
    type: "FeatureCollection",
    features: geoms.map(geom => ({ type: "Feature", geometry: geom, properties: {} }))
  };

  const proj = d3.geoIdentity()
    .reflectY(true)
    .fitExtent([[0, 0], [w, h]], fc);

  const pathGen = d3.geoPath().projection(proj);

  const { fillColor, strokeColor, opacity } =
    window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

  g.selectAll("path.geom-sf")
    .data(layer.data.map((d, i) => ({ ...d, _geom: geoms[i] })))
    .enter().append("path")
      .attr("class", "geom-sf")
      .attr("d", d => pathGen({ type: "Feature", geometry: d._geom, properties: {} }))
      .attr("fill", d => fillColor(d))
      .attr("stroke", d => strokeColor(d))
      .attr("opacity", d => opacity(d));

  return layer.data.length;
}
```

### Pattern 3: CRS Normalization in R Before IR Emission

**What:** Before calling `sfc_geojson()`, normalize all sf layer geometries to a single CRS — EPSG:4326 (WGS84 lon/lat) — using `sf::st_transform()`. Store the original CRS in the IR for reference.

**When to use:** Always, as a safety measure. coord_sf already reprojects layers to a common CRS internally, but the CRS stored in `b$data[[i]]$geometry` may differ per layer if coord_sf hasn't normalized them. Normalizing to EPSG:4326 also makes the IR CRS-agnostic: the JS side always receives lon/lat coordinates and `geoIdentity` fits them to the panel.

**Trade-offs:**
- Adds `sf::st_transform()` call in R — requires sf package (already a Suggests dependency for geom_sf to work at all)
- Slightly increases R-side computation for projected data
- Avoids CRS mismatch bugs where JS receives mixed-CRS geometries
- EPSG:4326 is the GeoJSON spec's expected CRS (RFC 7946), so this is semantically correct

```r
# In sf_utils.R
normalize_to_wgs84 <- function(geom_col) {
  if (!inherits(geom_col, "sfc")) return(geom_col)
  current_crs <- sf::st_crs(geom_col)
  if (!is.na(current_crs) && current_crs != sf::st_crs(4326)) {
    geom_col <- sf::st_transform(geom_col, 4326)
  }
  geom_col
}
```

---

## Data Flow

### geom_sf Render Flow

```
User: gg2d3(p)  where p has geom_sf() layer
    ↓
as_d3_ir(p)
    ↓
ggplot_build(p) → b
    ↓
b$data[[i]]  — sf data.frame with:
    ├─ geometry column (sfc, preserved by ggplot_build)
    ├─ fill, colour, alpha, size, linewidth, linetype columns
    └─ PANEL column
    ↓
extract_sf_geometries()
    ├─ normalize_to_wgs84(df$geometry)
    └─ geojsonsf::sfc_geojson(geom_col)  → character vector of GeoJSON strings
    ↓
to_rows(df)  — aesthetics only (geometry excluded from keep_aes)
    ↓
IR layer = { geom:"sf", geometries:[...], data:[{fill,...},...], crs:{...} }
    ↓
htmlwidgets serialization (jsonlite::toJSON)
    — geometries[] is plain character vector → JSON array of strings
    — data[] is plain list of named lists → JSON array of objects
    ↓
JS: sf.js renderSf()
    ├─ Parse each GeoJSON string
    ├─ Build FeatureCollection for fitExtent
    ├─ d3.geoIdentity().reflectY(true).fitExtent([panel dims], fc)
    ├─ d3.geoPath().projection(proj)
    └─ SVG <path class="geom-sf"> per row, styled from data[]
    ↓
SVG output in browser
```

### ggplot_build Output for sf Layers

Verified from ggplot2 source (`geom-sf.R`):

- `b$data[[i]]` for a `geom_sf` layer is a data frame where:
  - The `geometry` column is class `sfc` (simple feature collection) — **preserved through ggplot_build**
  - Aesthetic columns present: `fill`, `colour`, `size`, `linewidth`, `linetype`, `alpha`, `stroke`, `shape`
  - `PANEL` column present (for facet filtering)
  - `use_defaults()` splits rows by geometry type (point/line/polygon) to apply type-specific defaults, then recombines in original row order
- The class of the layer object in `b$plot$layers[[i]]$geom` is `GeomSf`
- `coord_sf` reprojects all layers to a common CRS and stores it; the CRS of `b$data[[i]]$geometry` is in the plot's target CRS

### Coord Detection for sf Maps

```
b$plot$coordinates class:
├─ CoordSf   → ir.coord.type = "sf"
│              ir.coord.crs  = sf::st_crs(coord$crs)
│              ir.coord.bbox = coord limits
├─ CoordFlip → existing handling (unchanged)
└─ CoordCartesian → existing handling (unchanged)
```

### Interactivity Flow for Map Regions

```
User hover/click on SVG path.geom-sf
    ↓
events.js INTERACTIVE_SELECTORS matches "path.geom-sf"
    ↓
Tooltip: data-tooltip from row data (d.fill value, region name if label aes)
    ↓
Hover: dim all path.geom-sf except hovered (existing dim pattern)
    ↓
Brush: pixel-position check against path bounding box
    (d3.select(el).node().getBBox() for path elements)
```

---

## Integration Points

### Modified: as_d3_ir.R

| Touch Point | Change |
|-------------|--------|
| `gname` switch statement | Add `GeomSf = "sf"` case |
| `keep_aes` vector | Do NOT add `"geometry"` — it must be excluded from to_rows |
| Layer list construction | Add `geometries` and `crs` fields when `gname == "sf"` |
| Coord detection block | Add `CoordSf` branch: extract CRS, bbox, emit `coord.type = "sf"` |

### New: R/sf_utils.R

| Function | Purpose |
|----------|---------|
| `extract_sf_geometries(df)` | Normalizes CRS to WGS84, calls `sfc_geojson()`, returns character vector |
| `normalize_to_wgs84(geom_col)` | Transforms sfc to EPSG:4326 if not already |
| `detect_dominant_geom_type(df)` | Returns `"polygon"`, `"multipolygon"`, `"point"`, etc. from `sf::st_geometry_type()` |
| `get_layer_crs(df)` | Extracts CRS as list `{epsg, proj4}` from geometry column |

### New: inst/htmlwidgets/modules/geoms/sf.js

| Responsibility | Implementation |
|----------------|----------------|
| Parse GeoJSON strings | `JSON.parse(layer.geometries[i])` per row |
| Build projection | `d3.geoIdentity().reflectY(true).fitExtent(...)` |
| Build path generator | `d3.geoPath().projection(proj)` |
| Render SVG paths | `g.selectAll("path.geom-sf").data(...).enter().append("path").attr("d", pathGen)` |
| Apply aesthetics | `makeColorAccessors(layer, options)` (existing utility) |
| Self-register | `window.gg2d3.geomRegistry.register('sf', renderSf)` |

### Modified: inst/htmlwidgets/gg2d3.js

The main render entry point needs a routing branch for sf coordinate panels. Current `renderPanel()` creates Cartesian x/y scales — these are not meaningful for geographic data. sf panels need a bypass that skips Cartesian scale creation and calls the sf renderer directly.

```javascript
// In gg2d3.js factory, at renderPanel dispatch:
if (ir.coord && ir.coord.type === 'sf') {
  // sf panels: skip Cartesian scales, pass panel dims to sf renderer
  renderSfPanel(root, parentGroup, panelBox, panelData, ir, theme, convertColor, panelNum, isFaceted);
} else {
  renderPanel(...);  // existing
}
```

`renderSfPanel()` creates a panel group, draws background and clip path (same as `renderPanel`), then calls `geomRegistry.render()` with `options.panelSize = { w, h }` instead of D3 Cartesian scales.

### Modified: INTERACTIVE_SELECTORS (events.js, brush.js)

Add to both arrays:
```javascript
'path.geom-sf',  // geom_sf polygon/multipolygon/linestring
```

### Modified: geom-registry.js updateGeoms()

sf paths must be redrawn (not just repositioned) when zoom changes, because the path `d` attribute is computed from the geoPath generator which bakes in the projection transform. Add:

```javascript
// In updateGeoms(), after other geom updates:
// geom_sf paths: cannot be repositioned with scale — must be regenerated
// The sf.js module must expose a re-render function that updateGeoms() can call.
// Simplest approach: tag sf paths with data-panel attribute and trigger
// a panel-level re-render rather than per-element repositioning.
```

**Note on zoom:** Standard D3 zoom for sf maps uses `d3.zoom()` applied at the SVG level, storing a transform. sf paths are typically zoomed via an SVG `<g transform="...">` group rather than recomputing geoPath. This is different from the existing Cartesian zoom which redraws axes and repositions elements. The sf renderer can store the geoPath generator and re-apply to the selection on zoom events.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Small maps (<100 features) | One SVG path per feature — current approach, no issue |
| Medium maps (100-1000 features) | Path simplification in R via `sf::st_simplify()` before IR emission; still one path per feature |
| Large maps (>1000 features) | Consider Canvas rendering via `d3.geoPath().context(canvasCtx)` instead of SVG; gg2d3 is SVG-only by design, so simplification is the lever |
| GeoJSON payload size | Choropleth data is typically 50-500 features with complex polygon boundaries; consider `rmapshaper::ms_simplify()` or tolerance parameter in `sfc_geojson()` |

---

## Anti-Patterns

### Anti-Pattern 1: Putting Geometry in the Row Data

**What people do:** Add `"geometry"` to `keep_aes` and let `to_rows()` serialize it alongside other columns.

**Why it's wrong:** sfc columns are R list-columns containing S3 objects. `jsonlite::toJSON()` will either error, emit `{}`, or produce unusable output. The existing `to_rows()` function handles list-columns with `I(col)` passthrough (for boxplot outliers), but sfc columns are not JSON-serializable even with that workaround.

**Do this instead:** Extract geometries separately via `geojsonsf::sfc_geojson()` before `to_rows()`, exclude `"geometry"` from `keep_aes`, and pass geometries as a parallel `layer.geometries` array.

### Anti-Pattern 2: Using a Geographic Projection in JS

**What people do:** Apply `d3.geoMercator()` or another spherical projection in JavaScript to the GeoJSON coordinates received from R.

**Why it's wrong:** ggplot2's `coord_sf()` already handled projection in R. The coordinates in `b$data[[i]]$geometry` are in the user's target CRS. Applying a second projection in JS double-projects and distorts the geometry. Additionally, the visual output would no longer match ggplot2's rendered output.

**Do this instead:** Use `d3.geoIdentity().reflectY(true).fitExtent(...)` to perform a pure scale+translate fit to the panel dimensions. This respects the projection ggplot2 already applied.

### Anti-Pattern 3: Reusing Cartesian xScale/yScale for sf Rendering

**What people do:** Pass the existing Cartesian `xScale` and `yScale` (built from `ir.scales.x` and `ir.scales.y`) to the sf renderer instead of routing through `renderSfPanel()`.

**Why it's wrong:** sf plots don't have Cartesian x/y scales in the ggplot2 sense. The `ir.scales.x` / `ir.scales.y` fields are not populated by `coord_sf()` — the coordinate bounds are stored in `ir.coord.bbox`. Attempting to use non-existent Cartesian scales will cause crashes or render nothing.

**Do this instead:** The sf render path must bypass Cartesian scale creation entirely. Pass `panelSize = { w, h }` in the options object instead of `xScale`/`yScale`, and build the `geoIdentity` projection inside the sf renderer.

### Anti-Pattern 4: Forgetting reflectY

**What people do:** Use `d3.geoIdentity().fitExtent(...)` without `.reflectY(true)`.

**Why it's wrong:** Geographic coordinate systems (including EPSG:4326) have y increasing northward (up). SVG has y increasing downward. Without `reflectY(true)`, the map renders upside-down.

**Do this instead:** Always chain `.reflectY(true)` before `.fitExtent()` when using `geoIdentity` for geographic data.

### Anti-Pattern 5: Treating sf Zoom Like Cartesian Zoom

**What people do:** Add `path.geom-sf` to the existing `updateGeoms()` zoom repositioning using scale functions.

**Why it's wrong:** sf path shapes (the SVG `d` attribute) are computed from a projection object, not from x/y scale functions. Repositioning by updating `cx`/`cy` or `x`/`y` attributes does not apply to path elements whose shape is defined by `d`. The existing zoom approach translates data domain → pixel position; sf paths bake both position and shape into a single `d` string.

**Do this instead:** For sf zoom, store the rendered geoPath generator and the D3 zoom transform. On zoom, apply a CSS/SVG `transform` to the sf layer group (translate+scale), or re-render the paths with an adjusted `fitExtent` that accounts for the zoom level.

---

## Suggested Build Order

Based on component dependencies and risk:

### Phase 1: R Extraction (no JS dependency)
1. Add `GeomSf = "sf"` to geom dispatch switch in `as_d3_ir.R`
2. Create `R/sf_utils.R` with `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`
3. Integrate geometry extraction into layer construction: emit `geometries[]` and `crs` fields
4. Add `CoordSf` detection to coord extraction block
5. Exclude `"geometry"` from `keep_aes` in the sf layer branch
6. Write R tests: verify IR structure, verify geometry is GeoJSON strings, verify aesthetics in data[]
7. Add `sf` and `geojsonsf` to DESCRIPTION `Suggests`

### Phase 2: Basic D3 Rendering (no interactivity)
1. Create `modules/geoms/sf.js` with basic `renderSf()` using `geoIdentity` + `geoPath`
2. Add `renderSfPanel()` to `gg2d3.js` main render
3. Add coord routing: `if (ir.coord.type === 'sf') renderSfPanel(...)`
4. Update `gg2d3.yaml` to include `sf.js` in module loading order (after geom-registry.js)
5. Visual test: render a simple world map choropleth, verify orientation and fill colors

### Phase 3: Interactivity Wiring
1. Add `'path.geom-sf'` to INTERACTIVE_SELECTORS in `events.js`
2. Add `'path.geom-sf'` to INTERACTIVE_SELECTORS in `brush.js`
3. Verify tooltip shows fill value and any label aesthetic on hover
4. Verify brush dim/highlight works on polygon regions

### Phase 4: Zoom Integration
1. Decide approach: SVG group transform vs geoPath re-render (SVG group transform is simpler)
2. Implement sf-specific zoom behavior: apply zoom transform to sf panel group element
3. Coordinate with existing zoom.js to not apply Cartesian axis repositioning for sf panels

### Phase 5: Edge Cases and Polish
1. MultiPolygon handling (already in GeoJSON spec; `d3.geoPath` handles it natively)
2. GeometryCollection layers (mixed polygon + point within one sf layer)
3. Non-polygon geometry types: LineString (use same geoPath, just no fill) and Point (render as circles using geoPath's `.pointRadius()`)
4. Faceted sf maps (each panel has same features but different data values — filter by PANEL column)

---

## Sources

- [ggplot2 geom-sf.R source](https://github.com/tidyverse/ggplot2/blob/main/R/geom-sf.R) — geometry column preserved through ggplot_build, aesthetics applied per geometry type
- [ggplot2 ggsf reference](https://ggplot2.tidyverse.org/reference/ggsf.html) — geometry aesthetic is sfc class, coord_sf controls CRS
- [d3-geo path documentation](https://d3js.org/d3-geo/path) — d3.geoPath API, SVG path string output, geoPath.bounds for bounding box
- [d3-geo projection documentation](https://github.com/d3/d3/blob/main/docs/d3-geo/projection.md) — geoIdentity.reflectY(true), fitExtent/fitSize API
- [geojsonsf package](https://github.com/SymbolixAU/geojsonsf) — sfc_geojson() converts sfc column to character vector of GeoJSON strings
- [geojsonsf vignette](https://cran.r-project.org/web/packages/geojsonsf/vignettes/geojson-sf-conversions.html) — atomise=TRUE for per-row GeoJSON
- [d3-geo geoIdentity reflectY issue](https://github.com/d3/d3-geo/issues/68) — canonical reference for why reflectY is needed
- [ggplot2-book maps chapter](https://ggplot2-book.org/maps.html) — coord_sf CRS behavior, default_crs parameter

---

*Architecture research for: gg2d3 v1.7 geom_sf choropleth integration*
*Researched: 2026-04-04*
