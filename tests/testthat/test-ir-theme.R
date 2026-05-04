# Real assertions for R/ir_theme.R: extract_theme_ir + calc_element_safe.
# (Replaces the Plan 01 stub.)

test_that("extract_theme_ir returns the expected top-level structure", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  th <- extract_theme_ir(b)
  expect_false(is.null(th))
  expect_true(all(c("panel", "plot", "grid", "axis", "text", "legend", "strip") %in% names(th)))
  expect_false(is.null(th$panel$background))
})

test_that("extract_theme_ir output matches the v1.0 as_d3_ir theme slice", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  expect_equal(ir$theme, extract_theme_ir(b))
})

test_that("calc_element_safe Tier 1 succeeds for a vanilla theme without warning", {
  .gg2d3_reset_calc_element_warned()
  library(ggplot2)
  expect_silent(res <- calc_element_safe("panel.background", theme_grey()))
  expect_false(.gg2d3_pkgenv$calc_element_warned)
  expect_false(is.null(res))
})

test_that("calc_element_safe falls back and warns once on Tier 1 failure", {
  .gg2d3_reset_calc_element_warned()
  # ggplot2:::calc_element returns NULL silently for unknown element names; to
  # actually trigger the Tier 1 error path we pass a non-theme value, which
  # raises an indexing error inside ggplot2:::calc_element.
  expect_warning(
    calc_element_safe("panel.background", "not a theme"),
    regexp = "ggplot2:::calc_element\\(\\) failed"
  )
  # warn-once: subsequent calls are silent even when they also fall back.
  expect_silent(calc_element_safe("panel.background", "still not a theme"))
})

test_that("calc_element_safe static defaults match documented values", {
  expect_identical(.gg2d3_calc_element_default("legend.position"), "right")
  expect_identical(.gg2d3_calc_element_default("legend.key.size"), grid::unit(1.2, "lines"))
  expect_identical(.gg2d3_calc_element_default("panel.spacing"),  grid::unit(5.5, "pt"))
  expect_null(.gg2d3_calc_element_default("anything.else"))
})
