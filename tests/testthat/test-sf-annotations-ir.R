skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

sfann_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
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

sfann_make_polygon_point_line <- function() {
  sf::st_sf(
    label = c("polygon", "point", "line"),
    panel = factor(c("A", "A", "B"), levels = c("A", "B")),
    geometry = sf::st_sfc(
      sf::st_polygon(list(sfann_square_ring())),
      sf::st_point(c(2, 2)),
      sf::st_linestring(matrix(c(3, 0, 4, 1, 5, 0), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )
}

expect_sf_annotation_row_fields <- function(row) {
  expect_true("label" %in% names(row))
  expect_true("size" %in% names(row))
  expect_true("row_id" %in% names(row))
  expect_true(".sf_family" %in% names(row))
}

expect_sf_annotation_layer <- function(layer, geom, annotation_type) {
  expect_equal(layer$geom, geom)
  expect_equal(layer$annotation_type, annotation_type)
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_false(is.null(layer$sf_diagnostics))
  expect_true(all(c("accepted_rows", "skipped_rows") %in% names(layer$sf_diagnostics)))
  invisible(layer)
}

test_that("SFANN-01 geom_sf_text creates sf_text IR with labels aesthetics and diagnostics", {
  source_sf <- sfann_make_polygon_point_line()
  ir <- as_d3_ir(
    ggplot2::ggplot(source_sf, ggplot2::aes(label = label, colour = label)) +
      ggplot2::geom_sf_text(size = 3, hjust = 0.5, vjust = 0.5)
  )
  layer <- expect_sf_annotation_layer(ir$layers[[1]], "sf_text", "text")

  expect_true("colour" %in% names(layer$data[[1]]))
  expect_sf_annotation_row_fields(layer$data[[1]])
  expect_equal(layer$sf_family, "mixed")
  expect_equal(layer$sf_diagnostics$accepted_geometry_families, c("line", "point", "polygon"))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
  expect_no_warning(validate_ir(ir))
})

test_that("SFANN-01 geom_sf_label creates sf_label IR with fill colour and alpha", {
  source_sf <- sfann_make_polygon_point_line()
  ir <- as_d3_ir(
    ggplot2::ggplot(source_sf, ggplot2::aes(label = label, fill = label)) +
      ggplot2::geom_sf_label(colour = "black", alpha = 0.8)
  )
  layer <- expect_sf_annotation_layer(ir$layers[[1]], "sf_label", "label")

  expect_true("fill" %in% names(layer$data[[1]]))
  expect_true("colour" %in% names(layer$data[[1]]))
  expect_true("alpha" %in% names(layer$data[[1]]))
  expect_equal(layer$sf_diagnostics$accepted_geometry_families, c("line", "point", "polygon"))
  expect_no_warning(validate_ir(ir))
})

test_that("SFANN-01 sf annotation rows skip unsupported empty invalid and missing geometries", {
  bad_sf <- sf::st_sf(
    label = c("polygon", "collection", "empty", "invalid", "missing"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(sfann_square_ring())),
      sf::st_geometrycollection(list(sf::st_point(c(10, 10)))),
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
      sf::st_point(c(NA_real_, NA_real_)),
      crs = 4326
    )
  )

  expect_warning(
    ir <- as_d3_ir(
      ggplot2::ggplot(bad_sf, ggplot2::aes(label = label)) +
        ggplot2::geom_sf_text()
    ),
    regexp = "skipped"
  )
  layer <- expect_sf_annotation_layer(ir$layers[[1]], "sf_text", "text")
  row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))

  expect_equal(row_ids, 1)
  expect_equal(layer$sf_diagnostics$accepted_rows, 1L)
  expect_true(all(c(2L, 3L, 4L, 5L) %in% layer$sf_diagnostics$skipped_rows))
  expect_equal(length(layer$data), length(layer$geometries))
})

test_that("SFANN-01 stacked sf and sf annotation layers share sf_bbox", {
  base_sf <- sf::st_sf(
    label = "base",
    geometry = sf::st_sfc(sf::st_polygon(list(sfann_square_ring(0, 0, 1, 1))), crs = 4326)
  )
  text_sf <- sf::st_sf(
    label = "far",
    geometry = sf::st_sfc(sf::st_point(c(10, 20)), crs = 4326)
  )

  ir <- as_d3_ir(
    ggplot2::ggplot() +
      ggplot2::geom_sf(data = base_sf) +
      ggplot2::geom_sf_text(data = text_sf, ggplot2::aes(label = label))
  )

  expect_equal(vapply(ir$layers, `[[`, character(1), "geom"), c("sf", "sf_text"))
  expect_false(is.null(ir$panels[[1]]$sf_bbox))
  expect_equal(ir$panels[[1]]$sf_bbox, c(0, 0, 10, 20))
  expect_no_warning(validate_ir(ir))
})

test_that("SFANN-01 facet_wrap preserves sf annotation PANEL membership and panel bboxes", {
  source_sf <- sf::st_sf(
    label = c("A", "B"),
    panel = factor(c("A", "B"), levels = c("A", "B")),
    geometry = sf::st_sfc(
      sf::st_polygon(list(sfann_square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(sfann_square_ring(100, 10, 101, 11))),
      crs = 4326
    )
  )

  ir <- as_d3_ir(
    ggplot2::ggplot(source_sf, ggplot2::aes(label = label)) +
      ggplot2::geom_sf_text() +
      ggplot2::facet_wrap(~ panel)
  )
  layer <- expect_sf_annotation_layer(ir$layers[[1]], "sf_text", "text")
  panels <- vapply(layer$data, function(row) row$PANEL, integer(1))

  expect_equal(panels, c(1L, 2L))
  expect_equal(length(ir$panels), 2L)
  expect_true(all(vapply(ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))))
  expect_false(identical(ir$panels[[1]]$sf_bbox, ir$panels[[2]]$sf_bbox))
  expect_no_warning(validate_ir(ir))
})
