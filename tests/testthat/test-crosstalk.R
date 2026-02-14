skip_if_not_installed("crosstalk")

test_that("gg2d3() detects SharedData", {
  library(ggplot2)
  library(crosstalk)

  # Create SharedData
  sd <- SharedData$new(mtcars, key = ~rownames(mtcars), group = "test_group")

  # Build ggplot from SharedData - ggplot needs to store the SharedData object
  # We need to manually keep the reference for detection
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  p$data <- sd  # Store SharedData object in ggplot

  # Create widget
  w <- gg2d3(p)

  # Verify crosstalk metadata is present
  expect_true(!is.null(w$x$crosstalk_key))
  expect_true(!is.null(w$x$crosstalk_group))
  expect_equal(w$x$crosstalk_group, "test_group")
})

test_that("gg2d3() works without SharedData", {
  library(ggplot2)

  # Regular ggplot with regular data frame
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p)

  # Verify no crosstalk metadata
  expect_null(w$x$crosstalk_key)
  expect_null(w$x$crosstalk_group)
})

test_that("gg2d3() extracts correct keys", {
  library(ggplot2)
  library(crosstalk)

  # Create SharedData with explicit keys
  sd <- SharedData$new(mtcars[1:5, ], key = ~rownames(mtcars[1:5, ]))
  p <- ggplot(mtcars[1:5, ], aes(x = wt, y = mpg)) + geom_point()
  p$data <- sd
  w <- gg2d3(p)

  # Verify keys match
  expect_equal(w$x$crosstalk_key, sd$key())
  expect_equal(length(w$x$crosstalk_key), 5)
})

test_that("gg2d3() extracts correct group", {
  library(ggplot2)
  library(crosstalk)

  # Create SharedData with named group
  sd <- SharedData$new(mtcars, group = "my_group")
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  p$data <- sd
  w <- gg2d3(p)

  # Verify group name matches
  expect_equal(w$x$crosstalk_group, sd$groupName())
  expect_equal(w$x$crosstalk_group, "my_group")
})

test_that("Crosstalk dependencies attached", {
  library(ggplot2)
  library(crosstalk)

  sd <- SharedData$new(mtcars)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  p$data <- sd
  w <- gg2d3(p)

  # Verify crosstalk dependencies are included
  expect_true(!is.null(w$dependencies))
  dep_names <- sapply(w$dependencies, function(d) d$name)
  expect_true("crosstalk" %in% dep_names)
})

test_that("Regular plots have no crosstalk dependencies", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  w <- gg2d3(p)

  # If dependencies exist, crosstalk should not be among them
  if (!is.null(w$dependencies)) {
    dep_names <- sapply(w$dependencies, function(d) d$name)
    expect_false("crosstalk" %in% dep_names)
  }
})

test_that("SharedData detection handles missing crosstalk package gracefully", {
  library(ggplot2)

  # Regular data frame (no SharedData)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  # Should not error even if checking for crosstalk
  expect_no_error({
    w <- gg2d3(p)
  })
})
