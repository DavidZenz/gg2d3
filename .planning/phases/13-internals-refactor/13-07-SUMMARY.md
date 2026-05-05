---
phase: 13-internals-refactor
plan: 07
subsystem: refactor
tags: [r-package, ggplot2, refactor, orchestrator, verification]

# Dependency graph
requires:
  - phase: 13-01-foundation
    provides: R/zzz.R pkgenv + R/ir_utils.R top-level helpers + 5 Wave-0 test stubs
  - phase: 13-02-theme
    provides: R/ir_theme.R::extract_theme_ir + calc_element_safe chokepoint
  - phase: 13-03-scales
    provides: R/ir_scales.R::extract_scales_ir
  - phase: 13-04-layers
    provides: R/ir_layers.R::extract_layers_ir
  - phase: 13-05-legends
    provides: R/ir_legends.R::extract_legends_ir
  - phase: 13-06-facets
    provides: R/ir_facets.R::extract_facets_ir
provides:
  - Thin as_d3_ir() orchestrator (120-line file, 118-line function body) delegating to all 5 ir_*.R extractors
  - Phase-13 verification record (line counts, calc_element audit, test summary, visual diff sign-off)
affects: [14-color-fidelity, 15-secondary-axes, 16-robustness]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Orchestrator-as-pipeline: as_d3_ir() = ggplot_build -> coord detect -> 5 delegating extractor calls -> ir list -> validate_ir"
    - "Single chokepoint for ggplot2 private API: ggplot2:::calc_element only via R/ir_theme.R::calc_element_safe"
    - "Visual regression checkpoint against test_output/ corpus as the no-behavior-change gate (no automated pixel-diff in v1.0)"

key-files:
  created:
    - .planning/phases/13-internals-refactor/13-07-SUMMARY.md
  modified:
    - R/as_d3_ir.R

key-decisions:
  - "Inline x_trans_name/y_trans_name and x_breaks/y_breaks intermediates directly into extract_facets_ir call site — these were leftover compat shims from Plan 06 with no other consumers"
  - "Drop redundant is_flip_early (v1.0 computed it twice; orchestrator now computes is_flip once)"
  - "Inline subtitle_text/caption_text into the final ir list assembly — single-use locals add no clarity"
  - "Keep .axis_ticklabels and .has_sec_axis logic inline in orchestrator (compressed) rather than lifting to ir_utils.R — small enough that a lift would not pay for itself; sec.axis lift is Phase 15's job"
  - "Visual diff against test_output/phase13/*.html corpus signed off by user — no automated pixel-diff harness in v1.0 (RESEARCH Open Question 1)"

patterns-established:
  - "Pattern 1: Orchestrator delegates to one extractor per concern (scales, theme, layers, legends, facets); orchestrator owns only ggplot_build, coord detection, axis-label swap, and final ir list assembly"
  - "Pattern 2: ggplot2 private-API access flows through a single auditable chokepoint (calc_element_safe)"
  - "Pattern 3: Phase-level visual regression gate via test_output/ corpus comparison until automated diffing exists"

requirements-completed: [REFACTOR-01, REFACTOR-02]

# Metrics
duration: ~10m
completed: 2026-05-04
---

# Phase 13 Plan 07: Orchestrator Shrink Summary

**`as_d3_ir()` reduced from 1,151 lines to a 120-line file (118-line function body) delegating to 5 `ir_*.R` extractor modules; `ggplot2:::calc_element` access chokepointed through `calc_element_safe`; Phase 13 internals refactor complete.**

## Performance

- **Duration:** ~10 min (Task 1 shrink + Task 2 visual checkpoint + Task 3 summary)
- **Completed:** 2026-05-04
- **Tasks:** 3
- **Files modified:** 1 (R/as_d3_ir.R)

## Accomplishments

- Final shrink: `R/as_d3_ir.R` 167 lines (post-Plan-06) -> **120 lines total** (function body **118 lines**, well under the ~200 target with 41% slack on the 210-line gate).
- Phase-wide reduction: **1,151 -> 120 lines (-1,031 lines, -89.6%)** for `R/as_d3_ir.R`.
- REFACTOR-01 satisfied: orchestrator delegates to all 5 extractors (`extract_scales_ir`, `extract_theme_ir`, `extract_layers_ir`, `extract_legends_ir`, `extract_facets_ir`).
- REFACTOR-02 satisfied: `ggplot2:::calc_element` audit clean — only `R/ir_theme.R` matches.
- Visual regression corpus (8 plots) rendered to `test_output/phase13/` and approved by user — no observable behavior change.

## Task Commits

1. **Task 1: Final orchestrator shrink** — `cec563d` (refactor)
2. **Task 2: Visual regression checkpoint** — no commit (user-verification gate; sign-off recorded in this summary)
3. **Task 3: Phase summary + state metadata** — committed alongside this file (docs)

**Plan metadata:** _this commit_ (docs(13-07): complete orchestrator shrink + phase verification)

## Final Metrics

### Line Counts

| Metric | Pre-Phase-13 | Post-Plan-06 | Post-Plan-07 | Delta from v1.0 |
|---|---|---|---|---|
| `wc -l R/as_d3_ir.R` | 1,151 | 167 | **120** | **-1,031 (-89.6%)** |
| `as_d3_ir` function body | ~1,140 | 165 | **118** | **-1,022 (-89.6%)** |

Gate: `awk '/^as_d3_ir <- function/,/^}$/' R/as_d3_ir.R | wc -l` -> **118**, ≤ 210 (REFACTOR-01 #1 with 5% slack on D-03 "~200"). PASS.

### REFACTOR-01 Verification — Delegation

```r
$ grep -E 'extract_(scales|theme|layers|legends|facets)_ir' R/as_d3_ir.R
extract_scales_ir(b, pp_x, pp_y, is_flip)
extract_theme_ir(b)
extract_layers_ir(b, scales$xscale_obj, scales$yscale_obj)
extract_legends_ir(b, p)
extract_facets_ir(b, pp_x, pp_y, scales, ...)
```

All 5 extractors delegated to. Public `as_d3_ir()` signature `function(p, width = 640, height = 400, padding = list(...))` and `@export` preserved verbatim (D-04).

### REFACTOR-02 Verification — `ggplot2:::calc_element` Audit

```
$ grep -rn 'ggplot2:::calc_element' R/
R/ir_theme.R:26:    ggplot2:::calc_element(element_name, theme),
R/ir_theme.R:58:    "gg2d3: ggplot2:::calc_element() failed for '%s'; using %s. ggplot2 version: %s. ..."
```

Only `R/ir_theme.R` matches — both inside `calc_element_safe()` (line 26 = the call; line 58 = the warning string). All 5 prior call sites in `R/as_d3_ir.R` were migrated in Plan 13-02. Audit: **PASS**.

```
$ grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l
0
```

### Test Summary

```
[ FAIL 8 | WARN 0 | SKIP 0 | PASS 551 ]
```

The 8 failures are pre-existing `coord_fixed` / `coord_trans` baseline issues in `test-ir.R`, `test-layout.R`, and `test-legends.R` — **unchanged from start of Phase 13** and documented as out-of-scope in `13-CONTEXT.md` (D-09 carve-out). Every Phase-13-introduced test (`test-ir-{scales,theme,layers,legends,facets}.R`) is green.

### NAMESPACE

```
$ git diff NAMESPACE
(empty)
```

No exports added or removed during the entire phase. Public API surface unchanged.

### Visual Regression Result

User-approved against `test_output/phase13/*.html` corpus on 2026-05-04. Corpus rendered:

| Plot | File | Status |
|---|---|---|
| `p_point` | `test_output/phase13/p_point.html` | approved |
| `p_bar` | `test_output/phase13/p_bar.html` | approved |
| `p_box` | `test_output/phase13/p_box.html` | approved |
| `p_line` | `test_output/phase13/p_line.html` | approved |
| `p_color` | `test_output/phase13/p_color.html` | approved |
| `p_facet_w` | `test_output/phase13/p_facet_w.html` | approved |
| `p_facet_g` | `test_output/phase13/p_facet_g.html` | approved |
| `p_flip` | `test_output/phase13/p_flip.html` | approved |

No `gg2d3: ggplot2:::calc_element() failed` warning emitted on healthy ggplot2 4.0.3 install (Tier 1 succeeds; Tier 2 fallback never engaged during render).

## Files Created (Phase-Wide, Plans 01-06)

- `R/zzz.R` — package-internal env + warn-once reset hook (Plan 01)
- `R/ir_utils.R` — `%||%`, `to_rows(df, keep_aes)`, `dom()` (Plan 01)
- `R/ir_theme.R` — `extract_theme_ir` + `calc_element_safe` chokepoint (Plan 02)
- `R/ir_scales.R` — `extract_scales_ir` + 4 helpers (Plan 03)
- `R/ir_layers.R` — `extract_layers_ir` (Plan 04)
- `R/ir_legends.R` — `extract_legends_ir` (Plan 05)
- `R/ir_facets.R` — `extract_facets_ir` with `<<-` removed (Plan 06)
- `tests/testthat/test-ir-{scales,theme,layers,legends,facets}.R` (Plans 01-06)

## Files Modified

- `R/as_d3_ir.R` — 1,151 -> 120 lines; thin orchestrator wired to 5 extractors

## Decisions Made

- Tiny inline helpers (`.axis_ticklabels`, `.has_sec_axis`) kept inline in orchestrator rather than lifted — under the threshold where extraction pays for itself, and `sec_axis` is Phase 15's territory.
- Compat shims from Plan 06 (`x_breaks`, `y_breaks`, `x_trans_name`, `y_trans_name`) inlined directly into `extract_facets_ir(...)` call site at this plan; no other call sites needed them.
- Visual diff sign-off captured in this summary — no automated pixel-diff harness in v1.0.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external services or credentials needed.

## Next Phase Readiness

Phase 13 is **ready for `/gsd-verify-work`**. Downstream phases that depend on the new module boundaries:

- **Phase 14 (Color Fidelity)** — operates on `R/ir_scales.R` for the colorbar gradient legend work.
- **Phase 15 (Secondary Axes)** — operates on `R/ir_scales.R` plus the inline axis-label / sec.axis block in the orchestrator.
- **Phase 16 (Robustness & Edge Cases)** — operates on `R/ir_layers.R` for non-finite filtering and on `R/ir_facets.R` for the `coord_flip + facet_grid` regression.

All 7 plans complete. The internals refactor leaves a clean, testable seam structure for v1.1 feature work.

## Self-Check: PASSED

- `R/as_d3_ir.R` exists at 120 lines with 118-line function body (verified via `wc -l` and `awk`).
- `grep -rn 'ggplot2:::calc_element' R/` returns only `R/ir_theme.R` matches (verified).
- All 5 `extract_*_ir` call sites present in `R/as_d3_ir.R` (verified).
- NAMESPACE clean (`git diff NAMESPACE` empty — verified).
- Task 1 commit `cec563d` exists in git log (verified).
- Visual diff corpus `test_output/phase13/*.html` (8 files) rendered and user-approved (verified).

---
*Phase: 13-internals-refactor*
*Completed: 2026-05-04*
