# Add hover effects to gg2d3 widget

Enables hover highlighting for a gg2d3 widget. When hovering over an
element, other elements are dimmed (reduced opacity) and the hovered
element can optionally receive a highlight stroke.

## Usage

``` r
d3_hover(widget, opacity = 0.3, stroke = NULL, stroke_width = NULL)
```

## Arguments

- widget:

  A gg2d3 widget object created by
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)

- opacity:

  Numeric opacity value (0-1) for non-hovered elements. Default is 0.3,
  which strongly dims other elements so the hovered one stands out. The
  hovered element always has opacity 1.0.

- stroke:

  Optional stroke color for hovered element (e.g., "black", "#ff0000").
  If `NULL`, no highlight stroke is added.

- stroke_width:

  Optional stroke width in pixels for hovered element. Only used if
  `stroke` is provided. Default is `NULL`.

## Value

Modified gg2d3 widget with hover effects enabled. Returns the widget to
enable pipe chaining.

## Details

For ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
paths and
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
polygon-family, point-family, line-family,
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html),
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
marks, hover uses the existing shared event handling path and exposes
sanitized source-row payloads without renderer-private fields.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()

# Basic hover with default dimming
gg2d3(p) |> d3_hover()

# Custom opacity
gg2d3(p) |> d3_hover(opacity = 0.3)

# Add highlight stroke
gg2d3(p) |> d3_hover(stroke = "red", stroke_width = 2)

# Combine with tooltips
gg2d3(p) |> d3_tooltip() |> d3_hover(opacity = 0.5)
} # }
```
