# Build a D3-ready IR (intermediate representation) from a ggplot

Build a D3-ready IR (intermediate representation) from a ggplot

## Usage

``` r
as_d3_ir(
  p,
  width = 640,
  height = 400,
  padding = list(top = 20, right = 20, bottom = 40, left = 50)
)
```

## Arguments

- p:

  A ggplot object.

- width:

  Widget width in pixels.

- height:

  Widget height in pixels.

- padding:

  Named list of top, right, bottom, and left plot padding in pixels.
