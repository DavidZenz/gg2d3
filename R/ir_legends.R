# Legend extraction. Reads guide data via the public ggplot2 API
# (ggplot2::get_guide_data) and resolves legend.position via
# R/ir_theme.R::calc_element_safe. Lifted out of R/as_d3_ir.R in Plan 13-05.

#' @keywords internal
#' @noRd
extract_legends_ir <- function(b, p) {
  `%||%` <- function(x, y) if (is.null(x)) y else x

  legend_position <- tryCatch({
    pos <- calc_element_safe("legend.position", b$plot$theme)
    if (is.character(pos)) pos else "right"
  }, error = function(e) "right")

  guides_ir <- list()

  if (legend_position != "none") {
    # Get all scales that can produce guides
    all_scales <- b$plot$scales$scales

    # Identify aesthetics that should have legends
    legend_aesthetics <- c()

    for (scale in all_scales) {
      aes_names <- scale$aesthetics
      for (aes_name in aes_names) {
        if (aes_name %in% c("colour", "color", "fill", "size", "shape", "alpha")) {
          guide_obj <- scale$guide
          if (!inherits(guide_obj, "GuideNone") &&
              !identical(guide_obj, "none") &&
              !identical(guide_obj, FALSE)) {
            legend_aesthetics <- c(legend_aesthetics, aes_name)
          }
        }
      }
    }

    legend_aesthetics <- unique(legend_aesthetics)
    if ("color" %in% legend_aesthetics) {
      legend_aesthetics <- setdiff(legend_aesthetics, "color")
      if (!"colour" %in% legend_aesthetics) {
        legend_aesthetics <- c(legend_aesthetics, "colour")
      }
    }

    for (aes_name in legend_aesthetics) {
      guide_data <- tryCatch(
        ggplot2::get_guide_data(p, aesthetic = aes_name),
        error = function(e) NULL
      )

      if (is.null(guide_data) || nrow(guide_data) == 0) {
        next
      }

      scale_obj <- b$plot$scales$get_scales(aes_name)
      if (is.null(scale_obj)) next

      # ScaleBinned (scale_*_steps / scale_*_binned) does NOT inherit from ScaleContinuous,
      # so we must enumerate both. ggplot2's default guide for binned color is
      # guide_coloursteps, which is a banded colorbar — see Phase 14 D-06.
      is_continuous <- inherits(scale_obj, c("ScaleContinuous", "ScaleBinned"))
      is_steps <- inherits(scale_obj, "ScaleBinned")
      is_color_aes <- aes_name %in% c("colour", "fill")
      guide_type <- if (is_continuous && is_color_aes) "colorbar" else "legend"

      title <- scale_obj$name
      if (is.null(title) || identical(title, ggplot2::waiver())) {
        title <- b$plot$labels[[aes_name]] %||% aes_name
      }

      keys_list <- list()
      for (i in seq_len(nrow(guide_data))) {
        key <- list()

        if (".value" %in% names(guide_data)) {
          key$value <- guide_data[[".value"]][i]
        }
        if (".label" %in% names(guide_data)) {
          key$label <- as.character(guide_data[[".label"]][i])
        }

        if (aes_name %in% names(guide_data)) {
          key[[aes_name]] <- guide_data[[aes_name]][i]
        }
        if ("colour" %in% names(guide_data)) {
          key$colour <- guide_data$colour[i]
        }
        if ("fill" %in% names(guide_data)) {
          key$fill <- guide_data$fill[i]
        }
        if ("size" %in% names(guide_data)) {
          key$size <- guide_data$size[i]
        }
        if ("shape" %in% names(guide_data)) {
          key$shape <- guide_data$shape[i]
        }
        if ("alpha" %in% names(guide_data)) {
          key$alpha <- guide_data$alpha[i]
        }

        keys_list[[i]] <- key
      }

      colors_array <- NULL
      if (guide_type == "colorbar") {
        scale_domain <- tryCatch(
          scale_obj$get_limits(),
          error = function(e) c(0, 1)
        )

        color_values <- seq(scale_domain[1], scale_domain[2], length.out = 30)

        colors_array <- tryCatch(
          scale_obj$map(color_values),
          error = function(e) NULL
        )
      }

      guide_spec <- list(
        aesthetic = aes_name,
        aesthetics = list(aes_name),
        type = guide_type,
        title = as.character(title),
        keys = keys_list,
        colors = colors_array,
        is_steps = isTRUE(is_steps)
      )

      guides_ir[[length(guides_ir) + 1]] <- guide_spec
    }

    # Detect and handle merged guides (same title)
    if (length(guides_ir) > 1) {
      guide_titles <- sapply(guides_ir, function(g) g$title)
      duplicates <- duplicated(guide_titles) | duplicated(guide_titles, fromLast = TRUE)

      if (any(duplicates)) {
        merged_guides <- list()
        processed_titles <- character(0)

        for (i in seq_along(guides_ir)) {
          guide <- guides_ir[[i]]
          title <- guide$title

          if (title %in% processed_titles) {
            next
          }

          matching_indices <- which(guide_titles == title)

          if (length(matching_indices) > 1) {
            merged_guide <- guide
            merged_aesthetics <- list()

            for (idx in matching_indices) {
              merged_aesthetics[[length(merged_aesthetics) + 1]] <- guides_ir[[idx]]$aesthetic

              if (idx > matching_indices[1]) {
                other_guide <- guides_ir[[idx]]
                for (j in seq_along(merged_guide$keys)) {
                  if (j <= length(other_guide$keys)) {
                    other_key <- other_guide$keys[[j]]
                    for (col_name in names(other_key)) {
                      if (!(col_name %in% names(merged_guide$keys[[j]]))) {
                        merged_guide$keys[[j]][[col_name]] <- other_key[[col_name]]
                      }
                    }
                  }
                }
              }
            }

            merged_guide$aesthetics <- merged_aesthetics
            merged_guides[[length(merged_guides) + 1]] <- merged_guide
            processed_titles <- c(processed_titles, title)
          } else {
            merged_guides[[length(merged_guides) + 1]] <- guide
            processed_titles <- c(processed_titles, title)
          }
        }

        guides_ir <- merged_guides
      }
    }
  }

  list(position = legend_position, guides = guides_ir)
}
