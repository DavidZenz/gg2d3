# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — Choropleth Map Research

**Shipped:** 2026-05-20
**Phases:** 4 | **Plans:** 6

### What Was Built
- R-side `geom_sf` extraction feasibility, including `geojsonsf::sfc_geojson()` serialization, WGS84 normalization, CRS metadata, and sf IR schema.
- D3 `geom_sf` polygon renderer prototype using `geoIdentity().reflectY(true).fitExtent()`, `fill-rule="evenodd"`, row IDs, centroids, and visual test artifacts.
- Interactivity design contract for `path.geom-sf` tooltip, hover, centroid brush, and first-build zoom suppression.
- Final edge-case and implementation blueprint covering mixed geometries, stacked sf layers, faceted sf maps, anti-features, future phases, file targets, and validation gates.

### What Worked
- Research-first sequencing kept production implementation choices from leaking into a research milestone.
- Human visual checkpoints were valuable for multipolygon holes and choropleth fidelity where CLI checks cannot prove the rendered shape.
- The Phase 30 blueprint successfully consolidated Phase 27-29 findings into a build-ready handoff.

### What Was Inefficient
- Older validation metadata in Phase 28 remained marked non-Nyquist even after the phase was verified and human-approved.
- Some GSD SDK wrappers misparsed named flags, requiring direct CLI/manual corrections for state and milestone operations.
- One Phase 28 summary used a literal `One-liner:` label that needed cleanup during milestone archiving.

### Patterns Established
- For spatial features, split feasibility, renderer proof, interactivity design, and implementation blueprint into separate phases before production build work.
- Anti-features should include revisit conditions, not just “out of scope” labels.
- Future build blueprints should name exact files, validation gates, and unresolved edge cases before implementation begins.

### Key Lessons
1. `geom_sf` support should remain polygon-first until shared projection, facets, and unsupported geometry behavior are stable.
2. Browser reprojection, slippy maps, tile basemaps, polygon-overlap brushing, and large-map guarantees are different product categories from ggplot parity and need explicit deferral.
3. Milestone closeout should check stale top-level roadmap/status lines before archiving; summaries can be complete while overview prose lags behind.

### Cost Observations
- Model mix: not tracked.
- Sessions: multiple short GSD sessions across April and May.
- Notable: Docs-only design phases were quick once prior research artifacts were clean and specific.

---

## Milestone: v1.6 — Advanced Geoms & API Polish

**Shipped:** 2026-04-04
**Phases:** 3 | **Plans:** 4

### What Was Built
- 5 specialized D3 renderers (dotplot, rug, errorbar, linerange, pointrange)
- Standardized onRender pattern across all d3_* interactivity functions
- Full interactivity wiring for all new geoms (hover, tooltip, brush, zoom)
- Scoped interval updateGeoms handler with flip-aware coordinate logic
- Regenerated README.md documenting all 25 geoms and composable interactivity API

### What Worked
- Milestone audit caught integration gaps (INTERACTIVE_SELECTORS, updateGeoms stub) before shipping
- Gap closure phase (26) cleanly addressed all audit findings with minimal scope
- Parallel executor agents completed both Wave 1 plans simultaneously
- Research phase accurately identified all insertion points by line number

### What Was Inefficient
- Phase 24 shipped geom renderers without wiring interactivity, requiring Phase 26 gap closure
- Audit status remained `gaps_found` even after gap closure phase completed (stale audit)
- README.Rmd was updated in Phase 25 but `build_readme()` wasn't run until Phase 26

### Patterns Established
- Milestone audits before completion catch integration gaps that per-phase verification misses
- INTERACTIVE_SELECTORS arrays must be updated whenever new geom CSS classes are introduced
- updateGeoms handlers need scoped selectors per geom sub-type to prevent cross-contamination

### Key Lessons
1. New geom implementation should include interactivity wiring in the same phase — rendering and interaction are not independent concerns
2. Documentation generation (`build_readme()`) should be a task in the phase that changes README.Rmd, not deferred

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Pattern |
|-----------|--------|-------|-------------|
| v1.7 | 4 | 6 | Research → prototype → design contract → implementation blueprint |
| v1.6 | 3 | 4 | Milestone audit → gap closure phase |

### Recurring Issues

- Integration gaps when features span multiple modules (selectors, handlers, renderers)
- Documentation regeneration deferred and forgotten
- Validation metadata can become stale even when phase verification passes

### What to Watch

- As geom count grows (25+), INTERACTIVE_SELECTORS maintenance becomes a scaling concern — consider auto-registration pattern
- Spatial support should not expand into GIS-engine behavior without explicit product intent and validation budget
