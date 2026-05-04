---
phase: 13
plan: 05
type: execute
wave: 5
depends_on: ["13-01", "13-02", "13-03", "13-04"]
files_modified:
  - R/ir_legends.R
  - R/as_d3_ir.R
  - tests/testthat/test-ir-legends.R
autonomous: true
requirements: [REFACTOR-01]
tags: [r-package, ggplot2, refactor, legends, guides]

must_haves:
  truths:
    - "extract_legends_ir(b, p) returns list(position, guides) matching v1.0 legend output"
    - "Orchestrator's legend block (lines ~616-817) is replaced with single delegating call"
    - "ggplot2::get_guide_data() public API still used (not hand-rolled)"
    - "Legend merge-by-title pass at v1.0 lines 760-816 preserved"
    - "legend.position resolution routes through calc_element_safe (already wired in Plan 02)"
  artifacts:
    - path: "R/ir_legends.R"
      provides: "extract_legends_ir + any legend-internal helpers (continuous colorbar, discrete keys, guide merging)"
      contains: "extract_legends_ir"
    - path: "R/as_d3_ir.R"
      provides: "Orchestrator with legend block removed"
      contains: "extract_legends_ir(b"
    - path: "tests/testthat/test-ir-legends.R"
      provides: "Real assertions covering position, discrete guide, continuous (colorbar/discrete depending on v1.0 behavior)"
      contains: "extract_legends_ir"
  key_links:
    - from: "R/ir_legends.R"
      to: "ggplot2::get_guide_data"
      via: "public API call for per-aesthetic guide data"
      pattern: "ggplot2::get_guide_data"
    - from: "R/ir_legends.R"
      to: "R/ir_theme.R::calc_element_safe"
      via: "legend.position resolution"
      pattern: "calc_element_safe\\(\"legend\\.position\""
---

<objective>
Lift the legends concern out of `R/as_d3_ir.R` into `R/ir_legends.R`. After this plan, the orchestrator's legend block (currently `R/as_d3_ir.R:616-817` post-Plan-02 — Plan 02 already touched the legend.position site at 615-625, so this plan operates on the post-Plan-02 line numbering — but the legend assembly + merge logic is intact) is replaced by `legends <- extract_legends_ir(b, p)` and the orchestrator destructures `legend_position <- legends$position; guides_ir <- legends$guides`.

Purpose: REFACTOR-01 progress. Legends are ~200 lines and use `ggplot2::get_guide_data()` (public API) — clean lift.

Output: `R/ir_legends.R` (new), `R/as_d3_ir.R` (modified — legend block removed), `tests/testthat/test-ir-legends.R` (real assertions).
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
@R/ir_utils.R
@tests/testthat/test-legends.R

<interfaces>
<!-- Established by this plan. -->

From R/ir_legends.R:
```r
extract_legends_ir <- function(b, p)
# Returns: list(position = <character>, guides = <list>)
# `p` is the ggplot object (not just b) because ggplot2::get_guide_data(p, aesthetic = ...)
# requires the plot object, not the built object.
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create R/ir_legends.R; rewrite orchestrator to delegate; add real assertions to test-ir-legends.R</name>
  <files>R/ir_legends.R, R/as_d3_ir.R, tests/testthat/test-ir-legends.R</files>
  <read_first>
    - R/as_d3_ir.R — read the entire current legend block. Plan 02 already replaced the inline `complete_theme + ggplot2:::calc_element("legend.position", ...)` with `calc_element_safe("legend.position", b$plot$theme)`. The block now spans roughly the lines that previously were 615-817; verify exact post-Plan-02 boundaries before lifting.
    - R/as_d3_ir.R: lines 616-625 (post-Plan-02) — `legend_position <- tryCatch(...)` block.
    - R/as_d3_ir.R: lines 632-817 (post-Plan-02) — `if (legend_position != "none") { ... guides_ir <- list(); for (aes_name in ...) { gd <- ggplot2::get_guide_data(p, aesthetic = aes_name); ...; if continuous colour/fill and inherits guide colorbar -> colorbar branch; else discrete keys branch ... }; merge-by-title pass ... }`.
    - R/as_d3_ir.R lines 667 (post-Plan-02) — the `ggplot2::get_guide_data(p, aesthetic = aes_name)` call. Public API, keep using it (PATTERNS Don't Hand-Roll).
    - R/as_d3_ir.R lines 760-816 (post-Plan-02) — the merge-by-title pass that consolidates guides sharing a title. PRESERVE verbatim.
    - tests/testthat/test-legends.R (existing — comprehensive legend test suite; must remain green).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/ir_legends.R` section — entry-point sketch).
  </read_first>
  <behavior>
    - Test 1: For `ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()`, `extract_legends_ir(b, p)$position == "right"` (default theme).
    - Test 2: Same plot — `$guides` is a non-empty list with at least one element having `$title == "factor(cyl)"` and `$type` in `{"discrete","categorical","colorbar"}` (whatever v1.0 emits).
    - Test 3: For `ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme(legend.position = "none")`, `extract_legends_ir(b, p)$position == "none"` and `$guides` is `list()`.
    - Test 4: For a plot with the same title on color and fill aesthetics, the merge-by-title pass collapses them — v1.0 behavior preserved.
    - Test 5: `extract_legends_ir(b, p)$guides` `expect_equal` to `as_d3_ir(p)$guides` for a discrete-colour point plot.
  </behavior>
  <action>
**Part A — Create `R/ir_legends.R`:**

Lift the legend block wholesale. Top-level entry:

```r
# Legend extraction. Reads guide data via the public ggplot2 API.

#' @keywords internal
#' @noRd
extract_legends_ir <- function(b, p) {
  legend_position <- tryCatch({
    pos <- calc_element_safe("legend.position", b$plot$theme)
    if (is.character(pos)) pos else "right"
  }, error = function(e) "right")

  guides_ir <- list()
  if (legend_position != "none") {
    # ============ LIFT VERBATIM from R/as_d3_ir.R post-Plan-02 ============
    # The for-loop walking b$plot$scales (or b$plot$layers, whichever v1.0 uses
    # to enumerate aesthetics needing legends).
    # The colorbar branch (continuous colour/fill).
    # The discrete keys branch.
    # The merge-by-title pass at the end.
    # =====================================================================
    # ... (verbatim from current orchestrator) ...
  }

  list(position = legend_position, guides = guides_ir)
}
```

**Implementation note:** This task is mechanical lifting. Open `R/as_d3_ir.R`, identify the exact post-Plan-02 line range of the legend block, and copy-paste it inside `extract_legends_ir`. Adjust ONLY the variables that came from outer orchestrator scope:
- `legend_position` (was a local in orchestrator) — now local to this function ✓.
- `guides_ir` (was a local in orchestrator) — now local ✓.
- All references to `b$plot$theme`, `b$plot$scales`, `b$plot$layers`, `b$data` — already pass through `b`, no change.
- `p` — must be passed as a function argument because `ggplot2::get_guide_data(p, aesthetic = ...)` needs the plot object (not the built object). Add `p` to the signature.

**Anti-pattern check:** No `<<-` in the legend block (verified — only the facets block uses `<<-`). No closure-capture rewrites needed beyond `p` and `b`.

**Part B — Edit `R/as_d3_ir.R`:**

1. Identify the post-Plan-02 line range of the legend block. Replace the entire block (`legend_position <- tryCatch(...)` through the end of the merge-by-title pass) with:
   ```r
   legends <- extract_legends_ir(b, p)
   legend_position <- legends$position
   guides_ir       <- legends$guides
   ```
   `legend_position` is still consumed by the final `ir <- list(... legend = list(enabled = TRUE, position = legend_position) ...)`. `guides_ir` is consumed by `ir$guides <- guides_ir` (already in v1.0 final assembly). No further callsite changes needed.

2. Verify zero leftover `ggplot2::get_guide_data` calls in `R/as_d3_ir.R` after the edit:
   ```bash
   grep -c 'get_guide_data' R/as_d3_ir.R   # → 0
   ```

**Part C — Replace `tests/testthat/test-ir-legends.R` stub with real assertions:**

```r
test_that("extract_legends_ir returns position right by default", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_equal(L$position, "right")
})

test_that("extract_legends_ir produces a guide for discrete colour aesthetic", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_true(length(L$guides) >= 1L)
})

test_that("extract_legends_ir respects theme(legend.position = 'none')", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() + theme(legend.position = "none")
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_equal(L$position, "none")
  expect_equal(length(L$guides), 0L)
})

test_that("extract_legends_ir output equals as_d3_ir guides slice for a discrete-colour point plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  L  <- extract_legends_ir(b, p)
  expect_equal(ir$guides, L$guides)
  expect_equal(ir$legend$position, L$position)
})

test_that("extract_legends_ir handles a plot with no legend-eligible aesthetic", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  # No mapped aesthetics other than x/y → guides should be empty.
  expect_equal(length(L$guides), 0L)
})
```

After all three parts, run `Rscript -e 'devtools::test()'` — full suite green, including `test-legends.R`.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/ir_legends.R` exits 0; `grep -cE '^extract_legends_ir <- function' R/ir_legends.R` equals 1.
    - `grep -c '@export' R/ir_legends.R` equals 0.
    - `grep -c 'extract_legends_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'get_guide_data' R/as_d3_ir.R` equals 0 (lifted into ir_legends.R).
    - `grep -c 'get_guide_data' R/ir_legends.R` ≥ 1.
    - `wc -l R/as_d3_ir.R` is at least 150 lines smaller than at the start of this plan.
    - `grep -c 'test_that' tests/testthat/test-ir-legends.R` ≥ 5.
    - `Rscript -e 'devtools::test()'` exits 0; `test-legends.R` specifically remains green.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/ir_legends.R contains extract_legends_ir using ggplot2::get_guide_data and calc_element_safe. R/as_d3_ir.R no longer contains the legend block or get_guide_data calls. test-ir-legends.R has ≥5 assertions. test-legends.R green.</done>
</task>

</tasks>

<verification>
1. `Rscript -e 'devtools::test()'` → green.
2. `grep -c 'get_guide_data' R/as_d3_ir.R` → 0.
3. `grep -c 'extract_legends_ir(b' R/as_d3_ir.R` ≥ 1.
4. `wc -l R/as_d3_ir.R` strictly less than post-Plan-04 value.
</verification>

<success_criteria>
- `R/ir_legends.R` exists with `extract_legends_ir(b, p)`.
- Orchestrator delegates legend extraction to a single call.
- `tests/testthat/test-ir-legends.R` has ≥5 real assertions.
- `test-legends.R` remains green; full suite green.
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-05-SUMMARY.md` listing files modified, post-edit `wc -l R/as_d3_ir.R`, and confirming `test-legends.R` is green.
</output>
