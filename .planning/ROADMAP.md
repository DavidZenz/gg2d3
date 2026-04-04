# Roadmap: gg2d3

## Overview

This roadmap defines milestone **v1.6 Advanced Geoms & API Polish**. The phase structure continues from v1.5 and focuses on completing the geom catalog and refining the developer experience.

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- 🟡 **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (in progress)

## Phases

### Phase 24 - Specialized Geoms

**Goal:** Implement specialized geoms for data density and interval visualizations.

**Requirements:** GEOM-20, GEOM-21, GEOM-22

**Success Criteria (observable):**
1. `geom_dotplot` correctly stacks dots based on bin width.
2. `geom_rug` renders markers along axis boundaries.
3. `geom_errorbar` and related geoms correctly show interval bounds.

### Phase 25 - API Polish & Performance

**Goal:** Refine internal helpers and optimize rendering for larger datasets.

**Requirements:** API-01, API-02, PERF-01

**Success Criteria (observable):**
1. Developer documentation is clear and accurate.
2. Plots with >5000 points remain responsive.

### Phase 26 - New Geom Interactivity Wiring

**Goal:** Wire Phase 24 geoms into the interactivity system so dotplot, rug, and interval geoms participate in brush, hover, tooltip, and zoom interactions. Regenerate shipped documentation.

**Requirements:** GEOM-20, GEOM-21, GEOM-22, API-02

**Gap Closure:** Closes all gaps from v1.6 milestone audit.

**Plans:** 2/2 plans complete

Plans:
- [x] 26-01-PLAN.md — Wire dotplot, rug, and interval geoms into interactivity selectors and implement interval zoom handler
- [x] 26-02-PLAN.md — Regenerate README.md from README.Rmd

**Success Criteria (observable):**
1. `geom_dotplot` marks respond to brush selection, hover highlighting, and tooltips.
2. `geom_rug` marks respond to brush selection, hover highlighting, and tooltips.
3. `geom_errorbar`, `geom_linerange`, and `geom_pointrange` reposition correctly on zoom/reset and respond to interactivity modules.
4. `README.md` reflects all v1.6 features (regenerated from `README.Rmd`).

## Progress

| Phase | Milestone | Goal | Requirements | Status |
|-------|-----------|------|--------------|--------|
| 24. Specialized Geoms | v1.6 | Implementation of dotplot, rug, and errorbars | GEOM-20..22 | Complete |
| 25. API Polish & Performance | v1.6 | Documentation, helpers, and performance tuning | API-01..02, PERF-01 | Complete |
| 26. New Geom Interactivity Wiring | v1.6 | 2/2 | Complete   | 2026-04-04 |

---
*Roadmap updated: 2026-04-03*
