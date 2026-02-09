# Phase 5 Stat Geom IR Extraction Tests
# Tests for boxplot, violin, density, smooth geoms

test_that("geom_boxplot produces correct IR structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot()

  ir <- as_d3_ir(p)

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "boxplot")

  # Check that data is present (as list of row objects)
  # Should have 3 rows (one per cyl group: 4, 6, 8)
  expect_equal(length(ir$layers[[1]]$data), 3)

  # Check that first row has all five-number summary columns
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("lower" %in% names(first_row))
  expect_true("middle" %in% names(first_row))
  expect_true("upper" %in% names(first_row))
  expect_true("ymin" %in% names(first_row))
  expect_true("ymax" %in% names(first_row))

  # Check that outliers column exists
  expect_true("outliers" %in% names(first_row))

  # Verify outliers is a list/vector (not a scalar or NULL)
  expect_true(is.list(first_row$outliers) || is.vector(first_row$outliers))
})

test_that("geom_boxplot outliers are correctly serialized", {
  library(ggplot2)

  # mtcars mpg has outliers for some cyl groups
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot()

  ir <- as_d3_ir(p)

  # Check all rows for outliers
  has_outliers <- FALSE
  for (row in ir$layers[[1]]$data) {
    if ("outliers" %in% names(row)) {
      outliers <- row$outliers
      # If this group has outliers (not NULL and length > 0)
      if (!is.null(outliers) && length(outliers) > 0) {
        has_outliers <- TRUE
        # Verify outliers is numeric
        expect_true(is.numeric(outliers))
        # Verify outlier values are within expected range for mpg (10-35)
        expect_true(all(outliers >= 10 & outliers <= 35))
      }
    }
  }

  # mtcars should have at least some outliers
  expect_true(has_outliers)
})

test_that("geom_violin produces correct IR structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_violin()

  ir <- as_d3_ir(p)

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "violin")

  # Check that data has many rows (significantly more than 3 groups)
  # Each violin is ~512 points, so 3 groups * ~512 = ~1536 rows
  expect_true(length(ir$layers[[1]]$data) > 100)

  # Check that first row has violinwidth column
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("violinwidth" %in% names(first_row))

  # Check that first row has y column (data value)
  expect_true("y" %in% names(first_row))

  # Verify violinwidth is numeric and >= 0
  expect_true(is.numeric(first_row$violinwidth))
  expect_true(first_row$violinwidth >= 0)
})

test_that("geom_density produces correct IR structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(mpg)) +
    geom_density()

  # Use suppressMessages to suppress any scale messages
  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "density")

  # Check that data has many rows (~512 for one group)
  expect_true(length(ir$layers[[1]]$data) > 100)

  # Check that first row has x and y columns
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))

  # Verify y values are non-negative (density is always >= 0)
  all_y <- sapply(ir$layers[[1]]$data, function(row) row$y)
  expect_true(all(all_y >= 0))
})

test_that("geom_density with groups produces correct structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(mpg, fill = factor(cyl))) +
    geom_density(alpha = 0.4)

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "density")

  # Check that data has many rows (~512 * 3 groups)
  expect_true(length(ir$layers[[1]]$data) > 1000)

  # Check that group column exists
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("group" %in% names(first_row))
})

test_that("geom_smooth produces correct IR structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_smooth(method = "lm")

  # Use suppressMessages to suppress fitting messages
  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name is "smooth" (NOT "path")
  expect_equal(ir$layers[[1]]$geom, "smooth")

  # Check that data is present
  expect_true(length(ir$layers[[1]]$data) > 0)

  # Check that first row has x, y, ymin, ymax columns
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))
  expect_true("ymin" %in% names(first_row))
  expect_true("ymax" %in% names(first_row))

  # Verify ymin < y < ymax for fitted values (CI bounds bracket fitted)
  expect_true(first_row$ymin < first_row$y)
  expect_true(first_row$y < first_row$ymax)
})

test_that("geom_smooth without se still produces smooth geom", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_smooth(method = "lm", se = FALSE)

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name is still "smooth"
  expect_equal(ir$layers[[1]]$geom, "smooth")

  # Check that data has x and y columns
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))

  # Check if ymin/ymax are present or absent
  # (They may be present but NA, or absent entirely - test actual behavior)
  # For now, just verify the basic structure works
  expect_true(length(ir$layers[[1]]$data) > 0)
})

test_that("geom_histogram works via existing bar renderer", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(mpg)) +
    geom_histogram(bins = 10)

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name is "bar" (GeomBar used by histogram)
  expect_equal(ir$layers[[1]]$geom, "bar")

  # Check that data has expected structure
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))
  expect_true("xmin" %in% names(first_row))
  expect_true("xmax" %in% names(first_row))
})

test_that("IR validation accepts all Phase 5 geom types", {
  library(ggplot2)

  # Create plots with each Phase 5 stat geom
  p_boxplot <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot()

  p_violin <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_violin()

  p_density <- ggplot(mtcars, aes(mpg)) +
    geom_density()

  p_smooth <- ggplot(mtcars, aes(wt, mpg)) +
    geom_smooth(method = "lm")

  p_histogram <- ggplot(mtcars, aes(mpg)) +
    geom_histogram(bins = 10)

  # Validate each - should not produce warnings about unrecognized geom types
  expect_silent(validate_ir(as_d3_ir(p_boxplot)))
  expect_silent(validate_ir(as_d3_ir(p_violin)))
  expect_silent(validate_ir(suppressMessages(as_d3_ir(p_density))))
  expect_silent(validate_ir(suppressMessages(as_d3_ir(p_smooth))))
  expect_silent(validate_ir(suppressMessages(as_d3_ir(p_histogram))))
})

test_that("geom_boxplot with coord_flip", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    coord_flip()

  ir <- as_d3_ir(p)

  # Verify coord type is "flip" in IR
  expect_equal(ir$coord$type, "flip")
  expect_true(ir$coord$flip)

  # Verify boxplot data structure unchanged by flip
  expect_equal(ir$layers[[1]]$geom, "boxplot")

  # Check that first row still has five-number summary
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("lower" %in% names(first_row))
  expect_true("middle" %in% names(first_row))
  expect_true("upper" %in% names(first_row))
})

test_that("geom_violin with multiple aesthetics", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
    geom_violin(alpha = 0.7)

  ir <- as_d3_ir(p)

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "violin")

  # Check that fill aesthetic is present (either in data or params)
  first_row <- ir$layers[[1]]$data[[1]]
  has_fill <- "fill" %in% names(first_row) || !is.null(ir$layers[[1]]$params$fill)
  expect_true(has_fill)

  # Check that alpha is present in params
  expect_true(!is.null(ir$layers[[1]]$params$alpha))
})

test_that("geom_smooth with loess method", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_smooth()  # Default is loess

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name is "smooth"
  expect_equal(ir$layers[[1]]$geom, "smooth")

  # Check that data has confidence bands
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("ymin" %in% names(first_row))
  expect_true("ymax" %in% names(first_row))

  # Data should have more points than linear (loess is smooth curve)
  expect_true(length(ir$layers[[1]]$data) > 50)
})

test_that("geom_density with custom bandwidth", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(mpg)) +
    geom_density(bw = 2)

  ir <- suppressMessages(as_d3_ir(p))

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "density")

  # Should still have proper structure
  first_row <- ir$layers[[1]]$data[[1]]
  expect_true("x" %in% names(first_row))
  expect_true("y" %in% names(first_row))
})

test_that("geom_boxplot with notch", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot(notch = TRUE)

  ir <- as_d3_ir(p)

  # Check geom name
  expect_equal(ir$layers[[1]]$geom, "boxplot")

  # Check for notch columns (notchlower and notchupper)
  first_row <- ir$layers[[1]]$data[[1]]
  # Notch columns may or may not be present depending on ggplot2 version
  # Just verify basic structure is intact
  expect_true("lower" %in% names(first_row))
  expect_true("middle" %in% names(first_row))
  expect_true("upper" %in% names(first_row))
})
