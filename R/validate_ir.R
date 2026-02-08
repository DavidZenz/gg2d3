#' Validate the structure of a D3 intermediate representation
#'
#' Checks that an IR object has the required structure before passing
#' it to JavaScript. This catches malformed IR early with informative
#' error messages.
#'
#' @param ir A list representing the intermediate representation
#' @return The IR unchanged (invisibly) if valid, otherwise throws an error
#' @keywords internal
#' @export
validate_ir <- function(ir) {
  # List of recognized geom types
  known_geoms <- c(
    "point", "line", "path", "bar", "col", "area",
    "text", "rect", "segment", "ribbon", "violin", "boxplot"
  )

  # Check that IR is a list
  if (!is.list(ir)) {
    stop("IR must be a list", call. = FALSE)
  }

  # Check for required top-level elements
  if (!"scales" %in% names(ir)) {
    stop("IR must contain a 'scales' element", call. = FALSE)
  }

  if (!"layers" %in% names(ir)) {
    stop("IR must contain a 'layers' element", call. = FALSE)
  }

  # Validate scales structure
  if (!is.list(ir$scales)) {
    stop("'scales' must be a list", call. = FALSE)
  }

  if (!"x" %in% names(ir$scales)) {
    stop("scales must contain 'x' scale definition", call. = FALSE)
  }

  if (!"y" %in% names(ir$scales)) {
    stop("scales must contain 'y' scale definition", call. = FALSE)
  }

  # Validate layers
  if (!is.list(ir$layers)) {
    stop("'layers' must be a list", call. = FALSE)
  }

  # Validate each layer
  for (i in seq_along(ir$layers)) {
    layer <- ir$layers[[i]]

    # Check for required geom element
    if (!"geom" %in% names(layer)) {
      stop(sprintf("Layer %d is missing required 'geom' element", i), call. = FALSE)
    }

    # Check that geom is a character string
    if (!is.character(layer$geom) || length(layer$geom) != 1) {
      stop(sprintf("Layer %d 'geom' must be a character string", i), call. = FALSE)
    }

    # Warn if layer has no data
    if (is.null(layer$data) || length(layer$data) == 0) {
      warning(sprintf("Layer %d (geom='%s') has no data", i, layer$geom), call. = FALSE)
    }

    # Warn if geom type is not recognized
    if (!layer$geom %in% known_geoms) {
      warning(sprintf("Layer %d uses unrecognized geom type '%s'", i, layer$geom), call. = FALSE)
    }
  }

  # Validate log scale domains
  for (axis in c("x", "y")) {
    scale <- ir$scales[[axis]]
    if (!is.null(scale$transform) && grepl("log", scale$transform, ignore.case = TRUE) &&
        !grepl("symlog", scale$transform, ignore.case = TRUE)) {
      if (any(scale$domain <= 0)) {
        stop(sprintf(
          "IR scale %s has log transform but non-positive domain [%s, %s]",
          axis, scale$domain[1], scale$domain[2]
        ), call. = FALSE)
      }
    }
  }

  # Return IR unchanged (invisibly)
  invisible(ir)
}
