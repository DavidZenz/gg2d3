# Phase 14 colour-fidelity test helpers.
# See .planning/phases/14-color-fidelity/14-RESEARCH.md "Pipeline map" for
# why these are the right extraction points.
#
# testthat auto-sources helper-*.R before any test file, so functions defined
# here are in scope across the test suite. They are intentionally NOT exported
# via NAMESPACE — helper-*.R lives only in tests/testthat/.

`%||%` <- function(a, b) if (is.null(a)) b else a

# Resolved per-row colour column from ggplot_build (source of truth, D-04).
build_colours <- function(p, layer_index = 1L) {
  b <- ggplot2::ggplot_build(p)
  b$data[[layer_index]]$colour
}

build_fills <- function(p, layer_index = 1L) {
  b <- ggplot2::ggplot_build(p)
  b$data[[layer_index]]$fill
}

# Per-row colours/fills as carried in the IR layer data.
ir_layer_colours <- function(p, layer_index = 1L) {
  ir <- as_d3_ir(p)
  vapply(ir$layers[[layer_index]]$data, function(row) row$colour %||% NA_character_, character(1))
}

ir_layer_fills <- function(p, layer_index = 1L) {
  ir <- as_d3_ir(p)
  vapply(ir$layers[[layer_index]]$data, function(row) row$fill %||% NA_character_, character(1))
}

# Find the IR guide for a given aesthetic.
guide_by_aes <- function(p, aes_name) {
  ir <- as_d3_ir(p)
  for (g in ir$guides) {
    if (identical(g$aesthetic, aes_name)) return(g)
    if (is.list(g$aesthetics) && aes_name %in% unlist(g$aesthetics)) return(g)
  }
  NULL
}

# Extract the ggplot2 scale object for a given aesthetic from a built plot.
scale_by_aes <- function(p, aes_name) {
  b <- ggplot2::ggplot_build(p)
  b$plot$scales$get_scales(aes_name)
}

# Reference legend hex from the ggplot2 scale object — what the colorbar
# stops *should* be (D-04).
scale_reference_breaks <- function(scale_obj) {
  limits <- scale_obj$get_limits()
  scale_obj$get_breaks(limits)
}

scale_reference_labels <- function(scale_obj, breaks = NULL) {
  if (is.null(breaks)) breaks <- scale_reference_breaks(scale_obj)
  scale_obj$get_labels(breaks)
}
