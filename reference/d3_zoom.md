# Add zoom and pan to gg2d3 widget

Enables mouse-wheel zoom and click-drag pan for a gg2d3 widget. Users
can zoom in/out with the mouse wheel, pan by dragging, and double-click
to reset to the original view.

## Usage

``` r
d3_zoom(widget, scale_extent = c(1, 8), direction = c("both", "x", "y"))
```

## Arguments

- widget:

  A gg2d3 widget object created by
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)

- scale_extent:

  Numeric vector of length 2 specifying the minimum and maximum zoom
  scale factors. Default is `c(1, 8)`, allowing up to 8x zoom. The
  minimum value must be \>= 1 (no zoom out beyond original view).

- direction:

  Character string specifying which axes to zoom. Options are:

  "both"

  :   Zoom both x and y axes (default)

  "x"

  :   Zoom only the x-axis (horizontal zoom)

  "y"

  :   Zoom only the y-axis (vertical zoom)

## Value

Modified gg2d3 widget with zoom interactivity enabled. Returns the
widget to enable pipe chaining.

## Details

`d3_zoom()` does not currently support widgets containing
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html) layers.
Those widgets are returned unchanged with the warning "d3_zoom() does
not support geom_sf layers yet; zoom has been suppressed." This keeps sf
map anti-features explicit until projection-aware zoom exists.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()

# Basic zoom (both axes)
gg2d3(p) |> d3_zoom()

# Horizontal zoom only
gg2d3(p) |> d3_zoom(direction = "x")

# Custom zoom range (1x to 16x)
gg2d3(p) |> d3_zoom(scale_extent = c(1, 16))

# Combine with tooltips
gg2d3(p) |> d3_tooltip() |> d3_zoom()
} # }
```
