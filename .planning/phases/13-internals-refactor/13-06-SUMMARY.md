---
phase: 13
plan: 06
subsystem: r-ir-facets
tags: [r-package, ggplot2, refactor, facets]
requires:
  - R/ir_theme.R::calc_element_safe (Plan 13-02)
  - R/ir_scales.R::extract_scales_ir (Plan 13-03)
provides:
  - R/ir_facets.R::extract_facets_ir
affects:
  - R/as_d3_ir.R (orchestrator shrunk by 250 lines; <<- removed)
tech_stack:
  added: []
  patterns:
    - "Pure-function delegation returning multi-slice list (facets + panels)"
    - "Explicit `function(e) fallback` error handler — replaces dynamic-scope `<<-`"
    - "Per-panel temporal conversion preserved verbatim (Date * 86400000, POSIXct * 1000)"
key_files:
  created:
    - R/ir_facets.R
  modified:
    - R/as_d3_ir.R
    - tests/testthat/test-ir-facets.R
decisions:
  - "extract_facets_ir returns list(facets=..., panels=...) so the orchestrator can destructure without superassign — eliminates the v1.0 <<- pattern that would have written to globalenv once moved out of as_d3_ir's frame (RESEARCH Pitfall 2)"
  - "tryCatch error handler now `function(e) fallback` (precomputed value) rather than `function(e) { facets_ir <<- ...; panels_ir <<- ... }` — the explicit value is the function's return, no dynamic scope tricks"
  - "Compat shims (x_breaks, y_breaks, x_trans_name, y_trans_name) retained in orchestrator as they are now formal arguments to extract_facets_ir; will be cleaned up further in Plan 07"
  - "is_flip_early continues to be passed through (orchestrator owns the un-swap of pp_x/pp_y; extractor accepts the boolean for per-panel re-un-swap)"
metrics:
  duration: ~6m
  completed: 2026-05-04
  tasks_completed: 1
  files_changed: 3
---

# Phase 13 Plan 06: Facets Extraction Summary

Lifted the facets concern out of `R/as_d3_ir.R` into `R/ir_facets.R::extract_facets_ir`, completing Wave 6 of the internals refactor. The orchestrator's ~260-line facets block (FacetWrap branch + FacetGrid branch + null-facet branch + tryCatch error handler) is now a single delegating call. The structural fix — replacing the v1.0 `<<-` superassign in the error handler with an explicit return value — is complete.

## What Changed

- `R/ir_facets.R` (new, 269 lines): `extract_facets_ir(b, pp_x, pp_y, scales, x_breaks, y_breaks, x_trans_name, y_trans_name, is_flip = FALSE)` returns `list(facets, panels)`. All three branches (FacetWrap, FacetGrid, null) lifted verbatim. Per-panel temporal conversion preserved (`* 86400000` for Date, `* 1000` for POSIXct). `panel.spacing` resolution continues to route through `calc_element_safe` (Plan 02).
- `R/as_d3_ir.R`: 417 → 167 lines (-250). Facets block replaced with `fp <- extract_facets_ir(...); facets_ir <- fp$facets; panels_ir <- fp$panels`. Zero `<<-` references remain.
- `tests/testthat/test-ir-facets.R`: stub replaced with 5 real assertions including a global-env-pollution regression check (Pitfall 2).

## Pitfall 2 Fix — `<<-` Removal

v1.0 lines 1109-1126 used:
```r
}, error = function(e) {
  facets_ir <<- list(...)
  panels_ir <<- list(...)
})
```
Within `as_d3_ir`'s body, `<<-` walked up to `as_d3_ir`'s frame and assigned the locals. Once that block moves into `extract_facets_ir`, `<<-` would skip the function frame (no `facets_ir`/`panels_ir` defined there) and reach **globalenv**, silently polluting global state on every error path.

The fix: the error handler is now `function(e) fallback`, returning a precomputed value. The success branches each return `list(facets = ..., panels = ...)` as their final expression. No `<<-` survives. The dedicated regression test (`test-ir-facets.R::extract_facets_ir does NOT pollute global env`) confirms `facets_ir` / `panels_ir` are never created in `globalenv` after a happy-path call.

## Verification

- `Rscript -e 'pkgload::load_all(); testthat::test_dir("tests/testthat")'` → **551 PASS / 8 FAIL** (8 fail = pre-existing baseline `coord_fixed` failures in `test-ir.R` / `test-layout.R` / `test-legends.R`, unchanged by this plan; documented as out-of-scope in phase context).
- `test-facets.R` → 72 PASS, 0 FAIL.
- `test-facet-grid.R` → 67 PASS, 0 FAIL.
- `test-ir-facets.R` → 12 PASS, 0 FAIL.
- `grep -c '<<-' R/as_d3_ir.R` → 0 (only comment-prose mentions remain — code uses zero).
- `grep -c '<<-' R/ir_facets.R` → 0 (lifted code uses normal `<-` since it's now within its own function frame).
- `grep -n 'extract_facets_ir' R/as_d3_ir.R` → 1 call site at line 135.
- `wc -l R/as_d3_ir.R` → **167** (was 417 at plan start; -250 lines, ~60% reduction).
- NAMESPACE: unchanged (no exports added).

## Files Modified

| File | Change |
|------|--------|
| `R/ir_facets.R` | Created (269 lines) |
| `R/as_d3_ir.R` | -250 lines (417 → 167); facets block replaced with delegating call; `<<-` removed |
| `tests/testthat/test-ir-facets.R` | Stub → 5 real assertions including Pitfall 2 regression |

## Deviations from Plan

None — plan executed exactly as written. Compat shims (`x_breaks`, `y_breaks`, `x_trans_name`, `y_trans_name`) retained because they're formal arguments to `extract_facets_ir`; further cleanup deferred to Plan 07 orchestrator-shrink as that plan calls for.

## Self-Check: PASSED

- `R/ir_facets.R` exists.
- `R/as_d3_ir.R` shrunk to 167 lines, contains `extract_facets_ir` call, contains zero code-level `<<-`.
- `tests/testthat/test-ir-facets.R` has 5 `test_that` blocks.
- Commits `f9facac` (RED test) and `0dc6d5e` (GREEN implementation) verified in `git log`.
- All facet test files green.
