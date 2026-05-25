# Phase 46: sf Text And Label Annotations - Pattern Map

## Files and Closest Analogs

| Target | Role | Closest Analog | Pattern to Reuse |
|--------|------|----------------|------------------|
| `R/as_d3_ir.R` | Detect ggplot geom classes and dispatch layer IR creation. | Current `GeomSf` dispatch to `sf_layer_ir_payload()`. | Add `GeomSfText` / `GeomSfLabel` handling without disturbing non-sf text layers. |
| `R/sf_utils.R` | Prepare sf-like annotation payloads. | `prepare_sf_geometry_ir()`, `sf_layer_ir_payload()`, `sf_layer_data_rows()`. | Reuse filtering, diagnostics, CRS normalization, row identity, panel geometry aggregation. |
| `R/validate_ir.R` | Validate new IR geom types. | Existing `"sf"` structural validation block. | Treat `"sf_text"` and `"sf_label"` as sf-like layers requiring `geometries` and `sf_diagnostics`. |
| `inst/htmlwidgets/gg2d3.js` | Panel filtering before renderer dispatch. | Existing `layer.geom === "sf"` pair filtering. | Apply data/geometry pair filtering to all sf-like geoms. |
| `inst/htmlwidgets/modules/geoms/sf.js` | Project sf geometry to SVG. | Current polygon/point/line renderers. | Share projection, row copy, family, centroid, `data-cx`, and `data-cy` helpers with annotation renderers. |
| `inst/htmlwidgets/modules/geoms/text.js` | SVG text baseline. | `renderText()` text creation and text-anchor baseline. | Reuse simple text styling expectations, but do not use Cartesian x/y scales for sf annotations. |
| `inst/htmlwidgets/modules/events.js` | Tooltip/hover/custom handler selectors and sanitization. | `.geom-sf` selector and `sanitizeEventDatum()`. | No new API; ensure new annotation marks carry `.geom-sf`. |
| `inst/htmlwidgets/modules/brush.js` | Anchor-based brush. | `.geom-sf` `data-cx` / `data-cy` branch. | Put anchor attributes on interactive annotation marks and verify sanitization. |
| `inst/htmlwidgets/modules/tooltip.js` | Tooltip sanitization. | `sanitizeTooltipDatum()` stripping underscore fields. | Keep private geometry/anchor fields underscore-prefixed. |
| `tests/testthat/test-sf-ir.R` | sf IR fixtures. | Polygon/point/line, skipped-row, stacked, and faceted tests. | Add annotation-specific IR tests in a new file or adjacent section. |
| `tests/testthat/test-sf-renderer.R` | sf renderer source contracts. | Projection, `sfBBox`, `data-cx`, family DOM class tests. | Add annotation renderer source contracts. |
| `tests/testthat/test-sf-interactivity.R` | selector/sanitizer source contracts. | `.geom-sf` selector and private-field guards. | Extend for `geom-sf-text` / `geom-sf-label`. |
| `tests/testthat/helper-browser-sf.R`, `tests/testthat/test-sf-browser.R` | Optional chromote sf smoke. | Existing skip helpers and DOM/callback assertions. | Add optional annotation DOM smoke with the same dependency skip behavior. |

## Concrete Patterns

### sf-like panel filtering

`gg2d3.js` currently special-cases only:

```javascript
if (layer.geom === "sf" && Array.isArray(layer.geometries)) {
  const sfPairs = indexedLayerData.map(function(d, i) {
    return { data: d, geometry: layer.geometries[i] };
  });
}
```

Phase 46 should make this a reusable sf-like check for `"sf"`, `"sf_text"`, and `"sf_label"`.

### Interactive annotation mark classes

Use `.geom-sf` so existing selector arrays continue to apply:

```javascript
text.geom-sf.geom-sf-text
g.geom-sf.geom-sf-label
```

For labels, child nodes should not carry `.geom-sf` unless they intentionally receive the data and anchor attributes:

```javascript
rect.geom-sf-label-box
text.geom-sf-label-text
```

### Private fields

Renderer-private fields must remain underscore-prefixed:

```javascript
_geom
_centroid
_sfFamily
_sfAnchor
_pointCoord
_pointIndex
```

Existing sanitizers strip these by checking `key.startsWith('_')`.

### Optional browser smoke

Follow `helper-browser-sf.R`:

- `skip_on_cran()`
- `skip_if_not_installed("chromote", "0.5.1")`
- `skip_if_not_installed("sf")`
- `skip_if_not_installed("geojsonsf")`
- skip if Chrome/Chromium unavailable
- skip if chromote session launch fails

## Plan Constraints

- Do not introduce screenshot, vdiffr, Playwright, Puppeteer, Selenium, or pixel-diff validation.
- Do not add ggrepel or collision avoidance.
- Do not add JavaScript CRS reprojection.
- Do not add a new public `d3_*` interactivity function for annotations.

