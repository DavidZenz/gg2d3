skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

# Load package if not already loaded
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

test_that("sf IR data rows include row_id field", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]
  expect_true(length(layer$data) > 0)
  expect_true("row_id" %in% names(layer$data[[1]]),
    info = "First data row must contain row_id")
})

test_that("row_id values are sequential integers from 1 to n", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]
  n <- length(layer$geometries)
  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))
  expect_equal(row_ids, seq_len(n),
    info = "row_id must be sequential integers 1..n")
})

test_that("geometries and data arrays are the same length", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]
  expect_equal(length(layer$geometries), length(layer$data),
    info = "geometries and data must be parallel arrays of equal length")
})

test_that("row_id in data row i equals i (positional correspondence)", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]
  for (i in seq_along(layer$data)) {
    expect_equal(layer$data[[i]]$row_id, i,
      info = paste("data row", i, "row_id must equal", i))
    # Stop early after checking first 5 and last 5 to keep test fast
    if (i == 5) break
  }
  n <- length(layer$data)
  if (n > 5) {
    expect_equal(layer$data[[n]]$row_id, n,
      info = paste("last data row", n, "row_id must equal", n))
  }
})

test_that("non-sf geom layers do NOT contain row_id in their data rows", {
  p <- ggplot2::ggplot(data.frame(x = 1:5, y = 1:5), ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point()
  ir <- as_d3_ir(p)
  layer <- ir$layers[[1]]
  expect_true(length(layer$data) > 0)
  expect_false("row_id" %in% names(layer$data[[1]]),
    info = "Non-sf layers must not have row_id in data rows")
})
