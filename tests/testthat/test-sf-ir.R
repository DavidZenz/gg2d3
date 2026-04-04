skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

test_that("basic sf IR generation succeeds without error", {
  expect_no_error({
    ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  })
})

test_that("sf layer geom is 'sf'", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_equal(ir$layers[[1]]$geom, "sf")
})

test_that("sf coord type is 'sf'", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_equal(ir$coord$type, "sf")
})

test_that("sf layer has geometries field", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_false(is.null(ir$layers[[1]]$geometries))
})

test_that("geometries is character vector of length 100", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_length(ir$layers[[1]]$geometries, 100)
  expect_type(ir$layers[[1]]$geometries, "character")
})

test_that("each GeoJSON string is valid geometry JSON", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  first_geom <- ir$layers[[1]]$geometries[[1]]
  expect_true(
    startsWith(first_geom, '{"type":"Multi') ||
    startsWith(first_geom, '{"type":"Poly') ||
    startsWith(first_geom, "{\"type\":\"Multi") ||
    startsWith(first_geom, "{\"type\":\"Poly")
  )
})

test_that("geom_type field is MULTIPOLYGON for NC data", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_equal(ir$layers[[1]]$geom_type, "MULTIPOLYGON")
})

test_that("crs field is normalized to WGS84 (EPSG 4326)", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_equal(ir$layers[[1]]$crs$epsg, 4326L)
})

test_that("bbox has 4 numeric values", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_length(ir$coord$bbox, 4)
  expect_true(all(is.numeric(ir$coord$bbox)))
})

test_that("bbox values are in NC longitude/latitude range", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  bbox <- ir$coord$bbox
  xmin <- bbox[1]; ymin <- bbox[2]; xmax <- bbox[3]; ymax <- bbox[4]
  # xmin < xmax and ymin < ymax
  expect_true(xmin < xmax)
  expect_true(ymin < ymax)
  # NC is roughly -85 to -75 longitude, 33 to 37 latitude
  expect_true(xmin > -86 && xmin < -84)
  expect_true(xmax > -76 && xmax < -74)
  expect_true(ymin > 32 && ymin < 35)
  expect_true(ymax > 35 && ymax < 38)
})

test_that("validate_ir does not warn on sf layers or sf panels", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_no_warning(validate_ir(ir))
})

test_that("sf panels have NULL x_range/y_range without warning", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  panel <- ir$panels[[1]]
  expect_equal(panel$PANEL, 1L)
  expect_null(panel$x_range)
  expect_null(panel$y_range)
  # validate_ir should not warn about missing ranges for sf coord
  expect_no_warning(validate_ir(ir))
})

test_that("aesthetic-mapped sf plot includes fill in data rows", {
  ir2 <- as_d3_ir(ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) + ggplot2::geom_sf())
  first_row <- ir2$layers[[1]]$data[[1]]
  expect_true("fill" %in% names(first_row))
})

test_that("data rows are parallel to geometries", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  expect_equal(length(ir$layers[[1]]$data), length(ir$layers[[1]]$geometries))
})
