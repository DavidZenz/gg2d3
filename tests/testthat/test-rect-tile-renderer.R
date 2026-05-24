read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

source_block_after <- function(source, marker) {
  start <- regexpr(marker, source)
  expect_true(start[[1]] > 0)
  substr(source, start[[1]], nchar(source))
}

classification_notes <- function() {
  read_repo_file(".planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md")
}

rect_source_contract_terms <- c(
  "register(['rect', 'tile']",
  "rect.geom-rect",
  "bandwidth",
  "options.flip",
  "Math.abs",
  "geom-registry",
  "width",
  "height"
)

test_that("RECT-01 rect renderer module registers rect and tile aliases", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  expect_true(all(nzchar(rect_source_contract_terms)))
  expect_match(rect_js, "function renderRect")
  expect_match(rect_js, "geomRegistry\\.register\\(\\['rect', 'tile'\\]")
  expect_match(rect_js, "rect\\.geom-rect|geom-rect")
})

test_that("RECT-01 rect renderer filters rows missing any required bound", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  filter_start <- regexpr("const rects = dat\\.filter", rect_js)
  expect_true(filter_start[[1]] > 0)
  filter_block <- substr(rect_js, filter_start[[1]], filter_start[[1]] + 260)

  expect_match(filter_block, "aes\\.xmin")
  expect_match(filter_block, "aes\\.xmax")
  expect_match(filter_block, "aes\\.ymin")
  expect_match(filter_block, "aes\\.ymax")
  expect_match(filter_block, "!= null")
})

test_that("RECT-01 rect renderer handles band scales, coord flip, and continuous dimensions", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  expect_match(rect_js, "bandwidth")
  expect_match(rect_js, "options\\.flip")
  expect_match(rect_js, "isXBand")
  expect_match(rect_js, "isYBand")
  expect_match(rect_js, "Math\\.abs")
  expect_match(rect_js, "function rectX")
  expect_match(rect_js, "function rectY")
  expect_match(rect_js, "Math\\.min\\(xScale\\(num\\(get\\(d, aes\\.xmin\\)\\)\\)")
  expect_match(rect_js, "Math\\.min\\(yScale\\(num\\(get\\(d, aes\\.ymin\\)\\)\\)")
})

test_that("RECT-02 rect renderer uses registry fill, stroke, linewidth, and opacity accessors", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  expect_match(registry_js, "return \\{ strokeColor, fillColor, opacity \\}")
  expect_match(rect_js, "makeColorAccessors")
  expect_match(rect_js, "fillColor")
  expect_match(rect_js, "strokeColor")
  expect_match(rect_js, "\\.attr\\(\"stroke\"")
  expect_match(rect_js, "\\.attr\\(\"stroke-width\"")
  expect_match(rect_js, "mmToPxLinewidth")
  expect_match(rect_js, "rectStroke")
  expect_match(rect_js, "rectLinewidth")
  expect_match(rect_js, "opacity")
})

test_that("RECT-02 rect renderer uses band centers for categorical tile positioning", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  expect_match(rect_js, "function bandValue")
  expect_match(rect_js, "isXBand\\) return xScale\\(bandValue\\(d, aes\\.x, aes\\.xmin\\)\\)")
  expect_match(rect_js, "isYBand\\) return yScale\\(bandValue\\(d, aes\\.y, aes\\.ymin\\)\\)")
  expect_match(rect_js, "if \\(isXBand\\) return xScale\\.bandwidth\\(\\)")
  expect_match(rect_js, "if \\(isYBand\\) return yScale\\.bandwidth\\(\\)")
})

test_that("RECT-01 rect update path targets rect.geom-rect and updates geometry", {
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  rect_update <- source_block_after(registry_js, "geom_rect / geom_tile")

  expect_match(rect_update, "rect\\.geom-rect")
  expect_match(rect_update, "\\.attr\\('x'")
  expect_match(rect_update, "\\.attr\\('y'")
  expect_match(rect_update, "\\.attr\\('width'")
  expect_match(rect_update, "\\.attr\\('height'")
  expect_match(rect_update, "Math\\.min")
  expect_match(rect_update, "Math\\.abs")
})

test_that("RECT-02 rect update path is band and flip safe", {
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  rect_update <- source_block_after(registry_js, "geom_rect / geom_tile")
  next_section <- regexpr("geom_text", rect_update)
  expect_true(next_section[[1]] > 0)
  rect_update <- substr(rect_update, 1, next_section[[1]])

  has_band_safe_logic <- grepl("bandwidth", registry_js, fixed = TRUE)
  has_explicit_flip_branch <- grepl("if (flip)", rect_update, fixed = TRUE)

  expect_true(has_band_safe_logic)
  expect_true(has_explicit_flip_branch)
  expect_match(registry_js, "function rectX")
  expect_match(registry_js, "function flippedRectX")
  expect_match(registry_js, "xScale\\(bandValue\\(d, 'x', 'xmin'\\)\\)")
  expect_match(registry_js, "yScale\\(bandValue\\(d, 'y', 'ymin'\\)\\)")
  expect_match(rect_update, "rect\\.geom-rect")
  expect_match(rect_update, "flippedRectWidth")
  expect_match(rect_update, "rectHeight")
})
