# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**gg2d3** is an R package that renders ggplot2 graphics with D3.js in the browser via htmlwidgets. It converts ggplot objects into an intermediate representation (IR) and renders them as D3 SVG visualizations.

## Development Commands

```r
# Load package for development
devtools::load_all()

# Update roxygen2 documentation
devtools::document()

# Run tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-ir.R")

# Rebuild README (from README.Rmd)
devtools::build_readme()
```

D3 v7 must be vendored locally:
```r
dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file("https://d3js.org/d3.v7.min.js",
              destfile = "inst/htmlwidgets/lib/d3/d3.v7.min.js", mode = "wb")
```

## Architecture

The package has a three-layer pipeline:

1. **R Layer** (`R/as_d3_ir.R`) - Extracts ggplot2 objects and converts them to IR
2. **IR Layer** - JSON-serializable intermediate representation passed to JavaScript
3. **D3 Layer** (`inst/htmlwidgets/gg2d3.js`) - Renders IR as D3 SVG

### Key Files

| File | Purpose |
|------|---------|
| `R/gg2d3.R` | Main widget entry point (`gg2d3()` function) |
| `R/as_d3_ir.R` | ggplot2 → IR converter (~450 lines) |
| `inst/htmlwidgets/gg2d3.js` | D3 rendering engine (~1000 lines) |
| `inst/htmlwidgets/gg2d3.yaml` | htmlwidgets configuration |

### IR Structure

The intermediate representation contains:
- `scales` - x/y scale descriptions (type, domain, range)
- `layers` - Array of geom layers with data and params
- `theme` - Extracted theme elements (backgrounds, grids, axes, text)
- `coord` - Coordinate system info (including flip status)

## Current Feature Support

**Geoms:** point, line/path, bar/col, rect/tile, text

**Supported:**
- Continuous & categorical scales
- Axes with titles
- Color/fill aesthetics
- Theme translation (backgrounds, grids, axes)
- Stacked bars
- Basic coord_flip

## Known Limitations

Documented in `vignettes/d3-drawing-diagnostics.md`:
- No legends or facets
- geom_path sorts by x (breaks intentional ordering)
- Bar charts assume domain includes zero
- coord_flip puts axes on wrong sides
- Limited text options (no rotation/alignment)
