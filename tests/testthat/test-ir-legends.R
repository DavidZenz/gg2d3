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
  titles <- vapply(L$guides, function(g) g$title, character(1))
  expect_true("factor(cyl)" %in% titles)
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
  expect_equal(length(L$guides), 0L)
})

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
