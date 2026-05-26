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
