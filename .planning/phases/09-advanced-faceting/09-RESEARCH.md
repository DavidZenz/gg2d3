# Phase 9: Advanced Faceting - Research

**Researched:** 2026-02-13
**Domain:** ggplot2 facet_grid, free scales, multi-panel layouts
**Confidence:** HIGH

## Summary

Phase 9 extends Phase 8's facet_wrap foundation to support facet_grid's 2D row×column layouts and free scales. The core difference: facet_grid creates rectangular grids with separate row and column variables, while free scales allow each panel (or row/column) to have independent axis ranges. Implementation requires: (1) extracting row/col facet variables separately, (2) handling SCALE_X/SCALE_Y indexing into panel_scales_x/y arrays for free scales, (3) extending layout engine for 2D strip positioning (column strips on top, row strips on right), (4) per-panel axis rendering for free scales, and (5) blank panel handling for missing row×column combinations.

**Key insight:** With free scales, `length(panel_scales_x)` varies by scale mode: `scales="free"` creates unique scales per panel, `scales="free_x"` creates one scale per column (shared across rows), `scales="free_y"` creates one scale per row (shared across columns). The `SCALE_X` and `SCALE_Y` columns in layout dataframe index into these arrays.

**Primary recommendation:** Implement in dependency order: (1) facet_grid layout with fixed scales, (2) free_x and free_y modes, (3) full free mode, (4) multi-variable strips, (5) missing combination handling. This allows incremental testing and reuses Phase 8's panel rendering infrastructure.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Overarching Principle:**
- Clone ggplot2 behavior exactly — every rendering decision defaults to matching ggplot2's output
- This applies to all gray areas: free scale axes, missing combinations, strip layout, nested faceting

**Free Scale Axes:**
- `scales = "free"`: each panel gets its own x and y axis range and tick labels (per ggplot2)
- `scales = "free_x"`: per-panel x ranges, shared y (per ggplot2)
- `scales = "free_y"`: per-panel y ranges, shared x (per ggplot2)
- Tick labels appear on every panel that needs them (leftmost column for y, bottom row for x with fixed; every panel for free axis)

**Missing Combinations:**
- facet_grid with missing row×column combos shows blank/empty panels in the grid (per ggplot2)
- Grid structure remains rectangular — no collapsing

**Strip Label Layout:**
- Column strips on top (ggplot2 default)
- Row strips on right (ggplot2 default)
- Multi-variable strips (e.g., `facet_grid(a + b ~ c)`) render as ggplot2 does

**Scope Boundaries:**
- `facet_grid(rows ~ cols)` with single or multiple variables per dimension
- Free/fixed/free_x/free_y scale modes
- Missing combination handling
- Strip placement matching ggplot2 defaults (top/right)

### Claude's Discretion

- Implementation order (which features to tackle in which plan)
- Whether to extract panel-specific scale data in R or compute in JS
- How to structure the layout engine extensions for 2D grids
- Performance tradeoffs for many-panel grids

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 3.5+ | facet_grid system | Built-in facet_grid(), provides layout dataframe with ROW/COL/SCALE_X/SCALE_Y |
| D3.js | v7 | Per-panel axis rendering | Already used, supports per-group scale creation and axis rendering |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grid (R) | Base | Unit conversion | Convert panel.spacing from pt to pixels (same as Phase 8) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| R-side scale extraction | JS-side domain calculation | R extraction is safer (matches ggplot2's expansion logic exactly), JS calculation risks domain mismatches |
| Shared axis rendering | Per-panel axes | Shared rendering fails with free scales, per-panel required |

**Installation:**
No additional packages required - uses existing ggplot2 and D3.js v7.

## Architecture Patterns

### Recommended IR Structure Extension (Free Scales)

Phase 8 IR has single `panels` array with per-panel ranges. For free scales, extend to include scale metadata:

```javascript
{
  facets: {
    type: "grid",           // NEW: "grid" type
    rows: ["cyl"],          // NEW: row facet variables
    cols: ["am"],           // NEW: column facet variables
    scales: "free",         // NEW: "fixed", "free_x", "free_y", "free"
    nrow: 3,
    ncol: 2,
    layout: [               // Same structure as facet_wrap
      {PANEL: 1, ROW: 1, COL: 1, cyl: "4", am: "0", SCALE_X: 1, SCALE_Y: 1},
      {PANEL: 2, ROW: 1, COL: 2, cyl: "4", am: "1", SCALE_X: 2, SCALE_Y: 1},
      {PANEL: 3, ROW: 2, COL: 1, cyl: "6", am: "0", SCALE_X: 1, SCALE_Y: 2},
      // ...
    ],
    row_strips: [           // NEW: row-side strip labels
      {ROW: 1, label: "4"},
      {ROW: 2, label: "6"},
      {ROW: 3, label: "8"}
    ],
    col_strips: [           // NEW: column-side strip labels
      {COL: 1, label: "0"},
      {COL: 2, label: "1"}
    ]
  },
  panels: [
    {
      PANEL: 1,
      x_range: [2.32, 5.57],   // Panel-specific for free scales
      y_range: [20.78, 34.52],
      x_breaks: [...],
      y_breaks: [...]
    },
    // ... per panel
  ]
}
```

**Key changes from Phase 8:**
1. `facets.type = "grid"` distinguishes from `"wrap"`
2. `rows` and `cols` arrays instead of single `vars`
3. `scales` field: "fixed", "free_x", "free_y", "free"
4. `row_strips` and `col_strips` arrays for 2D strip layout
5. Panel ranges already vary per SCALE_X/SCALE_Y indices (extracted in R)

### Pattern 1: facet_grid Layout Calculation (2D Grid with Row/Column Strips)

**What:** Extend Phase 8's grid layout to support row and column strips simultaneously

**When to use:** facet_grid plots with rows ~ cols formula

**Algorithm:**
```javascript
function calculateFacetGridLayout(availableBox, facets) {
  const { nrow, ncol, layout, spacing } = facets;
  const stripHeight = 15;  // Column strips (top)
  const stripWidth = 15;   // Row strips (right)

  // Reserve space for strips
  const panelAreaX = availableBox.x;
  const panelAreaY = availableBox.y + stripHeight;  // Column strips on top
  const panelAreaW = availableBox.w - stripWidth;   // Row strips on right
  const panelAreaH = availableBox.h - stripHeight;

  // Calculate panel dimensions
  const totalSpacingX = (ncol - 1) * spacing;
  const totalSpacingY = (nrow - 1) * spacing;
  const panelW = (panelAreaW - totalSpacingX) / ncol;
  const panelH = (panelAreaH - totalSpacingY) / nrow;

  // Generate panel positions
  const panels = layout.map(row => {
    const col = row.COL - 1;
    const rowIdx = row.ROW - 1;
    return {
      PANEL: row.PANEL,
      x: panelAreaX + col * (panelW + spacing),
      y: panelAreaY + rowIdx * (panelH + spacing),
      w: panelW,
      h: panelH,
      clipId: `panel-${row.PANEL}-clip`
    };
  });

  // Generate column strips (top of each column)
  const colStrips = facets.col_strips.map(strip => {
    const col = strip.COL - 1;
    return {
      COL: strip.COL,
      x: panelAreaX + col * (panelW + spacing),
      y: availableBox.y,
      w: panelW,
      h: stripHeight,
      label: strip.label,
      orientation: "top"
    };
  });

  // Generate row strips (right of each row)
  const rowStrips = facets.row_strips.map(strip => {
    const rowIdx = strip.ROW - 1;
    return {
      ROW: strip.ROW,
      x: panelAreaX + panelAreaW,
      y: panelAreaY + rowIdx * (panelH + spacing),
      w: stripWidth,
      h: panelH,
      label: strip.label,
      orientation: "right"
    };
  });

  return { panels, colStrips, rowStrips };
}
```

### Pattern 2: Per-Panel Scale Creation for Free Scales

**What:** Create unique D3 scale objects per panel using panel-specific ranges

**When to use:** facet_grid with `scales = "free"`, `"free_x"`, or `"free_y"`

**Example:**
```javascript
// In renderPanel() with free scales
const panelData = ir.panels.find(p => p.PANEL === panelNum);

// CRITICAL: For free scales, use panel-specific ranges directly
// For continuous scales only - categorical scales keep global domain
const xScaleDesc = Object.assign({}, ir.scales.x);
const yScaleDesc = Object.assign({}, ir.scales.y);

if (ir.facets.scales === "free" || ir.facets.scales === "free_x") {
  if (xScaleDesc.type === "continuous") {
    xScaleDesc.domain = panelData.x_range;  // Panel-specific domain
  }
}

if (ir.facets.scales === "free" || ir.facets.scales === "free_y") {
  if (yScaleDesc.type === "continuous") {
    yScaleDesc.domain = panelData.y_range;  // Panel-specific domain
  }
}

const xScale = createScale(xScaleDesc, [0, panelW]);
const yScale = createScale(yScaleDesc, [panelH, 0]);
```

### Pattern 3: Per-Panel Axis Rendering for Free Scales

**What:** Render axes on every panel that needs them based on free scale mode

**When to use:** facet_grid with free scales

**Logic:**
```javascript
const isFreeX = facets.scales === "free" || facets.scales === "free_x";
const isFreeY = facets.scales === "free" || facets.scales === "free_y";

layout.panels.forEach(panelBox => {
  const layoutEntry = facets.layout.find(l => l.PANEL === panelBox.PANEL);
  const panelData = ir.panels.find(p => p.PANEL === panelBox.PANEL);

  // Create per-panel scale
  const xScale = createPanelScale(ir.scales.x, panelData.x_range, panelBox.w);
  const yScale = createPanelScale(ir.scales.y, panelData.y_range, panelBox.h);

  // Render axes based on position and free scale mode
  const isBottomRow = layoutEntry.ROW === maxRow;
  const isLeftCol = layoutEntry.COL === 1;

  if (isBottomRow || isFreeX) {
    // Render x-axis
    const xAxis = d3.axisBottom(xScale)
      .tickValues(panelData.x_breaks);
    svg.append("g")
      .attr("transform", `translate(${panelBox.x}, ${panelBox.y + panelBox.h})`)
      .call(xAxis);
  }

  if (isLeftCol || isFreeY) {
    // Render y-axis
    const yAxis = d3.axisLeft(yScale)
      .tickValues(panelData.y_breaks);
    svg.append("g")
      .attr("transform", `translate(${panelBox.x}, ${panelBox.y})`)
      .call(yAxis);
  }
});
```

### Pattern 4: Row Strip Rendering with Rotation

**What:** Render row strip labels on the right side of panels with vertical text

**When to use:** facet_grid with row faceting variables

**Example:**
```javascript
// Row strips (right side, vertical text)
layout.rowStrips.forEach(strip => {
  const stripGroup = svg.append("g")
    .attr("class", "strip-right");

  // Background rect
  stripGroup.append("rect")
    .attr("x", strip.x)
    .attr("y", strip.y)
    .attr("width", strip.w)
    .attr("height", strip.h)
    .attr("fill", stripTheme.bgFill);

  // Text label (rotated -90 degrees)
  stripGroup.append("text")
    .attr("x", strip.x + strip.w / 2)
    .attr("y", strip.y + strip.h / 2)
    .attr("text-anchor", "middle")
    .attr("dominant-baseline", "central")
    .attr("transform", `rotate(-90, ${strip.x + strip.w / 2}, ${strip.y + strip.h / 2})`)
    .style("font-size", stripTheme.fontSize + "px")
    .style("fill", stripTheme.fontColour)
    .text(strip.label);
});
```

### Anti-Patterns to Avoid

- **Don't share scale objects across panels with free scales:** Each panel must have its own D3 scale instance when scales are free
- **Don't render axes once for the entire grid with free scales:** Free scales require per-panel axes with different tick positions
- **Don't override categorical scale domains with panel ranges:** Categorical scales must keep their global label-based domain (Phase 8 learning)
- **Don't collapse missing panels:** ggplot2 renders blank spaces, grid stays rectangular

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Free scale domain calculation | Custom per-panel min/max | Extract from `b$layout$panel_params[[i]]$x$range` | ggplot2 handles expansion, padding, limits correctly |
| SCALE_X/SCALE_Y indexing logic | Manual panel→scale mapping | Use `layout$SCALE_X` and `layout$SCALE_Y` directly | ggplot2 already computed which panels share scales |
| Strip label formatting | String concatenation for multi-var | Use `b$layout$facet$params$labeller` | ggplot2's labeller handles multi-variable formatting, custom functions |
| Blank panel detection | Check data presence | Render all panels in `layout`, filter data by PANEL | ggplot2 includes all row×col combos in layout regardless of data |

**Key insight:** With free scales, the relationship between panels and scales is complex. Fixed scales have `length(panel_scales_x) == 1`, free_x has `length(panel_scales_x) == ncol`, free_y has `length(panel_scales_y) == nrow`, and free has `length(panel_scales_x) == ncol` and `length(panel_scales_y) == nrow`. The `SCALE_X`/`SCALE_Y` indices in the layout dataframe handle this automatically. Don't recompute what ggplot2 provides.

## Common Pitfalls

### Pitfall 1: Free Scale Mode Confusion

**What goes wrong:** Rendering axes on wrong panels (e.g., every panel gets axes when only bottom/left should)

**Why it happens:** Mixing fixed and free scale axis rendering logic

**How to avoid:**
- Check `facets.scales` value: "fixed", "free_x", "free_y", "free"
- For fixed scales: axes on outer edges only (bottom row, left column)
- For free_x: x-axis on every panel, y-axis on left column
- For free_y: y-axis on every panel, x-axis on bottom row
- For free: both axes on every panel

**Warning signs:** Duplicate axes where they shouldn't be, missing axes on inner panels with free scales

### Pitfall 2: SCALE_X/SCALE_Y Index Misalignment

**What goes wrong:** Using wrong scale range for a panel, causing data to render outside panel bounds or with wrong axis ticks

**Why it happens:** Manually computing panel→scale mapping instead of using ggplot2's SCALE_X/SCALE_Y

**How to avoid:**
- Always use `layout$SCALE_X` and `layout$SCALE_Y` from ggplot2's layout dataframe
- For free scales: `panel_params[[panelNum]]` contains the correct per-panel ranges
- Don't assume SCALE_X correlates with COL for free_y mode (it doesn't - free_y has shared x scales)

**Warning signs:** Bars floating above panel, axes showing wrong ranges, data clipped unexpectedly

### Pitfall 3: Row Strip Width Calculation

**What goes wrong:** Row strips too narrow or too wide, overlapping axis labels or extending into margins

**Why it happens:** Not accounting for rotated text dimensions, or hardcoding strip width

**How to avoid:**
- Estimate rotated text height as strip width: `estimateTextHeight(stripTextSize)`
- Add margin: `stripWidth = textHeight + margin * 2`
- Reserve space in layout calculation before slicing panel area
- Default: ~15-20px for standard strip text size (8.8pt)

**Warning signs:** Row strip text clipped, strip overlapping right axis labels

### Pitfall 4: Missing Combination Blank Panels

**What goes wrong:** Missing data panels cause layout to collapse or throw errors

**Why it happens:** Assuming all panels have data, filtering panels by data presence

**How to avoid:**
- Always render all panels from `facets.layout` regardless of data
- Filter layer data by PANEL: `layer.data.filter(d => d.PANEL === panelNum)`
- Empty filter result is valid - renders blank panel with axes/strips
- ggplot2 creates panel_params for all row×col combinations

**Warning signs:** Fewer panels than expected, layout shifts for missing combos

### Pitfall 5: Multi-Variable Strip Label Concatenation

**What goes wrong:** Strip labels missing variables or formatted incorrectly (e.g., "4, 0" instead of "cyl: 4, am: 0")

**Why it happens:** Manual string concatenation without respecting labeller settings

**How to avoid:**
- Extract strip labels from ggplot2 post-build (ggplot2 already applied labeller)
- For column strips: one label per column combining all row variables at that position
- For row strips: one label per row combining all column variables
- Preserve ggplot2's label formatting exactly

**Warning signs:** Strip labels don't match ggplot2 output, missing variable names

### Pitfall 6: Strip Positioning with Multi-Variable Facets

**What goes wrong:** Single strip row/column when multiple variables require hierarchical strips

**Why it happens:** Assuming one strip per panel instead of hierarchical strip structure

**How to avoid:**
- Phase 9 scope: single strip per row/column (matches ggplot2 default behavior)
- Multi-variable facets concatenate labels into single strip per row/column
- Advanced strip layouts (nested strips) are out of scope for Phase 9
- Document limitation for future phases

**Warning signs:** User expects nested strips like `cyl=4 | am=0`, gets single strip `4, 0`

## Code Examples

Verified patterns from research:

### Extracting facet_grid Metadata (R)

```r
# Source: Empirical testing with ggplot_build()
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_grid(cyl ~ am, scales = "free")

b <- ggplot_build(p)

# Layout dataframe includes SCALE_X/SCALE_Y indices
layout_df <- b$layout$layout
#   PANEL ROW COL cyl am SCALE_X SCALE_Y
# 1     1   1   1   4  0       1       1
# 2     2   1   2   4  1       2       1
# 3     3   2   1   6  0       1       2
# ...

# Facet params distinguish rows and cols
rows_vars <- names(b$layout$facet$params$rows)  # "cyl"
cols_vars <- names(b$layout$facet$params$cols)  # "am"
scales_mode <- b$layout$facet$params$free$x      # "free" / "fixed"

# Panel-specific ranges for free scales
panel_1 <- b$layout$panel_params[[1]]
x_range_panel_1 <- panel_1$x$continuous_range  # [2.32, 5.57]
y_range_panel_1 <- panel_1$y$continuous_range  # [20.78, 34.52]

# Scale array lengths vary by mode
n_x_scales <- length(b$layout$panel_scales_x)  # 2 for free/free_x, 1 for free_y/fixed
n_y_scales <- length(b$layout$panel_scales_y)  # 3 for free/free_y, 1 for free_x/fixed
```

### D3 Per-Panel Scale and Axis (JavaScript)

```javascript
// Source: Adapted from D3 small multiples pattern
// https://www.fabiofranchino.com/blog/non-constant-axis-in-small-multiple-with-d3/

// Determine free scale mode
const isFreeX = facets.scales === "free" || facets.scales === "free_x";
const isFreeY = facets.scales === "free" || facets.scales === "free_y";

layout.panels.forEach(panelBox => {
  const panelNum = panelBox.PANEL;
  const panelData = ir.panels.find(p => p.PANEL === panelNum);

  // Create per-panel scales using panel-specific domains
  const xDomain = isFreeX && ir.scales.x.type === "continuous"
    ? panelData.x_range
    : ir.scales.x.domain;
  const yDomain = isFreeY && ir.scales.y.type === "continuous"
    ? panelData.y_range
    : ir.scales.y.domain;

  const xScale = d3.scaleLinear()
    .domain(xDomain)
    .range([0, panelBox.w]);

  const yScale = d3.scaleLinear()
    .domain(yDomain)
    .range([panelBox.h, 0]);

  // Render axis if needed for this panel's position
  const layoutEntry = facets.layout.find(l => l.PANEL === panelNum);
  const isBottomRow = layoutEntry.ROW === maxRow;
  const isLeftCol = layoutEntry.COL === 1;

  if (isBottomRow || isFreeX) {
    const xAxis = d3.axisBottom(xScale)
      .tickValues(panelData.x_breaks);
    svg.append("g")
      .attr("transform", `translate(${panelBox.x}, ${panelBox.y + panelBox.h})`)
      .call(xAxis);
  }

  if (isLeftCol || isFreeY) {
    const yAxis = d3.axisLeft(yScale)
      .tickValues(panelData.y_breaks);
    svg.append("g")
      .attr("transform", `translate(${panelBox.x}, ${panelBox.y})`)
      .call(yAxis);
  }
});
```

### Extracting Row and Column Strip Labels (R)

```r
# Source: Empirical testing with facet_grid
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_grid(cyl + vs ~ am + gear)

b <- ggplot_build(p)

# Extract unique row combinations (for row strips)
row_vars <- names(b$layout$facet$params$rows)  # c("cyl", "vs")
row_combos <- unique(b$layout$layout[, c("ROW", row_vars)])
row_strips <- lapply(seq_len(nrow(row_combos)), function(i) {
  label_parts <- vapply(row_vars, function(v) {
    as.character(row_combos[[v]][i])
  }, character(1))
  list(
    ROW = as.integer(row_combos$ROW[i]),
    label = paste(label_parts, collapse = ", ")
  )
})

# Extract unique column combinations (for column strips)
col_vars <- names(b$layout$facet$params$cols)  # c("am", "gear")
col_combos <- unique(b$layout$layout[, c("COL", col_vars)])
col_strips <- lapply(seq_len(nrow(col_combos)), function(i) {
  label_parts <- vapply(col_vars, function(v) {
    as.character(col_combos[[v]][i])
  }, character(1))
  list(
    COL = as.integer(col_combos$COL[i]),
    label = paste(label_parts, collapse = ", ")
  )
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single facet type | facet_wrap + facet_grid | ggplot2 2.0+ | Grid supports 2D layouts with row/col variables |
| Shared scales only | Free scales per panel | ggplot2 2.0+ | Allows better visualization of heterogeneous distributions |
| Strip labels on top only | Position control (top/bottom/left/right) | ggplot2 2.2+ | Row strips default to right for grid |
| Manual scale array indexing | SCALE_X/SCALE_Y columns | ggplot2 2.0+ | Automatic panel→scale mapping from ggplot_build |

**Deprecated/outdated:**
- **`facet_grid(. ~ x)` single-row syntax:** Still works but `facet_wrap(~ x, nrow=1)` is more explicit
- **`facet_grid(margins = TRUE)`:** Creates margin panels (not in Phase 9 scope)

## Open Questions

1. **Multi-variable strip layout (nested vs concatenated)**
   - What we know: ggplot2 default concatenates labels with comma separator
   - What's unclear: Whether nested strip layout (hierarchical strips) is required for basic facet_grid
   - Recommendation: Phase 9 uses concatenated labels (default), defer nested strips to future phase

2. **Strip text wrapping for long labels**
   - What we know: Same as Phase 8 - ggplot2 has `label_wrap_gen()` but unclear if applied pre-build
   - What's unclear: Maximum label length before wrapping becomes critical
   - Recommendation: Defer wrapping to future phase, document limitation

3. **Axis positioning with free scales and coord_flip**
   - What we know: coord_flip swaps axes, free scales create per-panel axes
   - What's unclear: How these interact (does flip affect which axes appear where?)
   - Recommendation: Test combination, likely defer coord_flip + free scales to future phase if complex

4. **Performance with large grids (e.g., 10×10 = 100 panels)**
   - What we know: Each panel renders independently with own scale/axis objects
   - What's unclear: D3 performance threshold for many panels
   - Recommendation: Implement naively first, optimize if needed based on user reports

## Sources

### Primary (HIGH confidence)
- Empirical testing with `ggplot_build()` on facet_grid plots (mtcars dataset)
- [ggplot2 facet_grid reference](https://ggplot2.tidyverse.org/reference/facet_grid.html)
- Phase 8 facet_wrap research and implementation (`.planning/phases/08-basic-faceting/08-RESEARCH.md`)
- Existing gg2d3 codebase: `R/as_d3_ir.R`, `inst/htmlwidgets/modules/layout.js`

### Secondary (MEDIUM confidence)
- [16 Faceting – ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/facet.html) - User-facing faceting concepts
- [Non-constant axis in small multiple charts with D3.js](https://www.fabiofranchino.com/blog/non-constant-axis-in-small-multiple-with-d3/) - D3 per-panel axis pattern
- [Interactive and Responsive Small Multiples with D3](https://blog.scottlogic.com/2017/04/05/interactive-responsive-small-multiples.html) - D3 grid layout pattern

### Tertiary (LOW confidence)
- [d3-scale documentation](https://d3js.org/d3-scale) - General scale API (no facet-specific guidance)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ggplot2 facet_grid and D3 v7 established, empirically verified with multiple scale modes
- Architecture: HIGH - Tested facet_grid structure with free scales, confirmed SCALE_X/SCALE_Y indexing, validated Phase 8 infrastructure reusability
- Pitfalls: MEDIUM-HIGH - Free scale axis positioning inferred from ggplot2 behavior and D3 patterns, scale indexing verified empirically

**Research date:** 2026-02-13
**Valid until:** 2026-03-13 (30 days - stable ggplot2 API)
