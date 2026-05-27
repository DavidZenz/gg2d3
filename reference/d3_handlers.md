# Add custom JavaScript event handlers to the plot

Handlers receive public data rows for rendered marks. Ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
paths and
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
polygon-family, point-family, line-family,
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html),
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
marks reuse the existing callback path and pass sanitized source-row
payloads to custom JavaScript callbacks and Shiny-style `shiny_id` click
updates without exposing renderer-private fields.

## Usage

``` r
d3_handlers(
  widget,
  click = NULL,
  mouseover = NULL,
  mouseout = NULL,
  shiny_id = NULL
)
```

## Arguments

- widget:

  A gg2d3 widget.

- click:

  Optional JS function string for click events.

- mouseover:

  Optional JS function string for mouseover events.

- mouseout:

  Optional JS function string for mouseout events.

- shiny_id:

  Optional string. If provided, clicking a mark will automatically
  update a Shiny input with this ID.

## Value

The modified widget.
