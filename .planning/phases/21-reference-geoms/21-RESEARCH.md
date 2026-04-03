# Phase 21 Research: Reference Geoms

## Objective
Implement `geom_hline`, `geom_vline`, and `geom_abline` to provide high-fidelity annotation support.

## Current State Analysis

### 1. Data Extraction
- **Status:** `as_d3_ir.R` already includes `slope`, `intercept`, `xintercept`, and `yintercept` in the `keep_aes` list.
- **Limitation:** The `aes` mapping object in `as_d3_ir.R` (L260 approx) only includes basic aesthetics. We need to add mappings for these reference parameters.
- **Verification:** Ensure that `geom_hline(aes(yintercept = ...))` works as well as static `geom_hline(yintercept = ...)`.

### 2. D3 Rendering
- **Status:** There are currently no renderers for these geoms in the JS modules.
- **Requirement:** New renderers in a `reference.js` module.
- **Clipping:** These geoms must respect the panel clipping area. `hline` and `vline` are simple lines extending across the full panel width/height. `abline` requires calculating intersection points with the panel boundaries.

### 3. Discrete Scales
- **Requirement:** If `yintercept` is used on a categorical axis, ggplot2 maps it to the numeric index of the level. We need to ensure `as_d3_ir` handles this correctly (possibly by NOT calling `map_discrete` for intercept columns).

## Technical Proposals

### Update `as_d3_ir.R` Aes Mapping
```r
aes <- list(
  # ... existing ...
  slope = if ("slope" %in% cols) "slope" else NULL,
  intercept = if ("intercept" %in% cols) "intercept" else NULL,
  xintercept = if ("xintercept" %in% cols) "xintercept" else NULL,
  yintercept = if ("yintercept" %in% cols) "yintercept" else NULL
)
```

### Reference Geom Renderers (`reference.js`)
- **`renderHline`**: Draw a line from `x=0` to `x=panelW` at `y=yScale(yintercept)`.
- **`renderVline`**: Draw a line from `y=0` to `y=panelH` at `x=xScale(xintercept)`.
- **`renderAbline`**: 
  - Equation: `y = slope * x + intercept`.
  - Find intersections with `x=0`, `x=panelW`, `y=0`, `y=panelH`.
  - Draw line between the two valid intersection points.

### Animation Support
Add these geoms to `updateGeoms` in `geom-registry.js` so they transition smoothly during zoom/resets.

## Proposed Plan (21-01-PLAN.md)
1. Add regression tests for reference geoms (continuous and discrete).
2. Update `as_d3_ir.R` to correctly extract reference aesthetic mappings.
3. Create `inst/htmlwidgets/modules/geoms/reference.js` and register the new renderers.
4. Update `geom-registry.js` to support updating reference lines during transitions.
5. Verify visual correctness with a specialized check script.

---
*Research completed: 2026-03-31*
