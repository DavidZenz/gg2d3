---
phase: 53
slug: renderer-and-ir-contract-consolidation
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 53 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2, edition 3 |
| **Config file** | `DESCRIPTION` with `Config/testthat/edition: 3` |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_dir("tests/testthat")'` |
| **Estimated runtime** | ~20-90 seconds for focused tests, longer for full suite depending on optional skips |

---

## Sampling Rate

- **After every task commit:** Run the focused quick command, or the single affected test file when a task changes only one track.
- **After every plan wave:** Run the quick command plus any adjacent affected tests named in the plan.
- **Before `$gsd-verify-work`:** Focused contract/helper tests must pass. Browser visual smoke should run or skip with documented opt-in behavior unless CI-equivalent artifact validation is explicitly requested.
- **Max feedback latency:** 90 seconds for focused source-level contract feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 0 | ARCH-01, ARCH-03 | T-53-01 | Renderer-private fields remain internal and contract drift is detected before release. | source/unit | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` | yes | green |
| 53-02-01 | 02 | 0 | ARCH-02 | T-53-02 | IR helper extraction preserves representative serialized behavior. | unit/characterization | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'` | yes | green |
| 53-03-01 | 03 | 1 | ARCH-01, ARCH-02, ARCH-03 | T-53-03 | Maintainers can inspect the remaining architecture boundary without overclaiming generated contracts or full modularization. | docs/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-renderer-wiring-contracts.R` - failing-first coverage for module path/load order, render selectors, explicit exception shape, and actionable failure messages.
- [x] `tests/testthat/test-ir-helper-boundaries.R` - failing-first or characterization coverage for theme extraction and geom parameter routing seams.
- [x] Existing testthat infrastructure covers all phase requirements; no new test framework is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional browser visual smoke artifact review | ARCH-01, ARCH-03 | Browser visual smoke is an opt-in downstream confidence check, not the primary Phase 53 contract gate. | Run or confirm documented skip for `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'`. If opting in, set `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true` and inspect the generated artifact index. |

## Executed Evidence

- `tests/testthat/test-renderer-wiring-contracts.R` passed in the combined Phase 53 quick gate with 594 passes.
- `tests/testthat/test-ir-helper-boundaries.R` passed in the combined Phase 53 quick gate with 65 passes and 2 expected `{sf}` skips.
- `tests/testthat/test-browser-visual-smoke.R` exited 0 with the expected opt-in skip: set `GG2D3_BROWSER_VISUAL_SMOKE=true` to generate browser visual smoke artifacts.
- Diagnostics string checks passed for `vignettes/d3-drawing-diagnostics.md`, including `geom-contracts.js`, `test-renderer-wiring-contracts.R`, `publicData.sanitizeDatum`, `as_d3_ir()`, FUT-03, FUT-04, golden screenshots, and pixel thresholds.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing contract and helper-boundary references.
- [x] No watch-mode flags.
- [x] Feedback latency target is below 90 seconds for focused tests.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-28
