# Domain Pitfalls

**Domain:** v1.9 sf robustness and expansion for R/htmlwidgets + D3 `gg2d3`
**Researched:** 2026-05-20
**Overall confidence:** HIGH for repo-specific risks; MEDIUM for future non-polygon rendering details until implementation fixtures exist.

## Recommended Phase Ownership

| Phase | Suggested Name | Primary Risk Area |
|-------|----------------|-------------------|
| Phase 36 | Browser Sf Smoke Harness | DOM/browser validation hardening for rendered sf nodes and brush behavior |
| Phase 37 | Non-Polygon Sf IR And Renderer | POINT/MULTIPOINT/LINESTRING/MULTILINESTRING extraction, rendering, aesthetics, diagnostics |
| Phase 38 | Sf Interaction And Facet Hardening | Brush semantics, row identity, stacked/faceted bbox alignment across mixed sf geometry families |
| Phase 39 | Package Internals Hardening | `as_d3_ir()` modularization, ggplot2 private API isolation, regression gates |

## Critical Pitfalls

Mistakes that can cause rewrites, false confidence, or user-visible regressions.

### Pitfall 1: DOM Smoke Tests Assert Incidental Markup Instead Of Behavior

**What goes wrong:** Browser tests pass because an SVG exists, while `path.geom-sf` nodes have empty `d` attributes, missing centroid attributes, wrong `data-row-id`, broken facet filtering, or brush callbacks returning renderer-private fields.

**Why it happens:** v1.8 coverage is mostly R-side/source-contract tests plus generated/manual HTML fixtures. htmlwidgets interactivity is attached through `onRender(... setTimeout(..., 0))`, so tests that query immediately or inspect raw files can miss runtime failures. Playwright also distinguishes retrying locator assertions from one-shot value assertions; one-shot checks are a common source of flaky or falsely passing tests.

**Consequences:** The project can ship automated "browser coverage" that does not catch the exact v1.8 audit debt: rendered `path.geom-sf` nodes, finite `data-cx`/`data-cy`, brush selection, and fixture automation.

**Prevention:**
- Use a real browser smoke layer, not only static HTML inspection or jsdom. Prefer Playwright for the first hardening phase because D3 SVG layout APIs and pointer events matter.
- Save fixtures with `htmlwidgets::saveWidget(..., selfcontained = FALSE)` to avoid Pandoc and keep dependencies inspectable.
- Assert stable contracts: `svg .panel path.geom-sf` count, non-empty `d`, finite `data-cx`/`data-cy`, stable `data-row-id`, per-panel counts under facets, and no `_geom`/`_centroid` fields in public callback payloads.
- Use retrying locator or polling assertions for render completion. Avoid fixed sleeps except as a last-resort diagnostic.
- Put test-only hooks behind stable DOM attributes or callbacks; do not rely on D3-generated child ordering beyond known `panel > clipped group > geom` structure.

**Detection:** Tests pass locally but fail in CI; path count is correct but attributes are blank; brush tests pass without proving opacity/callback changes; tests read HTML source instead of evaluating the live DOM.

**Phase:** Phase 36.

### Pitfall 2: Non-Polygon Sf Support Is Implemented By Only Expanding `supported_types`

**What goes wrong:** `prepare_sf_geometry_ir()` accepts `POINT` or `LINESTRING`, but the existing renderer still treats every sf row like a polygon path with fill, `fill-rule`, polygon centroid brushing, and polygon-oriented defaults.

**Why it happens:** D3 `geoPath()` can render all GeoJSON geometry types, so it is tempting to let the current `path.geom-sf` renderer handle everything. That hides semantic differences: points need radius/size handling, lines should not be filled, multipoints may create multiple visible marks for one data row, and line centroids/bounds are not equivalent to polygon selection.

**Consequences:** Point maps may show tiny default-radius circles unrelated to ggplot2 `size`; lines may inherit fill incorrectly; brush behavior becomes surprising; legends and tooltips may appear to work while visual fidelity is wrong.

**Prevention:**
- Add an explicit sf geometry-family field in the IR, not just a wider accepted type list. Treat polygon, line, and point families as renderer branches with separate defaults.
- Keep a single public geom name (`geom = "sf"`) if that preserves API compatibility, but use internal `geom_type` or `geometry_family` for rendering and tests.
- For points, choose and document one renderer contract: either SVG circles positioned through the sf projection, or paths with `path.pointRadius()` whose radius is derived from ggplot2 size. Do not rely on D3's default point radius as a visual-fidelity decision.
- For lines, set fill to `none` by default and map `colour`, `linewidth`, `alpha`, `linetype`, and `lineend` deliberately.
- Add fixture coverage for POINT, MULTIPOINT, LINESTRING, MULTILINESTRING, and mixed-family layers before treating the feature as complete.

**Detection:** A point layer renders as paths but ignores `size`; a line layer has filled artifacts; multipoints produce one row but many visible symbols with ambiguous tooltip/brush behavior; source tests only check accepted rows and never inspect rendered attributes.

**Phase:** Phase 37, with browser assertions in Phase 36/38.

### Pitfall 3: CRS Alignment Regresses When Mixed Sf Families Are Added

**What goes wrong:** Points, lines, and polygons from different CRSs appear misaligned even though each layer renders. Stacked layers may each fit independently or panels may use bbox metadata computed from only one family.

**Why it happens:** Current v1.8 behavior relies on R-side WGS84 normalization in `sf_utils.R`, panel-scoped `sf_bbox` metadata in `as_d3_ir.R`, and D3 `geoIdentity().reflectY(true).fitExtent()` in `sf.js`. `coord_sf()` in ggplot2 ensures layers share a common CRS, while gg2d3 currently normalizes sf geometries before serialization and fits SVG space from panel bbox. Expanding geometry families increases the chance that bbox aggregation, empty geometries, missing CRS, or accepted/skipped filtering diverges by family.

**Consequences:** Overlay points drift from polygons; faceted maps use global extents; missing-CRS coordinates are silently fit with WGS84-normalized layers; line-only panels may get null or invalid bbox metadata.

**Prevention:**
- Preserve the R-side projection boundary: no JavaScript-side CRS reprojection in v1.9.
- Compute `sf_bbox` from all accepted sf geometries in the panel, across all sf families and stacked sf layers.
- Keep missing CRS warning behavior, but test mixed known-CRS/missing-CRS layers explicitly because "serialized as-is" is not alignment-safe.
- Add tests where the same features are provided in EPSG:4326 and EPSG:3857 and must overlay after normalization.
- Add line-only and point-only panels to bbox tests, including faceted empty panels.

**Detection:** `ir$panels[[i]]$sf_bbox` differs by layer order; stacked overlays align in single-panel tests but drift under facets; browser smoke screenshots show apparently valid SVG paths in the wrong panel location.

**Phase:** Phase 37 for IR acceptance and bbox; Phase 38 for stacked/faceted alignment validation.

### Pitfall 4: Row Identity Breaks Under Filtering, Faceting, Or Multi-Geometries

**What goes wrong:** Tooltip, hover, handlers, and brush callbacks report the wrong row after unsupported rows are skipped, facets are filtered, or multipoint/multiline geometries are rendered.

**Why it happens:** Current sf rendering uses parallel `layer.data` and `layer.geometries` arrays, with `row_id` preserving source row identity. `gg2d3.js` facet filtering preserves data/geometry pairs by array index. This is correct but fragile: any future refactor that filters data and geometries separately, sorts rows, expands multipoints into multiple DOM nodes, or rebuilds rows in JS can break identity.

**Consequences:** User callbacks mutate/select the wrong data; brush selections are impossible to trust; faceted sf plots pass visual checks but fail linked-view semantics.

**Prevention:**
- Treat `row_id` as a public sf interaction contract. It must remain source-row identity, not post-filter index.
- Keep data and geometry paired as a single internal structure during filtering, then split only at the renderer boundary if needed.
- If multipoints are expanded into multiple DOM nodes, add both `data-row-id` and a child geometry index such as `data-geometry-part`, while callbacks still return the source row once unless explicitly documented otherwise.
- Test skipped rows plus facets together, not separately.
- Test that callback payloads are sanitized and row ids match expected source rows after brushing.

**Detection:** `data-row-id` values reset to `1..n` after filtering; brushed rows include skipped source rows; callbacks include `_geom` or `_centroid`; facet panels render correct counts but wrong `data-row-id` attributes.

**Phase:** Phase 37 for IR and renderer contracts; Phase 38 for interaction/facet regression tests.

### Pitfall 5: Brush Behavior Is Defined Too Broadly For Sf Geometry Families

**What goes wrong:** A rectangle brush over a line or polygon selects based on a centroid users did not touch, or a point brush selects visually nearby marks inconsistently with ordinary `geom_point`.

**Why it happens:** v1.8 intentionally uses projected centroid attributes for `path.geom-sf` brush selection. That is a clear polygon MVP contract, but it is not automatically correct for lines and points. D3 brush selection is pixel-space, and current `brush.js` has a special `geom-sf` branch that reads `data-cx`/`data-cy` before the generic path bbox fallback.

**Consequences:** The same brush rectangle can select a county by centroid but miss a long line crossing the rectangle; users infer polygon-overlap or line-intersection semantics that gg2d3 does not provide.

**Prevention:**
- Keep v1.9 brush semantics explicit: polygon-family remains centroid brush unless a later phase implements overlap; point-family should use point center; line-family should use a documented representative point or bbox/endpoint policy.
- Name this in docs and tests. Do not let tests imply overlap brushing unless implemented.
- Consider adding geometry-family-specific attributes: `data-cx`/`data-cy` for representative point, plus optional `data-bbox-*` for future line/polygon overlap work.
- Preserve the current callback sanitization path.

**Detection:** Brush tests only check that opacity changes somewhere; long lines crossing a selection are not selected; docs say "features inside brush" without defining centroid/representative-point behavior.

**Phase:** Phase 38.

### Pitfall 6: Faceted Sf Expansion Reintroduces Global Projection Fitting

**What goes wrong:** Facet panels render, but all panels share a global bbox, or empty panels inherit a neighboring panel's bbox.

**Why it happens:** v1.8 fixed this by storing sf geometries by `PANEL` and assigning per-panel `sf_bbox` in `as_d3_ir.R`. Non-polygon expansion may add new helper paths or refactors that compute bbox from `sf_coord_geometries` globally or from the current layer only.

**Consequences:** Faceted maps lose comparability with ggplot2 behavior; empty facet panels can render stray marks; stacked overlays align in one facet but not another.

**Prevention:**
- Keep panel-scoped bbox calculation as the only renderer fit source for faceted `coord_sf` plots.
- Test `facet_wrap()` and `facet_grid(drop = FALSE)` for polygon-only, point-only, line-only, and mixed-family data.
- Include empty panels in tests and assert their `sf_bbox` is `NULL`, not borrowed.
- In browser smoke tests, assert each panel's sf element count and projected coordinate range independently.

**Detection:** `ir$panels` has identical `sf_bbox` values for panels with far-apart data; rendered features cluster in the same relative area in every facet; empty panels contain sf nodes.

**Phase:** Phase 38.

### Pitfall 7: Refactoring `as_d3_ir()` Changes Behavior While Appearing Mechanical

**What goes wrong:** Package hardening breaks non-sf geoms, legends, facets, date scales, theme extraction, or sf projection metadata because a monolithic function was split without enough characterization tests.

**Why it happens:** `as_d3_ir.R` contains geom dispatch, data rowization, theme extraction, scale metadata, guide extraction, facet extraction, coord metadata, and sf bbox collection in one function. Several pieces depend on side effects (`<<-` into sf geometry accumulators), duplicated helpers, and ggplot2 object internals.

**Consequences:** A refactor intended to reduce risk becomes the biggest regression source in v1.9.

**Prevention:**
- Refactor only after Phase 36-38 have locked browser and sf regression gates.
- Extract pure helpers in small commits: geom-name detection, rowization, sf layer preparation, panel metadata, theme extraction. Avoid changing IR schema in the same phase.
- Add snapshot-like structural tests for representative plots before moving code: non-faceted point plot, date scale, color legend, facet_wrap, facet_grid, coord_flip, polygon sf, point sf, line sf.
- Keep old and new helper output compared in tests during the transition where feasible.

**Detection:** Broad diff in `as_d3_ir.R` plus only sf tests run; changed warnings; changed key order or missing optional fields in IR; unrelated visual fixtures differ.

**Phase:** Phase 39.

### Pitfall 8: Private ggplot2 APIs Stay Scattered And Unversioned

**What goes wrong:** A future ggplot2 release changes `ggplot2:::calc_element()`, `ggplot2:::plot_theme()`, facet params, or panel param structure, and gg2d3 starts warning, mis-rendering, or failing.

**Why it happens:** The current package uses private ggplot2 APIs for theme and layout extraction, and also reads ggplot build internals such as `b$layout$panel_params`, `b$layout$facet$params`, and ggproto class names. This is common for ggplot2 converters, but it is fragile unless isolated.

**Consequences:** Users see regressions unrelated to v1.9 sf work; CRAN checks can break when dependency versions move; sf failures are misdiagnosed as geometry issues.

**Prevention:**
- Centralize private ggplot2 access behind wrapper functions with fallbacks and tests.
- Prefer exported APIs where available, such as `ggplot2::get_guide_data()` already used for guides.
- Add compatibility tests that fail with clear messages when key ggplot2 structures move.
- Record the supported ggplot2 version range in package docs or release notes if hard limits are discovered.

**Detection:** `:::` appears in new code outside the wrapper module; tests fail only under a newer ggplot2; warnings fall back to default panel ranges or default theme values silently.

**Phase:** Phase 39.

## Moderate Pitfalls

### Pitfall 1: Test Fixtures Depend On Optional Heavy Packages Or Network

**What goes wrong:** Browser fixture tests fail on CI or contributors' machines because they require optional packages, downloaded map data, Pandoc, or self-contained widget bundling.

**Prevention:** Use small synthetic `sf::st_sf()` geometries for core tests. Keep `rnaturalearth`/large map fixtures as optional/manual or skipped tests. Continue `selfcontained = FALSE`.

**Phase:** Phase 36.

### Pitfall 2: Geometry Validity Filtering Becomes Too Aggressive For Lines And Points

**What goes wrong:** Valid non-polygon geometries are skipped because filtering logic was written around polygon validity/emptiness.

**Prevention:** Validate `st_is_empty()`, `st_is_valid()`, missing geometry, and supported-type checks separately for each geometry family. Keep skipped diagnostics family-aware.

**Phase:** Phase 37.

### Pitfall 3: Aesthetic Defaults Ignore Geometry Family

**What goes wrong:** Lines inherit polygon fill defaults; points ignore `shape`, `stroke`, or `size`; alpha is applied inconsistently.

**Prevention:** Define an sf aesthetic matrix for polygon, line, and point families before coding. Match ggplot2 where feasible, and explicitly document deferred aesthetics.

**Phase:** Phase 37.

### Pitfall 4: Zoom Suppression Is Accidentally Removed

**What goes wrong:** Adding browser smoke tests or non-polygon sf support enables Cartesian `d3_zoom()` on sf widgets again, producing misleading transforms.

**Prevention:** Keep `d3_zoom()` suppression for all `geom_sf` layers in v1.9 unless a dedicated sf zoom design exists. Add a regression test with point and line sf widgets.

**Phase:** Phase 38.

### Pitfall 5: Source-Contract Tests Become A Substitute For Browser Tests

**What goes wrong:** Tests search JS files for strings like `data-cx` or `path.geom-sf` and claim behavior coverage.

**Prevention:** Keep source-contract tests for cheap guardrails, but require one live browser assertion for every public sf interaction contract.

**Phase:** Phase 36.

## Minor Pitfalls

### Pitfall 1: Documentation Says "All Sf" Too Early

**What goes wrong:** Users expect `GEOMETRYCOLLECTION`, `CURVEPOLYGON`, Z/M dimensions, projection controls, basemaps, or overlap brushing.

**Prevention:** Phrase v1.9 as "polygon, point, and line sf geometry families" with explicit unsupported geometry diagnostics.

**Phase:** Phase 37 and Phase 38 docs.

### Pitfall 2: CSS Selectors Drift Across Interactivity Modules

**What goes wrong:** Renderer introduces `circle.geom-sf-point` or `path.geom-sf-line`, but tooltip, hover, brush, handler, or crosstalk selectors are not updated.

**Prevention:** Either keep `path.geom-sf` as a shared selector for all sf families or introduce a centralized selector registry. Test every new sf DOM class with all existing interactivity APIs.

**Phase:** Phase 38.

### Pitfall 3: Snapshot Counts Hide Visual Regressions

**What goes wrong:** Tests assert node counts but not whether features are visible, finite, or inside panel bounds.

**Prevention:** Add bounds checks for `d`, `cx/cy`, line path length/bounds, and per-panel rendered extents. Screenshot tests are optional; DOM geometry checks are required.

**Phase:** Phase 36 and Phase 38.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Browser smoke harness | Flaky tests caused by async htmlwidgets render and one-shot assertions | Use Playwright locators/retrying assertions, poll for `path.geom-sf` count and finite attributes |
| Browser smoke harness | Fixture generation depends on Pandoc or optional map packages | Use non-self-contained widgets and synthetic sf data for required tests |
| Non-polygon IR | Adding `POINT`/`LINESTRING` to `supported_types` without schema clarity | Add `geometry_family`, family-aware diagnostics, and tests per family |
| Non-polygon renderer | Points/lines inherit polygon fill/centroid assumptions | Separate renderer branches and aesthetic defaults by family |
| CRS/projection | Mixed CRS layers drift after normalization or missing CRS serialization | Test EPSG:4326 + EPSG:3857 overlays and missing-CRS warnings explicitly |
| Row identity | Data/geometries filtered separately under facets | Preserve paired filtering and assert `data-row-id` source rows after skips |
| Brush behavior | Users infer overlap/intersection selection from rectangle brush | Document representative-point semantics and test the exact chosen policy |
| Facets | Empty panels or far-apart panels inherit global bbox | Assert per-panel `sf_bbox`, null empty-panel bbox, and DOM counts |
| Refactoring | Mechanical split of `as_d3_ir()` changes unrelated IR fields | Refactor after sf/browser gates; use characterization tests before edits |
| Private ggplot2 APIs | Dependency update breaks private theme/facet extraction | Centralize `:::` usage behind wrappers with fallbacks and version-sensitive tests |

## Sources

- Local project context: `.planning/PROJECT.md`, `.planning/RETROSPECTIVE.md`, `.planning/milestones/v1.8-MILESTONE-AUDIT.md`.
- Local implementation: `R/as_d3_ir.R`, `R/sf_utils.R`, `inst/htmlwidgets/modules/geoms/sf.js`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/brush.js`, `tests/testthat/test-sf-visual.R`.
- sf official docs: `st_geometry_type()` returns per-geometry or set-level geometry types, supporting family-aware filtering. https://r-spatial.github.io/sf/reference/st_geometry_type.html
- sf official docs: `st_transform()` transforms coordinates and can return empty geometries when transformation fails; axis-order ambiguity around EPSG:4326 is documented. https://r-spatial.github.io/sf/reference/st_transform.html
- ggplot2 official docs: `geom_sf()` uses the unique `geometry` aesthetic, `coord_sf()` aligns layers to a common CRS, and non-sf layers require explicit CRS interpretation. https://ggplot2.tidyverse.org/reference/ggsf.html
- D3 official docs: `geoPath()` supports Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, and GeometryCollection; separate path elements are useful for styling and interaction. https://d3js.org/d3-geo/path
- D3 official docs: `geoPath().centroid()` returns projected planar centroids; `pointRadius()` controls rendered Point/MultiPoint radius and defaults to 4.5. https://d3js.org/d3-geo/path
- D3 official docs: `geoIdentity()` supports `fitExtent()` and `reflectY()`, matching the current gg2d3 sf renderer strategy. https://d3js.org/d3-geo/projection
- D3 official docs: `d3.brush()` selection shapes differ for xy, x, and y brushes; brush state should be read through official APIs rather than internals. https://d3js.org/d3-brush
- Playwright official docs: locators provide auto-waiting/retry behavior, and non-retrying assertions can create flaky tests for asynchronous pages. https://playwright.dev/docs/locators and https://playwright.dev/docs/test-assertions
- htmlwidgets docs: `saveWidget(..., selfcontained = FALSE)` writes external resources beside the HTML instead of embedding them, avoiding the heavier self-contained path. https://rdrr.io/cran/htmlwidgets/man/saveWidget.html
