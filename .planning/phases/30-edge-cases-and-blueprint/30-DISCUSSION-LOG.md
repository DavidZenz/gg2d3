# Phase 30: Edge Cases and Blueprint - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 30-Edge Cases and Blueprint
**Areas discussed:** Edge-case matrix, Blueprint granularity, Anti-features, Validation evidence

---

## Edge-case matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Representative suite | Cover the required three cases deeply, plus 2-3 nearby risks only if they affect the build plan. | Yes |
| Minimum required | Cover exactly mixed geometry, multiple sf layers, and facets. | |
| Exhaustive catalog | Try to enumerate every plausible sf/map edge case. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked representative suite. Required cases are mixed geometry types, multiple stacked `geom_sf` layers, and faceted sf maps.

| Option | Description | Selected |
|--------|-------------|----------|
| Polygon-family only | Support `POLYGON`/`MULTIPOLYGON`; document non-polygon sf as unsupported or future work. | Yes |
| Best effort | Render any GeoJSON geometry `d3.geoPath()` can draw, with caveats. | |
| Split by geometry type | Plan explicit branches for polygons, lines, points, and collections. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked polygon-family first build.

| Option | Description | Selected |
|--------|-------------|----------|
| Shared projection per panel | All sf layers in a panel use one projection/bbox so overlays align. | Yes |
| Per-layer projection | Each layer fits itself independently, simpler but overlays can misalign. | |
| Disallow stacked sf initially | Document stacked sf layers as out of scope for first build. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked shared per-panel projection for stacked sf layers.

| Option | Description | Selected |
|--------|-------------|----------|
| Per-panel projection from panel data | Each facet panel fits its own sf features. | Yes |
| Global shared projection across facets | All panels use the same bbox for visual comparability. | |
| Defer faceted sf | Document facets as unsupported until after single-panel maps are complete. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked per-panel projection for faceted sf maps.

---

## Blueprint granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Build-phase roadmap | A short sequence of future implementation phases, each with files, tasks, and validation. | Yes |
| Single implementation plan | One big end-to-end plan for all remaining sf work. | |
| Decision memo only | Explain direction, but leave task breakdown for later. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked build-phase roadmap format.

| Option | Description | Selected |
|--------|-------------|----------|
| Concrete file-by-file checklist | Name exact R/JS/test/docs files and what changes in each. | Yes |
| Subsystem-level only | Say R extraction, D3 renderer, interactivity, without exact file instructions. | |
| Minimal | Capture only high-level architecture. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked file-by-file future implementation checklist.

| Option | Description | Selected |
|--------|-------------|----------|
| Production-safe MVP | Single-panel polygon choropleths with tooltip/hover/brush, explicit zoom suppression. | Yes |
| Broad feature sweep | Try to include facets, stacked layers, and edge handling immediately. | |
| Research-hardening only | Add tests/docs first, delay user-facing build work. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked production-safe MVP as first future build phase.

| Option | Description | Selected |
|--------|-------------|----------|
| Mixed automated + visual gates | R tests for IR shape, JS structure checks, and human/browser visual comparisons. | Yes |
| Automated only | Prefer testthat and structural checks; avoid human visual gates. | |
| Visual first | Prioritize browser screenshots and manual comparisons over tests. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked mixed validation model.

---

## Anti-features

| Option | Description | Selected |
|--------|-------------|----------|
| Required plus obvious map temptations | At least five anti-features: tile basemaps, slippy zoom, JS-side reprojection, polygon-overlap brushing, large-map performance guarantees. | Yes |
| Minimum required | Exactly three anti-features. | |
| Broad not-a-GIS list | Many exclusions, including routing, geocoding, spatial joins, legends, map controls, etc. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked at least five anti-features.

| Option | Description | Selected |
|--------|-------------|----------|
| Deferred with rationale | Not in first build because... future condition to revisit... | Yes |
| Hard no | Explicitly declare the capability out of scope permanently. | |
| Soft mention | Short note without much rationale. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked deferral-with-rationale style.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicitly out of scope | gg2d3 remains SVG/htmlwidgets/ggplot parity, not Leaflet/Mapbox. | Yes |
| Future maybe | Mention possible future integration but do not plan it. | |
| Include hooks now | Design extension points for tiles/map controls. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked tile/slippy-map exclusion.

| Option | Description | Selected |
|--------|-------------|----------|
| Document limits, defer optimization | First build can warn/test typical datasets; large-scale simplification/tiling is future work. | Yes |
| Optimize now | Blueprint should include simplification or feature-count management. | |
| Ignore performance | Do not call it out as an anti-feature. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked large-map performance as documented limit and future work.

---

## Validation evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Documents plus lightweight probes if cheap | Written blueprint is primary; small snippets/check commands are allowed when they strengthen claims. | Yes |
| Documents only | No new runnable artifacts in this phase. | |
| Probe-heavy | Create prototype scripts for every major edge case. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked documents-first validation with optional lightweight probes.

| Option | Description | Selected |
|--------|-------------|----------|
| IR/DOM contract evidence | Document expected `PANEL` filtering, panel bbox/projection behavior, and future tests. | Yes |
| Visual screenshot requirement | Require manual HTML comparison before blueprint completion. | |
| Defer evidence | Just state the desired behavior. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked IR/DOM contract evidence for faceted sf.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit unsupported-case test plan | Future tests should assert non-polygon sf is warned/skipped predictably. | Yes |
| Best-effort render test plan | Future tests should try rendering all geometry types. | |
| Documentation only | No future test plan needed. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked unsupported-case test plan for mixed geometry.

| Option | Description | Selected |
|--------|-------------|----------|
| No unresolved implementation choices | Future build agents should not need to choose scope, file targets, or validation gates. | Yes |
| Some flexibility | Let future agents decide non-core sequencing and test depth. | |
| High-level handoff | Enough direction, but not a detailed implementation contract. | |

**User's choice:** Recommendations are fine.
**Notes:** Locked strict handoff standard.

---

## the agent's Discretion

- Exact section order and table layout in the final blueprint.
- Which 2-3 nearby risks to include beyond the required three edge cases, provided they affect the future build plan.
- Exact wording of future warning messages, provided the blueprint specifies where warnings occur and what user-facing behavior must be clear.

## Deferred Ideas

- Tile basemaps and slippy-map controls.
- JavaScript-side reprojection.
- Polygon-overlap or spatial-intersection brush selection.
- Large-map simplification, tiling, or performance guarantees.
- Non-polygon sf rendering beyond `POLYGON`/`MULTIPOLYGON`.
