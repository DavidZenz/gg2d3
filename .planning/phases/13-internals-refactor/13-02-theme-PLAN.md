---
phase: 13
plan: 02
type: execute
wave: 2
depends_on: ["13-01"]
files_modified:
  - R/ir_theme.R
  - R/as_d3_ir.R
  - tests/testthat/test-ir-theme.R
autonomous: true
requirements: [REFACTOR-01, REFACTOR-02]
tags: [r-package, ggplot2, refactor, theme, calc_element]

must_haves:
  truths:
    - "calc_element_safe is the only function in R/ that calls ggplot2:::calc_element"
    - "All 5 v1.0 sites that called ggplot2:::calc_element now call calc_element_safe instead"
    - "calc_element_safe falls back to ggplot2::calc_element (public, exported in 4.0.3) on private-API failure"
    - "calc_element_safe emits exactly one warning per session on fallback (warn-once via .gg2d3_pkgenv$calc_element_warned)"
    - "extract_theme_ir(b) reproduces the v1.0 theme slice (panel/plot/grid/axis/text/legend/strip)"
  artifacts:
    - path: "R/ir_theme.R"
      provides: "calc_element_safe, .gg2d3_warn_once, .gg2d3_calc_element_default, extract_theme_element, extract_theme_ir"
      contains: "calc_element_safe"
    - path: "R/as_d3_ir.R"
      provides: "Orchestrator delegating theme to extract_theme_ir; all calc_element sites routed through calc_element_safe"
      contains: "extract_theme_ir(b)"
    - path: "tests/testthat/test-ir-theme.R"
      provides: "Real assertions for extract_theme_ir + calc_element_safe (fallback + warn-once)"
      contains: "calc_element_safe"
  key_links:
    - from: "R/ir_theme.R"
      to: "ggplot2:::calc_element"
      via: "Tier 1 of calc_element_safe (tryCatch wrapped)"
      pattern: "ggplot2:::calc_element"
    - from: "R/ir_theme.R"
      to: "ggplot2::calc_element"
      via: "Tier 2 public-API fallback"
      pattern: "ggplot2::calc_element"
    - from: "R/ir_theme.R"
      to: ".gg2d3_pkgenv$calc_element_warned"
      via: ".gg2d3_warn_once toggles flag and emits warning() once"
      pattern: "\\.gg2d3_pkgenv\\$calc_element_warned"
---

<objective>
Lift the theme concern out of `R/as_d3_ir.R` into `R/ir_theme.R`, AND introduce the new `calc_element_safe()` chokepoint that closes REFACTOR-02. After this plan, `grep -rn 'ggplot2:::calc_element' R/` matches only the body of `calc_element_safe` in `R/ir_theme.R`. All 5 historical call sites (lines 75, 619, 825, 942, 1061 of v1.0 `R/as_d3_ir.R`) route through it. `extract_theme_ir(b)` reproduces the v1.0 theme slice; the orchestrator delegates `theme = ...` assignment to one call.

Purpose: per CONTEXT D-08 the helper lives in `R/ir_theme.R`, and per the recommended sequencing (theme first because it gates `calc_element_safe`) every later extractor can call `calc_element_safe()` instead of inline `tryCatch({ ... ggplot2:::calc_element ... })` blocks.

Output: `R/ir_theme.R` (new), `R/as_d3_ir.R` (modified — theme block removed, 5 call sites collapsed, 1 new helper call added), `tests/testthat/test-ir-theme.R` (real assertions replacing the stub).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/13-internals-refactor/13-CONTEXT.md
@.planning/phases/13-internals-refactor/13-RESEARCH.md
@.planning/phases/13-internals-refactor/13-PATTERNS.md
@.planning/phases/13-internals-refactor/13-VALIDATION.md
@./CLAUDE.md
@R/as_d3_ir.R
@R/zzz.R
@R/ir_utils.R
@tests/testthat/test-ir.R

<interfaces>
<!-- Contracts established here for downstream extractor plans (03–06). -->

From R/ir_theme.R (created in this plan):
```r
# THE chokepoint. Tier1=ggplot2:::calc_element, Tier2=ggplot2::calc_element (public),
# Tier3=static default. Warns ONCE per session on fallback.
calc_element_safe <- function(element_name, theme)

# Lifted from R/as_d3_ir.R:73-141 — line 75 internal call replaced.
extract_theme_element <- function(element_name, theme)

# Pure function of ggplot_build output. Returns the v1.0 theme list slice
# (panel/plot/grid/axis/text/legend/strip).
extract_theme_ir <- function(b)
```

Downstream plans 03–06 SHOULD call `calc_element_safe(...)` instead of any inline `ggplot2:::calc_element(...)` they encounter while lifting code.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create R/ir_theme.R with calc_element_safe + extract_theme_element + extract_theme_ir</name>
  <files>R/ir_theme.R</files>
  <read_first>
    - R/as_d3_ir.R lines 73-141 (the inline `extract_theme_element` closure — lift verbatim, ONE edit at line 75: `ggplot2:::calc_element(...)` → `calc_element_safe(...)`).
    - R/as_d3_ir.R lines 535-571 (theme assembly: panel/plot/grid/axis blocks of `theme_ir <- list(...)`).
    - R/as_d3_ir.R lines 819-856 (legend.theme + strip block + the inline `tryCatch` for legend.key.size at 822-833 that calls `ggplot2:::calc_element("legend.key.size", complete_theme)`).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/ir_theme.R` section — exact `calc_element_safe`, `.gg2d3_warn_once`, `.gg2d3_calc_element_default` bodies, plus `extract_theme_ir` skeleton).
    - .planning/phases/13-internals-refactor/13-RESEARCH.md (Pattern 2 — verbatim implementation; D-06 three-tier chain; D-07 once-per-session warn).
    - R/zzz.R (just-created in Plan 01 — confirm `.gg2d3_pkgenv$calc_element_warned` exists and is FALSE on load).
  </read_first>
  <behavior>
    - Test 1: `calc_element_safe("panel.background", theme)` returns the SAME object as `ggplot2:::calc_element("panel.background", theme)` for a vanilla `theme_grey()` — Tier 1 path, no warning emitted.
    - Test 2: `.gg2d3_reset_calc_element_warned(); calc_element_safe("nonexistent.element.name", broken_theme)` (where Tier 1 errors) emits exactly one `warning()` whose message contains "ggplot2:::calc_element() failed" and either "public-API path" or "static default".
    - Test 3: A second invocation immediately afterwards (without resetting) is `expect_silent` — warn-once gate via `.gg2d3_pkgenv$calc_element_warned`.
    - Test 4: For `legend.position` / `legend.key.size` / `panel.spacing`, when both Tier 1 and Tier 2 fail, the Tier 3 default matches `.gg2d3_calc_element_default` ("right" / `unit(1.2, "lines")` / `unit(5.5, "pt")`).
    - Test 5: `extract_theme_ir(ggplot_build(ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_grey()))` returns a list with non-NULL `panel`, `plot`, `grid`, `axis`, `text`, `legend`, `strip` keys.
  </behavior>
  <action>
Create `R/ir_theme.R` with the following structure (use Write tool). All functions are `#' @keywords internal #' @noRd` — zero `@export` directives.

**Section 1 — `calc_element_safe` (the new helper, REFACTOR-02 chokepoint):** Implement per RESEARCH Pattern 2 and PATTERNS Section "calc_element_safe pattern". Three tiers:
1. `tryCatch(ggplot2:::calc_element(element_name, theme), error = function(e) e)`. If not an error, return.
2. `tryCatch({ complete <- ggplot2::theme_get() + theme; ggplot2::calc_element(element_name, complete) }, error = function(e) e)`. If not an error: `.gg2d3_warn_once(element_name, "public-API path")`; return.
3. `default <- .gg2d3_calc_element_default(element_name); .gg2d3_warn_once(element_name, "static default"); return(default)`.

**Section 2 — `.gg2d3_warn_once`:** Reads `.gg2d3_pkgenv$calc_element_warned` (created in Plan 01). If TRUE, returns invisible. Else sets to TRUE and emits a `warning(sprintf(...), call. = FALSE)` whose message names the failing element, the path label, and `as.character(utils::packageVersion("ggplot2"))`.

**Section 3 — `.gg2d3_calc_element_default`:** `switch(element_name, legend.position = "right", legend.key.size = grid::unit(1.2, "lines"), panel.spacing = grid::unit(5.5, "pt"), NULL)`.

**Section 4 — `extract_theme_element(element_name, theme)`:** Lift `R/as_d3_ir.R:73-141` verbatim. Single edit: line 75 changes from `calc <- ggplot2:::calc_element(element_name, theme)` to `calc <- calc_element_safe(element_name, theme)`. Keep the linewidth conversion `* 3.7795275591` exactly as-is (per MEMORY.md and PATTERNS — DO NOT change in this phase).

**Section 5 — `extract_theme_ir(b)`:** Pure function. Returns NULL if `b$plot$theme` is NULL. Otherwise builds the list per PATTERNS sketch:
- `panel = list(background, border)` from `extract_theme_element("panel.background"|"panel.border", b$plot$theme)` (current code R/as_d3_ir.R:535-571).
- `plot = list(background, margin)`.
- `grid = list(major, minor)` from `panel.grid.major`, `panel.grid.minor`.
- `axis = list(line, line.x, line.y, text, text.x, text.y, title, title.x, title.y, ticks, ticks.x, ticks.y, ticks.length, ticks.length.x, ticks.length.y)` — copy verbatim from current 552-571 (preserve every key the v1.0 IR exposed).
- `text = list(title, subtitle, caption)` from `plot.title`, `plot.subtitle`, `plot.caption`.
- `legend = list(key.size, text, title, background, key)` — `key.size` lifted from R/as_d3_ir.R:822-833. The current inline does `tryCatch({ complete_theme <- ggplot2::theme_get() + b$plot$theme; spacing <- ggplot2:::calc_element("legend.key.size", complete_theme); grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96 }, error = function(e) NULL)`. Replace the `complete_theme` + `ggplot2:::calc_element` two-line dance with `spacing <- calc_element_safe("legend.key.size", b$plot$theme)`. Keep the surrounding `tryCatch` and the `grid::convertUnit(...) * 96` pixel conversion verbatim.
- `strip = list(text, background)`.

Use namespaced calls (`ggplot2::theme_get`, `grid::convertUnit`, `utils::packageVersion`) per PATTERNS Pattern D — do NOT add `@importFrom`.

**Do NOT modify `R/as_d3_ir.R` in this task.** The orchestrator's inline `extract_theme_element` (line 73-141) still shadows the new top-level one — that's by design until Task 2 wires it.
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(); stopifnot(exists("calc_element_safe"), exists("extract_theme_ir"), exists("extract_theme_element")); .gg2d3_reset_calc_element_warned(); library(ggplot2); t <- theme_grey(); r <- calc_element_safe("panel.background", t); stopifnot(!is.null(r)); stopifnot(isFALSE(.gg2d3_pkgenv$calc_element_warned)); cat("OK tier1 silent\n")'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/ir_theme.R` exits 0.
    - `grep -cE '^calc_element_safe <- function' R/ir_theme.R` equals 1.
    - `grep -cE '^extract_theme_element <- function' R/ir_theme.R` equals 1.
    - `grep -cE '^extract_theme_ir <- function' R/ir_theme.R` equals 1.
    - `grep -c 'ggplot2:::calc_element' R/ir_theme.R` equals 1 (only inside `calc_element_safe`'s Tier 1 tryCatch).
    - `grep -c 'ggplot2::calc_element' R/ir_theme.R` ≥ 2 (Tier 2 line) — note the regex must distinguish from `:::`; use `grep -cE 'ggplot2::calc_element\\b' R/ir_theme.R | grep -v ':::'`. Equivalently: `grep -E 'ggplot2::calc_element' R/ir_theme.R | grep -vc ':::'` ≥ 1.
    - `grep -c '@export' R/ir_theme.R` equals 0.
    - `Rscript -e 'devtools::document()'` produces no NAMESPACE diff (`git diff NAMESPACE` empty).
    - The verify command exits 0 with `OK tier1 silent` printed.
  </acceptance_criteria>
  <done>R/ir_theme.R contains calc_element_safe (3-tier chain), .gg2d3_warn_once, .gg2d3_calc_element_default, extract_theme_element (line-75-equivalent call rewritten), and extract_theme_ir. All internal. NAMESPACE unchanged.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire orchestrator to extract_theme_ir; replace all 5 v1.0 calc_element sites with calc_element_safe; add real assertions to test-ir-theme.R</name>
  <files>R/as_d3_ir.R, tests/testthat/test-ir-theme.R</files>
  <read_first>
    - R/as_d3_ir.R lines 73-141 (inline `extract_theme_element` closure — DELETE).
    - R/as_d3_ir.R lines 535-571 (inline theme assembly — DELETE; replaced by `extract_theme_ir(b)` call).
    - R/as_d3_ir.R lines 615-625 (Site 2 — `legend.position` calc_element call — REPLACE inline `complete_theme <- ...; ggplot2:::calc_element("legend.position", complete_theme)` with `calc_element_safe("legend.position", b$plot$theme)`).
    - R/as_d3_ir.R lines 819-856 (legend theme block including Site 3 — `legend.key.size` at 822-833 — DELETE the block; lifted into extract_theme_ir).
    - R/as_d3_ir.R lines 935-955 (Site 4 — `panel.spacing` for FacetWrap calc_element — REPLACE with `calc_element_safe("panel.spacing", b$plot$theme)`).
    - R/as_d3_ir.R lines 1055-1075 (Site 5 — `panel.spacing` for FacetGrid — REPLACE with `calc_element_safe("panel.spacing", b$plot$theme)`).
    - R/ir_theme.R (just-created — confirm exports the 3 functions needed).
    - tests/testthat/test-ir-theme.R (current stub from Plan 01).
    - tests/testthat/test-ir.R (existing — full pipeline regression that must keep passing).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (test-ir-theme.R warn-once test sketch).
  </read_first>
  <behavior>
    - Test 1: `extract_theme_ir(ggplot_build(ggplot(mtcars, aes(wt, mpg)) + geom_point()))$panel$background` is non-NULL and matches the panel.background slice the v1.0 pipeline produces (compare to `as_d3_ir(p)$theme$panel$background`).
    - Test 2: `extract_theme_ir(b)$legend$key.size` is numeric (pixels) when theme has a defined legend.key.size.
    - Test 3: `.gg2d3_reset_calc_element_warned(); calc_element_safe("totally.fake.element", theme_grey())` warns exactly once; second call is `expect_silent`.
    - Test 4: After this task, `as_d3_ir(p)$theme` is structurally equivalent to its v1.0 output for a vanilla `ggplot(mtcars, aes(wt, mpg)) + geom_point()` plot.
    - Test 5: After this task, `grep -rn 'ggplot2:::calc_element' R/` matches ONLY R/ir_theme.R.
  </behavior>
  <action>
**Part A — Edit `R/as_d3_ir.R`:**

1. **Delete inline `extract_theme_element` closure** (lines 73-141). It now lives in `R/ir_theme.R`.

2. **Replace inline theme assembly** (lines 535-571) with a single line: `theme_ir <- extract_theme_ir(b)`. Keep the line that assigns `theme = theme_ir` into the `ir` list (currently around line 1149).

3. **Site 2 — legend.position** (around lines 615-625). Current code:
   ```r
   legend_position <- tryCatch({
     complete_theme <- ggplot2::theme_get() + b$plot$theme
     pos <- ggplot2:::calc_element("legend.position", complete_theme)
     if (is.character(pos)) pos else "right"
   }, error = function(e) "right")
   ```
   Replace with:
   ```r
   legend_position <- tryCatch({
     pos <- calc_element_safe("legend.position", b$plot$theme)
     if (is.character(pos)) pos else "right"
   }, error = function(e) "right")
   ```

4. **Delete legend theme block** (lines 819-856). It is now inside `extract_theme_ir` (Task 1 lifted it).

5. **Site 4 — panel.spacing for FacetWrap** (around lines 935-955). Current code does:
   ```r
   panel_spacing <- tryCatch({
     complete_theme <- ggplot2::theme_get() + b$plot$theme
     spacing <- ggplot2:::calc_element("panel.spacing", complete_theme)
     if (!is.null(spacing)) grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96 else 7.3
   }, error = function(e) 7.3)
   ```
   Replace with:
   ```r
   panel_spacing <- tryCatch({
     spacing <- calc_element_safe("panel.spacing", b$plot$theme)
     if (!is.null(spacing)) grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96 else 7.3
   }, error = function(e) 7.3)
   ```

6. **Site 5 — panel.spacing for FacetGrid** (around lines 1055-1075). Same rewrite as Site 4.

7. **Verify zero remaining `ggplot2:::calc_element` references** in R/as_d3_ir.R via `grep -c 'ggplot2:::calc_element' R/as_d3_ir.R` → expect 0.

8. **Do NOT remove** the inline `%||%`, `to_rows`, `dom`, `keep_aes`, `map_discrete`, `validate_log_domain`, `get_scale_transform`, `get_scale_info` closures yet — they're consumed by extractor blocks not yet lifted (Plans 03–06). They will be removed in those plans.

**Part B — Replace `tests/testthat/test-ir-theme.R` stub with real assertions** per PATTERNS test-ir-theme.R sketch:

```r
test_that("extract_theme_ir returns the expected top-level structure", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  th <- extract_theme_ir(b)
  expect_false(is.null(th))
  expect_true(all(c("panel","plot","grid","axis","text","legend","strip") %in% names(th)))
  expect_false(is.null(th$panel$background))
})

test_that("extract_theme_ir output matches the v1.0 as_d3_ir theme slice", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  expect_equal(ir$theme, extract_theme_ir(b))
})

test_that("calc_element_safe Tier 1 succeeds for a vanilla theme without warning", {
  .gg2d3_reset_calc_element_warned()
  library(ggplot2)
  expect_silent(res <- calc_element_safe("panel.background", theme_grey()))
  expect_false(.gg2d3_pkgenv$calc_element_warned)
  expect_false(is.null(res))
})

test_that("calc_element_safe falls back and warns once on Tier 1 failure", {
  .gg2d3_reset_calc_element_warned()
  # An element name guaranteed not to resolve in any tier of the public API.
  expect_warning(
    calc_element_safe("element.that.does.not.exist", ggplot2::theme_grey()),
    regexp = "ggplot2:::calc_element\\(\\) failed"
  )
  # warn-once: subsequent calls are silent
  expect_silent(calc_element_safe("element.that.does.not.exist.either", ggplot2::theme_grey()))
})

test_that("calc_element_safe static defaults match documented values", {
  expect_identical(.gg2d3_calc_element_default("legend.position"), "right")
  expect_identical(.gg2d3_calc_element_default("legend.key.size"), grid::unit(1.2, "lines"))
  expect_identical(.gg2d3_calc_element_default("panel.spacing"),  grid::unit(5.5, "pt"))
  expect_null(.gg2d3_calc_element_default("anything.else"))
})
```

After both edits, run `Rscript -e 'devtools::test()'` — full suite must be green. Visual baseline corpus does NOT need to be re-rendered yet; that gate is in Plan 07.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()' && bash -lc 'set -e; n=$(grep -rn "ggplot2:::calc_element" R/ | grep -v "R/ir_theme.R" | wc -l | tr -d " "); test "$n" -eq 0 || (echo "FAIL: ggplot2::: outside ir_theme.R: $n hits"; grep -rn "ggplot2:::calc_element" R/; exit 1); echo "OK no leaks"'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l` equals 0 (REFACTOR-02 success criterion).
    - `grep -c 'ggplot2:::calc_element' R/ir_theme.R` equals 1.
    - `grep -c 'extract_theme_ir(b)' R/as_d3_ir.R` ≥ 1 (orchestrator delegates).
    - `grep -c '^extract_theme_element <- function' R/as_d3_ir.R` equals 0 (closure deleted).
    - `grep -c 'calc_element_safe' R/as_d3_ir.R` ≥ 3 (legend.position + 2 panel.spacing sites; the 5th was the `extract_theme_element` line-75 call which is now in `R/ir_theme.R`, the 4th was legend.key.size which is now in `extract_theme_ir`).
    - `grep -c 'test_that' tests/testthat/test-ir-theme.R` ≥ 5.
    - `Rscript -e 'devtools::test()'` exits 0 with zero failures (regression baseline maintained).
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/as_d3_ir.R no longer references ggplot2:::calc_element; the only such reference in R/ is inside calc_element_safe in R/ir_theme.R. The orchestrator delegates the entire theme slice to extract_theme_ir(b). test-ir-theme.R has at least 5 real assertions covering structure equivalence, v1.0 compatibility, Tier 1 silence, fallback warn-once, and static defaults. Full test suite is green.</done>
</task>

</tasks>

<verification>
1. `grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l` → 0. (REFACTOR-02 gate.)
2. `Rscript -e 'devtools::test()'` → green.
3. `Rscript -e 'devtools::document()'` followed by `git diff NAMESPACE` → empty.
4. `grep -c 'extract_theme_ir' R/as_d3_ir.R` ≥ 1 (orchestrator delegates).
5. `wc -l R/as_d3_ir.R` is strictly less than 1151 (theme block removed).
</verification>

<success_criteria>
- `R/ir_theme.R` exists with `calc_element_safe`, `.gg2d3_warn_once`, `.gg2d3_calc_element_default`, `extract_theme_element`, `extract_theme_ir` — all `@keywords internal @noRd`.
- All 5 v1.0 sites that used `ggplot2:::calc_element` now route through `calc_element_safe` (REFACTOR-02 success criterion).
- The orchestrator delegates the theme block to `extract_theme_ir(b)` (REFACTOR-01 progress).
- `tests/testthat/test-ir-theme.R` has real assertions covering structural equivalence, v1.0-output equivalence, Tier 1 silence, fallback warn-once, and Tier 3 static defaults.
- Full `devtools::test()` is green; NAMESPACE unchanged.
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-02-SUMMARY.md` listing files created/modified, the post-edit `wc -l R/as_d3_ir.R` value, and confirming the `grep -rn 'ggplot2:::calc_element' R/` audit shows only `R/ir_theme.R`.
</output>
