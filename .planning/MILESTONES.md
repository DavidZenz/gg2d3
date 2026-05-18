# Milestones

## v1.7 Choropleth Map Research (Shipped: 2026-05-18)

**Phases completed:** 4 research phases (27-30) + 1 cross-milestone distribution phase (31)
**Plans:** 10 (6 v1.7 + 4 distribution, plus user-setup plan 31-04)
**Timeline:** 45 days (2026-04-04 → 2026-05-18)
**Git range:** cc31fad → c7a5c22 (30 files changed, 1,897 insertions, 164 deletions)

**Delivered:** A complete, build-ready blueprint for adding `geom_sf` choropleth support to gg2d3 — backed by working R-side IR extraction, a D3 sf renderer prototype with human-verified visual fidelity, an interactivity design contract covering tooltip/brush/zoom, and edge-case empirical findings with explicit anti-features. The public package site went live at https://davidzenz.github.io/gg2d3/ via pkgdown + GitHub Pages on every push to master.

**Known deferred items at close:** 2 (see STATE.md Deferred Items — Phase 29 human-UAT/verification gaps; 4 subjective design-doc reads pending)

**Key accomplishments:**

- **R sf extraction (Phase 27):** `R/sf_utils.R` with 4 utility functions (geojsonsf::sfc_geojson serialization, unconditional WGS84 normalization, geometry-type detection, CRS extraction), wired into `as_d3_ir.R` via GeomSf/CoordSf dispatch, with IR-SCHEMA-SF.md documenting the schema extension. 26 tests across NC shapefile, rnaturalearth world borders, EPSG:3857 projected CRS.
- **D3 sf renderer (Phase 28):** `inst/htmlwidgets/modules/geoms/sf.js` (113 lines) uses `d3.geoIdentity().reflectY(true).fitExtent()` (no JS reprojection) with `fill-rule="evenodd"` for multipolygon holes; centroids pre-computed and emitted as `data-cx`/`data-cy`. Human-verified for REND-01/02/03 via NC choropleth and world-borders test HTMLs.
- **Interactivity design contract (Phase 29):** `29-01-SF-INTERACTIVITY-DESIGN.md` (654 lines, 11 design decisions D-01..D-11) covers tooltip/hover, brush (centroid-only with documented rejection of polygon hit-testing), and zoom (SVG group transform + `vector-effect="non-scaling-stroke"` as presentation attribute). Resolves the `data-centroid` vs `data-cx/data-cy` inconsistency with named build-phase migration.
- **Implementation blueprint (Phase 30):** `30-01-BLUEPRINT.md` (734 lines) — three edge cases empirically resolved (mixed-geometry sentinel, multi-layer union-bbox confirmed, per-panel-bbox finding for faceted sf), three explicit anti-features (tile basemaps, JS-side reprojection, slippy zoom), and a phase-by-phase Build Phase A/B/C plan with file/line-anchored change callouts ready for `/gsd-plan-phase` to consume.
- **Cross-milestone distribution (Phase 31):** pkgdown site live at https://davidzenz.github.io/gg2d3/, rebuilds on every push to master via `.github/workflows/pkgdown.yaml` (r-lib v2-branch template, SHA-pinned JamesIves deploy action). Vignette gg2d3.html embeds 44 interactive `gg2d3()` widget divs; D-14 published-site human checkpoint passed on 2026-05-17. Satisfies cross-milestone requirement DOCS-02.

**Requirements:** 14/14 satisfied — FEAS-01..04, REND-01..03, INTR-01..03, BLPR-01..03, DOCS-02.

**Audit:** .planning/milestones/v1.7-MILESTONE-AUDIT.md (status: tech_debt — no critical blockers; verification-artifact gaps non-blocking for a research milestone)

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
