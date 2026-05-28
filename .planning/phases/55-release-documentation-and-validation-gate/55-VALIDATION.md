---
phase: 55
slug: release-documentation-and-validation-gate
status: executing
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-28
---

# Phase 55 - Validation Strategy

> Per-phase validation contract for release documentation and validation-gate closure.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x, devtools, roxygen2, chromote browser smoke, and base `R CMD build/check` |
| **Config file** | `DESCRIPTION` (`Config/testthat/edition: 3`, `Config/roxygen2/version`) |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R"); testthat::test_file("tests/testthat/test-text-label-polish.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` |
| **Release check command** | From `/private/tmp`: `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` then `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz` |
| **Estimated runtime** | Focused gates: under 2 minutes; full test/docs gate: several minutes; `R CMD check`: longer release gate |

---

## Sampling Rate

- **After every task commit:** Run `rtk git diff --check` and the narrowest doc/source grep or focused test for touched files.
- **After every plan wave:** Run the focused v1.13 source gates and documentation-generation check.
- **Before `$gsd-verify-work`:** Full suite, browser smoke behavior, package build/check, and all-requirements evidence map must be recorded.
- **Max feedback latency:** Keep task-level feedback under 2 minutes when possible; reserve `R CMD check` for release-gate task/final validation.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | REL-01 | T-55-01 | Public docs do not overclaim unsupported parity or leak local artifacts. | docs/source | `rtk rg -n "v1.13|browser visual|geom_label|geom_polygon|rect|tile|geom-contracts|FUT-" README.Rmd README.md vignettes/gg2d3.Rmd vignettes/d3-drawing-diagnostics.md R/gg2d3.R man/gg2d3.Rd NEWS.md` | yes | pending |
| 55-01-02 | 01 | 1 | REL-01 | T-55-01 | Generated docs derive from source docs. | docs/generated | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` | yes | pending |
| 55-02-01 | 02 | 2 | REL-02 | T-55-02 | Focused v1.13 source gates pass before release gate. | source/tests | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R"); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes | green |
| 55-02-02 | 02 | 2 | REL-02 | T-55-02 | Full package tests, optional skips, and docs generation are recorded. | package/tests | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` | yes | green |
| 55-02-03 | 02 | 2 | REL-02 | T-55-03 | Browser visual smoke pass/skip/CI artifact evidence is explicit. | browser/artifact | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` plus CI/artifact evidence when feasible | yes | green |
| 55-02-04 | 02 | 2 | REL-02 | T-55-04 | Package build/check evidence is from a source tarball outside the repo root. | release/check | `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` and `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz` from `/private/tmp` | yes | green |
| 55-03-01 | 03 | 3 | REL-03 | T-55-01 | `NEWS.md` summarizes support and risks without raw local logs. | docs/source | `rtk rg -n "v1.13|browser visual|R CMD check|test_output/browser-visual-smoke|FUT-01|FUT-06|geom_label|geom_polygon|rect|tile" NEWS.md` | yes | pending |
| 55-04-01 | 04 | 4 | REL-01, REL-02, REL-03 | T-55-05 | Final evidence maps every v1.13 requirement to source, tests, docs, and gate results. | planning/evidence | `rtk rg -n "CI-01|ARCH-01|GEOM-01|REL-01|REL-02|REL-03" .planning/phases/55-release-documentation-and-validation-gate/55-VERIFICATION.md .planning/phases/55-release-documentation-and-validation-gate/55-GATE-RUN.md` | no W0 | pending |

*Status: pending, green, red, skipped*

---

## Wave 0 Requirements

- Existing testthat, devtools, roxygen2, browser visual, and package-check infrastructure covers Phase 55.
- `55-GATE-RUN.md` must be created during execution to record release-gate commands, outcomes, generated artifact paths, and optional skip behavior.
- `55-VERIFICATION.md` must be created during final validation to map all v1.13 requirements to evidence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser artifact inspection, if live GitHub artifact refresh is unavailable | REL-02 | `gh` authentication may be invalid locally, so existing downloaded artifact evidence may need human-readable confirmation. | Inspect or summarize the existing `test_output/github-run-26575140296/browser-visual-smoke-26575140296/` artifact index, or record the fresh run ID if `gh` works during execution. |
| Package-check NOTE classification | REL-02 | CRAN-style NOTEs can be environment-dependent and require maintainer judgement. | Record ERROR/WARNING as blockers. Summarize retained NOTEs without broad cleanup unless they are release-blocking. |

---

## Validation Sign-Off

- [x] All planned tasks have automated verify commands or explicit manual-only evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 uses existing infrastructure; no new validation dependency is required.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
