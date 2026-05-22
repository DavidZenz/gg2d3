#' Add custom JavaScript event handlers to the plot
#'
#' Handlers receive public data rows for rendered marks. For `geom_sf()` layers,
#' handlers attach to `.geom-sf` polygon-family, point-family, and line-family
#' marks and pass sanitized source-row payloads to custom JavaScript callbacks
#' and Shiny-style `shiny_id` click updates.
#'
#' @param widget A gg2d3 widget.
#' @param click Optional JS function string for click events.
#' @param mouseover Optional JS function string for mouseover events.
#' @param mouseout Optional JS function string for mouseout events.
#' @param shiny_id Optional string. If provided, clicking a mark will
#'   automatically update a Shiny input with this ID.
#' @return The modified widget.
#' @export
d3_handlers <- function(widget, click = NULL, mouseover = NULL, mouseout = NULL, shiny_id = NULL) {
  if (!inherits(widget, "gg2d3")) {
    stop("d3_handlers must be applied to a gg2d3 widget", call. = FALSE)
  }

  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  widget$x$interactivity$handlers <- list(
    click = click,
    mouseover = mouseover,
    mouseout = mouseout,
    shiny_id = shiny_id
  )

  # Use htmlwidgets::onRender to attach handlers after the widget is fully initialized.
  # We use setTimeout(..., 0) to ensure the D3 rendering pass (draw) has completed.
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.handlers) {
          if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.attachHandlers) {
            window.gg2d3.events.attachHandlers(el, x.interactivity.handlers);
          }
        }
      }, 0);
    }
  ")

  widget
}
