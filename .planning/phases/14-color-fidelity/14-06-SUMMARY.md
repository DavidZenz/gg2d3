---
phase: 14-color-fidelity
plan: 06
subsystem: js-renderer
tags: [js, d3, legend, colorbar, banded, horizontal]

requires:
  - phase: 14-color-fidelity
    provides: "Colorbar IR carries breaks, labels, domain, is_continuous, is_steps, bin_colors, orientation, legend_position (14-05)"
provides:
  - "renderColorbar consumes guide.breaks/labels/domain for ticks (Pitfall 5 fix)"
  - "renderColorbar branches smooth-vs-banded gradient on guide.is_steps + guide.bin_colors (Pitfall 8 fix)"
  - "renderColorbar branches vertical-vs-horizontal layout on guide.orientation (D-10)"
affects: [14-07-snapshots]

tech-stack:
  added: []
  patterns:
    - "console.assert defensive invariant on banded bin_colors length vs breaks - 1"
    - "Imperative if/else gradient axis attrs (per static-grep regex contract)"

key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/legend.js
    - tests/testthat/test-color-fidelity.R

key-decisions:
  - "Imperative if/else for gradient axes instead of ternary inside .attr() — required by Task 1 RED regex contract for x2=100% literal match"
  - "Banded gradient uses 2 paired stops per bin from guide.bin_colors[i] at offsets ((breaks[i,i+1]-d0)/range)*100"
  - "Horizontal tick layout: text-anchor='middle', placed below bar at y = barY + barHeight + 5 + textSize"
  - "Vertical tick layout preserved verbatim: ticks right of bar with dy=0.35em vertical centering"
  - "Tick proportion uses (break - domain[0]) / (domain[1] - domain[0]); skip non-finite breaks"

patterns-established:
  - "Renderer-side static-grep contract: function body must literally contain key field names + literal '100%' for horizontal x2"

requirements-completed: [COLOR-02]

duration: 8min
completed: 2026-05-07
---

# Phase 14 Plan 06: renderColorbar Rewrite Summary

**Rewrote `renderColorbar` in `inst/htmlwidgets/modules/legend.js` to consume the IR fields landed in plan 14-05: ticks now come from `guide.breaks`/`guide.labels`/`guide.domain` instead of first/last keys; `guide.is_steps` + `guide.bin_colors` triggers a banded 2-stops-per-bin gradient; `guide.orientation === "horizontal"` swaps gradient axes, bar dimensions, and tick placement.**

## Performance

- **Duration:** ~8 min
- **Tasks:** 2 (RED + GREEN)
- **Files modified:** 2
- **Net change in renderColorbar:** -42 / +82 lines (smooth path retained, banded + horizontal branches added)

## Branches Added

| is_steps | orientation | Behavior |
|----------|-------------|----------|
| FALSE    | vertical    | Smooth 30-stop gradient, ticks right of bar (existing path, generalized to walk `guide.breaks`) |
| FALSE    | horizontal  | Smooth 30-stop gradient with `x2=100%`, bar 5×keySize wide × keySize tall, ticks below |
| TRUE     | vertical    | Banded 2-stops-per-bin from `guide.bin_colors`, ticks right of bar |
| TRUE     | horizontal  | Banded 2-stops-per-bin with `x2=100%`, bar wider than tall, ticks below |

## Task Commits

1. **Task 1: RED — static assertions** — `3bac6fd` (test)
2. **Task 2: GREEN — rewrite renderColorbar** — `43bfcab` (feat)

## Files Created/Modified

- `inst/htmlwidgets/modules/legend.js` — `renderColorbar` body rewritten (lines ~433-572). New control flow: orientation branch sets bar dims → title → gradient defs (if/else for x1/x2/y1/y2) → smooth/banded stop generation → bar rect → break-walking tick loop with horizontal/vertical sub-branches.
- `tests/testthat/test-color-fidelity.R` — 2 skip-pending stubs flipped to real static-grep assertions (regmatches → regexpr-extract `function renderColorbar` body → assert presence of `guide.breaks`, `guide.labels`, `guide.domain`, `guide.is_steps|guide.bin_colors`, absence of endKeys hardcode, presence of `guide.orientation`, `"horizontal"`, and `x2 ... "100%"`).

## RED → GREEN

- **Before Task 2:** test-color-fidelity.R had 1 fail (orientation block — first block actually grepped `guide.breaks` against the OLD body, but it lacked the field, hence RED). Suite snapshot at RED: 8 baseline + 1 new = 9 fails.
- **After Task 2:** Both new blocks GREEN. Suite: 599 PASS / 8 FAIL / 13 SKIP.

## Suite vs Baseline

- **14-05 baseline:** 589 PASS / 8 FAIL / 15 SKIP
- **14-06 result:** 599 PASS / 8 FAIL / 13 SKIP
- **Delta:** +10 passes (2 new flipped + 8 from broader load_all coverage), -2 skips, **8 baseline FAILs unchanged** (test-ir.R::coord_fixed pre-existing, out-of-scope).

## Decisions Made

- **Imperative if/else gradient axes instead of ternary inside `.attr()`** — the Task 1 RED regex `x2"?,?\s*["']100%["']` requires the literal `"x2", "100%"` form. A `.attr("x2", isHorizontal ? "100%" : "0%")` form passed unit smoke but failed the contract. Changed to:
  ```js
  if (isHorizontal) gradient.attr("x1","0%").attr("x2","100%").attr("y1","0%").attr("y2","0%");
  else              gradient.attr("x1","0%").attr("x2","0%" ).attr("y1","100%").attr("y2","0%");
  ```
- **`console.assert` invariant** kept on banded path — guide.bin_colors.length must equal breaks.length - 1 (D-06 contract from 14-05 IR).
- **Tick proportion uses `(b - d0) / range`** — not `parseFloat(key.value)` — so ticks land at correct fraction of bar even when breaks are not domain endpoints.
- **`isFinite(b)` skip** in tick loop — defensive against NA/null breaks slipping through IR.

## Deviations from Plan

**1. [Rule 3 — Test contract] Restructured gradient-axis assignment from ternary to imperative if/else**
- **Found during:** Task 2 verification — the test in Task 1 uses regex `x2"?,?\s*["']100%["']` which requires the literal `"x2", "100%"` adjacency.
- **Issue:** The plan's skeleton used `.attr("x2", isHorizontal ? "100%" : "0%")` which doesn't match the regex (extra `, isHorizontal ? ` between `"x2"` and `"100%"`).
- **Fix:** Replaced the 4 ternary `.attr()` calls with an imperative `if (isHorizontal) {...} else {...}` block emitting literal `.attr("x2", "100%")`. Functionally identical; satisfies the static-grep contract.
- **Files modified:** `inst/htmlwidgets/modules/legend.js`
- **Commit:** `43bfcab`

**Total deviations:** 1 (cosmetic, contract-driven).
**Impact on plan:** None. Same runtime behavior.

## Known Stubs

- **`calculateLegendSize` colorbar branch (`inst/htmlwidgets/modules/legend.js` ~line 166-185)** still uses `[guide.keys[0], guide.keys[guide.keys.length - 1]]` to estimate label width for legend bounding box. This is sizing-only logic (not visible ticks) and is OUT OF SCOPE per the plan's renderer-only focus. It estimates a width based on min/max labels, which is conservative — actual ticks may now exceed the estimated box for non-endpoint breaks. Plan 14-07's snapshot corpus may surface clipping; if so, fix in a follow-up plan or 14-07 deviation.

## Verification

- **Field reference grep:** `grep -cE 'guide\.breaks|guide\.labels|guide\.domain' inst/htmlwidgets/modules/legend.js` → 4 (target ≥3).
- **`guide.is_steps`:** 1 match (target ≥1).
- **`guide.orientation`:** 1 match in renderColorbar (target ≥1).
- **`"horizontal"`:** 1 match in renderColorbar (target ≥1; +7 in unrelated discrete-legend `direction` paths).
- **`console.assert`:** 1 match (target ≥1).
- **endKeys hardcode in renderColorbar:** none (verified via static-grep test).
- **Suite:** 599 PASS / 8 FAIL / 13 SKIP — 8 baseline failures unchanged.

## Next Phase Readiness

Plan 14-07 (snapshot corpus + manual checkpoints) will exercise both branches:
- Smooth+vertical: `scale_color_viridis_c()` default theme
- Smooth+horizontal: `scale_color_viridis_c() + theme(legend.position="bottom")`
- Banded+vertical: `scale_color_steps()` default theme
- Banded+horizontal: `scale_color_steps() + theme(legend.position="bottom")`

## Self-Check: PASSED

- File `inst/htmlwidgets/modules/legend.js` exists and `renderColorbar` consumes all 4 required IR fields.
- Commits `3bac6fd` (test) and `43bfcab` (feat) present in git log.
- Suite delta verified (599 PASS / 8 FAIL / 13 SKIP).
- All 6 exit criteria from PLAN.md met within renderColorbar scope (calculateLegendSize endKeys reference flagged as out-of-scope known stub).

---
*Phase: 14-color-fidelity*
*Completed: 2026-05-07*
