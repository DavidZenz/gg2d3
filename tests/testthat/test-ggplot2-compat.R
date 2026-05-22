if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

test_that("HARD-02 gg2d3_plot_theme resolves plot theme", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::theme(legend.position = "bottom")

  theme <- gg2d3_plot_theme(p)

  expect_false(is.null(theme))
  expect_equal(gg2d3_calc_element("legend.position", theme, default = "right"), "bottom")
})

test_that("HARD-02 gg2d3_calc_element returns fallback on missing element", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  theme <- gg2d3_plot_theme(p)

  expect_equal(gg2d3_calc_element("not.a.real.element", theme, default = "fallback"), "fallback")
  expect_equal(gg2d3_calc_element("legend.position", NULL, default = "right"), "right")
})

test_that("HARD-02 gg2d3_panel_axis extracts displayed axes", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::coord_flip()
  panel_params <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]

  expect_false(is.null(gg2d3_panel_axis(panel_params, "x")))
  expect_false(is.null(gg2d3_panel_axis(panel_params, "y")))
  expect_null(gg2d3_panel_axis(panel_params, "z"))
})

test_that("HARD-02 gg2d3_continuous_range reads expanded range", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  panel_axis <- gg2d3_panel_axis(ggplot2::ggplot_build(p)$layout$panel_params[[1]], "x")

  continuous_range <- gg2d3_continuous_range(panel_axis)

  expect_type(continuous_range, "double")
  expect_length(continuous_range, 2L)
})

test_that("HARD-02 gg2d3_panel_labels returns character labels", {
  discrete_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
    ggplot2::geom_boxplot()
  discrete_axis <- gg2d3_panel_axis(
    ggplot2::ggplot_build(discrete_plot)$layout$panel_params[[1]],
    "x"
  )

  date_plot <- ggplot2::ggplot(
    data.frame(date = as.Date(c("2024-01-01", "2024-02-01")), y = c(1, 2)),
    ggplot2::aes(date, y)
  ) +
    ggplot2::geom_point()
  date_axis <- gg2d3_panel_axis(ggplot2::ggplot_build(date_plot)$layout$panel_params[[1]], "x")

  discrete_labels <- gg2d3_panel_labels(discrete_axis)
  date_labels <- gg2d3_panel_labels(date_axis)

  expect_type(discrete_labels, "character")
  expect_true(all(c("4", "6", "8") %in% discrete_labels))
  expect_type(date_labels, "character")
  expect_true(length(date_labels) > 0)
})
