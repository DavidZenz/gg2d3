# Getting started with gg2d3

gg2d3 renders ggplot2 plots as interactive D3.js SVG widgets in the
browser. Pass any ggplot object to
[`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md) and
get an htmlwidget you can view in RStudio, R Markdown, Shiny, or any web
page.

## Basic usage

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`gg2d3`](https://github.com/DavidZenz/gg2d3)`)`\
\
`p`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, color ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`ggtitle`](https://ggplot2.tidyverse.org/reference/labs.html)`(``"Motor Trend Cars"``)`\
\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`

The widget size defaults to the viewer/container size. Override with
`width` and `height` (in pixels or CSS units):

\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``, width ``=`` ``800``, height ``=`` ``500``)`

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
are described in the public support sections below.

## v1.13 validation and caveat summary

The v1.13 support contract is source-first and intentionally bounded.
Browser visual validation uses the dedicated browser visual smoke
workflow and the same `test_output/browser-visual-smoke/` artifact
layout documented in diagnostics; local runs may skip cleanly when
optional browser tooling is unavailable, while CI mode treats
browser-level skips as failures. Renderer and interactivity wiring are
guarded by `geom-contracts.js`, and representative IR helper-boundary
tests cover the selected theme and geom-parameter helper boundaries
without claiming full
[`as_d3_ir()`](https://davidzenz.github.io/gg2d3/reference/as_d3_ir.md)
modularization.

Geometry caveats are also explicit. Ordinary
[`geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
support covers bounded SVG label boxes and small placement fields.
Ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
support remains a grouped closed-path renderer, not topology or hole
repair.
[`geom_rect()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
and
[`geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
use ggplot2-built transformed bounds and filter non-finite transformed
SVG bounds before drawing. Collision avoidance, rich text,
path-following text, broad GIS-style topology repair, committed pixel
thresholds, and generated renderer reference docs remain future work.

### Points, lines, and paths

\
`# Scatter plot`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``iris``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``Sepal.Length``, ``Sepal.Width``, color ``=`` ``Species``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``3``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Line chart (connects points in x order)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``economics``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``date``, ``unemploy``)``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Path (connects points in data order)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(`[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``x ``=`` `[`cos`](https://rdrr.io/r/base/Trig.html)`(`[`seq`](https://rdrr.io/r/base/seq.html)`(``0``, ``2`` ``*`` ``pi``, length.out ``=`` ``60``)``)``,`\
`                    y ``=`` `[`sin`](https://rdrr.io/r/base/Trig.html)`(`[`seq`](https://rdrr.io/r/base/seq.html)`(``0``, ``2`` ``*`` ``pi``, length.out ``=`` ``60``)``)``)``,`\
`        `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``x``, ``y``)``)`` ``+`\
`  `[`geom_path`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)`` ``+`\
`  `[`coord_fixed`](https://ggplot2.tidyverse.org/reference/coord_fixed.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### Bars and columns

\
`# geom_bar (counts)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, fill ``=`` ``class``)``)`` ``+`\
`  `[`geom_bar`](https://ggplot2.tidyverse.org/reference/geom_bar.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# geom_col (values) with stacking`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, fill ``=`` ``drv``)``)`` ``+`\
`  `[`geom_bar`](https://ggplot2.tidyverse.org/reference/geom_bar.html)`(``position ``=`` ``"stack"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### Rectangles, tiles, and text

\
`# Heatmap with geom_tile`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``faithfuld``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``waiting``, ``eruptions``, fill ``=`` ``density``)``)`` ``+`\
`  `[`geom_tile`](https://ggplot2.tidyverse.org/reference/geom_tile.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Text labels`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, label ``=`` `[`rownames`](https://rdrr.io/r/base/colnames.html)`(``mtcars``)``)``)`` ``+`\
`  `[`geom_text`](https://ggplot2.tidyverse.org/reference/geom_text.html)`(``size ``=`` ``3``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### Ordinary polygons

Ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
renders each group as a grouped closed SVG path while preserving
ggplot2’s built row order. Fill, stroke, alpha, linewidth, linetype,
facets, zoom/update behavior, and the existing tooltip, hover, brush,
handler, and linked-view hooks are supported at the polygon path level.

\
`poly`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  id ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"a"``, ``"b"``)``, each ``=`` ``4``)``,`\
`  x ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``1``, ``1.2``, ``0``, ``1.5``, ``2.6``, ``2.2``, ``1.3``)``,`\
`  y ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``0.2``, ``1``, ``0.8``, ``0.1``, ``0.4``, ``1.2``, ``0.9``)`\
`)`\
\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``poly``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``x``, ``y``, group ``=`` ``id``, fill ``=`` ``id``)``)`` ``+`\
`  `[`geom_polygon`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)`(``color ``=`` ``"white"``, linewidth ``=`` ``0.4``, alpha ``=`` ``0.8``)`` ``+`\
`  `[`coord_fixed`](https://ggplot2.tidyverse.org/reference/coord_fixed.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

This is a grouped-path contract, not a GIS topology engine:
topology/hole repair outside clean ggplot2 built groups is deferred.

### Area and ribbon

\
`# Area chart`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``economics``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``date``, ``unemploy``)``)`` ``+`\
`  `[`geom_area`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)`(``fill ``=`` ``"steelblue"``, alpha ``=`` ``0.5``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Ribbon (confidence band)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``economics``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``date``, ``unemploy``)``)`` ``+`\
`  `[`geom_ribbon`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)`(`[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``ymin ``=`` ``unemploy`` ``-`` ``500``, ymax ``=`` ``unemploy`` ``+`` ``500``)``,`\
`              alpha ``=`` ``0.3``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### Segments and reference lines

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`geom_hline`](https://ggplot2.tidyverse.org/reference/geom_abline.html)`(``yintercept ``=`` ``20``, linetype ``=`` ``"dashed"``, color ``=`` ``"red"``)`` ``+`\
`  `[`geom_vline`](https://ggplot2.tidyverse.org/reference/geom_abline.html)`(``xintercept ``=`` ``3``, linetype ``=`` ``"dotted"``, color ``=`` ``"blue"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

`geom_segment` and `geom_abline` are also supported.

### Statistical geoms

These geoms are pre-computed in R (via ggplot2’s stat system) and
rendered by D3. No JavaScript statistics are needed.

\
`# Boxplot`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``)``)`` ``+`\
`  `[`geom_boxplot`](https://ggplot2.tidyverse.org/reference/geom_boxplot.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Violin`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``, fill ``=`` ``class``)``)`` ``+`\
`  `[`geom_violin`](https://ggplot2.tidyverse.org/reference/geom_violin.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Density`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``diamonds``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``price``, fill ``=`` ``cut``)``)`` ``+`\
`  `[`geom_density`](https://ggplot2.tidyverse.org/reference/geom_density.html)`(``alpha ``=`` ``0.5``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
\
`# Smooth (loess or lm)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`geom_smooth`](https://ggplot2.tidyverse.org/reference/geom_smooth.html)`(``method ``=`` ``"loess"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`\
`` #> `geom_smooth()` using formula = 'y ~ x' ``

### sf family maps with `geom_sf`

geom_sf() supports polygon-family (`POLYGON`, `MULTIPOLYGON`),
point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
`MULTILINESTRING`) geometries. Polygon-family choropleths and overlays
render as D3 `path` marks; point-family rows render as `.geom-sf-point`
marks; and line-family rows render as `.geom-sf-line` paths.
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
render labels at projected anchors aligned with those accepted sf
families. This example uses the `nc` shapefile bundled with `sf` and
renders county boundaries as D3 `path` marks.

\
`has_sf`` ``<-`` `[`requireNamespace`](https://rdrr.io/r/base/ns-load.html)`(``"sf"``, quietly ``=`` ``TRUE``)`\
`has_geojsonsf`` ``<-`` `[`requireNamespace`](https://rdrr.io/r/base/ns-load.html)`(``"geojsonsf"``, quietly ``=`` ``TRUE``)`\
`missing_sf_packages`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`  ``if`` ``(``!``has_sf``)`` ``"sf"``,`\
`  ``if`` ``(``!``has_geojsonsf``)`` ``"geojsonsf"`\
`)`\
\
`if`` ``(`[`length`](https://rdrr.io/r/base/length.html)`(``missing_sf_packages``)`` ``>`` ``0``)`` ``{`\
`  `[`cat`](https://rdrr.io/r/base/cat.html)`(`\
`    ``"PKGDOWN_SF_OPTIONAL_SKIP: sf example not rendered; missing "``,`\
`    `[`paste`](https://rdrr.io/r/base/paste.html)`(``missing_sf_packages``, collapse ``=`` ``", "``)``,`\
`    ``".\n"``,`\
`    sep ``=`` ``""`\
`  ``)`\
`}`` ``else`` ``{`\
`  ``sf_pkg`` ``<-`` `[`asNamespace`](https://rdrr.io/r/base/ns-internal.html)`(``"sf"``)`\
`  ``nc`` ``<-`` ``sf_pkg``$``st_read``(`[`system.file`](https://rdrr.io/r/base/system.file.html)`(``"shape/nc.shp"``, package ``=`` ``"sf"``)``, quiet ``=`` ``TRUE``)`\
\
`  ``(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``nc``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``fill ``=`` ``AREA``)``)`` ``+`\
`    `[`geom_sf`](https://ggplot2.tidyverse.org/reference/ggsf.html)`(``color ``=`` ``"white"``, linewidth ``=`` ``0.2``)`` ``+`\
`    `[`scale_fill_gradient`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)`(``low ``=`` ``"#eff3ff"``, high ``=`` ``"#08519c"``)`` ``+`\
`    `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``fill ``=`` ``"Area"``)``)`` ``|>`\
`    `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`` ``|>`\
`    `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``fields ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"NAME"``, ``"AREA"``)``)`` ``|>`\
`    `[`d3_hover`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)`(``opacity ``=`` ``0.35``, stroke ``=`` ``"#111827"``, stroke_width ``=`` ``1.5``)`` ``|>`\
`    `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``fill ``=`` ``"#f59e0b"``, opacity ``=`` ``0.2``)`\
`}`

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
  rotation parity, or path-following placement.

## Scales

### Continuous transforms

Log, sqrt, and reverse transforms work as expected:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``diamonds``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``carat``, ``price``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``alpha ``=`` ``0.1``)`` ``+`\
`  `[`scale_y_log10`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### Date and datetime scales

Date and POSIXct columns are automatically detected and rendered with
temporal D3 scales. Axis tick labels use the format from ggplot2’s
`date_labels` argument:

\
`df`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  date ``=`` `[`seq`](https://rdrr.io/r/base/seq.html)`(`[`as.Date`](https://rdrr.io/r/base/as.Date.html)`(``"2024-01-01"``)``, `[`as.Date`](https://rdrr.io/r/base/as.Date.html)`(``"2024-12-31"``)``, by ``=`` ``"month"``)``,`\
`  value ``=`` `[`cumsum`](https://rdrr.io/r/base/cumsum.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``12``)``)`\
`)`\
\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``df``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``date``, ``value``)``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`scale_x_date`](https://ggplot2.tidyverse.org/reference/scale_date.html)`(``date_labels ``=`` ``"%b %Y"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

POSIXct (datetime) works the same way:

\
`df`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  time ``=`` `[`as.POSIXct`](https://rdrr.io/r/base/as.POSIXlt.html)`(``"2024-01-01"``)`` ``+`` ``(``0``:``23``)`` ``*`` ``3600``,`\
`  temp ``=`` ``15`` ``+`` ``5`` ``*`` `[`sin`](https://rdrr.io/r/base/Trig.html)`(`[`seq`](https://rdrr.io/r/base/seq.html)`(``0``, ``2`` ``*`` ``pi``, length.out ``=`` ``24``)``)`` ``+`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``24``, sd ``=`` ``0.5``)`\
`)`\
\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``df``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``time``, ``temp``)``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)`` ``+`\
`  `[`scale_x_datetime`](https://ggplot2.tidyverse.org/reference/scale_date.html)`(``date_labels ``=`` ``"%H:%M"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

Timezone information from `scale_x_datetime(timezone = ...)` is
preserved in tooltips.

### Secondary axes

Secondary axes are fully rendered — ticks, labels, and the axis title
from
[`sec_axis()`](https://ggplot2.tidyverse.org/reference/sec_axis.html)
all appear on the opposite side of the panel.

\
`# Secondary axis showing unemployment in millions`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``economics``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``date``, ``unemploy``)``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)`` ``+`\
`  `[`scale_y_continuous`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)`(`\
`    name ``=`` ``"Unemployment (thousands)"``,`\
`    sec.axis ``=`` `[`sec_axis`](https://ggplot2.tidyverse.org/reference/sec_axis.html)`(``~`` ``.`` ``/`` ``1000``, name ``=`` ``"Millions"``)`\
`  ``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

## Color scales

Continuous color and fill aesthetics render as a true colorbar legend (a
gradient with axis ticks), not a stack of discrete keys. Discrete
palettes — viridis, brewer, manual — produce identical hex codes to
ggplot2’s own output.

\
`# Viridis continuous → colorbar legend`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``faithfuld``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``waiting``, ``eruptions``, fill ``=`` ``density``)``)`` ``+`\
`  `[`geom_tile`](https://ggplot2.tidyverse.org/reference/geom_tile.html)`(``)`` ``+`\
`  `[`scale_fill_viridis_c`](https://ggplot2.tidyverse.org/reference/scale_viridis.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
`# Brewer discrete`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, color ``=`` ``class``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`scale_color_brewer`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)`(``palette ``=`` ``"Set2"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
`# Manual`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, color ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``3``)`` ``+`\
`  `[`scale_color_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"4"`` ``=`` ``"#1b9e77"``, ``"6"`` ``=`` ``"#d95f02"``, ``"8"`` ``=`` ``"#7570b3"``)``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

## Coordinates

### coord_flip

Swaps x and y axes. All geoms and scales adapt automatically:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``)``)`` ``+`\
`  `[`geom_boxplot`](https://ggplot2.tidyverse.org/reference/geom_boxplot.html)`(``)`` ``+`\
`  `[`coord_flip`](https://ggplot2.tidyverse.org/reference/coord_flip.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### coord_fixed

Enforces a fixed aspect ratio between x and y units:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`coord_fixed`](https://ggplot2.tidyverse.org/reference/coord_fixed.html)`(``ratio ``=`` ``1``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

## Faceting

### facet_wrap

Wraps panels into rows by one or more variables:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`facet_wrap`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)`(``~``class``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

With free scales:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`facet_wrap`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)`(``~``class``, scales ``=`` ``"free"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

### facet_grid

Lays out panels in a grid defined by row and column variables:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`facet_grid`](https://ggplot2.tidyverse.org/reference/facet_grid.html)`(``drv`` ``~`` ``cyl``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

Free scales work per-row (`"free_y"`) or per-column (`"free_x"`):

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`facet_grid`](https://ggplot2.tidyverse.org/reference/facet_grid.html)`(``drv`` ``~`` ``cyl``, scales ``=`` ``"free"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

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

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``iris``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``Sepal.Length``, ``Sepal.Width``, color ``=`` ``Species``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(``legend.position ``=`` ``"bottom"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

Use `theme(legend.position = "none")` to hide legends entirely.

When multiple aesthetics share the same variable, guides are merged into
a single legend automatically.

## Theming

gg2d3 translates ggplot2 theme elements to SVG styling:

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`theme_minimal`](https://ggplot2.tidyverse.org/reference/ggtheme.html)`(``)`` ``+`\
`  `[`ggtitle`](https://ggplot2.tidyverse.org/reference/labs.html)`(``"Minimal theme"``)`` ``+`\
`  `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``subtitle ``=`` ``"Rendered with D3"``, caption ``=`` ``"Source: mtcars"``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

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

\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``iris``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``Sepal.Length``, ``Sepal.Width``, color ``=`` ``Species``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``3``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`` ``|>`\
`  `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``)`` ``|>`\
`  `[`d3_hover`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)`(``)`` ``|>`\
`  `[`d3_zoom`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)`(``)`` ``|>`\
`  `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``)`

You can use any combination — they are all optional and independent.

### Tooltips

[`d3_tooltip()`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)
shows data values on hover. By default it displays all mapped
aesthetics.

\
`# Default: show all aesthetics`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``)`

\
\
`# Show specific fields only`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``fields ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"wt"``, ``"mpg"``)``)`

\
\
`# Custom JavaScript formatter`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``formatter ``=`` ``"function(d) { return d.mpg + ' mpg'; }"``)`

Tooltips automatically format date/datetime values using the browser’s
locale.

### Hover highlighting

[`d3_hover()`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)
dims non-hovered elements so the hovered group stands out.

\
`# Default: dim others to 30% opacity`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_hover`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)`(``)`

\
\
`# Softer dimming + highlight stroke`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_hover`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)`(``opacity ``=`` ``0.5``, stroke ``=`` ``"black"``, stroke_width ``=`` ``2``)`

When a brush selection is active, hover highlighting is automatically
disabled to avoid visual conflicts.

### Zoom and pan

[`d3_zoom()`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)
enables scroll-to-zoom and drag-to-pan. Double-click resets to the
original view.

\
`# Default: zoom both axes, 1x to 8x`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_zoom`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)`(``)`

\
\
`# Zoom x-axis only, up to 20x`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_zoom`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)`(``direction ``=`` ``"x"``, scale_extent ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``, ``20``)``)`

Axes update dynamically during zoom. Temporal axes preserve their date
formatting.

### Brush selection

[`d3_brush()`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)
lets users drag to select a rectangular region. Selected elements stay
at full opacity while others dim.

\
`# Default: 2D brush with blue overlay`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``)`

\
\
`# Horizontal brush only`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``direction ``=`` ``"x"``)`

\
\
`# Custom callback receiving selected data`\
[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p``)`` ``|>`` `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(`\
`  on_brush ``=`` ``"function(data) { console.log(data.length + ' points selected'); }"`\
`)`

Double-click clears the brush selection.

### Linked views with Crosstalk

gg2d3 supports [crosstalk](https://rstudio.github.io/crosstalk/) for
linking multiple widgets. Brushing in one widget highlights the same
observations in all linked widgets.

\
`has_crosstalk`` ``<-`` `[`requireNamespace`](https://rdrr.io/r/base/ns-load.html)`(``"crosstalk"``, quietly ``=`` ``TRUE``)`\
`has_htmltools`` ``<-`` `[`requireNamespace`](https://rdrr.io/r/base/ns-load.html)`(``"htmltools"``, quietly ``=`` ``TRUE``)`\
\
`if`` ``(``!``has_crosstalk`` ``||`` ``!``has_htmltools``)`` ``{`\
`  ``missing_crosstalk_packages`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`    ``if`` ``(``!``has_crosstalk``)`` ``"crosstalk"``,`\
`    ``if`` ``(``!``has_htmltools``)`` ``"htmltools"`\
`  ``)`\
`  `[`cat`](https://rdrr.io/r/base/cat.html)`(`\
`    ``"PKGDOWN_CROSSTALK_OPTIONAL_SKIP: linked-view example not rendered; missing "``,`\
`    `[`paste`](https://rdrr.io/r/base/paste.html)`(``missing_crosstalk_packages``, collapse ``=`` ``", "``)``,`\
`    ``".\n"``,`\
`    sep ``=`` ``""`\
`  ``)`\
`}`` ``else`` ``{`\
`  ``shared`` ``<-`` ``crosstalk``::`[`SharedData`](https://rdrr.io/pkg/crosstalk/man/SharedData.html)`$``new``(`\
`    ``iris``,`\
`    key ``=`` `[`rownames`](https://rdrr.io/r/base/colnames.html)`(``iris``)``,`\
`    group ``=`` ``"pkgdown_crosstalk_iris"`\
`  ``)`\
\
`  ``p1`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``iris``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``Sepal.Length``, ``Sepal.Width``, color ``=`` ``Species``)``)`` ``+`\
`    `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``2``)`\
`  ``p1``$``data`` ``<-`` ``shared`\
\
`  ``p2`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``iris``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``Petal.Length``, ``Petal.Width``, color ``=`` ``Species``)``)`` ``+`\
`    `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``2``)`\
`  ``p2``$``data`` ``<-`` ``shared`\
\
`  ``w1`` ``<-`` `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p1``)`` ``|>`` `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``)`` ``|>`` `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``)`\
`  ``w2`` ``<-`` `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``p2``)`` ``|>`` `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``)`` ``|>`` `[`d3_brush`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)`(``)`\
\
`  ``htmltools``::`[`tagList`](https://rstudio.github.io/htmltools/reference/tagList.html)`(`\
`    ``htmltools``::`[`div`](https://rstudio.github.io/htmltools/reference/builder.html)`(`\
`      style ``=`` `[`paste`](https://rdrr.io/r/base/paste.html)`(`\
`        ``"display: grid;"``,`\
`        ``"grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));"``,`\
`        ``"gap: 1rem;"`\
`      ``)``,`\
`      ``w1``,`\
`      ``w2`\
`    ``)`\
`  ``)`\
`}`

Crosstalk works in static HTML documents — no Shiny server required.

## Combining features

A realistic example combining multiple features:

\
`# warning = FALSE: loess emits "neighborhood too small" / "pseudoinverse"`\
`# notes when fit per (class × year) — some classes have <4 points per`\
`# facet. The fit still renders; the messages are expected for this demo.`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, color ``=`` ``class``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``2``)`` ``+`\
`  `[`geom_smooth`](https://ggplot2.tidyverse.org/reference/geom_smooth.html)`(``method ``=`` ``"loess"``, se ``=`` ``TRUE``)`` ``+`\
`  `[`facet_wrap`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)`(``~``year``)`` ``+`\
`  `[`scale_color_brewer`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)`(``palette ``=`` ``"Set2"``)`` ``+`\
`  `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`\
`    title ``=`` ``"Engine displacement vs highway MPG"``,`\
`    subtitle ``=`` ``"By vehicle class and model year"``,`\
`    x ``=`` ``"Displacement (L)"``,`\
`    y ``=`` ``"Highway MPG"`\
`  ``)`` ``+`\
`  `[`theme_minimal`](https://ggplot2.tidyverse.org/reference/ggtheme.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`` ``|>`\
`  `[`d3_tooltip`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)`(``)`` ``|>`\
`  `[`d3_hover`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)`(``)`` ``|>`\
`  `[`d3_zoom`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)`(``)`

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

\
`# Non-finite values: filtered with a single warning per layer;`\
`# remaining points render with visible gaps`\
`df`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``x ``=`` ``1``:``10``, y ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``:``4``, ``NA``, ``6``:``9``, ``NaN``)``)`\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``df``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``x``, ``y``)``)`` ``+`\
`  `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`\
`  `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
`# Warning: Removed 2 rows containing non-finite values (geom_point).`\
`# The geom_line connects the finite segments and shows a visible gap.`

\
`# Ordinary polygons: grouped closed paths with row-order preservation`\
`poly_edges`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  group ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"left"``, ``"right"``)``, each ``=`` ``4``)``,`\
`  x ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``1``, ``1``, ``0``, ``1.4``, ``2.4``, ``2.1``, ``1.2``)``,`\
`  y ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``0``, ``1``, ``0.8``, ``0.1``, ``0.2``, ``1``, ``0.9``)`\
`)`\
\
`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``poly_edges``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``x``, ``y``, group ``=`` ``group``, fill ``=`` ``group``)``)`` ``+`\
`  `[`geom_polygon`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)`(``color ``=`` ``"grey35"``, linewidth ``=`` ``0.4``, alpha ``=`` ``0.75``)`` ``+`\
`  `[`coord_fixed`](https://ggplot2.tidyverse.org/reference/coord_fixed.html)`(``)``)`` ``|>`\
`  `[`gg2d3`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md)`(``)`

\
`# topology/hole repair beyond grouped closed paths remains outside the shipped`\
`# support contract.`

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
