# Phase 3: Coordinate Systems - Research

**Researched:** 2026-02-08
**Domain:** ggplot2 coordinate systems, D3.js coordinate transformations, SVG aspect ratio control
**Confidence:** HIGH

## Summary

Phase 3 addresses two critical coordinate system features: fixing `coord_flip()` axis positioning and implementing `coord_fixed()` aspect ratio control. The current codebase has a broken `coord_flip()` implementation that reverses scale ranges but fails to reposition axes correctly. Research reveals that coordinate flipping is a **layout transformation**, not a scale transformation—it requires repositioning axis groups, updating theme element mappings, and coordinating grid line orientations.

`coord_fixed()` requires implementing aspect ratio constraints that persist during widget resize, which htmlwidgets and D3.js support through SVG viewBox and preserveAspectRatio attributes or programmatic redraw approaches.

**Primary recommendation:** Implement coord transformations as first-class layout operations in the D3 rendering pipeline. For coord_flip, swap axis generator functions and their physical positions while maintaining theme element semantics. For coord_fixed, add aspect ratio constraints via SVG viewBox or constrained panel dimensions.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 3.5.x | Coordinate system reference | Defines authoritative coord behavior and theme element mappings |
| D3.js | v7 | SVG rendering and axis generation | Already vendored; axis generators support flexible positioning |
| htmlwidgets | 1.6.x | R-to-JavaScript bridge with sizing framework | Provides resize hooks and dimension management |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grid (R) | Base R | Unit conversion for aspect ratios | When translating ggplot2's physical size units to pixel dimensions |
| SVG viewBox | SVG 1.1 | Aspect ratio preservation | For coord_fixed resize behavior without redrawing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| viewBox for coord_fixed | Programmatic redraw on resize | viewBox scales all elements (including text); redraw maintains consistent sizes but is more complex |
| Axis repositioning | CSS transforms | CSS transforms break D3 event coordinates and axis label positioning |

**Installation:**
No new dependencies required. All necessary libraries are already in the project.

## Architecture Patterns

### Recommended IR Structure
```
ir.coord = {
  type: "cartesian",      // cartesian, flip, fixed, trans, polar
  flip: false,            // boolean for coord_flip
  ratio: null,            // aspect ratio for coord_fixed (y/x)
  xlim: null,             // coord limits (if specified)
  ylim: null
}
```

### Pattern 1: Coordinate-Aware Scale Creation

**What:** Create scales with ranges appropriate for the coordinate system before layout
**When to use:** During scale factory initialization in D3 renderer
**Example:**
```javascript
// Source: Current codebase (inst/htmlwidgets/gg2d3.js lines 56-58)
const flip = !!(ir.coord && ir.coord.flip);
let xScale = createScale(ir.scales && ir.scales.x, flip ? [h, 0] : [0, w]);
let yScale = createScale(ir.scales && ir.scales.y, flip ? [0, w] : [h, 0]);
```
**Issue:** This swaps ranges but doesn't reposition axes—axes remain at bottom (x) and left (y).

### Pattern 2: Axis Position Dispatch

**What:** Select axis generator and position based on coordinate system
**When to use:** When rendering axes after data layers
**Example:**
```javascript
// Correct coord_flip implementation pattern
if (flip) {
  // After flip: x-scale controls vertical visual axis (should be on LEFT)
  // y-scale controls horizontal visual axis (should be on BOTTOM)
  const leftAxis = g.append("g").call(d3.axisLeft(xScale));
  const bottomAxis = g.append("g")
    .attr("transform", `translate(0,${h})`)
    .call(d3.axisBottom(yScale));
} else {
  // Normal: x-axis at bottom, y-axis at left
  const bottomAxis = g.append("g")
    .attr("transform", `translate(0,${h})`)
    .call(d3.axisBottom(xScale));
  const leftAxis = g.append("g").call(d3.axisLeft(yScale));
}
```

### Pattern 3: Theme Element Semantic Mapping

**What:** Map theme elements to visual axes based on coordinate system
**When to use:** When applying theme styling to axis elements
**Example:**
```javascript
// ggplot2 behavior: axis.text.x always refers to the X aesthetic (horizontal in normal coords)
// After coord_flip, axis.text.x controls the LEFT visual axis (because x aesthetic is now vertical)
if (flip) {
  // x theme elements → left visual axis
  applyAxisStyle(leftAxis, theme.get("axis.text.x"), theme.get("axis.line.x"));
  // y theme elements → bottom visual axis
  applyAxisStyle(bottomAxis, theme.get("axis.text.y"), theme.get("axis.line.y"));
} else {
  // Normal mapping
  applyAxisStyle(bottomAxis, theme.get("axis.text.x"), theme.get("axis.line.x"));
  applyAxisStyle(leftAxis, theme.get("axis.text.y"), theme.get("axis.line.y"));
}
```

**Critical insight:** Theme elements in ggplot2 follow **aesthetic semantics**, not visual position. After coord_flip, `axis.text.x` refers to the x-aesthetic's axis (now vertical), not the bottom physical axis.

### Pattern 4: Aspect Ratio with viewBox

**What:** Use SVG viewBox to maintain aspect ratio during resize
**When to use:** For coord_fixed with simple plots where text scaling is acceptable
**Example:**
```javascript
// Source: D3 responsive patterns (see sources)
const ratio = ir.coord.ratio || 1; // y/x
const viewBoxWidth = w + pad.left + pad.right;
const viewBoxHeight = (w / ratio) + pad.top + pad.bottom; // Height constrained by ratio

root.attr("viewBox", `0 0 ${viewBoxWidth} ${viewBoxHeight}`)
    .attr("preserveAspectRatio", "xMidYMid meet");
```

### Pattern 5: Aspect Ratio with Constrained Dimensions

**What:** Calculate panel dimensions constrained by aspect ratio
**When to use:** For coord_fixed when text size must remain constant (preferred for data viz)
**Example:**
```javascript
// Calculate constrained panel dimensions
const ratio = ir.coord.ratio || 1; // y/x ratio
const availableWidth = innerW - pad.left - pad.right;
const availableHeight = innerH - pad.top - pad.bottom;

let w, h;
if (availableHeight / availableWidth > ratio) {
  // Height-constrained
  w = availableWidth;
  h = w * ratio;
} else {
  // Width-constrained
  h = availableHeight;
  w = h / ratio;
}

// Center panel in available space
const xOffset = pad.left + (availableWidth - w) / 2;
const yOffset = pad.top + (availableHeight - h) / 2;
const g = root.append("g").attr("transform", `translate(${xOffset},${yOffset})`);
```

### Anti-Patterns to Avoid

- **Axis swapping via CSS transforms:** Breaks D3 event coordinates and complicates label positioning
- **Scale transformation for coordinate flip:** `scale_x_reverse()` flips one axis direction; `coord_flip()` is a layout transformation affecting axes, grids, and all geoms
- **Hard-coded axis positions:** Always derive axis positions and generators from coord type
- **Theme element confusion:** Don't assume `axis.text.x` controls the bottom visual axis—it controls the x-aesthetic's axis, which moves with coord_flip

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Aspect ratio maintenance | Custom resize logic | SVG viewBox + preserveAspectRatio | Browser-native, handles all edge cases including rotation |
| Axis label rotation | Manual trigonometry | D3 axis generator's orient parameter | Handles tick positioning, label collision, text anchoring |
| Grid line positioning after flip | Conditional x/y logic | Semantic orientation ("vertical"/"horizontal") | Grids align with visual direction, not data aesthetic |

**Key insight:** Coordinate transformations affect the entire rendering pipeline—scales, axes, grids, geoms, and theme elements. Treating coord as a scale operation creates hard-to-debug layout issues.

## Common Pitfalls

### Pitfall 1: coord_flip Scale Swap Without Axis Repositioning

**What goes wrong:** Axes appear on wrong sides—x-axis at bottom when it should be left, y-axis at left when it should be bottom

**Why it happens:** Developers treat coord_flip as "swap x and y scales" when it's actually "swap visual axis positions AND maintain theme element semantics." Current codebase reverses scale ranges but continues drawing bottom x-axis and left y-axis.

**How to avoid:**
- After detecting flip, swap BOTH scale generators AND axis positions
- Use `d3.axisLeft(xScale)` for x-aesthetic (vertical visual axis)
- Use `d3.axisBottom(yScale)` for y-aesthetic (horizontal visual axis)
- Grid lines must also flip: x-breaks draw horizontal lines, y-breaks draw vertical lines

**Warning signs:**
- Axes on wrong sides but data appears correct
- Grid lines perpendicular to expected direction
- Axis labels pointing wrong way
- Theme elements applied to wrong visual axes

**Source:** Official ggplot2 docs confirm this is a known issue that was fixed in development versions. See [GitHub Issue #1784](https://github.com/tidyverse/ggplot2/issues/1784).

### Pitfall 2: Theme Element Visual Position Confusion

**What goes wrong:** After coord_flip, attempting to style "the bottom axis" with `axis.text.y` because y is now at bottom

**Why it happens:** Misunderstanding ggplot2's theme semantics. Theme elements follow **aesthetic naming**, not visual position.

**How to avoid:**
- `axis.text.x` always styles the x-aesthetic's axis (bottom in normal, LEFT in flipped)
- `axis.text.y` always styles the y-aesthetic's axis (left in normal, BOTTOM in flipped)
- In D3 renderer, apply theme elements based on which scale is used, not axis position:
  ```javascript
  // leftAxis uses xScale after flip → apply axis.text.x theme
  applyAxisStyle(leftAxis, theme.get("axis.text.x"), ...);
  ```

**Warning signs:**
- Axis text size/color wrong after coord_flip
- User's theme customizations not appearing
- x-axis theme applying to y-axis visually

**Source:** [ggplot2 coord_flip reference](https://ggplot2.tidyverse.org/reference/coord_flip.html): "the x-axis theme settings, such as axis.line.x apply to the horizontal direction, while the y-axis theme settings, such as axis.text.y apply to the vertical direction."

### Pitfall 3: Aspect Ratio Text Scaling

**What goes wrong:** When using viewBox for coord_fixed, text size changes with plot dimensions

**Why it happens:** viewBox scales ALL elements uniformly, including fonts. This differs from ggplot2 where text remains constant size.

**How to avoid:**
- For data visualizations (gg2d3 use case), prefer constrained dimension approach
- Calculate panel dimensions that respect aspect ratio, center panel in available space
- Text elements use absolute pixel sizes, remain readable at all dimensions

**Warning signs:**
- Axis labels too small/large after resize
- Title text scales unexpectedly
- Tick labels overlap or disappear

**Source:** Multiple D3.js tutorials note this tradeoff. See [viewBox vs. redraw comparison](https://maheshsenniappan.medium.com/responsive-svg-charts-viewbox-may-not-be-the-answer-aaf9c9bc4ca2).

### Pitfall 4: Grid Line Orientation After Flip

**What goes wrong:** Grid lines remain horizontal/vertical in data coordinates when they should flip to visual coordinates

**Why it happens:** Grid drawing logic uses data breaks without considering coordinate transformation

**How to avoid:**
- Grid orientation should be based on visual axis, not data aesthetic
- After coord_flip: x-breaks draw HORIZONTAL lines (because x-scale controls vertical axis)
- After coord_flip: y-breaks draw VERTICAL lines (because y-scale controls horizontal axis)
- Current code at `theme.js:138-167` draws based on orientation parameter—ensure this is set correctly for coord type

**Warning signs:**
- Horizontal grid lines don't align with x-axis ticks after flip
- Vertical grid lines misaligned
- Grid appears "sideways"

### Pitfall 5: coord_fixed vs. Scale Limits Confusion

**What goes wrong:** User sets `coord_fixed(xlim = c(0, 10))` but data outside range disappears

**Why it happens:** Coordinate system limits perform **clipping** after statistical transformations, different from scale limits which affect stat computation

**How to avoid:**
- Extract `xlim`/`ylim` from IR coord object (not scale object)
- Apply as clip-path in SVG after rendering geoms
- Scale domains control data-to-position mapping; coord limits control visible region

**Warning signs:**
- Data points missing at plot edges
- Lines cut off abruptly at boundaries
- Different behavior than scale_x_continuous(limits = ...)

**Source:** [ggplot2 coord_cartesian reference](https://ggplot2.tidyverse.org/reference/coord_cartesian.html): "Setting limits on the coordinate system will zoom the plot (like you're looking at it with a magnifying glass), and will not change the underlying data like setting limits on a scale will."

## Code Examples

Verified patterns from official sources:

### coord_flip Complete Implementation
```javascript
// Source: Synthesized from ggplot2 coord_flip.html and D3 axis docs
function renderAxes(g, xScale, yScale, ir, theme, w, h) {
  const flip = !!(ir.coord && ir.coord.flip);

  // Get breaks for tick values
  const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
  const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;

  if (flip) {
    // After flip:
    // - xScale (x-aesthetic) controls LEFT visual axis (vertical)
    // - yScale (y-aesthetic) controls BOTTOM visual axis (horizontal)

    const leftAxisGen = d3.axisLeft(xScale);
    const bottomAxisGen = d3.axisBottom(yScale);

    if (xBreaks) leftAxisGen.tickValues(xBreaks);
    if (yBreaks) bottomAxisGen.tickValues(yBreaks);

    const leftAxis = g.append("g").attr("class", "axis-x").call(leftAxisGen);
    const bottomAxis = g.append("g")
      .attr("class", "axis-y")
      .attr("transform", `translate(0,${h})`)
      .call(bottomAxisGen);

    // Theme elements follow aesthetic semantics
    applyAxisStyle(leftAxis, theme.get("axis.text.x"), theme.get("axis.line.x"));
    applyAxisStyle(bottomAxis, theme.get("axis.text.y"), theme.get("axis.line.y"));

    return { leftAxis, bottomAxis };
  } else {
    // Normal coordinates
    const bottomAxisGen = d3.axisBottom(xScale);
    const leftAxisGen = d3.axisLeft(yScale);

    if (xBreaks) bottomAxisGen.tickValues(xBreaks);
    if (yBreaks) leftAxisGen.tickValues(yBreaks);

    const bottomAxis = g.append("g")
      .attr("class", "axis-x")
      .attr("transform", `translate(0,${h})`)
      .call(bottomAxisGen);
    const leftAxis = g.append("g").attr("class", "axis-y").call(leftAxisGen);

    applyAxisStyle(bottomAxis, theme.get("axis.text.x"), theme.get("axis.line.x"));
    applyAxisStyle(leftAxis, theme.get("axis.text.y"), theme.get("axis.line.y"));

    return { leftAxis, bottomAxis };
  }
}
```

### coord_flip Grid Rendering
```javascript
// Source: Synthesized from theme.js drawGrid function and coord_flip logic
function renderGrid(g, xScale, yScale, ir, theme, w, h) {
  const flip = !!(ir.coord && ir.coord.flip);
  const gridMajor = theme.get("grid.major");

  if (!gridMajor || gridMajor.type === "blank") return;

  const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
  const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;

  if (flip) {
    // After flip: x-breaks are on vertical axis → draw HORIZONTAL lines
    //             y-breaks are on horizontal axis → draw VERTICAL lines
    drawGridLines(g, xScale, "horizontal", gridMajor, xBreaks, w, h);
    drawGridLines(g, yScale, "vertical", gridMajor, yBreaks, w, h);
  } else {
    // Normal: x-breaks → vertical lines, y-breaks → horizontal lines
    drawGridLines(g, xScale, "vertical", gridMajor, xBreaks, w, h);
    drawGridLines(g, yScale, "horizontal", gridMajor, yBreaks, w, h);
  }
}

function drawGridLines(g, scale, orientation, spec, breaks, w, h) {
  if (!breaks) return;
  const isBand = typeof scale.bandwidth === "function";

  breaks.forEach(tick => {
    const pos = isBand ? scale(tick) + scale.bandwidth() / 2 : scale(tick);

    if (orientation === "vertical") {
      g.insert("line", ".axis")
        .attr("x1", pos).attr("x2", pos)
        .attr("y1", 0).attr("y2", h)
        .attr("stroke", spec.colour || "white")
        .attr("stroke-width", spec.linewidth || 1.89);
    } else {
      g.insert("line", ".axis")
        .attr("x1", 0).attr("x2", w)
        .attr("y1", pos).attr("y2", pos)
        .attr("stroke", spec.colour || "white")
        .attr("stroke-width", spec.linewidth || 1.89);
    }
  });
}
```

### coord_fixed with Constrained Dimensions
```javascript
// Source: Synthesized from ggplot2 coord_fixed.html and htmlwidgets sizing patterns
function calculateConstrainedPanelSize(innerW, innerH, pad, ratio) {
  // ratio is y/x (e.g., ratio=1 means square, ratio=2 means height is 2x width)
  if (!ratio || ratio <= 0) {
    // No constraint, use full available space
    return {
      w: innerW - pad.left - pad.right,
      h: innerH - pad.top - pad.bottom,
      offsetX: pad.left,
      offsetY: pad.top
    };
  }

  const availableWidth = innerW - pad.left - pad.right;
  const availableHeight = innerH - pad.top - pad.bottom;

  // Determine constraining dimension
  let w, h;
  if (availableHeight / availableWidth > ratio) {
    // Width-limited: use full width, constrain height
    w = availableWidth;
    h = w * ratio;
  } else {
    // Height-limited: use full height, constrain width
    h = availableHeight;
    w = h / ratio;
  }

  // Center panel in available space
  const offsetX = pad.left + (availableWidth - w) / 2;
  const offsetY = pad.top + (availableHeight - h) / 2;

  return { w, h, offsetX, offsetY };
}

// Usage in draw function:
function draw(ir, elW, elH) {
  const ratio = ir.coord && ir.coord.ratio;
  const { w, h, offsetX, offsetY } = calculateConstrainedPanelSize(
    elW, elH, pad, ratio
  );

  const g = root.append("g").attr("transform", `translate(${offsetX},${offsetY})`);
  // ... rest of rendering
}
```

### htmlwidgets Resize Hook for coord_fixed
```javascript
// Source: htmlwidgets sizing vignette (https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_sizing.html)
HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function(el, width, height) {
    let currentIR = null;

    function draw(ir, elW, elH) {
      // Main rendering logic with coord_fixed support
      // ... (as shown above)
    }

    return {
      renderValue: function(x) {
        currentIR = x.ir;
        draw(currentIR, width, height);
      },

      resize: function(newWidth, newHeight) {
        if (currentIR) {
          // Redraw with new dimensions, maintaining aspect ratio
          d3.select(el).selectAll("*").remove();
          draw(currentIR, newWidth, newHeight);
        }
      }
    };
  }
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| coord_flip swaps aesthetics before rendering | coord_flip is layout transformation preserving aesthetic semantics | ggplot2 v2.2.0 (2016) | Theme elements follow aesthetic names, not visual position |
| viewBox-only responsive charts | viewBox OR programmatic redraw with size constraints | D3 v5+ era (~2018) | Data viz can maintain readable text at all sizes |
| Manual axis positioning | Coordinate-aware rendering pipeline | Industry pattern (~2020+) | Coordinate type drives entire layout, not just scales |

**Deprecated/outdated:**
- **coord_trans()**: Deprecated in favor of `coord_transform()` (still works but emits warnings)
- **Aesthetic swapping for horizontal plots**: Use `coord_flip()` instead of manually mapping x=y, y=x (preserves stat computations on correct axes)

## Open Questions

1. **coord_trans() Support Timeline**
   - What we know: IR already detects and warns about coord_trans (as_d3_ir.R:8-16)
   - What's unclear: Priority for Phase 3 vs. later? coord_trans is niche (scale transforms cover most cases)
   - Recommendation: Defer to Phase 4+. Scale transformations (log10, sqrt) provide equivalent visual output for 95% of use cases.

2. **coord_polar Scope**
   - What we know: ROADMAP lists coord_polar as Phase 4+ (low priority)
   - What's unclear: Whether IR should include coord.type = "polar" field now for future-proofing
   - Recommendation: Add `coord.type` field to IR now (defaults to "cartesian"). Prepare for future without adding complexity.

3. **Aspect Ratio Persistence Across Sessions**
   - What we know: htmlwidgets can store state between rerenders
   - What's unclear: Whether coord_fixed ratio should persist if user resizes RStudio viewer
   - Recommendation: Always recalculate from IR on each render. Don't cache aspect ratio state.

4. **coord_equal Synonym**
   - What we know: ggplot2 provides `coord_equal()` as synonym for `coord_fixed(ratio = 1)`
   - What's unclear: Whether R layer should normalize this to coord_fixed in IR or pass through
   - Recommendation: Normalize in R layer. IR should only contain `coord.ratio = 1`, not separate type.

## Sources

### Primary (HIGH confidence)
- [ggplot2 coord_flip reference](https://ggplot2.tidyverse.org/reference/coord_flip.html) - Axis positioning and theme element behavior
- [ggplot2 coord_fixed reference](https://ggplot2.tidyverse.org/reference/coord_fixed.html) - Aspect ratio implementation
- [ggplot2 Book Chapter 15: Coordinate Systems](https://ggplot2-book.org/coord.html) - Coordinate transformation architecture
- [ggplot2 Issue #1784: Coord_flip axis side bug](https://github.com/tidyverse/ggplot2/issues/1784) - Known coord_flip positioning issue
- [htmlwidgets Sizing Vignette](https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_sizing.html) - Resize hooks and dimension management
- [D3.js Axis Reference](https://d3js.org/d3-axis) - axisLeft, axisBottom, orient behavior

### Secondary (MEDIUM confidence)
- [D3 responsive charts tutorial](https://lucidar.me/en/d3.js/part-11-responsive-chart/) - viewBox vs. redraw tradeoffs
- [viewBox may not be the answer (Medium)](https://maheshsenniappan.medium.com/responsive-svg-charts-viewbox-may-not-be-the-answer-aaf9c9bc4ca2) - Text scaling issues
- [D3 responsive patterns (Ben Clinkinbeard)](https://benclinkinbeard.com/d3tips/make-any-chart-responsive-with-one-function/) - responsivefy pattern
- [ggplot2 coordinate systems guide (R-Charts)](https://r-charts.com/ggplot2/coordinate-systems/) - Practical examples

### Tertiary (LOW confidence)
- Multiple StackOverflow threads on coord_flip confusion - Common pain points align with research findings
- D3 community patterns for axis swapping - Generally agree on generator + position approach

## Metadata

**Confidence breakdown:**
- coord_flip semantics: HIGH - Official ggplot2 docs and source code confirm theme element behavior
- coord_fixed aspect ratio: HIGH - Multiple official sources document ratio parameter and resize behavior
- D3 implementation patterns: MEDIUM-HIGH - Well-established community patterns, verified in multiple tutorials
- htmlwidgets resize: HIGH - Official vignette documents sizing framework

**Research date:** 2026-02-08
**Valid until:** 90 days (coordinate system APIs are stable; ggplot2 last changed coord behavior in 2016)

## Key Findings Summary

1. **coord_flip is a layout transformation, not scale transformation**
   - Must reposition axis groups and generators, not just reverse scale ranges
   - Theme elements follow aesthetic semantics (axis.text.x → x-aesthetic axis)
   - Grid lines must flip orientation (x-breaks → horizontal after flip)

2. **coord_fixed requires dimension constraints**
   - viewBox approach scales text (undesirable for data viz)
   - Constrained panel dimensions maintain readable text
   - htmlwidgets resize hook enables redraw on dimension change

3. **Current implementation is broken**
   - Reverses scale ranges but leaves axes in wrong positions
   - Documented in CONCERNS.md, vignettes/d3-drawing-diagnostics.md
   - Affects all geoms due to layout-level issue

4. **IR already supports coord metadata**
   - `ir.coord = {type, flip}` structure exists
   - Need to add `ratio` field for coord_fixed
   - Could add `xlim`/`ylim` for coord clipping (Phase 4+)

5. **Verification requirements**
   - Test with all geom types (layout affects all)
   - Verify theme element mappings (axis.text.x on correct visual axis)
   - Check grid line alignment after flip
   - Confirm aspect ratio maintains across resize events
