---
phase: 32
slug: geom-sf-ir-foundation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat |
| **Config file** | `tests/testthat.R`, `DESCRIPTION` (`Config/testthat/edition: 3`) |
| **Quick run command** | `testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~30-90 seconds depending on sf package load time |

---

## Sampling Rate

- **After every task commit:** Run the quick sf helper/IR test command for the files touched by that task.
- **After every plan wave:** Run `devtools::test()` if local optional spatial dependencies are installed; otherwise record skipped sf tests explicitly.
- **Before `$gsd-verify-work`:** Quick sf helper/IR tests must be green or explicitly skipped only because optional spatial packages are unavailable.
- **Max feedback latency:** 90 seconds for quick tests when `sf` and `geojsonsf` are installed.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | SFIR-01/SFIR-03 | T-32-01 | Unsupported geometry handling does not silently misrepresent skipped data | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | SFIR-02/SFIR-03 | T-32-02 | Missing CRS is visible to users and does not trigger browser reprojection | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ✅ | ⬜ pending |
| 32-02-01 | 02 | 2 | SFIR-01/SFIR-03 | T-32-03 | Filtered IR preserves source row identity and geometry/data alignment | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | ✅ | ⬜ pending |
| 32-02-02 | 02 | 2 | SFIR-02 | T-32-04 | IR exposes bbox/CRS diagnostics without adding JS reprojection | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `tests/testthat/test-sf-utils.R` exists
- [x] `tests/testthat/test-sf-ir.R` exists
- [x] `sf` and `geojsonsf` tests already use `skip_if_not_installed()` guards
- [x] `devtools::test()` is the existing full-suite command

---

## Manual-Only Verifications

All Phase 32 behaviors have automated verification. Browser/manual map validation is deferred to Phase 33+.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target < 90 seconds for quick tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-20
