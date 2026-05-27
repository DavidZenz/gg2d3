---
phase: 51
slug: geometry-edge-case-classification-and-polish
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 51 Validation Strategy

## Validation Architecture

Phase 51 validates geometry polish through layered evidence: ggplot2 built-data classification first, gg2d3 IR assertions second, renderer source-contract tests for JavaScript-boundary behavior third, and optional browser visual smoke as supplementary proof.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R `testthat` through `rtk Rscript --vanilla` |
| **Config file** | `DESCRIPTION`, `tests/testthat/` |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-text-label-polish.R")'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-regression-core.R")'` |
| **Estimated runtime** | ~30-120 seconds without optional browser smoke |

## Sampling Rate

- **After every task commit:** Run the relevant focused `testthat::test_file(...)` command from the task.
- **After every plan wave:** Run the full suite command above, allowing only documented optional dependency skips.
- **Before `$gsd-verify-work`:** Full suite must be green; optional browser/sf checks must pass or record explicit skip reasons.
- **Max feedback latency:** 120 seconds for source/IR tests; browser visual smoke is optional and slower.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | GEOM-01 | T-51-01 | Transformed rect/tile rows are classified before code changes. | IR/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` | existing | pending |
| 51-01-02 | 01 | 1 | GEOM-01 | T-51-02 | Renderer/update behavior is fixed only at a proven D3 boundary or deferred with evidence. | source contract | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | existing | pending |
| 51-02-01 | 02 | 1 | GEOM-02 | T-51-03 | Ordinary polygons remain grouped closed paths without topology overclaim. | IR/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | existing | pending |
| 51-03-01 | 03 | 1 | GEOM-03 | T-51-04 | Text/label polish is local and tested, or explicitly deferred. | IR/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R")'` | planned | pending |
| 51-04-01 | 04 | 2 | GEOM-01/02/03 | T-51-05 | Final support/non-goal evidence is recorded without optional skip ambiguity. | validation/docs | full suite command plus optional browser command | this file | pending |

## Wave 0 Requirements

Existing test infrastructure covers the phase. Plan 51-03 creates `tests/testthat/test-text-label-polish.R` if it does not already exist.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-rendered geometry smoke | GEOM-01, GEOM-02, GEOM-03 | Browser visual smoke is opt-in and may skip when Chrome/Chromote is unavailable. | Run `GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` when local browser launch is available. |

## Required Checks

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-regression-core.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
rtk git diff --check
```

## Pass Conditions

- GEOM-01 has focused transformed-scale rect/tile fixtures comparing ggplot2 built data, IR rows, and D3-boundary behavior.
- GEOM-02 has ordinary polygon topology/hole/subgroup classification tests and does not claim GIS topology repair.
- GEOM-03 has either one small verified text/label improvement or implementation-ready deferral evidence for larger placement features.
- Browser/sf skips are explicit and limited to optional dependency policy.
- Final execution notes record commands, outcomes, and the final geometry-polish contract.

## Known Skip Conditions

- Browser visual smoke may skip unless `GG2D3_BROWSER_VISUAL_SMOKE=true`.
- Chrome/Chromium or Chromote launch failures are acceptable only when recorded explicitly and source/IR tests have passed.
- sf annotation checks may skip when `{sf}` or `geojsonsf` is unavailable.

## Interim Execution Notes

### GEOM-01 Transformed Rect/Tile Boundary

Plan 51-01 classified transformed rect/tile bounds as ggplot2-built values already copied into the IR. The renderer and update paths currently scale those bounds directly, while `scales.js` creates transformed D3 scales from transformed IR domains for log, sqrt, and reverse scales.

That is a scale factory / axis semantics boundary, not a rect-only renderer fix. Phase 51 records this as an explicit non-goal for local rect/tile code unless a later validation pass identifies a smaller boundary. The source-contract tests in `tests/testthat/test-rect-tile-renderer.R` make this seam visible so future work can address it deliberately.

## Validation Sign-Off

- [x] All planned tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references through existing `testthat` infrastructure or planned focused files.
- [x] No watch-mode flags.
- [x] Feedback latency target defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution
