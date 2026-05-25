if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

test_that("SFANN-03 sf annotation marks use existing geom-sf interaction selectors", {
  sf_js <- read_module("inst/htmlwidgets/modules/geoms/sf.js")
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
  crosstalk_js <- read_module("inst/htmlwidgets/modules/crosstalk.js")

  expect_match(sf_js, "geom-sf-text")
  expect_match(sf_js, "geom-sf-label")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "data-row-id")

  expect_match(events_js, "\\.geom-sf")
  expect_match(brush_js, "\\.geom-sf")
  expect_match(crosstalk_js, "\\.geom-sf")
})

test_that("SFANN-03 brush uses sf annotation anchor coordinates and sanitizes selection data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "classList\\.contains\\('geom-sf'\\)")
  expect_match(brush_js, "getAttribute\\('data-cx'\\)")
  expect_match(brush_js, "getAttribute\\('data-cy'\\)")
  expect_match(brush_js, "isPointInPixelRect\\(sfCx, sfCy, rect\\)")
  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "dedupeSelectedDataByRowId")
  expect_match(brush_js, "selectedData\\.push\\(sanitizeSelectedDatum\\(d\\)\\)")
  expect_match(brush_js, "key\\.startsWith\\('_'\\)")
})

test_that("SFANN-03 events and tooltip expose public annotation payloads only", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "publicDatum")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
  expect_match(events_js, "setInputValue\\(shinyId, publicDatum\\)")
  expect_match(events_js, "key\\.startsWith\\('_'\\)")

  expect_match(tooltip_js, "sanitizeTooltipDatum")
  expect_match(tooltip_js, "key\\.startsWith\\('_'\\)")
  expect_match(tooltip_js, "config\\.fields\\.filter\\(k => !String\\(k\\)\\.startsWith\\('_'\\)\\)")
})

test_that("SFANN-03 private sf annotation fields remain sanitizer-compatible", {
  private_fields <- c("_geom", "_centroid", "_sfFamily", "_sfAnchor", "_pointCoord", "_pointIndex")
  sf_js <- read_module("inst/htmlwidgets/modules/geoms/sf.js")

  expect_true(all(startsWith(private_fields, "_")))
  expect_match(sf_js, "_geom")
  expect_match(sf_js, "_centroid")
  expect_match(sf_js, "_sfFamily")
  expect_match(sf_js, "_sfAnchor")
})
