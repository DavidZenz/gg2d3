# Testing Patterns

**Analysis Date:** 2026-02-07

## Test Framework

**Runner:**
- testthat (>= 3.0.0) - R testing framework
- Config: `tests/testthat.R`
- Roxygen edition: 3 (Config/testthat/edition: 3 in DESCRIPTION)

**Assertion Library:**
- testthat built-in expectations: `expect_true()`, `expect_equal()`, etc.

**Run Commands:**
```bash
# Run all tests (from R console)
devtools::test()

# Run single test file
testthat::test_file("tests/testthat/test-ir.R")

# Run tests via command line
R CMD check .
```

## Test File Organization

**Location:**
- Co-located in `tests/testthat/` directory (not beside source files)
- Main test file: `tests/testthat/test-ir.R`
- Setup file: `tests/testthat.R` (standard testthat boilerplate)

**Naming:**
- Pattern: `test-*.R` for test files
- Currently: `test-ir.R` for intermediate representation tests

**Structure:**
```
tests/
├── testthat.R          # Setup and configuration
└── testthat/
    └── test-ir.R       # Test suite for as_d3_ir()
```

## Test Structure

**Suite Organization:**
```r
test_that("as_d3_ir builds layers with data", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_true(length(ir$layers) >= 1)
  expect_true(length(ir$layers[[1]]$data) >= 1)
  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$y$type, "continuous")
})
```

**Patterns:**
- Single test suite with 4 assertions per test_that block
- Setup within test block (creates plot object locally)
- Direct assertions on IR structure fields
- Library imported within test for scope isolation

## Mocking

**Framework:** Not detected; no mocking library used (no mockery, unittest.mock, etc.)

**Patterns:**
- No mocking detected in current tests
- Tests work with real ggplot2 objects rather than mocks
- Real data (mtcars) used for testing

**What to Mock:**
- External system calls (not relevant to current codebase)
- ggplot2::ggplot_build() could be mocked for unit testing, but current approach uses real builds

**What NOT to Mock:**
- ggplot2 objects and their structure (tests rely on real behavior)
- Data frames and list structures (work with actual outputs)

## Fixtures and Factories

**Test Data:**
- Real R data: `mtcars` dataset used in test
- No factory pattern detected
- Plots created inline: `ggplot(mtcars, aes(wt, mpg)) + geom_point()`

**Location:**
- Test data created within `test-ir.R` test blocks
- No separate fixtures directory
- No reusable factory functions for test data

**Coverage:**
- Current coverage: Only 1 test for IR conversion
- Geom types: Tests point geometry only
- Scale types: Tests continuous scales only
- Theme elements: Not explicitly tested
- Edge cases: Not tested (empty data, NULL values, etc.)

## Test Types

**Unit Tests:**
- Scope: Individual function behavior (`as_d3_ir()`)
- Approach: Direct IR structure validation
- Example: `test_that("as_d3_ir builds layers with data", {`
- Single responsibility: Verify IR layer and scale structure

**Integration Tests:**
- Scope: Not explicitly present
- Widget integration with htmlwidgets could be tested but isn't
- JavaScript rendering not tested at R level

**E2E Tests:**
- Framework: Not used
- ggplot2 → IR → D3 rendering chain not tested end-to-end
- Manual verification done via generated HTML files

## Common Patterns

**Async Testing:**
- Not applicable; R is single-threaded in this context
- No async/await patterns in testthat

**Error Testing:**
```r
# Current approach: Not explicitly tested
# Should test:
expect_error(as_d3_ir(not_a_ggplot_object), "Provide a ggplot")
expect_error(gg2d3(invalid_input), "Provide a ggplot")
```

**Setup and Teardown:**
- Not explicitly used
- Setup within each test block
- No shared fixtures or one-time setup

## Coverage

**Requirements:** Not enforced (no coverage targets in DESCRIPTION or CI config)

**View Coverage:**
```bash
# Via devtools
devtools::test_coverage()

# Or via covr
covr::package_coverage()
```

**Current Coverage:** Minimal
- 1 test covering basic `as_d3_ir()` functionality
- Major gaps:
  - No tests for `gg2d3()` widget function
  - No tests for discrete scales
  - No tests for categorical data
  - No tests for theme extraction
  - No tests for error conditions
  - No tests for edge cases (NULL, empty, NA values)
  - No tests for different geom types beyond point

**Test Execution:**
```r
# From R console during development
library(testthat)
library(gg2d3)
test_check("gg2d3")

# Or via devtools
devtools::test()
```

## Testing Gaps and Risks

**Untested Functions:**
- `gg2d3()`: Main widget entry point - not tested
- Helper functions inside `as_d3_ir()`:
  - `map_discrete()` - discrete scale mapping
  - `extract_theme_element()` - theme extraction
  - `get_scale_info()` - scale processing
  - `to_rows()` - data transformation (defined twice)

**Untested Geom Types:**
- Only point tested; bar, line, path, rect, text, area, segment, ribbon unsupported

**Untested Scale Types:**
- Only continuous tested
- Categorical/discrete scales need coverage
- Specialized scales (log, sqrt, etc.) untested

**Untested Theme Features:**
- Panel background/border
- Grid major/minor
- Axis text, ticks, titles
- Plot margins
- Text rotation/alignment

**Untested Error Paths:**
- Invalid ggplot input to `gg2d3()`
- NULL scale objects
- Malformed theme elements
- Empty data frames
- Factor handling edge cases

---

*Testing analysis: 2026-02-07*
