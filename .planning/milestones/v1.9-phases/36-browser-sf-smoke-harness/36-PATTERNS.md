# Phase 36: Browser sf Smoke Harness - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 5 planned source/config files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `DESCRIPTION` | config | dependency metadata | `DESCRIPTION` | exact |
| `tests/testthat/helper-browser-sf.R` | utility / test helper | request-response, event-driven, file-I/O | `tests/testthat/test-sf-visual.R` + `tests/testthat/test-sf-interactivity.R` | partial |
| `tests/testthat/helper-sf-fixtures.R` | utility / fixture helper | transform, file-I/O | `tests/testthat/test-sf-visual.R` | exact extraction |
| `tests/testthat/test-sf-browser.R` | test | request-response, event-driven, file-I/O | `tests/testthat/test-sf-visual.R` + `tests/testthat/test-sf-interactivity.R` + `tests/testthat/test-sf-ir.R` | role-match |
| `tests/testthat/test-sf-visual.R` | test / fixture owner | transform, file-I/O | existing same file | exact if modified |

Generated runtime artifacts under `test_output/browser-sf/` are not source files and should remain ignored local output, following the existing `test_output/` convention.

## Pattern Assignments

### `DESCRIPTION` (config, dependency metadata)

**Analog:** `DESCRIPTION`

**Suggests pattern** (lines 20-25):
```r
Suggests:
    testthat (>= 3.0.0),
    crosstalk,
    sf (>= 1.0.0),
    geojsonsf (>= 2.0.0),
    rnaturalearth
```

**Apply:** Add `chromote (>= 0.5.1)` under `Suggests`, keeping it optional. Do not add browser tooling to `Imports`.

---

### `tests/testthat/helper-browser-sf.R` (utility / test helper, request-response + event-driven + file-I/O)

**Analog:** `tests/testthat/test-sf-visual.R` for package loading, artifact directory, and non-self-contained widget saves.

**Package-load pattern** (lines 11-12):
```r
# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)
```

**Artifact directory pattern** (lines 14-22):
```r
.test_output_dir <- function() {
  # Write to project root test_output/ (CLAUDE.md: "Always save visual test HTML
  # files to test_output/ in the project root, not /tmp/")
  pkg_root <- tryCatch(
    rprojroot::find_package_root_file(),
    error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
  )
  file.path(pkg_root, "test_output")
}
```

**Non-self-contained save pattern** (lines 38-49):
```r
.phase35_save_widget <- function(widget, filename) {
  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  outpath <- file.path(out_dir, filename)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(outpath, mustWork = FALSE),
    selfcontained = FALSE
  )
  expect_true(file.exists(outpath))
  outpath
}
```

**Analog:** `tests/testthat/test-sf-interactivity.R` for repository file resolution style if browser helpers need JS snippets or diagnostics.

**Read helper pattern** (lines 1-8):
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

**Chromote gap:** No existing codebase analog drives a live browser, subscribes to CDP events, polls DOM state, or captures console/page errors. Implement this part from `36-RESEARCH.md` patterns, but keep the surrounding R/testthat helper style above.

**Helper responsibilities to centralize:**
- `skip_browser_sf_smoke()` with `skip_on_cran()`, `skip_if_not_installed("chromote", "0.5.1")`, `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and Chrome/session-launch skip guards.
- `browser_sf_artifact_dir()` rooted at `.test_output_dir()/browser-sf`.
- `save_browser_sf_widget(widget, filename)` using `htmlwidgets::saveWidget(..., selfcontained = FALSE)`.
- `with_chromote_session()` or equivalent session lifecycle wrapper with `on.exit()` cleanup.
- `browser_console_collector()` or equivalent, enabled before navigation.
- `wait_for_sf_paths(session, expected, timeout)` polling `document.querySelectorAll("path.geom-sf")`.
- `eval_js_value(session, script)` wrapping `Runtime.evaluate(..., returnByValue = TRUE)`.
- failure artifact writer for HTML path, console/page logs, and optional screenshot.

---

### `tests/testthat/helper-sf-fixtures.R` (utility / fixture helper, transform + file-I/O)

**Analog:** `tests/testthat/test-sf-visual.R`

This helper is optional, but if created it should extract the Phase 35 fixture builders instead of cloning them. Testthat automatically sources `helper-*.R` files before tests, so `test-sf-visual.R` and `test-sf-browser.R` can share these functions.

**Geometry helper pattern** (lines 24-35):
```r
.phase35_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
  matrix(
    c(
      xmin, ymin,
      xmax, ymin,
      xmax, ymax,
      xmin, ymax,
      xmin, ymin
    ),
    ncol = 2,
    byrow = TRUE
  )
}
```

**Fixture data constructors** (lines 52-74):
```r
.phase35_make_two_panel_sf <- function() {
  sf::st_sf(
    facet = factor(c("A", "B"), levels = c("A", "B")),
    row = factor(c("north", "south"), levels = c("north", "south")),
    col = factor(c("west", "east"), levels = c("west", "east")),
    value = c(10, 20),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(.phase35_square_ring(100, 10, 101, 11))),
      crs = 4326
    )
  )
}

.phase35_make_adjacent_sf <- function() {
  sf::st_sf(
    value = c(10, 20),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(.phase35_square_ring(1.4, 0, 2.4, 1))),
      crs = 4326
    )
  )
}
```

**Skipped-row fixture pattern** (lines 77-99):
```r
.phase35_make_mixed_sf <- function() {
  sf::st_sf(
    label = c("polygon", "point", "empty", "invalid", "multipolygon"),
    value = c(1, 2, 3, 4, 5),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring())),
      sf::st_point(c(10, 10)),
      sf::st_polygon(),
      sf::st_polygon(list(matrix(
        c(
          20, 0,
          21, 1,
          21, 0,
          20, 1,
          20, 0
        ),
        ncol = 2,
        byrow = TRUE
      ))),
      sf::st_multipolygon(list(list(.phase35_square_ring(1.4, 0, 2.4, 1)))),
      crs = 4326
    )
  )
}
```

**IR sanity helper pattern** (lines 102-110):
```r
.phase35_expect_sf_layer <- function(ir, layer_index = 1L) {
  layer <- ir$layers[[layer_index]]
  expect_equal(layer$geom, "sf")
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_true("row_id" %in% names(layer$data[[1]]))
  expect_false(is.null(layer$sf_diagnostics))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
  layer
}
```

**Fixture matrix pattern** (lines 113-212):
```r
.phase35_sf_fixture_set <- function() {
  fixtures <- list()

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  choropleth <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) +
    ggplot2::geom_sf()
  fixtures[["phase35-sf-choropleth.html"]] <- .phase35_save_widget(
    gg2d3(choropleth),
    "phase35-sf-choropleth.html"
  )
  .phase35_expect_sf_layer(as_d3_ir(choropleth))

  # ... same helper continues with stacked overlay, facet wrap, facet grid,
  # skipped-row filtering, and interactivity smoke widgets.
  fixtures
}
```

**Apply:** Preserve the existing function names or add compatibility wrappers so existing `test-sf-visual.R` keeps passing. If names are changed for Phase 36, update `test-sf-visual.R` and `test-sf-browser.R` together.

---

### `tests/testthat/test-sf-browser.R` (test, request-response + event-driven + file-I/O)

**Analog:** `tests/testthat/test-sf-visual.R` for fixture coverage and optional dependency skips.

**Skip pattern** (lines 215-217 and 268-270):
```r
test_that("REND-01: NC counties render as filled choropleth via gg2d3 pipeline", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
```

```r
test_that("Phase 35 fixture set is generated for manual sf validation", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
```

**Full fixture coverage assertion** (lines 272-284):
```r
fixtures <- .phase35_sf_fixture_set()

expect_equal(
  sort(names(fixtures)),
  sort(c(
    "phase35-sf-choropleth.html",
    "phase35-sf-stacked-overlay.html",
    "phase35-sf-facet-wrap.html",
    "phase35-sf-facet-grid.html",
    "phase35-sf-skipped-rows.html",
    "phase35-sf-interactivity-smoke.html"
  ))
)
```

**Analog:** `inst/htmlwidgets/modules/geoms/sf.js` for live DOM contract the browser test must assert.

**Rendered path contract** (lines 119-140):
```javascript
sfGroup.selectAll("path.geom-sf")
  .data(rows)
  .enter().append("path")
    .attr("class", "geom-sf")
    .attr("d", function(d) {
      if (!d._geom) return "";
      return pathGen({ type: "Feature", geometry: d._geom, properties: {} }) || "";
    })
    .attr("fill", function(d) { return fillColor(d); })
    .attr("stroke", function(d) { return strokeColor(d); })
    .attr("stroke-width", strokeWidth)
    .attr("opacity", function(d) { return opacityFn(d); })
    .attr("fill-rule", "evenodd")
    .attr("data-cx", function(d) {
      return isFiniteNumber(d._centroid[0]) ? d._centroid[0] : null;
    })
    .attr("data-cy", function(d) {
      return isFiniteNumber(d._centroid[1]) ? d._centroid[1] : null;
    })
    .attr("data-row-id", function(d) {
      return d.row_id != null ? d.row_id : null;
    });
```

**Browser DOM assertions should check:**
- `document.querySelectorAll("path.geom-sf").length` equals expected path counts.
- every path has non-empty `d`.
- every path has a stable non-empty `data-row-id`.
- every path has finite numeric `data-cx` and `data-cy`.
- facet smoke checks query each `.panel` separately, not only global path counts.

**Analog:** `tests/testthat/test-sf-ir.R` for skipped-row expected values.

**Skipped-row source row pattern** (lines 180-197):
```r
expect_warning(
  ir <- as_d3_ir(ggplot2::ggplot(mixed) + ggplot2::geom_sf()),
  regexp = "skipped 3"
)

layer <- ir$layers[[1]]
row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))
skipped_rows <- layer$sf_diagnostics$skipped_rows

expect_equal(length(layer$data), length(layer$geometries))
expect_equal(row_ids, layer$sf_diagnostics$accepted_rows)
expect_equal(row_ids, c(1, 5))
expect_equal(skipped_rows, c(2L, 3L, 4L))
expect_false(any(skipped_rows %in% row_ids))
expect_equal(length(layer$geometries), length(layer$sf_diagnostics$accepted_rows))
expect_equal(layer$sf_diagnostics$accepted_geometry_types, c("MULTIPOLYGON", "POLYGON"))
expect_true("POINT" %in% layer$sf_diagnostics$unsupported_geometry_types)
expect_no_warning(validate_ir(ir))
```

**Apply:** Browser test for skipped rows should assert DOM row ids are `1` and `5`, not `2`, `3`, or `4`.

**Analog:** `tests/testthat/test-sf-interactivity.R` for source-level behavior that Phase 36 should lift into live-browser assertions.

**Existing event sanitizer assertions** (lines 31-41):
```r
test_that("events module sanitizes sf custom handler data", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "startsWith\\('_'\\)")
  expect_match(events_js, "publicDatum")
  expect_match(events_js, "key\\.startsWith\\('_'\\)")
  expect_match(events_js, "setInputValue\\(shinyId, publicDatum\\)")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
  expect_match(events_js, "mouseoverHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)")
  expect_match(events_js, "mouseoutHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)")
})
```

**Existing tooltip sanitizer assertions** (lines 44-55):
```r
test_that("tooltip module sanitizes sf renderer internals", {
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(tooltip_js, "sanitizeTooltipDatum")
  expect_match(tooltip_js, "startsWith\\('_'\\)")
  expect_match(tooltip_js, "key\\.startsWith\\('_'\\)")
  expect_match(tooltip_js, "d = sanitizeTooltipDatum\\(d\\)")
  expect_match(tooltip_js, "customFn\\(enriched\\)")
  expect_match(tooltip_js, "config\\.fields\\.filter\\(k => !String\\(k\\)\\.startsWith\\('_'\\)\\)")
  private_fields <- c("_geom", "_centroid")
  expect_true(all(startsWith(private_fields, "_")))
})
```

**Existing brush sanitizer assertions** (lines 91-101):
```r
test_that("brush module sanitizes sf callback data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "key\\.startsWith\\('_'\\)")
  expect_match(brush_js, "collectSelectedData")
  expect_match(brush_js, "sanitizeSelectedDatum\\(d\\)")
  expect_match(brush_js, "selectedData\\.push\\(sanitizeSelectedDatum\\(d\\)\\)")
  private_fields <- c("_geom", "_centroid")
  expect_true(all(startsWith(private_fields, "_")))
})
```

**Apply:** Replace source-only confidence with runtime checks where feasible:
- click a `path.geom-sf` in the interactivity fixture and inspect `window.__gg2d3_sf_click`.
- verify the captured payload excludes `_geom` and `_centroid`.
- trigger tooltip display or call in-page tooltip formatting against bound sf datum and assert private fields are absent.
- attempt brush gesture over sf centroid anchors; if unreliable, document D-09 fallback and still assert centroid attributes plus sanitized callback path.

**Analog:** `tests/testthat/test-zoom-brush.R` for sf zoom suppression assertions.

**Zoom suppression pattern** (lines 111-134):
```r
test_that("d3_zoom() suppresses sf zoom without dropping brush tooltip or hover", {
  skip_if_not_installed("sf")
  library(ggplot2)

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot(nc) + geom_sf()
  sf_zoom_warning <- "geom_sf.*zoom|zoom.*geom_sf"

  w <- gg2d3(p) |>
    d3_brush() |>
    d3_tooltip() |>
    d3_hover()

  expect_warning(
    w <- w |> d3_zoom(),
    sf_zoom_warning
  )

  expect_s3_class(w, "gg2d3")
  expect_s3_class(w, "htmlwidget")
  expect_true(w$x$interactivity$brush$enabled)
  expect_true(w$x$interactivity$tooltip$enabled)
  expect_true(w$x$interactivity$hover$enabled)
  expect_null(w$x$interactivity$zoom)
})
```

**Apply:** Browser smoke should verify the interactivity fixture still renders `path.geom-sf` and attaches brush/tooltip/handler behavior after `d3_zoom()` is suppressed.

---

### `tests/testthat/test-sf-visual.R` (test / fixture owner, transform + file-I/O)

**Analog:** existing same file.

If `helper-sf-fixtures.R` is created, modify this file only to remove duplicated local helper definitions or delegate to shared helpers. Preserve the existing public behavior:

**Manual fixture generation test** (lines 268-285):
```r
test_that("Phase 35 fixture set is generated for manual sf validation", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  fixtures <- .phase35_sf_fixture_set()

  expect_equal(
    sort(names(fixtures)),
    sort(c(
      "phase35-sf-choropleth.html",
      "phase35-sf-stacked-overlay.html",
      "phase35-sf-facet-wrap.html",
      "phase35-sf-facet-grid.html",
      "phase35-sf-skipped-rows.html",
      "phase35-sf-interactivity-smoke.html"
    ))
  )
})
```

**Rule:** Do not weaken existing Phase 35 manual fixture coverage while adding the browser harness.

## Shared Patterns

### Optional Dependency And CRAN Skips

**Source:** `tests/testthat/test-sf-visual.R` lines 215-217, 268-270; `tests/testthat/test-sf-ir.R` lines 1-2.

```r
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")
```

**Apply to:** every browser smoke `test_that()` or central browser skip helper. Add `skip_on_cran()` and `skip_if_not_installed("chromote", "0.5.1")` for Phase 36.

### Package Loading For Direct `test_file()`

**Source:** `tests/testthat/test-sf-visual.R` lines 11-12; `tests/testthat/test-sf-ir.R` lines 4-5; `tests/testthat/test-sf-renderer.R` lines 4-5.

```r
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)
```

**Apply to:** new browser test/helper files that may be run directly with `testthat::test_file()`.

### Test Output Location

**Source:** `tests/testthat/test-sf-visual.R` lines 14-22 and 38-49.

```r
pkg_root <- tryCatch(
  rprojroot::find_package_root_file(),
  error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
)
file.path(pkg_root, "test_output")
```

**Apply to:** HTML, console/page logs, and optional screenshots. Prefer a `browser-sf` subdirectory under this root.

### sf DOM Contract

**Source:** `inst/htmlwidgets/modules/geoms/sf.js` lines 119-140.

```javascript
.attr("class", "geom-sf")
.attr("d", function(d) {
  if (!d._geom) return "";
  return pathGen({ type: "Feature", geometry: d._geom, properties: {} }) || "";
})
.attr("data-cx", function(d) {
  return isFiniteNumber(d._centroid[0]) ? d._centroid[0] : null;
})
.attr("data-cy", function(d) {
  return isFiniteNumber(d._centroid[1]) ? d._centroid[1] : null;
})
.attr("data-row-id", function(d) {
  return d.row_id != null ? d.row_id : null;
});
```

**Apply to:** all live DOM assertions in `test-sf-browser.R`.

### Brush Centroid Selection

**Source:** `inst/htmlwidgets/modules/brush.js` lines 310-315.

```javascript
if (tagName === 'path') {
  if (node.classList && node.classList.contains('geom-sf')) {
    var sfCx = parseFloat(node.getAttribute('data-cx'));
    var sfCy = parseFloat(node.getAttribute('data-cy'));
    return isPointInPixelRect(sfCx, sfCy, rect);
  }
```

**Apply to:** brush smoke. Select around `data-cx`/`data-cy`; do not assert polygon intersection behavior.

### Brush Callback Sanitization

**Source:** `inst/htmlwidgets/modules/brush.js` lines 397-429.

```javascript
function sanitizeSelectedDatum(d) {
  if (!d || typeof d !== 'object' || Array.isArray(d)) return d;

  var sanitized = {};
  Object.keys(d).forEach(function(key) {
    if (key.startsWith('_')) return;
    sanitized[key] = d[key];
  });
  return sanitized;
}

function collectSelectedData(panelGroup, pixelRect) {
  var clippedGroup = panelGroup.select('g[clip-path]');
  if (clippedGroup.empty()) return [];

  var selectedData = [];

  INTERACTIVE_SELECTORS.forEach(function(selector) {
    clippedGroup.selectAll(selector).each(function(d) {
      if (!d) return;
      if (isElementInPixelRect(this, pixelRect)) {
        selectedData.push(sanitizeSelectedDatum(d));
      }
    });
  });

  return selectedData;
}
```

**Apply to:** `on_brush` browser callback assertions; expected payload excludes `_geom` and `_centroid`.

### Event Handler Sanitization

**Source:** `inst/htmlwidgets/modules/events.js` lines 56-65 and 679-686.

```javascript
function sanitizeEventDatum(d) {
  if (!d || typeof d !== 'object' || Array.isArray(d)) return d;

  const sanitized = {};
  Object.keys(d).forEach(function(key) {
    if (key.startsWith('_')) return;
    sanitized[key] = d[key];
  });
  return sanitized;
}
```

```javascript
selection.on('click.custom', function(event, d) {
  const publicDatum = sanitizeEventDatum(d);
  if (clickHandler) clickHandler.call(this, event, publicDatum);
  if (shinyId && window.Shiny) {
    window.Shiny.setInputValue(shinyId, publicDatum);
  }
});
```

**Apply to:** click/custom handler browser smoke, especially `window.__gg2d3_sf_click`.

### Tooltip Sanitization

**Source:** `inst/htmlwidgets/modules/tooltip.js` lines 117-126 and 139-157.

```javascript
function sanitizeTooltipDatum(d) {
  if (!d || typeof d !== 'object' || Array.isArray(d)) return d || {};

  const sanitized = {};
  Object.keys(d).forEach(function(key) {
    if (key.startsWith('_')) return;
    sanitized[key] = d[key];
  });
  return sanitized;
}
```

```javascript
function format(d, config, ir) {
  if (Array.isArray(d)) {
    d = d.length > 0 ? d[0] : {};
  }
  if (d && typeof d === 'object' && d.d && typeof d.d === 'object' && !Array.isArray(d.d)) {
    d = d.d;
  }
  d = sanitizeTooltipDatum(d);
```

**Apply to:** tooltip browser smoke. Assert rendered tooltip/custom formatter output does not expose `_geom` or `_centroid`.

### Zoom Suppression

**Source:** `R/d3_zoom.R` lines 65-72.

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

**Apply to:** sf zoom suppression browser fixture. The browser test should confirm interactivity still works on the returned widget and `zoom` config is absent.

## No Analog Found

| File / Subpattern | Role | Data Flow | Reason |
|-------------------|------|-----------|--------|
| `helper-browser-sf.R` chromote session/navigation helpers | utility | request-response | No existing `chromote` or browser-driving code exists in the repo. Use `36-RESEARCH.md` `ChromoteSession$new()`, `go_to()`, and `Runtime.evaluate()` guidance. |
| `helper-browser-sf.R` console/page error capture | utility | event-driven | Existing tests inspect source strings or IR only; none subscribe to browser runtime events. Implement as new centralized helper and preserve logs as artifacts. |
| `test-sf-browser.R` live brush gesture automation | test | event-driven | Existing brush tests are source-level. If direct gesture automation is flaky, follow D-09: document the gap and assert strongest feasible DOM/callback behavior. |

## Metadata

**Analog search scope:** `DESCRIPTION`, `R/`, `tests/testthat/`, `inst/htmlwidgets/modules/`

**Files scanned:** 53 files from `tests/testthat`, `R`, and `inst/htmlwidgets/modules`, plus phase artifacts and project guidance.

**Pattern extraction date:** 2026-05-20

**Project guidance applied:** `AGENTS.md`, `CLAUDE.md`, and `/Users/davidzenz/.codex/RTK.md` were read. No project-local `.claude/skills/` or `.agents/skills/` directories were found.
