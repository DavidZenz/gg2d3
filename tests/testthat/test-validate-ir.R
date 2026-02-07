test_that("validate_ir passes valid IR unchanged", {
  valid_ir <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_silent(validate_ir(valid_ir))
  result <- validate_ir(valid_ir)
  expect_identical(result, valid_ir)
})

test_that("validate_ir passes real ggplot IR", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)

  # Should not throw an error
  expect_silent(validate_ir(ir))
  result <- validate_ir(ir)
  expect_identical(result, ir)
})

test_that("validate_ir errors on missing scales", {
  invalid_ir <- list(
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "IR must contain a 'scales' element"
  )
})

test_that("validate_ir errors on missing layers", {
  invalid_ir <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "IR must contain a 'layers' element"
  )
})

test_that("validate_ir errors on non-list scales", {
  invalid_ir <- list(
    scales = "not a list",
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "'scales' must be a list"
  )
})

test_that("validate_ir errors on missing x scale", {
  invalid_ir <- list(
    scales = list(
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "scales must contain 'x' scale definition"
  )
})

test_that("validate_ir errors on missing y scale", {
  invalid_ir <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10))
    ),
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "scales must contain 'y' scale definition"
  )
})

test_that("validate_ir errors on layer missing geom", {
  invalid_ir <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "Layer 1 is missing required 'geom' element"
  )
})

test_that("validate_ir errors on non-character geom", {
  invalid_ir <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(geom = 123, data = list(), aes = list(), params = list())
    )
  )

  expect_error(
    validate_ir(invalid_ir),
    "Layer 1 'geom' must be a character string"
  )
})

test_that("validate_ir warns on layer with no data", {
  ir_no_data <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(geom = "point", data = list(), aes = list(), params = list())
    )
  )

  expect_warning(
    validate_ir(ir_no_data),
    "Layer 1 \\(geom='point'\\) has no data"
  )
})

test_that("validate_ir warns on unrecognized geom type", {
  ir_unknown <- list(
    scales = list(
      x = list(type = "continuous", domain = c(0, 10)),
      y = list(type = "continuous", domain = c(0, 100))
    ),
    layers = list(
      list(geom = "unknown_geom", data = list(list(x = 1, y = 2)), aes = list(), params = list())
    )
  )

  expect_warning(
    validate_ir(ir_unknown),
    "Layer 1 uses unrecognized geom type 'unknown_geom'"
  )
})

test_that("validate_ir accepts all known geom types", {
  known_geoms <- c("point", "line", "path", "bar", "col", "area", "text", "rect", "segment", "ribbon", "violin", "boxplot")

  for (geom_type in known_geoms) {
    ir <- list(
      scales = list(
        x = list(type = "continuous", domain = c(0, 10)),
        y = list(type = "continuous", domain = c(0, 100))
      ),
      layers = list(
        list(geom = geom_type, data = list(list(x = 1, y = 2)), aes = list(), params = list())
      )
    )

    expect_silent(validate_ir(ir))
  }
})
