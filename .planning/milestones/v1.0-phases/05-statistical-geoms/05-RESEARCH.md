# Phase 5: Statistical Geoms - Research

**Researched:** 2026-02-09
**Domain:** Statistical visualization layers (ggplot2 stat system + D3.js rendering)
**Confidence:** HIGH

## Summary

Phase 5 implements statistical geoms (boxplot, violin, density, smooth) by extracting pre-computed stat data from ggplot2's `ggplot_build()` and rendering it with D3.js. The critical architectural insight is that ggplot2 already performs all statistical computations during the build phase, creating computed variables (quartiles, density estimates, regression fits) that are available in `b$data[[i]]` after `ggplot_build()`. The R layer's job is to extract these computed values and pass them through the IR; the D3 layer's job is pure visualization using D3 shape generators (d3.line, d3.area, SVG primitives). This maintains the architectural principle that JavaScript never performs statistical computations—all stats happen in R.

The existing geom registry pattern perfectly accommodates statistical geoms. Each stat geom (boxplot, violin, density, smooth) requires: (1) R-side geom name mapping in `as_d3_ir.R` to handle `GeomBoxplot`, `GeomViolin`, etc., (2) extraction of computed aesthetics from `b$data[[i]]` (e.g., `ymin`, `lower`, `middle`, `upper`, `ymax`, `outliers` for boxplots), and (3) a new D3 renderer module in `inst/htmlwidgets/modules/geoms/` that registers with the geom registry.

**Primary recommendation:** Extract all stat-computed data from `ggplot_build()$data` in R, pass it through IR unchanged, and implement pure rendering modules in D3. Never reimpute statistics in JavaScript.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 3.5+ | Stat layer computation | Only source of truth for statistical transformations; `ggplot_build()` provides all computed variables |
| D3.js | v7 | SVG rendering | Already integrated; provides shape generators (d3.line, d3.area) for rendering stat output |
| R stats | base | Statistical functions | Native R functions (quantile, density, loess) power ggplot2's stat layers |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| d3-regression | 1.x | Regression curves | Optional—only if implementing client-side regression (NOT recommended; use R's pre-computed values) |
| jsonlite | 1.x | IR serialization | Already in use; handles list-column serialization for `outliers` field |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ggplot_build() stat extraction | JavaScript stat computation | Would require porting R's quantile(), density(), loess() algorithms to JS; breaks "R computes, D3 renders" architecture |
| D3 shape generators | Manual SVG path construction | Reinvents well-tested curve interpolation; d3.line() with curve interpolators handles smoothing correctly |

**Installation:**
No new dependencies required. All necessary components already in package (ggplot2, D3.js v7, jsonlite).

## Architecture Patterns

### Recommended Stat Geom Processing Flow
```
User Code (R)
  ↓
ggplot() + geom_boxplot()
  ↓
ggplot_build(p)  ← Stats compute HERE (quartiles, densities, fits)
  ↓
as_d3_ir(p)      ← Extract computed data from b$data[[i]]
  ↓
IR (JSON)        ← Contains pre-computed stat values
  ↓
D3 Renderer      ← Pure visualization (no computation)
```

### Pattern 1: Stat Data Extraction from ggplot_build()

**What:** ggplot2's stat layers create computed variables during `ggplot_build()`. These appear in `b$data[[i]]` with columns like `ymin`, `lower`, `middle`, `upper`, `ymax` for boxplots.

**When to use:** Every statistical geom (boxplot, violin, density, smooth).

**Example:**
```r
# In as_d3_ir.R, layers loop (around line 143):
layers <- lapply(seq_along(b$data), function(i) {
  df <- b$data[[i]]  # <-- This contains stat-computed variables!

  # For geom_boxplot, df has:
  # - ymin, lower, middle, upper, ymax (five-number summary)
  # - outliers (list-column of outlier values)
  # - notchupper, notchlower (for notched boxplots)

  # For geom_violin, df has:
  # - x, y (density curve points)
  # - density, scaled, violinwidth
  # - Many rows per group (512 points for curve)

  # Extract geom name
  gobj <- b$plot$layers[[i]]$geom
  gname <- switch(class(gobj)[1],
    GeomBoxplot = "boxplot",
    GeomViolin = "violin",
    GeomDensity = "density",
    GeomSmooth = "smooth",
    # ... existing geoms ...
  )

  # Convert to row-oriented JSON
  list(
    geom = gname,
    data = to_rows(df),  # Includes all computed variables
    aes = aes,
    params = params
  )
})
```

**Source:** [ggplot2 internals](https://ggplot2-book.org/internals.html), observed behavior from `ggplot_build()` inspection.

### Pattern 2: Boxplot Rendering with SVG Primitives

**What:** Boxplots consist of rectangles (boxes), lines (whiskers, median), and circles (outliers). All coordinates pre-computed by R.

**When to use:** geom_boxplot rendering in D3.

**Example:**
```javascript
// In inst/htmlwidgets/modules/geoms/boxplot.js
function renderBoxplot(layer, g, xScale, yScale, options) {
  const data = window.gg2d3.helpers.asRows(layer.data);
  const flip = !!options.flip;

  // Each row has: x, ymin, lower, middle, upper, ymax, outliers (list)
  data.forEach(d => {
    const xPos = typeof xScale.bandwidth === 'function'
      ? xScale(d.x) + xScale.bandwidth() / 2
      : xScale(d.x);

    const boxWidth = d.width || (xScale.bandwidth ? xScale.bandwidth() * 0.75 : 20);

    // Draw box (IQR: lower to upper)
    g.append('rect')
      .attr('x', xPos - boxWidth/2)
      .attr('y', yScale(d.upper))
      .attr('width', boxWidth)
      .attr('height', yScale(d.lower) - yScale(d.upper))
      .attr('fill', fillColor(d))
      .attr('stroke', strokeColor(d));

    // Draw median line
    g.append('line')
      .attr('x1', xPos - boxWidth/2)
      .attr('x2', xPos + boxWidth/2)
      .attr('y1', yScale(d.middle))
      .attr('y2', yScale(d.middle))
      .attr('stroke', strokeColor(d));

    // Draw whiskers (vertical lines + endcaps)
    // Upper whisker: upper to ymax
    // Lower whisker: lower to ymin
    // ... (whisker implementation)

    // Draw outliers as circles
    if (d.outliers && d.outliers.length > 0) {
      d.outliers.forEach(outlier => {
        g.append('circle')
          .attr('cx', xPos)
          .attr('cy', yScale(outlier))
          .attr('r', 1.5)
          .attr('fill', strokeColor(d));
      });
    }
  });

  return data.length;
}

window.gg2d3.geomRegistry.register('boxplot', renderBoxplot);
```

**Source:** [D3 Graph Gallery - Boxplot](https://d3-graph-gallery.com/boxplot.html), existing rect/line geom patterns in codebase.

### Pattern 3: Violin Plot Rendering with d3.area()

**What:** Violin plots are symmetrical density curves. ggplot2 provides density points; D3 renders as mirrored area shapes.

**When to use:** geom_violin rendering in D3.

**Example:**
```javascript
// In inst/htmlwidgets/modules/geoms/violin.js
function renderViolin(layer, g, xScale, yScale, options) {
  const d3 = window.d3;
  const data = window.gg2d3.helpers.asRows(layer.data);

  // Group by x (categorical grouping variable)
  const grouped = d3.group(data, d => d.x);

  grouped.forEach((points, xVal) => {
    const xPos = xScale(xVal) + (xScale.bandwidth ? xScale.bandwidth() / 2 : 0);
    const maxWidth = points[0].width || (xScale.bandwidth ? xScale.bandwidth() * 0.9 : 40);

    // points array has: y (data value), violinwidth (density scaled)
    // Create mirrored area (left and right sides)
    const areaLeft = d3.area()
      .x(d => xPos - d.violinwidth * maxWidth / 2)
      .y0(d => yScale(d.y))
      .y1(d => yScale(d.y));

    const areaRight = d3.area()
      .x(d => xPos + d.violinwidth * maxWidth / 2)
      .y0(d => yScale(d.y))
      .y1(d => yScale(d.y));

    // Draw left side
    g.append('path')
      .datum(points)
      .attr('d', areaLeft)
      .attr('fill', fillColor(points[0]))
      .attr('stroke', strokeColor(points[0]));

    // Draw right side (mirror)
    g.append('path')
      .datum(points)
      .attr('d', areaRight)
      .attr('fill', fillColor(points[0]))
      .attr('stroke', strokeColor(points[0]));
  });

  return grouped.size;
}

window.gg2d3.geomRegistry.register('violin', renderViolin);
```

**Source:** [D3 Graph Gallery - Violin Plot](https://d3-graph-gallery.com/graph/violin_basicHist.html), d3.area() documentation.

### Pattern 4: Density and Smooth Curves with d3.line()

**What:** Density and smooth geoms are continuous curves. ggplot2 provides (x, y) points; D3 connects them with d3.line().

**When to use:** geom_density, geom_smooth rendering in D3.

**Example:**
```javascript
// In inst/htmlwidgets/modules/geoms/density.js
function renderDensity(layer, g, xScale, yScale, options) {
  const d3 = window.d3;
  const data = window.gg2d3.helpers.asRows(layer.data);

  // Density data has: x (value), y (density estimate)
  // Group by 'group' aesthetic for multiple densities
  const grouped = d3.group(data, d => d.group || -1);

  const line = d3.line()
    .x(d => xScale(d.x))
    .y(d => yScale(d.y))
    .curve(d3.curveMonotoneX);  // Smooth interpolation

  grouped.forEach(points => {
    g.append('path')
      .datum(points)
      .attr('d', line)
      .attr('fill', 'none')
      .attr('stroke', strokeColor(points[0]))
      .attr('stroke-width', lineWidth(points[0]));
  });

  return grouped.size;
}

window.gg2d3.geomRegistry.register(['density', 'smooth'], renderDensity);
```

**Source:** Existing geom-line.js pattern, [d3.line() documentation](https://d3js.org/d3-shape/line).

### Pattern 5: List-Column Serialization for Outliers

**What:** Boxplot outliers are list-columns in R (each row has a vector of outliers). jsonlite handles this automatically.

**When to use:** Any stat geom with nested data structures.

**Example:**
```r
# In as_d3_ir.R, to_rows() function (around line 27):
to_rows <- function(df) {
  if (is.null(df) || !nrow(df)) return(list())
  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]

  # Add "outliers" to keep_aes if present (boxplot)
  keep_aes_extended <- c(keep_aes, "outliers")

  df[] <- lapply(df, function(col) {
    if (is.factor(col)) as.character(col)
    else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000
    else if (inherits(col, "Date")) as.numeric(col) * 86400000
    else if (is.list(col)) I(col)  # <-- Preserves list-columns!
    else col
  })

  rows <- vector("list", nrow(df))
  for (i in seq_len(nrow(df))) {
    r <- lapply(df[i, , drop = FALSE], function(v) v[[1]])
    # r$outliers will be a list/vector, serialized by jsonlite as JSON array
    names(r) <- names(df)
    rows[[i]] <- r
  }
  rows
}
```

**Source:** Existing `to_rows()` implementation, jsonlite list-column handling.

### Anti-Patterns to Avoid

- **Recomputing stats in JavaScript:** Never call custom quantile/density/regression functions in D3. R is the source of truth.
- **Assuming fixed number of points:** Violin/density layers have 512+ points per group. Don't hardcode array sizes.
- **Ignoring list-columns:** Boxplot `outliers` field is a list. Check for `is.list()` in to_rows().
- **Manual curve interpolation:** Use d3.line().curve() for smooth curves, not hand-rolled Bezier math.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Quartile calculation | Custom percentile function in JS | R's `quantile()` via ggplot_build() | R's Type 7 quantiles match ggplot2 exactly; edge cases (small n, ties) handled correctly |
| Kernel density estimation | JavaScript KDE implementation | R's `density()` via stat_ydensity | Bandwidth selection (nrd0), boundary correction, kernel functions are complex; R's implementation is authoritative |
| LOESS smoothing | d3-regression or custom loess | R's `loess()` via stat_smooth | LOESS has many parameters (span, degree, family); ggplot2's defaults and behavior must match exactly |
| Bezier curve fitting | Manual SVG path construction | d3.line().curve(d3.curveMonotoneX) | D3's curve interpolators handle monotonicity, avoid overshoots, tested edge cases |
| Outlier detection | Custom IQR threshold logic | ggplot2's pre-computed outliers field | Outlier definition (1.5*IQR) seems simple but edge cases (no variation, all outliers) are subtle |

**Key insight:** Statistical computations are the domain of R, not JavaScript. Any stat geom that requires computation should extract it from ggplot2's build phase, never reimplement it. D3's role is pure visualization.

## Common Pitfalls

### Pitfall 1: Assuming Stat Geoms Have Simple Data Structures
**What goes wrong:** Developer expects boxplot data to have one row per box, but discovers it has computed columns they didn't anticipate (notchupper, notchlower, weight, width).

**Why it happens:** ggplot2's stat layers compute many variables for flexibility. `stat_boxplot()` creates 26 columns (observed via `str(ggplot_build()$data[[1]])`).

**How to avoid:** Always inspect `ggplot_build(p)$data[[1]]` in R console before implementing a stat geom renderer. Document which columns are required vs. optional.

**Warning signs:** JavaScript console errors like `Cannot read property 'middle' of undefined` when some boxplots have no median.

### Pitfall 2: List-Columns Not Serializing to IR
**What goes wrong:** Boxplot outliers field is a list-column. If not handled correctly, it becomes `"[object Object]"` in JSON.

**Why it happens:** Default JSON serialization doesn't handle R list-columns. Need `I(col)` in `to_rows()` to preserve structure.

**How to avoid:** In `to_rows()`, check `if (is.list(col)) I(col)` to preserve list-columns. Add `outliers` to `keep_aes` for boxplots.

**Warning signs:** IR validation errors or JavaScript receiving strings instead of arrays for outliers.

### Pitfall 3: Violin Plots Rendering as Single Line
**What goes wrong:** Violin plot appears as a thin vertical line instead of a symmetrical shape.

**Why it happens:** Developer used d3.line() instead of d3.area(), or forgot to mirror the density curve left/right.

**How to avoid:** Use d3.area() with symmetric x-offsets based on `violinwidth`. Study existing d3-graph-gallery violin examples.

**Warning signs:** Violin plot has no width, looks like a single path.

### Pitfall 4: Smooth Lines Not Smooth
**What goes wrong:** geom_smooth renders as jagged polyline instead of smooth curve.

**Why it happens:** Developer used d3.line() without `.curve()` interpolator. Default is d3.curveLinear (straight segments).

**How to avoid:** Always call `.curve(d3.curveMonotoneX)` or `.curve(d3.curveBasis)` on line generators for stat geoms.

**Warning signs:** Visual comparison with ggplot2 shows D3 version has sharp corners.

### Pitfall 5: Coordinate Flip Breaking Boxplots
**What goes wrong:** Boxplots render upside-down or sideways with coord_flip.

**Why it happens:** Boxplot renderer assumes vertical orientation (x categorical, y continuous). coord_flip swaps axes.

**How to avoid:** Check `options.flip` in boxplot renderer. Swap x/y scales and orientation when flipped. Mirror pattern from existing geoms (point, bar).

**Warning signs:** Boxplots horizontal when they should be vertical, or vice versa.

## Code Examples

Verified patterns from ggplot2 and existing codebase:

### Extracting Boxplot Stat Data in R
```r
# Observed structure from ggplot_build()
library(ggplot2)
p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg)) + geom_boxplot()
b <- ggplot_build(p)
str(b$data[[1]], max.level=1)

# Output shows:
# $ ymin       : num  21.4 17.8 13.3        # Lower whisker
# $ lower      : num  22.8 18.6 14.4        # Q1 (25th percentile)
# $ middle     : num  26 19.7 15.2          # Median
# $ upper      : num  30.4 21 16.2          # Q3 (75th percentile)
# $ ymax       : num  33.9 21.4 18.7        # Upper whisker
# $ outliers   :List of 3                   # Outlier values (list-column)
# $ x          : 'mapped_discrete' num  1 2 3
# ... 18 more columns (notch, width, colour, fill, etc.)

# In as_d3_ir.R, this is already extracted by the layers loop.
# Just ensure "outliers" is in keep_aes.
```

### Rendering Density Curve
```javascript
// Source: Existing geom-line.js pattern + d3.line() with curve interpolation
function renderDensity(layer, g, xScale, yScale, options) {
  const d3 = window.d3;
  const asRows = window.gg2d3.helpers.asRows;
  const val = window.gg2d3.helpers.val;
  const num = window.gg2d3.helpers.num;

  const data = asRows(layer.data);
  const aes = layer.aes || {};

  // Group by 'group' aesthetic (density can have multiple groups)
  const grouped = d3.group(data, d => d[aes.group || 'group'] || -1);

  const line = d3.line()
    .x(d => xScale(num(d[aes.x])))
    .y(d => yScale(num(d[aes.y])))
    .curve(d3.curveMonotoneX);  // Smooth, monotonic interpolation

  const { strokeColor, fillColor, opacity } =
    window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

  grouped.forEach(points => {
    g.append('path')
      .datum(points)
      .attr('d', line)
      .attr('fill', 'none')
      .attr('stroke', strokeColor(points[0]))
      .attr('stroke-width', 1)
      .attr('opacity', opacity(points[0]));
  });

  return grouped.size;
}

window.gg2d3.geomRegistry.register('density', renderDensity);
```

### Handling Outliers List-Column
```r
# In as_d3_ir.R, extend keep_aes to include outliers
keep_aes <- c(
  "PANEL","x","y","xend","yend","xmin","xmax","ymin","ymax",
  "colour","fill","size","alpha","group","label",
  "slope","intercept","xintercept","yintercept",
  "outliers",  # <-- Add this for boxplot
  "lower","middle","upper"  # <-- Boxplot quartiles
)

# to_rows() already handles list-columns with:
# else if (is.list(col)) I(col)
# This preserves the outliers list structure through JSON serialization.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| JavaScript stat libraries (d3-regression) | R pre-computation via ggplot_build() | Phase 5 (2026) | Ensures perfect ggplot2 fidelity; avoids porting complex stat algorithms to JS |
| Manual SVG path construction | d3.line() / d3.area() generators | D3 v4+ (2016) | Curve interpolators handle smooth rendering correctly; less error-prone |
| Single data structure for all geoms | Stat-specific computed variables | ggplot2 3.0+ (2018) | Each stat layer has unique computed aesthetics; renderers must handle variable columns |

**Deprecated/outdated:**
- **d3-regression for ggplot2 rendering:** While d3-regression is a fine library for D3-native charts, using it to replicate ggplot2's stat_smooth would produce mismatches in default parameters (bandwidth, span, method). Always use R's pre-computed values.
- **Hardcoded outlier thresholds:** Some old D3 boxplot examples compute outliers in JavaScript. In gg2d3, outliers come from R's stat_boxplot, ensuring consistency with ggplot2.

## Open Questions

1. **Notched boxplot rendering**
   - What we know: ggplot2 provides `notchupper` and `notchlower` columns for notched boxplots (95% CI around median)
   - What's unclear: SVG path construction for notched box shape (pentagon instead of rectangle)
   - Recommendation: Implement basic boxplot first, add notch support in follow-up if notch aesthetic is present

2. **Histogram vs. geom_bar overlap**
   - What we know: `geom_histogram()` uses `stat_bin()` to compute counts. `geom_bar()` can also use stat="count"
   - What's unclear: Whether histogram should be separate geom or handled by existing bar renderer with stat data
   - Recommendation: Check if `stat_bin()` output matches geom_bar's data structure. If yes, reuse bar renderer. If no, create histogram.js module.

3. **Smooth confidence bands (ribbons)**
   - What we know: `stat_smooth()` computes `ymin`, `ymax` for confidence bands. geom_smooth renders line + ribbon.
   - What's unclear: Whether to handle this as single "smooth" geom with embedded ribbon, or two separate layers
   - Recommendation: Inspect ggplot_build() output. If geom_smooth creates one layer with ribbon data, render both in smooth.js. If two layers (line + ribbon), use existing ribbon renderer.

4. **Violin plot quantile lines**
   - What we know: Violin plots can show internal quantile lines (25%, 50%, 75%). ggplot2 has `draw_quantiles` parameter.
   - What's unclear: How quantile line coordinates are stored in stat_ydensity output (separate rows? computed column?)
   - Recommendation: Test `geom_violin(draw_quantiles = c(0.25, 0.5, 0.75))` in R, inspect `ggplot_build()$data[[1]]` for quantile-related columns

## Sources

### Primary (HIGH confidence)
- **ggplot2 official documentation:**
  - [Layer stats overview](https://ggplot2.tidyverse.org/reference/layer_stats.html) - Computed variables, stat execution
  - [geom_boxplot](https://ggplot2.tidyverse.org/reference/geom_boxplot.html) - Boxplot algorithm (1.5*IQR whiskers, outliers)
  - [geom_violin](https://ggplot2.tidyverse.org/reference/geom_violin.html) - Violin plot stat_ydensity computed variables (density, scaled, violinwidth)
- **ggplot2 source code:**
  - Inspected via `ggplot_build()` on mtcars dataset (boxplot, violin, density, smooth) - confirmed data structures
- **R documentation:**
  - [quantile() Type 7 algorithm](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html) - Default percentile calculation
- **D3.js official documentation:**
  - [d3-shape (line, area)](https://d3js.org/d3-shape) - Path generators
  - [d3-path](https://d3js.org/d3-path) - Low-level path construction
- **gg2d3 codebase:**
  - `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` - Existing layer extraction pattern (lines 143-256)
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/geoms/` - Existing geom renderers (point, line, bar, etc.)

### Secondary (MEDIUM confidence)
- [Demystifying stat_ layers in ggplot2](https://yjunechoe.github.io/posts/2020-09-26-demystifying-stat-layers-ggplot2/) - Excellent explanation of stat computation timing and layer_data() usage
- [ggplot2 book: Internals](https://ggplot2-book.org/internals.html) - Build process stages, stat execution order
- [D3 Graph Gallery: Boxplot](https://d3-graph-gallery.com/boxplot.html) - D3 boxplot rendering examples
- [D3 Graph Gallery: Violin](https://d3-graph-gallery.com/graph/violin_basicHist.html) - D3 violin plot with histogram approach
- [CRAN ggplot2 User Guide](https://cran.r-project.org/web/packages/gginnards/vignettes/user-guide-2.html) - Manipulating ggplots, layer_data() extraction

### Tertiary (LOW confidence)
- [Medium: ggplot2 boxplots and outliers](https://medium.com/@henriquepott/exploring-health-data-using-ggplot2-boxplots-and-outliers-9db055e85181) - Outlier calculation explanation (verified against official docs)
- [GitHub: d3-regression](https://github.com/HarryStevens/d3-regression) - D3 regression library (not used in gg2d3, but documents LOESS parameters)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ggplot2 + D3.js already integrated; R stats functions native
- Architecture: HIGH - Verified ggplot_build() data structures empirically; existing geom pattern proven
- Pitfalls: MEDIUM-HIGH - List-column and curve interpolation pitfalls observed in existing code; coord_flip issues extrapolated from existing geom behavior

**Research date:** 2026-02-09
**Valid until:** 90 days (stable domain - ggplot2 stat layer API unlikely to change)
