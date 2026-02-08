# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

**Current focus:** Phase 2 - Core Scale System (in progress)

## Current Position

Phase: 2 of 11 (Core Scale System)
Plan: 1 of 3 in Phase 2 complete
Status: In progress — Phase 2 executing
Last activity: 2026-02-08 — Completed 02-01-PLAN.md (Panel Params Scale Extraction). 2 plans remaining in Phase 2.

Progress: [█░░░░░░░░░] 12% (6/51 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 12.2 min
- Total execution time: 1.2 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation-refactoring | 5/5 | 70.4 min | 14.1 min |
| 02-core-scale-system | 1/3 | 3 min | 3.0 min |

**Recent Trend:**
- Last 5 plans: 01-03 (2.4 min), 01-04 (2 min), 01-05 (~3 min), 02-01 (3 min)
- Trend: Most plans execute quickly (2-3 min), except TDD/extraction intensive plans

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Geom coverage before visual polish — User priority; broader coverage unlocks more use cases
- Legends early, facets later — Legends needed to verify geom rendering; facets are more complex
- Pipe-based interactivity API — Composable like ggplot layers: `gg2d3(p) |> d3_tooltip() |> d3_link()`
- Pixel-perfect fidelity target — R community expects professional output matching ggplot2

**From Plan 01-01:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| namespace-pattern | Use window.gg2d3 namespace for module exports | HTMLWidgets loads scripts in order; global namespace enables module communication | All future modules follow this pattern |

**From Plan 01-02:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| theme-deep-merge | Theme module uses deep merge for user overrides | Nested objects merge at all levels instead of replacing entire objects | Enables partial theme customization without losing defaults |
| helpers-in-constants | Shared utilities in constants.js instead of separate file | Both Plan 01-01 and 01-02 needed same helpers; avoids duplication | All modules share utilities via window.gg2d3.helpers namespace |

**From Plan 01-03:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| geom-dispatch-pattern | Use registry-based dispatch for geom rendering | Enables adding new geoms without modifying core code; each geom is self-contained | All future geoms follow this pattern; main draw() function will be simplified |
| makeColorAccessors-utility | Centralize color accessor creation in registry module | All geoms need identical color/fill/opacity logic; avoid duplication | Consistent color handling across all geoms; easier to maintain |
| geom-self-registration | Each geom renderer self-registers on load | No central registration list to maintain; adding geom = create file + load in YAML | More maintainable; clear separation of concerns |

**From Plan 01-04:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| validate-before-js | Validate IR in R before JavaScript | Catch errors early with clear R messages instead of cryptic JS failures | Better developer experience, easier debugging |
| warnings-for-non-critical | Use warnings for non-critical issues (empty data, unknown geoms) | Allows experimentation while alerting to potential problems | More flexible, less brittle |
| invisible-return | validate_ir() returns IR invisibly | Enables chaining and maintains original IR unchanged | Clean integration into pipeline |

**From Plan 02-02:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| transform-first-dispatch | Transform field takes priority over type field in scale descriptors | Ensures {type: "continuous", transform: "log10"} creates log scale, not linear | All scale creation checks transform before type |
| ir-breaks-as-ticks | Use IR breaks instead of D3 auto-generated ticks | D3's log ticks too dense and don't match ggplot2; ggplot2 pre-computes correct breaks | Axis ticks now match ggplot2 exactly |
| clean-tick-formatting | Apply d3.format('.4~g') for transformed scales | Avoid scientific notation (1e+3) on log/sqrt/pow scales; show clean numbers (1000) | Better readability, matches ggplot2 output |

### Pending Todos

None.

### Pre-existing Issues Found During Phase 1 Verification

These issues were identified during the 01-05 visual verification checkpoint. They are **not regressions** — they existed before Phase 1 refactoring and are tracked for resolution in later phases:

- **Scale expansion missing on bar charts** — X-axis padding not implemented; bars touch axis edges (Phase 2, Plan 02-02)
- **coord_flip rendering broken** — Axes on wrong sides after flip (Phase 3, Plan 03-01)
- **rect geom out of bounds / grid issues** — rect/tile edge cases with rendering (Phase 2/3)

### Blockers/Concerns

**Phase 1 (Foundation) — COMPLETE:**
- ~~Hardcoded unit conversions scattered across R and JavaScript must be centralized~~ — RESOLVED in 01-01
- ~~Monolithic draw() geom rendering (lines 436-662) blocks adding new geoms~~ — RESOLVED in 01-03
- ~~Monolithic gg2d3.js (717 lines) needs modularization~~ — RESOLVED in 01-05 (169 lines)
- Monolithic as_d3_ir() function (353 lines) needs modularization before adding features
- Private API dependency on ggplot2:::calc_element() creates fragility

**Phase 2 (Scales):**
- ~~Scale expansion mismatch causes data to touch axis edges (5% padding not implemented)~~ — RESOLVED in 02-01
- Discrete scale index mapping fails with unusual factor scenarios

**Phase 3 (Coordinates):**
- coord_flip axes on wrong sides (documented bug in CONCERNS.md)

**Known from research:**
- ggplot2 private API usage may break on updates (mitigation: wrap in try-catch, version testing)
- Statistical transformations trap (Phase 5): must pre-compute in R or implement algorithms in JavaScript
- Facet data structure complexity (Phase 8-9): not "just multiple subplots" — requires sophisticated layout math

## Session Continuity

Last session: 2026-02-08
Stopped at: Completed 02-01 (Panel Params Scale Extraction). 2 plans remaining in Phase 2.
Resume file: .planning/phases/02-core-scale-system/02-01-SUMMARY.md
Next action: Execute 02-02 (Transform-Aware Scale Rendering) next.

---
*State initialized: 2026-02-07*
*Phase 1 completed: 2026-02-07*
