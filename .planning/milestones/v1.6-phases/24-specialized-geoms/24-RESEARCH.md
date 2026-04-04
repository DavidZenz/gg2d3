# Phase 24 Research: Specialized Geoms

## Objective
Implement `geom_dotplot`, `geom_rug`, and interval geoms (`geom_errorbar`, `geom_linerange`, `geom_pointrange`) to complete the standard ggplot2 geom catalog.

## Current State Analysis

### 1. IR Extraction
- **Status:** `as_d3_ir.R` correctly maps `GeomDotPlot`, `GeomRug`, etc., to their IR names but lacks specialized aesthetic mapping logic for some parameters.
- **Requirement:** Add `ymin`, `ymax`, `xmin`, `xmax` to the global `keep_aes` list (done in previous phases).
- **Specialized Mapping:**
  - `dotplot`: Needs `stackpos`, `binwidth`, `countidx`.
  - `rug`: Needs `sides` parameter (default "bl").
  - `errorbar/linerange/pointrange`: Standard interval aesthetics are already supported in `keep_aes`.

### 2. D3 Rendering
- **Requirement:** New modules for these specialized geoms.
- **Implementation Strategy:**
  - **`dotplot.js`**: Renders circles at `(x, y + stackpos)`.
  - **`rug.js`**: Renders small segments along the panel edges.
  - **`interval.js`**: Renders vertical/horizontal segments with optional crossbars (`errorbar`) or points (`pointrange`).

## Technical Proposals

### Dotplot Logic
In `geom_dotplot`, ggplot2 pre-calculates `stackpos`. We just need to multiply this by the dot diameter (in pixels) and offset from the baseline.

### Rug Logic
The `rug` renderer needs to know the panel width and height. It draws lines of a fixed length (e.g., 3% of panel size) inward from the specified sides.

### Interval Geoms
- `linerange`: Simple vertical line from `ymin` to `ymax`.
- `errorbar`: `linerange` + two horizontal segments at `ymin` and `ymax`.
- `pointrange`: `linerange` + circle at `y`.

## Proposed Plan (24-01-PLAN.md)
1. Add `dotplot`, `rug`, and interval geoms to `as_d3_ir.R` mapping.
2. Implement `inst/htmlwidgets/modules/geoms/dotplot.js`.
3. Implement `inst/htmlwidgets/modules/geoms/rug.js`.
4. Implement `inst/htmlwidgets/modules/geoms/interval.js`.
5. Register new geoms in `gg2d3.yaml`.
6. Add regression tests for all new geom types.

---
*Research completed: 2026-03-31*
