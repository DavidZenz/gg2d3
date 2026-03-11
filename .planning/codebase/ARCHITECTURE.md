# Architecture

**Analysis Date:** 2026-03-11

## Pattern Overview

**Overall:** Three-layer pipeline with intermediate representation (IR) decoupling

**Key Characteristics:**
- R layer (`R/as_d3_ir.R`) builds a JSON-serializable IR from ggplot2 objects
- IR layer passes structured data between R and JavaScript without execution
- D3 layer (`inst/htmlwidgets/gg2d3.js`) renders IR as SVG using modular geom renderers
- Module-based architecture in JavaScript with clear separation of concerns
- htmlwidgets integration for browser rendering and interactivity

## Layers

**R Layer (ggplot2 → IR):**
- Purpose: Extract ggplot2 structure and convert to JSON-compatible intermediate representation
- Location: `R/as_d3_ir.R` (main converter, ~900 lines)
- Contains: Scale extraction, geom layer processing, theme translation, facet metadata
- Depends on: ggplot2 (ggplot_build), grid (unit conversion)
- Used by: `R/gg2d3.R` (main widget entry point)

**IR Layer:**
- Purpose: Platform-agnostic data structure carrying all rendering information
- Location: In-memory JSON list, serialized by htmlwidgets
- Contains: `scales`, `layers`, `theme`, `coord`, `guides`, `facets`, `panels` keys
- Depends on: R list serialization via htmlwidgets
- Used by: D3 rendering engine

**D3 Layer (IR → SVG):**
- Purpose: Render IR specification as interactive D3 SVG visualization
- Location: `inst/htmlwidgets/gg2d3.js` (main widget factory, ~1200 lines) + `inst/htmlwidgets/modules/`
- Contains: Scale creation, panel rendering, axis drawing, legend generation, interactivity
- Depends on: D3 v7 (vendored in `inst/htmlwidgets/lib/d3/`), module system
- Used by: Browser HTMLWidget framework

## Data Flow

**Plot Rendering:**

1. User calls `gg2d3(ggplot_object)` in `R/gg2d3.R`
2. Detect crosstalk SharedData (if present) and extract underlying data
3. Call `as_d3_ir(ggplot_object)` to build intermediate representation
4. `as_d3_ir()` calls `ggplot2::ggplot_build()` to extract build data
5. Extract scales (x, y, color) from `b$layout$panel_scales_*` and `b$plot$scales`
6. Process layers: for each layer in `b$data`, map geom class to geom name, coerce data to rows
7. Extract theme elements from `b$plot$theme` (backgrounds, grids, axes, text)
8. Extract facet metadata from `b$layout$facet` and `b$layout$layout`
9. Return IR list with `scales`, `layers`, `theme`, `coord`, `guides`, `facets`, `panels`
10. htmlwidgets serializes IR to JSON and passes to browser
11. JavaScript factory in `gg2d3.js` receives IR and creates widget instance
12. Widget calls `renderPanel()` for each panel (facet or single)
13. For each panel: create scales, render grid/axes, filter layer data by PANEL, render geoms
14. Geom renderers (`inst/htmlwidgets/modules/geoms/*.js`) draw marks (circles, lines, bars, etc.)
15. Layout engine (`inst/htmlwidgets/modules/layout.js`) computes positions for title, axes, legend
16. Legend renderer (`inst/htmlwidgets/modules/legend.js`) draws legend keys and labels

**State Management:**
- R-side: ggplot2 build object contains all geom and scale state
- IR-side: Stateless JSON structure, IR serves as contract between languages
- JS-side: D3 selections manage DOM state; module namespace (`window.gg2d3.*`) holds utilities

## Key Abstractions

**Intermediate Representation (IR):**
- Purpose: Language-agnostic format capturing complete plot specification
- Examples: `R/as_d3_ir.R` builds IR, `inst/htmlwidgets/gg2d3.js` consumes it
- Pattern: Recursive lists/objects serializable to JSON with no functions or circular refs
- Structure:
  ```
  {
    scales: {x: {type, domain, breaks, ...}, y: {...}, color: {...}},
    layers: [{geom, data: [...], aes: {...}, params: {...}}, ...],
    theme: {panel, plot, grid, axis, text, legend, strip},
    coord: {type, ratio?},
    guides: [{aesthetic, type, title, keys, ...}, ...],
    facets: {type, nrow, ncol, scales_mode},
    panels: [{x_range, y_range, panel_num}, ...]
  }
  ```

**Geom Registry:**
- Purpose: Central dispatch for rendering different geom types
- Examples: `inst/htmlwidgets/modules/geom-registry.js` provides register/render/has APIs
- Pattern: HashMap of geom name → renderer function
- Renderers loaded in order in `gg2d3.yaml`: point, line, bar, rect, text, area, ribbon, segment, reference, boxplot, violin, density, smooth

**Scale Factory:**
- Purpose: Convert IR scale descriptors to D3 scale functions
- Examples: `inst/htmlwidgets/modules/scales.js` implements `createScale(scaleDesc, range)`
- Pattern: Examines `scaleDesc.type` (continuous/categorical), applies transform (log, sqrt, reverse), handles temporal scales
- Handles unit conversion (R mm → SVG pixels using W3C constants)

**Theme Factory:**
- Purpose: Provide theme values with default fallback
- Examples: `inst/htmlwidgets/modules/theme.js` implements `createTheme()` and deep merge
- Pattern: Merges user-provided theme over `DEFAULT_THEME` at retrieval time
- Matches ggplot2 theme_gray() defaults for consistency

**Panel Renderer:**
- Purpose: Render single plot panel (one facet, or whole plot if no facets)
- Examples: `renderPanel()` in `gg2d3.js` (lines 11-100)
- Pattern: Creates clipped group, renders grid/axes, filters layer data by PANEL, calls geom renderers

**Layout Engine:**
- Purpose: Compute pixel positions for all chart regions
- Examples: `inst/htmlwidgets/modules/layout.js` implements `calculateLayout()`
- Pattern: Pure function using box algebra (shrink, slice) to allocate space for margins, title, axes, legend

## Entry Points

**R Entry Point:**
- Location: `R/gg2d3.R`
- Triggers: User calls `gg2d3(ggplot_object)` or `gg2d3(ir_list)`
- Responsibilities: Accept ggplot or IR, detect crosstalk, build IR, create htmlwidget, add dependencies

**JavaScript Widget Factory:**
- Location: `inst/htmlwidgets/gg2d3.js` lines 1-10
- Triggers: htmlwidgets.js calls factory function with (el, width, height)
- Responsibilities: Initialize SVG, store IR, define render function, handle resize

**Render Function:**
- Location: `inst/htmlwidgets/gg2d3.js` in factory
- Triggers: htmlwidgets calls render(x) with serialized IR
- Responsibilities: Parse IR, call calculateLayout(), renderPanel() for each panel, set up interactivity

## Error Handling

**Strategy:** Early validation with informative messages

**Patterns:**
- `validate_ir()` in `R/validate_ir.R` checks IR structure before passing to JS (top-level keys, layer geoms, scale types)
- `as_d3_ir()` validates log scale domains (must be strictly positive) and warns on unsupported features (coord_trans)
- Discrete scale handling: Safe integer index mapping with bounds checks
- Temporal scale handling: Try-catch on date format extraction with UTC fallback
- Facet detection: Try-catch on facet inheritance checks with null-safe defaults

## Cross-Cutting Concerns

**Logging:** No logging layer; development debugging via console.log in JavaScript modules

**Validation:**
- R-side: `validate_ir()` function checks required IR structure
- JS-side: `createScale()` validates domain finiteness, color module checks hex/named color validity

**Authentication:** None (client-side rendering only)

**Unit Conversion:**
- Constants: `inst/htmlwidgets/modules/constants.js` defines W3C standards (96 DPI)
- Conversions: R mm → pixels (3.7795), points → pixels (1.333), dates → milliseconds (86400000 for days, 1000 for seconds)
- Applied in: `as_d3_ir.R` for theme linewidth/text size, `scales.js` for point radius/stroke width

---

*Architecture analysis: 2026-03-11*
