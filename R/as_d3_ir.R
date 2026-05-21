#' Build a D3-ready IR (intermediate representation) from a ggplot
#' @export
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)
  is_flip <- inherits(b$plot$coordinates, "CoordFlip")

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
    if (scale_obj$is_discrete() && is.numeric(values)) {
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
    calc <- tryCatch(ggplot2:::calc_element(element_name, theme), error = function(e) NULL)

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
        fill = if (length(calc$fill) > 0 && !is.na(calc$fill)) calc$fill else NULL,
        colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
        linewidth = linewidth_px,
        linetype = calc$linetype
      ))
    }

    if (inherits(calc, "element_line")) {
      # Convert linewidth from mm to pixels (1mm = 96/25.4 px at 96 DPI)
      linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

      return(list(
        type = "line",
        colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
        linewidth = linewidth_px,
        linetype = calc$linetype,
        lineend = calc$lineend
      ))
    }

    if (inherits(calc, "element_text")) {
      # Extract margin if present
      margin_info <- if (!is.null(calc$margin)) {
        inches <- grid::convertUnit(calc$margin, "inches", valueOnly = TRUE)
        pixels <- inches * 96
        list(top = pixels[1], right = pixels[2], bottom = pixels[3], left = pixels[4])
      } else {
        NULL
      }

      return(list(
        type = "text",
        colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
        size = calc$size,
        face = calc$face,
        family = calc$family,
        hjust = calc$hjust,
        vjust = calc$vjust,
        angle = calc$angle,
        lineheight = calc$lineheight,
        margin = margin_info
      ))
    }

    # Handle margin elements (plot.margin, legend.margin)
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

    # Handle unit elements (legend.spacing, etc.)
    if (inherits(calc, "unit")) {
      inches <- grid::convertUnit(calc, "inches", valueOnly = TRUE)
      return(inches * 96)
    }

    return(NULL)
  }

  sf_coord_geometries <- list()
  sf_panel_geometries <- list()

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
                    GeomCol    = "bar",
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
                    GeomDotplot = "dotplot",
                    GeomRug    = "rug",
                    GeomErrorbar = "errorbar",
                    GeomLinerange = "linerange",
                    GeomPointrange = "pointrange",
                    GeomPolygon= "polygon",
                    GeomSf     = "sf",
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
      "weight",
      # Dotplot specific
      "stackpos","binwidth","countidx",
      # sf-specific: row index for geometry-aesthetic join (D-06)
      "row_id",".sf_family"
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
      yintercept = if ("yintercept" %in% cols) "yintercept" else NULL,
      # Dotplot
      stackpos = if ("stackpos" %in% cols) "stackpos" else NULL,
      binwidth = if ("binwidth" %in% cols) "binwidth" else NULL,
      countidx = if ("countidx" %in% cols) "countidx" else NULL
    )

    # Convert temporal data columns to milliseconds (ggplot_build strips
    # Date/POSIXct class, leaving plain numeric days or seconds)
    x_tn <- if (!is.null(xscale_obj$trans)) xscale_obj$trans$name else NULL
    y_tn <- if (!is.null(yscale_obj$trans)) yscale_obj$trans$name else NULL

    x_cols <- intersect(c("x", "xmin", "xmax", "xend", "xintercept"), names(df))
    y_cols <- intersect(c("y", "ymin", "ymax", "yend", "yintercept"), names(df))

    if (!is.null(x_tn) && x_tn == "date") {
      for (cn in x_cols) if (is.numeric(df[[cn]])) df[[cn]] <- df[[cn]] * 86400000
    } else if (!is.null(x_tn) && x_tn == "time") {
      for (cn in x_cols) if (is.numeric(df[[cn]])) df[[cn]] <- df[[cn]] * 1000
    }
    if (!is.null(y_tn) && y_tn == "date") {
      for (cn in y_cols) if (is.numeric(df[[cn]])) df[[cn]] <- df[[cn]] * 86400000
    } else if (!is.null(y_tn) && y_tn == "time") {
      for (cn in y_cols) if (is.numeric(df[[cn]])) df[[cn]] <- df[[cn]] * 1000
    }

    # Build aesthetic -> original variable name map for this layer
    # (e.g., list(x = "wt", y = "mpg", colour = "factor(cyl)")).
    # Used to let tooltip users reference original column names instead of
    # internal aesthetic keys.
    plot_mapping <- as.list(b$plot$mapping %||% list())
    layer_mapping <- as.list(b$plot$layers[[i]]$mapping %||% list())
    combined_mapping <- utils::modifyList(plot_mapping, layer_mapping)
    var_names <- list()
    if (length(combined_mapping) > 0) {
      for (nm in names(combined_mapping)) {
        label <- tryCatch(
          rlang::as_label(combined_mapping[[nm]]),
          error = function(e) NULL
        )
        if (!is.null(label) && nzchar(label)) var_names[[nm]] <- label
      }
      # ggplot2 normalizes "color" -> "colour" internally
      if (!is.null(var_names$color) && is.null(var_names$colour)) {
        var_names$colour <- var_names$color
      }
    }

    # Extract geom-specific parameters
    g_params <- b$plot$layers[[i]]$aes_params
    if (gcl == "GeomRug") {
      g_params$sides <- b$plot$layers[[i]]$geom_params$sides
    } else if (gcl == "GeomDotplot") {
      g_params$method <- b$plot$layers[[i]]$geom_params$method
      g_params$binaxis <- b$plot$layers[[i]]$geom_params$binaxis
      g_params$stackdir <- b$plot$layers[[i]]$geom_params$stackdir
    }

    if (gname == "sf") {
      sf_prepared <- prepare_sf_geometry_ir(df)
      if (length(sf_prepared$geometry) > 0L) {
        sf_coord_geometries[[length(sf_coord_geometries) + 1L]] <<- sf_prepared$geometry
        panel_values <- if ("PANEL" %in% names(sf_prepared$data)) {
          as.integer(sf_prepared$data$PANEL)
        } else {
          rep(1L, length(sf_prepared$geometry))
        }
        for (geom_idx in seq_along(sf_prepared$geometry)) {
          panel_key <- as.character(panel_values[[geom_idx]])
          existing <- sf_panel_geometries[[panel_key]]
          sf_panel_geometries[[panel_key]] <<- if (is.null(existing)) {
            sf_prepared$geometry[geom_idx]
          } else {
            c(existing, sf_prepared$geometry[geom_idx])
          }
        }
      }
      list(
        geom           = "sf",
        geom_type      = sf_prepared$geom_type,
        sf_family      = sf_prepared$sf_family,
        geometries     = sf_prepared$geometries,
        data           = to_rows(sf_prepared$data),
        aes            = aes,
        params         = g_params,
        crs            = sf_prepared$crs,
        sf_diagnostics = sf_prepared$sf_diagnostics,
        var_names      = var_names
      )
    } else {
      list(
        geom   = gname,          # <-- now always a non-NULL string like "point"
        data   = to_rows(df),
        aes    = aes,
        params = g_params,
        var_names = var_names
      )
    }
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
    if (scale_obj$is_discrete()) {
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
        format_pattern <- NULL
        if (!is.null(scale_obj$labels) && is.function(scale_obj$labels)) {
          format_pattern <- tryCatch({
            outer_env <- environment(scale_obj$labels)
            f <- outer_env$f
            if (is.function(f)) {
              inner_env <- environment(f)
              dl <- inner_env$date_labels
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
            tz_val <- scale_obj$timezone
            if (!is.null(tz_val) && tz_val != "") {
              tz_val
            } else {
              if (is.function(scale_obj$labels)) {
                env <- environment(scale_obj$labels)
                tz_val2 <- env$tz
                if (!is.null(tz_val2) && tz_val2 != "") {
                  tz_val2
                } else {
                  f <- env$f
                  if (is.function(f)) {
                    env_f <- environment(f)
                    tz_val3 <- env_f$tz
                    if (!is.null(tz_val3) && tz_val3 != "") tz_val3 else NULL
                  } else {
                    NULL
                  }
                }
              } else {
                NULL
              }
            }
          }, error = function(e) NULL)

          if (is.null(timezone) || timezone == "") {
            timezone <- tryCatch({
              attr(scale_obj$range$range, "tzone")[1]
            }, error = function(e) NULL)
          }

          result$timezone <- if (!is.null(timezone) && timezone != "") timezone else "UTC"
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

  # Extract grid breaks from panel params
  if (is_flip) {
    pp_x <- b$layout$panel_params[[1]]$y
    pp_y <- b$layout$panel_params[[1]]$x
  } else {
    pp_x <- b$layout$panel_params[[1]]$x
    pp_y <- b$layout$panel_params[[1]]$y
  }

  x_breaks <- pp_x$breaks
  y_breaks <- pp_y$breaks
  x_minor_breaks <- pp_x$minor_breaks
  y_minor_breaks <- pp_y$minor_breaks

  x_breaks <- x_breaks[!is.na(x_breaks)]
  y_breaks <- y_breaks[!is.na(y_breaks)]
  x_minor_breaks <- if (!is.null(x_minor_breaks)) x_minor_breaks[!is.na(x_minor_breaks)] else NULL
  y_minor_breaks <- if (!is.null(y_minor_breaks)) y_minor_breaks[!is.na(y_minor_breaks)] else NULL

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
  th <- ggplot2:::plot_theme(b$plot)
  if (!is.null(th)) {
    theme_ir <- list(
      panel = list(
        background = extract_theme_element("panel.background", th),
        border = extract_theme_element("panel.border", th)
      ),
      plot = list(
        background = extract_theme_element("plot.background", th),
        margin = extract_theme_element("plot.margin", th),
        title = extract_theme_element("plot.title", th),
        subtitle = extract_theme_element("plot.subtitle", th),
        caption = extract_theme_element("plot.caption", th)
      ),
      grid = list(
        major = extract_theme_element("panel.grid.major", th),
        minor = extract_theme_element("panel.grid.minor", th)
      ),
      axis = list(
        line = extract_theme_element("axis.line", th),
        line.x = extract_theme_element("axis.line.x", th),
        line.y = extract_theme_element("axis.line.y", th),
        text = extract_theme_element("axis.text", th),
        text.x = extract_theme_element("axis.text.x", th),
        text.y = extract_theme_element("axis.text.y", th),
        title = extract_theme_element("axis.title", th),
        title.x = extract_theme_element("axis.title.x", th),
        title.y = extract_theme_element("axis.title.y", th),
        ticks = extract_theme_element("axis.ticks", th),
        ticks.x = extract_theme_element("axis.ticks.x", th),
        ticks.y = extract_theme_element("axis.ticks.y", th)
      ),
      global_text = extract_theme_element("text", th),
      legend = list(
        background = extract_theme_element("legend.background", th),
        key = extract_theme_element("legend.key", th),
        text = extract_theme_element("legend.text", th),
        title = extract_theme_element("legend.title", th),
        margin = extract_theme_element("legend.margin", th),
        spacing = extract_theme_element("legend.spacing", th),
        key.size = tryCatch({
          size <- ggplot2:::calc_element("legend.key.size", th)
          inches <- grid::convertUnit(size, "inches", valueOnly = TRUE)
          inches * 96
        }, error = function(e) 23)
      ),
      strip = list(
        background = extract_theme_element("strip.background", th),
        text = extract_theme_element("strip.text", th),
        text.x = extract_theme_element("strip.text.x", th),
        text.y = extract_theme_element("strip.text.y", th)
      )
    )
  }

  is_fixed    <- inherits(b$plot$coordinates, "CoordFixed")
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
  pp_x_display <- b$layout$panel_params[[1]]$x
  pp_y_display <- b$layout$panel_params[[1]]$y

  x_tick_labels <- tryCatch({
    labs <- pp_x_display$get_labels()
    labs <- labs[!is.na(labs)]
    as.character(labs)
  }, error = function(e) character(0))

  y_tick_labels <- tryCatch({
    labs <- pp_y_display$get_labels()
    labs <- labs[!is.na(labs)]
    as.character(labs)
  }, error = function(e) character(0))

  has_sec_x <- tryCatch({
    sec <- b$layout$panel_scales_x[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  has_sec_y <- tryCatch({
    sec <- b$layout$panel_scales_y[[1]]$secondary.axis
    !is.null(sec) && !inherits(sec, "waiver")
  }, error = function(e) FALSE)

  legend_position <- tryCatch({
    pos <- ggplot2:::calc_element("legend.position", th)
    if (is.character(pos)) pos else "right"
  }, error = function(e) "right")

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

  facets_ir <- NULL; panels_ir <- NULL
  tryCatch({
    is_facet_wrap <- inherits(b$layout$facet, "FacetWrap")
    is_facet_grid <- inherits(b$layout$facet, "FacetGrid")
    if (is_facet_wrap) {
      layout_df <- b$layout$layout; facet_vars <- names(b$layout$facet$params$facets)
      free_params <- b$layout$facet$params$free
      if (free_params$x && free_params$y) scales_mode <- "free" else if (free_params$x) scales_mode <- "free_x" else if (free_params$y) scales_mode <- "free_y" else scales_mode <- "fixed"
      strips <- lapply(seq_along(facet_vars), function(l) {
        var <- facet_vars[l]
        level_labels <- lapply(seq_len(nrow(layout_df)), function(i) list(PANEL = as.integer(layout_df$PANEL[i]), label = as.character(layout_df[[var]][i])))
        list(level = l, variable = var, labels = level_labels)
      })
      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip) { ppx <- pp$y; ppy <- pp$x } else { ppx <- pp$x; ppy <- pp$y }
        panel_x_range <- if (xscale_obj$is_discrete()) unname(xscale_obj$get_limits()) else unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- if (yscale_obj$is_discrete()) unname(yscale_obj$get_limits()) else unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])
        panel_x_minor_breaks <- if (!is.null(ppx$minor_breaks)) unname(ppx$minor_breaks[!is.na(ppx$minor_breaks)]) else NULL
        panel_y_minor_breaks <- if (!is.null(ppy$minor_breaks)) unname(ppy$minor_breaks[!is.na(ppy$minor_breaks)]) else NULL
        if (!is.null(x_trans_name) && x_trans_name == "date") { panel_x_range <- panel_x_range * 86400000; panel_x_breaks <- panel_x_breaks * 86400000; if (!is.null(panel_x_minor_breaks)) panel_x_minor_breaks <- panel_x_minor_breaks * 86400000
        } else if (!is.null(x_trans_name) && x_trans_name == "time") { panel_x_range <- panel_x_range * 1000; panel_x_breaks <- panel_x_breaks * 1000; if (!is.null(panel_x_minor_breaks)) panel_x_minor_breaks <- panel_x_minor_breaks * 1000 }
        if (!is.null(y_trans_name) && y_trans_name == "date") { panel_y_range <- panel_y_range * 86400000; panel_y_breaks <- panel_y_breaks * 86400000; if (!is.null(panel_y_minor_breaks)) panel_y_minor_breaks <- panel_y_minor_breaks * 86400000
        } else if (!is.null(y_trans_name) && y_trans_name == "time") { panel_y_range <- panel_y_range * 1000; panel_y_breaks <- panel_y_breaks * 1000; if (!is.null(panel_y_minor_breaks)) panel_y_minor_breaks <- panel_y_minor_breaks * 1000 }
        list(PANEL = as.integer(p), x_range = panel_x_range, y_range = panel_y_range, x_breaks = panel_x_breaks, y_breaks = panel_y_breaks, x_minor_breaks = panel_x_minor_breaks, y_minor_breaks = panel_y_minor_breaks)
      })
      panel_spacing <- tryCatch({ spacing <- ggplot2:::calc_element("panel.spacing", th); if (!is.null(spacing)) grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96 else 7.3 }, error = function(e) 7.3)
      facets_ir <- list(type = "wrap", vars = facet_vars, nrow = as.integer(max(layout_df$ROW)), ncol = as.integer(max(layout_df$COL)), scales = scales_mode, spacing = panel_spacing, layout = lapply(seq_len(nrow(layout_df)), function(i) { row <- as.list(layout_df[i, , drop = FALSE]); row$PANEL <- as.integer(row$PANEL); row$ROW <- as.integer(row$ROW); row$COL <- as.integer(row$COL); row$SCALE_X <- as.integer(row$SCALE_X); row$SCALE_Y <- as.integer(row$SCALE_Y); row }), strips = strips)
    } else if (is_facet_grid) {
      layout_df <- b$layout$layout; row_vars <- names(b$layout$facet$params$rows); col_vars <- names(b$layout$facet$params$cols)
      free_params <- b$layout$facet$params$free
      if (free_params$x && free_params$y) scales_mode <- "free" else if (free_params$x) scales_mode <- "free_x" else if (free_params$y) scales_mode <- "free_y" else scales_mode <- "fixed"
      row_strips <- NULL; if (length(row_vars) > 0) { row_combos <- unique(layout_df[, c("ROW", row_vars), drop = FALSE]); row_strips <- lapply(seq_along(row_vars), function(l) { var <- row_vars[l]; level_labels <- lapply(seq_len(nrow(row_combos)), function(i) list(ROW = as.integer(row_combos$ROW[i]), label = as.character(row_combos[[var]][i]))); list(level = l, variable = var, labels = level_labels) }) }
      col_strips <- NULL; if (length(col_vars) > 0) { col_combos <- unique(layout_df[, c("COL", col_vars), drop = FALSE]); col_strips <- lapply(seq_along(col_vars), function(l) { var <- col_vars[l]; level_labels <- lapply(seq_len(nrow(col_combos)), function(i) list(COL = as.integer(col_combos$COL[i]), label = as.character(col_combos[[var]][i]))); list(level = l, variable = var, labels = level_labels) }) }
      panels_ir <- lapply(seq_along(b$layout$panel_params), function(p) {
        pp <- b$layout$panel_params[[p]]
        if (is_flip) { ppx <- pp$y; ppy <- pp$x } else { ppx <- pp$x; ppy <- pp$y }
        panel_x_range <- if (xscale_obj$is_discrete()) unname(xscale_obj$get_limits()) else unname(ppx$continuous_range %||% ppx$range)
        panel_y_range <- if (yscale_obj$is_discrete()) unname(yscale_obj$get_limits()) else unname(ppy$continuous_range %||% ppy$range)
        panel_x_breaks <- unname(ppx$breaks[!is.na(ppx$breaks)])
        panel_y_breaks <- unname(ppy$breaks[!is.na(ppy$breaks)])
        panel_x_minor_breaks <- if (!is.null(ppx$minor_breaks)) unname(ppx$minor_breaks[!is.na(ppx$minor_breaks)]) else NULL
        panel_y_minor_breaks <- if (!is.null(ppy$minor_breaks)) unname(ppy$minor_breaks[!is.na(ppy$minor_breaks)]) else NULL
        if (!is.null(x_trans_name) && x_trans_name == "date") { panel_x_range <- panel_x_range * 86400000; panel_x_breaks <- panel_x_breaks * 86400000; if (!is.null(panel_x_minor_breaks)) panel_x_minor_breaks <- panel_x_minor_breaks * 86400000
        } else if (!is.null(x_trans_name) && x_trans_name == "time") { panel_x_range <- panel_x_range * 1000; panel_x_breaks <- panel_x_breaks * 1000; if (!is.null(panel_x_minor_breaks)) panel_x_minor_breaks <- panel_x_minor_breaks * 1000 }
        if (!is.null(y_trans_name) && y_trans_name == "date") { panel_y_range <- panel_y_range * 86400000; panel_y_breaks <- panel_y_breaks * 86400000; if (!is.null(panel_y_minor_breaks)) panel_y_minor_breaks <- panel_y_minor_breaks * 86400000
        } else if (!is.null(y_trans_name) && y_trans_name == "time") { panel_y_range <- panel_y_range * 1000; panel_y_breaks <- panel_y_breaks * 1000; if (!is.null(panel_y_minor_breaks)) panel_y_minor_breaks <- panel_y_minor_breaks * 1000 }
        list(PANEL = as.integer(p), x_range = panel_x_range, y_range = panel_y_range, x_breaks = panel_x_breaks, y_breaks = panel_y_breaks, x_minor_breaks = panel_x_minor_breaks, y_minor_breaks = panel_y_minor_breaks)
      })
      panel_spacing <- tryCatch({ spacing <- ggplot2:::calc_element("panel.spacing", th); if (!is.null(spacing)) grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96 else 7.3 }, error = function(e) 7.3)
      facets_ir <- list(type = "grid", rows = row_vars, cols = col_vars, scales = scales_mode, nrow = as.integer(max(layout_df$ROW)), ncol = as.integer(max(layout_df$COL)), spacing = panel_spacing, layout = lapply(seq_len(nrow(layout_df)), function(i) { row <- as.list(layout_df[i, , drop = FALSE]); row$PANEL <- as.integer(row$PANEL); row$ROW <- as.integer(row$ROW); row$COL <- as.integer(row$COL); row$SCALE_X <- as.integer(row$SCALE_X); row$SCALE_Y <- as.integer(row$SCALE_Y); row }), row_strips = row_strips, col_strips = col_strips)
    } else {
      facets_ir <- list(type = "null", vars = list(), nrow = 1L, ncol = 1L, layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)), strips = list())
      if (is_sf_coord) {
        # sf panels: no meaningful Cartesian x/y scale domains; bbox is on coord object
        panels_ir <- list(list(PANEL = 1L, x_range = NULL, y_range = NULL, x_breaks = NULL, y_breaks = NULL))
      } else {
        panels_ir <- list(list(PANEL = 1L, x_range = unname(scales$x$domain), y_range = unname(scales$y$domain), x_breaks = unname(x_breaks), y_breaks = unname(y_breaks)))
      }
    }
  }, error = function(e) {
    facets_ir <<- list(type = "null", vars = list(), nrow = 1L, ncol = 1L, layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)), strips = list())
    panels_ir <<- list(list(PANEL = 1L, x_range = unname(scales$x$domain), y_range = unname(scales$y$domain), x_breaks = unname(x_breaks), y_breaks = unname(y_breaks)))
  })

  if (is_sf_coord && !is.null(panels_ir)) {
    panels_ir <- lapply(panels_ir, function(panel) {
      panel_key <- as.character(panel$PANEL %||% 1L)
      panel$sf_bbox <- sf_bbox_values(sf_panel_geometries[[panel_key]])
      panel
    })
  }

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
