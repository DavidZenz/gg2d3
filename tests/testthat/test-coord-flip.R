library(ggplot2)

test_that("coord_flip swaps axis labels correctly", {
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    coord_flip()
  ir <- as_d3_ir(p)

  expect_equal(ir$coord$type, "flip")
  expect_true(ir$coord$flip)

  # In ggplot2: x = factor(cyl), y = mpg
  # After coord_flip: x visual axis (bottom) should show y aesthetic (mpg)
  #                  y visual axis (left) should show x aesthetic (cyl)
  expect_equal(ir$axes$x$label, "mpg")
  expect_equal(ir$axes$y$label, "factor(cyl)")
})

test_that("facet_wrap with coord_flip preserves IR structure", {
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    facet_wrap(~ am) +
    coord_flip()
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "wrap")
  expect_true(ir$coord$flip)

  # Check that panel ranges and breaks are preserved/un-swapped correctly in IR
  # so that x always refers to the x-aesthetic (cyl)
  expect_equal(ir$scales$x$type, "categorical")
  expect_equal(ir$scales$y$type, "continuous")

  for (panel in ir$panels) {
    # x_range should be categorical (cyl), y_range should be continuous (mpg)
    expect_equal(length(panel$x_range), 3) # 3 levels of cyl
    expect_equal(length(panel$y_range), 2) # numeric range
  }
})

test_that("facet_grid with coord_flip preserves IR structure", {
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_boxplot() +
    facet_grid(am ~ vs) +
    coord_flip()
  ir <- as_d3_ir(p)

  expect_equal(ir$facets$type, "grid")
  expect_true(ir$coord$flip)

  # 2x2 grid
  expect_equal(length(ir$panels), 4)
  expect_equal(ir$facets$nrow, 2)
  expect_equal(ir$facets$ncol, 2)
})

test_that("is_flip consolidated logic works for various geom detections", {
  # Just ensuring no crashes and consistency
  p <- ggplot(iris, aes(Species, Sepal.Length)) +
    geom_col() +
    coord_flip()
  ir <- as_d3_ir(p)

  expect_true(ir$coord$flip)
  expect_equal(ir$layers[[1]]$geom, "bar") # geom_col uses bar
})
