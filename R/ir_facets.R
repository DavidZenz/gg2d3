# Facet extraction. Returns BOTH `facets` and `panels` slices in one list so the
# orchestrator can destructure (avoids <<- — see RESEARCH Pitfall 2).
#
# Lifted verbatim from R/as_d3_ir.R (post-Plan-05). The v1.0 tryCatch error
# handler used `facets_ir <<- ...` and `panels_ir <<- ...` which would write
# to globalenv once moved out of as_d3_ir's frame. Replaced with an explicit
# `return(fallback)` from the error handler — no superassign survives.

#' @keywords internal
#' @noRd
extract_facets_ir <- function(b, pp_x, pp_y, scales,
                              x_breaks, y_breaks,
                              x_trans_name, y_trans_name,
                              is_flip = FALSE) {

  `%||%` <- function(x, y) if (is.null(x)) y else x

  # The v1.0 fallback (was the <<- target). Now an explicit value.
  fallback <- list(
    facets = list(
      type   = "null",
      vars   = list(),
      nrow   = 1L,
      ncol   = 1L,
      layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
      strips = list()
    ),
    panels = list(list(
      PANEL    = 1L,
      x_range  = unname(scales$x$domain),
      y_range  = unname(scales$y$domain),
      x_breaks = unname(x_breaks),
      y_breaks = unname(y_breaks)
    ))
  )

  tryCatch({
    is_facet_wrap <- inherits(b$layout$facet, "FacetWrap")
    is_facet_grid <- inherits(b$layout$facet, "FacetGrid")

    if (is_facet_wrap) {
      layout_df <- b$layout$layout
      facet_vars <- names(b$layout$facet$params$facets)

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

      strips <- lapply(seq_len(nrow(layout_df)), function(i) {
        label_parts <- vapply(facet_vars, function(v) {
          as.character(layout_df[[v]][i])
        }, character(1))
        list(
          PANEL = as.integer(layout_df$PANEL[i]),
          label = paste(label_parts, collapse = ", ")
        )
      })

      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip) {
          ppx <- pp$y
          ppy <- pp$x
        } else {
          ppx <- pp$x
          ppy <- pp$y
        }
        panel_x_range <- unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])

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

      panel_spacing <- tryCatch({
        spacing <- calc_element_safe("panel.spacing", b$plot$theme)
        if (!is.null(spacing)) {
          inches <- grid::convertUnit(spacing, "inches", valueOnly = TRUE)
          inches * 96
        } else {
          7.3
        }
      }, error = function(e) 7.3)

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

      list(facets = facets_ir, panels = panels_ir)

    } else if (is_facet_grid) {
      layout_df <- b$layout$layout
      row_vars <- names(b$layout$facet$params$rows)
      col_vars <- names(b$layout$facet$params$cols)

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

      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip) {
          ppx <- pp$y
          ppy <- pp$x
        } else {
          ppx <- pp$x
          ppy <- pp$y
        }
        panel_x_range <- unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])

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

      panel_spacing <- tryCatch({
        spacing <- calc_element_safe("panel.spacing", b$plot$theme)
        if (!is.null(spacing)) {
          inches <- grid::convertUnit(spacing, "inches", valueOnly = TRUE)
          inches * 96
        } else {
          7.3
        }
      }, error = function(e) 7.3)

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

      list(facets = facets_ir, panels = panels_ir)

    } else {
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
      list(facets = facets_ir, panels = panels_ir)
    }
  }, error = function(e) fallback)  # NOT <<- — explicit return per Pitfall 2.
}
