# Phase 18 Research: Nested Facet Support

## Objective
Support multiple variables in `facet_grid` and `facet_wrap` (nesting) and ensure facet labels respect theme justifications and rotations.

## Current State Analysis

### 1. Nested Labels (`FACE-01`)
- **Status:** Currently, `as_d3_ir.R` joins nested variable values with a comma (e.g., "4, 0") and passes them as a single string.
- **Limitation:** ggplot2 renders nested facets as distinct "strips" or "headers" stacked on top of each other (for columns) or side-by-side (for rows).
- **IR Limitation:** `facets_ir` only supports a flat `strips` or `row_strips`/`col_strips` array.

### 2. Layout Logic (`FACE-01`)
- **Limitation:** `inst/htmlwidgets/modules/layout.js` assumes a single `stripHeight` (or `stripWidth` for rows) and allocates space accordingly.
- **Requirement:** Layout must calculate the number of nesting levels and multiply the strip dimension by that count.

### 3. Theme Parity (`FACE-02`)
- **Status:** Basic styling (font size, color, background) is extracted.
- **Limitation:** Justification (`hjust`, `vjust`), margin, and rotation are not fully integrated into the rendering pipeline.
- **Requirement:** `as_d3_ir.R` should extract these from `strip.text.x`, `strip.text.y`, etc., and JS should apply them during SVG generation.

## Technical Proposals

### Hierarchical Strip IR
Instead of a flat array of labels, `as_d3_ir.R` should provide an array of levels for each side:
```r
col_strips = list(
  list(level = 1, labels = list(list(COL = 1, label = "Var1_Val1"), ...)),
  list(level = 2, labels = list(list(COL = 1, label = "Var2_Val1"), ...))
)
```

### Enhanced Layout Engine
Update `calculateLayout` to:
1. Count the number of nesting variables for rows and columns.
2. Multiply `stripHeight` by `numColVars` and `stripWidth` by `numRowVars`.
3. Position each strip at its specific level-offset.

### Theme-Aware Rendering
Update `gg2d3.js` to:
1. Handle multiple strips per panel/row/column.
2. Apply theme justifications (transform/translate/rotate) to the strip text.

## Proposed Plan (18-01-PLAN.md)
1. Add regression tests for nested `facet_grid` and `facet_wrap`.
2. Update `R/as_d3_ir.R` to extract multi-level strip metadata and detailed theme elements.
3. Update `layout.js` to allocate space for hierarchical headers.
4. Update `gg2d3.js` to render nested strips with full theme support.

---
*Research completed: 2026-03-31*
