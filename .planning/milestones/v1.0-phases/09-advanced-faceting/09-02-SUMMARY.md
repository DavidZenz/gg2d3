---
phase: 09-advanced-faceting
plan: 02
subsystem: layout-rendering
tags: [faceting, facet-grid, layout, strips, 2d-grid]
dependencies:
  requires: [facet-grid-ir, facet-wrap-layout]
  provides: [facet-grid-layout, facet-grid-rendering, 2d-strip-positioning]
  affects: [layout-engine, strip-rendering, panel-positioning]
tech-stack:
  added: []
  patterns: [2d-grid-layout, rotated-text-strips, strip-positioning]
key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/layout.js
    - inst/htmlwidgets/gg2d3.js
decisions:
  - id: separate-wrap-grid-calculations
    title: Separate layout calculations for facet_wrap and facet_grid
    rationale: "facet_grid has different strip positioning (top/right) vs facet_wrap (top only)"
    impact: "Clear code separation, easier to maintain distinct layout patterns"
  - id: strip-width-equals-height
    title: Row strip width equals column strip height for rotated text
    rationale: "Rotated text's visual width equals text height; same font size for both"
    impact: "Consistent visual weight for row and column strips"
  - id: panel-area-subtraction
    title: Subtract strip dimensions from available area before panel calculation
    rationale: "Reserve space for strips first, then divide remaining area by panel count"
    impact: "Correct panel sizing that accounts for strip space"
metrics:
  duration: 2
  completed: 2026-02-13T14:31:00Z
---

# Phase 09 Plan 02: 2D Grid Layout Engine Summary

**One-liner:** Extended layout engine and rendering to support facet_grid's 2D panel grid with column strips (top, horizontal) and row strips (right, rotated -90°).

## What Was Built

Implemented facet_grid layout calculation and rendering in the JavaScript layer, producing a 2D grid of panels with separate column strips (positioned above columns) and row strips (positioned to the right of rows with rotated text). The implementation maintains full backward compatibility with facet_wrap and non-faceted plots while adding the new grid layout pattern.

Key additions:

1. **Layout engine (layout.js)**: Extended `calculateLayout()` to detect `facets.type === "grid"` and compute 2D grid layout with strip space allocation
2. **Strip positioning**: Column strips at top (horizontal text), row strips on right (rotated -90° text)
3. **Panel grid calculation**: Panels positioned in rows × columns after reserving strip space
4. **Rendering (gg2d3.js)**: Added colStrips and rowStrips rendering with proper text rotation
5. **Backward compatibility**: facet_wrap and non-faceted rendering unchanged

## Implementation Details

### Layout Engine Changes (inst/htmlwidgets/modules/layout.js)

**Detection (line 296-298):**
```javascript
const isFaceted = facets && (facets.type === "wrap" || facets.type === "grid") &&
                  facets.layout && facets.layout.length > 1;
const isFacetGrid = facets && facets.type === "grid";
```

**facet_grid layout calculation (lines 505-576):**
- Calculate `stripWidth = stripHeight` (rotated text width equals text height)
- Reserve space: `panelAreaW = availW - stripWidth` (right side for row strips)
- Reserve space: `panelAreaH = availH - stripHeight` (top for column strips)
- Calculate panel dimensions: `panelW = (panelAreaW - totalSpacingX) / ncol`
- Position panels: `x = availX + col * (panelW + spacing)`, `y = availY + stripHeight + row * (panelH + spacing)`
- Build colStrips array: positioned at `y = availY` for each column
- Build rowStrips array: positioned at `x = availX + panelAreaW` for each row
- Update panel bounding box to span full grid (for axis label centering)

**Return object additions (lines 566-567):**
```javascript
colStrips: colStripsArr, // [{COL, x, y, w, h, label, orientation}, ...] or null
rowStrips: rowStripsArr, // [{ROW, x, y, w, h, label, orientation}, ...] or null
```

### Rendering Changes (inst/htmlwidgets/gg2d3.js)

**layoutConfig update (lines 187-195):**
- Pass `facets` for both `type === "wrap"` and `type === "grid"`
- Include `row_strips` and `col_strips` arrays
- Include `scales` mode

**isFacetGrid detection (line 200):**
```javascript
const isFacetGrid = ir.facets && ir.facets.type === "grid";
```

**Strip rendering (lines 257-337):**

1. **facet_wrap strips** (guarded with `!isFacetGrid`): unchanged, one strip per panel above each panel
2. **facet_grid column strips** (lines 289-308): horizontal text, centered in strip box
3. **facet_grid row strips** (lines 310-337): rotated -90° text using SVG transform

Column strip rendering pattern:
```javascript
stripGroup.append("text")
  .attr("x", strip.x + strip.w / 2)
  .attr("y", strip.y + strip.h / 2)
  .attr("text-anchor", "middle")
  .attr("dominant-baseline", "central")
  .text(strip.label);
```

Row strip rendering pattern (rotated):
```javascript
var cx = strip.x + strip.w / 2;
var cy = strip.y + strip.h / 2;
stripGroup.append("text")
  .attr("x", cx).attr("y", cy)
  .attr("text-anchor", "middle")
  .attr("dominant-baseline", "central")
  .attr("transform", "rotate(-90," + cx + "," + cy + ")")
  .text(strip.label);
```

**Axis rendering**: No changes needed — existing faceted axis rendering (lines 354-391) already works for both wrap and grid since it uses `ir.facets.layout` to find bottom-row panels (`ROW === maxRow`) and left-column panels (`COL === 1`).

## Deviations from Plan

None — plan executed exactly as written.

## Testing

**Unit verification (all tests passed):**

```r
# Basic facet_grid (3x2 grid: cyl ~ am)
p1 <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am)
gg2d3(p1)
# ✓ 3 rows × 2 columns
# ✓ Column strips "0", "1" at top
# ✓ Row strips "4", "6", "8" on right (rotated)
# ✓ Axes on bottom row and left column

# facet_grid with color aesthetic
p2 <- ggplot(mtcars, aes(wt, mpg, color = factor(gear))) +
  geom_point() + facet_grid(cyl ~ am)
gg2d3(p2)
# ✓ Colored points rendered correctly per panel

# Backward compatibility: facet_wrap
p3 <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~ cyl)
gg2d3(p3)
# ✓ Unchanged from Phase 8

# Backward compatibility: non-faceted
p4 <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
gg2d3(p4)
# ✓ Single panel, no strips
```

**IR structure verification:**
```r
ir <- as_d3_ir(ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(cyl ~ am))
# ✓ type: "grid"
# ✓ nrow: 3, ncol: 2
# ✓ scales: "fixed"
# ✓ 3 row_strips: ROW 1/2/3 with labels "4"/"6"/"8"
# ✓ 2 col_strips: COL 1/2 with labels "0"/"1"
# ✓ 6 panels with per-panel metadata
```

**Visual verification (HTML widget output):**
- Column strips appear above panels with horizontal text
- Row strips appear to right of panels with rotated text (-90°)
- Panel grid correctly positioned with spacing
- X-axes render on bottom row panels only
- Y-axes render on left column panels only
- Data correctly partitioned by PANEL into each panel

## Key Insights

1. **Strip width for rotated text equals height** — For row strips with -90° rotation, the visual "width" consumed by rotated text equals the text height (not the text width). Setting `stripWidth = stripHeight` produces visually balanced strips.

2. **Space allocation order matters** — Must reserve strip space BEFORE calculating panel dimensions. Pattern: `panelAreaW = availW - stripWidth`, then `panelW = (panelAreaW - spacing) / ncol`. Reversing this order produces incorrect panel sizes.

3. **SVG rotation uses transform attribute** — Rotating text requires transform on text element, not on parent group: `attr("transform", "rotate(-90," + cx + "," + cy + ")")`. Rotation point must be text center for proper centering.

4. **facet_wrap and facet_grid share panel structure** — Both produce `panels` array with same structure: `[{PANEL, x, y, w, h, clipId}, ...]`. Only strip positioning differs. Multi-panel rendering loop works identically for both.

5. **Axis rendering generalizes across facet types** — Existing axis rendering code (from Phase 8) works for facet_grid without changes because it uses `ir.facets.layout` to find bottom-row and left-column panels via `ROW` and `COL` values. This design choice from Phase 8 paid off.

6. **Guard conditions prevent interference** — Adding `!isFacetGrid` guard to facet_wrap strip rendering ensures strip arrays don't conflict. Pattern: facet_wrap uses `strips`, facet_grid uses `colStrips`/`rowStrips`.

## What's Next

**Plan 09-03: Per-Panel Rendering with Free Scales** — Implement free scale support where each panel can have independent x/y scale domains. Current implementation assumes fixed scales (all panels share same scale).

**Plan 09-04: Testing & Visual Verification** — Comprehensive test cases for all scales modes (fixed/free/free_x/free_y), multi-variable facets, coord_flip interaction, edge cases.

## Files Modified

- `inst/htmlwidgets/modules/layout.js` (+103 lines): facet_grid layout calculation, colStrips/rowStrips positioning
- `inst/htmlwidgets/gg2d3.js` (+62 lines): facet_grid rendering, column/row strip rendering

## Commits

- `ef02e89`: feat(09-02): extend calculateLayout for facet_grid 2D layout
- `3c2e1c5`: feat(09-02): render facet_grid with col/row strips and axes

## Self-Check

Verifying files and commits exist:

```
FOUND: inst/htmlwidgets/modules/layout.js
FOUND: inst/htmlwidgets/gg2d3.js
FOUND: ef02e89
FOUND: 3c2e1c5
```

## Self-Check: PASSED
