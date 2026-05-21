skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

# Load package if not already loaded
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

renderer_sf_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
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

expect_renderer_sf_layer <- function(layer, family, accepted_types) {
  expect_equal(layer$geom, "sf")
  expect_equal(layer$sf_family, family)
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_equal(layer$sf_diagnostics$accepted_geometry_types, accepted_types)
  expect_true(all(vapply(layer$data, function(row) ".sf_family" %in% names(row), logical(1))))
  expect_true(all(vapply(layer$data, function(row) "row_id" %in% names(row), logical(1))))
}

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

test_that("panel renderer filters sf data and geometries together", {
  gg2d3_js <- read_repo_file("inst/htmlwidgets/gg2d3.js")

  expect_match(gg2d3_js, 'layer\\.geom === "sf"')
  expect_match(gg2d3_js, "Array\\.isArray\\(layer\\.geometries\\)")
  expect_match(gg2d3_js, "sfPairs")
  expect_match(gg2d3_js, "pair\\.data\\.PANEL === panelNum")
  expect_match(gg2d3_js, "geometries: filteredPairs\\.map")
})

test_that("skipped sf rows cannot become selectable paths", {
  gg2d3_js <- read_repo_file("inst/htmlwidgets/gg2d3.js")
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(gg2d3_js, "sfPairs")
  expect_match(gg2d3_js, "filteredPairs\\.map\\(function\\(pair\\) \\{ return pair\\.data; \\}\\)")
  expect_match(gg2d3_js, "geometries: filteredPairs\\.map\\(function\\(pair\\) \\{ return pair\\.geometry; \\}\\)")

  expect_match(sf_js, "path\\.geom-sf")
  expect_match(sf_js, "\\.data\\(polygonRows\\)")
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "d\\.row_id")
})

test_that("panel renderer passes sf bbox state to geom renderers", {
  gg2d3_js <- read_repo_file("inst/htmlwidgets/gg2d3.js")

  expect_match(gg2d3_js, "panelData: panelData")
  expect_match(gg2d3_js, "sfBBox:")
  expect_match(gg2d3_js, "panelData\\.sf_bbox")
  expect_match(gg2d3_js, "plotWidth")
  expect_match(gg2d3_js, "plotHeight")
})

test_that("sf renderer consumes shared panel bbox when available", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "bboxToFeatureCollection")
  expect_match(sf_js, "options\\.sfBBox")
  expect_match(sf_js, "fitSource")
  expect_match(sf_js, "reflectY\\(true\\)")
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
})

test_that("SFGEOM-03 sf renderer source dispatches polygon point and line families", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "Point")
  expect_match(sf_js, "MultiPoint")
  expect_match(sf_js, "LineString")
  expect_match(sf_js, "MultiLineString")
  expect_match(sf_js, "Polygon")
  expect_match(sf_js, "MultiPolygon")
  expect_match(sf_js, "geom-sf-point")
  expect_match(sf_js, "geom-sf-line")
  expect_match(sf_js, "geom-sf-polygon")
})

test_that("SFGEOM-03 sf renderer source declares point and line DOM attributes", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, 'append\\("circle"\\)')
  expect_match(sf_js, 'attr\\("cx"')
  expect_match(sf_js, 'attr\\("cy"')
  expect_match(sf_js, 'attr\\("r"')
  expect_match(sf_js, 'fill", "none"')
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "mmToPxRadius")
  expect_match(sf_js, "mmToPxLinewidth")
  expect_match(sf_js, "getDashArray")
})

test_that("SFGEOM-04 sf renderer continues polygon path projection contract", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "path\\.geom-sf")
  expect_match(sf_js, "d3\\.geoIdentity\\(\\)")
  expect_match(sf_js, "reflectY\\(true\\)")
  expect_match(sf_js, "fitExtent")
  expect_match(sf_js, "options\\.sfBBox")
  expect_match(sf_js, "fill-rule")
  expect_match(sf_js, "evenodd")
})

test_that("SFGEOM-03 renderer IR smoke accepts point and multipoint sf_family data", {
  point_sf <- sf::st_sf(
    id = 1:2,
    geometry = sf::st_sfc(
      sf::st_point(c(0, 0)),
      sf::st_multipoint(matrix(c(1, 1, 2, 2), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )

  ir <- as_d3_ir(ggplot2::ggplot(point_sf) + ggplot2::geom_sf())

  expect_renderer_sf_layer(ir$layers[[1]], "point", c("MULTIPOINT", "POINT"))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
})

test_that("SFGEOM-03 renderer IR smoke accepts line and multiline sf_family data", {
  line_sf <- sf::st_sf(
    id = 1:2,
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 0, 1, 1), ncol = 2, byrow = TRUE)),
      sf::st_multilinestring(list(
        matrix(c(2, 0, 3, 1), ncol = 2, byrow = TRUE),
        matrix(c(3, 1, 4, 0), ncol = 2, byrow = TRUE)
      )),
      crs = 4326
    )
  )

  ir <- as_d3_ir(ggplot2::ggplot(line_sf) + ggplot2::geom_sf())

  expect_renderer_sf_layer(ir$layers[[1]], "line", c("LINESTRING", "MULTILINESTRING"))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
})

test_that("SFGEOM-04 renderer IR smoke spans polygon+point stacked bbox", {
  polygon_sf <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_polygon(list(renderer_sf_square_ring())), crs = 4326)
  )
  point_sf <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_point(c(5, 6)), crs = 4326)
  )

  ir <- as_d3_ir(
    ggplot2::ggplot() +
      ggplot2::geom_sf(data = polygon_sf) +
      ggplot2::geom_sf(data = point_sf)
  )

  expect_renderer_sf_layer(ir$layers[[1]], "polygon", "POLYGON")
  expect_renderer_sf_layer(ir$layers[[2]], "point", "POINT")
  expect_equal(ir$panels[[1]]$sf_bbox, c(0, 0, 5, 6))
})
