# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.

## Geom coverage

gg2d3 supports core Cartesian geoms (point, line, path, bar, col, rect, tile,
text, area, ribbon, segment, hline/vline/abline, boxplot, violin, density,
smooth) plus polygon-family `geom_sf`.

Geoms outside this set (for example `geom_contour`) log a warning and do not
render.

## Polygon-family `geom_sf` support

`geom_sf()` support exists for polygon-family layers: `POLYGON` and
`MULTIPOLYGON` geometries render as SVG paths for choropleths and polygon
overlays. Known CRS inputs are normalized to WGS84 in R before serialization.
If a layer has no CRS, gg2d3 warns that coordinates will be serialized as-is.

Unsupported, empty, invalid, or missing sf geometries are skipped with a
warning while valid polygon rows remain renderable. Non-polygon sf rendering is
not supported in v1.8.

Map anti-features are explicit: no tile basemaps, no slippy map controls, no
JavaScript-side CRS reprojection, no polygon-overlap brushing, no non-polygon
sf rendering, and no large-map performance guarantees.

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
