# Phase 40 Optional Skip Audit

## Browser Skip Gate

`tests/testthat/helper-browser-sf.R` centralizes live browser smoke gating in `skip_browser_sf_smoke()` with this order:

1. `testthat::skip_on_cran()`
2. `testthat::skip_if_not_installed("chromote", "0.5.1")`
3. `testthat::skip_if_not_installed("sf")`
4. `testthat::skip_if_not_installed("geojsonsf")`
5. `chromote::find_chrome()`
6. `chromote::ChromoteSession$new(width = 10, height = 10)`

The Chrome absence message is `Chrome/Chromium not available for chromote sf smoke tests`.
The launch failure message starts with `chromote session launch unavailable:`.

`tests/testthat/test-sf-browser.R` calls `skip_browser_sf_smoke()` at each live browser smoke test entry point. Helper code such as `.browser_sf_assert_interaction_payloads()` can construct `sf::` objects internally, but its live test callers invoke `skip_browser_sf_smoke()` before using the helper.

## Spatial Skip Gate

Non-browser sf test files retain direct spatial package skips:

- `tests/testthat/test-sf-ir.R` starts with `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")` before top-level `sf::st_read()`.
- `tests/testthat/test-sf-renderer.R` starts with `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")` before top-level `sf::st_read()`.
- `tests/testthat/test-sf-utils.R` gates individual tests with `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and `skip_if_not_installed("rnaturalearth")` before constructing optional spatial objects.

The audited source checks found no non-browser sf fixture/test path that requires Chrome before running source-level IR or renderer assertions.

## Non-Browser Coverage

Source-level and IR sf tests remain independent of live Chrome execution:

- `tests/testthat/test-sf-ir.R` covers sf IR extraction and geometry family behavior.
- `tests/testthat/test-sf-renderer.R` covers renderer-side source contracts.
- `tests/testthat/test-sf-utils.R` covers R helper behavior and optional spatial edge cases.

Phase 40 keeps Node, Playwright, Puppeteer, Selenium, screenshot-diff, pixel diff, and visual diff tooling out of scope. Browser coverage remains the existing optional R/testthat/chromote smoke harness.

## Required Changes

No helper changes required. The existing helper already preserves the required skip order and diagnostic messages, and non-browser sf tests continue to skip optional spatial packages directly without depending on Chrome.
