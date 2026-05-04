---
phase: 13-internals-refactor
plan: 01
subsystem: refactor
tags: [r-package, ggplot2, refactor, testthat, ir-extraction]

# Dependency graph
requires:
  - phase: 12-v1.0-shipped
    provides: monolithic R/as_d3_ir.R (1,151 lines) and existing testthat suite
provides:
  - 5 Wave 0 test stub files (test-ir-{scales,theme,layers,legends,facets}.R) ready to receive real assertions in Plans 02-06
  - R/zzz.R with .gg2d3_pkgenv (warn-once env) and .gg2d3_reset_calc_element_warned() test hook
  - R/ir_utils.R with top-level %||%, to_rows(df, keep_aes), and dom() — closure-free, callable from any extractor
affects: [13-02-theme, 13-03-scales, 13-04-layers, 13-05-legends, 13-06-facets, 13-07-orchestrator-shrink]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Package-internal env (.gg2d3_pkgenv) for warn-once state with test-only reset hook"
    - "Cross-cutting utilities live in R/ir_utils.R with @keywords internal @noRd"
    - "Closure-captured args (e.g. keep_aes) lifted to explicit function parameters"

key-files:
  created:
    - tests/testthat/test-ir-scales.R
    - tests/testthat/test-ir-theme.R
    - tests/testthat/test-ir-layers.R
    - tests/testthat/test-ir-legends.R
    - tests/testthat/test-ir-facets.R
    - R/zzz.R
    - R/ir_utils.R
  modified: []

key-decisions:
  - "to_rows takes keep_aes as explicit argument (Pitfall 1 — not a closure capture)"
  - "Warn-once state stored in package-internal env (.gg2d3_pkgenv), not options() or globals"
  - "Test-only reset hook .gg2d3_reset_calc_element_warned() lives in R/zzz.R alongside the env"
  - "R/as_d3_ir.R untouched — its inline closures still shadow new top-level helpers, preserving v1.0 behavior exactly"

patterns-established:
  - "Pattern A: Package-internal env for one-shot session warnings + test reset hook"
  - "Pattern B: Lift closure-captured args to explicit parameters when extracting helpers"
  - "Pattern C: New ir_*.R files use @keywords internal @noRd — never @export — to preserve NAMESPACE"

requirements-completed: [REFACTOR-01, REFACTOR-02]

# Metrics
duration: 5min
completed: 2026-05-04
---

# Phase 13 Plan 01: Foundation Summary

**Foundation for the as_d3_ir refactor: 5 Wave 0 test stubs, R/zzz.R warn-once env, and R/ir_utils.R with closure-free %||%, to_rows(df, keep_aes), and dom() — zero source changes to R/as_d3_ir.R, NAMESPACE unchanged.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-04T08:18:33Z
- **Completed:** 2026-05-04T08:23:22Z
- **Tasks:** 2
- **Files created:** 7
- **Files modified:** 0

## Accomplishments

- Created 5 Wave 0 test stub files matching extractors planned for Plans 02–06; each file contains a trivially-passing `test_that` block so devtools::test() picks it up. Plans 02–06 will replace the stubs with real assertions.
- Created R/zzz.R defining `.gg2d3_pkgenv` (with `calc_element_warned = FALSE`) and the `.gg2d3_reset_calc_element_warned()` test-only reset hook (per D-07 + RESEARCH Open Question 3).
- Created R/ir_utils.R with three top-level closure-free helpers: `%||%`, `to_rows(df, keep_aes)` (Pitfall 1: keep_aes lifted to explicit arg), and `dom()`.
- NAMESPACE diff is empty — no new exports introduced (all helpers `@keywords internal @noRd`).
- R/as_d3_ir.R intentionally left unchanged in this plan: its inline `%||%`/`to_rows`/`dom` closures still shadow the new top-level definitions, so v1.0 behavior is preserved exactly.

## Task Commits

1. **Task 1: Create five Wave 0 test stub files** — `19ad9c7` (test)
2. **Task 2: Create R/zzz.R + R/ir_utils.R** — `32641f1` (feat)

## Files Created/Modified

- `tests/testthat/test-ir-scales.R` — Wave 0 stub for extract_scales_ir (Plan 03 target)
- `tests/testthat/test-ir-theme.R` — Wave 0 stub for extract_theme_ir + calc_element_safe (Plan 02 target)
- `tests/testthat/test-ir-layers.R` — Wave 0 stub for extract_layers_ir (Plan 04 target)
- `tests/testthat/test-ir-legends.R` — Wave 0 stub for extract_legends_ir (Plan 05 target)
- `tests/testthat/test-ir-facets.R` — Wave 0 stub for extract_facets_ir (Plan 06 target)
- `R/zzz.R` — `.gg2d3_pkgenv` env + `.gg2d3_reset_calc_element_warned()` test hook
- `R/ir_utils.R` — top-level `%||%`, `to_rows(df, keep_aes)`, `dom()`

## Decisions Made

- `to_rows` takes `keep_aes` as an explicit second argument rather than closing over a parent-scope value (Pitfall 1).
- `.gg2d3_pkgenv` is created at top level (not inside `.onLoad`) — top-level `<-` runs at package install/load and is sufficient for this minimal env.
- The reset hook is defined alongside the env in R/zzz.R rather than in R/ir_theme.R (which doesn't exist yet) so this plan stays self-contained.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Test environment bootstrap:** `testthat` and `pkgload` were not installed in the system R library, and `~/.R/Makevars` set `PKG_CPPFLAGS` to a value that overrode testthat's per-package Makevars (causing `testthat.h` to be unfindable during compilation). Worked around by installing testthat with `R_MAKEVARS_USER=/tmp/empty_makevars R CMD INSTALL` to neutralize the user-level override. This is a pre-existing environment issue, not caused by this plan; documented here so the next executor knows the workaround.
- **Pre-existing test failures:** `pkgload::load_all() + testthat::test_dir("tests/testthat")` shows `[FAIL 8 | WARN 19 | SKIP 2 | PASS 502]`. Verified the same 8 failures exist on the pre-plan baseline (git stash/pop confirms identical counts). Failures are in `test-ir.R` (`coord_fixed` related) and unrelated to this plan's changes — R/as_d3_ir.R was not modified. Per the SCOPE BOUNDARY rule, these are out-of-scope and logged for a future plan to triage.
- **devtools unavailable:** Could not run `devtools::document()` (devtools not installed in this R lib; build deps intricate on this system). NAMESPACE was confirmed unchanged via direct `diff` against pre-plan snapshot, and no `@export` roxygen tags exist in the new files (`grep -E "^#'.*@export" R/ir_utils.R R/zzz.R` returns nothing), so document() would be a no-op.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (theme + calc_element_safe extraction) can now `source` `R/ir_utils.R::%||%` and rely on `.gg2d3_pkgenv$calc_element_warned` for warn-once semantics.
- Plans 03–06 can call `to_rows(df, keep_aes)` and `dom()` as top-level functions without recreating closures.
- Plan 07 (orchestrator shrink) will remove the now-shadowed inline closures from R/as_d3_ir.R as the final cleanup step.

## TDD Gate Compliance

This plan is `type: execute` (not `type: tdd`); the RED/GREEN/REFACTOR gate sequence does not apply at the plan level. Task 1 used a `test(...)` commit (stub-only) and Task 2 used a `feat(...)` commit (utilities); these are concern-aligned commit types, not TDD gate ceremonies.

## Self-Check: PASSED

Verification:
- `tests/testthat/test-ir-scales.R` — FOUND
- `tests/testthat/test-ir-theme.R` — FOUND
- `tests/testthat/test-ir-layers.R` — FOUND
- `tests/testthat/test-ir-legends.R` — FOUND
- `tests/testthat/test-ir-facets.R` — FOUND
- `R/zzz.R` — FOUND
- `R/ir_utils.R` — FOUND
- Commit `19ad9c7` (Task 1) — FOUND in git log
- Commit `32641f1` (Task 2) — FOUND in git log
- NAMESPACE diff vs pre-plan — empty (no new exports)
- Verify command (`stopifnot(.gg2d3_pkgenv ...) ; to_rows(...) ; dom(...)`) — exited OK
- Stub test runs — 5/5 PASS

---
*Phase: 13-internals-refactor*
*Completed: 2026-05-04*
