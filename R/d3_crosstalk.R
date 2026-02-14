#' Internal crosstalk utilities
#'
#' Helper functions for crosstalk SharedData detection and metadata extraction.
#' These are internal utilities not exported to users.
#'
#' @name d3_crosstalk_internal
#' @keywords internal
NULL

#' Check if object is crosstalk SharedData
#'
#' @param x Object to check
#' @return Logical TRUE if x is SharedData, FALSE otherwise
#' @keywords internal
is_shared_data <- function(x) {
  requireNamespace("crosstalk", quietly = TRUE) && crosstalk::is.SharedData(x)
}

#' Extract crosstalk metadata from ggplot object
#'
#' Checks if ggplot's data layer is a SharedData object and extracts
#' the crosstalk key and group name for linked brushing.
#'
#' @param ggplot_obj A ggplot2 object
#' @return List with crosstalk_key and crosstalk_group, or NULL if not SharedData
#' @keywords internal
extract_crosstalk_meta <- function(ggplot_obj) {
  if (!inherits(ggplot_obj, "ggplot")) {
    return(NULL)
  }

  if (is_shared_data(ggplot_obj$data)) {
    return(list(
      crosstalk_key = ggplot_obj$data$key(),
      crosstalk_group = ggplot_obj$data$groupName()
    ))
  }

  return(NULL)
}
