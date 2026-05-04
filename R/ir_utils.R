# Cross-cutting utilities used by ir_scales.R, ir_theme.R, ir_layers.R,
# ir_legends.R, ir_facets.R, and as_d3_ir.R. All internal (no @export).

#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Row-ize a data.frame into a list of named scalar lists, applying the
#' established type coercions for downstream JSON serialization.
#'
#' `keep_aes` is an explicit argument (lifted out of the closure scope it
#' captured in v1.0 `as_d3_ir.R`). Callers MUST pass the desired aesthetic
#' vector — the orchestrator's `keep_aes` (currently `as_d3_ir.R` lines 20-24)
#' is the canonical value for layer extraction.
#'
#' @keywords internal
#' @noRd
to_rows <- function(df, keep_aes) {
  if (is.null(df) || !nrow(df)) return(list())
  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") as.integer(col)
    else if (is.factor(col)) as.character(col)
    else if (inherits(col, c("POSIXct", "POSIXt"))) as.numeric(col) * 1000
    else if (inherits(col, "Date")) as.numeric(col) * 86400000
    else if (is.list(col)) I(col)
    else col
  })
  names(df) <- col_names
  rows <- vector("list", nrow(df))
  for (ii in seq_len(nrow(df))) {
    r <- lapply(df[ii, , drop = FALSE], function(v) v[[1]])
    names(r) <- names(df)
    rows[[ii]] <- r
  }
  rows
}

#' Domain helper used by scales / facets: numeric → finite range, otherwise unique.
#'
#' @keywords internal
#' @noRd
dom <- function(v) {
  if (is.null(v) || length(v) == 0) return(numeric(0))
  if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
}
