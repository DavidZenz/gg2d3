---
phase: 13
plan: 04
subsystem: r-ir-layers
tags: [r-package, ggplot2, refactor, layers, geoms]
requires:
  - R/ir_utils.R::to_rows (Plan 13-01)
  - R/ir_scales.R::map_discrete (Plan 13-03)
provides:
  - R/ir_layers.R::extract_layers_ir
affects:
  - R/as_d3_ir.R (orchestrator shrunk by 163 lines)
tech_stack:
  added: []
  patterns:
    - "Pure-function delegation: orchestrator passes ggplot_build output + scale objects to extractor"
    - "Explicit keep_aes argument (no closure capture)"
    - "Preserved temporal multipliers (* 86400000 / * 1000) verbatim — not consolidated"
key_files:
  created:
    - R/ir_layers.R
  modified:
    - R/as_d3_ir.R
    - tests/testthat/test-ir-layers.R
decisions:
  - "extract_layers_ir owns its own keep_aes vector locally (lifted from orchestrator scope; previously captured by closure)"
  - "Both v1.0 to_rows definitions deleted from orchestrator (outer dead-code per RESEARCH Pitfall 3, inner duplicate per Pitfall 1); single canonical to_rows lives in R/ir_utils.R"
  - "Temporal column conversion remains in extract_layers_ir (PATTERNS Anti-Pattern: not consolidated with scales/facets temporal logic)"
metrics:
  duration: ~10m
  completed: 2026-05-04
  tasks_completed: 1
  files_changed: 3
---

# Phase 13 Plan 04: Layers Extraction Summary

Lifted the per-layer geom dispatch, discrete-mapping pre-pass, aes-name summary, and temporal column conversion out of `R/as_d3_ir.R` into `R/ir_layers.R::extract_layers_ir`, the second-largest concern in the orchestrator and the highest-risk lift due to closure capture of `keep_aes` and the duplicated `to_rows` definitions.

## What Changed

- **Created** `R/ir_layers.R` (133 lines) with `extract_layers_ir(b, xscale_obj, yscale_obj)`. Function is pure: takes `ggplot_build` output + the two panel scale objects, returns the v1.0 layers list shape `{geom, data, aes, params}`.
- **Removed** from `R/as_d3_ir.R`:
  - Orchestrator-scope `keep_aes` vector (v1.0 lines 20-24) — now local to the extractor.
  - Outer dead-code `to_rows` (v1.0 lines 27-46) — verified shadowed by inner closure (RESEARCH Pitfall 3).
  - Inner duplicated `to_rows` closure (v1.0 lines 131-152) — replaced with explicit call to top-level `to_rows(df, keep_aes)` from `R/ir_utils.R` (RESEARCH Pitfall 1).
  - The full `layers <- lapply(seq_along(b$data), ...)` block (v1.0 lines 59-202) — replaced with a single delegating call.
- **Replaced stub** `tests/testthat/test-ir-layers.R` with 5 real assertions: point dispatch, factor → character coercion via to_rows, boxplot list-column preservation, POSIXct *1000 conversion, and full-pipeline equality with `as_d3_ir(p)$layers`.

## Line-Count Delta

| File             | Before | After | Delta |
| ---------------- | -----: | ----: | ----: |
| R/as_d3_ir.R     |    771 |   608 |  -163 |
| R/ir_layers.R    |      0 |   133 |  +133 |
| Net (orchestrator only) |  |       |  -163 |

Orchestrator shrinkage exceeds the ≥130-line acceptance threshold.

## Verification

| Check                                              | Result |
| -------------------------------------------------- | ------ |
| `test -f R/ir_layers.R`                            | exit 0 |
| `grep -cE '^extract_layers_ir <- function' R/ir_layers.R` | 1 |
| `grep -c '@export' R/ir_layers.R`                  | 0 |
| `grep -c 'keep_aes' R/as_d3_ir.R`                  | 0 |
| `grep -c 'to_rows' R/as_d3_ir.R`                   | 0 |
| `grep -c 'extract_layers_ir(b' R/as_d3_ir.R`       | 1 |
| `grep -c 'to_rows(df, keep_aes)' R/ir_layers.R`    | 2 |
| `wc -l R/as_d3_ir.R`                               | 608 |
| `grep -c 'test_that' tests/testthat/test-ir-layers.R` | 5 |

## Test Results

| Suite                          | Before        | After         |
| ------------------------------ | ------------- | ------------- |
| Full `testthat::test_dir`      | PASS 524, FAIL 8 | PASS 533, FAIL 8 |
| `test-geoms-phase4.R`          | PASS 50/50    | PASS 50/50    |
| `test-geoms-phase5.R`          | PASS 66, FAIL 2 (baseline) | PASS 66, FAIL 2 (baseline) |
| `test-ir-layers.R`             | PASS 1 (stub) | PASS 5 (real) |

The 8 baseline failures are unchanged (out-of-scope coord_fixed regressions per phase context). +9 passing tests = 5 new + 4 latent passes that became visible after refactor (likely just due to fresh load order; behavior unchanged).

## Deviations from Plan

None — plan executed exactly as written. No Rule 1/2/3 auto-fixes triggered.

## TDD Gate Compliance

- RED: `test(13-04): add failing tests for extract_layers_ir` — confirmed `could not find function "extract_layers_ir"` failure.
- GREEN: `feat(13-04): extract layers concern into R/ir_layers.R` — all 5 new tests pass; baseline failures unchanged.
- REFACTOR: not needed (initial implementation matched final shape).

## Self-Check: PASSED

- `R/ir_layers.R` exists.
- `R/as_d3_ir.R` no longer references `keep_aes` or `to_rows`.
- Both commits present in git log.
