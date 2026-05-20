# Phase 30: Edge Cases and Blueprint - Research

**Researched:** 2026-05-20
**Phase:** 30 - Edge Cases and Blueprint
**Domain:** Documentation blueprint for future `geom_sf` implementation work
**Confidence:** HIGH for file targets and first-build scope; MEDIUM for exact future warning wording

## Research Question

What needs to be known to plan Phase 30 well?

Phase 30 is not a production implementation phase. It should produce a handoff blueprint that future build phases can execute without re-opening scope, edge-case semantics, anti-features, file targets, or validation gates.

## Inputs Read

- `.planning/phases/30-edge-cases-and-blueprint/30-CONTEXT.md` - user-locked decisions
- `.planning/REQUIREMENTS.md` - `BLPR-01`, `BLPR-02`, `BLPR-03`
- `.planning/ROADMAP.md` - Phase 30 goal and success criteria
- `.planning/STATE.md` - current focus and prior decisions
- `.planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md` - R-side sf extraction decisions
- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` - renderer and DOM contract decisions
- `.planning/phases/29-interactivity-design/29-CONTEXT.md` - interactivity scope decisions
- `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` - locked tooltip, hover, brush, and zoom guidance
- `R/as_d3_ir.R` - sf extraction, panel metadata, and coord metadata
- `R/sf_utils.R` - geometry serialization, CRS normalization, dominant geometry detection
- `R/validate_ir.R` - IR validation hooks
- `R/d3_zoom.R` - future zoom suppression hook
- `inst/htmlwidgets/gg2d3.js` - panel rendering and `PANEL` filtering
- `inst/htmlwidgets/modules/geoms/sf.js` - current path renderer, projection, centroids, and attributes
- `inst/htmlwidgets/modules/events.js` - future tooltip/hover selector hook
- `inst/htmlwidgets/modules/brush.js` - future centroid brush hook
- `tests/testthat/test-sf-ir.R`, `test-sf-renderer.R`, `test-sf-visual.R`, `test-facets.R`, `test-facet-grid.R` - validation patterns

## Key Findings

### Finding 1: mixed geometry support must be narrowed before implementation

`R/sf_utils.R` currently serializes whatever `sfc` geometries are present, and `detect_dominant_geom_type()` can report broad mixed geometry such as `GEOMETRY`. `inst/htmlwidgets/modules/geoms/sf.js` says it handles Polygon, MultiPolygon, and other GeoJSON geometry types, but the Phase 30 decisions narrow the first build to polygon-family maps only.

Planning implication: the blueprint should require a future R-side gate that accepts `POLYGON` and `MULTIPOLYGON`, and warns or skips non-polygon geometry types predictably. Mixed layers should be analyzed in the edge-case matrix, but the first implementation phase should not attempt best-effort rendering of points, lines, or geometry collections.

### Finding 2: stacked sf layers need shared projection state

`inst/htmlwidgets/modules/geoms/sf.js` currently computes `d3.geoIdentity().reflectY(true).fitExtent()` inside each `renderSf()` call from that layer's own features. In `inst/htmlwidgets/gg2d3.js`, layers are rendered sequentially for a panel and each layer is passed independently to the geom registry. That is fine for one sf layer, but stacked overlays can misalign if each layer fits to a different extent.

Planning implication: the blueprint must require a future shared per-panel projection or bbox cache. All sf layers in the same panel should be projected from the same panel feature collection or panel bbox. The concrete file targets are `R/as_d3_ir.R` for panel bbox metadata and `inst/htmlwidgets/gg2d3.js` plus `inst/htmlwidgets/modules/geoms/sf.js` for projection reuse.

### Finding 3: faceted sf maps already have the PANEL plumbing but need sf-specific bbox semantics

`R/as_d3_ir.R` preserves `PANEL` in layer data and builds `ir$facets` / `ir$panels`. `inst/htmlwidgets/gg2d3.js` filters `layer.data` by `PANEL` before rendering a panel. However, the current sf coord bbox is computed globally from all sf layers, and faceted panel metadata still follows Cartesian panel range extraction in the facet branches.

Planning implication: the blueprint should specify per-panel sf bbox/projection behavior for faceted maps. Future validation should prove that each panel renders only rows whose `PANEL` matches the panel box and that each panel projection is fit from that panel's sf features, unless a later explicit global-comparison mode is designed.

### Finding 4: the first future build should be a production-safe polygon MVP

The prior interactivity design already defines tooltip/hover selector reuse, centroid brush semantics, and zoom suppression for sf. Combining that with Phase 30 decisions yields a coherent first implementation phase: single-panel polygon choropleths with `POLYGON` / `MULTIPOLYGON`, `path.geom-sf`, bound row tooltips, hover, centroid brush, and R-visible zoom suppression.

Planning implication: the Phase 30 blueprint should start its future build roadmap with this MVP before stacked layers, facets, or broader geometry support. This reduces scope while still delivering usable map-region interactivity.

### Finding 5: anti-features should prevent accidental GIS scope expansion

The important anti-features are not merely omissions. They protect gg2d3's identity as an SVG/htmlwidgets renderer for ggplot parity, not a tiled web mapping engine. Tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees all add complexity that would destabilize the first build.

Planning implication: the blueprint should contain an anti-feature table with rationale, first-build behavior, and revisit conditions. This table must include at least the five Phase 30 decisions name.

### Finding 6: validation should combine document coverage with future executable gates

Because Phase 30's primary deliverable is a document, current verification should be grep/document-structure based. The blueprint itself should prescribe future validation gates:

- R tests for polygon-family acceptance and non-polygon warning/skip behavior.
- R tests for `PANEL` preservation and panel bbox metadata.
- JavaScript or fixture checks for shared projection state and `path.geom-sf` DOM attributes.
- Visual/manual browser checks for single-panel choropleths, stacked overlays, and faceted maps.
- Explicit checks that `d3_zoom()` suppresses sf widgets rather than attaching broken zoom behavior.

## Recommended Planning Shape

One documentation plan is sufficient:

- `30-01-PLAN.md` - Produce the final edge-case and implementation blueprint.

Suggested task breakdown:

1. Create `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` with edge-case matrix and anti-feature table.
2. Add a phase-by-phase future build roadmap with exact file targets and validation gates.
3. Add traceability for `BLPR-01`, `BLPR-02`, `BLPR-03`, decisions D-01 through D-16, and prior Phase 27-29 inputs.

No production `R/` or `inst/htmlwidgets/` files should be modified in Phase 30.

## Validation Architecture

### Dimension 1: Requirement coverage

- `BLPR-01` -> edge-case matrix covering mixed geometry types, stacked sf layers, and faceted sf maps.
- `BLPR-02` -> anti-feature table with rationale and revisit conditions.
- `BLPR-03` -> future build roadmap with concrete file changes and validation gates.

### Dimension 2: Decision preservation

Every decision in `30-CONTEXT.md` D-01 through D-16 must be represented in the blueprint or explicitly cited in a traceability table.

### Dimension 3: Implementation readiness

The blueprint must name concrete future file targets:

- `R/as_d3_ir.R`
- `R/sf_utils.R`
- `R/validate_ir.R`
- `R/d3_zoom.R`
- `inst/htmlwidgets/gg2d3.js`
- `inst/htmlwidgets/modules/geoms/sf.js`
- `inst/htmlwidgets/modules/events.js`
- `inst/htmlwidgets/modules/brush.js`
- `tests/testthat/test-sf-ir.R`
- `tests/testthat/test-sf-renderer.R`
- `tests/testthat/test-sf-visual.R`
- `tests/testthat/test-facets.R`
- `tests/testthat/test-facet-grid.R`

### Dimension 4: Edge-case specificity

The blueprint must state required handling for:

- mixed geometry types in one sf layer
- stacked `geom_sf` layers sharing one panel projection/bbox
- faceted sf maps using per-panel projection
- at least two nearby risks if they change the future build plan

### Dimension 5: Deferral clarity

The anti-feature table must include:

- tile basemaps
- slippy zoom/pan
- JavaScript-side reprojection
- polygon-overlap brushing
- large-map performance guarantees

Each anti-feature must have rationale and revisit conditions.

## Pitfalls for the Planner

- Do not turn Phase 30 into production code changes.
- Do not make non-polygon geometry rendering part of the first future build.
- Do not let stacked layers keep per-layer projections.
- Do not define faceted sf behavior as a vague future exercise; specify panel data filtering and per-panel bbox/projection semantics.
- Do not describe tile/slippy behavior as merely "not implemented"; explain why it is outside gg2d3's SVG/ggplot parity scope.
- Do not leave future build agents to choose file targets or validation gates.

## Recommended Files to Create or Modify

- Create `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md`
- Create `.planning/phases/30-edge-cases-and-blueprint/30-01-SUMMARY.md` during execution

Source files are future implementation hooks and should not be edited in Phase 30.

## RESEARCH COMPLETE
