---
phase: 33
slug: single-panel-renderer-and-interactivity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 33 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R testthat |
| **Config file** | `DESCRIPTION`, `tests/testthat.R` |
| **Quick run command** | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` |
| **Full suite command** | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` |
| **Estimated runtime** | ~20 seconds when optional spatial packages are installed |

## Sampling Rate

- **After every task commit:** Run the quick command for the touched behavior.
- **After every plan wave:** Run the full Phase 33 targeted suite.
- **Before `$gsd-verify-work`:** Phase 33 targeted suite must be green or skip only because optional spatial packages are unavailable.
- **Max feedback latency:** 30 seconds for targeted checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | SFREND-01 | T-33-01 | Renderer keeps row/path identity and finite centroid attrs | unit/source | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 33-01-02 | 01 | 1 | SFINTR-01 | T-33-02 | Tooltips and hover target `path.geom-sf` without leaking private fields | unit/source | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` | W0 creates | pending |
| 33-02-01 | 02 | 2 | SFINTR-02 | T-33-03 | Brush selection uses sf centroids only | unit/source | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` | yes | pending |
| 33-02-02 | 02 | 2 | SFINTR-02 | T-33-02 | Brush callback data omits sf renderer internals | unit/source | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` | yes | pending |
| 33-03-01 | 03 | 3 | SFINTR-03 | T-33-04 | `d3_zoom()` warns and suppresses zoom on sf widgets | unit | `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-zoom-brush.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers the phase. Plan 01 creates `tests/testthat/test-sf-interactivity.R` before later plans append checks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-rendered sf hover/tooltip feel | SFREND-01, SFINTR-01 | No headless htmlwidgets DOM harness exists in this repo yet | Render the NC sf visual fixture and confirm polygon paths display, hover dims peers, and tooltip content excludes `_geom`/`_centroid`. |
| Brush UX over polygon centroids | SFINTR-02 | Automated checks guard the code branch; visual confirmation verifies interaction feel | Open an sf widget with `d3_brush()` and confirm selections correspond to polygon centroids rather than bbox edges. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual-only justification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-20
