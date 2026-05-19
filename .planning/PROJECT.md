# gg2d3

## What This Is

An R package that renders ggplot2 graphics as interactive D3.js SVG visualizations in the browser via htmlwidgets. Users pass a ggplot object to `gg2d3()` and get a pixel-perfect D3 reproduction with tooltips, zoom, brush selection, and linked views. Aimed at the R community as an open-source package.

## Core Value

Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## Current State

v1.6 shipped 2026-04-04. v1.7 research milestone active — Phase 29 complete (geom_sf interactivity strategy documented for tooltip/hover, centroid brushing, and first-build zoom suppression).

## Current Milestone: v1.7 Choropleth Map Research

**Goal:** Investigate how gg2d3 can support choropleth map rendering via `geom_sf()` and document a clear implementation plan for future build.

**Target features:**
- Investigate `geom_sf()` / sf geometry extraction through `ggplot_build()`
- Determine how polygon/multipolygon geometries map to the IR layer
- Evaluate D3 `d3.geoPath()` rendering approach for geographic shapes
- Assess projection handling (CRS → D3 projection)
- Document integration points with existing interactivity (hover, tooltip, brush on regions)
- Produce a feasibility assessment and implementation blueprint

**Shipped through v1.6:**
- 25 geom types with full interactivity (hover, tooltip, brush, zoom)
- Composable pipe-based interactivity API (`d3_tooltip`, `d3_zoom`, `d3_brush`, `d3_hover`, `d3_transitions`, `d3_handlers`)
- Interactive legends with toggle/solo/reset/hover
- Facets (wrap + grid) with linked interactivity
- Non-Cartesian coordinates (polar) and advanced stats (density, smooth)
- Comprehensive theme parity and reference geoms
- Performance optimized for >5000 points

## Requirements

### Validated

- ✓ Basic geom rendering (point, line, path, bar, col, rect, tile, text) — pre-existing
- ✓ Continuous and categorical scale support — pre-existing
- ✓ Axis rendering with titles — pre-existing
- ✓ Color and fill aesthetic mapping — pre-existing
- ✓ Theme translation (backgrounds, grids, axes, text) — pre-existing
- ✓ Stacked bars — pre-existing
- ✓ Basic coord_flip support — pre-existing
- ✓ Three-layer pipeline (R → IR → D3) — pre-existing
- ✓ htmlwidgets integration — pre-existing
- ✓ Full geom coverage (statistical, area/ribbon, annotation geoms) — v1.0
- ✓ Pixel-perfect visual fidelity matching ggplot2 output — v1.0
- ✓ Legend rendering for all aesthetic types — v1.0
- ✓ Facet support (facet_wrap, facet_grid) — v1.0
- ✓ Full scale coverage (date/time, color palettes, sqrt, reverse) — v1.0
- ✓ Pipe-based interactivity API (tooltips, linked views) — v1.0
- ✓ Comprehensive test suite — v1.0
- ✓ Interactive legend controls (toggle/filter/highlight) — v1.1
- ✓ Animation and transition support — v1.2
- ✓ Advanced facets and custom interactivity — v1.3
- ✓ Comprehensive theme parity and reference geoms — v1.4
- ✓ Non-Cartesian systems and advanced stats — v1.5
- ✓ Specialized geoms (dotplot, rug, errorbar, linerange, pointrange) — v1.6
- ✓ Full interactivity wiring for all 25 geoms — v1.6

### Active

- [x] Investigate `geom_sf()` geometry extraction via `ggplot_build()` — Validated in Phase 27
- [x] Map polygon/multipolygon geometries to IR layer — Validated in Phase 27
- [x] Evaluate D3 `d3.geoPath()` rendering for geographic shapes — Validated in Phase 28
- [x] Assess CRS → D3 projection handling — Validated in Phase 27 (unconditional WGS84 normalization)
- [x] Document interactivity integration for map regions — Validated in Phase 29
- [ ] Produce feasibility assessment and implementation blueprint — v1.7

### Out of Scope

- Shiny integration beyond basic htmlwidgets — separate future effort
- Custom D3 extensions unrelated to ggplot2 mapping — not the package's purpose
- ggplot2 extension packages (ggridges, ggrepel, etc.) — focus on core ggplot2 first
- Mobile-specific optimizations — web-first

## Context

gg2d3 shipped v1.6 with ~7,300 lines of R + JavaScript source code. The three-layer pipeline (R → IR → D3) is mature: R extracts ggplot2 objects via `ggplot_build()` into a JSON intermediate representation, which D3.js renders as SVG through a registry-based geom dispatch system. The package supports 25 geom types, full scale system (continuous, discrete, log, sqrt, reverse, date/time), layout engine with legend and facet support, non-Cartesian coordinates, and a composable pipe-based interactivity API. Test coverage spans 16 test files across 638+ tests.

**Known tech debt:**
- Monolithic `as_d3_ir()` function (~1000 lines) needs modularization
- Private API dependency on `ggplot2:::calc_element()` creates fragility
- Orphaned GeomPolygon reference (no renderer)
- rect geom edge cases with out-of-bounds rendering

## Constraints

- **Tech stack**: R + JavaScript (D3.js v7) via htmlwidgets — established, not changing
- **ggplot2 compatibility**: Must work with current ggplot2 release; private API usage (`:::calc_element()`) is a known fragility
- **Visual fidelity**: Pixel-perfect matching of ggplot2 output at 96 DPI web standard
- **Package conventions**: Must follow CRAN-compatible R package structure (DESCRIPTION, NAMESPACE, roxygen2 docs)
- **Browser rendering**: SVG output only, no canvas/WebGL — D3.js conventions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Geom coverage before visual polish | User priority — broader coverage unlocks more use cases | ✓ Good — 25 geoms shipped |
| Legends early, facets later | Legends needed to verify geom rendering; facets are more complex | ✓ Good — legends ready for facet integration |
| Pipe-based interactivity API | Composable like ggplot layers: `gg2d3(p) \|> d3_tooltip() \|> d3_zoom()` | ✓ Good — clean API, non-breaking |
| Pixel-perfect fidelity target | R community expects professional output matching ggplot2 | ✓ Good — ggplot2 .pt conversion factor, visual verification |
| Registry-based geom dispatch | Adding new geoms without modifying core rendering code | ✓ Good — 25 geoms self-register |
| Pure-function layout engine | Single source of truth for all positioning, no DOM dependency | ✓ Good — eliminated magic numbers |
| Pre-computed statistics in R | Statistical computations (boxplot, violin, density, smooth) in R, not JS | ✓ Good — leverages ggplot2's stat system |
| D3 scaleUtc for temporal axes | Consistent cross-browser rendering with UTC-based time scales | ✓ Good — timezone-aware tooltips via Intl.DateTimeFormat |
| Crosstalk for linked views | Client-side linked brushing without Shiny dependency | ✓ Good — works in static HTML |
| Scoped INTERACTIVE_SELECTORS | Each interactivity module maintains its own selector array for geom classes | ✓ Good — extensible, caught as gap in v1.6 audit |
| Standardized onRender pattern | All d3_* functions use consistent onRender + setTimeout for reliable event attachment | ✓ Good — eliminated race conditions |
| geom_sf interactivity contract | Tooltip/hover should extend existing `path.geom-sf` selectors, brush should use centroid `data-cx`/`data-cy`, and zoom should be suppressed for first sf build | ✓ Good — validated in Phase 29 design contract |

---
*Last updated: 2026-05-19 after Phase 29 completion*
