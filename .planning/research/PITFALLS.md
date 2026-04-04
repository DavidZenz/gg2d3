# Pitfalls Research

**Domain:** Adding geom_sf / choropleth map rendering to an existing ggplot2-to-D3 pipeline (gg2d3 v1.7)
**Researched:** 2026-04-04
**Confidence:** HIGH (architecture known deeply; sf/D3-geo behavior verified against official docs and source)

---

## Critical Pitfalls

### Pitfall 1: sfc Geometry Column Breaks to_rows() Serialization

**What goes wrong:**
`as_d3_ir.R`'s `to_rows()` function iterates `ggplot_build()` layer data and converts each row to a plain R list. The geometry column in a geom_sf layer is of class `sfc` — an R list-column of `sfg` objects. `to_rows()` calls `v[[1]]` on each column per row, which extracts a single `sfg` object (e.g. a `MULTIPOLYGON`). When `jsonlite::toJSON()` serializes the resulting list, an `sfg` object is a nested list of numeric matrices. jsonlite serializes it as an arbitrary nested JSON array with no `type` property, no `coordinates` key — nothing that D3 can recognize as a GeoJSON geometry.

Separately, the `keep_aes` filter in `to_rows()` contains a fixed list of aesthetic names and does not include `geometry`. The geometry column may therefore be silently dropped before serialization even begins, leaving JavaScript with no polygon data and no error.

**Why it happens:**
`to_rows()` was designed for scalar aesthetics (x, y, color). It has no special handling for list-type geometry columns. The `keep_aes` whitelist was written before sf support was planned.

**How to avoid:**
Implement a dedicated `extract_sf_layer()` path in `as_d3_ir.R`. Detect geom_sf layers via `inherits(layer$geom, "GeomSf")`. Before calling `to_rows()`, extract the geometry column dynamically (see Pitfall 8 for column name lookup). Convert geometries to GeoJSON using `geojsonsf::sf_geojson()` or by calling `sf::st_transform()` then serializing with a GeoJSON writer. Store the per-row GeoJSON geometry objects in a parallel `geometries` array in the IR layer — do not mix them into the row data object. Then call `to_rows()` only on the non-geometry attribute columns.

**Warning signs:**
- geom_sf layer data arrives in JavaScript with no `geometry` property on each row object
- `d3.geoPath()(feature)` returns `null` or an empty string
- `jsonlite::toJSON()` produces `[[[[...]]]]` — deeply nested arrays with no `type` key

**Phase to address:**
Phase 1 (IR extraction design) — must be solved before any rendering work begins.

---

### Pitfall 2: coord_sf Replaces the Cartesian Scale System Entirely

**What goes wrong:**
When a ggplot has `geom_sf()`, ggplot2 automatically injects `coord_sf()`. `coord_sf()` is not a variant of `CoordCartesian` — it is a fundamentally different coordinate system. The existing `as_d3_ir.R` scale extraction reads `b$layout$panel_scales_x[[1]]` and expects `continuous` or `discrete` scale types with data-space `domain` and `breaks`. With `coord_sf`, these scale objects are geographic descriptors whose domain values are in the CRS's native units (degrees, meters, or projected units depending on the input data). The existing D3 `xScale`/`yScale` pipeline has no meaningful use for rendering polygon paths.

**Why it happens:**
The gg2d3 pipeline was designed around Cartesian and flipped-Cartesian coordinate systems. `coord_sf` is detectable via `inherits(b$plot$coordinates, "CoordSf")` but there is no branch for it — the code will fall through to the Cartesian path and produce meaningless scale domains that happen to serialize without error.

**How to avoid:**
Detect `CoordSf` early in `as_d3_ir.R` alongside the existing `CoordFlip` / `CoordTrans` checks. For sf layers, bypass the Cartesian scale extraction. Instead, read the bounding box from `sf::st_bbox()` on the geometry data after normalization to the target CRS. Emit the IR with a `coord: "sf"` marker and a `bbox: [xmin, ymin, xmax, ymax]` field. In the D3 renderer, use `d3.geoPath()` with a projection fitted to the panel dimensions via `.fitExtent()` rather than `xScale`/`yScale`.

**Warning signs:**
- Axis tick values are in degrees or meters rather than recognizable geographic ranges
- Polygon paths render as dots or fill the entire panel unexpectedly
- `b$layout$panel_scales_x[[1]]$limits` returns `c(-180, 180)` for a dataset covering a single US state

**Phase to address:**
Phase 1 (IR design) and Phase 2 (D3 renderer) — must be addressed in both layers before anything else works.

---

### Pitfall 3: Winding Order Mismatch Causes Holes to Fill Incorrectly in D3

**What goes wrong:**
D3's `d3.geoPath()` follows spherical polygon winding order conventions: exterior rings **clockwise**, interior rings (holes) **counter-clockwise** when viewed from outside the sphere. GeoJSON RFC 7946 specifies the opposite: exterior rings counter-clockwise, holes clockwise. The sf package and tools like `geojsonsf::sf_geojson()` output RFC 7946 compliant GeoJSON. When a MULTIPOLYGON with holes is serialized from sf and passed to `d3.geoPath()`, holes render as filled regions and filled regions render as holes — producing an inverted-donut appearance. No error is thrown.

**Why it happens:**
D3-geo predates RFC 7946 and follows TopoJSON/ESRI shapefile winding conventions, which are opposite. sf tools follow RFC 7946. This is a well-documented but silent mismatch in the ecosystem.

**How to avoid:**
Two options. Option A (preferred): set `fill-rule="evenodd"` on all `path.geom-sf` SVG elements. The SVG even-odd fill rule makes winding order irrelevant for determining inside/outside. Option B: use `d3.geoIdentity().reflectY(true)` as the projection, which corrects winding. Option A requires no coordinate transformation and is simpler. Either way, add a comment in the geom_sf renderer documenting which winding convention the incoming GeoJSON uses.

**Warning signs:**
- Countries with island lakes (e.g., Finland, Canada) appear as solid fills where lakes should be transparent
- Donut-shaped administrative regions fill the hole instead of the ring
- Simple convex polygons look correct but anything with interior rings looks inverted

**Phase to address:**
Phase 2 (D3 renderer implementation) — test with a MULTIPOLYGON that has at least one interior ring (hole) before considering the renderer complete.

---

### Pitfall 4: CRS Projection Coordinates Collapse Rendering for Non-WGS84 Input

**What goes wrong:**
sf objects can carry any CRS — EPSG:4326 (WGS84 lon/lat), EPSG:3857 (Web Mercator in meters), national grids (EPSG:27700 British National Grid has coordinates like `(532674, 181384)`), or custom projections. If the coordinates are passed to D3 in the native CRS without normalization, three failures occur: (1) coordinates in meters can be in the millions, completely outside D3's scale domain for a 600px panel; (2) `d3.geoPath()` with a geographic projection (Mercator, Natural Earth) expects WGS84 lon/lat degrees — passing projected coordinates produces garbled geometry; (3) for null projection, projected coordinates with origin offsets (e.g., BNG origin is SW of the UK) will render off-screen.

**Why it happens:**
Developers test with WGS84 data downloaded from the web and assume lon/lat is universal. Government, census, and national mapping agency data is almost always in a national projected CRS. The bug is invisible during development and catastrophic in production.

**How to avoid:**
Always normalize to WGS84 in R unconditionally inside `extract_sf_layer()`:
```r
geom_data <- sf::st_transform(geom_data, crs = 4326)
```
Apply this before any bounding box extraction or GeoJSON serialization. Do not make this optional or configurable in the MVP — WGS84 normalization should always happen. Document it as a known constraint.

**Warning signs:**
- All polygons appear at a single point near (0, 0)
- Polygon centroid coordinates in the IR are in the thousands or millions
- `sf::st_crs(layer_data)$epsg` returns something other than 4326

**Phase to address:**
Phase 1 (IR extraction) — enforce WGS84 normalization unconditionally at extraction time.

---

### Pitfall 5: D3 Zoom Architecture Is Incompatible with geoPath Re-rendering

**What goes wrong:**
The existing `zoom.js` module works by recalculating positions of individual SVG elements using updated D3 Cartesian scales and calling `updateGeoms()` in `geom-registry.js`. Geographic paths rendered by `d3.geoPath()` cannot be repositioned this way — their `d` attribute is a function of the projection, not of independent x/y scale lookups. On zoom, `updateGeoms()` will find no selector for `path.geom-sf` elements, silently skip them, and they will stay frozen at their original positions while axes update, producing a broken visual state.

**Why it happens:**
Geographic zoom works differently from Cartesian zoom. Two valid patterns exist: (1) transform the containing `<g>` with an SVG transform (fast, but stroke widths scale — already avoided in gg2d3 for good reason); (2) update the projection's scale/translate and re-render all path `d` attributes. gg2d3's zoom uses element repositioning (option 2 equivalent for Cartesian geoms). For geographic paths, option 2 requires storing the projection as a closure and calling `d3.geoPath()` again on each path element.

**How to avoid:**
For the sf geom renderer, store the geoPath generator and projection on the panel node: `panelNode.__gg2d3_geoPath = geoPath; panelNode.__gg2d3_projection = projection`. Register a dedicated update handler in `updateGeoms()` that selects `path.geom-sf` elements and recomputes their `d` attribute using the stored projection with updated scale/translate. The zoom module must call this handler after updating Cartesian scales.

If full geographic zoom is out of scope for the initial implementation, the simpler recovery is to detect geom_sf in `d3_zoom.R` and suppress zoom attachment, documenting it as a known limitation.

**Warning signs:**
- After zooming in, polygon paths remain at original position while axes rescale
- `updateGeoms()` emits no warning about skipped `path.geom-sf` elements
- Zooming out causes axes to show a wider range while map stays at original size

**Phase to address:**
Phase 3 (interactivity integration) — after the basic renderer works, address zoom explicitly. If deferred, document the limitation clearly.

---

### Pitfall 6: Brush Selection Logic Is Incompatible with Polygon Geometry

**What goes wrong:**
The existing `brush.js` highlights elements by comparing their SVG pixel positions (cx/cy for circles, bounding box for rects) against the brush rectangle bounds. For polygon `<path>` elements, there is no `cx`/`cy`. The `INTERACTIVE_SELECTORS` list does not include `path.geom-sf`. Brush applied to a map plot will show a selection rectangle but dim/highlight nothing — no error, silent failure.

**Why it happens:**
Brush highlighting was designed for scalar-position geoms (points, bars). Polygons are spatially extended — "is this polygon selected?" is a polygon-polygon intersection problem, not a point-in-rectangle test. The existing pixel-position approach does not generalize to paths.

**How to avoid:**
During geom_sf rendering, compute each polygon's centroid and store it as data attributes on the `<path>` element: `path.attr("data-cx", centroidX).attr("data-cy", centroidY)`. Centroids can be computed in D3 using `d3.geoPath().centroid(feature)`. Then add `path.geom-sf` to `INTERACTIVE_SELECTORS` and extend the brush highlight logic to check `data-cx`/`data-cy` the same way it checks `cx`/`cy` for circles. Document that brush selects by region centroid, not by spatial overlap — this is a deliberate tradeoff for implementation simplicity.

**Warning signs:**
- Brush rectangle appears and clears correctly but no polygon regions change opacity
- Console shows brush events firing but no elements match the selection
- `INTERACTIVE_SELECTORS` in `brush.js` does not contain `path.geom-sf`

**Phase to address:**
Phase 3 (interactivity integration) — add centroid attributes during Phase 2 renderer implementation to enable this; wire brush in Phase 3.

---

### Pitfall 7: Large Geometry Payloads Bloat the htmlwidgets HTML File

**What goes wrong:**
A US county shapefile (~3,000 counties at full resolution) produces a GeoJSON payload of 20-50MB. htmlwidgets embeds all data as inline JSON in the HTML output file. The consequences are: large Rmd knit files (>10MB) that may fail in some rendering environments; initial widget parse time of several seconds; browser tab memory spikes. Unlike tile-based mapping tools (Leaflet), gg2d3 embeds the complete geometry set in the page.

**Why it happens:**
ggplot2 users are accustomed to plotting sf data at full resolution because R's renderer handles it in-process without size constraints. The htmlwidgets inline-JSON pattern has no analogous pressure. Full-resolution administrative boundaries are visually indistinguishable from simplified versions at typical display resolutions (600-1200px wide).

**How to avoid:**
Two mitigations: (1) In the R extraction layer, reduce GeoJSON coordinate precision to 4 decimal places (~10m resolution) — sufficient for display at any realistic SVG size. Apply `sf::st_precision()` before serialization. (2) Add an IR payload size warning in `as_d3_ir.R` when the serialized geometry exceeds 1MB: `if (nchar(geojson_string) > 1e6) warning(...)`. Do not automatically simplify geometry — automatic simplification can alter recognized political boundaries in ways that surprise users. Instead, document `rmapshaper::ms_simplify()` as a recommended preprocessing step.

**Warning signs:**
- `object.size(ir)` reported by `as_d3_ir.R` exceeds several MB
- The knitted HTML file is >5MB
- Widget takes >2 seconds to appear in the browser after page load

**Phase to address:**
Phase 1 (IR extraction design) — add the size warning early and document simplification guidance before any rendering work ships.

---

### Pitfall 8: Geometry Column Name Is Not Always "geometry"

**What goes wrong:**
Any code in `extract_sf_layer()` that hardcodes `data[["geometry"]]` to locate the geometry column will silently return NULL when the sf object's geometry column has a non-standard name. sf allows any column name for the geometry list-column. Government data loaded from PostGIS databases frequently uses `the_geom`. ESRI shapefiles loaded via `sf::st_read()` default to `geometry` but this is not guaranteed for all drivers.

**Why it happens:**
Developers test with standard sf examples (which use `geometry`) and assume this name is universal. The sf class stores the active geometry column name as an attribute (`attr(obj, "sf_column")`), but this attribute may not survive `ggplot_build()` processing which can strip the sf class from the data frame.

**How to avoid:**
Always look up the geometry column name dynamically. First try: `geom_col <- attr(layer_data, "sf_column")`. If the sf class has been stripped, fall back to: `geom_col <- names(layer_data)[sapply(layer_data, inherits, "sfc")][1]`. Never hardcode `"geometry"`. Add a stop with an informative message if neither approach finds an sfc column.

**Warning signs:**
- No error is thrown but no polygons render; the layer appears empty
- Testing with a PostGIS-sourced dataset fails while the same shapes from a shapefile succeed
- `attr(b$data[[1]], "sf_column")` returns `"the_geom"` on real-world data

**Phase to address:**
Phase 1 (IR extraction) — write the lookup correctly from the start; test with a column named `the_geom`.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode `d3.geoMercator()` as the only projection | Ships faster, single rendering path | Breaks polar/conic/Equal-Earth projections users expect for thematic maps | MVP only — document the limitation explicitly |
| Pass geometry in native CRS without normalization to WGS84 | Saves one `st_transform()` call | Silent breakage for any non-WGS84 input — includes most government data | Never |
| Hardcode `"geometry"` as the geometry column name | Simpler code | Silent failure with PostGIS-loaded data and many real-world sources | Never |
| Use SVG `<g>` transform for geographic zoom instead of re-projecting | Trivially compatible with existing zoom module | Stroke widths scale with zoom — already rejected for Cartesian geoms | Never — suppress zoom or re-project properly |
| Embed full-resolution geometry without size warning | Simpler extraction code | Unusable widget for any real-world administrative boundary dataset | Never — add size warning at minimum |
| Add `path.geom-sf` to `INTERACTIVE_SELECTORS` without centroid attributes | Brush "works" (no crash) | Brush has zero visual effect on polygon regions; silent failure misleads users | Never — add centroid attributes first |
| Use WKT strings instead of GeoJSON for geometry transfer | Avoids winding order issue | Requires a WKT parser in JavaScript; no standard D3 utility exists for this | Never — use GeoJSON with `fill-rule="evenodd"` instead |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `to_rows()` / `keep_aes` filter | Assuming the geometry column survives the aesthetic filter | Bypass `to_rows()` for sf layers entirely; extract geometry before calling `to_rows()` on attribute columns |
| `jsonlite::toJSON()` | Calling it on a data frame that still has an `sfc` list-column | Strip or extract the geometry column before calling `toJSON()`; serialize geometry via `geojsonsf` separately |
| `geomRegistry.updateGeoms()` | Adding `path.geom-sf` to existing selector list without an update handler | Register a dedicated closure that re-runs `d3.geoPath()` with an updated projection for each sf path element |
| `brush.js` `INTERACTIVE_SELECTORS` | Adding the sf path class before centroid data attributes exist on path elements | Add `data-cx`/`data-cy` centroid attributes in the sf renderer first; only then update selectors |
| `validate_ir.R` | Forgetting to update the IR schema validator to accept the new `coord: "sf"`, `bbox`, and `geometries` fields | Add these as optional fields in the layer/IR schema; run validation on a geom_sf test plot |
| `coord_sf` detection | Detecting by `inherits(coord, "CoordSf")` but then still running Cartesian scale extraction | Short-circuit the entire Cartesian scale path; replace with bbox extraction |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full-resolution polygon paths in SVG | Browser paint time >2s; hover lag; scroll jank | Reduce coordinate precision to 4 decimal places; document `ms_simplify()` preprocessing | ~200 complex polygons (detailed coastlines, county-level US data) |
| Re-running `d3.geoPath()` on all paths during every zoom event tick | Choppy zoom; sustained CPU spike | Cache the path generator; recompute `d` attributes only on zoom end, not during zoom | Any polygon count — felt at 30+ polygons |
| Storing per-polygon GeoJSON as parsed JS objects instead of a single FeatureCollection | Excessive memory allocation during render | Serialize as one GeoJSON FeatureCollection string; parse once in JS; index by row | >100 polygons: memory doubles when geometry stored twice (IR + parsed objects) |
| Using `d3.brush()` area overlap check instead of centroid for polygon selection | CPU spike during brush move events (point-in-polygon per-frame per-polygon) | Store centroids as data attributes; reuse existing point-in-rectangle logic | Any count — the polygon intersection approach is O(n * vertices) per frame |

---

## "Looks Done But Isn't" Checklist

- [ ] **Geometry column lookup:** Verify the column is found via `attr(data, "sf_column")` + sfc class fallback, not hardcoded as `"geometry"` — test with a `the_geom` named column
- [ ] **Winding order:** Test with a MULTIPOLYGON that has at least one interior ring (hole) — verify holes are transparent not filled
- [ ] **CRS normalization:** Test with data in EPSG:3857 (Web Mercator) — verify polygons render at correct position and size after normalization
- [ ] **Brush highlighting:** Verify brush rectangle dims/highlights polygon regions — not just draws a rectangle with no effect
- [ ] **Zoom behavior:** Verify polygon paths reposition after zoom (or confirm zoom is explicitly suppressed with documentation)
- [ ] **Payload size warning:** Confirm warning fires when a US state polygon dataset is used without simplification
- [ ] **INTERACTIVE_SELECTORS:** Confirm `path.geom-sf` is absent from the selector list until centroid attributes are implemented in the renderer
- [ ] **Mixed layers:** Test a plot with geom_sf (polygons) AND geom_point on the same panel — confirm Cartesian point rendering is unaffected
- [ ] **IR validation:** Run `validate_ir.R` on a geom_sf plot — confirm it does not reject the new `coord`, `bbox`, and `geometries` fields

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| sfc column serialization breaks (pitfall 1) | LOW | Add a guard to strip or extract any `sfc` column before `to_rows()` and `toJSON()`; add dedicated `extract_sf_layer()` |
| Winding order bug found post-ship (pitfall 3) | LOW | Add `attr("fill-rule", "evenodd")` to all `path.geom-sf` elements; no R changes required |
| CRS normalization missing (pitfall 4) | MEDIUM | Add `sf::st_transform(data, 4326)` in the extraction path; no JS changes; all test inputs need to be re-run |
| Zoom incompatibility discovered (pitfall 5) | MEDIUM | Detect geom_sf in `d3_zoom.R` and suppress zoom with a warning; implement proper projection-based zoom in a follow-up phase |
| Brush incompatibility discovered (pitfall 6) | LOW | Add `d3.geoPath().centroid(feature)` centroid computation in the renderer, store as data attributes; update selectors |
| Oversized payload causing browser issues (pitfall 7) | LOW | Retroactively add the size warning; document `ms_simplify()` preprocessing; no rendering changes needed |
| Geometry column not found silently (pitfall 8) | LOW | Replace any hardcoded `"geometry"` string with the dynamic attribute lookup; add a stop with a clear message |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| sfc column breaks to_rows() serialization | Phase 1: IR extraction design | geom_sf plot serializes without error; `geometries` array arrives in JS as valid GeoJSON |
| coord_sf replaces Cartesian scale system | Phase 1: IR extraction design | IR contains `coord: "sf"` marker and `bbox` field; no Cartesian scale domains for sf layers |
| Winding order — holes render filled | Phase 2: D3 geom_sf renderer | MULTIPOLYGON with interior ring renders with transparent holes |
| CRS not normalized to WGS84 | Phase 1: IR extraction design | Test with EPSG:3857 input; polygons render correctly at expected location |
| D3 zoom incompatible with geoPath | Phase 3: Interactivity integration | After zoom, polygon paths reposition; OR zoom is suppressed with clear documentation |
| Brush incompatible with polygon geometry | Phase 3: Interactivity integration | Brush highlights/dims polygons by centroid; selector list updated only after centroid attributes exist |
| Large geometry payload | Phase 1: IR extraction design | Size warning fires for US county dataset; simplification guidance documented |
| Geometry column name not found | Phase 1: IR extraction design | Renderer finds geometry with `the_geom` column name without modification |

---

## Sources

- [ggplot2 ggsf reference — geom_sf / coord_sf / stat_sf](https://ggplot2.tidyverse.org/reference/ggsf.html)
- [ggplot2 layer_sf — sf geometry column auto-mapping](https://ggplot2.tidyverse.org/reference/layer_sf.html)
- [ggplot2 source R/geom-sf.R — geometry handling and draw_panel](https://rdrr.io/cran/ggplot2/src/R/geom-sf.R)
- [ggplot2 coord_sf scale interaction — issue #2846](https://github.com/tidyverse/ggplot2/issues/2846)
- [ggplot2 geometry column name detection — issue #2060](https://github.com/tidyverse/ggplot2/issues/2060)
- [ggplot2 geom_sf ggplot_build tibble column type conflict — issue #3453](https://github.com/tidyverse/ggplot2/issues/3453)
- [sf package — sfc simple feature geometry list column](https://r-spatial.github.io/sf/reference/sfc.html)
- [sf package — Plotting Simple Features vignette](https://r-spatial.github.io/sf/articles/sf5.html)
- [sf package — st_transform coordinate conversion](https://r-spatial.github.io/sf/reference/st_transform.html)
- [geojsonsf package — sf to GeoJSON conversion](https://cran.r-project.org/web/packages/geojsonsf/vignettes/geojson-sf-conversions.html)
- [D3-geo paths official documentation](https://d3js.org/d3-geo/path)
- [D3-geo projections official documentation](https://d3js.org/d3-geo/projection)
- [D3-geo GitHub README v3.1.0 — winding order conventions](https://github.com/d3/d3-geo/tree/v3.1.0)
- [GeoJSON winding order vs D3 convention analysis — macwright.com](https://macwright.com/2015/03/23/geojson-second-bite)
- [Tips for optimising large GeoJSON files](https://open-innovations.org/blog/2023-07-25-tips-for-optimising-geojson-files)
- [D3 choropleth hover interaction patterns](https://d3-graph-gallery.com/graph/choropleth_hover_effect.html)
- [d3-geo-zoom — geographic projection zoom library](https://github.com/vasturiano/d3-geo-zoom)
- [gg2d3 MEMORY.md — pixel-position brush design decision and D3 brush format notes](internal project memory)
- [gg2d3 brush.js — INTERACTIVE_SELECTORS and brush highlight architecture](internal codebase)
- [gg2d3 geom-registry.js — updateGeoms() architecture](internal codebase)
- [gg2d3 as_d3_ir.R — to_rows(), keep_aes, coord detection patterns](internal codebase)

---
*Pitfalls research for: geom_sf / choropleth map rendering added to gg2d3 v1.7*
*Researched: 2026-04-04*
