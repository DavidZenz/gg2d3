# gg2d3

## What This Is

An R package that renders ggplot2 graphics as interactive D3.js SVG visualizations in the browser via htmlwidgets. Users pass a ggplot object to `gg2d3()` and get a pixel-perfect D3 reproduction with tooltips, zoom, brush selection, and linked views. Aimed at the R community as an open-source package.

## Core Value

Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## Current State

v1.7 shipped 2026-05-20. The choropleth research milestone is complete: gg2d3 now has verified `geom_sf` R extraction research, a D3 polygon renderer prototype, interactivity design guidance, and a future implementation blueprint for production sf work.

## Next Milestone Goals

Start the next milestone with `$gsd-new-milestone`. The likely direction is a v1.8 production `geom_sf` build that starts from `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md`.

Candidate focus areas:
- Production-safe single-panel polygon choropleths with tooltip, hover, centroid brush, and zoom suppression.
- Shared per-panel projection/bbox for stacked sf layers.
- Faceted sf maps using per-panel projection from each panel's `PANEL` rows.
- Explicit unsupported geometry behavior and documentation hardening.

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
- ✓ `geom_sf()` extraction feasibility, CRS normalization, and IR schema — v1.7
- ✓ D3 polygon rendering prototype for `geom_sf` with multipolygon hole and aesthetic passthrough validation — v1.7
- ✓ `geom_sf` interactivity design for tooltip, hover, centroid brush, and zoom suppression — v1.7
- ✓ Future `geom_sf` implementation blueprint with edge cases, anti-features, file targets, and validation gates — v1.7

### Active

- [ ] Production `geom_sf` polygon MVP — future v1.8+ milestone candidate
- [ ] Shared projection alignment for stacked sf layers — future v1.8+ milestone candidate
- [ ] Faceted sf maps with per-panel bbox/projection behavior — future v1.8+ milestone candidate
- [ ] Unsupported sf geometry and documentation hardening — future v1.8+ milestone candidate

### Out of Scope

- Shiny integration beyond basic htmlwidgets — separate future effort
- Custom D3 extensions unrelated to ggplot2 mapping — not the package's purpose
- ggplot2 extension packages (ggridges, ggrepel, etc.) — focus on core ggplot2 first
- Mobile-specific optimizations — web-first
- Tile basemaps/slippy-map controls — gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity, not a tiled map engine
- JavaScript-side CRS reprojection — first production build should consume R-normalized WGS84 data
- Polygon-overlap brushing and large-map performance guarantees — deferred until polygon MVP behavior is stable

## Context

gg2d3 shipped v1.7 with a mature three-layer pipeline (R → IR → D3) plus a complete research handoff for `geom_sf`. R extracts ggplot2 objects via `ggplot_build()` into a JSON intermediate representation, D3 renders SVG through a registry-based geom dispatch system, and htmlwidgets bridges the browser output. The package supports 25 geom types, full scale system (continuous, discrete, log, sqrt, reverse, date/time), layout engine with legend and facet support, non-Cartesian coordinates, and a composable pipe-based interactivity API. The sf research stream validated geometry extraction, CRS normalization, GeoJSON serialization, D3 path rendering, centroid attributes, and future interactivity semantics.

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
| geojsonsf for sf serialization | C++-backed `sfc` to GeoJSON serialization is reliable and avoids ad hoc JSON construction | ✓ Good — validated in Phase 27 |
| R-side WGS84 normalization | Keep CRS handling in R via `sf::st_transform()` rather than implementing browser reprojection | ✓ Good — preserves simple D3 renderer boundary |
| `d3.geoIdentity().reflectY(true).fitExtent()` for sf prototype | Fits R-normalized GeoJSON polygons into SVG space without a full JS projection system | ✓ Good — validated visually in Phase 28 |
| geom_sf interactivity contract | Tooltip/hover should extend existing `path.geom-sf` selectors, brush should use centroid `data-cx`/`data-cy`, and zoom should be suppressed for first sf build | ✓ Good — validated in Phase 29 design contract |
| polygon-first `geom_sf` build blueprint | First production build should support `POLYGON`/`MULTIPOLYGON`, shared per-panel projection, explicit anti-features, and validation gates | ✓ Good — locked in Phase 30 blueprint |

---
*Last updated: 2026-05-20 after v1.7 milestone*
