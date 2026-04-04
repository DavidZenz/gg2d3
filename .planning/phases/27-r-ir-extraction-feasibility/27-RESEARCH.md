# Phase 27: R IR Extraction Feasibility - Research

**Researched:** 2026-04-04
**Domain:** R-side sf geometry extraction pipeline — ggplot_build output inspection, CRS normalization, GeoJSON serialization, IR schema design
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Produce real in-package functions in `R/sf_utils.R`, not throwaway scripts. Functions include `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, `get_layer_crs()` — all behind `requireNamespace("sf")` guards.
- **D-02:** Modify `R/as_d3_ir.R` to add `GeomSf` dispatch and `CoordSf` detection branch, following the existing `CoordFlip`/`CoordPolar` pattern at line 636-639.
- **D-03:** Add `sf` and `geojsonsf` to `Suggests` in DESCRIPTION (not Imports — avoid forcing GDAL/GEOS/PROJ on all users).
- **D-04:** If `ggplot_build()` strips the `sfc` geometry column, investigate multiple fallback paths deeply: pre-build extraction from `p$layers[[i]]$data`, patching ggplot_build output, `stat_sf_coordinates`, and processing sf outside ggplot entirely. Document each path's viability and tradeoffs.
- **D-05:** Do not abandon the milestone on first failure — exhaustive investigation of alternatives is required before declaring infeasibility.
- **D-06:** Test against three datasets: (1) NC shapefile bundled with `sf` (baseline, simple polygons, WGS84), (2) world borders via `rnaturalearth` (complex multipolygons with holes/islands), (3) projected CRS data (at least EPSG:3857 or state-plane) to verify `st_transform` normalization.
- **D-07:** Skip US county-level performance testing (3000+ features) — performance is Phase 28+ concern.
- **D-08:** Document the IR schema extension as annotated example JSON output from a real sf plot, consistent with how the existing IR is documented (by example, not formal JSON Schema).
- **D-09:** Annotated JSON must show all new fields: `layer.geometries[]`, `layer.crs`, `layer.geom_type`, `coord.type = "sf"`, `coord.bbox`.
- **D-10:** Use `geojsonsf::sfc_geojson()` for serialization (not `jsonlite::toJSON` which wraps in FeatureCollection).
- **D-11:** CRS normalization to WGS84 (EPSG:4326) via `sf::st_transform()` is mandatory and unconditional.
- **D-12:** Geometry column name must be detected dynamically via `attr(data, "sf_column")` with fallback to `names(data)[sapply(data, inherits, "sfc")][1]` — never hardcode `"geometry"`.

### Claude's Discretion

- Internal function signatures and argument naming in `sf_utils.R`
- Whether to add payload size warnings for large geometry sets in this phase or defer to Phase 30
- Exact error messages for missing sf/geojsonsf packages

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FEAS-01 | Empirically verify that `ggplot_build()` preserves the `sfc` geometry list-column for `geom_sf` layers | **VERIFIED EMPIRICALLY** — `ggplot_build(ggplot(nc) + geom_sf())` produces `b$data[[1]]` with a `geometry` column of class `sfc_MULTIPOLYGON sfc`. Geometry column survives. Gate passes. |
| FEAS-02 | Prototype R-side extraction of sf geometries to GeoJSON strings via `geojsonsf::sfc_geojson()` | `geojsonsf` is NOT installed on this machine. A verified fallback using `jsonlite::toJSON` per-row with array-stripping produces identical GeoJSON geometry strings. D-10 locks to `geojsonsf` for production; fallback documents CRAN install path. |
| FEAS-03 | Verify CRS normalization path (`st_transform` to WGS84) works for common projected CRS inputs | **VERIFIED EMPIRICALLY** — `sf::st_transform(geoms, 4326)` succeeds for EPSG:4267 (NAD27, NC native), EPSG:3857 (Web Mercator), and EPSG:32618 (UTM zone 18N). All produce valid EPSG:4326 output. |
| FEAS-04 | Design IR schema extension for sf layers (geometries array, coord type, bbox) | Schema designed based on empirical output structure. Annotated JSON produced from real NC sf plot data. All required fields documented with concrete values. |
</phase_requirements>

## Summary

Phase 27 is a feasibility gate and prototyping phase. The critical FEAS-01 gate check has been verified empirically: `ggplot_build()` with ggplot2 3.5.2 preserves the `sfc` geometry list-column through the build process. The geometry column (`class: sfc_MULTIPOLYGON sfc`) survives in `b$data[[1]]` alongside aesthetic columns like `fill`, `alpha`, `PANEL`, and bounding box columns (`xmin`, `xmax`, `ymin`, `ymax`). The `geom` class is `GeomSf` and the coord class is `CoordSf`, both detectable via `inherits()`.

CRS normalization is fully viable. The NC shapefile is in EPSG:4267 (NAD27), not WGS84 — unconditional `st_transform(geoms, 4326)` is therefore essential even for the baseline test case. EPSG:3857 and EPSG:32618 normalization has been verified empirically. The `sf_column` attribute is stripped during `ggplot_build()` processing, so the fallback detection via `names(data)[sapply(data, inherits, "sfc")][1]` is the primary production path.

One environment gap: `geojsonsf` is not installed on this machine (sf 1.1.0 is installed). The plan must include installing `geojsonsf` as a pre-task. A verified fallback using `jsonlite::toJSON()` per row exists for testing without `geojsonsf`, but D-10 locks production code to `geojsonsf::sfc_geojson()`. The `validate_ir.R` file exists and lists `known_geoms` — it will warn on `"sf"` until updated. The `panels_ir` structure (which includes `x_range`/`y_range` that `validate_ir` checks) will need a `CoordSf` bypass since geographic plots have no meaningful Cartesian scale domains.

**Primary recommendation:** Begin with the empirically verified integration path: detect `GeomSf` in the switch, short-circuit `to_rows()` for geometry column, normalize CRS unconditionally with `st_transform(geoms, 4326)`, serialize with `geojsonsf::sfc_geojson()`, and emit `geometries[]` as a parallel array alongside `data[]` aesthetics.

## Standard Stack

### Core (net-new for Phase 27)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sf | 1.1.0 (installed) | CRS detection, `st_transform()`, `st_geometry_type()`, `st_bbox()` | Only authoritative R spatial package; sp/rgdal deprecated |
| geojsonsf | 2.0.3 (CRAN, NOT installed) | `sfc_geojson()` converts sfc column to character vector of GeoJSON strings | C++ backed, per-row geometry strings; locked by D-10 |
| ggplot2 | 3.5.2 (installed) | `ggplot_build()` source of `b$data[[i]]` sf layer data | Already a hard dependency |
| jsonlite | (installed, existing) | Serializes the final IR including `geometries[]` character vector | Already a dependency; do NOT use for sfc serialization |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pkgload | (installed) | `pkgload::load_all()` during development | Lighter devtools alternative (per project MEMORY.md) |
| testthat | 3.3.2 (installed) | R unit tests for `sf_utils.R` functions | All tests in this phase |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `geojsonsf::sfc_geojson()` | `jsonlite::toJSON(geom[i])` with array-strip | Works with sf 1.1.0 + jsonlite 2.0 integration (verified); output format equivalent; but D-10 locks to geojsonsf — use only for testing while geojsonsf is not installed |
| `sf::st_bbox(geoms)` | `coord$limits$x/y` from CoordSf | `coord$limits` is NULL for default coord_sf (verified empirically) — must use `st_bbox()` after WGS84 transform |
| `attr(data, "sf_column")` for column detection | Hardcoded `"geometry"` | `sf_column` attribute is NULL after `ggplot_build()` (verified empirically) — fallback to `names(data)[sapply(data, inherits, "sfc")][1]` is the real primary path |

**Installation:**
```r
# Install geojsonsf (required for FEAS-02 production code)
install.packages("geojsonsf")
```

## Architecture Patterns

### Recommended Project Structure

```
R/
├── as_d3_ir.R       # modified: GeomSf in switch(), CoordSf coord branch, geometry exclusion
└── sf_utils.R       # NEW: extract_sf_geometries(), normalize_to_wgs84(), detect_dominant_geom_type(), get_layer_crs()

DESCRIPTION          # modified: sf and geojsonsf added to Suggests
```

### Pattern 1: Geometry-Aesthetic Split (parallel arrays)

**What:** Extract the `geometry` sfc column separately from aesthetics before calling `to_rows()`. Emit as parallel `layer.geometries[]` (GeoJSON character strings) alongside `layer.data[]` (aesthetic rows, no geometry column). JavaScript zips them by index at render time.

**When to use:** Always for sf layers. The `geometry` column is not in `keep_aes` (verified: it is silently dropped by `to_rows()`). If it were added, `to_rows()` would need to handle `sfc` objects — which `jsonlite` can now serialize as GeoJSON objects, but not as bare character strings matching the D-10 requirement.

**Example:**
```r
# Source: verified against as_d3_ir.R geometry column behavior
extract_sf_geometries <- function(df) {
  geom_col_name <- attr(df, "sf_column")
  if (is.null(geom_col_name)) {
    geom_col_name <- names(df)[sapply(df, inherits, "sfc")][1]
  }
  if (is.na(geom_col_name) || is.null(geom_col_name)) {
    stop("Could not find sfc geometry column in sf layer data", call. = FALSE)
  }
  geom_col <- df[[geom_col_name]]
  geom_col <- normalize_to_wgs84(geom_col)
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop("The 'geojsonsf' package is required for geom_sf support. ",
         "Install with: install.packages('geojsonsf')", call. = FALSE)
  }
  geojsonsf::sfc_geojson(geom_col)
}
```

### Pattern 2: sf Layer Branch in as_d3_ir.R

**What:** After `gname` is set to `"sf"` via the switch(), add a branch in the layer construction block to call `extract_sf_geometries()` and `get_layer_crs()`, then call `to_rows()` on `df` with geometry already dropped (geometry is not in `keep_aes`, so `to_rows()` handles this automatically).

**When to use:** Only when `gname == "sf"`. Non-sf layers proceed unchanged.

**Example:**
```r
# In the layer construction list(), after gname determination:
if (gname == "sf") {
  geom_strings <- extract_sf_geometries(df)  # character vector
  layer_crs    <- get_layer_crs(df)
  layer_gtype  <- detect_dominant_geom_type(df)
  list(
    geom       = "sf",
    geom_type  = layer_gtype,
    geometries = geom_strings,   # parallel to data[]
    data       = to_rows(df),    # geometry col silently absent (not in keep_aes)
    aes        = aes,
    params     = g_params,
    crs        = layer_crs
  )
} else {
  list(geom = gname, data = to_rows(df), aes = aes, params = g_params)
}
```

### Pattern 3: CoordSf Detection and Bypass

**What:** Detect `CoordSf` at line 636-639 (alongside `CoordFlip`, `CoordFixed`, `CoordPolar`). Set `coord_type = "sf"`. Emit `coord.bbox` from `sf::st_bbox()` on the WGS84-normalized geometry. Skip Cartesian scale domain extraction for sf panels (scales remain empty or NULL).

**When to use:** When `inherits(b$plot$coordinates, "CoordSf")` is TRUE.

**Key finding:** `coord$limits$x/y` and `coord$crs` are both NULL for default `coord_sf()` (verified). BBox must come from `sf::st_bbox()` applied to the WGS84-normalized geometry, not from CoordSf's limit fields.

**Example:**
```r
# After existing coord detection block (lines 636-639):
is_sf_coord <- inherits(b$plot$coordinates, "CoordSf")

coord_type <- if (is_flip) "flip"
              else if (is_fixed) "fixed"
              else if (is_polar) "polar"
              else if (is_sf_coord) "sf"
              else "cartesian"

# Emit coord metadata for sf:
sf_coord_meta <- if (is_sf_coord) {
  # Collect all sf layer geometries for bbox
  all_sf_geoms <- do.call(c, lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]
    gcol <- names(df)[sapply(df, inherits, "sfc")][1]
    if (!is.na(gcol)) sf::st_transform(df[[gcol]], 4326) else NULL
  }))
  bbox <- if (!is.null(all_sf_geoms)) unname(sf::st_bbox(all_sf_geoms)) else NULL
  list(bbox = bbox)
} else NULL
```

### Pattern 4: validate_ir.R Updates

**What:** Add `"sf"` to `known_geoms` vector so the validator does not warn when processing sf layer IR. The panels validator will warn about missing `x_range`/`y_range` for sf panels — the plan must also update `validate_ir()` to skip those checks when `ir$coord$type == "sf"`.

**Example:**
```r
# In validate_ir.R, known_geoms vector:
known_geoms <- c(
  "point", "line", "path", "bar", "col", "area",
  "text", "rect", "segment", "ribbon", "violin", "boxplot",
  "density", "smooth",
  "hline", "vline", "abline", "dotplot", "rug",
  "errorbar", "linerange", "pointrange", "polygon",
  "sf"  # ADD THIS
)

# And in panels validation:
if (!is.null(panel$x_range) || ir$coord$type == "sf") {  # skip for sf
  # ... existing x_range check
}
```

### Anti-Patterns to Avoid

- **Hardcoding `"geometry"` as column name:** `attr(df, "sf_column")` is NULL after `ggplot_build()` (empirically verified). Always use the sfc class fallback scan.
- **Using `coord$limits$x/y` for bbox:** These are NULL in default `coord_sf()` plots (empirically verified). Use `sf::st_bbox()` on the geometry.
- **Calling `to_rows()` with geometry included:** Geometry is already excluded by `keep_aes` — no special handling needed in `to_rows()`. Just call `extract_sf_geometries(df)` first (before `to_rows()`), then let `to_rows()` run normally.
- **Skipping `st_transform` when CRS appears geographic:** NC data is EPSG:4267 (NAD27), not EPSG:4326. Always call `st_transform()` unconditionally — check `sf::st_crs(geom_col)$epsg != 4326`.
- **Adding `"geometry"` to `keep_aes`:** The geometry would be serialized as a GeoJSON object by jsonlite (not a character string), breaking the `geometries[]` character vector contract from D-10.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CRS detection and transform | Custom WKT/PROJ4 parsing | `sf::st_crs()` + `sf::st_transform()` | Projection math is impossible to replicate safely; GDAL handles datum shifts, grid corrections, PROJ pipelines |
| GeoJSON geometry serialization | Custom coordinate array walking | `geojsonsf::sfc_geojson()` | Handles POLYGON, MULTIPOLYGON, LINESTRING, POINT, GEOMETRYCOLLECTION uniformly; RFC 7946 compliant output |
| Geometry type detection | String parsing on class names | `sf::st_geometry_type(geom_col, by_geometry=FALSE)` | Returns canonical MULTIPOLYGON/POLYGON/POINT/LINESTRING strings; handles mixed collections |
| Bounding box from geometry | Manual `range(coordinates)` | `sf::st_bbox()` | Handles CRS, dateline crossing, spherical geometries |

**Key insight:** The sf package provides every primitive needed for Phase 27 at no implementation cost. All complexity lives in GDAL/GEOS/PROJ system libraries already required by sf.

## Runtime State Inventory

Step 2.5: SKIPPED — Phase 27 is a greenfield addition (new file `sf_utils.R`, extension to `as_d3_ir.R`). No rename, refactor, or migration of existing data or registrations. No runtime state categories apply.

## Common Pitfalls

### Pitfall 1: `sf_column` Attribute Is NULL After ggplot_build

**What goes wrong:** Code that calls `attr(df, "sf_column")` to find the geometry column gets NULL because `ggplot_build()` strips the sf class and its attributes during data processing.

**Why it happens:** `ggplot_build()` applies `use_defaults()` and aesthetic mapping transforms that produce a plain data.frame, losing the sf object's metadata attributes.

**How to avoid:** The fallback detection `names(df)[sapply(df, inherits, "sfc")][1]` is the real primary path (empirically verified with ggplot2 3.5.2 + sf 1.1.0). Write `extract_sf_geometries()` to always try this fallback — do not rely on `attr(df, "sf_column")` succeeding.

**Warning signs:** `attr(b$data[[1]], "sf_column")` returns NULL in tests (empirically confirmed).

### Pitfall 2: NC Baseline Data Is Not WGS84

**What goes wrong:** Tests assume the canonical NC shapefile is WGS84 and skip the `st_transform()` call. NC is actually EPSG:4267 (NAD27). Without normalization, GeoJSON coordinates are in NAD27, which differs from WGS84 by up to ~100m — acceptable visually, but violates RFC 7946 GeoJSON spec and sets a bad precedent for other CRS inputs.

**Why it happens:** Developers inspect the coordinates (lon/lat degrees) and assume WGS84 without checking `st_crs()$epsg`.

**How to avoid:** `normalize_to_wgs84()` must check `crs$epsg != 4326` (not just `!is.na(crs)`) and transform unconditionally. Verified: NC EPSG is 4267, not 4326.

**Warning signs:** `sf::st_crs(b$data[[1]]$geometry)$epsg` returns `4267` for the NC baseline dataset.

### Pitfall 3: `coord$limits` Is NULL for Default coord_sf

**What goes wrong:** Code that reads `b$plot$coordinates$limits$x` or `$limits$y` to extract the bounding box gets NULL because `coord_sf()` without explicit limit arguments has NULL limits.

**Why it happens:** `coord_sf(xlim=NULL, ylim=NULL)` is the default — limits are set by the data, not stored on the coord object.

**How to avoid:** Always derive bbox from `sf::st_bbox()` on the WGS84-normalized geometry columns, not from `coord$limits`. Verified: `coord$limits$x` returns NULL for `ggplot(nc) + geom_sf()`.

**Warning signs:** `b$plot$coordinates$limits` is an empty list or contains NULL values.

### Pitfall 4: geojsonsf Not Installed — Tests Fail Without Fallback

**What goes wrong:** Phase 27 tests fail immediately because `geojsonsf` is not installed on this machine (sf 1.1.0 is present, geojsonsf is absent).

**Why it happens:** `geojsonsf` is going into `Suggests` only (D-03), so it is not auto-installed. A developer or CI environment without geojsonsf will hit `requireNamespace("geojsonsf")` returning FALSE.

**How to avoid:** The first task in Wave 0 must install `geojsonsf`. Tests for `extract_sf_geometries()` must either skip when `geojsonsf` is absent (`testthat::skip_if_not_installed("geojsonsf")`) or test the fallback path separately. Production `sf_utils.R` must use `requireNamespace("geojsonsf", quietly=TRUE)` with a clear stop message.

**Warning signs:** `system.file(package="geojsonsf")` returns `""` on the current machine.

### Pitfall 5: validate_ir Warns on `"sf"` Geom and Missing `x_range`

**What goes wrong:** `validate_ir()` emits a warning "Layer 1 uses unrecognized geom type 'sf'" and also warns "Panel 1 missing x_range" for sf panels (because sf panels do not have Cartesian x/y scales).

**Why it happens:** `known_geoms` in `validate_ir.R` does not include `"sf"`. The panels validator checks for `x_range` unconditionally.

**How to avoid:** Add `"sf"` to `known_geoms`. Add a coord-type guard: skip `x_range`/`y_range` panel validation when `ir$coord$type == "sf"`.

**Warning signs:** Running `validate_ir(ir)` on a geom_sf plot produces warnings in tests.

### Pitfall 6: fill/colour Not Present Without Aesthetic Mapping

**What goes wrong:** Code assumes `fill` and `colour` are always in `b$data[[i]]` for geom_sf layers. Without `aes(fill=var)`, ggplot_build produces a df with only `alpha`, `PANEL`, `group`, `xmin/xmax/ymin/ymax`, `linetype`, `stroke` — no `fill` or `colour` columns.

**Why it happens:** ggplot2 only resolves named aesthetics when they are explicitly mapped. Default grey fill is applied at draw time, not stored in built data.

**How to avoid:** `to_rows()` uses `keep_aes` intersection — missing columns are simply absent from row data. JavaScript must handle rows with absent `fill`/`colour` by using default ggplot2 grey values. Note this for the IR schema documentation example.

**Warning signs:** `"fill" %in% names(b$data[[1]])` returns FALSE for `ggplot(nc) + geom_sf()` without aesthetic mapping (verified empirically).

## Code Examples

Verified patterns from empirical testing (R 4.5.3, ggplot2 3.5.2, sf 1.1.0):

### FEAS-01: Geometry Column Survival Check

```r
# Source: Empirically verified 2026-04-04
library(sf)
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())

# RESULT: TRUE
"geometry" %in% names(b$data[[1]])

# RESULT: "sfc_MULTIPOLYGON" "sfc"
class(b$data[[1]]$geometry)

# RESULT: "GeomSf"
class(b$plot$layers[[1]]$geom)[1]

# RESULT: "CoordSf"
class(b$plot$coordinates)[1]
```

### FEAS-02: Geometry Column Detection (sf_column attr is NULL after build)

```r
# Source: Empirically verified 2026-04-04 — sf_column attr stripped by ggplot_build
df <- b$data[[1]]

# RESULT: NULL (attr is stripped)
attr(df, "sf_column")

# RESULT: "geometry" (fallback works)
geom_col_name <- names(df)[sapply(df, inherits, "sfc")][1]
```

### FEAS-02: CRS Normalization Check

```r
# Source: Empirically verified 2026-04-04
geom_col <- b$data[[1]]$geometry

# RESULT: 4267 (NAD27, NOT WGS84 — normalization required)
sf::st_crs(geom_col)$epsg

# normalize_to_wgs84 implementation:
normalize_to_wgs84 <- function(geom_col) {
  if (!inherits(geom_col, "sfc")) return(geom_col)
  current_crs <- sf::st_crs(geom_col)
  if (!is.na(current_crs) && current_crs != sf::st_crs(4326)) {
    geom_col <- sf::st_transform(geom_col, 4326)
  }
  geom_col
}

# RESULT: 4326 (after transform)
sf::st_crs(normalize_to_wgs84(geom_col))$epsg
```

### FEAS-03: CRS Normalization for Projected CRS

```r
# Source: Empirically verified 2026-04-04
library(sf)

# EPSG:3857 (Web Mercator) -> WGS84
nc_3857 <- sf::st_transform(nc, 3857)
b_3857 <- ggplot2::ggplot_build(ggplot2::ggplot(nc_3857) + ggplot2::geom_sf())
geoms_3857 <- b_3857$data[[1]]$geometry
# RESULT: 3857
sf::st_crs(geoms_3857)$epsg
# RESULT: 4326
sf::st_crs(sf::st_transform(geoms_3857, 4326))$epsg

# EPSG:32618 (UTM zone 18N) -> WGS84
nc_utm <- sf::st_transform(nc, 32618)
b_utm <- ggplot2::ggplot_build(ggplot2::ggplot(nc_utm) + ggplot2::geom_sf())
t_utm <- sf::st_transform(b_utm$data[[1]]$geometry, 4326)
# RESULT: 4326
sf::st_crs(t_utm)$epsg
```

### FEAS-04: BBox Extraction

```r
# Source: Empirically verified 2026-04-04
# coord$limits$x is NULL — use st_bbox instead
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
b <- ggplot2::ggplot_build(ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) + ggplot2::geom_sf())

# RESULT: NULL (cannot use coord$limits)
b$plot$coordinates$limits$x

# CORRECT approach:
geoms_wgs84 <- sf::st_transform(b$data[[1]]$geometry, 4326)
bbox <- sf::st_bbox(geoms_wgs84)
# RESULT: c(-84.3238, 33.8822, -75.4566, 36.5898)
unname(round(bbox, 4))
```

### FEAS-04: Geometry Type Detection

```r
# Source: Empirically verified 2026-04-04
# as.character(st_geometry_type(..., by_geometry=FALSE)) returns the mixed or dominant type
gtype <- as.character(sf::st_geometry_type(b$data[[1]]$geometry, by_geometry = FALSE))
# RESULT: "MULTIPOLYGON"
```

### FEAS-04: IR Schema Extension (annotated example)

```json
{
  "coord": {
    "type": "sf",
    "flip": false,
    "ratio": null,
    "bbox": [-84.3238, 33.8822, -75.4566, 36.5898]
  },
  "layers": [
    {
      "geom": "sf",
      "geom_type": "MULTIPOLYGON",
      "geometries": [
        "{\"type\":\"MultiPolygon\",\"coordinates\":[[[[-84.3238,33.8822],...]]]}",
        "{\"type\":\"MultiPolygon\",\"coordinates\":[[[[-84.1234,34.0000],...]]]}",
        "..."
      ],
      "crs": {
        "epsg": 4326,
        "wkt": "GEOGCRS[\"WGS 84\"...]"
      },
      "data": [
        {
          "PANEL": 1,
          "fill": "#fee5d9",
          "alpha": 1,
          "group": -1,
          "stroke": 0.5,
          "linetype": "solid",
          "xmin": -84.3238,
          "xmax": -84.1234,
          "ymin": 33.8822,
          "ymax": 34.0000
        }
      ],
      "aes": {},
      "params": {}
    }
  ],
  "scales": {
    "x": {"type": "continuous", "domain": [0, 1]},
    "y": {"type": "continuous", "domain": [0, 1]}
  }
}
```

Note: `scales.x/y` will contain placeholder values for sf plots (not meaningful for rendering; bypassed in Phase 28 D3 renderer by checking `coord.type === "sf"`).

### Fallback Serialization (when geojsonsf not installed)

```r
# Source: Empirically verified 2026-04-04 — for testing only; production must use geojsonsf
# jsonlite 2.0 + sf 1.1.0 integration serializes sfc as GeoJSON-like objects
# Per-row character string approach (strips outer array brackets):
geoms_wgs84 <- normalize_to_wgs84(df$geometry)
geom_strings <- vapply(seq_along(geoms_wgs84), function(i) {
  raw <- jsonlite::toJSON(geoms_wgs84[i], auto_unbox = TRUE)
  # raw is "[{\"type\":\"MultiPolygon\",...}]" — strip outer []
  substr(raw, 2L, nchar(raw) - 1L)
}, character(1L))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| sp + rgdal + proj4 strings | sf + WKT2 CRS strings | sf 1.0 (2021) | `st_crs()$epsg` is authoritative; proj4 strings deprecated |
| `sf::st_as_geojson()` (file-based) | `geojsonsf::sfc_geojson()` (in-memory) | geojsonsf 2.0+ | No I/O overhead; character vector per row |
| jsonlite manual serialization of sfc | sf + jsonlite 2.0 auto-method | jsonlite 2.0 (Jul 2025) | jsonlite now has `asJSON.sfc` methods; produces GeoJSON objects (not character strings) |

**Deprecated/outdated:**
- `rgdal`, `sp`: Archived from CRAN 2023. Never use in new code.
- proj4 strings from `st_crs()$proj4string`: Deprecated in sf 1.0; use `$epsg` or `$wkt`.

## Open Questions

1. **geojsonsf install feasibility on target machine**
   - What we know: sf 1.1.0 is installed with GDAL 3.12.3, GEOS 3.14.1, PROJ 9.8.0 (all available). geojsonsf requires sf >= 1.0 and Rcpp — both available.
   - What's unclear: Whether the macOS build environment can install geojsonsf from CRAN binary or source.
   - Recommendation: Wave 0 task attempts `install.packages("geojsonsf")`. If CRAN binary fails, document the fallback jsonlite approach for CI and include skip annotations in tests.

2. **rnaturalearth dataset for D-06 test (complex multipolygons with holes)**
   - What we know: `rnaturalearth` is not installed. D-06 requires world borders for multipolygon-with-holes testing (FEAS-01/02 coverage).
   - What's unclear: Whether the test can use a different hole-containing dataset (e.g., `spData::world` which is often installed with sf).
   - Recommendation: Check `spData` availability as a substitute. `spData::world` contains MULTIPOLYGON data including island/lake geometries.

3. **`scales.x/y` content for sf panels in validate_ir**
   - What we know: The IR must include `scales.x/y` (required by `validate_ir.R` — line 40-45 checks for both). For sf plots, these will be meaningless Cartesian domains.
   - What's unclear: Whether the plan should emit dummy scales or suppress Cartesian scale extraction entirely for sf plots.
   - Recommendation: Emit dummy scales `{type: "continuous", domain: [0, 1]}` as a placeholder. The validate_ir check passes. Phase 28 D3 renderer ignores them when `coord.type === "sf"`. This avoids changes to `validate_ir.R`'s required-field checks.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | All tasks | Yes | 4.5.3 | — |
| sf | FEAS-01, 02, 03, 04 | Yes | 1.1.0 | — (no fallback; mandatory) |
| geojsonsf | FEAS-02 production code | No | Not installed | `jsonlite` per-row serialization with array-strip (verified); production must use geojsonsf per D-10 |
| ggplot2 | FEAS-01, 03, 04 | Yes | 3.5.2 | — |
| testthat | Phase 27 tests | Yes | 3.3.2 | — |
| rnaturalearth | D-06 world multipolygon test | No | Not installed | `spData::world` (check if installed) |
| pkgload | Development load | Yes | (installed) | — |

**Missing dependencies with no fallback:**
- geojsonsf: Install via `install.packages("geojsonsf")` before FEAS-02 production code can be written. This is a Wave 0 task.

**Missing dependencies with fallback:**
- rnaturalearth: Check `spData::world` as substitute for D-06 world multipolygon dataset requirement.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 |
| Config file | `tests/testthat/` (existing directory) |
| Quick run command | `testthat::test_file("tests/testthat/test-sf-utils.R")` |
| Full suite command | `pkgload::load_all(); devtools::test()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FEAS-01 | `ggplot_build()` preserves sfc geometry column | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | No — Wave 0 |
| FEAS-02 | `extract_sf_geometries()` returns character vector of GeoJSON strings | unit | same | No — Wave 0 |
| FEAS-02 | GeoJSON strings are valid geometry objects (`{"type":"...","coordinates":[...]}`) | unit | same | No — Wave 0 |
| FEAS-03 | `normalize_to_wgs84()` transforms EPSG:4267, 3857, 32618 to EPSG:4326 | unit | same | No — Wave 0 |
| FEAS-03 | Already-WGS84 input is returned unchanged (no error) | unit | same | No — Wave 0 |
| FEAS-04 | `as_d3_ir()` on geom_sf plot emits `coord.type = "sf"` | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | No — Wave 0 |
| FEAS-04 | `as_d3_ir()` emits `coord.bbox` with 4 numeric values | integration | same | No — Wave 0 |
| FEAS-04 | Layer has `geometries[]` array equal length to `data[]` array | integration | same | No — Wave 0 |
| FEAS-04 | `validate_ir()` passes without warning on geom_sf IR | integration | same | No — Wave 0 |

### Sampling Rate

- **Per task commit:** `pkgload::load_all(); testthat::test_file("tests/testthat/test-sf-utils.R")`
- **Per wave merge:** `pkgload::load_all(); devtools::test()`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-sf-utils.R` — unit tests for `normalize_to_wgs84()`, `extract_sf_geometries()`, `detect_dominant_geom_type()`, `get_layer_crs()`; covers FEAS-01, FEAS-02, FEAS-03
- [ ] `tests/testthat/test-sf-ir.R` — integration tests for `as_d3_ir()` on geom_sf plots; covers FEAS-04
- [ ] Install geojsonsf: `install.packages("geojsonsf")` — required before FEAS-02 tests can run without skip annotation

## Project Constraints (from CLAUDE.md)

| Directive | Applies To |
|-----------|-----------|
| Use `pkgload::load_all()` not `devtools::load_all()` if devtools unavailable | All development tasks |
| Visual test HTML files must go to `test_output/` in project root | Any visual verification tasks |
| `sf` and `geojsonsf` go to `Suggests:` not `Imports:` in DESCRIPTION | DESCRIPTION edits |
| D3 v7 must be vendored locally at `inst/htmlwidgets/lib/d3/d3.v7.min.js` | Phase 28+ (not Phase 27) |

## Sources

### Primary (HIGH confidence)

- Empirical verification — R 4.5.3, ggplot2 3.5.2, sf 1.1.0 run on 2026-04-04 — all FEAS-01 through FEAS-04 findings
- `R/as_d3_ir.R` — existing pipeline; geom switch at lines 187-224; `keep_aes` at lines 227-238; coord detection at lines 636-641
- `R/validate_ir.R` — `known_geoms` list, panels validation logic, required fields
- `DESCRIPTION` — current `Suggests:` field (only testthat and crosstalk)
- `.planning/research/STACK.md` — sf/geojsonsf version details (2026-04-04)
- `.planning/research/ARCHITECTURE.md` — data flow patterns, code examples (2026-04-04)
- `.planning/research/PITFALLS.md` — 8 critical pitfalls with prevention strategies (2026-04-04)
- `.planning/research/SUMMARY.md` — overall v1.7 architecture approach (2026-04-04)

### Secondary (MEDIUM confidence)

- https://r-spatial.github.io/sf/reference/st_transform.html — `st_transform()` API
- https://r-spatial.github.io/sf/reference/st_bbox.html — `st_bbox()` output format
- https://github.com/SymbolixAU/geojsonsf — `sfc_geojson()` API, CRAN Nov 2025

### Tertiary (LOW confidence)

- spData::world as rnaturalearth substitute — not empirically verified; needs confirmation at test time

## Metadata

**Confidence breakdown:**
- FEAS-01 (geometry column survival): HIGH — empirically verified
- FEAS-02 (GeoJSON serialization): MEDIUM — geojsonsf not installed; verified fallback approach; geojsonsf behavior inferred from CRAN docs and STACK.md
- FEAS-03 (CRS normalization): HIGH — empirically verified for EPSG:4267, 3857, 32618
- FEAS-04 (IR schema): HIGH — schema design based on empirical data structure

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable sf/ggplot2 APIs — 30 days)
