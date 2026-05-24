read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

test_that("POLY-03 interaction selector modules target ordinary polygon paths", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
  crosstalk_js <- read_module("inst/htmlwidgets/modules/crosstalk.js")

  expect_match(events_js, "path\\.geom-polygon")
  expect_match(brush_js, "path\\.geom-polygon")
  expect_match(crosstalk_js, "path\\.geom-polygon")

  expect_match(events_js, "circle\\.geom-point")
  expect_match(events_js, "path\\.geom-line")
  expect_match(brush_js, "rect\\.geom-bar")
  expect_match(crosstalk_js, "rect\\.geom-rect")
})

test_that("POLY-03 events module sanitizes polygon callback data", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "startsWith\\('_'\\)")
  expect_match(events_js, "key\\.startsWith\\('_'\\)")
  expect_match(events_js, "publicDatum")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
  expect_match(events_js, "setInputValue\\(shinyId, publicDatum\\)")
  expect_match(events_js, "mouseoverHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)\\)")
  expect_match(events_js, "mouseoutHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)\\)")
  expect_match(events_js, "compileEventHandler")
  expect_match(events_js, "return \\(")
  expect_false(grepl("_polygonPoints", events_js, fixed = TRUE))
})

test_that("POLY-03 brush module keeps polygons on generic path bbox branch", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "key\\.startsWith\\('_'\\)")
  expect_match(brush_js, "selectedData\\.push\\(sanitizeSelectedDatum\\(d\\)\\)")
  expect_match(brush_js, "getBBox")
  expect_match(brush_js, "data-cx")
  expect_match(brush_js, "data-cy")

  polygon_lines <- grep("geom-polygon", strsplit(brush_js, "\n", fixed = TRUE)[[1]], value = TRUE)
  expect_true(length(polygon_lines) > 0)
  expect_false(any(grepl("data-cx|data-cy|classList\\.contains\\('geom-sf'\\)", polygon_lines)))

  sf_branch <- regexpr("classList\\.contains\\('geom-sf'\\)", brush_js)
  bbox_branch <- regexpr("getBBox", brush_js)
  expect_true(sf_branch[[1]] > 0)
  expect_true(bbox_branch[[1]] > sf_branch[[1]])
})

test_that("POLY-03 tooltip module strips polygon renderer-private fields", {
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(tooltip_js, "sanitizeTooltipDatum")
  expect_match(tooltip_js, "startsWith\\('_'\\)")
  expect_match(tooltip_js, "key\\.startsWith\\('_'\\)")
  expect_match(tooltip_js, "d = sanitizeTooltipDatum\\(d\\)")
  expect_match(tooltip_js, "config\\.fields\\.filter\\(k => !String\\(k\\)\\.startsWith\\('_'\\)\\)")
  expect_false(grepl("_polygonPoints", tooltip_js, fixed = TRUE))
})

test_that("POLY-03 polygon renderer keeps private points underscore-prefixed only", {
  polygon_js <- read_module("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(polygon_js, "_polygonPoints")
  expect_match(polygon_js, "publicRow\\._polygonPoints")
  expect_match(polygon_js, "_sourceIndex")
  expect_match(polygon_js, "publicRow\\._sourceIndex")
  expect_match(polygon_js, "sourceIndex")
  expect_match(polygon_js, "\\.datum\\(publicRow\\)")
  expect_false(grepl("polygonPoints", gsub("_polygonPoints", "", polygon_js), fixed = TRUE))
})

test_that("POLY-03 crosstalk keys use representative polygon source indices", {
  gg2d3_js <- read_module("inst/htmlwidgets/gg2d3.js")
  crosstalk_js <- read_module("inst/htmlwidgets/modules/crosstalk.js")
  polygon_js <- read_module("inst/htmlwidgets/modules/geoms/polygon.js")

  expect_match(gg2d3_js, "indexedLayerData")
  expect_match(gg2d3_js, "_sourceIndex: i")
  expect_match(gg2d3_js, "indexedLayerData\\.filter\\(function\\(d\\)")
  expect_match(crosstalk_js, "crosstalkKeyIndex")
  expect_match(crosstalk_js, "d\\._sourceIndex")
  expect_match(crosstalk_js, "Number\\.isFinite\\(sourceIndex\\)")
  expect_match(crosstalk_js, "keyArray\\[rowIndex\\]")
  expect_match(polygon_js, "dat\\.map\\(\\(d, sourceIndex\\)")
  expect_match(polygon_js, "existingIndex")
  expect_match(polygon_js, "publicRow\\._sourceIndex = pts\\[0\\]\\.sourceIndex")
})

test_that("POLY-03 callback paths do not expose polygon private points literally", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  callback_sources <- paste(events_js, brush_js, sep = "\n")
  expect_false(grepl("_polygonPoints", callback_sources, fixed = TRUE))
  expect_match(callback_sources, "sanitizeEventDatum|sanitizeSelectedDatum")
})
