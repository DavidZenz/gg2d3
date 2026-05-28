gg2d3_ir_theme_element <- function(element_name, theme) {
  calc <- gg2d3_calc_element(element_name, theme)

  if (is.null(calc)) {
    return(NULL)
  }

  if (inherits(calc, "element_blank")) {
    return(list(type = "blank"))
  }

  if (inherits(calc, "element_rect")) {
    linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

    return(list(
      type = "rect",
      fill = if (length(calc$fill) > 0 && !is.na(calc$fill)) calc$fill else NULL,
      colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
      linewidth = linewidth_px,
      linetype = calc$linetype
    ))
  }

  if (inherits(calc, "element_line")) {
    linewidth_px <- if (!is.null(calc$linewidth)) calc$linewidth * 3.7795275591 else NULL

    return(list(
      type = "line",
      colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
      linewidth = linewidth_px,
      linetype = calc$linetype,
      lineend = calc$lineend
    ))
  }

  if (inherits(calc, "element_text")) {
    margin_info <- if (!is.null(calc$margin)) {
      inches <- grid::convertUnit(calc$margin, "inches", valueOnly = TRUE)
      pixels <- inches * 96
      list(top = pixels[1], right = pixels[2], bottom = pixels[3], left = pixels[4])
    } else {
      NULL
    }

    return(list(
      type = "text",
      colour = if (length(calc$colour) > 0 && !is.na(calc$colour)) calc$colour else NULL,
      size = calc$size,
      face = calc$face,
      family = calc$family,
      hjust = calc$hjust,
      vjust = calc$vjust,
      angle = calc$angle,
      lineheight = calc$lineheight,
      margin = margin_info
    ))
  }

  if (inherits(calc, "margin") || "ggplot2::margin" %in% class(calc)) {
    inches <- grid::convertUnit(calc, "inches", valueOnly = TRUE)
    pixels <- inches * 96

    return(list(
      type = "margin",
      top = pixels[1],
      right = pixels[2],
      bottom = pixels[3],
      left = pixels[4]
    ))
  }

  if (inherits(calc, "unit")) {
    inches <- grid::convertUnit(calc, "inches", valueOnly = TRUE)
    return(inches * 96)
  }

  NULL
}


gg2d3_ir_theme <- function(theme) {
  if (is.null(theme)) {
    return(NULL)
  }

  list(
    panel = list(
      background = gg2d3_ir_theme_element("panel.background", theme),
      border = gg2d3_ir_theme_element("panel.border", theme)
    ),
    plot = list(
      background = gg2d3_ir_theme_element("plot.background", theme),
      margin = gg2d3_ir_theme_element("plot.margin", theme),
      title = gg2d3_ir_theme_element("plot.title", theme),
      subtitle = gg2d3_ir_theme_element("plot.subtitle", theme),
      caption = gg2d3_ir_theme_element("plot.caption", theme)
    ),
    grid = list(
      major = gg2d3_ir_theme_element("panel.grid.major", theme),
      minor = gg2d3_ir_theme_element("panel.grid.minor", theme)
    ),
    axis = list(
      line = gg2d3_ir_theme_element("axis.line", theme),
      line.x = gg2d3_ir_theme_element("axis.line.x", theme),
      line.y = gg2d3_ir_theme_element("axis.line.y", theme),
      text = gg2d3_ir_theme_element("axis.text", theme),
      text.x = gg2d3_ir_theme_element("axis.text.x", theme),
      text.y = gg2d3_ir_theme_element("axis.text.y", theme),
      title = gg2d3_ir_theme_element("axis.title", theme),
      title.x = gg2d3_ir_theme_element("axis.title.x", theme),
      title.y = gg2d3_ir_theme_element("axis.title.y", theme),
      ticks = gg2d3_ir_theme_element("axis.ticks", theme),
      ticks.x = gg2d3_ir_theme_element("axis.ticks.x", theme),
      ticks.y = gg2d3_ir_theme_element("axis.ticks.y", theme)
    ),
    global_text = gg2d3_ir_theme_element("text", theme),
    legend = list(
      background = gg2d3_ir_theme_element("legend.background", theme),
      key = gg2d3_ir_theme_element("legend.key", theme),
      text = gg2d3_ir_theme_element("legend.text", theme),
      title = gg2d3_ir_theme_element("legend.title", theme),
      margin = gg2d3_ir_theme_element("legend.margin", theme),
      spacing = gg2d3_ir_theme_element("legend.spacing", theme),
      key.size = tryCatch({
        size <- gg2d3_calc_element("legend.key.size", theme)
        inches <- grid::convertUnit(size, "inches", valueOnly = TRUE)
        inches * 96
      }, error = function(e) 23)
    ),
    strip = list(
      background = gg2d3_ir_theme_element("strip.background", theme),
      text = gg2d3_ir_theme_element("strip.text", theme),
      text.x = gg2d3_ir_theme_element("strip.text.x", theme),
      text.y = gg2d3_ir_theme_element("strip.text.y", theme)
    )
  )
}
