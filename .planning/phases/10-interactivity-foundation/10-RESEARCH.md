# Phase 10: Interactivity Foundation - Research

**Researched:** 2026-02-13
**Domain:** htmlwidgets interactivity, D3.js event handling, R pipe API design
**Confidence:** HIGH

## Summary

Phase 10 establishes the interactivity foundation for gg2d3 by implementing a pipe-based R API (`gg2d3(p) |> d3_tooltip()`) that adds event handlers to rendered D3 SVG elements. The implementation requires three coordinated components: (1) R-side pipe functions that modify widget structure and queue interactivity configurations, (2) JavaScript event system modules that attach D3 event listeners to geom elements, and (3) a tooltip renderer with smart viewport-aware positioning. The architecture must support both static HTML output and Shiny contexts without breaking existing rendering.

The research confirms that htmlwidgets provides well-established patterns for this exact use case. The key insight: R pipe functions return modified widget objects (not IDs), storing interactivity config in `x$interactivity` for JavaScript to process after rendering. D3 v7's event model is stable and well-documented. The main complexity lies in cross-geom event attachment (each geom renders differently) and tooltip positioning logic (viewport edge detection, pointer offset calculations).

**Primary recommendation:** Follow the leaflet/plotly pattern—pipe functions modify widget structure, `htmlwidgets::onRender()` processes config post-initialization, and D3 event handlers attach to `.selectAll()` queries using the existing geom class names.

## Standard Stack

### Core Dependencies (Already in Project)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| htmlwidgets | 1.6.x | R-JS bridge | Standard for all R HTML widgets |
| D3.js | v7 | SVG manipulation + events | Already vendored, stable event API |
| R base pipe | `\|>` (R ≥ 4.1) | Function chaining | Native R operator, no magrittr needed |

### No Additional Installation Required

The project already has all necessary dependencies. D3 v7 is vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`.

### Supporting Patterns (No New Libraries)

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `htmlwidgets::onRender()` | Post-init JS execution | Attach event handlers after SVG rendered |
| `SharedData` (crosstalk) | Linked brushing | Phase 11 only (out of scope for Phase 10) |
| `session$sendCustomMessage` | Shiny integration | Phase 11 only (out of scope for Phase 10) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native R pipe `\|>` | magrittr `%>%` | magrittr adds dependency, but more users familiar with it (decision: use `\|>`, document both) |
| D3 event handlers | jQuery | D3 already loaded, jQuery unnecessary overhead |
| Custom tooltip div | Browser native `<title>` | Native tooltips can't be styled or positioned dynamically |

## Architecture Patterns

### Recommended Project Structure

```
R/
├── gg2d3.R              # Main widget (unchanged)
├── d3_tooltip.R         # NEW: d3_tooltip() pipe function
├── d3_hover.R           # NEW: d3_hover() pipe function (optional: configure hover styles)

inst/htmlwidgets/
├── gg2d3.js             # Main renderer (minimal changes)
└── modules/
    ├── events.js        # NEW: Event system core
    ├── tooltip.js       # NEW: Tooltip renderer + positioning
    └── geoms/           # Existing geom renderers (add class names for selection)
```

### Pattern 1: Pipe Function Modifies Widget Structure

**What:** R pipe functions return modified widget object with interactivity config
**When to use:** All interactive features (tooltips, hover effects, future zoom/brush)
**Example:**

```r
# R/d3_tooltip.R
d3_tooltip <- function(widget, fields = NULL, formatter = NULL) {
  # Validate input
  if (!inherits(widget, "gg2d3")) {
    stop("d3_tooltip() requires a gg2d3 widget object")
  }

  # Initialize interactivity config if not present
  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  # Add tooltip configuration
  widget$x$interactivity$tooltip <- list(
    enabled = TRUE,
    fields = fields,      # NULL = show all aesthetics
    formatter = formatter  # NULL = default formatting
  )

  # Attach JavaScript to process config after render
  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      if (x.interactivity && x.interactivity.tooltip) {
        window.gg2d3.events.attachTooltips(el, x.interactivity.tooltip);
      }
    }
  ")

  return(widget)
}
```

**Key insight:** Return the widget, not the widget ID. This enables chaining and works in both static HTML and Shiny contexts.

### Pattern 2: JavaScript Event Module with Geom-Agnostic Selection

**What:** Central event module selects all rendered geoms by class and attaches handlers
**When to use:** Any feature that needs to add event handlers to existing rendered elements
**Example:**

```javascript
// inst/htmlwidgets/modules/events.js
(function() {
  'use strict';
  if (!window.gg2d3) window.gg2d3 = {};

  // Geom elements that support interactive events
  const INTERACTIVE_SELECTORS = [
    'circle',           // geom_point
    'rect',             // geom_bar, geom_tile
    'path.geom-line',   // geom_line (needs class to distinguish from area/ribbon)
    'path.geom-area',   // geom_area
    'text'              // geom_text
  ];

  function attachTooltips(el, config) {
    const svg = d3.select(el).select('svg');

    // Select all interactive elements
    INTERACTIVE_SELECTORS.forEach(selector => {
      svg.selectAll(selector)
        .on('mouseover', function(event, d) {
          window.gg2d3.tooltip.show(event, d, config);
        })
        .on('mousemove', function(event, d) {
          window.gg2d3.tooltip.move(event, d, config);
        })
        .on('mouseout', function(event, d) {
          window.gg2d3.tooltip.hide();
        });
    });
  }

  window.gg2d3.events = {
    attachTooltips: attachTooltips
  };
})();
```

**Key insight:** Use D3's `.selectAll()` to find all rendered marks. Geom renderers must add class names (e.g., `.geom-line`) to distinguish path types.

### Pattern 3: Tooltip Positioning with Viewport Awareness

**What:** Tooltip div positioned absolutely, adjusted to avoid viewport edges
**When to use:** Any tooltip or popover that should stay visible
**Example:**

```javascript
// inst/htmlwidgets/modules/tooltip.js
function positionTooltip(event, tooltipDiv) {
  const tooltip = tooltipDiv.node();
  const bounds = tooltip.getBoundingClientRect();
  const offset = 10; // px from cursor

  let x = event.pageX + offset;
  let y = event.pageY + offset;

  // Check right edge
  if (x + bounds.width > window.innerWidth) {
    x = event.pageX - bounds.width - offset;
  }

  // Check bottom edge
  if (y + bounds.height > window.innerHeight + window.scrollY) {
    y = event.pageY - bounds.height - offset;
  }

  // Check left edge (fallback)
  if (x < 0) {
    x = offset;
  }

  // Check top edge (fallback)
  if (y < window.scrollY) {
    y = window.scrollY + offset;
  }

  tooltipDiv
    .style('left', x + 'px')
    .style('top', y + 'px');
}
```

**Source:** [D3 Graph Gallery - Building tooltips](https://d3-graph-gallery.com/graph/interactivity_tooltip.html)

### Pattern 4: Data Binding for Tooltip Content

**What:** D3 event handlers receive bound data via `(event, d)` signature
**When to use:** Extracting values to display in tooltips
**Example:**

```javascript
function formatTooltipContent(d, config) {
  // d is the row object bound during geom rendering
  // { x: 5, y: 10, color: "red", size: 2.5, ... }

  const fields = config.fields || Object.keys(d).filter(k => !k.startsWith('_'));
  const lines = fields.map(field => {
    const value = d[field];
    const formatted = config.formatter
      ? config.formatter(field, value)
      : `${field}: ${value}`;
    return `<div>${formatted}</div>`;
  });

  return lines.join('');
}
```

**Key insight:** Geom renderers already bind full row data to SVG elements via `.data(rows)`. Event handlers automatically receive this data.

### Anti-Patterns to Avoid

- **Storing state in DOM attributes:** Use D3's `.datum()` or keep state in JavaScript closures. Parsing attributes is slow and brittle.
- **Global tooltip div per widget:** Create one shared tooltip per page, positioned absolutely. Multiple tooltips create z-index conflicts.
- **Synchronous tooltip updates in mousemove:** Throttle/debounce high-frequency events. Use `requestAnimationFrame` for smooth positioning.
- **Breaking changes to IR structure:** Add `interactivity` as optional top-level field. Never require it for static rendering.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Event delegation | Custom click handlers on parent with target detection | D3's `.on()` with `.selectAll()` | D3 handles delegation, bubbling, and cleanup automatically |
| Tooltip animation | Custom CSS transitions with timing logic | CSS `transition` property + class toggling | Browser-optimized, no RAF loop needed |
| Viewport bounds detection | Manual element.getBoundingClientRect() calculations with edge cases | Combine getBoundingClientRect() + window metrics (standard pattern) | Well-tested pattern, handles zoom/scroll correctly |
| Touch event handling | Separate touch event listeners + gesture detection | D3's pointer events (unified mouse/touch API) | Phase 11 concern, but D3 v7 normalizes pointer events |

**Key insight:** D3 v7 already handles the hard parts (event normalization, memory cleanup, data binding). Focus on widget integration, not reinventing event systems.

## Common Pitfalls

### Pitfall 1: Event Handlers Attached Before SVG Rendered

**What goes wrong:** `htmlwidgets::onRender()` called but SVG elements don't exist yet, `.selectAll()` returns empty selection
**Why it happens:** htmlwidgets renders asynchronously, DOM updates may not be complete when onRender callback fires
**How to avoid:** Use `setTimeout(() => attachEvents(), 0)` to defer until next event loop tick, ensuring SVG is in DOM
**Warning signs:** Event handlers work in RStudio Viewer but fail in Shiny or when embedded in markdown

**Prevention:**
```javascript
htmlwidgets::onRender(widget, "
  function(el, x) {
    // Defer to next tick to ensure SVG is rendered
    setTimeout(function() {
      window.gg2d3.events.attachTooltips(el, x.interactivity.tooltip);
    }, 0);
  }
")
```

### Pitfall 2: Tooltip Div Not Removed on Widget Destroy

**What goes wrong:** Multiple widget renders create orphaned tooltip divs, memory leak in Shiny apps
**Why it happens:** Tooltip created in document.body, not cleaned up when widget unmounted
**How to avoid:** Either (1) share one global tooltip, or (2) track tooltip in widget instance and remove in onUnmount callback
**Warning signs:** Inspecting DOM shows multiple `.gg2d3-tooltip` divs, page gets slower over time

**Prevention:**
```javascript
// Option 1: Global singleton tooltip (recommended)
function getTooltip() {
  let tooltip = d3.select('body').select('.gg2d3-tooltip');
  if (tooltip.empty()) {
    tooltip = d3.select('body').append('div')
      .attr('class', 'gg2d3-tooltip')
      .style('position', 'absolute')
      .style('display', 'none');
  }
  return tooltip;
}
```

### Pitfall 3: Geom Class Names Not Added

**What goes wrong:** Event system can't distinguish between `<path>` elements (line vs area vs ribbon), attaches wrong handlers
**Why it happens:** Existing geom renderers don't set class attributes, all paths look identical to selectors
**How to avoid:** Update geom renderers to add `.attr('class', 'geom-{type}')` during rendering
**Warning signs:** Tooltips appear on reference lines (geom_hline) when only geom_line intended

**Prevention:**
```javascript
// In geoms/line.js
g.append("path")
  .attr("class", "geom-line")  // ADD THIS
  .attr("d", lineGenerator)
  .attr("stroke", strokeColor)
  // ...
```

### Pitfall 4: Breaking Static Rendering

**What goes wrong:** Widget requires interactivity config, fails when rendering static HTML without pipe functions called
**Why it happens:** JavaScript assumes `x.interactivity` exists, throws error when undefined
**How to avoid:** Always check for config existence before accessing properties
**Warning signs:** Widget works when `d3_tooltip()` called, breaks when using just `gg2d3(plot)`

**Prevention:**
```javascript
// Always check existence
if (x.interactivity && x.interactivity.tooltip && x.interactivity.tooltip.enabled) {
  window.gg2d3.events.attachTooltips(el, x.interactivity.tooltip);
}
```

### Pitfall 5: Tooltip Covers Hovered Element (Pointer Hover Loss)

**What goes wrong:** Tooltip appears directly under cursor, covering the hovered element and triggering mouseout
**Why it happens:** Tooltip positioned exactly at cursor coordinates, becomes the topmost element
**How to avoid:** Add offset (10-15px) and set `pointer-events: none` CSS on tooltip
**Warning signs:** Tooltip flickers rapidly on hover, appears/disappears repeatedly

**Prevention:**
```css
.gg2d3-tooltip {
  pointer-events: none; /* Tooltip doesn't intercept mouse events */
}
```

```javascript
// Add offset from cursor
let x = event.pageX + 10;
let y = event.pageY + 10;
```

## Code Examples

Verified patterns from official sources:

### Creating Pipe Function That Returns Widget

```r
# R/d3_tooltip.R
#' Add tooltips to gg2d3 widget
#'
#' @param widget A gg2d3 widget
#' @param fields Character vector of field names to show (NULL = all)
#' @param formatter Optional JS function as string for custom formatting
#' @export
d3_tooltip <- function(widget, fields = NULL, formatter = NULL) {
  if (!inherits(widget, "gg2d3")) {
    stop("d3_tooltip() requires a gg2d3 widget")
  }

  if (is.null(widget$x$interactivity)) {
    widget$x$interactivity <- list()
  }

  widget$x$interactivity$tooltip <- list(
    enabled = TRUE,
    fields = fields,
    formatter = formatter
  )

  widget <- htmlwidgets::onRender(widget, "
    function(el, x) {
      setTimeout(function() {
        if (x.interactivity && x.interactivity.tooltip) {
          window.gg2d3.events.attachTooltips(el, x.interactivity.tooltip);
        }
      }, 0);
    }
  ")

  return(widget)
}
```

**Source:** Adapted from [Dean Attali's htmlwidgets tips](https://deanattali.com/blog/htmlwidgets-tips/)

### D3 Event Handler with Data Binding

```javascript
// inst/htmlwidgets/modules/events.js
function attachTooltips(el, config) {
  const svg = d3.select(el).select('svg');
  const tooltip = window.gg2d3.tooltip.getOrCreate();

  const selectors = ['circle', 'rect', 'path.geom-line'];

  selectors.forEach(selector => {
    svg.selectAll(selector)
      .on('mouseover', function(event, d) {
        // d is the bound data row
        tooltip.style('display', 'block');
        const content = window.gg2d3.tooltip.format(d, config);
        tooltip.html(content);
      })
      .on('mousemove', function(event, d) {
        window.gg2d3.tooltip.position(event, tooltip);
      })
      .on('mouseout', function() {
        tooltip.style('display', 'none');
      });
  });
}
```

**Source:** [D3 Graph Gallery - Tooltip Interactivity](https://d3-graph-gallery.com/graph/interactivity_tooltip.html)

### Smart Tooltip Positioning

```javascript
// inst/htmlwidgets/modules/tooltip.js
function positionTooltip(event, tooltipDiv) {
  const tooltip = tooltipDiv.node();
  const bounds = tooltip.getBoundingClientRect();
  const offset = 12;

  let x = event.pageX + offset;
  let y = event.pageY + offset;

  // Viewport collision detection
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight + window.scrollY;

  if (x + bounds.width > viewportWidth) {
    x = event.pageX - bounds.width - offset;
  }

  if (y + bounds.height > viewportHeight) {
    y = event.pageY - bounds.height - offset;
  }

  // Fallback: ensure visible
  x = Math.max(offset, Math.min(x, viewportWidth - bounds.width - offset));
  y = Math.max(window.scrollY + offset, y);

  tooltipDiv
    .style('left', x + 'px')
    .style('top', y + 'px');
}
```

**Source:** [Gist - D3 tooltip positioning with screen size](https://gist.github.com/GerHobbelt/2505393)

### Adding Class Names to Geom Renderers

```javascript
// inst/htmlwidgets/modules/geoms/line.js (modification)
function renderLine(layer, g, xScale, yScale, options) {
  // ... existing code ...

  g.append("path")
    .attr("class", "geom-line")  // ADD THIS for event selection
    .attr("d", lineGenerator(dat))
    .attr("stroke", strokeColor)
    .attr("stroke-width", strokeWidth)
    .attr("fill", "none");

  // ... rest of renderer ...
}
```

**Source:** Standard D3 practice, enables `.selectAll('path.geom-line')` specificity

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `d3.event` global | `event` parameter in handler | D3 v6 (2020) | Already using current approach (D3 v7) |
| `d3.mouse(this)` | `d3.pointer(event)` or `event.pageX/Y` | D3 v6 (2020) | Simpler API, works with touch |
| Separate touch handlers | Unified pointer events | D3 v6 (2020) | Phase 11 concern, but API stable |
| `%>%` (magrittr) | `|>` (base pipe) | R 4.1 (2021) | Native operator, no dep, but support both |

**Deprecated/outdated:**
- **`d3.event`**: Removed in D3 v6. Use `event` parameter passed to handler.
- **`d3.mouse(this)`**: Use `d3.pointer(event)` or `event.pageX/pageY` for tooltip positioning.
- **jQuery for event handling**: D3 already loaded, jQuery unnecessary for simple tooltips.

## Open Questions

1. **Should tooltip styling match ggplot2 theme?**
   - What we know: ggplot2 has no interactive tooltips, no theme precedent
   - What's unclear: User expectation—should tooltip colors match plot theme or use neutral defaults?
   - Recommendation: Start with neutral styling (white bg, black text, subtle shadow). Add theme integration in Phase 11 if users request it.

2. **How to handle faceted plots with tooltips?**
   - What we know: Each facet panel is a separate `<g>` group, event handlers attach to all
   - What's unclear: Should tooltip show panel/facet variable in content?
   - Recommendation: Include facet variables in tooltip by default (they're in the data row). Users can filter with `fields` parameter.

3. **Default tooltip fields: all aesthetics or just x/y?**
   - What we know: Plotly shows all mapped variables, Vega-Lite shows x/y by default
   - What's unclear: User expectation for ggplot2 context
   - Recommendation: Show all aesthetics (x, y, color, size, etc.) by default. Simple to filter with `fields = c("x", "y")` if too verbose.

4. **Should hovering change geom appearance (e.g., opacity)?**
   - What we know: Common pattern to highlight hovered element
   - What's unclear: Should this be automatic with tooltips, or separate `d3_hover()` function?
   - Recommendation: Separate concern. `d3_tooltip()` only shows tooltip. `d3_hover()` (Plan 10-02) adds hover styling. Users can combine both.

## Sources

### Primary (HIGH confidence)

- [htmlwidgets Advanced Topics](https://www.htmlwidgets.org/develop_advanced.html) - Official docs on data transformation, JS functions, Shiny integration
- [D3.js v7 Documentation](https://d3js.org/) - Official API reference for event handling
- [D3 Graph Gallery - Tooltips](https://d3-graph-gallery.com/graph/interactivity_tooltip.html) - Standard tooltip implementation patterns
- [CRAN htmlwidgets package](https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_intro.html) - Official vignette on widget development

### Secondary (MEDIUM confidence)

- [Dean Attali - htmlwidgets tips](https://deanattali.com/blog/htmlwidgets-tips/) - Pipe API implementation pattern from experienced widget author
- [JavaScript for R - Widgets with Shiny](https://book.javascript-for-r.com/shiny-widgets) - Message passing patterns verified with official Shiny docs
- [Shiny Documentation - Send Custom Messages](https://shiny.posit.co/r/articles/build/js-send-message/) - Official Shiny integration guide

### Tertiary (LOW confidence)

- [Crosstalk GitHub](https://github.com/rstudio/crosstalk) - Linked brushing patterns (Phase 11 concern, not Phase 10)
- [Plotly R book - Event Handlers](https://plotly-r.com/js-event-handlers.html) - Real-world htmlwidgets event handling example

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All dependencies already in project, D3 v7 API stable since 2021
- Architecture: HIGH - Pipe pattern verified in leaflet/plotly/timevis, htmlwidgets docs comprehensive
- Pitfalls: MEDIUM - Based on common issues in htmlwidgets GitHub issues and D3 tutorials, not project-specific testing

**Research date:** 2026-02-13
**Valid until:** 2026-03-13 (30 days - stable ecosystem, no fast-moving changes expected)

---

## Sources

- [htmlwidgets for R](https://www.htmlwidgets.org/)
- [htmlwidgets Advanced Topics](https://www.htmlwidgets.org/develop_advanced.html)
- [How to write a useful htmlwidgets in R](https://deanattali.com/blog/htmlwidgets-tips/)
- [Shiny - Send Custom Messages](https://shiny.posit.co/r/articles/build/js-send-message/)
- [JavaScript for R - Widgets with Shiny](https://book.javascript-for-r.com/shiny-widgets)
- [D3 Graph Gallery - Building tooltips](https://d3-graph-gallery.com/graph/interactivity_tooltip.html)
- [D3 tooltip positioning with screen size](https://gist.github.com/GerHobbelt/2505393)
- [Crosstalk GitHub Repository](https://github.com/rstudio/crosstalk)
- [Leaflet for R](https://rstudio.github.io/leaflet/)
- [Plotly R - Event Handlers](https://plotly-r.com/js-event-handlers.html)
