---
phase: 34
slug: stacked-and-faceted-projection-alignment
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 34 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R testthat |
| **Config file** | `DESCRIPTION`, `tests/testthat.R` |
| **Quick run command** | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R")'` |
| **Full suite command** | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R")'` |
| **Estimated runtime** | ~30 seconds when optional spatial packages are installed |

## Sampling Rate

- **After every task commit:** Run the verify command listed in that task.
- **After every plan wave:** Run the full Phase 34 targeted suite.
- **Before `$gsd-verify-work`:** Phase 34 targeted suite must be green or skip only because optional spatial packages are unavailable.
- **Max feedback latency:** 45 seconds for targeted checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | SFREND-02 | T-34-01 | Shared `sf_bbox` spans all accepted sf layers in the panel | unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R")'` | yes | pending |
| 34-01-02 | 01 | 1 | SFREND-02, SFREND-03 | T-34-02 | `sf_bbox` is panel-keyed and validates without Cartesian ranges | unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-ir.R")'` | yes | pending |
| 34-02-01 | 02 | 2 | SFREND-02 | T-34-03 | `sf.js` fits from shared panel bbox when available | source/unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 34-02-02 | 02 | 2 | SFREND-03 | T-34-04 | Faceted JS filters sf geometries with filtered data | source/unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 34-03-01 | 03 | 3 | SFREND-03 | T-34-05 | `facet_wrap()` sf panels fit from their own rows only | unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-facets.R")'` | yes | pending |
| 34-03-02 | 03 | 3 | SFREND-03 | T-34-06 | `facet_grid()` preserves layout and empty panels do not use global bbox fallback | unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-facet-grid.R")'` | yes | pending |

## Wave 0 Requirements

Existing R/testthat infrastructure covers all Phase 34 requirements. No new test framework is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual overlay alignment in browser | SFREND-02 | Automated IR/source tests prove contract; visual browser QA remains Phase 35 scope | Render a stacked sf overlay widget and confirm borders/fills share the same map frame. |
| Visual facet map fit | SFREND-03 | No headless htmlwidgets DOM harness exists yet | Render facet wrap/grid fixtures and confirm each panel uses its own map extent. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual-only justification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-20
