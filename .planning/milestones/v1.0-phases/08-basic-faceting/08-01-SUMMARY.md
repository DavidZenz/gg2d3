---
phase: 08-basic-faceting
plan: 01
subsystem: ir-extraction
tags: [faceting, ir, metadata-extraction]
dependencies:
  requires: []
  provides: [facet-ir-structure, panel-metadata]
  affects: [ir-validation, js-rendering]
tech-stack:
  added: []
  patterns: [facet-detection, per-panel-metadata]
key-files:
  created: []
  modified:
    - R/as_d3_ir.R
    - R/validate_ir.R
decisions: []
metrics:
  duration: 4
  completed: 2026-02-13T08:31:00Z
---

# Phase 08 Plan 01: facet_wrap IR Extraction Summary

**One-liner:** Extract facet_wrap metadata from ggplot_build() into multi-panel IR with per-panel scales, strip labels, and PANEL-keyed layer data.

## What Was Built

Added facet extraction logic to `as_d3_ir()` that detects `facet_wrap()` plots and builds a comprehensive facets IR structure containing:

1. **Facet metadata**: type, vars, nrow/ncol, panel.spacing
2. **Panel layout**: PANEL, ROW, COL grid mapping with faceting variable values
3. **Strip labels**: Per-panel labels constructed from faceting variables
4. **Per-panel scales**: x/y ranges and breaks for each panel (extracted from panel_params)
5. **Validation**: New IR validation checks for facets and panels arrays

The implementation maintains full backward compatibility — non-faceted plots produce `facets.type="null"` with a single panel, preserving all existing behavior.

## Implementation Details

### R/as_d3_ir.R Changes

**Facet Detection & Extraction (lines 745-873):**
- Detect `facet_wrap` via `inherits(b$layout$facet, "FacetWrap")`
- Extract layout dataframe from `b$layout$layout` (PANEL, ROW, COL, faceting vars)
- Build strip labels by concatenating faceting variable values per panel
- Extract per-panel scale metadata from `b$layout$panel_params` (ranges, breaks)
- Apply coord_flip un-swap logic to panel_params (reusing existing pattern)
- Extract `panel.spacing` from theme via `grid::convertUnit()` to pixels
- Wrap all extraction in `tryCatch` with fallback to non-faceted IR on error

**Strip Theme Extraction (lines 745-757):**
- Added `strip.text` and `strip.background` theme elements
- Integrated into `theme_ir$strip` for JavaScript rendering

**PANEL Integer Coercion (lines 218-226):**
- Modified inner `to_rows()` function to explicitly coerce PANEL column to integer
- Prevents factor-to-character conversion that would break panel filtering

**IR Structure Updates:**
- `facets`: Replaces hardcoded `{type: "grid", rows: 1, cols: 1}` with dynamic structure
- `panels`: New array field with per-panel metadata (PANEL, x_range, y_range, x_breaks, y_breaks)

### R/validate_ir.R Changes

**Facet Validation (lines 102-141):**
- Check `facets.type` field exists and has allowed value (null, wrap, grid)
- For `type="wrap"`: validate layout presence, warn if strips/nrow/ncol missing
- Validate `panels` array: check PANEL identifier, x_range/y_range structure
- Soft validation: warnings for non-critical issues, errors only for missing required fields
- Backward compatible: IR without facets field passes validation unchanged

## Deviations from Plan

None - plan executed exactly as written.

## Testing

**Unit verification:**
```r
# facet_wrap plot produces correct IR structure
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl, nrow = 2)
ir <- as_d3_ir(p)
# ✓ facets.type == "wrap"
# ✓ facets.nrow == 2, ncol == 2
# ✓ 3 layouts, 3 strips, 3 panels
# ✓ PANEL column is integer in layer data

# non-faceted plot maintains backward compatibility
p2 <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
ir2 <- as_d3_ir(p2)
# ✓ facets.type == "null"
# ✓ single panel with same structure
```

**IR validation passes for both faceted and non-faceted plots.**

## Key Insights

1. **ggplot2's `b$layout$layout` is the single source of truth for panel grid mapping** — contains PANEL, ROW, COL, SCALE_X, SCALE_Y plus all faceting variable values as character columns.

2. **panel_params is a list indexed by PANEL** — each entry has per-panel scale ranges/breaks. For fixed scales (Phase 8 scope), all panels share the same ranges, but the structure supports future free scales.

3. **coord_flip un-swap pattern applies to panel_params** — Same issue as single-panel case (plan 03-01): `ggplot_build()` swaps x↔y in panel_params but not in panel_scales or data. Applied existing un-swap logic to all panel_params entries.

4. **PANEL column must be integer for JSON serialization** — Factors would convert to character; explicit integer coercion ensures correct type for JavaScript panel filtering.

5. **Wrap in tryCatch for robustness** — Facet extraction touches multiple ggplot2 internals. Fallback to non-faceted IR prevents breaking existing non-faceted plots on any error.

## What's Next

**Plan 08-02: Multi-Panel Grid Layout** — Extend `calculateLayout()` to compute positions for multiple panels in a grid (panel boxes, strip positions, spacing application).

**Plan 08-03: Per-Panel Rendering** — Implement JavaScript rendering loops that filter data by PANEL and render geoms in clipped panel groups.

**Plan 08-04: Testing & Visual Verification** — Comprehensive test cases for single/multi-variable facets, different nrow/ncol values, theme styling.

## Files Modified

- `R/as_d3_ir.R` (+131 lines): Facet extraction, strip theme, PANEL integer coercion
- `R/validate_ir.R` (+37 lines): Facet and panels validation

## Commits

- `da3ad8e`: feat(08-basic-faceting): extract facet_wrap metadata and build facet IR structure
- `47d4f94`: feat(08-basic-faceting): add facet IR validation to validate_ir()

## Self-Check

All files and commits verified:

```bash
✓ R/as_d3_ir.R exists and contains facet extraction logic
✓ R/validate_ir.R exists and contains facet validation
✓ Commit da3ad8e exists in git log
✓ Commit 47d4f94 exists in git log
```

## Self-Check: PASSED
