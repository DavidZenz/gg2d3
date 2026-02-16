# Phase 7: Legend System - Research

**Researched:** 2026-02-09
**Domain:** Legend/guide generation for aesthetic mappings (ggplot2 guide system + D3.js SVG legend rendering)
**Confidence:** HIGH

## Summary

Phase 7 implements automatic legend generation for all aesthetic mappings (color, fill, size, shape, alpha) by extracting guide specifications from ggplot2's built-in guide system and rendering them as D3 SVG legend components. The critical architectural insight is that ggplot2 already computes all legend keys, labels, and aesthetic values through its guide training mechanism—the R layer extracts this pre-computed guide data and passes it through the IR, while the D3 layer renders pure SVG legends positioned by the existing layout engine.

ggplot2's guide system is built around the concept that every scale is associated with exactly one guide. The guide training process (`guide_train()`) extracts breaks from scales, maps data values to aesthetic values (colors, sizes, shapes), and creates a "key" data frame containing all information needed to render the legend. For discrete aesthetics (color, shape), ggplot2 uses `guide_legend()` which creates a key with one row per value. For continuous aesthetics, `guide_colorbar()` creates a gradient bar with tick marks. When multiple aesthetics are mapped to the same variable with the same name, ggplot2 automatically merges them into a single legend.

The existing Phase 6 layout engine already reserves space for legends based on `legend.position` ("right", "left", "top", "bottom", "inside", "none") but currently sets `legend.width` and `legend.height` to 0. Phase 7 must: (1) extract guide data using ggplot2's `get_guide_data()` function, (2) compute legend dimensions in R or estimate them in JavaScript, (3) pass guide specifications through IR, (4) implement D3 legend renderers for discrete and continuous guides, and (5) integrate with the layout engine to provide actual legend dimensions.

**Primary recommendation:** Extract guide keys using `get_guide_data()` for each mapped aesthetic, serialize guide specifications to IR with breaks/labels/values/colors, implement modular D3 legend renderers (`renderDiscreteLegend()`, `renderColorbar()`) that consume guide IR, and update the layout config to compute legend dimensions from guide content.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 3.5+ | Guide training and key extraction | `get_guide_data()` provides pre-computed legend keys with breaks, labels, and aesthetic values; guide system handles all merging logic |
| D3.js | v7 | SVG legend rendering | Already integrated; provides SVG primitives (rect, circle, text) and gradients (linearGradient) for legend elements |
| gg2d3 layout.js | 0.0.1 (Phase 6) | Legend space reservation | Layout engine already supports legend positioning via `sliceSide()`; just needs actual dimensions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jsonlite | 1.x | IR serialization | Already in use; handles guide key data frames and nested lists |
| gg2d3 theme.js | 0.0.1 | Legend styling defaults | Extract legend.key.size, legend.text.size, legend.title.size from theme |
| gg2d3 constants.js | 0.0.1 | Unit conversion | Convert legend theme elements (pt to px, lines to px) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| get_guide_data() | Manual scale extraction + key building | Would require reimplementing ggplot2's guide training logic (merging, key creation, break computation); breaks "R computes, D3 renders" principle |
| D3 SVG primitives | d3-legend library | External dependency; custom rendering gives precise ggplot2 visual parity |
| R-side dimension calculation | JavaScript-only estimation | R doesn't know browser font metrics; estimation in JS is more accurate |

**Installation:**
No new dependencies required. All necessary components exist in package (ggplot2 3.5+, D3.js v7, existing modules).

## Architecture Patterns

### Recommended Legend Processing Flow
```
User Code (R)
  ↓
ggplot() + scale_color_discrete() + theme(legend.position = "right")
  ↓
ggplot_build(p)  ← Scales trained, guide data computed
  ↓
get_guide_data(p, "colour")  ← Extract pre-computed guide key
  ↓
as_d3_ir(p)      ← Serialize guide specs to IR
  ↓
IR (JSON)        ← Contains guide keys, labels, aesthetic values
  ↓
Layout Engine    ← Computes legend dimensions, reserves space
  ↓
D3 Renderer      ← Pure SVG legend rendering
```

### Pattern 1: Guide Extraction with get_guide_data()

**What:** ggplot2 3.5+ provides `get_guide_data(plot, aesthetic)` to extract trained guide keys for any aesthetic. Returns a data frame with breaks, labels, and aesthetic-specific columns (color values, size values, shape values).

**When to use:** Every legend-producing aesthetic (color, fill, size, shape, alpha).

**Example:**
```r
# In as_d3_ir.R after ggplot_build():

# Identify all aesthetics that have legends
# Check each scale for mapped aesthetics
mapped_aesthetics <- c()

# Color/fill aesthetics
if (!is.null(b$plot$scales$get_scales("colour"))) {
  mapped_aesthetics <- c(mapped_aesthetics, "colour")
}
if (!is.null(b$plot$scales$get_scales("fill"))) {
  mapped_aesthetics <- c(mapped_aesthetics, "fill")
}

# Size aesthetic
if (!is.null(b$plot$scales$get_scales("size"))) {
  mapped_aesthetics <- c(mapped_aesthetics, "size")
}

# Extract guide data for each aesthetic
guides_ir <- lapply(mapped_aesthetics, function(aes) {
  guide_key <- tryCatch(
    get_guide_data(p, aesthetic = aes),
    error = function(e) NULL
  )

  if (is.null(guide_key)) return(NULL)

  # guide_key is a data frame with columns:
  # - breaks: data values (numeric or factor levels)
  # - labels: display labels (character)
  # - colour: hex color values (for color/fill aesthetics)
  # - size: numeric size values (for size aesthetic)
  # - shape: shape codes (for shape aesthetic)
  # - .value: aesthetic value mapped from data

  # Get guide type (legend vs colorbar)
  scale_obj <- b$plot$scales$get_scales(aes)
  is_continuous <- inherits(scale_obj, "ScaleContinuous")
  guide_type <- if (is_continuous) "colorbar" else "legend"

  # Get legend title from scale
  title <- scale_obj$name %||% ""

  list(
    aesthetic = aes,
    type = guide_type,
    title = title,
    keys = as.list(guide_key)  # Convert to list for JSON
  )
})

# Filter out NULLs
guides_ir <- Filter(Negate(is.null), guides_ir)

# Add to IR
ir$guides <- guides_ir
```

**Source:** [ggplot2 get_guide_data() documentation](https://ggplot2.tidyverse.org/reference/get_guide_data.html)

### Pattern 2: Discrete Legend Rendering (guide_legend)

**What:** Discrete legends show one key per unique value (color swatches, shape symbols, size circles). Each key has a label. Keys are arranged vertically or horizontally based on legend.direction theme element.

**When to use:** Categorical color/fill scales, discrete size scales, shape scales.

**Example:**
```javascript
// In inst/htmlwidgets/modules/legend.js

/**
 * Render a discrete legend (guide_legend equivalent)
 * @param {Object} guide - Guide spec from IR
 * @param {Object} layout - Legend box from layout engine
 * @param {Object} theme - Theme accessor
 * @returns {d3.Selection} Legend SVG group
 */
function renderDiscreteLegend(svg, guide, layout, theme) {
  const g = svg.append("g")
    .attr("class", "gg2d3-legend")
    .attr("transform", `translate(${layout.x}, ${layout.y})`);

  // Theme values
  const ptToPx = window.gg2d3.constants.ptToPx;
  const keySize = ptToPx(theme.get("legend.key.size") || 12);  // 1.2 lines default
  const textSize = ptToPx(theme.get("legend.text")?.size || 8.8);
  const titleSize = ptToPx(theme.get("legend.title")?.size || 11);
  const spacing = ptToPx(2.75);  // Space between key and label

  let currentY = 0;

  // Title
  if (guide.title) {
    g.append("text")
      .attr("x", 0)
      .attr("y", currentY + titleSize * 0.8)
      .attr("font-size", titleSize)
      .attr("font-weight", "bold")
      .text(guide.title);
    currentY += titleSize + spacing;
  }

  // Keys
  guide.keys.forEach((key, i) => {
    const keyGroup = g.append("g")
      .attr("class", "legend-key")
      .attr("transform", `translate(0, ${currentY})`);

    // Draw key symbol based on aesthetic
    if (guide.aesthetic === "colour" || guide.aesthetic === "fill") {
      // Color swatch (rectangle)
      keyGroup.append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", keySize)
        .attr("height", keySize)
        .attr("fill", key.colour || key.fill || "#000000")
        .attr("stroke", theme.get("legend.key")?.colour || "none");
    } else if (guide.aesthetic === "size") {
      // Size circle
      const radius = key.size || 3;
      keyGroup.append("circle")
        .attr("cx", keySize / 2)
        .attr("cy", keySize / 2)
        .attr("r", radius)
        .attr("fill", theme.get("legend.key")?.fill || "#000000");
    } else if (guide.aesthetic === "shape") {
      // Shape symbol
      keyGroup.append("path")
        .attr("d", getShapePath(key.shape, keySize / 2, keySize / 2))
        .attr("fill", theme.get("legend.key")?.fill || "#000000");
    }

    // Label
    keyGroup.append("text")
      .attr("x", keySize + spacing)
      .attr("y", keySize / 2 + textSize * 0.3)
      .attr("font-size", textSize)
      .text(key.label || key.breaks);

    currentY += keySize + spacing;
  });

  return g;
}
```

**Source:** [D3 Graph Gallery - Building legends](https://d3-graph-gallery.com/graph/custom_legend.html), [d3-legend](https://d3-legend.susielu.com/)

### Pattern 3: Continuous Colorbar Rendering (guide_colorbar)

**What:** Continuous legends show a gradient bar with tick marks and labels at specific breaks. Uses SVG linearGradient for smooth color transitions.

**When to use:** Continuous color/fill scales (scale_color_continuous, scale_fill_gradient).

**Example:**
```javascript
// In inst/htmlwidgets/modules/legend.js

/**
 * Render a continuous colorbar (guide_colorbar equivalent)
 * @param {Object} guide - Guide spec from IR (must have min/max and color scale)
 * @param {Object} layout - Legend box from layout engine
 * @param {Object} theme - Theme accessor
 * @returns {d3.Selection} Colorbar SVG group
 */
function renderColorbar(svg, guide, layout, theme) {
  const g = svg.append("g")
    .attr("class", "gg2d3-colorbar")
    .attr("transform", `translate(${layout.x}, ${layout.y})`);

  const ptToPx = window.gg2d3.constants.ptToPx;
  const barWidth = ptToPx(theme.get("legend.key.width") || 12);  // ~18px default
  const barHeight = ptToPx(theme.get("legend.key.height") || 100); // ~200px default
  const textSize = ptToPx(theme.get("legend.text")?.size || 8.8);
  const titleSize = ptToPx(theme.get("legend.title")?.size || 11);

  let currentY = 0;

  // Title
  if (guide.title) {
    g.append("text")
      .attr("x", 0)
      .attr("y", currentY + titleSize * 0.8)
      .attr("font-size", titleSize)
      .attr("font-weight", "bold")
      .text(guide.title);
    currentY += titleSize + 4;
  }

  // Create gradient
  const gradientId = `colorbar-gradient-${Math.random().toString(36).substr(2, 9)}`;
  const defs = svg.append("defs");
  const gradient = defs.append("linearGradient")
    .attr("id", gradientId)
    .attr("x1", "0%")
    .attr("x2", "0%")
    .attr("y1", "100%")  // Bottom to top (reversed for coordinate system)
    .attr("y2", "0%");

  // Add color stops from guide keys
  const nStops = guide.keys.length;
  guide.keys.forEach((key, i) => {
    gradient.append("stop")
      .attr("offset", `${(i / (nStops - 1)) * 100}%`)
      .attr("stop-color", key.colour || key.fill);
  });

  // Draw gradient bar
  g.append("rect")
    .attr("x", 0)
    .attr("y", currentY)
    .attr("width", barWidth)
    .attr("height", barHeight)
    .attr("fill", `url(#${gradientId})`)
    .attr("stroke", theme.get("legend.frame")?.colour || "#000000")
    .attr("stroke-width", 0.5);

  // Draw tick marks and labels
  const tickLength = 3;
  guide.keys.forEach((key, i) => {
    const tickY = currentY + (i / (nStops - 1)) * barHeight;

    // Tick mark
    g.append("line")
      .attr("x1", barWidth)
      .attr("x2", barWidth + tickLength)
      .attr("y1", tickY)
      .attr("y2", tickY)
      .attr("stroke", "#000000");

    // Label
    g.append("text")
      .attr("x", barWidth + tickLength + 2)
      .attr("y", tickY + textSize * 0.3)
      .attr("font-size", textSize)
      .text(key.label);
  });

  return g;
}
```

**Source:** [Visual Cinnamon - Creating a smooth color legend with SVG gradient](https://www.visualcinnamon.com/2016/05/smooth-color-legend-d3-svg-gradient/), [D3 Observable - Color Legend](https://observablehq.com/@d3/color-legend)

### Pattern 4: Legend Merging Detection

**What:** ggplot2 merges legends when multiple aesthetics are mapped to the same variable with the same scale name. Detect merged guides by checking if multiple aesthetics share the same title.

**When to use:** When extracting guides from plots with multiple aesthetic mappings.

**Example:**
```r
# In as_d3_ir.R guide extraction logic

# After extracting all guides, check for merging
# ggplot2 merges guides with the same title (name)
guide_titles <- sapply(guides_ir, function(g) g$title)
duplicates <- duplicated(guide_titles) | duplicated(guide_titles, fromLast = TRUE)

if (any(duplicates)) {
  # Merge guides with same title
  merged_guides <- list()
  for (title in unique(guide_titles)) {
    matching <- guides_ir[guide_titles == title]
    if (length(matching) > 1) {
      # Combine aesthetics into single guide
      merged_guide <- matching[[1]]
      merged_guide$aesthetics <- sapply(matching, function(g) g$aesthetic)
      merged_guide$merged <- TRUE

      # For each key, include values for all aesthetics
      # This requires combining key data frames
      merged_keys <- matching[[1]]$keys
      for (i in 2:length(matching)) {
        # Add columns from other aesthetics
        other_keys <- matching[[i]]$keys
        for (col in names(other_keys)) {
          if (!(col %in% names(merged_keys))) {
            merged_keys[[col]] <- other_keys[[col]]
          }
        }
      }
      merged_guide$keys <- merged_keys
      merged_guides[[length(merged_guides) + 1]] <- merged_guide
    } else {
      merged_guides[[length(merged_guides) + 1]] <- matching[[1]]
    }
  }
  guides_ir <- merged_guides
}
```

**Source:** [ggplot2 book - Legend merging and splitting](https://bookdown.dongzhuoer.com/hadley/ggplot2-book/legend-merge-split), [ggGallery - Merging ggplot legends](https://genchanghsu.github.io/ggGallery/posts/2022-03-02-post-13-ggplot-legend-tips-series-no4-merging-ggplot-legends/)

### Pattern 5: Legend Dimension Estimation

**What:** Compute legend width/height before rendering so the layout engine can reserve space. Estimate based on number of keys, text width, and key size.

**When to use:** In layout config preparation, before calling calculateLayout().

**Example:**
```javascript
// In gg2d3.js draw() function, before calculateLayout()

/**
 * Estimate legend dimensions from guide specification
 * @param {Object} guide - Guide IR spec
 * @param {Object} theme - Theme accessor
 * @returns {Object} {width, height} in pixels
 */
function estimateLegendDimensions(guide, theme) {
  const ptToPx = window.gg2d3.constants.ptToPx;
  const estimateTextWidth = window.gg2d3.layout.estimateTextWidth;
  const estimateTextHeight = window.gg2d3.layout.estimateTextHeight;

  const keySize = ptToPx(theme.get("legend.key.size") || 12);
  const textSize = ptToPx(theme.get("legend.text")?.size || 8.8);
  const titleSize = ptToPx(theme.get("legend.title")?.size || 11);
  const spacing = ptToPx(2.75);

  if (guide.type === "colorbar") {
    // Colorbar: fixed bar width + max label width
    const barWidth = ptToPx(theme.get("legend.key.width") || 18);
    const barHeight = ptToPx(theme.get("legend.key.height") || 200);

    const maxLabelWidth = Math.max(
      ...guide.keys.map(k => estimateTextWidth(k.label, textSize))
    );

    const width = barWidth + 3 + maxLabelWidth + 4;  // bar + tick + label + margin
    const height = (guide.title ? titleSize + 4 : 0) + barHeight;

    return { width, height };
  } else {
    // Discrete legend: key + spacing + max label width
    const maxLabelWidth = Math.max(
      ...guide.keys.map(k => estimateTextWidth(k.label || k.breaks, textSize))
    );

    const width = keySize + spacing + maxLabelWidth + 4;
    const height = (guide.title ? titleSize + spacing : 0) +
                   (guide.keys.length * (keySize + spacing));

    return { width, height };
  }
}

// Use in layout config
const legendDimensions = ir.guides && ir.guides.length > 0
  ? estimateLegendDimensions(ir.guides[0], theme)
  : { width: 0, height: 0 };

const layoutConfig = {
  // ... existing config ...
  legend: {
    position: (ir.legend && ir.legend.position) || "none",
    width: legendDimensions.width,
    height: legendDimensions.height
  }
};
```

**Source:** Phase 6 layout engine estimateTextWidth/Height functions, ggplot2 theme defaults

### Anti-Patterns to Avoid
- **Building legend keys manually:** Don't parse scale domains and create keys yourself—use `get_guide_data()` which handles all edge cases (merging, transformations, breaks computation).
- **Hardcoding legend spacing:** All legend dimensions should come from theme elements (legend.key.size, legend.text.size, etc.), not magic numbers.
- **Rendering legends before layout calculation:** Legends must be positioned by the layout engine, not placed with ad-hoc coordinates.
- **JavaScript-side guide training:** Never compute breaks, map colors, or generate keys in JavaScript—this is ggplot2's responsibility.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Guide key extraction | Manual scale$get_breaks() + mapping logic | `get_guide_data(plot, aesthetic)` | Handles guide training, merging, break computation, label formatting, and aesthetic value mapping automatically |
| Legend merging | Manual duplicate detection + key combining | ggplot2's built-in guide merging (same scale name) | ggplot2 merges guides with same title; already computed in guide training |
| SVG gradients | Canvas-based gradients or manual color interpolation | SVG linearGradient with stop elements | SVG gradients are native, hardware-accelerated, and scale-independent |
| Legend positioning | Custom coordinate calculation | Phase 6 layout engine sliceSide() | Layout engine handles all positioning logic, coord_fixed adjustments, and space reservation |

**Key insight:** The legend system is pure coordination—ggplot2 computes guide data, the layout engine reserves space, and D3 renders SVG. Don't replicate any of these responsibilities.

## Common Pitfalls

### Pitfall 1: Missing get_guide_data() in Older ggplot2 Versions
**What goes wrong:** `get_guide_data()` was added in ggplot2 3.5.0 (Feb 2024). Older versions don't have this function, causing errors.
**Why it happens:** Package dependencies allow ggplot2 < 3.5.0.
**How to avoid:** Require ggplot2 >= 3.5.0 in DESCRIPTION. Add version check with informative error message if get_guide_data() doesn't exist.
**Warning signs:** `Error: could not find function "get_guide_data"` when rendering legends.

### Pitfall 2: Legend Space Reservation Without Content
**What goes wrong:** Layout engine reserves space for legend but no legend is actually rendered, creating empty gap.
**Why it happens:** Legend dimensions computed from IR guides, but legend renderer not called or fails.
**How to avoid:** Always check `ir.guides && ir.guides.length > 0` before computing dimensions. Default to `{width: 0, height: 0}` when no guides exist.
**Warning signs:** Large empty space on right/left/top/bottom of plot with `legend.position` set.

### Pitfall 3: Mismatched Legend Dimensions
**What goes wrong:** Estimated legend dimensions in layout config don't match actual rendered legend size, causing overflow or excess whitespace.
**Why it happens:** Text width estimation inaccurate for long labels or specific fonts.
**How to avoid:** Use conservative estimates (add extra padding). Consider optional DOM-based measurement refinement after initial render.
**Warning signs:** Legend text cut off or large unused space in legend area.

### Pitfall 4: Continuous Scale Without Enough Keys
**What goes wrong:** Colorbar gradient has too few color stops, creating banding instead of smooth gradient.
**Why it happens:** `get_guide_data()` returns breaks (e.g., 5 values), but smooth gradient needs more stops.
**How to avoid:** For colorbars, interpolate additional color stops between breaks (e.g., 20-50 stops for smooth gradient). Use D3 scale to compute intermediate colors.
**Warning signs:** Stepped/banded appearance in continuous colorbars instead of smooth gradient.

### Pitfall 5: Legend Merging Not Detected
**What goes wrong:** Multiple legends rendered for aesthetics that should be merged (e.g., color and shape both mapped to same variable).
**Why it happens:** Guide extraction doesn't check for duplicate titles or merged guides.
**How to avoid:** Check for duplicate guide titles after extraction. ggplot2 merges guides automatically, so duplicate titles indicate merged guides—combine their aesthetic values into single guide IR.
**Warning signs:** Two separate legends for color and shape when they should be one combined legend.

### Pitfall 6: Inside Legend Positioning
**What goes wrong:** `legend.position = "inside"` with coordinates not handled by layout engine.
**Why it happens:** Layout engine's sliceSide() only handles edge positions (right/left/top/bottom), not numeric coordinates.
**How to avoid:** For "inside" position, layout engine should not reserve space—legend overlays panel. Use legend.position.inside coordinates directly for legend positioning.
**Warning signs:** Inside legend either not rendered or incorrectly positioned outside panel.

## Code Examples

Verified patterns from official sources:

### Extracting Guide Data in R
```r
# Source: https://ggplot2.tidyverse.org/reference/get_guide_data.html

library(ggplot2)

# Create a plot with color mapping
p <- ggplot(mpg, aes(displ, hwy, color = drv)) +
  geom_point() +
  scale_color_discrete(name = "Drive Type")

# Extract guide data for color aesthetic
guide_data <- get_guide_data(p, aesthetic = "colour")

# guide_data is a data frame:
# > guide_data
#   .value .label colour
# 1      4      4 #F8766D
# 2      f      f #00BA38
# 3      r      r #619CFF

# Columns:
# - .value: original data values
# - .label: display labels (can be customized with labels = parameter)
# - colour: hex color values mapped from scale
```

### SVG Gradient for Colorbar
```javascript
// Source: https://www.visualcinnamon.com/2016/05/smooth-color-legend-d3-svg-gradient/

// Create gradient definition
const defs = svg.append("defs");
const linearGradient = defs.append("linearGradient")
  .attr("id", "colorbar-gradient")
  .attr("x1", "0%")
  .attr("y1", "100%")  // Bottom
  .attr("x2", "0%")
  .attr("y2", "0%");   // Top

// Add color stops (example: viridis-like scale)
const colors = ["#440154", "#31688e", "#35b779", "#fde724"];
colors.forEach((color, i) => {
  linearGradient.append("stop")
    .attr("offset", `${(i / (colors.length - 1)) * 100}%`)
    .attr("stop-color", color);
});

// Apply gradient to rectangle
svg.append("rect")
  .attr("x", 10)
  .attr("y", 10)
  .attr("width", 20)
  .attr("height", 200)
  .style("fill", "url(#colorbar-gradient)");
```

### Legend Position in ggplot2
```r
# Source: https://ggplot2.tidyverse.org/reference/theme.html

# Edge positions
p + theme(legend.position = "right")   # Default
p + theme(legend.position = "left")
p + theme(legend.position = "top")
p + theme(legend.position = "bottom")
p + theme(legend.position = "none")    # Hide legend

# Inside positioning (numeric coordinates)
# c(0, 0) = bottom-left, c(1, 1) = top-right
p + theme(
  legend.position = c(0.95, 0.05),      # Bottom-right corner
  legend.justification = c("right", "bottom")  # Anchor point
)

# ggplot2 3.5.0+ new argument
p + theme(
  legend.position = "inside",
  legend.position.inside = c(0.95, 0.05)
)
```

### D3 Discrete Legend
```javascript
// Source: https://d3-graph-gallery.com/graph/custom_legend.html

// Data for legend keys
const legendData = [
  { label: "Category A", color: "#e41a1c" },
  { label: "Category B", color: "#377eb8" },
  { label: "Category C", color: "#4daf4a" }
];

// Create legend group
const legend = svg.append("g")
  .attr("class", "legend")
  .attr("transform", "translate(500, 20)");

// Add legend items
const legendItems = legend.selectAll(".legend-item")
  .data(legendData)
  .enter()
  .append("g")
  .attr("class", "legend-item")
  .attr("transform", (d, i) => `translate(0, ${i * 25})`);

// Color squares
legendItems.append("rect")
  .attr("x", 0)
  .attr("y", 0)
  .attr("width", 18)
  .attr("height", 18)
  .attr("fill", d => d.color);

// Labels
legendItems.append("text")
  .attr("x", 24)
  .attr("y", 9)
  .attr("dy", "0.35em")
  .text(d => d.label);
```

### Checking for Merged Guides
```r
# Source: https://bookdown.dongzhuoer.com/hadley/ggplot2-book/legend-merge-split

# Guides merge when mapped to same variable with same name
p1 <- ggplot(mpg, aes(displ, hwy, color = drv, shape = drv)) +
  geom_point() +
  scale_color_discrete(name = "Drive") +
  scale_shape_discrete(name = "Drive")
# Result: Single merged legend showing both color and shape

# Guides split when names differ
p2 <- ggplot(mpg, aes(displ, hwy, color = drv, shape = drv)) +
  geom_point() +
  scale_color_discrete(name = "Drive Type") +
  scale_shape_discrete(name = "Drive System")
# Result: Two separate legends

# Detect in R:
guide_colour <- get_guide_data(p1, "colour")
guide_shape <- get_guide_data(p1, "shape")
# Both will have same keys if merged
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual legend grob extraction | `get_guide_data()` function | ggplot2 3.5.0 (Feb 2024) | Clean API for extracting trained guide keys; no need to parse ggplot_gtable internals |
| Separate guide styling arguments | Theme-only guide styling | ggplot2 3.5.0 (Feb 2024) | All guide styling through `theme()` arguments; guide functions focus on structure not style |
| legend.position numeric vector | legend.position.inside argument | ggplot2 3.5.0 (Feb 2024) | Clearer distinction between edge and inside positioning |
| Custom D3 legend libraries | Native SVG primitives + gradients | Ongoing | Modern browsers fully support SVG gradients; no external legend library needed |

**Deprecated/outdated:**
- **guide_legend() style arguments:** In ggplot2 3.5.0+, style arguments like `theme` in guide functions are soft-deprecated. Use `theme(legend.key.size = ..., legend.text = ...)` instead.
- **Manual gtable extraction for legends:** Before `get_guide_data()`, extracting legend info required parsing `ggplot_gtable()$grobs`. This is no longer necessary.
- **d3-legend dependency:** While d3-legend is a good library, gg2d3 needs pixel-perfect ggplot2 parity, which requires custom rendering.

## Open Questions

1. **Should legends support legend.direction (horizontal vs vertical)?**
   - What we know: ggplot2 supports `legend.direction = "horizontal"` which arranges keys in a row instead of column. Layout and rendering logic differs significantly.
   - What's unclear: Whether Phase 7 scope includes horizontal legends or defers to later phase.
   - Recommendation: Start with vertical legends only (default). Horizontal layout is straightforward extension but requires separate rendering logic. Add in Phase 7 plan 07-03 if time permits, otherwise defer.

2. **How to handle legend.position = "inside" coordinates?**
   - What we know: Inside positioning uses panel-relative coordinates c(x, y) where 0,0 is bottom-left and 1,1 is top-right. Layout engine doesn't reserve space for inside legends.
   - What's unclear: Whether inside legends are Phase 7 scope or deferred.
   - Recommendation: Phase 7 should support edge positions (right/left/top/bottom) only. Inside positioning requires different layout logic (overlay, not space reservation) and is less commonly used. Defer to future enhancement.

3. **Should legend dimensions be computed in R or JavaScript?**
   - What we know: R can estimate based on guide key count and default theme sizes. JavaScript can measure actual text widths with DOM.
   - What's unclear: Which approach gives better accuracy vs. simplicity tradeoff.
   - Recommendation: Compute in JavaScript using estimation (no DOM measurement). R doesn't know browser font metrics. JavaScript estimation with padding (Phase 6 pattern) is accurate enough and doesn't require two-pass rendering.

4. **How to interpolate colors for smooth colorbar gradients?**
   - What we know: `get_guide_data()` returns breaks (typically 5-10 values). Smooth gradients need more color stops (20-50).
   - What's unclear: Whether to interpolate in R or JavaScript, and which interpolation method (linear, spline, D3 scale).
   - Recommendation: Interpolate in JavaScript using D3 scale. Create continuous D3 scale from IR scale descriptor, sample at regular intervals (e.g., 30 stops), and use those colors for gradient. This reuses existing scale creation logic.

## Sources

### Primary (HIGH confidence)
- **ggplot2 official documentation:**
  - [get_guide_data() reference](https://ggplot2.tidyverse.org/reference/get_guide_data.html) - Extract guide keys from plot
  - [guide_legend() reference](https://ggplot2.tidyverse.org/reference/guide_legend.html) - Discrete legend specification
  - [guide_colourbar() reference](https://ggplot2.tidyverse.org/reference/guide_colourbar.html) - Continuous colorbar specification
  - [ggplot2 3.5.0 blog post](https://tidyverse.org/blog/2024/02/ggplot2-3-5-0-legends/) - New legend features and changes
  - [ggplot2 book - Scales and guides chapter](https://ggplot2-book.org/scales-guides.html) - Guide system architecture
  - [ggplot2 book - Legend merging](https://bookdown.dongzhuoer.com/hadley/ggplot2-book/legend-merge-split) - How guide merging works
- **gg2d3 codebase (inspected directly):**
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/layout.js` - Layout engine with legend space reservation (lines 232-240, 315-333)
  - `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` - Current aesthetic extraction (lines 380-428)
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/scales.js` - D3 scale factory for mapping aesthetics

### Secondary (MEDIUM confidence)
- **D3.js legend resources:**
  - [Visual Cinnamon - SVG gradient legends](https://www.visualcinnamon.com/2016/05/smooth-color-legend-d3-svg-gradient/) - Best practices for continuous colorbars
  - [D3 Graph Gallery - Building legends](https://d3-graph-gallery.com/graph/custom_legend.html) - Discrete legend patterns
  - [D3 Observable - Color Legend](https://observablehq.com/@d3/color-legend) - Reference implementation
  - [d3-legend by Susie Lu](https://d3-legend.susielu.com/) - Community standard (not used but informative)
- **Community guides:**
  - [ggGallery - Merging legends](https://genchanghsu.github.io/ggGallery/posts/2022-03-02-post-13-ggplot-legend-tips-series-no4-merging-ggplot-legends/) - Practical examples of guide merging

### Tertiary (LOW confidence)
- **Text dimension estimation:** Using 0.6x font size for average character width (from Phase 6 research). Should be validated for legend labels which may be longer than axis tick labels.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ggplot2 3.5+ has all needed functions (`get_guide_data()`), D3.js v7 has SVG gradient support, layout engine already integrated
- Architecture: HIGH - Guide extraction verified via R console, D3 patterns verified via official examples and community resources
- Pitfalls: HIGH - get_guide_data() version requirement is documented, legend space reservation is current gap in codebase
- R-side extraction: HIGH - Verified get_guide_data() output structure and guide merging behavior via R console

**Research date:** 2026-02-09
**Valid until:** 60 days (stable domain - ggplot2 guide system established since 3.5.0; D3 SVG APIs stable)

**Sources:**
- [Continuous colour bar guide — guide_colourbar • ggplot2](https://ggplot2.tidyverse.org/reference/guide_colourbar.html)
- [ggplot2 3.5.0: Legends - Tidyverse](https://tidyverse.org/blog/2024/02/ggplot2-3-5-0-legends/)
- [Legend guide — guide_legend • ggplot2](https://ggplot2.tidyverse.org/reference/guide_legend.html)
- [Extract tick information from guides — get_guide_data • ggplot2](https://ggplot2.tidyverse.org/reference/get_guide_data.html)
- [14.5 Legend merging and splitting | ggplot2](https://bookdown.dongzhuoer.com/hadley/ggplot2-book/legend-merge-split)
- [14 Scales and guides – ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/scales-guides.html)
- [Creating a smooth color legend with an SVG gradient | Visual Cinnamon](https://www.visualcinnamon.com/2016/05/smooth-color-legend-d3-svg-gradient/)
- [D3 Graph Gallery - Building legends in d3.js](https://d3-graph-gallery.com/graph/custom_legend.html)
- [Color Legend / D3 | Observable](https://observablehq.com/@d3/color-legend)
- [D3 legend - Susie Lu](https://d3-legend.susielu.com/)
- [ggplot2 legend position documentation](https://ggplot2.tidyverse.org/reference/theme.html)
