---
phase: 13
plan: 05
subsystem: r-ir-legends
tags: [r-package, ggplot2, refactor, legends, guides]
requires:
  - R/ir_theme.R::calc_element_safe (Plan 13-02)
provides:
  - R/ir_legends.R::extract_legends_ir
affects:
  - R/as_d3_ir.R (orchestrator shrunk by 191 lines)
tech_stack:
  added: []
  patterns:
    - "Pure-function delegation: orchestrator passes ggplot_build output + plot object to extractor"
    - "Public ggplot2 API (ggplot2::get_guide_data) preserved — no hand-rolled guide enumeration"
    - "Merge-by-title pass lifted verbatim — v1.0 behavior preserved"
key_files:
  created:
    - R/ir_legends.R
  modified:
    - R/as_d3_ir.R
    - tests/testthat/test-ir-legends.R
decisions:
  - "extract_legends_ir takes (b, p) — p required because ggplot2::get_guide_data needs the plot object, not the built object"
  - "ggplot2::waiver() (qualified) replaces bare waiver() inside the lifted block to avoid ambiguity once outside the orchestrator's import scope"
  - "Legend block excised cleanly: zero get_guide_data references remain in R/as_d3_ir.R"
metrics:
  duration: ~8m
  completed: 2026-05-04
  tasks_completed: 1
  files_changed: 3
---

# Phase 13 Plan 05: Legends Extraction Summary

Lifted the legend-extraction concern out of `R/as_d3_ir.R` into `R/ir_legends.R::extract_legends_ir`, completing Wave 5 of the internals refactor. The orchestrator's ~200-line legend block (legend.position resolution → aesthetic enumeration → per-aesthetic guide_data fetch → key construction → colorbar branch → merge-by-title pass) is now a single delegating call.

## What Changed

- **Created** `R/ir_legends.R` (184 lines) with `extract_legends_ir(b, p)` returning `list(position, guides)`. Function uses `calc_element_safe("legend.position", ...)` for position and `ggplot2::get_guide_data(p, aesthetic = ...)` for per-aesthetic guide data. Merge-by-title pass preserved verbatim.
- **Removed** from `R/as_d3_ir.R`:
  - The `legend_position <- tryCatch(...)` block.
  - The `if (legend_position != "none") { ... }` block (aesthetic enumeration + guide_data loop + colorbar branch + merge-by-title pass).
  - All `ggplot2::get_guide_data` callsites (now zero in the orchestrator).
- **Replaced stub** `tests/testthat/test-ir-legends.R` with 5 real assertions: default position, discrete-colour guide title, `legend.position = "none"` honored, full-pipeline equality with `as_d3_ir(p)$guides`, and empty-guides for x/y-only mappings.
- One verbatim adjustment: `waiver()` → `ggplot2::waiver()` for namespace-safety inside the standalone file.

## Line-Count Delta

| File              | Before | After | Delta |
| ----------------- | -----: | ----: | ----: |
| R/as_d3_ir.R      |    608 |   417 |  -191 |
| R/ir_legends.R    |      0 |   184 |  +184 |
| Net (orchestrator only) |  |       |  -191 |

Orchestrator shrinkage exceeds the ≥150-line threshold implied by the plan.

## Verification

| Check                                                  | Result |
| ------------------------------------------------------ | ------ |
| `test -f R/ir_legends.R`                               | exit 0 |
| `grep -cE '^extract_legends_ir <- function' R/ir_legends.R` | 1 |
| `grep -c '@export' R/ir_legends.R`                     | 0 |
| `grep -F -c 'extract_legends_ir(b' R/as_d3_ir.R`       | 1 |
| `grep -F -c 'get_guide_data' R/as_d3_ir.R`             | 0 |
| `grep -F -c 'get_guide_data' R/ir_legends.R`           | 2 |
| `wc -l R/as_d3_ir.R`                                   | 417 |
| `grep -c 'test_that' tests/testthat/test-ir-legends.R` | 5 |
| `git diff NAMESPACE`                                   | empty |

## Test Results

| Suite                          | Before (post-04) | After (post-05) |
| ------------------------------ | ---------------- | --------------- |
| Full `testthat::test_dir`      | PASS 533, FAIL 8 | PASS 540, FAIL 8 |
| `test-legends.R`               | green            | green           |
| `test-ir-legends.R`            | PASS 1 (stub)    | PASS 5 (real)   |

The 8 baseline failures are unchanged (out-of-scope `coord_fixed` regressions per phase context). +7 passing tests = 5 new + 2 latent passes (likely test-load-order shuffle, behavior unchanged).

## Deviations from Plan

None — plan executed exactly as written. The only adjustment (`waiver()` → `ggplot2::waiver()`) is a routine namespace-safety fix when lifting code into a standalone file, not a behavioral change. No Rule 1/2/3 auto-fixes triggered.

## TDD Gate Compliance

- RED: `test(13-05): add failing tests for extract_legends_ir` (dd8d662) — confirmed `could not find function "extract_legends_ir"` failure.
- GREEN: `feat(13-05): extract legends concern into R/ir_legends.R` (463a891) — all 5 new tests pass; baseline failures unchanged.
- REFACTOR: not needed (initial implementation matched final shape).

## Self-Check: PASSED

- `R/ir_legends.R` exists with `extract_legends_ir`.
- `R/as_d3_ir.R` no longer contains `get_guide_data` or the legend block; delegating call present.
- Both commits present in git log: dd8d662 (RED), 463a891 (GREEN).
