#' Build a D3-ready IR (intermediate representation) from a ggplot
#' @export
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)

  # Detect coord_trans (not yet supported - Phase 3)
  if (inherits(b$plot$coordinates, "CoordTrans")) {
    warning(
      "coord_trans() is not yet supported by gg2d3. ",
      "Scale transformations (e.g., scale_x_log10()) provide equivalent visual output ",
      "for most cases. coord_trans() support is planned for Phase 3.",
      call. = FALSE
    )
  }

  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Coord detection (CoordFlip / CoordFixed / default CoordCartesian).
  is_flip     <- inherits(b$plot$coordinates, "CoordFlip")
  is_fixed    <- inherits(b$plot$coordinates, "CoordFixed")
  coord_type  <- if (is_flip) "flip" else if (is_fixed) "fixed" else "cartesian"
  coord_ratio <- if (is_fixed) (b$plot$coordinates$ratio %||% 1) else NULL

  # Scale objects: needed by extract_layers_ir (discrete mapping) and to read
  # trans names for the facets extractor's per-panel temporal conversion.
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # Layers slice (delegated to R/ir_layers.R).
  layers <- extract_layers_ir(b, xscale_obj, yscale_obj)

  # Un-swap panel_params for coord_flip: coord_flip swaps panel_params (x<->y)
  # but NOT panel_scales or data, so realign with original scale objects.
  if (is_flip) {
    pp_x <- b$layout$panel_params[[1]]$y
    pp_y <- b$layout$panel_params[[1]]$x
  } else {
    pp_x <- b$layout$panel_params[[1]]$x
    pp_y <- b$layout$panel_params[[1]]$y
  }

  # Scales slice (delegated to R/ir_scales.R).
  scales <- extract_scales_ir(b, pp_x, pp_y, is_flip = is_flip)

  # Theme slice (delegated to R/ir_theme.R).
  theme_ir <- extract_theme_ir(b)

  # Axis labels: swap for coord_flip so x-aesthetic title goes to left visual axis.
  if (is_flip) {
    x_label <- b$plot$labels$y %||% ""
    y_label <- b$plot$labels$x %||% ""
  } else {
    x_label <- b$plot$labels$x %||% ""
    y_label <- b$plot$labels$y %||% ""
  }

  # Axis tick labels as strings for JS layout text measurement (uses un-swapped pp).
  x_tick_labels <- tryCatch({
    labs <- pp_x$get_labels()
    as.character(labs[!is.na(labs)])
  }, error = function(e) character(0))

  y_tick_labels <- tryCatch({
    labs <- pp_y$get_labels()
    as.character(labs[!is.na(labs)])
  }, error = function(e) character(0))

  # Detect secondary axes (Phase 6 reserves space, future phases render).
  has_sec_x <- tryCatch({
    sec <- b$layout$panel_scales_x[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  has_sec_y <- tryCatch({
    sec <- b$layout$panel_scales_y[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  # Legends slice (delegated to R/ir_legends.R).
  legends         <- extract_legends_ir(b, p)
  legend_position <- legends$position
  guides_ir       <- legends$guides

  # Facets slice (delegated to R/ir_facets.R). The extractor still needs the
  # already-temporal-converted top-level breaks plus the trans names so it can
  # apply the same conversion to per-panel breaks pulled from panel_params.
  fp <- extract_facets_ir(
    b, pp_x, pp_y, scales,
    x_breaks     = scales$x$breaks,
    y_breaks     = scales$y$breaks,
    x_trans_name = if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL,
    y_trans_name = if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL,
    is_flip      = is_flip
  )

  ir <- list(
    width = width, height = height, padding = padding,
    coord  = list(type = coord_type, flip = is_flip, ratio = coord_ratio),
    title    = b$plot$labels$title    %||% "",
    subtitle = b$plot$labels$subtitle %||% "",
    caption  = b$plot$labels$caption  %||% "",
    axes   = list(
      x  = list(orientation = "bottom", label = x_label, tickLabels = x_tick_labels),
      y  = list(orientation = "left",   label = y_label, tickLabels = y_tick_labels),
      x2 = if (has_sec_x) list(enabled = TRUE) else NULL,
      y2 = if (has_sec_y) list(enabled = TRUE) else NULL
    ),
    facets = fp$facets,
    panels = fp$panels,
    scales = scales,
    layers = layers,
    guides = guides_ir,
    legend = list(enabled = TRUE, position = legend_position),
    theme  = theme_ir
  )

  validate_ir(ir)
}
