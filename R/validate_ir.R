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
    "text", "label", "rect", "segment", "ribbon", "violin", "boxplot",
    "density", "smooth",
    "hline", "vline", "abline", "dotplot", "rug",
    "errorbar", "linerange", "pointrange", "polygon",
    "sf", "sf_text", "sf_label"
  )
  sf_like_geoms <- c("sf", "sf_text", "sf_label")

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

    if (layer$geom %in% sf_like_geoms) {
      if (!"geometries" %in% names(layer) || !is.character(layer$geometries)) {
        stop(sprintf("Layer %d sf layer geometries must be a character vector", i), call. = FALSE)
      }

      if (length(layer$geometries) != length(layer$data)) {
        stop(sprintf("Layer %d sf layer geometries length must match data length", i), call. = FALSE)
      }

      if (!"sf_diagnostics" %in% names(layer) || !is.list(layer$sf_diagnostics)) {
        stop(sprintf("Layer %d sf layer sf_diagnostics must be present", i), call. = FALSE)
      }

      missing_diag <- setdiff(c("accepted_rows", "skipped_rows"), names(layer$sf_diagnostics))
      if (length(missing_diag) > 0L) {
        stop(
          sprintf("Layer %d sf layer sf_diagnostics missing %s", i, missing_diag[[1L]]),
          call. = FALSE
        )
      }

      if (!is.null(layer$sf_family)) {
        valid_sf_families <- c("polygon", "point", "line", "mixed", NA_character_)
        if (!is.character(layer$sf_family) || length(layer$sf_family) != 1L ||
            !(is.na(layer$sf_family) || layer$sf_family %in% valid_sf_families)) {
          warning(sprintf("Layer %d sf layer has invalid sf_family", i), call. = FALSE)
        }
      }

      if (layer$geom %in% c("sf_text", "sf_label")) {
        expected_annotation_type <- sub("^sf_", "", layer$geom)
        if (is.null(layer$annotation_type) ||
            !is.character(layer$annotation_type) ||
            length(layer$annotation_type) != 1L ||
            !identical(layer$annotation_type, expected_annotation_type)) {
          stop(
            sprintf(
              "Layer %d sf annotation layer annotation_type must be '%s'",
              i,
              expected_annotation_type
            ),
            call. = FALSE
          )
        }
      }
    }
  }

  # Validate guides structure (optional - may not exist for older IR)
  if (!is.null(ir$guides) && length(ir$guides) > 0) {
    for (i in seq_along(ir$guides)) {
      guide <- ir$guides[[i]]

      # Check required fields
      if (!"type" %in% names(guide)) {
        stop(sprintf("Guide %d is missing required 'type' field", i), call. = FALSE)
      }

      if (!guide$type %in% c("legend", "colorbar")) {
        warning(sprintf("Guide %d has unrecognized type '%s'", i, guide$type), call. = FALSE)
      }

      if (!"keys" %in% names(guide) || length(guide$keys) == 0) {
        warning(sprintf("Guide %d (type='%s') has no keys", i, guide$type), call. = FALSE)
      }

      # Colorbar must have colors array
      if (guide$type == "colorbar" && (is.null(guide$colors) || length(guide$colors) < 2)) {
        warning(sprintf("Guide %d is colorbar but has insufficient colors array", i), call. = FALSE)
      }
    }
  }

  # Validate facets structure
  if (!is.null(ir$facets)) {
    if (!"type" %in% names(ir$facets)) {
      stop("IR facets must contain a 'type' field", call. = FALSE)
    }
    if (!ir$facets$type %in% c("null", "wrap", "grid")) {
      warning(sprintf("Unrecognized facet type '%s'", ir$facets$type), call. = FALSE)
    }
    if (ir$facets$type == "wrap") {
      if (is.null(ir$facets$layout) || length(ir$facets$layout) == 0) {
        stop("facet_wrap IR must have non-empty layout", call. = FALSE)
      }
      if (is.null(ir$facets$strips)) {
        warning("facet_wrap IR has no strips", call. = FALSE)
      }
      if (is.null(ir$facets$nrow) || is.null(ir$facets$ncol)) {
        warning("facet_wrap IR missing nrow/ncol", call. = FALSE)
      }
    }
    if (ir$facets$type == "grid") {
      if (is.null(ir$facets$layout) || length(ir$facets$layout) == 0) {
        stop("facet_grid IR must have non-empty layout", call. = FALSE)
      }
      if (is.null(ir$facets$rows) && is.null(ir$facets$cols)) {
        warning("facet_grid IR has neither rows nor cols", call. = FALSE)
      }
      if (is.null(ir$facets$row_strips) && is.null(ir$facets$col_strips)) {
        warning("facet_grid IR has no strip labels", call. = FALSE)
      }
      if (is.null(ir$facets$nrow) || is.null(ir$facets$ncol)) {
        warning("facet_grid IR missing nrow/ncol", call. = FALSE)
      }
      if (!is.null(ir$facets$scales) && !ir$facets$scales %in% c("fixed", "free", "free_x", "free_y")) {
        warning(sprintf("Unrecognized facet scales mode '%s'", ir$facets$scales), call. = FALSE)
      }
    }
  }

  # Validate panels array
  if (!is.null(ir$panels) && length(ir$panels) > 0) {
    for (i in seq_along(ir$panels)) {
      panel <- ir$panels[[i]]
      if (is.null(panel$PANEL)) {
        warning(sprintf("Panel %d missing PANEL identifier", i), call. = FALSE)
      }
      is_sf <- !is.null(ir$coord) && !is.null(ir$coord$type) && ir$coord$type == "sf"
      if (is.null(panel$x_range) && !is_sf) {
        warning(sprintf("Panel %d missing x_range", i), call. = FALSE)
      } else if (!is_sf && !is.null(panel$x_range) && !is.character(panel$x_range) && length(panel$x_range) != 2) {
        warning(sprintf("Panel %d has invalid x_range (not categorical and length != 2)", i), call. = FALSE)
      }
      if (is.null(panel$y_range) && !is_sf) {
        warning(sprintf("Panel %d missing y_range", i), call. = FALSE)
      } else if (!is_sf && !is.null(panel$y_range) && !is.character(panel$y_range) && length(panel$y_range) != 2) {
        warning(sprintf("Panel %d has invalid y_range (not categorical and length != 2)", i), call. = FALSE)
      }
      if (is_sf && !is.null(panel$sf_bbox)) {
        if (!is.numeric(panel$sf_bbox) || length(panel$sf_bbox) != 4 || any(!is.finite(panel$sf_bbox))) {
          warning(sprintf("Panel %d has invalid sf_bbox (must be 4 finite numeric values)", i), call. = FALSE)
        }
      }
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
