if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

expect_regression_ir_ok <- function(plot) {
  ir <- as_d3_ir(plot)
  expect_no_warning(validate_ir(ir))
  ir
}

regression_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
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

regression_read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

test_that("HARD-03 regression matrix covers representative non-sf geoms", {
  base <- data.frame(
    x = c(1, 2, 3, 4),
    y = c(2, 3, 2, 5),
    group = c("a", "a", "b", "b"),
    label = c("one", "two", "three", "four")
  )
  rects <- data.frame(xmin = c(0, 2), xmax = c(1, 3), ymin = c(0, 1), ymax = c(2, 4))

  plots <- list(
    geom_point = ggplot2::ggplot(base, ggplot2::aes(x, y)) + ggplot2::geom_point(),
    geom_line = ggplot2::ggplot(base, ggplot2::aes(x, y, group = group)) + ggplot2::geom_line(),
    geom_col = ggplot2::ggplot(base, ggplot2::aes(group, y)) + ggplot2::geom_col(),
    geom_rect = ggplot2::ggplot(rects) +
      ggplot2::geom_rect(ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)),
    geom_text = ggplot2::ggplot(base, ggplot2::aes(x, y, label = label)) + ggplot2::geom_text(),
    geom_segment = ggplot2::ggplot(base, ggplot2::aes(x = x, y = y, xend = x + 0.5, yend = y + 0.5)) +
      ggplot2::geom_segment(),
    geom_boxplot = ggplot2::ggplot(base, ggplot2::aes(group, y)) + ggplot2::geom_boxplot(),
    geom_smooth = ggplot2::ggplot(base, ggplot2::aes(x, y)) +
      ggplot2::geom_smooth(method = "lm", se = FALSE)
  )

  for (plot_name in names(plots)) {
    ir <- expect_regression_ir_ok(plots[[plot_name]])
    expect_true(length(ir$layers) >= 1L, info = plot_name)
  }
})

test_that("HARD-03 regression matrix covers sf families", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  polygon_sf <- sf::st_sf(
    label = "polygon",
    geometry = sf::st_sfc(sf::st_polygon(list(regression_square_ring())), crs = 4326)
  )
  point_sf <- sf::st_sf(
    label = "point",
    geometry = sf::st_sfc(sf::st_point(c(2, 2)), crs = 4326)
  )
  line_sf <- sf::st_sf(
    label = "line",
    geometry = sf::st_sfc(
      sf::st_linestring(matrix(c(3, 0, 4, 1), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )
  mixed_sf <- sf::st_sf(
    label = c("polygon", "point", "line"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(regression_square_ring())),
      sf::st_point(c(2, 2)),
      sf::st_linestring(matrix(c(3, 0, 4, 1), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )

  polygon_ir <- expect_regression_ir_ok(ggplot2::ggplot(polygon_sf) + ggplot2::geom_sf())
  point_ir <- expect_regression_ir_ok(ggplot2::ggplot(point_sf) + ggplot2::geom_sf())
  line_ir <- expect_regression_ir_ok(ggplot2::ggplot(line_sf) + ggplot2::geom_sf())
  mixed_ir <- expect_regression_ir_ok(ggplot2::ggplot(mixed_sf) + ggplot2::geom_sf())

  expect_equal(polygon_ir$layers[[1]]$sf_family, "polygon")
  expect_equal(point_ir$layers[[1]]$sf_family, "point")
  expect_equal(line_ir$layers[[1]]$sf_family, "line")
  expect_equal(mixed_ir$layers[[1]]$sf_family, "mixed")
  expect_true(all(c("line", "point", "polygon") %in% mixed_ir$layers[[1]]$sf_diagnostics$accepted_geometry_families))
})

test_that("SFANN-01 regression matrix covers sf text and label annotation IR", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  polygon_sf <- sf::st_sf(
    label = "A",
    geometry = sf::st_sfc(sf::st_polygon(list(regression_square_ring())), crs = 4326)
  )

  ir <- expect_regression_ir_ok(
    ggplot2::ggplot(polygon_sf) +
      ggplot2::geom_sf_text(ggplot2::aes(label = label)) +
      ggplot2::geom_sf_label(ggplot2::aes(label = label), fill = "white")
  )
  layer_geoms <- vapply(ir$layers, `[[`, character(1), "geom")
  annotation_layers <- ir$layers[layer_geoms %in% c("sf_text", "sf_label")]

  expect_true("sf_text" %in% layer_geoms)
  expect_true("sf_label" %in% layer_geoms)
  expect_true(all(vapply(
    annotation_layers,
    function(layer) length(layer$data) == length(layer$geometries),
    logical(1)
  )))
})

test_that("HARD-03 regression matrix covers facets legends dates and coord_flip", {
  facet_ir <- expect_regression_ir_ok(
    ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
      ggplot2::geom_boxplot() +
      ggplot2::facet_wrap(~am)
  )
  legend_ir <- expect_regression_ir_ok(
    ggplot2::ggplot(iris, ggplot2::aes(Sepal.Length, Sepal.Width, colour = Species)) +
      ggplot2::geom_point()
  )
  date_ir <- expect_regression_ir_ok(
    ggplot2::ggplot(
      data.frame(date = as.Date(c("2024-01-01", "2024-02-01")), y = c(1, 2)),
      ggplot2::aes(date, y)
    ) +
      ggplot2::geom_point()
  )
  flip_ir <- expect_regression_ir_ok(
    ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
      ggplot2::geom_boxplot() +
      ggplot2::coord_flip()
  )

  expect_equal(facet_ir$facets$type, "wrap")
  expect_true(length(legend_ir$guides) >= 1L)
  expect_equal(date_ir$scales$x$transform, "date")
  expect_true(all(date_ir$scales$x$domain > 1e12))
  expect_equal(flip_ir$coord$type, "flip")
  expect_equal(flip_ir$axes$x$label, "mpg")
  expect_equal(flip_ir$axes$y$label, "factor(cyl)")
})

test_that("HARD-03 regression matrix guards sf renderer and interaction source contracts", {
  sf_js <- regression_read_module("inst/htmlwidgets/modules/geoms/sf.js")
  brush_js <- regression_read_module("inst/htmlwidgets/modules/brush.js")
  events_js <- regression_read_module("inst/htmlwidgets/modules/events.js")

  expect_match(sf_js, "geom-sf-polygon")
  expect_match(sf_js, "geom-sf-point")
  expect_match(sf_js, "geom-sf-line")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "bboxToFeatureCollection")

  expect_match(brush_js, "\\.geom-sf")
  expect_match(brush_js, "data-cx")
  expect_match(brush_js, "data-cy")
  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "dedupeSelectedDataByRowId")

  expect_match(events_js, "\\.geom-sf")
  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "setInputValue")
})
