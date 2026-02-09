# Roadmap: gg2d3

## Overview

gg2d3 transforms from a working 8-geom prototype into a production-ready R package that renders any ggplot2 visualization as interactive D3.js graphics with pixel-perfect fidelity. The journey follows a strategic build order: refactor existing code into modular components (Phase 1), complete the scale system that everything depends on (Phase 2-3), expand geom coverage to unlock real use cases (Phase 4-5), implement the layout engine that prevents position chaos (Phase 6), add the most-requested features of legends and facets (Phase 7-9), and finally layer on interactivity as the compelling differentiator (Phase 10-11). This path minimizes rework by establishing stable foundations before building complex features.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation Refactoring** - Modularize existing codebase, centralize conversions
- [x] **Phase 2: Core Scale System** - Complete scale infrastructure for all rendering
- [x] **Phase 3: Coordinate Systems** - Fix coord_flip, add coord_fixed
- [x] **Phase 4: Essential Geoms** - Area, ribbon, segment, reference lines
- [ ] **Phase 5: Statistical Geoms** - Boxplot, violin, density, smooth
- [ ] **Phase 6: Layout Engine** - Centralized spatial math for multi-panel layouts
- [ ] **Phase 7: Legend System** - Automatic legend generation for all aesthetics
- [ ] **Phase 8: Basic Faceting** - facet_wrap with fixed scales
- [ ] **Phase 9: Advanced Faceting** - facet_grid, free scales, complex layouts
- [ ] **Phase 10: Interactivity Foundation** - Event system and tooltips
- [ ] **Phase 11: Advanced Interactivity** - Brush, zoom, linked views

## Phase Details

### Phase 1: Foundation Refactoring
**Goal**: Modularize existing 8-geom implementation into scalable component architecture without changing visual output

**Depends on**: Nothing (first phase)

**Requirements**: All existing features (basic geoms, scales, themes, axes)

**Success Criteria** (what must be TRUE):
  1. All 8 existing geoms (point, line, path, bar, col, rect, tile, text) render identically to current implementation
  2. Unit conversions (mm to px, pt to px) are centralized with documented constants
  3. Geom registry pattern allows adding new geoms without modifying core rendering code
  4. Scale factory creates D3 scale objects from IR descriptors consistently
  5. Theme system merges extracted theme with defaults without hardcoded values

**Plans:** 5 plans in 3 waves

Plans:
- [x] 01-01-PLAN.md -- Constants module + scale factory (Wave 1)
- [x] 01-02-PLAN.md -- Theme module + shared helpers (Wave 1)
- [x] 01-03-PLAN.md -- Geom registry + renderer extraction (Wave 2)
- [x] 01-04-PLAN.md -- IR validation with TDD (Wave 1)
- [x] 01-05-PLAN.md -- Integration wiring + visual verification (Wave 3)

### Phase 2: Core Scale System
**Goal**: Full continuous and discrete scale support including transforms and expansions

**Depends on**: Phase 1

**Requirements**: Scale transformations, color scales, scale expansion

**Success Criteria** (what must be TRUE):
  1. Log, sqrt, and power scale transformations produce mathematically correct axis positions
  2. Reverse scales flip domain correctly without breaking axis positioning
  3. Scale expansion (5% padding for continuous, 0.6 units for discrete) matches ggplot2 exactly
  4. Data points never touch axis edges unless expansion explicitly disabled
  5. Discrete scales handle reordered factors, dropped levels, and subsetted data correctly

**Plans:** 3 plans in 2 waves

Plans:
- [x] 02-01-PLAN.md -- R-side scale extraction: transforms + expansion from panel_params (Wave 1)
- [x] 02-02-PLAN.md -- D3 scale factory transform dispatch + axis tick rendering (Wave 1)
- [x] 02-03-PLAN.md -- Domain validation, discrete edge cases, and visual verification (Wave 2)

### Phase 3: Coordinate Systems
**Goal**: Fix coord_flip and add coord_fixed for proper aspect ratios

**Depends on**: Phase 2

**Requirements**: coord_flip fixes, aspect ratio control

**Success Criteria** (what must be TRUE):
  1. coord_flip places x-axis on left and y-axis on bottom (matching ggplot2)
  2. Axis labels orient correctly in flipped coordinates
  3. Grid lines align with correct axes after coordinate flip
  4. coord_fixed maintains specified aspect ratio during resize
  5. Coordinate transformations apply to all geoms consistently

**Plans:** 3 plans in 3 waves

Plans:
- [x] 03-01-PLAN.md -- Fix coord_flip: R-side coord extraction + D3 axis/grid/title rendering (Wave 1)
- [x] 03-02-PLAN.md -- Implement coord_fixed aspect ratio constraints with resize support (Wave 2)
- [x] 03-03-PLAN.md -- Coordinate system unit tests + visual verification checkpoint (Wave 3)

### Phase 4: Essential Geoms
**Goal**: Add critical geometric layers for complete basic plots (area, ribbon, segment, reference lines)

**Depends on**: Phase 2 (complete scales)

**Requirements**: geom_area, geom_ribbon, geom_segment, geom_abline/hline/vline

**Success Criteria** (what must be TRUE):
  1. Area plots render filled regions with proper baseline (zero or ymin aesthetic)
  2. Ribbon plots show confidence bands with ymin/ymax aesthetics
  3. Segments connect arbitrary point pairs with correct endpoints
  4. Reference lines (hline, vline, abline) appear at specified positions with correct styling
  5. All new geoms respect theme styling (colors, line widths, alpha)

**Plans:** 4 plans in 3 waves

Plans:
- [x] 04-01-PLAN.md -- R-side IR extraction + YAML + placeholder JS for new geom types (Wave 1)
- [x] 04-02-PLAN.md -- Implement geom_area and geom_ribbon with d3.area() (Wave 2)
- [x] 04-03-PLAN.md -- Implement geom_segment and reference lines (hline/vline/abline) (Wave 2)
- [x] 04-04-PLAN.md -- Unit tests + visual verification checkpoint (Wave 3)

### Phase 5: Statistical Geoms
**Goal**: Add statistical visualization layers (boxplot, violin, density, smooth)

**Depends on**: Phase 4

**Requirements**: Statistical geoms with computed aesthetics

**Success Criteria** (what must be TRUE):
  1. Boxplots show quartiles, median, and outliers matching ggplot2 calculations
  2. Violin plots display kernel density distributions symmetrically
  3. Density curves show smoothed distributions with proper bandwidth
  4. Smooth lines (loess, lm) match ggplot2's stat_smooth computations
  5. Statistical computations happen in R layer (pre-computed, not JavaScript)

**Plans:** 4 plans in 3 waves

Plans:
- [ ] 05-01-PLAN.md -- R-side IR extraction + validation + YAML + placeholder JS for stat geom types (Wave 1)
- [ ] 05-02-PLAN.md -- Implement geom_boxplot and geom_violin D3 renderers (Wave 2)
- [ ] 05-03-PLAN.md -- Implement geom_density and geom_smooth D3 renderers (Wave 2)
- [ ] 05-04-PLAN.md -- Unit tests + visual verification checkpoint (Wave 3)

### Phase 6: Layout Engine
**Goal**: Centralized spatial calculation system for panel positioning, legend placement, and axis positioning

**Depends on**: Phase 5

**Requirements**: Layout infrastructure for guides and facets

**Success Criteria** (what must be TRUE):
  1. calculateLayout() function returns complete position data for panels, legends, and axes
  2. Panel dimensions account for margins, padding, and reserved space for legends
  3. Legend positioning (right, left, top, bottom, inside) calculates correctly
  4. Secondary axes position correctly with layout engine coordinates
  5. Layout calculations separate from rendering (single source of truth)

**Plans**: TBD

Plans:
- [ ] 06-01: Create layout engine core with margin calculations
- [ ] 06-02: Implement legend positioning system
- [ ] 06-03: Axis positioning infrastructure
- [ ] 06-04: Panel calculation for multi-panel prep

### Phase 7: Legend System
**Goal**: Automatic legend generation for all aesthetic mappings (color, fill, size, shape, alpha)

**Depends on**: Phase 6

**Requirements**: Legends for all aesthetics, legend merging, guide types

**Success Criteria** (what must be TRUE):
  1. Color and fill legends show all mapped values with correct colors
  2. Size legends display representative point sizes from data range
  3. Shape legends show all mapped shapes from scale
  4. Multiple aesthetics merge into single legend when appropriate
  5. Continuous aesthetics show gradient colorbars with tick marks

**Plans**: TBD

Plans:
- [ ] 07-01: Extract guide specifications from ggplot_build()
- [ ] 07-02: Build guide IR with keys, labels, and aesthetic values
- [ ] 07-03: Implement D3 legend renderer for discrete aesthetics
- [ ] 07-04: Implement colorbar renderer for continuous aesthetics
- [ ] 07-05: Legend merging and positioning integration

### Phase 8: Basic Faceting
**Goal**: facet_wrap with fixed scales for small multiples

**Depends on**: Phase 6 (layout engine) and Phase 7 (legends)

**Requirements**: facet_wrap, panel layout, strip labels

**Success Criteria** (what must be TRUE):
  1. facet_wrap creates grid of panels wrapping at specified width
  2. Each panel shows correct data subset based on faceting variable
  3. Strip labels appear above/beside panels with facet variable values
  4. All panels share same x and y scales (fixed scales)
  5. Panel spacing and strip styling match ggplot2 theme

**Plans**: TBD

Plans:
- [ ] 08-01: Extract facet layout metadata from ggplot_build()
- [ ] 08-02: Build facet IR with panel assignments
- [ ] 08-03: Extend layout engine for multi-panel grid
- [ ] 08-04: Implement strip label rendering
- [ ] 08-05: Per-panel data filtering and rendering loop

### Phase 9: Advanced Faceting
**Goal**: facet_grid and free scales for complex multi-panel layouts

**Depends on**: Phase 8

**Requirements**: facet_grid, free scales, advanced facet features

**Success Criteria** (what must be TRUE):
  1. facet_grid creates 2D grid from row and column faceting variables
  2. Free scales (free_x, free_y, free) allow independent axis ranges per panel
  3. Panels with no data appear as blank spaces in grid
  4. Nested faceting variables create hierarchical panel structure
  5. Strip placement options (top, bottom, left, right) position correctly

**Plans**: TBD

Plans:
- [ ] 09-01: Implement facet_grid layout calculations
- [ ] 09-02: Free scale support with per-panel scale domains
- [ ] 09-03: Handle missing combinations in facet grid
- [ ] 09-04: Advanced strip positioning and styling
- [ ] 09-05: Nested faceting support

### Phase 10: Interactivity Foundation
**Goal**: Event system and tooltip functionality via pipe-based R API

**Depends on**: Phase 9

**Requirements**: Pipe-based interactivity API, tooltips

**Success Criteria** (what must be TRUE):
  1. User can add tooltips with gg2d3(p) |> d3_tooltip() syntax
  2. Hovering over data points displays tooltip with aesthetic values
  3. Tooltip content is customizable (fields, formatting)
  4. Event handlers attach without breaking static rendering
  5. Tooltips position dynamically to avoid viewport edges

**Plans**: TBD

Plans:
- [ ] 10-01: Create pipe API functions (d3_tooltip, d3_hover)
- [ ] 10-02: Implement D3 event system core
- [ ] 10-03: Build tooltip renderer with positioning
- [ ] 10-04: Message passing between R and D3 for interactivity config
- [ ] 10-05: Cross-geom event handler integration

### Phase 11: Advanced Interactivity
**Goal**: Brush, zoom, and linked views for dynamic exploration

**Depends on**: Phase 10

**Requirements**: Zoom/pan, brush selection, linked brushing

**Success Criteria** (what must be TRUE):
  1. User can add zoom with gg2d3(p) |> d3_zoom() and pan plot with drag
  2. Brush selection highlights selected data points across linked plots
  3. Crosstalk integration enables client-side linked brushing in static HTML
  4. Shiny integration allows server-side updates via message passing
  5. Zoom and brush reset to initial state when user double-clicks

**Plans**: TBD

Plans:
- [ ] 11-01: Implement d3_zoom() with scale updates
- [ ] 11-02: Implement d3_brush() with selection highlighting
- [ ] 11-03: Crosstalk integration for linked views
- [ ] 11-04: Shiny message protocol for interactive updates
- [ ] 11-05: Touch event support for mobile brushing

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> 11

| Phase | Plans | Status | Completed |
|-------|-------|--------|-----------|
| 1. Foundation Refactoring | 5/5 | Complete | 2026-02-07 |
| 2. Core Scale System | 3/3 | Complete | 2026-02-08 |
| 3. Coordinate Systems | 3/3 | Complete | 2026-02-08 |
| 4. Essential Geoms | 4/4 | Complete | 2026-02-09 |
| 5. Statistical Geoms | 0/4 | Not started | - |
| 6. Layout Engine | 0/4 | Not started | - |
| 7. Legend System | 0/5 | Not started | - |
| 8. Basic Faceting | 0/5 | Not started | - |
| 9. Advanced Faceting | 0/5 | Not started | - |
| 10. Interactivity Foundation | 0/5 | Not started | - |
| 11. Advanced Interactivity | 0/5 | Not started | - |

---
*Roadmap created: 2026-02-07*
*Total phases: 11 (comprehensive depth)*
*Total plans: 49 (estimated)*
