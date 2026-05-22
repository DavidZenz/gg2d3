---
phase: 39
slug: package-internals-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 39 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat via Rscript |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ir.R"); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R"); testthat::test_file("tests/testthat/test-regression-core.R")'` |
| **Estimated runtime** | ~30-90 seconds, depending on optional sf packages |

## Sampling Rate

- **After every task commit:** Run the task's focused `testthat::test_file()` command.
- **After every plan wave:** Run the plan-level command listed in that plan.
- **Before verification:** Run the full suite command above.
- **Max feedback latency:** 90 seconds for automated local checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | HARD-01 | T-39-01 | N/A | unit/characterization | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R")'` | yes | pending |
| 39-01-02 | 01 | 1 | HARD-01 | T-39-01 | N/A | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R")'` | yes | pending |
| 39-01-03 | 01 | 1 | HARD-01 | T-39-01 | N/A | regression | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 39-02-01 | 02 | 2 | HARD-02 | T-39-02 | N/A | unit/characterization | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ggplot2-compat.R")'` | planned | pending |
| 39-02-02 | 02 | 2 | HARD-02 | T-39-02 | N/A | regression | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R")'` | yes | pending |
| 39-02-03 | 02 | 2 | HARD-02 | T-39-02 | N/A | regression | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R")'` | yes | pending |
| 39-03-01 | 03 | 3 | HARD-03 | T-39-03 | N/A | regression | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-regression-core.R")'` | planned | pending |
| 39-03-02 | 03 | 3 | HARD-03 | T-39-03 | N/A | regression | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` | planned | pending |
| 39-03-03 | 03 | 3 | HARD-03 | T-39-03 | N/A | full regression | Full suite command | planned | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification. Browser tests may skip in
CRAN-like Rscript contexts but are still included as optional live validation.

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity has no 3 consecutive tasks without automated verify.
- [x] Existing infrastructure covers all phase requirements.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 90 seconds for focused checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-22
