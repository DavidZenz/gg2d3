---
phase: 13-internals-refactor
verified: 2026-05-04T00:00:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 13: Internals Refactor Verification Report

**Phase Goal:** Split monolithic `R/as_d3_ir.R` into per-concern modules with the top-level function under ~200 lines, and chokepoint `ggplot2:::calc_element` access through a single safe helper with a public-API fallback.

**Verified:** 2026-05-04
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                  | Status     | Evidence                                                                                                                                                |
| --- | ------------------------------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `as_d3_ir()` is split into per-concern modules (scales, theme, facets, layers, legends)               | VERIFIED   | `R/ir_scales.R`, `R/ir_theme.R`, `R/ir_facets.R`, `R/ir_layers.R`, `R/ir_legends.R` all exist with their `extract_*_ir` exports                          |
| 2   | Top-level `as_d3_ir()` is under ~200 lines and orchestrator-only                                       | VERIFIED   | File: 120 lines. Function body via `awk '/^as_d3_ir <- function/,/^}$/'` = 118 lines. ≤210 gate satisfied with 41% slack                                |
| 3   | Each helper independently testable (`extract_*_ir` are package-internal pure functions)                | VERIFIED   | Test files `tests/testthat/test-ir-{scales,theme,layers,legends,facets}.R` all green (referenced in SUMMARY); functions take `b`/scale args, return IR |
| 4   | `ggplot2:::calc_element()` access is wrapped in a helper with public-API fallback                      | VERIFIED   | `R/ir_theme.R::calc_element_safe()` implements 3-tier chain (private → `ggplot2::theme_get() + theme` public API → static defaults table)              |
| 5   | A private-API change in ggplot2 does not break gg2d3 (single chokepoint)                               | VERIFIED   | `grep -rn 'ggplot2:::calc_element' R/` returns only 2 matches, both inside `R/ir_theme.R::calc_element_safe()` (call site + warning string)            |
| 6   | No behavior regressions (test pass rate unchanged from baseline)                                       | VERIFIED   | Live `testthat::test_dir(...)` run: `[ FAIL 8 | WARN 19 | SKIP 2 | PASS 551 ]` — matches documented baseline; 8 failures are pre-existing coord_* issues |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact            | Expected                                                  | Status     | Details                                                                                                       |
| ------------------- | --------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------- |
| `R/as_d3_ir.R`      | Thin orchestrator under ~200 lines                        | VERIFIED   | 120 lines; calls all 5 `extract_*_ir` extractors plus `validate_ir`; `@export` preserved                      |
| `R/ir_utils.R`      | `%||%`, `to_rows(df, keep_aes)`, `dom()`                  | VERIFIED   | 48 lines; `to_rows` lifted with explicit `keep_aes` arg (Pitfall 1 fix)                                       |
| `R/ir_theme.R`      | `extract_theme_ir` + `calc_element_safe` chokepoint       | VERIFIED   | 228 lines; `calc_element_safe` 3-tier fallback + `.gg2d3_warn_once` + `.gg2d3_calc_element_default` table     |
| `R/ir_scales.R`     | `extract_scales_ir` + helpers                             | VERIFIED   | 305 lines                                                                                                     |
| `R/ir_layers.R`     | `extract_layers_ir`                                       | VERIFIED   | 133 lines; explicit `keep_aes` vector lifted out of orchestrator closure                                      |
| `R/ir_legends.R`    | `extract_legends_ir`                                      | VERIFIED   | 184 lines                                                                                                     |
| `R/ir_facets.R`     | `extract_facets_ir` with `<<-` removed                    | VERIFIED   | 269 lines; comments confirm `<<-` removed (Pitfall 2); explicit return `}, error = function(e) fallback)`     |
| `R/zzz.R`           | Package env `.gg2d3_pkgenv` + warn-once reset hook        | VERIFIED   | 17 lines                                                                                                      |

### Key Link Verification

| From                   | To                          | Via                                              | Status | Details                                                                                                  |
| ---------------------- | --------------------------- | ------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------- |
| `as_d3_ir()`           | `extract_scales_ir`         | direct call in orchestrator                      | WIRED  | `scales <- extract_scales_ir(b, pp_x, pp_y, is_flip = is_flip)`                                          |
| `as_d3_ir()`           | `extract_theme_ir`          | direct call                                      | WIRED  | `theme_ir <- extract_theme_ir(b)`                                                                        |
| `as_d3_ir()`           | `extract_layers_ir`         | direct call                                      | WIRED  | `layers <- extract_layers_ir(b, xscale_obj, yscale_obj)`                                                 |
| `as_d3_ir()`           | `extract_legends_ir`        | direct call                                      | WIRED  | `legends <- extract_legends_ir(b, p)`                                                                    |
| `as_d3_ir()`           | `extract_facets_ir`         | direct call with breaks/trans args               | WIRED  | `fp <- extract_facets_ir(b, pp_x, pp_y, scales, x_breaks=..., y_breaks=..., x_trans_name=..., is_flip=)` |
| `extract_theme_ir`     | `calc_element_safe`         | called for legend.key.size + every theme element | WIRED  | `R/ir_theme.R:175` (legend.key.size) + via `extract_theme_element` for all elements                      |
| `calc_element_safe`    | `ggplot2:::calc_element`    | Tier 1 tryCatch                                  | WIRED  | `R/ir_theme.R:26`                                                                                        |
| `calc_element_safe`    | `ggplot2::calc_element`     | Tier 2 public fallback                           | WIRED  | `R/ir_theme.R:34` — `theme_get() + theme` then public `calc_element`                                     |
| `calc_element_safe`    | `.gg2d3_calc_element_default` | Tier 3 static table                            | WIRED  | `R/ir_theme.R:42`                                                                                        |
| `calc_element_safe`    | `.gg2d3_pkgenv$calc_element_warned` | warn-once gate                            | WIRED  | `R/ir_theme.R:55` reads/writes; `R/zzz.R` provides env                                                   |
| `extract_layers_ir`    | `to_rows(df, keep_aes)`     | per-layer row export                             | WIRED  | `R/ir_layers.R:128`                                                                                      |

### Pitfall Fixes from RESEARCH.md

| Pitfall                                                         | Fix                                                                                | Status     | Evidence                                                                                                                                |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Pitfall 1: `keep_aes` was a closure-captured orchestrator local | Lift `keep_aes` into `R/ir_layers.R` and pass explicitly to `to_rows`              | APPLIED    | `R/ir_layers.R:13` defines `keep_aes <- c(...)`; `R/ir_layers.R:128` `to_rows(df, keep_aes)`; orchestrator has zero `keep_aes` matches |
| Pitfall 2: facet handler used `<<-` to mutate orchestrator vars | Return value-typed list and let orchestrator destructure                           | APPLIED    | `grep '<<-' R/` returns only comments documenting the removal; `R/ir_facets.R:268` uses explicit `error = function(e) fallback`        |
| Pitfall 3: dead outer `to_rows` definition in orchestrator      | Remove dead helper from orchestrator entirely                                      | APPLIED    | `grep 'to_rows' R/as_d3_ir.R` returns 0 matches; sole definition in `R/ir_utils.R:18`                                                  |

### NAMESPACE Diff (Phase 13 only)

```
$ git diff f7df9c8..HEAD -- NAMESPACE
(empty)
```

Public API surface unchanged. Roxygen `@export` on `as_d3_ir` preserved verbatim. The 2 export deletions (`d3_handlers`, `d3_transitions`) shown in `git diff master -- NAMESPACE` are from prior phase 12 work, not phase 13. Verified by diffing against the phase-13 baseline commit `f7df9c8` (last commit before phase 13 began).

### Test Suite Result (Live Re-Run)

```
[ FAIL 8 | WARN 19 | SKIP 2 | PASS 551 ]
```

Identical pass/fail counts to the baseline documented in `13-CONTEXT.md` and `13-07-SUMMARY.md`. The 8 failures are the pre-existing `coord_fixed` / `coord_trans` baseline failures in `test-ir.R` (lines 228-229 confirmed: `coord_fixed with default ratio=1`), `test-layout.R`, and `test-legends.R` — explicitly carved out as out-of-scope in `D-09` of `13-CONTEXT.md`. Every Phase-13-introduced test (`test-ir-{scales,theme,layers,legends,facets}.R`) is green.

### Anti-Patterns Found

None blocking.

| File             | Line | Pattern                                               | Severity | Impact                                                                                              |
| ---------------- | ---- | ----------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `R/ir_facets.R`  | —    | Comments referencing removed `<<-`                    | Info     | Documentation of Pitfall 2 fix — intentional, not a stub                                            |
| `R/ir_theme.R`   | 102/115 | Linewidth uses `3.7795275591` (CSS px-per-mm)       | Info     | Documented in MEMORY.md as ggplot2-incorrect but preserved for v1.0 byte-equivalence; out of scope |

### Requirements Coverage

| Requirement   | Source Plan | Description                                                                                              | Status     | Evidence                                                                                                       |
| ------------- | ----------- | -------------------------------------------------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------- |
| REFACTOR-01   | 13-01..07   | `as_d3_ir()` split into per-concern modules; top-level under ~200 lines; helpers independently testable | SATISFIED  | 5 modules created; orchestrator 120 lines (118-line body); test-ir-* files exercise each extractor             |
| REFACTOR-02   | 13-02       | `ggplot2:::calc_element()` wrapped in helper with public-API fallback                                   | SATISFIED  | `calc_element_safe()` 3-tier chain; private API referenced only inside that single helper in `R/ir_theme.R`    |

### Human Verification Required

None. The visual regression checkpoint (`test_output/phase13/*.html`, 8 plots) was completed and signed off by the user on 2026-05-04 per `13-07-SUMMARY.md`. All other gates are programmatically verifiable and verified above.

### Gaps Summary

No gaps. The phase achieved both stated requirements (REFACTOR-01, REFACTOR-02) with verified line-count gate (118 ≤ 210), single-chokepoint audit clean, all three documented pitfall fixes applied in code, identical test pass/fail counts to baseline, and zero NAMESPACE drift. Visual regression user sign-off recorded. Phase 13 is ready for downstream phases 14-16 to build on the new module boundaries.

---

_Verified: 2026-05-04_
_Verifier: Claude (gsd-verifier)_
