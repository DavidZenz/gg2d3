---
phase: 09-advanced-faceting
plan: 01
subsystem: ir-extraction
tags: [faceting, facet-grid, ir, metadata-extraction]
dependencies:
  requires: [facet-wrap-ir]
  provides: [facet-grid-ir, free-scales-metadata]
  affects: [ir-validation, js-rendering]
tech-stack:
  added: []
  patterns: [2d-grid-detection, row-col-strip-extraction, scales-mode-detection]
key-files:
  created: []
  modified:
    - R/as_d3_ir.R
    - R/validate_ir.R
decisions:
  - id: row-col-separate-vars
    title: Row and column faceting variables stored separately
    rationale: "facet_grid(cyl ~ am) has distinct row vars and col vars, unlike facet_wrap which has single vars array"
    impact: "JavaScript rendering can position row strips (right) and col strips (top) independently"
  - id: scales-mode-from-free-params
    title: Derive scales mode from free$x and free$y boolean params
    rationale: "ggplot2 stores free scales as list(x=TRUE/FALSE, y=TRUE/FALSE), not as single 'fixed'/'free' string"
    impact: "Map boolean combinations to strings: fixed, free_x, free_y, free for IR clarity"
  - id: concatenated-multi-var-labels
    title: Multi-variable strip labels concatenated with ', ' separator
    rationale: "Phase 9 scope is basic facet_grid support; hierarchical/nested strip layout deferred to future phase"
    impact: "facet_grid(a + b ~ c) produces strip labels like '4, 0' not nested strips"
metrics:
  duration: 2
  completed: 2026-02-13T14:24:00Z
---

# Phase 09 Plan 01: facet_grid IR Extraction Summary

**One-liner:** Extract facet_grid metadata from ggplot_build() into 2D grid IR with separate row/col variables, row_strips/col_strips arrays, and free scale mode detection.

## What Was Built

Extended `as_d3_ir()` with facet_grid support alongside existing facet_wrap extraction. The implementation detects `FacetGrid` class, extracts row and column faceting variables separately, builds dedicated row_strips and col_strips arrays, determines scales mode from free scale params, and extracts per-panel scale metadata (ranges, breaks) for all panels in the rectangular grid.

Key additions:

1. **facet_grid detection**: `inherits(b$layout$facet, "FacetGrid")`
2. **Row/column variable separation**: `rows = names(params$rows)`, `cols = names(params$cols)`
3. **2D strip extraction**: `row_strips` (one per unique ROW), `col_strips` (one per unique COL)
4. **Scales mode detection**: Map `free$x` and `free$y` booleans to "fixed", "free_x", "free_y", "free"
5. **Multi-variable support**: Concatenate labels with ", " separator for `facet_grid(a + b ~ c)`
6. **Validation**: Extended `validate_ir()` to check facet_grid IR structure
7. **facet_wrap enhancement**: Added missing `scales` field to facet_wrap IR

Full backward compatibility maintained — facet_wrap and non-faceted plots unchanged.

## Implementation Details

### R/as_d3_ir.R Changes

**facet_grid branch (lines 768-870):**
- Added `is_facet_grid` detection alongside `is_facet_wrap`
- Extract row_vars from `b$layout$facet$params$rows`
- Extract col_vars from `b$layout$facet$params$cols`
- Determine scales mode from `b$layout$facet$params$free` (list with x/y booleans)
- Build row_strips: unique combinations of ROW + row variable values
- Build col_strips: unique combinations of COL + column variable values
- Reuse panel_params extraction pattern from facet_wrap (per-panel ranges/breaks)
- Apply coord_flip un-swap logic to panel_params (same as Phase 8)

**facet_wrap scales mode (lines 773-782):**
- Added scales mode detection to existing facet_wrap branch
- Was missing in Phase 8 implementation
- Uses same free$x/free$y → "fixed"/"free"/"free_x"/"free_y" mapping

**IR structure produced:**
```r
facets_ir <- list(
  type = "grid",
  rows = c("cyl"),           # Row faceting variables
  cols = c("am"),            # Column faceting variables
  scales = "fixed",          # Or "free", "free_x", "free_y"
  nrow = 3,
  ncol = 2,
  spacing = 7.3,             # pixels
  layout = [...],            # PANEL, ROW, COL, SCALE_X, SCALE_Y, plus var values
  row_strips = [             # One per unique ROW
    {ROW: 1, label: "4"},
    {ROW: 2, label: "6"},
    {ROW: 3, label: "8"}
  ],
  col_strips = [             # One per unique COL
    {COL: 1, label: "0"},
    {COL: 2, label: "1"}
  ]
)
```

### R/validate_ir.R Changes

**facet_grid validation (lines 121-137):**
- Check for non-empty layout (required)
- Warn if both rows and cols are null
- Warn if row_strips and col_strips both missing
- Warn if nrow/ncol missing
- Validate scales mode is one of: "fixed", "free", "free_x", "free_y"
- All checks use warnings (not errors) for non-critical issues

Validation pattern matches existing facet_wrap validation style.

## Deviations from Plan

None - plan executed exactly as written.

## Testing

**Unit verification (all tests passed):**

```r
# facet_grid basic structure
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
ir <- as_d3_ir(p)
# ✓ type == "grid"
# ✓ rows == ["cyl"], cols == ["am"]
# ✓ scales == "fixed"
# ✓ nrow == 3, ncol == 2
# ✓ 3 row_strips, 2 col_strips
# ✓ 6 panels with per-panel metadata

# Free scale modes
facet_grid(cyl ~ am, scales = "free")    # ✓ scales == "free"
facet_grid(cyl ~ am, scales = "free_x")  # ✓ scales == "free_x"
facet_grid(cyl ~ am, scales = "free_y")  # ✓ scales == "free_y"

# Multi-variable facets
facet_grid(cyl + vs ~ am + gear)
# ✓ rows == ["cyl", "vs"], cols == ["am", "gear"]
# ✓ Strip labels concatenated: "4, 0" format

# Backward compatibility
facet_wrap(~ cyl)  # ✓ type == "wrap", 3 strips
non-faceted plot   # ✓ type == "null", 1 panel

# Validation
validate_ir(ir)  # ✓ All facet types pass validation
```

## Key Insights

1. **ggplot2's facet_grid stores rows/cols separately** — `params$rows` and `params$cols` are distinct quosure lists, each with named variables. This differs from facet_wrap which has single `facets` quosure list.

2. **Free scale params are booleans, not strings** — `params$free` is `list(x = TRUE/FALSE, y = TRUE/FALSE)`. Must map to string for IR: both FALSE = "fixed", x only = "free_x", y only = "free_y", both = "free".

3. **Missing row×col combinations automatically handled** — ggplot2's `b$layout$layout` dataframe includes all row×col combinations in rectangular grid even if some have no data. JavaScript will filter data by PANEL (Phase 8 pattern) and render blank panels gracefully.

4. **Strip label extraction uses unique combinations** — For row strips: `unique(layout[, c("ROW", row_vars)])` gives one strip per unique ROW value. For col strips: same with COL. Multi-variable concatenation with `paste(..., collapse = ", ")`.

5. **panel_params structure identical to facet_wrap** — Same extraction pattern works: iterate over `panel_params`, extract x/y ranges and breaks, apply coord_flip un-swap if needed. For free scales, different panels have different ranges; for fixed, all panels have same ranges but structure supports both.

6. **facet_wrap was missing scales field** — Phase 8 implementation didn't capture scales mode. Added in this plan — facet_wrap supports free scales too (though Phase 8 only handled fixed).

## What's Next

**Plan 09-02: 2D Grid Layout Engine** — Extend `calculateLayout()` in JavaScript to compute positions for 2D grids with row strips (right) and column strips (top), handling free scale spacing requirements.

**Plan 09-03: Per-Panel Rendering with Free Scales** — Implement JavaScript rendering that creates per-panel scales using panel-specific ranges, renders axes on correct panels based on scales mode (free/free_x/free_y).

**Plan 09-04: Testing & Visual Verification** — Comprehensive test cases for all scales modes, multi-variable facets, missing combinations, coord_flip interaction.

## Files Modified

- `R/as_d3_ir.R` (+114 lines): facet_grid extraction, scales mode detection, facet_wrap scales enhancement
- `R/validate_ir.R` (+17 lines): facet_grid validation

## Commits

- `a6036eb`: feat(09-advanced-faceting): extract facet_grid metadata into IR
- `19143e5`: feat(09-advanced-faceting): add facet_grid validation to validate_ir

## Self-Check

Verifying files and commits exist:

```bash
# Files exist
[ -f "R/as_d3_ir.R" ] && echo "FOUND: R/as_d3_ir.R" || echo "MISSING: R/as_d3_ir.R"
[ -f "R/validate_ir.R" ] && echo "FOUND: R/validate_ir.R" || echo "MISSING: R/validate_ir.R"

# Commits exist
git log --oneline --all | grep -q "a6036eb" && echo "FOUND: a6036eb" || echo "MISSING: a6036eb"
git log --oneline --all | grep -q "19143e5" && echo "FOUND: 19143e5" || echo "MISSING: 19143e5"
```

Running self-check:

```
FOUND: R/as_d3_ir.R
FOUND: R/validate_ir.R
FOUND: a6036eb
FOUND: 19143e5
```

## Self-Check: PASSED
