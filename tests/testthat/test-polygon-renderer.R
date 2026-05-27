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

test_that("POLY-02 polygon paths participate in path update plumbing", {
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  update_start <- regexpr("Closed path geoms \\(polygon\\)", registry_js)
  expect_true(update_start[[1]] > 0)
  update_block <- substr(registry_js, update_start[[1]], nchar(registry_js))

  expect_match(update_block, "path\\.geom-polygon")
  expect_match(update_block, "_polygonPoints")
  expect_match(update_block, "curveLinearClosed")
})

test_that("GEOM-02 polygon renderer filters invalid points and skips too-small groups", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(polygon_js, "function isValidPoint")
  expect_match(polygon_js, "Number\\.isFinite\\(p\\.x\\)")
  expect_match(polygon_js, "Number\\.isFinite\\(p\\.y\\)")
  expect_match(polygon_js, "\\.filter\\(isValidPoint\\)")
  expect_match(polygon_js, "if \\(pts\\.length < 3\\) return")
})

test_that("GEOM-02 ordinary polygon renderer does not claim topology repair", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_false(grepl("subgroup", polygon_js, fixed = TRUE))
  expect_false(grepl("fill-rule", polygon_js, fixed = TRUE))
  expect_false(grepl("evenodd", polygon_js, fixed = TRUE))
  expect_false(grepl("topology", polygon_js, fixed = TRUE))
  expect_false(grepl("repair", polygon_js, fixed = TRUE))
  expect_false(grepl("intersect", polygon_js, fixed = TRUE))
})
