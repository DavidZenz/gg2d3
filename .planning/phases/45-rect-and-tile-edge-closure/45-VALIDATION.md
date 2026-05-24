---
phase: 45
slug: rect-and-tile-edge-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 45 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R testthat 3.x |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` |
| **Optional browser command** | `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-browser.R")'` |
| **Estimated runtime** | 5-30 seconds for IR/source tests; browser smoke depends on chromote/Chrome availability |

---

## Sampling Rate

- **After every task commit:** Run the relevant new `test-rect-tile-*.R` file for the touched behavior.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Full suite must be green; optional browser smoke must pass or skip cleanly with an explicit optional-dependency/browser message.
- **Max feedback latency:** 30 seconds for non-browser checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | RECT-01 | T-45-01 / T-45-02 | N/A - renderer classification only | unit / characterization | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` | W0: `tests/testthat/test-rect-tile-ir.R` | pending |
| 45-01-02 | 01 | 1 | RECT-01 | T-45-01 / T-45-02 | N/A - source/DOM contract only | source contract / optional DOM | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | W0: `tests/testthat/test-rect-tile-renderer.R` | pending |
| 45-02-01 | 02 | 2 | RECT-02 | T-45-03 / T-45-04 | Renderer preserves intended panel clipping and does not expose malformed rect geometry | unit / source / optional DOM | Full suite command plus optional browser command when included | W0 from Plan 01 | pending |
| 45-02-02 | 02 | 2 | RECT-02 | T-45-05 | Diagnostics record whether the deferred item was fixed or verified as a non-issue | docs check | `rg -n "rect|tile|out-of-bounds|Phase 45" vignettes/d3-drawing-diagnostics.md .planning/phases/45-rect-and-tile-edge-closure` | Existing docs | pending |

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-rect-tile-ir.R` - fixture matrix for scale limits, `coord_cartesian()` limits, discrete `geom_tile()` grids, reversed scales, `coord_flip()`, and facets.
- [ ] `tests/testthat/test-rect-tile-renderer.R` - source contract for `inst/htmlwidgets/modules/geoms/rect.js` and `inst/htmlwidgets/modules/geom-registry.js`.
- [ ] `tests/testthat/test-rect-tile-browser.R` - optional DOM smoke only if execution determines source/IR tests cannot prove representative visible clipping.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | RECT-01, RECT-02 | Phase 45 should close through automated IR/source tests and optional DOM smoke. | If browser smoke cannot run locally, it must skip cleanly with explicit optional-dependency/browser messaging. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references from research.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 30 seconds for non-browser checks.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and are wired into plan verification.

**Approval:** pending
