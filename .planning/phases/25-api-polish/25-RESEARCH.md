# Phase 25 Research: API Polish & Performance

## Objective
Finalize the developer API, improve documentation consistency, and optimize rendering performance for larger datasets.

## Current State Analysis

### 1. Developer API
- **Status:** The internal geom registration system is robust but requires manual script inclusion in `gg2d3.yaml`.
- **Polish:** Standardize the `onRender` pattern across all `d3_*` functions to ensure they always wait for the D3 drawing pass.

### 2. Performance
- **Status:** `draw()` clears the entire SVG (`d3.select(el).selectAll("*").remove()`) on every update.
- **Bottleneck:** While acceptable for small plots, this causes noticeable flickering and overhead for plots with thousands of marks.
- **Requirement:** Implement a "diffing" or "update-only" mode where `draw()` only updates changed attributes if the IR structure is mostly identical.

### 3. Documentation
- **Status:** Functions have good basic Roxygen headers.
- **Requirement:** Ensure all parameters and examples are consistent and up-to-date with the latest IR structure changes (e.g., `coord_polar` and hierarchical strips).

## Technical Proposals

### Performance Optimization: Targeted Redraw
Modify the `renderValue` logic:
1. Instead of always clearing the SVG, check if the "skeleton" (scales, facets) is unchanged.
2. If only data or state (legend toggle) has changed, use the existing `updateGeoms` logic instead of a full `draw()`.
3. For large datasets (>2000 points), consider using Canvas for rendering or simplifying the D3 selection pass.

### API Polish
- Create a `gg2d3_version` constant.
- Unified input validation helper for all `d3_*` functions.

## Proposed Plan (25-01-PLAN.md)
1. Standardize all `d3_*` functions with a common validation and `onRender` template.
2. Implement basic "update-only" mode in `gg2d3.js` to prevent unnecessary full redraws.
3. Conduct a final documentation audit and update news/README.
4. Add a performance stress test to the test suite.

---
*Research completed: 2026-03-31*
