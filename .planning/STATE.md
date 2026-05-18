---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Choropleth Map Research
status: completed
stopped_at: Phase 30 context gathered
last_updated: "2026-05-18T14:04:02.677Z"
last_activity: 2026-05-18
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-18 after v1.7 milestone)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.
**Current focus:** Between milestones — v1.7 shipped 2026-05-18; next milestone TBD (run `/gsd-new-milestone`)

## Current Position

Phase: 30
Plan: Not started
Status: Milestone complete
Last activity: 2026-05-18

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 2 (v1.7 milestone)
- Average duration: unknown
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 29 | 1 | - | - |
| 30 | 1 | - | - |

*Updated after each plan completion*
| Phase 27-r-ir-extraction-feasibility P01 | 10 | 3 tasks | 3 files |
| Phase 27-r-ir-extraction-feasibility P02 | 525626 | 2 tasks | 4 files |
| Phase 28-d3-renderer-prototyping P01 | 8 | 2 tasks | 4 files |
| Phase 28-d3-renderer-prototyping P02 | 10 | 2 tasks | 1 files |
| Phase 29 P29-01 | 2 | 2 tasks | 3 files |

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
- Option A: canonicalize sf path centroid as data-centroid="x,y" (Phase 29 design); IMPL-04 renames data-cx/data-cy in sf.js
- Polygon hit-test rejected for sf brush (D-06); centroid-only with documented memory/compute/UX rationale
- sf zoom uses SVG group transform on .sf-zoom-layer (D-08); deliberate divergence from element-repositioning pattern (D-10)
- vector-effect=non-scaling-stroke specified as SVG presentation attribute (D-09), NOT CSS, for saveWidget serialization survival

### Pending Todos

None yet.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-18:

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 29 29-HUMAN-UAT.md (4 pending subjective design-doc reads) | partial |
| verification_gap | Phase 29 29-VERIFICATION.md | human_needed |

### Blockers/Concerns

- Phase 27 feasibility gate: Must empirically verify `ggplot_build()` preserves the `sfc` geometry list-column before writing any extraction code. Run `b <- ggplot_build(ggplot(nc) + geom_sf()); "geometry" %in% names(b$data[[1]])`. If FALSE, fallback to pre-build layer extraction requires design rework.
- Phase 30 research flag: Zoom architecture decision (SVG group transform vs. geoPath re-render vs. explicit suppression) needs a short spike before committing to the blueprint.

## Session Continuity

Last session: --stopped-at
Stopped at: Phase 30 context gathered
Resume file: --resume-file

---
*State initialized: 2026-02-07*
*v1.0 shipped: 2026-02-16*
*v1.1-v1.6 shipped: 2026-03-31 to 2026-04-04*
*v1.7 milestone started: 2026-04-04*

**Planned Phase:** 30 (edge-cases-and-blueprint) — 1 plans — 2026-05-18T13:32:16.764Z
