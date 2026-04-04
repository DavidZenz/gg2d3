# Phase 28: D3 Renderer Prototyping - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Prototype D3 polygon rendering from Phase 27's IR output. Deliverables: a working `sf.js` geom renderer module integrated into the gg2d3 widget pipeline, visual test HTML files confirming correct rendering of filled choropleth regions and multipolygon holes, and validated aesthetic passthrough from IR to SVG path elements. This is still a research milestone phase — the module is a working prototype, not production-hardened code.

</domain>

<decisions>
## Implementation Decisions

### Prototype deliverable format
- **D-01:** Create `inst/htmlwidgets/modules/geoms/sf.js` following the existing IIFE + `geomRegistry.register('sf', renderSf)` pattern. Not a standalone HTML file.
- **D-02:** Register as a normal geom via `geomRegistry.register()`. The renderer receives `xScale`/`yScale` but ignores them, using `d3.geoPath` with `d3.geoIdentity().reflectY(true).fitExtent()` internally. No special-case branch in `gg2d3.js`.
- **D-03:** Wire `sf.js` into `gg2d3.yaml` so it loads with the package. The prototype must be testable end-to-end through the normal `gg2d3()` pipeline (R IR -> JSON -> sf.js renderer).

### Visual validation approach
- **D-04:** Generate visual test HTML files in `test_output/` (gitignored) for manual side-by-side comparison with ggplot2's `geom_sf` output. Consistent with how other geoms were validated in prior milestones.
- **D-05:** Test against two datasets: (1) NC counties shapefile (simple polygons, baseline REND-01), (2) rnaturalearth world borders (multipolygons with holes/islands, REND-02 validation). Matches Phase 27's dataset coverage.

### Geometry-aesthetic linkage
- **D-06:** Use key-based join with explicit `row_id` field on both `layer.data[]` and `layer.geometries[]`. Add `row_id = seq_along()` on the R side during IR construction. The JS renderer joins geometry to aesthetic data by matching `row_id` values.
- **D-07:** This requires a small R-side change in `as_d3_ir.R` to emit `row_id` for sf layers. Each `<path>` element gets fill/stroke from the matched data row.

### Fill-rule handling
- **D-08:** Apply `fill-rule="evenodd"` universally to all `<path>` elements in sf layers. No per-feature geometry type detection needed — evenodd is harmless on simple polygons and correctly handles multipolygon holes.

### Carried from prior phases/research
- **D-09:** Use `d3.geoIdentity().reflectY(true).fitExtent()` for projection — no JS-side reprojection (Research decision).
- **D-10:** sf panels use NULL `x_range`/`y_range` in IR; renderer uses `coord.bbox` with `fitExtent()` for scaling (Phase 27 D-09).
- **D-11:** Store centroids as `data-cx`/`data-cy` attributes on each `<path>` element for Phase 29 brush selection (Research decision).
- **D-12:** IR carries `layer.geometries[]`, `layer.crs`, `layer.geom_type`, `coord.type = "sf"`, `coord.bbox` (Phase 27 D-08/D-09).

### Claude's Discretion
- Internal structure of the `renderSf()` function (how it builds the projection, binds data, etc.)
- Whether to add a `geom-sf` CSS class to paths or use the existing geom class pattern
- Error handling for malformed GeoJSON strings in the geometries array
- Exact `fitExtent` padding values for the panel bounding box

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing renderer pipeline (understand before adding sf.js)
- `inst/htmlwidgets/gg2d3.js` -- Main renderValue() entry point; layer processing loop at ~line 97
- `inst/htmlwidgets/modules/geom-registry.js` -- Registry pattern: register(), render(), makeColorAccessors()
- `inst/htmlwidgets/modules/geoms/point.js` -- Reference geom module showing IIFE + register pattern
- `inst/htmlwidgets/gg2d3.yaml` -- Widget dependency declarations; where sf.js must be added

### Phase 27 R-side output (what sf.js consumes)
- `R/as_d3_ir.R` -- GeomSf dispatch at ~line 214, sf branch at ~line 321-336, coord.bbox extraction
- `R/sf_utils.R` -- extract_sf_geometries(), normalize_to_wgs84(), detect_dominant_geom_type()
- `.planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md` -- Phase 27 decisions (D-08 through D-12 define IR schema)

### Research findings
- `.planning/research/STACK.md` -- d3-geo version details, geoIdentity/geoPath usage patterns
- `.planning/research/ARCHITECTURE.md` -- Data flow for sf layers through the pipeline
- `.planning/research/PITFALLS.md` -- Pitfalls #3 (winding order), #6 (fitExtent sizing), #7 (reflectY)

### Requirements
- `.planning/REQUIREMENTS.md` -- REND-01, REND-02, REND-03 define Phase 28 scope

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `geom-registry.js:register()` -- Registration function for new geom renderers; sf.js follows this exactly
- `geom-registry.js:makeColorAccessors()` -- Builds fill/stroke/opacity accessors from layer params; reusable for sf paths
- `geom-registry.js:render()` -- Dispatch function that calls the registered renderer by geom name
- `constants.js` -- Unit conversion constants (mmToPxRadius, GGPLOT_PT, etc.)
- `helpers` namespace -- `val()`, `num()`, `asRows()` utilities on `window.gg2d3.helpers`

### Established Patterns
- **Geom module IIFE:** Each geom is a self-contained IIFE that registers itself at load time
- **Function signature:** `renderGeom(layer, g, xScale, yScale, options)` -- sf.js will receive but ignore xScale/yScale
- **Color accessors:** `makeColorAccessors(layer, options)` returns `{strokeColor, fillColor, opacity}` functions
- **Data iteration:** `asRows(layer.data)` converts to array; sf.js will iterate this alongside geometries

### Integration Points
- `gg2d3.yaml` -- Add `modules/geoms/sf.js` to the dependency list
- `gg2d3.js renderValue()` at ~line 97 -- `geomRegistry.render()` already dispatches by `layer.geom`; sf.js just needs to be registered
- `R/as_d3_ir.R` ~line 321-336 -- sf branch already emits `geometries[]`, `geom_type`, `crs`; needs `row_id` addition per D-06

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches. The key constraint is following the existing geom module pattern exactly so sf rendering integrates seamlessly with the widget pipeline.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 28-d3-renderer-prototyping*
*Context gathered: 2026-04-04*
