# Add custom JavaScript event handlers to the plot

Add custom JavaScript event handlers to the plot

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
