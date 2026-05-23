---
phase: 42
slug: release-validation-gate
status: passed-with-expected-skips
created: 2026-05-23
---

# Phase 42 - Gate Run Evidence

## Environment Snapshot

Commands run from repository root (`/Users/davidzenz/R/gg2d3`) on 2026-05-23:

| Command | Outcome |
|---|---|
| `rtk Rscript --version` | passed; `Rscript (R) version 4.6.0 (2026-04-24)` |
| `rtk Rscript --vanilla -e 'pkgs <- c("devtools", "testthat", "roxygen2", "chromote", "sf", "geojsonsf", "knitr", "rmarkdown"); for (pkg in pkgs) cat(pkg, if (requireNamespace(pkg, quietly = TRUE)) as.character(utils::packageVersion(pkg)) else "NOT_INSTALLED", "\n")'` | passed; package versions recorded below |
| `rtk Rscript --vanilla -e 'cat(read.dcf("DESCRIPTION")[1, "Version"])'` | passed; `0.0.0.9000` |

Package snapshot:

| Package | Version |
|---|---|
| devtools | 2.5.2 |
| testthat | 3.3.2 |
| roxygen2 | 8.0.0 |
| chromote | 0.5.1 |
| sf | NOT_INSTALLED |
| geojsonsf | 2.0.5 |
| knitr | 1.51 |
| rmarkdown | 2.31 |

Package version from `DESCRIPTION`: `0.0.0.9000`.

## Quick Gate

Command run exactly:

```bash
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'
```

Outcome: passed with expected optional skips.

Evidence:

| Test File | Outcome | Details |
|---|---|---|
| `tests/testthat/test-regression-core.R` | passed with expected optional skip | 41 passed, 1 skipped. Skip message: `{sf} cannot be loaded` at `test-regression-core.R:62:3`. This matches the expected spatial skip class for missing `sf`. |
| `tests/testthat/test-sf-browser.R` | passed with expected optional skips | 4 passed, 8 skipped. Skip message: `On CRAN` at browser smoke entry points. This matches `skip_on_cran()` as the first expected browser smoke skip gate in `42-VALIDATION-GATE.md`. |

## Full Gate

Full gate commands and outcomes:

| Command | Working Directory | Outcome | Expected Skip Or Failure | Artifact Path |
|---|---|---|---|---|
| `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` | `/Users/davidzenz/R/gg2d3` | Initial run failed: `test-interactivity.R:89:3` expected hover opacity `0.7` but actual was `0.30`; `test-theme-inheritance.R:39:3` errored with `$ operator is invalid for atomic vectors`. | Release-blocking test failures repaired below. Full-suite skips included expected missing `sf`, empty crosstalk test, and disabled visual-test context. | Local test output only. |
| `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-interactivity.R")'` | `/Users/davidzenz/R/gg2d3` | passed after repair: 54 passed. | None. | Local test output only. |
| `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-theme-inheritance.R")'` | `/Users/davidzenz/R/gg2d3` | passed after repair: 9 passed. | None. | Local test output only. |
| `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` | `/Users/davidzenz/R/gg2d3` | passed after repair with expected optional skips. | `{sf} cannot be loaded`; `On CRAN`. | Browser artifact paths remain `test_output/browser-sf/*` if live browser execution reaches artifact creation. |
| `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` | `/Users/davidzenz/R/gg2d3` | passed after first repair: 817 passed, 40 skipped, 6 warnings. | Expected skips: missing `sf`, empty crosstalk test, disabled visual-test context. | Generated docs reviewed in working tree. |
| `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` | `/private/tmp` | passed; built `gg2d3_0.0.0.9000.tar.gz`. | None. | `/private/tmp/gg2d3_0.0.0.9000.tar.gz` |
| `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz` | `/private/tmp` | Initial run failed with `1 ERROR, 1 WARNING, 4 NOTEs`. Rd usage warning and installed-package test error repaired below. | Release-blocking package-check failures repaired below. | `/private/tmp/gg2d3.Rcheck/00check.log` |
| `rtk Rscript --vanilla -e 'devtools::document()'` | `/Users/davidzenz/R/gg2d3` | passed; regenerated `man/as_d3_ir.Rd` and `man/gg2d3.Rd`. | None. | `man/as_d3_ir.Rd`, `man/gg2d3.Rd` |
| `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` | `/private/tmp` | passed; rebuilt `gg2d3_0.0.0.9000.tar.gz`. | None. | `/private/tmp/gg2d3_0.0.0.9000.tar.gz` |
| `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz` | `/private/tmp` | Second run failed with `1 ERROR, 4 NOTEs`: source-contract tests could not find installed JS module files. | Release-blocking package-check failure repaired below. | `/private/tmp/gg2d3.Rcheck/00check.log` |
| `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` | `/Users/davidzenz/R/gg2d3` | passed after repair: 82 passed, 1 expected `sf` skip. | `{sf} cannot be loaded`. | Local test output only. |
| `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'` | `/Users/davidzenz/R/gg2d3` | passed after repair: 41 passed, 1 expected `sf` skip. | `{sf} cannot be loaded`. | Local test output only. |
| `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` | `/Users/davidzenz/R/gg2d3` | final run passed: 817 passed, 40 skipped, 6 warnings. | Expected skips: missing `sf`, empty crosstalk test, disabled visual-test context. | Generated docs reviewed in working tree. |
| `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` | `/private/tmp` | final build passed; rebuilt `gg2d3_0.0.0.9000.tar.gz`. | None. | `/private/tmp/gg2d3_0.0.0.9000.tar.gz` |
| `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz` | `/private/tmp` | final check passed with 4 NOTEs and no ERROR/WARNING. Tests passed in check: `[14s/14s] OK`. | NOTEs retained as release evidence: CRAN incoming metadata/version/title, unused `jsonlite`/private ggplot2 compatibility calls, long `d3_tooltip.Rd` example line, and old HTML Tidy. | `/private/tmp/gg2d3.Rcheck/00check.log`; exact check directory `/private/tmp/gg2d3.Rcheck`. |

## Expected Optional Skips

Observed during quick gate:

| Skip | Source | Classification |
|---|---|---|
| `{sf} cannot be loaded` | `tests/testthat/test-regression-core.R` | Expected optional spatial skip because `sf` is `NOT_INSTALLED` and `42-VALIDATION-GATE.md` permits `skip_if_not_installed("sf")`. |
| `On CRAN` | `tests/testthat/test-sf-browser.R` | Expected optional browser smoke skip because `42-VALIDATION-GATE.md` lists `skip_on_cran()` as the first browser/spatial skip gate. |
| `{sf} cannot be loaded` | Full `devtools::test()` run | Expected optional spatial skip across sf IR, renderer, browser, interactivity, visual, facet, and zoom/brush tests because `sf` is `NOT_INSTALLED`. |
| `interactive() || identical(Sys.getenv("GG2D3_VISUAL_TESTS"), "true") is not TRUE` | `tests/testthat/test-date-scales.R` | Expected local visual-artifact skip for non-interactive/default visual-test context. |
| `empty test` | `tests/testthat/test-crosstalk.R` | Non-blocking testthat skip; not a browser/spatial failure. |

## Release-Blocking Repairs

### Repair 1: Hover default and ggplot2 4.x margin extraction

Original failure text:

- `Failure ('test-interactivity.R:89:3'): d3_zoom() returns valid widget Expected w$x$interactivity$hover$opacity to equal 0.7. actual: 0.30 expected: 0.70`
- `Error ('test-theme-inheritance.R:39:3'): legend background and margin are extracted Error in ir$theme$legend$margin$top: $ operator is invalid for atomic vectors`

Changed files:

- `tests/testthat/test-interactivity.R`
- `R/as_d3_ir.R`
- `tests/testthat/test-theme-inheritance.R`

Fix summary: updated the stale `d3_hover()` default expectation/test name to match the documented `0.3` default; made theme margin extraction recognize ggplot2 4.x's `ggplot2::margin` class; removed a debug `str()` call from the theme test.

Rerun result:

- `test-interactivity.R`: passed, 54 assertions.
- `test-theme-inheritance.R`: passed, 9 assertions.
- Quick gate: passed with expected optional skips.

### Repair 2: Rd usage docs and installed-package test context

Original failure text:

- `WARNING Undocumented arguments in Rd file 'as_d3_ir.Rd' 'p' 'width' 'height' 'padding'`
- `WARNING Undocumented arguments in Rd file 'gg2d3.Rd' 'width' 'height' 'elementId'`
- `ERROR ('test-theme-inheritance.R:2:1') ... devtools::load_all() ... pkgload_no_desc`

Changed files:

- `R/as_d3_ir.R`
- `R/gg2d3.R`
- `man/as_d3_ir.Rd`
- `man/gg2d3.Rd`
- `tests/testthat/test-theme-inheritance.R`

Fix summary: added missing roxygen `@param` documentation and removed the top-level `devtools::load_all()` call from the installed-package test file.

Rerun result:

- `devtools::document()`: passed and regenerated the two Rd files.
- `test-theme-inheritance.R`: passed, 9 assertions.
- Later `R CMD check` runs no longer reported the Rd usage warning or `pkgload_no_desc` error.

### Repair 3: Installed package path for JS source-contract tests

Original failure text:

- `ERROR ('test-sf-interactivity.R:114:3'): brush module deduplicates multipoint sf child selections by row_id Error: Cannot find module: inst/htmlwidgets/modules/brush.js`
- `ERROR ('test-sf-interactivity.R:124:3'): SFXDOC-01 source guards protect sf interaction selectors and payload sanitizers Error: Cannot find module: inst/htmlwidgets/modules/events.js`

Changed files:

- `tests/testthat/test-sf-interactivity.R`
- `tests/testthat/test-regression-core.R`

Fix summary: extended JS source readers to fall back to `system.file(sub("^inst/", "", path), package = "gg2d3")`, preserving repository-path behavior while allowing installed-package checks to find bundled htmlwidget modules.

Rerun result:

- `test-sf-interactivity.R`: passed, 82 assertions, 1 expected `sf` skip.
- `test-regression-core.R`: passed, 41 assertions, 1 expected `sf` skip.
- Final `R CMD check --as-cran`: passed with 4 NOTEs and no ERROR/WARNING.

## Failure Artifacts

Observed or expected artifact paths:

| Artifact Path | Status | Details |
|---|---|---|
| `test_output/browser-sf/*.html` | expected path; not created in this run | Live browser smoke skipped before fixture/failure artifact creation because optional browser/spatial gates fired. |
| `test_output/browser-sf/*-console.log` | expected path; not created in this run | Written by `write_browser_failure_artifacts()` only when live browser execution reaches a failure. |
| `test_output/browser-sf/*-page-errors.log` | expected path; not created in this run | Written by `write_browser_failure_artifacts()` only when live browser execution reaches a failure. |
| `test_output/browser-sf/*-browser-log.json` | expected path; not created in this run | Written by `write_browser_failure_artifacts()` only when live browser execution reaches a failure. |
| `/private/tmp/gg2d3.Rcheck/00check.log` | observed | Final `R CMD check --as-cran` log; final status was 4 NOTEs, no ERROR/WARNING. |
| `/private/tmp/gg2d3.Rcheck` | observed | Exact final check directory. |
| `/private/tmp/gg2d3_0.0.0.9000.tar.gz` | observed | Source package tarball built by final `R CMD build --no-manual`. |
| `README.md` | no generated diff retained | `devtools::build_readme()` did not leave a README diff. |
| `NAMESPACE` | no generated diff retained | `devtools::document()` did not leave a NAMESPACE diff. |
| `man/as_d3_ir.Rd` | generated diff retained | Updated by roxygen after adding missing `@param` docs. |
| `man/gg2d3.Rd` | generated diff retained | Updated by roxygen after adding missing `@param` docs. |

## Final Outcome

PASSED WITH EXPECTED OPTIONAL SKIPS

Final status: quick gate passed with expected optional browser/spatial skips; full R gate passed; final source package build passed; final `R CMD check --as-cran` passed with 4 NOTEs and no ERROR/WARNING after scoped repairs.

Requirement status:

| Requirement | Status | Evidence |
|---|---|---|
| VAL-01 | satisfied with expected skips | Quick and full release-gate commands are recorded with outcomes, working directories, package version, `/private/tmp` build/check artifacts, and final `R CMD check` result. |
| VAL-02 | satisfied with expected skips | Representative regression, sf/browser, full test suite, and installed-package check tests ran; missing `sf`, `skip_on_cran()`, visual-test, and empty-test skips are explicitly classified. |
| VAL-03 | satisfied | Browser smoke artifact patterns, generated docs paths, package tarball, exact `.Rcheck` directory, and `00check.log` are listed; release-blocking failures include original messages, changed files, and rerun outcomes. |
