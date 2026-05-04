---
phase: 13-internals-refactor
plan: 02
subsystem: refactor
tags: [r-package, ggplot2, refactor, theme, calc_element]

# Dependency graph
requires:
  - phase: 13-internals-refactor
    plan: 01
    provides: R/zzz.R (.gg2d3_pkgenv warn-once env), R/ir_utils.R (top-level helpers), 5 wave 0 test stubs
provides:
  - R/ir_theme.R with calc_element_safe (3-tier chokepoint), .gg2d3_warn_once, .gg2d3_calc_element_default, extract_theme_element, extract_theme_ir
  - REFACTOR-02 chokepoint achieved: only R/ir_theme.R references the ggplot2 private calc_element entry
  - Real test-ir-theme.R assertions replacing the Plan 01 stub
affects: [13-03-scales, 13-04-layers, 13-05-legends, 13-06-facets, 13-07-orchestrator-shrink]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Three-tier safety wrapper around a fragile private API (private -> public -> static default)"
    - "Warn-once-per-session via package-internal env (.gg2d3_pkgenv$calc_element_warned)"
    - "Pure-function extractor (extract_theme_ir) replacing inline orchestrator block"
    - "Linewidth conversion constant (3.7795275591) preserved verbatim per MEMORY.md (CSS px-per-mm; incorrect for ggplot2 line elements but kept for v1.0 parity)"

key-files:
  created:
    - R/ir_theme.R
  modified:
    - R/as_d3_ir.R
    - tests/testthat/test-ir-theme.R

key-decisions:
  - "Tier 1 fallback test uses a non-theme input to trigger ggplot2:::calc_element() error (the plan-suggested unknown element name returns NULL silently rather than erroring)"
  - "extract_theme_ir folds the legend + strip blocks (R/as_d3_ir.R:819-861) directly into its output, so the orchestrator no longer needs a post-hoc theme_ir$legend / theme_ir$strip merge"
  - "Linewidth constant (3.7795275591) explicitly NOT corrected in this phase per MEMORY.md and PATTERNS instructions"

patterns-established:
  - "Pattern A: chokepoint helper (calc_element_safe) for any private ggplot2 API gg2d3 must call"
  - "Pattern B: extract_*_ir(b) returns a complete IR slice; orchestrator just assigns it"

requirements-completed: [REFACTOR-01, REFACTOR-02]

# Metrics
duration: 8min
completed: 2026-05-04
---

# Phase 13 Plan 02: Theme + calc_element_safe Summary

**Lift the theme concern out of R/as_d3_ir.R into R/ir_theme.R and route all 5 v1.0 ggplot2:::calc_element sites through a new 3-tier calc_element_safe chokepoint (REFACTOR-02). R/as_d3_ir.R drops from 1151 to 1005 lines.**

## Performance

- Duration: ~8 min
- Started: 2026-05-04T08:26:25Z
- Completed: 2026-05-04T08:34:00Z (approx)
- Tasks: 2
- Files created: 1
- Files modified: 2

## Accomplishments

- Created R/ir_theme.R (228 lines) containing:
  - `calc_element_safe(element_name, theme)`: 3-tier fallback (Tier 1 = ggplot2 private; Tier 2 = ggplot2::theme_get() + ggplot2::calc_element public API; Tier 3 = `.gg2d3_calc_element_default` static table).
  - `.gg2d3_warn_once(element_name, path)`: emits one `warning()` per session, gated by `.gg2d3_pkgenv$calc_element_warned` (env created in Plan 01).
  - `.gg2d3_calc_element_default(element_name)`: switch returning "right" / unit(1.2,"lines") / unit(5.5,"pt") / NULL.
  - `extract_theme_element(element_name, theme)`: lifted verbatim from R/as_d3_ir.R:73-141 with the line-75 calc_element call rerouted through `calc_element_safe`.
  - `extract_theme_ir(b)`: pure function reproducing the v1.0 theme list slice (panel/plot/grid/axis/text/legend/strip), with the legend.key.size pixel conversion (formerly R/as_d3_ir.R:822-833) folded in.
- Edited R/as_d3_ir.R:
  - Deleted inline `extract_theme_element` closure (lines 73-141).
  - Replaced inline theme assembly (lines 535-571) with `theme_ir <- extract_theme_ir(b)`.
  - Deleted legend_theme + strip_theme blocks (lines 819-861).
  - Replaced 3 inline `complete_theme + ggplot2:::calc_element` blocks (legend.position, FacetWrap panel.spacing, FacetGrid panel.spacing) with one-line `calc_element_safe(...)` calls.
  - Net: **1151 -> 1005 lines (-146)**.
- Replaced tests/testthat/test-ir-theme.R Plan 01 stub with 5 real `test_that` blocks covering structural shape, v1.0 equivalence, Tier 1 silence, fallback warn-once, and static-default values.
- REFACTOR-02 success criterion met: `grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l` == 0.
- NAMESPACE diff empty (no new exports introduced).
- Test suite: 534 PASS, 8 FAIL, 19 WARN, 1 SKIP. The 8 failures are the same baseline documented in 13-01-SUMMARY.md (coord_trans + coord_fixed + boxplot/violin noise) and are out of scope per Plan 01.

## Task Commits

1. **Task 1: Create R/ir_theme.R with calc_element_safe + extract_theme_element + extract_theme_ir** -- `d2e1fbf` (feat)
2. **Task 2: Wire orchestrator to extract_theme_ir; replace 5 calc_element sites; add real test-ir-theme assertions** -- `3cc00a6` (refactor)

## Files Created/Modified

- **created** `R/ir_theme.R` -- new home of calc_element_safe + 4 supporting helpers (228 lines).
- **modified** `R/as_d3_ir.R` -- 1151 -> 1005 lines; theme block removed, 5 calc_element sites collapsed.
- **modified** `tests/testthat/test-ir-theme.R` -- stub replaced with 5 real assertions.

## Decisions Made

- **Tier 1 fallback test uses non-theme input.** The plan suggested calling `calc_element_safe("element.that.does.not.exist", theme_grey())` to trigger fallback. In ggplot2 4.x `ggplot2:::calc_element` returns NULL silently for unknown element names (Tier 1 succeeds), so it never falls back. To exercise the real fallback path the test now passes a non-theme value (`"not a theme"`) which raises an indexing error inside ggplot2:::calc_element. Outcome (one warning then expect_silent on second call) is unchanged.
- **Linewidth constant left at 3.7795275591.** MEMORY.md flags this as incorrect for ggplot2 element_line / element_rect (correct value is 2.845). Per PATTERNS Section "extract_theme_element" and the plan's explicit instruction ("DO NOT change in this phase"), preserved verbatim for v1.0 parity. Correction is a separate concern.
- **Folded legend + strip into extract_theme_ir.** Rather than leaving the orchestrator to do `theme_ir$legend <- legend_theme` post-hoc, extract_theme_ir produces the complete final list in one pass. Simpler interface for downstream callers.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Plan-supplied test for fallback path was a no-op**
   - **Found during:** Task 2 verification (`devtools::test()`).
   - **Issue:** The plan's Test 4 used an unknown element name to trigger Tier 1 failure, but ggplot2:::calc_element returns NULL silently in that case rather than erroring. The fallback path was never exercised, so `expect_warning` failed.
   - **Fix:** Switched the input from an unknown element name to a non-theme value, which raises an indexing error and routes through Tier 1's tryCatch error branch as intended.
   - **Files modified:** tests/testthat/test-ir-theme.R
   - **Commit:** 3cc00a6

### Acceptance-criterion notes

- Plan acceptance for Task 1 says `grep -c 'ggplot2:::calc_element' R/ir_theme.R` equals 1. Actual is 2: one is the live call inside calc_element_safe Tier 1; the second is the literal substring inside the warning message ("ggplot2:::calc_element() failed"), which the plan's own Test 4 regex (`"ggplot2:::calc_element\\(\\) failed"`) requires to be present. The test contract is the binding artifact, so the warning string was preserved. The REFACTOR-02 leak gate (`grep -rn ... | grep -v R/ir_theme.R | wc -l == 0`) is fully met.

## Issues Encountered

- Same Makevars / `pkgload` workaround as Plan 01: tests run via `R_MAKEVARS_USER=/tmp/empty_makevars Rscript -e 'pkgload::load_all(); testthat::test_dir(...)'`. devtools::document() not run for the same environmental reason; NAMESPACE confirmed unchanged via `git diff --stat NAMESPACE` (empty).
- Pre-existing 8 test failures (coord_trans, coord_fixed, geoms-phase5 boxplot/violin) persist unchanged. Out of scope.

## User Setup Required

None.

## Next Phase Readiness

- Plans 03 (scales), 04 (layers), 05 (legends), 06 (facets) can now call `calc_element_safe(element_name, theme)` directly when extracting theme-dependent code.
- Plan 07 (orchestrator shrink) will remove the remaining inline closures from R/as_d3_ir.R; line count expected to fall further from the current 1005.
- The chokepoint test pattern (Tier 1 silent / fallback warn-once / static-default identity) is reusable for future fragile-API wrappers.

## TDD Gate Compliance

This plan is `type: execute`. Each task used the most accurate concern-aligned commit type:
- Task 1: `feat` (new helpers)
- Task 2: `refactor` (orchestrator delegation + test additions; no IR shape change)

Plan-level TDD gate sequence does not apply.

## Self-Check: PASSED

Verification:
- `R/ir_theme.R` -- FOUND (228 lines, contains calc_element_safe, extract_theme_element, extract_theme_ir)
- `R/as_d3_ir.R` -- FOUND (1005 lines, down from 1151; contains 4 calc_element_safe references and 3 extract_theme_ir(b) references; 0 inline extract_theme_element)
- `tests/testthat/test-ir-theme.R` -- FOUND (5 test_that blocks, all passing)
- Commit `d2e1fbf` (Task 1) -- FOUND in git log
- Commit `3cc00a6` (Task 2) -- FOUND in git log
- `grep -rn 'ggplot2:::calc_element' R/ | grep -v R/ir_theme.R | wc -l` -- 0 (REFACTOR-02 gate)
- `git diff --stat NAMESPACE` -- empty
- `R_MAKEVARS_USER=/tmp/empty_makevars Rscript -e 'pkgload::load_all(); testthat::test_dir("tests/testthat")'` -- 534 PASS / 8 FAIL (baseline) / 19 WARN / 1 SKIP

---
*Phase: 13-internals-refactor*
*Completed: 2026-05-04*
