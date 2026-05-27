# Render a ggplot as a D3 widget

gg2d3 supports ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
as grouped closed SVG paths,
[`geom_rect()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
and
[`geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
edge behavior for the shipped Cartesian scale and panel-clipping
contract, and
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family (`POINT`,
`MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`) layers.
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
render labels at projected anchors aligned with the existing sf panel
projection.

## Usage

``` r
gg2d3(x, width = NULL, height = NULL, elementId = NULL)
```

## Arguments

- x:

  ggplot object or IR list from as_d3_ir()

- width:

  Optional widget width passed to htmlwidgets.

- height:

  Optional widget height passed to htmlwidgets.

- elementId:

  Optional htmlwidgets element id.

## Details

Detailed caveats for polygon topology, rect/tile transformed-scale
behavior, sf annotation placement, ggrepel-style collision avoidance,
path-following text, and map anti-features are tracked in
`vignettes/d3-drawing-diagnostics.md`. Optional browser validation for
sf behavior is R/testthat/chromote based and may skip cleanly when
optional local tooling is unavailable.
