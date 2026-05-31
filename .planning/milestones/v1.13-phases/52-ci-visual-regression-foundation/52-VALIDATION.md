---
phase: 52
slug: ci-visual-regression-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 52 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3, chromote browser execution, GitHub Actions workflow source checks |
| **Config file** | `DESCRIPTION` with `Config/testthat/edition: 3`; `.github/workflows/browser-visual-smoke.yaml` created in this phase |
| **Quick run command** | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| **Full suite command** | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| **Estimated runtime** | ~5 seconds for default skip path; browser path depends on chromote/Chrome availability |

---

## Sampling Rate

- **After every task commit:** Run the quick command or a source/helper assertion command named in the task.
- **After every plan wave:** Run all completed plan verification commands for that wave.
- **Before `$gsd-verify-work`:** Run quick skip path, source/workflow/doc checks, and the full CI-equivalent command where browser dependencies are available.
- **Max feedback latency:** 10 seconds for default skip/source checks; browser artifact path is dependency-bound.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | CI-01, CI-02, CI-03 | T-52-01, T-52-02 | CI mode fails browser-level skips while local/default runs still skip | source/unit | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); source("tests/testthat/helper-browser-visual.R"); stopifnot(is.function(browser_visual_ci_mode))'` | yes | pending |
| 52-01-02 | 01 | 1 | CI-02, CI-03 | T-52-02 | Report rows expose status, artifacts, reasons, and metadata without pixel comparisons | source/unit | `rg -n "browser_visual_report_metadata|validate_browser_visual_rows|GG2D3_BROWSER_VISUAL_CI|github_sha|screenshot_path" tests/testthat/helper-browser-visual.R tests/testthat/test-browser-visual-smoke.R` | yes | pending |
| 52-02-01 | 02 | 2 | CI-01, CI-02 | T-52-03 | Dedicated workflow opts in, proves browser availability, and uploads ignored artifacts | workflow/source | `rg -n "pull_request|workflow_dispatch|GG2D3_BROWSER_VISUAL_SMOKE|GG2D3_BROWSER_VISUAL_CI|actions/upload-artifact|test_output/browser-visual-smoke" .github/workflows/browser-visual-smoke.yaml` | no W0 | pending |
| 52-03-01 | 03 | 3 | CI-01, CI-02, CI-03 | T-52-04 | Maintainer docs describe CI/local inspection, troubleshooting, and pixel deferral | docs/source | `rg -n "Browser visual smoke artifacts|CI|CHROMOTE_CHROME|pixel|test_output/browser-visual-smoke|GG2D3_BROWSER_VISUAL_CI" vignettes/d3-drawing-diagnostics.md` | yes | pending |
| 52-03-02 | 03 | 3 | CI-01, CI-02, CI-03 | T-52-01, T-52-03 | Final checks prove requirements are covered without generated artifacts or forbidden stacks | source/test | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `.github/workflows/browser-visual-smoke.yaml` — missing at phase start, created in Plan 02.

Existing infrastructure covers helper/test/doc source files.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inspect uploaded CI artifact bundle | CI-02 | GitHub artifact UI is outside local testthat execution | After a workflow run, open the uploaded `browser-visual-smoke` artifact and confirm `index.html`, `index.json`, per-fixture HTML/PNG/DOM/browser-log files, and metadata are present. |
| Confirm browser-available CI run | CI-01, CI-03 | Local sandbox may not match GitHub-hosted runner browser availability | Run the GitHub Actions workflow manually or on a PR and confirm browser-level skips fail while explicit optional spatial skips are recorded. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 10 seconds for default skip/source checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
