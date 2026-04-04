# Visual tests for geom_sf D3 rendering (Phase 28)
# These tests generate HTML output files for manual visual verification.
# Run: testthat::test_file("tests/testthat/test-sf-visual.R")
#
# REND-01: NC counties choropleth (filled polygon rendering)
# REND-02: World borders with multipolygon holes (transparent interiors)
# REND-03: Fill/stroke aesthetic passthrough from IR to SVG path attributes
#
# Output goes to test_output/ in the project root (per CLAUDE.md convention).

.test_output_dir <- function() {
  # Write to project root test_output/ (CLAUDE.md: "Always save visual test HTML
  # files to test_output/ in the project root, not /tmp/")
  pkg_root <- tryCatch(
    rprojroot::find_package_root_file(),
    error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
  )
  file.path(pkg_root, "test_output")
}

test_that("REND-01: NC counties render as filled choropleth via gg2d3 pipeline", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) + ggplot2::geom_sf()

  w <- gg2d3(p)
  expect_s3_class(w, "htmlwidget")

  outpath <- file.path(out_dir, "phase28-nc-choropleth.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                          selfcontained = TRUE)
  expect_true(file.exists(outpath))

  # Verify the IR contains expected sf layer structure
  ir <- as_d3_ir(p)
  sf_layer <- ir$layers[[1]]
  expect_equal(sf_layer$geom, "sf")
  expect_true(length(sf_layer$geometries) > 0)
  expect_true("row_id" %in% names(sf_layer$data[[1]]))
})

test_that("REND-02/03: World borders render with multipolygon holes and correct aesthetics", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  skip_if_not_installed("rnaturalearth")

  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Use scale="small" which is bundled with rnaturalearth (no rnaturalearthdata needed)
  world <- rnaturalearth::ne_countries(scale = "small", returnclass = "sf")
  p <- ggplot2::ggplot(world) +
    ggplot2::geom_sf(ggplot2::aes(fill = pop_est))

  w <- gg2d3(p)
  expect_s3_class(w, "htmlwidget")

  outpath <- file.path(out_dir, "phase28-world-holes.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                          selfcontained = TRUE)
  expect_true(file.exists(outpath))

  # Verify IR structure
  ir <- as_d3_ir(p)
  sf_layer <- ir$layers[[1]]
  expect_equal(sf_layer$geom, "sf")
  # World data has multipolygons -- verify geom_type
  expect_true(sf_layer$geom_type %in% c("MULTIPOLYGON", "POLYGON"))
  # Verify fill aesthetic data exists
  expect_true("fill" %in% names(sf_layer$data[[1]]))
})
