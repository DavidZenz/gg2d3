library(ggplot2)

test_that("scale helper preserves continuous and transformed domains", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_length(ir$scales$x$domain, 2)
  expect_true(ir$scales$x$domain[1] <= min(mtcars$wt), info = "scale helper x domain lower bound")
  expect_true(ir$scales$x$domain[2] >= max(mtcars$wt), info = "scale helper x domain upper bound")

  p_log <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_log10()
  ir_log <- as_d3_ir(p_log)

  expect_equal(ir_log$scales$x$transform, "log10", info = "scale helper log transform")
  expect_equal(ir_log$scales$x$base, 10, info = "scale helper log base")
  expect_true(all(ir_log$scales$x$domain > 0), info = "scale helper log domain")
})

test_that("scale helper preserves date and datetime metadata", {
  date_df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-02-01", "2024-03-01")),
    y = c(1, 3, 2)
  )
  date_ir <- as_d3_ir(
    ggplot(date_df, aes(date, y)) +
      geom_point() +
      scale_x_date(date_labels = "%Y-%m-%d")
  )

  expect_equal(date_ir$scales$x$transform, "date", info = "scale helper date transform")
  expect_true(all(date_ir$scales$x$domain > 1e12), info = "scale helper date domain")
  expect_true(length(date_ir$scales$x$breaks) > 0, info = "scale helper date breaks")
  expect_true(all(date_ir$scales$x$breaks > 1e12), info = "scale helper date break units")
  expect_equal(date_ir$scales$x$format, "%Y-%m-%d", info = "scale helper date format")

  time_df <- data.frame(
    time = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 14:00"), tz = "UTC"),
    y = c(1, 2)
  )
  time_ir <- as_d3_ir(
    ggplot(time_df, aes(time, y)) +
      geom_point() +
      scale_x_datetime(timezone = "UTC")
  )

  expect_equal(time_ir$scales$x$transform, "time", info = "scale helper datetime transform")
  expect_equal(time_ir$scales$x$timezone, "UTC", info = "scale helper datetime timezone")
  expect_true(all(time_ir$scales$x$domain > 1e12), info = "scale helper datetime domain")
  expect_true(all(time_ir$scales$x$breaks > 1e12), info = "scale helper datetime breaks")
})

test_that("scale helper preserves discrete domains and coord_flip labels", {
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) +
    geom_col() +
    coord_flip() +
    labs(x = "Cylinders", y = "Miles per Gallon")
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "categorical", info = "scale helper discrete scale type")
  expect_equal(ir$scales$x$domain, c("4", "6", "8"), info = "scale helper discrete domain")
  expect_equal(ir$axes$x$label, "Miles per Gallon", info = "scale helper coord_flip x label")
  expect_equal(ir$axes$y$label, "Cylinders", info = "scale helper coord_flip y label")
})

test_that("layer helper preserves geom names and row data", {
  rect_df <- data.frame(xmin = 0, xmax = 1, ymin = 0, ymax = 1)
  text_df <- data.frame(x = 1, y = 1, label = "A")
  polygon_df <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1),
    id = 1
  )

  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point(data = mtcars[1:2, ]) +
    geom_line(data = mtcars[1:3, ]) +
    geom_rect(
      data = rect_df,
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      inherit.aes = FALSE
    ) +
    geom_text(data = text_df, aes(x = x, y = y, label = label), inherit.aes = FALSE) +
    geom_polygon(data = polygon_df, aes(x = x, y = y, group = id), inherit.aes = FALSE)
  ir <- as_d3_ir(p)

  expect_equal(
    vapply(ir$layers, `[[`, character(1), "geom"),
    c("point", "line", "rect", "text", "polygon"),
    info = "layer helper geom dispatch"
  )

  row <- ir$layers[[1]]$data[[1]]
  expect_true(is.numeric(row$x), info = "layer helper scalar x value")
  expect_true(is.numeric(row$y), info = "layer helper scalar y value")

  discrete_ir <- as_d3_ir(ggplot(mtcars, aes(factor(cyl), mpg)) + geom_point())
  expect_false(is.factor(discrete_ir$layers[[1]]$data[[1]]$x), info = "layer helper drops factor class")
})

test_that("layer helper preserves aesthetic variable maps", {
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point()
  ir <- as_d3_ir(p)
  var_names <- ir$layers[[1]]$var_names

  expect_equal(var_names$x, "wt", info = "layer helper var_names x")
  expect_equal(var_names$y, "mpg", info = "layer helper var_names y")
  expect_equal(var_names$colour, "factor(cyl)", info = "layer helper var_names colour")
  expect_equal(ir$aes_by_var$wt, "x", info = "layer helper aes_by_var x")
  expect_equal(ir$aes_by_var$mpg, "y", info = "layer helper aes_by_var y")
  expect_equal(ir$aes_by_var[["factor(cyl)"]], "colour", info = "layer helper aes_by_var colour")
})

test_that("theme helper preserves translated theme elements", {
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() +
    theme(
      panel.background = element_rect(fill = "grey95", colour = "black", linewidth = 0.5),
      panel.grid.major = element_line(colour = "grey70", linewidth = 0.25),
      axis.text.x = element_text(colour = "red", size = 11, angle = 35, margin = margin(t = 4)),
      plot.margin = margin(5, 6, 7, 8),
      legend.key.size = grid::unit(0.25, "in")
    )
  ir <- as_d3_ir(p)

  expect_equal(ir$theme$panel$background$type, "rect", info = "theme helper panel.background type")
  expect_equal(ir$theme$panel$background$fill, "grey95", info = "theme helper panel.background fill")
  expect_equal(ir$theme$panel$background$colour, "black", info = "theme helper panel.background colour")
  expect_equal(ir$theme$grid$major$type, "line", info = "theme helper panel.grid.major type")
  expect_equal(ir$theme$grid$major$colour, "grey70", info = "theme helper panel.grid.major colour")
  expect_equal(ir$theme$axis$text.x$type, "text", info = "theme helper axis.text.x type")
  expect_equal(ir$theme$axis$text.x$colour, "red", info = "theme helper axis.text.x colour")
  expect_equal(ir$theme$axis$text.x$size, 11, info = "theme helper axis.text.x size")
  expect_equal(ir$theme$axis$text.x$angle, 35, info = "theme helper axis.text.x angle")
  expect_true(ir$theme$axis$text.x$margin$top > 0, info = "theme helper axis.text.x margin")
  expect_equal(ir$theme$plot$margin$type, "margin", info = "theme helper plot.margin type")
  expect_true(ir$theme$plot$margin$top > 0, info = "theme helper plot.margin top")
  expect_true(ir$theme$plot$margin$right > ir$theme$plot$margin$top, info = "theme helper plot.margin right")
  expect_equal(ir$theme$legend$key.size, 24, tolerance = 1e-6, info = "theme helper legend.key.size")
})

test_that("geom parameter helper preserves routed geom params", {
  rug_ir <- as_d3_ir(
    ggplot(mtcars, aes(wt, mpg)) +
      geom_rug(sides = "b")
  )
  rug_params <- rug_ir$layers[[1]]$params

  expect_equal(rug_params$sides, "b", info = "geom parameter helper geom_rug sides")

  dot_ir <- as_d3_ir(
    ggplot(mtcars, aes(wt)) +
      geom_dotplot(method = "histodot", binaxis = "x", stackdir = "center")
  )
  dot_params <- dot_ir$layers[[1]]$params

  expect_equal(dot_params$method, "histodot", info = "geom parameter helper geom_dotplot method")
  expect_equal(dot_params$binaxis, "x", info = "geom parameter helper geom_dotplot binaxis")
  expect_equal(dot_params$stackdir, "center", info = "geom parameter helper geom_dotplot stackdir")
})

test_that("layer helper preserves sf annotation layer contracts", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")

  source_sf <- sf::st_sf(
    label = "here",
    geometry = sf::st_sfc(sf::st_point(c(0, 1)), crs = 4326)
  )
  ir <- as_d3_ir(
    ggplot(source_sf, aes(label = label)) +
      ggplot2::geom_sf_text()
  )
  layer <- ir$layers[[1]]

  expect_equal(layer$geom, "sf_text", info = "layer helper sf annotation geom")
  expect_equal(layer$annotation_type, "text", info = "layer helper sf annotation type")
  expect_true(length(layer$geometries) > 0, info = "layer helper sf annotation geometries")
  expect_true("row_id" %in% names(layer$data[[1]]), info = "layer helper sf annotation row id")
  expect_equal(layer$var_names$label, "label", info = "layer helper sf annotation var_names")
})

test_that("facet helper preserves wrap and grid layout metadata", {
  wrap_ir <- as_d3_ir(
    ggplot(mtcars, aes(wt, mpg)) +
      geom_point() +
      facet_wrap(~ cyl)
  )
  expect_equal(wrap_ir$facets$type, "wrap", info = "facet helper wrap type")
  expect_true(wrap_ir$facets$nrow >= 1L, info = "facet helper wrap nrow")
  expect_true(wrap_ir$facets$ncol >= 1L, info = "facet helper wrap ncol")
  expect_equal(length(wrap_ir$panels), length(wrap_ir$facets$layout), info = "facet helper wrap panels")
  expect_true(all(c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y") %in% names(wrap_ir$facets$layout[[1]])))

  grid_ir <- as_d3_ir(
    ggplot(mtcars, aes(wt, mpg)) +
      geom_point() +
      facet_grid(cyl ~ am)
  )
  expect_equal(grid_ir$facets$type, "grid", info = "facet helper grid type")
  expect_equal(grid_ir$facets$nrow, 3L, info = "facet helper grid nrow")
  expect_equal(grid_ir$facets$ncol, 2L, info = "facet helper grid ncol")
  expect_equal(length(grid_ir$panels), 6L, info = "facet helper grid panels")
  expect_true(is.integer(grid_ir$facets$layout[[1]]$SCALE_X), info = "facet helper SCALE_X integer")
  expect_true(is.integer(grid_ir$facets$layout[[1]]$SCALE_Y), info = "facet helper SCALE_Y integer")
})

test_that("facet helper preserves free scale panel ranges", {
  df <- data.frame(
    x = c(1, 2, 100, 200),
    y = c(1, 2, 50, 60),
    panel = factor(c("A", "A", "B", "B"))
  )
  ir <- as_d3_ir(
    ggplot(df, aes(x, y)) +
      geom_point() +
      facet_wrap(~ panel, scales = "free")
  )

  expect_equal(ir$facets$scales, "free", info = "facet helper free scale mode")
  expect_equal(length(ir$panels), 2L, info = "facet helper free panels")
  expect_false(identical(ir$panels[[1]]$x_range, ir$panels[[2]]$x_range), info = "facet helper free x ranges")
  expect_false(identical(ir$panels[[1]]$y_range, ir$panels[[2]]$y_range), info = "facet helper free y ranges")
  expect_true(length(ir$panels[[1]]$x_breaks) > 0, info = "facet helper free x breaks")
  expect_true(length(ir$panels[[1]]$y_breaks) > 0, info = "facet helper free y breaks")
})

test_that("facet helper preserves sf panel bbox contracts", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")

  square_ring <- function(xmin, ymin, xmax, ymax) {
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
  sf_data <- sf::st_sf(
    row_var = factor(c("A", "B"), levels = c("A", "B")),
    col_var = factor(c("X", "X"), levels = c("X", "Y")),
    geometry = sf::st_sfc(
      sf::st_polygon(list(square_ring(0, 0, 1, 1))),
      sf::st_polygon(list(square_ring(100, 0, 101, 1))),
      crs = 4326
    )
  )

  ir <- as_d3_ir(
    ggplot(sf_data) +
      ggplot2::geom_sf() +
      ggplot2::facet_grid(row_var ~ col_var, drop = FALSE)
  )
  panel_has_bbox <- vapply(ir$panels, function(panel) !is.null(panel$sf_bbox), logical(1))

  expect_equal(ir$facets$type, "grid", info = "facet helper sf grid type")
  expect_equal(length(ir$panels), 4L, info = "facet helper sf panel count")
  expect_equal(sum(panel_has_bbox), 2L, info = "facet helper sf populated bboxes")
  expect_true(any(!panel_has_bbox), info = "facet helper sf empty panel has NULL bbox")
})
