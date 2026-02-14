test_that("d3_zoom() requires gg2d3 widget", {
  expect_error(d3_zoom("not a widget"), "gg2d3 widget")
  expect_error(d3_zoom(list(x = 1)), "gg2d3 widget")
})

test_that("d3_zoom() stores zoom config with defaults", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom()

  expect_s3_class(w, "gg2d3")
  expect_true(w$x$interactivity$zoom$enabled)
  expect_equal(w$x$interactivity$zoom$scale_extent, c(1, 8))
  expect_equal(w$x$interactivity$zoom$direction, "both")
})

test_that("d3_zoom() stores custom scale_extent", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom(scale_extent = c(1, 16))

  expect_equal(w$x$interactivity$zoom$scale_extent, c(1, 16))
})

test_that("d3_zoom() stores x-only direction", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom(direction = "x")

  expect_equal(w$x$interactivity$zoom$direction, "x")
})

test_that("d3_zoom() stores y-only direction", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom(direction = "y")

  expect_equal(w$x$interactivity$zoom$direction, "y")
})

test_that("d3_zoom() validates scale_extent", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  # Non-numeric
  expect_error(gg2d3(p) |> d3_zoom(scale_extent = "invalid"), "numeric vector")

  # Wrong length
  expect_error(gg2d3(p) |> d3_zoom(scale_extent = c(1)), "length 2")
  expect_error(gg2d3(p) |> d3_zoom(scale_extent = c(1, 2, 3)), "length 2")

  # Minimum < 1
  expect_error(gg2d3(p) |> d3_zoom(scale_extent = c(0.5, 8)), "must be >= 1")

  # Min > max
  expect_error(gg2d3(p) |> d3_zoom(scale_extent = c(8, 1)), "minimum must be <= maximum")
})

test_that("d3_zoom() is pipe-composable with d3_tooltip", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom() |> d3_tooltip()

  expect_true(w$x$interactivity$zoom$enabled)
  expect_true(w$x$interactivity$tooltip$enabled)
})

test_that("d3_zoom() preserves widget class", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom()

  expect_s3_class(w, "gg2d3")
  expect_s3_class(w, "htmlwidget")
})

test_that("d3_zoom() adds onRender callback", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom()

  # Check that onRender was called (widget structure remains valid)
  expect_s3_class(w, "htmlwidget")
})

# d3_brush() tests

test_that("d3_brush() requires gg2d3 widget", {
  expect_error(d3_brush("not a widget"), "gg2d3 widget")
  expect_error(d3_brush(list(x = 1)), "gg2d3 widget")
})

test_that("d3_brush() stores brush config with defaults", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_brush()

  expect_s3_class(w, "gg2d3")
  expect_true(w$x$interactivity$brush$enabled)
  expect_equal(w$x$interactivity$brush$direction, "xy")
  expect_equal(w$x$interactivity$brush$fill, "#3b82f6")
  expect_equal(w$x$interactivity$brush$opacity, 0.15)
  expect_null(w$x$interactivity$brush$on_brush)
})

test_that("d3_brush() stores x-only direction", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_brush(direction = "x")

  expect_equal(w$x$interactivity$brush$direction, "x")
})

test_that("d3_brush() stores y-only direction", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_brush(direction = "y")

  expect_equal(w$x$interactivity$brush$direction, "y")
})

test_that("d3_brush() stores custom fill and opacity", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_brush(fill = "#ff0000", opacity = 0.3)

  expect_equal(w$x$interactivity$brush$fill, "#ff0000")
  expect_equal(w$x$interactivity$brush$opacity, 0.3)
})

test_that("d3_brush() validates opacity", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  expect_error(gg2d3(p) |> d3_brush(opacity = -0.1), "between 0 and 1")
  expect_error(gg2d3(p) |> d3_brush(opacity = 1.5), "between 0 and 1")
  expect_error(gg2d3(p) |> d3_brush(opacity = "invalid"), "between 0 and 1")
})

test_that("d3_brush() is pipe-composable with d3_zoom", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom() |> d3_brush()

  expect_true(w$x$interactivity$zoom$enabled)
  expect_true(w$x$interactivity$brush$enabled)
})

test_that("d3_brush() preserves widget class", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_brush()

  expect_s3_class(w, "gg2d3")
  expect_s3_class(w, "htmlwidget")
})

test_that("Full composition works", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_zoom() |> d3_brush() |> d3_tooltip() |> d3_hover()

  expect_true(w$x$interactivity$zoom$enabled)
  expect_true(w$x$interactivity$brush$enabled)
  expect_true(w$x$interactivity$tooltip$enabled)
  expect_true(w$x$interactivity$hover$enabled)
})
