# Phase 8: Basic Faceting - Research

**Researched:** 2026-02-13
**Domain:** ggplot2 facet_wrap, multi-panel layout, strip labels
**Confidence:** HIGH

## Summary

Faceting in ggplot2 creates small multiples by splitting data into panels based on faceting variables. The `facet_wrap()` function wraps a 1D sequence of panels into a 2D grid. Implementation requires: (1) extracting facet layout metadata from `ggplot_build()`, (2) creating multi-panel IR structure with per-panel data and scales, (3) extending the layout engine for grid positioning, (4) rendering strip labels with theme styling, and (5) implementing per-panel data filtering and rendering loops.

**Key insight:** ggplot2's `b$layout$layout` dataframe provides complete panel grid mapping (ROW, COL, PANEL, faceting variables), and `b$layout$panel_params` is a list with per-panel scales. For fixed scales (Phase 8 scope), all panels share one scale object but have independent rendering positions.

**Primary recommendation:** Start with fixed scales only (scales = "fixed") where `panel_scales_x` and `panel_scales_y` contain single scale objects shared across panels. This simplifies IR structure and rendering loop while establishing the multi-panel architecture.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 3.5+ | Faceting system | Built-in facet_wrap(), provides layout dataframe and panel_params |
| D3.js | v7 | Multi-panel rendering | Already used, supports SVG groups for panel isolation |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grid (R) | Base | Unit conversion | Convert panel.spacing from pt to pixels |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| D3 nested selections | Multiple SVGs | Multiple SVGs easier for responsiveness but harder for shared axes/legends |
| CSS Grid layout | SVG transforms | CSS Grid simpler but loses SVG coordinate precision for panel positioning |

**Installation:**
No additional packages required - uses existing ggplot2 and D3.js v7.

## Architecture Patterns

### Recommended IR Structure (Multi-Panel)

Current IR has single `panel_params` and single `layers` array. Faceting requires:

```javascript
{
  facets: {
    type: "wrap",           // "wrap", "grid", or "null"
    vars: ["cyl"],          // faceting variable names
    nrow: 2,
    ncol: null,             // computed if null
    layout: [               // from b$layout$layout dataframe
      {PANEL: 1, ROW: 1, COL: 1, cyl: "4", SCALE_X: 1, SCALE_Y: 1},
      {PANEL: 2, ROW: 1, COL: 2, cyl: "6", SCALE_X: 1, SCALE_Y: 1},
      {PANEL: 3, ROW: 2, COL: 1, cyl: "8", SCALE_X: 1, SCALE_Y: 1}
    ],
    strips: [               // strip label text per panel
      {PANEL: 1, label: "4"},
      {PANEL: 2, label: "6"},
      {PANEL: 3, label: "8"}
    ]
  },
  panels: [                 // per-panel metadata (replaces single panel_params)
    {
      PANEL: 1,
      x_range: [1.32, 5.62],
      y_range: [9.22, 35.07],
      x_breaks: [2, 3, 4, 5],
      y_breaks: [10, 15, 20, 25, 30, 35]
      // Fixed scales: all panels have same ranges
    },
    // ... panels 2, 3
  ],
  layers: [
    {
      geom: "point",
      data: [
        {PANEL: 1, x: 2.32, y: 22.8},  // PANEL column routes to correct panel
        {PANEL: 2, x: 2.62, y: 21.0},
        {PANEL: 3, x: 3.44, y: 18.7}
      ],
      aes: {...}
    }
  ]
}
```

**Key changes from single-panel IR:**
1. `facets` object added with layout dataframe and strip labels
2. `panels` array replaces single set of ranges/breaks
3. Layer data includes `PANEL` column for filtering

### Pattern 1: Layout Engine Extension for Multi-Panel Grid

**What:** Extend `calculateLayout()` to compute positions for multiple panels in a grid

**When to use:** All facet_wrap plots

**Structure:**
```javascript
// Input to calculateLayout
config.facets = {
  type: "wrap",
  nrow: 2,
  ncol: 2,
  layout: [...],  // PANEL, ROW, COL mappings
  spacing: 7.3    // panel.spacing in pixels
}

// Output from calculateLayout
return {
  panels: [       // Array of panel positions
    {
      PANEL: 1,
      x: 50, y: 20,
      w: 200, h: 150,
      clipId: "panel-1-clip"
    },
    {
      PANEL: 2,
      x: 270, y: 20,  // spacing applied
      w: 200, h: 150,
      clipId: "panel-2-clip"
    },
    // ...
  ],
  strips: [       // Array of strip label positions
    {
      PANEL: 1,
      x: 50, y: 5,
      w: 200, h: 15,
      label: "4"
    },
    // ...
  ],
  // existing single-panel layout fields remain for backwards compatibility
}
```

**Algorithm:**
1. Calculate total grid dimensions (nrow × ncol)
2. Divide available space after margins/titles/legend by grid size
3. Apply panel.spacing between panels
4. Reserve strip height (strip text height + margin)
5. Generate per-panel boxes with ROW/COL positioning
6. Single axis labels apply to entire grid (not per-panel for fixed scales)

### Pattern 2: Per-Panel Rendering Loop

**What:** Iterate over panels, filter data by PANEL column, render geoms in clipped groups

**When to use:** All geom rendering with facets

**Example:**
```javascript
// Pseudo-code for rendering loop
layout.panels.forEach(panelLayout => {
  const panelNum = panelLayout.PANEL;
  const panelData = ir.panels.find(p => p.PANEL === panelNum);

  // Create panel group with clip path
  const panelGroup = svg.append('g')
    .attr('class', `panel panel-${panelNum}`)
    .attr('clip-path', `url(#${panelLayout.clipId})`);

  // Create scales for this panel
  const xScale = createScale(
    panelData.x_range,
    [0, panelLayout.w],
    ir.scales.x.type
  );

  // Filter and render layers for this panel
  ir.layers.forEach(layer => {
    const panelLayerData = layer.data.filter(d => d.PANEL === panelNum);
    renderGeom(panelGroup, layer.geom, panelLayerData, xScale, yScale);
  });
});
```

### Pattern 3: Strip Label Rendering

**What:** Render facet strip labels above/beside panels with theme styling

**When to use:** All facet_wrap plots

**Example:**
```javascript
// Strip rendering from layout data
layout.strips.forEach(strip => {
  const stripGroup = svg.append('g')
    .attr('class', 'strip-top');

  // Background rect
  stripGroup.append('rect')
    .attr('x', strip.x)
    .attr('y', strip.y)
    .attr('width', strip.w)
    .attr('height', strip.h)
    .attr('fill', theme.get('strip.background').fill);

  // Text label
  stripGroup.append('text')
    .attr('x', strip.x + strip.w / 2)
    .attr('y', strip.y + strip.h / 2)
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'middle')
    .text(strip.label)
    .attr('fill', theme.get('strip.text').colour)
    .attr('font-size', ptToPx(theme.get('strip.text').size));
});
```

### Anti-Patterns to Avoid

- **Don't implement free scales in Phase 8:** Free scales require per-panel scale objects (indexed by SCALE_X/SCALE_Y in layout). Start with fixed scales only.
- **Don't compute strip labels in JavaScript:** Extract pre-formatted labels from ggplot2 using the facet variable levels.
- **Don't create separate axis per panel for fixed scales:** Fixed scales share one axis - render once per grid row/col.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Facet layout computation | Custom grid algorithm | Extract `b$layout$layout` dataframe | ggplot2 already handles wrap logic, drop empty panels, ROW/COL calculation |
| Strip label formatting | String concatenation | Facet params `$labeller` function | ggplot2's labeller handles multi-variable labels, custom formatting |
| Panel data subsetting | Manual filtering logic | Use PANEL column from `ggplot_build()` | ggplot2 already assigned PANEL numbers to all layer rows |
| Free scale domain calculation | Per-panel min/max | Use `panel_params[[i]]$x.range` | ggplot2 computed per-panel domains with proper expansion |

**Key insight:** ggplot2's `ggplot_build()` output contains ALL faceting metadata. Don't recompute what ggplot2 already provides. The `b$layout$layout` dataframe is the single source of truth for panel organization.

## Common Pitfalls

### Pitfall 1: Fixed vs Free Scale Confusion

**What goes wrong:** Assuming one scale object means one domain. With fixed scales, `panel_scales_x` has length 1 but all panels use it. With free scales, `panel_scales_x` has length N and `layout$SCALE_X` indexes into it.

**Why it happens:** The scale/panel relationship isn't obvious from the structure.

**How to avoid:**
- Phase 8: Verify `length(b$layout$panel_scales_x) == 1` for fixed scales
- Check `layout$SCALE_X` column - all values should be 1 for fixed scales
- Use the shared scale object for all panels

**Warning signs:** Different panels showing different axis ranges when scales="fixed"

### Pitfall 2: Strip Positioning Overlap with Title

**What goes wrong:** Strip labels positioned where title should be, or overlapping panel

**Why it happens:** Layout engine doesn't reserve space for strips in title slicing

**How to avoid:**
- Add strip height to title area calculation: `titleHeight + stripHeight`
- Or slice strips separately after title, before panels
- Default strip height: `strip.text.size (8.8pt) * 1.2 + strip.text.margin (4.4pt * 2) ≈ 21px`

**Warning signs:** Strips clipped by title, panels starting too high

### Pitfall 3: PANEL Column Type Mismatch

**What goes wrong:** Data filtering by PANEL fails silently, no data renders

**Why it happens:** PANEL is an integer in R but might serialize as string or factor

**How to avoid:**
- In R: Ensure PANEL column is integer in layer data before `to_rows()`
- In JS: Use `d.PANEL === panelNum` with strict equality
- Test with `console.log` to verify PANEL values and types

**Warning signs:** Empty panels, console shows data but nothing renders

### Pitfall 4: Panel Spacing Units

**What goes wrong:** Panels overlap or have huge gaps

**Why it happens:** `panel.spacing` is a grid unit (pt), not pixels

**How to avoid:**
- Extract theme value: `complete_theme$panel.spacing`
- Convert to pixels: `grid::convertUnit(spacing, "inches", valueOnly=TRUE) * 96`
- Default: 5.5pt = 7.3px

**Warning signs:** Panels touching or enormous gaps between panels

### Pitfall 5: Axes in Wrong Position for Facets

**What goes wrong:** Drawing axis per panel when using fixed scales

**Why it happens:** Mixing single-panel and multi-panel rendering logic

**How to avoid:**
- Fixed scales: axes render ONCE on outer edges of grid
- Only inside panels differ (grid lines, geoms)
- Axis labels apply to entire grid
- Don't call axis rendering inside panel loop

**Warning signs:** Duplicate axis labels, axes inside panel area

## Code Examples

Verified patterns from research:

### Extracting Facet Metadata (R)

```r
# Source: Empirical testing with ggplot_build()
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl, nrow = 2)

b <- ggplot_build(p)

# Layout dataframe: PANEL, ROW, COL, faceting vars, SCALE_X/Y
layout_df <- b$layout$layout
# Output:
#   PANEL ROW COL cyl SCALE_X SCALE_Y
# 1     1   1   1   4       1       1
# 2     2   1   2   6       1       1
# 3     3   2   1   8       1       1

# Facet parameters
facet_params <- b$layout$facet$params
# Contains: facets (quosure), nrow, ncol, free, labeller, dir, strip.position

# Strip labels: apply labeller to facet variable levels
facet_var <- "cyl"
facet_levels <- unique(mtcars[[facet_var]])
strip_labels <- facet_params$labeller(setNames(list(as.character(facet_levels)), facet_var))

# Panel count
n_panels <- length(b$layout$panel_params)

# Panel-specific data (layer data has PANEL column)
layer_data <- b$data[[1]]  # First layer
panel_1_data <- layer_data[layer_data$PANEL == 1, ]
```

### Grid Layout Calculation (JavaScript)

```javascript
// Source: D3 small multiples pattern (adapted)
// https://blog.scottlogic.com/2017/04/05/interactive-responsive-small-multiples.html

function calculateFacetGrid(availableBox, facets, spacing) {
  const { nrow, ncol, layout } = facets;

  // Calculate panel dimensions
  const totalSpacingX = (ncol - 1) * spacing;
  const totalSpacingY = (nrow - 1) * spacing;
  const panelWidth = (availableBox.w - totalSpacingX) / ncol;
  const panelHeight = (availableBox.h - totalSpacingY) / nrow;

  // Generate panel positions from layout dataframe
  const panels = layout.map(row => {
    const col = row.COL - 1;  // 1-indexed to 0-indexed
    const rowIdx = row.ROW - 1;

    return {
      PANEL: row.PANEL,
      x: availableBox.x + col * (panelWidth + spacing),
      y: availableBox.y + rowIdx * (panelHeight + spacing),
      w: panelWidth,
      h: panelHeight,
      clipId: `panel-${row.PANEL}-clip`
    };
  });

  return panels;
}
```

### Per-Panel Clipping (JavaScript)

```javascript
// Source: Existing panel-clip-path decision (Phase 3)
// Create clipPath definitions for each panel
ir.facets.layout.forEach(panel => {
  svg.append('defs').append('clipPath')
    .attr('id', `panel-${panel.PANEL}-clip`)
    .append('rect')
    .attr('x', 0)
    .attr('y', 0)
    .attr('width', panelLayout.w)
    .attr('height', panelLayout.h);
});

// Apply clip when rendering panel
const panelGroup = svg.append('g')
  .attr('class', `panel-${panel.PANEL}`)
  .attr('transform', `translate(${panelLayout.x}, ${panelLayout.y})`)
  .attr('clip-path', `url(#panel-${panel.PANEL}-clip)`);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CSS Flexbox for grid | SVG transforms | Ongoing | SVG transforms give pixel-perfect control, essential for coord_fixed aspect ratios |
| Multiple <svg> elements | Single <svg> with groups | D3 v3+ era | Single SVG enables shared scales/axes, simpler rendering |
| DOM measurement for text | Font-size estimation | Phase 6 decision | Estimation makes layout engine pure function, no DOM dependency |

**Deprecated/outdated:**
- **facet_grid(x ~ .)** single-column syntax: Still works but `facet_wrap(~ x, ncol=1)` is more flexible
- **Manual panel.border for facets:** Use `strip.background` and `panel.border` theme elements instead

## Open Questions

1. **Strip label wrapping for long text**
   - What we know: ggplot2 has `label_wrap_gen()` for labeller, but unclear if applied before ggplot_build
   - What's unclear: Whether pre-wrapped labels appear in facet params or need JavaScript wrapping
   - Recommendation: Test with long facet level names, extract labels post-build, defer wrapping to future phase

2. **Strip placement (inside vs outside)**
   - What we know: `strip.placement = "inside"` (default) vs `"outside"` moves strips relative to axes
   - What's unclear: How placement="outside" affects layout calculation (strips outside axis labels?)
   - Recommendation: Phase 8 supports placement="inside" only, document limitation

3. **Margins between strips and panels**
   - What we know: `strip.text$margin` is 4.4pt (5.87px), `strip.switch.pad.wrap` exists for switched strips
   - What's unclear: Exact pixel calculation when strips include margin
   - Recommendation: Add `strip.text$margin` to strip box height, validate visually

## Sources

### Primary (HIGH confidence)
- Empirical testing with `ggplot_build()` on facet_wrap plots (mtcars dataset)
- [ggplot2 facet_wrap reference](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
- [ggplot2 theme reference - strip elements](https://ggplot2.tidyverse.org/reference/theme.html)
- Existing gg2d3 codebase: `R/as_d3_ir.R`, `inst/htmlwidgets/modules/layout.js`

### Secondary (MEDIUM confidence)
- [16 Faceting – ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/facet.html) - User-facing faceting concepts
- [19 Internals of ggplot2 – ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/internals.html) - ggplot_build faceting process
- [Interactive and Responsive Small Multiples with D3](https://blog.scottlogic.com/2017/04/05/interactive-responsive-small-multiples.html) - D3 grid layout pattern
- [How to increase spacing between faceted plots using ggplot2](https://statisticsglobe.com/increase-space-between-ggplot2-facet-plot-panels-in-r) - panel.spacing usage

### Tertiary (LOW confidence)
- [d3-grid-layout](https://github.com/hughsk/d3-grid-layout) - Grid layout library (not needed, custom approach better)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ggplot2 faceting and D3 v7 are established, empirically verified
- Architecture: HIGH - Tested b$layout structure, confirmed PANEL column behavior, validated theme extraction
- Pitfalls: MEDIUM-HIGH - Fixed vs free scales from docs and testing, other pitfalls inferred from single-panel experience

**Research date:** 2026-02-13
**Valid until:** 2026-03-13 (30 days - stable ggplot2 API)
