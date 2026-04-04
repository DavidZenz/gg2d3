# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

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
| v1.6 | 3 | 4 | Milestone audit → gap closure phase |

### Recurring Issues

- Integration gaps when features span multiple modules (selectors, handlers, renderers)
- Documentation regeneration deferred and forgotten

### What to Watch

- As geom count grows (25+), INTERACTIVE_SELECTORS maintenance becomes a scaling concern — consider auto-registration pattern
