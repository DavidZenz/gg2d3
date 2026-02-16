# Phase 04: Essential Geoms - Research

**Researched:** 2026-02-08
**Domain:** D3.js path generators, area/ribbon rendering, line segments, reference lines
**Confidence:** HIGH

## Summary

Phase 4 adds critical geometric layers (area, ribbon, segment, reference lines) to complete basic plot capabilities. The research reveals that D3.js provides specialized path generators (`d3.area()`, `d3.line()`) that directly map to ggplot2's geom_area and geom_ribbon patterns. Segments and reference lines require simpler SVG line/rect rendering without path generators.

The key technical insight is that area/ribbon geoms are fundamentally path-based (similar to existing geom_line), while segments and reference lines are element-based (similar to existing geom_point). The existing codebase architecture (registry dispatch, color accessors, coord_flip handling) extends cleanly to all new geoms.

**Primary recommendation:** Implement area/ribbon using `d3.area()` path generator with proper baseline handling, segments as SVG line elements, and reference lines as full-span lines calculated from scale domains.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3.js | v7 | Area generator (`d3.area()`), line segments | Already vendored, official D3 shape API |
| ggplot2 | 3.4.0+ | Source geom behavior (area, ribbon, segment, hline/vline/abline) | Reference implementation for aesthetics and defaults |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| N/A | - | No additional libraries needed | Existing D3 v7 covers all requirements |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| d3.area() | Custom polygon path builder | d3.area() handles edge cases (missing data, curves, baseline) that would require reimplementation |
| SVG line elements | d3.line() for segments | Line generator is overkill for single segments; direct line elements are simpler |

**Installation:**
```bash
# No new dependencies - D3 v7 already vendored
# inst/htmlwidgets/lib/d3/d3.v7.min.js
```

## Architecture Patterns

### Recommended Project Structure
```
inst/htmlwidgets/modules/geoms/
├── area.js          # geom_area renderer (uses d3.area)
├── ribbon.js        # geom_ribbon renderer (uses d3.area)
├── segment.js       # geom_segment renderer (SVG line elements)
└── reference.js     # hline/vline/abline renderers (full-span lines)
```

### Pattern 1: Path Generator Pattern (Area/Ribbon)
**What:** Use D3 path generators to convert data arrays into SVG path `d` attribute strings
**When to use:** For continuous shapes (areas, ribbons) that form filled regions
**Example:**
```javascript
// Source: https://d3js.org/d3-shape/area + existing line.js pattern
function renderArea(layer, g, xScale, yScale, options) {
  const aes = layer.aes || {};
  const dat = asRows(layer.data);
  const flip = !!options.flip;

  // Group by 'group' aesthetic (for multiple areas)
  const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);

  grouped.forEach(arr => {
    let pts = arr
      .map(d => ({
        x: num(get(d, aes.x)),
        y: num(get(d, aes.y)),
        d
      }))
      .filter(p => p.x != null && p.y != null);

    if (pts.length >= 2) {
      // d3.area() requires x, y0 (baseline), y1 (topline)
      const area = flip
        ? d3.area()
            .x0(yScale(0))              // Baseline at zero (horizontal)
            .x1(p => yScale(p.y))       // Topline from data
            .y(p => xScale(p.x))        // Category axis (vertical)
        : d3.area()
            .x(p => xScale(p.x))        // Category axis (horizontal)
            .y0(yScale(0))              // Baseline at zero
            .y1(p => yScale(p.y));      // Topline from data

      g.append("path")
        .attr("d", area(pts))
        .attr("fill", fillColor(pts[0].d))
        .attr("stroke", "none")         // Areas have no outline by default
        .attr("opacity", opacity(pts[0].d));
    }
  });
}
```

### Pattern 2: Element-Based Pattern (Segments)
**What:** Direct SVG element creation for simple shapes
**When to use:** For discrete marks (points, segments, reference lines) without path generation
**Example:**
```javascript
// Source: Existing point.js + ggplot2 geom_segment behavior
function renderSegment(layer, g, xScale, yScale, options) {
  const aes = layer.aes || {};
  const dat = asRows(layer.data);
  const flip = !!options.flip;

  const segments = dat.filter(d =>
    get(d, aes.x) != null && get(d, aes.y) != null &&
    get(d, aes.xend) != null && get(d, aes.yend) != null
  );

  g.append("g").selectAll("line").data(segments)
    .enter().append("line")
    .attr("x1", d => flip ? yScale(num(get(d, aes.y))) : xScale(num(get(d, aes.x))))
    .attr("y1", d => flip ? xScale(num(get(d, aes.x))) : yScale(num(get(d, aes.y))))
    .attr("x2", d => flip ? yScale(num(get(d, aes.yend))) : xScale(num(get(d, aes.xend))))
    .attr("y2", d => flip ? xScale(num(get(d, aes.xend))) : yScale(num(get(d, aes.yend))))
    .attr("stroke", d => strokeColor(d))
    .attr("stroke-width", d => {
      const linewidthVal = val(get(d, "linewidth"));
      return linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.89;
    })
    .attr("opacity", d => opacity(d));
}
```

### Pattern 3: Reference Line Pattern (hline/vline/abline)
**What:** Full-span lines that extend across entire plot area
**When to use:** For annotation lines that mark specific values or slopes
**Example:**
```javascript
// Source: ggplot2 geom_hline/vline/abline behavior
function renderHline(layer, g, xScale, yScale, options) {
  const params = layer.params || {};
  const yintercept = params.yintercept;

  if (yintercept == null) return 0;

  const flip = !!options.flip;
  const yPos = yScale(yintercept);

  // hline spans full width of plot
  // When flip: horizontal line becomes vertical (spans height)
  g.append("line")
    .attr("x1", flip ? yPos : 0)
    .attr("y1", flip ? 0 : yPos)
    .attr("x2", flip ? yPos : options.plotWidth)
    .attr("y2", flip ? options.plotHeight : yPos)
    .attr("stroke", params.colour || "black")
    .attr("stroke-width", mmToPxLinewidth(params.linewidth || 0.5))
    .attr("opacity", 1);

  return 1;
}
```

### Anti-Patterns to Avoid
- **Building custom polygon strings for areas:** d3.area() handles missing data (`.defined()`), curves, and baseline logic that manual path building would miss
- **Using d3.line() for segments:** Segments connect arbitrary point pairs, not sequential data; direct line elements are simpler
- **Ignoring baseline for area charts:** Area baseline must respect scale domain (zero if in domain, else domain min) to match ggplot2 behavior
- **Forgetting coord_flip for reference lines:** hline/vline swap axes when flipped; implementation must handle this

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Area path generation | Manual polygon path strings with baseline logic | `d3.area()` generator | Handles missing data gaps, curve interpolation, and clockwise polygon ordering automatically |
| Ribbon baseline calculations | Custom ymin/ymax to path conversion | `d3.area()` with y0/y1 accessors | Generator correctly handles inverted scales, band scales, and missing data |
| Reference line positioning | Manual scale domain extraction and line drawing | Scale domain + options.plotWidth/Height | Avoids duplicating scale inversion logic |
| Segment arrow heads | Custom SVG marker definitions | Defer to future phase | SVG markers require careful coordinate transformation with coord_flip |

**Key insight:** D3 path generators are battle-tested for edge cases (missing data creating gaps, different curve types, coordinate inversions). Custom implementations would need extensive testing to match this robustness.

## Common Pitfalls

### Pitfall 1: Area Baseline Confusion
**What goes wrong:** Area charts render upside-down or don't touch zero baseline
**Why it happens:** SVG y-axis is inverted (0 at top), and y0/y1 meaning depends on orientation
**How to avoid:**
- `y0` is the baseline (typically `yScale(0)` for upright areas)
- `y1` is the topline (data values)
- When `coord_flip`, swap to `x0` (baseline) and `x1` (topline)
- Check if zero is in scale domain; if not, use domain min as baseline
**Warning signs:** Area "hangs" from top of chart, or floats above zero line

### Pitfall 2: geom_area vs geom_ribbon Stat Difference
**What goes wrong:** Stacked area charts don't align when groups have different x-values
**Why it happens:** geom_area uses `stat="align"` by default, geom_ribbon uses `stat="identity"`
**How to avoid:**
- For Phase 4, implement basic identity behavior only
- Document that `stat_align()` interpolation is deferred to later phase
- Test with aligned x-values initially
**Warning signs:** GitHub issues reporting "stacked areas have gaps"

### Pitfall 3: Reference Lines Ignore Aesthetics from Plot
**What goes wrong:** Reference lines inherit plot-level `aes(color=species)` and fail
**Why it happens:** ggplot2 reference lines explicitly don't inherit x/y aesthetics
**How to avoid:**
- In R layer: don't include plot aesthetics in reference line data
- In JS layer: reference lines only use `params`, not `aes` mappings
- Always use `params.yintercept`, never `aes.y`
**Warning signs:** Console errors about missing data columns for hline/vline

### Pitfall 4: Segment Coordinate Swapping with coord_flip
**What goes wrong:** Segments render at wrong angle when flipped
**Why it happens:** Both start and end points need axis swapping, not just one
**How to avoid:**
- When flip: `x1 = yScale(y)`, `y1 = xScale(x)`, `x2 = yScale(yend)`, `y2 = xScale(xend)`
- Test with diagonal segments that should remain diagonal after flip
**Warning signs:** Segments become horizontal/vertical instead of maintaining angle

### Pitfall 5: Missing Data Gaps in Areas
**What goes wrong:** Area path connects through NA values, creating misleading visuals
**Why it happens:** Default d3.area() behavior connects all points
**How to avoid:**
- Use `.defined(d => d.y != null && d.x != null)` on area generator
- This creates separate path segments for continuous data runs
**Warning signs:** Areas span across gaps where no data exists

## Code Examples

Verified patterns from official sources:

### D3 Area Generator (Vertical Orientation)
```javascript
// Source: https://d3js.org/d3-shape/area
const area = d3.area()
  .x(d => xScale(d.x))          // Horizontal position
  .y0(yScale(0))                // Baseline (bottom)
  .y1(d => yScale(d.y))         // Topline (from data)
  .defined(d => d.y != null);   // Skip NA values

svg.append("path")
  .attr("d", area(data))
  .attr("fill", "steelblue");
```

### D3 Area Generator (Horizontal Orientation / coord_flip)
```javascript
// Source: https://d3js.org/d3-shape/area
const area = d3.area()
  .y(d => xScale(d.x))          // Vertical position (original x)
  .x0(yScale(0))                // Baseline (left edge)
  .x1(d => yScale(d.y))         // Topline (from data)
  .defined(d => d.y != null);

svg.append("path")
  .attr("d", area(data))
  .attr("fill", "steelblue");
```

### Ribbon with ymin/ymax
```javascript
// Source: https://d3js.org/d3-shape/area
const ribbon = d3.area()
  .x(d => xScale(d.x))
  .y0(d => yScale(d.ymin))      // Lower bound
  .y1(d => yScale(d.ymax))      // Upper bound
  .defined(d => d.ymin != null && d.ymax != null);

svg.append("path")
  .attr("d", ribbon(data))
  .attr("fill", "steelblue")
  .attr("fill-opacity", 0.3);   // Ribbons often translucent
```

### SVG Line Element for Segment
```javascript
// Source: Existing point.js pattern + SVG line element spec
svg.append("line")
  .attr("x1", xScale(d.x))
  .attr("y1", yScale(d.y))
  .attr("x2", xScale(d.xend))
  .attr("y2", yScale(d.yend))
  .attr("stroke", "black")
  .attr("stroke-width", 2);
```

### Reference Line Spanning Full Width
```javascript
// Source: ggplot2 geom_hline behavior
const yPos = yScale(yintercept);

svg.append("line")
  .attr("x1", 0)
  .attr("y1", yPos)
  .attr("x2", plotWidth)
  .attr("y2", yPos)
  .attr("stroke", "red")
  .attr("stroke-dasharray", "4,4");  // Optional: dashed line
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| size aesthetic for line widths | linewidth aesthetic | ggplot2 3.4.0 (Nov 2022) | geom_segment/ribbon use `linewidth`, not `size` |
| Manual baseline calculation | d3.area() y0 accessor | D3 v4+ | Cleaner API, built-in inversion handling |
| outline.type parameter | Different defaults per geom | ggplot2 3.3.0+ | geom_area defaults to "upper" outline, ribbon to "both" |

**Deprecated/outdated:**
- **size for line widths:** ggplot2 3.4.0+ uses `linewidth` aesthetic for lines; `size` is for point area only
- **d3.svg.area():** D3 v3 API (now `d3.area()` in v7)
- **stat_align() for non-stacked areas:** Only needed for stacking; defer implementation

## Open Questions

1. **Should we implement arrow support for geom_segment in Phase 4?**
   - What we know: ggplot2 supports `arrow` parameter via `grid::arrow()`
   - What's unclear: SVG arrow markers require marker definitions, coordinate transformation is complex with coord_flip
   - Recommendation: Defer arrows to future phase; document as limitation

2. **How to handle geom_abline (diagonal lines) with coord_flip?**
   - What we know: geom_abline uses slope/intercept, requires calculating endpoints from scale domains
   - What's unclear: Slope meaning inverts with coord_flip (slope in data space vs pixel space)
   - Recommendation: Calculate endpoints in data space, then transform to pixel space with scales

3. **Should geom_area support stat="align" interpolation in Phase 4?**
   - What we know: stat_align() is needed for stacking areas with misaligned x-values
   - What's unclear: Complexity of interpolation algorithm vs immediate user need
   - Recommendation: Start with stat="identity" only; add stat="align" in Phase 5 (stacking)

4. **Do we need outline.type parameter for areas/ribbons?**
   - What we know: ggplot2 has outline.type to control which edges get stroked
   - What's unclear: User demand for outlined areas vs default filled-only areas
   - Recommendation: Default to no outline (areas typically don't have strokes); add outline support if requested

## Sources

### Primary (HIGH confidence)
- [D3.js v7 Areas API](https://d3js.org/d3-shape/area) - Area generator documentation
- [D3.js v7 Curves API](https://d3js.org/d3-shape/curve) - Curve interpolation options
- [ggplot2 geom_ribbon reference](https://ggplot2.tidyverse.org/reference/geom_ribbon.html) - Official geom_area/ribbon docs
- [ggplot2 geom_segment reference](https://ggplot2.tidyverse.org/reference/geom_segment.html) - Official segment/curve docs
- [ggplot2 geom_abline reference](https://ggplot2.tidyverse.org/reference/geom_abline.html) - Official reference line docs
- Existing codebase: `line.js`, `bar.js`, `point.js`, `rect.js`, `geom-registry.js`, `constants.js`

### Secondary (MEDIUM confidence)
- [ggplot2 3.4.0 linewidth change](https://tidyverse.org/blog/2022/08/ggplot2-3-4-0-size-to-linewidth/) - Size vs linewidth aesthetic split
- [R CHARTS reference lines guide](https://r-charts.com/ggplot2/lines-curves/) - Usage patterns and examples
- [SVG line element spec (MDN)](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/line) - SVG line attributes

### Tertiary (LOW confidence - needs validation)
- WebSearch: "stat_align interpolation" - Found description but no source code
- WebSearch: "SVG polygon baseline" - General SVG info, not D3-specific

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - D3 v7 already in use, area() API well-documented
- Architecture: HIGH - Existing geom patterns (line.js, point.js) directly apply
- Pitfalls: MEDIUM - Area baseline and coord_flip interactions need testing

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (30 days - stable APIs)
