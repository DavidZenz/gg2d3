---
phase: 14-color-fidelity
plan: 01
subsystem: testing
tags: [r-package, ggplot2, color, test-scaffold, snapshot, testthat]

# Dependency graph
requires:
  - phase: 13-internals-refactor
    provides: ir_scales.R / ir_legends.R / ir_layers.R extractors that helpers wrap
provides:
  - Reusable colour-extraction helpers (build_colours, ir_layer_colours, guide_by_aes, scale_by_aes)
  - Skip-pending test corpus (20 stubs) mapped to plans 14-02..14-07
  - Stable test file path for downstream plans' verify steps
affects: [14-02, 14-03, 14-04, 14-05, 14-06, 14-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "testthat helper-*.R auto-source for shared test utilities"
    - "Skip-pending test stubs as wave-0 contract for parallel plan execution"

key-files:
  created:
    - tests/testthat/helper-color.R
    - tests/testthat/test-color-fidelity.R
  modified: []

key-decisions:
  - "Keep helpers untyped and short — failures bubble up so tests reveal real defects"
  - "Define %||% locally in helper file so it works in fresh sessions without pkgload"
  - "Group skip-pending stubs by requirement (COLOR-01/COLOR-02) and target plan, mirroring VALIDATION.md exactly"

patterns-established:
  - "Wave-0 scaffold pattern: skip-pending test stubs landed before any production change so later plans only flip skip() to assertions"
  - "library(ggplot2) inside each test_that block (not globally) so skips don't load ggplot2 needlessly"

requirements-completed: []  # COLOR-01/COLOR-02 not closed yet — stubs only; full closure comes in 14-07

# Metrics
duration: 3min
completed: 2026-05-06
---

# Phase 14 Plan 01: Test Scaffold Summary

**Wave-0 colour-fidelity test scaffold: 8 reusable extraction helpers and 20 skip-pending test stubs that downstream plans (14-02..14-07) flip to real assertions.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-06T19:46:28Z
- **Completed:** 2026-05-06T19:49:22Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- `tests/testthat/helper-color.R` exposes 8 helpers covering ggplot_build colour/fill extraction, IR per-row colour/fill extraction, IR guide lookup by aesthetic, and ggplot2 scale-object reference breaks/labels
- `tests/testthat/test-color-fidelity.R` provides 20 skip-pending test_that blocks grouped per requirement (COLOR-01: 8, COLOR-02: 7, edge cases D-11..D-14: 4, JS regex: 1)
- Suite green vs Phase 13 baseline: 551 PASS / 8 FAIL (unchanged) / 21 SKIP (1 prior + 20 new)

## Task Commits

1. **Task 1: helper-color.R extraction utilities** — `5f66110` (test)
2. **Task 2: test-color-fidelity.R skip-pending corpus** — `4ed6261` (test)
3. **Task 3: full-suite regression confirmation** — verification-only, no commit

## Files Created/Modified

- `tests/testthat/helper-color.R` — 59 lines, 8 helpers + local %||%
- `tests/testthat/test-color-fidelity.R` — 129 lines, 20 skip-pending test_that blocks + section comments

## Helpers Exposed

| Helper                     | Purpose                                            |
| -------------------------- | -------------------------------------------------- |
| `build_colours(p, i)`      | ggplot_build resolved per-row colour (D-04 truth)  |
| `build_fills(p, i)`        | ggplot_build resolved per-row fill                 |
| `ir_layer_colours(p, i)`   | Per-row colour from IR layer data                  |
| `ir_layer_fills(p, i)`     | Per-row fill from IR layer data                    |
| `guide_by_aes(p, aes)`     | Find IR guide for a given aesthetic                |
| `scale_by_aes(p, aes)`     | Get ggplot2 scale object for an aesthetic          |
| `scale_reference_breaks`   | Reference breaks from scale object (legend stops)  |
| `scale_reference_labels`   | Reference labels from scale object                 |

## Stub Distribution

| Plan        | Stub count |
| ----------- | ---------- |
| 14-02 (JS regex)            | 1 |
| 14-03 (colorbar dispatch)   | 3 |
| 14-05 (colorbar IR fields)  | 2 |
| 14-06 (renderColorbar)      | 2 |
| 14-07 (snapshot corpus)     | 12 |
| **Total**                   | **20** |

## Decisions Made

- Used `pkgload::load_all()` in verification commands (not devtools, per CLAUDE.md / project memory)
- Set `R_MAKEVARS_USER=/tmp/empty_makevars` for R invocations to avoid Makevars conflicts noted in phase context
- `library(ggplot2)` placed inside each test_that block rather than at file top — avoids loading the package when every test is skipped

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes needed; helpers and stubs match the action specs char-for-char.

## Issues Encountered

- `testthat::test_dir()` aborts with "Test failures." error code on the 8 pre-existing coord_fixed/coord_trans baseline failures. Worked around by passing `stop_on_failure=FALSE` to extract counts. No action needed — those 8 fails are documented in STATE.md as Phase 13 baseline.

## Next Phase Readiness

- Wave 1 plans (14-02, 14-03, 14-04 per VALIDATION.md) can now spawn in parallel; each has a stable target file (`tests/testthat/test-color-fidelity.R`) and shared helpers in scope
- Plans only need to flip `skip(...)` → real assertions; no scaffold work duplicated downstream

## Self-Check: PASSED

- `tests/testthat/helper-color.R` exists (verified)
- `tests/testthat/test-color-fidelity.R` exists (verified)
- Commit `5f66110` exists in git log (verified)
- Commit `4ed6261` exists in git log (verified)
- 20 skips reported by testthat::test_file (verified)
- Suite baseline unchanged: 551 PASS / 8 FAIL / 21 SKIP (verified)

---
*Phase: 14-color-fidelity*
*Completed: 2026-05-06*
