test_that("sf and geojsonsf are available for sf_utils tests", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  expect_true(TRUE) # packages available
})

# ============================================================
# Dataset 1 — NC shapefile (baseline, simple polygons)
# ============================================================

test_that("FEAS-01 gate: ggplot_build() preserves sfc geometry column for geom_sf", {
  skip_if_not_installed("sf")
  skip_if_not_installed("ggplot2")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  expect_true("geometry" %in% names(df),
    info = "ggplot_build() must preserve the geometry column in b$data[[1]]"
  )
  expect_true(inherits(df$geometry, "sfc"),
    info = "geometry column must be of class sfc"
  )
})

test_that("extract_sf_geometries returns character vector from NC shapefile", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  result <- extract_sf_geometries(df)

  expect_type(result, "character")
  expect_length(result, 100L) # NC has 100 counties
})

test_that("extract_sf_geometries produces valid GeoJSON strings", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  result <- extract_sf_geometries(df)

  # Each string should be valid GeoJSON geometry object
  expect_true(all(grepl('\\{"type":', result)),
    info = "Each GeoJSON string must start with {\"type\":"
  )
})

test_that("normalize_to_wgs84 transforms EPSG:4267 (NC native CRS) to EPSG:4326", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  geom_col <- df$geometry
  result <- normalize_to_wgs84(geom_col)

  expect_equal(sf::st_crs(result)$epsg, 4326L)
})

test_that("normalize_to_wgs84 returns unchanged when CRS is already WGS84", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  nc_wgs84 <- sf::st_transform(nc, 4326)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc_wgs84) + ggplot2::geom_sf())
  df <- b$data[[1]]

  geom_col <- df$geometry
  result <- normalize_to_wgs84(geom_col)

  expect_equal(sf::st_crs(result)$epsg, 4326L)
})

test_that("normalize_to_wgs84 returns non-sfc input unchanged", {
  result <- normalize_to_wgs84("not_an_sfc")
  expect_equal(result, "not_an_sfc")

  result2 <- normalize_to_wgs84(42L)
  expect_equal(result2, 42L)
})

test_that("detect_dominant_geom_type returns MULTIPOLYGON for NC shapefile", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  result <- detect_dominant_geom_type(df)

  expect_equal(result, "MULTIPOLYGON")
})

test_that("get_layer_crs returns list with epsg and wkt fields", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  b <- ggplot2::ggplot_build(ggplot2::ggplot(nc) + ggplot2::geom_sf())
  df <- b$data[[1]]

  result <- get_layer_crs(df)

  expect_type(result, "list")
  expect_true("epsg" %in% names(result))
  expect_true("wkt" %in% names(result))
  expect_type(result$wkt, "character")
})

test_that("extract_sf_geometries errors on data.frame with no sfc column", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  plain_df <- data.frame(x = 1:3, y = 4:6)

  expect_error(
    extract_sf_geometries(plain_df),
    regexp = "Could not find sfc geometry column"
  )
})

# ============================================================
# Dataset 2 — rnaturalearth world borders (complex multipolygons)
# ============================================================

test_that("extract_sf_geometries handles rnaturalearth world borders (complex multipolygons)", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  skip_if_not_installed("rnaturalearth")

  world <- rnaturalearth::ne_countries(scale = "small", returnclass = "sf")
  b_world <- ggplot2::ggplot_build(ggplot2::ggplot(world) + ggplot2::geom_sf())
  df_world <- b_world$data[[1]]

  result <- extract_sf_geometries(df_world)

  expect_type(result, "character")
  expect_gt(length(result), 100L) # world has ~177 countries (small scale)
  expect_true(all(grepl('\\{"type":', result)),
    info = "All world border GeoJSON strings must be valid geometry objects"
  )
})

test_that("detect_dominant_geom_type returns polygon type for world borders", {
  skip_if_not_installed("sf")
  skip_if_not_installed("rnaturalearth")

  world <- rnaturalearth::ne_countries(scale = "small", returnclass = "sf")
  b_world <- ggplot2::ggplot_build(ggplot2::ggplot(world) + ggplot2::geom_sf())
  df_world <- b_world$data[[1]]

  result <- detect_dominant_geom_type(df_world)

  # World data may be MULTIPOLYGON or POLYGON depending on scale
  expect_true(result %in% c("MULTIPOLYGON", "POLYGON"),
    info = paste("Expected MULTIPOLYGON or POLYGON, got:", result)
  )
})

# ============================================================
# Dataset 3 — Projected CRS (EPSG:3857 Web Mercator)
# ============================================================

test_that("normalize_to_wgs84 transforms EPSG:3857 (Web Mercator) to EPSG:4326", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  nc_merc <- sf::st_transform(nc, 3857)
  b_merc <- ggplot2::ggplot_build(ggplot2::ggplot(nc_merc) + ggplot2::geom_sf())
  df_merc <- b_merc$data[[1]]

  geom_col <- df_merc$geometry
  result <- normalize_to_wgs84(geom_col)

  expect_equal(sf::st_crs(result)$epsg, 4326L)
})

test_that("extract_sf_geometries on projected EPSG:3857 data produces valid WGS84 GeoJSON", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  nc_merc <- sf::st_transform(nc, 3857)
  b_merc <- ggplot2::ggplot_build(ggplot2::ggplot(nc_merc) + ggplot2::geom_sf())
  df_merc <- b_merc$data[[1]]

  result <- extract_sf_geometries(df_merc)

  expect_type(result, "character")
  expect_length(result, 100L)
  expect_true(all(grepl('\\{"type":', result)),
    info = "GeoJSON strings from projected data must be valid geometry objects"
  )

  # Parse first result and verify coordinates are in WGS84 range (-180 to 180 lon, -90 to 90 lat)
  first_geom <- jsonlite::fromJSON(result[1])
  # For MULTIPOLYGON, coordinates are deeply nested
  coords_flat <- unlist(first_geom$coordinates)
  lon_vals <- coords_flat[seq(1, length(coords_flat), by = 2)]
  lat_vals <- coords_flat[seq(2, length(coords_flat), by = 2)]
  expect_true(all(lon_vals >= -180 & lon_vals <= 180),
    info = "Longitude values must be in WGS84 range after normalization"
  )
  expect_true(all(lat_vals >= -90 & lat_vals <= 90),
    info = "Latitude values must be in WGS84 range after normalization"
  )
})

# ============================================================
# Phase 32 — polygon-family preparation helper
# ============================================================

square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
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

test_that("prepare_sf_geometry_ir keeps polygon family and reports unsupported types", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  polygon <- sf::st_polygon(list(square_ring()))
  multipolygon <- sf::st_multipolygon(list(
    list(square_ring(2, 0, 3, 1)),
    list(square_ring(4, 0, 5, 1))
  ))
  point <- sf::st_point(c(0.5, 0.5))
  line <- sf::st_linestring(matrix(c(0, 0, 1, 1), ncol = 2, byrow = TRUE))

  df <- data.frame(label = c("poly", "multi", "point", "line"))
  df$geometry <- sf::st_sfc(polygon, multipolygon, point, line, crs = 4326)

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "skipped 2"
  )

  expect_equal(nrow(result$data), length(result$geometries))
  expect_equal(length(result$data$row_id), length(result$geometries))
  expect_equal(result$data$row_id, c(1L, 2L))
  expect_equal(result$sf_diagnostics$accepted_rows, c(1L, 2L))
  expect_equal(result$sf_diagnostics$skipped_rows, c(3L, 4L))
  expect_true(all(c("POINT", "LINESTRING") %in% result$sf_diagnostics$unsupported_geometry_types))
  expect_true(all(c("POLYGON", "MULTIPOLYGON") %in% result$sf_diagnostics$accepted_geometry_types))
  expect_type(result$geometries, "character")
  expect_true(all(grepl('\\{"type":', result$geometries)))
})

test_that("prepare_sf_geometry_ir records skipped mixed sf rows", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  polygon <- sf::st_polygon(list(square_ring()))
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
    list(square_ring(30, 0, 31, 1))
  ))

  df <- data.frame(label = c("polygon", "point", "empty", "invalid", "missing", "multipolygon"))
  df$geometry <- sf::st_sfc(
    polygon,
    point,
    empty_polygon,
    bowtie,
    polygon,
    multipolygon,
    crs = 4326
  )
  df$geometry[[5]] <- NA

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "skipped 4"
  )

  expect_equal(nrow(result$data), length(result$geometries))
  expect_equal(result$data$row_id, c(1L, 6L))
  expect_equal(result$sf_diagnostics$accepted_rows, c(1L, 6L))
  expect_equal(result$sf_diagnostics$skipped_rows, c(2L, 3L, 4L, 5L))

  reasons <- vapply(result$sf_diagnostics$skipped, function(item) item$reason, character(1))
  expect_equal(reasons, c("unsupported", "empty", "invalid", "missing"))
})

test_that("prepare_sf_geometry_ir skips empty polygon geometry", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  empty_polygon <- sf::st_polygon()
  valid_polygon <- sf::st_polygon(list(square_ring()))
  df <- data.frame(label = c("empty", "valid"))
  df$geometry <- sf::st_sfc(empty_polygon, valid_polygon, crs = 4326)

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "skipped 1"
  )

  expect_equal(result$data$row_id, 2L)
  expect_equal(result$sf_diagnostics$skipped_rows, 1L)
  expect_equal(result$sf_diagnostics$skipped[[1]]$reason, "empty")
})

test_that("prepare_sf_geometry_ir skips invalid bowtie polygon", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  bowtie <- sf::st_polygon(list(matrix(
    c(
      0, 0,
      1, 1,
      1, 0,
      0, 1,
      0, 0
    ),
    ncol = 2,
    byrow = TRUE
  )))
  valid_polygon <- sf::st_polygon(list(square_ring(2, 0, 3, 1)))
  df <- data.frame(label = c("invalid", "valid"))
  df$geometry <- sf::st_sfc(bowtie, valid_polygon, crs = 3857)

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "skipped 1"
  )

  expect_equal(result$data$row_id, 2L)
  expect_equal(result$sf_diagnostics$skipped_rows, 1L)
  expect_equal(result$sf_diagnostics$skipped[[1]]$reason, "invalid")
})

test_that("prepare_sf_geometry_ir warns for missing CRS and serializes as-is", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  df <- data.frame(label = "missing-crs")
  df$geometry <- sf::st_sfc(sf::st_polygon(list(square_ring())), crs = NA_character_)

  expect_warning(
    result <- prepare_sf_geometry_ir(df),
    regexp = "missing CRS"
  )

  expect_true(result$sf_diagnostics$missing_crs)
  expect_equal(result$data$row_id, 1L)
  expect_equal(result$sf_diagnostics$accepted_rows, 1L)
  expect_equal(result$crs$epsg, NA_integer_)
  expect_length(result$geometries, 1L)
})
