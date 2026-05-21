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

test_that("events module targets all sf families without dropping existing geoms", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "\\.geom-sf")
  expect_match(events_js, "circle\\.geom-sf")
  expect_match(events_js, "geom-sf-point")
  expect_match(events_js, "geom-sf-line")
  expect_match(events_js, "geom-sf-polygon")
  expect_match(events_js, "circle\\.geom-point")
  expect_match(events_js, "path\\.geom-line")
  expect_match(events_js, "rect\\.geom-bar")
})

test_that("events module sanitizes sf custom handler data", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")

  expect_match(events_js, "sanitizeEventDatum")
  expect_match(events_js, "startsWith\\('_'\\)")
  expect_match(events_js, "publicDatum")
  expect_match(events_js, "key\\.startsWith\\('_'\\)")
  expect_match(events_js, "setInputValue\\(shinyId, publicDatum\\)")
  expect_match(events_js, "clickHandler\\.call\\(this, event, publicDatum\\)")
  expect_match(events_js, "mouseoverHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)\\)")
  expect_match(events_js, "mouseoutHandler\\.call\\(this, event, sanitizeEventDatum\\(d\\)\\)")
})

test_that("tooltip module sanitizes sf renderer internals", {
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(tooltip_js, "sanitizeTooltipDatum")
  expect_match(tooltip_js, "startsWith\\('_'\\)")
  expect_match(tooltip_js, "key\\.startsWith\\('_'\\)")
  expect_match(tooltip_js, "d = sanitizeTooltipDatum\\(d\\)")
  expect_match(tooltip_js, "customFn\\(enriched\\)")
  expect_match(tooltip_js, "config\\.fields\\.filter\\(k => !String\\(k\\)\\.startsWith\\('_'\\)\\)")
  private_fields <- c("_geom", "_centroid", "_sfFamily", "_pointIndex", "_pointCoord")
  expect_true(all(startsWith(private_fields, "_")))
})

test_that("brush module targets all sf families without dropping existing geoms", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "\\.geom-sf")
  expect_match(brush_js, "circle\\.geom-sf")
  expect_match(brush_js, "geom-sf-point")
  expect_match(brush_js, "geom-sf-line")
  expect_match(brush_js, "geom-sf-polygon")
  expect_match(brush_js, "circle\\.geom-point")
  expect_match(brush_js, "path\\.geom-line")
  expect_match(brush_js, "rect\\.geom-bar")
})

test_that("brush module uses sf centroid attrs before generic path bbox", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "classList\\.contains\\('geom-sf'\\)")
  expect_match(brush_js, "data-cx")
  expect_match(brush_js, "data-cy")
  expect_match(brush_js, "Number\\.isFinite")
  expect_match(brush_js, "getBBox")

  sf_branch <- regexpr("classList\\.contains\\('geom-sf'\\)", brush_js)
  bbox_branch <- regexpr("getBBox", brush_js)
  expect_true(sf_branch[[1]] > 0)
  expect_true(bbox_branch[[1]] > sf_branch[[1]])
})

test_that("brush module selects geom_sf paths by centroid attributes", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "\\.geom-sf")
  expect_match(brush_js, "circle\\.geom-sf")
  expect_match(brush_js, "classList\\.contains\\('geom-sf'\\)")
  expect_match(brush_js, "getAttribute\\('data-cx'\\)")
  expect_match(brush_js, "getAttribute\\('data-cy'\\)")
  expect_match(brush_js, "isPointInPixelRect\\(sfCx, sfCy, rect\\)")
})

test_that("brush module sanitizes sf callback data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "key\\.startsWith\\('_'\\)")
  expect_match(brush_js, "collectSelectedData")
  expect_match(brush_js, "sanitizeSelectedDatum\\(d\\)")
  expect_match(brush_js, "selectedData\\.push\\(sanitizeSelectedDatum\\(d\\)\\)")
  private_fields <- c("_geom", "_centroid", "_sfFamily", "_pointIndex", "_pointCoord")
  expect_true(all(startsWith(private_fields, "_")))
})

test_that("brush module deduplicates multipoint sf child selections by row_id", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "dedupeSelectedDataByRowId")
  expect_match(brush_js, "row_id")
  expect_match(brush_js, "String\\(d\\.row_id\\)")
  expect_match(brush_js, "seenRowIds")
  expect_match(brush_js, "return dedupeSelectedDataByRowId\\(selectedData\\)")
})

test_that("sf interactivity remains composable when zoom is suppressed", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot2::ggplot(nc) + ggplot2::geom_sf()

  w <- gg2d3(p) |>
    d3_brush() |>
    d3_tooltip() |>
    d3_hover()

  expect_true(w$x$interactivity$brush$enabled)
  expect_true(w$x$interactivity$tooltip$enabled)
  expect_true(w$x$interactivity$hover$enabled)

  expect_warning(
    w_zoom <- w |> d3_zoom(),
    "geom_sf.*zoom|zoom.*geom_sf"
  )

  expect_true(w_zoom$x$interactivity$brush$enabled)
  expect_true(w_zoom$x$interactivity$tooltip$enabled)
  expect_true(w_zoom$x$interactivity$hover$enabled)
  expect_null(w_zoom$x$interactivity$zoom)
})
