# Regression test for facet free-scale y-axis label placement.
#
# Bug: with facet_wrap(~..., scales = "free"), each non-leftmost panel renders
# its own y-axis, but layout.js did not widen the inter-column gap to reserve
# room for those labels. They overflowed leftward into the previous panel.
#
# Fix: layout.js computeFreeAxisExtras() widens colSpacing by tickLength + max
# y-tick-label width + 4px when scales is "free"/"free_y" (and rowSpacing
# symmetrically for free_x). The widened gap must hold regardless of whether
# a secondary axis is present.
#
# This test invokes layout.js via V8 and asserts the inter-column gap exceeds
# the base spacing by at least the predicted tick-label width.

test_that("facet_wrap(scales='free') reserves inter-column gap for per-panel y-axes", {
  skip_if_not_installed("V8")
  ctx <- V8::v8()

  # Minimal globals layout.js expects: gg2d3.constants.ptToPx and a window stub.
  ctx$eval("var window = { gg2d3: { constants: { ptToPx: function(p) { return p * (96/72); } } } };")
  layout_js <- system.file("htmlwidgets/modules/layout.js", package = "gg2d3")
  if (!nzchar(layout_js)) layout_js <- testthat::test_path("..", "..", "inst", "htmlwidgets", "modules", "layout.js")
  ctx$source(layout_js)
  # The IIFE attached calculateLayout to window.gg2d3.layout.
  ctx$eval("var calculateLayout = window.gg2d3.layout.calculateLayout;")

  make_config <- function(scales) {
    list(
      width = 800, height = 600,
      # theme is set in JS below (V8 cannot serialize R closures).
      theme = NULL,
      titles = list(title = NULL, subtitle = NULL, caption = NULL),
      axes = list(
        x = list(label = "x", tickLabels = c("2", "4", "6")),
        y = list(label = "y", tickLabels = c("10", "20", "30"))
      ),
      legend = list(position = "none"),
      coord = list(type = "cartesian", flip = FALSE),
      facets = list(
        type = "wrap", nrow = 1L, ncol = 3L,
        layout = list(
          list(PANEL = 1L, ROW = 1L, COL = 1L),
          list(PANEL = 2L, ROW = 1L, COL = 2L),
          list(PANEL = 3L, ROW = 1L, COL = 3L)
        ),
        strips = list(list(level = 1L, labels = list(
          list(PANEL = 1L, label = "a"),
          list(PANEL = 2L, label = "b"),
          list(PANEL = 3L, label = "c")
        ))),
        scales = scales,
        spacing = 7.3
      ),
      panels = list(
        list(PANEL = 1L, x_range = c(0, 10), y_range = c(0, 100), y_breaks = c(0, 50, 100)),
        list(PANEL = 2L, x_range = c(0, 10), y_range = c(0, 10000), y_breaks = c(0, 5000, 10000)),
        list(PANEL = 3L, x_range = c(0, 10), y_range = c(0, 1),    y_breaks = c(0, 0.5, 1))
      )
    )
  }

  ctx$assign("cfgFixed", make_config("fixed"))
  ctx$assign("cfgFree",  make_config("free"))
  # layout.js expects theme to have a .get() method; attach one in JS.
  ctx$eval("cfgFixed.theme = { get: function() { return null; } };")
  ctx$eval("cfgFree.theme  = { get: function() { return null; } };")
  ctx$eval("var resFixed = calculateLayout(cfgFixed); var resFree = calculateLayout(cfgFree);")

  fixed_panels <- ctx$get("resFixed.panels")
  free_panels  <- ctx$get("resFree.panels")

  # Inter-column gap = panel[N+1].x - (panel[N].x + panel[N].w)
  gap_fixed <- fixed_panels$x[2] - (fixed_panels$x[1] + fixed_panels$w[1])
  gap_free  <- free_panels$x[2]  - (free_panels$x[1]  + free_panels$w[1])

  # Fixed-scales gap should match the base spacing (~7.3).
  expect_equal(round(gap_fixed, 1), 7.3)

  # Free-scales gap must be substantially larger to fit per-panel y labels.
  # The widest label in panel 2 is "10000" (~5 chars) — even at the smallest
  # axis text size that needs >15px extra room beyond tick length and padding.
  expect_gt(gap_free - gap_fixed, 15)
})
