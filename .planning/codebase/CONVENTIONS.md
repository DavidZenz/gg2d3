# Coding Conventions

**Analysis Date:** 2026-02-07

## Naming Patterns

**Files:**
- `.R` extension for R source files
- File names use snake_case: `as_d3_ir.R`, `gg2d3.R`
- Test files in `tests/testthat/` follow pattern `test-*.R`

**Functions:**
- snake_case for all function definitions: `as_d3_ir()`, `map_discrete()`, `extract_theme_element()`
- Local helper functions use snake_case within function scope
- Special operators use backticks: `` `%||%` `` for null coalescing operator
- Function names are descriptive: `to_rows()`, `get_scale_info()`, `isValidColor()` (JavaScript)

**Variables:**
- snake_case for all variable names: `xscale_obj`, `keep_aes`, `allx`, `ally`, `scale_range`
- Abbreviations acceptable when clear: `ir` (intermediate representation), `df` (data frame), `col` (column)
- Prefix convention for type hints: `*_obj` for objects, `*_px` for pixel measurements
- One-letter loop indices acceptable: `i`, `ii` for loops, `x`, `y` for parameters

**Types:**
- Class checking via `inherits()`: `inherits(x, "ggplot")`, `inherits(calc, "element_rect")`
- Type checking via `is.*()`: `is.null()`, `is.list()`, `is.factor()`, `is.numeric()`
- Qualified function calls used with namespace prefix when from external packages: `ggplot2::ggplot_build()`, `htmlwidgets::createWidget()`, `grid::convertUnit()`

**JavaScript (D3 rendering):**
- camelCase for JavaScript functions: `val()`, `num()`, `isHexColor()`, `asRows()`, `makeScale()`, `convertColor()`
- camelCase for JavaScript variables: `domainArr`, `numericDomain`, `dateDomain`
- Constants in functions use camelCase: `testElem`, `greyMatch`

## Code Style

**Formatting:**
- Roxygen2 for R documentation generation
- RoxygenNote: 7.3.1 in DESCRIPTION
- 2-space indentation throughout (not tabs)
- Functions typically have opening brace `{` on same line as declaration
- Nested functions allowed and common for helper utilities

**Linting:**
- No explicit linting configuration detected (no .lintr or ESLint config)
- Package uses roxygen2 for documentation
- Encoding: UTF-8 specified in DESCRIPTION

## Import Organization

**Order (R):**
1. Namespace qualification for external packages: `ggplot2::ggplot_build()`, `htmlwidgets::createWidget()`, `grid::convertUnit()`
2. Base R functions used without prefix: `stopifnot()`, `inherits()`, `is.*()`, `lapply()`, `vector()`
3. No explicit import statements in function body; packages accessed via `::` notation

**Path Aliases:**
- Not applicable; R does not use path aliases in the same way JavaScript/TypeScript does
- ggplot2 object hierarchy accessed via `$` notation: `b$layout$panel_scales_x`, `b$plot$layers`, `b$plot$theme`

**Dependencies:**
- Roxygen2: Documentation generation
- testthat (>= 3.0.0): Testing framework (in Suggests)
- ggplot2: Plotting library (implicit, accessed via `::`)
- htmlwidgets: Widget framework for web output
- grid: For unit conversion (`grid::convertUnit`)

## Error Handling

**Patterns:**
- Input validation via `stopifnot()` at function entry:
  ```r
  stopifnot(inherits(p, "ggplot"))
  ```
- Conditional early returns for null/empty cases:
  ```r
  if (is.null(df) || !nrow(df)) return(list())
  ```
- `tryCatch()` for recovery from potentially failing operations:
  ```r
  scale_range <- tryCatch(
    scale_obj$get_limits(),
    error = function(e) range(data_values, finite = TRUE)
  )
  ```
- Null coalescing via custom `%||%` operator for default values:
  ```r
  `%||%` <- function(x, y) if (is.null(x)) y else x
  title = b$plot$labels$title %||% ""
  ```
- JavaScript null checks: `if (v == null || v === "")` for truthiness, `Number.isFinite()` for numeric validation

**Error Messages:**
- Stop messages are plain text, no special formatting: `"Provide a ggplot object or a valid IR list."`

## Logging

**Framework:** None detected; no logger package used

**Patterns:**
- No explicit logging in source code
- Comments used for explanation inline rather than logged output
- Console output via browser/web context in JavaScript visualization

## Comments

**When to Comment:**
- Inline comments explain WHY not WHAT: `# colors may be hex already`, `# ms for JS time if ever needed`
- Section comments use comment markers for clarity:
  ```r
  # --- robust geom name ---
  # Extract scale objects early (needed for mapping discrete values)
  # Helper to map discrete x/y values to labels
  ```
- Comments on important implementation decisions:
  ```r
  # IMPORTANT: do NOT jsonlite::toJSON() here. htmlwidgets will serialize it.
  # Convert linewidth from mm to pixels (1mm = 96/25.4 px at 96 DPI)
  ```
- JavaScript uses explanatory comments for complex logic:
  ```javascript
  // Use paddingOuter for edge spacing (matches ggplot2's 0.6 units)
  // Use paddingInner for spacing between bars
  ```

**Roxygen/JSDoc:**
- Roxygen2 comments with `#'` for exported functions: `#' Render a ggplot as a D3 widget`
- Parameters documented with `@param`: `#' @param x ggplot object or IR list from as_d3_ir()`
- Functions marked with `@export` for inclusion in NAMESPACE
- No JSDoc comments in JavaScript code; minimal inline documentation

## Function Design

**Size:**
- Main conversion function `as_d3_ir()` is 353 lines (including nested helpers) - acceptable for complex data transformation
- Helper functions kept small and focused: `map_discrete()`, `extract_theme_element()`, `get_scale_info()`
- JavaScript rendering functions also moderately sized (716 lines total for gg2d3.js)

**Parameters:**
- Function parameters with sensible defaults:
  ```r
  as_d3_ir <- function(p, width = 640, height = 400,
                       padding = list(top = 20, right = 20, bottom = 40, left = 50))
  ```
- Parameters passed as named lists when multiple related values: `padding`, `aes`
- No variadic arguments (...) used

**Return Values:**
- Consistent list/structure returns matching JSON serialization needs:
  ```r
  list(
    geom = gname,
    data = to_rows(df),
    aes = aes,
    params = params
  )
  ```
- NULL returns for missing/blank theme elements
- Row-wise list conversion for data transformation

## Module Design

**Exports:**
- Two functions exported via roxygen `@export`: `gg2d3()` and `as_d3_ir()`
- NAMESPACE auto-generated shows: `export(as_d3_ir)` and `export(gg2d3)`
- No barrel files; functions exported individually

**Barrel Files:**
- Not applicable; R uses NAMESPACE file for exports, not barrel/index files

---

*Convention analysis: 2026-02-07*
