---
phase: 35
slug: geom-sf-docs-and-validation-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 35 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R testthat 3.x plus roxygen2/devtools documentation generation |
| **Config file** | `DESCRIPTION`, `tests/testthat.R` |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R", reporter = "summary")'` |
| **Full sf suite command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-visual.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` |
| **Docs generation command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` |
| **Estimated runtime** | ~60 seconds for targeted sf/docs checks when optional spatial packages are installed |

## Sampling Rate

- **After every task commit:** Run the verify command listed in that task.
- **After every plan wave:** Run the full sf suite command if tests changed; run docs generation if docs changed.
- **Before `$gsd-verify-work`:** Docs generation and the full sf suite must be green or skip only because optional spatial packages are unavailable.
- **Max feedback latency:** 90 seconds for targeted checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | SFDOC-01 | T-35-01 | Public docs accurately state polygon-family support and anti-features | docs | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` | yes | pending |
| 35-01-02 | 01 | 1 | SFDOC-01 | T-35-02 | Stale `geom_sf` unsupported language is removed or qualified | docs/source | `rtk rg -n "geom_sf.*unsupported|unsupported.*geom_sf" README.Rmd README.md vignettes man R` | yes | pending |
| 35-02-01 | 02 | 1 | SFDOC-02 | T-35-03 | Unsupported, empty, invalid, or missing sf rows do not become selectable paths | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 35-02-02 | 02 | 1 | SFDOC-02 | T-35-04 | Sf tooltip/hover/handler payloads expose public row data without renderer-private fields | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` | yes | pending |
| 35-03-01 | 03 | 2 | SFDOC-02 | T-35-05 | HTML fixtures cover single, stacked, facet_wrap, facet_grid, and skipped-row scenarios | fixture | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-visual.R")'` | yes | pending |
| 35-03-02 | 03 | 2 | SFDOC-01, SFDOC-02 | T-35-06 | Final generated docs and targeted sf suite agree with the production support contract | docs + tests | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()' && rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-visual.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` | yes | pending |

## Wave 0 Requirements

Existing R package documentation and test infrastructure covers Phase 35. No new framework is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual appearance of generated sf HTML fixtures | SFDOC-02 | Phase 35 explicitly avoids full pixel/screenshot regression infrastructure | Open generated `test_output/phase35-*.html` files and confirm polygons render for choropleth, stacked overlay, `facet_wrap()`, and `facet_grid()` fixtures. |
| Docs clarity for user expectations | SFDOC-01 | Readability and expectation-setting require human review | Read README, vignette, diagnostics doc, and help output to confirm `geom_sf` is described as polygon-family support, not full GIS/map support. |

## Validation Sign-Off

- [x] All planned task areas have automated verify commands or explicit manual-only justification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-20
