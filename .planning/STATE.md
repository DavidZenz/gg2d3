# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-23)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

**Current focus:** Post-v1.6 Stability & Feature Parity achieved.

## Current Position

Milestone: v1.6 Advanced Geoms & API Polish — COMPLETED 2026-03-31
Phase: 25 of 25 (API Polish & Performance)
Plan: 01 of 01 (Phase 25)
Status: Stable / Final Audit
Last activity: 2026-03-31 - Completed Milestone v1.6

Progress: [██████████] 100% (All planned milestones v1.0-v1.6 complete)

## Performance Metrics

- Total requirements delivered: 15+ (v1.1-v1.6)
- Core geoms supported: 25
- Interactivity modules: 14
- Current blockers: None

## Accumulated Context

### Key Decisions

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 13-roadmap | Start numbering at Phase 13 to continue from v1.0 Phase 12 | Preserve milestone continuity |
| 13-roadmap | Map v1.1 phases strictly from active LEG/DATE/COORD requirements | Keep scope traceable to validated requirements |
| 13-roadmap | Keep requirement categories as independent phases | Comprehensive depth favors explicit delivery boundaries |
| 13-01 | Split legend state into persistent (`hidden`, `solo`) and transient (`hover`) channels | Prevent hover previews from mutating persistent filter state |
| 13-01 | Route discrete legend interactions via semantic `d3.dispatch` events | Deterministic toggle/solo/reset behavior and modular integration |
| 13-01 | Keep colorbar guides non-interactive | Maintain discrete-only scope and guide semantics |
| 13-02 | Derive mark legend identity from discrete mapped aesthetics and attach stable `data-legend-*` attributes | Ensure deterministic legend-to-mark matching across redraws/facets |
| 13-02 | Apply hidden > solo > crosstalk/brush > hover precedence through a single state pass | Prevent contradictory visuals when interaction modes compose |
| 13-02 | Synchronize legend persistent filters through existing Crosstalk `SelectionHandle` set/clear flow | Keep linked widgets deterministic without introducing a new transport |
| 13-03 | Enforce stable key `value` fields in IR for all discrete guides | Ensure interaction contract robustness across complex/merged scales |
| 14-01 | Prioritize pre-formatted labels from ggplot2 for temporal axes | Guarantees label parity for complex formatters and custom breaks |
| 14-01 | Multi-level timezone fallback (Scale object -> Scale closure -> Domain attribute) | Maximizes TZ detection reliability across various ggplot2 usage patterns |
| 15-01 | Swap d3.axis generators in renderPanel based on flip state | Corrects axis placement for flipped faceted plots |
| 15-01 | Relax validate_ir length checks for categorical domains | Supports full level vector preservation in panel metadata |
| 16-01 | Centralize geom repositioning in `geomRegistry.js` | Enables reusable transition logic across all interactive modules |
| 16-01 | Force duration 0 if `prefers-reduced-motion` is active | Ensures accessibility compliance out of the box |
| 17-01 | Extract per-panel minor breaks into `panels_ir` | Guarantees correct grid rendering for free-scale facets |
| 17-01 | Use built data for all IR layers | Preserves OOB transformations (squish/censor) during interactive redraws |
| 18-01 | Move to hierarchical strip extraction in IR | Enables accurate rendering of nested facet headers |
| 18-01 | Multiply strip dimension by nesting depth in layout engine | Allocates correct space for multi-level hierarchical headers |
| 19-01 | Use onRender with setTimeout for custom handler attachment | Ensures D3 DOM is ready before binding user events |
| 19-01 | Automatic Shiny.setInputValue integration | Provides zero-config synchronization for basic plot-click workflows |
| 20-01 | Implement hierarchical JS theme lookups | Matches ggplot2 inheritance tree for robust D3-side styling |
| 20-01 | Extract margins and units systematically | Improves layout accuracy and visual fidelity for text and legends |
| 21-01 | Implement robust panel-intersection logic for abline | Ensures diagonal annotations are accurately clipped within the plotting area |
| 21-01 | Unified reference geom update logic | Enables hline/vline to participate in animated scale transitions |
| 22-01 | Support theta mapping in coord_polar | Enables both pie charts (theta=y) and coxcomb plots (theta=x) |
| 22-01 | Specialized radial/circular axis rendering | Provides visual parity for non-Cartesian grids and labels |
| 22-01 | Wrap theme extraction in tryCatch | Prevents crashes when ggplot2 base themes have non-standard element classes |
| 23-01 | Support animated statistical paths | Extends transition system to density and smooth geoms with complex area/line interpolation |
| 24-01 | Unified interval geom renderer | Handles errorbar, linerange, and pointrange with a single modular function |
| 24-01 | Data-driven rug sides | Supports ggplot2's complex side-mapping logic while preserving interactivity |
| 24-01 | Dotplot pixel conversion | Corrects stacking height and dot radius by deriving pixel-per-unit ratios from D3 scales |
| 25-01 | Standardize onRender timing | Ensures all interactivity features wait for the initial D3 DOM pass |
| 25-01 | Structural IR diffing in JS | Prevents flickering and white flashes by bypassing full redraws when only state (legends/etc) changes |

### Active TODOs
- Final package documentation audit.
- Prepare for release.

### Blockers
- None.

## Session Continuity

Last session: 2026-03-31
Stopped at: Completed Milestone v1.6 execution
Resume file: .planning/MILESTONES.md

---
*State initialized: 2026-02-07*
*v1.0 shipped: 2026-02-16*
*v1.1 shipped: 2026-03-31*
*v1.2 shipped: 2026-03-31*
*v1.3 shipped: 2026-03-31*
*v1.4 shipped: 2026-03-31*
*v1.5 shipped: 2026-03-31*
*v1.6 shipped: 2026-03-31*
