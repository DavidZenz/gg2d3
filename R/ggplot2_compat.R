gg2d3_plot_theme <- function(plot) {
  tryCatch(
    ggplot2:::plot_theme(plot), # no exported equivalent; quarantined in compat helper
    error = function(e) NULL
  )
}


gg2d3_calc_element <- function(element_name, theme, default = NULL) {
  if (is.null(theme)) {
    return(default)
  }

  element <- tryCatch(
    ggplot2:::calc_element(element_name, theme), # no exported equivalent; quarantined in compat helper
    error = function(e) NULL
  )

  if (is.null(element)) default else element
}


gg2d3_panel_axis <- function(panel_params, axis) {
  if (is.null(panel_params) || is.null(axis) || length(axis) != 1L) {
    return(NULL)
  }

  panel_params[[axis]]
}


gg2d3_continuous_range <- function(panel_params_axis) {
  if (is.null(panel_params_axis)) {
    return(NULL)
  }

  if (!is.null(panel_params_axis$continuous_range)) {
    panel_params_axis$continuous_range
  } else if (!is.null(panel_params_axis$range)) {
    panel_params_axis$range
  } else {
    NULL
  }
}


gg2d3_panel_labels <- function(panel_params_axis) {
  labels <- tryCatch(
    panel_params_axis$get_labels(),
    error = function(e) character(0)
  )

  if (is.null(labels) || length(labels) == 0L) {
    return(character(0))
  }

  labels <- labels[!is.na(labels)]
  as.character(labels)
}
