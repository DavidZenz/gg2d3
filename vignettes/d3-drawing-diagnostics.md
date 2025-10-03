# Potential pitfalls in the D3 renderer

This note documents the places in `inst/htmlwidgets/gg2d3.js` that are most
likely to cause rendering issues when the widget attempts to mirror ggplot2
output with D3. Each item links the behaviour back to the responsible code so
that follow-up fixes can be scoped quickly.

## Scale handling

* `makeScale()` now maps common descriptors (continuous, log variants, time,
  categorical, etc.) onto their corresponding D3 scale constructors. Any new
  descriptor that isn't covered will still fall back to a band scale, so
  additional transformations need explicit wiring when they appear in the
  IR.【F:inst/htmlwidgets/gg2d3.js†L30-L121】
* The coordinate flip support simply reverses the ranges that are fed into the
  scales while continuing to draw a bottom x-axis and a left y-axis. This means
  that the axes end up on the wrong side and the labels/tick orientation does
  not match a true `coord_flip()` rendering.【F:inst/htmlwidgets/gg2d3.js†L53-L59】

## Aesthetic mappings

* The colour helper only inspects `aes.color`, so fills on bars, areas, and
  rectangles ignore mapped `fill` aesthetics and fall back to `currentColor`.
  Default geom colours in `layer$params` are also ignored, so un-mapped geoms
  render with the browser default instead of ggplot's defaults.【F:inst/htmlwidgets/gg2d3.js†L84-L142】
* Alpha is handled, but size, stroke width, linetype, and text specific options
  such as `hjust`, `vjust`, `angle`, and `family` are not, causing noticeable
  visual mismatches for text and line geoms.【F:inst/htmlwidgets/gg2d3.js†L101-L160】

## Geometry coverage and grouping

* Only a small subset of geoms (`point`, `line`/`path`, `bar`/`col`, `rect`,
  and `text`) are implemented. Any other geom exported in the IR will log the
  "no marks drawn" warning and render a placeholder circle, which makes many
  common ggplot layers (e.g. `geom_area`, `geom_segment`, `geom_violin`) fail
  outright.【F:inst/htmlwidgets/gg2d3.js†L101-L169】
* Paths are always sorted by their x value before drawing. While this helps the
  `geom_line` case, it destroys intentional ordering for `geom_path` (which
  should honour data order) and any geoms that rely on the original point
  sequence to trace polygons or ribbons.【F:inst/htmlwidgets/gg2d3.js†L112-L128】
* Grouping falls back to the literal `group` column name. If the IR ever sends
  a different grouping key (e.g. derived from a facet), those groups will be
  merged together and lines will connect unrelated data.【F:inst/htmlwidgets/gg2d3.js†L112-L128】

## Quantitative calculations

* Bar heights are derived from `yScale(0)`, so plots where the domain does not
  include zero, or where zero is off the scale due to transformations, end up
  with negative heights and clipped rectangles. Diverging bar charts therefore
  render incorrectly.【F:inst/htmlwidgets/gg2d3.js†L131-L143】
* Rectangles assume all coordinates are numeric and simply subtract scaled
  positions. This breaks for flipped coordinates and for cases where the scale
  is categorical, leading to negative widths/heights or collapsed tiles.【F:inst/htmlwidgets/gg2d3.js†L145-L158】

These observations should make it easier to prioritise fixes or regression
tests around the D3 drawing pipeline.
