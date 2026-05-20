#' Extract sf geometries from ggplot_build layer data as GeoJSON strings
#'
#' Extracts the sfc geometry column from a data.frame produced by
#' `ggplot_build()$data[[i]]`, normalizes CRS to WGS84 unconditionally (per D-11),
#' and serializes each geometry as a GeoJSON geometry string via
#' `geojsonsf::sfc_geojson()` (per D-10).
#'
#' gg2d3's public `geom_sf()` renderer is limited to polygon-family
#' `POLYGON` and `MULTIPOLYGON` layers. Missing CRS emits
#' "geom_sf layer has missing CRS; coordinates will be serialized as-is".
#' Unsupported, empty, invalid, or missing geometries emit
#' "geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries"
#' and are skipped before rendering.
#'
#' @param df A data.frame from `ggplot_build()$data[[i]]` containing an sfc column
#' @return Character vector of GeoJSON geometry strings, one per row
#' @export
extract_sf_geometries <- function(df) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for geom_sf support. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop(
      "The 'geojsonsf' package is required for geom_sf support. ",
      "Install with: install.packages('geojsonsf')",
      call. = FALSE
    )
  }

  # Per D-12: detect geometry column dynamically; sf_column attr is NULL after
  # ggplot_build() so fallback to class-based detection is the primary path
  geom_col_name <- attr(df, "sf_column")
  if (is.null(geom_col_name)) {
    candidates <- names(df)[vapply(df, inherits, logical(1L), "sfc")]
    geom_col_name <- if (length(candidates) > 0L) candidates[[1L]] else NA_character_
  }
  if (is.na(geom_col_name) || is.null(geom_col_name)) {
    stop("Could not find sfc geometry column in sf layer data", call. = FALSE)
  }

  geom_col <- df[[geom_col_name]]

  # Per D-11: unconditional CRS normalization to WGS84
  geom_col <- normalize_to_wgs84(geom_col)

  # Per D-10: use geojsonsf::sfc_geojson() for serialization
  as.character(geojsonsf::sfc_geojson(geom_col))
}


#' Prepare sf geometries for gg2d3 IR
#'
#' Internal helper used by the geom_sf IR path. Filters unsupported or
#' non-renderable rows before GeoJSON serialization, while preserving source row
#' identity for downstream data/geometry joins.
#'
#' Only `POLYGON` and `MULTIPOLYGON` geometries are accepted by default. Missing
#' CRS warns with "geom_sf layer has missing CRS; coordinates will be serialized
#' as-is". Skipped rows warn with "geom_sf layer skipped %d unsupported, empty,
#' invalid, or missing geometries".
#'
#' @param df A data.frame containing an sfc geometry column
#' @param supported_types Character vector of geometry types to retain
#' @param warn Whether to emit user-facing warnings for skipped rows and missing CRS
#' @return A list with filtered data, GeoJSON geometries, normalized geometry,
#'   CRS metadata, dominant accepted geometry type, and sf diagnostics
prepare_sf_geometry_ir <- function(df,
                                   supported_types = c("POLYGON", "MULTIPOLYGON"),
                                   warn = TRUE) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for geom_sf support. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop(
      "The 'geojsonsf' package is required for geom_sf support. ",
      "Install with: install.packages('geojsonsf')",
      call. = FALSE
    )
  }

  geom_col_name <- attr(df, "sf_column")
  if (is.null(geom_col_name)) {
    candidates <- names(df)[vapply(df, inherits, logical(1L), "sfc")]
    geom_col_name <- if (length(candidates) > 0L) candidates[[1L]] else NA_character_
  }
  if (is.na(geom_col_name) || is.null(geom_col_name)) {
    stop("Could not find sfc geometry column in sf layer data", call. = FALSE)
  }

  geom_col <- df[[geom_col_name]]
  source_rows <- seq_len(nrow(df))
  geometry_types <- as.character(sf::st_geometry_type(geom_col, by_geometry = TRUE))
  empty <- sf::st_is_empty(geom_col)
  missing_geometry <- is.na(geom_col)
  valid <- tryCatch(
    sf::st_is_valid(geom_col),
    error = function(e) rep(FALSE, length(geom_col))
  )
  valid[is.na(valid)] <- FALSE

  supported <- geometry_types %in% supported_types
  accepted <- supported & !empty & !missing_geometry & valid
  skipped <- !accepted
  missing_crs <- is.na(sf::st_crs(geom_col))

  if (warn && missing_crs) {
    warning(
      "geom_sf layer has missing CRS; coordinates will be serialized as-is",
      call. = FALSE
    )
  }
  if (warn && any(skipped)) {
    warning(
      sprintf(
        "geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries",
        sum(skipped)
      ),
      call. = FALSE
    )
  }

  accepted_geom <- geom_col[accepted]
  accepted_geom <- normalize_to_wgs84(accepted_geom)

  accepted_data <- df[accepted, , drop = FALSE]
  accepted_data[[geom_col_name]] <- accepted_geom
  accepted_data[["row_id"]] <- source_rows[accepted]
  attr(accepted_data, "sf_column") <- geom_col_name

  geometries <- if (length(accepted_geom) > 0L) {
    as.character(geojsonsf::sfc_geojson(accepted_geom))
  } else {
    character()
  }

  accepted_geometry_types <- unique(geometry_types[accepted])
  unsupported_geometry_types <- sort(unique(geometry_types[!supported]))

  skip_reason <- function(i) {
    if (missing_geometry[[i]]) return("missing")
    if (empty[[i]]) return("empty")
    if (!valid[[i]]) return("invalid")
    if (!supported[[i]]) return("unsupported")
    "skipped"
  }
  skipped_details <- lapply(which(skipped), function(i) {
    list(
      row = source_rows[[i]],
      geometry_type = geometry_types[[i]],
      reason = skip_reason(i)
    )
  })

  crs <- sf::st_crs(accepted_geom)
  geom_type <- if (length(accepted_geometry_types) == 0L) {
    NA_character_
  } else if (length(accepted_geometry_types) == 1L) {
    accepted_geometry_types[[1L]]
  } else {
    "GEOMETRY"
  }

  list(
    data = accepted_data,
    geometries = geometries,
    geometry = accepted_geom,
    crs = list(
      epsg = if (!is.na(crs)) crs$epsg else NA_integer_,
      wkt = if (!is.na(crs)) crs$wkt else NA_character_
    ),
    geom_type = geom_type,
    sf_diagnostics = list(
      accepted_rows = source_rows[accepted],
      skipped_rows = source_rows[skipped],
      skipped = skipped_details,
      missing_crs = missing_crs,
      accepted_geometry_types = sort(accepted_geometry_types),
      unsupported_geometry_types = unsupported_geometry_types
    )
  )
}


sf_bbox_values <- function(geom) {
  if (is.null(geom) || length(geom) == 0L) {
    return(NULL)
  }

  unname(as.numeric(sf::st_bbox(geom)))
}


#' Normalize an sfc column to WGS84 (EPSG:4326)
#'
#' Transforms any projected or geographic CRS to EPSG:4326. Returns the input
#' unchanged if it is not an sfc object. If the CRS is already EPSG:4326,
#' no transformation is performed. If an sf geometry has missing CRS, the
#' `geom_sf()` IR path warns "geom_sf layer has missing CRS; coordinates will be
#' serialized as-is" and leaves coordinates unchanged.
#'
#' @param geom_col An sfc geometry column, or any other R object
#' @return The sfc column transformed to EPSG:4326, or the input unchanged if
#'   not an sfc object
#' @export
normalize_to_wgs84 <- function(geom_col) {
  if (!inherits(geom_col, "sfc")) return(geom_col)

  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for CRS normalization. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }

  current_crs <- sf::st_crs(geom_col)
  target_crs <- sf::st_crs(4326L)

  if (!is.na(current_crs) && current_crs != target_crs) {
    geom_col <- sf::st_transform(geom_col, 4326L)
  }

  geom_col
}


#' Detect the dominant geometry type in an sf layer
#'
#' Returns the summary geometry type for the sfc column in the data.frame.
#' When the column contains mixed types, `sf::st_geometry_type()` with
#' `by_geometry = FALSE` returns the shared type or "GEOMETRY". gg2d3 renders
#' polygon-family `geom_sf()` layers only: `POLYGON` and `MULTIPOLYGON`.
#'
#' @param df A data.frame from `ggplot_build()$data[[i]]` containing an sfc column
#' @return Character string such as "MULTIPOLYGON", "POLYGON", "POINT", "LINESTRING", etc.
#' @export
detect_dominant_geom_type <- function(df) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for geom_sf support. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }

  # Per D-12: dynamic column detection
  geom_col_name <- attr(df, "sf_column")
  if (is.null(geom_col_name)) {
    candidates <- names(df)[vapply(df, inherits, logical(1L), "sfc")]
    geom_col_name <- if (length(candidates) > 0L) candidates[[1L]] else NA_character_
  }
  if (is.na(geom_col_name) || is.null(geom_col_name)) {
    stop("Could not find sfc geometry column in sf layer data", call. = FALSE)
  }

  as.character(sf::st_geometry_type(df[[geom_col_name]], by_geometry = FALSE))
}


#' Get CRS information from an sf layer's geometry column
#'
#' Returns a list with the EPSG code (integer or NA) and WKT string for
#' the coordinate reference system of the geometry column. Known CRS inputs are
#' normalized to WGS84 in the `geom_sf()` IR path; missing CRS layers warn that
#' coordinates will be serialized as-is.
#'
#' @param df A data.frame from `ggplot_build()$data[[i]]` containing an sfc column
#' @return A list with fields:
#'   - `epsg`: integer EPSG code, or `NA_integer_` if not available
#'   - `wkt`: character WKT2 string, or `NA_character_` if not available
#' @export
get_layer_crs <- function(df) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for geom_sf support. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }

  # Per D-12: dynamic column detection
  geom_col_name <- attr(df, "sf_column")
  if (is.null(geom_col_name)) {
    candidates <- names(df)[vapply(df, inherits, logical(1L), "sfc")]
    geom_col_name <- if (length(candidates) > 0L) candidates[[1L]] else NA_character_
  }
  if (is.na(geom_col_name) || is.null(geom_col_name)) {
    stop("Could not find sfc geometry column in sf layer data", call. = FALSE)
  }

  crs <- sf::st_crs(df[[geom_col_name]])

  list(
    epsg = if (!is.na(crs)) crs$epsg else NA_integer_,
    wkt  = if (!is.na(crs)) crs$wkt  else NA_character_
  )
}
