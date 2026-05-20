# Phase 30: Edge Cases and Blueprint - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce the final v1.7 `geom_sf` handoff blueprint. This phase documents complex edge cases, explicit anti-features, and a concrete future build roadmap with file targets and validation gates. It clarifies what a future build milestone should implement; it does not implement production `geom_sf` features itself.

</domain>

<decisions>
## Implementation Decisions

### Edge-case matrix
- **D-01:** Use a representative edge-case suite, not an exhaustive catalog. Cover the required three cases deeply: mixed geometry types in one layer, multiple stacked `geom_sf` layers, and faceted sf maps. Add 2-3 nearby risks only if they materially change the future build plan.
- **D-02:** Recommend polygon-family support for the first build: `POLYGON` and `MULTIPOLYGON` are in scope; non-polygon sf geometries should be documented as unsupported or future work rather than best-effort rendered.
- **D-03:** Multiple stacked `geom_sf` layers in the same panel should share one panel projection/bbox so overlays align. Per-layer projection is rejected because it can misalign overlays.
- **D-04:** Faceted sf maps should prioritize per-panel projection from each panel's data. Each facet panel fits its own sf features unless a later build explicitly chooses global-comparison semantics.

### Blueprint granularity
- **D-05:** The final document should be a build-phase roadmap: a short sequence of future implementation phases, each with files, tasks, and validation.
- **D-06:** The blueprint must include a concrete file-by-file checklist. It should name exact R, JavaScript, test, and documentation files and describe what changes in each.
- **D-07:** The first future build phase should optimize for a production-safe MVP: single-panel polygon choropleths with tooltip, hover, centroid brush, and explicit zoom suppression.
- **D-08:** Validation in the blueprint should mix automated and visual gates: R tests for IR shape, JavaScript structure checks, and human/browser visual comparisons where visual fidelity matters.

### Anti-features
- **D-09:** Include at least five explicit anti-features: tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees.
- **D-10:** Phrase anti-features as first-build deferrals with rationale and revisit conditions, not as vague omissions or permanent hard bans.
- **D-11:** Tile basemaps and slippy-map controls are explicitly out of scope. gg2d3 should remain an SVG/htmlwidgets renderer focused on ggplot parity, not a Leaflet or Mapbox-style tiled map system.
- **D-12:** Large-map performance should be documented as limited in the first build. Typical datasets may be warned/tested, but simplification, tiling, and large-feature-count guarantees are future work.

### Validation evidence
- **D-13:** Phase 30 may include lightweight probes or check commands when cheap and useful, but the written blueprint is the primary deliverable. Do not make this a probe-heavy prototype phase.
- **D-14:** Faceted sf validation should be framed as IR/DOM contract evidence: expected `PANEL` filtering, panel bbox/projection behavior, and future tests.
- **D-15:** Mixed geometry validation should include an explicit future unsupported-case test plan: non-polygon sf should warn or skip predictably.
- **D-16:** The blueprint must leave no unresolved implementation choices. Future build agents should not need to choose scope, file targets, sequencing, or validation gates.

### the agent's Discretion
- Exact section order and table layout in the final blueprint.
- Which 2-3 nearby risks to include beyond the required three edge cases, provided they affect the future build plan.
- Exact wording of future warning messages, as long as the blueprint specifies where warnings occur and what user-facing behavior must be clear.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` - Phase 30 goal and success criteria for edge cases, anti-features, and build blueprint.
- `.planning/REQUIREMENTS.md` - `BLPR-01`, `BLPR-02`, and `BLPR-03` define the Phase 30 requirements.

### Prior sf decisions
- `.planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md` - R-side sf extraction, CRS normalization, and IR schema decisions.
- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` - `sf.js`, `row_id`, `data-cx`, `data-cy`, and projection decisions.
- `.planning/phases/29-interactivity-design/29-CONTEXT.md` - Tooltip, hover, brush, and zoom decisions for `path.geom-sf`.
- `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` - Final interactivity design contract for future implementation hooks.

### Existing code hooks
- `R/as_d3_ir.R` - Current sf extraction branch, `PANEL` handling, facet metadata, `coord.type = "sf"`, and `coord.bbox`.
- `R/validate_ir.R` - IR validation structure for facets and panels; useful for future validation gates.
- `inst/htmlwidgets/gg2d3.js` - Panel rendering, facet layout, and layer filtering by `PANEL`.
- `inst/htmlwidgets/modules/geoms/sf.js` - Current sf renderer using `geoIdentity().reflectY(true).fitExtent()`, bound row data, and centroid attributes.
- `inst/htmlwidgets/modules/events.js` - Future tooltip/hover selector integration for `path.geom-sf`.
- `inst/htmlwidgets/modules/brush.js` - Future centroid brush integration for sf paths.
- `R/d3_zoom.R` - Future R-side zoom suppression for sf widgets.

### Test references
- `tests/testthat/test-sf-ir.R` - Existing sf IR tests.
- `tests/testthat/test-sf-renderer.R` - Existing row/geometry alignment tests.
- `tests/testthat/test-sf-visual.R` - Existing visual test generation for sf rendering.
- `tests/testthat/test-facets.R` - Facet IR and panel metadata tests.
- `tests/testthat/test-facet-grid.R` - Facet grid and free scale tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/as_d3_ir.R`: already preserves `PANEL`, emits sf `geometries`, `geom_type`, `crs`, and `row_id`, and builds facet/panel metadata. Phase 30 should describe how future builds preserve these contracts for stacked and faceted sf maps.
- `inst/htmlwidgets/gg2d3.js`: already has multi-panel rendering, `ir.panels`, `ir.facets`, and per-panel layer data filtering by `PANEL`. The blueprint should connect faceted sf behavior to these existing panel mechanics.
- `inst/htmlwidgets/modules/geoms/sf.js`: already computes one projection per render call and writes `data-row-id`, `data-cx`, and `data-cy`. The blueprint should call out the future need for shared per-panel projections across stacked sf layers.
- `R/validate_ir.R`: validates facets and panels; future validation can extend this with sf-specific panel/bbox expectations.
- Existing sf and facet tests: provide patterns for R-side IR checks and visual artifact generation.

### Established Patterns
- Three-layer pipeline: R extracts a JSON-safe IR, D3 renders SVG, and htmlwidgets bridges the two.
- Optional spatial dependencies are guarded with `skip_if_not_installed()` in tests and `requireNamespace()` in code.
- Visual validation artifacts live outside committed production outputs; existing sf visual tests already generate HTML for manual inspection.
- Prior interactivity decisions favor extending existing APIs (`d3_tooltip()`, `d3_hover()`, `d3_brush()`, `d3_zoom()`) rather than adding map-specific user APIs.

### Integration Points
- R extraction: `R/as_d3_ir.R` and `R/sf_utils.R` for geometry type handling, panel-specific data, bbox decisions, and warning contracts.
- D3 rendering: `inst/htmlwidgets/modules/geoms/sf.js` and `inst/htmlwidgets/gg2d3.js` for projection scope, stacked layer alignment, and faceted rendering.
- Interactivity: `events.js`, `tooltip.js`, `brush.js`, `zoom.js`, and `R/d3_zoom.R` for the future MVP behavior defined in Phase 29.
- Tests/docs: `tests/testthat/test-sf-*.R`, facet tests, visual output scripts, vignettes, and the final blueprint artifact itself.

</code_context>

<specifics>
## Specific Ideas

- The first future build should feel production-safe rather than ambitious: single-panel polygon choropleths with known interaction behavior and clear warnings are preferred over broad but fragile map coverage.
- The blueprint should explicitly prevent future agents from accidentally turning gg2d3 into a general GIS/slippy-map package.
- Faceted sf maps should be analyzed as a real edge case even if implementation comes after the first build, because existing gg2d3 facet machinery already affects the likely design.
- Stacked sf layers are valuable only if overlays align; shared per-panel projection is the key invariant.

</specifics>

<deferred>
## Deferred Ideas

- Tile basemaps and slippy-map controls - outside the SVG/ggplot-parity first build.
- JavaScript-side reprojection - future only if R-side WGS84 normalization becomes insufficient.
- Polygon-overlap or spatial-intersection brush selection - future only if centroid brushing proves inadequate.
- Large-map simplification, tiling, or performance guarantees - future performance phase after baseline sf behavior is stable.
- Non-polygon sf rendering (`POINT`, `MULTIPOINT`, `LINESTRING`, `MULTILINESTRING`, `GEOMETRYCOLLECTION`) - future work after polygon-family maps are reliable.

</deferred>

---

*Phase: 30-edge-cases-and-blueprint*
*Context gathered: 2026-05-20*
