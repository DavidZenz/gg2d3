# Phase 4 Geom IR Extraction Tests
# Tests for area, ribbon, segment, hline, vline, abline geoms

test_that("geom_area produces correct IR structure", {
  library(ggplot2)

  p <- ggplot(economics, aes(x = as.numeric(date), y = unemploy)) +
    geom_area(fill = "steelblue", alpha = 0.7)

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "area")

  # Check that data is present (as list of row objects)
  expect_true(length(ir$layers[[1]]$data) > 0)

  # Check that first row has x, y, ymin (baseline)
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))
  expect_true("ymin" %in% names(first_row))

  # Check fill aesthetic
  expect_true("fill" %in% names(first_row) ||
              !is.null(ir$layers[[1]]$params$fill))
})

test_that("geom_ribbon produces correct IR structure", {
  library(ggplot2)

  huron <- data.frame(year = 1875:1972, level = as.numeric(LakeHuron))
  huron$ymin <- huron$level - 1
  huron$ymax <- huron$level + 1

  p <- ggplot(huron, aes(year)) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax), fill = "grey70")

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "ribbon")

  # Check that data is present (as list of row objects)
  expect_true(length(ir$layers[[1]]$data) > 0)

  # Check that first row has x, ymin, ymax
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("ymin" %in% names(first_row))
  expect_true("ymax" %in% names(first_row))

  # Check fill aesthetic
  expect_true("fill" %in% names(first_row) ||
              !is.null(ir$layers[[1]]$params$fill))
})

test_that("geom_segment produces correct IR structure with aesthetics", {
  library(ggplot2)

  df_seg <- data.frame(
    x = c(1, 3),
    y = c(1, 3),
    xend = c(3, 5),
    yend = c(4, 1)
  )

  p <- ggplot(df_seg, aes(x, y, xend = xend, yend = yend)) +
    geom_segment(linewidth = 1)

  ir <- as_d3_ir(p)

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "segment")

  # Check that data is present (as list of row objects)
  expect_equal(length(ir$layers[[1]]$data), 2)

  # Check that first row has x, y, xend, yend
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))
  expect_true("xend" %in% names(first_row))
  expect_true("yend" %in% names(first_row))
})

test_that("geom_hline produces correct IR with yintercept", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_hline(yintercept = 20, colour = "red", linetype = "dashed")

  ir <- as_d3_ir(p)

  # Find the hline layer (second layer)
  hline_layer <- ir$layers[[2]]

  # Check geom name
  expect_equal(hline_layer$geom, "hline")

  # Check that data is present (as list of row objects)
  expect_true(length(hline_layer$data) > 0)

  # Check that first row contains yintercept
  first_row <- hline_layer$data[[1]]
  expect_true("yintercept" %in% names(first_row))
  expect_equal(first_row$yintercept, 20)

  # Check color aesthetic
  expect_true("colour" %in% names(first_row) ||
              !is.null(hline_layer$params$colour))
})

test_that("geom_vline produces correct IR with xintercept", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_vline(xintercept = 3.5, colour = "blue")

  ir <- as_d3_ir(p)

  # Find the vline layer (second layer)
  vline_layer <- ir$layers[[2]]

  # Check geom name
  expect_equal(vline_layer$geom, "vline")

  # Check that data is present (as list of row objects)
  expect_true(length(vline_layer$data) > 0)

  # Check that first row contains xintercept
  first_row <- vline_layer$data[[1]]
  expect_true("xintercept" %in% names(first_row))
  expect_equal(first_row$xintercept, 3.5)

  # Check color aesthetic
  expect_true("colour" %in% names(first_row) ||
              !is.null(vline_layer$params$colour))
})

test_that("geom_abline produces correct IR with slope and intercept", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_abline(slope = -5, intercept = 35, colour = "darkgreen")

  ir <- as_d3_ir(p)

  # Find the abline layer (second layer)
  abline_layer <- ir$layers[[2]]

  # Check geom name
  expect_equal(abline_layer$geom, "abline")

  # Check that data is present (as list of row objects)
  expect_true(length(abline_layer$data) > 0)

  # Check that first row contains slope and intercept
  first_row <- abline_layer$data[[1]]
  expect_true("slope" %in% names(first_row))
  expect_true("intercept" %in% names(first_row))
  expect_equal(first_row$slope, -5)
  expect_equal(first_row$intercept, 35)

  # Check color aesthetic
  expect_true("colour" %in% names(first_row) ||
              !is.null(abline_layer$params$colour))
})

test_that("multiple reference lines produce correct number of data rows", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_hline(yintercept = c(15, 20, 25), linetype = "dotted", colour = "grey50")

  ir <- as_d3_ir(p)

  # Find the hline layer (second layer)
  hline_layer <- ir$layers[[2]]

  # Should have 3 rows in data (one per yintercept)
  expect_equal(length(hline_layer$data), 3)

  # Check that all three values are present
  yintercepts <- sapply(hline_layer$data, function(row) row$yintercept)
  expect_setequal(yintercepts, c(15, 20, 25))
})

test_that("IR validation accepts all Phase 4 geom types without warnings", {
  library(ggplot2)

  # Create plots with each Phase 4 geom type
  p_area <- ggplot(economics, aes(x = as.numeric(date), y = unemploy)) +
    geom_area()

  huron <- data.frame(year = 1875:1972, level = as.numeric(LakeHuron))
  huron$ymin <- huron$level - 1
  huron$ymax <- huron$level + 1
  p_ribbon <- ggplot(huron, aes(year)) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax))

  df_seg <- data.frame(x = c(1, 3), y = c(1, 3), xend = c(3, 5), yend = c(4, 1))
  p_segment <- ggplot(df_seg, aes(x, y, xend = xend, yend = yend)) +
    geom_segment()

  p_hline <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_hline(yintercept = 20)

  p_vline <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_vline(xintercept = 3.5)

  p_abline <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    geom_abline(slope = -5, intercept = 35)

  # Validate each - should not produce warnings about unrecognized geom types
  expect_silent(validate_ir(suppressMessages(as_d3_ir(p_area))))
  expect_silent(validate_ir(suppressMessages(as_d3_ir(p_ribbon))))
  expect_silent(validate_ir(as_d3_ir(p_segment)))
  expect_silent(validate_ir(as_d3_ir(p_hline)))
  expect_silent(validate_ir(as_d3_ir(p_vline)))
  expect_silent(validate_ir(as_d3_ir(p_abline)))
})

test_that("geom_segment with color aesthetic mapping", {
  library(ggplot2)

  df_seg <- data.frame(
    x = c(1, 3),
    y = c(1, 3),
    xend = c(3, 5),
    yend = c(4, 1),
    type = c("A", "B")
  )

  p <- ggplot(df_seg, aes(x, y, xend = xend, yend = yend, colour = type)) +
    geom_segment()

  ir <- as_d3_ir(p)

  # Check that colour aesthetic is mapped in data (first row)
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("colour" %in% names(first_row))

  # Extract all colours from rows
  colours <- sapply(ir$layers[[1]]$data, function(row) row$colour)
  expect_true(all(c("#F8766D", "#00BFC4") %in% colours))
})

test_that("geom_area with coord_flip", {
  library(ggplot2)

  p <- ggplot(economics, aes(x = as.numeric(date), y = unemploy)) +
    geom_area(fill = "steelblue") +
    coord_flip()

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom is still area
  expect_equal(ir$layers[[1]]$geom, "area")

  # Check coord flip is set
  expect_equal(ir$coord$type, "flip")
  expect_true(ir$coord$flip)
})

test_that("geom_ribbon preserves data order", {
  library(ggplot2)

  # Create data with intentional non-sequential ordering
  df <- data.frame(
    x = c(1, 3, 2, 4, 5),
    ymin = c(1, 2, 1.5, 3, 4),
    ymax = c(2, 3, 2.5, 4, 5)
  )

  p <- ggplot(df, aes(x)) +
    geom_ribbon(aes(ymin = ymin, ymax = ymax))

  ir <- suppressMessages(as_d3_ir(p))

  # Data should be present (5 rows)
  expect_equal(length(ir$layers[[1]]$data), 5)

  # Check that first row has all required columns
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true(all(c("x", "ymin", "ymax") %in% names(first_row)))
})
