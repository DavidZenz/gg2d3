# Phase 53: Renderer And IR Contract Consolidation - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/testthat/test-renderer-wiring-contracts.R` | test | batch source validation | `tests/testthat/test-renderer-wiring-contracts.R` | exact |
| `inst/htmlwidgets/modules/geom-contracts.js` | config / utility | transform / lookup | `inst/htmlwidgets/modules/geom-contracts.js` | exact |
| `inst/htmlwidgets/modules/geom-registry.js` | service / registry | request-response render dispatch | `inst/htmlwidgets/modules/geom-registry.js` | exact |
| `inst/htmlwidgets/gg2d3.yaml` | config | batch dependency loading | `inst/htmlwidgets/gg2d3.yaml` | exact |
| `R/as_d3_ir.R` | service / orchestrator | transform | `R/as_d3_ir.R` | exact |
| `R/ir_layer_helpers.R` | utility | transform | `R/ir_layer_helpers.R` | exact |
| `R/ir_scale_helpers.R` | utility | transform | `R/ir_scale_helpers.R` | exact |
| `R/ir_facet_helpers.R` | utility | transform | `R/ir_facet_helpers.R` | exact |
| `R/ir_theme_helpers.R` (if created) | utility | transform | `R/as_d3_ir.R` nested `extract_theme_element()` + `R/ggplot2_compat.R` | role-match |
| `R/ir_geom_params_helpers.R` (or added helper in `R/ir_layer_helpers.R`) | utility | transform | `R/as_d3_ir.R` layer parameter block + `R/ir_layer_helpers.R` | role-match |
| `tests/testthat/test-ir-helper-boundaries.R` | test | batch IR characterization | `tests/testthat/test-ir-helper-boundaries.R` | exact |
| `vignettes/d3-drawing-diagnostics.md` | documentation | batch reference | `vignettes/d3-drawing-diagnostics.md` | exact |

## Pattern Assignments

### `tests/testthat/test-renderer-wiring-contracts.R` (test, batch source validation)

**Analog:** `tests/testthat/test-renderer-wiring-contracts.R`

**Source read pattern** (lines 1-9):
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

**Parser helper pattern** (lines 20-28):
```r
extract_contract_entries <- function(contract_js) {
  lines <- strsplit(contract_js, "\n", fixed = TRUE)[[1]]
  starts <- grep("^    \\{\\s*$", lines)
  starts <- starts[vapply(starts, function(i) {
    i < length(lines) && grepl("^      geom: ", lines[[i + 1]])
  }, logical(1))]
  ends <- c(starts[-1] - 1L, grep("^  \\];\\s*$", lines)[1] - 1L)
  Map(function(start, end) paste(lines[start:end], collapse = "\n"), starts, ends)
}
```

**Actionable drift message pattern** (lines 118-129):
```r
for (selector in selectors) {
  expect_true(
    grepl(selector, registry_js, fixed = TRUE),
    info = paste("Missing updateGeoms selector:", selector)
  )
}
```

**Sanitizer delegation pattern** (lines 198-210):
```r
events_js <- read_module("inst/htmlwidgets/modules/events.js")
brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

expect_match(events_js, "sanitizeEventDatum", fixed = TRUE)
expect_match(brush_js, "sanitizeSelectedDatum", fixed = TRUE)
expect_match(tooltip_js, "sanitizeTooltipDatum", fixed = TRUE)

for (js in list(events_js, brush_js, tooltip_js)) {
  expect_match(js, "publicData.sanitizeDatum", fixed = TRUE)
}
```

Planner should extend this file with small parser helpers for contract `module`, `renderSelectors`, `update.reason`, interaction exception reasons, and `publicPayload` checks. Use `info = paste(...)` in loops so failures name the alias, module path, selector, field, or sanitizer surface.

---

### `inst/htmlwidgets/modules/geom-contracts.js` (config / utility, transform / lookup)

**Analog:** `inst/htmlwidgets/modules/geom-contracts.js`

**Module contract header** (lines 1-8):
```javascript
/**
 * gg2d3 Geom Contracts Module
 *
 * Internal metadata for renderer/update/interaction wiring. This is not a
 * public extension API; it exists so source-level tests and small runtime
 * helpers can share the same supported-geom contract.
 *
 * @module gg2d3.geomContracts
 */
```

**Ordinary contract entry pattern** (lines 17-30):
```javascript
{
  geom: 'point',
  aliases: ['point'],
  module: 'geoms/point.js',
  renderSelectors: ['circle.geom-point'],
  update: { type: 'selectors', selectors: ['circle.geom-point'] },
  interactions: {
    events: ['circle.geom-point'],
    brush: ['circle.geom-point'],
    crosstalk: ['circle.geom-point']
  },
  privateFields: [],
  publicPayload: true
}
```

**Explicit exception pattern** (lines 322-342):
```javascript
{
  geom: 'sf',
  aliases: ['sf'],
  module: 'geoms/sf.js',
  renderSelectors: [
    'path.geom-sf.geom-sf-polygon',
    'path.geom-sf.geom-sf-line',
    'circle.geom-sf.geom-sf-point'
  ],
  update: {
    type: 'explicit-none',
    selectors: [],
    reason: 'geom_sf uses projection-space coordinates and currently has no updateGeoms branch.'
  },
  interactions: {
    events: ['.geom-sf'],
    brush: ['.geom-sf'],
    crosstalk: ['.geom-sf']
  },
  privateFields: ['_geom', '_centroid', '_sfFamily', '_pointCoord', '_pointIndex'],
  publicPayload: true
}
```

**Selector and private-field API pattern** (lines 422-447):
```javascript
function selectorsFor(surface) {
  const selectors = [];
  contracts.forEach(function(entry) {
    interactionSelectors(entry, surface).forEach(function(selector) {
      selectors.push(selector);
    });
  });
  return unique(selectors);
}

function privateFields() {
  const fields = [];
  contracts.forEach(function(entry) {
    (entry.privateFields || []).forEach(function(field) {
      fields.push(field);
    });
  });
  return unique(fields);
}
```

Planner should preserve this manifest as the source of truth. Add reason-bearing exceptions here instead of hard-coding special cases only in tests.

---

### `inst/htmlwidgets/modules/geom-registry.js` (service / registry, request-response render dispatch)

**Analog:** `inst/htmlwidgets/modules/geom-registry.js`

**Registration and dispatch pattern** (lines 64-107):
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

**Shared color accessors pattern** (lines 127-190):
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

**Update selector pattern** (lines 259-263 and 333-354):
```javascript
container.selectAll('circle.geom-point')
  .transition(t)
  .attr('cx', d => xScaleFunc(d.x))
  .attr('cy', d => yScaleFunc(d.y));

container.selectAll('path.geom-ribbon, path.geom-violin, path.geom-smooth-ribbon')
  .transition(t)
  .attr('d', d => areaRibbon(d));

container.selectAll('path.geom-line, path.geom-path, path.geom-smooth, path.geom-density-outline')
  .transition(t)
  .attr('d', d => line(d));

container.selectAll('path.geom-polygon')
  .transition(t)
  .attr('d', d => closedLine(d && d._polygonPoints ? d._polygonPoints : []));
```

Contract tests should verify every `update.selectors` selector is present here unless the contract uses `update.type = 'explicit-none'` with a reason.

---

### `inst/htmlwidgets/gg2d3.yaml` (config, batch dependency loading)

**Analog:** `inst/htmlwidgets/gg2d3.yaml`

**Load-order pattern** (lines 15-29):
```yaml
script:
  - constants.js
  - scales.js
  - theme.js
  - layout.js
  - legend.js
  - geom-contracts.js
  - public-data.js
  - tooltip.js
  - events.js
  - zoom.js
  - brush.js
  - crosstalk.js
  - geom-registry.js
  - geoms/point.js
```

**Geom module list pattern** (lines 29-46):
```yaml
  - geoms/point.js
  - geoms/line.js
  - geoms/polygon.js
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

Planner should add tests that compare each contract `module` to this script list, and check `geom-contracts.js` loads before interaction modules and `geom-registry.js`.

---

### `R/as_d3_ir.R` (service / orchestrator, transform)

**Analog:** `R/as_d3_ir.R`

**Top-level orchestration pattern** (lines 9-30):
```r
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)
  is_flip <- inherits(b$plot$coordinates, "CoordFlip")

  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]
```

**Layer preprocessing / dispatch seam** (lines 123-201):
```r
layers <- lapply(seq_along(b$data), function(i) {
  df <- b$data[[i]]

  if ("x" %in% names(df) && !all(is.na(df$x))) {
    df$x <- gg2d3_ir_map_discrete(df$x, xscale_obj)
  }

  layer_obj <- b$plot$layers[[i]]
  gcl <- class(layer_obj$geom)[1]
  gname <- gg2d3_ir_geom_name(layer_obj)
  keep_aes <- gg2d3_ir_layer_keep_aes()
  cols <- intersect(keep_aes, names(df))
  aes <- gg2d3_ir_layer_aes(cols)

  x_tn <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
  y_tn <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL
  df <- gg2d3_ir_apply_temporal_layer_columns(df, x_tn, y_tn)
  var_names <- gg2d3_ir_var_names(b$plot$mapping, layer_obj$mapping)

  g_params <- layer_obj$aes_params
  if (gcl == "GeomRug") {
    g_params$sides <- layer_obj$geom_params$sides
  } else if (gcl == "GeomDotplot") {
    g_params$method <- layer_obj$geom_params$method
    g_params$binaxis <- layer_obj$geom_params$binaxis
    g_params$stackdir <- layer_obj$geom_params$stackdir
  }
```

**Scale / axis metadata seam** (lines 222-240):
```r
x_trans_name <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
y_trans_name <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL
x_break_info <- gg2d3_ir_axis_breaks(pp_x, x_trans_name)
y_break_info <- gg2d3_ir_axis_breaks(pp_y, y_trans_name)

scales <- list(
  x = c(gg2d3_ir_scale_info(xscale_obj, pp_x, "x"), list(
    breaks = unname(x_breaks),
    minor_breaks = if (!is.null(x_minor_breaks)) unname(x_minor_breaks) else NULL
  )),
  y = c(gg2d3_ir_scale_info(yscale_obj, pp_y, "y"), list(
    breaks = unname(y_breaks),
    minor_breaks = if (!is.null(y_minor_breaks)) unname(y_minor_breaks) else NULL
  ))
)
```

**Final IR assembly pattern** (lines 492-500):
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

Any extraction should leave `as_d3_ir()` as the orchestrator and preserve representative IR output.

---

### `R/ir_layer_helpers.R` (utility, transform)

**Analog:** `R/ir_layer_helpers.R`

**Discrete mapping pattern** (lines 1-13):
```r
gg2d3_ir_map_discrete <- function(values, scale_obj) {
  if (scale_obj$is_discrete() && is.numeric(values)) {
    labels <- scale_obj$get_limits()
    non_na <- !is.na(values)
    if (all(values[non_na] == floor(values[non_na]))) {
      result <- rep(NA_character_, length(values))
      result[non_na] <- labels[values[non_na]]
      return(result)
    }
  }

  values
}
```

**Layer row normalization pattern** (lines 30-62):
```r
gg2d3_ir_layer_rows <- function(df, keep_aes = gg2d3_ir_layer_keep_aes()) {
  if (is.null(df) || !nrow(df)) {
    return(list())
  }

  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") {
      as.integer(col)
    } else if (is.factor(col)) {
      as.character(col)
    } else if (inherits(col, c("POSIXct", "POSIXt"))) {
      as.numeric(col) * 1000
    } else if (inherits(col, "Date")) {
      as.numeric(col) * 86400000
    } else if (is.list(col)) {
      I(col)
    } else {
      col
    }
  })
```

**Geom-name dispatch pattern** (lines 65-126):
```r
gg2d3_ir_geom_name <- function(layer) {
  gobj <- layer$geom
  gcl_raw <- class(gobj)
  gcl <- gcl_raw[1]
  gname <- switch(gcl,
    GeomPoint = "point",
    GeomLine = "line",
    GeomPath = "path",
    GeomCol = "bar",
    GeomBar = "bar",
    GeomArea = "area",
    GeomText = "text",
    GeomLabel = "text",
    GeomRect = "rect",
    GeomTile = "rect",
    GeomSegment = "segment",
    GeomRibbon = "ribbon",
    GeomViolin = "violin",
    GeomBoxplot = "boxplot",
    GeomDensity = "density",
    GeomSmooth = "smooth",
    GeomHline = "hline",
    GeomVline = "vline",
    GeomAbline = "abline",
    GeomDotplot = "dotplot",
    GeomRug = "rug",
    GeomErrorbar = "errorbar",
    GeomLinerange = "linerange",
    GeomPointrange = "pointrange",
    GeomPolygon = "polygon",
    GeomSf = "sf",
    GeomSfText = "sf_text",
    GeomSfLabel = "sf_label",
```

**Non-sf payload pattern** (lines 204-212):
```r
gg2d3_ir_non_sf_layer <- function(gname, df, aes, params, var_names) {
  list(
    geom = gname,
    data = gg2d3_ir_layer_rows(df),
    aes = aes,
    params = params,
    var_names = var_names
  )
}
```

Use this file for layer preprocessing and geom parameter routing helpers unless a new helper file clearly reduces coupling.

---

### `R/ir_scale_helpers.R` (utility, transform)

**Analog:** `R/ir_scale_helpers.R`

**Error handling / validation pattern** (lines 1-24):
```r
gg2d3_ir_validate_log_domain <- function(scale_obj, domain, axis_name) {
  trans <- scale_obj$trans
  if (is.null(trans)) {
    return(invisible(TRUE))
  }

  is_log <- grepl("log", trans$name, ignore.case = TRUE) &&
    !grepl("pseudo_log|symlog", trans$name, ignore.case = TRUE)

  if (is_log && any(domain <= 0)) {
    stop(sprintf(
      paste0(
        "Log scale on %s-axis has non-positive domain [%.4g, %.4g].\n",
        "Log scales require strictly positive values.\n",
        "Consider:\n",
        "  - scale_%s_continuous(trans = 'pseudo_log') for data including zero\n",
        "  - Filtering data to positive values\n",
        "  - Using a linear scale"
      ),
```

**Transform mapping pattern** (lines 28-58):
```r
gg2d3_ir_scale_transform <- function(scale_obj) {
  if (is.null(scale_obj$trans)) {
    return(NULL)
  }

  trans_name <- scale_obj$trans$name
  result <- list()

  if (trans_name == "identity") {
    return(NULL)
  } else if (trans_name == "log-10" || trans_name == "log10") {
    result$transform <- "log10"
    result$base <- 10
  } else if (trans_name == "log-2" || trans_name == "log2") {
    result$transform <- "log2"
    result$base <- 2
  } else if (trans_name == "log") {
    result$transform <- "log"
    result$base <- exp(1)
```

**Axis break helper pattern** (lines 144-155):
```r
gg2d3_ir_axis_breaks <- function(panel_params_axis, trans_name) {
  breaks <- panel_params_axis$breaks
  minor_breaks <- panel_params_axis$minor_breaks

  breaks <- breaks[!is.na(breaks)]
  minor_breaks <- if (!is.null(minor_breaks)) minor_breaks[!is.na(minor_breaks)] else NULL

  list(
    breaks = gg2d3_ir_convert_temporal_values(breaks, trans_name),
    minor_breaks = gg2d3_ir_convert_temporal_values(minor_breaks, trans_name)
  )
}
```

Keep scale helpers pure: pass scale/panel objects in and return plain lists/vectors.

---

### `R/ir_facet_helpers.R` (utility, transform)

**Analog:** `R/ir_facet_helpers.R`

**Panel range helper pattern** (lines 1-39):
```r
gg2d3_ir_panel_ranges <- function(pp, xscale_obj, yscale_obj, is_flip, x_trans_name, y_trans_name) {
  if (is_flip) {
    ppx <- gg2d3_panel_axis(pp, "y")
    ppy <- gg2d3_panel_axis(pp, "x")
  } else {
    ppx <- gg2d3_panel_axis(pp, "x")
    ppy <- gg2d3_panel_axis(pp, "y")
  }

  panel_x_range <- if (xscale_obj$is_discrete()) {
    unname(xscale_obj$get_limits())
  } else {
    unname(gg2d3_continuous_range(ppx))
  }
```

**Try/catch fallback pattern** (lines 220-246):
```r
gg2d3_ir_facets <- function(build, scales, xscale_obj, yscale_obj, is_flip, is_sf_coord,
                            x_trans_name, y_trans_name, theme, sf_panel_geometries) {
  result <- tryCatch({
    layout_obj <- build$layout
    if (inherits(layout_obj$facet, "FacetWrap")) {
      gg2d3_ir_facet_wrap(
        layout_obj, build, xscale_obj, yscale_obj, is_flip,
        x_trans_name, y_trans_name, theme
      )
    } else if (inherits(layout_obj$facet, "FacetGrid")) {
      gg2d3_ir_facet_grid(
        layout_obj, build, xscale_obj, yscale_obj, is_flip,
        x_trans_name, y_trans_name, theme
      )
    } else {
      gg2d3_ir_null_facets(scales, is_sf_coord)
    }
  }, error = function(e) {
    gg2d3_ir_null_facets(scales, FALSE)
  })
```

Use this style for helper seams that need to degrade to current behavior rather than fail broadly.

---

### `R/ir_theme_helpers.R` (if created) (utility, transform)

**Analog:** `R/as_d3_ir.R` nested `extract_theme_element()` and `R/ggplot2_compat.R`

**Theme element extraction candidate** (`R/as_d3_ir.R` lines 32-118):
```r
extract_theme_element <- function(element_name, theme) {
  calc <- gg2d3_calc_element(element_name, theme)

  if (is.null(calc)) {
    return(NULL)
  }

  if (inherits(calc, "element_blank")) {
    return(list(type = "blank"))
  }

  if (inherits(calc, "element_rect")) {
    linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

    return(list(
      type = "rect",
      fill = if (length(calc$fill) > 0 && !is.na(calc$fill)) calc$fill else NULL,
      colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
      linewidth = linewidth_px,
      linetype = calc$linetype
    ))
  }
```

**Private ggplot2 API quarantine** (`R/ggplot2_compat.R` lines 1-20):
```r
gg2d3_plot_theme <- function(plot) {
  tryCatch(
    ggplot2:::plot_theme(plot), # no exported equivalent; quarantined in compat helper
    error = function(e) NULL
  )
}

gg2d3_calc_element <- function(element_name, theme, default = NULL) {
  if (is.null(theme)) {
    return(default)
  }

  element <- tryCatch(
    ggplot2:::calc_element(element_name, theme), # no exported equivalent; quarantined in compat helper
    error = function(e) NULL
  )

  if (is.null(element)) default else element
}
```

Do not add new `ggplot2:::` calls outside `R/ggplot2_compat.R`.

---

### `tests/testthat/test-ir-helper-boundaries.R` (test, batch IR characterization)

**Analog:** `tests/testthat/test-ir-helper-boundaries.R`

**Test imports pattern** (line 1):
```r
library(ggplot2)
```

**Focused expectation pattern** (lines 3-18):
```r
test_that("scale helper preserves continuous and transformed domains", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_length(ir$scales$x$domain, 2)
  expect_true(ir$scales$x$domain[1] <= min(mtcars$wt), info = "scale helper x domain lower bound")
  expect_true(ir$scales$x$domain[2] >= max(mtcars$wt), info = "scale helper x domain upper bound")

  p_log <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_log10()
  ir_log <- as_d3_ir(p_log)

  expect_equal(ir_log$scales$x$transform, "log10", info = "scale helper log transform")
  expect_equal(ir_log$scales$x$base, 10, info = "scale helper log base")
  expect_true(all(ir_log$scales$x$domain > 0), info = "scale helper log domain")
})
```

**Layer dispatch characterization pattern** (lines 66-99):
```r
test_that("layer helper preserves geom names and row data", {
  rect_df <- data.frame(xmin = 0, xmax = 1, ymin = 0, ymax = 1)
  text_df <- data.frame(x = 1, y = 1, label = "A")
  polygon_df <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1),
    id = 1
  )

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point(data = mtcars[1:2, ]) +
    geom_line(data = mtcars[1:3, ]) +
    geom_rect(
      data = rect_df,
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      inherit.aes = FALSE
    ) +
    geom_text(data = text_df, aes(x = x, y = y, label = label), inherit.aes = FALSE) +
    geom_polygon(data = polygon_df, aes(x = x, y = y, group = id), inherit.aes = FALSE)
  ir <- as_d3_ir(p)

  expect_equal(
    vapply(ir$layers, `[[`, character(1), "geom"),
    c("point", "line", "rect", "text", "polygon"),
    info = "layer helper geom dispatch"
  )
```

**Optional dependency skip pattern** (lines 115-118):
```r
test_that("layer helper preserves sf annotation layer contracts", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")
```

Add curated checks here for theme extraction and geom parameter routing. Keep expectations local and named with `info`.

---

### `vignettes/d3-drawing-diagnostics.md` (documentation, batch reference)

**Analog:** `vignettes/d3-drawing-diagnostics.md`

**Boundary documentation pattern** (lines 60-107):
````markdown
## Browser visual smoke artifacts

Maintainers can generate local browser-rendered visual smoke artifacts with the
opt-in test runner. The skip-friendly command is:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The full artifact command is:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```
````

**Residual-risk list pattern** (lines 155-167):
```markdown
## Phase 47 residual-risk list

The v1.11 geometry parity contract is deliberately bounded. The following items
are deferred and not shipped by Phase 47:

- Polygon topology/hole repair beyond grouped closed paths.
- Full rect/tile transformed-scale edge parity.
- Tile basemaps and slippy map controls.
- JavaScript-side CRS reprojection.
- ggrepel collision avoidance.
- Rich text for text and label annotations.
- Rotation parity for text and label annotations.
- Path-following annotation placement.
```

If diagnostics are updated, follow this concise limitation-and-validation style. Do not add generated docs or a public extension API description in Phase 53.

## Shared Patterns

### Renderer Module Registration

**Source:** `inst/htmlwidgets/modules/geoms/point.js` lines 32-39 and 160-162
**Apply to:** All geom module contract checks
```javascript
function renderPoint(layer, g, xScale, yScale, options) {
  const val = window.gg2d3.helpers.val;
  const num = window.gg2d3.helpers.num;
  const asRows = window.gg2d3.helpers.asRows;
  const mmToPxRadius = window.gg2d3.constants.mmToPxRadius;
  const { strokeColor, fillColor, opacity } =
    window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
}

window.gg2d3.geomRegistry.register('point', renderPoint);
```

**Multi-alias registration source:** `inst/htmlwidgets/modules/geoms/interval.js` lines 92-94
```javascript
// Register with geom registry
window.gg2d3.geomRegistry.register(['errorbar', 'linerange', 'pointrange'], renderInterval);
```

### Render Selectors

**Source:** `inst/htmlwidgets/modules/geoms/sf.js` lines 350-384 and 416-442
**Apply to:** `renderSelectors` contract validation
```javascript
sfGroup.selectAll("path.geom-sf.geom-sf-polygon")
  .data(polygonRows)
  .enter().append("path")
    .attr("class", "geom-sf geom-sf-polygon")

sfGroup.selectAll("path.geom-sf.geom-sf-line")
  .data(lineRows)
  .enter().append("path")
    .attr("class", "geom-sf geom-sf-line")

sfGroup.selectAll("circle.geom-sf.geom-sf-point")
  .data(pointRows)
  .enter().append("circle")
    .attr("class", "geom-sf geom-sf-point")

group.selectAll("text.geom-sf.geom-sf-text")
  .data(rows)
  .enter().append("text")
    .attr("class", "geom-sf geom-sf-text")

var labelGroups = group.selectAll("g.geom-sf.geom-sf-label")
  .data(rows)
  .enter().append("g")
    .attr("class", "geom-sf geom-sf-label")
```

### Interaction Selectors

**Source:** `inst/htmlwidgets/modules/events.js` lines 46-52; `brush.js` lines 52-58; `crosstalk.js` lines 39-45
**Apply to:** Events, brush, and crosstalk selector tests
```javascript
const contractEventSelectors = window.gg2d3.geomContracts &&
  typeof window.gg2d3.geomContracts.selectorsFor === 'function'
    ? window.gg2d3.geomContracts.selectorsFor('events')
    : [];
const INTERACTIVE_SELECTORS = contractEventSelectors.length
  ? contractEventSelectors
  : FALLBACK_INTERACTIVE_SELECTORS;
```

### Public Payload Sanitization

**Source:** `inst/htmlwidgets/modules/public-data.js` lines 21-37
**Apply to:** Tooltip, event handlers, brush callbacks
```javascript
function publicFieldNames(d) {
  if (!isObjectDatum(d)) return [];
  return Object.keys(d).filter(function(key) {
    return !String(key).startsWith('_');
  });
}

function sanitizeDatum(d) {
  if (!isObjectDatum(d)) return d;

  var sanitized = {};
  Object.keys(d).forEach(function(key) {
    if (String(key).startsWith('_')) return;
    sanitized[key] = d[key];
  });
  return sanitized;
}
```

**Consumer source:** `inst/htmlwidgets/modules/events.js` lines 64-77, `brush.js` lines 405-421, `tooltip.js` lines 117-130

### IR Helper Style

**Source:** `R/ir_scale_helpers.R`, `R/ir_layer_helpers.R`, `R/ir_facet_helpers.R`
**Apply to:** Any extracted `as_d3_ir()` helper seam

Internal helpers are unexported `gg2d3_ir_*` functions. They accept explicit objects/values, return plain R lists/vectors/data frames, avoid roxygen exports, and keep private ggplot2 API calls routed through `R/ggplot2_compat.R`.

### Test Message Style

**Source:** `tests/testthat/test-ir-helper-boundaries.R` and `tests/testthat/test-renderer-wiring-contracts.R`
**Apply to:** All new contract and helper-boundary assertions

Use `info = "..."` or `info = paste(...)` for high-risk loops. Messages should name the missing geom alias, module, selector, private field, sanitizer, or IR boundary.

## No Analog Found

None. Every expected Phase 53 file has an exact or role-match analog in the current codebase. If planning introduces a different helper filename, use `R/ir_layer_helpers.R`, `R/ir_scale_helpers.R`, and `R/ir_facet_helpers.R` as the helper style source.

## Metadata

**Analog search scope:** `R/`, `inst/htmlwidgets/`, `inst/htmlwidgets/modules/`, `inst/htmlwidgets/modules/geoms/`, `tests/testthat/`, `vignettes/`
**Files scanned:** 60+ source, test, widget, and planning files via `rtk rg --files`; 18 geom modules listed under `inst/htmlwidgets/modules/geoms`
**Pattern extraction date:** 2026-05-28
**Project instructions applied:** `AGENTS.md`, `CLAUDE.md`, `/Users/davidzenz/.codex/RTK.md`
