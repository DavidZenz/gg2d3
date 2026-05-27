if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

library(ggplot2)

rect_bounds <- c("xmin", "xmax", "ymin", "ymax")

row_complete_bounds <- function(row) {
  values <- unlist(row[rect_bounds], use.names = FALSE)
  all(!is.na(values)) && all(is.finite(as.numeric(values)))
}

bound_matrix_complete <- function(data) {
  complete.cases(data[, rect_bounds, drop = FALSE])
}

ir_bound_matrix_complete <- function(rows) {
  vapply(rows, row_complete_bounds, logical(1))
}

ir_bound_na_matrix <- function(rows) {
  do.call(rbind, lapply(rows, function(row) {
    is.na(unlist(row[rect_bounds], use.names = FALSE))
  }))
}

ir_bound_value_matrix <- function(rows) {
  do.call(rbind, lapply(rows, function(row) {
    as.numeric(unlist(row[rect_bounds], use.names = FALSE))
  }))
}

classify_rect_ir_case <- function(plot) {
  built <- ggplot2::ggplot_build(plot)$data[[1]]
  ir <- as_d3_ir(plot)
  layer <- ir$layers[[1]]

  expect_equal(layer$geom, "rect")
  expect_equal(length(layer$data), nrow(built))

  list(
    built = built,
    ir = ir,
    layer = layer,
    built_complete = bound_matrix_complete(built),
    ir_complete = ir_bound_matrix_complete(layer$data)
  )
}

rect_tile_cases <- list(
  continuous_scale_limits = ggplot(
    data.frame(xmin = c(-0.5, 0.2), xmax = c(0.5, 0.8), ymin = c(-0.5, 0.2), ymax = c(0.5, 0.8)),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#6699cc", colour = "#2f3e46") +
    scale_x_continuous(limits = c(0, 1)) +
    scale_y_continuous(limits = c(0, 1)),

  coord_cartesian_limits = ggplot(
    data.frame(xmin = c(-0.5, 0.2), xmax = c(0.5, 0.8), ymin = c(-0.5, 0.2), ymax = c(0.5, 0.8)),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#88aa55", colour = "#283618") +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)),

  discrete_tile_grid_limits = ggplot(
    expand.grid(x = factor(c("a", "b", "c")), y = factor(c("low", "mid", "high"))),
    aes(x = x, y = y)
  ) +
    geom_tile(fill = "#d9a441", colour = "#5f4b32") +
    scale_x_discrete(limits = c("a", "b")) +
    scale_y_discrete(limits = c("low", "mid")),

  reversed_scale_rect = ggplot(
    data.frame(xmin = c(1, 3), xmax = c(2, 4), ymin = c(1, 2), ymax = c(2, 3)),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#b56576", colour = "#5f0f40") +
    scale_x_reverse(),

  coord_flip_rect = ggplot(
    data.frame(xmin = c(1, 3), xmax = c(2, 4), ymin = c(1, 2), ymax = c(2, 3)),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#6a994e", colour = "#386641") +
    coord_flip(),

  faceted_rect_tile = ggplot(
    data.frame(
      panel = rep(c("left", "right"), each = 2),
      xmin = c(0, 1, 0, 1),
      xmax = c(0.7, 1.7, 0.7, 1.7),
      ymin = c(0, 0, 1, 1),
      ymax = c(0.8, 0.8, 1.8, 1.8)
    ),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#4d908e", colour = "#1d3557") +
    facet_wrap(~ panel)
)

test_that("RECT-01 continuous scale limits censor out-of-limit rect bounds before IR", {
  case <- classify_rect_ir_case(rect_tile_cases$continuous_scale_limits)

  expect_true(any(!case$built_complete))
  expect_equal(case$ir_complete, case$built_complete)
  expect_true(any(is.na(case$built[, rect_bounds])))
  expect_equal(
    unname(is.na(as.matrix(case$built[, rect_bounds]))),
    unname(ir_bound_na_matrix(case$layer$data))
  )
})

test_that("RECT-01 coord_cartesian limits preserve rect bounds for panel clipping", {
  case <- classify_rect_ir_case(rect_tile_cases$coord_cartesian_limits)

  expect_true(all(case$built_complete))
  expect_true(all(case$ir_complete))
  expect_true(any(case$built$xmin < 0 | case$built$ymin < 0))
})

test_that("RECT-01 discrete geom_tile limits retain finite bounds for kept tiles", {
  case <- classify_rect_ir_case(rect_tile_cases$discrete_tile_grid_limits)

  kept <- case$built_complete
  expect_true(any(kept))
  expect_true(any(!kept))
  expect_equal(case$ir_complete, kept)
  expect_true(all(vapply(case$layer$data[kept], row_complete_bounds, logical(1))))
})

test_that("RECT-01 reversed scales keep finite IR bounds without original ordering assumptions", {
  case <- classify_rect_ir_case(rect_tile_cases$reversed_scale_rect)

  expect_true(all(case$built_complete))
  expect_true(all(case$ir_complete))
  expect_true(all(vapply(case$layer$data, row_complete_bounds, logical(1))))
})

test_that("RECT-01 coord_flip preserves flip metadata and finite rect bounds", {
  case <- classify_rect_ir_case(rect_tile_cases$coord_flip_rect)

  expect_true(case$ir$coord$flip)
  expect_true(all(case$built_complete))
  expect_true(all(case$ir_complete))
})

test_that("RECT-01 faceted rects keep PANEL values across panels", {
  case <- classify_rect_ir_case(rect_tile_cases$faceted_rect_tile)

  panels <- unique(vapply(case$layer$data, function(row) as.character(row$PANEL), character(1)))
  expect_true(length(panels) >= 2L)
  expect_true(all(case$built_complete))
  expect_true(all(case$ir_complete))
})

test_that("GEOM-01 log10 rect bounds mirror ggplot2 built transformed bounds", {
  plot <- ggplot(
    data.frame(
      xmin = c(10, 100),
      xmax = c(20, 200),
      ymin = c(10, 100),
      ymax = c(20, 200)
    ),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#6699cc", colour = "#2f3e46") +
    scale_x_log10() +
    scale_y_log10()

  case <- classify_rect_ir_case(plot)

  expect_equal(case$ir$scales$x$transform, "log10")
  expect_equal(case$ir$scales$y$transform, "log10")
  expect_equal(unname(ir_bound_value_matrix(case$layer$data)), unname(as.matrix(case$built[, rect_bounds])), tolerance = 1e-8)
  expect_true(all(case$ir_complete))
})

test_that("GEOM-01 sqrt tile bounds mirror ggplot2 built transformed bounds", {
  plot <- ggplot(
    data.frame(x = c(1, 4), y = c(9, 16)),
    aes(x = x, y = y)
  ) +
    geom_tile(fill = "#d9a441", colour = "#5f4b32") +
    scale_x_sqrt() +
    scale_y_sqrt()

  case <- classify_rect_ir_case(plot)

  expect_equal(case$ir$scales$x$transform, "sqrt")
  expect_equal(case$ir$scales$y$transform, "sqrt")
  expect_equal(unname(ir_bound_value_matrix(case$layer$data)), unname(as.matrix(case$built[, rect_bounds])), tolerance = 1e-8)
  expect_true(all(case$ir_complete))
})

test_that("GEOM-01 reverse rect x and y bounds mirror ggplot2 built transformed bounds", {
  plot <- ggplot(
    data.frame(
      xmin = c(1, 3),
      xmax = c(2, 4),
      ymin = c(2, 4),
      ymax = c(3, 5)
    ),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#b56576", colour = "#5f0f40") +
    scale_x_reverse() +
    scale_y_reverse()

  case <- classify_rect_ir_case(plot)

  expect_equal(case$ir$scales$x$transform, "reverse")
  expect_equal(case$ir$scales$y$transform, "reverse")
  expect_equal(unname(ir_bound_value_matrix(case$layer$data)), unname(as.matrix(case$built[, rect_bounds])), tolerance = 1e-8)
  expect_true(all(case$ir_complete))
})

test_that("GEOM-01 non-positive log rect bounds are censored before IR rendering", {
  plot <- ggplot(
    data.frame(
      xmin = c(-1, 10),
      xmax = c(10, 100),
      ymin = c(10, 100),
      ymax = c(20, 200)
    ),
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect(fill = "#6699cc", colour = "#2f3e46") +
    scale_x_log10() +
    scale_y_log10()

  case <- suppressWarnings(classify_rect_ir_case(plot))

  expect_true(any(!case$built_complete))
  expect_equal(case$ir_complete, case$built_complete)
  expect_equal(unname(is.na(as.matrix(case$built[, rect_bounds]))), unname(ir_bound_na_matrix(case$layer$data)))
  expect_equal(unname(ir_bound_value_matrix(case$layer$data)), unname(as.matrix(case$built[, rect_bounds])), tolerance = 1e-8)
})
