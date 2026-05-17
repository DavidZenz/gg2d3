# Package index

## Main entry

Convert a ggplot to an interactive D3 widget.

- [`gg2d3()`](https://davidzenz.github.io/gg2d3/reference/gg2d3.md) :
  Render a ggplot as a D3 widget

## Interactivity

Composable interactivity layers (pipe with `|>`).

- [`d3_tooltip()`](https://davidzenz.github.io/gg2d3/reference/d3_tooltip.md)
  : Add tooltips to gg2d3 widget
- [`d3_hover()`](https://davidzenz.github.io/gg2d3/reference/d3_hover.md)
  : Add hover effects to gg2d3 widget
- [`d3_zoom()`](https://davidzenz.github.io/gg2d3/reference/d3_zoom.md)
  : Add zoom and pan to gg2d3 widget
- [`d3_brush()`](https://davidzenz.github.io/gg2d3/reference/d3_brush.md)
  : Add brush selection to gg2d3 widget
- [`d3_handlers()`](https://davidzenz.github.io/gg2d3/reference/d3_handlers.md)
  : Add custom JavaScript event handlers to the plot
- [`d3_transitions()`](https://davidzenz.github.io/gg2d3/reference/d3_transitions.md)
  : Configure D3 transitions for the widget

## Internals

Lower-level functions exposed for advanced use and testing.

- [`as_d3_ir()`](https://davidzenz.github.io/gg2d3/reference/as_d3_ir.md)
  : Build a D3-ready IR (intermediate representation) from a ggplot
- [`validate_ir()`](https://davidzenz.github.io/gg2d3/reference/validate_ir.md)
  : Validate the structure of a D3 intermediate representation
- [`detect_dominant_geom_type()`](https://davidzenz.github.io/gg2d3/reference/detect_dominant_geom_type.md)
  : Detect the dominant geometry type in an sf layer
- [`extract_sf_geometries()`](https://davidzenz.github.io/gg2d3/reference/extract_sf_geometries.md)
  : Extract sf geometries from ggplot_build layer data as GeoJSON
  strings
- [`get_layer_crs()`](https://davidzenz.github.io/gg2d3/reference/get_layer_crs.md)
  : Get CRS information from an sf layer's geometry column
- [`normalize_to_wgs84()`](https://davidzenz.github.io/gg2d3/reference/normalize_to_wgs84.md)
  : Normalize an sfc column to WGS84 (EPSG:4326)
