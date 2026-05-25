---
phase: 46
slug: sf-text-and-label-annotations
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 46 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | testthat |
| Config file | `tests/testthat.R`, `DESCRIPTION` |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'` |
| Full suite command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'` |
| Optional browser command | `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'` |
| Estimated runtime | Under 60 seconds for source/IR tests; browser smoke depends on chromote/Chrome startup |

## Sampling Rate

- After every task commit: run the task-specific `testthat::test_file()` command from its plan.
- After every plan wave: run all Phase 46 non-browser test files created so far.
- Before `$gsd-verify-work`: run the full non-browser Phase 46 command plus optional browser smoke when the file exists.
- Browser smoke must skip cleanly when optional spatial/browser dependencies are unavailable.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | SFANN-01 | T-46-01 | Unsupported, empty, invalid, or missing geometries are skipped with diagnostics. | IR | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'` | W0 | pending |
| 46-01-02 | 01 | 1 | SFANN-01 | T-46-02 | sf annotation IR keeps data/geometries parallel and validates sf-like structures. | IR/source | same as 46-01-01 plus `test-validate-ir.R` as needed | W0 | pending |
| 46-02-01 | 02 | 2 | SFANN-02 | T-46-03 | Renderers place text/label marks from projected anchors using panel `sf_bbox`. | source/DOM | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R")'` | W0 | pending |
| 46-03-01 | 03 | 3 | SFANN-03 | T-46-04 | Public tooltip/handler/brush payloads strip private geometry/anchor fields. | source/browser | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'` | W0 | pending |
| 46-03-02 | 03 | 3 | SFANN-01,SFANN-02,SFANN-03 | T-46-05 | Optional browser smoke proves representative DOM placement and interaction without screenshots. | browser | `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'` | W0 | pending |

## Wave 0 Requirements

- `tests/testthat/test-sf-annotations-ir.R` - IR and diagnostics tests for SFANN-01.
- `tests/testthat/test-sf-annotations-renderer.R` - source/renderer tests for SFANN-02.
- `tests/testthat/test-sf-annotations-interactivity.R` - source/interactivity tests for SFANN-03.
- `tests/testthat/test-sf-annotations-browser.R` - optional chromote DOM smoke when Plan 46-03 creates it.

## Manual-Only Verifications

All required Phase 46 behaviors should have automated IR/source/DOM coverage. Manual browser inspection may be useful for local sanity, but it is not a required gate and must not replace automated assertions.

## Validation Sign-Off

- [x] All plans have automated verification commands.
- [x] Sampling continuity has no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all new Phase 46 test files.
- [x] No watch-mode flags.
- [x] No screenshot or perceptual-diff gate.
- [x] Browser smoke remains optional and CRAN-compatible.

Approval: planned 2026-05-25

