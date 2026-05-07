---
phase: 14
plan: 04
subsystem: color, refactor, dead-code
tags: [r-package, js, refactor, color, dead-code]
requires:
  - 14-01 (test scaffold landed)
provides:
  - "ir.scales.color field eliminated from IR contract"
  - "Deterministic per-row hex passthrough is the only color path"
affects:
  - R/ir_scales.R
  - inst/htmlwidgets/gg2d3.js
  - inst/htmlwidgets/modules/geom-registry.js
  - tests/testthat/test-ir-scales.R
tech-stack:
  added: []
  patterns:
    - "Dead-code excision: delete masking fallback so future regressions are user-visible"
key-files:
  created: []
  modified:
    - path: R/ir_scales.R
      change: "Removed scales$color block (lines 295-302). is.numeric(allc) was permanently FALSE — block silently emitted misleading type=categorical with meaningless domain. -8 LOC."
    - path: inst/htmlwidgets/gg2d3.js
      change: "Deleted cdesc/colorScale construction (interpolateTurbo / schemeTableau10) and removed colorScale from geom render options. -8 LOC."
    - path: inst/htmlwidgets/modules/geom-registry.js
      change: "Simplified makeColorAccessors: dropped colorScale(v) fallback in both strokeColor and fillColor closures. Removed JSDoc options.colorScale references. Per-row hex passthrough (isValidColor → convertColor) is now the only path."
    - path: tests/testthat/test-ir-scales.R
      change: "Replaced scales$color presence assertion with expect_null(ir$scales$color) and expect_null(s$color)."
decisions:
  - "Pitfall 3+7 fix is a pure deletion — no replacement abstraction. Per-row hex from ggplot_build is already correct (Pitfall 6) and the dead colorScale was masking failures."
  - "Kept Pitfall 6 invariant guard implicit: R/ir_layers.R still references colour column at lines 15 + 93 (verified by grep)."
metrics:
  duration_minutes: 8
  completed: 2026-05-07
  tasks_completed: 2
  loc_deleted_r: 8
  loc_deleted_js: 16
---

# Phase 14 Plan 04: ColorScale Cleanup Summary

**One-liner:** Excised dead colorScale path (turbo/Tableau10 fallback) — `ir.scales.color` no longer emitted, `makeColorAccessors` simplified to deterministic per-row hex passthrough only.

## What Was Done

### R Layer (`R/ir_scales.R`)
Deleted the trailing `scales$color` block (8 lines). The block computed `allc <- unlist(...colour columns)` then keyed `type` on `is.numeric(allc)` — but `ggplot_build()` always resolves colour to character hex strings before this code runs, so `is.numeric()` was permanently FALSE. The block silently emitted `type="categorical"` with a domain of unique hex strings, which no consumer needed after the JS-side cleanup.

### JS Layer (`inst/htmlwidgets/gg2d3.js`)
Deleted the `cdesc`/`colorScale` construction block (8 lines, including the `interpolateTurbo` continuous fallback and `schemeTableau10` discrete fallback). Updated the geom-registry render call to omit `colorScale` from options.

### JS Layer (`inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors`)
Removed the `const colorScale = options.colorScale || (() => null);` destructure. Removed the `mapped = colorScale(v); return mapped || ...` branch from both `strokeColor` and `fillColor` closures. The fast path `isValidColor → convertColor` plus param fallback is now the only path. JSDoc references to `options.colorScale` removed in two locations.

### Test (`tests/testthat/test-ir-scales.R`)
Replaced the existing `expect_true(!is.null(s$color))` test (which incorrectly documented v1.0 categorical-only behaviour as intentional) with `expect_null` assertions for both the full pipeline (`as_d3_ir`) and the direct extractor (`extract_scales_ir`), covering both continuous (`hp`) and discrete (`factor(cyl)`) color aesthetics.

## Verification

- **TDD gates:** RED commit `84ffe20` (test asserting absence, fails); GREEN commit `e2e45b6` (deletion makes it pass).
- **Exit criteria:**
  - `grep -c 'scales\$color' R/ir_scales.R` = 0 ✓
  - `grep -c 'colorScale' inst/htmlwidgets/gg2d3.js` = 0 ✓
  - `grep -c 'colorScale' inst/htmlwidgets/modules/geom-registry.js` = 0 ✓
  - `grep -c 'colour' R/ir_layers.R` = 2 (Pitfall 6 invariant intact) ✓
- **Suite:** 554 PASS / 8 FAIL / 20 SKIP — identical to post-14-02 baseline. The 8 failures are all pre-existing `coord_fixed` baseline (out of scope per plan).

## Pitfall 6 Invariant — Per-row Passthrough Still Works

The deletion makes the color path deterministic: every per-row colour from `ggplot_build()` flows through `R/ir_layers.R` (lines 15 + 93 still reference `"colour"`) into the layer data, then through `makeColorAccessors` via the `isValidColor → convertColor` fast path. Viridis_c, brewer, distiller, and manual scales all resolve to hex strings server-side and now have only one rendering path on the client. Any future regression that strips the colour column is now user-visible (rows render `currentColor`/`grey35` instead of correct hex) instead of being silently masked by the turbo/Tableau10 fallback.

## Deviations from Plan

None — plan executed exactly as written. Two atomic commits (RED then GREEN), exact line counts as predicted (~8 R lines, ~16 JS lines including the registry simplification and JSDoc tidy).

## Self-Check

- [x] R/ir_scales.R modified (verified by grep)
- [x] inst/htmlwidgets/gg2d3.js modified (verified by grep)
- [x] inst/htmlwidgets/modules/geom-registry.js modified (verified by grep)
- [x] tests/testthat/test-ir-scales.R modified
- [x] Commit 84ffe20 (test RED) present
- [x] Commit e2e45b6 (fix) present
- [x] Suite count = 554/8/20 matches pre-plan baseline

## Self-Check: PASSED
