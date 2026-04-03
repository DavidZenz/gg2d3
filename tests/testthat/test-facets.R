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
  expect_equal(length(ir$facets$strips), 1)
  expect_equal(length(ir$facets$strips[[1]]$labels), 3)
  expect_true(!is.null(ir$facets$spacing))
})

test_that("facet_layout has PANEL, ROW, COL as integers", {
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

  strip_labels <- sapply(ir$facets$strips[[1]]$labels, function(s) s$label)
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
    expect_true(length(panel$x_range) >= 2)
    expect_true(length(panel$y_range) >= 2)
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
  # Labels should be in 2 levels
  expect_equal(length(ir$facets$strips), 2)
  expect_equal(ir$facets$strips[[1]]$variable, "cyl")
  expect_equal(ir$facets$strips[[2]]$variable, "gear")
})

test_that("facet_grid produces correct row/col strips", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(am ~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "grid")
  expect_equal(length(ir$facets$row_strips), 1)
  expect_equal(length(ir$facets$col_strips), 1)
  expect_equal(length(ir$facets$row_strips[[1]]$labels), 2) # am: 0, 1
  expect_equal(length(ir$facets$col_strips[[1]]$labels), 3) # cyl: 4, 6, 8
})

test_that("non-faceted plot backward compatibility", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_smooth(method = "lm")
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "null")
  expect_equal(length(ir$panels), 1)
})

# --- Advanced Facet Tests ---

test_that("nested facet_grid produces multi-level strip metadata", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + 
    geom_point() + 
    facet_grid(am + vs ~ cyl)
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "grid")
  
  # Row strips should have 2 levels (am, vs)
  expect_equal(length(ir$facets$row_strips), 2)
  expect_equal(ir$facets$row_strips[[1]]$level, 1)
  expect_equal(ir$facets$row_strips[[2]]$level, 2)
  
  # Column strips should have 1 level (cyl)
  expect_equal(length(ir$facets$col_strips), 1)
})

test_that("facet theme elements are correctly extracted", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + 
    geom_point() + 
    facet_wrap(~ cyl) +
    theme(strip.text = element_text(angle = 45, hjust = 1))
  ir <- as_d3_ir(p)

  expect_true(!is.null(ir$theme$strip$text))
  expect_equal(ir$theme$strip$text$angle, 45)
  expect_equal(ir$theme$strip$text$hjust, 1)
})
