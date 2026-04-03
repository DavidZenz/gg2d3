# Phase 22 Research: Polar Coordinates

## Objective
Implement `coord_polar` support to enable radial visualizations like pie charts, coxcomb plots, and radar charts.

## Current State Analysis

### 1. IR Extraction
- **Status:** `as_d3_ir.R` currently detects `CoordFlip` and `CoordFixed`.
- **Requirement:** Add detection for `CoordPolar`. Extract `theta` (usually "x"), `start` (offset angle), and `direction` (1 for clockwise, -1 for CCW).
- **Mapping:** In polar coords, one aesthetic (the `theta` variable) maps to an angle `[0, 2π]`, and the other (the `r` variable) maps to a radius `[0, R]`.

### 2. D3 Scales
- **Status:** `scales.js` creates linear/categorical scales.
- **Requirement:** 
  - Angular scale: `d3.scaleLinear().domain(domain).range([start, start + direction * 2 * Math.PI])`.
  - Radial scale: `d3.scaleLinear().domain(domain).range([0, maxRadius])`.

### 3. Axis Rendering
- **Status:** `gg2d3.js` uses `d3.axisBottom` and `d3.axisLeft`.
- **Requirement:** 
  - **Circular Axis:** Draws ticks and labels around the circumference.
  - **Radial Axis:** Draws ticks and labels along a radius (usually the vertical one).
  - **Grid Lines:** Circular lines for radial breaks, radiating lines for angular breaks.

### 4. Geom Support
- **Status:** Geoms use Cartesian `x`/`y` for positioning.
- **Requirement:** Geoms must be aware of the polar transformation. 
  - `point`: `x = cx + r * cos(theta)`, `y = cy + r * sin(theta)`.
  - `bar` (Pie): Maps to `d3.arc()`.
  - `path/line`: Needs to interpolate points in polar space or use `d3.lineRadial()`.

## Technical Proposals

### Coordinate System IR
```json
"coord": {
  "type": "polar",
  "theta": "x",
  "start": 0,
  "direction": 1
}
```

### JS Scale Factory Enhancement
Update `scales.js` to provide helpers for polar conversion:
```javascript
function getPolarCoords(r, theta, center, maxRadius) {
  // convert r/theta to x/y
}
```

### Specialized Polar Renderer
In `gg2d3.js`, if `ir.coord.type === "polar"`, bypass standard axis rendering and call a new `renderPolarAxes` helper.

## Proposed Plan (22-01-PLAN.md)
1. Add `is_polar` detection and parameter extraction to `as_d3_ir.R`.
2. Update `scales.js` with radial and angular scale helpers.
3. Implement `renderPolarAxes` in `gg2d3.js` for circular/radial grid and labels.
4. Update `geomRegistry.js` to support polar transformations for basic geoms (point, text).
5. Add specialized arc-based renderer for `geom_bar` in polar coords (Pie charts).
6. Add regression tests for polar IR structure.

---
*Research completed: 2026-03-31*
