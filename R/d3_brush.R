#' Add brush selection to gg2d3 widget
#'
#' Enables rectangular brush selection for a gg2d3 widget. Click and drag to
#' create a selection rectangle; data points inside the selection are highlighted
#' while points outside are dimmed. Double-click to clear the selection.
#'
#' @param widget A gg2d3 widget object created by \code{gg2d3()}
#' @param direction Character string specifying brush direction.
#'   One of:
#'   \itemize{
#'     \item \code{"xy"} (default): Two-dimensional rectangular brush
#'     \item \code{"x"}: Horizontal band selection (x-axis only)
#'     \item \code{"y"}: Vertical band selection (y-axis only)
#'   }
#' @param on_brush Optional JavaScript callback as string. Receives selected
#'   data as array. Function signature: \code{function(selectedData) { ... }}
#' @param fill Brush overlay fill color. Default is \code{"#3b82f6"} (light blue).
#' @param opacity Numeric opacity value (0-1) for non-selected elements.
#'   Default is 0.15 (heavily dimmed). Selected elements always have opacity 1.0.
#'
#' @return Modified gg2d3 widget with brush selection enabled.
#'   Returns the widget to enable pipe chaining.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
#'
#' # Basic brush selection
#' gg2d3(p) |> d3_brush()
#'
#' # Horizontal brush only
#' gg2d3(p) |> d3_brush(direction = "x")
#'
#' # Custom styling
#' gg2d3(p) |> d3_brush(fill = "#ff0000", opacity = 0.3)
#'
#' # Combine with tooltips
#' gg2d3(p) |> d3_tooltip() |> d3_brush()
#' }
#'
#' @export
d3_brush <- function(widget, direction = c("xy", "x", "y"),
                     on_brush = NULL, fill = "#3b82f6", opacity = 0.15) {
  # Validate input
  if (!inherits(widget, "gg2d3")) {
    stop("d3_brush() requires a gg2d3 widget object. Did you call gg2d3() first?")
  }

  # Validate direction
  direction <- match.arg(direction)

  # Validate opacity
  if (!is.numeric(opacity) || opacity < 0 || opacity > 1) {
    stop("opacity must be a numeric value between 0 and 1")
  }

  # Initialize interactivity config if not present
  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  # Add brush configuration
  widget$x$interactivity$brush <- list(
    enabled = TRUE,
    direction = direction,
    on_brush = on_brush,
    fill = fill,
    opacity = opacity
  )

  # Attach JavaScript to process config after render
  # Use setTimeout to defer until next tick, ensuring SVG is fully rendered
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.brush) {
          window.gg2d3.brush.attach(el, x.interactivity.brush, x.ir);
        }
      }, 0);
    }
  ")

  return(widget)
}
