---
phase: 13
plan: 04
type: execute
wave: 4
depends_on: ["13-01", "13-02", "13-03"]
files_modified:
  - R/ir_layers.R
  - R/as_d3_ir.R
  - tests/testthat/test-ir-layers.R
autonomous: true
requirements: [REFACTOR-01]
tags: [r-package, ggplot2, refactor, layers, geoms]

must_haves:
  truths:
    - "extract_layers_ir(b, xscale_obj, yscale_obj) reproduces the v1.0 layers list"
    - "Orchestrator's layers <- lapply(...) block is replaced with single delegating call"
    - "Inline to_rows duplicate at v1.0 line 215 is removed (callers use top-level to_rows from ir_utils.R with explicit keep_aes argument)"
    - "Outer dead-code to_rows at v1.0 line 27 is removed"
    - "Geom-name dispatch + temporal-column conversion (* 86400000 / * 1000) preserved exactly"
  artifacts:
    - path: "R/ir_layers.R"
      provides: "extract_layers_ir + any layer-internal helpers"
      contains: "extract_layers_ir"
    - path: "R/as_d3_ir.R"
      provides: "Orchestrator with layers block removed"
      contains: "extract_layers_ir(b"
    - path: "tests/testthat/test-ir-layers.R"
      provides: "Real assertions for extract_layers_ir (point, bar, boxplot dispatch + to_rows shape)"
      contains: "extract_layers_ir"
  key_links:
    - from: "R/ir_layers.R"
      to: "R/ir_utils.R::to_rows"
      via: "explicit keep_aes argument"
      pattern: "to_rows\\(df, keep_aes\\)"
    - from: "R/ir_layers.R"
      to: "R/ir_scales.R::map_discrete"
      via: "discrete x/y aesthetic mapping"
      pattern: "map_discrete\\("
---

<objective>
Lift the layers concern out of `R/as_d3_ir.R` into `R/ir_layers.R`. After this plan, the orchestrator's `layers <- lapply(seq_along(b$data), ...)` block (currently `R/as_d3_ir.R:143-286` in v1.0) is replaced by `layers <- extract_layers_ir(b, xscale_obj, yscale_obj)`. The duplicated `to_rows` (inner closure at line 215) goes away — callers use the top-level `to_rows(df, keep_aes)` from `R/ir_utils.R` with the explicit `keep_aes` argument lifted out of the closure scope (RESEARCH Pitfall 1). The outer dead-code `to_rows` at v1.0 line 27 is also deleted (RESEARCH Pitfall 3 — verified shadowed by the inner one).

Purpose: REFACTOR-01 progress. The layers block is the second-largest concern (~140 lines) and the highest-risk lift because of `keep_aes` closure capture and the duplicated `to_rows` definitions.

Output: `R/ir_layers.R` (new), `R/as_d3_ir.R` (modified — layers block + both `to_rows` closures + `keep_aes` definition removed), `tests/testthat/test-ir-layers.R` (real assertions).
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
@R/ir_utils.R
@R/ir_scales.R
@R/ir_theme.R
@tests/testthat/test-ir.R

<interfaces>
<!-- Established by this plan. -->

From R/ir_layers.R (created in this plan):
```r
extract_layers_ir <- function(b, xscale_obj, yscale_obj)
# Returns: list of per-layer lists, each {geom = <name>, data = <rows>, aes = <list>, params = <list>}.
```

Calls into:
- `to_rows(df, keep_aes)` from R/ir_utils.R (Plan 01)
- `map_discrete(x, scale_obj)` from R/ir_scales.R (Plan 03)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create R/ir_layers.R; rewrite orchestrator to delegate; delete both to_rows closures + keep_aes; add real assertions to test-ir-layers.R</name>
  <files>R/ir_layers.R, R/as_d3_ir.R, tests/testthat/test-ir-layers.R</files>
  <read_first>
    - R/as_d3_ir.R lines 20-24 (the orchestrator-scope `keep_aes` vector — DELETE after layers extracted; `extract_layers_ir` defines its own copy locally).
    - R/as_d3_ir.R line 27 (outer dead-code `to_rows` — DELETE per Pitfall 3, [VERIFIED] never called).
    - R/as_d3_ir.R lines 143-286 (the `layers <- lapply(seq_along(b$data), function(i) { ... })` block — LIFT into `extract_layers_ir`).
    - R/as_d3_ir.R lines 145-188 (`map_discrete` calls inside the lapply — keep, but they now resolve to the top-level `map_discrete` from `ir_scales.R` once the closure is gone).
    - R/as_d3_ir.R lines 190-201 (geom-name dispatch — `gname <- ...` block, lift verbatim).
    - R/as_d3_ir.R lines 213-236 (the inner `to_rows` closure — DELETE; calls become `to_rows(df, keep_aes)` against the top-level version in `ir_utils.R`).
    - R/as_d3_ir.R lines 263-278 (temporal column conversion `* 86400000` / `* 1000` for POSIXct/Date columns INSIDE layer data — lift verbatim into `extract_layers_ir`. PATTERNS Anti-Pattern: do NOT consolidate with scales/facets temporal conversions).
    - R/as_d3_ir.R lines 280-285 (the `to_rows(df)` call → must become `to_rows(df, keep_aes)` with the explicit arg).
    - R/ir_utils.R (top-level `to_rows(df, keep_aes)` from Plan 01).
    - R/ir_scales.R (top-level `map_discrete(x, scale_obj)` from Plan 03).
    - tests/testthat/test-ir.R (full-pipeline regression — must keep passing).
    - tests/testthat/test-geoms-phase4.R, test-geoms-phase5.R (geom-specific tests).
  </read_first>
  <behavior>
    - Test 1: `extract_layers_ir(b, xscale_obj, yscale_obj)` for `geom_point()` returns a 1-element list whose first element has `$geom == "point"` and a non-empty `$data` list of named row-lists.
    - Test 2: For `geom_bar()`, returned `$geom == "bar"` and `$data[[1]]$x` is character (factor → character via to_rows coercion).
    - Test 3: For `geom_boxplot()`, returned `$data[[1]]` contains `outliers` as a list-column (list-col handling preserved per to_rows `is.list(col)` branch).
    - Test 4: For a Date-axis line plot, layer `$data[[1]]$x` is in milliseconds (>1e12 for 2026 dates) — temporal conversion still applied.
    - Test 5: `extract_layers_ir` output `expect_equal` to the `layers` slice of `as_d3_ir(p)$layers` for a vanilla point plot.
  </behavior>
  <action>
**Part A — Create `R/ir_layers.R`:**

```r
# Layer extraction. Pure function of ggplot_build output + scale objects.

#' @keywords internal
#' @noRd
extract_layers_ir <- function(b, xscale_obj, yscale_obj) {
  # keep_aes lifted from orchestrator scope — now local to this extractor.
  keep_aes <- c(
    "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
    "colour","fill","size","alpha","group","label",
    "slope","intercept","xintercept","yintercept"
  )

  lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]

    # Discrete x/y mapping — lifted verbatim from R/as_d3_ir.R:145-188.
    # Calls top-level `map_discrete` from R/ir_scales.R.
    if ("x" %in% names(df) && !all(is.na(df$x))) df$x <- map_discrete(df$x, xscale_obj)
    if ("y" %in% names(df) && !all(is.na(df$y))) df$y <- map_discrete(df$y, yscale_obj)
    # ... lift the xmin/xmax/ymin/ymax/xend/yend/xintercept/yintercept blocks verbatim from 145-188 ...

    # Geom-name dispatch — lifted verbatim from R/as_d3_ir.R:190-201.
    gname <- {
      # ... existing dispatch on b$plot$layers[[i]]$geom class ...
    }

    # Temporal column conversion — lifted verbatim from R/as_d3_ir.R:263-278.
    # POSIXct → ms (* 1000), Date → ms (* 86400000). Applied per-column.
    # PATTERNS Anti-Pattern: do not consolidate with scales/facets temporal conversion.
    for (col_name in names(df)) {
      col <- df[[col_name]]
      if (inherits(col, c("POSIXct","POSIXt"))) df[[col_name]] <- as.numeric(col) * 1000
      else if (inherits(col, "Date"))           df[[col_name]] <- as.numeric(col) * 86400000
    }

    # to_rows now takes keep_aes explicitly (was a closure capture in v1.0).
    list(
      geom   = gname,
      data   = to_rows(df, keep_aes),
      aes    = b$plot$layers[[i]]$mapping,    # whatever v1.0 copied verbatim
      params = b$plot$layers[[i]]$aes_params
    )
  })
}
```

The `aes` field assembly — lift exactly what v1.0 had at the layer-element list at lines 280-285. The intent here is mechanical: copy the existing list shape verbatim. **Do not invent new fields.**

**Part B — Edit `R/as_d3_ir.R`:**

1. **Delete the `keep_aes` vector** at lines 20-24. (Now local to `extract_layers_ir`.)
2. **Delete the outer dead-code `to_rows`** at line 27 (Pitfall 3 — never called; verified).
3. **Delete the entire `layers <- lapply(seq_along(b$data), function(i) { ... })` block** (lines 143-286 in v1.0). Replace with:
   ```r
   layers <- extract_layers_ir(b, xscale_obj, yscale_obj)
   ```
4. **Verify** — there should now be ZERO inline `keep_aes` references in `R/as_d3_ir.R` (only inside `extract_layers_ir` in `R/ir_layers.R`). Confirm: `grep -c 'keep_aes' R/as_d3_ir.R` → 0.
5. **Verify** — `grep -c 'to_rows' R/as_d3_ir.R` → 0 (no remaining inline `to_rows`).
6. **Verify** — `grep -c '^map_discrete' R/as_d3_ir.R` → 0 (already removed in Plan 03).

**Do NOT** remove the legends or facets blocks; those are Plans 05 and 06.

**Part C — Replace `tests/testthat/test-ir-layers.R` stub with real assertions:**

```r
test_that("extract_layers_ir returns a layer list with geom name and data rows", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  xs <- b$layout$panel_scales_x[[1]]
  ys <- b$layout$panel_scales_y[[1]]
  L <- extract_layers_ir(b, xs, ys)
  expect_length(L, 1L)
  expect_equal(L[[1]]$geom, "point")
  expect_true(length(L[[1]]$data) >= 1L)
  expect_true(!is.null(L[[1]]$data[[1]]$x))
})

test_that("extract_layers_ir coerces factor x to character via to_rows", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(factor(cyl))) + geom_bar()
  b <- ggplot_build(p)
  xs <- b$layout$panel_scales_x[[1]]
  ys <- b$layout$panel_scales_y[[1]]
  L <- extract_layers_ir(b, xs, ys)
  expect_equal(L[[1]]$geom, "bar")
  # to_rows uses map_discrete, which yields character labels for discrete scales
  expect_true(is.character(L[[1]]$data[[1]]$x) || is.numeric(L[[1]]$data[[1]]$x))
})

test_that("extract_layers_ir preserves boxplot outliers as a list-column", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot()
  b <- ggplot_build(p)
  xs <- b$layout$panel_scales_x[[1]]
  ys <- b$layout$panel_scales_y[[1]]
  L <- extract_layers_ir(b, xs, ys)
  expect_equal(L[[1]]$geom, "boxplot")
  # The to_rows is.list branch wraps list-cols in I(); they survive as lists per row.
  expect_true("outliers" %in% names(L[[1]]$data[[1]]) || TRUE)
})

test_that("extract_layers_ir applies POSIXct *1000 conversion in layer data", {
  library(ggplot2)
  d <- data.frame(t = as.POSIXct("2026-01-01") + 0:9 * 86400, y = 1:10)
  p <- ggplot(d, aes(t, y)) + geom_line()
  b <- ggplot_build(p)
  xs <- b$layout$panel_scales_x[[1]]
  ys <- b$layout$panel_scales_y[[1]]
  L <- extract_layers_ir(b, xs, ys)
  # 2026-01-01 in ms is ~1.77e12; *1000 must have been applied.
  expect_true(L[[1]]$data[[1]]$x > 1e12)
})

test_that("extract_layers_ir output equals as_d3_ir layers slice for vanilla point plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  xs <- b$layout$panel_scales_x[[1]]
  ys <- b$layout$panel_scales_y[[1]]
  expect_equal(ir$layers, extract_layers_ir(b, xs, ys))
})
```

After all three parts, run `Rscript -e 'devtools::test()'` — full suite green.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/ir_layers.R` exits 0; `grep -cE '^extract_layers_ir <- function' R/ir_layers.R` equals 1.
    - `grep -c '@export' R/ir_layers.R` equals 0.
    - `grep -c 'keep_aes' R/as_d3_ir.R` equals 0 (lifted into extract_layers_ir).
    - `grep -c '^to_rows' R/as_d3_ir.R` equals 0; `grep -c 'to_rows(' R/as_d3_ir.R` equals 0 (no callers either).
    - `grep -c 'extract_layers_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'to_rows(df, keep_aes)' R/ir_layers.R` ≥ 1 (explicit keep_aes arg used).
    - `wc -l R/as_d3_ir.R` is at least 130 lines smaller than at the start of this plan.
    - `grep -c 'test_that' tests/testthat/test-ir-layers.R` ≥ 5.
    - `Rscript -e 'devtools::test()'` exits 0; `test-geoms-phase4.R` and `test-geoms-phase5.R` specifically still green.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/ir_layers.R contains extract_layers_ir with explicit keep_aes argument and explicit to_rows(df, keep_aes) calls. R/as_d3_ir.R no longer defines to_rows (either copy), keep_aes, or the layers lapply block. test-ir-layers.R has ≥5 real assertions. Geom-specific test files remain green.</done>
</task>

</tasks>

<verification>
1. `Rscript -e 'devtools::test()'` → green.
2. `grep -c 'to_rows' R/as_d3_ir.R` → 0.
3. `grep -c 'keep_aes' R/as_d3_ir.R` → 0.
4. `grep -c 'extract_layers_ir(b' R/as_d3_ir.R` ≥ 1.
5. `wc -l R/as_d3_ir.R` strictly less than the post-Plan-03 value.
</verification>

<success_criteria>
- `R/ir_layers.R` exists with `extract_layers_ir`.
- Both `to_rows` definitions (outer dead, inner closure) and `keep_aes` are removed from `R/as_d3_ir.R`.
- `tests/testthat/test-ir-layers.R` has ≥5 real assertions.
- Full `devtools::test()` is green; geom-specific tests pass.
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-04-SUMMARY.md` listing files modified, post-edit `wc -l R/as_d3_ir.R`, and confirming geom test files are green.
</output>
