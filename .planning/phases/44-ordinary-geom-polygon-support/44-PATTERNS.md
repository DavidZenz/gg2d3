# Phase 44: Ordinary geom_polygon Support - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/as_d3_ir.R` | model/transform | transform | `R/as_d3_ir.R` existing geom extraction block | exact |
| `R/validate_ir.R` | utility | validation | `R/validate_ir.R` known geom list | exact |
| `inst/htmlwidgets/gg2d3.yaml` | config | dependency loading | existing module script list | exact |
| `inst/htmlwidgets/modules/geoms/polygon.js` | renderer/component | grouped SVG path render | `inst/htmlwidgets/modules/geoms/area.js`, `inst/htmlwidgets/modules/geoms/line.js` | exact |
| `inst/htmlwidgets/modules/geom-registry.js` | registry/service | render dispatch + zoom update | `inst/htmlwidgets/modules/geom-registry.js` path update block | exact |
| `inst/htmlwidgets/modules/events.js` | service | event-driven | `inst/htmlwidgets/modules/events.js` selector + sanitizer patterns | exact |
| `inst/htmlwidgets/modules/brush.js` | service | event-driven selection | `inst/htmlwidgets/modules/brush.js` selector + path bbox + sanitizer patterns | exact |
| `inst/htmlwidgets/modules/crosstalk.js` | service | pub-sub / linked selection | `inst/htmlwidgets/modules/crosstalk.js` selector + key binding patterns | role-match |
| `tests/testthat/test-polygon-ir.R` | test | transform validation | `tests/testthat/test-ir.R`, `tests/testthat/test-sf-renderer.R` | role-match |
| `tests/testthat/test-polygon-renderer.R` | test | source contract validation | `tests/testthat/test-sf-renderer.R` | exact |
| `tests/testthat/test-polygon-interactivity.R` | test | source contract validation | `tests/testthat/test-sf-interactivity.R` | exact |
| `tests/testthat/helper-browser-polygon.R` | test helper | browser file I/O | `tests/testthat/helper-browser-sf.R` | exact |
| `tests/testthat/test-polygon-browser.R` | test | optional browser DOM smoke | `tests/testthat/test-sf-browser.R` | exact |
| `tests/testthat/test-zoom-path-datum.R` | test | source contract validation | existing `path_geoms` matrix | exact |

## Pattern Assignments

### `R/as_d3_ir.R` (model/transform, transform)

**Analog:** `R/as_d3_ir.R`

**Geom recognition pattern** (lines 195-225):
```r
gobj  <- b$plot$layers[[i]]$geom
gcl   <- class(gobj)[1]
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
                GeomSegment= "segment",
                GeomRibbon = "ribbon",
                GeomViolin = "violin",
                GeomBoxplot= "boxplot",
                GeomDensity= "density",
                GeomSmooth = "smooth",
                GeomPolygon= "polygon",
                GeomSf     = "sf",
```

**Aesthetic preservation pattern** (lines 238-252):
```r
keep_aes <- c(
  "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
  "colour","fill","size","alpha","group","label",
  "stroke","shape","linewidth","linetype","lineend",
  "slope","intercept","xintercept","yintercept",
  "lower","middle","upper","outliers","notchupper","notchlower",
  "width","violinwidth","density","scaled","count","ncount","ndensity",
  "weight",
  "stackpos","binwidth","countidx",
  "row_id",".sf_family"
)
```

**Rowization pattern** (lines 254-276):
```r
to_rows <- function(df) {
  if (is.null(df) || !nrow(df)) return(list())
  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") as.integer(col)
    else if (is.factor(col)) as.character(col)
    else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000
    else if (inherits(col, "Date")) as.numeric(col) * 86400000
    else if (is.list(col)) I(col)
    else col
  })
  names(df) <- col_names
  rows <- vector("list", nrow(df))
  for (ii in seq_len(nrow(df))) {
    r <- lapply(df[ii, , drop = FALSE], function(v) v[[1]])
    names(r) <- names(df)
    rows[[ii]] <- r
  }
  rows
}
```

Planner guidance: treat this as a source contract to characterize first. The current block already maps `GeomPolygon` and preserves the required columns; only change it if `test-polygon-ir.R` exposes a real gap.

---

### `R/validate_ir.R` (utility, validation)

**Analog:** `R/validate_ir.R`

**Known geom validation pattern** (lines 11-20):
```r
validate_ir <- function(ir) {
  # List of recognized geom types
  known_geoms <- c(
    "point", "line", "path", "bar", "col", "area",
    "text", "rect", "segment", "ribbon", "violin", "boxplot",
    "density", "smooth",
    "hline", "vline", "abline", "dotplot", "rug",
    "errorbar", "linerange", "pointrange", "polygon",
    "sf"
  )
```

Planner guidance: polygon is already recognized. Add tests only if needed; do not refactor this list for Phase 44.

---

### `inst/htmlwidgets/gg2d3.yaml` (config, dependency loading)

**Analog:** `inst/htmlwidgets/gg2d3.yaml`

**Module loading pattern** (lines 12-43):
```yaml
- name: gg2d3-modules
  version: "0.0.1"
  src: htmlwidgets/modules
  script:
    - constants.js
    - scales.js
    - theme.js
    - layout.js
    - legend.js
    - tooltip.js
    - events.js
    - zoom.js
    - brush.js
    - crosstalk.js
    - geom-registry.js
    - geoms/point.js
    - geoms/line.js
    - geoms/bar.js
    - geoms/rect.js
    - geoms/text.js
    - geoms/area.js
    - geoms/ribbon.js
    - geoms/segment.js
    - geoms/reference.js
    - geoms/dotplot.js
    - geoms/rug.js
    - geoms/interval.js
    - geoms/boxplot.js
    - geoms/violin.js
    - geoms/density.js
    - geoms/smooth.js
    - geoms/sf.js
```

Planner guidance: add `geoms/polygon.js` to this ordered list after related path geoms, before `geoms/sf.js`.

---

### `inst/htmlwidgets/modules/geoms/polygon.js` (renderer/component, grouped SVG path render)

**Analogs:** `inst/htmlwidgets/modules/geoms/area.js`, `inst/htmlwidgets/modules/geoms/line.js`

**Renderer module wrapper and utility imports** (`area.js` lines 15-37, `line.js` lines 33-40):
```javascript
(function() {
  'use strict';

  function renderArea(layer, g, xScale, yScale, options) {
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { fillColor, strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
```

```javascript
function renderLine(layer, g, xScale, yScale, options) {
  const val = window.gg2d3.helpers.val;
  const num = window.gg2d3.helpers.num;
  const asRows = window.gg2d3.helpers.asRows;
  const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
  const { strokeColor, opacity } =
    window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
```

**Grouping and row-order pattern** (`line.js` lines 52-109):
```javascript
const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);

grouped.forEach(arr => {
  let pts = arr
    .map(d => {
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      return { x: xVal, y: yVal, d };
    });

  const isDefined = p => {
    const xOk = isXBand ? (p.x != null && p.x !== "") : Number.isFinite(p.x);
    const yOk = isYBand ? (p.y != null && p.y !== "") : Number.isFinite(p.y);
    return xOk && yOk;
  };

  if (layer.geom === "line" && !isXBand && pts.every(isDefined)) {
    pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
  }
```

Planner guidance: copy the grouping and scale conversion, but do not copy the `geom_line` sort branch. Ordinary polygon must preserve built row order.

**Path append/style/register pattern** (`line.js` lines 111-152, `area.js` lines 107-125):
```javascript
if (pts.filter(isDefined).length >= 2) {
  const xOff = isXBand ? xScale.bandwidth() / 2 : 0;
  const yOff = isYBand ? yScale.bandwidth() / 2 : 0;
  const line = flip
    ? d3.line().defined(isDefined).x(p => yScale(p.y) + yOff).y(p => xScale(p.x) + xOff)
    : d3.line().defined(isDefined).x(p => xScale(p.x) + xOff).y(p => yScale(p.y) + yOff);
  const firstPoint = pts[0].d;
  const linewidthVal = val(get(firstPoint, "linewidth"));
  const strokeWidth = linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.42;

  g.append("path")
    .datum(pts)
    .attr("class", "geom-line")
    .attr("d", line(pts))
    .attr("fill", "none")
    .attr("stroke", strokeColor(firstPoint))
    .attr("stroke-width", strokeWidth)
    .attr("opacity", opacity(firstPoint))
```

```javascript
const firstPoint = pts[0].d;

g.append("path")
  .datum(pts)
  .attr("class", "geom-area")
  .attr("d", area(pts))
  .attr("fill", fillColor(firstPoint))
  .attr("stroke", "none")
  .attr("opacity", opacity(firstPoint));

window.gg2d3.geomRegistry.register(['area'], renderArea);
```

Planner guidance: new renderer should register `polygon`, emit `path.geom-polygon`, use a closed path generator, apply `fill`, `colour`/stroke, `alpha`, `linewidth`, and `linetype`, and bind a deterministic representative public row. Store any point array under an underscore field if zoom/update needs it.

---

### `inst/htmlwidgets/modules/geom-registry.js` (registry/service, render dispatch + zoom update)

**Analog:** `inst/htmlwidgets/modules/geom-registry.js`

**Registration and dispatch pattern** (lines 64-108):
```javascript
function registerGeom(names, renderer) {
  const nameArray = Array.isArray(names) ? names : [names];
  nameArray.forEach(name => {
    renderers[name] = renderer;
  });
}

function renderGeom(layer, g, xScale, yScale, options) {
  const renderer = renderers[layer.geom];
  if (!renderer) {
    console.warn(`gg2d3: Unknown geom type "${layer.geom}" - no renderer registered`);
    return 0;
  }
  return renderer(layer, g, xScale, yScale, options);
}
```

**Color accessor pattern** (lines 127-190):
```javascript
function makeColorAccessors(layer, options) {
  const aes = layer.aes || {};
  const params = layer.params || {};
  const colorScale = options.colorScale || (() => null);
  const val = window.gg2d3.helpers.val;
  const isValidColor = window.gg2d3.helpers.isValidColor;
  const convertColor = window.gg2d3.scales.convertColor;
  const get = (d, k) => (k && d != null) ? d[k] : null;

  const strokeColor = d => {
    if (aes.color) {
      const v = val(get(d, aes.color));
      if (isValidColor(v)) return convertColor(v);
      const converted = convertColor(v);
      if (converted !== v) return converted;
      const mapped = colorScale(v);
      return mapped || convertColor(params.colour) || "currentColor";
    }
    return convertColor(params.colour) || "currentColor";
  };
```

**Zoom path update pattern** (lines 275-282):
```javascript
// Path geoms (line, path, smooth, density-outline)
const line = d3.line()
  .x(pt => xScaleFunc(pt.x))
  .y(pt => yScaleFunc(pt.y));

container.selectAll('path.geom-line, path.geom-path, path.geom-smooth, path.geom-density-outline')
  .transition(t)
  .attr('d', d => line(d));
```

Planner guidance: if polygon binds `{ _polygonPoints: pts, ...publicRow }`, the update selector must recompute from `d._polygonPoints` using a closed line generator. Do not break existing array-bound path geoms.

---

### `inst/htmlwidgets/modules/events.js` (service, event-driven)

**Analog:** `inst/htmlwidgets/modules/events.js`

**Selector pattern** (lines 23-44):
```javascript
const INTERACTIVE_SELECTORS = [
  'circle.geom-point',
  'rect.geom-bar',
  'rect.geom-rect',
  'path.geom-line',
  'path.geom-area',
  'path.geom-density',
  'path.geom-smooth',
  'path.geom-ribbon',
  'path.geom-violin',
  '.geom-sf',
  'text.geom-text',
  'line.geom-segment',
  'rect.geom-boxplot-box',
  'circle.geom-boxplot-outlier',
  'circle.geom-dotplot',
  'line.geom-rug',
  'line.interval-line',
  'line.errorbar-cap-top',
  'line.errorbar-cap-bottom',
  'circle.pointrange-point'
];
```

**Public payload sanitizer** (lines 56-65):
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

**Tooltip/hover/handler attachment pattern** (lines 546-700):
```javascript
function attachTooltips(el, config, ir) {
  const svg = d3.select(el).select('svg');

  INTERACTIVE_SELECTORS.forEach(selector => {
    const selection = svg.selectAll(selector);
    if (selection.empty()) {
      return;
    }

    selection
      .on('mouseover.tooltip', function(event, d) {
        window.gg2d3.tooltip.show(event, d, config, ir);
      })
      .on('mousemove.tooltip', function(event) {
        window.gg2d3.tooltip.move(event);
      })
      .on('mouseout.tooltip', function() {
        window.gg2d3.tooltip.hide();
      });
  });
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

Planner guidance: add `path.geom-polygon` to `INTERACTIVE_SELECTORS`; no new API is needed.

---

### `inst/htmlwidgets/modules/brush.js` (service, event-driven selection)

**Analog:** `inst/htmlwidgets/modules/brush.js`

**Selector pattern** (lines 29-50):
```javascript
var INTERACTIVE_SELECTORS = [
  'circle.geom-point',
  'rect.geom-bar',
  'rect.geom-rect',
  'path.geom-line',
  'path.geom-area',
  'path.geom-density',
  'path.geom-smooth',
  'path.geom-ribbon',
  'path.geom-violin',
  '.geom-sf',
  'text.geom-text',
  'line.geom-segment',
  'rect.geom-boxplot-box',
  'circle.geom-boxplot-outlier',
  'circle.geom-dotplot',
  'line.geom-rug',
  'line.interval-line',
  'line.errorbar-cap-top',
  'line.errorbar-cap-bottom',
  'circle.pointrange-point'
];
```

**Path bounds brush pattern** (lines 316-327):
```javascript
if (tagName === 'path') {
  // Use bounding box center for path elements
  try {
    var bbox = node.getBBox();
    var centerX = bbox.x + bbox.width / 2;
    var centerY = bbox.y + bbox.height / 2;
    return centerX >= rect.px0 && centerX <= rect.px1 &&
           centerY >= rect.py0 && centerY <= rect.py1;
  } catch (e) {
    return false;
  }
}
```

**Selection sanitizer and collection pattern** (lines 397-440):
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

  return dedupeSelectedDataByRowId(selectedData);
}
```

Planner guidance: add `path.geom-polygon` to selectors and rely on the generic path branch. Do not add sf centroid attributes or sf-specific brush behavior for ordinary polygons.

---

### `inst/htmlwidgets/modules/crosstalk.js` (service, pub-sub / linked selection)

**Analog:** `inst/htmlwidgets/modules/crosstalk.js`

**Selector and key binding pattern** (lines 22-36, 118-130):
```javascript
const INTERACTIVE_SELECTORS = [
  'circle.geom-point',
  'rect.geom-bar',
  'rect.geom-rect',
  'path.geom-line',
  'path.geom-area',
  'path.geom-density',
  'path.geom-smooth',
  'path.geom-ribbon',
  'path.geom-violin',
  'text.geom-text',
  'line.geom-segment',
  'rect.geom-boxplot-box',
  'circle.geom-boxplot-outlier'
];
```

```javascript
function bindCrosstalkKeys(svg, keyArray) {
  svg.selectAll('.panel').each(function() {
    const panel = d3.select(this);
    const clippedGroup = panel.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    INTERACTIVE_SELECTORS.forEach(function(selector) {
      clippedGroup.selectAll(selector).each(function(d, i) {
        const key = keyArray && keyArray[i] !== undefined ? keyArray[i] : null;
        d3.select(this).attr('data-crosstalk-key', key == null ? null : String(key));
      });
    });
  });
}
```

Planner guidance: include `path.geom-polygon` if linked selection coverage is treated as part of existing interactivity. Keep the change selector-only.

---

### `tests/testthat/test-polygon-ir.R` (test, transform validation)

**Analogs:** `tests/testthat/test-ir.R`, `tests/testthat/test-sf-renderer.R`

**Simple IR fixture pattern** (`test-ir.R` lines 1-9):
```r
test_that("as_d3_ir builds layers with data", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_true(length(ir$layers) >= 1)
  expect_true(length(ir$layers[[1]]$data) >= 1)
  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$y$type, "continuous")
})
```

**Source/IR helper pattern** (`test-sf-renderer.R` lines 9-16, 32-40):
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

```r
expect_renderer_sf_layer <- function(layer, family, accepted_types) {
  expect_equal(layer$geom, "sf")
  expect_equal(layer$sf_family, family)
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_equal(layer$sf_diagnostics$accepted_geometry_types, accepted_types)
  expect_true(all(vapply(layer$data, function(row) ".sf_family" %in% names(row), logical(1))))
  expect_true(all(vapply(layer$data, function(row) "row_id" %in% names(row), logical(1))))
}
```

Planner guidance: create local polygon fixtures in this file. Assert `layer$geom == "polygon"`, built row order is preserved within each `group`, multiple groups remain distinct, facets carry `PANEL`, and core aesthetics include fill, colour, alpha, linewidth, and linetype including `NA` source values.

---

### `tests/testthat/test-polygon-renderer.R` (test, source contract validation)

**Analog:** `tests/testthat/test-sf-renderer.R`

**Renderer source contract pattern** (lines 140-180):
```r
test_that("SFGEOM-03 sf renderer source dispatches polygon point and line families", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "Point")
  expect_match(sf_js, "MultiPoint")
  expect_match(sf_js, "LineString")
  expect_match(sf_js, "MultiLineString")
  expect_match(sf_js, "Polygon")
  expect_match(sf_js, "MultiPolygon")
  expect_match(sf_js, "geom-sf-point")
  expect_match(sf_js, "geom-sf-line")
  expect_match(sf_js, "geom-sf-polygon")
})

test_that("SFGEOM-04 sf renderer continues polygon path projection contract", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "path\\.geom-sf")
  expect_match(sf_js, "d3\\.geoIdentity\\(\\)")
  expect_match(sf_js, "reflectY\\(true\\)")
  expect_match(sf_js, "fitExtent")
  expect_match(sf_js, "options\\.sfBBox")
  expect_match(sf_js, "fill-rule")
  expect_match(sf_js, "evenodd")
})
```

Planner guidance: assert `geoms/polygon.js` exists, `gg2d3.yaml` loads it, `geomRegistry.register('polygon'...)` or equivalent is present, `path.geom-polygon` is emitted, path generation is closed, no row sort is introduced, and fill/stroke/alpha/linewidth/linetype source strings are present.

---

### `tests/testthat/test-polygon-interactivity.R` (test, source contract validation)

**Analog:** `tests/testthat/test-sf-interactivity.R`

**Selector coverage and sanitizer pattern** (lines 23-47, 62-88, 101-111):
```r
test_that("events module targets all sf families without dropping existing geoms", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "\\.geom-sf")
  expect_match(events_js, "circle\\.geom-sf")
  expect_match(events_js, "geom-sf-point")
  expect_match(events_js, "geom-sf-line")
  expect_match(events_js, "geom-sf-polygon")
  expect_match(events_js, "circle\\.geom-point")
  expect_match(events_js, "path\\.geom-line")
  expect_match(events_js, "rect\\.geom-bar")
})

test_that("events module sanitizes sf custom handler data", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "startsWith\\('_'\\)")
  expect_match(events_js, "publicDatum")
  expect_match(events_js, "key\\.startsWith\\('_'\\)")
  expect_match(events_js, "setInputValue\\(shinyId, publicDatum\\)")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
})
```

```r
test_that("brush module uses sf centroid attrs before generic path bbox", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "classList\\.contains\\('geom-sf'\\)")
  expect_match(brush_js, "data-cx")
  expect_match(brush_js, "data-cy")
  expect_match(brush_js, "Number\\.isFinite")
  expect_match(brush_js, "getBBox")

  sf_branch <- regexpr("classList\\.contains\\('geom-sf'\\)", brush_js)
  bbox_branch <- regexpr("getBBox", brush_js)
  expect_true(sf_branch[[1]] > 0)
  expect_true(bbox_branch[[1]] > sf_branch[[1]])
})
```

```r
test_that("brush module sanitizes sf callback data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "key\\.startsWith\\('_'\\)")
  expect_match(brush_js, "collectSelectedData")
  expect_match(brush_js, "sanitizeSelectedDatum\\(d\\)")
  expect_match(brush_js, "selectedData\\.push\\(sanitizeSelectedDatum\\(d\\)\\)")
  private_fields <- c("_geom", "_centroid", "_sfFamily", "_pointIndex", "_pointCoord")
  expect_true(all(startsWith(private_fields, "_")))
})
```

Planner guidance: make polygon tests assert `path.geom-polygon` appears in `events.js`, `brush.js`, and optionally `crosstalk.js`; assert `getBBox` remains the ordinary path brush path; assert private polygon fields are underscore-prefixed and sanitized by tooltip/handler/brush paths.

---

### `tests/testthat/helper-browser-polygon.R` (test helper, browser file I/O)

**Analog:** `tests/testthat/helper-browser-sf.R`

**Skip and artifact helper pattern** (lines 21-64):
```r
skip_browser_sf_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote sf smoke tests"
  )

  launch <- tryCatch(
    {
      session <- chromote::ChromoteSession$new(width = 10, height = 10)
      on.exit(session$close(), add = TRUE)
      TRUE
    },
    error = function(e) e
  )
  testthat::skip_if(
    !isTRUE(launch),
    paste("chromote session launch unavailable:", conditionMessage(launch))
  )

  invisible(TRUE)
}

browser_sf_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-sf")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}
```

```r
save_browser_sf_widget <- function(widget, filename) {
  outpath <- file.path(browser_sf_artifact_dir(), filename)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(outpath, mustWork = FALSE),
    selfcontained = FALSE
  )
  testthat::expect_true(file.exists(outpath))
  outpath
}
```

Planner guidance: polygon helper should not skip on `sf` or `geojsonsf`; ordinary polygon fixtures only need chromote and existing package dependencies.

---

### `tests/testthat/test-polygon-browser.R` (test, optional browser DOM smoke)

**Analog:** `tests/testthat/test-sf-browser.R`

**Browser test setup pattern** (lines 3-15, 39-60):
```r
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_sf_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-sf.R",
    "helper-browser-sf.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}
```

```r
.browser_sf_file_url <- function(path) {
  paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
}

.browser_sf_path_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll(\"path.geom-sf\")).map(path => ({",
    'd: path.getAttribute("d"),',
    'dataRowId: path.getAttribute("data-row-id"),',
    'dataCx: path.getAttribute("data-cx"),',
    'dataCy: path.getAttribute("data-cy"),',
    'cx: Number(path.getAttribute("data-cx")),',
    'cy: Number(path.getAttribute("data-cy"))',
    "})))()"
  )
}
```

**Interaction smoke pattern** (lines 179-215, 225-244):
```r
.browser_sf_phase38_interaction_script <- function() {
  paste(
    "(() => new Promise(resolve => {",
    "window.__gg2d3_sf_click = null;",
    "window.__gg2d3_sf_mouseover = null;",
    "window.__gg2d3_sf_brush = [];",
    "window.__gg2d3_sf_shiny = null;",
    "window.Shiny = { setInputValue: function(id, value) { window.__gg2d3_sf_shiny = { id: id, value: value }; } };",
    "const mark = document.querySelector('.geom-sf');",
    "const panelGroup = mark ? mark.closest('.panel') : null;",
    "const cx = mark ? Number(mark.getAttribute('data-cx')) : NaN;",
    "const cy = mark ? Number(mark.getAttribute('data-cy')) : NaN;",
    "if (mark) {",
    "  mark.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "  mark.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "}",
    "const brush = panelGroup && panelGroup.__gg2d3_brush;",
    "if (brush && Number.isFinite(cx) && Number.isFinite(cy)) {",
    "  brush.group.call(brush.behavior.move, [[cx - 3, cy - 3], [cx + 3, cy + 3]]);",
    "}",
    "setTimeout(() => {",
    "  const tooltip = document.querySelector('.gg2d3-tooltip');",
    "  resolve({",
    "    tag: mark ? mark.tagName.toLowerCase() : '',",
    "    className: mark ? (mark.getAttribute('class') || '') : '',",
    "    click: window.__gg2d3_sf_click || null,",
    "    mouseover: window.__gg2d3_sf_mouseover || null,",
    "    shiny: window.__gg2d3_sf_shiny || null,",
    "    tooltipText: tooltip ? (tooltip.textContent || tooltip.innerHTML || '') : '',",
    "    brush: window.__gg2d3_sf_brush || []",
    "  });",
    "}, 100);",
    "}))()"
  )
}
```

```r
widget <- gg2d3(choropleth) |>
  d3_brush(on_brush = "window.__gg2d3_sf_brush = selectedData;") |>
  d3_tooltip() |>
  d3_hover() |>
  d3_handlers(click = "function(event, d) { window.__gg2d3_sf_click = d; }")
```

Planner guidance: use `path.geom-polygon`, browser path `getBBox()` center or `getBoundingClientRect()` to move the brush, and assert DOM counts, closed/non-empty path `d`, panel clipping, fill/stroke attributes including `none`, and sanitized click/brush/tooltip payloads.

---

### `tests/testthat/test-zoom-path-datum.R` (test, source contract validation)

**Analog:** existing `tests/testthat/test-zoom-path-datum.R`

**Path datum matrix pattern** (lines 10-18, 26-44):
```r
path_geoms <- list(
  list(file = "line.js",    class = "geom-line"),
  list(file = "area.js",    class = "geom-area"),
  list(file = "density.js", class = "geom-density"),
  list(file = "density.js", class = "geom-density-outline"),
  list(file = "ribbon.js",  class = "geom-ribbon"),
  list(file = "smooth.js",  class = "geom-smooth"),
  list(file = "smooth.js",  class = "geom-smooth-ribbon")
)
```

```r
for (entry in path_geoms) {
  local({
    e <- entry
    test_that(paste0("path geom '", e$class, "' binds datum for zoom updates"), {
      src <- readLines(file.path(geoms_dir, e$file), warn = FALSE)
      class_re <- paste0("\"class\",\\s*\"", e$class, "\"")
      class_idx <- grep(class_re, src)
      expect_true(length(class_idx) >= 1,
                  info = paste0("class attribute for ", e$class, " not found"))
      for (i in class_idx) {
        window <- src[max(1, i - 6):i]
        expect_true(any(grepl("\\.datum\\(", window)),
                    info = paste0(e$class, " path appended without .datum(); ",
                                  "zoom/pan will not transform this geom"))
      }
    })
  })
}
```

Planner guidance: add `list(file = "polygon.js", class = "geom-polygon")` if polygon participates in zoom/update. If the bound datum is representative-row-with-private-points rather than an array, add a polygon-specific assertion for `_polygonPoints` or the chosen private field.

## Shared Patterns

### Facet Filtering And Clipping

**Source:** `inst/htmlwidgets/gg2d3.js` lines 76-131
**Apply to:** `inst/htmlwidgets/modules/geoms/polygon.js`, `tests/testthat/test-polygon-browser.R`

```javascript
const gClipped = g.append("g").attr("clip-path", "url(#" + clipId + ")");

(ir.layers || []).forEach(function(layer) {
  const layerData = layer.data || [];
  let filteredLayer;

  if (layer.geom === "sf" && Array.isArray(layer.geometries)) {
    // sf special case omitted here
  } else {
    const filteredData = isFaceted
      ? layerData.filter(function(d) { return d.PANEL === panelNum; })
      : layerData;
    filteredLayer = Object.assign({}, layer, { data: filteredData });
  }

  const count = window.gg2d3.geomRegistry.render(
    filteredLayer,
    gClipped,
    xScale,
    yScale,
    {
      colorScale: colorScale,
      plotWidth: w,
      plotHeight: h,
      flip: flip,
      coord: ir.coord,
      scales: ir.scales,
      panelData: panelData,
      sfBBox: panelData && panelData.sf_bbox ? panelData.sf_bbox : null
    }
  );
});
```

### Public Payload Sanitization

**Source:** `inst/htmlwidgets/modules/events.js` lines 56-65; `inst/htmlwidgets/modules/tooltip.js` lines 117-156; `inst/htmlwidgets/modules/brush.js` lines 397-440
**Apply to:** `inst/htmlwidgets/modules/geoms/polygon.js`, `events.js`, `brush.js`, `test-polygon-interactivity.R`, `test-polygon-browser.R`

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

### Selector-Driven Interactivity

**Source:** `inst/htmlwidgets/modules/events.js` lines 23-44; `inst/htmlwidgets/modules/brush.js` lines 29-50; `inst/htmlwidgets/modules/crosstalk.js` lines 22-36
**Apply to:** all interactivity modules and source tests

Add exactly the same ordinary polygon selector where applicable:

```javascript
'path.geom-polygon'
```

### Source Test Module Reader

**Source:** `tests/testthat/test-sf-interactivity.R` lines 1-9
**Apply to:** `test-polygon-renderer.R`, `test-polygon-interactivity.R`

```r
read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}
```

## No Analog Found

All proposed Phase 44 files have close analogs in the current codebase. No planner fallback to research-only patterns is required.

## Metadata

**Analog search scope:** `R/`, `inst/htmlwidgets/`, `inst/htmlwidgets/modules/`, `inst/htmlwidgets/modules/geoms/`, `tests/testthat/`
**Files scanned:** 48 source/test/widget files via `rg --files`
**Strong analogs used:** 12 files
**Pattern extraction date:** 2026-05-24
