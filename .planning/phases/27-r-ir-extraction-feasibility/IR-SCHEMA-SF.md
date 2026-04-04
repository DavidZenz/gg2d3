# IR Schema Extension: geom_sf Layers

## Overview

This document shows the annotated IR JSON output produced by
`as_d3_ir(ggplot(nc, aes(fill = BIR74)) + geom_sf())` using the North Carolina
county shapefile included with the sf package.

The IR schema extension adds four new concepts to the existing structure:

1. `coord.type = "sf"` — replaces "cartesian" for geographic plots
2. `coord.bbox` — WGS84 bounding box for D3 projection fitting
3. `layer.geom = "sf"` with new fields: `geom_type`, `geometries`, `crs`
4. `panels[].x_range` and `panels[].y_range` are `null` for sf coord (D3 uses `coord.bbox` instead)

---

## coord Object

```json
{
  "type": "sf",
  // ^^^^
  // "sf" identifies this as a geographic coordinate system.
  // D3 renderer dispatches on this value instead of "cartesian"/"polar"/etc.

  "flip": false,
  "ratio": null,

  "bbox": [-84.3238, 33.8822, -75.4566, 36.5898]
  //        ^^^^^^^^  ^^^^^^^  ^^^^^^^^  ^^^^^^^
  //        xmin      ymin     xmax      ymax
  //
  // WGS84 (EPSG:4326) bounding box, computed from all sf layers.
  // Order matches sf::st_bbox() output: [xmin, ymin, xmax, ymax].
  //
  // D3 renderer uses this with:
  //   d3.geoIdentity().reflectY(true).fitExtent([[margin, margin], [width, height]], geojsonFC)
  // where geojsonFC is assembled from layer.geometries[] in a FeatureCollection.
}
```

---

## layers[0] Object (sf layer, trimmed to 2 geometries and 2 data rows)

```json
{
  "geom": "sf",
  // ^^^^^^^^^^
  // Geom type identifier. D3 renderer dispatches on this string.
  // "sf" is new — maps to d3.geoPath() rendering.

  "geom_type": "MULTIPOLYGON",
  // ^^^^^^^^^^^^^^^^^^^^^^^^
  // Dominant geometry type detected via sf::st_geometry_type(by_geometry = FALSE).
  // Possible values: "MULTIPOLYGON", "POLYGON", "LINESTRING",
  //                  "MULTILINESTRING", "POINT", "MULTIPOINT", "GEOMETRY"
  // D3 renderer uses this for fill-rule decisions:
  //   - POLYGON/MULTIPOLYGON: path fill with evenodd for donut polygons
  //   - LINESTRING/MULTILINESTRING: stroke only (no fill)
  //   - POINT/MULTIPOINT: circle rendering (centroid of each point geometry)

  "geometries": [
    "{\"type\":\"MultiPolygon\",\"coordinates\":[[[[-81.4725791159128,36.234484911068776],...]]]}",
    "{\"type\":\"MultiPolygon\",\"coordinates\":[[[[-81.23970416403293,36.365493522175605],...]]]}",
    "...(98 more)"
  ],
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // Array of GeoJSON geometry strings, one per row, parallel to data[] by index.
  //
  // - Length always equals length(data[]) — row i geometry corresponds to data[i]
  // - Serialized via geojsonsf::sfc_geojson() (not jsonlite::toJSON on sfc objects)
  // - Always normalized to WGS84 (EPSG:4326) before serialization (D-11)
  // - Each string is a GeoJSON "geometry" object (not a "feature") —
  //   D3 renderer wraps them in Feature/FeatureCollection for d3.geoPath()
  //
  // D3 rendering pattern:
  //   const path = d3.geoPath().projection(projection);
  //   svgG.selectAll("path")
  //     .data(layer.geometries.map((g, i) => ({
  //       geometry: JSON.parse(g),
  //       props: layer.data[i]
  //     })))
  //     .join("path")
  //     .attr("d", d => path(d.geometry))
  //     .attr("fill", d => d.props.fill || "steelblue");

  "data": [
    {
      "PANEL": 1,
      "xmin": -84.3239,
      "xmax": -75.4570,
      "ymin": 33.8820,
      "ymax": 36.5896,
      // ^^^ xmin/xmax/ymin/ymax: bounding box of each county in projected coords.
      // These are the built data values from ggplot_build(), NOT GeoJSON coords.
      // D3 renderer should ignore these for geographic rendering and use
      // the geometry strings above for actual path drawing.

      "fill": "#153049",
      // ^^^^^^^^^^^^
      // Hex color string mapped from BIR74 via the fill scale.
      // Present only when aes(fill = ...) is specified.
      // When no fill aesthetic is mapped, this field is absent from data rows.
      // D3 renderer falls back to geom_sf default fill (#595959, ~40% grey) when null.

      "alpha": null,
      "group": -1,
      "stroke": 0.5,
      "linetype": 1
    },
    {
      "PANEL": 1,
      "xmin": -84.3239,
      "xmax": -75.4570,
      "ymin": 33.8820,
      "ymax": 36.5896,
      "fill": "#142C45",
      "alpha": null,
      "group": -1,
      "stroke": 0.5,
      "linetype": 1
    }
  ],
  // ^^^ data[] rows are parallel to geometries[] by index.
  // Each row contains aesthetic values (fill, alpha, stroke, linetype).
  // The geometry column is NOT in data[] — it is in geometries[] instead.
  // Non-aesthetic columns from the sf data frame (county names, FIPS codes, etc.)
  // are not included (keep_aes whitelist applies).

  "aes": {
    "x": {},
    "y": {},
    "fill": "fill",
    // ^^^^^^^^^^
    // Aesthetic mapping. "fill" -> "fill" means the fill column in data[]
    // was computed from a user aesthetic mapping (aes(fill = BIR74)).
    // When no fill aesthetic is specified, "fill" value here is {} (empty).
    "alpha": "alpha",
    "group": "group"
  },

  "params": {},
  // ^^^^^^^^
  // Layer-level parameters (e.g., fill, colour specified outside aes()).
  // Empty for geom_sf with default params.

  "crs": {
    "epsg": 4326,
    // ^^^^^^^^^^
    // Always 4326 after normalization. R normalizes to WGS84 before serialization.
    // D3 renderer can rely on this being 4326 — no JS reprojection needed.

    "wkt": "GEOGCRS[\"WGS 84\", ...]"
    // ^^^
    // WKT2 string of the normalized CRS. Informational only for the D3 renderer.
    // May be used for display/debugging or future projection override support.
  }
}
```

---

## panels Array (sf coord)

```json
[
  {
    "PANEL": 1,
    "x_range": null,
    // ^^^^^^^^^^^^^^
    // null for sf coord. D3 uses coord.bbox for geographic extent, not Cartesian domains.
    // validate_ir() skips the x_range/y_range check when coord.type === "sf".

    "y_range": null,
    // ^^^^^^^^^^^^^^
    // Same as x_range — null for sf coord.

    "x_breaks": null,
    "y_breaks": null
  }
]
```

---

## scales Object (sf coord)

```json
{
  "x": {
    "type": "continuous",
    "domain": [-84.7672, -75.0136],
    "breaks": [-84.0001, -82.0002, -80.0002, -78.0003, -76.0004],
    "minor_breaks": {}
  },
  "y": {
    "type": "continuous",
    "domain": [33.7466, 36.7250],
    "breaks": [33.9999, 34.4999, 34.9999, 35.4999, 35.9999, 36.4999],
    "minor_breaks": {}
  }
}
```

**Note:** For sf coord, `scales.x` and `scales.y` contain the projected coordinate
bounding box values from ggplot_build (in WGS84 degrees for NC data). These values
exist but should NOT be used by the D3 renderer for geographic rendering.

The D3 renderer should use `coord.bbox` for geographic extent and
`d3.geoIdentity().reflectY(true).fitExtent()` for the projection, not these scale
domains. The scales here are a side-effect of ggplot_build's Cartesian layout
engine and are not meaningful for D3 geographic rendering.

---

## How D3 Renderer Should Detect sf Layers

```javascript
// In gg2d3.js geom dispatch:
if (coord.type === "sf") {
  // Use d3.geoIdentity().reflectY(true).fitExtent(extent, featureCollection)
  // for projection
} else {
  // Use existing Cartesian scale-based rendering
}

// Per-layer dispatch:
if (layer.geom === "sf") {
  // Render with d3.geoPath(projection)
  // Iterate layer.geometries[] in parallel with layer.data[]
}
```

---

## Field Summary Table

| IR Path | Type | Example | Purpose |
|---------|------|---------|---------|
| `coord.type` | string | `"sf"` | Triggers geographic rendering mode in D3 |
| `coord.bbox` | number[4] | `[-84.32, 33.88, -75.46, 36.59]` | WGS84 [xmin,ymin,xmax,ymax] for fitExtent |
| `layer.geom` | string | `"sf"` | Dispatches to d3.geoPath renderer |
| `layer.geom_type` | string | `"MULTIPOLYGON"` | Fill-rule and rendering decisions |
| `layer.geometries` | string[] | `["{\"type\":\"Multi..."]` | GeoJSON geometry strings, parallel to data[] |
| `layer.crs.epsg` | integer | `4326` | Always 4326 after WGS84 normalization |
| `layer.crs.wkt` | string | `"GEOGCRS[\"WGS 84\"...]"` | WKT2 string (informational) |
| `panels[].x_range` | null | `null` | Null for sf coord; D3 uses coord.bbox |
| `panels[].y_range` | null | `null` | Null for sf coord; D3 uses coord.bbox |

---

## Pitfall Notes (from Research)

- **data[] may lack fill/colour** when no aesthetic mapping is specified. The D3
  renderer must handle absent `fill` in data rows and fall back to a default.

- **geometries[] order matches data[]** — do not sort or reorder either array
  independently. Row i of data[] corresponds to geometries[i].

- **scales.x/y are placeholder** for sf plots — they reflect the projected
  coordinate range, not meaningful rendering bounds. Use coord.bbox for D3.

- **geom_type can be "GEOMETRY"** for mixed-type sfc columns. D3 renderer should
  handle this by detecting geometry type from each individual GeoJSON string.

- **crs.wkt may be long** (500+ chars). Do not attempt to display it in tooltips.
  Use crs.epsg for CRS identification.
