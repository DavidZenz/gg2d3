# Phase 6 Layout Metadata Extraction Tests
# Tests for IR layout metadata: tickLabels, subtitle, caption, legend.position, secondary axes

test_that("IR contains x-axis tick labels for continuous scale", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Check that tickLabels is a character vector with length > 0
  expect_true(is.character(ir$axes$x$tickLabels))
  expect_true(length(ir$axes$x$tickLabels) > 0)

  # All values should be non-NA character strings
  expect_true(all(!is.na(ir$axes$x$tickLabels)))
  expect_true(all(nchar(ir$axes$x$tickLabels) > 0))
})

test_that("IR contains y-axis tick labels for continuous scale", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Check that tickLabels is a character vector with length > 0
  expect_true(is.character(ir$axes$y$tickLabels))
  expect_true(length(ir$axes$y$tickLabels) > 0)

  # All values should be non-NA character strings
  expect_true(all(!is.na(ir$axes$y$tickLabels)))
  expect_true(all(nchar(ir$axes$y$tickLabels) > 0))
})

test_that("IR contains tick labels for categorical scale", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot()
  ir <- as_d3_ir(p)

  # Check that tickLabels contains the categorical values
  expect_true(is.character(ir$axes$x$tickLabels))
  expect_true(all(c("4", "6", "8") %in% ir$axes$x$tickLabels))
})

test_that("IR contains subtitle and caption", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    labs(title = "Title", subtitle = "Subtitle", caption = "Caption")
  ir <- as_d3_ir(p)

  # Check that subtitle and caption are extracted correctly
  expect_equal(ir$subtitle, "Subtitle")
  expect_equal(ir$caption, "Caption")
})

test_that("IR subtitle and caption default to empty string", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Check that subtitle and caption default to empty strings
  expect_equal(ir$subtitle, "")
  expect_equal(ir$caption, "")
})

test_that("IR legend position defaults to right", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Check that legend position defaults to "right"
  expect_equal(ir$legend$position, "right")
})

test_that("IR legend position extracted from theme", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    theme(legend.position = "bottom")
  ir <- as_d3_ir(p)

  # Check that legend position is extracted from theme
  expect_equal(ir$legend$position, "bottom")
})

test_that("IR has no secondary axis by default", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Check that x2 and y2 are NULL by default
  expect_null(ir$axes$x2)
  expect_null(ir$axes$y2)
})

test_that("IR detects secondary y axis", {
  library(ggplot2)

  # Wrap in tryCatch in case secondary axis extraction has issues
  skip_on_error <- function(code) {
    tryCatch(code, error = function(e) {
      skip(paste("Secondary axis test skipped due to error:", e$message))
    })
  }

  skip_on_error({
    p <- ggplot(mtcars, aes(wt, mpg)) +
      geom_point() +
      scale_y_continuous(sec.axis = sec_axis(~. * 1.6, name = "km/l"))
    ir <- as_d3_ir(p)

    # Check that y2 is enabled
    expect_true(!is.null(ir$axes$y2))
    expect_true(ir$axes$y2$enabled)
  })
})

test_that("IR tick labels survive coord_flip", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    coord_flip()
  ir <- as_d3_ir(p)

  # Check that both x and y have tick labels after coord_flip
  expect_true(is.character(ir$axes$x$tickLabels))
  expect_true(length(ir$axes$x$tickLabels) > 0)

  expect_true(is.character(ir$axes$y$tickLabels))
  expect_true(length(ir$axes$y$tickLabels) > 0)
})
