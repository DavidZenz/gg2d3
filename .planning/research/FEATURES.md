# Feature Research

**Domain:** ggplot2-to-D3.js translation for R visualization
**Researched:** 2026-02-07
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Core Geoms (Point, Line, Bar)** | Most common plot types in 80% of use cases | LOW | Already implemented; geom_point, geom_line, geom_bar |
| **Continuous & Categorical Scales** | Foundation of any plotting system | LOW | Already implemented with basic x/y scales |
| **Color/Fill Aesthetics** | Essential for encoding data dimensions | MEDIUM | Basic support exists; needs discrete/continuous color scales |
| **Axis Labels & Titles** | Basic plot annotation requirement | LOW | Already implemented |
| **Legends** | Users expect automatic legend generation for mapped aesthetics | HIGH | **MISSING** - Critical gap; users will immediately notice |
| **Faceting (facet_wrap/facet_grid)** | Standard for small multiples in ggplot2 | HIGH | **MISSING** - Essential for exploratory analysis |
| **Theme System** | ggplot2's theme() is foundational to appearance control | MEDIUM | Basic implementation exists; needs expansion |
| **Statistical Geoms (Smooth, Boxplot, Violin)** | Common in data exploration workflows | MEDIUM-HIGH | **MISSING** - Expected in scientific/statistical contexts |
| **Error Bars & Ranges** | Standard for uncertainty visualization | MEDIUM | **MISSING** - Required for scientific plots |
| **Text Labels (geom_text/geom_label)** | Basic annotation requirement | MEDIUM | Basic geom_text exists; needs styling options |
| **Stacked/Dodged Bars** | Standard bar chart variations | MEDIUM | Stacked bars work; dodged bars missing |
| **Date/Time Scales** | Essential for time series data | MEDIUM | **MISSING** - Common use case in R community |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Interactive Tooltips** | D3 advantage over static ggplot2 | MEDIUM | Hover details for data exploration |
| **Zoom & Pan** | Dynamic exploration beyond static limits | MEDIUM | Web-native interaction capability |
| **Linked Brushing** | Multi-plot coordination for analysis | HIGH | Powerful for dashboards; requires event system |
| **Animated Transitions** | Smooth visual transitions between states | MEDIUM-HIGH | D3 strength; engaging for presentations |
| **Click/Selection Events** | Connect plots to Shiny/JavaScript apps | MEDIUM | Enables dashboard integration |
| **Custom D3 Layers** | Escape hatch for advanced D3 users | HIGH | Pipe-based API for custom marks |
| **Pixel-Perfect Reproduction** | Exact match of ggplot2 output | MEDIUM | Trust builder for R community adoption |
| **WebGL Rendering** | Handle 100K+ points smoothly | HIGH | Performance differentiator vs. SVG |
| **Export to SVG/PNG** | Download publication-ready graphics | LOW-MEDIUM | Common requirement for reports |
| **Responsive Layouts** | Adapt to window/container size | MEDIUM | Web-native advantage over static plots |
| **CSS Theming** | Apply web design systems to plots | MEDIUM | Bridge R and web design worlds |
| **Accessibility (ARIA, keyboard nav)** | Screen reader support, keyboard interaction | MEDIUM-HIGH | Rarely seen in viz tools; ethical differentiator |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Complete ggplot2 Parity** | "Support everything ggplot2 does" | Impossible maintenance burden; ggplot2 has 40+ geoms, many niche | Focus on 80/20 rule: Cover common use cases first |
| **3D Plots (coord_3d)** | Seems impressive | Poor readability, limited utility, high complexity | Use faceting or animation for multidimensional data |
| **Full Extension System** | Allow user-defined geoms in R | Requires eval() security risks, hard to translate R→JS | Provide custom D3 layer escape hatch instead |
| **Real-time Streaming Data** | Live updating plots | Complicates state management, limited use cases | Support periodic updates; true streaming is specialized |
| **PDF Export with Cairo** | Match R's PDF output exactly | Cairo dependency adds binary complexity | Offer SVG export (convertible to PDF via external tools) |
| **Native Mobile App** | Mobile visualization | Maintenance burden; web responsive is sufficient | Build responsive HTML that works on mobile browsers |
| **R Expression Parsing (plotmath)** | Mathematical notation in labels | Requires LaTeX/MathJax parsing from R expressions | Support LaTeX strings directly or MathJax in labels |
| **All ColorBrewer Palettes** | Comprehensive color support | 35+ palettes bloat bundle size | Include top 10 most-used; let users specify custom |

## Feature Dependencies

```
Legends
    └──requires──> Color/Fill Scales (discrete, continuous)
    └──requires──> Shape/Size Scales
    └──requires──> Theme System (legend positioning, styling)

Faceting
    └──requires──> Layout Manager
    └──requires──> Scale Coordination (shared/free scales)
    └──requires──> Theme System (strip text, backgrounds)

Statistical Geoms (smooth, boxplot, violin)
    └──requires──> Statistical Transformations (stat_smooth, stat_boxplot)
    └──requires──> Confidence Interval Ribbons
    └──enhances──> Error Bars & Ranges

Date/Time Scales
    └──requires──> D3 Time Scales (d3.scaleTime)
    └──requires──> Date Formatting (d3-time-format)
    └──requires──> Break Calculation for dates

Interactive Tooltips
    └──requires──> Event Handling System
    └──enhances──> All Geoms (hover states)

Linked Brushing
    └──requires──> Event Handling System
    └──requires──> Selection State Management
    └──requires──> Coordinated Redraws

Custom D3 Layers
    └──requires──> Pipe-based API
    └──requires──> Scale Exposure to User Code
    └──requires──> Documentation/Examples

WebGL Rendering
    └──conflicts──> SVG-based Geoms (requires parallel implementation)
    └──requires──> Shader Code for Each Geom Type

Accessibility
    └──requires──> ARIA Labels on Data Points
    └──requires──> Keyboard Navigation System
    └──requires──> Screen Reader Descriptions
```

### Dependency Notes

- **Legends require Color/Fill Scales**: Cannot generate legends without proper discrete/continuous scale support for all aesthetic mappings
- **Faceting requires Layout Manager**: Multi-panel layouts need sophisticated grid system with shared/independent scales
- **Statistical Geoms require Stat Transformations**: geom_smooth() needs loess/linear regression calculations in JavaScript
- **Interactive Tooltips enhance All Geoms**: Once event system exists, adding tooltips to each geom is incremental
- **Linked Brushing requires Event System**: Must build selection/event infrastructure before multi-plot coordination
- **Custom D3 Layers require Pipe API**: Escape hatch depends on exposing scales/dimensions to user code
- **WebGL conflicts with SVG**: Performance optimization requires maintaining two render paths or sacrificing SVG features
- **Accessibility requires ARIA**: Screen reader support needs semantic markup for each data point

## MVP Definition

### Launch With (v1.0 - Table Stakes)

Minimum viable product — what's needed to validate the concept with R community.

- [x] **Core Geoms (point, line, bar, rect, text)** — Already implemented; foundation works
- [x] **Continuous/Categorical Scales** — Basic support exists; needs polish
- [x] **Basic Theme Translation** — Background, grid, axis styling implemented
- [ ] **Legends** — Critical gap; cannot launch without automatic legends
- [ ] **Color Scales (discrete, continuous, gradient)** — Required for data encoding
- [ ] **Date/Time Scales** — Common use case in time series analysis
- [ ] **Facet_wrap** — Essential for small multiples (defer facet_grid to v1.1)
- [ ] **geom_area, geom_ribbon** — Common filled area plots
- [ ] **geom_segment, geom_abline/hline/vline** — Reference lines and annotations
- [ ] **coord_flip** — Already partially implemented; needs axis positioning fix

**Launch criteria:** User can reproduce 70% of common ggplot2 plots with pixel-perfect fidelity. Legends work automatically. Faceting supports basic use cases.

### Add After Validation (v1.x - Expand Coverage)

Features to add once core is working and community adopts.

- [ ] **Statistical Geoms (smooth, boxplot, violin, density)** — After confirming user demand
- [ ] **Error Bars (errorbar, pointrange, linerange)** — Scientific plotting requirement
- [ ] **Facet_grid with free scales** — Advanced faceting use cases
- [ ] **Position Adjustments (dodge, jitter, stack)** — Bar chart variations
- [ ] **Additional Geoms (polygon, contour, bin2d, hex)** — Specialized use cases
- [ ] **Scale Transformations (log, sqrt, reverse)** — Already in ggplot2, low complexity
- [ ] **ColorBrewer & Viridis Palettes** — Top 10 most-used palettes
- [ ] **Annotation Layer (annotate function)** — Direct annotation without data
- [ ] **Coord_polar** — Pie charts and radial plots (low priority)
- [ ] **Theme Presets (theme_minimal, theme_bw, etc.)** — Quick styling options

**Trigger for adding:** User requests or GitHub issues indicating demand. Focus on features that multiple users request.

### Future Consideration (v2.0+ - Differentiators)

Features to defer until product-market fit is established.

- [ ] **Interactive Tooltips** — Major differentiator; requires event system architecture
- [ ] **Zoom & Pan** — Web-native exploration capability
- [ ] **Linked Brushing** — Dashboard/multi-plot coordination
- [ ] **Animated Transitions** — Visual polish and engagement
- [ ] **Custom D3 Layers (pipe-based API)** — Advanced user escape hatch
- [ ] **WebGL Rendering** — Performance for large datasets (100K+ points)
- [ ] **Export to SVG/PNG** — Download functionality
- [ ] **Responsive Layouts** — Adapt to container size changes
- [ ] **Accessibility (ARIA labels, keyboard nav)** — Ethical and compliance differentiator
- [ ] **Statistical Transformations (user-defined stats)** — Advanced statistical workflows
- [ ] **3rd-party Extension System** — Allow community to contribute geoms

**Why defer:** These are major architectural additions that require stable v1.0 foundation. Building interactivity before achieving ggplot2 parity risks fragmented feature set.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase |
|---------|------------|---------------------|----------|-------|
| **Legends** | HIGH | MEDIUM-HIGH | P1 | v1.0 |
| **Color Scales** | HIGH | MEDIUM | P1 | v1.0 |
| **Date/Time Scales** | HIGH | MEDIUM | P1 | v1.0 |
| **Facet_wrap** | HIGH | HIGH | P1 | v1.0 |
| **geom_area, geom_ribbon** | MEDIUM-HIGH | LOW-MEDIUM | P1 | v1.0 |
| **geom_segment** | MEDIUM-HIGH | LOW | P1 | v1.0 |
| **Reference Lines (hline/vline/abline)** | MEDIUM-HIGH | LOW | P1 | v1.0 |
| **coord_flip Fix** | MEDIUM-HIGH | LOW | P1 | v1.0 |
| **Statistical Geoms (smooth, boxplot, violin)** | MEDIUM-HIGH | HIGH | P2 | v1.x |
| **Error Bars** | MEDIUM | MEDIUM | P2 | v1.x |
| **Facet_grid** | MEDIUM | HIGH | P2 | v1.x |
| **Position Adjustments (dodge, jitter)** | MEDIUM | MEDIUM | P2 | v1.x |
| **Scale Transformations (log, sqrt)** | MEDIUM | LOW-MEDIUM | P2 | v1.x |
| **ColorBrewer/Viridis Palettes** | MEDIUM | LOW | P2 | v1.x |
| **Additional Geoms (polygon, contour, bin2d)** | LOW-MEDIUM | MEDIUM-HIGH | P2 | v1.x |
| **Interactive Tooltips** | HIGH (for D3 users) | MEDIUM-HIGH | P2 | v2.0 |
| **Zoom & Pan** | MEDIUM-HIGH (for D3 users) | MEDIUM | P2 | v2.0 |
| **Linked Brushing** | MEDIUM (niche dashboards) | HIGH | P3 | v2.0+ |
| **Animated Transitions** | MEDIUM (presentation value) | MEDIUM-HIGH | P3 | v2.0+ |
| **Custom D3 Layers** | LOW-MEDIUM (advanced users) | HIGH | P3 | v2.0+ |
| **WebGL Rendering** | LOW (niche performance cases) | HIGH | P3 | v2.0+ |
| **Accessibility** | MEDIUM (ethical, compliance) | MEDIUM-HIGH | P3 | v2.0+ |
| **coord_polar** | LOW (pie charts discouraged) | MEDIUM-HIGH | P3 | Future |
| **Theme Presets** | MEDIUM | LOW | P2 | v1.x |
| **Annotation Layer** | MEDIUM | LOW-MEDIUM | P2 | v1.x |
| **Export to SVG/PNG** | MEDIUM | LOW-MEDIUM | P2 | v2.0 |

**Priority key:**
- **P1**: Must have for v1.0 launch (table stakes for R community adoption)
- **P2**: Should have, add when possible (expands coverage or adds interactivity)
- **P3**: Nice to have, future consideration (differentiators or niche use cases)

## Competitor Feature Analysis

| Feature | ggplot2 (Static) | Plotly (Interactive) | Lattice (Fast) | gg2d3 (Proposed) |
|---------|------------------|----------------------|----------------|------------------|
| **Core Geoms** | 40+ geoms | Via ggplotly() | 15+ panel functions | 8 → 20+ planned |
| **Faceting** | facet_wrap/grid | Via ggplotly() | Formula-based | v1.0: wrap; v1.x: grid |
| **Legends** | Automatic | Automatic | Automatic | **v1.0: Planned** |
| **Themes** | Comprehensive | Limited CSS control | Theme system | v1.0: Basic → expanding |
| **Statistical Layers** | 20+ stat functions | Via ggplotly() | Some built-in | v1.x: Common stats |
| **Interactivity** | None (static PNG/PDF) | Tooltips, zoom, pan, click | None (static) | **v2.0: Differentiator** |
| **Performance** | Fast for small data | Slow for 10K+ points | Very fast (4-5x ggplot2) | v2.0: WebGL for large data |
| **Web Native** | No (R graphics device) | Yes (HTML widgets) | No (R graphics device) | **Yes (D3/SVG)** |
| **Customization** | Highly flexible | Limited (via ggplot2) | Moderate | v1: ggplot2-like; v2: D3 escape hatch |
| **Learning Curve** | Moderate (grammar of graphics) | Easy (if know ggplot2) | Steep (formula interface) | Easy (ggplot2 familiarity) |
| **Export Quality** | Publication-ready | HTML only | Publication-ready | v1: SVG (web); v2: PNG/PDF |
| **Ecosystem** | 100+ extension packages | plotly ecosystem | Mature but smaller | New; leverage R+D3 communities |
| **Use Case** | Static reports, papers | Dashboards, exploration | Large data, lattice plots | **Web viz with ggplot2 API** |

### Competitive Position

**gg2d3's Niche:**
- **Primary:** R users who want ggplot2 familiarity + web interactivity without learning plotly
- **Secondary:** Web developers who want ggplot2's grammar of graphics in JavaScript
- **Tertiary:** Shiny/R Markdown users who want lightweight, customizable web graphics

**vs. Plotly:**
- **Advantage:** Lighter weight, pixel-perfect ggplot2 reproduction, direct D3 control (v2.0)
- **Disadvantage:** Smaller feature set initially, less mature ecosystem

**vs. ggplot2:**
- **Advantage:** Web-native interactivity, responsive layouts, no image export needed
- **Disadvantage:** Cannot match full 40+ geom coverage; browser-dependent rendering

**vs. Lattice:**
- **Advantage:** Modern syntax, web compatibility, interactivity roadmap
- **Disadvantage:** Not optimized for very large datasets (until WebGL in v2.0)

## Geom Coverage Analysis

### ggplot2 Official Geom Count

Based on the [ggplot2 reference](https://ggplot2.tidyverse.org/reference/), ggplot2 provides **40+ geom functions**.

### Categorized by Implementation Priority

**Tier 1: Already Implemented (8 geoms)**
- geom_point, geom_line, geom_path
- geom_bar, geom_col
- geom_rect, geom_tile
- geom_text (basic)

**Tier 2: Essential for v1.0 (7 geoms)**
- geom_area, geom_ribbon
- geom_segment, geom_curve
- geom_abline, geom_hline, geom_vline

**Tier 3: Common Use Cases - v1.x (10 geoms)**
- geom_smooth (stat_smooth)
- geom_boxplot
- geom_violin
- geom_errorbar, geom_linerange, geom_pointrange, geom_crossbar
- geom_polygon
- geom_density (stat_density)
- geom_histogram, geom_freqpoly (stat_bin)

**Tier 4: Specialized - v1.x/v2.0 (10 geoms)**
- geom_contour, geom_contour_filled (stat_contour)
- geom_density_2d, geom_density_2d_filled (stat_density_2d)
- geom_bin_2d (stat_bin_2d)
- geom_hex (stat_bin_hex)
- geom_count (stat_sum)
- geom_dotplot
- geom_jitter (position_jitter)
- geom_rug

**Tier 5: Low Priority / Anti-Features (10+ geoms)**
- geom_qq, geom_qq_line (stat_qq)
- geom_quantile (stat_quantile)
- geom_function (stat_function)
- geom_map (superseded by geom_sf)
- geom_sf, geom_sf_text, geom_sf_label (spatial data)
- geom_label (complex text boxes)
- geom_raster (optimized geom_tile)
- geom_spoke (specialized direction vectors)
- geom_step (variant of geom_path)
- geom_blank (used for layout; not visual)

### Coverage Target

**v1.0 Goal:** 15 geoms (38% coverage, but ~80% of use cases)
**v1.x Goal:** 25 geoms (62% coverage, ~95% of use cases)
**v2.0+ Goal:** 30 geoms (75% coverage; remaining are highly specialized)

**Rationale:** Focus on Pareto principle. Most R users rely on 15-20 geoms for 80%+ of their plots. Full 40+ geom parity is anti-feature (maintenance burden exceeds user value).

## Scale Coverage Analysis

### ggplot2 Scale Types

Based on the [ggplot2 reference](https://ggplot2.tidyverse.org/reference/), ggplot2 provides **80+ scale functions** across categories:

**Position Scales:**
- Continuous: scale_x/y_continuous, log10, sqrt, reverse (4 variants x 2 axes = 8)
- Discrete: scale_x/y_discrete (2)
- Date/Time: scale_x/y_date, datetime, time (6)
- Binned: scale_x/y_binned (2)

**Color/Fill Scales:**
- Continuous: gradient, gradient2, gradientn, viridis_c, steps (5 x 2 aesthetics = 10)
- Discrete: discrete, hue, brewer, grey, viridis_d (5 x 2 = 10)
- Binned: viridis_b, fermenter, steps (3 x 2 = 6)
- Manual: manual (2)
- Identity: identity (2)

**Other Aesthetic Scales:**
- Alpha: continuous, discrete, binned, ordinal, manual, identity (6)
- Shape: shape, shape_binned, identity, manual (4)
- Size: size, size_area, size_binned, radius, identity, manual (6)
- Line width: linewidth, linewidth_binned, identity, manual (4)
- Line type: linetype, linetype_continuous, linetype_discrete, linetype_binned, identity, manual (6)

**Total:** 80+ scale functions

### Coverage Strategy

**v1.0 Target:** 20 scales (25% coverage, core use cases)
- scale_x/y_continuous, discrete, date, datetime (8)
- scale_colour/fill_discrete, hue, gradient, manual, identity (10)
- scale_alpha_continuous, discrete (2)

**v1.x Target:** 35 scales (44% coverage, common patterns)
- Add: log10, sqrt, reverse transforms (6)
- Add: brewer, viridis (4 x 2 = 8)
- Add: size, shape, linewidth, linetype (each continuous/discrete/manual = 12)
- Subtotal: 20 + 6 + 8 + 12 = 46 scales (~58%)

**v2.0+ Target:** 50 scales (62% coverage; remaining are variants)
- Add: binned scales, specialized palettes, ordinal scales

**Rationale:** Most users need position scales + color/fill + one other aesthetic (size or shape). 80+ scale functions include many specialized variants (binned, ordinal, identity) with lower usage frequency.

## Coordinate System Coverage

### ggplot2 Coordinate Systems

Based on the [ggplot2 reference](https://ggplot2-book.org/coord.html), ggplot2 provides **7 coordinate systems**:

**Linear Coordinate Systems:**
- coord_cartesian() (default)
- coord_fixed() (fixed aspect ratio)
- coord_flip() (x/y flipped - superseded by scales)

**Non-Linear Coordinate Systems:**
- coord_polar() (polar coordinates for pie/rose charts)
- coord_radial() (modern polar system)
- coord_map() / coord_quickmap() (map projections - superseded by coord_sf)
- coord_trans() (arbitrary transformations)
- coord_sf() (spatial features - requires sf package)

### Coverage Strategy

**v1.0 Target:** 2 coordinate systems
- coord_cartesian (already implemented)
- coord_flip (partially implemented; needs axis positioning fix)

**v1.x Target:** 3 coordinate systems
- Add: coord_fixed (moderate complexity; aspect ratio constraints)

**v2.0+ Target:** 4-5 coordinate systems
- Add: coord_polar (medium-high complexity; pie/rose charts)
- Maybe: coord_trans (arbitrary transformations; low priority)
- **Exclude:** coord_sf (requires spatial data libraries; anti-feature)
- **Exclude:** coord_map/quickmap (superseded; anti-feature)

**Rationale:** Most users need Cartesian coordinates (99% of plots). coord_flip is common for horizontal bar charts. coord_polar is niche (pie charts discouraged by data viz community). coord_sf requires significant spatial data infrastructure.

## Statistical Transformation Coverage

### ggplot2 Stat Functions

Based on the [ggplot2 reference](https://ggplot2.tidyverse.org/reference/layer_stats.html), ggplot2 provides **20+ stat functions**:

**Basic Stats:**
- stat_identity (pass-through; no transformation)
- stat_count (for bar charts)
- stat_bin (for histograms)
- stat_bin_2d, stat_bin_hex (2D binning)

**Density & Distribution:**
- stat_density (1D density estimation)
- stat_density_2d, stat_density_2d_filled (2D density)
- stat_ydensity (for violin plots)
- stat_ecdf (empirical cumulative distribution)

**Smoothing & Regression:**
- stat_smooth (loess, lm, glm smoothing)
- stat_quantile (quantile regression)
- stat_function (evaluate arbitrary function)

**Statistical Summaries:**
- stat_summary (summarize y at each x)
- stat_summary_2d, stat_summary_hex (2D summaries)
- stat_summary_bin (binned summaries)
- stat_boxplot (boxplot statistics)

**Specialized:**
- stat_contour, stat_contour_filled (contour lines)
- stat_qq, stat_qq_line (quantile-quantile)
- stat_ellipse (confidence ellipses)
- stat_sf, stat_sf_coordinates (spatial features)
- stat_unique (remove duplicates)
- stat_align (align multiple plots)

### Coverage Strategy

**v1.0 Target:** 3 stats (basic rendering)
- stat_identity (already works implicitly)
- stat_count (for geom_bar)
- stat_bin (for geom_histogram) - **if time permits**

**v1.x Target:** 8 stats (statistical plots)
- Add: stat_smooth (loess/lm smoothing)
- Add: stat_boxplot (boxplot calculations)
- Add: stat_density (density curves)
- Add: stat_ydensity (violin plots)
- Add: stat_summary (y summaries at each x)

**v2.0+ Target:** 12-15 stats (specialized analysis)
- Add: stat_density_2d (2D density contours)
- Add: stat_contour (contour lines)
- Add: stat_ellipse (confidence regions)
- Add: stat_qq (diagnostic plots)
- **Exclude:** stat_sf (spatial; requires sf package)

**Rationale:** Most geoms use stat_identity (no transformation). Statistical geoms (smooth, boxplot, violin, density) require implementing statistical algorithms in JavaScript (loess, kernel density estimation, quantile calculation). These are medium-high complexity but expected by scientific R users.

## Faceting Coverage

### ggplot2 Faceting Functions

Based on the [ggplot2 reference](https://ggplot2-book.org/facet.html), ggplot2 provides **2 main faceting functions**:

**Facet Types:**
- facet_wrap(~var) - Wrap 1D ribbon into 2D grid
- facet_grid(rows ~ cols) - 2D grid from two variables

**Features:**
- Free vs. fixed scales (scales = "fixed", "free_x", "free_y", "free")
- Free space (facet_grid only; space = "fixed", "free_x", "free_y", "free")
- Labellers (label_value, label_both, label_parsed, etc.)
- Strip positioning and styling

### Coverage Strategy

**v1.0 Target:** facet_wrap with fixed scales
- Basic small multiples
- Fixed scales (same axes across all panels)
- Default labelling

**v1.x Target:** Full facet_wrap + basic facet_grid
- Add: Free scales (free_x, free_y, free)
- Add: facet_grid for 2D layouts
- Add: Custom labellers
- Add: Strip positioning/styling

**v2.0+ Target:** Advanced faceting features
- Add: Free space (proportional panel sizes)
- Add: Nested faceting
- Add: Custom layout specifications

**Rationale:** facet_wrap covers 70% of faceting use cases. Free scales are essential for comparing trends with different ranges. facet_grid is less common but expected for 2D categorical structures. Free space is niche (mostly for spatial plots).

## Theme System Coverage

### ggplot2 Theme Elements

Based on the [ggplot2 reference](https://ggplot2.tidyverse.org/reference/theme.html), ggplot2's theme() has **90+ theme elements** across categories:

**Plot Elements:**
- plot.background, plot.title, plot.subtitle, plot.caption
- plot.margin, plot.tag

**Panel Elements:**
- panel.background, panel.border, panel.spacing, panel.ontop
- panel.grid.major, panel.grid.minor (with .x/.y variants)

**Axis Elements:**
- axis.line, axis.text, axis.title, axis.ticks, axis.ticks.length
- (with .x/.y and .top/.bottom/.left/.right variants)

**Legend Elements:**
- legend.background, legend.box, legend.box.margin, legend.box.spacing
- legend.key, legend.key.size, legend.key.height, legend.key.width
- legend.margin, legend.position, legend.direction, legend.justification
- legend.spacing, legend.text, legend.title

**Strip Elements (Facets):**
- strip.background, strip.text, strip.placement, strip.switch.pad.grid

**Element Types:**
- element_blank() - Remove element
- element_rect() - Rectangle (fill, colour, linewidth, linetype)
- element_line() - Line (colour, linewidth, linetype, lineend)
- element_text() - Text (family, face, colour, size, hjust, vjust, angle)

**Complete Themes:**
- theme_gray() (default)
- theme_bw(), theme_minimal(), theme_classic(), theme_void()
- theme_light(), theme_dark(), theme_linedraw()

### Coverage Strategy

**v1.0 Target:** 20 theme elements (core appearance)
- panel.background, panel.border
- panel.grid.major, panel.grid.minor
- plot.background, plot.margin, plot.title
- axis.line, axis.text, axis.title, axis.ticks
- Basic element types (rect, line, text, blank)

**v1.x Target:** 40 theme elements (+ legends & facets)
- legend.* elements (position, background, text, key)
- strip.* elements (facet labels)
- Axis variants (.x/.y, .top/.bottom/.left/.right)
- theme_minimal(), theme_bw() presets

**v2.0+ Target:** 60 theme elements (comprehensive)
- Fine-grained axis controls
- Advanced legend controls
- Complete theme presets
- Custom element creation

**Rationale:** Most users modify 10-15 theme elements (backgrounds, grids, axis text). Legend styling becomes critical once legends are implemented (v1.0). Facet strips are essential for faceting (v1.0/v1.x). Full theme parity is low priority; users can apply CSS for web-specific styling.

## Sources

### Official Documentation (HIGH Confidence)
- [ggplot2 Package Reference](https://ggplot2.tidyverse.org/reference/) - Complete function index
- [ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/) - Authoritative book by Hadley Wickham
- [Coordinate Systems](https://ggplot2-book.org/coord.html) - Coordinate system documentation
- [Faceting](https://ggplot2-book.org/facet.html) - Faceting documentation
- [Scales and Guides](https://ggplot2-book.org/scales-guides.html) - Scale documentation

### Competitive Analysis (MEDIUM Confidence)
- [Comparing R Graphic Packages - ggplot2 vs. plotly](https://williazo.github.io/statistics/plotly-ggplot2/) - Technical comparison
- [Plotly vs. GGplot2: Which Library is Better?](https://www.nobledesktop.com/blog/plotly-vs-ggplot2) - Feature comparison
- [Comparing plotting systems in R](https://www.atlantbh.com/comparing-different-plotting-systems-in-r/) - Lattice, ggplot2, base R
- [Best R Packages for Data Visualization in 2025](https://howik.com/best-r-packages-for-data-visualization) - Ecosystem overview

### Interactive Visualization (MEDIUM Confidence)
- [ggiraph-user-2025](https://github.com/z3tt/ggiraph-user-2025) - ggiraph interactivity patterns
- [Interactive Data Visualization with R](https://blog.tidy-intelligence.com/posts/interactive-data-visualization-with-r/) - Comparison of approaches
- [A Comparison of plot_ly and ggplotly](https://jtr13.github.io/spring19/community_contribution_group17.html) - Performance and features

### Community Usage Patterns (MEDIUM-LOW Confidence)
- [R Graph Gallery - ggplot2](https://r-graph-gallery.com/ggplot2-package.html) - Common usage examples
- [Top 50 ggplot2 Visualizations](http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html) - Popular plot types

---
*Feature research for: gg2d3 - ggplot2-to-D3.js translation for R visualization*
*Researched: 2026-02-07*
*Confidence: HIGH (official ggplot2 docs), MEDIUM (competitive landscape, usage patterns)*
