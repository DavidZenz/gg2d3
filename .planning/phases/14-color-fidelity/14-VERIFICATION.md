---
phase: 14-color-fidelity
verified: 2026-05-07T00:00:00Z
verifier: claude-opus-4-7
verdict: PASS
confidence: HIGH
status: passed
score: 4/4 roadmap success criteria · 2/2 requirements · 10/10 pitfalls · 17/17 decisions
test_suite:
  pass: 631
  fail: 8
  skip: 13
  baseline_fails_unchanged: true
  baseline_fail_files: [test-geoms-phase5.R, test-ir.R]
re_verification: false
---

# Phase 14: Color Fidelity — Verification Report

**Phase Goal:** ggplot2 color and fill scales (viridis, brewer, manual) render in D3 with the exact colors ggplot2 produces, and continuous color legends render as a true colorbar gradient.
**Verdict:** PASS
**Confidence:** HIGH

The codebase, tests, and snapshot baselines all line up with the SUMMARYs. Goal-backward inspection confirms COLOR-01 and COLOR-02 are closed, all 10 RESEARCH pitfalls are addressed in code, all 17 CONTEXT decisions are honored or explicitly deferred, and the test suite is at its expected end-state (631 PASS / 8 baseline FAIL / 13 SKIP). The Checkpoint-C inline horizontal-colorbar fix is captured in the SUMMARY, the commit (`d531ea7`), and the live `inst/htmlwidgets/modules/legend.js` source. Three manual visual checkpoints (A snapshot review, B vertical, C horizontal) were approved.

---

## ROADMAP Success Criteria → Plan / Commit / Evidence

| # | Success Criterion | Closing Plan | Commit | Code / Test Evidence |
|---|-------------------|--------------|--------|----------------------|
| 1 | viridis_c marks: DOM hex matches `ggplot_build()` exactly | 14-04 (passthrough) + 14-07 (snapshot) | `e2e45b6`, `5360a11`, `a1b93aa` | `tests/testthat/_snaps/color-fidelity.md:1` block "viridis_c per-row mark hex equals ggplot_build"; `expect_identical(ir, build)` per row in `test-color-fidelity.R` |
| 2 | brewer + scale_fill_manual round-trip identical hex | 14-07 | `5360a11`, `a1b93aa` | `_snaps/color-fidelity.md:71` (brewer), `:201` (scale_fill_manual) — literal hex values match `ggplot_build()` |
| 3 | Continuous color renders as colorbar gradient (not discrete keys) | 14-03 (route binned) + 14-05 (enrich IR) + 14-06 (renderer) | `bf82eab`, `5cf65e2`, `43bfcab`, `d531ea7` | `R/ir_legends.R:62-63` widens detection to `ScaleBinned`; `renderColorbar` in `legend.js:456+` produces gradient + ticks; visual checkpoints B and C approved |
| 4 | v1.0 discrete legends still render (no regression) | (no change) | n/a | `test-legends.R` and `test-ir-legends.R` green throughout phase; suite final 631/8/13 with same `coord_fixed` baseline FAILs |

---

## COLOR-01 Evidence — exact-string hex parity

- `R/ir_layers.R` lines 15 + 93 still reference `"colour"` column (Pitfall 6 invariant intact).
- Dead `colorScale`/`cdesc` masking fallback removed: `grep -cE 'cdesc|colorScale' inst/htmlwidgets/gg2d3.js` = 0.
- `makeColorAccessors` simplified to deterministic `isValidColor → convertColor` (per 14-04 SUMMARY).
- `isHexColor` regex widened to accept `#RRGGBBAA` (8-hex) and `#RGBA` (4-hex): `inst/htmlwidgets/modules/constants.js:190` matches `[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8}`.
- 12 snapshot baselines lock per-row hex against `ggplot_build()`: `tests/testthat/_snaps/color-fidelity.md` contains all 12 expected blocks (verified by `grep -c '^# '` = 12). Snapshots include viridis_c, viridis_d (8-hex RGBA), brewer, distiller, manual×2, scale_fill_manual, scale_color_steps, plus D-11..D-14 edge cases.

## COLOR-02 Evidence — colorbar legend (gradient + ticks), not discrete keys

- `R/ir_legends.R:62` widens `is_continuous` to include `ScaleBinned` so binned scales hit the colorbar branch.
- `R/ir_legends.R:106-180` enriches `guide_spec` with: `breaks`, `labels`, `na.value`, `domain`, `is_continuous`, `bin_colors`, `orientation`, `legend_position` (8 new fields, all driven by `scale_obj` accessors).
- `inst/htmlwidgets/modules/legend.js:456-572` `renderColorbar` consumes `guide.breaks`/`guide.labels`/`guide.domain`/`guide.is_steps`/`guide.bin_colors`/`guide.orientation`. Horizontal vs vertical branches at `legend.js:487, 548`; banded vs smooth gradient via `guide.is_steps` predicate.
- D-10 horizontal colorbar polish present in source: `barWidth = isHorizontal ? 12 * defaults.keySize : defaults.keySize` (`legend.js:460`); orientation-aware `estimateLegendDimensions` at `legend.js:168`; out-of-domain tick filter at `renderColorbar` tick loop.
- Visual Checkpoints B (vertical) and C (horizontal) approved per 14-07 SUMMARY.

---

## Pitfall Closure Table (RESEARCH.md §Pitfalls 1–10)

| # | Pitfall | Status | Evidence |
|---|---------|--------|----------|
| 1 | `isHexColor` rejects 8-digit RGBA | CLOSED | `constants.js:190` regex now `{3,4}|{6}|{8}`; commit `3f123a2` |
| 2 | `extract_legends_ir` misses `ScaleBinned` | CLOSED | `ir_legends.R:62` adds `ScaleBinned` to `inherits()`; commit `bf82eab` |
| 3 | `ir.scales.color.type` always categorical (misleading) | CLOSED | `scales$color` block deleted from `R/ir_scales.R`; `expect_null(ir$scales$color)` test added; commit `e2e45b6` |
| 4 | Colorbar IR carries no `breaks`/`labels`/`na.value`/`is_steps` | CLOSED | All 8 fields added in `ir_legends.R:106-180`; commit `5cf65e2` |
| 5 | `renderColorbar` uses key positions, not domain | CLOSED | Tick loop now uses `(b - d0) / range`; consumes `guide.breaks`/`labels`/`domain`; commit `43bfcab` |
| 6 | Per-row colour passthrough is correct (no-op pitfall) | CONFIRMED | `R/ir_layers.R` lines 15 + 93 still present (verified), no change required |
| 7 | Dead `colorScale` in `gg2d3.js` | CLOSED | `grep -cE 'cdesc|colorScale' inst/htmlwidgets/gg2d3.js` = 0; commit `e2e45b6` |
| 8 | `scale_*_steps` defaults to `guide_coloursteps`, banded | CLOSED | `is_steps` flag emitted; banded gradient in `renderColorbar` (2 stops per bin from `bin_colors`); commits `bf82eab`, `5cf65e2`, `43bfcab` |
| 9 | `na.value` not rendered as separate swatch (matches ggplot2; no-op) | CONFIRMED | No swatch added; `na.value` carried in IR for D-11 row rendering only |
| 10 | RColorBrewer "n too large" warnings are noise | CONFIRMED | No suppression added; suite remains green with warnings unchanged |

---

## Decision Closure Table (CONTEXT.md D-01..D-17)

| # | Decision | Status | Evidence |
|---|----------|--------|----------|
| D-01 | Three concrete gaps: hex parity, colorbar trigger, colorbar quality | CLOSED | All three covered (Plans 14-04, 14-03, 14-05/06) |
| D-02 | Researcher produces defect list before planner | CLOSED | RESEARCH.md §Pitfalls 1–10 |
| D-03 | "Identical hex" = char-for-char string equality | CLOSED | `expect_identical(ir, build)` in test-color-fidelity.R |
| D-04 | Truth source = `ggplot_build()` resolved column | CLOSED | `helper-color.R::build_colours/build_fills` use this exactly |
| D-05 | In-scope scales: viridis_c/d, brewer, distiller, manual×2, steps/binned | CLOSED | All 7 scales in snapshot corpus |
| D-06 | Steps render as banded colorbar | CLOSED | `bin_colors` field + 2-stops-per-bin renderer; `_snaps/color-fidelity.md:231` |
| D-07 | gradient/gradient2/gradientn defer unless free | DEFERRED (acknowledged) | Not in corpus; viridis_c uses gradient infrastructure so partially exercised |
| D-08 | Ticks come from `scale_obj$get_breaks()/get_labels()`, not d3-axis | CLOSED | `ir_legends.R:131-138` |
| D-09 | 30-stop gradient sampling kept | CLOSED | `ir_legends.R:125` `length.out = 30`; no banding observed in Checkpoint B |
| D-10 | Title, vertical default, horizontal when legend.position top/bottom | CLOSED | Orientation logic in `ir_legends.R`; horizontal branch in `legend.js`; Checkpoint C approved after polish |
| D-11 | NA → `na.value` (default `grey50`) | CLOSED | `_snaps/color-fidelity.md:276` D-11 block; `na.value` field on IR |
| D-12 | Both color+fill scales = 2 guides, no merge | CLOSED | `_snaps/color-fidelity.md:296` D-12 block |
| D-13 | RGBA alpha bytes round-trip | CLOSED | `_snaps/color-fidelity.md:326` D-13 block; isHexColor 8-hex support |
| D-14 | Out-of-range manual factor → `na.value` | CLOSED | `_snaps/color-fidelity.md:346` D-14 block |
| D-15 | Snapshot artifact under `_snaps/color/` | CLOSED (with format deviation) | testthat 3.x flattened to single `_snaps/color-fidelity.md` (12 blocks); equivalent baseline; documented in 14-07 SUMMARY |
| D-16 | One geom per scale variant; ~7-8 base + 4 edges | CLOSED | 8 base + 4 edge = 12 blocks present |
| D-17 | DOM-walk extraction, snapshot committed, accept-required | CLOSED | `helper-color.R::ir_layer_colours/ir_layer_fills` walk IR layer data; baseline committed (`a1b93aa`) |

---

## Code Audits

| Audit | Expected | Actual | Status |
|-------|----------|--------|--------|
| `grep -c '\[0-9a-f\]\{4\}\|\[0-9a-f\]\{8\}' inst/htmlwidgets/modules/constants.js` | ≥ 1 | 1 (line 190) | PASS |
| `grep -c 'ScaleBinned' R/ir_legends.R` | ≥ 2 | 3 (lines 59, 62, 63) | PASS |
| `grep -c 'is_steps' R/ir_legends.R` | ≥ 2 | 3 (lines 63, 146, 173) | PASS |
| `grep -nE 'guide.orientation|isHorizontal' inst/htmlwidgets/modules/legend.js` | horizontal branch present | 6 hits incl. `legend.js:168, 456, 460, 461, 487, 548` | PASS |
| `grep -n 'breaks\|labels\|na.value\|domain\|bin_colors' R/ir_legends.R` | enrichment present | All 5 fields present in colorbar branch | PASS |
| `grep -cE 'cdesc\|colorScale' inst/htmlwidgets/gg2d3.js` | 0 | 0 | PASS |
| `tests/testthat/_snaps/color-fidelity.md` | exists, 12 blocks | exists, 12 blocks (`grep -c '^# '` = 12) | PASS |

---

## Test Suite State

```
PASS = 631   FAIL = 8   SKIP = 13
Failed files: test-geoms-phase5.R, test-ir.R
```

The 8 FAILs are the documented Phase-13 baseline (`coord_fixed`/`coord_trans` carve-outs from Phase 13 D-09). Identical count and identical files. No new regressions.

Color-fidelity-specific:
- `test-color-fidelity.R` flipped from 20 skip-pending stubs to 19 real passing tests (1 stub remains for downstream; per 14-07 numbers).
- `test-ir-legends.R` and `test-legends.R` green (regression baseline preserved).
- `test-ir-scales.R` green (Pitfall 3+7 deletion test added in 14-04).

---

## Manual-Checkpoint Sign-Off

| Checkpoint | Subject | Status | Captured in SUMMARY |
|-----------|---------|--------|---------------------|
| A | Snapshot review (12 blocks) before `snapshot_accept` | APPROVED | 14-07 SUMMARY §Task 3 |
| B | Vertical colorbar (smooth viridis_c + banded steps) | APPROVED | 14-07 SUMMARY §Task 6 |
| C | Horizontal colorbar (`legend.position="bottom"`) | APPROVED on second pass after layout polish | 14-07 SUMMARY §Task 7 + §Deviations |

---

## Inline-Fix Deviation Note

**`d531ea7` — fix(14-07): horizontal colorbar layout polish (D-10)** is the documented Rule-3 inline fix made during Checkpoint C. It is correctly captured in `14-07-SUMMARY.md` §Deviations and produces three changes confirmed live in `inst/htmlwidgets/modules/legend.js`:

1. `barWidth = 12 * keySize` (was `5 * keySize`) — `legend.js:460`.
2. `estimateLegendDimensions` colorbar branch reads `guide.orientation` and reserves height for horizontal vs width for vertical — `legend.js:168+`.
3. Tick filter drops breaks with `proportion < 0 || proportion > 1` to suppress `pretty()` ticks outside domain — within `renderColorbar` tick loop.

Suite still 631/8/13 after the fix; reviewer approved on second pass.

---

## Unresolved Items

None.

- All 4 ROADMAP success criteria verified.
- Both COLOR-01 and COLOR-02 closed.
- All 10 pitfalls closed or explicitly confirmed as no-ops (6, 9, 10).
- All 17 CONTEXT decisions closed; D-07 (gradient/gradient2/gradientn) explicitly deferred per its own text.
- D-15 has a documented format deviation (single `_snaps/color-fidelity.md` instead of per-plot JSONs) accepted by the executor; functionally equivalent.

---

*Verified: 2026-05-07*
*Verifier: Claude (gsd-verifier) · model claude-opus-4-7*
