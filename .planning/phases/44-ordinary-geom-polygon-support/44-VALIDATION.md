---
phase: 44
slug: ordinary-geom-polygon-support
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x with optional chromote browser smoke coverage |
| **Config file** | `tests/testthat.R`; browser helpers under `tests/testthat/helper-browser-sf.R` and related helpers |
| **Quick run command** | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::test()'` |
| **Estimated runtime** | ~60-180 seconds locally; browser smoke may skip cleanly when optional browser tooling is unavailable |

---

## Sampling Rate

- **After every task commit:** Run the smallest relevant `testthat::test_file(...)` command for files changed by the task.
- **After every plan wave:** Run the quick run command above, plus any newly added polygon interactivity/browser file.
- **Before `$gsd-verify-work`:** `rtk Rscript --vanilla -e 'devtools::test()'` must pass or show only documented optional browser/spatial skips.
- **Max feedback latency:** 3 minutes for non-browser checks; browser smoke may take longer but must skip explicitly when unavailable.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | POLY-01 | T-44-01 | No user callback payload receives renderer-private fields | unit | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-ir.R")'` | W0 | pending |
| 44-01-02 | 01 | 1 | POLY-01 | T-44-01 | No user callback payload receives renderer-private fields | unit | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-ir.R")'` | W0 | pending |
| 44-02-01 | 02 | 2 | POLY-02 | T-44-02 | Renderer emits finite path geometry and no executable user data | source/unit | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | W0 | pending |
| 44-02-02 | 02 | 2 | POLY-02 | T-44-02 | Renderer emits finite path geometry and no executable user data | source/unit | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | W0 | pending |
| 44-03-01 | 03 | 3 | POLY-03 | T-44-03 | Tooltip, handler, crosstalk, and brush payloads remain sanitized | source/unit | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` | W0 | pending |
| 44-03-02 | 03 | 3 | POLY-03 | T-44-03 | Tooltip, handler, crosstalk, and brush payloads remain sanitized | browser | `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | W0 | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 44 plans may add new test files as part of implementation:

- [ ] `tests/testthat/test-polygon-ir.R` — ordinary polygon IR grouping, order, facets, styling fixtures.
- [ ] `tests/testthat/test-polygon-renderer.R` — polygon renderer registration/source contract and closed path behavior.
- [ ] `tests/testthat/test-polygon-interactivity.R` — selector and sanitized payload source contracts.
- [ ] `tests/testthat/test-polygon-browser.R` — optional browser DOM smoke for representative polygon marks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | POLY-01, POLY-02, POLY-03 | All Phase 44 behaviors have planned automated IR, source, or browser DOM checks | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-24
