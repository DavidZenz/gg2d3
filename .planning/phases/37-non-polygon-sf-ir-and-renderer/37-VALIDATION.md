---
phase: 37
slug: non-polygon-sf-ir-and-renderer
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R `testthat` |
| **Config file** | `tests/testthat/` |
| **Quick run command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` |
| **Estimated runtime** | ~60 seconds, with browser smoke tests skipping cleanly when optional dependencies are unavailable |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `testthat::test_file(...)` command in the plan.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Full suite must be green or browser-only checks must skip cleanly with a recorded reason.
- **Max feedback latency:** 60 seconds for non-browser checks; browser checks may take longer when live Chrome is available.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 0 | SFGEOM-01, SFGEOM-02 | T-37-01 | Renderer-private geometry metadata remains internal to IR/helpers | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` | yes | pending |
| 37-01-02 | 01 | 0 | SFGEOM-04 | T-37-02 | Skipped-row diagnostics do not expose malformed geometry internals beyond existing public diagnostics | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` | yes | pending |
| 37-02-01 | 02 | 1 | SFGEOM-03 | T-37-03 | SVG renderer keeps callback data sanitized and avoids remote/runtime dependency expansion | unit/source | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 37-02-02 | 02 | 1 | SFGEOM-03 | T-37-03 | Point and line styling does not inject unsafe script/content | unit/source | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-renderer.R")'` | yes | pending |
| 37-03-01 | 03 | 2 | SFGEOM-03, SFGEOM-04 | T-37-04 | Browser smoke payloads remain public-row-oriented and private fields stay stripped | browser/source | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` | yes | pending |

*Status: pending until execution updates summaries and verification evidence.*

---

## Wave 0 Requirements

Existing test infrastructure covers all phase requirements. No new test runner installation is required.

---

## Manual-Only Verifications

All phase behaviors should have automated IR/source coverage. Live browser execution may be environment-dependent; when `chromote`, Chrome, `sf`, or `geojsonsf` are unavailable, `tests/testthat/test-sf-browser.R` must skip cleanly and leave source-level coverage intact.

---

## Validation Sign-Off

- [x] All planned task categories have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test infrastructure references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-21
