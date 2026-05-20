# Phase 34: Stacked and Faceted Projection Alignment - Context

<domain>
## Phase Summary

Phase 34 extends the production `geom_sf` polygon renderer from Phase 33 so sf layers share projection state correctly. The phase covers two requirements: stacked sf overlays in one panel must align under one panel-level bbox/projection, and faceted sf maps must fit each facet panel from only that panel's `PANEL` rows.

## Roadmap Goal

Extend sf projection handling so stacked sf layers align in one panel and faceted sf maps fit each panel from its own data.

## Requirements

- `SFREND-02`: Multiple sf layers in the same panel share a per-panel bbox/projection so polygon overlays align instead of being fitted independently.
- `SFREND-03`: Faceted sf maps render with facet-aware `PANEL` filtering and per-panel bbox/projection behavior for both `facet_wrap()` and `facet_grid()`.

</domain>

<decisions>
## Decisions Captured

### Shared Projection Source

- Use the union of accepted `POLYGON`/`MULTIPOLYGON` features across all sf layers in a panel as the shared panel bbox/projection source.
- Do not let non-sf layers influence sf projection metadata.
- Preserve the polygon-first scope from Phase 30 and Phase 32; unsupported sf geometries remain filtered before projection metadata is built.

### Empty or Skipped sf Rows

- If a panel has no accepted sf geometries after filtering, render that sf content as blank with diagnostics/warnings rather than falling back to a global bbox.
- Avoid global fallback behavior because it can mask facet leakage and make empty panels look accidentally valid.

### Facet Projection Behavior

- `facet_wrap()` and `facet_grid()` must fit each panel from only that panel's sf rows.
- This per-panel projection behavior applies even when ggplot facets use fixed scales; the sf projection is map-fitting metadata, not the existing Cartesian x/y scale domain.
- Global-comparison projection mode remains deferred beyond v1.8.

### IR and Renderer Contract

- R should compute panel-level sf bbox/projection metadata and place it where panel rendering can access it consistently.
- `gg2d3.js` should pass the relevant panel projection state into every sf layer renderer for that panel.
- `sf.js` should consume passed panel projection state instead of fitting each layer independently.

</decisions>

<canonical_refs>
## Canonical References

### Project and Requirements

- `.planning/PROJECT.md` — Current milestone state, out-of-scope map anti-features, and key decisions through Phase 33.
- `.planning/REQUIREMENTS.md` — `SFREND-02` and `SFREND-03` requirement definitions and deferred future global-comparison mode.
- `.planning/ROADMAP.md` — Phase 34 goal, success criteria, dependencies, and likely files.
- `.planning/STATE.md` — Current GSD state and recent decisions affecting Phase 34.

### Prior Phase Context

- `.planning/phases/33-single-panel-renderer-and-interactivity/33-CONTEXT.md` — Prior phase context for single-panel sf rendering and interactivity.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-01-SUMMARY.md` — Renderer completion notes for `path.geom-sf`.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-02-SUMMARY.md` — Brush and centroid interactivity completion notes.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-03-SUMMARY.md` — Zoom suppression and sf interactivity composition notes.
- `.planning/phases/33-single-panel-renderer-and-interactivity/33-VERIFICATION.md` — Phase 33 verification scope and residual constraints.

### Code References

- `R/as_d3_ir.R` — Builds layer data, sf coord metadata, facet layout, and panel metadata.
- `R/sf_utils.R` — Filters/normalizes accepted sf geometries and returns serialized GeoJSON plus diagnostics.
- `R/validate_ir.R` — Validates sf layer structure and panel metadata expectations.
- `inst/htmlwidgets/gg2d3.js` — Renders panels, filters layer data by `PANEL`, and passes options into geom renderers.
- `inst/htmlwidgets/modules/geoms/sf.js` — Current sf renderer that independently calls `fitExtent()` per layer.
- `tests/testthat/test-sf-ir.R` — Existing sf IR and diagnostics tests.
- `tests/testthat/test-facets.R` — Existing facet wrap/grid panel metadata tests.
- `tests/testthat/test-facet-grid.R` — Existing facet grid layout and per-panel scale tests.
- `tests/testthat/test-sf-visual.R` — Existing browser-oriented sf visual fixture tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `prepare_sf_geometry_ir()` in `R/sf_utils.R` already returns accepted geometry, serialized GeoJSON, row identity, CRS metadata, and diagnostics. Phase 34 can build shared panel bbox metadata from accepted geometries instead of reparsing unsupported inputs.
- `as_d3_ir()` already collects `sf_coord_geometries` and writes `coord$type == "sf"` plus `coord$bbox` for the single-panel path. This is the natural place to evolve from one global sf bbox to per-panel sf metadata.
- `renderPanel()` in `inst/htmlwidgets/gg2d3.js` already receives `panelData`, `panelNum`, and filters `layer.data` by `PANEL`. Phase 34 should extend that path to keep `layer.geometries` aligned with filtered rows and pass panel sf projection metadata to renderers.
- `sf.js` already owns GeoJSON parsing, `geoIdentity().reflectY(true).fitExtent()`, path creation, and centroid calculation. It should retain rendering mechanics but swap the fit source from the current layer-only feature collection to shared panel projection state.

### Established Patterns

- Layer data and geometry arrays are currently positionally parallel after R-side filtering; any JS-side facet filtering must preserve geometry/data row alignment.
- Existing facet rendering uses `ir.panels` entries keyed by integer `PANEL`. New sf panel metadata should follow that panel-keyed pattern to reduce special cases.
- `validate_ir()` already exempts sf panels from Cartesian `x_range`/`y_range` warnings when `coord$type == "sf"`. It should validate any required sf projection metadata without reintroducing Cartesian scale assumptions.
- Optional spatial packages are guarded in tests with `skip_if_not_installed()`, and that pattern should continue for sf/facet fixtures.

### Integration Points

- R layer: compute per-panel sf bbox/projection metadata after all sf layers have been prepared and after facet `PANEL` values are known.
- IR layer: expose panel-level sf metadata either on `ir.panels[[i]]` or another panel-keyed field that `renderPanel()` can resolve without cross-panel lookup ambiguity.
- JS layer: pass panel sf projection state through `geomRegistry.render()` options, and update `sf.js` to use that state for all sf layers in the panel.
- Tests: cover stacked single-panel overlays, `facet_wrap()` panel isolation, `facet_grid()` panel isolation/layout preservation, empty panel behavior, and geometry/data alignment after facet filtering.

</code_context>

<specifics>
## Specific Ideas

- For stacked sf layers, a small synthetic fixture with two polygon sf layers using visibly different bboxes should assert shared panel bbox metadata spans both layers and prevents per-layer independent fitting.
- For facets, use synthetic polygons with far-apart coordinates in different `PANEL`s so a global bbox leak is obvious in metadata and rendered output.
- Keep the renderer projection primitive from earlier phases: `d3.geoIdentity().reflectY(true).fitExtent()` with the existing padding behavior.
- Keep first-build anti-features out of scope: tile basemaps, slippy zoom/pan, JavaScript-side CRS reprojection, polygon-overlap brushing, large-map performance guarantees, and global-comparison facet projection mode.

</specifics>

<deferred>
## Deferred Ideas

- Global-comparison projection mode for faceted sf maps remains a future requirement (`SFNEXT-04`), not Phase 34 behavior.
- Polygon-overlap brushing remains deferred (`SFNEXT-05`); Phase 34 should preserve centroid brush semantics from Phase 33.
- Large-map simplification/performance budgets remain deferred (`SFNEXT-06`).

</deferred>

---

*Phase: 34-stacked-and-faceted-projection-alignment*
*Context gathered: 2026-05-20*
