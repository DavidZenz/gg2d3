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

  keep_aes <- c(
    "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
    "colour","fill","size","alpha","group","label",
    "slope","intercept","xintercept","yintercept"
  )

  # coerce to plain base types (no factors), then row-wise list with scalars
  to_rows <- function(df) {
    if (is.null(df) || !nrow(df)) return(list())
    df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
    # drop factor classes to base vectors early
    df[] <- lapply(df, function(col) {
      if (is.factor(col)) as.character(col)          # colors may be hex already
      else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000 # ms for JS time if ever needed
      else if (inherits(col, "Date")) as.numeric(col) * 86400000            # ms days
      else if (is.list(col)) I(col)                 # leave lists as-is
      else col
    })
    rows <- vector("list", nrow(df))
    for (i in seq_len(nrow(df))) {
      # make true scalars (no length-1 vectors)
      r <- lapply(df[i, , drop = FALSE], function(v) v[[1]])
      names(r) <- names(df)
      rows[[i]] <- r
    }
    rows
  }

  # Extract scale objects early (needed for mapping discrete values)
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # Helper to map discrete x/y values to labels
  map_discrete <- function(values, scale_obj) {
    if (inherits(scale_obj, "ScaleDiscrete") && is.numeric(values)) {
      labels <- scale_obj$get_limits()
      # Only map if values are integer indices (not continuous)
      # Check if all non-NA values are whole numbers
      non_na <- !is.na(values)
      if (all(values[non_na] == floor(values[non_na]))) {
        # Values are integers, safe to use as indices
        result <- rep(NA_character_, length(values))
        result[non_na] <- labels[values[non_na]]
        result
      } else {
        # Values are continuous, don't map
        values
      }
    } else {
      values
    }
  }

  # Extract a single theme element as a plain list for JSON serialization
  extract_theme_element <- function(element_name, theme) {
    calc <- ggplot2:::calc_element(element_name, theme)

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

  layers <- lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]

    # Map discrete x/y values to their labels (only if column exists and has values)
    if ("x" %in% names(df) && !all(is.na(df$x))) {
      df$x <- map_discrete(df$x, xscale_obj)
    }
    if ("y" %in% names(df) && !all(is.na(df$y))) {
      df$y <- map_discrete(df$y, yscale_obj)
    }
    if ("xmin" %in% names(df) && !all(is.na(df$xmin))) {
      df$xmin <- map_discrete(df$xmin, xscale_obj)
    }
    if ("xmax" %in% names(df) && !all(is.na(df$xmax))) {
      df$xmax <- map_discrete(df$xmax, xscale_obj)
    }
    if ("ymin" %in% names(df) && !all(is.na(df$ymin))) {
      df$ymin <- map_discrete(df$ymin, yscale_obj)
    }
    if ("ymax" %in% names(df) && !all(is.na(df$ymax))) {
      df$ymax <- map_discrete(df$ymax, yscale_obj)
    }

    # --- robust geom name ---
    gobj  <- b$plot$layers[[i]]$geom
    gcl   <- class(gobj)[1]
    gname <- switch(gcl,
                    GeomPoint  = "point",
                    GeomLine   = "line",
                    GeomPath   = "path",
                    GeomCol    = "col",
                    GeomBar    = "bar",
                    GeomArea   = "area",
                    GeomText   = "text",
                    GeomLabel  = "text",
                    GeomRect   = "rect",
                    GeomTile   = "rect",
                    GeomSegment= "segment",
                    GeomRibbon = "ribbon",
                    GeomViolin = "violin",
                    GeomBoxplot= "boxplot",
                    GeomDensity= "density",
                    GeomSmooth = "smooth",
                    GeomHline  = "hline",
                    GeomVline  = "vline",
                    GeomAbline = "abline",
                    GeomPolygon= "polygon",
                    # Fallbacks
                    {
                      if (!is.null(gobj$objname)) {
                        gobj$objname
                      } else {
                        # strip leading "Geom" and lowercase, e.g. "GeomPoint" -> "point"
                        sub("^Geom", "", gcl) |>
                          tolower()
                      }
                    }
    )

    # columns we keep
    keep_aes <- c(
      "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
      "colour","fill","size","alpha","group","label",
      "stroke","shape","linewidth","linetype","lineend",
      "slope","intercept","xintercept","yintercept",
      # Statistical geom computed columns
      "lower","middle","upper","outliers","notchupper","notchlower",
      "width","violinwidth","density","scaled","count","ncount","ndensity",
      "weight"
    )

    # coerce + rowize (same as your latest version)
    to_rows <- function(df) {
      if (is.null(df) || !nrow(df)) return(list())
      df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
      col_names <- names(df)
      df[] <- lapply(col_names, function(colname) {
        col <- df[[colname]]
        if (colname == "PANEL") as.integer(col)  # PANEL must be integer
        else if (is.factor(col)) as.character(col)
        else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000
        else if (inherits(col, "Date")) as.numeric(col) * 86400000
        else if (is.list(col)) I(col)  # preserve list-columns (e.g., boxplot outliers)
        else col
      })
      names(df) <- col_names
      rows <- vector("list", nrow(df))
      for (ii in seq_len(nrow(df))) {
        r <- lapply(df[ii, , drop = FALSE], function(v) v[[1]])
        names(r) <- names(df)
        rows[[ii]] <- r
      }
      rows
    }

    cols <- intersect(keep_aes, names(df))
    aes <- list(
      x     = if ("x"     %in% cols) "x"     else NULL,
      y     = if ("y"     %in% cols) "y"     else NULL,
      xend  = if ("xend"  %in% cols) "xend"  else NULL,
      yend  = if ("yend"  %in% cols) "yend"  else NULL,
      xmin  = if ("xmin"  %in% cols) "xmin"  else NULL,
      xmax  = if ("xmax"  %in% cols) "xmax"  else NULL,
      ymin  = if ("ymin"  %in% cols) "ymin"  else NULL,
      ymax  = if ("ymax"  %in% cols) "ymax"  else NULL,
      color = if ("colour"%in% cols) "colour"else NULL,
      fill  = if ("fill"  %in% cols) "fill"  else NULL,
      size  = if ("size"  %in% cols) "size"  else NULL,
      alpha = if ("alpha" %in% cols) "alpha" else NULL,
      group = if ("group" %in% cols) "group" else NULL,
      label = if ("label" %in% cols) "label" else NULL,
      slope = if ("slope" %in% cols) "slope" else NULL,
      intercept = if ("intercept" %in% cols) "intercept" else NULL,
      xintercept = if ("xintercept" %in% cols) "xintercept" else NULL,
      yintercept = if ("yintercept" %in% cols) "yintercept" else NULL
    )

    list(
      geom   = gname,          # <-- now always a non-NULL string like "point"
      data   = to_rows(df),
      aes    = aes,
      params = b$plot$layers[[i]]$aes_params
    )
  })

  # Validate log scale domains (must be strictly positive)
  validate_log_domain <- function(scale_obj, domain, axis_name) {
    trans <- scale_obj$trans
    if (is.null(trans)) return(invisible(TRUE))

    is_log <- grepl("log", trans$name, ignore.case = TRUE) &&
              !grepl("pseudo_log|symlog", trans$name, ignore.case = TRUE)

    if (is_log && any(domain <= 0)) {
      stop(sprintf(
        paste0(
          "Log scale on %s-axis has non-positive domain [%.4g, %.4g].\n",
          "Log scales require strictly positive values.\n",
          "Consider:\n",
          "  - scale_%s_continuous(trans = 'pseudo_log') for data including zero\n",
          "  - Filtering data to positive values\n",
          "  - Using a linear scale"
        ),
        axis_name, domain[1], domain[2], axis_name
      ), call. = FALSE)
    }

    invisible(TRUE)
  }

  # Extract scale transformation metadata for IR
  get_scale_transform <- function(scale_obj) {
    if (is.null(scale_obj$trans)) {
      return(NULL)
    }

    trans_name <- scale_obj$trans$name

    # Map ggplot2 trans names to D3 equivalents
    result <- list()

    if (trans_name == "identity") {
      # No transform needed
      return(NULL)
    } else if (trans_name == "log-10" || trans_name == "log10") {
      result$transform <- "log10"
      result$base <- 10
    } else if (trans_name == "log-2" || trans_name == "log2") {
      result$transform <- "log2"
      result$base <- 2
    } else if (trans_name == "log") {
      result$transform <- "log"
      result$base <- exp(1)
    } else if (trans_name == "sqrt") {
      result$transform <- "sqrt"
    } else if (trans_name == "reverse") {
      result$transform <- "reverse"
    } else if (trans_name == "pseudo_log") {
      result$transform <- "symlog"
    } else {
      # Unknown transform, pass through name
      result$transform <- trans_name
    }

    result
  }

  # Check if scale is discrete and get proper domain
  get_scale_info <- function(scale_obj, panel_params_axis, axis_name) {
    if (inherits(scale_obj, "ScaleDiscrete")) {
      # Discrete scale: get labels from scale object
      domain <- scale_obj$get_limits()
      list(type = "categorical", domain = unname(domain))
    } else {
      # Continuous scale: extract already-expanded domain from panel_params
      # The panel_params contain ggplot2's pre-computed expanded range

      # Try to get the continuous_range (already expanded by ggplot2)
      expanded_range <- NULL

      if (!is.null(panel_params_axis)) {
        # First try: direct .range field (some ggplot2 versions)
        if (!is.null(panel_params_axis$continuous_range)) {
          expanded_range <- panel_params_axis$continuous_range
        } else if (!is.null(panel_params_axis$range)) {
          # Try range field if continuous_range doesn't exist
          expanded_range <- panel_params_axis$range
        }
      }

      # Fallback: if we couldn't get range from panel_params, use scale limits
      if (is.null(expanded_range) || length(expanded_range) != 2) {
        warning("Could not extract range from panel_params, falling back to scale limits")
        expanded_range <- tryCatch(
          scale_obj$get_limits(),
          error = function(e) c(0, 1)
        )
        # Apply manual 5% expansion as last resort
        if (!is.null(expanded_range) && length(expanded_range) == 2) {
          range_span <- diff(expanded_range)
          expansion <- range_span * 0.05
          expanded_range <- c(expanded_range[1] - expansion, expanded_range[2] + expansion)
        }
      }

      # Validate log domains before building result
      validate_log_domain(scale_obj, expanded_range, axis_name)

      # Build result with transform info
      result <- list(type = "continuous", domain = unname(expanded_range))

      # Add transformation metadata if present
      transform_info <- get_scale_transform(scale_obj)
      if (!is.null(transform_info)) {
        result <- c(result, transform_info)
      }

      # Temporal scale handling: convert domain to milliseconds and extract metadata
      trans_name <- if (!is.null(scale_obj$trans)) scale_obj$trans$name else NULL
      if (!is.null(trans_name) && trans_name %in% c("date", "time")) {
        # Convert domain to milliseconds
        if (trans_name == "date") {
          # Date: values are days since epoch -> multiply by 86400000
          result$domain <- result$domain * 86400000
        } else if (trans_name == "time") {
          # POSIXct/datetime: values are seconds since epoch -> multiply by 1000
          result$domain <- result$domain * 1000
        }

        # Extract date format pattern from scale closure
        # ggplot2 stores date_labels in the constructor closure:
        # environment(environment(scale_obj$labels)$f)$date_labels
        format_pattern <- NULL
        if (!is.null(scale_obj$labels) && is.function(scale_obj$labels)) {
          format_pattern <- tryCatch({
            # Navigate ggproto method -> underlying function closure
            outer_env <- environment(scale_obj$labels)
            f <- outer_env$f
            if (is.function(f)) {
              inner_env <- environment(f)
              dl <- inner_env$date_labels
              # NULL or waiver means auto-format; only pass explicit patterns
              if (!is.null(dl) && !inherits(dl, "waiver") && nzchar(dl)) dl else NULL
            } else {
              NULL
            }
          }, error = function(e) NULL)
        }
        result$format <- format_pattern

        # Extract timezone from datetime scale
        if (trans_name == "time") {
          timezone <- tryCatch({
            # First try: direct timezone field on scale object (scale_x_datetime stores it here)
            tz_val <- scale_obj$timezone
            if (!is.null(tz_val) && tz_val != "") {
              tz_val
            } else {
              # Fallback: try labels closure (when labels function has been resolved)
              if (is.function(scale_obj$labels)) {
                env <- environment(scale_obj$labels)
                tz_val2 <- env$tz
                if (!is.null(tz_val2) && tz_val2 != "") tz_val2 else "UTC"
              } else {
                "UTC"
              }
            }
          }, error = function(e) "UTC")
          result$timezone <- timezone
        }

        # Include pre-formatted labels as fallback
        formatted_labels <- tryCatch({
          pp_labels <- panel_params_axis$get_labels()
          if (length(pp_labels) > 0) as.character(pp_labels) else NULL
        }, error = function(e) NULL)
        result$labels <- formatted_labels
      }

      result
    }
  }

  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))

  # Helper for color domain
  dom <- function(v) {
    if (is.null(v) || length(v) == 0) return(numeric(0))
    if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
  }

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

  x_breaks <- pp_x$breaks
  y_breaks <- pp_y$breaks
  x_minor_breaks <- pp_x$minor_breaks
  y_minor_breaks <- pp_y$minor_breaks

  # Remove NA values (ggplot2 adds NAs at the edges)
  x_breaks <- x_breaks[!is.na(x_breaks)]
  y_breaks <- y_breaks[!is.na(y_breaks)]
  x_minor_breaks <- if (!is.null(x_minor_breaks)) x_minor_breaks[!is.na(x_minor_breaks)] else NULL
  y_minor_breaks <- if (!is.null(y_minor_breaks)) y_minor_breaks[!is.na(y_minor_breaks)] else NULL

  # Convert temporal breaks to milliseconds (matching domain conversion in get_scale_info)
  x_trans_name <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
  if (!is.null(x_trans_name) && x_trans_name == "date") {
    x_breaks <- x_breaks * 86400000
    if (!is.null(x_minor_breaks)) x_minor_breaks <- x_minor_breaks * 86400000
  } else if (!is.null(x_trans_name) && x_trans_name == "time") {
    x_breaks <- x_breaks * 1000
    if (!is.null(x_minor_breaks)) x_minor_breaks <- x_minor_breaks * 1000
  }

  y_trans_name <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL
  if (!is.null(y_trans_name) && y_trans_name == "date") {
    y_breaks <- y_breaks * 86400000
    if (!is.null(y_minor_breaks)) y_minor_breaks <- y_minor_breaks * 86400000
  } else if (!is.null(y_trans_name) && y_trans_name == "time") {
    y_breaks <- y_breaks * 1000
    if (!is.null(y_minor_breaks)) y_minor_breaks <- y_minor_breaks * 1000
  }

  scales <- list(
    x = c(get_scale_info(xscale_obj, pp_x, "x"), list(
      breaks = unname(x_breaks),
      minor_breaks = if (!is.null(x_minor_breaks)) unname(x_minor_breaks) else NULL
    )),
    y = c(get_scale_info(yscale_obj, pp_y, "y"), list(
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

  # Extract theme information
  theme_ir <- NULL
  if (!is.null(b$plot$theme)) {
    theme_ir <- list(
      panel = list(
        background = extract_theme_element("panel.background", b$plot$theme),
        border = extract_theme_element("panel.border", b$plot$theme)
      ),
      plot = list(
        background = extract_theme_element("plot.background", b$plot$theme),
        margin = extract_theme_element("plot.margin", b$plot$theme)
      ),
      grid = list(
        major = extract_theme_element("panel.grid.major", b$plot$theme),
        minor = extract_theme_element("panel.grid.minor", b$plot$theme)
      ),
      axis = list(
        line = extract_theme_element("axis.line", b$plot$theme),
        line.x = extract_theme_element("axis.line.x", b$plot$theme),
        line.y = extract_theme_element("axis.line.y", b$plot$theme),
        text = extract_theme_element("axis.text", b$plot$theme),
        text.x = extract_theme_element("axis.text.x", b$plot$theme),
        text.y = extract_theme_element("axis.text.y", b$plot$theme),
        title = extract_theme_element("axis.title", b$plot$theme),
        title.x = extract_theme_element("axis.title.x", b$plot$theme),
        title.y = extract_theme_element("axis.title.y", b$plot$theme),
        ticks = extract_theme_element("axis.ticks", b$plot$theme),
        ticks.x = extract_theme_element("axis.ticks.x", b$plot$theme),
        ticks.y = extract_theme_element("axis.ticks.y", b$plot$theme)
      ),
      text = list(
        title = extract_theme_element("plot.title", b$plot$theme),
        subtitle = extract_theme_element("plot.subtitle", b$plot$theme),
        caption = extract_theme_element("plot.caption", b$plot$theme)
      )
    )
  }

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

  # Extract legend position from theme for layout engine
  legend_position <- tryCatch({
    complete_theme <- ggplot2::theme_get() + b$plot$theme
    pos <- ggplot2:::calc_element("legend.position", complete_theme)
    if (is.character(pos)) pos else "right"
  }, error = function(e) "right")

  # Extract subtitle and caption from plot labels
  subtitle_text <- b$plot$labels$subtitle %||% ""
  caption_text <- b$plot$labels$caption %||% ""

  # Extract guide specifications for legends
  guides_ir <- list()

  if (legend_position != "none") {
    # Get all scales that can produce guides
    all_scales <- b$plot$scales$scales

    # Identify aesthetics that should have legends
    legend_aesthetics <- c()

    for (scale in all_scales) {
      # Check if this scale produces a legend
      aes_names <- scale$aesthetics

      # Only include aesthetics that produce legends
      for (aes_name in aes_names) {
        if (aes_name %in% c("colour", "color", "fill", "size", "shape", "alpha")) {
          # Check if guide is not disabled
          guide_obj <- scale$guide
          if (!inherits(guide_obj, "GuideNone") &&
              !identical(guide_obj, "none") &&
              !identical(guide_obj, FALSE)) {
            legend_aesthetics <- c(legend_aesthetics, aes_name)
          }
        }
      }
    }

    # Remove duplicates and normalize color/colour
    legend_aesthetics <- unique(legend_aesthetics)
    if ("color" %in% legend_aesthetics) {
      legend_aesthetics <- setdiff(legend_aesthetics, "color")
      if (!"colour" %in% legend_aesthetics) {
        legend_aesthetics <- c(legend_aesthetics, "colour")
      }
    }

    # Extract guide data for each aesthetic
    for (aes_name in legend_aesthetics) {
      guide_data <- tryCatch(
        ggplot2::get_guide_data(p, aesthetic = aes_name),
        error = function(e) NULL
      )

      if (is.null(guide_data) || nrow(guide_data) == 0) {
        next
      }

      # Get the scale object
      scale_obj <- b$plot$scales$get_scales(aes_name)
      if (is.null(scale_obj)) next

      # Determine guide type: only colour/fill continuous scales get colorbar
      is_continuous <- inherits(scale_obj, "ScaleContinuous")
      is_color_aes <- aes_name %in% c("colour", "fill")
      guide_type <- if (is_continuous && is_color_aes) "colorbar" else "legend"

      # Get title from scale name or plot labels
      title <- scale_obj$name
      if (is.null(title) || identical(title, waiver())) {
        title <- b$plot$labels[[aes_name]] %||% aes_name
      }

      # Convert guide_data to list of keys
      keys_list <- list()
      for (i in seq_len(nrow(guide_data))) {
        key <- list()

        # Add standard fields
        if (".value" %in% names(guide_data)) {
          key$value <- guide_data[[".value"]][i]
        }
        if (".label" %in% names(guide_data)) {
          key$label <- as.character(guide_data[[".label"]][i])
        }

        # Add aesthetic-specific values
        if (aes_name %in% names(guide_data)) {
          key[[aes_name]] <- guide_data[[aes_name]][i]
        }
        # Also check for normalized names
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

      # For colorbar, generate additional color stops for smooth gradient
      colors_array <- NULL
      if (guide_type == "colorbar") {
        # Get domain from scale
        scale_domain <- tryCatch(
          scale_obj$get_limits(),
          error = function(e) c(0, 1)
        )

        # Generate 30 evenly-spaced values for smooth gradient
        color_values <- seq(scale_domain[1], scale_domain[2], length.out = 30)

        # Map through scale to get colors
        colors_array <- tryCatch(
          scale_obj$map(color_values),
          error = function(e) NULL
        )
      }

      # Build guide specification
      guide_spec <- list(
        aesthetic = aes_name,
        aesthetics = list(aes_name),  # Will be updated if merged
        type = guide_type,
        title = as.character(title),
        keys = keys_list,
        colors = colors_array
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
            next  # Already processed as part of a merge
          }

          # Find all guides with this title
          matching_indices <- which(guide_titles == title)

          if (length(matching_indices) > 1) {
            # Merge guides with same title
            merged_guide <- guide
            merged_aesthetics <- list()

            for (idx in matching_indices) {
              merged_aesthetics[[length(merged_aesthetics) + 1]] <- guides_ir[[idx]]$aesthetic

              # Merge key columns from all aesthetics
              if (idx > matching_indices[1]) {
                other_guide <- guides_ir[[idx]]
                for (j in seq_along(merged_guide$keys)) {
                  if (j <= length(other_guide$keys)) {
                    # Add columns from other guide's keys
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
            # Single guide with unique title
            merged_guides[[length(merged_guides) + 1]] <- guide
            processed_titles <- c(processed_titles, title)
          }
        }

        guides_ir <- merged_guides
      }
    }
  }

  # Extract additional legend theme elements
  legend_theme <- NULL
  if (!is.null(b$plot$theme)) {
    # Extract legend.key.size (unit to pixels conversion)
    key_size <- tryCatch({
      complete_theme <- ggplot2::theme_get() + b$plot$theme
      key_size_elem <- ggplot2:::calc_element("legend.key.size", complete_theme)
      if (!is.null(key_size_elem)) {
        # Convert unit to pixels
        inches <- grid::convertUnit(key_size_elem, "inches", valueOnly = TRUE)
        inches * 96  # Convert to pixels
      } else {
        NULL
      }
    }, error = function(e) NULL)

    legend_theme <- list(
      key.size = key_size,
      text = extract_theme_element("legend.text", b$plot$theme),
      title = extract_theme_element("legend.title", b$plot$theme),
      background = extract_theme_element("legend.background", b$plot$theme),
      key = extract_theme_element("legend.key", b$plot$theme)
    )
  }

  # Add legend theme elements to theme_ir
  if (!is.null(theme_ir) && !is.null(legend_theme)) {
    theme_ir$legend <- legend_theme
  }

  # Extract strip theme elements for facets
  strip_theme <- NULL
  if (!is.null(b$plot$theme)) {
    strip_theme <- list(
      text = extract_theme_element("strip.text", b$plot$theme),
      background = extract_theme_element("strip.background", b$plot$theme)
    )
  }

  # Add strip to theme_ir
  if (!is.null(theme_ir) && !is.null(strip_theme)) {
    theme_ir$strip <- strip_theme
  }

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
        complete_theme <- ggplot2::theme_get() + b$plot$theme
        spacing <- ggplot2:::calc_element("panel.spacing", complete_theme)
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
        complete_theme <- ggplot2::theme_get() + b$plot$theme
        spacing <- ggplot2:::calc_element("panel.spacing", complete_theme)
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
