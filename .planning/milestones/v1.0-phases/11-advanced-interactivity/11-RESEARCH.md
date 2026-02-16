# Phase 11: Advanced Interactivity - Research

**Researched:** 2026-02-14
**Domain:** D3 v7 zoom/brush behaviors, Crosstalk linked brushing, Shiny integration
**Confidence:** HIGH

## Summary

This phase implements three advanced interactive features: (1) zoom/pan with d3.zoom(), (2) brush selection with d3.brush(), and (3) linked brushing via Crosstalk and Shiny. All three build on Phase 10's pipe-based API and event system architecture.

**Primary recommendation:** Use D3 v7's zoom and brush behaviors with event namespacing (.zoom, .brush) to avoid conflicts. For Crosstalk, implement SelectionHandle for brushing coordination. For Shiny, use Shiny.onInputChange() for client→server messaging and addCustomMessageHandler() for server→client. Double-click reset is a standard pattern using d3.zoomIdentity.

**Key insight:** D3 zoom and brush are separate behaviors that can conflict—use .filter() to control which input events trigger each. Zoom applies transforms to scales (rescaleX/rescaleY), while brush emits selection coordinates that require manual scale.invert() to map back to data domain.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3 v7 | 7.x | d3.zoom(), d3.brush() behaviors | Already vendored in project, official D3 interaction modules |
| crosstalk | 1.2.x | SharedData, SelectionHandle, FilterHandle | RStudio's official R package for htmlwidgets cross-widget communication |
| htmlwidgets | 1.6.x | onRender(), Shiny integration | Already in use, core framework for R→JS widgets |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Shiny | 1.8.x | Server-side reactivity, custom messages | Only when widget is inside Shiny app (not static HTML) |
| d3-selection | 7.x (in D3) | Event namespacing, .on() | Required for all event handlers (already used in Phase 10) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| d3.zoom() | Custom drag handlers | D3's zoom handles touch, wheel, pinch, constrain logic—don't hand-roll |
| d3.brush() | Custom rect drag | D3's brush handles resize handles, overlay, event lifecycle—very complex |
| Crosstalk | Custom JS event bus | Crosstalk is ecosystem standard, works with Leaflet/Plotly/DT without custom wiring |

**Installation:**
```r
# R side (already in DESCRIPTION)
install.packages("htmlwidgets")  # Already installed
install.packages("crosstalk")    # Add to Suggests

# D3 v7 already vendored at inst/htmlwidgets/lib/d3/d3.v7.min.js
```

## Architecture Patterns

### Recommended Project Structure
```
R/
├── d3_zoom.R           # gg2d3(p) |> d3_zoom() pipe function
├── d3_brush.R          # gg2d3(p) |> d3_brush() pipe function
└── d3_crosstalk.R      # SharedData wrapper for gg2d3

inst/htmlwidgets/modules/
├── zoom.js             # Zoom behavior setup, rescale logic
├── brush.js            # Brush behavior, selection→data mapping
└── crosstalk.js        # SelectionHandle integration
```

### Pattern 1: Zoom with Scale Rescaling
**What:** D3 zoom applies transforms to scales, not directly to SVG. Use `transform.rescaleX(scale)` to get updated scale for axis/data rendering.

**When to use:** Any zoom implementation—this is the only correct pattern for D3 zoom with data-driven scales.

**Example:**
```javascript
// Source: https://d3js.org/d3-zoom
const xScale = d3.scaleLinear().domain([0, 100]).range([0, width]);
const zoom = d3.zoom()
  .scaleExtent([1, 8])  // Min/max zoom levels
  .translateExtent([[0, 0], [width, height]])  // Pan bounds
  .on("zoom", (event) => {
    // Rescale the original scale (don't mutate)
    const newXScale = event.transform.rescaleX(xScale);
    const newYScale = event.transform.rescaleY(yScale);

    // Update axes
    xAxisGroup.call(d3.axisBottom(newXScale));
    yAxisGroup.call(d3.axisLeft(newYScale));

    // Reposition data elements (or re-render)
    circles
      .attr("cx", d => newXScale(d.x))
      .attr("cy", d => newYScale(d.y));
  });

svg.call(zoom);
```

**Why this pattern:** D3's zoom behavior manages the transform state (k, x, y) and handles all input modalities (mouse, touch, wheel). `rescaleX/Y` creates new scales without mutating originals, which is critical for reset/transition logic.

### Pattern 2: Double-Click Reset
**What:** Override default double-click zoom-in behavior to reset to identity transform.

**When to use:** Success criteria explicitly requires double-click reset.

**Example:**
```javascript
// Source: https://github.com/d3/d3-zoom/issues/49
const zoom = d3.zoom()
  .on("zoom", zoomed);

svg.call(zoom)
  .on("dblclick.zoom", null)  // Disable default double-click zoom
  .on("dblclick", function() {
    svg.transition()
      .duration(750)
      .call(zoom.transform, d3.zoomIdentity);
  });
```

**Why this pattern:** D3 zoom's default double-click behavior zooms in by 2x. Overriding with `.on("dblclick.zoom", null)` disables built-in handler, allowing custom reset. Using namespaced events (.zoom) ensures we only override zoom's handler, not other potential double-click handlers.

### Pattern 3: Brush Selection Mapping to Data
**What:** Brush emits pixel coordinates—must invert scales to get data domain values.

**When to use:** Any brush implementation that needs to filter/highlight data based on brush selection.

**Example:**
```javascript
// Source: https://d3js.org/d3-brush
const brush = d3.brush()
  .extent([[0, 0], [width, height]])
  .on("brush end", (event) => {
    const selection = event.selection;
    if (!selection) {
      // Brush cleared—reset highlighting
      circles.classed("selected", false);
      return;
    }

    const [[x0, y0], [x1, y1]] = selection;

    // Invert pixel coordinates to data domain
    const xDomain = [xScale.invert(x0), xScale.invert(x1)];
    const yDomain = [yScale.invert(y1), yScale.invert(y0)];  // Note: y inverted

    // Highlight data points within brush
    circles.classed("selected", d =>
      d.x >= xDomain[0] && d.x <= xDomain[1] &&
      d.y >= yDomain[0] && d.y <= yDomain[1]
    );
  });

svg.append("g").call(brush);
```

**Why this pattern:** Brush works in pixel space, data lives in domain space. `scale.invert()` only exists on continuous scales (linear, log, time). For categorical scales, manually map pixel positions to domain values.

### Pattern 4: Crosstalk SelectionHandle Integration
**What:** Use Crosstalk's SelectionHandle to broadcast/receive selection arrays across linked widgets.

**When to use:** When user wants linked brushing between gg2d3 and other Crosstalk widgets (Leaflet, Plotly, DT).

**Example:**
```javascript
// Source: https://rstudio.github.io/crosstalk/authoring.html
// In widget factory function:
factory: function(el, width, height) {
  return {
    renderValue: function(x) {
      // Check if crosstalk metadata exists
      if (x.crosstalk_key && x.crosstalk_group) {
        const sel = new crosstalk.SelectionHandle(x.crosstalk_group);

        // Listen for selection changes from other widgets
        sel.on("change", function(e) {
          const selectedKeys = e.value;  // Array of keys or null
          if (!selectedKeys) {
            // Clear selection
            svg.selectAll(".selected").classed("selected", false);
          } else {
            // Highlight selected data points
            svg.selectAll("circle").classed("selected", d =>
              selectedKeys.includes(x.crosstalk_key[d.index])
            );
          }
        });

        // Send selection to other widgets on brush
        brush.on("end", (event) => {
          const selectedIndices = /* compute from brush */;
          const selectedKeys = selectedIndices.map(i => x.crosstalk_key[i]);
          sel.set(selectedKeys);  // Broadcast to group
        });
      }

      // Render as normal
      renderPlot(x);
    }
  };
}
```

**Why this pattern:** Crosstalk's SelectionHandle manages group coordination and state synchronization. The `crosstalk_key` array maps each data row to a unique key, allowing widgets to communicate about specific rows without sharing full datasets.

### Pattern 5: Shiny Message Passing
**What:** Use Shiny.onInputChange() to send data from JS→R, and custom message handlers for R→JS.

**When to use:** When widget is embedded in Shiny and needs server-side reactivity (e.g., updating plot based on zoom level).

**Example:**
```javascript
// Source: https://shiny.posit.co/r/articles/build/js-send-message/
// JS: Send zoom state to Shiny
zoom.on("zoom", (event) => {
  if (HTMLWidgets.shinyMode) {
    Shiny.onInputChange(el.id + "_zoom_transform", {
      k: event.transform.k,
      x: event.transform.x,
      y: event.transform.y
    });
  }
});

// R: Observe zoom changes in Shiny server
observeEvent(input$myplot_zoom_transform, {
  # React to zoom state
  print(input$myplot_zoom_transform$k)
})

// JS: Receive messages from Shiny server
Shiny.addCustomMessageHandler("resetZoom_" + el.id, function(message) {
  svg.transition()
    .duration(750)
    .call(zoom.transform, d3.zoomIdentity);
});
```

**Why this pattern:** Shiny.onInputChange sends reactive values to server (available as `input$<id>_<name>`). Custom message handlers allow server-initiated actions. The `el.id` ensures messages are scoped to specific widget instances.

### Pattern 6: Coordinating Zoom Across Faceted Panels
**What:** Share a single zoom behavior across multiple panel groups, applying same transform to all panels.

**When to use:** When zooming one faceted panel should zoom all panels simultaneously.

**Example:**
```javascript
// Create shared zoom behavior
const sharedZoom = d3.zoom()
  .on("zoom", (event) => {
    // Apply transform to all panels
    panelGroups.each(function(panelData) {
      const panelGroup = d3.select(this);
      const xScale = panelData.xScale;
      const yScale = panelData.yScale;

      const newX = event.transform.rescaleX(xScale);
      const newY = event.transform.rescaleY(yScale);

      // Update axes for this panel
      panelGroup.select(".x-axis").call(d3.axisBottom(newX));
      panelGroup.select(".y-axis").call(d3.axisLeft(newY));

      // Reposition geoms
      panelGroup.selectAll("circle")
        .attr("cx", d => newX(d.x))
        .attr("cy", d => newY(d.y));
    });
  });

// Apply zoom to a single overlay rect covering all panels
svg.append("rect")
  .attr("class", "zoom-overlay")
  .attr("width", totalWidth)
  .attr("height", totalHeight)
  .style("fill", "none")
  .style("pointer-events", "all")
  .call(sharedZoom);
```

**Why this pattern:** Applying zoom to each panel separately creates independent zoom states. A shared zoom behavior with a single overlay ensures all panels zoom together. Each panel's clipped group still renders independently, but all respond to the same transform.

### Anti-Patterns to Avoid

- **Mutating original scales on zoom:** Don't do `xScale.domain(newDomain)`. Always use `event.transform.rescaleX(xScale)` to create new scale instance.
- **Applying zoom to data group:** Don't apply zoom to the group containing data elements—apply to overlay or root SVG. Otherwise, zoom transform literally scales the SVG group, which breaks click coordinates and pixel dimensions.
- **Forgetting scale.invert() for brush:** Don't use pixel coordinates directly as data values. Always invert through scale.
- **Using both zoom and brush on same element without filtering:** Will conflict. Use `.filter()` on one or both to separate by modifier key (e.g., brush only when Shift pressed).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pan and zoom behavior | Custom drag handlers + wheel listeners | d3.zoom() | Handles touch, wheel, pinch-zoom, constraints, double-click, smooth transitions—extremely complex edge cases |
| Brush selection UI | Custom rectangle drag logic | d3.brush() | Manages 8 resize handles, overlay, selection rect, keyboard modifiers, touch—hundreds of lines of logic |
| Widget-to-widget communication | Custom event bus / window messages | Crosstalk SelectionHandle | Crosstalk is ecosystem standard; works with Plotly, Leaflet, DT out of box |
| Transform constraints | Manual boundary checking | zoom.scaleExtent() + zoom.translateExtent() | D3's constrain function handles viewport/translate extent math correctly |
| Brush coordinate inversion | Manual pixel→data mapping | scale.invert() | Handles all scale types (linear, log, time) with correct math |

**Key insight:** D3's zoom and brush behaviors are production-hardened with years of edge case fixes. Don't underestimate complexity: touch events, modifier keys, event propagation, constrain logic, transition timing—all have subtle bugs waiting to happen.

## Common Pitfalls

### Pitfall 1: Zoom + Brush Event Conflicts
**What goes wrong:** Both zoom and brush respond to drag events. When both are active on same element, first behavior captures the event and second doesn't fire.

**Why it happens:** D3 event handlers are first-registered-first-served. Both behaviors listen to pointerdown/mousedown, and the first one calls `event.stopPropagation()` or `event.preventDefault()`.

**How to avoid:**
```javascript
// Option 1: Use filter to separate by modifier key
const zoom = d3.zoom()
  .filter(event => !event.shiftKey);  // Zoom unless Shift pressed

const brush = d3.brush()
  .filter(event => event.shiftKey);  // Brush only when Shift pressed

// Option 2: Apply to different elements
svg.append("rect").call(zoom);  // Zoom overlay (lower z-index)
svg.append("g").call(brush);    // Brush group (higher z-index)
```

**Warning signs:** Brush stops working after adding zoom, or vice versa. Drag events only trigger one behavior.

**Sources:**
- [D3 zoom/brush conflict GitHub issue](https://github.com/d3/d3-zoom/issues/222)
- [Cooperative Brushing and Tooltips in D3](https://wrobstory.github.io/2013/11/D3-brush-and-tooltip.html)

### Pitfall 2: Forgetting to Rescale Axes After Zoom
**What goes wrong:** Data elements zoom correctly, but axes don't update—tick labels become misaligned with data.

**Why it happens:** Zoom transform applies to scale copies, not to axis generators. Axis must be manually re-called with updated scale.

**How to avoid:**
```javascript
// Store axis generators
const xAxisGen = d3.axisBottom(xScale);
const yAxisGen = d3.axisLeft(yScale);

zoom.on("zoom", (event) => {
  const newX = event.transform.rescaleX(xScale);
  const newY = event.transform.rescaleY(yScale);

  // CRITICAL: Update axes
  xAxisGroup.call(xAxisGen.scale(newX));
  yAxisGroup.call(yAxisGen.scale(newY));

  // Update data
  circles.attr("cx", d => newX(d.x)).attr("cy", d => newY(d.y));
});
```

**Warning signs:** After zoom, tick labels don't match where data points appear. Grid lines misaligned.

### Pitfall 3: Crosstalk Performance with Large Datasets
**What goes wrong:** Page freezes when brushing plots with thousands of points. Selection updates take seconds.

**Why it happens:** Crosstalk passes all data to browser and uses client-side filtering. Every selection change triggers full array iteration across all linked widgets.

**How to avoid:**
- **Limit data size:** Crosstalk official docs warn against large datasets. Downsample to < 1000 rows for interactive use.
- **Use Shiny instead:** For large data, use Shiny with server-side filtering. Only send visible data to browser.
- **Debounce brush events:** Don't broadcast selection on every "brush" event—only on "end".

```javascript
// Bad: Broadcasts on every pixel of brush drag
brush.on("brush", (event) => sel.set(computeKeys(event.selection)));

// Good: Only broadcasts when brush finishes
brush.on("end", (event) => sel.set(computeKeys(event.selection)));
```

**Warning signs:** Browser lag during brush drag. Other widgets update slowly. High CPU usage in browser.

**Sources:**
- [Crosstalk official docs](https://rstudio.github.io/crosstalk/)
- [Crosstalk GitHub README](https://github.com/rstudio/crosstalk)

### Pitfall 4: Clip-Path Conflicts with Zoom
**What goes wrong:** After zoom, data elements disappear or render outside panel bounds.

**Why it happens:** If zoom transform is applied to the clipped group itself (`<g clip-path="...">`), the clip-path coordinates get transformed too, expanding the clipping region.

**How to avoid:**
- **Apply zoom to parent of clipped group:** Transform should apply to unclipped container.
- **Or reposition elements, not transform group:** On zoom, update element positions (cx/cy/d attributes) instead of group transform.

```javascript
// Bad: Transforms the clipped group
const gClipped = g.append("g").attr("clip-path", "url(#clip)");
gClipped.call(zoom);  // WRONG: clip-path transforms too

// Good: Transform parent, or update element positions
zoom.on("zoom", (event) => {
  const newX = event.transform.rescaleX(xScale);

  // Reposition elements inside clipped group
  gClipped.selectAll("circle")
    .attr("cx", d => newX(d.x));
  // Clipped group transform stays identity
});
```

**Warning signs:** After zoom, clip-path no longer constrains data. Elements render outside panel borders.

**Sources:**
- [D3 zoom with clip-path GitHub gist](https://gist.github.com/csessig86/91e582e34cd4637745ac673d0f73729f)
- [D3 zoom GitHub issue #1076](https://github.com/d3/d3/issues/1076)

### Pitfall 5: Brush on Categorical Scales
**What goes wrong:** `scale.invert()` doesn't exist on band/ordinal scales. Brush selection can't map back to data.

**Why it happens:** Categorical scales don't have mathematical inversion—multiple domain values can map to overlapping pixel ranges due to bandwidth.

**How to avoid:**
```javascript
// For band scale, manually find domain values within pixel range
const brush = d3.brush().on("end", (event) => {
  if (!event.selection) return;

  const [[x0, x1], [y0, y1]] = event.selection;

  // For categorical x scale (band)
  const selectedX = xScale.domain().filter(val => {
    const pos = xScale(val) + xScale.bandwidth() / 2;  // Center of band
    return pos >= x0 && pos <= x1;
  });

  // For continuous y scale
  const selectedY = [yScale.invert(y1), yScale.invert(y0)];
});
```

**Warning signs:** `TypeError: scale.invert is not a function` when brushing categorical axes.

### Pitfall 6: Shiny Widget Not Detecting Shiny Mode
**What goes wrong:** `Shiny.onInputChange()` called in static HTML, causing JavaScript errors.

**Why it happens:** Widget JavaScript runs in both static HTML and Shiny contexts. `Shiny` object undefined in static context.

**How to avoid:**
```javascript
// Check if widget is in Shiny mode before sending messages
if (window.Shiny && window.Shiny.onInputChange) {
  Shiny.onInputChange(el.id + "_zoom", transformData);
}

// Or use htmlwidgets helper
if (HTMLWidgets.shinyMode) {
  Shiny.onInputChange(el.id + "_zoom", transformData);
}
```

**Warning signs:** JavaScript console errors in static HTML: "Shiny is not defined" or "Cannot read property 'onInputChange' of undefined".

## Code Examples

Verified patterns from official sources:

### Zoom with Constrained Bounds
```javascript
// Source: https://d3js.org/d3-zoom
const zoom = d3.zoom()
  .scaleExtent([1, 8])  // Min zoom 1x, max zoom 8x
  .translateExtent([[0, 0], [width, height]])  // Can't pan outside plot area
  .extent([[0, 0], [width, height]])  // Viewport size
  .on("zoom", zoomed);

function zoomed(event) {
  const newX = event.transform.rescaleX(xScale);
  const newY = event.transform.rescaleY(yScale);

  xAxis.call(d3.axisBottom(newX));
  yAxis.call(d3.axisLeft(newY));

  dataLayer.attr("transform", event.transform);  // Or reposition elements
}

svg.call(zoom);
```

### Brush with Linked Highlighting
```javascript
// Source: https://d3js.org/d3-brush
const brush = d3.brush()
  .extent([[0, 0], [width, height]])
  .on("start brush end", brushed);

function brushed(event) {
  const selection = event.selection;

  circles.classed("selected", d => {
    if (!selection) return false;
    const [[x0, y0], [x1, y1]] = selection;
    return xScale(d.x) >= x0 && xScale(d.x) <= x1 &&
           yScale(d.y) >= y0 && yScale(d.y) <= y1;
  });
}

svg.append("g").attr("class", "brush").call(brush);
```

### Crosstalk SharedData Wrapper (R)
```r
# Source: https://rstudio.github.io/crosstalk/using.html
library(crosstalk)

# Wrap data frame with SharedData
sd <- SharedData$new(mtcars, key = ~rownames(mtcars), group = "cars")

# Pass to multiple widgets
gg2d3(sd) |> d3_brush()
plotly::plot_ly(sd, x = ~wt, y = ~mpg)  # Auto-linked
```

### Crosstalk JavaScript Integration
```javascript
// Source: https://rstudio.github.io/crosstalk/authoring.html
// In widget renderValue:
if (x.crosstalk_key && x.crosstalk_group) {
  const sel = new crosstalk.SelectionHandle(x.crosstalk_group);

  sel.on("change", function(e) {
    const keys = e.value;  // null or array of selected keys
    highlightByKeys(keys, x.crosstalk_key);
  });

  // Send selection from brush
  brush.on("end", function(event) {
    const selectedKeys = getKeysFromBrush(event.selection, x.crosstalk_key);
    sel.set(selectedKeys);
  });

  // Clear selection on double-click
  svg.on("dblclick", () => sel.clear());
}
```

### Programmatic Zoom Controls
```javascript
// Source: https://d3js.org/d3-zoom
// Zoom in button
d3.select("#zoom-in").on("click", () => {
  svg.transition().duration(750).call(zoom.scaleBy, 2);
});

// Zoom out button
d3.select("#zoom-out").on("click", () => {
  svg.transition().duration(750).call(zoom.scaleBy, 0.5);
});

// Reset button
d3.select("#reset").on("click", () => {
  svg.transition().duration(750).call(zoom.transform, d3.zoomIdentity);
});

// Zoom to specific transform
svg.transition().call(
  zoom.transform,
  d3.zoomIdentity.translate(100, 50).scale(1.5)
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| D3 v3 zoom with .scale()/.translate() | D3 v7 zoom with event.transform | D3 v4 (2016) | Transform is immutable object; rescaleX/rescaleY pattern replaces manual domain updates |
| Brush with .extent() extent accessor | .extent() setter only | D3 v4 (2016) | Must store extent separately if needed; brush doesn't expose current extent |
| zoom.x(scale) / zoom.y(scale) | zoom behavior agnostic, manual rescaling | D3 v4 (2016) | Zoom no longer owns scales; developer controls how transform applies |
| selection.on(".zoom", handler) to remove | selection.on(".zoom", null) | D3 v6 (2020) | Explicit null required to unbind namespaced events |

**Deprecated/outdated:**
- **zoom.x(scale) / zoom.y(scale):** Removed in D3 v4. Use `event.transform.rescaleX(scale)` instead.
- **brush.extent() as getter:** In D3 v4+, extent is write-only. If you need current extent, store it when setting.
- **event.sourceEvent.stopPropagation() in zoom handler:** D3 v5+ handles propagation internally; manual stopPropagation can break things.

## Open Questions

1. **How to handle zoom persistence across Shiny re-renders?**
   - What we know: Shiny re-renders destroy widget DOM and reset zoom state.
   - What's unclear: Best pattern to save/restore zoom transform when widget re-renders.
   - Recommendation: Store transform in Shiny input value; on render, check if previous transform exists and apply it. Need to test if this creates infinite loops.

2. **Should brush clear on zoom, or persist?**
   - What we know: Users expect either behavior depending on use case.
   - What's unclear: What's the most intuitive default for ggplot2 users?
   - Recommendation: Start with "brush persists, but updates to new scale coordinates." Provide optional `clear_on_zoom = TRUE` parameter.

3. **Faceted panels: independent zoom or synchronized?**
   - What we know: Both patterns have use cases (compare scales vs. see details).
   - What's unclear: Which should be default? Should we support both?
   - Recommendation: Default to synchronized zoom (all panels zoom together). Implement first; if users request independent zoom, add later.

## Sources

### Primary (HIGH confidence)
- [D3 Zoom Official Docs](https://d3js.org/d3-zoom) - Complete API reference, event model, transform API
- [D3 Brush Official Docs](https://d3js.org/d3-brush) - Brush creation, selection handling, programmatic control
- [Crosstalk Official Docs](https://rstudio.github.io/crosstalk/) - SharedData, SelectionHandle, FilterHandle APIs
- [Crosstalk Authoring Guide](https://rstudio.github.io/crosstalk/authoring.html) - JavaScript integration patterns
- [htmlwidgets Shiny Integration](https://shiny.posit.co/r/articles/build/js-send-message/) - Shiny.onInputChange, custom message handlers

### Secondary (MEDIUM confidence)
- [D3 Graph Gallery - Line chart with zoom](https://d3-graph-gallery.com/graph/line_brushZoom.html) - Brush+zoom coordination example
- [Observable Focus + Context](https://observablehq.com/@d3/focus-context) - Brush-driven zoom pattern
- [JavaScript for R - Linking Widgets](https://book.javascript-for-r.com/linking-widgets) - Crosstalk implementation guide
- [D3 In Depth - Zoom and Pan](https://www.d3indepth.com/zoom-and-pan/) - Tutorial with constrain examples

### Tertiary (LOW confidence - verify before using)
- GitHub discussions on zoom/brush conflicts (multiple patterns proposed, not all recommended)
- Medium articles on brush+zoom (may use outdated D3 v3/v4 APIs)

## Metadata

**Confidence breakdown:**
- D3 zoom/brush APIs: HIGH - Official docs comprehensive, widely used in production
- Crosstalk integration: HIGH - Official RStudio package with stable API
- Shiny integration: HIGH - Official Shiny docs cover message passing patterns
- Faceted panel coordination: MEDIUM - No official guidance, but pattern is straightforward extension
- Performance limits: MEDIUM - Crosstalk docs mention limits but don't quantify thresholds

**Research date:** 2026-02-14
**Valid until:** 2026-03-16 (30 days - D3 and Crosstalk are stable, slow-moving)

**Key takeaways for planner:**
1. Use d3.zoom() and d3.brush() behaviors—don't hand-roll interaction logic
2. Apply zoom to overlay/parent, not to clipped data groups
3. Always rescaleX/rescaleY on zoom events—don't mutate original scales
4. Use event namespacing (.zoom, .brush) to avoid conflicts with Phase 10's .tooltip/.hover
5. Crosstalk requires `crosstalk_key` and `crosstalk_group` in widget payload
6. For Shiny, wrap all Shiny.* calls in `if (HTMLWidgets.shinyMode)` checks
7. Double-click reset is `.on("dblclick.zoom", null)` + custom `.on("dblclick", reset)`
