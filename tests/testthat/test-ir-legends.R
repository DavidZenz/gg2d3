test_that("extract_legends_ir returns position right by default", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_equal(L$position, "right")
})

test_that("extract_legends_ir produces a guide for discrete colour aesthetic", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_true(length(L$guides) >= 1L)
  titles <- vapply(L$guides, function(g) g$title, character(1))
  expect_true("factor(cyl)" %in% titles)
})

test_that("extract_legends_ir respects theme(legend.position = 'none')", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() + theme(legend.position = "none")
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_equal(L$position, "none")
  expect_equal(length(L$guides), 0L)
})

test_that("extract_legends_ir output equals as_d3_ir guides slice for a discrete-colour point plot", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  ir <- as_d3_ir(p)
  b  <- ggplot_build(p)
  L  <- extract_legends_ir(b, p)
  expect_equal(ir$guides, L$guides)
  expect_equal(ir$legend$position, L$position)
})

test_that("extract_legends_ir handles a plot with no legend-eligible aesthetic", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  L <- extract_legends_ir(b, p)
  expect_equal(length(L$guides), 0L)
})
