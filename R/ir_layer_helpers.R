gg2d3_ir_map_discrete <- function(values, scale_obj) {
  if (scale_obj$is_discrete() && is.numeric(values)) {
    labels <- scale_obj$get_limits()
    non_na <- !is.na(values)
    if (all(values[non_na] == floor(values[non_na]))) {
      result <- rep(NA_character_, length(values))
      result[non_na] <- labels[values[non_na]]
      return(result)
    }
  }

  values
}


gg2d3_ir_layer_keep_aes <- function() {
  c(
    "PANEL", "x", "y", "xend", "yend", "xmin", "xmax", "ymin", "ymax",
    "colour", "fill", "size", "alpha", "group", "label",
    "hjust", "vjust", "angle", "family",
    "stroke", "shape", "linewidth", "linetype", "lineend",
    "slope", "intercept", "xintercept", "yintercept",
    "lower", "middle", "upper", "outliers", "notchupper", "notchlower",
    "width", "violinwidth", "density", "scaled", "count", "ncount", "ndensity",
    "weight", "stackpos", "binwidth", "countidx",
    "row_id", ".sf_family"
  )
}


gg2d3_ir_layer_rows <- function(df, keep_aes = gg2d3_ir_layer_keep_aes()) {
  if (is.null(df) || !nrow(df)) {
    return(list())
  }

  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") {
      as.integer(col)
    } else if (is.factor(col)) {
      as.character(col)
    } else if (inherits(col, c("POSIXct", "POSIXt"))) {
      as.numeric(col) * 1000
    } else if (inherits(col, "Date")) {
      as.numeric(col) * 86400000
    } else if (is.list(col)) {
      I(col)
    } else {
      col
    }
  })
  names(df) <- col_names

  rows <- vector("list", nrow(df))
  for (i in seq_len(nrow(df))) {
    row <- lapply(df[i, , drop = FALSE], function(v) v[[1]])
    names(row) <- names(df)
    rows[[i]] <- row
  }
  rows
}


gg2d3_ir_geom_name <- function(layer) {
  gobj <- layer$geom
  gcl_raw <- class(gobj)
  gcl <- gcl_raw[1]
  gname <- switch(gcl,
    GeomPoint = "point",
    GeomLine = "line",
    GeomPath = "path",
    GeomCol = "bar",
    GeomBar = "bar",
    GeomArea = "area",
    GeomText = "text",
    GeomLabel = "label",
    GeomRect = "rect",
    GeomTile = "rect",
    GeomSegment = "segment",
    GeomRibbon = "ribbon",
    GeomViolin = "violin",
    GeomBoxplot = "boxplot",
    GeomDensity = "density",
    GeomSmooth = "smooth",
    GeomHline = "hline",
    GeomVline = "vline",
    GeomAbline = "abline",
    GeomDotplot = "dotplot",
    GeomRug = "rug",
    GeomErrorbar = "errorbar",
    GeomLinerange = "linerange",
    GeomPointrange = "pointrange",
    GeomPolygon = "polygon",
    GeomSf = "sf",
    GeomSfText = "sf_text",
    GeomSfLabel = "sf_label",
    {
      if (!is.null(gobj$objname)) {
        gobj$objname
      } else {
        tolower(sub("^Geom", "", gcl))
      }
    }
  )

  stat_obj <- layer$stat
  sf_annotation_tokens <- tolower(c(
    gname,
    gcl_raw,
    if (!is.null(gobj$objname)) gobj$objname else character(),
    class(stat_obj),
    if (!is.null(stat_obj$objname)) stat_obj$objname else character()
  ))
  uses_sf_coordinates <- any(grepl("statsfcoordinates|sf_coordinates|sfcoordinates", sf_annotation_tokens))
  if (any(grepl("sf_text|sftext", sf_annotation_tokens)) ||
      (uses_sf_coordinates && identical(gcl, "GeomText"))) {
    return("sf_text")
  }
  if (any(grepl("sf_label|sflabel", sf_annotation_tokens)) ||
      (uses_sf_coordinates && identical(gcl, "GeomLabel"))) {
    return("sf_label")
  }

  gname
}


gg2d3_ir_layer_aes <- function(cols) {
  list(
    x = if ("x" %in% cols) "x" else NULL,
    y = if ("y" %in% cols) "y" else NULL,
    xend = if ("xend" %in% cols) "xend" else NULL,
    yend = if ("yend" %in% cols) "yend" else NULL,
    xmin = if ("xmin" %in% cols) "xmin" else NULL,
    xmax = if ("xmax" %in% cols) "xmax" else NULL,
    ymin = if ("ymin" %in% cols) "ymin" else NULL,
    ymax = if ("ymax" %in% cols) "ymax" else NULL,
    color = if ("colour" %in% cols) "colour" else NULL,
    fill = if ("fill" %in% cols) "fill" else NULL,
    size = if ("size" %in% cols) "size" else NULL,
    alpha = if ("alpha" %in% cols) "alpha" else NULL,
    group = if ("group" %in% cols) "group" else NULL,
    label = if ("label" %in% cols) "label" else NULL,
    slope = if ("slope" %in% cols) "slope" else NULL,
    intercept = if ("intercept" %in% cols) "intercept" else NULL,
    xintercept = if ("xintercept" %in% cols) "xintercept" else NULL,
    yintercept = if ("yintercept" %in% cols) "yintercept" else NULL,
    stackpos = if ("stackpos" %in% cols) "stackpos" else NULL,
    binwidth = if ("binwidth" %in% cols) "binwidth" else NULL,
    countidx = if ("countidx" %in% cols) "countidx" else NULL
  )
}


gg2d3_ir_apply_temporal_layer_columns <- function(df, x_trans_name, y_trans_name) {
  x_cols <- intersect(c("x", "xmin", "xmax", "xend", "xintercept"), names(df))
  y_cols <- intersect(c("y", "ymin", "ymax", "yend", "yintercept"), names(df))

  if (!is.null(x_trans_name) && x_trans_name %in% c("date", "time")) {
    for (col_name in x_cols) {
      if (is.numeric(df[[col_name]])) {
        df[[col_name]] <- gg2d3_ir_convert_temporal_values(df[[col_name]], x_trans_name)
      }
    }
  }
  if (!is.null(y_trans_name) && y_trans_name %in% c("date", "time")) {
    for (col_name in y_cols) {
      if (is.numeric(df[[col_name]])) {
        df[[col_name]] <- gg2d3_ir_convert_temporal_values(df[[col_name]], y_trans_name)
      }
    }
  }

  df
}


gg2d3_ir_var_names <- function(plot_mapping, layer_mapping) {
  plot_mapping <- as.list(if (is.null(plot_mapping)) list() else plot_mapping)
  layer_mapping <- as.list(if (is.null(layer_mapping)) list() else layer_mapping)
  combined_mapping <- utils::modifyList(plot_mapping, layer_mapping)
  var_names <- list()

  if (length(combined_mapping) > 0) {
    for (nm in names(combined_mapping)) {
      label <- tryCatch(
        rlang::as_label(combined_mapping[[nm]]),
        error = function(e) NULL
      )
      if (!is.null(label) && nzchar(label)) {
        var_names[[nm]] <- label
      }
    }
    if (!is.null(var_names$color) && is.null(var_names$colour)) {
      var_names$colour <- var_names$color
    }
  }

  var_names
}


gg2d3_ir_layer_params <- function(layer_obj, gcl) {
  params <- layer_obj$aes_params

  if (gcl == "GeomRug") {
    params$sides <- layer_obj$geom_params$sides
  } else if (gcl == "GeomDotplot") {
    params$method <- layer_obj$geom_params$method
    if (is.null(params$method)) {
      params$method <- layer_obj$stat_params$method
    }
    params$binaxis <- layer_obj$geom_params$binaxis
    if (is.null(params$binaxis)) {
      params$binaxis <- layer_obj$stat_params$binaxis
    }
    params$stackdir <- layer_obj$geom_params$stackdir
  } else if (gcl == "GeomLabel") {
    label_params <- list()
    padding <- layer_obj$geom_params$label.padding
    if (!is.null(padding)) {
      label_params$padding <- tryCatch(
        as.numeric(grid::convertUnit(padding, "pt", valueOnly = TRUE)) * 96 / 72,
        error = function(e) NULL
      )
    }
    if (length(label_params) > 0L) {
      params$label <- label_params
    }
  }

  params
}


gg2d3_ir_non_sf_layer <- function(gname, df, aes, params, var_names) {
  list(
    geom = gname,
    data = gg2d3_ir_layer_rows(df),
    aes = aes,
    params = params,
    var_names = var_names
  )
}
