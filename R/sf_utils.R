#' Extract sf geometries from ggplot_build layer data as GeoJSON strings
#'
#' Extracts the sfc geometry column from a data.frame produced by
#' `ggplot_build()$data[[i]]`, normalizes CRS to WGS84 unconditionally (per D-11),
#' and serializes each geometry as a GeoJSON geometry string via
#' `geojsonsf::sfc_geojson()` (per D-10).
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


#' Normalize an sfc column to WGS84 (EPSG:4326)
#'
#' Transforms any projected or geographic CRS to EPSG:4326. Returns the input
#' unchanged if it is not an sfc object. If the CRS is already EPSG:4326,
#' no transformation is performed.
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
#' `by_geometry = FALSE` returns the shared type or "GEOMETRY".
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
#' the coordinate reference system of the geometry column.
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
