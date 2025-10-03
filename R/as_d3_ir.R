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

  layers <- lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]

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

  # domains directly from built data to preserve numeric
  allx <- unlist(lapply(b$data, function(df) if ("x" %in% names(df)) df$x))
  ally <- unlist(lapply(b$data, function(df) if ("y" %in% names(df)) df$y))
  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))

  dom <- function(v) {
    if (is.null(v) || length(v) == 0) return(numeric(0))
    if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
  }

  scales <- list(
    x = list(type = if (is.numeric(allx)) "continuous" else "categorical",
             domain = unname(dom(allx))),
    y = list(type = if (is.numeric(ally)) "continuous" else "categorical",
             domain = unname(dom(ally)))
  )
  if (length(allc)) {
    scales$color <- list(
      type = if (is.numeric(allc)) "continuous" else "categorical",
      domain = unname(dom(allc))
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
    legend = list(enabled = TRUE)
  )
}
