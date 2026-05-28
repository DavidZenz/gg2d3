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

row_has_field <- function(rows, field) {
  vapply(rows, function(row) field %in% names(row), logical(1))
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

test_that("GEOM-02 classifies subgroup holes as built data without IR topology support", {
  polygon_data <- data.frame(
    shape = "donut",
    subgroup = rep(c("outer", "inner"), each = 5),
    x = c(0, 4, 4, 0, 0, 1, 1, 3, 3, 1),
    y = c(0, 0, 4, 4, 0, 1, 3, 3, 1, 1)
  )
  plot <- ggplot(polygon_data, aes(x, y, group = shape, subgroup = subgroup)) +
    geom_polygon(fill = "#79A7D3", colour = "#1B365D")
  built <- ggplot2::ggplot_build(plot)$data[[1]]

  layer <- expect_polygon_ir(plot)

  expect_true("subgroup" %in% names(built))
  expect_equal(as.character(built$subgroup), polygon_data$subgroup)
  expect_false(any(row_has_field(layer$data, "subgroup")))
  expect_equal(as.numeric(row_values(layer$data, "x")), built$x)
  expect_equal(as.numeric(row_values(layer$data, "y")), built$y)
})

test_that("GEOM-02 polygon subgroup hole fixtures define topology boundary", {
  hole_data <- data.frame(
    shape = "donut",
    subgroup = rep(c("outer", "inner"), each = 5),
    x = c(0, 4, 4, 0, 0, 1, 1, 3, 3, 1),
    y = c(0, 0, 4, 4, 0, 1, 3, 3, 1, 1)
  )
  hole_plot <- ggplot(hole_data, aes(x, y, group = shape, subgroup = subgroup)) +
    geom_polygon(rule = "evenodd", fill = "#79A7D3", colour = "#1B365D")
  hole_built <- ggplot2::ggplot_build(hole_plot)$data[[1]]
  hole_layer <- expect_polygon_ir(hole_plot)

  expect_true("subgroup" %in% names(hole_built))
  expect_equal(as.character(hole_built$subgroup), hole_data$subgroup)
  expect_equal(
    ggplot2::ggplot_build(hole_plot)$plot$layers[[1]]$geom_params$rule,
    "evenodd"
  )
  expect_false(any(row_has_field(hole_layer$data, "subgroup")))
  expect_false(any(row_has_field(hole_layer$data, "rule")))
  expect_equal(as.numeric(row_values(hole_layer$data, "x")), hole_built$x)
  expect_equal(as.numeric(row_values(hole_layer$data, "y")), hole_built$y)

  reversed_with_repeat <- data.frame(
    shape = "reversed",
    vertex = 5:1,
    x = c(0, 0, 4, 4, 0),
    y = c(0, 4, 4, 0, 0)
  )
  reversed_layer <- expect_polygon_ir(
    ggplot(reversed_with_repeat, aes(x, y, group = shape)) +
      geom_polygon(fill = "#b7e4c7", colour = "#1b4332")
  )
  expect_equal(as.numeric(row_values(reversed_layer$data, "x")), reversed_with_repeat$x)
  expect_equal(as.numeric(row_values(reversed_layer$data, "y")), reversed_with_repeat$y)

  self_crossing <- data.frame(
    shape = "bow",
    x = c(0, 2, 0, 2),
    y = c(0, 2, 2, 0)
  )
  self_crossing_layer <- expect_polygon_ir(
    ggplot(self_crossing, aes(x, y, group = shape)) +
      geom_polygon(fill = "#cdb4db", colour = "#3c096c")
  )
  expect_equal(as.numeric(row_values(self_crossing_layer$data, "x")), self_crossing$x)
  expect_equal(as.numeric(row_values(self_crossing_layer$data, "y")), self_crossing$y)

  too_small <- data.frame(
    shape = "few",
    x = c(0, 1),
    y = c(0, 1)
  )
  too_small_layer <- expect_polygon_ir(
    ggplot(too_small, aes(x, y, group = shape)) +
      geom_polygon(fill = "#ffc8dd", colour = "#590d22")
  )
  expect_equal(length(too_small_layer$data), 2L)
  expect_equal(as.numeric(row_values(too_small_layer$data, "x")), too_small$x)
  expect_equal(as.numeric(row_values(too_small_layer$data, "y")), too_small$y)
})

test_that("GEOM-02 preserves repeated ring vertices and reversed row order as ordinary polygon input", {
  polygon_data <- data.frame(
    vertex = 5:1,
    x = c(0, 0, 4, 4, 0),
    y = c(0, 4, 4, 0, 0)
  )
  plot <- ggplot(polygon_data, aes(x, y)) +
    geom_polygon(fill = "#b7e4c7", colour = "#1b4332")
  built <- ggplot2::ggplot_build(plot)$data[[1]]

  layer <- expect_polygon_ir(plot)

  expect_equal(as.numeric(row_values(layer$data, "x")), built$x)
  expect_equal(as.numeric(row_values(layer$data, "y")), built$y)
  expect_equal(as.numeric(row_values(layer$data, "x")), polygon_data$x)
  expect_equal(as.numeric(row_values(layer$data, "y")), polygon_data$y)
})

test_that("GEOM-02 preserves missing coordinate rows for renderer-side finite filtering", {
  polygon_data <- data.frame(
    shape = "missing",
    x = c(0, 1, NA, 0),
    y = c(0, 0, 1, 1)
  )
  plot <- ggplot(polygon_data, aes(x, y, group = shape)) +
    geom_polygon(fill = "#f2cc8f", colour = "#3d405b")
  built <- ggplot2::ggplot_build(plot)$data[[1]]

  layer <- expect_polygon_ir(plot)

  expect_true(any(is.na(built$x) | is.na(built$y)))
  expect_equal(as.numeric(row_values(layer$data, "x")), built$x)
  expect_equal(as.numeric(row_values(layer$data, "y")), built$y)
})

test_that("GEOM-02 classifies self-crossing and too-small polygons without topology repair", {
  self_crossing <- data.frame(
    shape = "bow",
    x = c(0, 2, 0, 2),
    y = c(0, 2, 2, 0)
  )
  too_small <- data.frame(
    shape = "few",
    x = c(0, 1),
    y = c(0, 1)
  )

  self_layer <- expect_polygon_ir(
    ggplot(self_crossing, aes(x, y, group = shape)) +
      geom_polygon(fill = "#cdb4db", colour = "#3c096c")
  )
  small_layer <- expect_polygon_ir(
    ggplot(too_small, aes(x, y, group = shape)) +
      geom_polygon(fill = "#ffc8dd", colour = "#590d22")
  )

  expect_equal(as.numeric(row_values(self_layer$data, "x")), self_crossing$x)
  expect_equal(as.numeric(row_values(self_layer$data, "y")), self_crossing$y)
  expect_equal(length(small_layer$data), 2L)
  expect_equal(as.numeric(row_values(small_layer$data, "x")), too_small$x)
  expect_equal(as.numeric(row_values(small_layer$data, "y")), too_small$y)
})
