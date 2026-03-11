# Coding Conventions

**Analysis Date:** 2026-03-11

## Naming Patterns

**Files:**
- `snake_case.R` - R source files use snake_case for descriptive names
- Examples: `as_d3_ir.R` (converter), `d3_zoom.R` (widget feature), `validate_ir.R` (validator)
- Test files follow `test-<feature>.R` pattern in `tests/testthat/` directory

**Functions:**
- `snake_case` - All functions use snake_case
- Exported functions documented with roxygen2 `#' @export`
- Examples: `gg2d3()`, `as_d3_ir()`, `d3_zoom()`, `d3_tooltip()`, `validate_ir()`
- Internal helper functions not exported, placed within larger functions when local

**Variables:**
- `snake_case` - Local variables and parameters use snake_case
- Abbreviations acceptable for clarity: `ir` (intermediate representation), `p` (plot), `b` (built ggplot), `df` (dataframe)
- Common shortcuts: `xscale_obj`, `yscale_obj`, `gname`, `col`, `cn`, `ii`, `v`
- List names are lowercase: `scales`, `layers`, `params`, `aes`, `data`, `geom`

**Types/Classes:**
- Classes inherit from htmlwidgets: `gg2d3` (defined implicitly by htmlwidgets)
- S3 inheritance checks use `inherits(x, "gg2d3")`

## Code Style

**Formatting:**
- No explicit formatter configured (no .lintr or .styler files)
- Indentation: 2 spaces (observed throughout codebase)
- Line length: Typically 100 characters, some longer allowed
- Comments: Space after `#` for readability

**Roxygen2 Documentation:**
- All exported functions documented with roxygen2
- Standard template: `#'`, `@param`, `@return`, `@examples`, `@export`
- Markdown enabled: `Roxygen: list(markdown = TRUE)` in DESCRIPTION
- Code references: Use backticks for function names and file references
- Example: `\code{gg2d3()}` or inline backticks `` `gg2d3()` ``

**Linting:**
- No linting config detected (no .lintr file)
- Manual code review approach

## Import Organization

**Package Loading:**
- Explicit `library()` calls within functions when needed
- Example: `library(ggplot2)` called in `as_d3_ir()` for `ggplot_build()`
- Example: `library(ggplot2)` in test files for test data and plot construction
- Conditional imports: `requireNamespace("crosstalk", quietly = TRUE)` for optional features in `gg2d3.R`

**Path Aliases:**
- Not applicable - R package structure uses explicit namespacing
- All dependencies in `DESCRIPTION` file

## Error Handling

**Stop Conditions:**
- `stop()` for fatal errors with `call. = FALSE` to suppress stack trace
- Informative messages that help users understand what went wrong
- Example from `gg2d3.R`: `"Provide a ggplot object or a valid IR list."`
- Example from `d3_zoom.R`: `"scale_extent minimum must be >= 1 (no zoom out beyond original view)"`

**Validation:**
- `stopifnot()` for simple assertions at function start
- Example: `stopifnot(inherits(p, "ggplot"))` in `as_d3_ir()`
- Manual validation with detailed error messages for complex conditions
- Input validation typically done first in public functions (see `d3_zoom.R` lines 41-54)

**Warnings:**
- `warning()` with `call. = FALSE` for non-fatal issues
- Used for unsupported features that still render
- Example: "coord_trans() is not yet supported" in `as_d3_ir.R`
- Example: "Layer has no data" in `validate_ir.R`

## Logging

**Framework:** No logging framework (console.log equivalent in JavaScript)

**Patterns:**
- No explicit logging in R code
- JavaScript errors/warnings handled via browser console (in D3 rendering layer)
- Informational output via `warning()` and `message()` functions only

## Comments

**When to Comment:**
- Inline comments explain _why_ not _what_ (what is obvious from code)
- Example in `as_d3_ir.R`: `# drop factor classes to base vectors early`
- Example in `as_d3_ir.R`: `# make true scalars (no length-1 vectors)`
- Phase annotations: `# Phase 3` indicates planned feature development
- Internal implementation notes for complex transformations

**Roxygen/Documentation:**
- Roxygen2 `#'` comments required on all exported functions
- Parameter descriptions start with capital letter in roxygen: `@param x ggplot object or IR list`
- Return descriptions: `@return Modified gg2d3 widget with [feature] enabled`
- Examples section: `@examples` with `\dontrun{}` for interactive examples

## Function Design

**Size:**
- Typical range: 20-50 lines for public functions
- Larger functions (200+ lines): `as_d3_ir()`, used for complex IR extraction logic
- Private helper functions nested inside larger functions when logically grouped

**Parameters:**
- Public functions take 1-3 main parameters
- Optional parameters use defaults (e.g., `scale_extent = c(1, 8)` in `d3_zoom()`)
- Widget functions pattern: First parameter is `widget`, subsequent params are feature-specific
- Complex IR extraction uses optional width/height/padding parameters with sensible defaults

**Return Values:**
- Widget functions return the modified widget object for pipe chaining (R 4.1+ `|>` operator)
- Validation functions return input unchanged invisibly: `invisible(ir)` in `validate_ir()`
- Converters return structured lists (IR format)
- Constructors return widget objects suitable for htmlwidgets

**Inheritance Checks:**
- Public widget functions use `inherits(widget, "gg2d3")` for type validation
- Class detection: `inherits(x, "ggplot")` for ggplot2 objects
- Scale detection: `inherits(calc, "element_rect")`, `inherits(calc, "element_line")`, etc.

## Module Design

**Exports:**
- Core function: `gg2d3()` - main widget creator in `R/gg2d3.R`
- Converters: `as_d3_ir()` in `R/as_d3_ir.R` - exported, used by `gg2d3()`
- Validators: `validate_ir()` in `R/validate_ir.R` - exported for debugging/testing
- Widget modifiers: `d3_zoom()`, `d3_tooltip()`, `d3_hover()`, `d3_brush()` - exported feature enhancers
- Special integrations: `d3_crosstalk()` for interoperability

**File Organization:**
- One primary function per file (e.g., `d3_zoom.R` contains only `d3_zoom()`)
- Helper functions defined locally within the file or within the primary function
- Large complex functions like `as_d3_ir()` contain nested helpers: `to_rows()`, `map_discrete()`, `extract_theme_element()`, `validate_log_domain()`

**Barrel Files:**
- Not used - R uses `NAMESPACE` for explicit export control

**Environment Variables:**
- Accessed via list assignment: `widget$x$interactivity` (htmlwidgets structure)
- IR data structure uses nested lists accessed via `$` operator

## Testing Patterns Reflected in Code

- All public functions tested thoroughly in `tests/testthat/`
- Test coverage: 1717 lines of R code, 2379 lines of test code (1.4x ratio)
- Edge cases tested: empty data, categorical scales, transformations, coordinate systems

---

*Convention analysis: 2026-03-11*
