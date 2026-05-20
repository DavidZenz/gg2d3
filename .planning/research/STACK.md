# Technology Stack

**Project:** gg2d3 v1.9 sf Robustness and Expansion
**Researched:** 2026-05-20
**Research mode:** Stack
**Overall confidence:** HIGH for browser-test stack and sf geometry stack; MEDIUM for exact CI wiring because repository CI files were not part of the requested read set.

## Recommendation

Keep the production rendering stack unchanged: R, ggplot2, htmlwidgets, vendored D3 v7, sf, and geojsonsf are already the right boundaries. For v1.9, add only one new optional testing dependency: `chromote`. Use it from `testthat` to open generated htmlwidget files in headless Chrome and assert DOM-level sf contracts.

Do not add Playwright, Puppeteer, Selenium, webshot2, shinytest2, Leaflet, mapdeck, topojson-client, turf.js, proj4js, or a JS test runner. They solve adjacent problems but add dependency surface that is not needed for DOM smoke tests, sf point/line rendering, or package hardening.

## Recommended Stack Additions

### Browser DOM Smoke Tests

| Technology | Version | DESCRIPTION Placement | Purpose | Why |
|------------|---------|-----------------------|---------|-----|
| `chromote` | `>= 0.5.1` | `Suggests` | Drive headless Chrome from R tests and inspect rendered widget DOM | It is an R implementation of the Chrome DevTools Protocol, supports synchronous browser commands, can navigate to local HTML files, evaluate JavaScript, inspect DOM attributes, and is already the lower-level browser layer used by R tooling such as shinytest2 and webshot2. |
| `testthat` | keep existing `>= 3.0.0`; optional bump to `>= 3.3.0` only if helper code uses newer expectations | already `Suggests` | Test harness for guarded browser smoke tests | Existing package convention uses testthat. Browser tests should remain ordinary testthat files with explicit skip guards. |
| `htmlwidgets::saveWidget()` | existing `htmlwidgets 1.6.4` | already `Imports` | Generate temporary or `test_output/` HTML fixtures for browser tests | Current visual fixture flow already uses `saveWidget(..., selfcontained = FALSE)`. Browser tests can reuse this instead of adding a fixture server. |

**Where it fits:**

- Add a focused helper in tests, not production code, for example `tests/testthat/helper-browser.R`.
- Add a dedicated smoke file such as `tests/testthat/test-sf-browser.R`.
- Generate widgets through existing helpers or small fixtures, save with `htmlwidgets::saveWidget(selfcontained = FALSE)`, then navigate chromote to `file://...`.
- Assert DOM facts, not screenshots:
  - `document.querySelectorAll("path.geom-sf").length`
  - every sf path has a non-empty `d`
  - expected `data-row-id`, `data-cx`, and `data-cy` attributes exist and are finite where required
  - tooltip/hover/click handlers attach to `path.geom-sf`
  - brushing changes opacity or callback payload for centroid-selected sf rows
  - private `_geom` and `_centroid` fields do not appear in public callback payloads

**Guarding policy:**

```r
testthat::skip_on_cran()
testthat::skip_if_not_installed("chromote")
testthat::skip_if_not_installed("sf")
testthat::skip_if_not_installed("geojsonsf")
```

Then skip cleanly if Chrome cannot launch. This is important because chromote's own CRAN guidance says Chrome-dependent tests should not run on CRAN; run them in CI instead, ideally on a scheduled workflow as well as PRs.

**CI policy:**

- Run the chromote smoke tests on GitHub Actions or equivalent CI where Chrome availability is controlled.
- Prefer system Chrome in CI for day-to-day compatibility.
- If CI drift becomes noisy, use chromote's Chrome-for-Testing support outside CRAN, for example `chromote::local_chrome_version("latest-stable")` or the headless-shell binary.
- Keep CRAN checks free of browser launch requirements.

## Existing Stack To Keep

### Core Framework

| Technology | Current Version Evidence | Purpose | Decision |
|------------|--------------------------|---------|----------|
| R package + `testthat` | DESCRIPTION uses testthat edition 3; local testthat is 3.3.2 | Package and test harness | Keep. Add browser smoke tests as opt-in/CI-safe testthat tests. |
| `ggplot2` | local 4.0.3; current code uses `ggplot2::ggplot_build()` and private theme helpers | Source plot build object | Keep. v1.9 hardening should isolate private calls behind wrappers, not replace ggplot2 integration. |
| `htmlwidgets` | local 1.6.4; current widget and fixture pipeline | R-to-browser bridge | Keep. It is the package contract. |
| `jsonlite` | local 2.0.0; current IR serialization path | Serialize non-geometry IR | Keep. Continue not using it for raw `sfc` geometry columns. |
| D3 v7 | vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`; yaml declares D3 version 7 | SVG rendering, geo path generation, interactions | Keep. No extra JS geospatial renderer is needed. |

### Spatial Stack

| Technology | Current Version Evidence | Purpose | Decision |
|------------|--------------------------|---------|----------|
| `sf` | DESCRIPTION `sf (>= 1.0.0)`; local 1.1.1 | Geometry inspection, CRS normalization, bbox, validity/empty checks, test fixtures | Keep in `Suggests`. Do not move to `Imports`; users without maps should not inherit GDAL/GEOS/PROJ installation cost. |
| `geojsonsf` | DESCRIPTION `geojsonsf (>= 2.0.0)`; local 2.0.5 | Serialize accepted `sfc` rows into GeoJSON strings | Keep in `Suggests`. Continue using `geojsonsf::sfc_geojson()` rather than hand-built JSON or WKT. |
| `rnaturalearth` | DESCRIPTION Suggests; local 1.2.0 | Optional world multipolygon fixture | Keep optional and skip guarded. Do not make it part of browser smoke minimums. |

## sf Point And Line Support

No new package is needed for point and line geometry support.

Use the existing `prepare_sf_geometry_ir()` path and widen the accepted geometry families deliberately:

```r
c(
  "POINT", "MULTIPOINT",
  "LINESTRING", "MULTILINESTRING",
  "POLYGON", "MULTIPOLYGON"
)
```

D3's `geoPath()` officially renders GeoJSON `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`, and `MultiPolygon` objects. For points, set `pathGen.pointRadius(...)` before rendering. The lowest-risk v1.9 renderer shape is still one `path.geom-sf` per accepted sf row, even for points and lines, because the existing tooltip, hover, handler, and brush selector stack already targets `path.geom-sf`.

Recommended renderer additions:

- Add `layer.geom_type` or per-row geometry type checks only where styling differs.
- For point-family sf, use `d3.geoPath().pointRadius(radius)` and preserve `path.geom-sf`.
- For line-family sf, use the same `path.geom-sf` path rendering with `fill="none"` by default unless ggplot2 supplies a fill aesthetic.
- Keep `data-cx` and `data-cy` centroid attributes for all sf paths so brush remains centroid-based.
- Add IR diagnostics that report accepted geometry types by family, not only dominant type.

Do not split sf points into `circle.geom-point` or lines into `path.geom-line` in v1.9. That would blur the sf interactivity contract, duplicate projection logic, and create inconsistent brush behavior across sf geometry families.

## Package Hardening Stack

### IR And Private API Hardening

No dependency addition is required.

Use internal helper modules and test fixtures:

| Area | Stack Decision | Rationale |
|------|----------------|-----------|
| `as_d3_ir()` modularization | Extract private helpers inside existing R files or new internal files under `R/`; no new framework | The risk is maintainability, not missing tooling. Smaller helpers make sf expansion and private API fallbacks testable. |
| ggplot2 private APIs | Wrap `ggplot2:::calc_element()` and `ggplot2:::plot_theme()` behind internal `gg2d3_*` helpers with graceful fallbacks | Current code calls private ggplot2 functions multiple times. Centralizing them reduces future breakage from ggplot2 internals. |
| IR schema validation | Extend `validate_ir()`; no JSON Schema dependency | The IR is an R list with package-specific invariants. `validate_ir()` already exists and should learn sf point/line geometry contracts, centroid requirements, and malformed renderer-edge cases. |
| JS renderer contracts | Keep source-contract tests plus new chromote DOM tests | Source tests catch selector regressions cheaply; browser tests catch runtime DOM failures. |

### Renderer Edge-Case Hardening

No new JS dependency is needed.

Prioritize tests and local guards around:

- `geom_sf` empty accepted geometry set: should render zero paths without JS errors.
- malformed GeoJSON string in `layer.geometries`: should skip/null safely without breaking the whole widget.
- mismatched `layer.data` and `layer.geometries`: should fail in `validate_ir()` before browser render.
- non-finite `sf_bbox`: already warns in `validate_ir()`; keep coverage.
- point radius defaults and aesthetics for point-family sf.
- line fill defaults so line-family sf does not accidentally produce filled shapes.
- existing `geom_rect` out-of-bounds behavior and orphaned `GeomPolygon` mapping as package-hardening items, but do not pull them into the sf stack.

## What NOT To Add

| Do Not Add | Why Not | Use Instead |
|------------|---------|-------------|
| Node Playwright or Puppeteer | Requires Node/npm toolchain, browser downloads, and a parallel JS test ecosystem for a package that already tests through R | `chromote` inside `testthat` |
| Selenium / RSelenium | Heavier browser-driver setup than needed for local HTML DOM smoke tests | `chromote` |
| `shinytest2` | Built for Shiny apps; gg2d3 htmlwidgets do not need a Shiny app driver for static widget DOM checks | Direct `chromote` sessions |
| `webshot2` | Screenshot capture is useful for visual regression, but v1.9 asks for DOM-level smoke tests and interactivity assertions | Direct DOM/JS evaluation with `chromote` |
| `vdiffr` | Tests grid/R graphics snapshots, not D3/browser DOM | testthat + chromote |
| Leaflet/mapview/mapdeck | Would turn gg2d3 into a map engine and conflict with the established SVG/htmlwidgets ggplot parity goal | Existing D3 SVG path renderer |
| `proj4js` or browser CRS libraries | CRS normalization is already an R-side contract; JS reprojection is out of scope and would duplicate sf/PROJ behavior poorly | `sf::st_transform()` in R |
| `topojson-client`, `turf.js`, spatial indexing libraries | v1.9 does not require topology simplification, polygon spatial predicates, or large-map performance guarantees | Existing GeoJSON strings and centroid brush |
| JSON Schema validator | Adds another schema language without clear benefit over package-specific R validation | Extend `validate_ir()` |

## Installation Changes

Recommended DESCRIPTION delta for v1.9:

```text
Suggests:
    testthat (>= 3.0.0),
    crosstalk,
    sf (>= 1.0.0),
    geojsonsf (>= 2.0.0),
    rnaturalearth,
    chromote (>= 0.5.1)
```

No production `Imports` additions are recommended.

For contributors running browser smoke tests locally:

```r
install.packages(c("chromote", "sf", "geojsonsf"))
```

Chrome or Chromium must be installed unless the test helper deliberately provisions Chrome-for-Testing outside CRAN.

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Chrome availability makes tests flaky on CRAN or developer machines | High | `skip_on_cran()`, skip when Chrome cannot launch, run browser smoke tests in controlled CI. |
| Browser tests become slow and discourage local test runs | Medium | Keep DOM smoke tests small: one polygon fixture, one point/line fixture, one interactivity fixture. Avoid screenshot diffs. |
| Point-family sf rendered as paths may surprise contributors expecting circles | Medium | Document that all sf geometries render as `path.geom-sf`; set `pointRadius()` and test DOM path count/centroids. |
| Line-family sf accidentally inherits polygon fill behavior | Medium | Renderer should branch defaults by geometry family; tests should assert line paths default to `fill="none"` or equivalent. |
| Mixed geometry layers create ambiguous styling | Medium | Support mixed point/line/polygon rows only if per-row family handling is added; otherwise accept homogeneous families first and document mixed support limits. |
| Private ggplot2 API changes break theme extraction | High | Centralize `ggplot2:::` calls and add fallback tests. Do not expand private API usage during sf work. |
| Optional sf stack increases install friction if moved to `Imports` | High | Keep `sf`, `geojsonsf`, `rnaturalearth`, and `chromote` in `Suggests` with explicit runtime/test skips. |

## Source Notes

| Source | Confidence | Notes |
|--------|------------|-------|
| Local `DESCRIPTION` | HIGH | Current dependency placement: `sf`, `geojsonsf`, and `rnaturalearth` are optional Suggests; testthat edition 3. |
| Local `R/sf_utils.R` | HIGH | Current sf path already normalizes CRS, filters invalid/empty/missing rows, serializes with `geojsonsf::sfc_geojson()`, and returns diagnostics. |
| Local `inst/htmlwidgets/modules/geoms/sf.js` | HIGH | Current renderer already uses `d3.geoIdentity()`, `fitExtent()`, `d3.geoPath()`, `path.geom-sf`, centroid attributes, and row ids. |
| Local `tests/testthat/test-sf-visual.R` | HIGH | Current browser validation is fixture-generation/manual HTML, not automated DOM inspection. |
| chromote docs: https://rstudio.github.io/chromote/ | HIGH | Documents chromote as an R implementation of Chrome DevTools Protocol with synchronous API and browser commands. |
| chromote CRAN-test guidance: https://rstudio.github.io/chromote/articles/example-cran-tests.html | HIGH | Recommends not running chromote tests on CRAN; use `skip_on_cran()` and CI instead. |
| chromote options: https://rstudio.github.io/chromote/reference/chromote-options.html | HIGH | Documents Chrome path/headless/timeout options for controlled test environments. |
| D3 geoPath docs: https://d3js.org/d3-geo/path | HIGH | Documents `geoPath()` rendering of GeoJSON Point, MultiPoint, LineString, MultiLineString, Polygon, and MultiPolygon, including `pointRadius()`. |
| sf validity docs: https://r-spatial.github.io/sf/reference/valid.html | HIGH | Documents `st_is_valid()` behavior used by current filtering. |
| sf geometry query docs: https://r-spatial.github.io/sf/reference/geos_query.html | HIGH | Documents geometry emptiness queries used by current filtering. |
| geojsonsf docs: https://www.rdocumentation.org/packages/geojsonsf/versions/2.0.5/topics/sf_geojson | MEDIUM | Confirms GeoJSON conversion support including point and line examples; package docs are mirrored rather than primary CRAN PDF. |
| testthat skip docs: https://testthat.r-lib.org/reference/skip.html | HIGH | Documents `skip_on_cran()` and `skip_if_not_installed()`. |
| htmlwidgets saveWidget docs: https://www.rdocumentation.org/packages/htmlwidgets/versions/1.6.4/topics/saveWidget | MEDIUM | Confirms `saveWidget()` file/selfcontained/libdir behavior; mirrored docs, but matches installed API and current code. |

