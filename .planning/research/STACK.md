# Stack Research

**Domain:** ggplot2-to-D3.js translation layer with pixel-perfect fidelity and interactivity
**Researched:** 2026-02-07
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| D3.js | 7.9.0 | Low-level SVG rendering engine | Latest stable version (March 2024). Provides modular architecture with granular control over scales, shapes, and DOM manipulation. Pure ES modules enable tree-shaking for smaller bundles. Industry standard for custom data visualizations requiring pixel-level control. |
| htmlwidgets | 1.6.4+ | R-to-JavaScript bridge | CRAN-standard framework for R bindings to JavaScript libraries. Enables seamless embedding in R Markdown, Shiny apps, and standalone HTML. Well-established with comprehensive documentation and ecosystem support. |
| R (ggplot2) | 3.5.0+ | Source plotting system | ggplot2 3.5.0 (Feb 2024) introduced improved legend system and guide positioning. Provides complete theme specification system and robust geometry layer API for extraction. |

### D3.js Modules (Granular Dependencies)

| Module | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| d3-selection | 3.x | DOM manipulation and data binding | Core module for all rendering. Required for SVG element creation and updates. |
| d3-scale | 4.x | Data-to-visual mappings | Required for all geoms. Supports continuous (linear, log, sqrt, pow, symlog), time, categorical (band, point, ordinal), and discrete (quantize, quantile, threshold) scales. Maps directly to ggplot2 scale types. |
| d3-shape | 3.x | Path generators for complex geometries | Essential for area, line, curve, arc, pie, stack, and symbol rendering. Provides built-in curve interpolators (linear, basis, cardinal, catmull-rom, monotone). |
| d3-axis | 3.x | Axis rendering and tick generation | Required for pixel-perfect axis reproduction. Handles tick positioning, formatting, and label placement. |
| d3-color | 3.x | Color space manipulation | Needed for color interpolation and ggplot2 color name conversion (e.g., grey0-grey100 to hex). |
| d3-interpolate | 3.x | Value interpolation | Required for smooth transitions and animations. Supports numbers, colors, transforms, and custom interpolators. |
| d3-format | 3.x | Number and date formatting | Essential for axis labels and tooltip formatting matching ggplot2 output. |
| d3-array | 3.x | Statistical operations | Needed for extent, min, max, quantile, and binning operations that match ggplot2 stat transformations. |
| d3-transition | 3.x | Animated transitions | Optional for basic rendering, critical for interactive features. Enables smooth data updates. |
| d3-ease | 3.x | Easing functions | Works with d3-transition for animation timing. Matches ggplot2 smooth aesthetic transitions. |
| d3-brush | 3.x | Selection brushing | Required for crosstalk integration and linked brushing functionality. |
| d3-zoom | 3.x | Pan and zoom behaviors | Optional advanced feature for interactive exploration. |

### Supporting R Packages

| Package | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| crosstalk | 1.2.1+ | Inter-widget communication | For linked brushing and filtering across multiple plots. Works without Shiny. Limitation: client-side only, not suitable for >10k points. |
| grid | Built-in | Unit conversion utilities | Essential for converting ggplot2 theme units (mm, pt, inches) to pixels. Already using `grid::convertUnit()` in current implementation. |
| jsonlite | 1.8.8+ | JSON serialization | For IR (intermediate representation) serialization. Fast C-based implementation handles complex nested structures. |
| testthat | 3.2.0+ | Testing framework | For regression tests comparing ggplot2 PNG output to D3 SVG rendering metrics. |
| vdiffr | 1.0.7+ | Visual regression testing | For automated visual comparison of plot outputs. Generates SVG snapshots for comparison. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| devtools | Package development workflow | Standard R package development (load_all, document, test) |
| roxygen2 | Documentation generation | Inline documentation with @export tags |
| ESLint | JavaScript linting | Enforce consistent code style in D3 renderer |
| Prettier | JavaScript formatting | Auto-format gg2d3.js for consistency |
| R CMD check | CRAN compliance | Ensure package meets CRAN standards |

## Installation

```r
# Core R dependencies (add to DESCRIPTION)
Imports:
  ggplot2 (>= 3.5.0),
  htmlwidgets (>= 1.6.0),
  jsonlite,
  grid

Suggests:
  crosstalk (>= 1.2.0),
  testthat (>= 3.0.0),
  vdiffr

# D3.js vendoring (manual download to inst/htmlwidgets/lib/)
dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file("https://d3js.org/d3.v7.min.js",
              destfile = "inst/htmlwidgets/lib/d3/d3.v7.min.js", mode = "wb")
```

```bash
# JavaScript development dependencies (optional, for linting)
npm install --save-dev eslint prettier
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative | Why Not Primary |
|-------------|-------------|-------------------------|-----------------|
| D3.js v7 | D3.js v8 (future) | When v8 is released with new features | v8 not yet released; v7.9.0 is latest stable (March 2024) |
| D3.js (SVG) | Canvas rendering | For >5000 points or high-frequency updates | SVG provides better accessibility, responsiveness, and exact ggplot2 fidelity. Canvas sacrifices DOM structure. |
| Custom D3 renderer | plotly.js (via ggplotly) | When speed to market matters more than fidelity | plotly.js doesn't preserve all ggplot2 aesthetics (subtitles, complex themes). Black-box approach limits customization. |
| Custom D3 renderer | ggiraph | When pixel-perfect fidelity not required | ggiraph closer to ggplot2 than plotly but still wrapper-based. Less control over rendering pipeline. |
| crosstalk | Shiny reactivity | For server-side filtering or >10k points | crosstalk is client-side only but enables static HTML deployment. Shiny requires server. |
| htmlwidgets | R Markdown native | For simple static plots | htmlwidgets enables reusable widget, Shiny integration, and crosstalk compatibility. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| D3.js v3-v5 | Outdated API, lacks ES modules, larger bundle size | D3.js v7.9.0 |
| ggvis | Abandoned (last update 2016), never reached production stability | Custom D3 with htmlwidgets |
| d3-tip (tooltip library) | Unmaintained, incompatible with D3 v7 | Tippy.js or custom SVG tooltips |
| Direct HTML strings | Security risk (XSS), hard to maintain | D3 selection API for DOM manipulation |
| Inline CSS in JavaScript | Poor separation of concerns, harder theming | CSS classes or inline styles via D3 `.style()` |
| Global D3 functions without namespace | Name collisions in complex apps | Use modular imports or namespaced D3 object |
| Fixed pixel values for all sizes | Breaks responsiveness | Relative units or dynamic calculation from container size |

## Stack Patterns by Variant

### Pattern 1: Static HTML Output (Current)
**Use when:** Generating standalone HTML reports or R Markdown documents
```
R (ggplot2) → as_d3_ir() → JSON → htmlwidget() → D3.js (SVG)
```
**Stack:** ggplot2 + htmlwidgets + D3.js v7 (core modules only)
**Trade-off:** No server required, limited to client-side data

### Pattern 2: Interactive with Crosstalk
**Use when:** Linked brushing across multiple plots in static HTML
```
R (SharedData) → multiple gg2d3() → crosstalk bridge → D3 brush events
```
**Stack:** ggplot2 + htmlwidgets + crosstalk + D3.js (add d3-brush, d3-transition)
**Limitation:** Client-side only, <10k points per dataset

### Pattern 3: Shiny Integration
**Use when:** Server-side filtering, large data, or dynamic plot updates
```
Shiny server → renderUI(gg2d3(...)) → updateData() → D3 re-render
```
**Stack:** ggplot2 + htmlwidgets + Shiny + D3.js (add d3-transition for smooth updates)
**Trade-off:** Requires running R server, but handles unlimited data size

### Pattern 4: Hybrid SVG + Canvas
**Use when:** >5000 points but need axes/labels/tooltips
```
Canvas layer (data marks) + SVG layer (axes, labels, interactions)
```
**Stack:** ggplot2 + htmlwidgets + D3.js + custom Canvas renderer
**Complexity:** High - requires dual rendering pipeline

## Rendering Approach: SVG vs Canvas

**Recommendation:** SVG for primary implementation, Canvas as future optimization

| Criterion | SVG (Recommended) | Canvas (Future Option) |
|-----------|-------------------|------------------------|
| Performance | Excellent <5k elements | Excellent >5k elements |
| Accessibility | Full DOM structure for screen readers | Requires ARIA fallbacks |
| Responsiveness | Scales perfectly to any resolution | Requires redraw on resize |
| Interactivity | Easy event listeners per element | Requires manual hit detection |
| ggplot2 Fidelity | Exact pixel-perfect match possible | Harder to match text/stroke rendering |
| Browser Consistency | Slight anti-aliasing differences | More consistent rendering |

**Decision:** Start with SVG (90% use cases fit <5k points). Add Canvas rendering for specific geoms (e.g., `geom_point` with >5k observations) in later phase.

## Scale Type Coverage

### Required D3 Scale Types for ggplot2 Parity

| ggplot2 Transform | D3 Scale | Current Support | Priority |
|-------------------|----------|-----------------|----------|
| identity/continuous | scaleLinear | ✅ Full | Core |
| log/log10/log2 | scaleLog | ✅ Full | Core |
| sqrt | scaleSqrt | ✅ Full | Core |
| reverse | scaleLinear + reversed domain | ⚠️ Partial | High |
| discrete/factor | scaleBand | ✅ Full | Core |
| discrete/factor | scalePoint | ⚠️ Missing | Medium |
| date/datetime | scaleTime | ✅ Full | Core |
| date/datetime (UTC) | scaleUtc | ⚠️ Missing | Low |
| pow/power | scalePow | ✅ Full | Medium |
| symlog | scaleSymlog | ✅ Full | Low |
| quantize | scaleQuantize | ⚠️ Missing | Low |
| quantile | scaleQuantile | ⚠️ Missing | Low |
| threshold | scaleThreshold | ⚠️ Missing | Low |
| ordinal (color) | scaleOrdinal | ✅ Full | Core |
| sequential (color) | scaleSequential | ✅ Full | Medium |
| diverging (color) | scaleDiverging | ⚠️ Missing | Medium |

**Assessment:** Current implementation covers 70% of common use cases. Priority gaps: scalePoint (for geom_dotplot), reversed scales, diverging color scales.

## Shape Generator Coverage

### Required D3 Shape Modules for Full Geom Support

| ggplot2 Geom | D3 Shape/Primitive | Current Support | Complexity |
|--------------|-------------------|-----------------|------------|
| geom_point | SVG `<circle>` | ✅ Full | Low |
| geom_line | d3.line() | ✅ Full | Low |
| geom_path | d3.line() (no sort) | ⚠️ Buggy (sorts x) | Low |
| geom_area | d3.area() | ❌ Missing | Low |
| geom_ribbon | d3.area() | ❌ Missing | Low |
| geom_bar/col | SVG `<rect>` | ✅ Full | Low |
| geom_rect/tile | SVG `<rect>` | ✅ Full | Low |
| geom_polygon | d3.line() + closepath | ❌ Missing | Medium |
| geom_segment | SVG `<line>` | ❌ Missing | Low |
| geom_curve | d3.line() + curve interpolator | ❌ Missing | Medium |
| geom_text/label | SVG `<text>` | ⚠️ Partial (no rotation) | Medium |
| geom_abline/hline/vline | SVG `<line>` | ❌ Missing | Low |
| geom_smooth | d3.line() + stat_smooth data | ❌ Missing | Medium |
| geom_boxplot | Multiple SVG primitives | ❌ Missing | High |
| geom_violin | d3.area() + density calc | ❌ Missing | High |
| geom_density | d3.line() + density calc | ❌ Missing | Medium |
| geom_histogram | SVG `<rect>` + binning | ❌ Missing | Medium |
| geom_contour | d3.contours() | ❌ Missing | High |
| geom_hex | SVG `<path>` hexagon | ❌ Missing | High |
| geom_sf | d3.geoPath() | ❌ Missing | Very High |

**Priority Order for Phase 2:**
1. geom_area, geom_ribbon (d3.area() - simple)
2. geom_segment, geom_abline/hline/vline (SVG lines - simple)
3. geom_polygon (close path - simple)
4. geom_text rotation/alignment (transform - medium)
5. geom_smooth (line with stat - medium)
6. geom_boxplot (composite shapes - complex)

## Version Compatibility

| Package | Compatible Versions | Notes |
|---------|-------------------|-------|
| ggplot2 | 3.4.0 - 3.5.x | IR extraction relies on ggplot_build() structure. v3.5.0+ recommended for improved legend system. |
| htmlwidgets | 1.5.4 - 1.6.x | Stable API since v1.5. v1.6.4 (July 2025) is latest. |
| D3.js | 7.0.0 - 7.9.0 | v7 is current stable branch. ES module format required. Avoid v3-v6 (breaking API changes). |
| crosstalk | 1.1.1 - 1.2.x | v1.2.1 stable. API unchanged since v1.1. |
| R | 4.1.0+ | grid::convertUnit() behavior consistent since R 4.1. |

## Interactivity Stack

### Tooltips

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| Tippy.js | 6.3.7 | Tooltip positioning and lifecycle | Production-ready, handles edge cases (viewport bounds, touch events). 20kb gzipped. Better than d3-tip (abandoned). |
| Popper.js | 2.11.x | Tooltip positioning engine | Lower-level alternative to Tippy.js. Use if custom tooltip design critical. |
| Custom SVG | N/A | Simple hover tooltips | For basic tooltips, use SVG `<title>` or positioned `<text>` elements. Zero dependencies. |

**Recommendation:** Start with SVG `<title>` for MVP (accessibility win, zero JS). Add Tippy.js when rich tooltips needed (HTML content, formatting, images).

### Linked Views

| Library | Version | Purpose | Limitation |
|---------|---------|---------|------------|
| crosstalk | 1.2.1 | Client-side linked brushing | <10k points, no aggregations |
| Shiny | 1.8.0+ | Server-side linked brushing | Requires running server |

**Pattern:** Use crosstalk for static HTML reports, Shiny for dashboards with large data.

## Pixel-Perfect Rendering Considerations

### Known Browser Inconsistencies

1. **Sub-pixel rendering:** SVG coordinates can be fractional, causing anti-aliasing differences
   - **Mitigation:** Round coordinates to integer pixels for crisp lines
   - **Trade-off:** Slight position inaccuracy vs. visual clarity

2. **Text rendering:** Font metrics vary across browsers and OS
   - **Mitigation:** Use web fonts (e.g., Google Fonts) for consistency
   - **ggplot2 default:** Uses system fonts (Helvetica/Arial), varies by OS
   - **Recommendation:** Match ggplot2's font family exactly or document differences

3. **Stroke rendering:** 1px lines may render at 0.5px or 1.5px depending on position
   - **Mitigation:** Use `shape-rendering: crispEdges` for rectangles/axes
   - **Current implementation:** Already converts mm to px (1mm = 3.78px at 96 DPI)

4. **Color space:** ggplot2 uses sRGB, browsers default to sRGB but HDR displays differ
   - **Mitigation:** Explicit color profile specification (future CSS Color Level 4)
   - **Current state:** Accept minor color variance on wide-gamut displays

### Testing Strategy for Pixel-Perfect Fidelity

1. **Visual regression:** vdiffr package for automated snapshot comparison
2. **Metric comparison:** Extract computed styles from both ggplot2 PNG and D3 SVG
3. **Cross-browser:** Test on Chrome, Firefox, Safari (different rendering engines)
4. **Acceptance criteria:** <2px position difference, exact color match (hex values)

## Sources

**D3.js Version and Features:**
- [D3.js Releases (GitHub)](https://github.com/d3/d3/releases) — Latest version 7.9.0 (March 2024) verified
- [D3.js Official Documentation](https://d3js.org/) — Module structure and feature overview
- [D3.js Getting Started](https://d3js.org/getting-started) — ES module usage
- [d3-scale Documentation](https://d3js.org/d3-scale) — Complete scale type reference
- [d3-shape Documentation](https://d3js.org/d3-shape) — Path generators and shape primitives
- [D3 Scale Functions (D3 in Depth)](https://www.d3indepth.com/scales/) — Scale implementation details

**htmlwidgets Ecosystem:**
- [htmlwidgets for R](https://www.htmlwidgets.org/) — Framework overview
- [htmlwidgets CRAN Documentation](https://cran.r-project.org/web/packages/htmlwidgets/htmlwidgets.pdf) — Package reference (July 2025)
- [Introduction to HTML Widgets](https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_intro.html) — Development guide
- [How to write a useful htmlwidget (Dean Attali)](https://deanattali.com/blog/htmlwidgets-tips/) — Best practices

**ggplot2 Ecosystem:**
- [ggplot2 Package Index](https://ggplot2.tidyverse.org/reference/) — Complete geom list
- [ggplot2 3.5.0: Legends](https://tidyverse.org/blog/2024/02/ggplot2-3-5-0-legends/) — Latest legend system updates
- [ggplot2 Themes](https://ggplot2-book.org/themes.html) — Theme system specification
- [ggplot2 Scale Transformations](https://ggplot2-book.org/scales-position.html) — Position scale details
- [ggplot2 Faceting](https://ggplot2-book.org/facet.html) — Facet grid and wrap implementation

**Alternatives and Comparisons:**
- [Interactive Data Visualization with R](https://blog.tidy-intelligence.com/posts/interactive-data-visualization-with-r/) — Ecosystem overview
- [ggplot2 vs Plotly Comparison](https://williazo.github.io/statistics/plotly-ggplot2/) — Trade-offs
- [SVG vs Canvas Performance 2026](https://www.augustinfotech.com/blogs/svg-vs-canvas-animation-what-modern-frontends-should-use-in-2026/) — Rendering trade-offs

**Interactivity:**
- [crosstalk Package](https://rstudio.github.io/crosstalk/) — Linked brushing documentation
- [D3.js Tooltips Guide](https://d3-graph-gallery.com/graph/interactivity_tooltip.html) — Tooltip patterns
- [Advanced Tooltip Techniques in D3](https://reintech.io/blog/advanced-tooltip-techniques-d3-enhanced-user-experience) — Best practices

**Rendering Quality:**
- [SVG Rendering in Browsers](https://area17.medium.com/svg-rendering-in-browsers-69e0a867297c) — Cross-browser consistency
- [Why Is My SVG Blurry?](https://www.svggenie.com/blog/svg-blurry-fixes) — Sub-pixel rendering issues

---
*Stack research for: gg2d3 (ggplot2-to-D3.js translation with pixel-perfect fidelity)*
*Researched: 2026-02-07*
