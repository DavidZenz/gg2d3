---
phase: 14
plan: 05
type: execute
wave: 3
depends_on: ["14-03"]
files_modified:
  - R/ir_legends.R
  - tests/testthat/test-ir-legends.R
  - tests/testthat/test-color-fidelity.R
autonomous: true
requirements: [COLOR-02]
tags: [r-package, ggplot2, legends, colorbar, ir-enrichment]

must_haves:
  truths:
    - "Colorbar guide_spec carries breaks (numeric vector from scale_obj$get_breaks)"
    - "Colorbar guide_spec carries labels (character vector from scale_obj$get_labels)"
    - "Colorbar guide_spec carries na.value (defaults to 'grey50')"
    - "Colorbar guide_spec carries domain (numeric c(min, max) from scale_obj$get_limits)"
    - "Colorbar guide_spec carries is_continuous (TRUE for ScaleContinuous + ScaleBinned)"
    - "Colorbar guide_spec carries orientation: 'horizontal' for legend.position top/bottom, else 'vertical' (D-10)"
    - "Colorbar guide_spec carries legend_position from theme so renderer knows placement"
    - "Banded colorbars (is_steps=TRUE) carry bin-aware breaks suitable for hard-stop gradients"
    - "Smooth colorbar colors_array remains 30 stops by default (D-09)"
  artifacts:
    - path: "R/ir_legends.R"
      provides: "Colorbar branch enriched with breaks/labels/na.value/domain/is_continuous/orientation/legend_position"
      contains: "orientation"
  key_links:
    - from: "R/ir_legends.R"
      to: "ggplot2 scale_obj$get_breaks / get_labels / get_limits"
      via: "public scale-object accessors"
      pattern: "get_breaks|get_labels|get_limits"
    - from: "R/ir_legends.R"
      to: "b$plot$theme$legend.position"
      via: "theme element lookup with theme_get fallback"
      pattern: "legend\\.position"
---

<objective>
Fix Pitfall 4: the colorbar branch in `R/ir_legends.R:101-114` produces a `colors_array` (30 sampled stops) but no `breaks`, `labels`, `na.value`, `domain`, or `is_continuous`. The downstream JS `renderColorbar` (plan 14-06) needs all of these to render proper ticks (D-08), to carry NA color metadata (D-11), and to choose smooth-vs-banded gradients (D-06, building on plan 14-03's `is_steps`).

Also, per **D-10**: the colorbar must default to vertical orientation but render horizontally when the user sets `theme(legend.position = "top"|"bottom")`. The IR carries an `orientation` string ("vertical" | "horizontal") plus the raw `legend_position` so the JS renderer (plan 14-06) can branch layout without re-deriving theme state.

This plan only enriches the IR. JS rendering changes are plan 14-06.

Banded gradient strategy (D-06, Pitfall 8): for `is_steps=TRUE`, also include enough information for the JS to build a 2-stop-per-bin gradient. Concretely, the JS needs the bin boundaries (already available as `breaks`) plus the per-bin colors. For ScaleBinned, `scale_obj$map(breaks)` gives one color per bin boundary; the JS can pair them. To avoid ambiguity, this plan emits an additional `bin_colors` field for banded scales — `scale_obj$map(midpoints_between(breaks))` — so the renderer doesn't have to guess.

Purpose: COLOR-02 IR enrichment, including D-10 orientation. Last R-side change before JS render extension (14-06) and snapshot corpus (14-07).

Output:
- `R/ir_legends.R` — colorbar branch grows by ~30 lines.
- `tests/testthat/test-ir-legends.R` — +2 tests asserting field presence and orientation logic.
- `tests/testthat/test-color-fidelity.R` — flip 2 skip-pending blocks (`colorbar IR carries breaks labels na.value domain is_continuous` + `colorbar IR orientation defaults vertical and flips horizontal for legend.position bottom`).
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
- `R/ir_legends.R` — colorbar branch enriched: ~30 lines added between current lines 101 and 123.
- `tests/testthat/test-ir-legends.R` — +2 tests (~50 lines).
- `tests/testthat/test-color-fidelity.R` — 2 blocks flipped (~50 lines).
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: TEST — RED assertions for breaks/labels/na.value/domain/is_continuous/orientation on colorbar guides</name>
  <files>tests/testthat/test-ir-legends.R, tests/testthat/test-color-fidelity.R</files>
  <behavior>
    - viridis_c colorbar guide has named fields: breaks (numeric), labels (character), na.value (character "grey50"), domain (numeric length 2), is_continuous (TRUE).
    - length(breaks) == length(labels) > 0.
    - length(breaks) == length(scale_obj$get_breaks(scale_obj$get_limits())).
    - distiller and steps colorbar guides also carry the fields.
    - bin_colors is non-NULL when is_steps == TRUE; NULL when is_steps == FALSE.
    - Default theme: g$orientation == "vertical".
    - theme(legend.position = "bottom"): g$orientation == "horizontal".
    - theme(legend.position = "top"): g$orientation == "horizontal".
    - theme(legend.position = "right" | "left"): g$orientation == "vertical".
    - g$legend_position carries the raw position string from the theme.
  </behavior>
  <action>
**Part A — `tests/testthat/test-ir-legends.R`:** Append:

```r
test_that("colorbar guide carries breaks/labels/na.value/domain/is_continuous", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_viridis_c()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  g <- Filter(function(x) identical(x$aesthetic, "colour"), L$guides)[[1]]
  expect_equal(g$type, "colorbar")
  expect_true(is.numeric(g$breaks))
  expect_true(is.character(g$labels))
  expect_equal(length(g$breaks), length(g$labels))
  expect_true(is.character(g$na.value))
  expect_true(is.numeric(g$domain))
  expect_equal(length(g$domain), 2L)
  expect_true(isTRUE(g$is_continuous))
})

test_that("colorbar orientation flips per legend.position theme (D-10)", {
  library(ggplot2)
  base <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_viridis_c()

  # Default theme — vertical.
  p_default <- base
  g_def <- Filter(function(x) identical(x$aesthetic, "colour"),
                  extract_legends_ir(ggplot_build(p_default), p_default)$guides)[[1]]
  expect_equal(g_def$orientation, "vertical")

  # legend.position = "bottom" — horizontal.
  p_bot <- base + theme(legend.position = "bottom")
  g_bot <- Filter(function(x) identical(x$aesthetic, "colour"),
                  extract_legends_ir(ggplot_build(p_bot), p_bot)$guides)[[1]]
  expect_equal(g_bot$orientation, "horizontal")
  expect_equal(g_bot$legend_position, "bottom")

  # legend.position = "top" — horizontal.
  p_top <- base + theme(legend.position = "top")
  g_top <- Filter(function(x) identical(x$aesthetic, "colour"),
                  extract_legends_ir(ggplot_build(p_top), p_top)$guides)[[1]]
  expect_equal(g_top$orientation, "horizontal")

  # legend.position = "right" — vertical (default-ish).
  p_right <- base + theme(legend.position = "right")
  g_right <- Filter(function(x) identical(x$aesthetic, "colour"),
                    extract_legends_ir(ggplot_build(p_right), p_right)$guides)[[1]]
  expect_equal(g_right$orientation, "vertical")
})

test_that("steps colorbar guide carries bin_colors when is_steps TRUE", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_steps()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  g <- Filter(function(x) identical(x$aesthetic, "colour"), L$guides)[[1]]
  expect_true(isTRUE(g$is_steps))
  expect_false(is.null(g$bin_colors))
  expect_true(length(g$bin_colors) >= 1L)
})
```

**Part B — `tests/testthat/test-color-fidelity.R`:** Replace the two skip-pending blocks:

```r
test_that("colorbar IR carries breaks labels na.value domain is_continuous", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_viridis_c()
  scale_obj <- scale_by_aes(p, "colour")
  ref_breaks <- scale_reference_breaks(scale_obj)
  ref_labels <- scale_reference_labels(scale_obj, ref_breaks)
  g <- guide_by_aes(p, "colour")
  expect_equal(g$breaks, unname(ref_breaks))
  expect_equal(g$labels, as.character(ref_labels))
  expect_equal(g$na.value, scale_obj$na.value %||% "grey50")
  expect_equal(g$domain, unname(scale_obj$get_limits()))
  expect_true(isTRUE(g$is_continuous))
})

test_that("colorbar IR orientation defaults vertical and flips horizontal for legend.position bottom", {
  library(ggplot2)
  p_v <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + scale_color_viridis_c()
  p_h <- p_v + theme(legend.position = "bottom")
  g_v <- guide_by_aes(p_v, "colour")
  g_h <- guide_by_aes(p_h, "colour")
  expect_equal(g_v$orientation, "vertical")
  expect_equal(g_h$orientation, "horizontal")
})
```

Run the suite. The new assertions are RED (orientation field doesn't exist; breaks/labels/na.value fields don't exist).

Count expected RED test_that blocks introduced/flipped here: 5 (3 in test-ir-legends.R, 2 in test-color-fidelity.R). The verifier asserts `failed >= 5` to ensure each new assertion is genuinely red.

Commit:
```
git add tests/testthat/test-ir-legends.R tests/testthat/test-color-fidelity.R
git commit -m "test(14-05): RED — colorbar IR enrichment + orientation (D-10)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_dir("tests/testthat", reporter="silent"); failed <- sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_failure"), logical(1))), integer(1))); stopifnot(failed >= 5)'</automated>
  </verify>
  <done>5 new assertions added; full suite shows ≥5 new RED relative to phase-13 baseline plus prior phase 14 plans.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: IMPL — enrich colorbar branch with breaks/labels/na.value/domain/is_continuous/bin_colors/orientation</name>
  <files>R/ir_legends.R</files>
  <action>
Edit `R/ir_legends.R`. Locate the colorbar branch (currently lines ~101-114) and the `guide_spec` assembly (lines ~116-123). Restructure to:

```r
# Colorbar enrichment — fields needed by renderColorbar (plan 14-06):
# breaks/labels (D-08), na.value (D-11), domain (tick positions), is_continuous,
# bin_colors (D-06 banded gradient), orientation (D-10).
colors_array <- NULL
breaks <- NULL
labels <- NULL
na_value <- NULL
domain <- NULL
bin_colors <- NULL
orientation <- NULL
legend_position <- NULL

if (guide_type == "colorbar") {
  scale_domain <- tryCatch(
    scale_obj$get_limits(),
    error = function(e) c(0, 1)
  )
  domain <- unname(scale_domain)

  # Smooth gradient sampling — Pitfall 4 keeps the existing 30-stop sample.
  color_values <- seq(scale_domain[1], scale_domain[2], length.out = 30)
  colors_array <- tryCatch(
    scale_obj$map(color_values),
    error = function(e) NULL
  )

  breaks <- tryCatch(
    unname(scale_obj$get_breaks(scale_domain)),
    error = function(e) NULL
  )
  labels <- tryCatch(
    as.character(scale_obj$get_labels(breaks)),
    error = function(e) NULL
  )
  na_value <- tryCatch(
    as.character(scale_obj$na.value %||% "grey50"),
    error = function(e) "grey50"
  )

  # For banded (ScaleBinned) colorbars: emit one color per bin so the JS
  # renderer can build a 2-stop-per-bin gradient (D-06).
  if (isTRUE(is_steps) && !is.null(breaks) && length(breaks) >= 2L) {
    midpoints <- (head(breaks, -1L) + tail(breaks, -1L)) / 2
    bin_colors <- tryCatch(
      scale_obj$map(midpoints),
      error = function(e) NULL
    )
  }

  # Orientation per D-10: legend.position drives layout. Vertical default;
  # horizontal when position is "top" or "bottom". Plot-level theme overrides
  # global theme; both fall back to "right" -> vertical.
  pos_raw <- tryCatch(b$plot$theme$legend.position, error = function(e) NULL)
  if (is.null(pos_raw)) {
    pos_raw <- tryCatch(ggplot2::theme_get()$legend.position, error = function(e) NULL)
  }
  if (is.null(pos_raw)) pos_raw <- "right"
  legend_position <- if (is.character(pos_raw)) pos_raw[[1]] else "right"
  orientation <- if (legend_position %in% c("top", "bottom")) "horizontal" else "vertical"
}

guide_spec <- list(
  aesthetic = aes_name,
  aesthetics = list(aes_name),
  type = guide_type,
  title = as.character(title),
  keys = keys_list,
  colors = colors_array,
  is_steps = isTRUE(is_steps),
  is_continuous = isTRUE(is_continuous),
  breaks = breaks,
  labels = labels,
  na.value = na_value,
  domain = domain,
  bin_colors = bin_colors,
  orientation = orientation,
  legend_position = legend_position
)
```

Notes:
- `%||%` is exported from the package (used elsewhere); it's in scope under `pkgload::load_all`.
- For non-color guide types (legend), all the new fields stay `NULL` — JSON serialization drops them, and JS code can use `guide.breaks || []`-style defaults.
- `breaks` may be a function in some scale subclasses; `scale_obj$get_breaks(limits)` always returns a numeric vector for the standard color scales in scope (D-05). If a future scale type breaks this assumption, the tryCatch above keeps the field `NULL` rather than blowing up.
- `bin_colors` only emitted when `is_steps && length(breaks) >= 2`. For non-binned, it stays `NULL`.
- `legend.position` may be a numeric c(x,y) for inside-plot positioning — we treat anything non-character as `"right"` (vertical) for now; numeric positioning is a v1.2 concern.

Run the suite. All RED tests from Task 1 should be GREEN.

Commit:
```
git add R/ir_legends.R
git commit -m "feat(14-05): enrich colorbar IR with breaks/labels/na.value/domain/orientation (Pitfall 4 + D-10)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>R/ir_legends.R colorbar branch carries breaks/labels/na.value/domain/is_continuous/bin_colors/orientation/legend_position; all 5 RED tests now GREEN; phase-13 baseline FAILs unchanged.</done>
</task>

</tasks>

<exit_criteria>
- `grep -cE 'breaks|labels|na\\.value|is_continuous|bin_colors|orientation|legend_position' R/ir_legends.R` ≥ 10 (each field referenced).
- 5 new GREEN test assertions in test-ir-legends.R + test-color-fidelity.R.
- For viridis_c: `length(g$breaks) == length(g$labels)` and `g$na.value == "grey50"`.
- For default theme viridis_c: `g$orientation == "vertical"`.
- For `theme(legend.position="bottom")` viridis_c: `g$orientation == "horizontal"`.
- For scale_color_steps: `g$bin_colors` is non-empty character vector.
- Phase-13 baseline FAILs unchanged.
- Two atomic commits (RED then GREEN).
</exit_criteria>

<threat_model>
No threat surface — package internals only. Pure data enrichment on an internal IR list.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-05-SUMMARY.md` listing the new IR fields and a sample dump of `as_d3_ir(p)$guides[[1]]` for a viridis_c plot under both `theme()` defaults and `theme(legend.position="bottom")`.
</output>
