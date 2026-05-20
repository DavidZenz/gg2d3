# Feature Research

**Domain:** Choropleth map rendering via geom_sf in gg2d3 (ggplot2-to-D3 bridge)
**Researched:** 2026-04-04
**Confidence:** HIGH (ggplot2 + sf + D3 official docs), MEDIUM (interactivity patterns, pipeline integration)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that users who call `ggplot() + geom_sf(aes(fill = variable))` assume will work.
Missing any of these = the renderer is not usable for choropleth work.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Polygon region rendering** | Core purpose of geom_sf; a filled polygon is the atomic unit of a choropleth | HIGH | Must extract sfc_POLYGON / sfc_MULTIPOLYGON geometry from ggplot_build output and convert to GeoJSON for d3.geoPath(). The `geometry` column in ggplot_build data is a list-column of `sf` / `sfc` objects — not a standard scalar column. |
| **Fill aesthetic mapped to a data variable** | The entire point of a choropleth is coloring regions by a value | MEDIUM | `fill` aesthetic is already supported in the IR; the challenge is the geometry extraction, not the color mapping. ggplot_build computes fill values per row, so each feature row carries its resolved fill hex color. |
| **Continuous sequential/diverging fill scales** | scale_fill_viridis_c, scale_fill_distiller, scale_fill_gradient are the standard choropleth color choices | MEDIUM | Existing scale system in gg2d3 handles these; main concern is that the fill legend (colorbar) must coexist with the map region rendering. |
| **Discrete/categorical fill scales** | Categorical choropleths (e.g., political maps) are extremely common | MEDIUM | scale_fill_brewer, scale_fill_manual — again existing scale support; the legend toggle behavior should mirror other discrete geoms. |
| **Boundary / outline stroke** | Users expect visible region borders (colour aesthetic on geom_sf) | LOW | D3 path elements naturally render stroke; must pass `colour` and `linewidth` (mapped from ggplot_build) through the IR. |
| **Aspect ratio preservation** | Maps must not be distorted — geographic shapes must look geographically correct | MEDIUM | coord_sf enforces a lat/lon aspect ratio. D3 projections respect this automatically when fitExtent() or fitSize() is used. Must not reuse the Cartesian scale system for geo coordinates. |
| **theme_void() / theme_map() compatibility** | Standard choropleth workflow suppresses axes, grids, and panel background | LOW | Existing theme system supports theme_void() — requires verifying that when panel.background and axis elements are blank, the map region fills the plot area. |
| **No Cartesian axes on map output** | Lat/lon axes are noise for most choropleth uses and users hide them | LOW | When coord_sf is detected, axes should be suppressed by default (or controlled by theme). Graticule lines are separate from axes. |
| **Legend for fill variable** | colorbar (continuous) or discrete swatches — existing gg2d3 legend system | MEDIUM | Dependency: existing legend renderer must handle map context without axis/scale system interference. |

### Differentiators (Competitive Advantage)

Features that would make gg2d3's choropleth support meaningfully better than `plot(sf_object)` or a static ggplot2 map.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Hover tooltip on region** | Users want to see region name + data value on hover — static choropleths cannot do this | MEDIUM | Existing d3_tooltip() machinery works on SVG elements. Each region path element needs data attributes (region identifier, fill value, raw data value) so tooltip template can read them. This is the primary interactive differentiator. |
| **Hover highlight (opacity/stroke change on region)** | Visual confirmation of which region is selected — essential for dense maps | LOW-MEDIUM | d3_hover() already manages opacity-based highlight for other geoms; must extend INTERACTIVE_SELECTORS to include `.geom-sf` paths. Standard D3 choropleth pattern. |
| **Click-to-select region with brush state** | Enables linked views: select a state, linked bar chart filters | HIGH | Requires extending brush/selection mechanism to work on polygon hits, not just rectangular SVG bounding boxes. Pixel-hit-test on polygon boundary is more complex than a rect. |
| **Binned stepped fill scale support** | scale_fill_steps / scale_fill_steps2 create discrete bins from continuous data — common for choropleths | LOW | These resolve to discrete hex values per row in ggplot_build; no special IR handling needed beyond existing fill support. Worth explicitly validating. |
| **Multiple geom_sf layers** | Users overlay state polygons + city points, or country borders + administrative borders | HIGH | Each layer is independent; mixed geometry types (polygon layer + point layer) must coexist. Each layer dispatches to its own renderer. Point/line geom_sf layers use existing point/line renderers; only polygon dispatch is new. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Full CRS / projection system in D3** | Users want coord_sf(crs = ...) to control the D3 map projection | coord_sf's CRS handling is deeply coupled to sf's R-side geometry transformation (st_transform). Replicating arbitrary EPSG projection math in JavaScript is scope explosion. Each projection has different distortion models. | Project geometries to WGS84 (EPSG:4326) in R before serialization using st_transform(), then use D3's null (identity) or geoMercator projection on pre-projected GeoJSON. Let R do the CRS work. |
| **Tile/raster basemap background** | Users want OpenStreetMap behind their choropleth | Requires HTTP tile fetching, raster compositing, zoom/pan tile management — this is a Leaflet concern, not gg2d3's SVG-only mandate | Recommend leaflet or mapview for tile-backed maps; gg2d3 choropleth is SVG-only with no tile background |
| **Zoom/pan like a slippy map** | Users associate interactive maps with zoom-scroll pan behavior | D3 geo zoom exists (d3.zoom() on geoPath) but conflicts with the existing plot zoom (d3_zoom()) which operates in Cartesian screen space. Map zoom needs to rescale the projection's scale + translate, not the SVG viewBox. | Defer map-specific zoom to v2+; existing d3_zoom() is Cartesian and would distort the projection |
| **geom_sf_text / geom_sf_label rendering** | Region labels are common in published maps | geom_sf_text uses sf interior point calculation (st_point_on_surface) to position labels — this coordinate must be extracted and projected through the same transform as geometries | Feasible but scope-increasing for MVP; defer to a separate phase |
| **Real-time GeoJSON streaming or remote URLs** | Users want to point at a remote shapefile | Requires async fetching, CORS management, format parsing — all outside the htmlwidgets synchronous data-passing model | All geographic data must be pre-loaded in R and passed through the IR as serialized GeoJSON |

---

## Feature Dependencies

```
Polygon region rendering
    └──requires──> Geometry extraction from ggplot_build sfc list-column
    └──requires──> sf-to-GeoJSON conversion in R (sf::st_as_sf / geojsonsf / jsonlite)
    └──requires──> IR: new "geometry" field on sf layer (GeoJSON FeatureCollection or array of feature objects)
    └──requires──> D3: new geom-sf renderer using d3.geoPath()
    └──requires──> D3: projection setup (null identity or fitExtent to plot area)

Fill aesthetic on choropleth
    └──requires──> Polygon region rendering (above)
    └──enhances──> Existing fill scale system (already built)
    └──enhances──> Existing legend/colorbar system (already built)

Hover tooltip on region
    └──requires──> Polygon region rendering
    └──enhances──> Existing d3_tooltip() (already built)
    └──requires──> Data attributes on path elements (region name, value)

Hover highlight
    └──requires──> Polygon region rendering
    └──enhances──> Existing d3_hover() (already built, needs INTERACTIVE_SELECTORS extension)

Multiple geom_sf layers
    └──requires──> Polygon region rendering (base case)
    └──requires──> Point/Line geom_sf layers (point/line renderers already exist)
    └──requires──> Geometry-type dispatch in geom-sf renderer (POLYGON → path, POINT → circle, LINESTRING → path)

Click-to-select (linked views)
    └──requires──> Hover highlight
    └──requires──> Polygon region rendering
    └──conflicts──> Rectangular brush (d3.brush() uses bounding boxes, not polygon hits)
```

### Dependency Notes

- **Geometry extraction is the foundational blocker.** Everything else in the choropleth feature set depends on successfully pulling `sfc` geometry objects from `ggplot_build()` data and converting them to GeoJSON in R. If this is not feasible (e.g., the geometry column is stripped by ggplot_build), the entire feature set is blocked. This is the first feasibility question to resolve.
- **CRS must be normalized in R, not JavaScript.** All geometries should be projected to WGS84 (EPSG:4326) using `sf::st_transform()` before serialization. D3 then uses `d3.geoIdentity().fitExtent()` to map lon/lat coordinates into pixel space. This avoids implementing any projection math in JS.
- **IR extension is narrow.** The existing IR layer only needs a new `geojson` field on sf-type layers (a GeoJSON FeatureCollection string or object). The rest of the IR structure (scales, theme, coord) can be inherited mostly as-is — though coord detection must flag `CoordSf` as a special case.
- **Interactivity extensions are additive.** Adding `.geom-sf` to INTERACTIVE_SELECTORS and ensuring path elements carry data attributes is low-risk and follows existing patterns from v1.6's interactivity wiring.
- **Rectangular brush conflicts with polygon hit-testing.** d3.brush() uses rectangular selection; polygon regions are not axis-aligned. Click-to-select is feasible; rectangular brush-over-region is not without significant custom hit-testing code.

---

## MVP Definition

### Launch With (v1.7 implementation scope, if feasibility confirmed)

Minimum viable choropleth: a user can call `gg2d3(ggplot(data) + geom_sf(aes(fill = value)))` and get a correctly rendered, hoverable choropleth with a color legend.

- [ ] **Geometry extraction from ggplot_build sfc column** — feasibility gate; must work before any other feature
- [ ] **sf-to-GeoJSON conversion in R** — using base sf package (`sf::st_as_text()` or `geojsonsf::sf_geojson()`), outputs embedded in IR as string
- [ ] **IR: new layer type `"geom_sf"` with `geojson` field** — minimal IR extension
- [ ] **D3: geom-sf renderer** — uses `d3.geoPath()` + `d3.geoIdentity().fitExtent()` to render polygons as `<path>` elements with fill/stroke from IR data
- [ ] **Fill aesthetic passthrough** — ggplot_build already resolves fill hex per row; bind to path element fill
- [ ] **Stroke (colour) and linewidth passthrough** — same binding pattern
- [ ] **Hover tooltip** — extend d3_tooltip() with `.geom-sf` selector; ensure path elements have data-tooltip attributes
- [ ] **Hover highlight** — extend INTERACTIVE_SELECTORS in d3_hover() to include `.geom-sf`
- [ ] **theme_void() panel suppression** — verify axes/grids are hidden correctly when coord_sf detected

### Add After Validation (v1.7.x)

Features to add once baseline polygon rendering is proven.

- [ ] **POINT and LINESTRING geom_sf dispatch** — route point geometries to circle renderer, line geometries to path renderer; reuse existing geoms
- [ ] **Multiple geom_sf layer stacking** — second geom_sf layer (e.g., borders overlay) on top of fill layer
- [ ] **Stepped/binned fill (scale_fill_steps)** — explicit validation that binned color scales render correctly on map regions
- [ ] **geom_sf_label / geom_sf_text** — requires R-side interior point extraction and coordinate projection passthrough

### Future Consideration (v2+)

Defer until core polygon rendering is production-stable.

- [ ] **Map-specific zoom/pan** — requires separate zoom implementation that rescales geoIdentity, not SVG viewBox; conflicts with current d3_zoom()
- [ ] **Click-to-select linked region** — requires polygon hit-testing or replacing rectangular brush with point-in-polygon test
- [ ] **Raster/tile basemap** — outside SVG-only mandate; recommend Leaflet integration path instead
- [ ] **Additional projection support** — d3.geoMercator, d3.geoAlbers for users who need projected output; requires projection parameter in coord_sf detection

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Polygon region rendering (geom_sf → geoPath) | HIGH | HIGH | P1 |
| Fill aesthetic on regions | HIGH | LOW (if geometry extraction works) | P1 |
| Stroke / boundary line | HIGH | LOW | P1 |
| Hover tooltip on region | HIGH | LOW-MEDIUM | P1 |
| Hover highlight | MEDIUM | LOW | P1 |
| theme_void() / axis suppression | MEDIUM | LOW | P1 |
| Legend (colorbar + discrete swatches) | HIGH | LOW (reuse existing) | P1 |
| POINT geom_sf dispatch | MEDIUM | LOW (reuse existing point renderer) | P2 |
| LINESTRING geom_sf dispatch | MEDIUM | LOW (reuse existing line renderer) | P2 |
| Multiple geom_sf layers | MEDIUM | MEDIUM | P2 |
| Stepped fill scales validation | MEDIUM | LOW | P2 |
| geom_sf_text / geom_sf_label | LOW-MEDIUM | HIGH | P3 |
| Map-specific zoom/pan | MEDIUM | HIGH | P3 |
| Click-to-select region (linked views) | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Required for choropleth MVP — without these, the feature is unusable
- P2: Strong follow-on — adds completeness and handles real-world usage patterns
- P3: Defer — requires deeper research or conflicts with existing architecture

---

## Competitor Feature Analysis

| Feature | Plotly (R) | Leaflet (R) | mapview (R) | gg2d3 target |
|---------|------------|-------------|-------------|--------------|
| Choropleth fill color | Full support (choroplethmapbox) | Full support via addPolygons | Full support | Target: full support for ggplot2-authored fills |
| Hover tooltip | Built-in | Built-in via addPolygons(popup=) | Built-in | Extend d3_tooltip() to .geom-sf paths |
| Click/select region | Via event_data() | Via layerId + click events | Via mapview events | Defer (P3); complex hit-testing |
| CRS projection | Server-side transforms | Leaflet uses WGS84 natively | sf handles CRS | Normalize to WGS84 in R via st_transform |
| Tile basemap | Mapbox tiles | OSM/tile providers | OSM default | Out of scope for SVG-only gg2d3 |
| Multiple layers | Yes | Yes | Yes | P2 target |
| Animated transitions | Via frames | No | No | Existing d3_transitions() may apply to fill changes |
| ggplot2 API parity | Via ggplotly conversion | Not ggplot2-native | Not ggplot2-native | Core differentiator: native geom_sf + aes() syntax |

**Key positioning insight:** Leaflet and mapview provide richer geospatial interactivity, but neither accepts a ggplot object as input. Plotly accepts ggplot objects via `ggplotly()` but has inconsistent `geom_sf` support (sf geometry handling is a known gap). gg2d3's differentiator is the native ggplot2 API: users write standard ggplot code and get interactive D3 output — no API translation required.

---

## Pipeline Integration Notes

These are observations about how choropleth features connect to the existing three-layer pipeline (R → IR → D3):

**R layer changes required:**
- Detect `CoordSf` in `b$plot$coordinates` (analogous to existing `CoordFlip` detection)
- In `to_rows()` / layer extraction: the `geometry` column in `ggplot_build()$data[[i]]` is an `sfc` list-column that current `keep_aes` filtering strips out — this must be preserved and serialized separately
- Convert `sfc` geometry to GeoJSON string via `sf::st_as_text()` (WKT) or ideally via `geojsonsf::sfc_geojson()` or `jsonlite` with sf methods — output as a GeoJSON FeatureCollection string
- Ensure CRS is WGS84 before serialization (call `sf::st_transform(geometry, 4326)` if CRS differs)

**IR layer changes required:**
- New layer type discriminator `"sf"` (or `"geom_sf"`) in `layers[i].geom`
- New field `layers[i].geojson`: GeoJSON FeatureCollection string (or pre-parsed object) where each Feature's `properties` carries the resolved aesthetics (fill hex, colour hex, alpha, linewidth)
- `layers[i].data` can be empty or carry non-geometry row metadata (e.g., tooltip text fields)

**D3 layer changes required:**
- New renderer in the geom registry for `"geom_sf"` / `"geom_sf_polygon"`
- Use `d3.geoPath(d3.geoIdentity().reflectY(true).fitExtent([[left, top], [right, bottom]], geojson))`
- Render each Feature as a `<path>` with `class="geom-sf"`, fill/stroke from properties
- Attach data attributes for tooltip (`data-tooltip`, `data-fill-value`, `data-region-id`)
- Add `"geom-sf"` to all relevant INTERACTIVE_SELECTORS arrays in d3_hover.js, d3_tooltip.js

---

## Sources

### High Confidence (Official documentation)

- ggplot2 geom_sf reference: https://ggplot2.tidyverse.org/reference/ggsf.html
- ggplot2 Maps chapter (book): https://ggplot2-book.org/maps.html
- sf package vignette — Simple Features for R: https://r-spatial.github.io/sf/articles/sf1.html
- sf package geometry manipulation: https://r-spatial.github.io/sf/articles/sf3.html
- D3 geoPath documentation: https://d3js.org/d3-geo/path
- D3 geo projections: https://d3js.org/d3-geo/projection
- geojsonsf package (sf ↔ GeoJSON): https://github.com/SymbolixAU/geojsonsf

### Medium Confidence (Tutorials and ecosystem patterns)

- Standard choropleth workflow with ggplot2: https://r-graph-gallery.com/327-chloropleth-map-from-geojson-with-ggplot2.html
- D3 choropleth with hover: https://d3-graph-gallery.com/graph/choropleth_hover_effect.html
- CRS projections with sf + ggplot2: https://aditya-dahiya.github.io/visage/geocomputation/crs_projections.html
- Interactive choropleth comparison (leaflet, mapview, tmap): https://rstudio-pubs-static.s3.amazonaws.com/324400_69a673183ba449e9af4011b1eeb456b9.html
- R as GIS for Economists — geom_sf + color scale patterns: https://tmieno2.github.io/R-as-GIS-for-Economists/geom-sf.html

### Low Confidence (Unverified pipeline-specific behavior)

- Whether `ggplot_build()` preserves the `sfc` geometry list-column or drops it — **must be verified empirically** before implementation begins. Historical GitHub issue (#3453) suggests tibble version interactions. Current behavior with ggplot2 >= 3.4.x needs direct testing.

---

*Feature research for: gg2d3 v1.7 choropleth map / geom_sf support*
*Researched: 2026-04-04*
*Confidence: HIGH overall for feature taxonomy; MEDIUM for pipeline integration specifics; LOW for ggplot_build geometry column survival (needs empirical verification)*
