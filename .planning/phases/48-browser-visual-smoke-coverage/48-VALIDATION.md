---
phase: 48
slug: browser-visual-smoke-coverage
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 48 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3, plus optional chromote browser execution |
| **Config file** | `DESCRIPTION` with `Config/testthat/edition: 3` |
| **Quick run command** | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| **Full suite command** | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| **Estimated runtime** | ~5 seconds for default skip path; browser path depends on local Chrome/chromote availability |

---

## Sampling Rate

- **After every task commit:** Run `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'`
- **After every plan wave:** Run the quick command plus existing browser smoke probes for polygon/sf where relevant.
- **Before `$gsd-verify-work`:** Full visual-smoke command should produce artifacts or explicit dependency skip/report rows.
- **Max feedback latency:** 10 seconds for default skip path; browser artifact path may be longer and dependency-bound.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | VIS-01, VIS-03 | T-48-01 | Generated artifacts stay under ignored `test_output/browser-visual-smoke/` | unit/source | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | No W0 | pending |
| 48-01-02 | 01 | 1 | VIS-01 | T-48-02 | Browser DOM summary JS remains static and fixture-controlled | unit/source | same quick command | No W0 | pending |
| 48-02-01 | 02 | 1 | VIS-02 | T-48-02 | Fixture IDs cover required surfaces without global sf dependency | source/browser smoke | same quick command; full command when local browser works | No W0 | pending |
| 48-03-01 | 03 | 2 | VIS-01, VIS-03 | T-48-01 | Maintainer docs expose opt-in command without committing local paths/artifacts | docs/source | `rg -n "GG2D3_BROWSER_VISUAL_SMOKE|browser-visual-smoke" vignettes tests` | No W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/helper-browser-visual.R` - shared artifact directory, screenshot, DOM summary, report, and status helpers for VIS-01/VIS-03.
- [ ] `tests/testthat/test-browser-visual-smoke.R` - opt-in representative fixture matrix for VIS-01/VIS-02/VIS-03.
- [ ] `test_output/browser-visual-smoke/index.html` and `test_output/browser-visual-smoke/index.json` - generated local report outputs, ignored by git.
- [ ] Maintainer-facing documentation containing the exact quick and full visual-smoke commands.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inspect rendered screenshots for visual plausibility | VIS-01, VIS-02 | Phase 48 intentionally avoids pixel thresholds and committed goldens | Run the full visual-smoke command, open `test_output/browser-visual-smoke/index.html`, and inspect linked screenshots/HTML/logs |
| Confirm skip behavior on machines missing optional dependencies | VIS-03 | Local dependency availability varies by machine | Run the quick command without `GG2D3_BROWSER_VISUAL_SMOKE=true`; confirm output skips cleanly and no committed artifacts appear |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 10 seconds for the default skip path.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
