# Add tooltips to gg2d3 widget

Enables interactive tooltips on hover for a gg2d3 widget. Tooltips
display data values associated with each visual element (points, bars,
etc.).

## Usage

``` r
d3_tooltip(widget, fields = NULL, formatter = NULL)
```

## Arguments

- widget:

  A gg2d3 widget object created by
  [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)

- fields:

  Character vector of field names to display in tooltip. Accepts either
  original data variable names (e.g. `"wt"`, `"mpg"`) or internal
  aesthetic keys (e.g. `"x"`, `"y"`, `"colour"`). Variable names are
  resolved via the plot's aesthetic mapping; mapped expressions like
  `factor(cyl)` can only be addressed by aesthetic key. If `NULL`
  (default), shows all aesthetics except internal fields (those starting
  with underscore or internal keys like PANEL, group, etc.)

- formatter:

  Optional JavaScript function as string for custom value formatting.
  Function signature:
  `function(field, value) { return formatted_string; }`

## Value

Modified gg2d3 widget with tooltip interactivity enabled. Returns the
widget to enable pipe chaining.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()

# Basic tooltip with all fields
gg2d3(p) |> d3_tooltip()

# Show only specific fields
gg2d3(p) |> d3_tooltip(fields = c("mpg", "wt"))

# Custom formatter
gg2d3(p) |> d3_tooltip(
  formatter = "if (field === 'mpg') return field + ': ' + value + ' mpg'; return field + ': ' + value;"
)
} # }
```
