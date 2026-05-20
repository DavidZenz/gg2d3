# Architecture Patterns: v1.9 sf Robustness and Expansion

**Domain:** R/htmlwidgets ggplot2-to-D3 renderer with sf support
**Project:** gg2d3
**Researched:** 2026-05-20
**Overall confidence:** HIGH for current pipeline and component boundaries; MEDIUM for browser runner choice because the repository has fixture generation but no committed browser automation harness yet.

## Recommended Architecture

v1.9 should stay additive around the v1.8 polygon contract. The stable contract is:

```text
R ggplot_build data
  -> prepare_sf_geometry_ir()
  -> layer.data[] + layer.geometries[] + sf_diagnostics
  -> panel sf_bbox metadata
  -> gg2d3.js panel filtering keeps data/geometries paired
  -> modules/geoms/sf.js renders path.geom-sf
  -> events/brush target path.geom-sf and use data-cx/data-cy
```

Do not introduce a separate map subsystem. `geom_sf()` should remain one registered geom in the existing geom registry, drawn inside the same panel, facet, theme, legend, tooltip, hover, handler, and brush infrastructure as other geoms. The expansion point is the sf geometry helper and the sf renderer, not the widget API.

The safest v1.9 architecture has three tracks:

1. **Browser validation hardening first** - add DOM smoke tests for existing polygon behavior before changing geometry support. This creates a regression tripwire for `path.geom-sf`, centroid attributes, row IDs, facet panel filtering, and brush selection.
2. **Non-polygon sf support second** - widen accepted sf families in `prepare_sf_geometry_ir()` and keep all sf marks as `path.geom-sf` rendered by `d3.geoPath()`. Use additional classes such as `geom-sf-point`, `geom-sf-line`, and `geom-sf-polygon`, but do not remove or rename `path.geom-sf`.
3. **Package hardening third** - extract high-risk internals behind narrow helpers after smoke coverage exists. Hardening should reduce `as_d3_ir()` blast radius without changing the emitted IR except where point/line support explicitly requires it.

## Component Boundaries

| Component | Current Responsibility | v1.9 Change | Boundary Rule |
|-----------|------------------------|-------------|---------------|
| `R/as_d3_ir.R` | Builds complete IR from `ggplot_build()`; dispatches `GeomSf`; computes coord/facet/panel metadata | Modify only to call more focused helpers and pass expanded sf support into `prepare_sf_geometry_ir()` | It should orchestrate extraction, not contain geometry-family logic or browser-test concerns |
| `R/sf_utils.R` | Detects sfc column, filters accepted polygon rows, normalizes CRS, serializes GeoJSON, records diagnostics | Extend accepted families to point and line; add family classification and degenerate bbox handling | All CRS, validity, empty/missing filtering, row identity, and diagnostics stay R-side |
| `R/validate_ir.R` | Validates required IR structure and sf data/geometries length | Extend sf validation to accept geometry-family metadata if added; keep existing diagnostics required | It validates shape, not semantic rendering correctness |
| `inst/htmlwidgets/gg2d3.js` | Panel layout, facet filtering, layer dispatch, panel `sf_bbox` handoff | Keep sf data/geometry pair filtering unchanged; pass panel dimensions and `sfBBox` as today | It should not inspect sf geometry types except to preserve parallel arrays |
| `inst/htmlwidgets/modules/geoms/sf.js` | Parses GeoJSON, fits a shared projection, draws `path.geom-sf`, sets centroid and row attributes | Add per-feature family styling and point radius handling; preserve polygon path attributes | It owns browser geometry rendering but not CRS reprojection |
| `inst/htmlwidgets/modules/events.js` | Tooltip, hover, handlers, legend state for interactive marks | Ideally no selector change if all sf families remain `path.geom-sf`; keep datum sanitization | It should see all sf families as the same interactive mark class |
| `inst/htmlwidgets/modules/brush.js` | Pixel brush selection, sf centroid branch for `path.geom-sf` | Preserve centroid selection; add DOM smoke coverage for brush result | It should not do polygon/line intersection in v1.9 |
| Browser smoke harness | Not present; manual HTML fixtures exist in `test-sf-visual.R` | New dev/test-only harness that renders fixture HTML and inspects DOM in a headless browser | It must not become a runtime dependency or alter package output |

## Data Flow Changes

### Existing Polygon Flow To Preserve

```text
sf polygon rows
  -> accepted if POLYGON/MULTIPOLYGON, non-empty, valid, non-missing
  -> normalized to WGS84
  -> serialized as GeoJSON strings
  -> accepted source row ids copied to data$row_id
  -> panel sf_bbox computed from accepted panel geometries
  -> renderer parses geometries and draws one path.geom-sf per accepted row
  -> path has data-row-id, data-cx, data-cy
```

This flow should continue to pass unchanged for polygon-only fixtures.

### v1.9 Expanded Flow

```text
sf POINT/MULTIPOINT/LINESTRING/MULTILINESTRING/POLYGON/MULTIPOLYGON rows
  -> accepted if supported, non-empty, valid, non-missing
  -> normalized to WGS84
  -> classified into point | line | polygon family
  -> serialized as GeoJSON strings
  -> stored in the same layer.geometries[] array
  -> row_id remains source row identity
  -> sf_bbox includes all accepted families in the current panel
  -> renderer draws all accepted families as path.geom-sf with family classes
```

Recommended family classes:

```text
path.geom-sf.geom-sf-polygon
path.geom-sf.geom-sf-line
path.geom-sf.geom-sf-point
```

Keeping `path.geom-sf` for all families avoids changes to tooltip, hover, handler, legend, and brush selectors. Points can be rendered through `d3.geoPath().pointRadius(...)` rather than SVG circles so the existing `path.geom-sf` interactivity contract remains valid. Lines should render as paths with `fill="none"` by default. Polygons should keep `fill-rule="evenodd"` and the existing fill/stroke behavior.

### Degenerate Bounding Boxes

Point-only layers and purely vertical or horizontal line layers can produce zero-width or zero-height bboxes. That is the main new data-flow risk. Handle it before `fitExtent()`:

- Prefer expanding degenerate `sf_bbox` values in `sf_bbox_values()` or a new R helper so panel metadata is already safe.
- Also guard in `bboxToFeatureCollection()` as a browser-side fallback.
- Expansion should be tiny relative to coordinate scale and deterministic, only enough to give `fitExtent()` non-zero width and height.

This preserves polygon bboxes while making point/line-only panels renderable.

## New Components

### Browser Smoke Test Harness

Add a test-only harness rather than embedding browser logic in package runtime. Recommended structure:

```text
tests/testthat/test-browser-smoke-sf.R
tests/testthat/helper-browser-smoke.R
tests/browser/sf-smoke.js              # optional if using Playwright
test_output/browser-smoke/             # generated HTML, ignored or disposable
```

The R test should generate the same kind of HTML files currently produced by `test-sf-visual.R`, then hand the file path to the browser runner. The browser runner should assert DOM facts, not visual screenshots.

Minimum smoke assertions:

| Scenario | DOM Assertions |
|----------|----------------|
| Polygon choropleth | `path.geom-sf` count equals accepted rows; every path has non-empty `d`, `data-row-id`, finite `data-cx`, finite `data-cy` |
| Skipped rows | No path exists for skipped row IDs; rendered row IDs equal `sf_diagnostics$accepted_rows` |
| Facet wrap/grid | Each panel contains only its own sf paths; empty facet panels contain zero sf paths; panel bboxes remain isolated |
| Stacked sf layers | Both layers draw in the same panel using shared projection; path count equals sum of accepted rows |
| Brush | Drag over a centroid and assert selected path opacity differs from non-selected path; callback data excludes `_geom` and `_centroid` |
| Zoom suppression | Widget with `geom_sf()` and `d3_zoom()` does not attach zoom behavior and still attaches brush/tooltip/hover |

Use an environment gate such as `GG2D3_BROWSER_SMOKE=true` and `skip_on_cran()`. Browser smoke tests should be mandatory in local/CI milestone validation, but optional for ordinary CRAN-like package checks.

### sf Geometry Family Classifier

Add a small internal helper in `R/sf_utils.R`:

```text
sf_geometry_family(type)
  POINT, MULTIPOINT -> point
  LINESTRING, MULTILINESTRING -> line
  POLYGON, MULTIPOLYGON -> polygon
  otherwise -> unsupported
```

Use this helper in diagnostics and, if needed, emit row- or layer-level metadata. The renderer can also classify from parsed GeoJSON `geometry.type`, so do not duplicate per-row family fields unless tests or styling require it.

### IR Hardening Helpers

Extract helpers from `as_d3_ir()` only around high-risk seams:

```text
extract_layer_ir()
extract_sf_layer_ir()
extract_theme_ir()
extract_facets_ir()
extract_panels_ir()
extract_guides_ir()
```

Start with `extract_sf_layer_ir()` and `extract_panels_ir()` because v1.9 changes touch those paths. Avoid a broad rewrite of `as_d3_ir()` during the same phase as point/line rendering unless smoke tests already cover the relevant behavior.

## Modified Components

### `R/sf_utils.R`

Recommended changes:

- Change supported types from polygon-only to `POINT`, `MULTIPOINT`, `LINESTRING`, `MULTILINESTRING`, `POLYGON`, `MULTIPOLYGON`.
- Keep empty, invalid, missing, and still-unsupported geometries skipped with diagnostics.
- Keep `row_id` as source row identity, not accepted-row position.
- Add accepted family diagnostics:

```text
sf_diagnostics$accepted_geometry_types
sf_diagnostics$accepted_geometry_families
sf_diagnostics$unsupported_geometry_types
```

- Add degenerate bbox expansion for point/line-only panels.

### `inst/htmlwidgets/modules/geoms/sf.js`

Recommended changes:

- Continue parsing `layer.geometries` into GeoJSON geometries.
- Continue using `d3.geoIdentity().reflectY(true).fitExtent(...)`.
- Keep `path.geom-sf` as the base mark.
- Add type-specific class and styling:

```javascript
function sfFamily(geom) {
  if (!geom || !geom.type) return "unknown";
  if (geom.type === "Point" || geom.type === "MultiPoint") return "point";
  if (geom.type === "LineString" || geom.type === "MultiLineString") return "line";
  if (geom.type === "Polygon" || geom.type === "MultiPolygon") return "polygon";
  return "unknown";
}
```

Default rendering rules:

| Family | Mark | Fill | Stroke | Size |
|--------|------|------|--------|------|
| polygon | `path.geom-sf.geom-sf-polygon` | mapped fill or default | mapped colour/stroke | existing linewidth |
| line | `path.geom-sf.geom-sf-line` | `none` | mapped colour or default | linewidth |
| point | `path.geom-sf.geom-sf-point` | mapped fill/colour | mapped colour/stroke | `size` mapped to point radius |

The renderer should set `data-row-id`, `data-cx`, and `data-cy` for every family. For lines, centroid selection is a deliberate v1.9 tradeoff; full line-intersection brushing should remain out of scope.

### `R/validate_ir.R`

Keep current hard failures:

- `layer.geometries` must be a character vector.
- `length(layer.geometries) == length(layer.data)`.
- `sf_diagnostics` must exist.
- accepted/skipped rows must exist.

Add warnings or failures only for new metadata if it becomes part of the contract. Do not require browser-only metadata in the IR.

### `inst/htmlwidgets/gg2d3.js`

Keep the current sf pair-filtering exactly conceptually:

```javascript
{ data: d, geometry: layer.geometries[i] }
  -> filter by pair.data.PANEL
  -> split back into filtered data[] and geometries[]
```

This is the key protection against skipped rows and faceted geometry mismatches. Do not move facet filtering into `sf.js`; `sf.js` should receive an already-panel-scoped layer.

## Patterns To Follow

### Pattern 1: Compatibility Anchor Classes

**What:** Preserve `path.geom-sf` for every sf-rendered feature and add more specific classes beside it.

**When:** All point, line, and polygon sf rendering.

**Why:** Existing source-contract tests, interactivity selectors, brush logic, tooltip handling, and manual fixtures all rely on `path.geom-sf`. Changing the base mark type would force coordinated changes in `events.js`, `brush.js`, tests, docs, and user callback expectations.

### Pattern 2: R-Side Geometry Truth, JS-Side Drawing

**What:** R decides which geometries are accepted, normalizes CRS, records diagnostics, and computes panel bbox metadata. JavaScript parses and draws the accepted GeoJSON only.

**When:** All sf features.

**Why:** The package already chose R-side WGS84 normalization and explicit unsupported behavior. Keeping that boundary prevents JavaScript from gaining CRS, validity, or diagnostic responsibilities.

### Pattern 3: DOM Smoke Tests Assert Contracts, Not Pixels

**What:** Browser tests should inspect SVG nodes, attributes, event effects, and sanitized callback data.

**When:** v1.9 smoke coverage and future renderer regressions.

**Why:** Pixel-perfect visual testing is brittle and not needed for the immediate risk. The current gap is whether the browser actually materializes expected nodes and interactivity behavior after htmlwidgets rendering.

## Anti-Patterns To Avoid

### Anti-Pattern 1: Separate sf Point/Circle Renderer

**What:** Rendering sf points as `circle.geom-sf` while polygons remain `path.geom-sf`.

**Why Bad:** It forces selector and brush changes across `events.js`, `brush.js`, source-contract tests, browser smoke tests, and docs. It also creates inconsistent callback surfaces.

**Instead:** Use `d3.geoPath().pointRadius(...)` so points remain paths.

### Anti-Pattern 2: Per-Layer Projection Fitting

**What:** Letting each sf layer fit itself to its own bbox.

**Why Bad:** v1.8 explicitly fixed stacked-layer misalignment by computing panel-level `sf_bbox`. Reverting to per-layer fitting breaks overlays.

**Instead:** Continue using `panelData.sf_bbox` as the fit source whenever available.

### Anti-Pattern 3: Browser Tests That Only Check File Existence

**What:** Generating HTML fixtures and asserting the file exists.

**Why Bad:** This already exists and does not catch missing `path.geom-sf`, broken centroid attributes, event attachment regressions, or brushed selection behavior.

**Instead:** Open the generated HTML in a headless browser and query the rendered DOM.

### Anti-Pattern 4: Refactoring `as_d3_ir()` Before Coverage

**What:** Broadly modularizing the monolithic converter before DOM smoke tests and sf expansion tests are in place.

**Why Bad:** `as_d3_ir()` owns scales, themes, facets, guides, coord metadata, and sf metadata. A broad refactor can break unrelated geoms and make sf regressions harder to identify.

**Instead:** Extract only the touched sf/panel helpers during v1.9, then continue hardening in smaller phases.

## Build Order

1. **Browser smoke harness skeleton**
   - Generate one polygon fixture from existing `test-sf-visual.R` patterns.
   - Open it in a headless browser.
   - Assert `path.geom-sf`, `data-row-id`, `data-cx`, and `data-cy`.
   - No renderer behavior changes yet.

2. **Browser smoke coverage for v1.8 contracts**
   - Add skipped-row, stacked-layer, facet-wrap, facet-grid, interactivity, and zoom-suppression smoke cases.
   - This locks polygon behavior before point/line changes.

3. **R-side geometry expansion**
   - Add geometry-family helper.
   - Expand supported sf types.
   - Update diagnostics and IR tests for point, multipoint, line, multiline, and mixed layers.
   - Add degenerate bbox protection.

4. **D3 sf renderer expansion**
   - Add feature-family classification in `sf.js`.
   - Preserve `path.geom-sf`; add family classes.
   - Add point radius and line default styling.
   - Keep polygon fill-rule and fill/stroke behavior unchanged.

5. **Browser smoke coverage for point/line**
   - Assert point and line paths render with `geom-sf-point` / `geom-sf-line`.
   - Assert finite centroid attrs and brush selection by centroid.
   - Assert polygon fixture counts and attributes still pass.

6. **Targeted hardening**
   - Extract `extract_sf_layer_ir()` and panel sf bbox assembly from `as_d3_ir()`.
   - Centralize private ggplot2 theme access behind a helper if touched.
   - Add source-contract tests for helper boundaries.

## Scalability Considerations

| Concern | Small Fixtures | Medium Maps | Large Maps |
|---------|----------------|-------------|------------|
| Browser smoke runtime | Run all smoke cases locally/CI | Keep DOM assertions targeted; avoid screenshots | Gate heavy fixtures behind explicit env var |
| Geometry parsing | Parse per render as today | Consider caching parsed GeoJSON on row object during render | Defer until profiling proves need |
| Brushing | Centroid selection works | Centroid remains predictable and cheap | Avoid polygon/line intersection until a later milestone |
| Facets | Panel bbox isolation required | Empty panels must be allowed | Keep per-panel bbox computation R-side |
| IR size | GeoJSON strings acceptable | Self-contained widgets can grow | Do not add duplicate geometry metadata unless needed |

## Source-Based Findings

| Finding | Confidence | Source |
|---------|------------|--------|
| sf data/geometries are parallel arrays and filtered together by panel | HIGH | `R/as_d3_ir.R`, `inst/htmlwidgets/gg2d3.js`, `tests/testthat/test-sf-renderer.R` |
| polygon renderer currently emits `path.geom-sf` with row and centroid attrs | HIGH | `inst/htmlwidgets/modules/geoms/sf.js`, `tests/testthat/test-sf-interactivity.R` |
| brush uses sf centroid attrs before generic path bbox | HIGH | `inst/htmlwidgets/modules/brush.js` |
| tooltip/hover/custom handlers target `path.geom-sf` and sanitize private fields | HIGH | `inst/htmlwidgets/modules/events.js`, `tests/testthat/test-sf-interactivity.R` |
| manual sf fixture generation exists but DOM smoke automation is absent | HIGH | `tests/testthat/test-sf-visual.R`, repository search |
| point/line support should be added by widening sf helper acceptance and extending `sf.js`, not by adding a new geom | HIGH | Current geom registry and sf helper structure |

## Research Gaps

- Exact browser runner should be decided during implementation. The architecture only requires a headless browser adapter that can open generated htmlwidgets, query SVG DOM, and simulate brush drag. Playwright is ergonomically strong for this; a pure-R runner is acceptable if it satisfies the same adapter contract.
- Point radius mapping needs implementation-level confirmation against existing `size` conventions in `geom-registry` color/size helpers.
- Mixed `GEOMETRY` columns containing geometry collections should remain unsupported unless a phase explicitly decomposes them. Supporting `GEOMETRYCOLLECTION` safely is a separate design problem.
