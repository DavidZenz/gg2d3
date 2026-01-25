#' Build a D3-ready IR (intermediate representation) from a ggplot
#' @export
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)

  `%||%` <- function(x, y) if (is.null(x)) y else x

  keep_aes <- c(
    "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
    "colour","fill","size","alpha","group","label"
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
                    GeomSmooth = "path",
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
      "colour","fill","size","alpha","group","label"
    )

    # coerce + rowize (same as your latest version)
    to_rows <- function(df) {
      if (is.null(df) || !nrow(df)) return(list())
      df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
      df[] <- lapply(df, function(col) {
        if (is.factor(col)) as.character(col)
        else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000
        else if (inherits(col, "Date")) as.numeric(col) * 86400000
        else col
      })
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
      label = if ("label" %in% cols) "label" else NULL
    )

    list(
      geom   = gname,          # <-- now always a non-NULL string like "point"
      data   = to_rows(df),
      aes    = aes,
      params = b$plot$layers[[i]]$aes_params
    )
  })

  # Check if scale is discrete and get proper domain
  get_scale_info <- function(scale_obj, data_values) {
    if (inherits(scale_obj, "ScaleDiscrete")) {
      # Discrete scale: get labels from scale object
      domain <- scale_obj$get_limits()
      list(type = "categorical", domain = unname(domain))
    } else {
      # Continuous scale: get range and apply ggplot2's default 5% expansion
      if (is.null(data_values) || length(data_values) == 0) {
        list(type = "continuous", domain = c(0, 1))
      } else {
        # Get the base scale range
        scale_range <- tryCatch(
          scale_obj$get_limits(),
          error = function(e) range(data_values, finite = TRUE)
        )

        # Apply ggplot2's default expansion (5% on each side)
        range_span <- diff(scale_range)
        expansion <- range_span * 0.05
        expanded_range <- c(scale_range[1] - expansion, scale_range[2] + expansion)

        # For scales that include 0, don't expand below 0 if data is all positive
        # (matches ggplot2 behavior for bar charts)
        if (scale_range[1] >= 0 && expanded_range[1] < 0) {
          expanded_range[1] <- 0
        }

        list(type = "continuous", domain = unname(expanded_range))
      }
    }
  }

  allx <- unlist(lapply(b$data, function(df) if ("x" %in% names(df)) df$x))
  ally <- unlist(lapply(b$data, function(df) if ("y" %in% names(df)) df$y))
  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))

  # Helper for color domain
  dom <- function(v) {
    if (is.null(v) || length(v) == 0) return(numeric(0))
    if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
  }

  # Extract grid breaks from panel params
  x_breaks <- b$layout$panel_params[[1]]$x$breaks
  y_breaks <- b$layout$panel_params[[1]]$y$breaks
  x_minor_breaks <- b$layout$panel_params[[1]]$x$minor_breaks
  y_minor_breaks <- b$layout$panel_params[[1]]$y$minor_breaks

  # Remove NA values (ggplot2 adds NAs at the edges)
  x_breaks <- x_breaks[!is.na(x_breaks)]
  y_breaks <- y_breaks[!is.na(y_breaks)]
  x_minor_breaks <- if (!is.null(x_minor_breaks)) x_minor_breaks[!is.na(x_minor_breaks)] else NULL
  y_minor_breaks <- if (!is.null(y_minor_breaks)) y_minor_breaks[!is.na(y_minor_breaks)] else NULL

  scales <- list(
    x = c(get_scale_info(xscale_obj, allx), list(
      breaks = unname(x_breaks),
      minor_breaks = if (!is.null(x_minor_breaks)) unname(x_minor_breaks) else NULL
    )),
    y = c(get_scale_info(yscale_obj, ally), list(
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
        text = extract_theme_element("axis.text", b$plot$theme),
        title = extract_theme_element("axis.title", b$plot$theme),
        ticks = extract_theme_element("axis.ticks", b$plot$theme)
      ),
      text = list(
        title = extract_theme_element("plot.title", b$plot$theme)
      )
    )
  }

  list(
    width = width, height = height, padding = padding,
    coord  = list(type = "cartesian", flip = inherits(b$plot$coordinates, "CoordFlip")),
    title  = b$plot$labels$title %||% "",
    axes   = list(
      x = list(orientation = "bottom", label = b$plot$labels$x %||% ""),
      y = list(orientation = "left",  label = b$plot$labels$y %||% "")
    ),
    facets = list(type = "grid", rows = 1, cols = 1,
                  layout = data.frame(panel = 1, row = 1, col = 1)),
    scales = scales,
    layers = layers,
    legend = list(enabled = TRUE),
    theme = theme_ir
  )
}
