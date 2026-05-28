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
  candidates <- c(
    ".planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md",
    ".planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md"
  )
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    existing <- file.path("..", "..", candidates)[file.exists(file.path("..", "..", candidates))]
  }
  if (length(existing) == 0L) {
    stop("Could not find Phase 45 rect/tile classification notes", call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
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

test_that("GEOM-01 transformed rect boundary is classified at scale factory seam", {
  scales_js <- read_repo_file("inst/htmlwidgets/modules/scales.js")
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  expect_match(scales_js, "d3\\.scaleLog\\(\\)")
  expect_match(scales_js, "d3\\.scaleSqrt\\(\\)")
  expect_match(scales_js, "case \"reverse\"")

  expect_match(rect_js, "xScale\\(num\\(get\\(d, aes\\.xmin\\)\\)\\)")
  expect_match(rect_js, "xScale\\(num\\(get\\(d, aes\\.xmax\\)\\)\\)")
  expect_match(rect_js, "yScale\\(num\\(get\\(d, aes\\.ymin\\)\\)\\)")
  expect_match(rect_js, "yScale\\(num\\(get\\(d, aes\\.ymax\\)\\)\\)")

  expect_match(registry_js, "xScale\\(num\\(d\\.xmin\\)\\)")
  expect_match(registry_js, "xScale\\(num\\(d\\.xmax\\)\\)")
  expect_match(registry_js, "yScale\\(num\\(d\\.ymin\\)\\)")
  expect_match(registry_js, "yScale\\(num\\(d\\.ymax\\)\\)")
})

test_that("GEOM-01 rect render and update paths share direct transformed-bound scaling", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  rect_render <- source_block_after(rect_js, "function rectX")
  rect_update_helpers <- source_block_after(registry_js, "function rectX")
  next_section <- regexpr("geom_point", rect_update_helpers)
  expect_true(next_section[[1]] > 0)
  rect_update_helpers <- substr(rect_update_helpers, 1, next_section[[1]])

  expect_match(rect_render, "Math\\.min\\(xScale")
  expect_match(rect_render, "Math\\.abs\\(x2 - x1\\)")
  expect_match(rect_update_helpers, "Math\\.min\\(xScale")
  expect_match(rect_update_helpers, "Math\\.abs\\(xScale\\(num\\(d\\.xmax\\)\\) - xScale\\(num\\(d\\.xmin\\)\\)\\)")

  expect_false(grepl("untransform", rect_render, fixed = TRUE))
  expect_false(grepl("untransform", rect_update_helpers, fixed = TRUE))
})

test_that("GEOM-03 rect tile render and update paths share transformed-bound scaling", {
  scales_js <- read_repo_file("inst/htmlwidgets/modules/scales.js")
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  rect_render <- source_block_after(rect_js, "function rectX")
  rect_update_helpers <- source_block_after(registry_js, "function rectX")
  next_section <- regexpr("geom_point", rect_update_helpers)
  expect_true(next_section[[1]] > 0)
  rect_update_helpers <- substr(rect_update_helpers, 1, next_section[[1]])

  expect_match(scales_js, "d3\\.scaleLog\\(\\)")
  expect_match(scales_js, "d3\\.scaleSqrt\\(\\)")
  expect_match(scales_js, "case \"reverse\"")

  expect_match(rect_render, "Math\\.min\\(xScale")
  expect_match(rect_render, "Math\\.min\\(yScale")
  expect_match(rect_render, "Math\\.abs\\(x2 - x1\\)")
  expect_match(rect_render, "Math\\.abs\\(y2 - y1\\)")
  expect_match(rect_update_helpers, "Math\\.min\\(xScale")
  expect_match(rect_update_helpers, "Math\\.min\\(yScale")
  expect_match(rect_update_helpers, "Math\\.abs\\(xScale\\(num\\(d\\.xmax\\)\\) - xScale\\(num\\(d\\.xmin\\)\\)\\)")
  expect_match(rect_update_helpers, "Math\\.abs\\(yScale\\(num\\(d\\.ymax\\)\\) - yScale\\(num\\(d\\.ymin\\)\\)\\)")

  expect_false(grepl("untransform", rect_render, fixed = TRUE))
  expect_false(grepl("untransform", rect_update_helpers, fixed = TRUE))
  expect_false(grepl("invert(", rect_render, fixed = TRUE))
  expect_false(grepl("invert(", rect_update_helpers, fixed = TRUE))
})

test_that("GEOM-03 rect tile transformed bounds avoid malformed DOM attributes", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  filter_start <- regexpr("const rects = dat\\.filter", rect_js)
  expect_true(filter_start[[1]] > 0)
  filter_block <- substr(rect_js, filter_start[[1]], filter_start[[1]] + 520)

  expect_match(filter_block, "validRectBounds")
  expect_match(filter_block, "scaledRectBoundsAreFinite")
  expect_match(filter_block, "Number\\.isFinite")
  expect_match(filter_block, "xScale")
  expect_match(filter_block, "yScale")
  expect_match(rect_js, "\\.attr\\(\"x\", d => rectX\\(d\\)\\)")
  expect_match(rect_js, "\\.attr\\(\"y\", d => rectY\\(d\\)\\)")
  expect_match(rect_js, "\\.attr\\(\"width\", d => rectWidth\\(d\\)\\)")
  expect_match(rect_js, "\\.attr\\(\"height\", d => rectHeight\\(d\\)\\)")
})

test_that("Phase 45 does not require browser smoke for rect/tile closure", {
  notes <- classification_notes()

  expect_false(grepl("browser-required", notes, fixed = TRUE))
  expect_match(notes, "Browser smoke: not required")
})
