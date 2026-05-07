---
phase: 14-color-fidelity
plan: 05
subsystem: ir
tags: [r-package, ggplot2, legends, colorbar, ir-enrichment, d10-orientation]

requires:
  - phase: 14-color-fidelity
    provides: "is_steps flag + ScaleBinned -> colorbar routing (14-03)"
provides:
  - "Colorbar IR carries breaks, labels, na.value, domain, is_continuous, bin_colors"
  - "Colorbar IR carries orientation (vertical/horizontal) + raw legend_position (D-10)"
  - "Per-bin colors via scale_obj$map(midpoints) for banded steps gradients (D-06)"
affects: [14-06-colorbar-render, 14-07-snapshots]

tech-stack:
  added: []
  patterns:
    - "tryCatch wrappers around scale_obj accessors for resilience"
    - "Plot-level theme overrides global theme; falls back to 'right' = vertical"

key-files:
  created: []
  modified:
    - R/ir_legends.R
    - tests/testthat/test-ir-legends.R
    - tests/testthat/test-color-fidelity.R

key-decisions:
  - "Emit bin_colors (midpoint mapping) only when is_steps=TRUE and length(breaks)>=2; NULL otherwise"
  - "Numeric legend.position (inside-plot c(x,y)) treated as 'right' vertical for now (v1.2 concern)"
  - "Smooth colorbar keeps 30 sampled stops (D-09) — no behavior change to colors_array"
  - "Plot-level theme$legend.position takes precedence over ggplot2::theme_get()"

patterns-established:
  - "Colorbar IR enrichment block: domain -> colors_array -> breaks -> labels -> na.value -> bin_colors -> orientation"
  - "Banded gradient hint: midpoints between breaks paired with scale_obj$map for renderer"

requirements-completed: [COLOR-02]

duration: 6min
completed: 2026-05-07
---

# Phase 14 Plan 05: Colorbar IR Enrichment Summary

**Enriched colorbar guide_spec in `R/ir_legends.R` with breaks/labels/na.value/domain/is_continuous/bin_colors and D-10 orientation/legend_position so plan 14-06's renderColorbar can draw proper ticks, NA metadata, banded gradients, and horizontal/vertical layouts.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-07T05:08:00Z
- **Completed:** 2026-05-07T05:14:53Z
- **Tasks:** 2 (RED + GREEN)
- **Files modified:** 3

## Accomplishments

- 8 new IR fields on colorbar guides: `is_continuous`, `breaks`, `labels`, `na.value`, `domain`, `bin_colors`, `orientation`, `legend_position`
- D-10 orientation logic: vertical default; flips horizontal for `legend.position` of "top" or "bottom"
- D-06 banded gradient prep: per-bin colors via midpoint mapping (`scale_obj$map((b[-n] + b[-1])/2)`)
- D-08 ticks ready: breaks/labels harvested from `scale_obj$get_breaks` / `$get_labels`
- D-11 NA metadata: `scale_obj$na.value %||% "grey50"` carried on every colorbar guide
- 5 new test_that blocks; 2 skip-pending blocks in test-color-fidelity.R flipped to real assertions
- Suite: 566 PASS / 8 FAIL / 17 SKIP baseline → 589 PASS / 8 FAIL / 15 SKIP (8 baseline FAILs unchanged; +23 passes; -2 skips)

## Task Commits

1. **Task 1: RED — colorbar IR enrichment + orientation tests** — `3c4eb6f` (test)
2. **Task 2: GREEN — enrich colorbar branch** — `5cf65e2` (feat)

## Files Created/Modified

- `R/ir_legends.R` — colorbar branch grew ~50 lines: domain capture, breaks/labels harvest, na.value default, midpoint bin_colors for banded, orientation derivation. `guide_spec` list grew from 7 to 15 fields.
- `tests/testthat/test-ir-legends.R` — +3 test_that blocks (~58 lines) covering field presence, orientation across 4 legend.position values, and bin_colors for ScaleBinned.
- `tests/testthat/test-color-fidelity.R` — 2 skip-pending stubs flipped to real assertions exercising the helpers (`scale_by_aes`, `scale_reference_breaks`, `scale_reference_labels`, `guide_by_aes`).

## Sample IR Dump

`as_d3_ir(p)$guides[[1]]` for `ggplot(mtcars, aes(wt, mpg, colour=hp)) + geom_point() + scale_color_viridis_c()`:

**Default theme (vertical):**
```
$ aesthetic      : "colour"
$ type           : "colorbar"
$ title          : "hp"
$ keys           : List of 5
$ colors         : chr [1:30] "#440154" "#45125C" "#461E65" ...
$ is_steps       : FALSE
$ is_continuous  : TRUE
$ breaks         : num [1:7] 50 100 150 200 250 300 350
$ labels         : chr [1:7] "50" "100" "150" "200" ...
$ na.value       : "grey50"
$ domain         : num [1:2] 52 335
$ bin_colors     : NULL
$ orientation    : "vertical"
$ legend_position: "right"
```

**With `theme(legend.position = "bottom")` (horizontal):**
```
$ orientation    : "horizontal"
$ legend_position: "bottom"
(all other fields identical)
```

## Decisions Made

- **bin_colors only for ScaleBinned with ≥2 breaks** — avoids ambiguous output for smooth scales; NULL serializes out of JSON cleanly.
- **`b$plot$theme$legend.position` first, then `ggplot2::theme_get()`** — plot-level overrides global; fallback to `"right"` keeps non-character values (numeric inside-plot positioning) defaulting to vertical until v1.2.
- **30 sampled stops kept verbatim** — D-09 mandate; only smooth-gradient colors_array path is unchanged behaviorally.
- **`unname()` on domain and breaks** — ggplot2 sometimes attaches names; tests compare via `unname` so we strip at IR boundary.

## Deviations from Plan

None — plan executed exactly as written. The only nominal cosmetic change: variable name `legend_position` was renamed to `legend_position_g` inside the colorbar branch to avoid shadowing the function-scope `legend_position` declared at the top of `extract_legends_ir`. This is a Rule 3 lexical fix (would have produced wrong field on guides where guide_type != "colorbar"), purely internal.

**Total deviations:** 0 (1 trivial local-variable rename)
**Impact on plan:** None.

## Issues Encountered

None.

## Verification

- **Field reference grep:** `grep -cE 'breaks|labels|na\.value|is_continuous|bin_colors|orientation|legend_position' R/ir_legends.R` → 30 (target ≥10).
- **Suite delta:** +23 passes (566→589), -2 skips, 8 baseline failures unchanged (test-ir.R::coord_fixed pre-existing, out of scope).
- **Sample dump:** confirmed orientation flips on `theme(legend.position="bottom")` + bin_colors populated for `scale_color_steps()`.

## Next Phase Readiness

- Plan 14-06 (renderColorbar JS) has every field needed:
  - smooth gradient: `colors_array` (30 stops)
  - banded gradient: `bin_colors` + `breaks` for 2-stop-per-bin construction
  - ticks: `breaks` + `labels` + `domain`
  - NA swatch: `na.value`
  - layout: `orientation` ("vertical" | "horizontal") + `legend_position` raw
- Plan 14-07 snapshot corpus can rely on these fields for fixture generation.

## Self-Check: PASSED

- File `R/ir_legends.R` exists and contains all 8 new fields on `guide_spec`.
- Commits `3c4eb6f` (test) and `5cf65e2` (feat) present in git log.
- Suite delta verified.

---
*Phase: 14-color-fidelity*
*Completed: 2026-05-07*
