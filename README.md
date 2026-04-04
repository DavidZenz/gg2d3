
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gg2d3

<!-- badges: start -->

<!-- [![R-CMD-check](https://github.com/DavidZenz/gg2d3/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DavidZenz/gg2d3/actions/workflows/R-CMD-check.yaml) -->

<!-- [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html) -->

<!-- badges: end -->

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
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text` |
| Area/Ribbon | `geom_area`, `geom_ribbon`, `geom_polygon` |
| Intervals | `geom_segment`, `geom_errorbar`, `geom_linerange`, `geom_pointrange` |
| Annotation | `geom_hline`, `geom_vline`, `geom_abline`, `geom_rug` |
| Statistical | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_smooth` (loess, gam, lm), `geom_dotplot` |

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
- Full support for `element_blank()` and detailed element styling
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
`devtools::build_readme()` to re-render.
