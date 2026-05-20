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

.phase35_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
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

.phase35_save_widget <- function(widget, filename) {
  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  outpath <- file.path(out_dir, filename)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(outpath, mustWork = FALSE),
    selfcontained = TRUE
  )
  expect_true(file.exists(outpath))
  outpath
}

.phase35_make_two_panel_sf <- function() {
  sf::st_sf(
    facet = factor(c("A", "B"), levels = c("A", "B")),
    row = factor(c("north", "south"), levels = c("north", "south")),
    col = factor(c("west", "east"), levels = c("west", "east")),
    value = c(10, 20),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(.phase35_square_ring(100, 10, 101, 11))),
      crs = 4326
    )
  )
}

.phase35_make_mixed_sf <- function() {
  sf::st_sf(
    label = c("polygon", "point", "empty", "invalid", "multipolygon"),
    value = c(1, 2, 3, 4, 5),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring())),
      sf::st_point(c(10, 10)),
      sf::st_polygon(),
      sf::st_polygon(list(matrix(
        c(
          20, 0,
          21, 1,
          21, 0,
          20, 1,
          20, 0
        ),
        ncol = 2,
        byrow = TRUE
      ))),
      sf::st_multipolygon(list(list(.phase35_square_ring(30, 0, 31, 1)))),
      crs = 4326
    )
  )
}

.phase35_expect_sf_layer <- function(ir, layer_index = 1L) {
  layer <- ir$layers[[layer_index]]
  expect_equal(layer$geom, "sf")
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_true("row_id" %in% names(layer$data[[1]]))
  expect_false(is.null(layer$sf_diagnostics))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
  layer
}

.phase35_sf_fixture_set <- function() {
  fixtures <- list()

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  choropleth <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) +
    ggplot2::geom_sf()
  fixtures[["phase35-sf-choropleth.html"]] <- .phase35_save_widget(
    gg2d3(choropleth),
    "phase35-sf-choropleth.html"
  )
  .phase35_expect_sf_layer(as_d3_ir(choropleth))

  base_sf <- .phase35_make_two_panel_sf()
  overlay_sf <- sf::st_sf(
    outline = c("A", "B"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0.2, 0.2, 0.8, 0.8))),
      sf::st_polygon(list(.phase35_square_ring(100.2, 10.2, 100.8, 10.8))),
      crs = 4326
    )
  )
  stacked <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = base_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf(data = overlay_sf, fill = NA, colour = "#111111")
  fixtures[["phase35-sf-stacked-overlay.html"]] <- .phase35_save_widget(
    gg2d3(stacked),
    "phase35-sf-stacked-overlay.html"
  )
  stacked_ir <- as_d3_ir(stacked)
  expect_equal(sum(vapply(stacked_ir$layers, function(layer) identical(layer$geom, "sf"), logical(1))), 2L)
  .phase35_expect_sf_layer(stacked_ir, 1L)
  .phase35_expect_sf_layer(stacked_ir, 2L)

  facet_wrap_plot <- ggplot2::ggplot(base_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf() +
    ggplot2::facet_wrap(~facet)
  fixtures[["phase35-sf-facet-wrap.html"]] <- .phase35_save_widget(
    gg2d3(facet_wrap_plot),
    "phase35-sf-facet-wrap.html"
  )
  wrap_ir <- as_d3_ir(facet_wrap_plot)
  expect_equal(wrap_ir$facets$type, "wrap")
  expect_equal(length(wrap_ir$panels), 2L)
  expect_true(all(vapply(wrap_ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))))
  expect_false(identical(wrap_ir$panels[[1]]$sf_bbox, wrap_ir$panels[[2]]$sf_bbox))

  facet_grid_plot <- ggplot2::ggplot(base_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf() +
    ggplot2::facet_grid(row ~ col, drop = FALSE)
  fixtures[["phase35-sf-facet-grid.html"]] <- .phase35_save_widget(
    gg2d3(facet_grid_plot),
    "phase35-sf-facet-grid.html"
  )
  grid_ir <- as_d3_ir(facet_grid_plot)
  expect_equal(grid_ir$facets$type, "grid")
  expect_equal(length(grid_ir$panels), 4L)
  expect_equal(sum(vapply(grid_ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))), 2L)

  mixed_sf <- .phase35_make_mixed_sf()
  skipped_plot <- ggplot2::ggplot(mixed_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf()
  expect_warning(
    skipped_widget <- gg2d3(skipped_plot),
    regexp = "skipped 3"
  )
  fixtures[["phase35-sf-skipped-rows.html"]] <- .phase35_save_widget(
    skipped_widget,
    "phase35-sf-skipped-rows.html"
  )
  expect_warning(
    skipped_ir <- as_d3_ir(skipped_plot),
    regexp = "skipped 3"
  )
  skipped_layer <- .phase35_expect_sf_layer(skipped_ir)
  row_ids <- vapply(skipped_layer$data, function(row) row$row_id, numeric(1))
  expect_equal(row_ids, c(1, 5))
  expect_equal(skipped_layer$sf_diagnostics$skipped_rows, c(2L, 3L, 4L))
  expect_false(any(skipped_layer$sf_diagnostics$skipped_rows %in% row_ids))

  interactivity <- gg2d3(choropleth) |>
    d3_brush() |>
    d3_tooltip() |>
    d3_hover() |>
    d3_handlers(click = "function(event, d) { window.__gg2d3_sf_click = d; }")
  expect_warning(
    interactivity <- d3_zoom(interactivity),
    regexp = "geom_sf.*zoom|zoom.*geom_sf"
  )
  fixtures[["phase35-sf-interactivity-smoke.html"]] <- .phase35_save_widget(
    interactivity,
    "phase35-sf-interactivity-smoke.html"
  )
  expect_true(interactivity$x$interactivity$brush$enabled)
  expect_true(interactivity$x$interactivity$tooltip$enabled)
  expect_true(interactivity$x$interactivity$hover$enabled)
  expect_false(is.null(interactivity$x$interactivity$handlers$click))
  expect_null(interactivity$x$interactivity$zoom)

  fixtures
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

  expect_warning(
    w <- gg2d3(p),
    regexp = "skipped 2"
  )
  expect_s3_class(w, "htmlwidget")

  outpath <- file.path(out_dir, "phase28-world-holes.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE),
                          selfcontained = TRUE)
  expect_true(file.exists(outpath))

  # Verify IR structure
  expect_warning(
    ir <- as_d3_ir(p),
    regexp = "skipped 2"
  )
  sf_layer <- ir$layers[[1]]
  expect_equal(sf_layer$geom, "sf")
  # World data has multipolygons -- verify geom_type
  expect_true(sf_layer$geom_type %in% c("MULTIPOLYGON", "POLYGON"))
  # Verify fill aesthetic data exists
  expect_true("fill" %in% names(sf_layer$data[[1]]))
})

test_that("Phase 35 fixture set is generated for manual sf validation", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  fixtures <- .phase35_sf_fixture_set()

  expect_equal(
    sort(names(fixtures)),
    sort(c(
      "phase35-sf-choropleth.html",
      "phase35-sf-stacked-overlay.html",
      "phase35-sf-facet-wrap.html",
      "phase35-sf-facet-grid.html",
      "phase35-sf-skipped-rows.html",
      "phase35-sf-interactivity-smoke.html"
    ))
  )
})
