test_that("as_d3_ir builds layers with data", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_true(length(ir$layers) >= 1)
  expect_true(length(ir$layers[[1]]$data) >= 1)
  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$y$type, "continuous")
})
