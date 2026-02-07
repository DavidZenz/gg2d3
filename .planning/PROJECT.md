# gg2d3

## What This Is

An R package that renders ggplot2 graphics as interactive D3.js SVG visualizations in the browser via htmlwidgets. Users pass a ggplot object to `gg2d3()` and get a pixel-perfect D3 reproduction with optional interactivity. Aimed at the R community as an open-source package.

## Core Value

Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## Requirements

### Validated

- ✓ Basic geom rendering (point, line, path, bar, col, rect, tile, text) — existing
- ✓ Continuous and categorical scale support — existing
- ✓ Axis rendering with titles — existing
- ✓ Color and fill aesthetic mapping — existing
- ✓ Theme translation (backgrounds, grids, axes, text) — existing
- ✓ Stacked bars — existing
- ✓ Basic coord_flip support — existing
- ✓ Three-layer pipeline (R → IR → D3) — existing
- ✓ htmlwidgets integration — existing

### Active

- [ ] Full geom coverage (statistical, area/ribbon, annotation geoms)
- [ ] Pixel-perfect visual fidelity matching ggplot2 output
- [ ] Legend rendering for all aesthetic types
- [ ] Facet support (facet_wrap, facet_grid)
- [ ] Full scale coverage (date/time, color palettes, sqrt, reverse, etc.)
- [ ] Pipe-based interactivity API (tooltips, linked views)
- [ ] Comprehensive test suite

### Out of Scope

- Shiny integration beyond basic htmlwidgets — separate future effort
- Custom D3 extensions unrelated to ggplot2 mapping — not the package's purpose
- ggplot2 extension packages (ggridges, ggrepel, etc.) — focus on core ggplot2 first
- Mobile-specific optimizations — web-first

## Context

gg2d3 is a brownfield project with a working three-layer pipeline: R extracts ggplot2 objects into a JSON intermediate representation, which D3.js renders as SVG. The core architecture is sound but currently handles only 8 geom types with known bugs (coord_flip axis positioning, geom_path sorting, bar baseline issues). The codebase has technical debt including a monolithic `as_d3_ir()` function, duplicated helpers, and reliance on ggplot2's private `:::calc_element()` API. Test coverage is minimal (1 test file). The IR format will need extension to carry data for new geoms, legends, and facets.

## Constraints

- **Tech stack**: R + JavaScript (D3.js v7) via htmlwidgets — established, not changing
- **ggplot2 compatibility**: Must work with current ggplot2 release; private API usage (`:::calc_element()`) is a known fragility
- **Visual fidelity**: Pixel-perfect matching of ggplot2 output at 96 DPI web standard
- **Package conventions**: Must follow CRAN-compatible R package structure (DESCRIPTION, NAMESPACE, roxygen2 docs)
- **Browser rendering**: SVG output only, no canvas/WebGL — D3.js conventions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Geom coverage before visual polish | User priority — broader coverage unlocks more use cases | — Pending |
| Legends early, facets later | Legends needed to verify geom rendering; facets are more complex | — Pending |
| Pipe-based interactivity API | Composable like ggplot layers: `gg2d3(p) \|> d3_tooltip() \|> d3_link()` | — Pending |
| Pixel-perfect fidelity target | R community expects professional output matching ggplot2 | — Pending |

---
*Last updated: 2026-02-07 after initialization*
