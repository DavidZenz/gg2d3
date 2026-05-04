# Scales extraction for the ggplot2 -> D3 IR pipeline.
#
# Owns the scales slice (Phase 13 REFACTOR-01). All functions are
# package-internal (no @export). Lifted verbatim from R/as_d3_ir.R as part
# of the internals refactor; see .planning/phases/13-internals-refactor/.
#
# Re-uses `dom` from R/ir_utils.R for color-domain assembly. Does NOT touch
# ggplot2 private API (only ir_theme.R is allowed to reach for `:::`).

#' Map discrete x/y values to their labels.
#'
#' Lifted verbatim from `R/as_d3_ir.R` (v1.0). `scale_obj` was already an
#' explicit argument in the original closure — no rewrite needed.
#'
#' @keywords internal
#' @noRd
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

#' Validate log scale domains (must be strictly positive).
#'
#' Lifted verbatim from `R/as_d3_ir.R` (v1.0). Emits the same `stop()` with
#' the v1.0 message text on invalid log domains.
#'
#' @keywords internal
#' @noRd
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

#' Extract scale transformation metadata for IR.
#'
#' Lifted verbatim from `R/as_d3_ir.R` (v1.0).
#'
#' @keywords internal
#' @noRd
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

#' Check if scale is discrete and get proper domain.
#'
#' Lifted verbatim from `R/as_d3_ir.R` (v1.0). The `tryCatch` block that
#' walks `environment(scale_obj$labels)$f` is intentional and load-bearing
#' for date/time scale formatting — see Phase 13 RESEARCH Pitfall 4.
#'
#' @keywords internal
#' @noRd
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
      # Compensates for ggplot2 lacking a public field for date_labels / timezone
      # — see Phase 13 RESEARCH Pitfall 4. DO NOT "clean up" the env-walking
      # logic; it walks ggproto method -> underlying function closure to
      # recover information ggplot2 does not expose publicly.
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

#' Extract the scales slice of the IR.
#'
#' Pure function of ggplot_build output + per-panel params. Replaces the
#' inline scales-assembly block in the v1.0 orchestrator (`R/as_d3_ir.R`).
#'
#' `is_flip` is accepted for API consistency with the other extractors
#' (Pattern E: uniform extractor signature). The scales block does not
#' branch on it directly because the orchestrator already un-swaps
#' `pp_x`/`pp_y` before calling.
#'
#' @keywords internal
#' @noRd
extract_scales_ir <- function(b, pp_x, pp_y, is_flip = FALSE) {
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # Breaks (lifted verbatim from the v1.0 orchestrator's scales block,
  # including the temporal `* 86400000` for Date and `* 1000` for POSIXct
  # conversions on x_breaks / y_breaks / minor_breaks).
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

  # Color scale — lifted from the orchestrator's `allc` + `dom(allc)` block.
  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))
  if (length(allc)) {
    scales$color <- list(
      type = if (is.numeric(allc)) "continuous" else "categorical",
      domain = unname(dom(allc))
    )
  }

  scales
}
