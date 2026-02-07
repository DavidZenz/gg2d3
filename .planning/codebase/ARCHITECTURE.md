# Architecture

**Analysis Date:** 2026-02-07

## Pattern Overview

**Overall:** Three-layer pipeline architecture for translating ggplot2 graphics to D3.js visualizations via HTMLWidgets.

**Key Characteristics:**
- Unidirectional data flow: R → Intermediate Representation → D3 rendering
- JSON-serializable intermediate representation (IR) decouples R layer from JavaScript layer
- Event-driven rendering: ggplot objects converted once to IR, then rendered by D3
- No bidirectional communication or JavaScript-to-R callbacks currently implemented

## Layers

**R Layer (ggplot2 extraction):**
- Purpose: Extract ggplot2 objects and convert to IR format
- Location: `R/as_d3_ir.R` (~353 lines)
- Contains: Scale extraction, layer data marshalling, theme element translation, unit conversion
- Depends on: `ggplot2`, `grid` (for unit conversion)
- Used by: `gg2d3()` widget entry point in `R/gg2d3.R`

**IR Layer (intermediate representation):**
- Purpose: JSON-serializable format passed from R to JavaScript
- Location: Memory only—constructed as nested lists in `as_d3_ir()` and JSON-serialized by htmlwidgets
- Contains:
  - `scales`: x/y scale descriptions (type, domain, breaks, minor_breaks)
  - `layers`: Array of geom layer objects with data, aesthetics, parameters
  - `theme`: Extracted ggplot2 theme elements (panel, plot, grid, axis, text)
  - `coord`: Coordinate system info (type, flip status)
  - `axes`: Axis titles and orientations
  - `title`: Plot title
  - `width`, `height`, `padding`: Layout dimensions

**D3 Layer (rendering engine):**
- Purpose: Render IR as SVG visualization in the browser
- Location: `inst/htmlwidgets/gg2d3.js` (~716 lines)
- Contains: Scale construction, axis drawing, geom rendering, theme application
- Depends on: D3 v7 (`inst/htmlwidgets/lib/d3/d3.v7.min.js`)
- Entry point: `renderValue()` function receives IR object

## Data Flow

**Full rendering pipeline:**

1. **User provides ggplot object** → calls `gg2d3(p)` in `R/gg2d3.R`
2. **Input validation** → checks if input is ggplot or pre-built IR
3. **ggplot build** → `ggplot2::ggplot_build(p)` creates internal build object with data, scales, layout
4. **Extract scales** → `xscale_obj`, `yscale_obj` from build object for categorical mapping
5. **Process layers** → For each layer in `b$data`:
   - Map discrete x/y values to labels if categorical
   - Extract geom name (point/line/bar/rect/text/etc.)
   - Keep only relevant aesthetics (x, y, color, fill, size, alpha, etc.)
   - Coerce to base types (factors → characters, dates → numeric, etc.)
   - Convert to row-wise list format for JSON serialization
6. **Extract scales** → Build scale descriptions with type, domain, breaks:
   - Continuous: type + domain with 5% ggplot2 expansion
   - Categorical: type + domain from scale limits
   - Color: separate scale from color aesthetic values
7. **Extract theme** → Call `extract_theme_element()` for each theme component:
   - Panel (background, border)
   - Plot (background, margin)
   - Grid (major, minor)
   - Axis (line, text, title, ticks)
   - Text (title)
8. **Build IR object** → Nested list with all extracted components
9. **HTMLWidgets serialization** → `htmlwidgets::createWidget()` JSON-serializes IR
10. **D3 initialization** → JavaScript factory receives widget HTML element and IR data
11. **D3 rendering** → `draw(ir, elW, elH)`:
    - Set theme defaults (merge with extracted theme)
    - Calculate padding from theme margins
    - Create SVG container
    - Apply backgrounds (plot, panel)
    - Construct D3 scales (linear, band, log, sqrt, pow, symlog, time, etc.)
    - Draw grid lines (major then minor)
    - Draw axes with labels and ticks
    - Draw title
    - Process each layer:
      - Parse data from IR
      - Apply color/fill scales
      - Render geoms (point, line/path, bar/col, rect, text)
    - Apply theme styling to axes

**State during rendering:**
- No persistent state in JavaScript layer (stateless rendering)
- Scales and theme recomputed on each render
- Widget width/height from htmlwidgets container

## Key Abstractions

**Intermediate Representation (IR):**
- Purpose: Platform-agnostic format for ggplot data and styling
- Examples: `ir$scales$x`, `ir$layers`, `ir$theme$panel$background`
- Pattern: Nested named lists, JSON-compatible (no functions, only primitives and arrays)

**Scale Objects:**
- Purpose: Map data values to visual space
- Examples: `ir$scales$x` (continuous with domain + breaks), `ir$scales$color` (categorical)
- Pattern: Type-driven factory (`makeScale()` in D3) creates d3.scaleLinear, scaleBand, etc.

**Theme Element Extraction:**
- Purpose: Convert ggplot2 theme objects to JSON-serializable format
- Examples: `extract_theme_element("panel.background", theme)` → `{type:"rect", fill:"#EBEBEB", ...}`
- Pattern: Switch on element class (element_blank, element_rect, element_line, element_text, margin)

**Layer Processing Pipeline:**
- Purpose: Standardize geom data into row-wise format with aesthetics mapping
- Examples: Row-wise list `[{x:1, y:2, colour:"red"}, ...]` with `aes={x:"x", y:"y", color:"colour"}`
- Pattern: Keep only relevant columns, coerce types, create scalar rows for JSON

**Unit Conversion Helpers:**
- Purpose: Convert ggplot2 units (mm, inches) to pixels for web display
- Examples:
  - Linewidth: `linewidth_mm * 3.7795275591` (96 DPI / 25.4 mm/inch)
  - Size (points): `(size_mm * 3.78) / 2` for radius in pixels
  - Margin: `grid::convertUnit(inches) * 96`
- Pattern: Centralized in `extract_theme_element()` for theme, in D3 for geom aesthetics

## Entry Points

**R Entry Point (`R/gg2d3.R`):**
- Location: `gg2d3()` function
- Triggers: User calls `gg2d3(ggplot_object)` in console or Rmarkdown
- Responsibilities:
  - Accept ggplot or pre-built IR
  - Call `as_d3_ir()` if ggplot
  - Wrap IR in htmlwidgets object
  - Return widget for display

**IR Construction Entry Point (`R/as_d3_ir.R`):**
- Location: `as_d3_ir(p, width=640, height=400, padding=...)`
- Triggers: Called from `gg2d3()` or directly for testing
- Responsibilities:
  - Build ggplot
  - Extract and marshal all components
  - Return complete IR object

**D3 Entry Point (`inst/htmlwidgets/gg2d3.js`):**
- Location: HTMLWidgets factory function, `renderValue()` method
- Triggers: Widget HTML element created in browser
- Responsibilities:
  - Receive IR as data
  - Call `draw(ir, width, height)`
  - Handle resize events (currently no-op)

## Error Handling

**Strategy:** Defensive extraction with graceful degradation

**Patterns:**
- **Input validation:** `stopifnot(inherits(p, "ggplot"))` in `as_d3_ir()`
- **Null coalescing:** `%||%` operator for defaults (title, labels)
- **Safe navigation:** Check for column existence before accessing (`if ("x" %in% names(df))`)
- **Try-catch on scale limits:** `tryCatch(scale_obj$get_limits(), error = function(e) range(data_values))`
- **Type checking in D3:** `num()` helper validates numeric conversion, `val()` extracts scalars
- **Missing data filtering:** Filter out rows with null x/y before rendering

## Cross-Cutting Concerns

**Logging:** None currently implemented. Debugging via HTML export to browser for inspection.

**Validation:**
- R: Input ggplot validation, scale domain sanity checks (positive for log scales)
- D3: Color validation (`isValidColor()`), numeric coercion checks

**Authentication:** Not applicable (client-side only)

**Unit Conversion:**
- Centralized in `extract_theme_element()` and geom rendering functions
- Consistent: 96 DPI web standard, 1mm = 3.7795 pixels
- Applied to: linewidth, font size, point radius, margins

**Color Handling:**
- R: Extracts color values as strings (hex or R color names like "grey50")
- D3: `convertColor()` translates R grey scale (grey0-grey100) to hex
- D3: `isValidColor()` checks hex or CSS named colors
- Fallback chain: Layer aesthetic → layer params → default

**Discrete Value Mapping:**
- R: `map_discrete()` converts integer indices to string labels using scale limits
- Purpose: Categorical scales store integers in built data, labels in scale object
- Safety: Only maps if all non-NA values are whole numbers

---

*Architecture analysis: 2026-02-07*
