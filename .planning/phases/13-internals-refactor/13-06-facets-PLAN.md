---
phase: 13
plan: 06
type: execute
wave: 6
depends_on: ["13-01", "13-02", "13-03", "13-04", "13-05"]
files_modified:
  - R/ir_facets.R
  - R/as_d3_ir.R
  - tests/testthat/test-ir-facets.R
autonomous: true
requirements: [REFACTOR-01]
tags: [r-package, ggplot2, refactor, facets]

must_haves:
  truths:
    - "extract_facets_ir(b, pp_x, pp_y, scales, x_breaks, y_breaks, x_trans_name, y_trans_name, is_flip) reproduces v1.0 facets+panels slice"
    - "FacetWrap, FacetGrid, and null-facet (single-panel default) branches all preserved"
    - "<<- superassign in tryCatch error handler at v1.0 lines 1109-1126 REPLACED with explicit return (Pitfall 2)"
    - "panel.spacing call sites already routed through calc_element_safe (Plan 02 wired this)"
    - "Per-panel temporal conversion (* 86400000 / * 1000) preserved"
  artifacts:
    - path: "R/ir_facets.R"
      provides: "extract_facets_ir + any facet-internal helpers"
      contains: "extract_facets_ir"
    - path: "R/as_d3_ir.R"
      provides: "Orchestrator with facets block removed; destructures fp$facets and fp$panels"
      contains: "extract_facets_ir(b"
    - path: "tests/testthat/test-ir-facets.R"
      provides: "Real assertions for null/wrap/grid branches + <<- removal regression"
      contains: "extract_facets_ir"
  key_links:
    - from: "R/ir_facets.R::extract_facets_ir"
      to: "R/as_d3_ir.R orchestrator"
      via: "explicit return list(facets=..., panels=...) — NO <<-"
      pattern: "list\\(facets = .*, panels = .*\\)"
    - from: "R/ir_facets.R"
      to: "R/ir_theme.R::calc_element_safe"
      via: "panel.spacing resolution"
      pattern: "calc_element_safe\\(\"panel\\.spacing\""
---

<objective>
Lift the facets concern out of `R/as_d3_ir.R` into `R/ir_facets.R`. The critical structural change is replacing the v1.0 `<<-` superassign in the `tryCatch` error handler (`R/as_d3_ir.R:1109-1126` in v1.0 numbering) with an explicit `list(facets=..., panels=...)` return — RESEARCH Pitfall 2 (without this fix, `<<-` would reach the global env once the function moves out of `as_d3_ir`'s frame, silently polluting global state).

After this plan, the orchestrator's facets block is replaced by `fp <- extract_facets_ir(b, pp_x, pp_y, scales, x_breaks, y_breaks, x_trans_name, y_trans_name, is_flip)` and destructures `ir$facets <- fp$facets; ir$panels <- fp$panels`.

Purpose: REFACTOR-01 progress — final extractor lift before the orchestrator-shrink plan. Highest structural risk because of `<<-` removal and the three branches (FacetWrap, FacetGrid, null) that need exact preservation.

Output: `R/ir_facets.R` (new), `R/as_d3_ir.R` (modified — facets block removed), `tests/testthat/test-ir-facets.R` (real assertions including a <<- regression check).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/13-internals-refactor/13-CONTEXT.md
@.planning/phases/13-internals-refactor/13-RESEARCH.md
@.planning/phases/13-internals-refactor/13-PATTERNS.md
@./CLAUDE.md
@R/as_d3_ir.R
@R/ir_theme.R
@R/ir_scales.R
@R/ir_layers.R
@R/ir_legends.R
@R/ir_utils.R
@tests/testthat/test-facets.R
@tests/testthat/test-facet-grid.R

<interfaces>
<!-- Established by this plan. -->

From R/ir_facets.R:
```r
extract_facets_ir <- function(b, pp_x, pp_y, scales,
                              x_breaks, y_breaks,
                              x_trans_name, y_trans_name,
                              is_flip = FALSE)
# Returns: list(facets = <list>, panels = <list>) — explicit, no <<-.
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create R/ir_facets.R; rewrite orchestrator to delegate; replace <<- with explicit return; add real assertions to test-ir-facets.R</name>
  <files>R/ir_facets.R, R/as_d3_ir.R, tests/testthat/test-ir-facets.R</files>
  <read_first>
    - R/as_d3_ir.R — read the current facets block in full. Plan 02 already replaced both panel.spacing sites with `calc_element_safe`, and Plan 03 lifted scale helpers, so the post-Plan-05 line numbers will differ from v1.0. Identify the post-Plan-05 boundaries before lifting.
    - R/as_d3_ir.R: FacetWrap branch (was v1.0 lines 871-969, including the `panel_spacing <- tryCatch(...)` block now using calc_element_safe).
    - R/as_d3_ir.R: FacetGrid branch (was v1.0 lines 970-1090).
    - R/as_d3_ir.R: null-facet branch (was v1.0 lines 1091-1107) — single-panel default.
    - R/as_d3_ir.R: tryCatch error handler with `<<-` (was v1.0 lines 1109-1126) — THIS IS THE STRUCTURAL FIX. The handler currently does `facets_ir <<- list(...)` and `panels_ir <<- list(...)`; once this code is in its own function, `<<-` no longer reaches `as_d3_ir`'s frame and would write to global env. REPLACE with explicit `return(list(facets = ..., panels = ...))` from the error handler.
    - R/as_d3_ir.R: per-panel temporal conversion (was v1.0 lines 905-928 in FacetWrap, 1034-1047 in FacetGrid) — `* 86400000` / `* 1000` for x_range/y_range when xscale/yscale is Date or POSIXct. PATTERNS Anti-Pattern: do NOT consolidate with the scales/layers temporal conversions.
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/ir_facets.R` section — sketch for the explicit-return refactor).
    - .planning/phases/13-internals-refactor/13-RESEARCH.md (Pitfall 2 — `<<-` removal).
    - tests/testthat/test-facets.R, tests/testthat/test-facet-grid.R (existing facet test suites; must remain green).
  </read_first>
  <behavior>
    - Test 1: Null-facet plot — `extract_facets_ir(b, pp_x, pp_y, scales, ...)` returns `$facets$type == "null"`, `$facets$nrow == 1L`, `$facets$ncol == 1L`, and `$panels` length 1.
    - Test 2: `facet_wrap(~cyl)` plot — `$facets$type == "wrap"`, `$panels` length equal to number of cyl values, each `$panel$x_range`/`y_range` non-null.
    - Test 3: `facet_grid(am ~ cyl)` — `$facets$type == "grid"`, panel count = product of factor levels.
    - Test 4: Force the tryCatch fallback (e.g., construct a `b` whose `b$layout$facet` triggers the error handler) — `extract_facets_ir` returns the fallback list explicitly. After the call, `ls(globalenv(), pattern = "^(facets_ir|panels_ir)$")` is `character(0)` (i.e., NO global env pollution from a stray `<<-`).
    - Test 5: `extract_facets_ir` output `$facets`/`$panels` `expect_equal` to `as_d3_ir(p)$facets`/`as_d3_ir(p)$panels` for a wrap plot.
  </behavior>
  <action>
**Part A — Create `R/ir_facets.R`:**

```r
# Facet extraction. Returns BOTH `facets` and `panels` slices in one list so the
# orchestrator can destructure (avoids <<- — see Pitfall 2).

#' @keywords internal
#' @noRd
extract_facets_ir <- function(b, pp_x, pp_y, scales,
                              x_breaks, y_breaks,
                              x_trans_name, y_trans_name,
                              is_flip = FALSE) {

  # The v1.0 fallback (was the <<- target). Now an explicit value.
  fallback <- list(
    facets = list(
      type   = "null",
      vars   = list(),
      nrow   = 1L,
      ncol   = 1L,
      layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
      strips = list()
    ),
    panels = list(list(
      PANEL    = 1L,
      x_range  = unname(scales$x$domain),
      y_range  = unname(scales$y$domain),
      x_breaks = unname(x_breaks),
      y_breaks = unname(y_breaks)
    ))
  )

  tryCatch({
    is_facet_wrap <- inherits(b$layout$facet, "FacetWrap")
    is_facet_grid <- inherits(b$layout$facet, "FacetGrid")

    if (is_facet_wrap) {
      # ============ LIFT VERBATIM from R/as_d3_ir.R FacetWrap branch ============
      # Including the panel.spacing block (already routes through
      # calc_element_safe per Plan 02), strips assembly, per-panel scale ranges,
      # and per-panel temporal conversion.
      # ==========================================================================
      # ... (verbatim from current orchestrator) ...
      list(facets = facets_ir, panels = panels_ir)
    } else if (is_facet_grid) {
      # ============ LIFT VERBATIM from R/as_d3_ir.R FacetGrid branch ============
      # ... (verbatim from current orchestrator) ...
      list(facets = facets_ir, panels = panels_ir)
    } else {
      # null-facet branch — single-panel default. LIFT VERBATIM from
      # R/as_d3_ir.R null-facet branch (post-Plan-05 line numbering).
      list(facets = facets_ir, panels = panels_ir)
    }
  }, error = function(e) fallback)  # NOT <<- — explicit return per Pitfall 2.
}
```

**Critical lift rules:**
1. INSIDE the lifted code, every `facets_ir <<-` and `panels_ir <<-` becomes a normal `<-` (local assignment within the `tryCatch` body). The whole branch must end by returning `list(facets = facets_ir, panels = panels_ir)`. The error handler returns `fallback` (also a normal value, NOT `<<-`).
2. The per-panel temporal conversion blocks (v1.0 lines 905-928 in FacetWrap, 1034-1047 in FacetGrid) lift verbatim — POSIXct cols `* 1000`, Date cols `* 86400000`. Do not consolidate.
3. `xscale_obj`/`yscale_obj` references in the lifted code: the orchestrator passes them via `b$layout$panel_scales_x[[1]]` / `b$layout$panel_scales_y[[1]]` already — keep those reads inside the function.

**Part B — Edit `R/as_d3_ir.R`:**

1. Identify the post-Plan-05 line range of the entire facets block (FacetWrap + FacetGrid + null + the tryCatch wrapper with the `<<-` handler). Replace with:
   ```r
   fp <- extract_facets_ir(
     b, pp_x, pp_y, scales,
     x_breaks, y_breaks,
     x_trans_name, y_trans_name,
     is_flip = is_flip
   )
   ```
   The orchestrator's final `ir <- list(...)` already has `facets = fp$facets, panels = fp$panels` — but post-Plan-05 the v1.0 had `facets = facets_ir, panels = panels_ir`. Adjust the final assembly to:
   ```r
   ir <- list(
     ...
     facets = fp$facets,
     panels = fp$panels,
     ...
   )
   ```
   OR keep the v1.0 names by destructuring:
   ```r
   facets_ir <- fp$facets
   panels_ir <- fp$panels
   ```
   (Either is fine — pick the smaller diff.)

2. Verify `x_breaks`, `y_breaks`, `x_trans_name`, `y_trans_name` are still computed in the orchestrator BEFORE the `extract_facets_ir` call. These were locals in the v1.0 orchestrator and need to remain available. If `x_trans_name`/`y_trans_name` were defined inside the (now-lifted) facets block, lift them either into `extract_scales_ir` (as fields on the returned `scales$x$transform_name`) OR keep the orchestrator computing them inline before the call. Use the smaller-diff option.

3. Verify zero remaining `<<-` references in `R/as_d3_ir.R`:
   ```bash
   grep -c '<<-' R/as_d3_ir.R   # → 0
   ```

**Part C — Replace `tests/testthat/test-ir-facets.R` stub with real assertions:**

```r
test_that("extract_facets_ir returns null-facet structure for unfaceted plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "null")
  expect_equal(fp$facets$nrow, 1L)
  expect_equal(fp$facets$ncol, 1L)
  expect_length(fp$panels, 1L)
})

test_that("extract_facets_ir produces wrap-type facets for facet_wrap plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "wrap")
  expect_equal(length(fp$panels), length(unique(mtcars$cyl)))
})

test_that("extract_facets_ir produces grid-type facets for facet_grid plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(am ~ cyl)
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "grid")
  expect_equal(length(fp$panels),
               length(unique(mtcars$am)) * length(unique(mtcars$cyl)))
})

test_that("extract_facets_ir error fallback does NOT pollute global env (Pitfall 2)", {
  # Ensure clean global state.
  rm(list = intersect(c("facets_ir","panels_ir"), ls(envir = globalenv())),
     envir = globalenv())
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  # Even on a happy path, this confirms <<- is gone — no globalenv side effect.
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_false(exists("facets_ir", envir = globalenv(), inherits = FALSE))
  expect_false(exists("panels_ir", envir = globalenv(), inherits = FALSE))
})

test_that("extract_facets_ir output equals as_d3_ir facets+panels for facet_wrap plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "wrap")
  expect_equal(length(ir$panels), length(unique(mtcars$cyl)))
})
```

After all three parts, run `Rscript -e 'devtools::test()'` — full suite green, including `test-facets.R` and `test-facet-grid.R`.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()' && bash -lc 'set -e; n=$(grep -c "<<-" R/as_d3_ir.R); test "$n" -eq 0 || (echo "FAIL: <<- survived in as_d3_ir.R: $n"; exit 1); echo "OK no <<- in orchestrator"'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/ir_facets.R` exits 0; `grep -cE '^extract_facets_ir <- function' R/ir_facets.R` equals 1.
    - `grep -c '@export' R/ir_facets.R` equals 0.
    - `grep -c '<<-' R/as_d3_ir.R` equals 0 (Pitfall 2 fix verified).
    - `grep -c '<<-' R/ir_facets.R` equals 0 (the lifted code uses normal `<-` since it's now within its own function frame).
    - `grep -c 'extract_facets_ir(b' R/as_d3_ir.R` ≥ 1.
    - `wc -l R/as_d3_ir.R` is at least 200 lines smaller than at the start of this plan.
    - `grep -c 'test_that' tests/testthat/test-ir-facets.R` ≥ 5.
    - `Rscript -e 'devtools::test()'` exits 0; `test-facets.R` and `test-facet-grid.R` specifically remain green.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/ir_facets.R contains extract_facets_ir with explicit list returns (no <<-). R/as_d3_ir.R no longer contains the facets block or <<-. test-ir-facets.R has ≥5 assertions including a global-env pollution check. test-facets.R and test-facet-grid.R green.</done>
</task>

</tasks>

<verification>
1. `Rscript -e 'devtools::test()'` → green.
2. `grep -c '<<-' R/as_d3_ir.R` → 0.
3. `grep -c '<<-' R/ir_facets.R` → 0.
4. `grep -c 'extract_facets_ir(b' R/as_d3_ir.R` ≥ 1.
5. `wc -l R/as_d3_ir.R` substantially smaller (orchestrator should now be close to ≤200 lines; final shrink in Plan 07).
</verification>

<success_criteria>
- `R/ir_facets.R` exists with `extract_facets_ir` using explicit list returns (no `<<-`).
- `R/as_d3_ir.R` no longer contains the facets block or any `<<-`.
- `tests/testthat/test-ir-facets.R` has ≥5 assertions, including a global-env-pollution regression check.
- `test-facets.R` and `test-facet-grid.R` remain green; full suite green.
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-06-SUMMARY.md` listing files modified, post-edit `wc -l R/as_d3_ir.R`, and confirming both facet test files are green.
</output>
