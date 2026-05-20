# Project Research Summary

**Project:** gg2d3 v1.9 sf Robustness and Expansion
**Domain:** R/htmlwidgets ggplot2-to-D3 SVG renderer with sf support
**Researched:** 2026-05-20
**Confidence:** HIGH

## Executive Summary

gg2d3 is an R package that converts ggplot2 objects into a JSON-like IR and renders them as interactive D3 SVG htmlwidgets. v1.8 established the production `geom_sf()` polygon foundation: R-side CRS normalization and diagnostics, GeoJSON serialization, panel-scoped bbox/projection metadata, `path.geom-sf` rendering, tooltip/hover/handler support, centroid brushing, and zoom suppression. v1.9 should strengthen that foundation rather than introduce a separate map engine.

The recommended approach is to add automated browser DOM smoke validation first, then expand sf support from polygon-family geometries to point and line families, then harden internals touched by the work. Keep the production stack stable: R, ggplot2, htmlwidgets, vendored D3 v7, sf, and geojsonsf. Add only `chromote` as an optional test dependency for live-browser DOM assertions. Do not add Playwright, Puppeteer, Selenium, Leaflet, browser CRS libraries, spatial JS libraries, or screenshot-diff infrastructure.

The biggest risks are false confidence from weak browser tests, treating points/lines as polygons by accident, breaking row identity under skipped rows/facets/multi-geometries, and broad refactoring of `as_d3_ir()` before characterization coverage exists. Mitigate these by asserting rendered DOM behavior in a real browser, preserving R-side geometry truth and panel-scoped projection metadata, keeping `path.geom-sf` as the shared sf compatibility selector, documenting centroid/representative-point brush semantics, and limiting hardening to small helper extractions after sf regression gates are in place.

## Key Findings

### Recommended Stack

Keep all production rendering dependencies unchanged. `sf`, `geojsonsf`, and `rnaturalearth` should remain optional `Suggests`; moving them to `Imports` would impose GDAL/GEOS/PROJ costs on users who never render maps. D3 v7 remains vendored and sufficient for GeoJSON `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, and `MultiPolygon` rendering through `d3.geoPath()`.

The only stack addition for v1.9 should be `chromote (>= 0.5.1)` in `Suggests`, used from `testthat` for local/CI browser smoke tests. Tests should use `htmlwidgets::saveWidget(selfcontained = FALSE)` to generate HTML fixtures, open them through headless Chrome, and assert DOM attributes and event effects. Browser tests must be skipped on CRAN and skipped cleanly when Chrome or optional spatial packages are unavailable.

**Core technologies:**
- R package + `testthat` - existing package and test harness; add guarded browser smoke tests here.
- `ggplot2` - source of build data and theme/facet metadata; isolate private API access behind wrappers.
- `htmlwidgets` - R-to-browser delivery contract; keep fixture generation through `saveWidget()`.
- D3 v7 - SVG rendering, `geoIdentity()`, `fitExtent()`, `geoPath()`, and `pointRadius()`.
- `sf` - R-side geometry inspection, CRS normalization, validity/empty checks, bbox calculation, and fixtures.
- `geojsonsf` - reliable `sfc` to GeoJSON serialization.
- `chromote` - optional dev/CI browser DOM smoke runner.

**Stack non-additions:**
- Do not add Playwright/Puppeteer/Node test tooling for v1.9 unless Phase 36 proves `chromote` cannot cover required brush/event checks.
- Do not add Selenium, shinytest2, webshot2, vdiffr, or screenshot diffs as the required validation gate.
- Do not add Leaflet, mapdeck, mapview, tile basemaps, `proj4js`, topojson-client, turf.js, spatial indexes, or a JSON Schema validator.

### Expected Features

v1.9 should make `geom_sf()` a deliberately bounded sf renderer for polygon, point, and line geometry families. It should not promise "all sf" behavior.

**Must have (table stakes):**
- Automated browser DOM smoke validation for sf fixtures: live rendered nodes, non-empty path data, finite anchors, row ids, console/page errors, brush behavior, and sanitized callback payloads.
- Polygon regression coverage: existing `POLYGON`/`MULTIPOLYGON` choropleths keep `path.geom-sf`, `fill-rule="evenodd"`, row identity, tooltip/hover/handler support, centroid brush, facets, stacked alignment, and zoom suppression.
- Browser fixture automation: deterministic fixture generation with useful artifacts for failures.
- `POINT` and `MULTIPOINT` support in `geom_sf()` with visible marks, finite projected anchors, row identity, mapped aesthetics where feasible, and source-row-oriented callbacks.
- `LINESTRING` and `MULTILINESTRING` support with ordered SVG paths, stroke-oriented defaults, no accidental polygon fill, and existing interactivity verbs.
- Family-aware diagnostics: accepted geometry types/families, unsupported types, skipped rows/reasons, missing CRS, and empty/invalid/missing geometry behavior.
- Shared panel projection across sf families and stacked sf layers, with `sf_bbox` computed from all accepted geometries in the panel.
- Existing sf interactivity parity for tooltip, hover, brush, handlers, and private-field sanitization.
- Continued `d3_zoom()` suppression for every sf widget until projection-aware map zoom is designed.
- Documentation updates that replace polygon-only language with a precise polygon/point/line contract.

**Should have (differentiators):**
- DOM assertions over source-string checks, so tests catch blank/malformed rendered SVG.
- Failure artifact bundle: generated HTML, console log, and optional diagnostic screenshot.
- Family-specific CSS classes beside the compatibility selector: `geom-sf-polygon`, `geom-sf-point`, `geom-sf-line`.
- Small mixed-overlay examples: choropleth plus points, boundaries plus routes.
- Deduplicated callback rows for multi-geometries where one source row produces multiple visible parts.
- Structured hardening checklist for private API wrappers, stale docs, and known renderer edge cases.

**Defer / out of scope:**
- `GEOMETRYCOLLECTION`, curved geometries, recursive/nested geometry support.
- `geom_sf_text()` and `geom_sf_label()`.
- Tile basemaps, raster backgrounds, slippy-map zoom/pan, and projection-aware map controls.
- JavaScript-side CRS reprojection.
- True polygon/line intersection brushing; v1.9 should document centroid or representative-point semantics.
- Large-map performance guarantees, simplification helpers, canvas/WebGL, and spatial indexing.
- Pixel-diff visual regression as the primary gate.
- Full rewrite of `as_d3_ir()`.

### Architecture Approach

Keep the existing three-layer pipeline and expand only the sf geometry helper and sf renderer. R remains responsible for geometry truth: detecting `sfc`, filtering missing/empty/invalid/unsupported rows, normalizing CRS to WGS84, serializing accepted geometries, preserving source `row_id`, computing panel `sf_bbox`, and emitting diagnostics. JavaScript receives accepted GeoJSON strings and draws them inside the existing panel, facet, interaction, and geom registry infrastructure.

**Major components:**
1. `R/as_d3_ir.R` - orchestrates ggplot build extraction, panel/facet metadata, and layer IR assembly; v1.9 should call narrower helpers rather than gain more geometry logic.
2. `R/sf_utils.R` - owns sf detection, supported-family classification, CRS normalization, row filtering, GeoJSON serialization, diagnostics, and degenerate bbox protection.
3. `R/validate_ir.R` - validates IR shape, especially data/geometries alignment and required sf diagnostics.
4. `inst/htmlwidgets/gg2d3.js` - preserves panel filtering of paired data/geometries and passes panel-scoped `sf_bbox` to the renderer.
5. `inst/htmlwidgets/modules/geoms/sf.js` - parses GeoJSON, fits one panel projection, renders all accepted sf families as `path.geom-sf` with family classes, and sets row/anchor attributes.
6. `inst/htmlwidgets/modules/events.js` and `brush.js` - keep existing interactivity contracts; brush remains pixel-space with sf representative anchors.
7. Browser smoke harness - test-only helper and tests under `tests/testthat`, with no runtime package dependency.

**Key architecture decisions:**
- Preserve `path.geom-sf` as the compatibility anchor for polygon, point, and line sf families. Use `d3.geoPath().pointRadius()` for points rather than switching to `circle.geom-sf`.
- Add family-specific classes, not separate public geoms.
- Compute `sf_bbox` from all accepted sf geometries in the current panel across stacked layers and families.
- Guard point-only and line-only degenerate bboxes before `fitExtent()`, with a JS fallback.
- Keep data/geometries paired through facet filtering; never filter or sort them independently.
- Centralize `ggplot2:::` access behind internal helpers during hardening.

### Critical Pitfalls

1. **Browser tests assert incidental markup instead of behavior** - open generated widgets in a live browser, poll for render completion, assert counts, non-empty `d`, finite anchors, row ids, panel-local counts, brush effects, and sanitized callbacks.
2. **Non-polygon support only widens `supported_types`** - add family classification, renderer branches, point radius handling, line no-fill defaults, family diagnostics, and fixtures for each supported type.
3. **CRS/projection alignment regresses** - preserve R-side normalization, compute panel bbox from all accepted families, test mixed EPSG:4326/EPSG:3857 overlays, missing CRS warnings, point-only and line-only panels, and facets.
4. **Row identity breaks under skipped rows, facets, or multi-geometries** - treat `row_id` as a public interaction contract; keep data/geometries paired; add child-part metadata only if needed; callbacks should remain source-row-oriented.
5. **Brush semantics are overpromised** - document and test centroid/representative-point brushing for sf; do not imply polygon/line overlap selection.
6. **Faceted sf expansion reintroduces global projection fitting** - assert per-panel `sf_bbox`, `NULL` empty-panel bbox, and DOM counts/coordinate ranges per panel.
7. **`as_d3_ir()` refactor appears mechanical but changes behavior** - refactor only after browser/sf regression gates, in small helper extractions with characterization tests.
8. **Private ggplot2 APIs stay scattered** - wrap `calc_element()`, `plot_theme()`, and other private structure reads behind tested compatibility helpers.

## Implications for Roadmap

Based on the research, v1.9 should start at Phase 36 and use four phases.

### Phase 36: Browser Sf Smoke Harness

**Rationale:** The project should not change sf rendering until v1.8 polygon behavior is protected by live DOM assertions. This phase converts manual fixture confidence into repeatable validation.

**Delivers:** `chromote` in `Suggests`; helper(s) for generating non-self-contained widget fixtures; smoke tests for polygon paths, row ids, finite centroid attrs, skipped rows, stacked layers, facets, brush behavior, callback sanitization, console/page errors, and zoom suppression.

**Addresses:** Automated DOM smoke validation, polygon regression checks, fixture automation.

**Avoids:** False confidence from file-existence/source-string tests, async htmlwidgets render races, fixture flakiness from heavy optional packages.

**Research flag:** Moderate. Planning should verify `chromote` can reliably simulate the required brush/event checks in this package. If not, document the gap before considering a Node browser runner.

### Phase 37: Non-Polygon Sf IR And Renderer

**Rationale:** Once polygon contracts are guarded, widen the sf contract to point and line families in the R IR and D3 renderer together. Accepting new types without renderer semantics is the central implementation trap.

**Delivers:** `sf_geometry_family()` helper; accepted types expanded to `POINT`, `MULTIPOINT`, `LINESTRING`, `MULTILINESTRING`, `POLYGON`, `MULTIPOLYGON`; family-aware diagnostics; panel bbox from all accepted families; degenerate bbox protection; renderer family classes; point radius handling through `geoPath().pointRadius()`; line `fill="none"` defaults; tests for point, multipoint, line, multiline, mixed accepted/unsupported rows, and CRS normalization.

**Addresses:** POINT/MULTIPOINT and LINESTRING/MULTILINESTRING support, geometry-family diagnostics, shared projection across families, stack stability without new runtime dependencies.

**Avoids:** Polygon-style fill on lines, invisible/default-radius points, broken source row identity, invalid point/line bboxes, and CRS drift.

**Research flag:** Low to moderate. D3 and sf patterns are documented; implementation planning should decide exact point radius mapping against existing gg2d3 size conventions.

### Phase 38: Sf Interaction, Facet, And Documentation Hardening

**Rationale:** Rendering nodes is not enough. v1.9 must prove point and line sf marks participate correctly in the existing interactivity stack and that docs state the precise contract.

**Delivers:** Browser smoke coverage for point/line tooltip, hover, handlers, brush, callback sanitization, stacked overlays, facet-wrap/grid including empty panels, and zoom suppression. Documentation updates for README/vignettes/roxygen/diagnostics to describe polygon, point, and line support; centroid/representative-point brushing; unsupported geometries; map anti-features; and optional browser validation.

**Addresses:** Existing sf interactivity parity, faceted/stacked alignment, documentation truthfulness, explicit out-of-scope behavior.

**Avoids:** Selector drift, callback payload leaks, global facet bboxes, users inferring overlap brushing or full-map-engine support.

**Research flag:** Low. This is mostly validation and documentation against decisions already made.

### Phase 39: Package Internals Hardening

**Rationale:** After the browser and sf behavior gates exist, reduce future maintenance risk in the core package without destabilizing unrelated geoms.

**Delivers:** Focused extraction around touched IR seams, especially `extract_sf_layer_ir()` and panel sf bbox assembly; centralized ggplot2 private API wrappers for theme extraction if touched; targeted regression tests for representative non-sf plots, facets, date scales, legends, coord_flip, polygon sf, point sf, and line sf; cleanup of stale renderer/documentation contradictions and known high-risk edge cases only where in scope.

**Addresses:** Monolithic `as_d3_ir()` risk, private ggplot2 API fragility, stale unsupported-geom behavior, core package hardening.

**Avoids:** Broad IR rewrites, unrelated renderer churn, hidden regressions in the 25 existing geoms.

**Research flag:** Moderate. Planning should inspect current `as_d3_ir.R` dependencies and choose the smallest helper extractions with characterization tests.

### Phase Ordering Rationale

- Browser validation comes first because it creates the regression tripwire for v1.8 polygon behavior before point/line changes.
- IR and renderer expansion belong together because accepted sf types, diagnostics, bbox metadata, and visual semantics are coupled.
- Interactions/facets/docs follow rendering because they verify the public behavior users experience and prevent overclaiming.
- Internals hardening comes last because broad refactoring is safest after the browser and sf contracts are locked.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 36:** Confirm the `chromote` helper can wait for htmlwidgets render completion, capture console/page errors, and simulate brush interactions robustly.
- **Phase 37:** Confirm point radius mapping and any limitations around `MULTIPOINT`/`MULTILINESTRING` row identity before implementation.
- **Phase 39:** Inspect current private ggplot2 API usage and `as_d3_ir()` side effects before extracting helpers.

Phases with standard patterns where additional research should usually be skipped:
- **Phase 38:** Interaction/facet/documentation validation should be driven by the already documented contracts and browser harness.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Local dependency state, chromote docs, testthat skip patterns, D3 geoPath docs, and current sf/htmlwidgets pipeline all support a small optional test-only addition. |
| Features | HIGH | Table stakes align with PROJECT.md, v1.8 shipped behavior, ggplot2 `geom_sf()` semantics, and current user-facing gaps. Browser-runner mechanics remain the main implementation detail. |
| Architecture | HIGH | Current component boundaries are clear in local code and research: R-side sf truth, panel-scoped bbox, D3 SVG drawing, and existing interactivity modules. |
| Pitfalls | HIGH | Risks are repo-specific and grounded in known v1.8 debt: manual browser fixtures, parallel data/geometries, private ggplot2 APIs, facet bbox behavior, and monolithic IR code. |

**Overall confidence:** HIGH

### Gaps to Address

- `chromote` brush simulation and render-wait ergonomics: validate in Phase 36 before making the harness a milestone gate.
- Point radius mapping: align `geom_sf()` point size behavior with existing gg2d3 size conventions and document any deferred aesthetics.
- Multi-geometry callback semantics: decide whether one source row that creates multiple visible parts returns once or per part; default recommendation is source-row deduplication.
- Mixed geometry-family layers: support only if source row identity, diagnostics, family classes, and interactivity remain simple; otherwise document homogeneous-family expectations for v1.9.
- CI wiring: choose controlled Chrome availability for project CI while keeping CRAN checks browser-free.

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` - current milestone goal, v1.8 shipped state, constraints, known tech debt, and out-of-scope boundaries.
- `.planning/research/STACK.md` - dependency recommendations, chromote addition, non-additions, sf/D3 stack rationale.
- `.planning/research/FEATURES.md` - table stakes, differentiators, anti-features, deferred items, user/developer contracts.
- `.planning/research/ARCHITECTURE.md` - component boundaries, data flow, build order, anti-patterns, and research gaps.
- `.planning/research/PITFALLS.md` - phase ownership, critical/moderate/minor pitfalls, and mitigations.
- Local code references cited by research: `R/as_d3_ir.R`, `R/sf_utils.R`, `R/validate_ir.R`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/geoms/sf.js`, `inst/htmlwidgets/modules/events.js`, `inst/htmlwidgets/modules/brush.js`, and current sf tests.
- Official docs cited by research: D3 `geoPath()`/`geoIdentity()`, ggplot2 `geom_sf()`/`coord_sf()`, sf geometry/transform/validity docs, testthat skip docs, chromote docs.

### Secondary (MEDIUM confidence)
- Mirrored package docs for `geojsonsf` and `htmlwidgets::saveWidget()` confirm current APIs but should be treated as supporting evidence behind installed/local behavior.

---
*Research completed: 2026-05-20*
*Ready for roadmap: yes*
