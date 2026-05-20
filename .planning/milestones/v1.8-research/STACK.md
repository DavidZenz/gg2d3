# Stack Research

**Domain:** gg2d3 v1.7 choropleth map rendering — geom_sf / geographic geometry additions
**Researched:** 2026-04-04
**Confidence:** HIGH (R-side), MEDIUM (JS projection strategy)

---

## Context

This document covers ONLY net-new stack additions required for choropleth / geom_sf support. The existing v1.6 stack (D3 v7.9.0, htmlwidgets 1.6.4, ggplot2, jsonlite, scales) remains unchanged. Nothing in the existing pipeline is removed or replaced.

---

## Recommended Stack

### Core Technologies (new for v1.7)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| sf (R pkg) | **1.1-0** (CRAN Feb 2026) | sf object inspection, CRS detection, WGS84 transform | The authoritative R package for simple features. Provides `st_crs()`, `st_transform()`, `st_geometry_type()`, and the `sfc` list-column that geom_sf uses. No alternative exists in the R ecosystem. Requires GDAL, GEOS, PROJ system libs — available as CRAN binary on macOS/Windows. |
| geojsonsf (R pkg) | **2.0.3** (CRAN, updated Nov 2025) | Serialize sfc geometry column to GeoJSON strings | Fastest R→GeoJSON path. C++ backed via Rcpp. `sfc_geojson(sfc_col)` returns a character vector of per-row GeoJSON geometries. Dramatically simpler than jsonlite's sf serialization, which requires constructing a FeatureCollection when you only need geometry strings per row. |
| d3-geo (within D3 v7) | **bundled in d3 v7.9.0** | `d3.geoPath()` SVG path generator, `d3.geoIdentity()`, `d3.geoMercator()`, `d3.geoEquirectangular()`, `d3.geoNaturalEarth1()` | Already vendored. No new JS library needed. `d3.geoPath` accepts GeoJSON objects directly and produces `<path d="...">` strings. The null-projection (`d3.geoIdentity()`) supports pre-projected coordinates; named projections support forward lon/lat→pixel. |

### Supporting Libraries (new for v1.7)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sf (R pkg) | 1.1-0 | System dependency detection, CRS introspection | Always when geom_sf layer is present. Use `inherits(layer_data, "sf")` or `"sfc" %in% class(col)` to detect. |
| geojsonsf | 2.0.3 | `sfc_geojson()` — sfc column → character vector of GeoJSON geometry strings | In the R IR builder when extracting geom_sf geometry. Each row's geometry becomes an inline GeoJSON string sent to JS as part of the layer data. |
| jsonlite (existing) | 2.0.0 | JSON serialization of IR — sfc columns need special handling | Already a dependency. Do NOT use `jsonlite::toJSON(sf_object)` for the IR — it wraps everything in FeatureCollection. Use geojsonsf for geometry, then include the GeoJSON strings as plain character fields in each row. |

### Development Tools (v1.7 specific)

| Tool | Purpose | Notes |
|------|---------|-------|
| sf built-in datasets | `sf::st_read(system.file("shape/nc.shp", package="sf"))` | North Carolina counties shapefile ships with sf. Use as canonical test fixture — no internet required. |
| rnaturalearth / rnaturalearthdata | World polygon data for integration testing | Optional, CRAN available. Use for world-scale choropleth smoke tests. |
| R CMD check with sf in Suggests | Conditional sf usage so sf is not a hard DESCRIPTION Imports | geom_sf support should trigger only when sf is loaded; keeps sf in `Suggests:` to avoid making GDAL/GEOS/PROJ required system deps for all gg2d3 users. |

---

## Integration Points with Existing IR Pipeline

### R Layer: `R/as_d3_ir.R`

The IR builder must handle geom_sf as a special case inside the existing layer loop.

**Detection:** After `ggplot_build()`, a geom_sf layer's built data retains the `geometry` column as an `sfc` list-column. Detect with:

```r
has_sf_geom <- function(layer_data) {
  "geometry" %in% names(layer_data) &&
    inherits(layer_data$geometry, "sfc")
}
```

**CRS normalization:** `coord_sf()` (automatically added by `geom_sf()`) applies a CRS transform before rendering. The built data geometry column is already in the plot CRS. To send valid GeoJSON to D3, transform to WGS84 (EPSG:4326 / lon-lat) first — D3's geoPath expects spherical lon/lat in degrees:

```r
normalize_to_lonlat <- function(sfc_col) {
  crs <- sf::st_crs(sfc_col)
  if (is.na(crs) || crs == sf::st_crs(4326)) return(sfc_col)
  sf::st_transform(sfc_col, 4326)
}
```

**Geometry serialization:** Convert each row's geometry to an inline GeoJSON string using geojsonsf:

```r
geojson_strings <- geojsonsf::sfc_geojson(normalized_sfc)
```

This produces a character vector, one GeoJSON string per row (e.g., `'{"type":"Polygon","coordinates":[...]}'`). Include this as a new column in the row data sent to JS. Keep non-geometry aesthetics (fill, colour, alpha, label) in the same row object — they drive choropleth coloring.

**IR schema addition for geom_sf layers:**

```json
{
  "geom": "sf",
  "data": [
    {
      "geometry": "{\"type\":\"Polygon\",\"coordinates\":[...]}",
      "fill": "#3182bd",
      "colour": "#000000",
      "alpha": 1,
      "label": "Wake County"
    }
  ],
  "params": { "linewidth": 0.5 },
  "aes": { "fill": "fill_col", "colour": "colour_col" },
  "projection": "identity"
}
```

The `"projection": "identity"` field signals to JS to use `d3.geoIdentity()` + `fitExtent` (coordinates are already in lon/lat, D3 does the lon/lat→pixel projection). If the gg2d3 user has applied `coord_sf(crs = something_else)` and ggplot_build has already projected to that CRS, we always re-normalize to WGS84 before serialization.

### JS Layer: new file `inst/htmlwidgets/modules/geoms/sf.js`

Register a `"sf"` geom renderer in the existing geom registry. The renderer:

1. Parses each row's `geometry` field with `JSON.parse()`.
2. Constructs a `d3.geoIdentity().reflectY(true)` projection, then calls `.fitExtent([[0,0],[width,height]], featureCollection)` to auto-fit all features into the panel dimensions.
3. Creates a `d3.geoPath().projection(proj)` path generator.
4. Appends one `<path class="geom-sf">` per row, setting `d` from the path generator and `fill`/`stroke` from aesthetics.

**Why geoIdentity with reflectY + fitExtent (not a named projection like Mercator):**

- The R side (ggplot2's `coord_sf`) has already handled the projection choice and applied it to the built data before `ggplot_build()` returns. If we re-project in JS using Mercator or Albers, we double-project.
- `geoIdentity()` treats coordinates as-is (no spherical math) but **fitExtent** auto-scales them to fill the panel — which is exactly what ggplot2's layout engine does.
- `reflectY(true)` is required because SVG's y-axis is inverted relative to geographic convention.
- For the common WGS84 (lon/lat) case, `geoIdentity + fitExtent` on lon/lat coordinates produces correct aspect-ratio-preserving maps without requiring us to replicate ggplot2's projection logic in JavaScript.

**Named D3 projections (geoMercator, geoNaturalEarth1, etc.):** Available in d3 v7 bundle without additional libraries. Use only if the IR explicitly requests a projection by name — a post-v1.7 feature. For v1.7, identity is the correct default.

---

## DESCRIPTION Changes

```r
# Add to Suggests (NOT Imports — sf has heavy system deps)
Suggests:
  sf (>= 1.0-0),
  geojsonsf (>= 2.0.3),
  testthat (>= 3.0.0),
  crosstalk
```

Guard all sf usage at runtime:

```r
if (!requireNamespace("sf", quietly = TRUE)) {
  stop("The 'sf' package is required for geom_sf support. Install with: install.packages('sf')",
       call. = FALSE)
}
```

This keeps GDAL/GEOS/PROJ out of gg2d3's hard install requirements — users without spatial data don't need them.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| geojsonsf::sfc_geojson() | sf::st_as_text() (WKT) + parse in JS | Never for gg2d3. WKT requires a JS WKT parser library; GeoJSON is directly consumable by d3.geoPath. |
| geojsonsf::sfc_geojson() | jsonlite::toJSON(sf_object, dataframe="geojson") | Only if you want a single FeatureCollection blob. gg2d3 needs per-row geometry strings to match the existing row-oriented IR data format. |
| geoIdentity() + fitExtent | geoMercator / geoAlbers in JS | Use named projections only for future "raw lon/lat without coord_sf" support. Not needed when R has already handled projection. |
| geoIdentity() + fitExtent | Passing pixel-projected coordinates from R | Possible but fragile — requires replicating ggplot2's panel size math in R to get the same pixel coords that coord_sf would use. Too brittle; let D3 fitExtent handle scaling. |
| sf in Suggests | sf in Imports | Use sf in Imports only if the entire package depends on spatial capability. gg2d3's non-map users should not need GDAL. |
| Inline GeoJSON strings per row | TopoJSON | TopoJSON requires a separate topology-generation step and a separate JS parser (topojson-client). For choropleth rendering in a ggplot2 IR pipeline, the added complexity is not justified — GeoJSON is the direct output of sf and the direct input to d3.geoPath. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **leaflet / mapbox / maplibre tile servers** | gg2d3 renders static SVG shapes only; tile maps are raster-based with a completely different rendering model | d3.geoPath producing SVG `<path>` elements |
| **topojson-client JS library** | Extra vendored JS with no benefit over GeoJSON for single-layer choropleth rendering | GeoJSON inline strings + d3.geoPath |
| **geojsonio R package** | Heavier dependency (many Suggests), built around HTTP/file I/O API; not designed for in-memory pipeline use | geojsonsf (C++ backed, in-memory, no I/O) |
| **sp / rgdal (legacy R spatial)** | Deprecated. sp→sf migration complete across the R ecosystem; rgdal was archived from CRAN in Oct 2023 | sf package exclusively |
| **Projection logic in JavaScript** | ggplot2's coord_sf has already resolved projection choices; reproducing this in JS means double-projecting | Always normalize to WGS84 in R, use geoIdentity in JS |
| **sf in Imports** | Forces GDAL/GEOS/PROJ system library installation on every gg2d3 user regardless of whether they use maps | sf in Suggests with runtime requireNamespace() guard |

---

## Stack Patterns by Variant

**If user calls `gg2d3(p)` where `p` has only non-sf geoms:**
- No sf/geojsonsf code path is triggered.
- Zero runtime overhead from map support.

**If user calls `gg2d3(p)` where `p` has `geom_sf()` with polygon/multipolygon geometries:**
- R: detect sfc column, normalize CRS to WGS84, call `sfc_geojson()`, embed strings in IR.
- JS: `sf.js` geom renderer parses JSON, calls geoIdentity + fitExtent, renders `<path>` elements.
- Interactivity: existing hover/tooltip/brush modules can target `path.geom-sf` selectors — same pattern as other geoms.

**If user calls `gg2d3(p)` where `p` has `geom_sf()` with mixed geometry types (point + line + polygon):**
- geom_sf splits rows by geometry type internally (GeomPoint defaults for points, GeomPolygon defaults for polygons).
- The IR should emit separate layer entries per geometry type, or the JS renderer must branch per row based on `feature.geometry.type`.
- Recommended: emit separate sub-layers keyed by geometry type in R; simpler renderer logic in JS.

**If user's sf data is in a non-WGS84 CRS (e.g., EPSG:3857 Web Mercator, EPSG:32617 UTM):**
- R: `st_transform(sfc_col, 4326)` converts to lon/lat before GeoJSON serialization.
- JS: geoIdentity + fitExtent handles lon/lat correctly.
- This is the right approach even if the original data is in a projected CRS — GeoJSON RFC 7946 mandates WGS84.

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| sf 1.1-0 | ggplot2 3.5.x, 4.0.x | ggplot2 geom_sf / coord_sf API stable; sf 1.0+ uses WKT2 for CRS (not proj4 strings) |
| geojsonsf 2.0.3 | sf 1.0+ | geojsonsf requires sf; sfc_geojson() works on sfc objects from sf 1.0+ |
| d3 v7.9.0 | d3-geo bundled | d3.geoPath, geoIdentity, geoMercator, geoEquirectangular, geoNaturalEarth1 all included |
| jsonlite 2.0.0 | sf sfc columns | jsonlite 2.0 (Jul 2025) has asJSON.sf methods, but NOT used in our pipeline (geojsonsf preferred per-row) |

---

## Sources

- https://cran.r-project.org/web/packages/sf/sf.pdf — sf 1.1-0 CRAN release date (Feb 24, 2026), system deps (GDAL, GEOS, PROJ) **[HIGH]**
- https://r-spatial.github.io/sf/reference/st_transform.html — st_transform() CRS conversion API **[HIGH]**
- https://r-spatial.github.io/sf/reference/st_crs.html — st_crs() introspection, WGS84/EPSG:4326 usage **[HIGH]**
- https://github.com/SymbolixAU/geojsonsf — geojsonsf v2.0.3, sfc_geojson() function **[MEDIUM — GitHub, Nov 2025 CRAN date confirmed]**
- https://cran.r-project.org/web/packages/geojsonsf/geojsonsf.pdf — CRAN documentation, Nov 2025 build **[HIGH]**
- https://d3js.org/d3-geo — d3-geo API, geoPath, projection types, fitExtent/fitSize **[HIGH]**
- https://github.com/d3/d3-geo — d3-geo v3.1.1 (bundled in D3 v7.9.0) **[HIGH]**
- https://github.com/tidyverse/ggplot2/blob/main/R/geom-sf.R — geom_sf draw_panel, required_aes="geometry", type classification **[HIGH]**
- https://github.com/tidyverse/ggplot2/issues/3453 — tibble+sfc ggplot_build compatibility (resolved) **[HIGH]**
- https://cran.r-project.org/web/packages/jsonlite/jsonlite.pdf — jsonlite 2.0.0 (Jul 2025), sf serialization modes **[HIGH]**
- https://ggplot2.tidyverse.org/reference/ggsf.html — coord_sf, geom_sf public API **[HIGH]**

---

*Stack research for: gg2d3 v1.7 milestone (choropleth map / geom_sf support)*
*Researched: 2026-04-04*
