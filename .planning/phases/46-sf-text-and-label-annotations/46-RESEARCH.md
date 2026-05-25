# Phase 46: sf Text And Label Annotations - Research

## RESEARCH COMPLETE

Phase 46 should extend the existing sf pipeline rather than build a separate map-label system. The current package already has the important pieces: R-side sf filtering/diagnostics in `R/sf_utils.R`, panel-scoped `sf_bbox` metadata in `R/as_d3_ir.R`, D3 projection and centroid attributes in `inst/htmlwidgets/modules/geoms/sf.js`, and selector-driven interactivity in `events.js`, `brush.js`, `tooltip.js`, and `crosstalk.js`.

Local note: the current machine cannot load `sf` because the installed package links to a missing GDAL dylib. Phase tests must continue to use `skip_if_not_installed("sf")` / `skip_if_not_installed("geojsonsf")` so CRAN-like or locally broken sf environments skip explicitly.

## Current Architecture

### R IR Layer

- `R/as_d3_ir.R` maps `GeomText` and `GeomLabel` to `"text"` and `GeomSf` to `"sf"`.
- `R/as_d3_ir.R` dispatches `"sf"` layers through `sf_layer_ir_payload(df, aes, g_params, var_names)`.
- `R/sf_utils.R` centralizes `prepare_sf_geometry_ir()`, `sf_layer_ir_payload()`, `sf_layer_data_rows()`, `attach_sf_panel_bboxes()`, and `sf_bbox_values()`.
- `sf_layer_data_rows()` already retains `label`, `colour`, `fill`, `size`, `alpha`, `group`, `row_id`, and `.sf_family`.
- `R/validate_ir.R` validates `"sf"` layers by requiring `geometries`, data/geometries length parity, and `sf_diagnostics`.

### D3 Renderer Layer

- `inst/htmlwidgets/modules/geoms/sf.js` renders polygon, line, and point sf families with a per-panel `d3.geoIdentity().reflectY(true).fitExtent()` projection.
- `sf.js` uses `options.sfBBox` to align stacked/faceted sf layers.
- `sf.js` computes projected centroids with `pathGen.centroid()` and exposes `data-cx` / `data-cy` on all `.geom-sf` marks.
- `inst/htmlwidgets/modules/geoms/text.js` is a simple Cartesian text renderer and does not know about sf projections.
- `inst/htmlwidgets/gg2d3.js` currently preserves parallel `data` and `geometries` arrays only for `layer.geom === "sf"` during facet filtering.

### Interactivity

- `events.js`, `brush.js`, and `crosstalk.js` include `.geom-sf` selectors.
- `brush.js` selects `.geom-sf` marks by reading `data-cx` and `data-cy` before falling back to generic tag behavior.
- `events.js`, `brush.js`, and `tooltip.js` sanitize underscore-prefixed renderer-private fields before public callbacks.
- Existing source tests in `tests/testthat/test-sf-interactivity.R` already guard sf selector and sanitizer contracts.

## Recommended Implementation Shape

1. Add distinct IR geoms for sf annotations: `"sf_text"` and `"sf_label"`.
2. Keep sf annotation layers structurally sf-like: `geometries`, `data`, `crs`, `sf_diagnostics`, `sf_family`, `geom_type`, `var_names`, and `annotation_type`.
3. Reuse `prepare_sf_geometry_ir()` for unsupported/empty/invalid/missing geometry filtering, row identity, CRS normalization, and diagnostics.
4. Extend retained sf aesthetics to include `hjust`, `vjust`, `angle`, `fontface`, and `family` where ggplot2 built data supplies them.
5. Update `gg2d3.js` facet filtering so `"sf_text"` and `"sf_label"` keep `data` and `geometries` arrays parallel just like `"sf"`.
6. Update `validate_ir()` so `"sf_text"` and `"sf_label"` are known geoms and use the same sf-like structural validation as `"sf"`.
7. Refactor `sf.js` enough to share projection helpers with annotation rendering, or add a focused annotation path in the same file.
8. Register `"sf_text"` and `"sf_label"` renderers and render:
   - `text.geom-sf.geom-sf-text` for `geom_sf_text()`.
   - `g.geom-sf.geom-sf-label` containing `rect.geom-sf-label-box` and `text.geom-sf-label-text` for `geom_sf_label()`.
9. Put `data-cx`, `data-cy`, and `data-row-id` on the interactive mark (`text` for text, `g` for label).
10. Bind the public data row to the interactive mark and keep private fields underscore-prefixed.

## Anchor Strategy

Use the existing D3 projection as the source of truth for screen position:

- Point: project the point coordinate directly, matching existing point-family `geom_sf()` behavior.
- MultiPoint: create one annotation mark per source row at a deterministic representative point or use the first projected point unless implementation research proves ggplot2 built data expects another row-level anchor. Do not duplicate public callback rows without deduping by `row_id`.
- Polygon/MultiPolygon: use `pathGen.centroid(asFeature(geom))` or a deterministic representative point derived from the projected feature. If `pathGen.centroid()` returns non-finite values, skip the mark.
- Line/MultiLineString: use `pathGen.centroid(asFeature(geom))` as the deterministic center-style anchor. Do not implement path-following text.

This aligns with Phase 46 context decisions D-01 through D-05 and the current `data-cx` / `data-cy` contract.

## Pitfalls

- `geom_sf_text()` and `geom_sf_label()` may have distinct ggplot2 geom classes such as `GeomSfText` / `GeomSfLabel`, not `GeomSf`. Detection in `R/as_d3_ir.R` should handle exact classes and robust fallback names.
- Faceted sf annotations will break if `gg2d3.js` only preserves geometry/data pairs for `layer.geom === "sf"`.
- Label groups must carry data and anchor attributes on the group itself, not only on child `rect` or `text`, so `.geom-sf` interactivity and brush anchor logic continue to work.
- Tooltip/handler payloads must not expose `_geom`, `_centroid`, `_sfFamily`, `_sfAnchor`, `_pointCoord`, or `_pointIndex`.
- Adding new geom names requires `validate_ir()` updates and renderer registration source tests.
- Exact ggplot2 label padding/radius parity is out of scope; use stable simple padding unless existing helpers make more precise parity cheap.

## Validation Architecture

Use three validation layers:

1. **IR and diagnostics tests**
   - New `tests/testthat/test-sf-annotations-ir.R`.
   - Cover `geom_sf_text()` and `geom_sf_label()` for polygon, point, line, stacked layers, facets, and skipped unsupported/empty/invalid/missing rows.
   - Assert `geom` is `"sf_text"` / `"sf_label"`, `annotation_type`, `label`, core aesthetics, `row_id`, `.sf_family`, `geometries`, `sf_diagnostics`, and panel `sf_bbox`.

2. **Renderer/source tests**
   - New or extended `tests/testthat/test-sf-annotations-renderer.R`.
   - Assert renderer registration for `"sf_text"` and `"sf_label"`, projection helper reuse, `options.sfBBox`, `data-cx`, `data-cy`, DOM class names, label box/text structure, and YAML/module loading if a new module is added.

3. **Interactivity and optional browser DOM smoke**
   - Extend `tests/testthat/test-sf-interactivity.R` or add `tests/testthat/test-sf-annotations-interactivity.R`.
   - Add optional `tests/testthat/test-sf-annotations-browser.R` only if it remains chromote/testthat-based and skips explicitly on missing browser/spatial dependencies.
   - Assert tooltip/hover/brush/handler payload sanitization, anchor-based brushing, faceted panel placement, and no screenshot/perceptual diff machinery.

Recommended commands:

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'
rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'
```

Browser tests may skip cleanly when `sf`, `geojsonsf`, `chromote`, or Chrome/Chromium is unavailable.
