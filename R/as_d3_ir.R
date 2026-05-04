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

  # Extract facet metadata
  facets_ir <- NULL
  panels_ir <- NULL

  tryCatch({
    is_facet_wrap <- inherits(b$layout$facet, "FacetWrap")
    is_facet_grid <- inherits(b$layout$facet, "FacetGrid")

    if (is_facet_wrap) {
      # Extract facet_wrap metadata
      layout_df <- b$layout$layout
      facet_vars <- names(b$layout$facet$params$facets)

      # Determine scales mode for facet_wrap
      free_params <- b$layout$facet$params$free
      if (free_params$x && free_params$y) {
        scales_mode <- "free"
      } else if (free_params$x) {
        scales_mode <- "free_x"
      } else if (free_params$y) {
        scales_mode <- "free_y"
      } else {
        scales_mode <- "fixed"
      }

      # Extract strip labels
      strips <- lapply(seq_len(nrow(layout_df)), function(i) {
        label_parts <- vapply(facet_vars, function(v) {
          as.character(layout_df[[v]][i])
        }, character(1))
        list(
          PANEL = as.integer(layout_df$PANEL[i]),
          label = paste(label_parts, collapse = ", ")
        )
      })

      # Extract per-panel scale metadata
      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip_early) {
          ppx <- pp$y  # un-swap for coord_flip
          ppy <- pp$x
        } else {
          ppx <- pp$x
          ppy <- pp$y
        }
        panel_x_range <- unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])

        # Convert temporal panel values to milliseconds
        if (!is.null(x_trans_name) && x_trans_name == "date") {
          panel_x_range <- panel_x_range * 86400000
          panel_x_breaks <- panel_x_breaks * 86400000
        } else if (!is.null(x_trans_name) && x_trans_name == "time") {
          panel_x_range <- panel_x_range * 1000
          panel_x_breaks <- panel_x_breaks * 1000
        }
        if (!is.null(y_trans_name) && y_trans_name == "date") {
          panel_y_range <- panel_y_range * 86400000
          panel_y_breaks <- panel_y_breaks * 86400000
        } else if (!is.null(y_trans_name) && y_trans_name == "time") {
          panel_y_range <- panel_y_range * 1000
          panel_y_breaks <- panel_y_breaks * 1000
        }

        list(
          PANEL = as.integer(p),
          x_range = panel_x_range,
          y_range = panel_y_range,
          x_breaks = panel_x_breaks,
          y_breaks = panel_y_breaks
        )
      })

      # Extract panel.spacing
      panel_spacing <- tryCatch({
        spacing <- calc_element_safe("panel.spacing", b$plot$theme)
        if (!is.null(spacing)) {
          inches <- grid::convertUnit(spacing, "inches", valueOnly = TRUE)
          inches * 96  # pixels
        } else {
          7.3  # default 5.5pt in pixels
        }
      }, error = function(e) 7.3)

      # Build facets IR object
      facets_ir <- list(
        type = "wrap",
        vars = facet_vars,
        nrow = as.integer(max(layout_df$ROW)),
        ncol = as.integer(max(layout_df$COL)),
        scales = scales_mode,
        spacing = panel_spacing,
        layout = lapply(seq_len(nrow(layout_df)), function(i) {
          row <- as.list(layout_df[i, , drop = FALSE])
          row$PANEL <- as.integer(row$PANEL)
          row$ROW <- as.integer(row$ROW)
          row$COL <- as.integer(row$COL)
          row$SCALE_X <- as.integer(row$SCALE_X)
          row$SCALE_Y <- as.integer(row$SCALE_Y)
          row
        }),
        strips = strips
      )
    } else if (is_facet_grid) {
      # Extract facet_grid metadata
      layout_df <- b$layout$layout
      row_vars <- names(b$layout$facet$params$rows)
      col_vars <- names(b$layout$facet$params$cols)

      # Determine scales mode
      free_params <- b$layout$facet$params$free
      if (free_params$x && free_params$y) {
        scales_mode <- "free"
      } else if (free_params$x) {
        scales_mode <- "free_x"
      } else if (free_params$y) {
        scales_mode <- "free_y"
      } else {
        scales_mode <- "fixed"
      }

      # Extract row strips (one per unique ROW)
      row_strips <- NULL
      if (length(row_vars) > 0) {
        row_combos <- unique(layout_df[, c("ROW", row_vars), drop = FALSE])
        row_strips <- lapply(seq_len(nrow(row_combos)), function(i) {
          label_parts <- vapply(row_vars, function(v) {
            as.character(row_combos[[v]][i])
          }, character(1))
          list(
            ROW = as.integer(row_combos$ROW[i]),
            label = paste(label_parts, collapse = ", ")
          )
        })
      }

      # Extract column strips (one per unique COL)
      col_strips <- NULL
      if (length(col_vars) > 0) {
        col_combos <- unique(layout_df[, c("COL", col_vars), drop = FALSE])
        col_strips <- lapply(seq_len(nrow(col_combos)), function(i) {
          label_parts <- vapply(col_vars, function(v) {
            as.character(col_combos[[v]][i])
          }, character(1))
          list(
            COL = as.integer(col_combos$COL[i]),
            label = paste(label_parts, collapse = ", ")
          )
        })
      }

      # Extract per-panel scale metadata
      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip_early) {
          ppx <- pp$y  # un-swap for coord_flip
          ppy <- pp$x
        } else {
          ppx <- pp$x
          ppy <- pp$y
        }
        panel_x_range <- unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])

        # Convert temporal panel values to milliseconds
        if (!is.null(x_trans_name) && x_trans_name == "date") {
          panel_x_range <- panel_x_range * 86400000
          panel_x_breaks <- panel_x_breaks * 86400000
        } else if (!is.null(x_trans_name) && x_trans_name == "time") {
          panel_x_range <- panel_x_range * 1000
          panel_x_breaks <- panel_x_breaks * 1000
        }
        if (!is.null(y_trans_name) && y_trans_name == "date") {
          panel_y_range <- panel_y_range * 86400000
          panel_y_breaks <- panel_y_breaks * 86400000
        } else if (!is.null(y_trans_name) && y_trans_name == "time") {
          panel_y_range <- panel_y_range * 1000
          panel_y_breaks <- panel_y_breaks * 1000
        }

        list(
          PANEL = as.integer(p),
          x_range = panel_x_range,
          y_range = panel_y_range,
          x_breaks = panel_x_breaks,
          y_breaks = panel_y_breaks
        )
      })

      # Extract panel.spacing
      panel_spacing <- tryCatch({
        spacing <- calc_element_safe("panel.spacing", b$plot$theme)
        if (!is.null(spacing)) {
          inches <- grid::convertUnit(spacing, "inches", valueOnly = TRUE)
          inches * 96  # pixels
        } else {
          7.3  # default 5.5pt in pixels
        }
      }, error = function(e) 7.3)

      # Build facets IR object
      facets_ir <- list(
        type = "grid",
        rows = row_vars,
        cols = col_vars,
        scales = scales_mode,
        nrow = as.integer(max(layout_df$ROW)),
        ncol = as.integer(max(layout_df$COL)),
        spacing = panel_spacing,
        layout = lapply(seq_len(nrow(layout_df)), function(i) {
          row <- as.list(layout_df[i, , drop = FALSE])
          row$PANEL <- as.integer(row$PANEL)
          row$ROW <- as.integer(row$ROW)
          row$COL <- as.integer(row$COL)
          row$SCALE_X <- as.integer(row$SCALE_X)
          row$SCALE_Y <- as.integer(row$SCALE_Y)
          row
        }),
        row_strips = row_strips,
        col_strips = col_strips
      )
    } else {
      # Non-faceted plot (default)
      facets_ir <- list(
        type = "null",
        vars = list(),
        nrow = 1L,
        ncol = 1L,
        layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
        strips = list()
      )
      panels_ir <- list(list(
        PANEL = 1L,
        x_range = unname(scales$x$domain),
        y_range = unname(scales$y$domain),
        x_breaks = unname(x_breaks),
        y_breaks = unname(y_breaks)
      ))
    }
  }, error = function(e) {
    # Fallback to non-faceted on any error
    facets_ir <<- list(
      type = "null",
      vars = list(),
      nrow = 1L,
      ncol = 1L,
      layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
      strips = list()
    )
    panels_ir <<- list(list(
      PANEL = 1L,
      x_range = unname(scales$x$domain),
      y_range = unname(scales$y$domain),
      x_breaks = unname(x_breaks),
      y_breaks = unname(y_breaks)
    ))
  })

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
