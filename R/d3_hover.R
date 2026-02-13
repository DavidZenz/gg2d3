#' Add hover effects to gg2d3 widget
#'
#' Enables hover highlighting for a gg2d3 widget. When hovering over an element,
#' other elements are dimmed (reduced opacity) and the hovered element can
#' optionally receive a highlight stroke.
#'
#' @param widget A gg2d3 widget object created by \code{gg2d3()}
#' @param opacity Numeric opacity value (0-1) for non-hovered elements.
#'   Default is 0.7, which dims other elements while keeping them visible.
#'   The hovered element always has opacity 1.0.
#' @param stroke Optional stroke color for hovered element (e.g., "black", "#ff0000").
#'   If \code{NULL}, no highlight stroke is added.
#' @param stroke_width Optional stroke width in pixels for hovered element.
#'   Only used if \code{stroke} is provided. Default is \code{NULL}.
#'
#' @return Modified gg2d3 widget with hover effects enabled.
#'   Returns the widget to enable pipe chaining.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
#'
#' # Basic hover with default dimming
#' gg2d3(p) |> d3_hover()
#'
#' # Custom opacity
#' gg2d3(p) |> d3_hover(opacity = 0.3)
#'
#' # Add highlight stroke
#' gg2d3(p) |> d3_hover(stroke = "red", stroke_width = 2)
#'
#' # Combine with tooltips
#' gg2d3(p) |> d3_tooltip() |> d3_hover(opacity = 0.5)
#' }
#'
#' @export
d3_hover <- function(widget, opacity = 0.7, stroke = NULL, stroke_width = NULL) {
  # Validate input
  if (!inherits(widget, "gg2d3")) {
    stop("d3_hover() requires a gg2d3 widget object. Did you call gg2d3() first?")
  }

  # Validate opacity
  if (!is.numeric(opacity) || opacity < 0 || opacity > 1) {
    stop("opacity must be a numeric value between 0 and 1")
  }

  # Initialize interactivity config if not present
  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  # Add hover configuration
  widget$x$interactivity$hover <- list(
    enabled = TRUE,
    opacity = opacity,
    stroke = stroke,
    stroke_width = stroke_width
  )

  # Attach JavaScript to process config after render
  # Use setTimeout to defer until next tick, ensuring SVG is fully rendered
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.hover) {
          window.gg2d3.events.attachHover(el, x.interactivity.hover);
        }
      }, 0);
    }
  ")

  return(widget)
}
