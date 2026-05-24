# Phase 45: Rect And Tile Edge Closure - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/as_d3_ir.R` | utility / IR transformer | transform | `R/as_d3_ir.R` rect/tile and facet sections | exact |
| `inst/htmlwidgets/modules/geoms/rect.js` | renderer component | transform | `inst/htmlwidgets/modules/geoms/rect.js` existing rect renderer | exact |
| `inst/htmlwidgets/modules/geom-registry.js` | registry / update service | event-driven transform | `inst/htmlwidgets/modules/geom-registry.js` rect and bar update blocks | exact |
| `tests/testthat/test-rect-tile-ir.R` | test | batch transform | `tests/testthat/test-polygon-ir.R`, `tests/testthat/test-regression-core.R`, `tests/testthat/test-coord-flip.R` | role-match |
| `tests/testthat/test-rect-tile-renderer.R` | test | source contract | `tests/testthat/test-polygon-renderer.R` | exact |
| `tests/testthat/test-rect-tile-browser.R` | optional test | browser DOM / file-I/O | `tests/testthat/test-polygon-browser.R` | role-match |
| `tests/testthat/helper-browser-rect-tile.R` | optional test utility | browser DOM / file-I/O | `tests/testthat/helper-browser-polygon.R` | role-match |
| `vignettes/d3-drawing-diagnostics.md` | documentation | batch | `vignettes/d3-drawing-diagnostics.md` rect/tile section | exact |
| `.planning/phases/45-rect-and-tile-edge-closure/45-VERIFICATION.md` | verification documentation | batch | `.planning/phases/44-ordinary-geom-polygon-support/44-VERIFICATION.md` | role-match |

## Pattern Assignments

### `R/as_d3_ir.R` (utility / IR transformer, transform)

**Analog:** `R/as_d3_ir.R`

**Entry and ggplot build pattern** (lines 9-13):
```r
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)
  is_flip <- inherits(b$plot$coordinates, "CoordFlip")
```

**Discrete boundary mapping pattern** (lines 175-193):
```r
if ("x" %in% names(df) && !all(is.na(df$x))) {
  df$x <- map_discrete(df$x, xscale_obj)
}
if ("y" %in% names(df) && !all(is.na(df$y))) {
  df$y <- map_discrete(df$y, yscale_obj)
}
if ("xmin" %in% names(df) && !all(is.na(df$xmin))) {
  df$xmin <- map_discrete(df$xmin, xscale_obj)
}
if ("xmax" %in% names(df) && !all(is.na(df$xmax))) {
  df$xmax <- map_discrete(df$xmax, xscale_obj)
}
if ("ymin" %in% names(df) && !all(is.na(df$ymin))) {
  df$ymin <- map_discrete(df$ymin, yscale_obj)
}
if ("ymax" %in% names(df) && !all(is.na(df$ymax))) {
  df$ymax <- map_discrete(df$ymax, yscale_obj)
}
```

**Geom mapping pattern** (lines 198-209):
```r
gname <- switch(gcl,
                GeomPoint  = "point",
                GeomLine   = "line",
                GeomPath   = "path",
                GeomCol    = "bar",
                GeomBar    = "bar",

                GeomArea   = "area",
                GeomText   = "text",
                GeomLabel  = "text",
                GeomRect   = "rect",
                GeomTile   = "rect",
```

**Rect boundary field contract** (lines 278-287):
```r
cols <- intersect(keep_aes, names(df))
aes <- list(
  x     = if ("x"     %in% cols) "x"     else NULL,
  y     = if ("y"     %in% cols) "y"     else NULL,
  xend  = if ("xend"  %in% cols) "xend"  else NULL,
  yend  = if ("yend"  %in% cols) "yend"  else NULL,
  xmin  = if ("xmin"  %in% cols) "xmin"  else NULL,
  xmax  = if ("xmax"  %in% cols) "xmax"  else NULL,
  ymin  = if ("ymin"  %in% cols) "ymin"  else NULL,
  ymax  = if ("ymax"  %in% cols) "ymax"  else NULL,
```

**Validation and return pattern** (lines 921-930):
```r
ir <- list(
  width = width, height = height, padding = padding,
  coord  = c(list(type = coord_type, flip = is_flip, ratio = coord_ratio), polar_meta, sf_coord_meta),
  title  = b$plot$labels$title %||% "", subtitle = subtitle_text, caption = caption_text,
  axes   = list(x = list(orientation = "bottom", label = x_label, tickLabels = x_tick_labels), y = list(orientation = "left",  label = y_label, tickLabels = y_tick_labels), x2 = if (has_sec_x) list(enabled = TRUE) else NULL, y2 = if (has_sec_y) list(enabled = TRUE) else NULL),
  facets = facets_ir, panels = panels_ir, scales = scales, layers = layers, guides = guides_ir, legend = list(enabled = TRUE, position = legend_position), theme = theme_ir,
  aes_by_var = aes_by_var
)
validate_ir(ir)
```

**Apply to Phase 45:** Preserve `ggplot2::ggplot_build()` as the source of truth. If classification proves a mismatch, patch only the row/boundary mapping that conflicts with built data. Do not create a separate out-of-bounds classifier unless tests prove the existing ggplot-built rows cannot express the expected behavior.

---

### `inst/htmlwidgets/modules/geoms/rect.js` (renderer component, transform)

**Analog:** `inst/htmlwidgets/modules/geoms/rect.js`

**Module wrapper and helper import pattern** (lines 14-39):
```javascript
(function() {
  'use strict';

  function renderRect(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);
```

**Defensive row filtering pattern** (lines 41-48):
```javascript
// Helper to get column value from row
const get = (d, k) => (k && d != null) ? d[k] : null;

// Filter valid rectangles (must have all 4 bounds)
const rects = dat.filter(d =>
  get(d, aes.xmin) != null && get(d, aes.xmax) != null &&
  get(d, aes.ymin) != null && get(d, aes.ymax) != null
);
```

**Scale and coord branch pattern** (lines 50-52):
```javascript
const isXBand = typeof xScale.bandwidth === "function";
const isYBand = typeof yScale.bandwidth === "function";
const flip = !!options.flip;
```

**Flipped rect geometry pattern** (lines 88-112):
```javascript
if (flip) {
  sel.enter().append("rect")
    .attr("class", "geom-rect")
    .attr("x", d => {
      const ymax = isYBand ? val(get(d, aes.ymax)) : num(get(d, aes.ymax));
      const ymin = isYBand ? val(get(d, aes.ymin)) : num(get(d, aes.ymin));
      return Math.min(yScale(ymax), yScale(ymin));
    })
    .attr("y", d => {
      const xmin = isXBand ? val(get(d, aes.xmin)) : num(get(d, aes.xmin));
      const xmax = isXBand ? val(get(d, aes.xmax)) : num(get(d, aes.xmax));
      return Math.min(xScale(xmin), xScale(xmax));
    })
    .attr("width", d => {
      if (isYBand) return yScale.bandwidth();
      const y1 = yScale(num(get(d, aes.ymin)));
      const y2 = yScale(num(get(d, aes.ymax)));
      return Math.abs(y2 - y1);
    })
    .attr("height", d => {
      if (isXBand) return xScale.bandwidth();
      const x1 = xScale(num(get(d, aes.xmin)));
      const x2 = xScale(num(get(d, aes.xmax)));
      return Math.abs(x2 - x1);
    })
```

**Non-flipped rect geometry pattern** (lines 127-149):
```javascript
} else {
  sel.enter().append("rect")
    .attr("class", "geom-rect")
    .attr("x", d => {
      const xmin = isXBand ? val(get(d, aes.xmin)) : num(get(d, aes.xmin));
      return xScale(xmin);
    })
    .attr("y", d => {
      const ymax = isYBand ? val(get(d, aes.ymax)) : num(get(d, aes.ymax));
      return yScale(ymax);
    })
    .attr("width", d => {
      if (isXBand) return xScale.bandwidth();
      const x1 = xScale(num(get(d, aes.xmin)));
      const x2 = xScale(num(get(d, aes.xmax)));
      return Math.abs(x2 - x1);
    })
    .attr("height", d => {
      if (isYBand) return yScale.bandwidth();
      const y1 = yScale(num(get(d, aes.ymin)));
      const y2 = yScale(num(get(d, aes.ymax)));
      return Math.abs(y2 - y1);
    })
```

**Registration pattern** (lines 166-170):
```javascript
return rects.length;
}

// Register with geom registry (both rect and tile use same renderer)
window.gg2d3.geomRegistry.register(['rect', 'tile'], renderRect);
```

**Apply to Phase 45:** Keep `rect.geom-rect` as the DOM selector and keep null-bound filtering before attribute writes. If out-of-bounds coordinates are intentionally clipped, tests should allow negative or oversized `x`/`y`/`width`/`height` as long as they are finite and the mark has a clip-path ancestor.

---

### `inst/htmlwidgets/modules/geom-registry.js` (registry / update service, event-driven transform)

**Analog:** `inst/htmlwidgets/modules/geom-registry.js`

**Registry wrapper and exported API pattern** (lines 14-22, 411-417):
```javascript
(function() {
  'use strict';

  // Initialize namespace
  if (!window.gg2d3) window.gg2d3 = {};
  if (!window.gg2d3.geomRegistry) window.gg2d3.geomRegistry = {};

  // Registry storage: geom name -> renderer function
  const renderers = {};
```

```javascript
// Export to window.gg2d3.geomRegistry namespace
window.gg2d3.geomRegistry.register = registerGeom;
window.gg2d3.geomRegistry.render = renderGeom;
window.gg2d3.geomRegistry.has = hasGeom;
window.gg2d3.geomRegistry.list = listGeoms;
window.gg2d3.geomRegistry.makeColorAccessors = makeColorAccessors;
window.gg2d3.geomRegistry.updateGeoms = updateGeoms;
```

**Update setup pattern** (lines 202-208):
```javascript
function updateGeoms(container, xScale, yScale, options) {
  const flip = !!options.flip;
  const t = options.transition || d3.transition().duration(0);

  const xScaleFunc = flip ? yScale : xScale;
  const yScaleFunc = flip ? xScale : yScale;
```

**Rect update pattern that must stay aligned with `rect.js`** (lines 243-249):
```javascript
// geom_rect / geom_tile
container.selectAll('rect.geom-rect')
  .transition(t)
  .attr('x', d => Math.min(xScaleFunc(d.xmin), xScaleFunc(d.xmax)))
  .attr('y', d => Math.min(yScaleFunc(d.ymin), yScaleFunc(d.ymax)))
  .attr('width', d => Math.abs(xScaleFunc(d.xmax) - xScaleFunc(d.xmin)))
  .attr('height', d => Math.abs(yScaleFunc(d.ymax) - yScaleFunc(d.ymin)));
```

**Branching update analog for coord-specific geometry** (lines 215-241):
```javascript
// geom_bar
container.selectAll('rect.geom-bar')
  .transition(t)
  .each(function(d) {
    const elem = d3.select(this);
    if (flip) {
      const y0 = yScaleFunc(d.y);
      const y1 = yScaleFunc(d.yend);
      const x0 = xScaleFunc(d.xmin);
      const x1 = xScaleFunc(d.xmax);
      elem
        .attr('x', Math.min(y0, y1))
        .attr('y', Math.min(x0, x1))
        .attr('width', Math.abs(y1 - y0))
        .attr('height', Math.abs(x1 - x0));
    } else {
      const bx0 = xScaleFunc(d.xmin);
      const bx1 = xScaleFunc(d.xmax);
      const by0 = yScaleFunc(d.y);
      const by1 = yScaleFunc(d.yend);
      elem
        .attr('x', Math.min(bx0, bx1))
        .attr('y', Math.min(by0, by1))
        .attr('width', Math.abs(bx1 - bx0))
        .attr('height', Math.abs(by1 - by0));
    }
  });
```

**Apply to Phase 45:** Any geometry change in `rect.js` must be mirrored here or explicitly locked as unnecessary with source-contract tests. Prefer a helper or matched source-contract assertions if the rect and update math become more complex.

---

### `tests/testthat/test-rect-tile-ir.R` (test, batch transform)

**Analogs:** `tests/testthat/test-polygon-ir.R`, `tests/testthat/test-regression-core.R`, `tests/testthat/test-coord-flip.R`, `tests/testthat/test-facets.R`

**Load package and ggplot2 pattern** (`test-polygon-ir.R` lines 1-3):
```r
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

library(ggplot2)
```

**IR helper pattern** (`test-polygon-ir.R` lines 5-17):
```r
expect_valid_ir <- function(ir) {
  expect_silent(validate_ir(ir))
  TRUE
}

expect_polygon_ir <- function(plot) {
  ir <- as_d3_ir(plot)
  expect_true(expect_valid_ir(ir))
  layer <- ir$layers[[1]]
  expect_equal(layer$geom, "polygon")
  expect_true(length(layer$data) > 0L)
  layer
}
```

**Row extraction helpers pattern** (`test-polygon-ir.R` lines 19-31):
```r
expect_polygon_row_fields <- function(rows, fields) {
  for (row in rows) {
    expect_true(all(fields %in% names(row)))
  }
}

row_values <- function(rows, field) {
  vapply(rows, function(row) row[[field]], rows[[1]][[field]])
}

rows_for <- function(rows, field, value) {
  rows[vapply(rows, function(row) identical(row[[field]], value), logical(1))]
}
```

**Existing rect fixture analog** (`test-regression-core.R` lines 33-60):
```r
test_that("HARD-03 regression matrix covers representative non-sf geoms", {
  base <- data.frame(
    x = c(1, 2, 3, 4),
    y = c(2, 3, 2, 5),
    group = c("a", "a", "b", "b"),
    label = c("one", "two", "three", "four")
  )
  rects <- data.frame(xmin = c(0, 2), xmax = c(1, 3), ymin = c(0, 1), ymax = c(2, 4))

  plots <- list(
    geom_point = ggplot2::ggplot(base, ggplot2::aes(x, y)) + ggplot2::geom_point(),
    geom_line = ggplot2::ggplot(base, ggplot2::aes(x, y, group = group)) + ggplot2::geom_line(),
    geom_col = ggplot2::ggplot(base, ggplot2::aes(group, y)) + ggplot2::geom_col(),
    geom_rect = ggplot2::ggplot(rects) +
      ggplot2::geom_rect(ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)),
    geom_text = ggplot2::ggplot(base, ggplot2::aes(x, y, label = label)) + ggplot2::geom_text(),
    geom_segment = ggplot2::ggplot(base, ggplot2::aes(x = x, y = y, xend = x + 0.5, yend = y + 0.5)) +
      ggplot2::geom_segment(),
    geom_boxplot = ggplot2::ggplot(base, ggplot2::aes(group, y)) + ggplot2::geom_boxplot(),
    geom_smooth = ggplot2::ggplot(base, ggplot2::aes(x, y)) +
      ggplot2::geom_smooth(method = "lm", se = FALSE)
  )
```

**Coord flip assertion pattern** (`test-coord-flip.R` lines 27-47):
```r
test_that("facet_wrap with coord_flip preserves IR structure", {
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    facet_wrap(~ am) +
    coord_flip()
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "wrap")
  expect_true(ir$coord$flip)

  expect_equal(ir$scales$x$type, "categorical")
  expect_equal(ir$scales$y$type, "continuous")

  for (panel in ir$panels) {
    expect_equal(length(panel$x_range), 3)
    expect_equal(length(panel$y_range), 2)
  }
})
```

**Facet panel metadata pattern** (`test-facets.R` lines 45-62):
```r
test_that("panels array has per-panel scale metadata", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(length(ir$panels), 3)
  for (panel in ir$panels) {
    expect_true(is.integer(panel$PANEL))
    expect_true(length(panel$x_range) >= 2)
    expect_true(length(panel$y_range) >= 2)
    expect_true(length(panel$x_breaks) > 0)
    expect_true(length(panel$y_breaks) > 0)
  }

  expect_equal(ir$panels[[1]]$x_range, ir$panels[[2]]$x_range)
  expect_equal(ir$panels[[1]]$y_range, ir$panels[[2]]$y_range)
})
```

**Apply to Phase 45:** Build a local helper like `classify_rect_tile_case(plot)` that returns both `ggplot2::ggplot_build(plot)$data[[1]]` boundary state and `as_d3_ir(plot)$layers[[1]]` boundary state. Cover scale limits, `coord_cartesian()` limits, discrete `geom_tile()`, reversed scales, `coord_flip()`, and facets in separate `test_that()` blocks so a renderer mismatch is not confused with ggplot2 data censoring.

---

### `tests/testthat/test-rect-tile-renderer.R` (test, source contract)

**Analog:** `tests/testthat/test-polygon-renderer.R`

**Source reader pattern** (lines 1-8):
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

**Module registration contract pattern** (lines 10-18):
```r
test_that("POLY-02 polygon renderer module is bundled and registered", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")
  yaml <- read_repo_file("inst/htmlwidgets/gg2d3.yaml")

  expect_match(yaml, "geoms/polygon\\.js")
  expect_match(polygon_js, "function renderPolygon")
  expect_match(polygon_js, "geomRegistry\\.register\\(['\"]polygon['\"]")
  expect_match(polygon_js, "path\\.geom-polygon|geom-polygon")
})
```

**Update path contract pattern** (lines 55-65):
```r
test_that("POLY-02 polygon paths participate in path update plumbing", {
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  update_start <- regexpr("Closed path geoms \\(polygon\\)", registry_js)
  expect_true(update_start[[1]] > 0)
  update_block <- substr(registry_js, update_start[[1]], nchar(registry_js))

  expect_match(update_block, "path\\.geom-polygon")
  expect_match(update_block, "_polygonPoints")
  expect_match(update_block, "curveLinearClosed")
})
```

**Apply to Phase 45:** Assert `rect.js` still registers `['rect', 'tile']`, filters missing bounds, emits `rect.geom-rect`, contains band-scale branches, and keeps update plumbing in `geom-registry.js`. If renderer math is changed, assert the same helper names or core expressions exist in both initial render and update path.

---

### `tests/testthat/test-rect-tile-browser.R` (optional test, browser DOM / file-I/O)

**Analog:** `tests/testthat/test-polygon-browser.R`

**Load helper and package pattern** (lines 3-17):
```r
# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_polygon_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-polygon.R",
    "helper-browser-polygon.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

library(ggplot2)
```

**DOM extraction script pattern** (lines 91-103):
```r
.browser_polygon_paths_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('path.geom-polygon')).map(path => ({",
    "d: path.getAttribute('d') || '',",
    "fill: path.getAttribute('fill') || '',",
    "stroke: path.getAttribute('stroke') || '',",
    "opacity: path.getAttribute('opacity') || '',",
    "strokeWidth: path.getAttribute('stroke-width') || '',",
    "strokeDasharray: path.getAttribute('stroke-dasharray') || '',",
    "hasClipAncestor: !!path.closest('g[clip-path]'),",
    "className: path.getAttribute('class') || ''",
    "})))()"
  )
}
```

**Wait and assertion pattern** (lines 120-148):
```r
.browser_polygon_wait_for_paths <- function(session, expected, timeout = 10) {
  deadline <- Sys.time() + timeout
  repeat {
    count <- eval_js_value(
      session,
      "document.querySelectorAll('path.geom-polygon').length"
    )
    if (!is.null(count) && count >= expected) {
      return(eval_js_value(session, .browser_polygon_paths_script()))
    }
    if (Sys.time() >= deadline) break
    Sys.sleep(0.1)
  }

  testthat::fail(sprintf(
    "Timed out waiting for %s path.geom-polygon nodes after %s seconds",
    expected,
    timeout
  ))
}

.browser_polygon_expect_paths <- function(paths, expected) {
  expect_length(paths, expected)
  for (path in paths) {
    expect_true(grepl("geom-polygon", path$className, fixed = TRUE))
    expect_true(nzchar(path$d))
    expect_true(grepl("Z\\s*$", path$d))
    expect_true(isTRUE(path$hasClipAncestor))
  }
}
```

**Browser test body pattern** (lines 205-235):
```r
test_that("POLY-02 DOM: single and grouped polygon paths render closed clipped marks", {
  skip_browser_polygon_smoke()

  fixtures <- list(
    single = list(plot = .browser_polygon_single_plot(), expected = 1L),
    grouped = list(plot = .browser_polygon_grouped_plot(), expected = 2L)
  )

  with_chromote_session({
    logs <- browser_polygon_console_collector(session)

    for (name in names(fixtures)) {
      html_path <- save_browser_polygon_widget(
        gg2d3(fixtures[[name]]$plot),
        paste0("phase44-polygon-", name, ".html")
      )

      tryCatch(
        {
          session$go_to(.browser_polygon_file_url(html_path), delay = 1)
          paths <- .browser_polygon_wait_for_paths(session, fixtures[[name]]$expected)
          .browser_polygon_expect_paths(paths, fixtures[[name]]$expected)
          assert_no_polygon_browser_errors(logs)
        },
```

**Apply to Phase 45:** Translate `path.geom-polygon` to `rect.geom-rect`. DOM assertions should collect numeric `x`, `y`, `width`, `height`, class name, and `hasClipAncestor`. Assert finite non-negative dimensions and expected node counts; do not assert screenshots.

---

### `tests/testthat/helper-browser-rect-tile.R` (optional test utility, browser DOM / file-I/O)

**Analog:** `tests/testthat/helper-browser-polygon.R`

**CRAN-compatible skip pattern** (lines 20-49):
```r
skip_browser_polygon_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote polygon smoke tests"
  )

  launch <- tryCatch(
    {
      session <- chromote::ChromoteSession$new(width = 10, height = 10)
      on.exit(session$close(), add = TRUE)
      TRUE
    },
    error = function(e) e
  )
  launch_message <- if (inherits(launch, "condition")) {
    conditionMessage(launch)
  } else {
    as.character(launch)
  }
  testthat::skip_if(
    !isTRUE(launch),
    paste("chromote session launch unavailable:", launch_message)
  )

  invisible(TRUE)
}
```

**Artifact output and widget save pattern** (lines 51-66):
```r
browser_polygon_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-polygon")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

save_browser_polygon_widget <- function(widget, filename) {
  outpath <- file.path(browser_polygon_artifact_dir(), filename)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(outpath, mustWork = FALSE),
    selfcontained = FALSE
  )
  testthat::expect_true(file.exists(outpath))
  outpath
}
```

**Chromote evaluation pattern** (lines 68-85):
```r
with_chromote_session <- function(code, width = 900, height = 700) {
  session <- chromote::ChromoteSession$new(width = width, height = height)
  on.exit(session$close(), add = TRUE)

  eval(
    substitute(code),
    envir = list2env(list(session = session), parent = parent.frame())
  )
}

eval_js_value <- function(session, script) {
  result <- session$Runtime$evaluate(
    script,
    returnByValue = TRUE,
    awaitPromise = TRUE
  )
  result$result$value
}
```

**Browser error assertion pattern** (lines 150-169):
```r
assert_no_polygon_browser_errors <- function(logs) {
  entries <- .browser_polygon_logs(logs)
  if (length(entries) == 0) return(invisible(TRUE))

  is_error <- vapply(entries, function(entry) {
    identical(entry$source, "Runtime.exceptionThrown") ||
      identical(entry$type, "exception") ||
      identical(entry$type, "error") ||
      identical(entry$type, "assert")
  }, logical(1))

  if (any(is_error)) {
    messages <- vapply(entries[is_error], function(entry) {
      paste(entry$source %||% "browser", entry$type %||% "error", entry$message %||% "", sep = ": ")
    }, character(1))
    testthat::fail(paste(c("Browser errors were captured:", messages), collapse = "\n"))
  }

  invisible(TRUE)
}
```

**Apply to Phase 45:** Reuse the helper directly if the planner accepts polygon-named helpers, or create a rect/tile-specific copy with names changed to `rect_tile`. Keep `skip_on_cran()`, `skip_if_not_installed("chromote", "0.5.1")`, Chrome detection, launch probing, and failure artifacts under `test_output/`.

---

### `vignettes/d3-drawing-diagnostics.md` (documentation, batch)

**Analog:** `vignettes/d3-drawing-diagnostics.md`

**Existing limitations style** (lines 1-5):
```markdown
# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.
```

**Existing rect/tile note to replace or narrow** (lines 60-65):
```markdown
## Rect/tile edge cases

`geom_rect` and `geom_tile` are clipped at the panel boundary, but rectangles
whose bounds extend beyond scale limits or interact with transformed/reversed
scales remain a known edge case. The current release treats this as deferred
non-blocking renderer debt unless a focused regression proves otherwise.
```

**Optional-browser language precedent** (lines 33-35):
```markdown
Optional browser validation is R/testthat/chromote based and may skip cleanly;
when available, it covers sf family interactivity, stacked overlays, faceted and
empty panels, skipped rows, and zoom suppression.
```

**Apply to Phase 45:** Replace the deferred wording only after tests classify the behavior. Valid endings are either "fixed by renderer/IR changes with regression tests" or "verified compatible with ggplot2/SVG panel clipping and locked by tests." Do not broaden into public docs unless support contract changes.

---

### `.planning/phases/45-rect-and-tile-edge-closure/45-VERIFICATION.md` (verification documentation, batch)

**Analog:** `.planning/phases/44-ordinary-geom-polygon-support/44-VERIFICATION.md`

**Frontmatter pattern** (lines 1-7):
```markdown
---
phase: 44-ordinary-geom-polygon-support
verified: 2026-05-24T18:50:55Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---
```

**Goal achievement table pattern** (lines 16-34):
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `as_d3_ir()` recognizes `GeomPolygon` layers and preserves group/order, x/y coordinates, and supported aesthetics. | VERIFIED | `R/as_d3_ir.R:224` maps `GeomPolygon= "polygon"`; `R/as_d3_ir.R:239-252` keeps `PANEL`, coordinates, `group`, `fill`, `colour`, `alpha`, `linewidth`, and `linetype`; `test-polygon-ir.R` passed 79 assertions. |
| 2 | D3 renders each ordinary polygon group as a closed SVG path with ggplot2-like fill, stroke, alpha, clipping, and facet placement. | VERIFIED | `polygon.js` groups rows with `d3.group`, uses `curveLinearClosed`, appends `path.geom-polygon`, applies fill/stroke/linewidth/linetype/opacity, and browser DOM tests passed in full suite. |
```

**Behavioral spot-check pattern** (lines 80-87):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 44 targeted tests | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-zoom-path-datum.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | IR 79 pass, renderer 27 pass, zoom 18 pass, interactivity 54 pass, browser 5 explicit CRAN skips | PASS |
| Forced browser direct run handles unavailable browser tooling | `rtk env NOT_CRAN=true Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | 5 explicit skips: chromote session launch unavailable, cannot find an available port | PASS |
| Full package regression suite | `rtk Rscript --vanilla -e 'devtools::test()'` | `FAIL 0`, `WARN 6`, `SKIP 40`, `PASS 1058`; `polygon-browser` passed 77 assertions live | PASS |
```

**Gaps summary pattern** (lines 106-112):
```markdown
### Human Verification Required

None. Phase 44's contract is covered by IR assertions, source/selector checks, and DOM/callback browser smoke tests; no screenshot or perceptual gate is part of this phase.

### Gaps Summary

No gaps found. Phase 44 achieves its goal and satisfies POLY-01, POLY-02, and POLY-03.
```

**Apply to Phase 45:** Verification should explicitly state whether rect/tile edge behavior was fixed or closed as a non-issue. Include commands from `45-VALIDATION.md`, direct result summaries, and the diagnostics note status.

## Shared Patterns

### IR Source Of Truth
**Source:** `R/as_d3_ir.R`
**Apply to:** `R/as_d3_ir.R`, `tests/testthat/test-rect-tile-ir.R`
```r
b <- ggplot2::ggplot_build(p)
```

Use `ggplot_build()` rows to classify scale-limit censoring before renderer assertions. Phase 45 tests should compare built-data bounds and IR bounds for the same fixture.

### Boundary Fields
**Source:** `R/as_d3_ir.R`
**Apply to:** IR tests, renderer tests, rect renderer, update path
```r
"PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
```

The rect/tile contract is the preservation or intentional loss of `xmin`, `xmax`, `ymin`, and `ymax`. Tests should avoid inferring rect behavior from center `x`/`y` alone.

### Panel Clipping
**Source:** `inst/htmlwidgets/gg2d3.js`
**Apply to:** `tests/testthat/test-rect-tile-browser.R`, `vignettes/d3-drawing-diagnostics.md`
```javascript
// Clip path definition
root.select("defs").append("clipPath").attr("id", clipId)
  .append("rect").attr("width", w).attr("height", h);

// Clipped group for data
const gClipped = g.append("g").attr("clip-path", "url(#" + clipId + ")");
```

Out-of-panel SVG coordinates are not automatically bugs. DOM smoke should check clip-path ancestry and finite dimensions rather than visual pixel diffs.

### Facet Panel Filtering
**Source:** `inst/htmlwidgets/gg2d3.js`
**Apply to:** browser smoke and IR fixture matrix
```javascript
const filteredData = isFaceted
  ? indexedLayerData.filter(function(d) { return d.PANEL === panelNum; })
  : indexedLayerData;  // non-faceted: use all data
filteredLayer = Object.assign({}, layer, { data: filteredData });
```

Faceted rect/tile tests should assert panel-local row counts or per-panel DOM counts, not only global counts.

### Optional Browser Skips
**Source:** `tests/testthat/helper-browser-polygon.R`
**Apply to:** `tests/testthat/test-rect-tile-browser.R`, optional helper
```r
testthat::skip_on_cran()
testthat::skip_if_not_installed("chromote", "0.5.1")
```

Browser smoke must remain optional and CRAN-compatible. Forced local browser runs may pass or skip; either result should be explicit in verification notes.

### Source Contract Tests
**Source:** `tests/testthat/test-polygon-renderer.R`
**Apply to:** `tests/testthat/test-rect-tile-renderer.R`
```r
expect_match(polygon_js, "function renderPolygon")
expect_match(polygon_js, "geomRegistry\\.register\\(['\"]polygon['\"]")
expect_match(polygon_js, "path\\.geom-polygon|geom-polygon")
```

Use source contracts to lock renderer registration, selectors, band-scale handling, null filtering, and update path parity without adding screenshot infrastructure.

## No Analog Found

All expected Phase 45 files have close in-repo analogs. The optional browser helper can either reuse `helper-browser-polygon.R` directly or copy its structure with rect/tile-specific names.

## Metadata

**Analog search scope:** `R/`, `inst/htmlwidgets/modules/`, `inst/htmlwidgets/modules/geoms/`, `tests/testthat/`, `vignettes/`, `.planning/phases/44-ordinary-geom-polygon-support/`
**Files scanned:** 8 direct analog files plus phase context, research, validation, and project guidance
**Pattern extraction date:** 2026-05-24
