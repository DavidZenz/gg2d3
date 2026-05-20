# Phase 30: Edge Cases and Blueprint - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` | documentation / implementation blueprint | transform | `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | exact |
| `.planning/phases/30-edge-cases-and-blueprint/30-01-SUMMARY.md` | documentation / execution summary | batch | `.planning/phases/29-interactivity-design/29-01-SUMMARY.md` | exact |
| `R/as_d3_ir.R` | future R extractor hook | transform | `R/as_d3_ir.R` | exact hook |
| `R/sf_utils.R` | future sf utility hook | transform | `R/sf_utils.R` | exact hook |
| `R/validate_ir.R` | future validation hook | validation | `R/validate_ir.R` | exact hook |
| `R/d3_zoom.R` | future R API guard hook | widget configuration | `R/d3_zoom.R` | exact hook |
| `inst/htmlwidgets/gg2d3.js` | future panel/projection orchestration hook | render orchestration | `inst/htmlwidgets/gg2d3.js` | exact hook |
| `inst/htmlwidgets/modules/geoms/sf.js` | future renderer hook | render transform | `inst/htmlwidgets/modules/geoms/sf.js` | exact hook |
| `inst/htmlwidgets/modules/events.js` | future selector hook | event-driven | `inst/htmlwidgets/modules/events.js` | exact hook |
| `inst/htmlwidgets/modules/brush.js` | future centroid brush hook | event-driven selection | `inst/htmlwidgets/modules/brush.js` | exact hook |
| `tests/testthat/test-sf-ir.R` | future R IR tests | validation | `tests/testthat/test-sf-ir.R` | exact hook |
| `tests/testthat/test-sf-renderer.R` | future row/geometry tests | validation | `tests/testthat/test-sf-renderer.R` | exact hook |
| `tests/testthat/test-sf-visual.R` | future visual evidence tests | validation artifact | `tests/testthat/test-sf-visual.R` | exact hook |
| `tests/testthat/test-facets.R` / `test-facet-grid.R` | future facet tests | validation | existing facet tests | strong |

Phase 30 is documentation-only. The R, JavaScript, and test files above are future implementation hooks that the blueprint must name and sequence; they should not be edited in this phase.

## Pattern Assignments

### `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` (documentation / implementation blueprint)

**Analog:** `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md`

Use the same contract-document pattern:

- YAML frontmatter with `phase`, `slug`, `status`, and `created`.
- H1 title naming the phase deliverable.
- A note that the phase produces guidance only and must not edit production source.
- Requirement sections with exact IDs.
- Implementation hook checklist.
- Decision traceability table.
- Checker sign-off checklist.

For Phase 30, the document title should be `# Phase 30 - Edge Cases and Implementation Blueprint`.

Required sections:

- `## BLPR-01 - Edge Case Matrix`
- `## BLPR-02 - Anti-Features`
- `## BLPR-03 - Future Build Roadmap`
- `## File-by-File Checklist`
- `## Validation Gates`
- `## Decision Traceability`
- `## Checker Sign-Off`

### Edge-case matrix pattern

Use a table with columns:

| Edge case | Required first-build behavior | File targets | Validation |
|-----------|-------------------------------|--------------|------------|

Rows must include:

- `Mixed geometry types`
- `Stacked geom_sf layers`
- `Faceted sf maps`

Recommended nearby-risk rows:

- `CRS normalization and missing CRS`
- `Large feature counts`
- `Missing or invalid geometries`

### Anti-feature table pattern

Use a table with columns:

| Anti-feature | First-build behavior | Rationale | Revisit condition |
|--------------|----------------------|-----------|-------------------|

Rows must include:

- `tile basemaps`
- `slippy zoom/pan`
- `JavaScript-side reprojection`
- `polygon-overlap brushing`
- `large-map performance guarantees`

### Future build roadmap pattern

The roadmap should be short and executable by later GSD phases. Recommended future phases:

1. `geom_sf polygon MVP` - single-panel polygon choropleths with tooltip, hover, centroid brush, and zoom suppression.
2. `stacked sf projection alignment` - shared per-panel projection/bbox across multiple sf layers.
3. `faceted sf maps` - panel-specific bbox/projection and facet validation.
4. `unsupported geometry and warnings` - predictable non-polygon warning/skip behavior and docs.

Each roadmap entry must include:

- goal
- files to modify/create
- concrete changes
- automated validation
- visual/manual validation
- anti-features still deferred

### Future source hook patterns

`R/as_d3_ir.R` currently:

- normalizes sf geometry columns to WGS84
- extracts GeoJSON geometry strings
- adds `row_id`
- computes global `coord$bbox`
- preserves `PANEL`

Blueprint guidance should say future build work extends it with polygon-family checks, panel bbox metadata, and shared projection inputs.

`inst/htmlwidgets/modules/geoms/sf.js` currently:

- parses geometry strings
- computes a per-layer `geoIdentity().reflectY(true).fitExtent()`
- emits `path.geom-sf`
- emits `data-cx`, `data-cy`, and `data-row-id`

Blueprint guidance should say future build work moves or parameterizes projection creation so stacked layers in the same panel reuse one projection.

`inst/htmlwidgets/gg2d3.js` currently:

- filters layer data by `PANEL`
- renders each layer into the current panel

Blueprint guidance should say future build work passes panel projection/bbox state into sf layer rendering.

### `.planning/phases/30-edge-cases-and-blueprint/30-01-SUMMARY.md` (documentation / execution summary)

**Analog:** `.planning/phases/29-interactivity-design/29-01-SUMMARY.md`

Use summary frontmatter with:

- `phase: 30-edge-cases-and-blueprint`
- `plan: "01"`
- `subsystem: sf-edge-case-blueprint`
- `tags: [geom-sf, blueprint, edge-cases, anti-features, validation]`
- `key-files.created` listing `30-EDGE-CASE-BLUEPRINT.md`

The summary should state that Phase 30 is complete when the blueprint covers `BLPR-01`, `BLPR-02`, and `BLPR-03` and no production source files were modified.
