---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Choropleth Map Research
status: planning
stopped_at: Phase 27 context gathered
last_updated: "2026-04-04T14:20:38.357Z"
last_activity: 2026-04-04 — v1.7 roadmap created; research milestone initialized (Phases 27-30)
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-04)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.
**Current focus:** Phase 27 — R IR Extraction Feasibility

## Current Position

Phase: 27 of 30 (R IR Extraction Feasibility)
Plan: 0 of ? in current phase
Status: Ready to plan
Last activity: 2026-04-04 — v1.7 roadmap created; research milestone initialized (Phases 27-30)

Progress: [░░░░░░░░░░] 0% (v1.7 milestone)

## Performance Metrics

**Velocity:**

- Total plans completed: 0 (v1.7 milestone)
- Average duration: unknown
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Research (2026-04-04): Use `geojsonsf::sfc_geojson()` for GeoJSON serialization (not `jsonlite::toJSON`); add sf + geojsonsf to Suggests only to avoid forcing GDAL/GEOS/PROJ on all users
- Research (2026-04-04): Use `d3.geoIdentity().reflectY(true).fitExtent()` — no JS reprojection; R normalizes CRS to WGS84 via `sf::st_transform` before serialization
- Research (2026-04-04): Centroid-based brush selection preferred over polygon hit-testing; store centroids as `data-cx`/`data-cy` on path elements in Phase 28

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 27 feasibility gate: Must empirically verify `ggplot_build()` preserves the `sfc` geometry list-column before writing any extraction code. Run `b <- ggplot_build(ggplot(nc) + geom_sf()); "geometry" %in% names(b$data[[1]])`. If FALSE, fallback to pre-build layer extraction requires design rework.
- Phase 30 research flag: Zoom architecture decision (SVG group transform vs. geoPath re-render vs. explicit suppression) needs a short spike before committing to the blueprint.

## Session Continuity

Last session: 2026-04-04T14:20:38.353Z
Stopped at: Phase 27 context gathered
Resume file: .planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md

---
*State initialized: 2026-02-07*
*v1.0 shipped: 2026-02-16*
*v1.1-v1.6 shipped: 2026-03-31 to 2026-04-04*
*v1.7 milestone started: 2026-04-04*
