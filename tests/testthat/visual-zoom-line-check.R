library(ggplot2)
pkgload::load_all(quiet = TRUE)

# Regression check for zoom-on-line bug: scrolling/panning must transform the
# line path together with the axes. Mixed with point/bar to verify those geoms
# (which use .data() binding) are not regressed.

cases <- list(
  list(
    file = "zoom_line.html",
    title = "geom_line + d3_zoom",
    widget = local({
      p <- ggplot(economics, aes(date, unemploy)) + geom_line() +
        labs(title = "geom_line + d3_zoom",
             subtitle = "Scroll-wheel zoom and drag-pan must move the line WITH the axes")
      gg2d3(p) |> d3_zoom()
    })
  ),
  list(
    file = "zoom_line_point.html",
    title = "geom_line + geom_point + d3_zoom",
    widget = local({
      p <- ggplot(economics[seq(1, nrow(economics), by = 12), ],
                  aes(date, unemploy)) +
        geom_line() + geom_point(size = 1) +
        labs(title = "geom_line + geom_point + d3_zoom",
             subtitle = "Line and points must stay aligned through zoom/pan")
      gg2d3(p) |> d3_zoom()
    })
  ),
  list(
    file = "zoom_area.html",
    title = "geom_area + d3_zoom",
    widget = local({
      p <- ggplot(economics, aes(date, unemploy)) + geom_area(alpha = 0.5) +
        labs(title = "geom_area + d3_zoom",
             subtitle = "Filled area must reshape together with the axes")
      gg2d3(p) |> d3_zoom()
    })
  ),
  list(
    file = "zoom_smooth.html",
    title = "geom_smooth + geom_point + d3_zoom",
    widget = local({
      p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() +
        geom_smooth(method = "loess", formula = y ~ x) +
        labs(title = "geom_smooth + geom_point + d3_zoom",
             subtitle = "Smooth line, its ribbon, and points must all transform together")
      gg2d3(p) |> d3_zoom()
    })
  ),
  list(
    file = "zoom_xonly.html",
    title = "geom_line + d3_zoom(direction = 'x')",
    widget = local({
      p <- ggplot(economics, aes(date, unemploy)) + geom_line() +
        labs(title = "geom_line + d3_zoom(direction = 'x')",
             subtitle = "X-axis only zoom; line must reshape horizontally")
      gg2d3(p) |> d3_zoom(direction = "x")
    })
  )
)

dir.create("test_output", showWarnings = FALSE)

for (c in cases) {
  htmlwidgets::saveWidget(c$widget, file.path("test_output", c$file),
                          selfcontained = TRUE)
}

index <- paste0(
  "<!doctype html><meta charset='utf-8'>",
  "<title>Zoom-on-path-geom Regression Check</title>",
  "<style>body{font-family:system-ui;max-width:720px;margin:2em auto;padding:0 1em}",
  "li{margin:.5em 0}</style>",
  "<h1>Zoom-on-path-geom Regression Check</h1>",
  "<p>For each plot: scroll-wheel to zoom, drag to pan. All marks ",
  "(line, area, ribbon, points) must transform together with the axes. ",
  "Double-click to reset.</p><ul>",
  paste(vapply(cases, function(c) {
    sprintf("<li><a href='%s'>%s</a></li>", c$file, c$title)
  }, character(1)), collapse = ""),
  "</ul>"
)
writeLines(index, "test_output/test_zoom_line.html")
message("Saved visual check index to: test_output/test_zoom_line.html")
