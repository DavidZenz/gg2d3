test_that("d3_tooltip() returns valid widget", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip()

  expect_s3_class(w, "gg2d3")
  expect_true(w$x$interactivity$tooltip$enabled)
})

test_that("d3_tooltip() with fields parameter", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip(fields = c("x", "y"))

  expect_equal(w$x$interactivity$tooltip$fields, c("x", "y"))
})

test_that("d3_tooltip() with formatter parameter", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  formatter_code <- "return field + ': ' + value.toFixed(1)"
  w <- gg2d3(p) |> d3_tooltip(formatter = formatter_code)

  expect_equal(w$x$interactivity$tooltip$formatter, formatter_code)
})

test_that("d3_tooltip() rejects non-widget input", {
  expect_error(d3_tooltip("not a widget"), "gg2d3 widget")
  expect_error(d3_tooltip(list(x = 1)), "gg2d3 widget")
})

test_that("d3_hover() returns valid widget", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_hover()

  expect_s3_class(w, "gg2d3")
  expect_true(w$x$interactivity$hover$enabled)
  expect_equal(w$x$interactivity$hover$opacity, 0.7)
})

test_that("d3_hover() with custom params", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_hover(opacity = 0.3, stroke = "red", stroke_width = 2)

  expect_equal(w$x$interactivity$hover$opacity, 0.3)
  expect_equal(w$x$interactivity$hover$stroke, "red")
  expect_equal(w$x$interactivity$hover$stroke_width, 2)
})

test_that("d3_hover() rejects non-widget input", {
  expect_error(d3_hover(42), "gg2d3 widget")
})

test_that("pipe chaining works (tooltip + hover)", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip() |> d3_hover()

  expect_true(w$x$interactivity$tooltip$enabled)
  expect_true(w$x$interactivity$hover$enabled)
})

test_that("static rendering unaffected (backward compat)", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p)

  expect_null(w$x$interactivity)
  expect_s3_class(w, "gg2d3")
})

test_that("d3_tooltip() defaults: fields NULL, formatter NULL", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip()

  expect_null(w$x$interactivity$tooltip$fields)
  expect_null(w$x$interactivity$tooltip$formatter)
})

test_that("d3_hover() validates opacity range", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  expect_error(gg2d3(p) |> d3_hover(opacity = -0.1), "between 0 and 1")
  expect_error(gg2d3(p) |> d3_hover(opacity = 1.5), "between 0 and 1")
  expect_error(gg2d3(p) |> d3_hover(opacity = "invalid"), "between 0 and 1")
})

test_that("d3_tooltip() interactivity structure initializes correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip()

  # Check structure
  expect_type(w$x$interactivity, "list")
  expect_type(w$x$interactivity$tooltip, "list")
  expect_true("enabled" %in% names(w$x$interactivity$tooltip))
  expect_true("fields" %in% names(w$x$interactivity$tooltip))
  expect_true("formatter" %in% names(w$x$interactivity$tooltip))
})

test_that("d3_hover() interactivity structure initializes correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_hover()

  # Check structure
  expect_type(w$x$interactivity, "list")
  expect_type(w$x$interactivity$hover, "list")
  expect_true("enabled" %in% names(w$x$interactivity$hover))
  expect_true("opacity" %in% names(w$x$interactivity$hover))
  expect_true("stroke" %in% names(w$x$interactivity$hover))
  expect_true("stroke_width" %in% names(w$x$interactivity$hover))
})

test_that("chaining preserves independent configurations", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |>
    d3_tooltip(fields = c("x", "y")) |>
    d3_hover(opacity = 0.5, stroke = "blue")

  # Both configs should exist independently
  expect_equal(w$x$interactivity$tooltip$fields, c("x", "y"))
  expect_equal(w$x$interactivity$hover$opacity, 0.5)
  expect_equal(w$x$interactivity$hover$stroke, "blue")
})

test_that("d3_hover() default stroke is NULL", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p) |> d3_hover()

  expect_null(w$x$interactivity$hover$stroke)
  expect_null(w$x$interactivity$hover$stroke_width)
})
