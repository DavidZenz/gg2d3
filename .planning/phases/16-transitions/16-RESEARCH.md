# Phase 16 Research: Animated Transitions

## Objective
Implement object-constant enter/update/exit transitions for marks and axes during interactive state changes (zoom, filter, crosstalk).

## Current State Analysis

### 1. Element Repositioning
- Currently, `zoom.js` has a `repositionElements` function that manually updates `cx`, `cy`, `x`, `y`, and `d` attributes.
- This function is specific to zoom and does not support transitions (it uses `.attr()` directly).
- Other interactions (crosstalk, legend toggle) typically trigger a full `renderValue` redraw or a simple opacity pass, missing out on smooth animations.

### 2. D3 Transitions
- D3 provides a powerful `.transition()` API that handles interpolation between old and new attribute values.
- **Challenge:** Elements need stable identities (key functions) to support object constancy during enter/update/exit.
- **Challenge:** Path-based geoms (`geom_line`, `geom_area`, etc.) require specialized interpolation if the number of points changes.

### 3. Motion Preferences
- We need to respect `prefers-reduced-motion` and provide an R-side toggle `d3_transitions(none)`.

## Technical Proposals

### Centralized `updateGeoms` in `geomRegistry.js`
Move `repositionElements` from `zoom.js` to `geomRegistry.js` and enhance it to support optional transitions:
```javascript
function updateGeoms(container, xScale, yScale, options) {
  const t = options.transition || d3.transition().duration(0);
  
  container.selectAll('circle.geom-point')
    .transition(t)
    .attr('cx', d => xScale(d.x))
    .attr('cy', d => yScale(d.y));
    
  // ... similar for other geoms ...
}
```

### Stable Keys
In the initial render, we should use a key function for D3 data joins. 
- For most geoms, an index-based or row-id-based key is sufficient if the data structure is stable.
- For faceted plots, `PANEL + row_index` could serve as a stable key.

### Axis Transitions
`d3.axis` supports transitions out of the box:
```javascript
axisGroup.transition(t).call(axisGen);
```

### Path Interpolation
For `geom_line` and `geom_ribbon`, we can use `attrTween` with `d3.interpolatePath` (if we add the dependency) or a simpler strategy if point counts are identical.

## Proposed Plan (16-01-PLAN.md)
1. Add R-side `d3_transitions()` config function to set transition duration/easing in the IR.
2. Refactor `zoom.js` to use a centralized `updateGeoms` helper.
3. Implement `updateGeoms` in `geomRegistry.js` with D3 transition support.
4. Update `renderValue` logic to support "update" mode instead of "clear and redraw" where possible.
5. Add regression tests for motion preference and transition presence.

---
*Research completed: 2026-03-31*
