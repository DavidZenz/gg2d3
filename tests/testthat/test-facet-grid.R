test_that("facet_grid produces correct IR structure", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "grid")
  expect_equal(ir$facets$rows, "cyl")
  expect_equal(ir$facets$cols, "am")
  expect_equal(ir$facets$nrow, 3L)
  expect_equal(ir$facets$ncol, 2L)
  expect_equal(ir$facets$scales, "fixed")
  expect_equal(length(ir$facets$layout), 6)  # 3 rows x 2 cols
  expect_equal(length(ir$panels), 6)
})

test_that("facet_grid row_strips and col_strips are correct", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir <- as_d3_ir(p)
  expect_equal(length(ir$facets$row_strips), 3)  # 3 cyl values
  expect_equal(length(ir$facets$col_strips), 2)  # 2 am values
  # Check ROW/COL indices
  row_indices <- sapply(ir$facets$row_strips, function(s) s$ROW)
  col_indices <- sapply(ir$facets$col_strips, function(s) s$COL)
  expect_equal(sort(row_indices), 1:3)
  expect_equal(sort(col_indices), 1:2)
})

test_that("facet_grid layout includes SCALE_X and SCALE_Y", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir <- as_d3_ir(p)
  layout <- ir$facets$layout
  for (entry in layout) {
    expect_true("SCALE_X" %in% names(entry))
    expect_true("SCALE_Y" %in% names(entry))
    expect_true(is.integer(entry$SCALE_X))
    expect_true(is.integer(entry$SCALE_Y))
  }
})

test_that("facet_grid detects free scale modes correctly", {
  library(ggplot2)
  p_free <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am, scales = "free")
  ir_free <- as_d3_ir(p_free)
  expect_equal(ir_free$facets$scales, "free")

  p_fx <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am, scales = "free_x")
  ir_fx <- as_d3_ir(p_fx)
  expect_equal(ir_fx$facets$scales, "free_x")

  p_fy <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am, scales = "free_y")
  ir_fy <- as_d3_ir(p_fy)
  expect_equal(ir_fy$facets$scales, "free_y")

  p_fixed <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir_fixed <- as_d3_ir(p_fixed)
  expect_equal(ir_fixed$facets$scales, "fixed")
})

test_that("free scales produce per-panel specific ranges", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am, scales = "free")
  ir <- as_d3_ir(p)
  # With free scales, at least some panels should have different ranges
  x_ranges <- lapply(ir$panels, function(pan) pan$x_range)
  y_ranges <- lapply(ir$panels, function(pan) pan$y_range)
  # Not all x_ranges should be identical
  expect_false(all(sapply(x_ranges, function(r) identical(r, x_ranges[[1]]))))
})

test_that("multi-variable facet_grid produces correct strips", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am + vs)
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "grid")
  expect_equal(length(ir$facets$cols), 2)  # am and vs
  expect_equal(length(ir$facets$rows), 1)  # cyl only
  # Column strips should have concatenated labels
  col_labels <- sapply(ir$facets$col_strips, function(s) s$label)
  expect_true(all(grepl(",", col_labels)))  # Labels contain comma separator
})

test_that("facet_grid handles missing combinations", {
  library(ggplot2)
  # Create dataset with missing combination
  df <- data.frame(
    x = c(1, 2, 3, 4),
    y = c(1, 2, 3, 4),
    row_var = c("A", "A", "B", "B"),
    col_var = c("X", "Y", "X", "X")  # B,Y combination is missing
  )
  p <- ggplot(df, aes(x, y)) + geom_point() + facet_grid(row_var ~ col_var)
  ir <- as_d3_ir(p)
  # Should still have 4 panels (2x2 grid)
  expect_equal(length(ir$panels), 4)
  expect_equal(ir$facets$nrow, 2L)
  expect_equal(ir$facets$ncol, 2L)
})

test_that("facet_wrap IR unchanged by Phase 9", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "wrap")
  expect_true(!is.null(ir$facets$strips))
  expect_true(is.null(ir$facets$row_strips))
  expect_true(is.null(ir$facets$col_strips))
})

test_that("non-faceted IR unchanged by Phase 9", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "null")
  expect_equal(length(ir$panels), 1)
})

test_that("facet_grid layer data has integer PANEL", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir <- as_d3_ir(p)
  panels <- unique(sapply(ir$layers[[1]]$data, function(d) d$PANEL))
  expect_true(all(is.integer(panels) | is.numeric(panels)))
})

test_that("facet_grid panels have breaks", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
  ir <- as_d3_ir(p)
  for (panel in ir$panels) {
    expect_true(length(panel$x_breaks) > 0)
    expect_true(length(panel$y_breaks) > 0)
  }
})
