# Getting started with gg2d3

gg2d3 renders ggplot2 plots as interactive D3.js SVG widgets in the
browser. Pass any ggplot object to
[`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md) and
get an htmlwidget you can view in RStudio, R Markdown, Shiny, or any web
page.

## Basic usage

``` r

library(ggplot2)
library(gg2d3)

p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point() +
  ggtitle("Motor Trend Cars")

gg2d3(p)
```

The widget size defaults to the viewer/container size. Override with
`width` and `height` (in pixels or CSS units):

``` r

gg2d3(p, width = 800, height = 500)
```

## Supported geoms

gg2d3 supports the core Cartesian geoms below, ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html),
polygon-family, point-family, and line-family
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html), plus
projected-anchor
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
annotations. All aesthetics that ggplot2 maps (color, fill, size, shape,
alpha, linewidth) are carried through to D3. Detailed geometry caveats
live in `vignettes/d3-drawing-diagnostics.md`.

### Points, lines, and paths

``` r

# Scatter plot
(ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point(size = 3)) |>
  gg2d3()
```

``` r


# Line chart (connects points in x order)
(ggplot(economics, aes(date, unemploy)) +
  geom_line()) |>
  gg2d3()
```

``` r


# Path (connects points in data order)
(ggplot(data.frame(x = cos(seq(0, 2 * pi, length.out = 60)),
                    y = sin(seq(0, 2 * pi, length.out = 60))),
        aes(x, y)) +
  geom_path() +
  coord_fixed()) |>
  gg2d3()
```

### Bars and columns

``` r

# geom_bar (counts)
(ggplot(mpg, aes(class, fill = class)) +
  geom_bar()) |>
  gg2d3()
```

``` r


# geom_col (values) with stacking
(ggplot(mpg, aes(class, fill = drv)) +
  geom_bar(position = "stack")) |>
  gg2d3()
```

### Rectangles, tiles, and text

``` r

# Heatmap with geom_tile
(ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_tile()) |>
  gg2d3()
```

``` r


# Text labels
(ggplot(mtcars, aes(wt, mpg, label = rownames(mtcars))) +
  geom_text(size = 3)) |>
  gg2d3()
```

### Ordinary polygons

Ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
renders each group as a grouped closed SVG path while preserving
ggplot2’s built row order. Fill, stroke, alpha, linewidth, linetype,
facets, zoom/update behavior, and the existing tooltip, hover, brush,
handler, and linked-view hooks are supported at the polygon path level.

``` r

poly <- data.frame(
  id = rep(c("a", "b"), each = 4),
  x = c(0, 1, 1.2, 0, 1.5, 2.6, 2.2, 1.3),
  y = c(0, 0.2, 1, 0.8, 0.1, 0.4, 1.2, 0.9)
)

(ggplot(poly, aes(x, y, group = id, fill = id)) +
  geom_polygon(color = "white", linewidth = 0.4, alpha = 0.8) +
  coord_fixed()) |>
  gg2d3()
```

This is a grouped-path contract, not a GIS topology engine:
topology/hole repair outside clean ggplot2 built groups is deferred. See
`vignettes/d3-drawing-diagnostics.md` for detailed caveats.

### Area and ribbon

``` r

# Area chart
(ggplot(economics, aes(date, unemploy)) +
  geom_area(fill = "steelblue", alpha = 0.5)) |>
  gg2d3()
```

``` r


# Ribbon (confidence band)
(ggplot(economics, aes(date, unemploy)) +
  geom_ribbon(aes(ymin = unemploy - 500, ymax = unemploy + 500),
              alpha = 0.3) +
  geom_line()) |>
  gg2d3()
```

### Segments and reference lines

``` r

(ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_hline(yintercept = 20, linetype = "dashed", color = "red") +
  geom_vline(xintercept = 3, linetype = "dotted", color = "blue")) |>
  gg2d3()
```

`geom_segment` and `geom_abline` are also supported.

### Statistical geoms

These geoms are pre-computed in R (via ggplot2’s stat system) and
rendered by D3. No JavaScript statistics are needed.

``` r

# Boxplot
(ggplot(mpg, aes(class, hwy)) +
  geom_boxplot()) |>
  gg2d3()
```

``` r


# Violin
(ggplot(mpg, aes(class, hwy, fill = class)) +
  geom_violin()) |>
  gg2d3()
```

``` r


# Density
(ggplot(diamonds, aes(price, fill = cut)) +
  geom_density(alpha = 0.5)) |>
  gg2d3()
```

``` r


# Smooth (loess or lm)
(ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  geom_smooth(method = "loess")) |>
  gg2d3()
#> `geom_smooth()` using formula = 'y ~ x'
```

### sf family maps with `geom_sf`

[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
supports polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family
(`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
`MULTILINESTRING`) geometries. Polygon-family choropleths and overlays
render as D3 `path` marks; point-family rows render as `.geom-sf-point`
marks; and line-family rows render as `.geom-sf-line` paths.
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
render labels at projected anchors aligned with those accepted sf
families. This example uses the `nc` shapefile bundled with `sf` and
renders county boundaries as D3 `path` marks.

``` r

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

(ggplot(nc, aes(fill = AREA)) +
  geom_sf(color = "white", linewidth = 0.2) +
  scale_fill_gradient(low = "#eff3ff", high = "#08519c") +
  labs(fill = "Area")) |>
  gg2d3()
```

The [`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
support contract is intentionally explicit:

- Accepted families are polygon-family (`POLYGON`, `MULTIPOLYGON`),
  point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
  `MULTILINESTRING`), including projected-anchor
  [`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
  and
  [`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
  annotations for those families.
- known CRS inputs are normalized to WGS84 in R before serialization.
- Missing CRS emits
  `geom_sf layer has missing CRS; coordinates will be serialized as-is`.
- Rows that are unsupported, empty, invalid, or missing emit
  `geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries`
  and are skipped while accepted rows remain renderable.
- Optional browser validation is R/testthat/chromote based and may skip
  cleanly; when available, it covers sf family interactivity, stacked
  overlays, faceted and empty panels, projected anchor placement,
  sanitized interactivity payloads, and zoom suppression.
- gg2d3 does not provide tile basemaps, slippy map controls,
  JavaScript-side CRS reprojection, true geometry-overlap brushing, or
  large-map performance guarantees.
- sf annotations do not provide ggrepel collision avoidance, rich text,
  rotation parity, or path-following placement. See
  `vignettes/d3-drawing-diagnostics.md` for the detailed residual-risk
  list.

## Scales

### Continuous transforms

Log, sqrt, and reverse transforms work as expected:

``` r

(ggplot(diamonds, aes(carat, price)) +
  geom_point(alpha = 0.1) +
  scale_y_log10()) |>
  gg2d3()
```

### Date and datetime scales

Date and POSIXct columns are automatically detected and rendered with
temporal D3 scales. Axis tick labels use the format from ggplot2’s
`date_labels` argument:

``` r

df <- data.frame(
  date = seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "month"),
  value = cumsum(rnorm(12))
)

(ggplot(df, aes(date, value)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %Y")) |>
  gg2d3()
```

POSIXct (datetime) works the same way:

``` r

df <- data.frame(
  time = as.POSIXct("2024-01-01") + (0:23) * 3600,
  temp = 15 + 5 * sin(seq(0, 2 * pi, length.out = 24)) + rnorm(24, sd = 0.5)
)

(ggplot(df, aes(time, temp)) +
  geom_line() +
  scale_x_datetime(date_labels = "%H:%M")) |>
  gg2d3()
```

Timezone information from `scale_x_datetime(timezone = ...)` is
preserved in tooltips.

### Secondary axes

Secondary axes are fully rendered — ticks, labels, and the axis title
from
[`sec_axis()`](https://ggplot2.tidyverse.org/reference/sec_axis.html)
all appear on the opposite side of the panel.

``` r

# Secondary axis showing unemployment in millions
(ggplot(economics, aes(date, unemploy)) +
  geom_line() +
  scale_y_continuous(
    name = "Unemployment (thousands)",
    sec.axis = sec_axis(~ . / 1000, name = "Millions")
  )) |>
  gg2d3()
```

## Color scales

Continuous color and fill aesthetics render as a true colorbar legend (a
gradient with axis ticks), not a stack of discrete keys. Discrete
palettes — viridis, brewer, manual — produce identical hex codes to
ggplot2’s own output.

``` r

# Viridis continuous → colorbar legend
(ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_tile() +
  scale_fill_viridis_c()) |>
  gg2d3()
```

``` r

# Brewer discrete
(ggplot(mpg, aes(displ, hwy, color = class)) +
  geom_point() +
  scale_color_brewer(palette = "Set2")) |>
  gg2d3()
```

``` r

# Manual
(ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_manual(values = c("4" = "#1b9e77", "6" = "#d95f02", "8" = "#7570b3"))) |>
  gg2d3()
```

## Coordinates

### coord_flip

Swaps x and y axes. All geoms and scales adapt automatically:

``` r

(ggplot(mpg, aes(class, hwy)) +
  geom_boxplot() +
  coord_flip()) |>
  gg2d3()
```

### coord_fixed

Enforces a fixed aspect ratio between x and y units:

``` r

(ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  coord_fixed(ratio = 1)) |>
  gg2d3()
```

## Faceting

### facet_wrap

Wraps panels into rows by one or more variables:

``` r

(ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(~class)) |>
  gg2d3()
```

With free scales:

``` r

(ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(~class, scales = "free")) |>
  gg2d3()
```

### facet_grid

Lays out panels in a grid defined by row and column variables:

``` r

(ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_grid(drv ~ cyl)) |>
  gg2d3()
```

Free scales work per-row (`"free_y"`) or per-column (`"free_x"`):

``` r

(ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_grid(drv ~ cyl, scales = "free")) |>
  gg2d3()
```

## Legends

Legends are generated automatically from mapped aesthetics. All standard
legend types are supported:

- **Discrete color/fill** — color swatches with labels
- **Continuous colorbar** — gradient bar for continuous color/fill
  scales
- **Size** — graduated circles
- **Shape** — different point shapes
- **Alpha** — opacity levels

Legends can be positioned with `theme(legend.position = ...)`:

``` r

(ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point() +
  theme(legend.position = "bottom")) |>
  gg2d3()
```

Use `theme(legend.position = "none")` to hide legends entirely.

When multiple aesthetics share the same variable, guides are merged into
a single legend automatically.

## Theming

gg2d3 translates ggplot2 theme elements to SVG styling:

``` r

(ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  theme_minimal() +
  ggtitle("Minimal theme") +
  labs(subtitle = "Rendered with D3", caption = "Source: mtcars")) |>
  gg2d3()
```

Theme elements that are translated include:

- Plot, panel, and legend backgrounds
- Major and minor grid lines
- Axis lines, ticks, and text
- Plot title, subtitle, and caption
- Legend title and text styling

## Interactivity

gg2d3 provides a composable pipe-based API for adding interactivity.
Each function takes a widget and returns a widget, so they chain
naturally:

``` r

(ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point(size = 3)) |>
  gg2d3() |>
  d3_tooltip() |>
  d3_hover() |>
  d3_zoom() |>
  d3_brush()
```

You can use any combination — they are all optional and independent.

### Tooltips

[`d3_tooltip()`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)
shows data values on hover. By default it displays all mapped
aesthetics.

``` r

# Default: show all aesthetics
gg2d3(p) |> d3_tooltip()
```

``` r


# Show specific fields only
gg2d3(p) |> d3_tooltip(fields = c("wt", "mpg"))
```

``` r


# Custom JavaScript formatter
gg2d3(p) |> d3_tooltip(formatter = "function(d) { return d.mpg + ' mpg'; }")
```

Tooltips automatically format date/datetime values using the browser’s
locale.

### Hover highlighting

[`d3_hover()`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)
dims non-hovered elements so the hovered group stands out.

``` r

# Default: dim others to 30% opacity
gg2d3(p) |> d3_hover()
```

``` r


# Softer dimming + highlight stroke
gg2d3(p) |> d3_hover(opacity = 0.5, stroke = "black", stroke_width = 2)
```

When a brush selection is active, hover highlighting is automatically
disabled to avoid visual conflicts.

### Zoom and pan

[`d3_zoom()`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)
enables scroll-to-zoom and drag-to-pan. Double-click resets to the
original view.

``` r

# Default: zoom both axes, 1x to 8x
gg2d3(p) |> d3_zoom()
```

``` r


# Zoom x-axis only, up to 20x
gg2d3(p) |> d3_zoom(direction = "x", scale_extent = c(1, 20))
```

Axes update dynamically during zoom. Temporal axes preserve their date
formatting.

### Brush selection

[`d3_brush()`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)
lets users drag to select a rectangular region. Selected elements stay
at full opacity while others dim.

``` r

# Default: 2D brush with blue overlay
gg2d3(p) |> d3_brush()
```

``` r


# Horizontal brush only
gg2d3(p) |> d3_brush(direction = "x")
```

``` r


# Custom callback receiving selected data
gg2d3(p) |> d3_brush(
  on_brush = "function(data) { console.log(data.length + ' points selected'); }"
)
```

Double-click clears the brush selection.

### Linked views with Crosstalk

gg2d3 supports [crosstalk](https://rstudio.github.io/crosstalk/) for
linking multiple widgets. Brushing in one widget highlights the same
observations in all linked widgets.

``` r

library(crosstalk)

shared <- SharedData$new(iris)

p1 <- ggplot(shared, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point()

p2 <- ggplot(shared, aes(Petal.Length, Petal.Width, color = Species)) +
  geom_point()

# Display side by side (e.g. in R Markdown or Shiny)
w1 <- gg2d3(p1) |> d3_tooltip() |> d3_brush()
w2 <- gg2d3(p2) |> d3_tooltip() |> d3_brush()
```

Crosstalk works in static HTML documents — no Shiny server required.

## Combining features

A realistic example combining multiple features:

``` r

# warning = FALSE: loess emits "neighborhood too small" / "pseudoinverse"
# notes when fit per (class × year) — some classes have <4 points per
# facet. The fit still renders; the messages are expected for this demo.
(ggplot(mpg, aes(displ, hwy, color = class)) +
  geom_point(size = 2) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_wrap(~year) +
  scale_color_brewer(palette = "Set2") +
  labs(
    title = "Engine displacement vs highway MPG",
    subtitle = "By vehicle class and model year",
    x = "Displacement (L)",
    y = "Highway MPG"
  ) +
  theme_minimal()) |>
  gg2d3() |>
  d3_tooltip() |>
  d3_hover() |>
  d3_zoom()
```

## Error handling and edge cases

gg2d3 provides three observable guarantees when data or geoms fall
outside normal rendering scope:

1.  **Non-finite values** — `NA`, `NaN`, and `Inf` are filtered from
    each layer with a single R warning per layer. Remaining finite
    points render normally; line/path geoms show a visible gap where the
    non-finite rows were removed.
2.  **Unsupported geoms** — when a geom type has no D3 renderer, gg2d3
    emits a browser-console warning instead of rendering marks for that
    layer.
3.  **R-level errors during build** — if
    [`ggplot_build()`](https://ggplot2.tidyverse.org/reference/ggplot_build.html)
    itself errors (e.g., incompatible stat/geom combinations), the error
    is surfaced as an R condition before any D3 rendering is attempted.

``` r

# Non-finite values: filtered with a single warning per layer;
# remaining points render with visible gaps
df <- data.frame(x = 1:10, y = c(1:4, NA, 6:9, NaN))
(ggplot(df, aes(x, y)) +
  geom_point() +
  geom_line()) |>
  gg2d3()
```

``` r

# Warning: Removed 2 rows containing non-finite values (geom_point).
# The geom_line connects the finite segments and shows a visible gap.
```

``` r

# Ordinary polygons: grouped closed paths with row-order preservation
poly_edges <- data.frame(
  group = rep(c("left", "right"), each = 4),
  x = c(0, 1, 1, 0, 1.4, 2.4, 2.1, 1.2),
  y = c(0, 0, 1, 0.8, 0.1, 0.2, 1, 0.9)
)

(ggplot(poly_edges, aes(x, y, group = group, fill = group)) +
  geom_polygon(color = "grey35", linewidth = 0.4, alpha = 0.75) +
  coord_fixed()) |>
  gg2d3()
```

``` r

# topology/hole repair beyond grouped closed paths remains outside the shipped
# support contract.
```

## Tips

- **Pipe from ggplot directly:** wrap the ggplot expression in
  parentheses so `+` resolves before `|>`:
  `(ggplot(...) + geom_point()) |> gg2d3()`. Without the parens, `|>`
  binds tighter than `+` and
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)
  receives only the last geom — not the plot. The cleaner alternative is
  to assign first: `p <- ggplot(...) + geom_point(); gg2d3(p)`.
- **Inspect the IR:** Use `gg2d3:::as_d3_ir(p)` to see exactly what data
  is sent to D3. Useful for debugging unexpected rendering.
- **Widget sizing:** In R Markdown, set chunk options `fig.width` and
  `fig.height` or pass `width`/`height` to
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md).
- **Performance:** For large datasets (\>10k points), consider using
  `alpha` to reduce overdraw and limit interactivity features to what
  you need.
