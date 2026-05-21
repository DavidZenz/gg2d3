# Shared sf fixture builders for browser and visual smoke tests.

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

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
    selfcontained = FALSE
  )
  testthat::expect_true(file.exists(outpath))
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

.phase35_make_adjacent_sf <- function() {
  sf::st_sf(
    value = c(10, 20),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(.phase35_square_ring(1.4, 0, 2.4, 1))),
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
      sf::st_multipolygon(list(list(.phase35_square_ring(1.4, 0, 2.4, 1)))),
      crs = 4326
    )
  )
}

.phase35_expect_sf_layer <- function(ir, layer_index = 1L) {
  layer <- ir$layers[[layer_index]]
  testthat::expect_equal(layer$geom, "sf")
  testthat::expect_true(length(layer$geometries) > 0)
  testthat::expect_equal(length(layer$data), length(layer$geometries))
  testthat::expect_true("row_id" %in% names(layer$data[[1]]))
  testthat::expect_false(is.null(layer$sf_diagnostics))
  testthat::expect_false(is.null(ir$panels[[1]]$sf_bbox))
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

  stacked_sf <- .phase35_make_adjacent_sf()
  overlay_sf <- sf::st_sf(
    outline = c("A", "B"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(.phase35_square_ring(0.2, 0.2, 0.8, 0.8))),
      sf::st_polygon(list(.phase35_square_ring(1.6, 0.2, 2.2, 0.8))),
      crs = 4326
    )
  )
  stacked <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = stacked_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf(data = overlay_sf, fill = NA, colour = "#111111")
  fixtures[["phase35-sf-stacked-overlay.html"]] <- .phase35_save_widget(
    gg2d3(stacked),
    "phase35-sf-stacked-overlay.html"
  )
  stacked_ir <- as_d3_ir(stacked)
  testthat::expect_equal(sum(vapply(stacked_ir$layers, function(layer) identical(layer$geom, "sf"), logical(1))), 2L)
  .phase35_expect_sf_layer(stacked_ir, 1L)
  .phase35_expect_sf_layer(stacked_ir, 2L)

  facet_sf <- .phase35_make_two_panel_sf()
  facet_wrap_plot <- ggplot2::ggplot(facet_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf() +
    ggplot2::facet_wrap(~facet)
  fixtures[["phase35-sf-facet-wrap.html"]] <- .phase35_save_widget(
    gg2d3(facet_wrap_plot),
    "phase35-sf-facet-wrap.html"
  )
  wrap_ir <- as_d3_ir(facet_wrap_plot)
  testthat::expect_equal(wrap_ir$facets$type, "wrap")
  testthat::expect_equal(length(wrap_ir$panels), 2L)
  testthat::expect_true(all(vapply(wrap_ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))))
  testthat::expect_false(identical(wrap_ir$panels[[1]]$sf_bbox, wrap_ir$panels[[2]]$sf_bbox))

  facet_grid_plot <- ggplot2::ggplot(facet_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf() +
    ggplot2::facet_grid(row ~ col, drop = FALSE)
  fixtures[["phase35-sf-facet-grid.html"]] <- .phase35_save_widget(
    gg2d3(facet_grid_plot),
    "phase35-sf-facet-grid.html"
  )
  grid_ir <- as_d3_ir(facet_grid_plot)
  testthat::expect_equal(grid_ir$facets$type, "grid")
  testthat::expect_equal(length(grid_ir$panels), 4L)
  testthat::expect_equal(sum(vapply(grid_ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))), 2L)

  mixed_sf <- .phase35_make_mixed_sf()
  skipped_plot <- ggplot2::ggplot(mixed_sf, ggplot2::aes(fill = value)) +
    ggplot2::geom_sf()
  testthat::expect_warning(
    skipped_widget <- gg2d3(skipped_plot),
    regexp = "skipped 3"
  )
  fixtures[["phase35-sf-skipped-rows.html"]] <- .phase35_save_widget(
    skipped_widget,
    "phase35-sf-skipped-rows.html"
  )
  testthat::expect_warning(
    skipped_ir <- as_d3_ir(skipped_plot),
    regexp = "skipped 3"
  )
  skipped_layer <- .phase35_expect_sf_layer(skipped_ir)
  row_ids <- vapply(skipped_layer$data, function(row) row$row_id, numeric(1))
  testthat::expect_equal(row_ids, c(1, 5))
  testthat::expect_equal(skipped_layer$sf_diagnostics$skipped_rows, c(2L, 3L, 4L))
  testthat::expect_false(any(skipped_layer$sf_diagnostics$skipped_rows %in% row_ids))

  interactivity <- gg2d3(choropleth) |>
    d3_brush() |>
    d3_tooltip() |>
    d3_hover() |>
    d3_handlers(click = "function(event, d) { window.__gg2d3_sf_click = d; }")
  testthat::expect_warning(
    interactivity <- d3_zoom(interactivity),
    regexp = "geom_sf.*zoom|zoom.*geom_sf"
  )
  fixtures[["phase35-sf-interactivity-smoke.html"]] <- .phase35_save_widget(
    interactivity,
    "phase35-sf-interactivity-smoke.html"
  )
  testthat::expect_true(interactivity$x$interactivity$brush$enabled)
  testthat::expect_true(interactivity$x$interactivity$tooltip$enabled)
  testthat::expect_true(interactivity$x$interactivity$hover$enabled)
  testthat::expect_false(is.null(interactivity$x$interactivity$handlers$click))
  testthat::expect_null(interactivity$x$interactivity$zoom)

  fixtures
}
