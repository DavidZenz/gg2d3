# Technology Stack

**Analysis Date:** 2026-02-07

## Languages

**Primary:**
- R 4.x - Core package logic and API (`R/gg2d3.R`, `R/as_d3_ir.R`)
- JavaScript (ES6+) - D3 rendering engine (`inst/htmlwidgets/gg2d3.js`)

## Runtime

**Environment:**
- R runtime (minimum version not explicitly specified in DESCRIPTION)

**Package Manager:**
- R package system (DESCRIPTION manifest)
- No Node.js/npm (D3 is bundled, not managed via npm)

## Frameworks

**Core:**
- htmlwidgets 1.6.4+ - R/JavaScript bridge for interactive widgets
- ggplot2 - Input graphics system being converted
- D3.js v7 - SVG rendering engine (vendored locally)

**Testing:**
- testthat 3.0.0+ - Unit testing framework

**Build/Dev:**
- roxygen2 7.3.1 - Documentation generation
- devtools - Development utilities

## Key Dependencies

**Critical:**
- htmlwidgets - Bridges R ggplot objects to D3 rendering
- ggplot2 - Input parser; used via `ggplot2::ggplot_build()` and internal `ggplot2:::calc_element()`
- D3.js v7 - Renders IR as interactive SVG charts

**Infrastructure:**
- grid - Unit conversion (`grid::convertUnit()` in `R/as_d3_ir.R` for margin calculations)

**Implied (R base):**
- base R functions for list/vector manipulation

## Configuration

**Environment:**
- No environment variables required
- No configuration files (.env, config files)

**Build:**
- `DESCRIPTION` - Package metadata and dependencies
- `NAMESPACE` - Exports: `gg2d3()`, `as_d3_ir()`
- `inst/htmlwidgets/gg2d3.yaml` - htmlwidgets binding configuration

## Platform Requirements

**Development:**
- R runtime (4.x recommended based on roxygen2 compatibility)
- devtools package installed
- D3.js v7 vendored in `inst/htmlwidgets/lib/d3/d3.v7.min.js` (downloaded separately)

**Production:**
- Browser with SVG and D3.js support
- R Shiny/RMarkdown environment or standalone htmlwidgets

## Package Dependencies

**Imports (implicit - not listed in DESCRIPTION):**
- ggplot2 - Used directly without Imports declaration; code accesses:
  - `ggplot2::ggplot_build()` for building plot objects
  - `ggplot2:::calc_element()` for theme element extraction (private API)
- htmlwidgets - Used via `htmlwidgets::createWidget()` in `R/gg2d3.R`
- grid - Used via `grid::convertUnit()` for unit conversions

**Suggests:**
- testthat (>= 3.0.0) - Test framework

## D3 Dependency

**Version:** D3.js v7 (minified)
**Location:** `inst/htmlwidgets/lib/d3/d3.v7.min.js`
**Distribution:** Vendored locally; not managed via package manager
**Install:** Must be manually downloaded via:
```r
dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file("https://d3js.org/d3.v7.min.js",
              destfile = "inst/htmlwidgets/lib/d3/d3.v7.min.js", mode = "wb")
```

---

*Stack analysis: 2026-02-07*
