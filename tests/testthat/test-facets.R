# Phase 8 Facet IR Extraction Tests
# Tests for facet_wrap structure in IR: panels array, layout, strips, theme elements

test_that("facet_wrap produces correct IR structure", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "wrap")
  expect_true(ir$facets$nrow >= 1)
  expect_true(ir$facets$ncol >= 1)
  expect_equal(length(ir$facets$layout), 3)  # 3 levels of cyl
  expect_equal(length(ir$facets$strips), 3)
  expect_true(!is.null(ir$facets$spacing))
})

test_that("facet layout has PANEL, ROW, COL as integers", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl, nrow = 2)
  ir <- as_d3_ir(p)

  for (entry in ir$facets$layout) {
    expect_true(is.integer(entry$PANEL))
    expect_true(is.integer(entry$ROW))
    expect_true(is.integer(entry$COL))
  }
  # With nrow=2, 3 panels: should be 2 rows, 2 cols
  expect_equal(ir$facets$nrow, 2L)
  expect_equal(ir$facets$ncol, 2L)
})

test_that("strip labels contain facet variable values", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  strip_labels <- vapply(ir$facets$strips, function(s) s$label, character(1))
  # cyl has values 4, 6, 8
  expect_true("4" %in% strip_labels)
  expect_true("6" %in% strip_labels)
  expect_true("8" %in% strip_labels)
})

test_that("panels array has per-panel scale metadata", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(length(ir$panels), 3)
  for (panel in ir$panels) {
    expect_true(is.integer(panel$PANEL))
    expect_equal(length(panel$x_range), 2)
    expect_equal(length(panel$y_range), 2)
    expect_true(length(panel$x_breaks) > 0)
    expect_true(length(panel$y_breaks) > 0)
  }

  # Fixed scales: all panels should have same ranges
  expect_equal(ir$panels[[1]]$x_range, ir$panels[[2]]$x_range)
  expect_equal(ir$panels[[1]]$y_range, ir$panels[[2]]$y_range)
})

test_that("layer data has PANEL as integer", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  panels_in_data <- vapply(ir$layers[[1]]$data, function(d) d$PANEL, integer(1))
  expect_true(all(panels_in_data %in% 1:3))
  expect_true(is.integer(panels_in_data))
})

test_that("non-faceted plot has null facet type", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "null")
  expect_equal(length(ir$panels), 1)
  expect_equal(ir$panels[[1]]$PANEL, 1L)
})

test_that("multi-variable facet_wrap works", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl + gear)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "wrap")
  expect_true(length(ir$facets$vars) == 2)
  # Labels should contain both variable values
  for (strip in ir$facets$strips) {
    expect_true(grepl(",", strip$label))  # multi-var labels have comma
  }
})

test_that("strip theme elements are in IR", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  # Strip theme structure should exist
  expect_true(!is.null(ir$theme$strip))
  expect_true("text" %in% names(ir$theme$strip))
  expect_true("background" %in% names(ir$theme$strip))
})

test_that("facet_wrap works with bar geom", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(factor(gear))) + geom_bar() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "wrap")
  expect_equal(length(ir$panels), 3)
  # Each panel should have data
  panel_counts <- table(vapply(ir$layers[[1]]$data, function(d) d$PANEL, integer(1)))
  expect_true(all(panel_counts > 0))
})

test_that("validate_ir catches malformed facet structure", {
  ir <- list(
    scales = list(x = list(type = "continuous", domain = c(0, 1)),
                  y = list(type = "continuous", domain = c(0, 1))),
    layers = list(),
    facets = list()  # missing type
  )
  expect_error(validate_ir(ir), "type")
})

test_that("facet vars extracted correctly", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$vars, "cyl")
})

test_that("facet spacing extracted from theme", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    facet_wrap(~ cyl) +
    theme(panel.spacing = unit(10, "pt"))
  ir <- as_d3_ir(p)

  # panel.spacing should be converted to pixels
  expect_true(is.numeric(ir$facets$spacing))
  expect_true(ir$facets$spacing > 0)
})

test_that("facet layout includes SCALE_X and SCALE_Y", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)

  for (entry in ir$facets$layout) {
    expect_true(is.integer(entry$SCALE_X))
    expect_true(is.integer(entry$SCALE_Y))
  }
})

test_that("non-faceted plot backward compatibility", {
  library(ggplot2)
  # Ensure non-faceted plots still work as before Phase 8
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_smooth(method = "lm")
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "null")
  expect_equal(length(ir$panels), 1)
  expect_true(length(ir$layers) == 2)  # point + smooth
})
