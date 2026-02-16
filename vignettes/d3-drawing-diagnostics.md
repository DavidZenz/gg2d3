# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.

## Geom coverage

gg2d3 supports 15 geom types (point, line, path, bar, col, rect, tile, text,
area, ribbon, segment, hline/vline/abline, boxplot, violin, density, smooth).
Geoms not in this list (e.g. `geom_polygon`, `geom_contour`, `geom_sf`) will
log a warning and not render.

## Text options

`geom_text` supports position, size, color, and alpha. Rotation (`angle`),
justification (`hjust`/`vjust`), and font family are not yet translated.

## Linetype

Dashed and dotted linetypes (`linetype = "dashed"`, `"dotted"`, etc.) are
translated to SVG `stroke-dasharray` patterns. Custom numeric linetype
specifications may not match ggplot2 exactly.

## Theme translation

Most theme elements are translated, but some edge cases are not covered:

- `element_blank()` is handled, but `element_line(arrow = ...)` is not
- `strip.text` rotation is not supported
- `plot.margin` is partially supported (outer margins only)

## Rect/tile edge cases

`geom_rect` and `geom_tile` may render incorrectly when coordinates extend
outside the panel area (negative widths/heights). Clipping is applied at the
panel boundary.

## Private API dependency

The package uses `ggplot2:::calc_element()` to resolve inherited theme
elements. This private API could change in future ggplot2 releases. If theme
translation breaks after a ggplot2 update, this is the likely cause.

## Extension packages

Geoms from ggplot2 extension packages (ggridges, ggrepel, ggforce, etc.) are
not supported. Only geoms from core ggplot2 are recognized by the renderer.
