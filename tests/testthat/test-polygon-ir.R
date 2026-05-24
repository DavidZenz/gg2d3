if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

library(ggplot2)

expect_valid_ir <- function(ir) {
  expect_silent(validate_ir(ir))
  TRUE
}

expect_polygon_ir <- function(plot) {
  ir <- as_d3_ir(plot)
  expect_true(expect_valid_ir(ir))
  layer <- ir$layers[[1]]
  expect_equal(layer$geom, "polygon")
  expect_true(length(layer$data) > 0L)
  layer
}

expect_polygon_row_fields <- function(rows, fields) {
  for (row in rows) {
    expect_true(all(fields %in% names(row)))
  }
}

row_values <- function(rows, field) {
  vapply(rows, function(row) row[[field]], rows[[1]][[field]])
}

rows_for <- function(rows, field, value) {
  rows[vapply(rows, function(row) identical(row[[field]], value), logical(1))]
}

polygon_required_fields <- c(
  "PANEL", "x", "y", "group", "fill", "colour", "alpha", "linewidth", "linetype"
)

test_that("POLY-01 recognizes a single non-monotone geom_polygon layer", {
  polygon_data <- data.frame(
    vertex = 1:5,
    x = c(0, 2, 1, -0.5, 0.5),
    y = c(0, 0, 1.5, 0.75, 0.25)
  )

  layer <- expect_polygon_ir(
    ggplot(polygon_data, aes(x, y)) +
      geom_polygon(
        fill = "#79A7D3",
        colour = "#1B365D",
        alpha = 0.65,
        linewidth = 1.2,
        linetype = "dashed"
      )
  )

  expect_polygon_row_fields(layer$data, polygon_required_fields)
  expect_equal(as.numeric(row_values(layer$data, "x")), polygon_data$x)
  expect_equal(as.numeric(row_values(layer$data, "y")), polygon_data$y)
})

test_that("POLY-01 preserves row order within each polygon group", {
  grouped_data <- data.frame(
    polygon = rep(c("a", "b"), each = 5),
    vertex = rep(1:5, 2),
    x = c(0, 2, 1, -0.5, 0.5, 4, 6, 5, 3.5, 4.5),
    y = c(0, 0, 1.5, 0.75, 0.25, 1, 1, 2.5, 1.75, 1.25)
  )

  layer <- expect_polygon_ir(
    ggplot(grouped_data, aes(x, y, group = polygon, fill = polygon)) +
      geom_polygon(colour = "#283618", alpha = 0.8, linewidth = 0.9, linetype = "solid")
  )

  expect_polygon_row_fields(layer$data, polygon_required_fields)
  group_ids <- unique(row_values(layer$data, "group"))
  expect_equal(length(group_ids), 2L)

  first_group_rows <- rows_for(layer$data, "group", group_ids[[1]])
  second_group_rows <- rows_for(layer$data, "group", group_ids[[2]])

  expect_equal(as.numeric(row_values(first_group_rows, "x")), grouped_data$x[grouped_data$polygon == "a"])
  expect_equal(as.numeric(row_values(first_group_rows, "y")), grouped_data$y[grouped_data$polygon == "a"])
  expect_equal(as.numeric(row_values(second_group_rows, "x")), grouped_data$x[grouped_data$polygon == "b"])
  expect_equal(as.numeric(row_values(second_group_rows, "y")), grouped_data$y[grouped_data$polygon == "b"])
})

test_that("POLY-01 keeps PANEL and row order for faceted polygons", {
  faceted_data <- data.frame(
    panel = rep(c("left", "right"), each = 5),
    vertex = rep(1:5, 2),
    x = c(0, 2, 1, -0.5, 0.5, 1, 3, 2, 0.5, 1.5),
    y = c(0, 0, 1.5, 0.75, 0.25, 2, 2, 3.5, 2.75, 2.25)
  )

  layer <- expect_polygon_ir(
    ggplot(faceted_data, aes(x, y, group = panel, fill = panel)) +
      geom_polygon(colour = "#2F3E46", alpha = 0.7, linewidth = 0.75, linetype = "solid") +
      facet_wrap(~ panel)
  )

  expect_polygon_row_fields(layer$data, polygon_required_fields)
  panel_ids <- unique(row_values(layer$data, "PANEL"))
  expect_equal(length(panel_ids), 2L)

  left_rows <- rows_for(layer$data, "PANEL", panel_ids[[1]])
  right_rows <- rows_for(layer$data, "PANEL", panel_ids[[2]])

  expect_equal(as.numeric(row_values(left_rows, "x")), faceted_data$x[faceted_data$panel == "left"])
  expect_equal(as.numeric(row_values(left_rows, "y")), faceted_data$y[faceted_data$panel == "left"])
  expect_equal(as.numeric(row_values(right_rows, "x")), faceted_data$x[faceted_data$panel == "right"])
  expect_equal(as.numeric(row_values(right_rows, "y")), faceted_data$y[faceted_data$panel == "right"])
})

test_that("POLY-01 preserves mapped polygon styling columns", {
  style_data <- data.frame(
    polygon = rep(c("matte", "bright"), each = 5),
    x = c(0, 2, 1, -0.5, 0.5, 4, 6, 5, 3.5, 4.5),
    y = c(0, 0, 1.5, 0.75, 0.25, 1, 1, 2.5, 1.75, 1.25),
    fill_value = rep(c("fill-a", "fill-b"), each = 5),
    colour_value = rep(c("stroke-a", "stroke-b"), each = 5),
    alpha_value = rep(c(0.35, 0.85), each = 5),
    linewidth_value = rep(c(0.4, 1.4), each = 5),
    linetype_value = rep(c("solid", "dashed"), each = 5)
  )

  layer <- expect_polygon_ir(
    ggplot(
      style_data,
      aes(
        x,
        y,
        group = polygon,
        fill = fill_value,
        colour = colour_value,
        alpha = alpha_value,
        linewidth = linewidth_value,
        linetype = linetype_value
      )
    ) +
      geom_polygon()
  )

  expect_polygon_row_fields(layer$data, polygon_required_fields)
  expect_equal(length(unique(row_values(layer$data, "fill"))), 2L)
  expect_equal(length(unique(row_values(layer$data, "colour"))), 2L)
  expect_equal(length(unique(row_values(layer$data, "alpha"))), 2L)
  expect_equal(length(unique(row_values(layer$data, "linewidth"))), 2L)
  expect_equal(length(unique(row_values(layer$data, "linetype"))), 2L)
})

test_that("POLY-01 preserves NA polygon styling values", {
  polygon_data <- data.frame(
    vertex = 1:5,
    x = c(0, 2, 1, -0.5, 0.5),
    y = c(0, 0, 1.5, 0.75, 0.25)
  )

  layer <- expect_polygon_ir(
    ggplot(polygon_data, aes(x, y)) +
      geom_polygon(fill = NA, colour = NA, alpha = 0.5, linewidth = 0.8, linetype = "solid")
  )

  expect_polygon_row_fields(layer$data, polygon_required_fields)
  expect_true(all(is.na(row_values(layer$data, "fill"))))
  expect_true(all(is.na(row_values(layer$data, "colour"))))
})
