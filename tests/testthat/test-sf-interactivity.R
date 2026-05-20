read_module <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  resolved <- candidates[file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

test_that("sf renderer exposes path row and centroid attributes", {
  sf_js <- read_module("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "path\\.geom-sf")
  expect_match(sf_js, "geom-sf")
  expect_match(sf_js, "data-row-id")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "reflectY\\(true\\)")
  expect_match(sf_js, "Number\\.isFinite")
})

test_that("events module targets sf paths without dropping existing geoms", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "path\\.geom-sf")
  expect_match(events_js, "circle\\.geom-point")
  expect_match(events_js, "path\\.geom-line")
  expect_match(events_js, "rect\\.geom-bar")
})
