# Phase 9: Advanced Faceting - Context

**Gathered:** 2026-02-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend faceting from `facet_wrap` with fixed scales (Phase 8) to `facet_grid` with free scales and complex multi-panel layouts. This phase adds: `facet_grid()` 2D row×column layouts, `scales = "free"` / `"free_x"` / `"free_y"` for per-panel axis ranges, handling of missing row×column combinations, and strip label placement for both row and column variables.

</domain>

<decisions>
## Implementation Decisions

### Overarching Principle
- Clone ggplot2 behavior exactly — every rendering decision defaults to matching ggplot2's output
- This applies to all gray areas: free scale axes, missing combinations, strip layout, nested faceting

### Free Scale Axes
- `scales = "free"`: each panel gets its own x and y axis range and tick labels (per ggplot2)
- `scales = "free_x"`: per-panel x ranges, shared y (per ggplot2)
- `scales = "free_y"`: per-panel y ranges, shared x (per ggplot2)
- Tick labels appear on every panel that needs them (leftmost column for y, bottom row for x with fixed; every panel for free axis)

### Missing Combinations
- facet_grid with missing row×column combos shows blank/empty panels in the grid (per ggplot2)
- Grid structure remains rectangular — no collapsing

### Strip Label Layout
- Column strips on top (ggplot2 default)
- Row strips on right (ggplot2 default)
- Multi-variable strips (e.g., `facet_grid(a + b ~ c)`) render as ggplot2 does

### Scope Boundaries
- `facet_grid(rows ~ cols)` with single or multiple variables per dimension
- Free/fixed/free_x/free_y scale modes
- Missing combination handling
- Strip placement matching ggplot2 defaults (top/right)

### Claude's Discretion
- Implementation order (which features to tackle in which plan)
- Whether to extract panel-specific scale data in R or compute in JS
- How to structure the layout engine extensions for 2D grids
- Performance tradeoffs for many-panel grids

</decisions>

<specifics>
## Specific Ideas

- Match ggplot2 exactly — the project's core value is pixel-perfect fidelity
- Phase 8 established the facet rendering architecture (renderPanel, layout engine panels array, strip rendering) — extend rather than rewrite

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-advanced-faceting*
*Context gathered: 2026-02-13*
