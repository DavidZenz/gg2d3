# Package-internal state. Created at package load.
# Tracks one-shot conditions that should not spam the user across a session.
.gg2d3_pkgenv <- new.env(parent = emptyenv())
.gg2d3_pkgenv$calc_element_warned <- FALSE

#' Reset the once-per-session warn flag for `calc_element_safe`.
#'
#' Test-only hook so `tests/testthat/test-ir-theme.R` can exercise both the
#' "first call warns" and "subsequent calls are silent" branches deterministically.
#' Not exported.
#'
#' @keywords internal
#' @noRd
.gg2d3_reset_calc_element_warned <- function() {
  .gg2d3_pkgenv$calc_element_warned <- FALSE
  invisible(NULL)
}
