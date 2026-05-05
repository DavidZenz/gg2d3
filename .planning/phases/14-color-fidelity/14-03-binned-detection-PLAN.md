---
phase: 14
plan: 03
type: execute
wave: 2
depends_on: ["14-01", "14-02"]
files_modified:
  - R/ir_legends.R
  - tests/testthat/test-color-fidelity.R
  - tests/testthat/test-ir-legends.R
autonomous: true
requirements: [COLOR-02]
tags: [r-package, ggplot2, legends, colorbar, binned, scale-steps]

must_haves:
  truths:
    - "extract_legends_ir routes scale_*_steps / scale_*_binned to guide_type=colorbar"
    - "Guide spec for binned scales carries is_steps=TRUE"
    - "Guide spec for non-binned continuous color carries is_steps=FALSE"
    - "viridis_c and distiller continue to emit colorbar (no regression)"
    - "viridis_d, brewer-discrete, manual still emit type=legend (no regression)"
  artifacts:
    - path: "R/ir_legends.R"
      provides: "Continuous predicate widened to include ScaleBinned; is_steps flag emitted"
      contains: "ScaleBinned"
  key_links:
    - from: "R/ir_legends.R"
      to: "ggplot2::ScaleBinned"
      via: "inherits(scale_obj, c(\"ScaleContinuous\",\"ScaleBinned\"))"
      pattern: "ScaleBinned"
---

<objective>
Fix Pitfall 2 from the research: `R/ir_legends.R:59` predicates `is_continuous` solely on `inherits(scale_obj, "ScaleContinuous")`, but `ScaleBinned` (the class behind `scale_*_steps` / `scale_*_binned`) inherits from `Scale` directly. Result: binned color scales today emit `type="legend"` instead of `type="colorbar"`, contradicting D-06.

Widen the predicate to also match `ScaleBinned`, and add an `is_steps` boolean to the guide spec so the JS renderer (plan 14-06) can branch smooth-vs-banded.

This plan also fills two pending COLOR-02 trigger tests in `test-color-fidelity.R`.

Purpose: COLOR-02 (D-06). Unblocks plan 14-05's IR enrichment (which assumes the binned branch reaches the colorbar block) and plan 14-06's banded gradient renderer.

NOTE: This plan runs in Wave 2 (after 14-02) because both plans edit `tests/testthat/test-color-fidelity.R`. Sequencing prevents file-write conflicts.

Output:
- `R/ir_legends.R` — predicate widened (~3 lines) + `is_steps` field added to guide_spec (1 line).
- `tests/testthat/test-ir-legends.R` — add 2 assertions: binned routes to colorbar; is_steps flag set.
- `tests/testthat/test-color-fidelity.R` — flip 3 skip-pending blocks (viridis_c/distiller/steps colorbar trigger).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-CONTEXT.md
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@R/ir_legends.R
@tests/testthat/test-ir-legends.R
@tests/testthat/test-color-fidelity.R
@tests/testthat/helper-color.R
</inputs>

<outputs>
- `R/ir_legends.R` lines ~59-61 — predicate widened; ~line ~123 — `is_steps` added to guide_spec.
- `tests/testthat/test-ir-legends.R` — +2 test_that blocks (~30 lines).
- `tests/testthat/test-color-fidelity.R` — 3 skip-pending → real assertions (~40 lines net).
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: TEST — RED assertions for binned colorbar routing and is_steps flag</name>
  <files>tests/testthat/test-color-fidelity.R, tests/testthat/test-ir-legends.R</files>
  <behavior>
    - test-color-fidelity.R: viridis_c emits guide.type=="colorbar" with length(colors) >= 30.
    - test-color-fidelity.R: distiller emits guide.type=="colorbar".
    - test-color-fidelity.R: scale_color_steps emits guide.type=="colorbar" AND is_steps==TRUE.
    - test-ir-legends.R (new): scale_color_steps routes to colorbar; is_steps TRUE.
    - test-ir-legends.R (new): viridis_c is_steps == FALSE (smooth, not binned).
    - The steps tests are RED today (currently routes to "legend" per Pitfall 2).
  </behavior>
  <action>
**Part A — `tests/testthat/test-color-fidelity.R`:** Replace these three blocks (currently `skip(...)`):

```r
test_that("viridis_c emits guide.type colorbar with >=30 stops", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
    scale_color_viridis_c()
  g <- guide_by_aes(p, "colour")
  expect_false(is.null(g))
  expect_equal(g$type, "colorbar")
  expect_gte(length(g$colors), 30L)
})

test_that("distiller emits guide.type colorbar", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
    scale_color_distiller(palette = "Spectral")
  g <- guide_by_aes(p, "colour")
  expect_false(is.null(g))
  expect_equal(g$type, "colorbar")
})

test_that("scale_color_steps emits guide.type colorbar with is_steps TRUE", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
    scale_color_steps()
  g <- guide_by_aes(p, "colour")
  expect_false(is.null(g))
  expect_equal(g$type, "colorbar")
  expect_true(isTRUE(g$is_steps))
})
```

**Part B — `tests/testthat/test-ir-legends.R`:** Append:

```r
test_that("ScaleBinned (scale_color_steps) routes to colorbar with is_steps TRUE", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_steps()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  steps_guide <- Filter(function(g) identical(g$aesthetic, "colour"), L$guides)[[1]]
  expect_equal(steps_guide$type, "colorbar")
  expect_true(isTRUE(steps_guide$is_steps))
})

test_that("viridis_c carries is_steps FALSE (smooth, not binned)", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_viridis_c()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  c_guide <- Filter(function(g) identical(g$aesthetic, "colour"), L$guides)[[1]]
  expect_equal(c_guide$type, "colorbar")
  expect_false(isTRUE(c_guide$is_steps))
})
```

Run the suite — the steps test (`g$type == "colorbar"`) is RED today (currently `"legend"`). The 3 viridis_c-and-distiller tests assert `g$type == "colorbar"` against current behavior that already routes ScaleContinuous correctly, so those 2 may already pass — but the new steps assertion is the genuine RED. Verifier asserts `failed >= 3` to catch the case where the predicate is silently broken in more places (e.g. `expect_gte(length(g$colors), 30L)` fails if the colorbar branch isn't reached for steps).

Commit:
```
git add tests/testthat/test-color-fidelity.R tests/testthat/test-ir-legends.R
git commit -m "test(14-03): RED — binned colorbar routing and is_steps flag"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_dir("tests/testthat", reporter="silent"); failed <- sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_failure"), logical(1))), integer(1))); stopifnot(failed >= 3)'</automated>
  </verify>
  <done>2 new test_that in test-ir-legends.R; 3 flipped from skip in test-color-fidelity.R; full suite shows ≥3 new RED relative to phase-13 baseline.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: IMPL — widen continuous predicate; add is_steps to guide_spec</name>
  <files>R/ir_legends.R</files>
  <action>
Edit `R/ir_legends.R`. Two surgical changes:

**Change 1 — Widen predicate at line 59:**

Before:
```r
is_continuous <- inherits(scale_obj, "ScaleContinuous")
is_color_aes <- aes_name %in% c("colour", "fill")
guide_type <- if (is_continuous && is_color_aes) "colorbar" else "legend"
```

After:
```r
# ScaleBinned (scale_*_steps / scale_*_binned) does NOT inherit from ScaleContinuous,
# so we must enumerate both. ggplot2's default guide for binned color is
# guide_coloursteps, which is a banded colorbar — see Phase 14 D-06.
is_continuous <- inherits(scale_obj, c("ScaleContinuous", "ScaleBinned"))
is_steps <- inherits(scale_obj, "ScaleBinned")
is_color_aes <- aes_name %in% c("colour", "fill")
guide_type <- if (is_continuous && is_color_aes) "colorbar" else "legend"
```

**Change 2 — Add `is_steps` to guide_spec (around line 116-123):**

Before:
```r
guide_spec <- list(
  aesthetic = aes_name,
  aesthetics = list(aes_name),
  type = guide_type,
  title = as.character(title),
  keys = keys_list,
  colors = colors_array
)
```

After:
```r
guide_spec <- list(
  aesthetic = aes_name,
  aesthetics = list(aes_name),
  type = guide_type,
  title = as.character(title),
  keys = keys_list,
  colors = colors_array,
  is_steps = isTRUE(is_steps)
)
```

`is_steps` is FALSE for non-color aesthetics and discrete legends because `is_steps` is only set in this loop iteration when `is_continuous` is TRUE; the `isTRUE()` wrapper guarantees logical(1).

Run the suite. The 5 RED tests from Task 1 should now be GREEN. Phase-13 baseline FAILs unchanged.

Commit:
```
git add R/ir_legends.R
git commit -m "fix(14-03): route ScaleBinned to colorbar; emit is_steps flag (Pitfall 2)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>R/ir_legends.R predicate widened; is_steps emitted on every guide_spec; all 5 new tests GREEN; phase-13 baseline FAILs unchanged.</done>
</task>

</tasks>

<exit_criteria>
- `grep -c 'ScaleBinned' R/ir_legends.R` ≥ 2 (predicate + is_steps flag).
- `grep -c 'is_steps' R/ir_legends.R` ≥ 2.
- 3 colorbar-trigger tests in `test-color-fidelity.R` are now GREEN (no longer skipped).
- 2 new `test-ir-legends.R` assertions GREEN.
- Full suite: phase-13 baseline FAILs unchanged.
- Two atomic commits (RED then GREEN).
</exit_criteria>

<threat_model>
No threat surface — package internals only. Predicate widening on a class hierarchy check.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-03-SUMMARY.md` listing the changes and a copy of the post-fix relevant lines.
</output>
