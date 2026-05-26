gg2d3_ir_validate_log_domain <- function(scale_obj, domain, axis_name) {
  trans <- scale_obj$trans
  if (is.null(trans)) {
    return(invisible(TRUE))
  }

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


gg2d3_ir_scale_transform <- function(scale_obj) {
  if (is.null(scale_obj$trans)) {
    return(NULL)
  }

  trans_name <- scale_obj$trans$name
  result <- list()

  if (trans_name == "identity") {
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
    result$transform <- trans_name
  }

  result
}


gg2d3_ir_temporal_metadata <- function(scale_obj, panel_params_axis, result) {
  trans_name <- if (!is.null(scale_obj$trans)) scale_obj$trans$name else NULL
  if (is.null(trans_name) || !trans_name %in% c("date", "time")) {
    return(result)
  }

  result$domain <- gg2d3_ir_convert_temporal_values(result$domain, trans_name)

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

  if (trans_name == "time") {
    timezone <- tryCatch({
      tz_val <- scale_obj$timezone
      if (!is.null(tz_val) && tz_val != "") {
        tz_val
      } else if (is.function(scale_obj$labels)) {
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
    }, error = function(e) NULL)

    if (is.null(timezone) || timezone == "") {
      timezone <- tryCatch({
        attr(scale_obj$range$range, "tzone")[1]
      }, error = function(e) NULL)
    }

    result$timezone <- if (!is.null(timezone) && timezone != "") timezone else "UTC"
  }

  formatted_labels <- gg2d3_panel_labels(panel_params_axis)
  if (length(formatted_labels) == 0L) {
    formatted_labels <- NULL
  }
  result$labels <- formatted_labels

  result
}


gg2d3_ir_convert_temporal_values <- function(values, trans_name) {
  if (is.null(values)) {
    return(NULL)
  }

  if (!is.null(trans_name) && trans_name == "date") {
    values * 86400000
  } else if (!is.null(trans_name) && trans_name == "time") {
    values * 1000
  } else {
    values
  }
}


gg2d3_ir_axis_breaks <- function(panel_params_axis, trans_name) {
  breaks <- panel_params_axis$breaks
  minor_breaks <- panel_params_axis$minor_breaks

  breaks <- breaks[!is.na(breaks)]
  minor_breaks <- if (!is.null(minor_breaks)) minor_breaks[!is.na(minor_breaks)] else NULL

  list(
    breaks = gg2d3_ir_convert_temporal_values(breaks, trans_name),
    minor_breaks = gg2d3_ir_convert_temporal_values(minor_breaks, trans_name)
  )
}


gg2d3_ir_scale_info <- function(scale_obj, panel_params_axis, axis_name) {
  if (scale_obj$is_discrete()) {
    domain <- scale_obj$get_limits()
    return(list(type = "categorical", domain = unname(domain)))
  }

  expanded_range <- gg2d3_continuous_range(panel_params_axis)

  if (is.null(expanded_range) || length(expanded_range) != 2) {
    warning("Could not extract range from panel_params, falling back to scale limits")
    expanded_range <- tryCatch(
      scale_obj$get_limits(),
      error = function(e) c(0, 1)
    )
    if (!is.null(expanded_range) && length(expanded_range) == 2) {
      range_span <- diff(expanded_range)
      expansion <- range_span * 0.05
      expanded_range <- c(expanded_range[1] - expansion, expanded_range[2] + expansion)
    }
  }

  gg2d3_ir_validate_log_domain(scale_obj, expanded_range, axis_name)

  result <- list(type = "continuous", domain = unname(expanded_range))

  transform_info <- gg2d3_ir_scale_transform(scale_obj)
  if (!is.null(transform_info)) {
    result <- c(result, transform_info)
  }

  gg2d3_ir_temporal_metadata(scale_obj, panel_params_axis, result)
}
