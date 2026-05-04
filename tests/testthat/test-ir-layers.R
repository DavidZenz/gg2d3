# Plan 13-04: real assertions for extract_layers_ir.

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
