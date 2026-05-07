# Real assertions for R/ir_scales.R (Phase 13 Plan 03 — REFACTOR-01).
# Replaces the Wave 0 stub: now exercises extract_scales_ir directly,
# plus a full-pipeline equivalence check against as_d3_ir().

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
  expect_true(all(c("4", "6", "8") %in% as.character(s$x$domain)))
})

test_that("ir$scales$color is no longer emitted (Pitfall 3 dead-code removed)", {
  library(ggplot2)
  p_cont <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point()
  p_disc <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  expect_null(as_d3_ir(p_cont)$scales$color)
  expect_null(as_d3_ir(p_disc)$scales$color)

  b <- ggplot_build(p_cont)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_null(s$color)
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
  # Modern Dates are >> 1e12 ms (1970 epoch milliseconds for 2026 ~= 1.77e12)
  expect_true(s$x$domain[1] > 1e12)
})
