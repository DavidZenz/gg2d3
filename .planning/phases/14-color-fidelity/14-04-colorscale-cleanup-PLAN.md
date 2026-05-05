---
phase: 14
plan: 04
type: execute
wave: 1
depends_on: ["14-01"]
files_modified:
  - R/ir_scales.R
  - inst/htmlwidgets/gg2d3.js
  - inst/htmlwidgets/modules/geom-registry.js
  - tests/testthat/test-ir-scales.R
autonomous: true
requirements: [COLOR-01]
tags: [r-package, js, dead-code, color, refactor]

must_haves:
  truths:
    - "ir.scales.color is no longer emitted by extract_scales_ir (Pitfall 3 dead code removed)"
    - "gg2d3.js no longer constructs a turbo/Tableau10 colorScale"
    - "makeColorAccessors no longer references options.colorScale fallback path"
    - "Per-row hex passthrough still works for viridis_c, brewer, distiller, manual (Pitfall 6)"
    - "Existing test-ir-scales.R assertions about scales$color removed or updated"
    - "Phase-13 baseline FAILs unchanged"
  artifacts:
    - path: "R/ir_scales.R"
      provides: "scales$color block deleted"
      contains: "scales <- list("
    - path: "inst/htmlwidgets/gg2d3.js"
      provides: "Dead colorScale construction removed"
      contains: "ir.layers"
    - path: "inst/htmlwidgets/modules/geom-registry.js"
      provides: "makeColorAccessors no longer falls through to colorScale(v)"
      contains: "makeColorAccessors"
  key_links:
    - from: "inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors"
      to: "isValidColor + convertColor"
      via: "deterministic per-row hex passthrough"
      pattern: "isValidColor"
---

<objective>
Excise the dead-code colorScale path identified in research Pitfalls 3 + 7. Three coupled removals:

1. `R/ir_scales.R` lines 295-302 — delete the `scales$color` block. `is.numeric(allc)` is permanently FALSE because `ggplot_build()` resolves color to character hex; the block silently produces a misleading `type="categorical"` and a meaningless `domain`. No consumer needs it after the cleanup below.
2. `inst/htmlwidgets/gg2d3.js:79-84` — delete the `colorScale` construction. Pass `null` (or omit the field) instead of `colorScale: colorScale` in the geom render call.
3. `inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors` — drop the `colorScale(v)` fallback branch (only reached for invalid color strings, which `ggplot_build()` never emits). Simplify to `isValidColor → convertColor` then param fallback.

Why now: leaving the broken `interpolateTurbo` fallback in place silently masks any future fall-through (e.g. if a new geom emits a non-hex value), producing visually wrong colors that pass char-for-char tests because of the `convertColor` round-trip. Deletion makes the color path deterministic.

NOTE: This plan runs in parallel with 14-02 (Wave 1). The two plans touch disjoint files — 14-02 touches `inst/htmlwidgets/modules/constants.js` + `tests/testthat/test-color-fidelity.R`, while 14-04 touches `R/ir_scales.R`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/geom-registry.js`, and `tests/testthat/test-ir-scales.R`. Zero overlap.

Output: smaller `R/ir_scales.R` (~10 lines deleted), smaller `gg2d3.js` (~6 lines deleted), simpler `makeColorAccessors`, updated test-ir-scales.R.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@R/ir_scales.R
@inst/htmlwidgets/gg2d3.js
@inst/htmlwidgets/modules/geom-registry.js
@tests/testthat/test-ir-scales.R
@R/ir_layers.R
</inputs>

<outputs>
- `R/ir_scales.R` — `scales$color` block removed (lines 295-302).
- `inst/htmlwidgets/gg2d3.js` — `cdesc`/`colorScale` lines 79-84 removed; render call updated.
- `inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors` — `colorScale(v)` fallback removed in both `strokeColor` and `fillColor` branches; ~10 lines net.
- `tests/testthat/test-ir-scales.R` — any assertion targeting `ir$scales$color` removed or rewritten to assert the field is absent.
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: TEST — RED assertion that ir$scales$color is absent; update existing scales test</name>
  <files>tests/testthat/test-ir-scales.R</files>
  <read_first>
    - tests/testthat/test-ir-scales.R — search for any test referencing `scales$color`, `ir$scales$color`, or `categorical`. Each one needs an update.
    - R/ir_scales.R lines 295-302 — confirm the block exists exactly as research describes.
  </read_first>
  <behavior>
    - Test (new): For a continuous-color plot, `as_d3_ir(p)$scales$color` is NULL.
    - Test (new): For a discrete-color plot, `as_d3_ir(p)$scales$color` is NULL.
    - Existing assertions about `ir$scales$color$type == "categorical"`: rewrite to `expect_null(ir$scales$color)` or delete (research Pitfall 3 confirms no consumer).
  </behavior>
  <action>
First grep for existing references:

```bash
grep -nE 'scales\$color|scales\\.color' tests/testthat/test-ir-scales.R
```

For each hit:
- If it asserts `type == "categorical"` or `type == "continuous"` → replace with `expect_null(ir$scales$color)`.
- If it asserts `domain` length or contents → delete; the field is going away.

Append two new assertions:

```r
test_that("ir$scales$color is no longer emitted (Pitfall 3 dead-code removed)", {
  library(ggplot2)
  p_cont <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point()
  p_disc <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  expect_null(as_d3_ir(p_cont)$scales$color)
  expect_null(as_d3_ir(p_disc)$scales$color)
})
```

Run the suite. The new assertion is RED until Task 2 runs.

Commit:
```
git add tests/testthat/test-ir-scales.R
git commit -m "test(14-04): RED — assert ir$scales$color is absent"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_file("tests/testthat/test-ir-scales.R", reporter="silent"); failed <- sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_failure"), logical(1))), integer(1))); stopifnot(failed >= 1)'</automated>
  </verify>
  <done>test-ir-scales.R updated; new assertion fails RED; existing scales-color assertions normalized.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: IMPL — delete dead colorScale path across R + JS; verify GREEN</name>
  <files>R/ir_scales.R, inst/htmlwidgets/gg2d3.js, inst/htmlwidgets/modules/geom-registry.js</files>
  <action>
**Part A — `R/ir_scales.R`:** Delete lines 295-302 (the `# Color scale — lifted from the orchestrator's allc + dom(allc) block.` block through the trailing `}`). The `scales` list returned at line 304 simply omits `color`.

Verify post-edit:
```bash
grep -c 'scales\$color' R/ir_scales.R   # → 0
```

**Part B — `inst/htmlwidgets/gg2d3.js`:** Edit lines 78-84. Delete the `cdesc`/`colorScale` block:

Before:
```js
// Color scale (same for all panels)
const cdesc = ir.scales && ir.scales.color;
const colorScale = cdesc
  ? (cdesc.type === "continuous"
      ? d3.scaleSequential(d3.interpolateTurbo).domain(d3.extent(cdesc.domain || [0, 1]))
      : d3.scaleOrdinal(d3.schemeTableau10).domain(cdesc.domain || []))
  : function() { return null; };
```

After: delete entirely. Then update the geom-registry call site (around line 96-101). Replace `{ colorScale: colorScale, plotWidth: w, plotHeight: h, flip: flip }` with `{ plotWidth: w, plotHeight: h, flip: flip }`.

Verify:
```bash
grep -c 'colorScale' inst/htmlwidgets/gg2d3.js  # → 0
```

**Part C — `inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors`:** Read the function (around lines 127-191). Two color closures (`strokeColor` and `fillColor`) each contain a fallthrough:

```js
const mapped = colorScale(v);
return mapped || convertColor(params.colour) || "currentColor";
```

Replace both fallthroughs with the param fallback only:

```js
return convertColor(params.colour) || "currentColor";
```

(Mirror the change for `fillColor` with `params.fill`.) Also delete the destructuring of `colorScale` from the `options` parameter — `makeColorAccessors(aes, params, options)` no longer reads it.

Verify:
```bash
grep -c 'colorScale' inst/htmlwidgets/modules/geom-registry.js  # → 0
```

**Static check on Pitfall 6 invariant:** Confirm `R/ir_layers.R` still passes the `colour` column through (this is the deterministic per-row hex passthrough that the deleted colorScale fallback was masking):

```bash
Rscript -e 'stopifnot(any(grepl("colour", readLines("R/ir_layers.R"))))'
```

This guards against a future regression that strips the colour column without noticing — the dead-code removal makes such a regression user-visible (rows render `currentColor` instead of correct hex), so an explicit guard is cheap insurance.

**Run the suite:**
```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'
```

Expected: RED test from Task 1 now GREEN. All viridis_c/brewer/distiller/manual per-row colors still pass through correctly because the fast path `isValidColor → convertColor` is untouched (Pitfall 6).

Commit:
```
git add R/ir_scales.R inst/htmlwidgets/gg2d3.js inst/htmlwidgets/modules/geom-registry.js
git commit -m "fix(14-04): delete dead colorScale path (Pitfalls 3+7)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); stopifnot(any(grepl("colour", readLines("R/ir_layers.R")))); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>scales$color removed from R; colorScale construction removed from gg2d3.js; makeColorAccessors fallback simplified; Task 1 RED test now GREEN; phase-13 baseline FAILs unchanged.</done>
</task>

</tasks>

<exit_criteria>
- `grep -c 'scales\$color' R/ir_scales.R` equals 0.
- `grep -c 'colorScale' inst/htmlwidgets/gg2d3.js` equals 0.
- `grep -c 'colorScale' inst/htmlwidgets/modules/geom-registry.js` equals 0.
- `expect_null(ir$scales$color)` test passes.
- Pitfall 6 invariant: `grep colour R/ir_layers.R` returns ≥1 match.
- Full suite: phase-13 baseline FAILs unchanged.
- Two atomic commits (RED then GREEN).
</exit_criteria>

<threat_model>
No threat surface — package internals only. Dead-code removal across R and JS layers.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-04-SUMMARY.md` with line-counts deleted (R + JS) and confirmation that the per-row passthrough still produces correct hex.
</output>
