---
phase: 14
slug: color-fidelity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-05
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `testthat` 3.x (already established) |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'` |
| **Full suite command** | `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'` |
| **Snapshot tool** | `testthat::expect_snapshot_value(style="json2")` writing to `tests/testthat/_snaps/color/` |
| **Estimated runtime** | ~10s quick · ~30s full suite |
| **R env note** | If devtools/Makevars conflict: prefix commands with `R_MAKEVARS_USER=/tmp/empty_makevars` |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'`
- **After every plan wave:** Run `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'`
- **Before `/gsd-verify-work`:** Full suite must be green; baseline 8 pre-existing `coord_fixed`/`coord_trans` FAILs (carved out by Phase 13 D-09) must remain unchanged.
- **Max feedback latency:** ~10 seconds per task commit

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| COLOR-01 | viridis_c per-row mark hex equals `ggplot_build()` | unit/snapshot | `testthat::test_file("tests/testthat/test-color-fidelity.R")` | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | viridis_d per-row mark hex (8-hex RGBA) equals `ggplot_build()` | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | brewer (discrete fill) per-row hex parity | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | distiller per-row hex parity | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | manual (named) per-row hex parity | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | manual (unnamed) per-row hex parity | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-01 | steps/binned per-row hex parity | unit/snapshot | same | ❌ Wave 0 | ⬜ pending |
| COLOR-02 | viridis_c emits `guide.type="colorbar"` with ≥30 gradient stops | unit | extends `tests/testthat/test-ir-legends.R` | ✅ partial | ⬜ pending |
| COLOR-02 | distiller emits `guide.type="colorbar"` | unit | same | ❌ Wave 1 | ⬜ pending |
| COLOR-02 | scale_color_steps emits `guide.type="colorbar"` AND `is_steps=true` | unit | same | ❌ Wave 1 | ⬜ pending |
| COLOR-02 | colorbar IR includes `breaks`, `labels`, `na.value`, `domain`, `is_continuous` | unit | same | ❌ Wave 2 | ⬜ pending |
| COLOR-02 | renderColorbar tick count matches `length(guide$breaks)` | static/JS | string-search rendered SVG via htmlwidgets render | ❌ Wave 3 | ⬜ pending |
| D-11 | NA color row renders as `#7F7F7F` (`grey50`) | unit/snapshot | corpus snapshot test | ❌ Wave 3 | ⬜ pending |
| D-12 | dual color+fill produces 2 guides, no merge | unit/snapshot | corpus snapshot test | ❌ Wave 3 | ⬜ pending |
| D-13 | RGBA hex round-trips identically | unit/snapshot | corpus snapshot test (also covered by viridis_d) | ❌ Wave 3 | ⬜ pending |
| D-14 | manual out-of-range factor maps to `na.value` | unit/snapshot | corpus snapshot test | ❌ Wave 3 | ⬜ pending |
| Regression | v1.0 discrete legends still pass | unit | `tests/testthat/test-legends.R` | ✅ exists | ⬜ pending |
| Regression | post-Phase-13 IR-legends tests still pass | unit | `tests/testthat/test-ir-legends.R` | ✅ exists | ⬜ pending |
| JS regex | `isHexColor` accepts 4/8-digit hex | static | grep against `inst/htmlwidgets/modules/constants.js` | ❌ Wave 1 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-color-fidelity.R` — covers COLOR-01 + COLOR-02 + edge cases
- [ ] `tests/testthat/_snaps/color/` directory — snapshot artifacts (created on first run)
- [ ] `tests/testthat/helper-color.R` — shared helpers for: (a) extracting `b$data[[i]]$colour`/`fill` from ggplot_build, (b) extracting per-row colors from `ir.layers[[i]].data[[j]]`, (c) extracting colorbar guide colors/breaks/labels from `ir.guides[[k]]`, (d) `scale_obj$map(scale_obj$get_breaks())` for legend swatch reference

*No new framework/config files needed — `testthat` is already configured.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual smoothness of 30-stop gradient (viridis_c, distiller) | COLOR-02 quality | Snapshot tests assert hex stops but cannot judge perceptual banding | Render `test_output/phase14/colorbar-smooth.html` and visually confirm no banding; if visible, increase stop count and re-snapshot |
| Banded colorbar visual match for `scale_*_steps` | COLOR-02 (D-06) | Hard color stops at bin boundaries — easy to miss bin-edge alignment off-by-one in JSON | Render `test_output/phase14/steps-bar.html` and confirm band edges align with `scale$get_breaks()` |

---

## Eval Dimensions

| Dimension | Question | Pass criterion |
|-----------|----------|----------------|
| **hex-parity** | For every layer row, does the IR's `colour`/`fill` exactly equal `ggplot_build()`'s? | `identical()` per row across all corpus plots |
| **colorbar-trigger** | Does every continuous and binned color/fill scale produce `guide.type=="colorbar"`? | viridis_c, distiller, steps, binned all emit colorbar; viridis_d, brewer-discrete, manual emit `legend` |
| **colorbar-quality** | Does the colorbar IR carry `breaks`, `labels`, `na.value`, `domain`, `is_continuous`, `is_steps`? Are tick count and label strings what ggplot2 produces? | Field presence asserted via `expect_named`; tick count == `length(scale_obj$get_breaks())`; labels == `scale_obj$get_labels(...)` |
| **edge-cases** | NA, RGBA, dual scales, out-of-range manual all correct? | 4 dedicated snapshots; D-11/D-12/D-13/D-14 explicitly named |
| **regression** | Discrete legend behavior preserved? Phase 13 baseline preserved? | `test-legends.R`, `test-ir-legends.R`, `test-ir-scales.R` all pass; `[ FAIL 8 | PASS 551+N ]` where N is new tests |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (test-color-fidelity.R, helper-color.R, _snaps/color/ dir)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter once planner finishes

**Approval:** pending
