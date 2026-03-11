# Codebase Structure

**Analysis Date:** 2026-03-11

## Directory Layout

```
gg2d3/
├── R/                          # R package implementation layer
│   ├── gg2d3.R                 # Main widget entry point (44 lines)
│   ├── as_d3_ir.R              # ggplot2 → IR converter (~900 lines)
│   ├── validate_ir.R           # IR structure validation
│   ├── d3_hover.R              # Hover tooltip wrapper
│   ├── d3_zoom.R               # Zoom interactivity wrapper
│   ├── d3_brush.R              # Brush selection wrapper
│   ├── d3_crosstalk.R          # Crosstalk integration wrapper
│   └── d3_tooltip.R            # Tooltip customization
├── inst/htmlwidgets/           # Widget assets
│   ├── gg2d3.js                # Main widget factory (~1200 lines)
│   ├── gg2d3.yaml              # htmlwidgets config + module loading order
│   ├── lib/d3/                 # D3 v7 dependency (vendored)
│   │   └── d3.v7.min.js
│   └── modules/                # JavaScript modular architecture (1886 lines total)
│       ├── constants.js         # W3C unit conversions, ggplot2 defaults
│       ├── scales.js            # D3 scale factory
│       ├── theme.js             # Theme factory with defaults
│       ├── layout.js            # Layout engine (box algebra, space allocation)
│       ├── legend.js            # Legend rendering (keys, colorbars, merged guides)
│       ├── tooltip.js           # Hover tooltip rendering
│       ├── events.js            # D3 event binding (hover, click, brushing)
│       ├── zoom.js              # Pan/zoom interaction
│       ├── brush.js             # Rectangular brush selection
│       ├── crosstalk.js         # Crosstalk integration
│       ├── geom-registry.js     # Geom renderer dispatch
│       └── geoms/               # Individual geom renderers (12 files, 1886 lines total)
│           ├── point.js         # Circle marks
│           ├── line.js          # Line path
│           ├── bar.js           # Bar/column chart
│           ├── rect.js          # Rectangle (tile, heatmap)
│           ├── text.js          # Text labels
│           ├── area.js          # Area fill (stacked area)
│           ├── ribbon.js        # Ribbon (confidence band)
│           ├── segment.js       # Line segment
│           ├── reference.js     # Reference lines (hline, vline, abline)
│           ├── boxplot.js       # Box plot
│           ├── violin.js        # Violin plot
│           ├── density.js       # Density estimation plot
│           └── smooth.js        # Smoothing curves
├── tests/testthat/             # Test suite
│   ├── test-ir.R               # IR structure and scale tests
│   ├── test-validate-ir.R      # IR validation tests
│   ├── test-geoms-phase4.R     # Phase 4 geom rendering tests
│   ├── test-geoms-phase5.R     # Phase 5 geom rendering tests
│   ├── test-interactivity.R    # Zoom/brush/hover tests
│   ├── test-legends.R          # Legend rendering tests
│   ├── test-facets.R           # Faceting tests
│   ├── test-facet-grid.R       # facet_grid specific tests
│   ├── test-layout.R           # Layout engine tests
│   ├── test-zoom-brush.R       # Interactive selection tests
│   ├── test-date-scales.R      # Temporal scale tests
│   ├── test-crosstalk.R        # Crosstalk integration tests
│   └── testthat.R              # Test runner config
├── vignettes/                  # Documentation
│   └── d3-drawing-diagnostics.md # Feature support matrix and limitations
├── man/                        # Roxygen2 documentation (auto-generated)
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Package exports
├── README.md                   # User-facing overview
└── README.Rmd                  # Source for README
```

## Directory Purposes

**R/**
- Purpose: R API layer and ggplot2 → IR conversion
- Contains: Public functions (gg2d3, d3_*), IR builder, IR validator, wrapper functions
- Key files: `gg2d3.R` (entry point), `as_d3_ir.R` (converter)

**inst/htmlwidgets/**
- Purpose: Widget assets served to browser
- Contains: HTML widget factory, D3 library, modular JavaScript
- Key files: `gg2d3.js` (main renderer), `gg2d3.yaml` (dependency/module loading order)

**inst/htmlwidgets/modules/**
- Purpose: Reusable JavaScript utilities and renderers
- Contains: Scale/theme factories, layout engine, geom renderers, interactivity handlers
- Key files: `scales.js`, `layout.js`, `geom-registry.js`

**inst/htmlwidgets/modules/geoms/**
- Purpose: Individual geom-type rendering implementations
- Contains: One renderer per geom type, each implementing standard interface
- Key files: `point.js` (most basic), `bar.js` (complex with grouping)

**tests/testthat/**
- Purpose: Test coverage for all major features
- Contains: Unit tests organized by feature area
- Key files: `test-ir.R` (core IR tests), `test-geoms-phase*.R` (rendering tests)

## Key File Locations

**Entry Points:**
- `R/gg2d3.R`: User-facing function accepting ggplot or IR
- `inst/htmlwidgets/gg2d3.js`: Widget factory called by htmlwidgets framework

**Configuration:**
- `inst/htmlwidgets/gg2d3.yaml`: Declares dependencies and module load order
- `DESCRIPTION`: Package dependencies (ggplot2, htmlwidgets)
- `NAMESPACE`: Exported functions

**Core Logic:**
- `R/as_d3_ir.R`: Converts ggplot2 to IR (scales, layers, theme, facets)
- `inst/htmlwidgets/gg2d3.js`: Main render loop (layout, panel rendering, event setup)
- `inst/htmlwidgets/modules/layout.js`: Box algebra for space allocation

**Testing:**
- `tests/testthat/test-ir.R`: IR structure validation and scale tests
- `tests/testthat/test-geoms-*.R`: Rendering tests for specific geom phases

## Naming Conventions

**Files:**
- R functions: Snake_case (e.g., `as_d3_ir()`, `d3_zoom()`)
- R files: Snake_case (e.g., `as_d3_ir.R`, `validate_ir.R`)
- JavaScript modules: Kebab-case (e.g., `geom-registry.js`, `scales.js`)
- Test files: `test-{feature}.R` (e.g., `test-ir.R`, `test-geoms-phase4.R`)

**Functions:**
- R: Lowercase with underscores (`gg2d3()`, `as_d3_ir()`, `validate_ir()`)
- JavaScript: camelCase for methods, UPPER_SNAKE_CASE for constants
  - Exported: `window.gg2d3.{module}.{function}`
  - Example: `window.gg2d3.scales.createScale()`, `window.gg2d3.constants.DPI`

**Variables:**
- R: Lowercase with underscores within functions; camelCase for list elements in IR
- JavaScript: camelCase for local vars, snake_case for IR data (matching R convention)
- CSS classes: Kebab-case (e.g., `class="panel panel-1"`, `class="axis x-axis"`)

**Types:**
- R: `S3` classes for theme elements (element_rect, element_line, element_text)
- JavaScript: Plain objects for IR; no TypeScript
- R list keys: camelCase (x, y, color, label, xintercept)

## Where to Add New Code

**New Geom Type:**
1. Create `inst/htmlwidgets/modules/geoms/{name}.js` implementing renderer function
   - Signature: `function render{Name}(layer, g, xScale, yScale, options)`
   - Return: number of marks drawn
   - Pattern: See `point.js` or `bar.js` for examples
2. Register in same file: `window.gg2d3.geomRegistry.registerGeom("{name}", render{Name});`
3. Add to `inst/htmlwidgets/gg2d3.yaml` script list (maintains load order)
4. Add support in `R/as_d3_ir.R` geom name mapping (lines 169-200):
   - Map `Geom{ClassName}` to string name in switch statement
5. Add tests in new file `tests/testthat/test-geoms-phase*.R`
6. Export in `R/validate_ir.R` known_geoms list (line 13)

**New Feature (e.g., interactivity):**
1. Create wrapper function in `R/d3_{feature}.R`
   - Pattern: See `d3_zoom.R`, `d3_brush.R` for examples
   - Attach to htmlwidget as attribute
2. Create corresponding module `inst/htmlwidgets/modules/{feature}.js`
   - Pattern: Export function as `window.gg2d3.{feature}.initialize()`
3. Add module to `inst/htmlwidgets/gg2d3.yaml` script list
4. Call from main widget factory in `gg2d3.js` if needed
5. Add tests in `tests/testthat/test-interactivity.R` or new file

**New Utility:**
- Scales/theme: Add to `inst/htmlwidgets/modules/scales.js` or `theme.js`
- Unit conversion: Add to `inst/htmlwidgets/modules/constants.js`
- Layout: Add helper to `inst/htmlwidgets/modules/layout.js`

**New Theme Element:**
1. Add extraction in `R/as_d3_ir.R` (e.g., line 540-570 for theme structure)
2. Add to `inst/htmlwidgets/modules/theme.js` DEFAULT_THEME
3. Apply styling in relevant module (theme.js, scales.js, etc.)

## Special Directories

**inst/htmlwidgets/lib/d3/:**
- Purpose: Vendored D3 v7 library
- Generated: No (manually downloaded)
- Committed: Yes (dist/minified, checked into git)
- Setup: Download from https://d3js.org/d3.v7.min.js if missing

**.planning/milestones/**
- Purpose: Archive of phase plans and intermediate work
- Generated: Yes (during development phases)
- Committed: Yes (historical record)

**man/**
- Purpose: Roxygen2-generated documentation files
- Generated: Yes (from `@export` and `@param` comments in R files)
- Committed: Yes (in git, regenerated via `devtools::document()`)

---

*Structure analysis: 2026-03-11*
