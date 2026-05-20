---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: sf Robustness and Expansion
status: defining_requirements
stopped_at: defining v1.9 requirements
last_updated: "2026-05-20T20:50:00.000Z"
last_activity: 2026-05-20
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-20)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.
**Current focus:** v1.9 sf Robustness and Expansion — defining requirements

## Current Position

Phase: Not started
Plan: -
Status: Defining requirements
Last activity: 2026-05-20 — Milestone v1.9 started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 0 (v1.9 milestone)
- Average duration: unknown
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 32 | 2 | - | - |
| 33 | 3 | - | - |
| 34 | 3 | - | - |
| 35 | 3 | - | - |

*Updated after each plan completion*
| Phase 32 P01 | 20min | 2 tasks | 2 files |
| Phase 32 P02 | 5min | 3 tasks | 3 files |
| Phase 33 P01 | 3min | 3 tasks | 4 files |
| Phase 33 P02 | 3min | 3 tasks | 2 files |
| Phase 33 P03 | 4min | 3 tasks | 3 files |
| Phase 34 P01 | - | 3 tasks | 3 files |
| Phase 34 P02 | - | 3 tasks | 3 files |
| Phase 34 P03 | - | 3 tasks | 2 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Research (2026-04-04): Use `geojsonsf::sfc_geojson()` for GeoJSON serialization (not `jsonlite::toJSON`); add sf + geojsonsf to Suggests only to avoid forcing GDAL/GEOS/PROJ on all users
- Research (2026-04-04): Use `d3.geoIdentity().reflectY(true).fitExtent()` — no JS reprojection; R normalizes CRS to WGS84 via `sf::st_transform` before serialization
- Research (2026-04-04): Centroid-based brush selection preferred over polygon hit-testing; store centroids as `data-cx`/`data-cy` on path elements in Phase 28
- [Phase 27-r-ir-extraction-feasibility]: geojsonsf installed cleanly for D-10 production path; sf_column attr is NULL post-ggplot_build so class-based sfc fallback is primary detection path
- [Phase 27-r-ir-extraction-feasibility]: Normalize geometry column before get_layer_crs() in sf branch so crs.epsg is always 4326 in IR
- [Phase 27-r-ir-extraction-feasibility]: sf panels use NULL x_range/y_range; D3 renderer uses coord.bbox with d3.geoIdentity().reflectY(true).fitExtent()
- [Phase 28-d3-renderer-prototyping]: sf.js uses geoIdentity+reflectY+fitExtent; xScale/yScale received but ignored; centroids pre-computed in single pass
- [Phase 28-d3-renderer-prototyping]: Visual tests use skip_if_not_installed() guards for all optional spatial packages so CI passes without GDAL/GEOS/PROJ
- [Phase 28-d3-renderer-prototyping]: REND-01/02/03 all human-verified passing via browser inspection of NC choropleth and world borders HTML files
- [Phase 29-interactivity-design]: Future geom_sf tooltip and hover support extends existing selectors with path.geom-sf and keeps bound rows as the tooltip data source
- [Phase 29-interactivity-design]: Future geom_sf brush support selects regions by data-cx/data-cy centroid containment, not polygon overlap
- [Phase 29-interactivity-design]: First geom_sf build suppresses d3_zoom() from R with a warning; map zoom is deferred to projection/path re-rendering
- [Phase 30-edge-cases-and-blueprint]: Future geom_sf build starts with polygon-family choropleths (`POLYGON` and `MULTIPOLYGON`) and explicit unsupported geometry handling
- [Phase 30-edge-cases-and-blueprint]: Stacked sf layers use shared per-panel projection/bbox, while faceted sf maps use per-panel projection from each panel's `PANEL` rows
- [Phase 30-edge-cases-and-blueprint]: Tile basemaps, slippy zoom/pan, JavaScript-side reprojection, polygon-overlap brushing, and large-map performance guarantees are first-build anti-features
- [Phase 34-stacked-and-faceted-projection-alignment]: Panel-level `sf_bbox` metadata is computed from accepted sf geometries per `PANEL`, and the D3 renderer filters sf data/geometry pairs together before fitting from that bbox

### Pending Todos

None yet.

### Blockers/Concerns

None for v1.9 yet. The milestone starts from the archived v1.8 polygon MVP and will define requirements for browser validation hardening, non-polygon sf support, and package hardening.

## Session Continuity

Last session: 2026-05-20T14:40:02Z
Stopped at: defining v1.9 requirements
Resume file: .planning/PROJECT.md

---
*State initialized: 2026-02-07*
*v1.0 shipped: 2026-02-16*
*v1.1-v1.6 shipped: 2026-03-31 to 2026-04-04*
*v1.7 milestone started: 2026-04-04*
*v1.8 milestone started: 2026-05-20*
*v1.9 milestone started: 2026-05-20*

**Planned milestone:** v1.9 sf Robustness and Expansion — requirements in progress — 2026-05-20
