# Opt-in browser visual smoke artifact generation.

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_visual_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-visual.R",
    "helper-browser-visual.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

library(ggplot2)

.browser_visual_expected <- function(...) {
  c(...)
}

.browser_visual_mtcars <- function() {
  dat <- mtcars[order(mtcars$wt), ]
  dat$model <- rownames(dat)
  dat
}

.browser_visual_polygon_data <- function() {
  data.frame(
    group = rep(c("alpha", "beta"), each = 4),
    vertex = rep(1:4, 2),
    x = c(0, 2, 1.6, 0.2, 3, 5, 4.6, 3.2),
    y = c(0, 0.3, 1.8, 1.4, 1, 1.3, 2.8, 2.4)
  )
}

.browser_visual_non_sf_fixtures <- function() {
  mt <- .browser_visual_mtcars()
  bars <- data.frame(
    x = c("A", "B", "C"),
    y = c(1.2, 2.4, 1.7),
    group = c("one", "two", "one")
  )

  list(
    list(
      id = "cartesian-point-line-text",
      category = "cartesian",
      widget = gg2d3(
        ggplot(mt, aes(wt, mpg)) +
          geom_line(colour = "#4062BB") +
          geom_point(aes(colour = factor(cyl)), size = 2) +
          geom_text(
            data = head(mt, 3),
            aes(label = model),
            nudge_y = 1,
            size = 2.5
          )
      ),
      expected = .browser_visual_expected(
        "circle.geom-point" = 1,
        "path.geom-line" = 1,
        "text.geom-text" = 1
      )
    ),
    list(
      id = "cartesian-bars-rects",
      category = "cartesian",
      widget = gg2d3(
        ggplot(bars, aes(x, y)) +
          geom_col(aes(fill = group)) +
          geom_rect(
            data = data.frame(xmin = 0.6, xmax = 1.4, ymin = 0.5, ymax = 1.5),
            inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = NA,
            colour = "#D1495B"
          )
      ),
      expected = .browser_visual_expected(
        "rect.geom-bar" = 1,
        "rect.geom-rect" = 1
      )
    ),
    list(
      id = "facet-wrap-points",
      category = "facets",
      widget = gg2d3(
        ggplot(mt, aes(wt, mpg)) +
          geom_point() +
          facet_wrap(~ cyl)
      ),
      expected = .browser_visual_expected(
        ".panel" = 3,
        "circle.geom-point" = 1
      )
    ),
    list(
      id = "interactivity-point-brush-tooltip",
      category = "interactivity",
      widget = gg2d3(
        ggplot(mt, aes(wt, mpg)) +
          geom_point(aes(colour = factor(cyl)), size = 2)
      ) |>
        d3_tooltip() |>
        d3_hover() |>
        d3_brush(on_brush = "window.__gg2d3_visual_brush = selectedData;") |>
        d3_handlers(click = "function(event, d) { window.__gg2d3_visual_click = d; }"),
      expected = .browser_visual_expected(
        "circle.geom-point" = 1
      )
    ),
    list(
      id = "ordinary-polygon",
      category = "polygon",
      widget = gg2d3(
        ggplot(.browser_visual_polygon_data(), aes(x, y, group = group, fill = group)) +
          geom_polygon(colour = "#283618", linewidth = 0.7, alpha = 0.8)
      ),
      expected = .browser_visual_expected(
        "path.geom-polygon" = 2
      )
    )
  )
}

.browser_visual_sf_skip_rows <- function(ids, deps) {
  lapply(ids, function(id) {
    list(
      id = id,
      category = if (grepl("^sf-annotations", id)) "sf-annotations" else "sf",
      status = "skipped",
      html = "",
      screenshot = "",
      dom_summary = "",
      browser_log = "",
      skip_reason = deps$message,
      error = NULL
    )
  })
}

.browser_visual_sf_matrix <- function() {
  sf_ids <- c(
    "sf-polygon-point-line",
    "sf-facet-wrap",
    "sf-annotations-text-label",
    "sf-annotations-skipped-row"
  )
  deps <- browser_visual_optional_dependencies(require_sf = TRUE, require_geojsonsf = TRUE)
  if (!isTRUE(deps$available)) {
    return(list(fixtures = list(), skipped = .browser_visual_sf_skip_rows(sf_ids, deps)))
  }

  square <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
    matrix(
      c(xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax, xmin, ymin),
      ncol = 2,
      byrow = TRUE
    )
  }

  polygon_sf <- sf::st_sf(
    kind = "polygon",
    geometry = sf::st_sfc(sf::st_polygon(list(square())), crs = 4326)
  )
  point_sf <- sf::st_sf(
    kind = "point",
    geometry = sf::st_sfc(sf::st_point(c(2, 2)), crs = 4326)
  )
  line_sf <- sf::st_sf(
    kind = "line",
    geometry = sf::st_sfc(sf::st_linestring(matrix(c(3, 0, 4, 1, 5, 0), ncol = 2, byrow = TRUE)), crs = 4326)
  )

  facet_point <- sf::st_sf(
    facet = factor("A", levels = c("A", "B", "C")),
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
  )
  facet_line <- sf::st_sf(
    facet = factor("B", levels = c("A", "B", "C")),
    geometry = sf::st_sfc(sf::st_linestring(matrix(c(1, 0, 2, 1), ncol = 2, byrow = TRUE)), crs = 4326)
  )

  annotation_text <- sf::st_sf(
    label = "text",
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
  )
  annotation_label <- sf::st_sf(
    label = "label",
    geometry = sf::st_sfc(sf::st_linestring(matrix(c(1, 0, 2, 1, 3, 0), ncol = 2, byrow = TRUE)), crs = 4326)
  )
  skipped_annotation <- sf::st_sf(
    label = c("ok", "skip"),
    # GEOMETRYCOLLECTION is intentionally unsupported and should produce a skipped-row warning.
    geometry = sf::st_sfc(
      sf::st_point(c(0, 0)),
      sf::st_geometrycollection(list(sf::st_point(c(10, 10)))),
      crs = 4326
    )
  )

  skipped_widget <- testthat::expect_warning(
    gg2d3(
      ggplot(skipped_annotation, aes(label = label)) +
        geom_sf_text()
    ),
    regexp = "skipped"
  )

  list(
    fixtures = list(
      list(
        id = "sf-polygon-point-line",
        category = "sf",
        widget = gg2d3(
          ggplot() +
            geom_sf(data = polygon_sf, fill = "#B3D4FC") +
            geom_sf(data = point_sf, colour = "#D1495B") +
            geom_sf(data = line_sf, colour = "#4062BB")
        ),
        expected = .browser_visual_expected(
          ".geom-sf" = 3,
          ".geom-sf-polygon" = 1,
          ".geom-sf-point" = 1,
          ".geom-sf-line" = 1
        )
      ),
      list(
        id = "sf-facet-wrap",
        category = "sf",
        widget = gg2d3(
          ggplot() +
            geom_sf(data = facet_point) +
            geom_sf(data = facet_line) +
            facet_wrap(~ facet, drop = FALSE)
        ),
        expected = .browser_visual_expected(
          ".panel" = 3,
          ".geom-sf" = 2
        )
      ),
      list(
        id = "sf-annotations-text-label",
        category = "sf-annotations",
        widget = gg2d3(
          ggplot() +
            geom_sf_text(data = annotation_text, aes(label = label)) +
            geom_sf_label(data = annotation_label, aes(label = label), fill = "white")
        ),
        expected = .browser_visual_expected(
          "text.geom-sf.geom-sf-text" = 1,
          "g.geom-sf.geom-sf-label" = 1,
          ".geom-sf" = 2
        )
      ),
      list(
        id = "sf-annotations-skipped-row",
        category = "sf-annotations",
        widget = skipped_widget,
        expected = .browser_visual_expected(
          "text.geom-sf.geom-sf-text" = 1
        )
      )
    ),
    skipped = list()
  )
}

.browser_visual_log_slice <- function(logs, start) {
  entries <- browser_visual_logs(logs)
  if (length(entries) <= start) {
    return(list())
  }
  entries[(start + 1L):length(entries)]
}

test_that("BVIS-01 browser visual smoke artifacts are generated for representative fixtures", {
  # Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate local browser artifacts.
  skip_browser_visual_smoke()

  non_sf_fixtures <- .browser_visual_non_sf_fixtures()
  expect_equal(vapply(non_sf_fixtures, `[[`, character(1), "id"), c(
    "cartesian-point-line-text",
    "cartesian-bars-rects",
    "facet-wrap-points",
    "interactivity-point-brush-tooltip",
    "ordinary-polygon"
  ))

  sf_matrix <- .browser_visual_sf_matrix()
  fixtures <- c(non_sf_fixtures, sf_matrix$fixtures)
  rows <- sf_matrix$skipped

  rows <- with_chromote_session({
    logs <- browser_visual_console_collector(session)
    captured_rows <- rows

    for (fixture in fixtures) {
      log_start <- length(browser_visual_logs(logs))
      fixture$logs <- function() .browser_visual_log_slice(logs, log_start)
      captured_rows <- c(captured_rows, list(capture_browser_visual_fixture(session, fixture)))
    }

    captured_rows
  }, width = 960, height = 720)

  validate_browser_visual_rows(rows)
  index <- write_browser_visual_index(rows)
  # Report artifacts are test_output/browser-visual-smoke/index.html and index.json.
  expect_true(file.exists(index$html))
  expect_true(file.exists(index$json))

  index_data <- jsonlite::read_json(index$json, simplifyVector = TRUE)
  expect_true("generated_at" %in% names(index_data))
  expect_true("metadata" %in% names(index_data))
  expect_true("rows" %in% names(index_data))
  expect_equal(index_data$metadata$browser_visual_smoke, "true")

  non_skipped <- rows[vapply(rows, function(row) !identical(row$status, "skipped"), logical(1))]
  for (row in non_skipped) {
    expect_equal(row$status, "passed", info = row$error %||% row$id)
    expect_true(nzchar(row$html))
    expect_true(nzchar(row$screenshot))
    expect_true(nzchar(row$dom_summary))
    expect_true(nzchar(row$browser_log))
    expect_true(file.exists(row$html))
    expect_true(file.exists(row$screenshot))
    expect_true(file.exists(row$dom_summary))
    expect_true(file.exists(row$browser_log))
  }

  # Full artifact command:
  # NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
})
