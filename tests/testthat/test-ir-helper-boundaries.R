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
