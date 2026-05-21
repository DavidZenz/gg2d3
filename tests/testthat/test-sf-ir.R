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

expect_finite_sf_bbox <- function(bbox) {
  expect_false(is.null(bbox))
  expect_length(bbox, 4)
  expect_true(all(is.finite(bbox)))
}

expect_sf_layer_contract <- function(layer, family, accepted_rows, accepted_types, accepted_families) {
  expect_equal(layer$geom, "sf")
  expect_equal(layer$sf_family, family)
  expect_equal(length(layer$data), length(layer$geometries))

  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))
  row_families <- vapply(layer$data, function(row) row$.sf_family, character(1))

  expect_equal(row_ids, accepted_rows)
  expect_equal(layer$sf_diagnostics$accepted_rows, accepted_rows)
  expect_equal(sort(unique(row_families)), accepted_families)
  expect_equal(layer$sf_diagnostics$accepted_geometry_types, accepted_types)
  expect_equal(layer$sf_diagnostics$accepted_geometry_families, accepted_families)
}

test_that("SFGEOM-01 point-family sf rows enter IR with diagnostics and bbox", {
  point_sf <- sf::st_sf(
    id = 1:2,
    geometry = sf::st_sfc(
      sf::st_point(c(0, 1)),
      sf::st_multipoint(matrix(c(2, 2, 3, 3), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )

  ir <- as_d3_ir(ggplot2::ggplot(point_sf) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]

  expect_sf_layer_contract(
    layer,
    family = "point",
    accepted_rows = c(1, 2),
    accepted_types = c("MULTIPOINT", "POINT"),
    accepted_families = "point"
  )
  expect_false(layer$sf_diagnostics$missing_crs)
  expect_finite_sf_bbox(ir$panels[[1]]$sf_bbox)
  expect_finite_sf_bbox(ir$coord$bbox)
  expect_no_warning(validate_ir(ir))
})

test_that("SFGEOM-02 line-family sf rows enter IR with diagnostics and bbox", {
  line_sf <- sf::st_sf(
    id = 1:2,
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 0, 1, 1, 2, 0), ncol = 2, byrow = TRUE)),
      sf::st_multilinestring(list(
        matrix(c(3, 0, 4, 1), ncol = 2, byrow = TRUE),
        matrix(c(4, 1, 5, 0), ncol = 2, byrow = TRUE)
      )),
      crs = 4326
    )
  )

  ir <- as_d3_ir(ggplot2::ggplot(line_sf) + ggplot2::geom_sf())
  layer <- ir$layers[[1]]

  expect_sf_layer_contract(
    layer,
    family = "line",
    accepted_rows = c(1, 2),
    accepted_types = c("LINESTRING", "MULTILINESTRING"),
    accepted_families = "line"
  )
  expect_finite_sf_bbox(ir$panels[[1]]$sf_bbox)
  expect_no_warning(validate_ir(ir))
})

test_that("SFGEOM-04 mixed sf families keep row identity and skip unsupported rows", {
  mixed_sf <- sf::st_sf(
    label = c("polygon", "point", "line", "collection"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(sf_ir_square_ring())),
      sf::st_point(c(2, 2)),
      sf::st_linestring(matrix(c(3, 0, 4, 1), ncol = 2, byrow = TRUE)),
      sf::st_geometrycollection(list(sf::st_point(c(10, 10)))),
      crs = 4326
    )
  )

  expect_warning(
    ir <- as_d3_ir(ggplot2::ggplot(mixed_sf) + ggplot2::geom_sf()),
    regexp = "skipped 1"
  )
  layer <- ir$layers[[1]]

  expect_sf_layer_contract(
    layer,
    family = "mixed",
    accepted_rows = c(1, 2, 3),
    accepted_types = c("LINESTRING", "POINT", "POLYGON"),
    accepted_families = c("line", "point", "polygon")
  )
  expect_equal(layer$sf_diagnostics$skipped_rows, 4L)
  expect_true("GEOMETRYCOLLECTION" %in% layer$sf_diagnostics$unsupported_geometry_types)
  expect_finite_sf_bbox(ir$panels[[1]]$sf_bbox)
  expect_no_warning(validate_ir(ir))
})

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
  expect_lt(ir$coord$bbox[[3]], 6)
  expect_lt(ir$coord$bbox[[4]], 2)
  expect_equal(ir$panels[[1]]$sf_bbox, ir$coord$bbox)
  expect_no_warning(validate_ir(ir))
})

test_that("as_d3_ir keeps skipped sf rows out of accepted row ids", {
  polygon <- sf::st_polygon(list(sf_ir_square_ring()))
  point <- sf::st_point(c(10, 10))
  empty_polygon <- sf::st_polygon()
  bowtie <- sf::st_polygon(list(matrix(
    c(
      20, 0,
      21, 1,
      21, 0,
      20, 1,
      20, 0
    ),
    ncol = 2,
    byrow = TRUE
  )))
  multipolygon <- sf::st_multipolygon(list(
    list(sf_ir_square_ring(30, 0, 31, 1))
  ))

  mixed <- sf::st_sf(
    id = 1:5,
    label = c("polygon", "point", "empty", "invalid", "multipolygon"),
    geometry = sf::st_sfc(polygon, point, empty_polygon, bowtie, multipolygon, crs = 4326)
  )

  expect_warning(
    ir <- as_d3_ir(ggplot2::ggplot(mixed) + ggplot2::geom_sf()),
    regexp = "skipped 3"
  )

  layer <- ir$layers[[1]]
  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))
  skipped_rows <- layer$sf_diagnostics$skipped_rows

  expect_equal(length(layer$data), length(layer$geometries))
  expect_equal(row_ids, layer$sf_diagnostics$accepted_rows)
  expect_equal(row_ids, c(1, 5))
  expect_equal(skipped_rows, c(2L, 3L, 4L))
  expect_false(any(skipped_rows %in% row_ids))
  expect_equal(length(layer$geometries), length(layer$sf_diagnostics$accepted_rows))
  expect_equal(layer$sf_diagnostics$accepted_geometry_types, c("MULTIPOLYGON", "POLYGON"))
  expect_true("POINT" %in% layer$sf_diagnostics$unsupported_geometry_types)
  expect_no_warning(validate_ir(ir))
})

test_that("stacked sf layers share one panel sf_bbox", {
  base_sf <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(
      sf::st_polygon(list(sf_ir_square_ring(0, 0, 1, 1))),
      crs = 4326
    )
  )
  overlay_sf <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(
      sf::st_polygon(list(sf_ir_square_ring(10, 20, 11, 21))),
      crs = 4326
    )
  )

  ir <- as_d3_ir(
    ggplot2::ggplot() +
      ggplot2::geom_sf(data = base_sf) +
      ggplot2::geom_sf(data = overlay_sf)
  )

  expect_equal(ir$panels[[1]]$sf_bbox, c(0, 0, 11, 21))
  expect_equal(ir$coord$bbox, c(0, 0, 11, 21))
  expect_no_warning(validate_ir(ir))
})

test_that("validate_ir warns on malformed sf_bbox metadata", {
  ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf())

  short_bbox <- ir
  short_bbox$panels[[1]]$sf_bbox <- c(0, 1, 2)
  expect_warning(validate_ir(short_bbox), regexp = "sf_bbox")

  non_finite_bbox <- ir
  non_finite_bbox$panels[[1]]$sf_bbox <- c(0, 1, Inf, 3)
  expect_warning(validate_ir(non_finite_bbox), regexp = "sf_bbox")
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
