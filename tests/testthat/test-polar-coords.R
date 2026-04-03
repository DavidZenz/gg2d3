library(ggplot2)

test_that("coord_polar produces correct IR structure", {
  # Pie chart case
  p <- ggplot(mtcars, aes(x = factor(1), fill = factor(cyl))) +
    geom_bar(width = 1) +
    coord_polar(theta = "y")
  ir <- as_d3_ir(p)

  expect_equal(ir$coord$type, "polar")
  expect_equal(ir$coord$theta, "y")
  expect_equal(ir$coord$start, 0)
  expect_equal(ir$coord$direction, 1)
})

test_that("coord_polar with custom parameters is captured", {
  p <- ggplot(mtcars, aes(x = factor(1), fill = factor(cyl))) +
    geom_bar(width = 1) +
    coord_polar(theta = "x", start = pi/2, direction = -1)
  ir <- as_d3_ir(p)

  expect_equal(ir$coord$type, "polar")
  expect_equal(ir$coord$theta, "x")
  expect_equal(ir$coord$start, pi/2)
  expect_equal(ir$coord$direction, -1)
})

test_that("polar IR includes necessary scale metadata", {
  p <- ggplot(mtcars, aes(x = factor(cyl), fill = factor(cyl))) +
    geom_bar() +
    coord_polar()
  ir <- as_d3_ir(p)

  # Check that x and y scales exist
  expect_true(!is.null(ir$scales$x))
  expect_true(!is.null(ir$scales$y))
})
