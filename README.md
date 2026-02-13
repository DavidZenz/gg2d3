
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gg2d3

<!-- badges: start -->
<!-- [![R-CMD-check](https://github.com/DavidZenz/gg2d3/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DavidZenz/gg2d3/actions/workflows/R-CMD-check.yaml) -->
<!-- [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html) -->
<!-- badges: end -->

**gg2d3** renders **ggplot2** objects with **D3** in the browser (via
**htmlwidgets**).
Under the hood, gg2d3 converts a ggplot into a small intermediate
representation (IR) and draws it in SVG with D3.

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
|----------|-------|
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text` |
| Area/Ribbon | `geom_area`, `geom_ribbon` |
| Segments | `geom_segment`, `geom_hline`, `geom_vline`, `geom_abline` |
| Statistical | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_smooth` |

### Scales & Coordinates

- Continuous and categorical x/y scales
- Log, sqrt, and reverse scale transforms
- `coord_flip` and `coord_fixed` with aspect ratio support

### Layout & Guides

- Centralized layout engine for panel, axis, and legend positioning
- Legends for color, fill, size, shape, and alpha aesthetics
- Merged guides for shared aesthetics
- Continuous colorbars with gradient rendering
- Legend placement: right, left, top, bottom, none

### Faceting

- `facet_wrap` with fixed scales
- Strip labels with themed styling
- Per-panel data filtering and rendering
- Panel spacing from theme

### Theming

- Full theme translation (backgrounds, grids, axes, text)
- Axis titles, plot titles, subtitles, and captions
- Secondary axes

## Planned

- `facet_grid` and free scales
- Pipe-based interactivity: `gg2d3(p) |> d3_tooltip() |> d3_zoom()`
- Brush selection and linked views

## Troubleshooting

- **Blank widget / only axes**
  Ensure D3 is bundled correctly in the package
  (`inst/htmlwidgets/lib/d3/d3.v7.min.js`) and
  `inst/htmlwidgets/gg2d3.yaml` declares it.

- **Console says "no marks drawn"**
  Your layer may be missing a recognized `geom` or data columns. Start
  with a simple scatter and inspect the IR:

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
