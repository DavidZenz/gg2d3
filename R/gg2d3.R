#' Render a ggplot as a D3 widget
#' @param x ggplot object or IR list from as_d3_ir()
#' @export
gg2d3 <- function(x, width = NULL, height = NULL, elementId = NULL) {
  if (inherits(x, "ggplot")) {
    ir <- as_d3_ir(x)
  } else if (is.list(x) && !is.null(x$scales) && !is.null(x$layers)) {
    ir <- x
  } else {
    stop("Provide a ggplot object or a valid IR list.")
  }

  # IMPORTANT: do NOT jsonlite::toJSON() here. htmlwidgets will serialize it.
  htmlwidgets::createWidget(
    name = "gg2d3",
    x = list(ir = ir),
    width = width, height = height, package = "gg2d3", elementId = elementId
  )
}
