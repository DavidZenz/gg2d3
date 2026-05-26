---
phase: 50
slug: renderer-wiring-and-interaction-contracts
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 50 Validation Strategy

## Validation Architecture

Phase 50 validates JavaScript renderer wiring through source-level contract tests first, then existing interactivity regression tests, then optional browser visual smoke.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R `testthat` through `Rscript --vanilla` |
| **Config file** | `DESCRIPTION`, `tests/testthat/` |
| **Quick run command** | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` |
| **Full suite command** | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-path-datum.R"); testthat::test_file("tests/testthat/test-regression-core.R")'` |
| **Estimated runtime** | ~30-90 seconds without optional browser smoke |

## Sampling Rate

- **After every task commit:** Run the quick contract test when it exists.
- **After every plan wave:** Run the full interactivity/source contract suite.
- **Before `$gsd-verify-work`:** Full suite must be green or skip only for missing optional dependencies.
- **Max feedback latency:** 90 seconds for source tests; browser smoke is optional confidence.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | ARCH-02 | T-50-01 | Supported renderer names are represented in the contract. | source contract | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` | W0 existing test infra | pending |
| 50-01-02 | 01 | 1 | ARCH-02 | T-50-02 | Update selectors are contract-covered or explicitly excluded. | source contract | same as above | W0 existing test infra | pending |
| 50-02-01 | 02 | 2 | ARCH-02 | T-50-03 | Events and brush selectors are contract-covered. | source contract | same as above | W0 existing test infra | pending |
| 50-02-02 | 02 | 2 | ARCH-02 | T-50-04 | Crosstalk selector differences are intentional and tested. | source contract | same as above | W0 existing test infra | pending |
| 50-03-01 | 03 | 3 | ARCH-03 | T-50-05 | Public tooltip/event/brush payloads strip private fields. | source contract | same as above | W0 existing test infra | pending |
| 50-03-02 | 03 | 3 | ARCH-03 | T-50-06 | Polygon and sf annotation private fields remain internal. | regression | full suite command above | W0 existing test infra | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase adds `tests/testthat/test-renderer-wiring-contracts.R` during Plan 01 as the focused contract suite.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-rendered smoke confidence | ARCH-02, ARCH-03 | Browser smoke is opt-in and may skip when Chromote/browser dependencies are unavailable. | Run `GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` when local browser launch is available. |

## Required Checks

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-path-datum.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

## Pass Conditions

- `geom-contracts.js` exists and is loaded by `gg2d3.yaml` before consumers.
- Every supported registered geom is represented by the contract.
- Every expected update selector is present in `geom-registry.js` or has an explicit exclusion reason.
- Events, brush, and crosstalk selector coverage is derived from or validated against contract metadata.
- Tooltip, event callbacks, Shiny event payloads, and brush callback payloads use a shared sanitizer or are contract-tested to omit underscore-prefixed fields.
- Polygon and sf annotation private fields are covered by tests.

## Known Skip Conditions

- sf checks may skip only when `sf` or `geojsonsf` is unavailable.
- Browser visual smoke may skip unless `GG2D3_BROWSER_VISUAL_SMOKE=true`.
- Chromote launch failures are acceptable only when the skip/error clearly names browser launch unavailability and source-level tests have passed.

## Validation Sign-Off

- [x] All tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references through existing `testthat` infrastructure.
- [x] No watch-mode flags.
- [x] Feedback latency target defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-26
