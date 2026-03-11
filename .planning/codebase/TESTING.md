# Testing Patterns

**Analysis Date:** 2026-03-11

## Test Framework

**Runner:**
- testthat [>= 3.0.0]
- Edition 3: `Config/testthat/edition: 3` in DESCRIPTION
- Config file: `tests/testthat.R` (standard setup, unchanged)

**Assertion Library:**
- testthat's `expect_*()` functions (built-in to testthat)

**Run Commands:**
```bash
devtools::test()              # Run all tests
testthat::test_file("tests/testthat/test-ir.R")  # Run single test file
devtools::test()              # Watch mode available via devtools
```

## Test File Organization

**Location:**
- `tests/testthat/` directory (standard R package structure)
- Test files committed to repository

**Naming:**
- Pattern: `test-<feature>.R`
- Examples:
  - `test-ir.R` - Intermediate representation structure and conversion
  - `test-validate-ir.R` - IR validation function
  - `test-interactivity.R` - Widget interactivity features
  - `test-geoms-phase4.R` - Geom support (area, ribbon, segment, etc.)
  - `test-geoms-phase5.R` - Additional geom support
  - `test-date-scales.R` - Temporal data handling
  - `test-facets.R`, `test-facet-grid.R` - Multi-panel layouts
  - `test-legends.R` - Guide/legend rendering
  - `test-zoom-brush.R`, `test-crosstalk.R` - Interactivity features
  - `test-layout.R` - Coordinate systems and layout

**Files per feature:** 1 file per feature area (clean separation of concerns)

## Test Structure

**Suite Organization:**
```r
test_that("descriptive test name", {
  # Setup
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

  # Action
  ir <- as_d3_ir(p)

  # Assertion
  expect_true(length(ir$layers) >= 1)
})
```

**Patterns:**
- Each test isolated and independent
- `library(ggplot2)` called within test functions for clarity
- Test names are descriptive and start with descriptive verb: "as_d3_ir builds layers", "continuous scale extracts domain"
- Data setup typically uses built-in datasets: `mtcars`, `economics`, `LakeHuron`

## Mocking

**Framework:** Not used - tests call actual functions

**Approach:**
- Direct function calls (no mocking)
- Built-in data (mtcars, economics, etc.) used as test data
- ggplot2 functions called directly to build test plots
- IR validation done against actual IR structures produced by `as_d3_ir()`

**What to Mock:**
- Not applicable - no mocking framework used

**What NOT to Mock:**
- ggplot2 functions (called directly)
- Data structures (use real test data)
- IR extraction (tested by calling actual `as_d3_ir()`)

## Fixtures and Factories

**Test Data:**
- Built-in R datasets: `mtcars`, `economics`, `LakeHuron`
- Ad-hoc dataframes created inline:
  ```r
  df <- data.frame(
    x = factor(c("A", "B"), levels = c("A", "B", "C", "D", "E")),
    y = 1:2
  )
  ```
- Custom transformations created as needed:
  ```r
  log2_trans <- scales::trans_new(
    "log2",
    transform = log2,
    inverse = function(x) 2^x
  )
  ```

**Common Test Data Patterns:**
- Factor levels with `levels` parameter for testing drop behavior
- NA values for null handling: `data.frame(x = c("A", "B", NA, "A"), y = 1:4)`
- Custom data ranges for scale testing
- Temporal data (Date, POSIXct) for time scale testing

**Location:**
- No separate fixture files - all test data created inline in test files
- Simple and self-contained approach

## Coverage

**Requirements:** No coverage targets enforced (none in DESCRIPTION or config)

**View Coverage:**
```bash
covr::package_coverage()           # Generate coverage report
covr::report()                     # Show in RStudio viewer
```

## Test Types

**Unit Tests:**
- Scope: Individual functions and small units
- Approach: Test IR structure, validation rules, widget modifications
- Dominant test type (90%+ of tests)
- Examples:
  - `test-ir.R`: Tests `as_d3_ir()` extraction for scales, layers, coordinates
  - `test-validate-ir.R`: Tests `validate_ir()` error/warning behavior
  - `test-interactivity.R`: Tests widget modifier functions (`d3_tooltip()`, `d3_hover()`)

**Integration Tests:**
- Scope: Multiple components working together
- Approach: Build full plots with multiple geoms/aesthetics, verify complete IR structure
- Examples:
  - Coordinate system + scale + geom combinations
  - Faceted plots with scale handling
  - Multiple layers with different geoms in single plot

**E2E Tests:**
- Not applicable - this is a rendering library (visual testing requires browser)
- Widget output tested for structure/data, not visual correctness

## Common Patterns

**Function Validation Testing:**
```r
test_that("function validates input", {
  expect_error(function_name("invalid_input"), "expected error message")
})
```

Example from `test-interactivity.R`:
```r
test_that("d3_hover() validates opacity range", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  expect_error(gg2d3(p) |> d3_hover(opacity = -0.1), "between 0 and 1")
  expect_error(gg2d3(p) |> d3_hover(opacity = 1.5), "between 0 and 1")
})
```

**Structure Verification:**
```r
test_that("object has expected structure", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  expect_true(length(ir$layers) >= 1)
  expect_true(length(ir$layers[[1]]$data) >= 1)
  expect_equal(ir$scales$x$type, "continuous")
})
```

**Widget Chaining:**
```r
test_that("pipe chaining preserves configurations", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |>
    d3_tooltip(fields = c("x", "y")) |>
    d3_hover(opacity = 0.5)

  expect_equal(w$x$interactivity$tooltip$fields, c("x", "y"))
  expect_equal(w$x$interactivity$hover$opacity, 0.5)
})
```

**Assertion Types Used:**

| Pattern | Usage | Example |
|---------|-------|---------|
| `expect_equal()` | Exact equality | `expect_equal(ir$scales$x$type, "continuous")` |
| `expect_true()` / `expect_false()` | Boolean conditions | `expect_true(length(ir$layers) >= 1)` |
| `expect_error()` | Error throwing | `expect_error(as_d3_ir(invalid), "error message")` |
| `expect_warning()` | Warning throwing | `expect_warning(as_d3_ir(p), "coord_trans")` |
| `expect_silent()` | No output | `expect_silent(validate_ir(valid_ir))` |
| `expect_null()` | NULL values | `expect_null(ir$scales$x$transform)` |
| `expect_s3_class()` | S3 class membership | `expect_s3_class(w, "gg2d3")` |
| `expect_identical()` | Reference equality | `expect_identical(result, valid_ir)` |
| `expect_type()` | R type checking | `expect_type(w$x$interactivity, "list")` |

**Assumption Testing (Implicit):**
```r
test_that("domain values cover data range", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Implicit assumption: domain should expand slightly beyond data range
  expect_true(ir$scales$x$domain[1] <= min(mtcars$wt))
  expect_true(ir$scales$x$domain[2] >= max(mtcars$wt))
})
```

**Discrete/Categorical Scale Testing:**
```r
test_that("discrete scale with drop=FALSE shows all factor levels", {
  library(ggplot2)
  df <- data.frame(
    x = factor(c("A", "B"), levels = c("A", "B", "C", "D", "E")),
    y = 1:2
  )
  p <- ggplot(df, aes(x, y)) + geom_point() + scale_x_discrete(drop = FALSE)
  ir <- as_d3_ir(p)

  expect_equal(length(ir$scales$x$domain), 5)
})
```

**Scale Transformation Testing:**
```r
test_that("log10 transformation extracted correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    scale_x_log10()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "log10")
  expect_equal(ir$scales$x$base, 10)
  expect_true(all(ir$scales$x$domain > 0))
})
```

**Error Message Validation:**
```r
test_that("log scale with zero data throws informative error", {
  library(ggplot2)
  p <- ggplot(data.frame(x = 0:10, y = 1:11), aes(x, y)) +
    geom_point() +
    scale_x_log10()

  expect_error(
    as_d3_ir(p),
    "Log scale on x-axis has non-positive domain"
  )

  expect_error(
    as_d3_ir(p),
    "pseudo_log"
  )
})
```

**Backward Compatibility Testing:**
```r
test_that("static rendering unaffected (backward compat)", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p)

  expect_null(w$x$interactivity)
  expect_s3_class(w, "gg2d3")
})
```

## Test Coverage Analysis

**Well-Tested Areas:**
- IR structure and extraction (`test-ir.R` - 263 lines)
- IR validation (`test-validate-ir.R` - 231 lines)
- Scale handling (continuous, discrete, transformations, temporal)
- Coordinate systems (flip, fixed)
- Widget interactivity (tooltip, hover, zoom, brush)
- Geom support (point, line, area, ribbon, bar, text, etc.)
- Faceting (wrap, grid)
- Legends/guides

**Test File Sizes:**
- Range: 230-390 lines per file
- Typical: 250-300 lines
- Total test code: 2379 lines across 12 files

---

*Testing analysis: 2026-03-11*
