# Phase 35: geom_sf Docs and Validation Hardening - Pattern Map

**Mapped:** 2026-05-20  
**Files analyzed:** 24  
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.Rmd` | documentation source | transform | `README.Rmd` | exact |
| `README.md` | generated documentation | transform | `README.md` from `README.Rmd` | exact-generated |
| `vignettes/gg2d3.Rmd` | documentation source | transform | `vignettes/gg2d3.Rmd` | exact |
| `vignettes/gg2d3-interactivity.Rmd` | documentation source | transform | `vignettes/gg2d3-interactivity.Rmd` | exact |
| `vignettes/d3-drawing-diagnostics.md` | diagnostics documentation | transform | `vignettes/d3-drawing-diagnostics.md` | exact |
| `R/gg2d3.R` | roxygen documentation source | request-response | `R/gg2d3.R` | exact |
| `R/sf_utils.R` | utility + roxygen documentation source | transform | `R/sf_utils.R` | exact |
| `R/d3_zoom.R` | interactivity helper + roxygen documentation source | request-response | `R/d3_zoom.R` | exact |
| `man/gg2d3.Rd` | generated documentation | transform | `man/gg2d3.Rd` | exact-generated |
| `man/d3_zoom.Rd` | generated documentation | transform | `man/d3_zoom.Rd` | exact-generated |
| `man/extract_sf_geometries.Rd` | generated documentation | transform | `R/sf_utils.R` roxygen output | exact-generated |
| `man/normalize_to_wgs84.Rd` | generated documentation | transform | `R/sf_utils.R` roxygen output | exact-generated |
| `man/detect_dominant_geom_type.Rd` | generated documentation | transform | `R/sf_utils.R` roxygen output | exact-generated |
| `man/get_layer_crs.Rd` | generated documentation | transform | `R/sf_utils.R` roxygen output | exact-generated |
| `tests/testthat/test-sf-ir.R` | test | transform | `tests/testthat/test-sf-ir.R` | exact |
| `tests/testthat/test-sf-utils.R` | test | transform | `tests/testthat/test-sf-utils.R` | exact |
| `tests/testthat/test-sf-renderer.R` | test | file-I/O + transform | `tests/testthat/test-sf-renderer.R` | exact |
| `tests/testthat/test-sf-interactivity.R` | test | file-I/O + event-driven | `tests/testthat/test-sf-interactivity.R` | exact |
| `tests/testthat/test-zoom-brush.R` | test | event-driven | `tests/testthat/test-zoom-brush.R` | exact |
| `tests/testthat/test-sf-visual.R` | test/fixture generator | file-I/O | `tests/testthat/test-sf-visual.R` | exact |
| `tests/testthat/test-facets.R` | test | transform | `tests/testthat/test-facets.R` | exact |
| `tests/testthat/test-facet-grid.R` | test | transform | `tests/testthat/test-facet-grid.R` | exact |
| `tests/testthat/test-sf-docs.R` (optional) | test | file-I/O + transform | `tests/testthat/test-sf-renderer.R` | role-match |
| `test_output/phase35-*.html` | manual fixture artifact | file-I/O | `test_output/phase28-*.html` via `tests/testthat/test-sf-visual.R` | exact-generated |

## Pattern Assignments

### `README.Rmd` / `README.md` (documentation source + generated output, transform)

**Analog:** `README.Rmd`

**Generated README source marker** (`README.Rmd` lines 1-13):
````markdown
---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  out.width = "100%"
)
```
````

**Feature table pattern** (`README.Rmd` lines 48-59):
```markdown
## Features

### Geoms

| Category | Geoms |
|----------|-------|
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text` |
| Area/Ribbon | `geom_area`, `geom_ribbon`, `geom_polygon` |
| Intervals | `geom_segment`, `geom_errorbar`, `geom_linerange`, `geom_pointrange` |
| Annotation | `geom_hline`, `geom_vline`, `geom_abline`, `geom_rug` |
| Statistical | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_smooth` (loess, gam, lm), `geom_dotplot` |
```

**Troubleshooting/IR inspection pattern** (`README.Rmd` lines 106-116):
````markdown
## Troubleshooting

- **Console says "no marks drawn"**
  Your layer may be missing a recognized `geom` or data columns. Start with a simple scatter and inspect the IR:
  ```r
  ir <- gg2d3:::as_d3_ir(p)
  str(ir$layers[[1]], max.level = 1)
  ```
````

**Generated-output rule:** `README.md` has the same generated marker (`README.md` line 2). Planner should edit `README.Rmd`, then regenerate with `devtools::build_readme()`; do not plan direct manual edits to `README.md`.

---

### `vignettes/gg2d3.Rmd` (documentation source, transform)

**Analog:** `vignettes/gg2d3.Rmd`

**Vignette header and chunk defaults** (lines 1-16):
````markdown
---
title: "Getting started with gg2d3"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting started with gg2d3}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
```
````

**Section/example style** (lines 42-46, 47-67):
````markdown
## Supported geoms

gg2d3 supports 15 geom types. All aesthetics that ggplot2 maps (color, fill,
size, shape, alpha, linewidth) are carried through to D3.

### Points, lines, and paths

```{r}
# Scatter plot
(ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point(size = 3)) |>
  gg2d3()
```
````

**Edge-case contract style** (lines 496-510):
```markdown
## Error handling and edge cases

gg2d3 provides three observable guarantees when data or geoms fall outside
normal rendering scope:

1. **Non-finite values** ...
2. **Unsupported geoms** ...
3. **R-level errors during build** ...
```

Apply this pattern for the `geom_sf` section: short practical examples first, then a blunt support contract for `POLYGON`/`MULTIPOLYGON`, skipped rows, CRS behavior, zoom suppression, and anti-features.

---

### `vignettes/gg2d3-interactivity.Rmd` (documentation source, event-driven)

**Analog:** `vignettes/gg2d3-interactivity.Rmd`

**Interactivity verb section pattern** (lines 121-155):
````markdown
## Zoom and pan (`d3_zoom`)

`d3_zoom()` enables scroll-wheel zoom and drag-to-pan. Double-click resets
to the original view.

**Signature:** `d3_zoom(widget, scale_extent = c(1, 8), direction = c("both", "x", "y"))`

```{r}
p <- ggplot(economics, aes(date, unemploy)) + geom_line()

# Default: zoom both axes, 1x minimum to 8x maximum
gg2d3(p) |> d3_zoom()
```

Zoom behavior:

- `scale_extent[1]` must be >= 1 (no zoom out beyond the original view).
- Axes - including temporal axes and secondary axes - update dynamically
  during zoom.
````

**Caveat list pattern** (lines 242-256):
```markdown
## Interaction caveats

- **Brush overrides hover** - when a brush selection is active, hover dimming
  is suspended.
- **Faceted plots** - brush selection is per-panel.
- **Zoom extent** - `scale_extent[1]` must be >= 1.
```

Use this for sf-specific notes: tooltip/hover/handlers work on `path.geom-sf`; brush uses centroids; `d3_zoom()` warns and suppresses zoom for sf widgets.

---

### `vignettes/d3-drawing-diagnostics.md` (diagnostics documentation, transform)

**Analog:** `vignettes/d3-drawing-diagnostics.md`

**Current limitations structure** (lines 1-12):
```markdown
# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.

## Geom coverage

gg2d3 supports 15 geom types ...
Geoms not in this list (e.g. `geom_polygon`, `geom_contour`, `geom_sf`) will
log a warning and not render.
```

This file is the stale-doc target. Replace the `geom_sf` unsupported wording with a support-boundary section: polygon-family sf support exists; non-polygon sf rows warn and skip; no basemaps/slippy controls/JS reprojection/non-polygon rendering/overlap brushing/performance guarantees.

---

### `R/gg2d3.R` (roxygen documentation source, request-response)

**Analog:** `R/gg2d3.R`

**Minimal roxygen + widget entry pattern** (lines 1-4, 31-36):
```r
#' Render a ggplot as a D3 widget
#' @param x ggplot object or IR list from as_d3_ir()
#' @export
gg2d3 <- function(x, width = NULL, height = NULL, elementId = NULL) {
  widget <- htmlwidgets::createWidget(
    name = "gg2d3",
    x = widget_data,
    width = width, height = height, package = "gg2d3", elementId = elementId
  )
}
```

If adding help text, keep roxygen concise and generate `man/gg2d3.Rd` from this source.

---

### `R/sf_utils.R` and sf helper `.Rd` files (utility + roxygen, transform)

**Analog:** `R/sf_utils.R`

**Dependency guard pattern** (lines 62-75):
```r
if (!requireNamespace("sf", quietly = TRUE)) {
  stop(
    "The 'sf' package is required for geom_sf support. ",
    "Install with: install.packages('sf')",
    call. = FALSE
  )
}
if (!requireNamespace("geojsonsf", quietly = TRUE)) {
  stop(
    "The 'geojsonsf' package is required for geom_sf support. ",
    "Install with: install.packages('geojsonsf')",
    call. = FALSE
  )
}
```

**Supported geometry and warning contract** (lines 59-116):
```r
prepare_sf_geometry_ir <- function(df,
                                   supported_types = c("POLYGON", "MULTIPOLYGON"),
                                   warn = TRUE) {
  geometry_types <- as.character(sf::st_geometry_type(geom_col, by_geometry = TRUE))
  empty <- sf::st_is_empty(geom_col)
  missing_geometry <- is.na(geom_col)
  valid <- tryCatch(
    sf::st_is_valid(geom_col),
    error = function(e) rep(FALSE, length(geom_col))
  )

  supported <- geometry_types %in% supported_types
  accepted <- supported & !empty & !missing_geometry & valid

  if (warn && missing_crs) {
    warning(
      "geom_sf layer has missing CRS; coordinates will be serialized as-is",
      call. = FALSE
    )
  }
  if (warn && any(skipped)) {
    warning(
      sprintf(
        "geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries",
        sum(skipped)
      ),
      call. = FALSE
    )
  }
}
```

**Diagnostics output pattern** (lines 159-176):
```r
list(
  data = accepted_data,
  geometries = geometries,
  geometry = accepted_geom,
  crs = list(
    epsg = if (!is.na(crs)) crs$epsg else NA_integer_,
    wkt = if (!is.na(crs)) crs$wkt else NA_character_
  ),
  geom_type = geom_type,
  sf_diagnostics = list(
    accepted_rows = source_rows[accepted],
    skipped_rows = source_rows[skipped],
    skipped = skipped_details,
    missing_crs = missing_crs,
    accepted_geometry_types = sort(accepted_geometry_types),
    unsupported_geometry_types = unsupported_geometry_types
  )
)
```

Generated outputs `man/extract_sf_geometries.Rd`, `man/normalize_to_wgs84.Rd`, `man/detect_dominant_geom_type.Rd`, and `man/get_layer_crs.Rd` all carry `Please edit documentation in R/sf_utils.R`; plan roxygen edits in `R/sf_utils.R`, not hand edits in `man/`.

---

### `R/d3_zoom.R` / `man/d3_zoom.Rd` (interactivity helper + docs, event-driven)

**Analog:** `R/d3_zoom.R`

**Roxygen examples and return contract** (lines 1-39):
```r
#' Add zoom and pan to gg2d3 widget
#'
#' Enables mouse-wheel zoom and click-drag pan for a gg2d3 widget. Users can
#' zoom in/out with the mouse wheel, pan by dragging, and double-click to reset
#' to the original view.
#'
#' @return Modified gg2d3 widget with zoom interactivity enabled.
#'   Returns the widget to enable pipe chaining.
#'
#' @examples
#' \dontrun{
#' gg2d3(p) |> d3_zoom()
#' gg2d3(p) |> d3_zoom(direction = "x")
#' gg2d3(p) |> d3_zoom(scale_extent = c(1, 16))
#' }
#' @export
```

**Zoom suppression contract** (lines 60-67):
```r
has_sf_layer <- widget_has_sf_layer(widget)
if (has_sf_layer) {
  warning(
    "d3_zoom() does not support geom_sf layers yet; zoom has been suppressed.",
    call. = FALSE
  )
  return(widget)
}
```

**Generated `.Rd` source marker** (`man/d3_zoom.Rd` lines 1-3):
```r
% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/d3_zoom.R
\name{d3_zoom}
```

---

### `tests/testthat/test-sf-ir.R` (test, transform)

**Analog:** `tests/testthat/test-sf-ir.R`

**Top-level optional dependency guard and package loading** (lines 1-7):
```r
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
```

**Skipped-row contract pattern** (lines 121-153):
```r
test_that("as_d3_ir filters unsupported sf rows and preserves source row_id", {
  mixed <- sf::st_sf(
    id = 1:3,
    label = c("polygon", "point", "multipolygon"),
    geometry = sf::st_sfc(polygon, point, multipolygon, crs = 4326)
  )

  expect_warning(
    ir <- as_d3_ir(ggplot2::ggplot(mixed) + ggplot2::geom_sf()),
    regexp = "skipped 1"
  )

  layer <- ir$layers[[1]]
  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))

  expect_equal(length(layer$data), length(layer$geometries))
  expect_equal(row_ids, c(1, 3))
  expect_equal(layer$sf_diagnostics$accepted_rows, c(1L, 3L))
  expect_equal(layer$sf_diagnostics$skipped_rows, 2L)
  expect_no_warning(validate_ir(ir))
})
```

**Missing CRS warning pattern** (lines 194-212):
```r
expect_warning(
  ir <- as_d3_ir(ggplot2::ggplot(missing_crs) + ggplot2::geom_sf()),
  regexp = "missing CRS"
)

layer <- ir$layers[[1]]
expect_true(layer$sf_diagnostics$missing_crs)
expect_equal(layer$sf_diagnostics$accepted_rows, 1L)
expect_equal(layer$crs$epsg, NA_integer_)
expect_no_warning(validate_ir(ir))
```

---

### `tests/testthat/test-sf-utils.R` (test, transform)

**Analog:** `tests/testthat/test-sf-utils.R`

**Per-test skip guard pattern** (lines 237-266):
```r
test_that("prepare_sf_geometry_ir keeps polygon family and reports unsupported types", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  polygon <- sf::st_polygon(list(square_ring()))
  multipolygon <- sf::st_multipolygon(list(
    list(square_ring(2, 0, 3, 1)),
    list(square_ring(4, 0, 5, 1))
  ))
  point <- sf::st_point(c(0.5, 0.5))
  line <- sf::st_linestring(matrix(c(0, 0, 1, 1), ncol = 2, byrow = TRUE))

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "skipped 2"
  )

  expect_equal(result$data$row_id, c(1L, 2L))
  expect_equal(result$sf_diagnostics$skipped_rows, c(3L, 4L))
  expect_true(all(c("POINT", "LINESTRING") %in% result$sf_diagnostics$unsupported_geometry_types))
})
```

**Invalid/empty/missing CRS patterns**:
- Empty polygon skip: lines 268-284.
- Invalid bowtie skip: lines 287-313.
- Missing CRS warning and as-is serialization: lines 316-333.

---

### `tests/testthat/test-sf-renderer.R` (test, file-I/O + transform)

**Analog:** `tests/testthat/test-sf-renderer.R`

**Source contract reader** (lines 9-16):
```r
read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}
```

**Parallel data/geometry assertions** (lines 35-40):
```r
test_that("geometries and data arrays are the same length", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]
  expect_equal(length(layer$geometries), length(layer$data),
    info = "geometries and data must be parallel arrays of equal length")
})
```

**Renderer source selector assertions** (lines 68-98):
```r
test_that("panel renderer filters sf data and geometries together", {
  gg2d3_js <- read_repo_file("inst/htmlwidgets/gg2d3.js")

  expect_match(gg2d3_js, 'layer\\.geom === "sf"')
  expect_match(gg2d3_js, "Array\\.isArray\\(layer\\.geometries\\)")
  expect_match(gg2d3_js, "sfPairs")
  expect_match(gg2d3_js, "pair\\.data\\.PANEL === panelNum")
  expect_match(gg2d3_js, "geometries: filteredPairs\\.map")
})

test_that("sf renderer consumes shared panel bbox when available", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
})
```

Use this file for the Phase 35 skipped-row interactivity guard: accepted row ids, skipped row ids, selectors, and `data-row-id` must agree so skipped sf rows cannot become selectable paths.

---

### `tests/testthat/test-sf-interactivity.R` (test, file-I/O + event-driven)

**Analog:** `tests/testthat/test-sf-interactivity.R`

**Module reader** (lines 1-8):
```r
read_module <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  resolved <- candidates[file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}
```

**Selector and sanitization assertions** (lines 10-20, 31-41, 78-87):
```r
test_that("sf renderer exposes path row and centroid attributes", {
  sf_js <- read_module("inst/htmlwidgets/modules/geoms/sf.js")
  expect_match(sf_js, "path\\.geom-sf")
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
})

test_that("events module sanitizes sf custom handler data", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "startsWith\\('_'\\)")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
})

test_that("brush module sanitizes sf callback data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "collectSelectedData")
})
```

**Zoom-suppressed composition smoke** (lines 89-112):
```r
w <- gg2d3(p) |>
  d3_brush() |>
  d3_tooltip() |>
  d3_hover()

expect_warning(
  w_zoom <- w |> d3_zoom(),
  "geom_sf.*zoom|zoom.*geom_sf"
)

expect_true(w_zoom$x$interactivity$brush$enabled)
expect_true(w_zoom$x$interactivity$tooltip$enabled)
expect_true(w_zoom$x$interactivity$hover$enabled)
expect_null(w_zoom$x$interactivity$zoom)
```

---

### `tests/testthat/test-zoom-brush.R` (test, event-driven)

**Analog:** `tests/testthat/test-zoom-brush.R`

**Zoom suppression unit pattern** (lines 86-101):
```r
test_that("d3_zoom() warns and suppresses zoom for geom_sf widgets", {
  skip_if_not_installed("sf")
  library(ggplot2)

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot(nc) + geom_sf()

  expect_warning(
    w <- gg2d3(p) |> d3_zoom(),
    "geom_sf.*zoom|zoom.*geom_sf"
  )

  expect_s3_class(w, "gg2d3")
  expect_s3_class(w, "htmlwidget")
  expect_null(w$x$interactivity$zoom)
})
```

---

### `tests/testthat/test-sf-visual.R` / `test_output/phase35-*.html` (fixture generator, file-I/O)

**Analog:** `tests/testthat/test-sf-visual.R`

**Project-root output helper** (lines 9-19):
```r
# Output goes to test_output/ in the project root (per CLAUDE.md convention).

.test_output_dir <- function() {
  pkg_root <- tryCatch(
    rprojroot::find_package_root_file(),
    error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
  )
  file.path(pkg_root, "test_output")
}
```

**HTML fixture generation pattern** (lines 21-45):
```r
test_that("REND-01: NC counties render as filled choropleth via gg2d3 pipeline", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) + ggplot2::geom_sf()

  w <- gg2d3(p)
  expect_s3_class(w, "htmlwidget")

  outpath <- file.path(out_dir, "phase28-nc-choropleth.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                          selfcontained = TRUE)
  expect_true(file.exists(outpath))

  ir <- as_d3_ir(p)
  sf_layer <- ir$layers[[1]]
  expect_equal(sf_layer$geom, "sf")
  expect_true(length(sf_layer$geometries) > 0)
  expect_true("row_id" %in% names(sf_layer$data[[1]]))
})
```

**Optional data fixture guard** (lines 47-76):
```r
test_that("REND-02/03: World borders render with multipolygon holes and correct aesthetics", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  skip_if_not_installed("rnaturalearth")

  world <- rnaturalearth::ne_countries(scale = "small", returnclass = "sf")
  p <- ggplot2::ggplot(world) +
    ggplot2::geom_sf(ggplot2::aes(fill = pop_est))

  outpath <- file.path(out_dir, "phase28-world-holes.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                          selfcontained = TRUE)
  expect_true(file.exists(outpath))
})
```

Phase 35 fixture names should follow `phase35-*.html` and stay under project-root `test_output/`. Required scenarios from context: choropleth, stacked overlay, `facet_wrap`, `facet_grid`, unsupported/mixed rows, invalid/empty/missing geometry rows, tooltip/hover/handler smoke, centroid brush smoke, and zoom suppression.

---

### `tests/testthat/test-facets.R` / `tests/testthat/test-facet-grid.R` (test, transform)

**Analog:** `tests/testthat/test-facets.R` and `tests/testthat/test-facet-grid.R`

**facet_wrap sf bbox isolation pattern** (`tests/testthat/test-facets.R` lines 173-203):
```r
test_that("facet_wrap sf panels use per-panel sf_bbox from their own rows", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  sf_data <- sf::st_sf(
    facet = factor(c("A", "B"), levels = c("A", "B")),
    geometry = sf::st_sfc(
      sf::st_polygon(list(facet_sf_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(facet_sf_square_ring(100, 0, 101, 1))),
      crs = 4326
    )
  )

  ir <- as_d3_ir(
    ggplot2::ggplot(sf_data) +
      ggplot2::geom_sf() +
      ggplot2::facet_wrap(~facet)
  )

  expect_equal(ir$facets$type, "wrap")
  expect_false(is.null(panel_a$sf_bbox))
  expect_false(is.null(panel_b$sf_bbox))
  expect_false(identical(panel_a$sf_bbox, panel_b$sf_bbox))
  expect_no_warning(validate_ir(ir))
})
```

**facet_grid sf layout/isolation pattern** (`tests/testthat/test-facet-grid.R` lines 167-209):
```r
test_that("facet_grid sf panels preserve layout and isolate sf_bbox", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  ir <- as_d3_ir(
    ggplot2::ggplot(sf_data) +
      ggplot2::geom_sf() +
      ggplot2::facet_grid(row_var ~ col_var)
  )

  expect_equal(ir$facets$type, "grid")
  expect_equal(length(ir$panels), 4)
  expect_equal(ir$facets$nrow, 2L)
  expect_equal(ir$facets$ncol, 2L)
  for (entry in ir$facets$layout) {
    expect_true(is.integer(entry$PANEL))
    expect_true(is.integer(entry$ROW))
    expect_true(is.integer(entry$COL))
  }

  expect_true(is.null(panel_by$sf_bbox))
  expect_no_warning(validate_ir(ir))
})
```

Use these for structural assertions behind the manual facet HTML fixtures.

---

### `tests/testthat/test-sf-docs.R` (optional new test, file-I/O + transform)

**Analog:** `tests/testthat/test-sf-renderer.R`

If planner chooses docs-source assertions, copy the existing `read_repo_file()` helper from `tests/testthat/test-sf-renderer.R` lines 9-16 and assert documentation text with `expect_match(read_repo_file(...), ...)`.

Recommended checks:
- `README.Rmd` and `README.md` mention polygon-family `geom_sf`.
- `vignettes/d3-drawing-diagnostics.md` no longer says `geom_sf` is unsupported without qualification.
- `R/d3_zoom.R` and `man/d3_zoom.Rd` describe warning/suppression for sf widgets.

## Shared Patterns

### Generated Documentation
**Source:** `README.Rmd`, `R/*.R` roxygen blocks, `man/*.Rd` markers  
**Apply to:** `README.md`, `man/gg2d3.Rd`, `man/d3_zoom.Rd`, sf helper `.Rd` files

```r
# README workflow from AGENTS.md
devtools::build_readme()

# roxygen workflow from AGENTS.md
devtools::document()
```

Generated files carry explicit markers:
```r
<!-- README.md is generated from README.Rmd. Please edit that file -->
% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/d3_zoom.R
```

### Optional Spatial Dependencies
**Source:** `tests/testthat/test-sf-ir.R` lines 1-2, `tests/testthat/test-sf-visual.R` lines 47-50  
**Apply to:** all sf/geojsonsf/rnaturalearth tests and fixtures

```r
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")
skip_if_not_installed("rnaturalearth")
```

### Sf Diagnostics and Row Identity
**Source:** `R/sf_utils.R` lines 97-124 and 168-175  
**Apply to:** docs, IR tests, renderer/interactivity guard tests

```r
supported <- geometry_types %in% supported_types
accepted <- supported & !empty & !missing_geometry & valid
accepted_data <- df[accepted, , drop = FALSE]
accepted_data[["row_id"]] <- source_rows[accepted]

sf_diagnostics = list(
  accepted_rows = source_rows[accepted],
  skipped_rows = source_rows[skipped],
  skipped = skipped_details,
  missing_crs = missing_crs,
  accepted_geometry_types = sort(accepted_geometry_types),
  unsupported_geometry_types = unsupported_geometry_types
)
```

### Source Contract Assertions
**Source:** `tests/testthat/test-sf-renderer.R` and `tests/testthat/test-sf-interactivity.R`  
**Apply to:** skipped-row path guard, selector inclusion, callback sanitization, centroid brushing

```r
expect_match(sf_js, "path\\.geom-sf")
expect_match(sf_js, "data-row-id")
expect_match(sf_js, "data-cx")
expect_match(sf_js, "data-cy")
expect_match(events_js, "startsWith\\('_'\\)")
expect_match(brush_js, "sanitizeSelectedDatum")
```

### Manual HTML Fixtures
**Source:** `tests/testthat/test-sf-visual.R` lines 11-19 and 34-37  
**Apply to:** `test_output/phase35-*.html`

```r
out_dir <- .test_output_dir()
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
outpath <- file.path(out_dir, "phase35-sf-choropleth.html")
htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                        selfcontained = TRUE)
expect_true(file.exists(outpath))
```

## No Analog Found

None. Every Phase 35 target has an existing same-role analog. The only optional new file, `tests/testthat/test-sf-docs.R`, should reuse the source-file assertion helper already present in `tests/testthat/test-sf-renderer.R`.

## Metadata

**Analog search scope:** `README.Rmd`, `README.md`, `R/`, `man/`, `vignettes/`, `tests/testthat/`, `test_output/` conventions  
**Files scanned:** 20 primary files plus generated-doc index checks  
**Pattern extraction date:** 2026-05-20  
**Project instructions loaded:** `AGENTS.md`, `CLAUDE.md`, `/Users/davidzenz/.codex/RTK.md`  
**Repo-local skills:** none found under `.claude/skills/` or `.agents/skills/`
