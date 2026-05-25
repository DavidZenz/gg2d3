# Phase 44: Ordinary geom_polygon Support - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 44 delivers ordinary `geom_polygon()` support for gg2d3. Users should be able to render grouped Cartesian polygons as SVG paths with representative styling, facets, and existing interactivity hooks. This phase does not add sf annotation behavior, rect/tile edge fixes, GIS topology repair, screenshot-diff infrastructure, or new interactivity APIs.

</domain>

<decisions>
## Implementation Decisions

### Polygon Group Semantics
- **D-01:** Render ordinary `geom_polygon()` as one SVG path per `group`, preserving row order from ggplot2 built data.
- **D-02:** Support multiple groups/polygons in one layer when ggplot2 built data provides distinct groups.
- **D-03:** Defer explicit hole/subgroup/topology semantics unless ggplot2 built data already represents them cleanly without special topology work.
- **D-04:** Treat row-order preservation as part of the public rendering contract; planners should avoid automatic sorting that would reorder intentional polygon paths.

### Styling Contract
- **D-05:** Lock core visible polygon styling in Phase 44: `fill`, `colour`/stroke, `alpha`, `linewidth`, and `linetype`.
- **D-06:** `fill = NA` should render as no fill, and `colour = NA` should render as no stroke.
- **D-07:** Broader styling edge cases beyond the core polygon contract are not Phase 44 scope unless they fall out naturally from existing helpers.

### Interactivity Behavior
- **D-08:** Ordinary polygon marks are interactive at the group/path level.
- **D-09:** Tooltip, hover, custom handler, and Shiny-style handler payloads should use a sanitized representative source row for the polygon group.
- **D-10:** Brush selection should use SVG path bounds for ordinary Cartesian polygons rather than sf-style centroid/anchor semantics.
- **D-11:** Do not create a new polygon-specific interactivity API; reuse existing tooltip, hover, brush, and handler plumbing.

### Validation Matrix
- **D-12:** Phase 44 should include IR tests, JavaScript source/contract tests, and browser DOM smoke coverage.
- **D-13:** Representative validation cases must include: single polygon, multiple groups, facets, mapped styling, `NA` fill/stroke behavior, and interactivity selectors/payload sanitization.
- **D-14:** Do not add screenshot or perceptual comparison infrastructure in Phase 44; DOM/source assertions are the expected automated gate.

### the agent's Discretion
- Exact helper names, file split, and fixture names are left to research/planning.
- Planner may decide whether to implement polygon rendering in a new `inst/htmlwidgets/modules/geoms/polygon.js` file or another established renderer location, provided registry and bundle conventions are followed.
- Planner may choose the exact representative source row for group-level payloads, as long as the choice is deterministic, sanitized, and documented in tests.

</decisions>

<specifics>
## Specific Ideas

- Conservative defaults are preferred over ambitious topology work.
- Ordinary polygon brush behavior should stay Cartesian and bounds-based, unlike sf brushing, which uses representative centroid/anchor attributes.
- `geom_polygon()` should close the v1.10 deferred parity item without expanding into map-engine behavior.

</specifics>

<canonical_refs>
## Canonical References

### Milestone and phase scope
- `.planning/PROJECT.md` - v1.11 Geometry Parity project context and active milestone goal.
- `.planning/REQUIREMENTS.md` - POLY-01, POLY-02, and POLY-03 define Phase 44 requirements.
- `.planning/ROADMAP.md` - Phase 44 boundary, success criteria, and plan structure.

### Prior decisions
- `.planning/milestones/v1.8-phases/33-single-panel-renderer-and-interactivity/33-CONTEXT.md` - Reuse existing interactivity APIs, sanitize renderer-private fields, preserve path mark contracts.
- `.planning/milestones/v1.9-phases/37-non-polygon-sf-ir-and-renderer/37-CONTEXT.md` - Keep shared selectors, source-row-oriented payloads, and stable mark classes.
- `.planning/milestones/v1.9-phases/38-sf-interaction-facet-and-documentation-hardening/38-CONTEXT.md` - Prefer DOM/IR assertions and sanitized payload proof over visual screenshot assertions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/as_d3_ir.R` already maps `GeomPolygon` to `"polygon"` and preserves `x`, `y`, `group`, fill/stroke, alpha, linewidth, linetype, and panel-related columns in the general layer data path.
- `R/validate_ir.R` already recognizes `"polygon"` as a known geom type.
- `inst/htmlwidgets/modules/geom-registry.js` provides the renderer registration and dispatch pattern used by existing geoms.
- `inst/htmlwidgets/modules/geoms/area.js` and related path geoms provide useful examples for grouping rows into D3 path data.
- `inst/htmlwidgets/modules/events.js`, `brush.js`, and `crosstalk.js` define selector arrays and payload-handling paths that should be extended for polygon marks.

### Established Patterns
- Path-like geoms use SVG `path` nodes with classes such as `geom-area`, `geom-ribbon`, `geom-line`, and `geom-path`.
- sf paths already participate in existing interactivity by using shared selectors and sanitized callback payloads.
- Browser validation for sf behavior uses optional chromote/testthat helpers and DOM-level assertions, not screenshot diffs.

### Integration Points
- R layer: `R/as_d3_ir.R` may need targeted polygon-specific grouping/row-order tests even though basic recognition already exists.
- JS renderer: add/register a polygon renderer and ensure bundled widget dependencies load it in the correct order.
- Interactivity: add `path.geom-polygon` to relevant selector arrays and ensure brush, tooltip, hover, handlers, and crosstalk use the intended group-level data.
- Tests: add targeted tests under `tests/testthat/`, likely alongside existing IR, renderer, interactivity, browser, and regression-core coverage.

</code_context>

<deferred>
## Deferred Ideas

- Explicit polygon hole/subgroup/topology support beyond clean ggplot2 built-data grouping.
- Screenshot or perceptual visual regression infrastructure.
- sf text/label annotations, covered by Phase 46.
- Rect/tile out-of-bounds behavior, covered by Phase 45.

</deferred>

---

*Phase: 44-ordinary-geom-polygon-support*
*Context gathered: 2026-05-24*
