# Milestones

## v1.12 Quality & Architecture Hardening (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 13 plans, 31 tasks

**Delivered:** Quality and architecture hardening for browser visual confidence, IR helper boundaries, renderer/interactivity contracts, and geometry edge-case classification.

**Key accomplishments:**

- Shared browser visual smoke helper for opt-in screenshots, DOM summaries, browser logs, and local reports
- Opt-in browser visual smoke matrix covering Cartesian, facet, interactivity, polygon, sf, and sf annotation surfaces
- Maintainer diagnostics now document the browser visual smoke command, artifact bundle, coverage, and skip behavior
- Layer rowization, geom dispatch, aesthetic maps, var-name maps, and ordinary layer assembly now live behind internal helpers.
- Facet and panel metadata construction now lives behind internal helpers with final Phase 49 validation coverage.
- Internal geom contract metadata with source tests that guard renderer aliases and update selector coverage
- Event, brush, and crosstalk selectors now derive from internal geom contracts with tests guarding polygon, sf, and module-specific coverage
- Shared public datum sanitizer now strips renderer-private fields across tooltip, event, Shiny, and brush payload paths with final validation evidence recorded
- Transformed rect/tile bounds are classified against ggplot2 built data, with the remaining parity issue recorded as shared scale semantics rather than a rect-only fix.
- Ordinary polygon topology is classified as grouped closed-path behavior, with `subgroup` holes and topology repair explicitly outside the current contract.
- Ordinary text/label behavior is classified, and `geom_text(size=...)` now renders through the ordinary D3 text renderer instead of always using `10px`.
- Phase 51 validation evidence is executed and recorded, including focused geometry suites, expected browser-smoke skip behavior, and the final support/non-goal contract.

**Stats:**

- 53 files changed across code, tests, docs, and planning artifacts in the milestone diff
- 5,485 insertions / 361 deletions in the milestone diff
- 4 phases, 13 plans, 31 tasks
- 2 days from first v1.12 phase context to archive

**Known deferred items at close:** 0 open GSD blockers. The pre-close artifact audit reported the Phase 48 human UAT file, but it is `status: passed` with 0 pending scenarios and 0 gaps. No formal `v1.12-MILESTONE-AUDIT.md` was present; closeout relied on the clear open-artifact audit, phase verification reports, and code review artifacts.

---

## v1.11 Geometry Parity (Shipped: 2026-05-25)

**Phases completed:** 4 phases, 11 plans, 29 tasks

**Delivered:** Geometry parity closure for ordinary polygons, rect/tile edge behavior, and sf text/label annotations, with source-first documentation and validation evidence.

**Key accomplishments:**

- Ordinary `geom_polygon()` IR characterization coverage for row-order-preserving grouped polygons with facets and core style aesthetics
- D3 grouped `geom_polygon()` rendering with closed SVG paths, style handling, yaml loading, and zoom update support
- Ordinary `geom_polygon()` marks now participate in existing selector-driven interactivity with sanitized representative payload coverage
- Rect/tile edge behavior classified with ggplot2-built-data fixtures and renderer/update source contracts for Plan 45-02.
- Rect/tile renderer mismatches fixed at the D3 boundary with diagnostics and verification notes closing the deferred v1.10 item.
- R-side sf annotation extraction now produces validated `sf_text` and `sf_label` IR with geometry diagnostics and panel metadata.
- D3 rendering now places `sf_text` and `sf_label` marks from projected sf anchors using panel-local bbox metadata.
- sf annotation marks now reuse existing `.geom-sf` tooltip, hover, brush, handler, and crosstalk plumbing with sanitized public payloads.
- Source documentation now describes shipped ordinary polygon, rect/tile edge, and sf annotation support with adjacent v1.11 caveats and diagnostics links.
- Roxygen and generated help now describe v1.11 ordinary polygon, rect/tile, and sf annotation support from source-first documentation.
- Representative geometry parity evidence matrix with source-command outcomes, optional browser skip semantics, and future-risk handoff for v1.11

**Stats:**

- 95 files changed across code, tests, docs, and planning artifacts
- 12,358 insertions / 334 deletions in the milestone diff
- 4 phases, 11 plans, 29 tasks
- 2 days from first v1.11 phase context to archive

**Known deferred items at close:** 0 open GSD artifacts. No formal `v1.11-MILESTONE-AUDIT.md` was present; closeout relied on the clear open-artifact audit plus phase verification and code review artifacts.

---

## v1.10 Release Hardening (Shipped: 2026-05-23)

**Phases completed:** 4 phases, 10 plans, 28 tasks

**Key accomplishments:**

- Dependency metadata now covers direct runtime, test, browser, visual-check, README, and vignette package usage.
- Optional browser and spatial validation skip behavior is documented and verified without adding new tooling.
- Local browser, visual, and check artifacts now resolve to predictable ignored paths and are excluded from package builds.
- Release advisory follow-ups classified with source-backed dependency and facet identity evidence
- Ordinary polygon and rect/tile release debt classified with corrected public support documentation
- Two-tier local release validation contract with preserved browser/spatial skip semantics and artifact-backed coverage mapping
- Quick/full release gate execution with expected optional skips, repaired package-check blockers, and recorded `/private/tmp` check artifacts
- Gate-run-derived verification report and maintainer debugging handoff for browser, documentation, test, and package-check failures
- DOC-01 documentation now consistently states the shipped polygon-family, point-family, and line-family `geom_sf()` contract across source docs, generated README/help, and coverage evidence.
- DOC-02 now has a v1.10 release checklist summarizing Phase 42 gate outcomes, expected optional skips, residual risks, deferred non-blockers, and future candidates without publishing local logs.

**Known deferred items at close:** 2 context-question groups acknowledged and resolved/deferred through Phase 41/42 artifacts and Phase 43 release notes. See `.planning/STATE.md` Deferred Items.

---

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
