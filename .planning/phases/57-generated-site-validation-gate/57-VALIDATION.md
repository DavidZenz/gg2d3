---
phase: 57
slug: generated-site-validation-gate
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 57 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R testthat |
| **Config file** | `DESCRIPTION` (`Config/testthat/edition: 3`) |
| **Quick run command** | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::test()'` |
| **Estimated runtime** | ~60-180 seconds locally, excluding release rebuild |

## Sampling Rate

- **After every task commit:** Run the focused command for the files touched by that task.
- **After every plan wave:** Run `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'`.
- **Before `$gsd-verify-work`:** Run quick validation and `devtools::test()`.
- **Max feedback latency:** One plan wave.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | SITE-01 | T-57-01 | Test and script share one validation core. | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | yes | green |
| 57-01-02 | 01 | 1 | SITE-01 | T-57-02 | Missing markers/assets fail with exact file/path messages. | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | yes | green |
| 57-02-01 | 02 | 2 | SITE-01 | T-57-03 | Maintainers can run quick/release validation with one command. | integration | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | yes | green |
| 57-02-02 | 02 | 2 | SITE-01 | T-57-04 | CI validates generated site after build and before deploy. | config | `rtk rg -n "Validate generated pkgdown site|Rscript tools/validate-pkgdown-site.R --mode ci" .github/workflows/pkgdown.yaml` | yes | green |
| 57-03-01 | 03 | 2 | SITE-01 | T-57-05 | Maintainer diagnostics explain run, interpretation, and repair path. | docs | `rtk rg -n "validate-pkgdown-site|PKGDOWN_SF_OPTIONAL_SKIP|release mode" vignettes/d3-drawing-diagnostics.md README.Rmd` | yes | green |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI rendered-sf path | SITE-01 | Local `sf` is currently installed but not loadable because of missing GDAL dylib. | Confirm workflow or another environment with loadable `sf`/`geojsonsf` runs `--mode ci` and requires rendered sf evidence. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded by focused test/script runs.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-01

## Executed Command Evidence

| Command | Outcome |
|---------|---------|
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Passed with `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release` | Passed with `sf outcome: classified_skip`; tracked generated-site churn was limited to `README.md`. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | Passed with 42 expectations. |
| `rtk Rscript --vanilla -e 'devtools::test()'` | Passed with 2151 expectations, 6 existing warnings, and 47 expected skips. |
