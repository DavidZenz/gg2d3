# Project Research Summary

**Project:** gg2d3 - ggplot2-to-D3.js translation with pixel-perfect fidelity and interactivity
**Domain:** Data visualization translation layer (R graphics to web)
**Researched:** 2026-02-07
**Confidence:** HIGH

## Executive Summary

gg2d3 is an R package that translates ggplot2 plots into interactive D3.js visualizations, bridging R's statistical graphics ecosystem with web-native interactivity. Research reveals this is a complex translation problem requiring three distinct layers: (1) R extraction from ggplot2 internals, (2) a JSON intermediate representation (IR), and (3) D3 rendering with pixel-perfect fidelity. The current implementation has validated the core architecture with 8 geoms but must modularize before scaling to 30+ geoms, legends, facets, and interactivity.

The recommended approach is architectural refactoring first, then incremental feature expansion. Modularizing the monolithic codebase (Phase 1) prevents rework when adding complex features. Scale system completion (Phase 2) unblocks all downstream work since geoms, legends, and axes all depend on scales. Geom coverage expansion (Phase 3) delivers immediate user value with parallelizable work. Layout engine implementation (Phase 4) enables legends and facets without position-calculation chaos. Finally, legends (Phase 5) and facets (Phase 6) provide the remaining table-stakes features for v1.0 launch, with interactivity (Phase 7) deferred to v2.0.

Key risks center on ggplot2 API fragility (private `calc_element()` dependency), unit conversion consistency (mm to pixels across R and JavaScript), and underestimated complexity of faceting and legends. Mitigation strategies include isolating ggplot2 API calls in extractor modules, centralizing all unit conversions with documented constants, and implementing a layout engine before attempting multi-panel or legend positioning. The Pareto principle applies: targeting 30 geoms (75% coverage) captures 95% of use cases without the maintenance burden of complete 40+ geom parity.

## Key Findings

### Recommended Stack

The package should use D3.js v7.9.0 (latest stable, March 2024) with modular imports for tree-shaking, htmlwidgets 1.6.4+ for R-JavaScript bridging, and ggplot2 3.5.0+ for improved legend system APIs. D3's modular architecture provides granular control over scales, shapes, and rendering while enabling selective bundling. htmlwidgets is the CRAN-standard framework for embedding JavaScript visualizations in R Markdown, Shiny, and standalone HTML.

**Core technologies:**
- **D3.js v7.9.0**: Low-level SVG rendering engine with modular scale/shape/axis systems — industry standard for pixel-level control, pure ES modules enable tree-shaking
- **htmlwidgets 1.6.4+**: R-to-JavaScript bridge via JSON serialization — CRAN-standard with seamless R Markdown/Shiny integration
- **ggplot2 3.5.0+**: Source plotting system with complete theme specification — provides robust extraction API, v3.5.0 improves legend/guide positioning

**D3 modules required:** d3-selection (DOM manipulation), d3-scale (data-to-visual mappings covering continuous/categorical/time), d3-shape (path generators for area/line/curve), d3-axis (tick generation), d3-color (palette conversion), d3-format (label formatting), d3-array (statistical operations), d3-transition (animations for v2.0).

**Supporting R packages:** grid (unit conversion mm→px using `convertUnit()`), jsonlite (fast JSON serialization), crosstalk 1.2.1+ (client-side linked brushing for v2.0), testthat + vdiffr (visual regression testing).

**Rendering approach:** SVG primary (pixel-perfect, accessible, responsive), Canvas deferred to v2.0 for >5k point optimization. SVG provides DOM structure for screen readers, exact ggplot2 fidelity, and easy event handling. Canvas sacrifices these for raw performance beyond typical use cases (<5k points).

### Expected Features

Research shows ggplot2 has 40+ geoms, 80+ scale functions, 7 coordinate systems, 20+ stat layers, and 90+ theme elements. Complete parity is an anti-feature—unsustainable maintenance burden. Instead, focus on the Pareto principle: 30 geoms cover 95% of real-world plots.

**Must have (table stakes):**
- **Legends** — Users expect automatic legend generation for mapped aesthetics; currently MISSING, blocks v1.0 launch
- **Faceting (facet_wrap)** — Essential for small multiples in exploratory analysis; currently MISSING
- **Color scales (discrete, continuous, gradient)** — Foundation for data encoding; basic support exists, needs expansion
- **Date/time scales** — Common in time series (frequent R use case); currently MISSING
- **Additional core geoms** — area, ribbon, segment, hline/vline/abline for complete basic plots

**Should have (competitive advantage):**
- **Interactive tooltips** — D3 advantage over static ggplot2, enables data exploration
- **Zoom & pan** — Web-native dynamic exploration beyond static limits
- **Pixel-perfect reproduction** — Trust builder for R community, validates fidelity
- **Statistical geoms** — boxplot, violin, density, smooth (expected in scientific contexts)

**Defer (v2+):**
- **Linked brushing** — Complex event system, niche dashboard use case
- **Animated transitions** — Presentation polish, not core functionality
- **WebGL rendering** — Performance for >100k points (rare need)
- **Complete stat system** — Only implement stats with proven user demand

**Anti-features (avoid):**
- **Complete ggplot2 parity** — 40+ geoms include many niche cases; focus on common 30
- **3D plots (coord_3d)** — Poor readability, high complexity, limited utility
- **Full extension system** — Eval() security risks; provide D3 escape hatch instead
- **Real-time streaming** — Complicates state management; periodic updates sufficient

### Architecture Approach

The architecture should evolve from the current three-layer pipeline (R extraction → JSON IR → D3 rendering) to a modular component system. Current implementation has a 353-line monolithic `as_d3_ir()` function and 716-line `gg2d3.js` renderer. This works for 8 geoms but becomes unmaintainable at 30+ geoms with legends, facets, and interactivity.

Recommended pattern: **Extractor-Builder-Validator pipeline** in R (separates ggplot2 API usage, unit conversions, and integrity checks) plus **Geom Registry with Layout Engine** in D3 (each geom is standalone renderer, layout engine centralizes position calculations).

**Major components:**

1. **R Extractor Modules** — Isolated functions (`extract_scales()`, `extract_theme()`, `extract_geoms()`, `extract_facets()`, `extract_guides()`) that use ggplot2 APIs including private `calc_element()`. Isolating private API usage here makes ggplot2 version updates easier.

2. **R Builder Modules** — Transform extracted data into normalized IR (`build_scale_ir()`, `build_layer_ir()`, `build_guide_ir()`). This is where unit conversions (mm→px), color translations (grey→gray), and default value application happen. Separating from extraction allows independent testing.

3. **R Validator Modules** — Schema validation before JSON serialization (`validate_ir()`, `validate_scales()`). Catches errors in R layer with clear messages rather than cryptic JavaScript failures.

4. **D3 Scale Factory** — Module that converts IR scale descriptors into D3 scale objects (`makeScale(desc)`). Handles all scale types: linear, log, sqrt, date, band, point, ordinal, sequential, diverging.

5. **D3 Layout Engine** — Centralized spatial math (`calculateLayout()`) for panel positioning, facet grids, legend placement, axis positioning. Single source of truth for all layout calculations prevents hardcoded positions that break with multi-panel layouts.

6. **D3 Geom Registry** — Each geom is separate file with consistent interface (`renderPoint()`, `renderLine()`, `renderBar()`). Registry dispatches by geom name: `geomRegistry[layer.geom](layer, scales, g, theme)`. Enables parallel geom development, independent testing, and clean separation of concerns.

7. **D3 Guide Renderers** — Separate modules for legend rendering (`renderLegend()`), axis rendering (`renderAxis()`), and facet panel layout (`renderFacet()`). These use layout engine results for positioning.

8. **Pipe-Based Interactivity API** — R functions that augment widgets via htmlwidgets messaging: `gg2d3(p) |> d3_tooltip() |> d3_brush()`. Familiar tidyverse syntax, composable, works in R Markdown without custom JavaScript.

**Data flow:** ggplot object → ggplot_build() → extractor modules → builder modules → validator → JSON IR → D3 renderValue() → layout calculations → scale creation → geom rendering (via registry) → guide rendering → event attachment.

**Key insight from architecture research:** Don't build facets before legends (you'll rewrite facet layout when legends need space). Don't build geoms before modularizing (you'll have unmaintainable 2000-line file). Don't build legends before layout engine (you'll hardcode positions that break with facets).

### Critical Pitfalls

1. **Unit Conversion Inconsistencies** — Hardcoded conversion factor (3.7795275591) scattered across R and JavaScript causes visual mismatches. ggplot2 assumes 72 DPI, browsers assume 96 DPI. Formula `pixels = mm × (96/25.4)` must be centralized with clear documentation. Test by comparing line widths, point sizes, spacing to ggplot2 output. Address in Phase 1 (Foundation) before building other features.

2. **ggplot2 Private API Dependency** — Using `ggplot2:::calc_element()` for theme extraction creates fragile dependency. ggplot2 can change internals without notice (v3.4→v3.5→v4.0 breaking changes). Wrap all private API calls in try-catch, document prominently, test against multiple ggplot2 versions in CI. Consider contributing theme extraction as public API to ggplot2. Address in Phase 1 with defensive coding.

3. **Statistical Transformation Trap** — Attempting to translate stat layers (smooth, density, bin) by extracting post-stat computed data works for static plots but loses interactivity. Can't recompute density curves when user filters data. Must choose: (1) pre-compute in R and accept static-only, or (2) implement stat algorithms in JavaScript. For MVP, focus on geometric layers only. Phase in stat support gradually starting with simple ones (count, identity). Address in Phase 3-4.

4. **Coordinate System Transformation Complexity** — coord_flip() isn't just scale swapping—requires repositioning axes, rotating labels, transforming entire layout. Simply reversing scale ranges puts axes on wrong sides. Treat coord as first-class IR concept, pass coord info separately, restructure D3 rendering pipeline based on coord type. Currently broken (documented in CONCERNS.md). Address in Phase 2.

5. **Scale Expansion Mismatch** — ggplot2 adds 5% multiplicative padding plus additive padding to axes by default. Discrete scales use different expansion (0.6 units) than continuous (5%). Missing expansion causes data to touch axis edges or points cut off at boundaries. Extract expansion parameters explicitly, implement expansion() logic in JavaScript matching ggplot2 formula. Critical for visual parity. Address in Phase 1.

6. **Facet Data Structure Complexity** — Faceting requires calculating panel positions in grid layout, sharing/separating scales across panels, handling strip labels, synchronizing axes, dealing with missing combinations, managing free vs fixed scales. Not "just make multiple subplots"—needs sophisticated layout math. Start with facet_wrap (simpler) before facet_grid. Requires complete scale system and layout engine first. Address in Phase 6.

7. **Legend Generation Without Scales** — Legends require reverse-mapping from aesthetic values to data values. Can't create correct legends from layer data alone—need scale guide information, aesthetic mappings, legend merging logic. Must extract from `ggplot_build()$plot$scales`. Support guide_legend() vs guide_colorbar() distinctions. Depends on complete scale system. Address in Phase 5.

## Implications for Roadmap

Based on combined research across stack, features, architecture, and pitfalls, the optimal build order follows component dependencies. Scales are prerequisite for everything. Layout engine prevents position-calculation chaos. Modularization before feature expansion prevents exponential complexity.

### Phase 1: Foundation Refactoring & Polish
**Rationale:** Current codebase works for 8 geoms but won't scale to 30+ without modularization. Extracting existing functionality into modular components (geom registry, scale factory, theme system) prevents 2000+ line files. Centralizing unit conversions and color translations fixes critical pitfalls before they propagate to new features.

**Delivers:**
- Geom registry pattern (8 existing geoms in separate files)
- Scale factory module (existing scale types extracted)
- Centralized unit conversion utilities (mm→px, pt→px with documented constants)
- Color translation system (grey↔gray, R colors→hex)
- Validation system (IR schema checks before JSON serialization)

**Addresses:**
- Pitfall #1 (unit conversion inconsistencies)
- Pitfall #2 (private API isolation)
- Pitfall #5 (scale expansion implementation)
- Pitfall #7 (color name translation)

**Avoids:** Creating 2000+ line monolithic files when adding 30 geoms in later phases.

**Research flag:** Standard refactoring patterns, no deep research needed.

---

### Phase 2: Complete Scale System
**Rationale:** Scales are used by geoms, legends, and axes—incomplete scale support blocks everything downstream. Better to have robust scales early than patch them repeatedly while building geoms/legends. Current implementation has basic continuous/categorical; missing date/time, color palettes (viridis, brewer), transformations (log, sqrt, reverse), and diverging scales.

**Delivers:**
- Date/time scale support (d3.scaleTime, date formatting)
- Color scale system (discrete, continuous, gradient, viridis, brewer palettes)
- Scale transformations (log, sqrt, reverse)
- Diverging color scales
- Complete scale expansion implementation
- coord_cartesian and coord_flip fixes (axis positioning)

**Uses:**
- D3 modules: d3-scale (scaleTime, scaleLog, scaleSqrt, scaleDiverging)
- D3 d3-format for date/time formatting
- D3 d3-color for palette interpolation

**Implements:** Scale Factory architectural component with full ggplot2 scale type coverage.

**Addresses:**
- Feature gaps: Date/time scales (table stakes)
- Feature gaps: Color scales (table stakes)
- Pitfall #4 (coordinate system complexity—fix coord_flip)

**Avoids:** Patching scale system repeatedly when building geoms that reveal scale limitations.

**Research flag:** Date/time formatting may need research-phase for complex ggplot2 date features.

---

### Phase 3: Expand Geom Coverage
**Rationale:** High user value, parallelizable work once registry exists, validates scale system works correctly. Focus on geoms that complete common plot types: area plots, reference lines, annotations. Each geom is independent module (~50-100 lines) using established patterns.

**Delivers:**
- geom_area, geom_ribbon (d3.area() path generator)
- geom_segment, geom_curve (SVG line/path elements)
- geom_abline, geom_hline, geom_vline (reference lines)
- geom_polygon (path with closepath)
- geom_text enhancements (rotation, alignment via transforms)
- Position adjustments: dodge, stack improvements

**Geom count:** 8 existing + 9 new = 17 geoms (42% of ggplot2's 40+, covers ~85% of use cases)

**Uses:**
- D3 modules: d3-shape (d3.area(), curve interpolators)
- SVG primitives: line, path, text with transforms

**Implements:** Geom Registry pattern with real scale—tests pattern viability.

**Addresses:**
- Features: geom_area, geom_ribbon (table stakes)
- Features: Reference lines (table stakes)
- Features: Annotation geoms (should have)

**Avoids:** Building complex statistical geoms (boxplot, violin, density) before simpler geometric ones.

**Research flag:** Statistical geoms (smooth, boxplot) may need research-phase for stat computation algorithms.

---

### Phase 4: Layout Engine
**Rationale:** Legends need space carved out of plot area—can't hardcode positions. Facets need multi-panel grid calculations. Building layout engine before these features avoids rewriting legend code when facets arrive. Centralized spatial math enables both legends (Phase 5) and facets (Phase 6) without position chaos.

**Delivers:**
- Layout engine core (`calculateLayout()` function)
- Legend positioning system (right, left, top, bottom, inside)
- Axis positioning (secondary axes, coord-based placement)
- Panel calculation infrastructure (prepares for facets)
- Margin and spacing calculations

**Uses:**
- IR facet/guide metadata
- Theme margin specifications

**Implements:** Layout Engine architectural component—single source of truth for spatial calculations.

**Addresses:**
- Architecture requirement: Centralized layout math before multi-panel features
- Pitfall #6 prep: Facet layout infrastructure

**Avoids:** Hardcoded positions in legends that break when facets need grid layout.

**Research flag:** Standard layout patterns, no deep research needed. Test-driven development sufficient.

---

### Phase 5: Legend System
**Rationale:** Legends are most-requested missing feature (users immediately notice absence). Requires complete scale system (Phase 2), layout engine (Phase 4), and geom glyphs. Building legends validates scales work correctly and makes debugging geoms easier (can see data-to-aesthetic mappings).

**Delivers:**
- R guide extraction (`extract_guides()` from ggplot_build)
- R guide IR builder (`build_guide_ir()` with keys, colors, shapes, sizes)
- D3 legend renderer (`renderLegend()` for color/fill/size/shape/alpha)
- Legend layout integration (uses Phase 4 layout engine)
- Legend merging (combine color + size into one legend)
- Support for guide_legend() vs guide_colorbar()

**Uses:**
- Layout engine from Phase 4
- Complete scale system from Phase 2
- Geom glyphs for legend keys

**Implements:** Guide Renderers architectural component (legend portion).

**Addresses:**
- Feature gap: Legends (table stakes, MISSING—blocks v1.0)
- Pitfall #10 (legend generation without scales)

**Avoids:** Building facets first (would need to rewrite legend positioning for multi-panel).

**Research flag:** May need research-phase for complex guide types (guide_bins, guide_stairs, guide_custom).

---

### Phase 6: Facet System
**Rationale:** Facets are most complex feature—requires layout engine, complete geom coverage, proper scale handling. Building last allows all earlier components to be battle-tested. Facets validate that modular architecture works at scale (multiple panels, each rendering all layers).

**Delivers:**
- facet_wrap with fixed scales
- facet_wrap with free scales (free_x, free_y, free)
- facet_grid for 2D layouts (rows ~ cols)
- Strip labels and positioning
- Panel grid layout with spacing
- Per-panel rendering loop with panel-specific scales

**Uses:**
- Layout engine from Phase 4 (multi-panel calculations)
- Complete geom registry from Phase 3
- Scale system from Phase 2 (shared vs free scales)
- Theme system for strip backgrounds/text

**Implements:** Complete Layout Engine with multi-panel support, Facet Renderers (guide component).

**Addresses:**
- Feature gap: Faceting (table stakes, MISSING—blocks v1.0)
- Pitfall #9 (facet data structure complexity)

**Avoids:** Building facets before legends (positioning would need rewrite for legend space).

**Research flag:** Likely needs research-phase for free space (proportional panel sizing), nested faceting.

---

### Phase 7: Interactivity (v2.0)
**Rationale:** Interactivity is value-add on top of complete rendering. Users can create static plots with full coverage (Phases 1-6) before interactivity arrives. Building last allows API design informed by real usage patterns. Pipe-based API matches tidyverse conventions.

**Delivers:**
- Event system (D3 handlers for hover, click, brush, zoom)
- Tooltip module (`d3_tooltip()` pipe function, D3 tooltip renderer)
- Brush/zoom module (`d3_brush()`, `d3_zoom()` with scale updates)
- Linked views (`d3_link()` for cross-widget communication)
- Shiny integration (message passing to Shiny outputs)

**Uses:**
- D3 modules: d3-brush, d3-zoom, d3-transition, d3-ease
- htmlwidgets message passing protocol
- crosstalk for client-side linked brushing

**Implements:** Event System and Pipe-Based Interactivity API architectural components.

**Addresses:**
- Features: Interactive tooltips (differentiator)
- Features: Zoom & pan (differentiator)
- Features: Linked brushing (should have for dashboards)

**Avoids:** Designing interactive APIs before static rendering is complete and stable.

**Research flag:** Will need research-phase for crosstalk integration patterns, Shiny message protocol.

---

### Phase Ordering Rationale

- **Foundation first** — Modularizing (Phase 1) prevents exponential rework when adding 30 geoms + legends + facets
- **Scales early** — Everything depends on scales (geoms, legends, axes); getting them right upfront saves iteration
- **Geoms next** — High user value, parallelizable once registry exists, validates scale system
- **Layout before guides** — Avoids rewriting legends/facets when adding the other (both need space calculations)
- **Legends before facets** — Legends are simpler, debugging patterns apply to facets
- **Facets late** — Most complex feature, benefits from stable foundation and battle-tested components
- **Interactivity last** — Pure enhancement, doesn't block core functionality, informed by usage patterns

**Dependency chain:**
```
Phase 1 (Foundation) → Phase 2 (Scales)
                           ↓
                       Phase 3 (Geoms—parallel)
                           ↓
                       Phase 4 (Layout Engine)
                           ↓
                       Phase 5 (Legends)
                           ↓
                       Phase 6 (Facets)
                           ↓
                       Phase 7 (Interactivity)
```

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 2 (Scales):** Complex date/time formatting edge cases, ggplot2 date scale expansion rules
- **Phase 3 (Statistical Geoms):** If adding geom_smooth/boxplot/violin—needs stat algorithm research (loess, kernel density, quantile calculations in JavaScript)
- **Phase 5 (Legends):** Advanced guide types (guide_bins, guide_stairs, guide_coloursteps) if needed beyond basic guide_legend/guide_colorbar
- **Phase 6 (Facets):** Free space (proportional panel sizing), nested faceting, strip placement edge cases
- **Phase 7 (Interactivity):** crosstalk integration patterns, Shiny bidirectional messaging, touch event handling

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation):** Refactoring patterns are well-established; test-driven development sufficient
- **Phase 3 (Simple Geoms):** Area, ribbon, segment, polygon follow documented D3 patterns
- **Phase 4 (Layout Engine):** Spatial math is straightforward; unit testing validates correctness

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official D3.js/htmlwidgets/ggplot2 documentation reviewed. Version compatibility verified. D3 v7.9.0 is current stable (March 2024). |
| Features | HIGH | Complete ggplot2 function count from official reference. Pareto analysis shows 30 geoms = 95% coverage. MVP definition matches community usage patterns. |
| Architecture | HIGH | Patterns validated from Vega-Lite, Plotly, Observable Plot research. Current codebase analysis confirms pain points. Modular architecture is industry-standard for D3 projects. |
| Pitfalls | HIGH | Extracted from current codebase issues (CONCERNS.md, d3-drawing-diagnostics.md), ggplot2 changelog analysis, and R graphics system documentation. Unit conversion details verified in grid package docs. |

**Overall confidence:** HIGH

Research is comprehensive with official documentation sources. Architecture recommendations are proven patterns from similar projects. Pitfalls are based on actual codebase issues rather than speculation. Phase ordering has clear dependency rationale.

### Gaps to Address

- **ggplot2 version compatibility:** Need CI testing against ggplot2 3.4.x, 3.5.x, and dev version to catch private API breakage early. Strategy: Create compatibility shims, document minimum supported version.

- **Statistical algorithms in JavaScript:** Implementing loess smoothing, kernel density estimation, boxplot calculations in JavaScript is complex. Strategy: For MVP, extract pre-computed stat data from ggplot_build(). For v2.0 interactivity, consider JavaScript stats libraries (simple-statistics, science.js) or R-to-wasm compilation experiments.

- **Pixel-perfect fidelity validation:** Need automated visual regression testing to verify D3 output matches ggplot2. Strategy: Use vdiffr for R side, implement SVG screenshot comparison for D3 side. Accept <2px position differences, exact color hex match.

- **High-DPI display handling:** Current unit conversion assumes 96 DPI. Retina/4K displays may need adjusted conversion factors. Strategy: Document DPI assumptions clearly, consider parameterizing DPI for future enhancement.

- **Facet free space:** Proportional panel sizing (space="free") is rarely used but tricky to implement. Strategy: Defer to v1.1+ unless strong user demand. Focus on fixed-space facets for v1.0.

- **Theme completeness:** ggplot2 has 90+ theme elements; v1.0 targets 20-30 most common. Strategy: Start with elements that affect layout (margins, backgrounds, grids, axes), add aesthetic refinements (fonts, colors) incrementally based on user requests.

## Sources

### Primary (HIGH confidence)

**D3.js Official Documentation:**
- [D3.js Releases (GitHub)](https://github.com/d3/d3/releases) — Version 7.9.0 verified as latest stable (March 2024)
- [D3.js Official Documentation](https://d3js.org/) — Module structure, API reference
- [d3-scale Documentation](https://d3js.org/d3-scale) — Complete scale type reference
- [d3-shape Documentation](https://d3js.org/d3-shape) — Path generators and shape primitives

**ggplot2 Official Documentation:**
- [ggplot2 Package Reference](https://ggplot2.tidyverse.org/reference/) — Complete function index (40+ geoms, 80+ scales)
- [ggplot2: Elegant Graphics for Data Analysis (3e)](https://ggplot2-book.org/) — Authoritative book by Hadley Wickham
- [ggplot2 3.5.0: Legends](https://tidyverse.org/blog/2024/02/ggplot2-3-5-0-legends/) — Latest legend system improvements
- [ggplot2 Themes](https://ggplot2-book.org/themes.html) — Theme system specification (90+ elements)
- [ggplot2 Faceting](https://ggplot2-book.org/facet.html) — Facet implementation details

**htmlwidgets:**
- [htmlwidgets for R](https://www.htmlwidgets.org/) — Framework overview
- [htmlwidgets CRAN Documentation](https://cran.r-project.org/web/packages/htmlwidgets/htmlwidgets.pdf) — Package reference (July 2025)
- [Introduction to HTML Widgets](https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_intro.html) — Development guide

**R Graphics System:**
- [Scaling Issues - svglite vignette](https://cran.r-project.org/web/packages/svglite/vignettes/scaling.html) — Unit conversion in R SVG output
- [Understanding text size and resolution in ggplot2](https://www.christophenicault.com/post/understand_size_dimension_ggplot2/) — DPI and unit conversion details

### Secondary (MEDIUM confidence)

**Architecture Patterns:**
- [Vega-Lite: A High-Level Grammar of Interactive Graphics](https://vega.github.io/vega-lite/) — Declarative visualization architecture
- [D3.js Modular Architecture (Medium)](https://medium.com/@christopheviau/d3-js-modularity-d5eed78ba06e) — Component patterns
- [Plotly's ggplotly Converter](https://moderndata.plotly.com/ggplot2-docs-completely-remade-in-d3-js/) — Translation approach

**Competitive Analysis:**
- [Comparing R Graphic Packages - ggplot2 vs. plotly](https://williazo.github.io/statistics/plotly-ggplot2/) — Feature comparison
- [Interactive Data Visualization with R](https://blog.tidy-intelligence.com/posts/interactive-data-visualization-with-r/) — Ecosystem overview
- [ggiraph-user-2025](https://github.com/z3tt/ggiraph-user-2025) — Alternative interactivity approach

**Pitfalls and Edge Cases:**
- [ggplot2 Changelog](https://ggplot2.tidyverse.org/news/index.html) — Breaking changes across versions
- [Coord_flip also flip the axes side - Issue #1784](https://github.com/tidyverse/ggplot2/issues/1784) — Known coord_flip issues
- [Why Is My SVG Blurry? Fixing Common SVG Rendering Issues](https://www.svggenie.com/blog/svg-blurry-fixes) — Sub-pixel rendering
- [SVG Rendering in Browsers](https://area17.medium.com/svg-rendering-in-browsers-69e0a867297c) — Cross-browser consistency

### Tertiary (Project-Specific)

**Current Codebase Analysis:**
- `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` — Current 353-line monolithic IR builder
- `/Users/davidzenv/R/gg2d3/inst/htmlwidgets/gg2d3.js` — Current 716-line D3 renderer
- `/Users/davidzenz/R/gg2d3/vignettes/d3-drawing-diagnostics.md` — Known issues document
- `/Users/davidzenz/R/gg2d3/.planning/codebase/CONCERNS.md` — Technical debt and bugs
- `/Users/davidzenv/R/gg2d3/CLAUDE.md` — Project context and development commands

---
*Research completed: 2026-02-07*
*Ready for roadmap: YES*
