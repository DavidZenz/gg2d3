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

  # Note: the orchestrator-scope aesthetic vector and the outer dead-code
  # row-izer were removed in Plan 13-04. The canonical row-izer lives in
  # R/ir_utils.R and is invoked from R/ir_layers.R.

  # Extract scale objects early (needed for mapping discrete values, axis
  # labels, legends, and facets blocks below). The scales-slice assembly
  # is delegated to R/ir_scales.R::extract_scales_ir; map_discrete is now
  # a top-level internal in R/ir_scales.R and is called bare below.
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # extract_theme_element / extract_theme_ir / calc_element_safe live in
  # R/ir_theme.R (Phase 13 internals refactor). The orchestrator now delegates
  # the entire theme slice via extract_theme_ir(b) below.

  # Layers slice (geom dispatch + per-layer data + aes mapping + temporal conv)
  # delegated to R/ir_layers.R::extract_layers_ir. The orchestrator no longer
  # owns the discrete-mapping pre-pass, the geom-name switch, or the
  # temporal-column conversion — all live in the extractor.
  layers <- extract_layers_ir(b, xscale_obj, yscale_obj)

  # Detect coord_flip early (needed for panel_params alignment)
  is_flip_early <- inherits(b$plot$coordinates, "CoordFlip")

  # Extract grid breaks from panel params
  # NOTE: coord_flip swaps panel_params (x<->y) but NOT panel_scales or data.
  # We un-swap panel_params here to realign with the original scale objects.
  if (is_flip_early) {
    pp_x <- b$layout$panel_params[[1]]$y  # un-swap: original x is in y after flip
    pp_y <- b$layout$panel_params[[1]]$x  # un-swap: original y is in x after flip
  } else {
    pp_x <- b$layout$panel_params[[1]]$x
    pp_y <- b$layout$panel_params[[1]]$y
  }

  # Scales slice (x, y, optional color) — delegated to R/ir_scales.R.
  # The orchestrator owns the pp_x / pp_y un-swap above; everything else
  # (breaks, temporal multipliers, log validation, color domain) lives in
  # extract_scales_ir. xscale_obj / yscale_obj remain in scope for the
  # axis-labels, legends, and facets blocks below until those plans land.
  scales <- extract_scales_ir(b, pp_x, pp_y, is_flip = is_flip_early)

  # Compatibility shims for the not-yet-extracted facets block (Plan 06)
  # and the single-panel fallback in the panels_ir assembly. These reach
  # straight into `scales$<axis>$breaks` (already temporal-converted by
  # extract_scales_ir) and the scale objects' trans names, so the facets
  # block can keep its local temporal-conversion logic until Plan 06.
  x_breaks <- scales$x$breaks
  y_breaks <- scales$y$breaks
  x_trans_name <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
  y_trans_name <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL

  # Extract theme information (delegated to R/ir_theme.R::extract_theme_ir)
  theme_ir <- extract_theme_ir(b)

  # Coord detection: CoordFlip, CoordFixed, or default CoordCartesian

  is_flip  <- inherits(b$plot$coordinates, "CoordFlip")
  is_fixed <- inherits(b$plot$coordinates, "CoordFixed")

  coord_type  <- if (is_flip) "flip" else if (is_fixed) "fixed" else "cartesian"
  coord_ratio <- if (is_fixed) (b$plot$coordinates$ratio %||% 1) else NULL

  # Axis labels: swap for coord_flip so x-aesthetic title goes to left visual axis

  if (is_flip) {
    x_label <- b$plot$labels$y %||% ""
    y_label <- b$plot$labels$x %||% ""
  } else {
    x_label <- b$plot$labels$x %||% ""
    y_label <- b$plot$labels$y %||% ""
  }

  # Extract axis tick labels as strings for JS layout text measurement
  # Use the un-swapped panel_params (pp_x, pp_y) already computed above
  x_tick_labels <- tryCatch({
    labs <- pp_x$get_labels()
    labs <- labs[!is.na(labs)]
    as.character(labs)
  }, error = function(e) character(0))

  y_tick_labels <- tryCatch({
    labs <- pp_y$get_labels()
    labs <- labs[!is.na(labs)]
    as.character(labs)
  }, error = function(e) character(0))

  # Detect secondary axes (Phase 6 reserves space, future phases render)
  has_sec_x <- tryCatch({
    sec <- b$layout$panel_scales_x[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  has_sec_y <- tryCatch({
    sec <- b$layout$panel_scales_y[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  # Legend extraction (position + guides) delegated to R/ir_legends.R.
  # extract_legends_ir uses the public ggplot2 guide-data API for per-aesthetic
  # guide data and routes legend.position resolution through calc_element_safe.
  legends <- extract_legends_ir(b, p)
  legend_position <- legends$position
  guides_ir       <- legends$guides

  # Extract subtitle and caption from plot labels
  subtitle_text <- b$plot$labels$subtitle %||% ""
  caption_text <- b$plot$labels$caption %||% ""

  # Legend + strip theme elements are now part of extract_theme_ir(b) above.

  # Facets slice (FacetWrap / FacetGrid / null) — delegated to R/ir_facets.R.
  # Returns list(facets, panels). The v1.0 tryCatch error handler used `<<-`
  # to write into this frame; the extractor now uses an explicit `return`
  # from the error handler (RESEARCH Pitfall 2).
  fp <- extract_facets_ir(
    b, pp_x, pp_y, scales,
    x_breaks, y_breaks,
    x_trans_name, y_trans_name,
    is_flip = is_flip_early
  )
  facets_ir <- fp$facets
  panels_ir <- fp$panels

  ir <- list(
    width = width, height = height, padding = padding,
    coord  = list(type = coord_type, flip = is_flip, ratio = coord_ratio),
    title  = b$plot$labels$title %||% "",
    subtitle = subtitle_text,
    caption = caption_text,
    axes   = list(
      x = list(orientation = "bottom", label = x_label, tickLabels = x_tick_labels),
      y = list(orientation = "left",  label = y_label, tickLabels = y_tick_labels),
      x2 = if (has_sec_x) list(enabled = TRUE) else NULL,
      y2 = if (has_sec_y) list(enabled = TRUE) else NULL
    ),
    facets = facets_ir,
    panels = panels_ir,
    scales = scales,
    layers = layers,
    guides = guides_ir,
    legend = list(enabled = TRUE, position = legend_position),
    theme = theme_ir
  )

  # Validate IR structure before returning
  validate_ir(ir)
}
