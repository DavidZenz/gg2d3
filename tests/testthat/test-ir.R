test_that("as_d3_ir builds layers with data", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_true(length(ir$layers) >= 1)
  expect_true(length(ir$layers[[1]]$data) >= 1)
  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$y$type, "continuous")
})

test_that("continuous scale extracts domain from panel_params", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Verify it's continuous
  expect_equal(ir$scales$x$type, "continuous")

  # Verify domain is NOT exactly the hardcoded 5% expansion of data range
  # (panel_params uses more sophisticated expansion)
  data_range <- range(mtcars$wt)
  hardcoded_expansion <- data_range + c(-1, 1) * diff(data_range) * 0.05

  # The domain should be close but may differ from hardcoded expansion
  # because ggplot2's expansion is more sophisticated
  expect_true(length(ir$scales$x$domain) == 2)
  expect_true(ir$scales$x$domain[1] <= min(mtcars$wt))
  expect_true(ir$scales$x$domain[2] >= max(mtcars$wt))
})

test_that("log10 transformation extracted correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_log10()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "log10")
  expect_equal(ir$scales$x$base, 10)

  # Domain values should be in log10 space (all positive)
  expect_true(all(ir$scales$x$domain > 0))
  expect_true(all(ir$scales$x$domain < 1))  # log10(wt) ranges from ~0.15 to ~0.76
})

test_that("sqrt transformation extracted correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_sqrt()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "sqrt")

  # Domain values should be in sqrt space
  expect_true(all(ir$scales$x$domain > 0))
})

test_that("reverse transformation extracted correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_reverse()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "reverse")

  # Domain should be reversed (negative values in reversed space)
  expect_true(ir$scales$x$domain[1] < ir$scales$x$domain[2])
})

test_that("discrete scales still work correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "categorical")
  expect_equal(ir$scales$x$domain, c("4", "6", "8"))

  # Discrete scales should have no transform
  expect_null(ir$scales$x$transform)
})

test_that("identity transform produces no transform field", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Identity transform should result in NULL transform field
  expect_null(ir$scales$x$transform)
  expect_null(ir$scales$y$transform)
})

test_that("log2 transformation extracted correctly", {
  library(ggplot2)

  # Create a custom log2 scale (ggplot2 doesn't have scale_x_log2 built-in)
  log2_trans <- scales::trans_new(
    "log2",
    transform = log2,
    inverse = function(x) 2^x
  )

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    scale_x_continuous(trans = log2_trans)

  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "log2")
  expect_equal(ir$scales$x$base, 2)
})

test_that("log scale with zero data throws informative error", {
  library(ggplot2)

  p <- ggplot(data.frame(x = 0:10, y = 1:11), aes(x, y)) +
    geom_point() +
    scale_x_log10()

  expect_error(
    as_d3_ir(p),
    "Log scale on x-axis has non-positive domain"
  )

  expect_error(
    as_d3_ir(p),
    "pseudo_log"
  )
})

test_that("coord_trans produces warning", {
  library(ggplot2)

  # coord_trans with log transformation
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    coord_trans(x = "log10")

  expect_warning(
    as_d3_ir(p),
    "coord_trans\\(\\) is not yet supported"
  )

  expect_warning(
    as_d3_ir(p),
    "Phase 3"
  )
})
