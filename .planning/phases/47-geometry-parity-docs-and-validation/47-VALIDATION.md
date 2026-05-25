---
phase: 47
slug: geometry-parity-docs-and-validation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 47 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2, roxygen2 8.0.0, devtools 2.5.2 |
| **Config file** | `DESCRIPTION` with `Config/testthat/edition: 3` and `Config/roxygen2/version: 8.0.0` |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::test()'` |
| **Docs generation command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` |
| **Estimated runtime** | Focused checks under a few minutes; full suite varies with optional browser/spatial skips |

---

## Sampling Rate

- **After every task commit:** Run the focused command for the geometry area or docs surface touched by the task.
- **After every plan wave:** Run docs regeneration plus the stale-claim grep across source and generated docs.
- **Before `$gsd-verify-work`:** Representative geometry checks must pass or skip explicitly, and generated docs must be synchronized.
- **Max feedback latency:** Prefer under 5 minutes for focused checks; avoid watch-mode commands.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-doc-source | 01 | 1 | DOCVAL-01 | T-47-01 | Public docs do not expose private renderer fields or stale unsupported claims | docs grep | `rtk rg -n 'does not currently have a D3 renderer|no renderer is registered|geom_sf_text\\(\\).*not supported|geom_sf_label\\(\\).*not supported' README.Rmd README.md vignettes R man` | yes | pending |
| 47-01-generate | 01 | 1 | DOCVAL-01 | T-47-02 | Generated README/help are derived from sources, not manual-only edits | docs generation | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` | yes | pending |
| 47-02-polygon | 02 | 1 | DOCVAL-01 | T-47-03 | Polygon evidence documents sanitized public payload and supported grouped-path contract | unit/source/browser optional | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` | yes | pending |
| 47-02-rect-tile | 02 | 1 | DOCVAL-01 | T-47-04 | Rect/tile evidence documents classified edge behavior without overclaiming transformed-scale parity | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes | pending |
| 47-02-sfann | 02 | 1 | DOCVAL-01 | T-47-05 | sf annotation evidence documents projected-anchor support and skips optional spatial/browser dependencies cleanly | unit/source/browser optional | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'` | yes | pending |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 47 should create the planned validation evidence artifact during execution, not before planning.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Generated docs diff inspection | DOCVAL-01 | Generated files may change unrelated formatting; a maintainer should confirm source-first changes produced expected help/README updates | Inspect `git diff -- README.md man/*.Rd` after `devtools::document(); devtools::build_readme()` |
| Optional browser smoke interpretation | DOCVAL-01 | Local machines may lack `sf`, `chromote`, or Chrome; skips need interpretation rather than failing the phase | Record pass/skip outcome for `test-polygon-browser.R` and `test-sf-annotations-browser.R`, including skipped dependency reason |

---

## Validation Sign-Off

- [x] All tasks have automated or explicit manual verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 5 minutes for focused checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-25
