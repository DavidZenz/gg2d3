# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.

## Geom coverage

gg2d3 supports core Cartesian geoms (point, line, path, bar, col, rect, tile,
text, polygon, area, ribbon, segment, hline/vline/abline, boxplot, violin,
density, smooth) plus polygon-family, point-family, and line-family `geom_sf`
and projected-anchor `geom_sf_text()` / `geom_sf_label()` annotations.

Geoms outside this set (for example `geom_contour`) log a warning and do not
render.

## Ordinary `geom_polygon()` support

Ordinary `geom_polygon()` renders grouped closed SVG paths from ggplot2 built
data. Row order is preserved inside each group, core fill/stroke/alpha/
linewidth/linetype styling is carried through, and facets plus existing
tooltip, hover, brush, handler, and linked-view hooks are supported at the path
mark level.

Residual risks remain explicit: topology/hole repair beyond clean grouped
closed paths is not shipped by Phase 51. ggplot2 built data may include a
`subgroup` column for hole-style polygon input, but gg2d3's ordinary polygon IR
does not currently preserve `subgroup` or render compound paths. The renderer
does not infer GIS topology, ring containment, hole winding, or invalid-polygon
repair for arbitrary polygon input; users should provide groups that ggplot2
already builds into the intended path order.

## `geom_sf` support

`geom_sf()` support exists for polygon-family (`POLYGON`, `MULTIPOLYGON`),
point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
`MULTILINESTRING`) layers. Polygon and line families render as SVG paths; point
families render as SVG circle marks. Known CRS inputs are normalized to WGS84 in
R before serialization. If a layer has no CRS, gg2d3 warns that coordinates
will be serialized as-is.

Unsupported, empty, invalid, or missing sf geometries are skipped with a
warning while accepted rows remain renderable. `GEOMETRYCOLLECTION` expansion is
not supported.

`geom_sf_text()` and `geom_sf_label()` are supported for the accepted sf
families above. They render text and label groups at projected anchors aligned
with the same panel projection used by polygon, point, and line sf marks.
Tooltip, hover, handler, and brush behavior reuse the existing `.geom-sf`
interaction path with sanitized public payloads.

Interactivity targets `.geom-sf` polygon, point, and line marks. Tooltip,
hover, custom handler, and Shiny-style callback payloads are sanitized
source-row objects. Brush selection uses representative-anchor brushing from
rendered `data-cx` and `data-cy` anchors rather than geometric intersection.
Optional browser validation is R/testthat/chromote based and may skip cleanly;
when available, it covers sf family interactivity, stacked overlays, faceted and
empty panels, skipped rows, and zoom suppression.

## Browser visual smoke artifacts

Maintainers can generate local browser-rendered visual smoke artifacts with the
opt-in test runner. The skip-friendly command is:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The full artifact command is:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The CI-equivalent local command is:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-browser-visual-smoke.R"); df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)'
```

In CI, the dedicated workflow is `.github/workflows/browser-visual-smoke.yaml`.
It runs on pull requests and `workflow_dispatch`, sets
`GG2D3_BROWSER_VISUAL_SMOKE=true` and `GG2D3_BROWSER_VISUAL_CI=true`, and
uploads the full `test_output/browser-visual-smoke/` directory as a workflow
artifact on every run.

Generated files live under `test_output/browser-visual-smoke/`, which is ignored
by git and excluded from package builds. The report files are `index.html` and
`index.json`. `index.html` is the human-readable report, while `index.json`
contains structured row and run metadata. Each executable fixture can also
produce `<fixture>.html`, `<fixture>.png`, `<fixture>-dom-summary.json`, and
`<fixture>-browser-log.json`.

Coverage includes Cartesian geoms, facets, interactivity-facing marks, ordinary
`geom_polygon()`, sf geometry marks, and `geom_sf_text()` /
`geom_sf_label()` annotations. The run may skip explicitly when
`GG2D3_BROWSER_VISUAL_SMOKE` is not true, when Chrome/Chromium or chromote
launch is unavailable, or for sf-dependent rows when `sf` or `geojsonsf` is
unavailable.

If `chromote::find_chrome()` does not find the intended local browser, set
`CHROMOTE_CHROME=/path/to/chrome` as a troubleshooting override. In the
dedicated CI workflow, browser-level skips are failures; optional `sf` or
`geojsonsf` row skips may pass only when the generated report records them
explicitly. Screenshots are inspection evidence only. The golden screenshots
are deferred, and pixel thresholds are deferred until CI artifacts prove stable
across environments.

Map anti-features are explicit: no tile basemaps, no slippy map controls, no
JavaScript-side CRS reprojection, no true geometry-overlap brushing, no
`GEOMETRYCOLLECTION` expansion, and no large-map performance guarantees.

Annotation anti-features are also explicit: ggrepel collision avoidance, rich
text, rotation parity, and path-following annotation placement are not shipped
by Phase 47.

## Text options

`geom_text` supports position, size, color, and alpha. Ordinary `geom_label()`
currently maps to the text renderer, so label boxes, padding, and label-specific
background styling are not yet translated. Rotation (`angle`), justification
(`hjust`/`vjust`), font family, collision avoidance, and path-following text are
not yet translated.

## Linetype

Dashed and dotted linetypes (`linetype = "dashed"`, `"dotted"`, etc.) are
translated to SVG `stroke-dasharray` patterns. Custom numeric linetype
specifications may not match ggplot2 exactly.

## Theme translation

Most theme elements are translated, but some edge cases are not covered:

- `element_blank()` is handled, but `element_line(arrow = ...)` is not
- `strip.text` rotation is not supported
- `plot.margin` is partially supported (outer margins only)

## Renderer and IR contract boundaries

The internal renderer contract manifest is
`inst/htmlwidgets/modules/geom-contracts.js`. Source-level drift is checked by
`tests/testthat/test-renderer-wiring-contracts.R`, including renderer module
paths, htmlwidgets load order, declared render selectors, update selectors,
interaction selectors, and public payload expectations. Unsupported update or
interaction surfaces should use explicit exceptions with reason strings rather
than bare empty arrays.

Public tooltip, event, brush, and linked-view payload paths are expected to pass
through `window.gg2d3.publicData.sanitizeDatum()` / `publicData.sanitizeDatum`
so renderer-private underscore fields stay out of public row payloads.

On the R side, `as_d3_ir()` remains the orchestrator for plot building, sf
payload routing, coordinate metadata, guides, facets, final IR assembly, and
validation. Focused helpers cover selected scale, layer, facet, theme, and geom
parameter seams, but full `as_d3_ir()` modularization remains deferred to
FUT-03. The generated renderer documentation remains deferred to FUT-04; the
source contract and focused tests are the maintained boundary for now.

These diagnostics do not add committed golden screenshots or pixel thresholds.
Browser visual smoke artifacts remain downstream inspection evidence, with
golden screenshots and pixel thresholds still deferred until CI artifacts prove
stable across environments.

## Rect/tile edge cases

Phase 45 closed the deferred `geom_rect` and `geom_tile` out-of-bounds item.
Focused fixtures distinguish scale-limit censoring from `coord_cartesian()` and
SVG clipping: scale limits can produce `NA` bounds before gg2d3 sees the rows,
while coordinate limits preserve finite bounds and rely on the panel clip path.

Confirmed renderer/update mismatches were fixed at the D3 boundary. Categorical
tile positioning now uses band-scale center values with `bandwidth()` dimensions,
rect borders use the registry stroke/linewidth accessors, and the
`rect.geom-rect` update path mirrors band-scale and `coord_flip()` geometry.
The remaining scale-limit, reversed-scale, coordinate-limit, and facet cases are
closed as tested non-issues in the Phase 45 classification notes. Full
rect/tile transformed-scale edge parity remains out of scope for this closure
and is not shipped by Phase 47.

## Phase 47 residual-risk list

The v1.11 geometry parity contract is deliberately bounded. The following items
are deferred and not shipped by Phase 47:

- Polygon topology/hole repair beyond grouped closed paths.
- Full rect/tile transformed-scale edge parity.
- Tile basemaps and slippy map controls.
- JavaScript-side CRS reprojection.
- ggrepel collision avoidance.
- Rich text for text and label annotations.
- Rotation parity for text and label annotations.
- Path-following annotation placement.

## Private API dependency

The package uses `ggplot2:::calc_element()` to resolve inherited theme
elements. This private API could change in future ggplot2 releases. If theme
translation breaks after a ggplot2 update, this is the likely cause.

## Extension packages

Geoms from ggplot2 extension packages (ggridges, ggrepel, ggforce, etc.) are
not supported. Only geoms from core ggplot2 are recognized by the renderer.
