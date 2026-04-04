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
