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
  expect_match(sf_js, "\\.data\\(rows\\)")
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
