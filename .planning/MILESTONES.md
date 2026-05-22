# Milestones

## v1.9 sf Robustness and Expansion (Shipped: 2026-05-22)

**Phases completed:** 4 phases, 13 plans, 32 tasks

**Key accomplishments:**

- Browser sf smoke harness now generates non-self-contained htmlwidget fixtures, opens them through optional chromote tooling, and asserts live sf DOM contracts, runtime errors, sanitized payloads, centroid/anchor brushing, and zoom suppression.
- `geom_sf()` support expanded from polygon-family geometries to point-family and line-family geometries with shared row identity, CRS normalization, diagnostics, panel bbox metadata, and family-aware renderer classes.
- sf tooltip, hover, custom handler, Shiny-style handler, and brush behavior now work across polygon, point, line, multipoint, multiline, mixed-family, stacked, skipped-row, and faceted cases.
- README, vignettes, diagnostics docs, roxygen source, and generated help now document the v1.9 polygon/point/line support contract and explicit map anti-features.
- sf IR assembly and panel bbox attachment were extracted behind focused internal helpers while preserving existing IR behavior.
- Private ggplot2 theme/layout access is quarantined in `R/ggplot2_compat.R`, and representative non-sf, sf, facet, legend, date-scale, coord_flip, and renderer-edge behavior is covered by bounded regression tests.

**Known deferred items at close:** 0 open GSD artifacts. No formal `v1.9-MILESTONE-AUDIT.md` was present; closeout relied on the clear open-artifact audit plus phase verification and code review artifacts.

---

## v1.8 Production geom_sf Polygon MVP (Shipped: 2026-05-20)

**Phases completed:** 4 phases, 11 plans, 21 tasks

**Key accomplishments:**

- Polygon-family sf IR extraction with CRS normalization, source-row diagnostics, accepted-geometry bbox metadata, and structural validation.
- D3 `path.geom-sf` rendering for single-panel choropleths, including multipolygon holes, stable row ids, and centroid attributes.
- Existing tooltip, hover, handler, and brush APIs now work for sf paths with sanitized public callback payloads.
- Stacked sf overlays share panel-level projection metadata, and faceted sf maps isolate projection/bbox behavior per panel.
- `d3_zoom()` now suppresses unsupported sf Cartesian zoom with a clear warning while preserving other interactivity config.
- README, vignettes, diagnostics docs, generated help, automated checks, and browser fixtures now tell one truthful polygon-first sf support story.

**Known deferred items at close:** 0 blockers. One non-blocking validation debt item is recorded in `.planning/milestones/v1.8-MILESTONE-AUDIT.md`.

---

## v1.7 Choropleth Map Research (Shipped: 2026-05-20)

**Phases completed:** 4 phases, 6 plans, 16 tasks

**Key accomplishments:**

- Four sf geometry utility functions shipping geojsonsf::sfc_geojson() serialization with unconditional WGS84 normalization, dynamic sfc column detection, and 26 tests covering NC shapefile, rnaturalearth world borders, and EPSG:3857 projected CRS
- geom_sf extraction wired into as_d3_ir with GeomSf/CoordSf dispatch, WGS84-normalized GeoJSON geometries in IR, and validate_ir updated to recognize sf layers and skip Cartesian panel checks
- NC counties choropleth and world-borders MULTIPOLYGON hole tests generated and human-verified — all three REND requirements confirmed passing via browser inspection.
- geom_sf interactivity contract covering bound-row tooltips, selector-based hover, centroid brushing, and first-build zoom suppression
- geom_sf handoff blueprint covering polygon-first edge cases, explicit GIS anti-features, future build sequencing, file targets, and validation gates

**Known deferred items at close:** 0 open artifacts. One non-blocking validation-process note is recorded in `.planning/milestones/v1.7-MILESTONE-AUDIT.md`.

---

## v1.6 Advanced Geoms & API Polish (Shipped: 2026-04-04)

**Phases completed:** 14 phases, 17 plans, 9 tasks

**Key accomplishments:**

- Canonical discrete legend controller now drives toggle/solo/reset/hover semantics through d3.dispatch with deterministic legend-item identity and automatic render-time wiring.
- Legend controls now drive deterministic mark visibility and transient hover preview while staying synchronized with Crosstalk-linked selection across widgets.
- dotplot, rug, and interval geoms wired into hover/tooltip/brush/zoom via 6 new INTERACTIVE_SELECTORS entries and a functional scoped interval updateGeoms handler
- README.md regenerated from README.Rmd via devtools::build_readme(), now documenting all 25 geoms including geom_dotplot, geom_rug, geom_errorbar, and the full composable interactivity pipe API

---

## v1.0 MVP (Shipped: 2026-02-16)

**Phases completed:** 12 phases, 48 plans
**Timeline:** 10 days (2026-02-07 → 2026-02-16)
**Lines of code:** 10,442 (R + JavaScript)
**Tests:** 515+
**Commits:** 192

Delivered: Production-ready R package rendering any ggplot2 visualization as interactive D3.js SVG with pixel-perfect fidelity.

**Key accomplishments:**

- Modular three-layer architecture (R → IR → D3) with 14 JS modules and registry-based geom dispatch
- 15 geom types: point, line, path, bar, col, rect, tile, text, area, ribbon, segment, reference, boxplot, violin, density, smooth
- Full scale system with continuous, discrete, log, sqrt, reverse, and date/time transforms
- Pure-function layout engine + automatic legend system (discrete, colorbar, merged guides)
- Faceting: facet_wrap + facet_grid with fixed and free scales, strip labels
- Pipe-based interactivity API: d3_tooltip(), d3_hover(), d3_zoom(), d3_brush(), crosstalk linked views

---

## v1.1 Interactive Exploration (Shipped: 2026-03-31)

**Phases completed:** 3 phases (13-15)
**Timeline:** 8 days (2026-03-23 → 2026-03-31)

**Delivered:** Enhanced interactive workflows for data exploration, date/time parity, and coordination system hardening.

**Key accomplishments:**

- **Interactive Legends:** Implementation of toggle, solo/reset, and hover preview synchronization for discrete guides.
- **Date/Time Parity:** Full parity with ggplot2 for date breaks, labels, and robust timezone extraction across all browser locales.
- **coord_flip Hardening:** Corrected axis placement and orientation for flipped coordinates in both single-panel and faceted contexts.

---

## v1.2 Smooth Transitions & Scale Parity (Shipped: 2026-03-31)

**Phases completed:** 2 phases (16-17)
**Timeline:** 1 day (2026-03-31)

**Delivered:** Smooth animation system and deep scale parity.

**Key accomplishments:**

- **Fluid Animations:** Smooth enter/update/exit transitions for marks and axes.
- **Scale Depth:** Parity for per-panel minor breaks and OOB squishing logic.
- **Accessibility:** Support for `prefers-reduced-motion`.

---

## v1.3 Advanced Facets & Custom Interactivity (Shipped: 2026-03-31)

**Phases completed:** 2 phases (18-19)
**Timeline:** 1 day (2026-03-31)

**Delivered:** Hierarchical faceting and user-extensible interactivity.

**Key accomplishments:**

- **Nested Facets:** Support for multiple variables in facet_grid/facet_wrap with hierarchical headers.
- **Custom Handlers:** R API (`d3_handlers`) for injecting custom JS logic into plot events.
- **Shiny Sync:** Automated synchronization of plot clicks and legend changes with Shiny.

---

## v1.4 Comprehensive Theme Parity & Reference Geoms (Shipped: 2026-03-31)

**Phases completed:** 2 phases (20-21)
**Timeline:** 1 day (2026-03-31)

**Delivered:** High-fidelity theme system and common annotation geoms.

**Key accomplishments:**

- **Theme Inheritance:** Full `theme()` inheritance logic and support for detailed element styling (margins, text alignment).
- **Reference Geoms:** Implementation of `geom_hline`, `geom_vline`, and `geom_abline` with robust clipping.
- **Visual Fidelity:** Support for `element_blank()` and comprehensive legend box styling.

---

## v1.5 Non-Cartesian Systems & Advanced Stats (Shipped: 2026-03-31)

**Phases completed:** 2 phases (22-23)
**Timeline:** 1 day (2026-03-31)

**Delivered:** Support for radial coordinate systems and complex statistical geoms.

**Key accomplishments:**

- **Polar Coordinates:** Full support for `coord_polar`, including specialized radial/circular axis rendering and pie/coxcomb charts.
- **Advanced Stats:** High-fidelity rendering for `geom_density` and `geom_smooth` (loess, gam) using pre-computed R paths.
- **Statistical Transitions:** Extended the animation system to support complex SVG paths for ribbons and density outlines.

---

## v1.6 Advanced Geoms & API Polish (Planned)

**Status:** Planning
**Focus:** Completing the geom catalog and refining the developer experience.

**Planned Features:**

- **Additional Geoms:** Implementation of `geom_dotplot`, `geom_rug`, and `geom_errorbar`.
- **API Refinement:** Polishing documentation and internal helpers for easier extension.
- **Performance Audit:** Optimizing rendering for large datasets.
