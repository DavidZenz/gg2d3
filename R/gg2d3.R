#' Render a ggplot as a D3 widget
#' @param x ggplot object or IR list from as_d3_ir()
#' @export
gg2d3 <- function(x, width = NULL, height = NULL, elementId = NULL) {
  # Detect crosstalk SharedData
  crosstalk_key <- NULL
  crosstalk_group <- NULL

  if (inherits(x, "ggplot")) {
    # Check if ggplot's data is SharedData
    if (requireNamespace("crosstalk", quietly = TRUE) && crosstalk::is.SharedData(x$data)) {
      crosstalk_key <- x$data$key()
      crosstalk_group <- x$data$groupName()
      # Replace SharedData with its underlying data frame for ggplot_build()
      x$data <- x$data$origData()
    }
    ir <- as_d3_ir(x)
  } else if (is.list(x) && !is.null(x$scales) && !is.null(x$layers)) {
    ir <- x
  } else {
    stop("Provide a ggplot object or a valid IR list.")
  }

  # Add crosstalk metadata to widget payload
  widget_data <- list(ir = ir)
  if (!is.null(crosstalk_key)) {
    widget_data$crosstalk_key <- crosstalk_key
    widget_data$crosstalk_group <- crosstalk_group
  }

  # IMPORTANT: do NOT jsonlite::toJSON() here. htmlwidgets will serialize it.
  widget <- htmlwidgets::createWidget(
    name = "gg2d3",
    x = widget_data,
    width = width, height = height, package = "gg2d3", elementId = elementId
  )

  # Add Crosstalk dependencies when SharedData detected
  if (!is.null(crosstalk_key)) {
    widget$dependencies <- c(widget$dependencies, crosstalk::crosstalkLibs())
  }

  return(widget)
}
