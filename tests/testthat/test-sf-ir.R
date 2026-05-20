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

# ============================================================
# Phase 32 - filtered sf IR diagnostics
# ============================================================

sf_ir_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
  matrix(
    c(
      xmin, ymin,
      xmax, ymin,
      xmax, ymax,
      xmin, ymax,
      xmin, ymin
    ),
    ncol = 2,
    byrow = TRUE
  )
}

test_that("as_d3_ir filters unsupported sf rows and preserves source row_id", {
  polygon <- sf::st_polygon(list(sf_ir_square_ring()))
  point <- sf::st_point(c(10, 10))
  multipolygon <- sf::st_multipolygon(list(
    list(sf_ir_square_ring(2, 0, 3, 1)),
    list(sf_ir_square_ring(4, 0, 5, 1))
  ))

  mixed <- sf::st_sf(
    id = 1:3,
    label = c("polygon", "point", "multipolygon"),
    geometry = sf::st_sfc(polygon, point, multipolygon, crs = 4326)
  )

  expect_warning(
    ir <- as_d3_ir(ggplot2::ggplot(mixed) + ggplot2::geom_sf()),
    regexp = "skipped 1"
  )

  layer <- ir$layers[[1]]
  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))

  expect_equal(layer$geom, "sf")
  expect_equal(length(layer$data), length(layer$geometries))
  expect_equal(row_ids, c(1, 3))
  expect_equal(layer$sf_diagnostics$accepted_rows, c(1L, 3L))
  expect_equal(layer$sf_diagnostics$skipped_rows, 2L)
  expect_true("POINT" %in% layer$sf_diagnostics$unsupported_geometry_types)
  expect_no_warning(validate_ir(ir))
})

test_that("as_d3_ir warns for missing CRS and records sf diagnostics", {
  missing_crs <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(
      sf::st_polygon(list(sf_ir_square_ring())),
      crs = NA_character_
    )
  )

  expect_warning(
    ir <- as_d3_ir(ggplot2::ggplot(missing_crs) + ggplot2::geom_sf()),
    regexp = "missing CRS"
  )

  layer <- ir$layers[[1]]
  expect_true(layer$sf_diagnostics$missing_crs)
  expect_equal(layer$sf_diagnostics$accepted_rows, 1L)
  expect_equal(layer$crs$epsg, NA_integer_)
  expect_no_warning(validate_ir(ir))
})

test_that("validate_ir errors on malformed sf layer structures", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())

  missing_geometries <- ir
  missing_geometries$layers[[1]]$geometries <- NULL
  expect_error(validate_ir(missing_geometries), regexp = "sf layer.*geometries")

  mismatched_geometries <- ir
  mismatched_geometries$layers[[1]]$geometries <- mismatched_geometries$layers[[1]]$geometries[-1]
  expect_error(validate_ir(mismatched_geometries), regexp = "sf layer.*geometries")

  missing_diagnostics <- ir
  missing_diagnostics$layers[[1]]$sf_diagnostics <- NULL
  expect_error(validate_ir(missing_diagnostics), regexp = "sf layer.*sf_diagnostics")

  missing_rows <- ir
  missing_rows$layers[[1]]$sf_diagnostics$accepted_rows <- NULL
  expect_error(validate_ir(missing_rows), regexp = "sf layer.*accepted_rows")
})
