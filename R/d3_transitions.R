#' Configure D3 transitions for the widget
#'
#' @param widget A gg2d3 widget.
#' @param duration Transition duration in milliseconds (default: 500). Set to 0 to disable.
#' @param easing Easing function name (default: "cubic-in-out").
#' @return The modified widget.
#' @export
d3_transitions <- function(widget, duration = 500, easing = "cubic-in-out") {
  if (!inherits(widget, "gg2d3")) {
    stop("d3_transitions must be applied to a gg2d3 widget", call. = FALSE)
  }

  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  widget$x$interactivity$transitions <- list(
    enabled = duration > 0,
    duration = duration,
    easing = easing
  )

  widget
}
