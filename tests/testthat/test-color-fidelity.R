# Phase 14 colour-fidelity snapshot harness.
#
# Wave 0 scaffold — all tests are skip-pending stubs that later plans flip to
# real assertions. The names and groupings mirror VALIDATION.md's per-task
# verification map exactly. Helpers in tests/testthat/helper-color.R are
# auto-sourced by testthat before this file runs.
#
# Requirement IDs:
#   COLOR-01 — per-row hex parity vs ggplot_build (D-03/D-04)
#   COLOR-02 — continuous color renders as colorbar (not discrete fallback)
#
# Each test_that block calls skip("pending plan 14-XX") as the first line so
# the file is harmless until the named plan replaces it. Do NOT add real
# assertions here; that's the downstream plans' job.

# ---------------------------------------------------------------------------
# COLOR-01 — per-row mark hex parity (filled in by plan 14-07 corpus)
# ---------------------------------------------------------------------------

test_that("viridis_c per-row mark hex equals ggplot_build", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:10, y = 1:10, v = seq(1, 100, length.out = 10))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() + scale_color_viridis_c()

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "colorbar")
  expect_gte(length(g$colors), 30L)

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row     = ir_col,
    legend_hex  = unname(ref_legend),
    breaks      = unname(g$breaks),
    labels      = g$labels,
    is_steps    = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("viridis_d per-row mark hex equals ggplot_build (8-hex RGBA)", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:5, y = 1:5, g = factor(letters[1:5]))
  p <- ggplot(df, aes(x, y, colour = g)) + geom_point() + scale_color_viridis_d()

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)
  expect_true(all(grepl("^#[0-9A-Fa-f]{8}$", build_col)))

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "legend")

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_col,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("brewer (discrete fill) per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:9, y = 1:9, g = factor(rep(c("a","b","c"), each = 3)))
  p <- ggplot(df, aes(x, y, fill = g)) + geom_point(shape = 21, size = 4) +
    scale_fill_brewer(palette = "Set1")

  build_fill <- build_fills(p)
  ir_fill    <- ir_layer_fills(p)
  expect_identical(ir_fill, build_fill)

  g <- guide_by_aes(p, "fill")
  expect_false(is.null(g))
  expect_equal(g$type, "legend")

  scale_obj <- scale_by_aes(p, "fill")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_fill,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("distiller per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:10, y = 1:10, v = seq(1, 100, length.out = 10))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() +
    scale_color_distiller(palette = "Spectral")

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "colorbar")
  expect_gte(length(g$colors), 30L)

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_col,
    legend_hex = unname(ref_legend),
    breaks     = unname(g$breaks),
    labels     = g$labels,
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("scale_color_manual (named) per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:9, y = 1:9, g = factor(rep(c("a","b","c"), each = 3)))
  p <- ggplot(df, aes(x, y, colour = g)) + geom_point() +
    scale_color_manual(values = c(a = "#FF0000", b = "#00FF00", c = "#0000FF"))

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "legend")

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_col,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("scale_color_manual (unnamed) per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:9, y = 1:9, g = factor(rep(c("a","b","c"), each = 3)))
  p <- ggplot(df, aes(x, y, colour = g)) + geom_point() +
    scale_color_manual(values = c("#FF0000", "#00FF00", "#0000FF"))

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "legend")

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_col,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("scale_fill_manual per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:9, y = 1:9, g = factor(rep(c("a","b","c"), each = 3)))
  p <- ggplot(df, aes(x, y, fill = g)) + geom_point(shape = 21, size = 4) +
    scale_fill_manual(values = c(a = "#1f77b4", b = "#ff7f0e", c = "#2ca02c"))

  build_fill <- build_fills(p)
  ir_fill    <- ir_layer_fills(p)
  expect_identical(ir_fill, build_fill)

  g <- guide_by_aes(p, "fill")
  expect_false(is.null(g))
  expect_equal(g$type, "legend")

  scale_obj <- scale_by_aes(p, "fill")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_fill,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})

test_that("scale_color_steps per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:10, y = 1:10, v = seq(1, 100, length.out = 10))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() + scale_color_steps()

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "colorbar")
  expect_true(isTRUE(g$is_steps))
  expect_gte(length(g$bin_colors %||% character(0)), 1L)

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row     = ir_col,
    legend_hex  = unname(ref_legend),
    breaks      = unname(g$breaks),
    labels      = g$labels,
    is_steps    = g$is_steps,
    bin_colors  = g$bin_colors
  )
  expect_snapshot_value(snap, style = "json2")
})

# ---------------------------------------------------------------------------
# COLOR-02 — colorbar IR & rendering (plans 14-03..14-06)
# ---------------------------------------------------------------------------

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

test_that("renderColorbar tick logic uses breaks (not first/last keys)", {
  src <- paste(readLines("../../inst/htmlwidgets/modules/legend.js", warn = FALSE), collapse = "\n")
  fn <- regmatches(src, regexpr("function renderColorbar[\\s\\S]*?\\n  \\}\\n", src, perl = TRUE))
  expect_length(fn, 1L)
  # Must consume IR fields rather than reinventing them.
  expect_match(fn, "guide\\.breaks")
  expect_match(fn, "guide\\.labels")
  expect_match(fn, "guide\\.domain")
  expect_match(fn, "guide\\.is_steps|guide\\.bin_colors")
  # The endKeys hardcode must be gone.
  expect_false(grepl("guide\\.keys\\[guide\\.keys\\.length - 1\\]", fn))
})

test_that("renderColorbar branches on guide.orientation for horizontal layout", {
  src <- paste(readLines("../../inst/htmlwidgets/modules/legend.js", warn = FALSE), collapse = "\n")
  fn <- regmatches(src, regexpr("function renderColorbar[\\s\\S]*?\\n  \\}\\n", src, perl = TRUE))
  expect_length(fn, 1L)
  # Must consult guide.orientation.
  expect_match(fn, "guide\\.orientation")
  # Must compare against the literal "horizontal" — no other source of "horizontal" expected in renderColorbar.
  expect_match(fn, "\"horizontal\"")
  # Horizontal gradient must set x2 to "100%" (smooth) — present somewhere in the function.
  expect_match(fn, "x2\"?,?\\s*[\"']100%[\"']")
})

# ---------------------------------------------------------------------------
# Edge cases (plan 14-07 corpus snapshots) — D-11..D-14
# ---------------------------------------------------------------------------

test_that("D-11 NA colour row renders as #7F7F7F (grey50)", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-12 dual color+fill produces 2 guides without merge", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-13 RGBA hex round-trips identically", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-14 manual out-of-range factor maps to na.value", {
  library(ggplot2)
  skip("pending plan 14-07")
})

# ---------------------------------------------------------------------------
# JS regex static check (plan 14-02)
# ---------------------------------------------------------------------------

test_that("isHexColor accepts 4 and 8 digit hex (constants.js regex)", {
  src <- readLines("../../inst/htmlwidgets/modules/constants.js", warn = FALSE)
  joined <- paste(src, collapse = "\n")
  # Find the isHexColor function body.
  # Match through the line-leading closing brace (function body ends with a `}` at line start,
  # not the inner `{3,4}` quantifier braces). Lazy match up to first newline-anchored `}`.
  fn_match <- regmatches(joined, regexpr("function isHexColor[\\s\\S]*?\\n  \\}", joined, perl = TRUE))
  expect_length(fn_match, 1L)
  # Regex must accept 8-digit hex (full RGBA: #RRGGBBAA) and 4-digit (short RGBA: #RGBA).
  expect_match(fn_match, "\\[0-9a-f\\]\\{8\\}|\\[0-9a-f\\]\\{6,8\\}|\\[0-9a-f\\]\\{3,8\\}")
  expect_match(fn_match, "\\[0-9a-f\\]\\{4\\}|\\[0-9a-f\\]\\{3,4\\}|\\[0-9a-f\\]\\{3,8\\}")
})
