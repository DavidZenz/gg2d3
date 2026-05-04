# Theme extraction for the ggplot2 -> D3 IR pipeline.
#
# This file owns the calc_element chokepoint (REFACTOR-02). It is the ONLY
# place in R/ that may reference the ggplot2 private calc_element entry point;
# all other extractors call `calc_element_safe()` instead.
# See .planning/phases/13-internals-refactor/.
#
# All functions are package-internal (no @export). Namespaced calls are used
# in lieu of @importFrom directives, matching the style of R/as_d3_ir.R.

#' Safe calc_element wrapper with three-tier fallback chain.
#'
#' Tier 1: the ggplot2 private calc_element entry (preserves v1.0 behavior exactly).
#' Tier 2: ggplot2::theme_get() + theme then ggplot2::calc_element (public API,
#'         exported in ggplot2 4.0.3).
#' Tier 3: A small static-default table for the elements we actually depend on.
#'
#' Emits exactly one warning per session on any fallback (Tier 2 or Tier 3),
#' gated by `.gg2d3_pkgenv$calc_element_warned`.
#'
#' @keywords internal
#' @noRd
calc_element_safe <- function(element_name, theme) {
  # Tier 1: existing private path (preserves v1.0 behavior exactly).
  result <- tryCatch(
    ggplot2:::calc_element(element_name, theme),
    error = function(e) e
  )
  if (!inherits(result, "error")) return(result)

  # Tier 2: public exported API.
  result <- tryCatch({
    complete <- ggplot2::theme_get() + theme
    ggplot2::calc_element(element_name, complete)
  }, error = function(e) e)
  if (!inherits(result, "error")) {
    .gg2d3_warn_once(element_name, "public-API path")
    return(result)
  }

  # Tier 3: static default.
  default <- .gg2d3_calc_element_default(element_name)
  .gg2d3_warn_once(element_name, "static default")
  default
}

#' Emit at most one warning per R session about a calc_element fallback.
#'
#' Reads/writes `.gg2d3_pkgenv$calc_element_warned` (created in R/zzz.R).
#' Test code can reset the flag via `.gg2d3_reset_calc_element_warned()`.
#'
#' @keywords internal
#' @noRd
.gg2d3_warn_once <- function(element_name, path) {
  if (isTRUE(.gg2d3_pkgenv$calc_element_warned)) return(invisible())
  .gg2d3_pkgenv$calc_element_warned <- TRUE
  warning(sprintf(
    "gg2d3: ggplot2:::calc_element() failed for '%s'; using %s. ggplot2 version: %s. Further occurrences this session will be silent.",
    element_name, path, as.character(utils::packageVersion("ggplot2"))
  ), call. = FALSE)
}

#' Static fallback values for the theme elements gg2d3 actually consumes.
#'
#' These mirror the ggplot2 defaults used at the call sites (legend.position
#' defaults to "right", legend.key.size to unit(1.2, "lines"), panel.spacing
#' to unit(5.5, "pt")). Returns NULL for any unrecognized element.
#'
#' @keywords internal
#' @noRd
.gg2d3_calc_element_default <- function(element_name) {
  switch(element_name,
    legend.position = "right",
    legend.key.size = grid::unit(1.2, "lines"),
    panel.spacing  = grid::unit(5.5, "pt"),
    NULL
  )
}

#' Extract a single theme element as a plain list for JSON serialization.
#'
#' Lifted verbatim from R/as_d3_ir.R:73-141 (v1.0). The only edit is the
#' line-75-equivalent call: the ggplot2 private API -> `calc_element_safe`.
#' Linewidth conversion uses the CSS px-per-mm constant (3.7795275591); per
#' MEMORY.md this constant is incorrect for ggplot2 line elements, but it is
#' preserved here to match v1.0 output exactly. Correction is out of scope.
#'
#' @keywords internal
#' @noRd
extract_theme_element <- function(element_name, theme) {
  calc <- calc_element_safe(element_name, theme)

  if (is.null(calc)) {
    return(NULL)
  }

  if (inherits(calc, "element_blank")) {
    return(list(type = "blank"))
  }

  if (inherits(calc, "element_rect")) {
    # Convert linewidth from mm to pixels (1mm = 96/25.4 px at 96 DPI)
    linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

    return(list(
      type = "rect",
      fill = if (is.na(calc$fill)) NULL else calc$fill,
      colour = if (is.na(calc$colour)) NULL else calc$colour,
      linewidth = linewidth_px,
      linetype = calc$linetype
    ))
  }

  if (inherits(calc, "element_line")) {
    # Convert linewidth from mm to pixels (1mm = 96/25.4 px at 96 DPI)
    linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

    return(list(
      type = "line",
      colour = if (is.na(calc$colour)) NULL else calc$colour,
      linewidth = linewidth_px,
      linetype = calc$linetype,
      lineend = calc$lineend
    ))
  }

  if (inherits(calc, "element_text")) {
    return(list(
      type = "text",
      colour = if (is.na(calc$colour)) NULL else calc$colour,
      size = calc$size,
      face = calc$face,
      family = calc$family,
      hjust = calc$hjust,
      vjust = calc$vjust,
      angle = calc$angle
    ))
  }

  # Handle margin elements (plot.margin)
  if (inherits(calc, "margin")) {
    # Convert margin to pixels using grid::convertUnit
    # First convert to inches, then to pixels (96 DPI web standard)
    inches <- grid::convertUnit(calc, "inches", valueOnly = TRUE)
    pixels <- inches * 96

    return(list(
      type = "margin",
      top = pixels[1],
      right = pixels[2],
      bottom = pixels[3],
      left = pixels[4]
    ))
  }

  return(NULL)
}

#' Assemble the v1.0 theme slice of the IR from a ggplot_build object.
#'
#' Pure function. Returns NULL if `b$plot$theme` is NULL. Otherwise returns a
#' list with keys panel/plot/grid/axis/text/legend/strip, structurally
#' equivalent to the v1.0 `theme_ir` produced inline by R/as_d3_ir.R lines
#' 535-571 + 819-856.
#'
#' @keywords internal
#' @noRd
extract_theme_ir <- function(b) {
  if (is.null(b$plot$theme)) return(NULL)

  theme <- b$plot$theme

  # legend.key.size: produce pixels via grid::convertUnit; preserve v1.0 NULL-on-error.
  legend_key_size <- tryCatch({
    spacing <- calc_element_safe("legend.key.size", theme)
    if (!is.null(spacing)) {
      inches <- grid::convertUnit(spacing, "inches", valueOnly = TRUE)
      inches * 96  # Convert to pixels (96 DPI web standard)
    } else {
      NULL
    }
  }, error = function(e) NULL)

  list(
    panel = list(
      background = extract_theme_element("panel.background", theme),
      border     = extract_theme_element("panel.border",     theme)
    ),
    plot = list(
      background = extract_theme_element("plot.background", theme),
      margin     = extract_theme_element("plot.margin",     theme)
    ),
    grid = list(
      major = extract_theme_element("panel.grid.major", theme),
      minor = extract_theme_element("panel.grid.minor", theme)
    ),
    axis = list(
      line    = extract_theme_element("axis.line",    theme),
      line.x  = extract_theme_element("axis.line.x",  theme),
      line.y  = extract_theme_element("axis.line.y",  theme),
      text    = extract_theme_element("axis.text",    theme),
      text.x  = extract_theme_element("axis.text.x",  theme),
      text.y  = extract_theme_element("axis.text.y",  theme),
      title   = extract_theme_element("axis.title",   theme),
      title.x = extract_theme_element("axis.title.x", theme),
      title.y = extract_theme_element("axis.title.y", theme),
      ticks   = extract_theme_element("axis.ticks",   theme),
      ticks.x = extract_theme_element("axis.ticks.x", theme),
      ticks.y = extract_theme_element("axis.ticks.y", theme)
    ),
    text = list(
      title    = extract_theme_element("plot.title",    theme),
      subtitle = extract_theme_element("plot.subtitle", theme),
      caption  = extract_theme_element("plot.caption",  theme)
    ),
    legend = list(
      key.size   = legend_key_size,
      text       = extract_theme_element("legend.text",       theme),
      title      = extract_theme_element("legend.title",      theme),
      background = extract_theme_element("legend.background", theme),
      key        = extract_theme_element("legend.key",        theme)
    ),
    strip = list(
      text       = extract_theme_element("strip.text",       theme),
      background = extract_theme_element("strip.background", theme)
    )
  )
}
