# Add brush selection to gg2d3 widget

Enables rectangular brush selection for a gg2d3 widget. Click and drag
to create a selection rectangle; data points inside the selection are
highlighted while points outside are dimmed. Double-click to clear the
selection.

## Usage

``` r
d3_brush(
  widget,
  direction = c("xy", "x", "y"),
  on_brush = NULL,
  fill = "#3b82f6",
  opacity = 0.15
)
```

## Arguments

- widget:

  A gg2d3 widget object created by
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)

- direction:

  Character string specifying brush direction. One of:

  - `"xy"` (default): Two-dimensional rectangular brush

  - `"x"`: Horizontal band selection (x-axis only)

  - `"y"`: Vertical band selection (y-axis only)

- on_brush:

  Optional JavaScript callback as string. Receives selected data as
  array. Function signature: `function(selectedData) { ... }`

- fill:

  Brush overlay fill color. Default is `"#3b82f6"` (light blue).

- opacity:

  Numeric opacity value (0-1) for non-selected elements. Default is 0.15
  (heavily dimmed). Selected elements always have opacity 1.0.

## Value

Modified gg2d3 widget with brush selection enabled. Returns the widget
to enable pipe chaining.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()

# Basic brush selection
gg2d3(p) |> d3_brush()

# Horizontal brush only
gg2d3(p) |> d3_brush(direction = "x")

# Custom styling
gg2d3(p) |> d3_brush(fill = "#ff0000", opacity = 0.3)

# Combine with tooltips
gg2d3(p) |> d3_tooltip() |> d3_brush()
} # }
```
