---
phase: 36-browser-sf-smoke-harness
verified: 2026-05-21T08:47:05Z
status: passed
requirements: [BRSF-01, BRSF-02, BRSF-03]
automated_checks:
  passed: 3
  failed: 0
  browser_skips: 4
review_warnings: 2
---

# Phase 36 Verification: Browser sf Smoke Harness

## Goal

Developers can repeatedly validate live browser sf rendering before expanding geometry support.

## Result

Passed. Phase 36 adds a browser-oriented `geom_sf` smoke harness around the Phase 35 polygon fixture matrix, live DOM contracts, browser runtime error capture, deterministic fixture artifacts, and runtime interaction payload checks.

## Requirement Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| BRSF-01: automated browser smoke tests assert live DOM `path.geom-sf` nodes, non-empty path data, row ids, finite anchor attributes, and no page or console errors | Passed | `tests/testthat/test-sf-browser.R` asserts fixture path counts, `d`, `data-row-id`, `data-cx`, `data-cy`, and calls `assert_no_browser_errors()` after navigation. `tests/testthat/helper-browser-sf.R` captures `Runtime.consoleAPICalled` and `Runtime.exceptionThrown`. |
| BRSF-02: browser smoke tests cover polygon regressions for choropleths, stacked overlays, facets, skipped rows, payload sanitization, centroid brushing, and sf zoom suppression | Passed | `tests/testthat/helper-sf-fixtures.R` centralizes the six Phase 35 sf fixtures. `tests/testthat/test-sf-browser.R` covers choropleth, stacked overlay, facet wrap, facet grid, skipped rows, tooltip/handler sanitization, centroid brush payloads, and `d3_zoom()` suppression. |
| BRSF-03: fixture generation uses non-self-contained htmlwidgets output, skips cleanly when optional dependencies are unavailable, and leaves useful failure artifacts | Passed | `tests/testthat/helper-sf-fixtures.R` and `tests/testthat/helper-browser-sf.R` save non-self-contained widgets under deterministic `test_output` paths, guard optional browser/spatial dependencies, and write browser failure logs under `test_output/browser-sf`. |

## Automated Checks

The following checks were run after implementation:

```text
rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'
```

Result: 0 failures, 4 passes, 4 clean skips. The skips are the intended CRAN-style browser skip path.

```text
rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-interactivity.R")'
```

Result: 57 passes.

```text
rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-visual.R")'
```

Result: 64 passes.

Schema drift check:

```text
rtk gsd-sdk query verify.schema-drift 36
```

Result: valid, no issues, 3 plans checked.

## Review Notes

The required Phase 36 code review completed and found two advisory warnings, neither blocking the phase goal:

- `pkgload` and `rprojroot` are used in test helpers but are not listed in `DESCRIPTION` `Suggests`.
- The facet panel-count smoke assertion sorts counts, so it validates distribution but not panel identity.

These are suitable follow-ups for `$gsd-code-review-fix 36`.

## Residual Risk

The current automation run exercised the CRAN-compatible clean-skip path for live browser tests. To exercise the live Chrome path locally, run the browser smoke file in an environment where `skip_on_cran()` does not skip and `chromote`, Chrome, `sf`, and `geojsonsf` are available.

## Conclusion

Phase 36 achieved its stated goal. The package now has a repeatable browser smoke harness for existing polygon-family sf behavior before Phase 37 expands geometry support.
