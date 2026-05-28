---
phase: 54
slug: geometry-polish-closure
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-28
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2 with pkgload 1.5.2 |
| **Config file** | `DESCRIPTION` (`Config/testthat/edition: 3`) |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` |
| **Renderer contract command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R"); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` |
| **Optional browser smoke command** | `rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); devtools::test()'` |
| **Estimated runtime** | ~15-45 seconds for targeted source tests; browser smoke depends on chromote startup |

---

## Sampling Rate

- **After every task commit:** Run the relevant targeted test file(s) for touched files.
- **After every plan wave:** Run the quick command plus the renderer contract command.
- **Before `$gsd-verify-work`:** Run quick command, renderer contract command, diagnostics grep, and optional browser smoke if DOM label/polygon behavior was shipped.
- **Max feedback latency:** one task commit between automated checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 0 | GEOM-01, GEOM-04 | T-54-01 | Failing-first tests require bounded label boxes and small text placement without HTML insertion | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R")'` | yes | ⬜ pending |
| 54-01-02 | 01 | 1 | GEOM-01, GEOM-04 | T-54-01 | R-side IR exposes only bounded label/text support and numeric label padding | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R")'` | yes | ⬜ pending |
| 54-01-03 | 01 | 1 | GEOM-01, GEOM-04 | T-54-01 | Labels/text use SVG `.text(...)`, not HTML insertion; renderer contracts cover selectors | unit/source contract | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` | yes | ⬜ pending |
| 54-02-01 | 02 | 0 | GEOM-02 | T-54-02 | Subgroup/hole fixtures prove ggplot2 built-data boundary without speculative IR support | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R")'` | yes | ⬜ pending |
| 54-02-02 | 02 | 1 | GEOM-02 | T-54-02 | Ordinary polygon renderer does not imply topology repair or unsupported subgroup rendering | source contract | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | yes | ⬜ pending |
| 54-03-01 | 03 | 0 | GEOM-03 | T-54-03 | Rect/tile transformed-bound fixtures compare ggplot2 built data, IR rows, and renderer/update source seams | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes | ⬜ pending |
| 54-03-02 | 03 | 1 | GEOM-03 | T-54-03 | Proven drift is fixed minimally, or no-drift evidence is recorded without broad scale/rect refactor | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes | ⬜ pending |
| 54-04-01 | 04 | 2 | GEOM-01, GEOM-02, GEOM-03, GEOM-04 | T-54-01/T-54-02/T-54-03 | User-facing diagnostics distinguish shipped support from explicit future work | docs/source | `rtk rg -n "geom_label|geom_polygon|subgroup|hole|hjust|vjust|angle|collision|path-following|rect|tile" vignettes/d3-drawing-diagnostics.md README.Rmd README.md` | yes | ⬜ pending |
| 54-04-02 | 04 | 2 | GEOM-01, GEOM-02, GEOM-03, GEOM-04 | T-54-01/T-54-02/T-54-03 | Final validation records source/renderer gates and non-primary browser smoke outcome without local artifact leakage | final gate/browser smoke | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` plus renderer contract command and optional browser smoke from this file | yes | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-text-label-polish.R` — update label/text characterization from current text-only label behavior to failing-first shipped or explicit-deferral expectations for GEOM-01 and GEOM-04.
- [ ] `tests/testthat/test-polygon-ir.R` — add focused subgroup/rule fixtures for GEOM-02.
- [ ] `tests/testthat/test-polygon-renderer.R` — either prove bounded compound-path/fill-rule support or strengthen the non-goal source contract.
- [ ] `tests/testthat/test-rect-tile-ir.R` and `tests/testthat/test-rect-tile-renderer.R` — add narrower transformed render/update evidence for GEOM-03.
- [ ] `tests/testthat/test-renderer-wiring-contracts.R` — update if ordinary label selectors, aliases, or private fields change.
- [ ] `vignettes/d3-drawing-diagnostics.md` — update shipped support and deferral language after implementation decisions.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual label-box polish | GEOM-01, GEOM-04 | Browser font metrics and `getBBox()` sizing can vary; source/DOM tests remain primary | Inspect optional visual smoke artifacts only after automated selector and IR tests pass; do not add pixel thresholds in this phase. |

---

## Threat Model

| Threat Ref | Risk | Required Mitigation | Validation |
|------------|------|---------------------|------------|
| T-54-01 | Label/text values could become script or HTML injection if renderer uses HTML insertion | Keep ordinary text and label content rendered with SVG `.text(...)`; do not introduce `.html(...)` for labels | Source tests in `test-text-label-polish.R` or renderer contract grep |
| T-54-02 | Polygon subgroup metadata could imply unsupported topology or leak private renderer fields | Preserve subgroup only with concrete bounded renderer/tests, or document it as an explicit non-goal | `test-polygon-ir.R`, `test-polygon-renderer.R`, diagnostics grep |
| T-54-03 | Invalid transformed rect/tile values could create malformed SVG attributes during render/update | Keep finite-row filtering and direct transformed-bound scaling contracts; change scale/rect math only on failing evidence | `test-rect-tile-ir.R`, `test-rect-tile-renderer.R` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for targeted source tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
