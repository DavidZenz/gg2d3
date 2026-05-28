# gg2d3

## What This Is

An R package that renders ggplot2 graphics as interactive D3.js SVG visualizations in the browser via htmlwidgets. Users pass a ggplot object to `gg2d3()` and get a pixel-perfect D3 reproduction with tooltips, zoom, brush selection, and linked views. Aimed at the R community as an open-source package.

## Core Value

Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## Current State

v1.13 Phases 52 and 53 are complete. gg2d3 now has a dedicated GitHub Actions browser visual smoke workflow, CI-mode browser failure behavior, downloadable `index.html`/`index.json` visual artifacts, stable DOM/browser-log metadata checks, approved sf visual smoke fixtures, a source-level renderer contract manifest, stricter renderer drift tests, and focused theme/geom-parameter IR helper boundaries. v1.12 Quality & Architecture Hardening remains the last shipped milestone; remaining v1.13 work continues with geometry polish closure in Phase 54.

## Current Milestone: v1.13 Regression & Release Polish

**Goal:** Turn the new validation and architecture foundations into release-ready regression confidence while closing the next practical geometry polish gaps.

**Target features:**
- CI-ready visual and DOM regression coverage built on the v1.12 browser smoke artifact contract.
- Deeper renderer and IR architecture consolidation around declarative geom contracts and remaining high-risk helper boundaries.
- Focused geometry polish for label boxes, transformed rect/tile scale semantics, ordinary polygon subgroup/hole behavior, and text placement deferrals.
- Release-facing documentation, validation gates, and package-site/readiness polish that describe the v1.13 support contract without overclaiming.

## Last Shipped Milestone: v1.12 Quality & Architecture Hardening

**Goal:** Make gg2d3 easier to trust and extend by adding visual/browser regression coverage, reducing renderer/IR maintenance burden, and closing high-value geometry polish gaps.

**Shipped features:**
- Screenshot or perceptual regression coverage for representative browser-rendered plots, with explicit skip semantics for optional local browser dependencies.
- Renderer and IR architecture cleanup that reduces maintenance risk around the monolithic `as_d3_ir()` path, geom registration, update handlers, and interactivity selectors.
- Selected geometry polish for known deferred gaps such as transformed-scale rect/tile behavior, polygon topology/hole behavior, label collision avoidance, or path-following annotations.

## Last Shipped Milestone: v1.11 Geometry Parity

**Goal:** Close the remaining geometry-parity gaps around ordinary polygons, rect/tile edge behavior, and sf annotations.

**Shipped features:**
- Ordinary `geom_polygon()` rendering with grouped paths, fill/stroke aesthetics, facets, and existing interactivity hooks where applicable.
- A focused rect/tile out-of-bounds reproduction that either fixes the renderer mismatch or documents a verified non-issue.
- `geom_sf_text()` and `geom_sf_label()` support, scoped to useful centroid/anchor behavior and the existing polygon/point/line sf contract.
- Source-first public documentation, generated help, diagnostics, and validation evidence for the shipped geometry-parity contract.

## Completed Milestone: v1.10 Release Hardening

**Goal:** Prepare gg2d3 for a cleaner release-quality checkpoint by closing package hygiene gaps, validating the release surface, and documenting known residual risks.

**Shipped features:**
- Package metadata and dependency hygiene for tests, docs, optional browser tooling, and spatial helpers.
- Release-blocking debt triage for stale references, known renderer edge cases, and advisory follow-ups from recent reviews.
- Reproducible release validation gates covering package tests, representative browser skips/runs, documentation generation, and package check behavior.
- Release notes and docs polish that describe the current v1.9/v1.10 support contract without stale milestone language.

## Previous Shipped Milestone: v1.9 sf Robustness and Expansion

**Goal:** Strengthen the `geom_sf` foundation with automated browser validation, non-polygon sf geometry support, and core package hardening.

**Shipped features:**
- DOM-level smoke coverage for rendered sf marks, centroid/anchor attributes, brushing behavior, runtime browser errors, sanitized payloads, and fixture automation.
- Non-polygon sf support for point and line geometry families without weakening the polygon-first contracts.
- sf point/line/mixed-family interactivity, facet validation, documentation, and generated help aligned to the v1.9 public support contract.
- Package hardening around high-risk internals such as sf IR helper boundaries, private ggplot2 API compatibility wrappers, and known renderer edge cases.

## Previous Shipped Milestone: v1.8 Production geom_sf Polygon MVP

**Goal:** Ship production-safe `geom_sf` polygon rendering for gg2d3, starting with polygon-family choropleths and the interactivity behaviors proven in v1.7.

**Shipped features:**
- Production-safe single-panel `geom_sf` polygon choropleths with tooltip, hover, centroid brush, and zoom suppression.
- Shared per-panel projection/bbox for stacked sf layers so overlays align.
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
- ✓ `geom_sf()` polygon-family IR extraction with CRS normalization, skipped-row diagnostics, accepted-geometry bbox metadata, and source-row alignment — v1.8 Phase 32
- ✓ Production single-panel `geom_sf` polygon renderer and interactivity with tooltip/hover/handler selectors, centroid brush, private-field sanitization, and zoom suppression — v1.8 Phase 33
- ✓ Shared projection alignment for stacked sf layers and facet-aware per-panel bbox/projection behavior for `facet_wrap()` and `facet_grid()` — v1.8 Phase 34
- ✓ Documentation and validation hardening for supported and unsupported sf behavior — v1.8 Phase 35
- ✓ Browser smoke harness for polygon-family sf fixtures, DOM contracts, runtime error capture, sanitized interaction payloads, centroid brushing, zoom suppression, and deterministic debug artifacts — v1.9 Phase 36
- ✓ Non-polygon `geom_sf()` IR and renderer support for point and line families — v1.9 Phase 37
- ✓ sf interaction, facet, and documentation hardening for point/line/mixed families — v1.9 Phase 38
- ✓ Package internals hardening for sf helper boundaries, ggplot2 compatibility wrappers, and bounded regression coverage — v1.9 Phase 39
- ✓ Package metadata, optional dependency skip behavior, and generated artifact hygiene for release readiness — v1.10 Phase 40
- ✓ Release-blocking debt triage for dependency/facet advisories, ordinary `geom_polygon()` support signaling, and rect/tile out-of-bounds diagnostics — v1.10 Phase 41
- ✓ Repeatable local release validation gate covering tests, docs, `R CMD check`, expected optional skips, failure artifacts, and Phase 43 handoff evidence — v1.10 Phase 42
- ✓ Documentation and release-note polish describing the shipped polygon/point/line `geom_sf()` contract, optional browser validation, residual risks, deferred non-blockers, and next-milestone candidates — v1.10 Phase 43
- ✓ Ordinary `geom_polygon()` IR recognition, grouped closed-path D3 rendering, facets, styling, zoom/update behavior, sanitized interactivity payloads, and grouped/faceted crosstalk key binding — v1.11 Phase 44
- ✓ Rect/tile edge behavior fixture matrix, ggplot2-compatible non-issue classification, categorical tile renderer fixes, update-path parity fixes, and diagnostics closure — v1.11 Phase 45
- ✓ `geom_sf_text()` and `geom_sf_label()` IR extraction, projected-anchor D3 rendering, facets/skipped-row coverage, and sanitized interaction contracts — v1.11 Phase 46
- ✓ Geometry parity documentation and validation handoff across README, vignettes, diagnostics, roxygen/generated help, and validation evidence — v1.11 Phase 47
- ✓ Deterministic opt-in browser visual smoke coverage for representative Cartesian, facet, interactivity, polygon, sf, and sf annotation surfaces with explicit optional dependency skips — v1.12 Phase 48
- ✓ High-risk `as_d3_ir()` helper boundaries isolated with representative IR behavior preserved — v1.12 Phase 49
- ✓ Renderer registration, update-handler, interactivity-selector, and public payload sanitization contracts covered for registered geoms, ordinary polygons, and sf text/label annotations — v1.12 Phase 50
- ✓ Geometry edge-case classification and polish for transformed rect/tile behavior, ordinary polygon subgroup/topology boundaries, and ordinary text size rendering with explicit label/topology deferrals — v1.12 Phase 51
- ✓ CI-ready browser visual smoke workflow, CI-mode report metadata, validated visual report rows, and downloadable artifact bundles — v1.13 Phase 52
- ✓ Renderer contract source validation and selected IR helper-boundary consolidation for modules, load order, render/update/interaction selectors, public payload sanitization, theme extraction, and geom parameter routing — v1.13 Phase 53

### Active

- v1.13 requirements for selected geometry polish and release-facing documentation/readiness.

### Out of Scope

- Shiny integration beyond basic htmlwidgets — separate future effort
- Custom D3 extensions unrelated to ggplot2 mapping — not the package's purpose
- ggplot2 extension packages (ggridges, ggrepel, etc.) — focus on core ggplot2 first
- Mobile-specific optimizations — web-first
- Tile basemaps/slippy-map controls — gg2d3 remains an SVG/htmlwidgets renderer focused on ggplot parity, not a tiled map engine
- JavaScript-side CRS reprojection — first production build should consume R-normalized WGS84 data
- Polygon-overlap brushing and large-map performance guarantees — deferred until polygon MVP behavior is stable

## Context

gg2d3 shipped v1.12 with a mature three-layer pipeline (R → IR → D3), production polygon/point/line-family `geom_sf()` support, ordinary polygon rendering, sf text/label annotations, deterministic opt-in browser visual smoke artifacts, and architecture hardening around high-risk IR and renderer/interactivity boundaries. R extracts ggplot2 objects via `ggplot_build()` into a JSON intermediate representation, D3 renders SVG through a registry-based geom dispatch system, and htmlwidgets bridges the browser output. The package supports 25 non-sf geom types, full scale system (continuous, discrete, log, sqrt, reverse, date/time), layout engine with legend and facet support, non-Cartesian coordinates, a composable pipe-based interactivity API, and polygon-first sf rendering with tooltip, hover, handler, centroid brush, stacked-layer alignment, and faceted panel projection behavior.

**Known tech debt:**
- `as_d3_ir()` now has focused helper boundaries, but broader modularization beyond the high-risk helper slices remains future work.
- Private ggplot2 theme access remains necessary but is quarantined in `R/ggplot2_compat.R` behind compatibility helpers.
- Transform-scale rect/tile edge parity is classified at the shared scale factory / axis semantics boundary rather than fixed by a rect-only renderer change.
- Polygon topology/hole repair beyond grouped closed paths, ggrepel-style collision avoidance, label boxes, and path-following text remain future geometry candidates.
- Browser visual smoke has deterministic local artifacts and explicit skips; live Chrome execution still depends on optional local browser dependencies.

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
| helper-driven sf IR preparation | Keep unsupported geometry filtering, CRS warnings, GeoJSON serialization, row identity, diagnostics, and accepted-geometry bbox calculation in the R IR layer | ✓ Good — implemented and verified in Phase 32 |
| sanitized sf interactivity payloads | `path.geom-sf` reuses existing tooltip, hover, handler, and brush APIs, but renderer-private `_geom`/`_centroid` fields must not become user-facing callback data | ✓ Good — implemented and verified in Phase 33 |
| panel-scoped sf projection metadata | Stacked and faceted sf layers should use `sf_bbox` from accepted geometries in the current panel, with the renderer filtering data/geometry pairs together by original row index | ✓ Good — implemented and verified in Phase 34 |
| documented polygon-first sf contract | The first production `geom_sf` support should be explicit about polygon-family support, skipped unsupported/empty/invalid/missing geometries, zoom suppression, and map anti-features | ✓ Good — implemented and verified in Phase 35 |
| chromote-backed sf browser smoke harness | Browser-level sf regression coverage should use optional R tooling and non-self-contained htmlwidgets fixtures, not a Node browser stack | ✓ Good — implemented and verified in Phase 36 |
| point/line sf support extends existing renderer contract | Non-polygon sf support should reuse the existing `.geom-sf` interactivity selectors and add family-specific DOM classes rather than introduce a separate map engine | ✓ Good — implemented and verified in Phase 37 |
| sf internals helper boundaries | Remaining sf layer assembly and panel bbox attachment should live behind focused helpers outside the monolithic `as_d3_ir()` body | ✓ Good — implemented and verified in Phase 39 |
| ggplot2 compatibility quarantine | Unavoidable private ggplot2 calls should be isolated behind internal wrappers with characterization tests and explicit comments | ✓ Good — implemented and verified in Phase 39 |
| release-hygiene dependency classification | Direct optional test, browser, vignette, visual-check, and helper dependencies should be declared in `Suggests`, while guarded runtime paths stay optional unless required unconditionally | ✓ Good — implemented and verified in Phase 40 |
| local generated artifact boundaries | Browser fixtures, logs, visual outputs, and check artifacts should be preserved for debugging under ignored paths and excluded from source package builds | ✓ Good — implemented and verified in Phase 40 |
| two-tier local release validation gate | Maintainers need quick day-to-day validation plus full release evidence without weakening optional browser/spatial skips | ✓ Good — implemented and verified in Phase 42 |
| gate-run-derived release handoff | Release notes should reuse summarized gate evidence and artifact paths rather than publish local logs or reinterpret raw command output | ✓ Good — implemented and verified in Phase 42 |
| source-first release documentation polish | README, vignettes, roxygen source, generated help, and release notes should describe the shipped polygon/point/line `geom_sf()` contract without stale milestone language | ✓ Good — implemented and verified in Phase 43 |
| combined geometry-parity milestone | Ordinary polygon, rect/tile edge behavior, and sf annotations share renderer/IR/interactivity risk and should be planned together after v1.10 hardening | ✓ Good — shipped as v1.11 |
| ordinary polygon grouped path renderer | Ordinary `geom_polygon()` should render through a dedicated grouped closed-path module, not by branching line/path renderers that sort or assume open paths | ✓ Good — implemented and verified in Phase 44 |
| representative polygon crosstalk keys | Grouped/faceted ordinary polygon paths should carry private source-row indices for crosstalk while public callbacks keep underscore-prefixed renderer fields sanitized | ✓ Good — implemented and verified in Phase 44 |
| rect/tile edge closure boundary | Rect/tile out-of-bounds behavior should be classified against ggplot2 built data first, fixed only at the implicated D3 renderer/update boundary, and closed as non-issue where panel clipping or scale-limit censoring is expected | ✓ Good — implemented and verified in Phase 45 |
| sf annotation anchor contract | `geom_sf_text()` and `geom_sf_label()` should render projected anchors aligned with existing sf panel projection metadata rather than adding ggrepel or path-following placement in the first pass | ✓ Good — implemented and verified in Phase 46 |
| source-first geometry support documentation | README, vignettes, roxygen source, generated help, and diagnostics should describe shipped geometry parity with adjacent caveats and validation evidence | ✓ Good — implemented and verified in Phase 47 |
| opt-in browser visual smoke artifacts | Browser validation should use local chromote-backed artifacts with explicit dependency skips before introducing CI/pixel-diff enforcement | ✓ Good — implemented and verified in Phase 48 |
| high-risk IR helper boundaries first | v1.12 should isolate scale, layer, facet, and panel responsibilities without attempting a full `as_d3_ir()` rewrite | ✓ Good — implemented and verified in Phase 49 |
| internal geom contracts for wiring | Renderer registration, update handling, and interactivity selectors should be guarded by source contracts so missing wiring fails tests | ✓ Good — implemented and verified in Phase 50 |
| shared public datum sanitizer | Tooltip, hover, Shiny-style handler, and brush payload paths should share private-field stripping instead of duplicating sanitization | ✓ Good — implemented and verified in Phase 50 |
| evidence-driven geometry polish | Rect/tile transforms, polygon topology, and text/label candidates should be classified against ggplot2/source behavior before claiming support or fixing local renderers | ✓ Good — implemented and verified in Phase 51 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-27 after starting v1.13 Regression & Release Polish*
