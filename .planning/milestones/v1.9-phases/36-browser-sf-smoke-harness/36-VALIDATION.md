---
phase: 36
slug: browser-sf-smoke-harness
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-20
---

# Phase 36 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2; package requires testthat >= 3.0.0 |
| **Config file** | `DESCRIPTION` with `Config/testthat/edition: 3`; `tests/testthat.R` calls `test_check("gg2d3")` |
| **Quick run command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` |
| **Existing sf quick command** | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-visual.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::test()'` |
| **Estimated runtime** | Browser smoke: under 120 seconds when Chrome is available; skip path should complete quickly when optional dependencies are unavailable |

---

## Sampling Rate

- **After every task commit:** Run `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` when `chromote` and Chrome are available; otherwise verify clean skip output and run existing sf source tests.
- **After every plan wave:** Run `test-sf-browser.R`, `test-sf-visual.R`, `test-sf-interactivity.R`, and `test-sf-ir.R`.
- **Before `$gsd-verify-work`:** Full suite must be green, and browser smoke must either pass locally/CI or skip only for documented optional dependency absence.
- **Max feedback latency:** 120 seconds for browser smoke on a machine with Chrome.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-W0-01 | TBD | 0 | BRSF-01 | T36-03 | Browser runtime errors are captured and fail tests | browser smoke | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "DOM")'` | W0 missing | pending |
| 36-W0-02 | TBD | 0 | BRSF-02 | T36-01 | Private renderer fields are not exposed through tooltip, handler, or brush payloads | browser smoke + interaction smoke | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "fixture|interaction")'` | W0 missing | pending |
| 36-W0-03 | TBD | 0 | BRSF-03 | T36-02 | Fixture paths are deterministic and artifacts are preserved for failure diagnosis | helper/unit + browser smoke | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "artifact|skip")'` | W0 missing | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/helper-browser-sf.R` - chromote skip/session/navigation/poll/log/artifact helpers.
- [ ] `tests/testthat/test-sf-browser.R` - BRSF-01 through BRSF-03 live browser smoke assertions.
- [ ] `tests/testthat/helper-sf-fixtures.R` - optional extraction target if direct reuse of Phase 35 fixtures would duplicate code.
- [ ] Console/page error accumulation using Chrome DevTools Runtime events before fixture navigation.
- [ ] Brush gesture smoke or documented D-09 fallback when reliable automation is not feasible.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional screenshot diagnostics | BRSF-03 | Screenshots are allowed only as debugging artifacts, not pass/fail assertions | Inspect screenshot only when a browser smoke test fails and a screenshot artifact exists |

All required phase behaviors must have automated verification or a documented skip/fallback path.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 120 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-20 for planning; execution must update task statuses through summaries.
