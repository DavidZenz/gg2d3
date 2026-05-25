#' Add tooltips to gg2d3 widget
#'
#' Enables interactive tooltips on hover for a gg2d3 widget. Tooltips display
#' data values associated with each visual element (points, bars, etc.).
#'
#' For ordinary `geom_polygon()` paths and `geom_sf()` polygon-family,
#' point-family, line-family, `geom_sf_text()`, and `geom_sf_label()` marks,
#' tooltips reuse the existing callback path. Tooltip data uses sanitized
#' source-row payloads and does not expose renderer-private fields.
#'
#' @param widget A gg2d3 widget object created by \code{gg2d3()}
#' @param fields Character vector of field names to display in tooltip.
#'   Accepts either original data variable names (e.g. \code{"wt"},
#'   \code{"mpg"}) or internal aesthetic keys (e.g. \code{"x"}, \code{"y"},
#'   \code{"colour"}). Variable names are resolved via the plot's aesthetic
#'   mapping; mapped expressions like \code{factor(cyl)} can only be addressed
#'   by aesthetic key. If \code{NULL} (default), shows all aesthetics except
#'   internal fields (those starting with underscore or internal keys like
#'   PANEL, group, etc.)
#' @param formatter Optional JavaScript function as string for custom value
#'   formatting. Function signature: \code{function(field, value) { return formatted_string; }}
#'
#' @return Modified gg2d3 widget with tooltip interactivity enabled.
#'   Returns the widget to enable pipe chaining.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
#'
#' # Basic tooltip with all fields
#' gg2d3(p) |> d3_tooltip()
#'
#' # Show only specific fields
#' gg2d3(p) |> d3_tooltip(fields = c("mpg", "wt"))
#'
#' # Custom formatter
#' gg2d3(p) |> d3_tooltip(
#'   formatter = "if (field === 'mpg') return field + ': ' + value + ' mpg'; return field + ': ' + value;"
#' )
#' }
#'
#' @export
d3_tooltip <- function(widget, fields = NULL, formatter = NULL) {
  # Validate input
  if (!inherits(widget, "gg2d3")) {
    stop("d3_tooltip() requires a gg2d3 widget object. Did you call gg2d3() first?")
  }

  # Initialize interactivity config if not present
  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  # Add tooltip configuration
  widget$x$interactivity$tooltip <- list(
    enabled = TRUE,
    fields = fields,
    formatter = formatter
  )

  # Attach JavaScript to process config after render
  # Use setTimeout to defer until next tick, ensuring SVG is fully rendered
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.tooltip) {
          window.gg2d3.events.attachTooltips(el, x.interactivity.tooltip, x.ir);
        }
      }, 0);
    }
  ")

  return(widget)
}
