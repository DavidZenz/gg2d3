# Phase 20 Research: Deep Theme Inheritance

## Objective
Implement full theme inheritance logic and support for detailed element styling (margins, text alignment, legend box).

## Current State Analysis

### 1. Inheritance Logic (`THEME-01`)
- **Status:** `as_d3_ir.R` uses `ggplot2:::calc_element`, which already resolves inheritance on the R side.
- **Limitation:** The current `theme_ir` extraction is manual and only covers a subset of elements. If a user defines `theme_minimal()`, many elements might be missed if not explicitly listed in the extraction loop.
- **Limitation:** `DEFAULT_THEME` in `theme.js` provides a baseline, but the merge logic is simple.

### 2. Element Blank (`THEME-01`)
- **Status:** `element_blank` is partially supported (returns `type: "blank"`).
- **Requirement:** Ensure all rendering modules (axis, grid, legend, strip) check for `type === "blank"` and skip rendering.

### 3. Text Styling Parity (`THEME-02`)
- **Status:** `hjust`, `vjust`, `angle` are extracted but not consistently applied.
- **Requirement:** `margin` (from `element_text`) needs to be extracted and used by the layout engine.

### 4. Legend Styling (`THEME-03`)
- **Status:** `legend.background` and `legend.key` are mostly ignored.
- **Requirement:** Extract `legend.background` (rect), `legend.margin`, and `legend.spacing`.

## Technical Proposals

### Exhaustive Theme Extraction
Instead of hardcoding every sub-element, we can use a more systematic approach in `as_d3_ir.R` to ensure all standard ggplot2 theme elements are captured if they are non-default or if they inherit from a non-default parent.

### JS `getInherited` Helper
In `theme.js`, implement a helper that follows the standard ggplot2 inheritance tree for D3-side lookups:
- `axis.text.x` -> `axis.text` -> `text`
- `axis.line.y` -> `axis.line` -> `line`
- `strip.text.x` -> `strip.text` -> `text`

### Layout Engine Updates
Update `calculateLayout` to:
1. Use `margin` from `text` elements to add spacing around titles and labels.
2. Use `legend.margin` and `legend.spacing` for precise legend placement.

## Proposed Plan (20-01-PLAN.md)
1. Expand `extract_theme_element` to handle `unit` and `margin` types more robustly.
2. Comprehensive update to `theme_ir` extraction in `R/as_d3_ir.R`.
3. Refactor `theme.js` to support deep hierarchical lookups and `element_blank`.
4. Update `gg2d3.js` and `layout.js` to respect the expanded theme metadata.
5. Add regression tests for `element_blank` and custom theme inheritance.

---
*Research completed: 2026-03-31*
