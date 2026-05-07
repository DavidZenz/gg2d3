---
phase: 14-color-fidelity
plan: 07
subsystem: testing
tags: [r-package, ggplot2, color, snapshots, colorbar, viridis, brewer, manual]

requires:
  - phase: 14-color-fidelity
    provides: "rgba-hex regex (14-02), binned colorbar routing + is_steps (14-03), dead colorScale removed (14-04), enriched colorbar IR with breaks/labels/orientation (14-05), breaks-driven renderColorbar (14-06)"
provides:
  - "12 snapshot baselines covering 8 base + 4 edge-case scale variants"
  - "Per-row hex identity assertions vs ggplot_build (D-03/D-04)"
  - "scale_fill_manual coverage (literal ROADMAP success criterion 2)"
  - "End-to-end visual verification of vertical and horizontal colorbar (D-10)"
  - "Horizontal colorbar layout polish (bar width, orientation-aware dimensions, out-of-domain tick filter)"
affects: [phase-15-secondary-axes, phase-16-robustness, phase-18-docs]

tech-stack:
  added: []
  patterns:
    - "expect_snapshot_value(style='json2') for per-row hex + legend metadata baselines"
    - "ggplot_build() as char-for-char source of truth for color resolution"
    - "Three-checkpoint visual confirmation pattern (snapshot review + vertical render + horizontal render)"

key-files:
  created:
    - "tests/testthat/_snaps/color-fidelity.md"
  modified:
    - "tests/testthat/test-color-fidelity.R"
    - "inst/htmlwidgets/modules/legend.js"

key-decisions:
  - "testthat 3.x flattened snapshots into _snaps/color-fidelity.md (single file, 12 blocks) rather than _snaps/color/*.json — equivalent baseline, simpler review"
  - "Horizontal colorbar barWidth raised from 5*keySize to 12*keySize to match ggplot2 default"
  - "estimateLegendDimensions made orientation-aware so horizontal layout reserves correct height/width"
  - "Tick filter drops breaks with proportion <0 or >1 to suppress out-of-domain pretty() ticks (e.g., 50/350 vs hp range 52..335)"

patterns-established:
  - "Snapshot review checkpoint before snapshot_accept() prevents committing wrong baselines"
  - "Visual checkpoint immediately after snapshot accept catches layout bugs that hex-equality cannot"
  - "Orientation-aware legend sizing: read guide.orientation in both render and dimension-estimate paths"

requirements-completed: [COLOR-01, COLOR-02]

duration: ~2h (across multiple checkpoint cycles)
completed: 2026-05-07
---

# Phase 14 Plan 07: Snapshot Corpus Summary

**12-snapshot baseline locking ggplot2 color/fidelity hex parity (8 base scales + 4 edge cases) plus end-to-end visual confirmation of vertical and horizontal colorbar rendering, with three inline horizontal-layout fixes folded in.**

## Performance

- **Duration:** ~2h (multi-checkpoint, spans Checkpoints A/B/C)
- **Started:** 2026-05-06
- **Completed:** 2026-05-07
- **Tasks:** 7/7
- **Files modified:** 3 (1 test source, 1 snapshot baseline, 1 JS module)

## Accomplishments

- 12 `test_that` blocks in `tests/testthat/test-color-fidelity.R` flipped from `skip()` stubs to real per-row identity + snapshot assertions.
- 12 snapshot blocks captured in `tests/testthat/_snaps/color-fidelity.md` covering: viridis_c, viridis_d, brewer, distiller, scale_color_manual (named + unnamed), **scale_fill_manual** (literal ROADMAP success criterion 2), scale_color_steps, plus edge cases D-11 (NA → grey50), D-12 (dual color+fill, no merge), D-13 (8-hex RGBA round-trip), D-14 (out-of-range manual → na.value).
- `expect_identical(ir_col, build_col)` passes for all 12 corpus plots — char-for-char hex parity with `ggplot_build()`.
- Vertical colorbar (smooth viridis_c + banded scale_color_steps) visually verified — no banding on smooth, clean band edges on stepped.
- Horizontal colorbar (D-10, `theme(legend.position="bottom")`) visually verified — gradient runs left-to-right, ticks below, title above.
- Suite final state: **631 PASS / 8 baseline FAIL (unchanged from phase 13) / 13 SKIP**. Phase-13 baseline FAILs untouched; `test-legends.R` and `test-ir-legends.R` remain green.

## Task Commits

1. **Task 1: Base-corpus per-row hex parity (8 scale variants)** — `5360a11` (test)
2. **Task 2: Edge-case corpus D-11/D-12/D-13/D-14** — `21fd6cf` (test)
3. **Task 3: Checkpoint A — snapshot review** — approved (no commit; review-only)
4. **Task 4: Accept snapshots and commit baseline** — `a1b93aa` (test)
5. **Task 5: Render manual-verification HTML artifacts** — no commit (gitignored `test_output/`)
6. **Task 6: Checkpoint B — vertical colorbar visual** — approved
7. **Task 7: Checkpoint C — horizontal colorbar visual** — approved after layout-polish fix
8. **Inline fix during Checkpoint C: horizontal colorbar layout polish** — `d531ea7` (fix)

**Plan metadata commit:** _this commit_ (docs).

## Files Created/Modified

- `tests/testthat/test-color-fidelity.R` — 12 skip-pending blocks replaced with real assertions (~220 net lines added).
- `tests/testthat/_snaps/color-fidelity.md` — new baseline file with 12 snapshot blocks (365 lines, ~30 lines per block).
- `inst/htmlwidgets/modules/legend.js` — three horizontal-layout fixes (see Deviations below).

## Decisions Made

- Snapshot format: testthat 3.x produced a single consolidated `_snaps/color-fidelity.md` rather than 12 separate JSON files. Functionally equivalent — each `expect_snapshot_value` call still asserts char-for-char baseline equality. Plan referenced `_snaps/color/*.json`; actual on-disk layout is the testthat default.
- Horizontal colorbar `barWidth` of `12*keySize` chosen to match ggplot2's default horizontal `legend.key.width`. The previous `5*keySize` was carried over from vertical layout and rendered far too narrow.
- Out-of-domain tick filter applied at the `renderColorbar` tick-build step rather than upstream in IR enrichment, because `pretty()`-derived breaks legitimately exist in the IR; rendering is where the visual constraint applies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking layout bugs] Horizontal colorbar layout polish**

- **Found during:** Task 7 (Checkpoint C — horizontal colorbar visual review).
- **Issue:** Three layout defects reported by reviewer when opening `test_output/phase14/colorbar-horizontal.html`:
  1. Horizontal gradient bar far too narrow (`5*keySize` carried over from vertical default).
  2. Tick labels overflowed legend bounding box because `estimateLegendDimensions` was hardcoded for vertical orientation.
  3. Ticks rendered past the bar edges because `pretty()` produced breaks (50, 100, …, 350) outside the actual `hp` domain (52..335).
- **Fix (committed as `d531ea7`):**
  1. `renderColorbar` horizontal branch: `barWidth = 12 * keySize` (was `5 * keySize`).
  2. `estimateLegendDimensions` colorbar branch made orientation-aware — reads `guide.orientation` and reserves height for horizontal (`bar + tick + label + title`) vs width for vertical.
  3. Tick filter in `renderColorbar`: drop breaks where `proportion < 0 || proportion > 1` (i.e., outside the `[domain_min, domain_max]` window).
- **Files modified:** `inst/htmlwidgets/modules/legend.js` (3 hunks, 43 lines net).
- **Verification:**
  - Re-ran full suite: **631 PASS / 8 baseline FAIL (unchanged) / 13 SKIP** — no regressions.
  - Re-rendered `test_output/phase14/colorbar-horizontal.html`; reviewer approved on second pass: bar wide, gradient left→right purple→yellow, ticks below at sensible domain positions, title above.
- **Committed in:** `d531ea7` (`fix(14-07): horizontal colorbar layout polish (D-10)`).

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking task completion of Checkpoint C).
**Impact on plan:** Required for D-10 horizontal colorbar acceptance. The plan correctly identified D-10 as in-scope (Checkpoint C explicit), and these fixes complete that contract. No scope creep — all three changes are layout corrections to code introduced by plans 14-05 and 14-06.

## Issues Encountered

- Snapshot directory layout differed from plan's prediction (`_snaps/color/*.json` vs actual `_snaps/color-fidelity.md`). Resolved by accepting testthat's default and updating documentation expectations — no behavior change.
- During Checkpoint A review the reviewer cross-checked that viridis_d snapshots contained 8-hex RGBA (`#......FF`), `scale_fill_manual` contained the three named hex values verbatim, and D-11 contained `grey50`/`#7F7F7F`. All confirmed.

## Phase 14 Completion Status

- **ROADMAP success criterion 1:** `scale_color_viridis_c()` mark hex matches `ggplot_build()` — verified by `viridis_c per-row mark hex` snapshot block.
- **ROADMAP success criterion 2:** `scale_color_brewer()` and `scale_fill_manual()` round-trip identical hex codes — verified by `brewer (discrete fill) per-row hex parity` and `scale_fill_manual per-row hex parity` snapshot blocks.
- **ROADMAP success criterion 3:** Continuous color renders as colorbar gradient (not stack of discrete keys) — verified by `g$type == "colorbar"` assertions plus visual checkpoints B (vertical smooth + steps) and C (horizontal).
- **ROADMAP success criterion 4:** Discrete legends from v1.0 still render — `test-legends.R` and `test-ir-legends.R` green throughout the phase.
- **D-10 (horizontal colorbar):** end-to-end verified — R IR carries `orientation = "horizontal"` (plan 14-05), JS branches on it (plan 14-06), layout fixed and visually approved (plan 14-07).

## Next Phase Readiness

- Phase 14 (Color Fidelity) complete: 7/7 plans, COLOR-01 + COLOR-02 satisfied.
- Phase 15 (Secondary Axes) unblocked. The clean ir_legends / ir_scales modules from phase 13 plus the orientation-aware legend sizing introduced here are the primary surface that sec.axis work will touch.
- No outstanding blockers. Phase-13 baseline FAIL count (8) remains the only known suite redness, carried into v1.1 release hardening as expected.

## Self-Check: PASSED

- SUMMARY.md exists at `.planning/phases/14-color-fidelity/14-07-SUMMARY.md`.
- All recorded commits found in git log: `5360a11`, `21fd6cf`, `a1b93aa`, `d531ea7`.

---
*Phase: 14-color-fidelity*
*Plan: 07-snapshots*
*Completed: 2026-05-07*
