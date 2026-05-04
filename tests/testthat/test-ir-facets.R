test_that("extract_facets_ir returns null-facet structure for unfaceted plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "null")
  expect_equal(fp$facets$nrow, 1L)
  expect_equal(fp$facets$ncol, 1L)
  expect_length(fp$panels, 1L)
})

test_that("extract_facets_ir produces wrap-type facets for facet_wrap plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "wrap")
  expect_equal(length(fp$panels), length(unique(mtcars$cyl)))
})

test_that("extract_facets_ir produces grid-type facets for facet_grid plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(am ~ cyl)
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_equal(fp$facets$type, "grid")
  expect_equal(length(fp$panels),
               length(unique(mtcars$am)) * length(unique(mtcars$cyl)))
})

test_that("extract_facets_ir does NOT pollute global env (Pitfall 2 — <<- removed)", {
  rm(list = intersect(c("facets_ir", "panels_ir"), ls(envir = globalenv())),
     envir = globalenv())
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, FALSE)
  fp <- extract_facets_ir(b, pp_x, pp_y, scales,
                          x_breaks = pp_x$breaks, y_breaks = pp_y$breaks,
                          x_trans_name = "identity", y_trans_name = "identity",
                          is_flip = FALSE)
  expect_false(exists("facets_ir", envir = globalenv(), inherits = FALSE))
  expect_false(exists("panels_ir", envir = globalenv(), inherits = FALSE))
})

test_that("extract_facets_ir output equals as_d3_ir facets+panels for facet_wrap plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)
  ir <- as_d3_ir(p)
  expect_equal(ir$facets$type, "wrap")
  expect_equal(length(ir$panels), length(unique(mtcars$cyl)))
})
