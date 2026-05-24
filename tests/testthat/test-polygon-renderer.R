read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

test_that("POLY-02 polygon renderer module is bundled and registered", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")
  yaml <- read_repo_file("inst/htmlwidgets/gg2d3.yaml")

  expect_match(yaml, "geoms/polygon\\.js")
  expect_match(polygon_js, "function renderPolygon")
  expect_match(polygon_js, "geomRegistry\\.register\\(['\"]polygon['\"]")
  expect_match(polygon_js, "path\\.geom-polygon|geom-polygon")
})

test_that("POLY-02 polygon renderer groups rows into closed paths without sorting", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(polygon_js, "d3\\.group")
  expect_match(polygon_js, "curveLinearClosed|closePath")
  expect_match(polygon_js, "_polygonPoints")
  expect_match(polygon_js, "Number\\.isFinite")

  expect_false(grepl("pts.sort", polygon_js, fixed = TRUE))
  expect_false(grepl("d3.ascending", polygon_js, fixed = TRUE))
  expect_false(grepl('layer.geom === "line"', polygon_js, fixed = TRUE))
})

test_that("POLY-02 polygon renderer applies visible styling contract", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(polygon_js, "fill")
  expect_match(polygon_js, "stroke")
  expect_match(polygon_js, "stroke-width")
  expect_match(polygon_js, "stroke-dasharray")
  expect_match(polygon_js, "opacity")
  expect_match(polygon_js, "mmToPxLinewidth")
  expect_match(polygon_js, "getDashArray")
})

test_that("POLY-02 polygon renderer handles missing fill and stroke explicitly", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(polygon_js, "NA")
  expect_match(polygon_js, "null")
  expect_match(polygon_js, "Number\\.isNaN")
  expect_match(polygon_js, "fill.*none|none.*fill")
  expect_match(polygon_js, "stroke.*none|none.*stroke")
})
