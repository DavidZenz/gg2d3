# Layer extraction. Pure function of ggplot_build output + scale objects.
# Lifted from R/as_d3_ir.R lines 59-202 (v1.0). The duplicated inner `to_rows`
# closure (v1.0 lines 131-152) is gone — callers use the top-level
# to_rows(df, keep_aes) from R/ir_utils.R with an explicit keep_aes argument.
# The outer dead-code `to_rows` (v1.0 line 27) and orchestrator-scope
# `keep_aes` (v1.0 lines 20-24) are deleted from the orchestrator entirely.

#' @keywords internal
#' @noRd
extract_layers_ir <- function(b, xscale_obj, yscale_obj) {
  # Aesthetic + computed-stat columns to keep when row-izing layer data.
  # Lifted from the inner closure scope (v1.0 R/as_d3_ir.R:119-128).
  keep_aes <- c(
    "PANEL", "x", "y", "xend", "yend", "xmin", "xmax", "ymin", "ymax",
    "colour", "fill", "size", "alpha", "group", "label",
    "stroke", "shape", "linewidth", "linetype", "lineend",
    "slope", "intercept", "xintercept", "yintercept",
    # Statistical geom computed columns
    "lower", "middle", "upper", "outliers", "notchupper", "notchlower",
    "width", "violinwidth", "density", "scaled", "count", "ncount", "ndensity",
    "weight"
  )

  lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]

    # Map discrete x/y values to their labels (only if column exists and has values).
    # Lifted verbatim from R/as_d3_ir.R:62-80 (v1.0).
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

    # --- robust geom name --- (lifted verbatim from R/as_d3_ir.R:82-116)
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
                    {
                      if (!is.null(gobj$objname)) {
                        gobj$objname
                      } else {
                        sub("^Geom", "", gcl) |>
                          tolower()
                      }
                    }
    )

    # aes mapping summary (lifted verbatim from R/as_d3_ir.R:154-174).
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

    # Convert temporal data columns to milliseconds (ggplot_build strips
    # Date/POSIXct class, leaving plain numeric days or seconds).
    # Lifted verbatim from R/as_d3_ir.R:179-194. PATTERNS Anti-Pattern:
    # do not consolidate with scales/facets temporal conversions.
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

    list(
      geom   = gname,
      data   = to_rows(df, keep_aes),  # explicit keep_aes (was closure capture in v1.0)
      aes    = aes,
      params = b$plot$layers[[i]]$aes_params
    )
  })
}
