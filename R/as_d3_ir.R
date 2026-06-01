#' Build a D3-ready IR (intermediate representation) from a ggplot
#'
#' @param p A ggplot object.
#' @param width Widget width in pixels.
#' @param height Widget height in pixels.
#' @param padding Named list of top, right, bottom, and left plot padding in pixels.
#'
#' @export
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)
  is_flip <- inherits(b$plot$coordinates, "CoordFlip")

  # Detect transformed coordinates (not yet supported - Phase 3)
  if (inherits(b$plot$coordinates, "CoordTrans") ||
      inherits(b$plot$coordinates, "CoordTransform")) {
    warning(
      "coord_trans() is not yet supported by gg2d3. ",
      "Scale transformations (e.g., scale_x_log10()) provide equivalent visual output ",
      "for most cases. coord_trans() support is planned for Phase 3.",
      call. = FALSE
    )
  }

  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Extract scale objects early (needed for mapping discrete values)
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  sf_coord_geometries <- list()
  sf_panel_geometries <- list()

  layers <- lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]

    # Map discrete x/y values to their labels (only if column exists and has values)
    if ("x" %in% names(df) && !all(is.na(df$x))) {
      df$x <- gg2d3_ir_map_discrete(df$x, xscale_obj)
    }
    if ("y" %in% names(df) && !all(is.na(df$y))) {
      df$y <- gg2d3_ir_map_discrete(df$y, yscale_obj)
    }
    if ("xmin" %in% names(df) && !all(is.na(df$xmin))) {
      df$xmin <- gg2d3_ir_map_discrete(df$xmin, xscale_obj)
    }
    if ("xmax" %in% names(df) && !all(is.na(df$xmax))) {
      df$xmax <- gg2d3_ir_map_discrete(df$xmax, xscale_obj)
    }
    if ("ymin" %in% names(df) && !all(is.na(df$ymin))) {
      df$ymin <- gg2d3_ir_map_discrete(df$ymin, yscale_obj)
    }
    if ("ymax" %in% names(df) && !all(is.na(df$ymax))) {
      df$ymax <- gg2d3_ir_map_discrete(df$ymax, yscale_obj)
    }

    layer_obj <- b$plot$layers[[i]]
    gcl <- class(layer_obj$geom)[1]
    gname <- gg2d3_ir_geom_name(layer_obj)
    keep_aes <- gg2d3_ir_layer_keep_aes()
    cols <- intersect(keep_aes, names(df))
    aes <- gg2d3_ir_layer_aes(cols)

    # Convert temporal data columns to milliseconds (ggplot_build strips
    # Date/POSIXct class, leaving plain numeric days or seconds)
    x_tn <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
    y_tn <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL
    df <- gg2d3_ir_apply_temporal_layer_columns(df, x_tn, y_tn)
    var_names <- gg2d3_ir_var_names(b$plot$mapping, layer_obj$mapping)
    source_data <- gg2d3_ir_layer_source_data(b$plot$data, layer_obj)

    g_params <- gg2d3_ir_layer_params(layer_obj, gcl)

    if (gname == "sf") {
      payload <- sf_layer_ir_payload(df, aes, g_params, var_names, source_data = source_data)
      if (length(payload$coord_geometry) > 0L) {
        sf_coord_geometries[[length(sf_coord_geometries) + 1L]] <<- payload$coord_geometry
        for (panel_key in names(payload$panel_geometries)) {
          existing <- sf_panel_geometries[[panel_key]]
          sf_panel_geometries[[panel_key]] <<- if (is.null(existing)) {
            payload$panel_geometries[[panel_key]]
          } else {
            c(existing, payload$panel_geometries[[panel_key]])
          }
        }
      }
      payload$layer
    } else if (gname %in% c("sf_text", "sf_label")) {
      annotation_type <- sub("^sf_", "", gname)
      payload <- sf_annotation_layer_ir_payload(
        df,
        aes,
        g_params,
        var_names,
        annotation_type,
        source_data = source_data
      )
      if (length(payload$coord_geometry) > 0L) {
        sf_coord_geometries[[length(sf_coord_geometries) + 1L]] <<- payload$coord_geometry
        for (panel_key in names(payload$panel_geometries)) {
          existing <- sf_panel_geometries[[panel_key]]
          sf_panel_geometries[[panel_key]] <<- if (is.null(existing)) {
            payload$panel_geometries[[panel_key]]
          } else {
            c(existing, payload$panel_geometries[[panel_key]])
          }
        }
      }
      payload$layer
    } else {
      gg2d3_ir_non_sf_layer(gname, df, aes, g_params, var_names)
    }
  })

  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))

  # Helper for color domain
  dom <- function(v) {
    if (is.null(v) || length(v) == 0) return(numeric(0))
    if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
  }

  # Extract grid breaks from panel params
  first_panel_params <- b$layout$panel_params[[1]]
  if (is_flip) {
    pp_x <- gg2d3_panel_axis(first_panel_params, "y")
    pp_y <- gg2d3_panel_axis(first_panel_params, "x")
  } else {
    pp_x <- gg2d3_panel_axis(first_panel_params, "x")
    pp_y <- gg2d3_panel_axis(first_panel_params, "y")
  }

  x_trans_name <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
  y_trans_name <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL
  x_break_info <- gg2d3_ir_axis_breaks(pp_x, x_trans_name)
  y_break_info <- gg2d3_ir_axis_breaks(pp_y, y_trans_name)
  x_breaks <- x_break_info$breaks
  y_breaks <- y_break_info$breaks
  x_minor_breaks <- x_break_info$minor_breaks
  y_minor_breaks <- y_break_info$minor_breaks

  scales <- list(
    x = c(gg2d3_ir_scale_info(xscale_obj, pp_x, "x"), list(
      breaks = unname(x_breaks),
      minor_breaks = if (!is.null(x_minor_breaks)) unname(x_minor_breaks) else NULL
    )),
    y = c(gg2d3_ir_scale_info(yscale_obj, pp_y, "y"), list(
      breaks = unname(y_breaks),
      minor_breaks = if (!is.null(y_minor_breaks)) unname(y_minor_breaks) else NULL
    ))
  )
  if (length(allc)) {
    scales$color <- list(
      type = if (is.numeric(allc)) "continuous" else "categorical",
      domain = unname(dom(allc))
    )
  }

  th <- gg2d3_plot_theme(b$plot)
  theme_ir <- gg2d3_ir_theme(th)

  is_fixed    <- inherits(b$plot$coordinates, "CoordFixed") ||
    (!is.null(b$plot$coordinates$ratio))
  is_polar    <- inherits(b$plot$coordinates, "CoordPolar")
  is_sf_coord <- inherits(b$plot$coordinates, "CoordSf")

  coord_type  <- if (is_flip) "flip"
                 else if (is_fixed) "fixed"
                 else if (is_polar) "polar"
                 else if (is_sf_coord) "sf"
                 else "cartesian"
  coord_ratio <- if (is_fixed) (b$plot$coordinates$ratio %||% 1) else NULL

  # Polar metadata
  polar_meta <- if (is_polar) {
    list(
      theta = b$plot$coordinates$theta %||% "x",
      start = b$plot$coordinates$start %||% 0,
      direction = b$plot$coordinates$direction %||% 1
    )
  } else {
    NULL
  }

  # sf coord metadata: compute WGS84 bounding box from all sf layers
  sf_coord_meta <- if (is_sf_coord) {
    all_sf_geoms <- if (length(sf_coord_geometries) > 0L) do.call(c, sf_coord_geometries) else NULL
    bbox_vals <- sf_bbox_values(all_sf_geoms)
    list(bbox = bbox_vals)
  } else {
    NULL
  }

  if (is_flip) {
    x_label <- b$plot$labels$y %||% ""
    y_label <- b$plot$labels$x %||% ""
  } else {
    x_label <- b$plot$labels$x %||% ""
    y_label <- b$plot$labels$y %||% ""
  }

  # Tick labels mirror the displayed (post-flip) axes — matches the swap
  # applied to x_label/y_label below. Use the unswapped panel_params because
  # ggplot_build already orients panel_params$x/$y to the rendered axes.
  pp_x_display <- gg2d3_panel_axis(first_panel_params, "x")
  pp_y_display <- gg2d3_panel_axis(first_panel_params, "y")

  x_tick_labels <- gg2d3_panel_labels(pp_x_display)

  y_tick_labels <- gg2d3_panel_labels(pp_y_display)

  has_sec_x <- tryCatch({
    sec <- b$layout$panel_scales_x[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  has_sec_y <- tryCatch({
    sec <- b$layout$panel_scales_y[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  legend_position <- gg2d3_calc_element("legend.position", th, default = "right")
  if (!is.character(legend_position)) legend_position <- "right"

  subtitle_text <- b$plot$labels$subtitle %||% ""
  caption_text <- b$plot$labels$caption %||% ""

  guides_ir <- list()
  if (legend_position != "none") {
    all_scales <- b$plot$scales$scales
    legend_aesthetics <- c()
    for (scale in all_scales) {
      aes_names <- scale$aesthetics
      for (aes_name in aes_names) {
        if (aes_name %in% c("colour", "color", "fill", "size", "shape", "alpha")) {
          guide_obj <- scale$guide
          if (!inherits(guide_obj, "GuideNone") && !identical(guide_obj, "none") && !identical(guide_obj, FALSE)) {
            legend_aesthetics <- c(legend_aesthetics, aes_name)
          }
        }
      }
    }
    legend_aesthetics <- unique(legend_aesthetics)
    if ("color" %in% legend_aesthetics) {
      legend_aesthetics <- setdiff(legend_aesthetics, "color")
      if (!"colour" %in% legend_aesthetics) legend_aesthetics <- c(legend_aesthetics, "colour")
    }

    for (aes_name in legend_aesthetics) {
      guide_data <- tryCatch(ggplot2::get_guide_data(p, aesthetic = aes_name), error = function(e) NULL)
      if (is.null(guide_data) || nrow(guide_data) == 0) next
      scale_obj <- b$plot$scales$get_scales(aes_name)
      if (is.null(scale_obj)) next
      is_continuous <- inherits(scale_obj, "ScaleContinuous")
      is_color_aes <- aes_name %in% c("colour", "fill")
      guide_type <- if (is_continuous && is_color_aes) "colorbar" else "legend"
      title <- scale_obj$name
      if (is.null(title) || identical(title, ggplot2::waiver())) title <- b$plot$labels[[aes_name]] %||% aes_name
      keys_list <- list()
      for (i in seq_len(nrow(guide_data))) {
        key <- list()
        if (".value" %in% names(guide_data)) key$value <- guide_data[[".value"]][i]
        if (".label" %in% names(guide_data)) key$label <- as.character(guide_data[[".label"]][i])
        if (aes_name %in% names(guide_data)) key[[aes_name]] <- guide_data[[aes_name]][i]
        if ("colour" %in% names(guide_data)) key$colour <- guide_data$colour[i]
        if ("fill" %in% names(guide_data)) key$fill <- guide_data$fill[i]
        if ("size" %in% names(guide_data)) key$size <- guide_data$size[i]
        if ("shape" %in% names(guide_data)) key$shape <- guide_data$shape[i]
        if ("alpha" %in% names(guide_data)) key$alpha <- guide_data$alpha[i]
        keys_list[[i]] <- key
      }
      colors_array <- NULL
      if (guide_type == "colorbar") {
        scale_domain <- tryCatch(scale_obj$get_limits(), error = function(e) c(0, 1))
        color_values <- seq(scale_domain[1], scale_domain[2], length.out = 30)
        colors_array <- tryCatch(scale_obj$map(color_values), error = function(e) NULL)
      }
      guides_ir[[length(guides_ir) + 1]] <- list(
        aesthetic = aes_name, aesthetics = list(aes_name), type = guide_type,
        title = as.character(title), keys = keys_list, colors = colors_array
      )
    }
    if (length(guides_ir) > 1) {
      guide_titles <- sapply(guides_ir, function(g) g$title)
      duplicates <- duplicated(guide_titles) | duplicated(guide_titles, fromLast = TRUE)
      if (any(duplicates)) {
        merged_guides <- list(); processed_titles <- character(0)
        for (i in seq_along(guides_ir)) {
          guide <- guides_ir[[i]]; title <- guide$title
          if (title %in% processed_titles) next
          matching_indices <- which(guide_titles == title)
          if (length(matching_indices) > 1) {
            merged_guide <- guide; merged_aesthetics <- list()
            for (idx in matching_indices) {
              merged_aesthetics[[length(merged_aesthetics) + 1]] <- guides_ir[[idx]]$aesthetic
              if (idx > matching_indices[1]) {
                other_guide <- guides_ir[[idx]]
                for (j in seq_along(merged_guide$keys)) {
                  if (j <= length(other_guide$keys)) {
                    other_key <- other_guide$keys[[j]]
                    for (col_name in names(other_key)) {
                      if (!(col_name %in% names(merged_guide$keys[[j]]))) merged_guide$keys[[j]][[col_name]] <- other_key[[col_name]]
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

  facet_payload <- gg2d3_ir_facets(
    b,
    scales,
    xscale_obj,
    yscale_obj,
    is_flip,
    is_sf_coord,
    x_trans_name,
    y_trans_name,
    th,
    sf_panel_geometries
  )
  facets_ir <- facet_payload$facets
  panels_ir <- facet_payload$panels

  # Build reverse map: variable name -> aesthetic key (first layer wins on collision).
  # Lets tooltip lookups resolve user-supplied variable names (e.g. "wt") back
  # to the aesthetic key under which the value is actually stored ("x").
  aes_by_var <- list()
  for (lyr in layers) {
    vn <- lyr$var_names
    if (is.null(vn) || length(vn) == 0) next
    for (aes_name in names(vn)) {
      var_name <- vn[[aes_name]]
      if (is.null(aes_by_var[[var_name]])) aes_by_var[[var_name]] <- aes_name
    }
  }

  ir <- list(
    width = width, height = height, padding = padding,
    coord  = c(list(type = coord_type, flip = is_flip, ratio = coord_ratio), polar_meta, sf_coord_meta),
    title  = b$plot$labels$title %||% "", subtitle = subtitle_text, caption = caption_text,
    axes   = list(x = list(orientation = "bottom", label = x_label, tickLabels = x_tick_labels), y = list(orientation = "left",  label = y_label, tickLabels = y_tick_labels), x2 = if (has_sec_x) list(enabled = TRUE) else NULL, y2 = if (has_sec_y) list(enabled = TRUE) else NULL),
    facets = facets_ir, panels = panels_ir, scales = scales, layers = layers, guides = guides_ir, legend = list(enabled = TRUE, position = legend_position), theme = theme_ir,
    aes_by_var = aes_by_var
  )
  validate_ir(ir)
}
