#' Add zoom and pan to gg2d3 widget
#'
#' Enables mouse-wheel zoom and click-drag pan for a gg2d3 widget. Users can
#' zoom in/out with the mouse wheel, pan by dragging, and double-click to reset
#' to the original view.
#'
#' @param widget A gg2d3 widget object created by \code{gg2d3()}
#' @param scale_extent Numeric vector of length 2 specifying the minimum and
#'   maximum zoom scale factors. Default is \code{c(1, 8)}, allowing up to 8x zoom.
#'   The minimum value must be >= 1 (no zoom out beyond original view).
#' @param direction Character string specifying which axes to zoom. Options are:
#'   \describe{
#'     \item{"both"}{Zoom both x and y axes (default)}
#'     \item{"x"}{Zoom only the x-axis (horizontal zoom)}
#'     \item{"y"}{Zoom only the y-axis (vertical zoom)}
#'   }
#'
#' @return Modified gg2d3 widget with zoom interactivity enabled.
#'   Returns the widget to enable pipe chaining.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
#'
#' # Basic zoom (both axes)
#' gg2d3(p) |> d3_zoom()
#'
#' # Horizontal zoom only
#' gg2d3(p) |> d3_zoom(direction = "x")
#'
#' # Custom zoom range (1x to 16x)
#' gg2d3(p) |> d3_zoom(scale_extent = c(1, 16))
#'
#' # Combine with tooltips
#' gg2d3(p) |> d3_tooltip() |> d3_zoom()
#' }
#'
#' @export
d3_zoom <- function(widget, scale_extent = c(1, 8), direction = c("both", "x", "y")) {
  # Validate input
  if (!inherits(widget, "gg2d3")) {
    stop("d3_zoom() requires a gg2d3 widget object. Did you call gg2d3() first?")
  }

  # Validate scale_extent
  if (!is.numeric(scale_extent) || length(scale_extent) != 2) {
    stop("scale_extent must be a numeric vector of length 2")
  }
  if (scale_extent[1] < 1) {
    stop("scale_extent minimum must be >= 1 (no zoom out beyond original view)")
  }
  if (scale_extent[1] > scale_extent[2]) {
    stop("scale_extent minimum must be <= maximum")
  }

  # Validate direction
  direction <- match.arg(direction)

  # Initialize interactivity config if not present
  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  # Add zoom configuration
  widget$x$interactivity$zoom <- list(
    enabled = TRUE,
    scale_extent = scale_extent,
    direction = direction
  )

  # Attach JavaScript to process config after render
  # Use setTimeout to defer until next tick, ensuring SVG is fully rendered
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.zoom) {
          window.gg2d3.zoom.attach(el, x.interactivity.zoom, x.ir);
        }
      }, 0);
    }
  ")

  return(widget)
}
