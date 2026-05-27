# gg2d3

**gg2d3** renders **ggplot2** objects with **D3** in the browser (via
**htmlwidgets**). Under the hood, gg2d3 converts a ggplot into a small
intermediate representation (IR) and draws it in SVG with D3.

## Installation

Install the development version from GitHub:

``` r

# install.packages("devtools")
devtools::install_github("DavidZenz/gg2d3")
```

## Quick start

``` r

library(ggplot2)
library(gg2d3)

p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point() +
  ggtitle("mpg vs wt")

gg2d3(p)
```

## Features

### Geoms

| Category | Geoms |
|----|----|
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text`, `geom_polygon` |
| Area/Ribbon | `geom_area`, `geom_ribbon` |
| Intervals | `geom_segment`, `geom_errorbar`, `geom_linerange`, `geom_pointrange` |
| Annotation | `geom_hline`, `geom_vline`, `geom_abline`, `geom_rug` |
| Statistical | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_smooth` (loess, gam, lm), `geom_dotplot` |

Ordinary
[`geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
renders as grouped closed SVG paths with ggplot2 built row order
preserved inside each group. The shipped contract covers core
fill/stroke/alpha/linewidth/linetype styling, facets, zoom/update
behavior, and the existing tooltip, hover, brush, handler, and
linked-view hooks. Brush selection is path-bounds based and callback
payloads use sanitized representative source rows.

[`geom_rect()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
and
[`geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
support distinguishes scale-limit censoring from
[`coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html)
panel clipping: scale limits can remove or censor bounds before gg2d3
sees them, while coordinate limits keep finite rect/tile bounds and clip
in the SVG panel. Discrete tile geometry is closed for initial render
and update paths.

gg2d3 also supports
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html) for
polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family (`POINT`,
`MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`)
geometries, plus
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
annotations at projected anchors aligned with those accepted sf
families. Rows that are unsupported, empty, invalid, or missing are
skipped with warnings while accepted rows render; known CRS inputs are
normalized in R before serialization, and missing CRS coordinates are
serialized as-is with a warning. Optional browser validation is
R/testthat/chromote based and may skip cleanly; when available, it
covers sf family interactivity, stacked overlays, faceted and empty
panels, projected anchor placement, sanitized interactivity payloads,
and zoom suppression.

These support claims are intentionally scoped. gg2d3 does not claim
complete ggplot2 parity for polygon topology/hole repair beyond grouped
closed paths, full rect/tile transformed-scale edge parity, tile
basemaps, slippy controls, JavaScript-side CRS reprojection, ggrepel
collision avoidance, rich text, rotation parity, or path-following
annotation placement. See `vignettes/d3-drawing-diagnostics.md` for
detailed geometry caveats.

### Scales & Coordinates

- Continuous and categorical x/y scales with full parity
- Advanced scale configuration: `breaks`, `minor_breaks`, `expand`, and
  `oob` (squish/censor) logic
- Log, sqrt, and reverse scale transforms
- Date and datetime (POSIXct) scales with timezone parity
- `coord_flip`, `coord_fixed`, and **`coord_polar`** (pie, coxcomb,
  radar)

### Layout & Guides

- Centralized layout engine for high-fidelity panel, axis, and header
  positioning
- **Interactive Legends**: Click to toggle, Double-click to solo, Hover
  to preview
- Legends for color, fill, size, shape, and alpha aesthetics
- Continuous colorbars with gradient rendering
- Support for hierarchical facet headers (nested variables)

### Theming

- Deep theme inheritance (matches ggplot2 parent-child element tree)
- Full support for
  [`element_blank()`](https://ggplot2.tidyverse.org/reference/element.html)
  and detailed element styling
- Text justifications (`hjust`, `vjust`), margins, and rotations
- Legend box backgrounds and borders

### Interactivity

Composable pipe-based API:

``` r

gg2d3(p) |>
  d3_tooltip() |>
  d3_hover() |>
  d3_zoom() |>
  d3_brush() |>
  d3_transitions() |>
  d3_handlers(click = "console.log(d)")
```

- **Tooltips** — hover to see data values (with date/time and custom
  formatting)
- **Hover highlighting** — dim non-hovered groups with configurable
  styles
- **Zoom & pan** — scroll to zoom, drag to pan (smooth transitions)
- **Brush selection** — drag to select data regions (rectangular or
  axis-only)
- **Animated Transitions** — smooth, object-constant enter/update/exit
  animations
- **Custom Handlers** — execute custom JavaScript on mark interaction
- **Shiny Sync** — automatic synchronization of plot interactions with
  Shiny inputs
- **Linked views** — Crosstalk integration for cross-widget brushing

## Troubleshooting

- **Blank widget / only axes** Ensure D3 is bundled correctly in the
  package (`inst/htmlwidgets/lib/d3/d3.v7.min.js`) and
  `inst/htmlwidgets/gg2d3.yaml` declares it.

- **Console says “no marks drawn”** Your layer may be missing a
  recognized `geom` or data columns. Start with a simple scatter and
  inspect the IR:

  ``` r

  ir <- gg2d3:::as_d3_ir(p)
  str(ir$layers[[1]], max.level = 1)
  ```

## Development (for contributors)

Vendor D3 v7 locally:

``` r

dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file(
  "https://d3js.org/d3.v7.min.js",
  destfile = "inst/htmlwidgets/lib/d3/d3.v7.min.js",
  mode = "wb"
)
```

Iterate:

``` r

devtools::document()
devtools::load_all()
devtools::test()
```

------------------------------------------------------------------------

*Note:* `README.md` is generated from `README.Rmd`. Use
[`devtools::build_readme()`](https://devtools.r-lib.org/reference/build_readme.html)
to re-render.
