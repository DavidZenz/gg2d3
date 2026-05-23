---
phase: 42
slug: release-validation-gate
status: draft
created: 2026-05-23
---

# Phase 42 - Release Validation Gate

## Purpose

This document defines the local release validation contract for VAL-01, VAL-02, and VAL-03. It gives maintainers a quick local gate for day-to-day confidence, a full release gate for release evidence, the expected optional skip semantics, the behavior coverage map, and the artifact paths to inspect when validation fails.

## Quick Local Gate

Run this gate from the repository root:

```bash
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'
```

This quick tier covers the bounded release-surface regression matrix and the browser smoke source/artifact contract. Browser and spatial checks may skip when optional local tooling is absent, provided the skip message is explicit.

## Full Release Gate

Run this sequence for release evidence. Read the tarball version from `DESCRIPTION` before the `R CMD check` command:

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'
rtk Rscript --vanilla -e 'cat(read.dcf("DESCRIPTION")[1, "Version"])'
cd /private/tmp
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Replace gg2d3_0.0.0.9000.tar.gz with the package version printed from DESCRIPTION when the version changes.

## Expected Optional Skips

The quick and full gates preserve this optional browser and spatial skip order from `tests/testthat/helper-browser-sf.R`:

1. `skip_on_cran()`
2. `skip_if_not_installed("chromote", "0.5.1")`
3. `skip_if_not_installed("sf")`
4. `skip_if_not_installed("geojsonsf")`
5. `Chrome/Chromium not available for chromote sf smoke tests`
6. `chromote session launch unavailable:`

Missing optional browser/spatial tooling is expected skip evidence, not a release failure, when the skip message is explicit.

## Coverage Matrix

| Behavior Area | Requirement | Command Or Gate | Primary Test Or Source | Expected Optional Skip | Failure Artifact |
|---|---|---|---|---|---|
| Representative non-sf plots | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R` | None expected | testthat failure output |
| polygon/point/line geom_sf families | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-renderer.R` | `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")` | testthat failure output |
| Facets | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R`, `tests/testthat/test-facets.R`, `tests/testthat/test-facet-grid.R` | Browser facet smoke rows may skip on optional browser/spatial tooling | `test_output/browser-sf/*.html` when browser smoke reaches live rendering |
| Legends | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R`, `tests/testthat/test-legends.R` | None expected | testthat failure output |
| Dates | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R`, `tests/testthat/test-date-scales.R` | Visual artifact checks may skip in non-interactive or unavailable visual-test contexts | README and testthat failure output |
| coord_flip | VAL-02 | Quick Local Gate and `devtools::test()` in the Full Release Gate | `tests/testthat/test-regression-core.R`, `tests/testthat/test-coord-flip.R`, `tests/testthat/test-date-scales.R` | None expected | testthat failure output |
| Browser smoke DOM rendering | VAL-01, VAL-02, VAL-03 | Quick Local Gate and browser smoke portion of `devtools::test()` | `tests/testthat/test-sf-browser.R`, `tests/testthat/helper-browser-sf.R` | `skip_on_cran()`, `skip_if_not_installed("chromote", "0.5.1")`, `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, Chrome/chromote launch messages | `test_output/browser-sf/*.html`, `test_output/browser-sf/*-console.log`, `test_output/browser-sf/*-page-errors.log`, `test_output/browser-sf/*-browser-log.json` |
| Browser smoke interaction payloads | VAL-01, VAL-02, VAL-03 | Quick Local Gate and browser smoke portion of `devtools::test()` | `tests/testthat/test-sf-browser.R`, `tests/testthat/helper-browser-sf.R` | `skip_on_cran()`, `skip_if_not_installed("chromote", "0.5.1")`, `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, Chrome/chromote launch messages | `test_output/browser-sf/*.html`, `test_output/browser-sf/*-console.log`, `test_output/browser-sf/*-page-errors.log`, `test_output/browser-sf/*-browser-log.json` |
| Package documentation generation | VAL-01, VAL-03 | First command in the Full Release Gate | `README.Rmd`, `README.md`, `man/`, `NAMESPACE` | None expected | `README.md`, `man/*.Rd`, and `NAMESPACE` diffs after documentation generation |
| R CMD check output | VAL-01, VAL-03 | Build/check commands in the Full Release Gate | `DESCRIPTION`, `*.Rcheck/` | Optional browser/spatial tests may skip with explicit messages inside check logs | `/private/tmp/gg2d3_*.Rcheck/00check.log` |

## Failure Artifacts

- `test_output/browser-sf/*.html` for saved browser smoke widgets and failure copies.
- `test_output/browser-sf/*-console.log` for browser console output.
- `test_output/browser-sf/*-page-errors.log` for JavaScript exception output.
- `test_output/browser-sf/*-browser-log.json` for structured browser smoke logs.
- `/private/tmp/gg2d3_*.Rcheck/00check.log` for package check summaries.
- `README.md`, `man/*.Rd`, and `NAMESPACE` diffs after documentation generation.

Browser smoke artifacts are local debugging evidence under ignored paths. Inspect them locally and redact logs before sharing outside the release-validation context.

## Debugging Failed Gates

### Browser Smoke Debugging

When browser smoke validation fails after the optional gates pass, inspect the local browser artifacts before changing renderer code:

- `test_output/browser-sf/*.html` for the saved widget fixture or failure copy.
- `test_output/browser-sf/*-console.log` for browser console output.
- `test_output/browser-sf/*-page-errors.log` for JavaScript exception output.
- `test_output/browser-sf/*-browser-log.json` for structured browser smoke logs.

If live browser validation skips, first confirm the skip message matches one of the expected optional skip contracts: `Chrome/Chromium not available for chromote sf smoke tests` or `chromote session launch unavailable:`. Matching optional skip messages are not release failures; different browser errors should be treated as release-gate failures and debugged from the artifact paths above.

### Package Check Debugging

For package-check failures, inspect `/private/tmp/gg2d3_*.Rcheck/00check.log` first. Rebuild the package from the repository root, then rerun the check from `/private/tmp`:

```bash
rtk Rscript --vanilla -e 'cat(read.dcf("DESCRIPTION")[1, "Version"])'
cd /private/tmp
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Replace `gg2d3_0.0.0.9000.tar.gz` with the version built from `DESCRIPTION`.

### Documentation Debugging

For documentation-generation failures or unexpected generated diffs, rerun:

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

Then inspect diffs in `README.md`, `NAMESPACE`, and `man/*.Rd`.

### Test Failure Debugging

For release-surface test failures, start with the failing test file named in the output and compare it to the coverage matrix above. The primary release-gate test files are `test-regression-core.R`, `test-sf-browser.R`, `test-sf-ir.R`, `test-sf-renderer.R`, `test-facets.R`, `test-facet-grid.R`, `test-legends.R`, `test-date-scales.R`, and `test-coord-flip.R`.

## Phase 42 Evidence Files

- `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md` records the maintainer-facing command and interpretation contract.
- `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` records execution evidence when the full release gate is run.
- `.planning/phases/42-release-validation-gate/42-VERIFICATION.md` records final Phase 42 verification evidence.

## Out Of Scope

- New scripts, package dependencies, or hidden release wrappers.
- Node/browser automation stacks such as Playwright, Puppeteer, or Selenium.
- screenshot diff or pixel diff infrastructure.
- Renderer feature work or broad parity fixes.
