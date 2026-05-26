gg2d3_ir_panel_ranges <- function(pp, xscale_obj, yscale_obj, is_flip, x_trans_name, y_trans_name) {
  if (is_flip) {
    ppx <- gg2d3_panel_axis(pp, "y")
    ppy <- gg2d3_panel_axis(pp, "x")
  } else {
    ppx <- gg2d3_panel_axis(pp, "x")
    ppy <- gg2d3_panel_axis(pp, "y")
  }

  panel_x_range <- if (xscale_obj$is_discrete()) {
    unname(xscale_obj$get_limits())
  } else {
    unname(gg2d3_continuous_range(ppx))
  }
  panel_y_range <- if (yscale_obj$is_discrete()) {
    unname(yscale_obj$get_limits())
  } else {
    unname(gg2d3_continuous_range(ppy))
  }

  x_break_info <- gg2d3_ir_axis_breaks(ppx, x_trans_name)
  y_break_info <- gg2d3_ir_axis_breaks(ppy, y_trans_name)

  if (!xscale_obj$is_discrete()) {
    panel_x_range <- gg2d3_ir_convert_temporal_values(panel_x_range, x_trans_name)
  }
  if (!yscale_obj$is_discrete()) {
    panel_y_range <- gg2d3_ir_convert_temporal_values(panel_y_range, y_trans_name)
  }

  list(
    x_range = panel_x_range,
    y_range = panel_y_range,
    x_breaks = unname(x_break_info$breaks),
    y_breaks = unname(y_break_info$breaks),
    x_minor_breaks = if (!is.null(x_break_info$minor_breaks)) unname(x_break_info$minor_breaks) else NULL,
    y_minor_breaks = if (!is.null(y_break_info$minor_breaks)) unname(y_break_info$minor_breaks) else NULL
  )
}


gg2d3_ir_panel_spacing <- function(theme) {
  tryCatch({
    spacing <- gg2d3_calc_element("panel.spacing", theme)
    if (!is.null(spacing)) {
      grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96
    } else {
      7.3
    }
  }, error = function(e) 7.3)
}


gg2d3_ir_facet_scales_mode <- function(free_params) {
  if (free_params$x && free_params$y) {
    "free"
  } else if (free_params$x) {
    "free_x"
  } else if (free_params$y) {
    "free_y"
  } else {
    "fixed"
  }
}


gg2d3_ir_facet_layout_rows <- function(layout_df) {
  lapply(seq_len(nrow(layout_df)), function(i) {
    row <- as.list(layout_df[i, , drop = FALSE])
    row$PANEL <- as.integer(row$PANEL)
    row$ROW <- as.integer(row$ROW)
    row$COL <- as.integer(row$COL)
    row$SCALE_X <- as.integer(row$SCALE_X)
    row$SCALE_Y <- as.integer(row$SCALE_Y)
    row
  })
}


gg2d3_ir_panel_list <- function(layout_obj, xscale_obj, yscale_obj, is_flip, x_trans_name, y_trans_name) {
  lapply(seq_along(layout_obj$panel_params), function(panel_index) {
    c(
      list(PANEL = as.integer(panel_index)),
      gg2d3_ir_panel_ranges(
        layout_obj$panel_params[[panel_index]],
        xscale_obj,
        yscale_obj,
        is_flip,
        x_trans_name,
        y_trans_name
      )
    )
  })
}


gg2d3_ir_facet_wrap <- function(layout_obj, build, xscale_obj, yscale_obj,
                                is_flip, x_trans_name, y_trans_name, theme) {
  layout_df <- layout_obj$layout
  facet_vars <- names(layout_obj$facet$params$facets)
  scales_mode <- gg2d3_ir_facet_scales_mode(layout_obj$facet$params$free)

  strips <- lapply(seq_along(facet_vars), function(level) {
    var <- facet_vars[level]
    level_labels <- lapply(seq_len(nrow(layout_df)), function(i) {
      list(PANEL = as.integer(layout_df$PANEL[i]), label = as.character(layout_df[[var]][i]))
    })
    list(level = level, variable = var, labels = level_labels)
  })

  panels <- gg2d3_ir_panel_list(
    layout_obj,
    xscale_obj,
    yscale_obj,
    is_flip,
    x_trans_name,
    y_trans_name
  )

  list(
    facets = list(
      type = "wrap",
      vars = facet_vars,
      nrow = as.integer(max(layout_df$ROW)),
      ncol = as.integer(max(layout_df$COL)),
      scales = scales_mode,
      spacing = gg2d3_ir_panel_spacing(theme),
      layout = gg2d3_ir_facet_layout_rows(layout_df),
      strips = strips
    ),
    panels = panels
  )
}


gg2d3_ir_facet_grid <- function(layout_obj, build, xscale_obj, yscale_obj,
                                is_flip, x_trans_name, y_trans_name, theme) {
  layout_df <- layout_obj$layout
  row_vars <- names(layout_obj$facet$params$rows)
  col_vars <- names(layout_obj$facet$params$cols)
  scales_mode <- gg2d3_ir_facet_scales_mode(layout_obj$facet$params$free)

  row_strips <- NULL
  if (length(row_vars) > 0) {
    row_combos <- unique(layout_df[, c("ROW", row_vars), drop = FALSE])
    row_strips <- lapply(seq_along(row_vars), function(level) {
      var <- row_vars[level]
      level_labels <- lapply(seq_len(nrow(row_combos)), function(i) {
        list(ROW = as.integer(row_combos$ROW[i]), label = as.character(row_combos[[var]][i]))
      })
      list(level = level, variable = var, labels = level_labels)
    })
  }

  col_strips <- NULL
  if (length(col_vars) > 0) {
    col_combos <- unique(layout_df[, c("COL", col_vars), drop = FALSE])
    col_strips <- lapply(seq_along(col_vars), function(level) {
      var <- col_vars[level]
      level_labels <- lapply(seq_len(nrow(col_combos)), function(i) {
        list(COL = as.integer(col_combos$COL[i]), label = as.character(col_combos[[var]][i]))
      })
      list(level = level, variable = var, labels = level_labels)
    })
  }

  panels <- gg2d3_ir_panel_list(
    layout_obj,
    xscale_obj,
    yscale_obj,
    is_flip,
    x_trans_name,
    y_trans_name
  )

  list(
    facets = list(
      type = "grid",
      rows = row_vars,
      cols = col_vars,
      scales = scales_mode,
      nrow = as.integer(max(layout_df$ROW)),
      ncol = as.integer(max(layout_df$COL)),
      spacing = gg2d3_ir_panel_spacing(theme),
      layout = gg2d3_ir_facet_layout_rows(layout_df),
      row_strips = row_strips,
      col_strips = col_strips
    ),
    panels = panels
  )
}


gg2d3_ir_null_facets <- function(scales, is_sf_coord) {
  facets <- list(
    type = "null",
    vars = list(),
    nrow = 1L,
    ncol = 1L,
    layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
    strips = list()
  )

  panels <- if (is_sf_coord) {
    list(list(PANEL = 1L, x_range = NULL, y_range = NULL, x_breaks = NULL, y_breaks = NULL))
  } else {
    list(list(
      PANEL = 1L,
      x_range = unname(scales$x$domain),
      y_range = unname(scales$y$domain),
      x_breaks = unname(scales$x$breaks),
      y_breaks = unname(scales$y$breaks)
    ))
  }

  list(facets = facets, panels = panels)
}


gg2d3_ir_facets <- function(build, scales, xscale_obj, yscale_obj, is_flip, is_sf_coord,
                            x_trans_name, y_trans_name, theme, sf_panel_geometries) {
  result <- tryCatch({
    layout_obj <- build$layout
    if (inherits(layout_obj$facet, "FacetWrap")) {
      gg2d3_ir_facet_wrap(
        layout_obj, build, xscale_obj, yscale_obj, is_flip,
        x_trans_name, y_trans_name, theme
      )
    } else if (inherits(layout_obj$facet, "FacetGrid")) {
      gg2d3_ir_facet_grid(
        layout_obj, build, xscale_obj, yscale_obj, is_flip,
        x_trans_name, y_trans_name, theme
      )
    } else {
      gg2d3_ir_null_facets(scales, is_sf_coord)
    }
  }, error = function(e) {
    gg2d3_ir_null_facets(scales, FALSE)
  })

  if (is_sf_coord && !is.null(result$panels)) {
    result$panels <- attach_sf_panel_bboxes(result$panels, sf_panel_geometries)
  }

  result
}
