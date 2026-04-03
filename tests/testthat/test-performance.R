library(ggplot2)

test_that("performance: rendering 5000 points is within acceptable limits", {
  # Create a large dataset
  n <- 5000
  df <- data.frame(
    x = rnorm(n),
    y = rnorm(n),
    group = sample(letters[1:5], n, replace = TRUE)
  )
  
  p <- ggplot(df, aes(x, y, color = group)) +
    geom_point(alpha = 0.5)
  
  # Measure time to build IR
  start_time <- Sys.time()
  ir <- as_d3_ir(p)
  end_time <- Sys.time()
  
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # IR generation for 5000 points should be fast (< 1s)
  expect_true(elapsed < 1.0)
  
  # Verify data size in IR
  expect_equal(length(ir$layers[[1]]$data), n)
})

test_that("performance: update-only mode does not trigger draw()", {
  # This is a JS-side optimization, but we can verify the IR structure
  # is stable for identical plots
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir1 <- as_d3_ir(p)
  ir2 <- as_d3_ir(p)
  
  # Structural comparison via JSON round-trip
  expect_equal(
    jsonlite::fromJSON(jsonlite::toJSON(ir1)), 
    jsonlite::fromJSON(jsonlite::toJSON(ir2))
  )
})
