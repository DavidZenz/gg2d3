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

test_that("BVIS-01 browser visual smoke artifacts are generated for representative fixtures", {
  # Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate local browser artifacts.
  skip_browser_visual_smoke()

  fixtures <- .browser_visual_non_sf_fixtures()
  expect_equal(vapply(fixtures, `[[`, character(1), "id"), c(
    "cartesian-point-line-text",
    "cartesian-bars-rects",
    "facet-wrap-points",
    "interactivity-point-brush-tooltip",
    "ordinary-polygon"
  ))
})
