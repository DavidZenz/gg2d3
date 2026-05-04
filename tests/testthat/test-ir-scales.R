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

test_that("extract_scales_ir emits a color scale when colour aesthetic is mapped", {
  library(ggplot2)
  # Note: ggplot_build resolves the colour aesthetic to hex strings before
  # extract_scales_ir sees them, so even a numeric source column produces
  # a categorical color scale (preserved v1.0 behaviour — matches the
  # full-pipeline equivalence test below).
  p <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  s <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_true(!is.null(s$color))
  expect_true(s$color$type %in% c("continuous", "categorical"))
  expect_true(length(s$color$domain) >= 1)
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
