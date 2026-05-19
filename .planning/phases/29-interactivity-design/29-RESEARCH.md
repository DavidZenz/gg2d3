# Phase 29: Interactivity Design - Research

**Researched:** 2026-05-19
**Phase:** 29 - Interactivity Design
**Domain:** Design documentation for `geom_sf` interactivity in gg2d3
**Confidence:** HIGH for tooltip/hover and brush; MEDIUM-HIGH for zoom deferral framing

## Research Question

What needs to be known to plan Phase 29 well?

Phase 29 is not a production implementation phase. It should produce written design artifacts that downstream build agents can use without re-opening decisions about tooltip/hover selectors, brush semantics, or sf zoom behavior.

## Inputs Read

- `.planning/phases/29-interactivity-design/29-CONTEXT.md` - user-locked decisions
- `.planning/REQUIREMENTS.md` - `INTR-01`, `INTR-02`, `INTR-03`
- `.planning/ROADMAP.md` - Phase 29 goal and success criteria
- `.planning/research/SUMMARY.md` - v1.7 choropleth architecture synthesis
- `.planning/research/ARCHITECTURE.md` - interactivity flow and integration points
- `.planning/research/FEATURES.md` - feature priorities and explicit deferrals
- `.planning/research/PITFALLS.md` - zoom and brush pitfalls
- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` - sf renderer DOM/data contract
- `.planning/phases/28-d3-renderer-prototyping/28-UI-SPEC.md` - path attribute contract
- `inst/htmlwidgets/modules/events.js` - tooltip/hover selector architecture
- `inst/htmlwidgets/modules/tooltip.js` - bound-row tooltip formatting and `aes_by_var`
- `inst/htmlwidgets/modules/brush.js` - pixel-rectangle brush implementation
- `inst/htmlwidgets/modules/zoom.js` - Cartesian zoom implementation
- `inst/htmlwidgets/modules/geoms/sf.js` - sf path renderer and centroid attributes
- `R/d3_zoom.R` - R-side zoom entry point

## Key Findings

### Finding 1: tooltip and hover design is mostly a selector/data-contract document

The existing tooltip and hover machinery is already event-selector driven. `events.js` has an `INTERACTIVE_SELECTORS` array used by `attachTooltips()` and `attachHover()`. Phase 28's sf renderer already emits `path.geom-sf` and binds the row object to each path. `tooltip.js` already formats bound row data and prefers original ggplot variable names through `ir.aes_by_var`.

Planning implication: the plan should create a short but explicit section that says future implementation adds `path.geom-sf` to the existing selector list and relies on bound row data. It should reject a DOM-attribute-only tooltip model and avoid inventing a separate map-specific tooltip API.

### Finding 2: the brush comparison must be written as a tradeoff, not just a decision

`brush.js` is built around a pixel rectangle and fast element-position checks. For circles it uses `cx`/`cy`; for rectangles it checks overlap; for paths it currently falls back to bounding-box center. Phase 28 deliberately prepared sf paths with `data-cx` and `data-cy` from `d3.geoPath().centroid()`.

The Phase 29 success criterion requires a comparison of centroid-based brush selection vs polygon hit-testing, including rationale for rejecting the other approach. That comparison should be a standalone section or document with a table covering:

| Approach | Accuracy | Runtime cost | Code complexity | Fit with gg2d3 |
|----------|----------|--------------|-----------------|----------------|
| Centroid inside brush | Selects regions by representative point, can miss partial overlaps | O(n) simple coordinate checks | Low | Excellent, reuses existing pixel brush |
| Polygon overlap / hit-testing | More spatially intuitive for partial overlaps | O(n * vertices) or custom spatial logic | High | Poor for first build; risks lag and scope growth |
| Disable brush | Honest but loses linked-selection value | None | Low | Too conservative; Phase 28 already added centroid hooks |

Planning implication: at least one plan must produce this comparison and document centroid semantics in user/developer terms.

### Finding 3: zoom should be explicitly deferred, not researched again

Prior research and Phase 29 context are aligned: the existing Cartesian zoom updates scales and repositions geoms; geographic paths are generated `d` strings from a projection. SVG group transform is easy but scales stroke widths, which gg2d3 has avoided for Cartesian zoom. Projection/path re-render is the likely future approach, but is beyond the first sf build's interactivity wiring.

Planning implication: do not spend Phase 29 on a code spike. The plan should document:

- why current `d3_zoom()` must not attach to sf panels
- where the first-build guard should live conceptually (`R/d3_zoom.R`, with JS fallback if needed)
- why SVG group transform is rejected for first build
- why projection re-render is the preferred future candidate
- the exact expected user-facing behavior: R-side warning and no broken zoom attachment

### Finding 4: Phase 29 should probably create one design document, plus update summary artifacts

The cleanest deliverable is a single phase-owned design document, for example:

- `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md`

It should contain three required sections mapping directly to success criteria:

1. Tooltip and Hover Contract (`INTR-01`)
2. Brush Selection Semantics (`INTR-02`)
3. Zoom Architecture Decision (`INTR-03`)

The plan can also update `29-SUMMARY.md` after execution, but the main deliverable should be the design doc. This avoids scattering Phase 29 output across unrelated package docs before production code exists.

### Finding 5: validation should be document-structure and coverage based

Since this is a design phase, validation should not require R package tests. Verification should instead check:

- design doc exists at the planned path
- doc mentions `path.geom-sf`, `data-row-id`, `data-cx`, `data-cy`
- doc explicitly references `d3_tooltip()`, `d3_hover()`, `d3_brush()`, `d3_zoom()`
- doc covers `INTR-01`, `INTR-02`, and `INTR-03`
- doc includes a centroid-vs-polygon-hit-testing comparison table
- doc explicitly says map zoom is deferred and projection re-render is the future candidate

## Recommended Planning Shape

One plan is enough unless the planner prefers separate documentation and verification tasks. Suggested plan:

- `29-01-PLAN.md` - Write interactivity design document for sf map regions

Task breakdown:

1. Read phase context, prior Phase 28 contracts, research, and code hooks.
2. Create `29-INTERACTIVITY-DESIGN.md` with sections for tooltip/hover, brush, and zoom.
3. Add exact file-level future implementation hooks for `events.js`, `tooltip.js`, `brush.js`, `zoom.js`, `sf.js`, and `R/d3_zoom.R`.
4. Verify the document covers all requirement IDs and context decisions.

## Validation Architecture

### Dimension 1: Requirement coverage

Every Phase 29 requirement ID must map to a design section:

- `INTR-01` -> Tooltip and Hover Contract
- `INTR-02` -> Brush Selection Semantics
- `INTR-03` -> Zoom Architecture Decision

### Dimension 2: Decision preservation

Every decision in `29-CONTEXT.md` D-01 through D-12 must be represented or explicitly referenced in `29-INTERACTIVITY-DESIGN.md`.

### Dimension 3: Implementation readiness

The design doc must name concrete future implementation hooks and values:

- `path.geom-sf`
- `data-row-id`
- `data-cx`
- `data-cy`
- `events.js` selector update
- `brush.js` centroid hit test
- `R/d3_zoom.R` warning/suppression gate

### Dimension 4: Deferral clarity

The zoom section must distinguish:

- first-build behavior: suppress `d3_zoom()` for sf
- rejected first-build path: SVG group transform
- future candidate: projection/path re-render

## Pitfalls for the Planner

- Do not turn Phase 29 into production code changes; the roadmap asks for written design decisions.
- Do not make polygon-overlap brushing a task; it was explicitly rejected for first build.
- Do not mark zoom as impossible forever; it is explicitly deferred.
- Do not require a UI-SPEC; this phase is about interactivity architecture documentation, not screen layout.
- Do not rely on DOM `data-*` attributes for tooltip values beyond row/debug/geometry attributes. Bound row data is canonical.

## Recommended Files to Create or Modify

- Create `.planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md`
- Create `.planning/phases/29-interactivity-design/29-01-SUMMARY.md` during execution

No package source files should be modified in Phase 29 unless the planner deliberately adds a tiny documentation-only reference. Production implementation belongs to a later build phase.

## RESEARCH COMPLETE
