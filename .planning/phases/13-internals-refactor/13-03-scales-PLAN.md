---
phase: 13
plan: 03
type: execute
wave: 3
depends_on: ["13-01", "13-02"]
files_modified:
  - R/ir_scales.R
  - R/as_d3_ir.R
  - tests/testthat/test-ir-scales.R
autonomous: true
requirements: [REFACTOR-01]
tags: [r-package, ggplot2, refactor, scales]

must_haves:
  truths:
    - "extract_scales_ir(b, pp_x, pp_y, is_flip) reproduces the v1.0 scales slice (x, y, optional color)"
    - "Orchestrator no longer contains the scales-assembly block; delegates via single call"
    - "Temporal multipliers (* 86400000 for Date, * 1000 for POSIXct) still applied in scales (NOT consolidated with layers/facets)"
    - "Log domain validation still emits the v1.0 warning when domain is invalid"
  artifacts:
    - path: "R/ir_scales.R"
      provides: "extract_scales_ir + map_discrete + validate_log_domain + get_scale_transform + get_scale_info"
      contains: "extract_scales_ir"
    - path: "R/as_d3_ir.R"
      provides: "Orchestrator with scales block removed; delegates to extract_scales_ir"
      contains: "extract_scales_ir(b"
    - path: "tests/testthat/test-ir-scales.R"
      provides: "Real assertions for extract_scales_ir (continuous, categorical, color, log validation)"
      contains: "extract_scales_ir"
  key_links:
    - from: "R/ir_scales.R"
      to: "R/ir_utils.R::dom"
      via: "color scale domain assembly"
      pattern: "dom\\(allc\\)"
    - from: "R/as_d3_ir.R"
      to: "R/ir_scales.R::extract_scales_ir"
      via: "single-call delegation"
      pattern: "extract_scales_ir\\(b"
---

<objective>
Lift the scales concern out of `R/as_d3_ir.R` into `R/ir_scales.R`. After this plan the orchestrator's scales block is replaced by `scales <- extract_scales_ir(b, pp_x, pp_y, is_flip)`. All scale-related closures (`map_discrete`, `validate_log_domain`, `get_scale_transform`, `get_scale_info`) move to `R/ir_scales.R` as top-level internal functions.

Purpose: REFACTOR-01 progress. The scales block is the single largest concern (~250 lines) — its extraction takes the orchestrator a step closer to the ≤200-line target.

Output: `R/ir_scales.R` (new), `R/as_d3_ir.R` (modified — scales block removed), `tests/testthat/test-ir-scales.R` (real assertions).
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
@.planning/phases/13-internals-refactor/13-VALIDATION.md
@./CLAUDE.md
@R/as_d3_ir.R
@R/ir_utils.R
@R/ir_theme.R
@tests/testthat/test-ir.R

<interfaces>
<!-- Contracts established here for downstream extractor plans (04, 06). -->

From R/ir_scales.R (created in this plan):
```r
# Top-level entry. Pure function of ggplot_build output + per-panel params.
extract_scales_ir <- function(b, pp_x, pp_y, is_flip = FALSE)

# Internal helpers, lifted verbatim from as_d3_ir.R closures.
map_discrete         <- function(x, scale_obj)
validate_log_domain  <- function(domain, scale_obj, axis_name)
get_scale_transform  <- function(scale_obj)
get_scale_info       <- function(scale_obj, pp, axis_name)
```

Plans 04 (layers) and 06 (facets) will REUSE `map_discrete` (layers) and `get_scale_info`/`get_scale_transform` (facets per-panel) from this file.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create R/ir_scales.R with all scale helpers and extract_scales_ir entry point</name>
  <files>R/ir_scales.R</files>
  <read_first>
    - R/as_d3_ir.R lines 49-71 (`map_discrete` closure — lift verbatim, scale_obj is already an explicit arg).
    - R/as_d3_ir.R lines 263-278 (the inline temporal-conversion block in the layers section — DO NOT lift; this stays in layers per RESEARCH Anti-Pattern "Reordering temporal conversion").
    - R/as_d3_ir.R lines 287-311 (`validate_log_domain` — lift verbatim).
    - R/as_d3_ir.R lines 314-348 (`get_scale_transform` — lift verbatim).
    - R/as_d3_ir.R lines 351-464 (`get_scale_info` — lift verbatim, INCLUDING the fragile `tryCatch` at 416-451 that walks `scale_obj$labels` closure environments; PATTERNS Pitfall 4 says DO NOT clean it up; add a `# Compensates for ggplot2 lacking a public field for date_labels / timezone` comment).
    - R/as_d3_ir.R lines 466-475 (color scale `allc` + `dom` — `dom` is in `ir_utils.R` already; `allc` body lives in this file).
    - R/as_d3_ir.R lines 487-533 (breaks block + `scales <- list(x=..., y=..., color=...)` assembly — lift into `extract_scales_ir`).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/ir_scales.R` section — exact line ranges and the entry-point sketch).
    - .planning/phases/13-internals-refactor/13-RESEARCH.md (Pattern 1 + Pitfall 4).
  </read_first>
  <action>
Create `R/ir_scales.R`. All functions are `#' @keywords internal #' @noRd` (zero `@export`). Use Write tool.

**Section 1 — `map_discrete`:** Lift verbatim from `R/as_d3_ir.R:49-71`. `scale_obj` is already an explicit arg, no closure rewrite needed.

**Section 2 — `validate_log_domain`:** Lift verbatim from `R/as_d3_ir.R:287-311`. Keeps the `warning(...)` for invalid log domains exactly as v1.0.

**Section 3 — `get_scale_transform`:** Lift verbatim from `R/as_d3_ir.R:314-348`.

**Section 4 — `get_scale_info`:** Lift verbatim from `R/as_d3_ir.R:351-464`. **Critical:** preserve the `tryCatch` at 416-451 that probes `environment(scale_obj$labels)$f` for `date_labels` and timezone — add the comment `# Compensates for ggplot2 lacking a public field for date_labels / timezone — see Phase 13 RESEARCH Pitfall 4` immediately above the tryCatch. Do not "clean up" the env-walking logic.

**Section 5 — `extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)`:** New top-level entry. Lift the body of the orchestrator's scales block (`R/as_d3_ir.R:466-533`). Sketch:

```r
#' @keywords internal
#' @noRd
extract_scales_ir <- function(b, pp_x, pp_y, is_flip = FALSE) {
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # Breaks (lifted verbatim from R/as_d3_ir.R:487-516, including the temporal
  # `* 86400000` for Date and `* 1000` for POSIXct conversions on x_breaks/y_breaks).
  x_breaks <- pp_x$breaks
  y_breaks <- pp_y$breaks
  x_breaks <- x_breaks[!is.na(x_breaks)]
  y_breaks <- y_breaks[!is.na(y_breaks)]
  # ... lift the temporal conversion block exactly as v1.0 ...

  # Scale info + breaks merge (lifted from R/as_d3_ir.R:518-527).
  scales <- list(
    x = c(get_scale_info(xscale_obj, pp_x, "x"),
          list(breaks = unname(x_breaks))),
    y = c(get_scale_info(yscale_obj, pp_y, "y"),
          list(breaks = unname(y_breaks)))
  )

  # Log validation — currently in orchestrator immediately after scales assembly.
  validate_log_domain(scales$x$domain, xscale_obj, "x")
  validate_log_domain(scales$y$domain, yscale_obj, "y")

  # Color scale — lifted from R/as_d3_ir.R:466-472, 528-533.
  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))
  if (length(allc)) {
    scales$color <- list(
      type = if (is.numeric(allc)) "continuous" else "categorical",
      domain = unname(dom(allc))
    )
  }

  scales
}
```

**Notes:**
- `dom` is already in `R/ir_utils.R` from Plan 01; called bare here.
- `is_flip` is accepted as an arg for API consistency with the other extractors (used by facets/layers); the v1.0 scales block doesn't actually branch on flip — it operates on `pp_x`/`pp_y` which the orchestrator already swapped. Keep the param even if unused inside this function (forward compat + uniform extractor signature per Pattern E).
- Use namespaced `ggplot2::` calls anywhere the lifted code referenced ggplot2 internals via `::`. NO `:::` calls in this file (theme is the only place that should ever go private; scales has no calc_element use).

After writing, run `Rscript -e 'pkgload::load_all(); exists("extract_scales_ir")'` → TRUE. Run `Rscript -e 'devtools::document()'` → NAMESPACE diff empty.

**Do NOT modify `R/as_d3_ir.R` in this task.** The orchestrator's inline closures still shadow the new top-level helpers; behavior is unchanged.
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(); stopifnot(exists("extract_scales_ir"), exists("map_discrete"), exists("get_scale_info"), exists("get_scale_transform"), exists("validate_log_domain")); library(ggplot2); p <- ggplot(mtcars, aes(wt, mpg)) + geom_point(); b <- ggplot_build(p); pp_x <- b$layout$panel_params[[1]]$x; pp_y <- b$layout$panel_params[[1]]$y; s <- extract_scales_ir(b, pp_x, pp_y, FALSE); stopifnot(s$x$type == "continuous", s$y$type == "continuous"); cat("OK\n")'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/ir_scales.R` exits 0.
    - `grep -cE '^extract_scales_ir <- function' R/ir_scales.R` equals 1.
    - `grep -cE '^map_discrete <- function' R/ir_scales.R` equals 1.
    - `grep -cE '^get_scale_info <- function' R/ir_scales.R` equals 1.
    - `grep -cE '^get_scale_transform <- function' R/ir_scales.R` equals 1.
    - `grep -cE '^validate_log_domain <- function' R/ir_scales.R` equals 1.
    - `grep -c '@export' R/ir_scales.R` equals 0.
    - `grep -c 'ggplot2:::' R/ir_scales.R` equals 0 (only `ir_theme.R` is allowed to use private API).
    - The verify command exits 0 with `OK`.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/ir_scales.R contains the 5 functions listed, all internal, all callable. devtools::test() still green (R/as_d3_ir.R unchanged in this task).</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire orchestrator to extract_scales_ir; delete inline scale closures; add real assertions to test-ir-scales.R</name>
  <files>R/as_d3_ir.R, tests/testthat/test-ir-scales.R</files>
  <read_first>
    - R/as_d3_ir.R lines 49-71 (`map_discrete` closure — DELETE; layers extractor in Plan 04 will call top-level `map_discrete` from `ir_scales.R`).
    - R/as_d3_ir.R lines 287-311, 314-348, 351-464 (the three scale helpers — DELETE).
    - R/as_d3_ir.R lines 466-533 (color scale + breaks + scales assembly + validate_log_domain calls — REPLACE with single delegation).
    - R/as_d3_ir.R the post-466 region (the orchestrator currently has `scales <- list(x = ..., y = ...)` inline; the next block consumes `scales` and `xscale_obj`/`yscale_obj` for axis labels at ~573-589 and the facets block uses `scales` at ~863+ — keep `scales` as a local variable holding `extract_scales_ir`'s return).
    - R/ir_scales.R (just-created — exposes the 5 functions).
    - R/ir_utils.R (`dom` is here; do not redefine).
    - tests/testthat/test-ir.R (existing — full pipeline regression).
    - tests/testthat/test-ir-scales.R (current stub from Plan 01 — REPLACE with real assertions).
    - tests/testthat/test-date-scales.R (existing date-scale tests; the Pitfall 4 closure walk MUST keep these green).
  </read_first>
  <behavior>
    - Test 1: For `ggplot(mtcars, aes(wt, mpg)) + geom_point()`, `extract_scales_ir(b, pp_x, pp_y, FALSE)$x$type == "continuous"` and `$y$type == "continuous"`.
    - Test 2: For `ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot()`, `extract_scales_ir(...)$x$type == "categorical"` and `$x$domain` contains `"4"`, `"6"`, `"8"`.
    - Test 3: For a plot with a numeric color aesthetic, `extract_scales_ir(...)$color$type == "continuous"`; for a discrete one, `"categorical"`.
    - Test 4: `extract_scales_ir` output is `expect_equal` to the `scales` slice of the corresponding `as_d3_ir(p)` output (full-pipeline equivalence).
    - Test 5: Date-axis plot: `extract_scales_ir` produces a domain in milliseconds (i.e., * 86400000 applied) — `expect_true(scales$x$domain[1] > 1e9)` for any modern date.
  </behavior>
  <action>
**Part A — Edit `R/as_d3_ir.R`:**

1. **Delete the 4 inline scale closures**: `map_discrete` (lines 49-71), `validate_log_domain` (287-311), `get_scale_transform` (314-348), `get_scale_info` (351-464).

2. **Replace the scales-assembly block** (currently lines 466-533, including the breaks block, scales list, log validations, and color scale) with a single delegation. After the orchestrator computes `pp_x`/`pp_y` (existing logic at the start), insert:
   ```r
   scales <- extract_scales_ir(b, pp_x, pp_y, is_flip = is_flip)
   xscale_obj <- b$layout$panel_scales_x[[1]]
   yscale_obj <- b$layout$panel_scales_y[[1]]
   ```
   Keep `xscale_obj`/`yscale_obj` local because the legends and facets blocks still consume them (until those plans land).

3. **Verify** `scales` is referenced unchanged downstream: the existing axis-label block (~573-589), the legends block (~616-817), the facets block (~863-1126), and the final `ir <- list(...)` at the bottom — all already say `scales = scales`. No callsite changes needed.

4. **Do NOT remove** the inline `to_rows`, `keep_aes`, or other layer/legend/facet closures. They will be removed by Plans 04, 05, 06.

5. **Run** `Rscript -e 'devtools::test()'` after the edit. The full suite — including `test-date-scales.R`, `test-facets.R`, `test-ir.R` — must remain green. If the date-labels closure walk regresses, double-check the `tryCatch` block at ir_scales.R was lifted verbatim including the `environment(scale_obj$labels)$f` access.

**Part B — Replace `tests/testthat/test-ir-scales.R` stub with real assertions:**

```r
test_that("extract_scales_ir extracts continuous x and y domain from panel_params", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_equal(s$x$type, "continuous")
  expect_equal(s$y$type, "continuous")
  expect_true(s$x$domain[1] <= min(mtcars$wt))
  expect_true(s$x$domain[2] >= max(mtcars$wt))
})

test_that("extract_scales_ir handles categorical x scale", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_equal(s$x$type, "categorical")
  expect_true(all(c("4","6","8") %in% as.character(s$x$domain)))
})

test_that("extract_scales_ir produces continuous color scale for numeric colour aesthetic", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_equal(s$color$type, "continuous")
})

test_that("extract_scales_ir output equals the v1.0 as_d3_ir scales slice", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  expect_equal(ir$scales, extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE))
})

test_that("extract_scales_ir applies temporal *86400000 conversion for Date axis", {
  library(ggplot2)
  d <- data.frame(date = as.Date("2026-01-01") + 0:9, y = 1:10)
  p <- ggplot(d, aes(date, y)) + geom_line()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  # Modern Dates are >> 1e9 ms (1970 epoch milliseconds for 2026 ~= 1.77e12)
  expect_true(s$x$domain[1] > 1e12)
})
```
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '^extract_scales_ir(' R/as_d3_ir.R` equals 0 AND `grep -c 'extract_scales_ir(b' R/as_d3_ir.R` ≥ 1 (delegation, not redefinition).
    - `grep -c '^map_discrete <- function' R/as_d3_ir.R` equals 0 (closure deleted).
    - `grep -c '^get_scale_info <- function' R/as_d3_ir.R` equals 0.
    - `grep -c '^validate_log_domain <- function' R/as_d3_ir.R` equals 0.
    - `grep -c '^get_scale_transform <- function' R/as_d3_ir.R` equals 0.
    - `wc -l R/as_d3_ir.R` is at least 200 lines smaller than at the start of this plan (≈ -250 lines net).
    - `grep -c 'test_that' tests/testthat/test-ir-scales.R` ≥ 5.
    - `Rscript -e 'devtools::test()'` exits 0; `test-date-scales.R` remains green specifically.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/as_d3_ir.R no longer contains map_discrete / validate_log_domain / get_scale_transform / get_scale_info / the scales-assembly block. The orchestrator's `scales <- extract_scales_ir(...)` is a single line. test-ir-scales.R has at least 5 real assertions (continuous, categorical, color, full-pipeline equivalence, temporal). Full test suite green including date scales.</done>
</task>

</tasks>

<verification>
1. `Rscript -e 'devtools::test()'` → green (0 failures).
2. `grep -c '^get_scale_info <- function' R/as_d3_ir.R` → 0 (deleted).
3. `grep -c 'extract_scales_ir(b' R/as_d3_ir.R` ≥ 1.
4. `wc -l R/as_d3_ir.R` strictly less than the post-Plan-02 value.
5. `git diff NAMESPACE` empty.
</verification>

<success_criteria>
- `R/ir_scales.R` exists with 5 internal functions.
- `R/as_d3_ir.R` no longer defines `map_discrete`, `validate_log_domain`, `get_scale_transform`, `get_scale_info`, or the scales-assembly block.
- `tests/testthat/test-ir-scales.R` has ≥5 real assertions.
- Full `devtools::test()` is green; date-scale tests specifically still pass (Pitfall 4 not regressed).
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-03-SUMMARY.md` listing files modified, the new `wc -l R/as_d3_ir.R` value, and confirming the full suite plus `test-date-scales.R` is green.
</output>
