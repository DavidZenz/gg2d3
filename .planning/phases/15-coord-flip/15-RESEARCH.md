# Phase 15 Research: coord_flip Correctness Hardening

## Objective
Ensure `coord_flip` correctly places x/y axes on the proper sides (horizontal vs. vertical) and maintains consistent orientation in both single-panel and faceted plots.

## Current State Analysis

### 1. Axis Placement (`COORD-01`)
- **Single-panel:** `inst/htmlwidgets/gg2d3.js` (L498) correctly handles `flip` by creating a `leftAxisGen` for `axisXScale` and a `bottomAxisGen` for `axisYScale`.
- **Faceted-panel:** `renderPanel` in `gg2d3.js` (L430) has a **BUG**: it always uses `d3.axisBottom(panelXScale)` and `d3.axisLeft(panelYScale)`, regardless of the `flip` state.
- **R Side:** `R/as_d3_ir.R` correctly swaps `x_label` and `y_label` and un-swaps `panel_params` (L480) so that `ir$scales$x` always refers to the x-aesthetic.

### 2. Faceted Orientation (`COORD-02`)
- In `renderPanel`, when `flip` is true:
  - The x-aesthetic (usually categorical) is rendered vertically. It should use `axisLeft`.
  - The y-aesthetic (usually continuous) is rendered horizontally. It should use `axisBottom`.
- Currently, `renderPanel` does not swap these generator types, leading to axes being rendered on the wrong sides or with incorrect tick orientations in faceted plots.

### 3. Redundancy in R
- `is_flip_early` (L495) and `is_flip` (L595) are duplicate logic. Consolidating them will improve readability.

## Technical Proposals

### Fix `renderPanel` Axis Logic
Modify `renderPanel` to mirror the single-panel axis logic:
```javascript
if (flip) {
  // x-aesthetic is vertical -> LEFT axis
  const leftAxisGen = d3.axisLeft(panelXScale);
  // ... apply breaks/formats ...
  const leftAxis = ag.append("g").attr("class", "axis axis-left").call(leftAxisGen);
  
  // y-aesthetic is horizontal -> BOTTOM axis
  // ... similar for bottom ...
} else {
  // normal logic
}
```

### Regression Tests
1. **Test 1:** Single-panel `coord_flip` (confirm already working).
2. **Test 2:** `facet_wrap` + `coord_flip` (should fail before fix).
3. **Test 3:** `facet_grid` + `coord_flip` (should fail before fix).

## Proposed Plan (15-01-PLAN.md)
1. Consolidate `is_flip` logic in `R/as_d3_ir.R`.
2. Implement the axis-swapping logic in `renderPanel` within `inst/htmlwidgets/gg2d3.js`.
3. Add comprehensive regression tests for `coord_flip` + facets in `tests/testthat/test-coord-flip.R` (new file).
4. Verify visual correctness with a specialized visual check script.

---
*Research completed: 2026-03-31*
