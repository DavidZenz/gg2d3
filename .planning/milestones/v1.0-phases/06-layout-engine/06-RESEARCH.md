# Phase 6: Layout Engine - Research

**Researched:** 2026-02-09
**Domain:** Spatial layout calculation for SVG chart components (panels, axes, titles, legends)
**Confidence:** HIGH

## Summary

Phase 6 extracts the ad-hoc layout calculations currently scattered throughout `gg2d3.js` into a centralized `layout.js` module that computes pixel positions for every chart component before any rendering occurs. The current renderer computes panel dimensions by subtracting hardcoded padding offsets from widget dimensions, positions titles with magic numbers (`pad.top * 0.6`, `pad.left - 35`), and has no mechanism for reserving space for legends, secondary axes, or facet strips. This must be replaced with a constraint-based layout algorithm that mirrors ggplot2's gtable approach: allocate fixed space for known elements (margins, titles, axis labels), then give remaining space to the panel.

ggplot2 uses a gtable (grid table) layout internally where every component (title, subtitle, axes, panel, legend boxes, caption) occupies a named cell in a grid. The gtable has 13 columns and 16 rows in a standard plot, with the panel cell taking `1null` (all remaining space). We do NOT need to replicate gtable in JavaScript -- instead we extract the key spatial relationships and implement a simpler box-model layout engine. The critical insight is that the layout engine must produce a complete `LayoutResult` object containing pixel coordinates for every component, and rendering functions consume this object instead of computing positions themselves.

The layout engine must be designed to support Phase 7 (legends), Phase 8 (faceting), and Phase 9 (advanced faceting) without breaking changes. This means the `calculateLayout()` function must accept legend dimensions, facet grid specs, and secondary axis presence as optional inputs, and the `LayoutResult` must have reserved fields for these future components.

**Primary recommendation:** Create a pure-function `calculateLayout(config)` in a new `layout.js` module that takes widget dimensions, theme, IR metadata (titles, axis labels, legend position) and returns a complete position map. Refactor `gg2d3.js` to call this function once at the start of `draw()` and pass the result to all rendering functions.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3.js | v7 | Text measurement (`getComputedTextLength()`) | Already integrated; SVG text measurement is the only reliable way to get label widths in browser |
| gg2d3 theme module | 0.0.1 | Theme defaults for font sizes, margins | Existing module provides all theme values needed for size estimation |
| gg2d3 constants module | 0.0.1 | Unit conversion (pt to px, mm to px) | Existing conversions for ggplot2 units |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| R ggplot2 | 3.5+ | Extract axis label strings, title text, legend position from ggplot_build() | Pre-compute label text in R so JS can estimate dimensions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom box-model layout | CSS Grid/Flexbox (foreignObject) | Would require foreignObject which has browser compatibility issues in SVG; pure SVG positioning is more reliable for charts |
| JavaScript text measurement | R-side pre-computed label widths | R cannot know the browser font metrics; JS measurement is more accurate for web rendering |
| Constraint solver (Cassowary.js) | Simple subtraction | Overkill for chart layout; subtraction-based allocation is what ggplot2 does (fixed sizes subtracted from total, panel gets remainder) |

**Installation:**
No new dependencies required. Layout engine is pure JavaScript using existing modules.

## Architecture Patterns

### Recommended Module Structure
```
inst/htmlwidgets/modules/
  layout.js          # NEW: calculateLayout() + helpers
  constants.js       # Existing: unit conversions
  theme.js           # Existing: theme defaults + padding calc (to be simplified)
  scales.js          # Existing: scale factory
  geom-registry.js   # Existing: geom dispatch
  geoms/             # Existing: geom renderers
```

### Pattern 1: Subtraction-Based Layout Algorithm
**What:** Allocate space for fixed-size elements first (margins, titles, axis labels), then give all remaining space to the panel. This mirrors ggplot2's gtable approach where the panel cell uses `1null` (remaining space).

**When to use:** Every chart render. This is the core layout algorithm.

**Example:**
```javascript
// Source: Derived from ggplot2 gtable layout structure
function calculateLayout(config) {
  const { width, height, theme, titles, axes, legend, coord } = config;

  // 1. Start with full widget dimensions
  let available = { x: 0, y: 0, w: width, h: height };

  // 2. Subtract plot margins (outermost)
  const margin = theme.plotMargin; // {top, right, bottom, left} in px
  available.x += margin.left;
  available.y += margin.top;
  available.w -= margin.left + margin.right;
  available.h -= margin.top + margin.bottom;

  // 3. Reserve space for title/subtitle/caption (top/bottom)
  const titleHeight = titles.title ? estimateTextHeight(titles.titleSize) + 4 : 0;
  const subtitleHeight = titles.subtitle ? estimateTextHeight(titles.subtitleSize) + 2 : 0;
  const captionHeight = titles.caption ? estimateTextHeight(titles.captionSize) + 2 : 0;

  const topReserved = titleHeight + subtitleHeight;
  const bottomReserved = captionHeight;

  available.y += topReserved;
  available.h -= topReserved + bottomReserved;

  // 4. Reserve space for legend (based on position)
  const legendSpace = legend.enabled ? estimateLegendSize(legend) : { w: 0, h: 0 };
  // ... subtract from appropriate side

  // 5. Reserve space for axis labels and tick labels
  const bottomAxisSpace = axes.x.label ? axes.x.titleSize + axes.x.tickLabelHeight + axes.x.tickLength + 8 : 0;
  const leftAxisSpace = axes.y.label ? axes.y.titleSize + axes.y.maxTickLabelWidth + axes.y.tickLength + 8 : 0;
  // ... subtract from available

  // 6. Panel = remaining space
  const panel = {
    x: available.x + leftAxisSpace,
    y: available.y,
    w: available.w - leftAxisSpace - rightAxisSpace,
    h: available.h - bottomAxisSpace - topAxisSpace
  };

  // 7. Apply coord_fixed constraints
  if (coord && coord.ratio) {
    // Constrain panel dimensions to maintain aspect ratio
    // Center in available space
  }

  return {
    total: { w: width, h: height },
    margin: margin,
    title: { x, y, w, anchor },
    subtitle: { x, y, w, anchor },
    caption: { x, y, w, anchor },
    panel: panel,
    clipId: generateClipId(),
    axes: {
      bottom: { x, y, w },
      left: { x, y, h },
      top: { x, y, w },    // secondary
      right: { x, y, h }   // secondary
    },
    axisLabels: {
      x: { x, y, anchor },
      y: { x, y, anchor, rotation }
    },
    legend: { x, y, w, h, position },
    // Future: facets, strips
  };
}
```

### Pattern 2: Text Dimension Estimation
**What:** Estimate text height and width without actually rendering, using font size and character count. For accurate measurement, optionally render a hidden text element and measure with `getComputedTextLength()`.

**When to use:** Estimating space for axis labels, titles, and legend text.

**Example:**
```javascript
// Fast estimation (no DOM measurement needed)
function estimateTextHeight(fontSizePx) {
  // Text height is approximately 1.2x font size (line height)
  return fontSizePx * 1.2;
}

function estimateTextWidth(text, fontSizePx) {
  // Average character width is ~0.6x font size for sans-serif
  return text.length * fontSizePx * 0.6;
}

// Accurate measurement (requires SVG container)
function measureText(svgContainer, text, fontSizePx, fontFamily) {
  const el = svgContainer.append("text")
    .attr("visibility", "hidden")
    .style("font-size", fontSizePx + "px")
    .style("font-family", fontFamily || "sans-serif")
    .text(text);
  const bbox = el.node().getBBox();
  el.remove();
  return { w: bbox.width, h: bbox.height };
}
```

### Pattern 3: LayoutResult as Single Source of Truth
**What:** All rendering functions receive a `LayoutResult` object and use its coordinates directly, never computing positions themselves.

**When to use:** Every component renderer (panel background, axes, grids, titles, legends).

**Example:**
```javascript
// Before (current scattered approach):
function draw(ir, elW, elH) {
  const pad = calculatePadding(theme, ir.padding);  // magic offsets
  const w = innerW - pad.left - pad.right;           // ad-hoc
  const h = innerH - pad.top - pad.bottom;           // ad-hoc
  // Title positioned with magic: pad.top * 0.6
  // Y-axis title: Math.max(12, pad.left - 35)
}

// After (centralized layout):
function draw(ir, elW, elH) {
  const layout = calculateLayout({
    width: elW, height: elH,
    theme: theme, titles: extractTitles(ir),
    axes: extractAxes(ir), legend: ir.legend, coord: ir.coord
  });
  // All positions come from layout object
  drawPanelBackground(g, layout.panel);
  drawGrid(g, layout.panel, ...);
  drawAxes(g, layout.axes, ...);
  drawTitle(root, layout.title, ir.title);
  drawAxisLabels(root, layout.axisLabels, ir.axes);
}
```

### Pattern 4: Extensible Layout Config for Future Phases
**What:** The layout config and result objects include optional fields for legends (Phase 7), facets (Phase 8-9), and secondary axes.

**When to use:** Design the API now even though features come later.

**Example:**
```javascript
// Config (input) - future fields are optional/null
const config = {
  width: 640,
  height: 400,
  theme: themeAccessor,
  titles: {
    title: "My Plot",
    subtitle: null,
    caption: null,
    tag: null
  },
  axes: {
    x: { label: "Weight", position: "bottom", tickLabels: ["2","3","4","5"] },
    y: { label: "MPG", position: "left", tickLabels: ["10","15","20","25","30","35"] },
    x2: null,  // secondary x axis (Phase 6)
    y2: null   // secondary y axis (Phase 6)
  },
  legend: {
    position: "right",  // "right"|"left"|"top"|"bottom"|"inside"|"none"
    insidePosition: null, // {x, y} for "inside" position
    width: 0,   // estimated or measured width (0 = no legend yet)
    height: 0
  },
  coord: {
    type: "cartesian",
    flip: false,
    ratio: null  // coord_fixed ratio
  },
  facet: null  // Phase 8: { type, nrow, ncol, panels: [...] }
};

// Result (output) - future fields present but empty
const result = {
  panel: { x: 60, y: 30, w: 480, h: 320 },
  panels: null,  // Phase 8: array of panel rects for faceting
  // ...
};
```

### Anti-Patterns to Avoid
- **Hardcoded pixel offsets:** Never use magic numbers like `pad.top * 0.6` or `pad.left - 35`. All positions must derive from the layout calculation.
- **Layout in render functions:** Render functions should receive position data, not compute it. The layout engine is the single source of truth.
- **DOM-dependent layout:** The core layout algorithm should be a pure function (no DOM access). Text measurement is an optional refinement step.
- **Coupling to single panel:** Design for `panels[]` array from the start, even if Phase 6 only has one panel.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG text measurement | Character-counting width estimation | `SVGTextElement.getComputedTextLength()` | Font kerning, variable-width characters, and different font families make character counting inaccurate; browsers have native measurement |
| CSS unit conversion | Custom pt/mm/in converters | Existing `constants.js` module | Already has verified W3C-standard conversion factors |
| Theme value resolution | Manual defaults checking | Existing `theme.js` `createTheme().get()` | Deep merge with defaults already implemented |
| Aspect ratio math | Custom ratio calculation | Existing `calculatePanelSize()` function | coord_fixed aspect ratio logic already handles width/height-limited cases correctly |

**Key insight:** The layout engine orchestrates existing components -- it does not replace them. Theme resolution, unit conversion, and aspect ratio math already work correctly. The layout engine's job is to sequence these calculations and produce a unified position map.

## Common Pitfalls

### Pitfall 1: Text Measurement Before DOM Exists
**What goes wrong:** `calculateLayout()` tries to measure text with `getComputedTextLength()` before the SVG element is created, throwing an error.
**Why it happens:** Layout calculation runs first, but text measurement needs a rendered SVG context.
**How to avoid:** Use a two-phase approach: (1) estimate dimensions with font-size-based heuristics, (2) optionally refine with actual measurement after SVG creation. Or create a hidden measurement SVG at the start of draw().
**Warning signs:** `Cannot read property 'getComputedTextLength' of null` errors.

### Pitfall 2: Negative Panel Dimensions
**What goes wrong:** Too many components (long title, large axis labels, legend) consume more space than available, resulting in negative panel width or height.
**Why it happens:** The subtraction algorithm doesn't enforce minimums.
**How to avoid:** Clamp panel dimensions to a minimum (e.g., 50x50 px). If panel would be too small, progressively reduce component sizes or skip optional elements.
**Warning signs:** Panel area collapses to zero, chart looks empty.

### Pitfall 3: Resize Recalculation Cost
**What goes wrong:** Layout is expensive to recalculate, causing janky resize animation.
**Why it happens:** Text measurement DOM operations are slow when called on every resize frame.
**How to avoid:** Use estimation-based layout (no DOM measurement) for resize events. Cache text measurements from initial render. Use `requestAnimationFrame` debouncing.
**Warning signs:** Laggy resize, visual glitches during window resizing.

### Pitfall 4: Breaking Existing Rendering
**What goes wrong:** Refactoring layout calculation changes panel dimensions, breaking visual tests.
**Why it happens:** Current padding has hardcoded offsets (`+30`, `+50`, etc.) that affect where geoms are positioned. Changing these shifts everything.
**How to avoid:** Phase the migration: first make `calculateLayout()` produce the SAME positions as current code, then iteratively improve. Use visual comparison tests.
**Warning signs:** All existing test outputs shift by a few pixels after layout engine integration.

### Pitfall 5: Legend Space Reservation Without Legends
**What goes wrong:** Phase 6 reserves space for legends but Phase 7 (legend rendering) doesn't exist yet, creating an empty gap.
**Why it happens:** Layout engine accounts for legend dimensions but no legend is drawn.
**How to avoid:** Default legend dimensions to 0 until Phase 7 provides actual legend content. The layout engine should treat `legend.width = 0` as "no legend".
**Warning signs:** Unexplained empty space on one side of the plot.

### Pitfall 6: coord_flip Axis Position Confusion
**What goes wrong:** Layout engine positions x-axis at bottom and y-axis at left, but coord_flip swaps which data maps to which visual axis.
**Why it happens:** "x-axis" means different things in data space vs. visual space when coord_flip is active.
**How to avoid:** Layout engine works in VISUAL space only. "bottom axis" is always at the bottom regardless of flip. The data-to-visual mapping (which scale drives which axis) is handled by the render step, not layout.
**Warning signs:** Axis labels appear on wrong side after coord_flip.

## Code Examples

### Current Layout Calculation (to be replaced)
```javascript
// Source: /Users/davidzenz/R/gg2d3/inst/htmlwidgets/gg2d3.js lines 45-101
// CURRENT approach - scattered, hardcoded

const innerW = ir.width || elW || 640;
const innerH = ir.height || elH || 400;

// theme.js calculatePadding adds hardcoded offsets:
// top: plotMargin.top + 30
// right: plotMargin.right + 20
// bottom: plotMargin.bottom + 40
// left: plotMargin.left + 50
const pad = window.gg2d3.theme.calculatePadding(theme, ir.padding);

const availW = Math.max(10, innerW - pad.left - pad.right);
const availH = Math.max(10, innerH - pad.top - pad.bottom);

// coord_fixed panel sizing
const panel = calculatePanelSize(availW, availH, coordRatio, xDataRange, yDataRange);
const w = panel.w;
const h = panel.h;

// Title: magic y-position
root.append("text")
  .attr("x", innerW / 2)
  .attr("y", Math.max(14, pad.top * 0.6))  // <-- magic number

// Y axis title: magic x-position
const yTitleX = Math.max(12, pad.left + panel.offsetX - 35);  // <-- magic number
```

### Proposed Layout Engine API
```javascript
// Source: New module inst/htmlwidgets/modules/layout.js

/**
 * Calculate complete layout for all chart components.
 *
 * @param {Object} config - Layout configuration
 * @param {number} config.width - Total widget width in pixels
 * @param {number} config.height - Total widget height in pixels
 * @param {Object} config.theme - Theme accessor (from createTheme)
 * @param {Object} config.titles - {title, subtitle, caption, tag} strings
 * @param {Object} config.axes - Axis metadata with labels and tick label strings
 * @param {Object} config.legend - Legend position and estimated dimensions
 * @param {Object} config.coord - Coordinate system (flip, ratio)
 * @returns {LayoutResult} Complete position data for all components
 */
function calculateLayout(config) {
  const {
    width, height, theme, titles, axes, legend, coord
  } = config;

  const convertColor = window.gg2d3.scales.convertColor;
  const ptToPx = window.gg2d3.constants.ptToPx;

  // --- Get theme values ---
  const plotMargin = getPlotMargin(theme);
  const axisTextSize = getAxisTextSize(theme);
  const axisTitleSize = getAxisTitleSize(theme);
  const tickLength = getTickLength(theme);
  const titleSize = getTitleSize(theme);

  // --- Compute component sizes ---
  const titleHeight = titles.title ?
    estimateTextHeight(titleSize.title) + 4 : 0;
  const subtitleHeight = titles.subtitle ?
    estimateTextHeight(titleSize.subtitle) + 2 : 0;
  const captionHeight = titles.caption ?
    estimateTextHeight(titleSize.caption) + 4 : 0;

  // Axis tick labels: estimate from label strings
  const yTickMaxWidth = axes.y.tickLabels ?
    estimateMaxTextWidth(axes.y.tickLabels, axisTextSize.y) : 0;
  const xTickHeight = axes.x.tickLabels ?
    estimateTextHeight(axisTextSize.x) : 0;

  // Axis titles
  const xTitleHeight = axes.x.label ?
    estimateTextHeight(axisTitleSize.x) + 4 : 0;
  const yTitleWidth = axes.y.label ?
    estimateTextHeight(axisTitleSize.y) + 4 : 0;

  // --- Allocate space (outside-in) ---
  let box = { x: 0, y: 0, w: width, h: height };

  // 1. Plot margins
  box = shrinkBox(box, plotMargin);

  // 2. Title area (top)
  const titleArea = sliceTop(box, titleHeight + subtitleHeight);
  box = titleArea.remaining;

  // 3. Caption area (bottom)
  const captionArea = sliceBottom(box, captionHeight);
  box = captionArea.remaining;

  // 4. Legend area (based on position)
  let legendArea = { x: 0, y: 0, w: 0, h: 0 };
  if (legend && legend.position !== "none" && legend.position !== "inside") {
    const legendResult = sliceSide(box, legend.position,
      legend.width || 0, legend.height || 0);
    legendArea = legendResult.sliced;
    box = legendResult.remaining;
  }

  // 5. Axis labels (bottom and left)
  const bottomSpace = xTickHeight + tickLength + xTitleHeight + 4;
  const leftSpace = yTickMaxWidth + tickLength + yTitleWidth + 4;
  const rightSpace = (axes.y2 && axes.y2.label) ?
    yTickMaxWidth + tickLength + yTitleWidth + 4 : 0;
  const topSpace = (axes.x2 && axes.x2.label) ?
    xTickHeight + tickLength + xTitleHeight + 4 : 0;

  // 6. Panel = remaining space
  let panel = {
    x: box.x + leftSpace,
    y: box.y + topSpace,
    w: Math.max(50, box.w - leftSpace - rightSpace),
    h: Math.max(50, box.h - bottomSpace - topSpace)
  };

  // 7. Apply coord_fixed constraint
  if (coord && coord.ratio) {
    panel = applyAspectRatio(panel, coord.ratio, coord.xRange, coord.yRange);
  }

  return {
    total: { w: width, h: height },
    plotMargin: plotMargin,
    title: {
      x: panel.x + panel.w / 2,
      y: titleArea.sliced ? titleArea.sliced.y + titleHeight * 0.8 : 0,
      visible: !!titles.title
    },
    subtitle: {
      x: panel.x + panel.w / 2,
      y: titleArea.sliced ? titleArea.sliced.y + titleHeight + subtitleHeight * 0.8 : 0,
      visible: !!titles.subtitle
    },
    caption: {
      x: panel.x + panel.w / 2,
      y: captionArea.sliced ? captionArea.sliced.y + captionHeight * 0.8 : height,
      visible: !!titles.caption
    },
    panel: panel,
    axes: {
      bottom: { x: panel.x, y: panel.y + panel.h, w: panel.w },
      left: { x: panel.x, y: panel.y, h: panel.h },
      top: topSpace > 0 ? { x: panel.x, y: panel.y, w: panel.w } : null,
      right: rightSpace > 0 ? { x: panel.x + panel.w, y: panel.y, h: panel.h } : null
    },
    axisLabels: {
      x: {
        x: panel.x + panel.w / 2,
        y: panel.y + panel.h + xTickHeight + tickLength + xTitleHeight,
        visible: !!axes.x.label
      },
      y: {
        x: panel.x - yTickMaxWidth - tickLength - yTitleWidth / 2,
        y: panel.y + panel.h / 2,
        rotation: -90,
        visible: !!axes.y.label
      }
    },
    legend: legendArea,
    // Future phases:
    panels: null,     // Phase 8: [{x, y, w, h}, ...] for facets
    strips: null,     // Phase 8: [{x, y, w, h, label}, ...] for facet strips
    secondaryAxes: {  // Phase 6 supports this
      top: topSpace > 0,
      right: rightSpace > 0
    }
  };
}
```

### R-Side Layout Metadata Extraction
```r
# Source: Additions needed in R/as_d3_ir.R

# Extract axis tick labels as strings for JavaScript text measurement
x_labels <- tryCatch(
  b$layout$panel_params[[1]]$x$get_labels(),
  error = function(e) character(0)
)
y_labels <- tryCatch(
  b$layout$panel_params[[1]]$y$get_labels(),
  error = function(e) character(0)
)

# Remove NAs
x_labels <- x_labels[!is.na(x_labels)]
y_labels <- y_labels[!is.na(y_labels)]

# Extract secondary axis presence
has_sec_y <- !inherits(b$layout$panel_params[[1]]$y.sec, "waiver")
has_sec_x <- !inherits(b$layout$panel_params[[1]]$x.sec, "waiver")

# Extract legend position from theme
legend_pos <- tryCatch(
  as.character(ggplot2:::calc_element("legend.position", complete_theme)),
  error = function(e) "right"
)

# Include in IR
ir$axes$x$tickLabels <- as.character(x_labels)
ir$axes$y$tickLabels <- as.character(y_labels)
ir$axes$x2 <- if (has_sec_x) list(enabled = TRUE) else NULL
ir$axes$y2 <- if (has_sec_y) list(enabled = TRUE) else NULL
ir$legend$position <- legend_pos
```

### Box Manipulation Helpers
```javascript
// Pure utility functions for the layout algorithm

function shrinkBox(box, margin) {
  return {
    x: box.x + margin.left,
    y: box.y + margin.top,
    w: box.w - margin.left - margin.right,
    h: box.h - margin.top - margin.bottom
  };
}

function sliceTop(box, amount) {
  return {
    sliced: { x: box.x, y: box.y, w: box.w, h: amount },
    remaining: { x: box.x, y: box.y + amount, w: box.w, h: box.h - amount }
  };
}

function sliceBottom(box, amount) {
  return {
    sliced: { x: box.x, y: box.y + box.h - amount, w: box.w, h: amount },
    remaining: { x: box.x, y: box.y, w: box.w, h: box.h - amount }
  };
}

function sliceLeft(box, amount) {
  return {
    sliced: { x: box.x, y: box.y, w: amount, h: box.h },
    remaining: { x: box.x + amount, y: box.y, w: box.w - amount, h: box.h }
  };
}

function sliceRight(box, amount) {
  return {
    sliced: { x: box.x + box.w - amount, y: box.y, w: amount, h: box.h },
    remaining: { x: box.x, y: box.y, w: box.w - amount, h: box.h }
  };
}
```

## ggplot2 gtable Layout Reference

Understanding ggplot2's internal layout structure is critical for building a compatible layout engine.

### gtable Structure (Standard Single-Panel Plot)
```
ggplot2 gtable: 13 columns x 16 rows

Columns (left to right):
  1: plot margin left (5.5pt)
  2: tag space (0pt if no tag)
  3: guide-box-left (0cm if legend not on left)
  4: spacing (0pt)
  5: y-axis label width (grobwidth)
  6: y-axis tick labels + ticks (computed)
  7: PANEL (1null = remaining space)
  8: right-side axis area (0cm if no secondary axis)
  9: y-axis label right (0cm)
  10: spacing (11pt for legend gap)
  11: guide-box-right (legend width)
  12: spacing (0pt)
  13: plot margin right (5.5pt)

Rows (top to bottom):
  1: plot margin top (5.5pt)
  2: tag space (0pt)
  3: title (grobheight)
  4: subtitle (grobheight)
  5: guide-box-top (0cm)
  6: spacing (0pt)
  7: x-axis label top (0cm)
  8: top-side axis area (0cm if no secondary axis)
  9: PANEL (1null = remaining space)
  10: x-axis tick labels + ticks (computed)
  11: x-axis title (grobheight)
  12: spacing (0pt)
  13: guide-box-bottom (0cm)
  14: caption (grobheight)
  15: spacing (0pt)
  16: plot margin bottom (5.5pt)
```

### Key Layout Component Sizes (theme_gray defaults)
```
Component                    Size (default)
---------                    ----
plot.margin (each side)      5.5pt = 7.3px
title (plot.title)           13.2pt font = ~17.6px line height
subtitle (plot.subtitle)     11.0pt font = ~14.7px line height
caption (plot.caption)       8.8pt font = ~11.7px line height
axis.text (tick labels)      8.8pt font = ~11.7px line height
axis.title                   11.0pt font = ~14.7px line height
axis.ticks.length            2.75pt = 3.7px
panel.spacing                5.5pt = 7.3px (for facets)
legend.box.spacing           11pt = 14.7px (gap between panel and legend)
legend.key.size              1.2 lines = ~14px per key
legend.margin (each side)    5.5pt = 7.3px
```

### Axis Label Width Estimation
The largest layout challenge is estimating y-axis tick label width, since it depends on the actual label text and font. ggplot2 solves this by rendering grobs and measuring; we must estimate or measure in SVG.

**Verified approach:** For axis text at 8.8pt (11.7px), average character width is ~6.5px for sans-serif numerals. A label like "10000" = 5 chars * 6.5 = 32.5px. Add tick length (3.7px) + small gap (2px) = ~38px for y-axis tick area.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded padding offsets in theme.js | Centralized calculateLayout() | Phase 6 (now) | Single source of truth for all positions; eliminates magic numbers |
| Ad-hoc title positioning (pad.top * 0.6) | Layout-computed title position | Phase 6 (now) | Titles position correctly regardless of widget dimensions |
| Fixed 50px left margin for y-axis | Content-aware left margin based on tick label width | Phase 6 (now) | Wide labels (e.g., "100,000") get enough space |
| No legend space reservation | Legend-aware panel sizing | Phase 6 (now) | Panel shrinks to accommodate legend without overflow |

**Deprecated/outdated:**
- **theme.js `calculatePadding()` function:** Will be superseded by layout engine. The hardcoded offsets (`+30`, `+40`, `+50`) are replaced by content-aware calculations. Keep the function for backward compatibility during migration, then remove.
- **`calculatePanelSize()` in gg2d3.js:** The coord_fixed aspect ratio logic moves into the layout engine's `applyAspectRatio()` helper.

## Open Questions

1. **Should the layout engine use DOM-based text measurement or estimation?**
   - What we know: Estimation is faster and pure (no DOM dependency). DOM measurement with `getComputedTextLength()` is pixel-accurate but requires a rendered SVG element.
   - What's unclear: Whether estimation is accurate enough for production quality, or if the character-width heuristic will produce visible misalignment with some fonts/label lengths.
   - Recommendation: Start with estimation. Add optional DOM measurement refinement as a configurable second pass. In practice, ggplot2's default numeric labels (short numbers) will estimate well; long categorical labels may need measurement.

2. **How to handle the migration without breaking visual output?**
   - What we know: Current hardcoded offsets produce specific panel dimensions. Changing them shifts all geom positions.
   - What's unclear: Whether to match current output exactly (regression-free) or accept slight improvements as acceptable changes.
   - Recommendation: Accept that the layout engine will produce BETTER (more correct) positions than the current hardcoded offsets. Existing test snapshots will need updating. Document the improvements.

3. **Should layout.js replace or wrap calculatePadding?**
   - What we know: `calculatePadding()` in theme.js is the current layout entry point. It adds hardcoded offsets to theme margins.
   - What's unclear: Whether to keep calculatePadding for backward compat during transition.
   - Recommendation: Replace it. The layout engine produces strictly more information. Update gg2d3.js to call calculateLayout() instead of calculatePadding(). Mark calculatePadding as deprecated but keep it in theme.js temporarily.

4. **Secondary axis extraction -- how much to extract now vs. defer?**
   - What we know: ggplot2 panel_params has `x.sec` and `y.sec` ViewScale objects with breaks, labels, and transformation info. The gtable already allocates axis-r and axis-t cells for secondary axes.
   - What's unclear: Whether to implement full secondary axis rendering in Phase 6 or just reserve space for it.
   - Recommendation: Phase 6 should extract secondary axis presence and breaks from the R layer, reserve space in the layout, but defer actual rendering of secondary axis ticks/labels to a focused plan. The layout engine must know about them to size the panel correctly.

## Sources

### Primary (HIGH confidence)
- **gg2d3 codebase (inspected directly):**
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/gg2d3.js` - Current renderer with ad-hoc layout (lines 10-301)
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/theme.js` - `calculatePadding()` function (lines 110-125)
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/constants.js` - Unit conversion functions
  - `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` - IR extraction including theme elements (lines 74-498)
- **ggplot2 gtable layout (inspected via R console):**
  - `ggplot_gtable(ggplot_build(p))` - 13x16 grid layout with named cells for all components
  - `gt$layout` - Maps component names to grid cells (background, panel, axis-l/r/t/b, title, subtitle, caption, guide-box-right/left/top/bottom/inside, xlab-t/b, ylab-l/r, spacers)
  - `gt$widths` / `gt$heights` - Grid unit specifications (points, cm, grobwidth, 1null for panel)
- **ggplot2 theme system (inspected via R console):**
  - `calc_element()` output for all layout-relevant elements (margins, spacings, font sizes, tick lengths)
  - Default values for theme_gray(): plot.margin=5.5pt, panel.spacing=5.5pt, legend.box.spacing=11pt
- **ggplot2 secondary axis system (inspected via R console):**
  - `panel_params$y.sec` ViewScale with breaks, labels, position for secondary axes
  - Secondary axes create axis-r and axis-t grobs in the gtable

### Secondary (MEDIUM confidence)
- **D3.js SVG text measurement:** `SVGTextElement.getComputedTextLength()` and `getBBox()` are standard SVG APIs available in all modern browsers. Used for accurate text dimension measurement.
- **ggplot2 book internals chapter:** Describes the build -> gtable -> render pipeline, confirming that gtable is the authoritative layout structure.

### Tertiary (LOW confidence)
- **Character-width estimation heuristic (0.6x font size):** This is a commonly used approximation for sans-serif fonts. Actual widths vary by character, font, and rendering engine. Should be validated against DOM measurement in testing.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new dependencies; all components already exist in codebase
- Architecture: HIGH - Subtraction-based layout is the established pattern (ggplot2 uses it); extensively verified via gtable inspection
- Pitfalls: HIGH - Identified from direct inspection of current code's magic numbers and hardcoded offsets
- R-side extraction: HIGH - Verified all extractable metadata (tick labels, secondary axes, legend position) via R console

**Research date:** 2026-02-09
**Valid until:** 90 days (stable domain - ggplot2 layout system well-established; D3 SVG APIs stable)
