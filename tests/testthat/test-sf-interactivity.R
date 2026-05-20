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

test_that("tooltip module sanitizes sf renderer internals", {
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(tooltip_js, "sanitizeTooltipDatum")
  expect_match(tooltip_js, "startsWith\\('_'\\)")
  expect_match(tooltip_js, "d = sanitizeTooltipDatum\\(d\\)")
  expect_match(tooltip_js, "customFn\\(enriched\\)")
  private_fields <- c("_geom", "_centroid")
  expect_true(all(startsWith(private_fields, "_")))
})

test_that("brush module targets sf paths without dropping existing geoms", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "path\\.geom-sf")
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

test_that("brush module sanitizes sf callback data", {
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")

  expect_match(brush_js, "sanitizeSelectedDatum")
  expect_match(brush_js, "startsWith\\('_'\\)")
  expect_match(brush_js, "collectSelectedData")
  expect_match(brush_js, "sanitizeSelectedDatum\\(d\\)")
  private_fields <- c("_geom", "_centroid")
  expect_true(all(startsWith(private_fields, "_")))
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
