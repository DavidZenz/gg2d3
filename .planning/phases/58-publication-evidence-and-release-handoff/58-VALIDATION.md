---
phase: 58
slug: publication-evidence-and-release-handoff
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 58 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R `testthat` plus shell/`gh`/git inspection |
| **Config file** | `DESCRIPTION`, `.github/workflows/pkgdown.yaml`, `_pkgdown.yml` |
| **Quick run command** | `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` |
| **Full suite command** | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release` |
| **Estimated runtime** | quick: ~10 seconds; release: several minutes |

---

## Sampling Rate

- **After helper/script changes:** Run `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs`.
- **After docs changes:** Run `rtk Rscript --vanilla -e 'devtools::build_readme()'` and quick inspection.
- **After workflow changes:** Run `rtk rg -n "Upload pkgdown site artifact|actions/upload-artifact@v4|pkgdown-site-\\$\\{\\{ github.run_id \\}\\}|path: docs|if-no-files-found: error|retention-days: 14" .github/workflows/pkgdown.yaml`.
- **Before final verification:** Run release validation and inspect either a downloaded workflow artifact or `origin/gh-pages` checkout.
- **Max feedback latency:** quick checks should complete within 30 seconds; release/remote checks may take several minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | SITE-02 | T-58-01 | Workflow uploads pkgdown artifact only after generated-site validation | config | `rtk rg -n "Validate generated pkgdown site|Upload pkgdown site artifact|actions/upload-artifact@v4|pkgdown-site-\\$\\{\\{ github.run_id \\}\\}|path: docs" .github/workflows/pkgdown.yaml` | W0 | pending |
| 58-01-02 | 01 | 1 | SITE-02 | T-58-02 | Site-root inspector validates downloaded/deployed layout without duplicating marker contracts | integration | `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` | W0 | pending |
| 58-01-03 | 01 | 1 | SITE-02 | T-58-02 | Focused tests cover publication inspector/helper behavior | unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | W0 | pending |
| 58-02-01 | 02 | 2 | SITE-02 | T-58-03 | Maintainer docs contain CLI trigger/download and manual fallback | docs | `rtk rg -n "gh workflow run pkgdown.yaml|gh run list --workflow pkgdown.yaml|gh run download <run-id>|inspect-pkgdown-publication|origin/gh-pages" vignettes/d3-drawing-diagnostics.md README.Rmd README.md` | W0 | pending |
| 58-02-02 | 02 | 2 | SITE-03 | T-58-04 | Release messaging does not imply new renderer support | docs | `rtk rg -n "publication-surface|without implying new rendering support|not.*new rendering support" NEWS.md vignettes/d3-drawing-diagnostics.md README.Rmd` | W0 | pending |
| 58-03-01 | 03 | 3 | SITE-02, SITE-03 | T-58-05 | Final evidence maps source/build/artifact/deploy/browser/package-check outcomes without raw logs | docs | `rtk rg -n "SITE-02|SITE-03|DOCS-01|BUILD-03|workflow run|artifact|gh-pages|browser visual smoke|R CMD check|residual" .planning/phases/58-publication-evidence-and-release-handoff/58-VERIFICATION.md` | W0 | pending |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authenticated `gh` workflow trigger/download | SITE-02 | Local `gh auth status` currently reports an invalid token, and remote workflow timing depends on GitHub Actions | If auth is fixed, run the documented `gh workflow run`, `gh run list`, and `gh run download` flow. If auth remains invalid, record the blocker and use `origin/gh-pages` deploy inspection fallback. |
| Published GitHub Pages URL visual/currentness spot-check | SITE-02 | Network/publication timing can lag workflow completion | Inspect the configured URL or `origin/gh-pages` checkout and record commit SHA, site root, and inspector outcome in `58-VERIFICATION.md`. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or documented manual gates.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-01
