# Regression: zoom updates path-based geoms by calling
# `selection.attr('d', d => generator(d))`. This requires each path to have its
# datum bound via `.datum(pts)` at render time. Without the binding, `d` is
# undefined and the path silently stays in its original position when the user
# zooms or pans (observed during Phase 19 pkgdown vignette).
#
# We assert source-level that every path-geom render binds its data, so the bug
# can't silently re-emerge.

path_geoms <- list(
  list(file = "line.js",    class = "geom-line"),
  list(file = "area.js",    class = "geom-area"),
  list(file = "density.js", class = "geom-density"),
  list(file = "density.js", class = "geom-density-outline"),
  list(file = "ribbon.js",  class = "geom-ribbon"),
  list(file = "polygon.js", class = "geom-polygon"),
  list(file = "smooth.js",  class = "geom-smooth"),
  list(file = "smooth.js",  class = "geom-smooth-ribbon")
)

geoms_dir <- system.file("htmlwidgets", "modules", "geoms", package = "gg2d3")
if (!nzchar(geoms_dir)) {
  geoms_dir <- normalizePath(file.path("..", "..", "inst", "htmlwidgets",
                                       "modules", "geoms"))
}

for (entry in path_geoms) {
  local({
    e <- entry
    test_that(paste0("path geom '", e$class, "' binds datum for zoom updates"), {
      src <- readLines(file.path(geoms_dir, e$file), warn = FALSE)
      # Find the line that sets the class attribute for this geom
      class_re <- paste0("\"class\",\\s*\"", e$class, "\"")
      class_idx <- grep(class_re, src)
      expect_true(length(class_idx) >= 1,
                  info = paste0("class attribute for ", e$class, " not found"))
      # Look in a small window above for `.datum(`
      for (i in class_idx) {
        window <- src[max(1, i - 6):i]
        expect_true(any(grepl("\\.datum\\(", window)),
                    info = paste0(e$class, " path appended without .datum(); ",
                                  "zoom/pan will not transform this geom"))
      }
    })
  })
}

test_that("polygon path geom stores private point datum for closed zoom updates", {
  src <- readLines(file.path(geoms_dir, "polygon.js"), warn = FALSE)
  expect_true(any(grepl('"geom-polygon"', src, fixed = TRUE)),
              info = "polygon.js must render path.geom-polygon")
  expect_true(any(grepl("_polygonPoints", src, fixed = TRUE)),
              info = "polygon.js must store source points for zoom updates")
})
