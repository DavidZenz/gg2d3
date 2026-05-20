# Phase 35: geom_sf Docs and Validation Hardening - Research

**Researched:** 2026-05-20 [VERIFIED: system date]  
**Domain:** R package documentation, testthat validation, htmlwidgets manual browser fixtures for `geom_sf` polygon support [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** HIGH [VERIFIED: local code grep, prior phase verification files, official package docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all constraints in this section: `.planning/phases/35-geom-sf-docs-and-validation-hardening/35-CONTEXT.md`. [VERIFIED: 35-CONTEXT.md]

### Locked Decisions

### Public Support Story
- **D-01:** Present `geom_sf` as supported for polygon-family choropleths and polygon overlays, not as general-purpose sf/map support.
- **D-02:** Update the support story in user-facing places: `README.Rmd`, generated `README.md`, the main vignette, diagnostics/limitations docs, and generated help where relevant.
- **D-03:** Keep README coverage concise and confidence-building: one short feature bullet plus one small example or reference to the vignette. Put detailed caveats and validation examples in vignette/diagnostics docs.
- **D-04:** Make `README.md` generated from `README.Rmd`; do not hand-edit the generated file except as an output of `devtools::build_readme()`.

### Truthful Boundaries
- **D-05:** Be explicit and blunt about supported geometry scope: only `POLYGON` and `MULTIPOLYGON` render in v1.8.
- **D-06:** Document unsupported sf rows as warn-and-skip behavior, preserving valid polygon rows where possible.
- **D-07:** Document missing CRS behavior honestly: known CRS inputs are normalized to WGS84 in R; missing CRS emits a warning and serializes coordinates as-is.
- **D-08:** Document `d3_zoom()` suppression for sf widgets as intentional truthful behavior, not a bug.
- **D-09:** Keep explicit anti-features visible: no tile basemaps, no slippy map controls, no JavaScript-side CRS reprojection, no polygon-overlap brushing, no non-polygon sf rendering, and no large-map performance guarantees.
- **D-10:** Replace stale documentation that lists `geom_sf` as unsupported now that polygon-family support exists.

### Validation Fixture Set
- **D-11:** Treat the canonical validation set as: single-panel choropleth, stacked sf overlay, `facet_wrap()` sf map, `facet_grid()` sf map, unsupported/mixed geometry rows, invalid/empty/missing geometry rows, missing CRS warning, tooltip/hover/handler smoke, centroid brush smoke, and zoom suppression.
- **D-12:** Prefer focused automated checks for contracts that can be asserted in R/source tests: warnings, diagnostics fields, row identity, `sf_bbox`, geometry/data alignment, selector inclusion, callback payload sanitization, centroid attributes, and zoom suppression.
- **D-13:** Use browser/manual HTML fixtures for visual confidence in map rendering and composition, written to project-root `test_output/` per existing convention.
- **D-14:** Guard optional spatial fixture tests with `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and additional package skips such as `rnaturalearth` where needed.
- **D-15:** Do not let invalid or skipped sf rows become misleading selectable paths; tests should prove skipped rows do not appear as interactive marks.

### Browser Verification Depth
- **D-16:** Phase 35 should add lightweight browser/manual validation fixtures and structural assertions, not a full pixel visual regression system.
- **D-17:** Accept manual HTML inspection artifacts for rendered visual checks, supported by automated IR/source/HTML-existence assertions.
- **D-18:** If a cheap browser smoke check is available locally, it may verify that generated sf HTML contains non-empty `path.geom-sf` output and expected attributes, but full screenshot diffing is out of scope.
- **D-19:** Keep the validation harness small and maintainable; Phase 35 should harden confidence without introducing heavy new infrastructure.

### Claude's Discretion
- The planner may decide the exact documentation section names and whether to create a dedicated `geom_sf` vignette or add a focused section to an existing vignette, as long as the public support story is discoverable.
- The planner may choose exact fixture names and file organization within existing test conventions.
- The planner may choose exact warning text references in docs, but docs must stay consistent with actual warnings in `R/sf_utils.R` and `R/d3_zoom.R`.

### Deferred Ideas (OUT OF SCOPE)
- Full screenshot/pixel visual regression infrastructure — future testing infrastructure phase if needed.
- Global-comparison projection mode for faceted sf maps — future requirement `SFNEXT-04`.
- Non-polygon sf rendering for points, lines, and geometry collections — future requirements `SFNEXT-01`, `SFNEXT-02`, and `SFNEXT-03`.
- Polygon-overlap brushing — future requirement `SFNEXT-05`.
- Large-map simplification/performance budgets — future requirement `SFNEXT-06`.
- Tile basemaps, slippy map controls, and JavaScript-side CRS reprojection remain out of scope for v1.8.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SFDOC-01 | Package-facing docs describe supported `geom_sf` polygon behavior, unsupported geometry handling, and explicit map anti-features. [VERIFIED: .planning/REQUIREMENTS.md] | Update generated-doc sources first: `README.Rmd`, vignette Rmd/md, roxygen comments in `R/gg2d3.R`, `R/sf_utils.R`, and `R/d3_zoom.R`; regenerate `README.md` and `man/*.Rd`. [VERIFIED: 35-CONTEXT.md, README.Rmd, R/gg2d3.R, R/sf_utils.R, R/d3_zoom.R] |
| SFDOC-02 | Automated and human/browser validation fixtures cover single-panel choropleths, stacked sf overlays, faceted sf maps, unsupported geometry behavior, and interactivity smoke checks. [VERIFIED: .planning/REQUIREMENTS.md] | Extend existing sf test files and `tests/testthat/test-sf-visual.R`; keep optional spatial fixtures behind `skip_if_not_installed()`. [VERIFIED: tests/testthat/test-sf-visual.R, tests/testthat/test-sf-ir.R, tests/testthat/test-sf-interactivity.R, testthat skip docs] |
</phase_requirements>

## Summary

Phase 35 is a hardening phase, not a feature-expansion phase. [VERIFIED: 35-CONTEXT.md] The implementation plan should split into three streams: package-facing documentation, automated contract tests, and lightweight manual/browser HTML fixtures. [VERIFIED: 35-CONTEXT.md, .planning/ROADMAP.md]

The current code already implements the core sf behavior: polygon-family extraction, WGS84 normalization for known CRS, skipped-row diagnostics, `path.geom-sf` rendering, centroid attributes, tooltip/hover/handler targeting, centroid brushing, zoom suppression, stacked shared bbox, and facet-aware per-panel bbox. [VERIFIED: .planning/phases/32-geom-sf-ir-foundation/32-VERIFICATION.md, .planning/phases/33-single-panel-renderer-and-interactivity/33-VERIFICATION.md, .planning/phases/34-stacked-and-faceted-projection-alignment/34-VERIFICATION.md]

**Primary recommendation:** Plan this phase as docs-source edits plus focused validation additions; do not introduce a new browser visual-regression framework or expand `geom_sf` beyond `POLYGON`/`MULTIPOLYGON`. [VERIFIED: 35-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public sf support story | Documentation / R package | Generated docs | README, vignettes, roxygen sources, generated README, and generated Rd files own user-facing documentation. [VERIFIED: README.Rmd, vignettes/gg2d3.Rmd, vignettes/d3-drawing-diagnostics.md, R/gg2d3.R, R/d3_zoom.R] |
| Unsupported geometry diagnostics | R Layer | Tests | `prepare_sf_geometry_ir()` filters unsupported, empty, invalid, and missing geometries before serialization and records diagnostics. [VERIFIED: R/sf_utils.R] |
| Selectable sf path guardrails | R Layer and D3 Layer | Tests | R filtering removes skipped rows from `data`/`geometries`; D3 renders one path per accepted feature with `data-row-id`, `data-cx`, and `data-cy`. [VERIFIED: R/sf_utils.R, inst/htmlwidgets/modules/geoms/sf.js, tests/testthat/test-sf-renderer.R] |
| Manual visual validation | Test fixtures | Browser / HTML output | Existing sf visual tests write htmlwidgets output to project-root `test_output/` and assert files plus IR shape. [VERIFIED: tests/testthat/test-sf-visual.R] |
| Zoom suppression story | R Layer | Documentation | `d3_zoom()` detects sf layers, warns, and returns the widget without adding zoom config. [VERIFIED: R/d3_zoom.R, tests/testthat/test-zoom-brush.R] |

## Project Constraints (from AGENTS.md)

- Shell commands should be prefixed with `rtk`. [VERIFIED: AGENTS.md, /Users/davidzenz/.codex/RTK.md]
- `gg2d3` is an R package that renders ggplot2 graphics through htmlwidgets and D3 SVG. [VERIFIED: AGENTS.md, DESCRIPTION]
- The project pipeline is R layer `R/as_d3_ir.R`, JSON-serializable IR, and D3 layer `inst/htmlwidgets/gg2d3.js`. [VERIFIED: AGENTS.md]
- Generated documentation workflow uses `devtools::document()` for roxygen output and `devtools::build_readme()` for README output. [VERIFIED: AGENTS.md, README.Rmd]
- D3 v7 is vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: AGENTS.md, inst/htmlwidgets/lib/d3/d3.v7.min.js]
- Known docs are stale where `vignettes/d3-drawing-diagnostics.md` still lists `geom_sf` as unsupported. [VERIFIED: vignettes/d3-drawing-diagnostics.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | CRAN 4.0.3, installed 4.0.3 | Source plot object and `geom_sf()` build data. [VERIFIED: CRAN ggplot2, local packageVersion] | Package imports ggplot2 and the entire renderer pipeline starts from ggplot build output. [VERIFIED: DESCRIPTION, R/as_d3_ir.R] |
| htmlwidgets | CRAN 1.6.4, installed 1.6.4 | Widget creation and HTML fixture serialization. [VERIFIED: CRAN htmlwidgets, local packageVersion] | `gg2d3()` uses `htmlwidgets::createWidget()` and fixture tests use `htmlwidgets::saveWidget()`. [VERIFIED: R/gg2d3.R, tests/testthat/test-sf-visual.R] |
| D3.js | Vendored v7 file | SVG rendering, geo paths, and projection fitting. [VERIFIED: inst/htmlwidgets/lib/d3/d3.v7.min.js, inst/htmlwidgets/gg2d3.yaml] | `sf.js` uses D3 geo APIs; official D3 docs define `geoPath()` for SVG path data and `geoIdentity()` with `fitExtent()`/`reflectY()`. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js, CITED: https://d3js.org/d3-geo/path, CITED: https://d3js.org/d3-geo/projection] |
| sf | CRAN 1.1-1, installed 1.1.1; DESCRIPTION requires `sf (>= 1.0.0)` in Suggests | Spatial geometry creation, CRS inspection/transform, bbox, emptiness, and validity checks. [VERIFIED: CRAN sf, local packageVersion, DESCRIPTION] | Current helper code uses `sf::st_geometry_type()`, `sf::st_is_empty()`, `sf::st_is_valid()`, `sf::st_crs()`, `sf::st_transform()`, and `sf::st_bbox()`. [VERIFIED: R/sf_utils.R] |
| geojsonsf | CRAN 2.0.5, installed 2.0.5; DESCRIPTION requires `geojsonsf (>= 2.0.0)` in Suggests | Serialize accepted `sfc` geometries to GeoJSON geometry strings. [VERIFIED: CRAN geojsonsf, local packageVersion, DESCRIPTION] | `prepare_sf_geometry_ir()` serializes with `geojsonsf::sfc_geojson()`, and geojsonsf docs document `sfc_geojson()` for returning geometries. [VERIFIED: R/sf_utils.R, CITED: https://www.rdocumentation.org/packages/geojsonsf/versions/2.0.3] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | CRAN 3.3.2, installed 3.3.2 | Unit/source/fixture assertions. [VERIFIED: CRAN testthat, local packageVersion] | Use for all automated SFDOC-02 checks; `skip_if_not_installed()` is official testthat skip support. [VERIFIED: tests/testthat/*.R, CITED: https://testthat.r-lib.org/reference/skip.html] |
| roxygen2 | CRAN 8.0.0, installed 8.0.0 | Generate `man/*.Rd` from R comments. [VERIFIED: CRAN roxygen2, local packageVersion] | Use through `devtools::document()` after editing roxygen source comments. [VERIFIED: AGENTS.md, CITED: https://roxygen2.r-lib.org/reference/roxygenize.html] |
| devtools | CRAN 2.5.2, installed 2.5.2 | Developer commands for docs, tests, README build. [VERIFIED: CRAN devtools, local packageVersion] | Use `devtools::document()`, `devtools::build_readme()`, and `devtools::test()` per project commands. [VERIFIED: AGENTS.md] |
| rnaturalearth | CRAN 1.2.0, installed 1.2.0 | Optional world multipolygon visual fixture data. [VERIFIED: CRAN rnaturalearth, local packageVersion] | Keep behind `skip_if_not_installed("rnaturalearth")`, as current visual tests already do. [VERIFIED: tests/testthat/test-sf-visual.R] |
| rprojroot | installed 2.1.1 | Resolve project root for `test_output/`. [VERIFIED: local packageVersion] | Existing `test-sf-visual.R` uses `rprojroot::find_package_root_file()`. [VERIFIED: tests/testthat/test-sf-visual.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `test_output/` HTML fixtures | Screenshot/pixel visual regression | Pixel diffing is explicitly out of scope for Phase 35. [VERIFIED: 35-CONTEXT.md] |
| Existing testthat/source-contract tests | Full browser DOM harness | Browser smoke is optional and only cheap structural validation is in scope. [VERIFIED: 35-CONTEXT.md] |
| Existing main vignette plus diagnostics doc | New dedicated `geom_sf` vignette | A dedicated vignette is allowed, but not required; discoverability is the locked requirement. [VERIFIED: 35-CONTEXT.md] |

**Installation:** No dependency installation should be planned by default because the needed spatial/doc/test packages are already available locally and optional spatial deps are already Suggests. [VERIFIED: DESCRIPTION, local packageVersion probe]

```r
# Documentation
devtools::document()
devtools::build_readme()

# Tests
devtools::test()
testthat::test_file("tests/testthat/test-sf-visual.R")
```

**Version verification:** Versions above were verified from CRAN package pages and local `packageVersion()` output on 2026-05-20. [VERIFIED: CRAN package pages, local Rscript packageVersion probe]

## Architecture Patterns

### System Architecture Diagram

```text
User ggplot + geom_sf()
  -> ggplot2 build data
  -> R sf preparation layer
       -> detect sfc geometry column
       -> classify geometry type
       -> skip unsupported/empty/invalid/missing rows
       -> normalize accepted known-CRS geometries to WGS84
       -> serialize accepted geometries with geojsonsf
       -> record accepted/skipped diagnostics and sf_bbox
  -> gg2d3 IR
       -> layer data + parallel geometries
       -> panel sf_bbox metadata
  -> htmlwidgets payload
  -> D3 renderer
       -> panel filters data/geometries together by PANEL
       -> sf renderer fits path projection from panel bbox
       -> path.geom-sf elements expose row and centroid attributes
  -> interactivity modules
       -> tooltip/hover/handler target path.geom-sf
       -> brush selects by centroid
       -> zoom suppressed in R before JS attachment
```

This data flow is the implemented contract through Phase 34. [VERIFIED: R/sf_utils.R, R/as_d3_ir.R, inst/htmlwidgets/gg2d3.js, inst/htmlwidgets/modules/geoms/sf.js, R/d3_zoom.R, prior verification files]

### Recommended Project Structure

```text
R/
  gg2d3.R          # roxygen support story for main entry point [VERIFIED: R/gg2d3.R]
  sf_utils.R       # roxygen and actual sf diagnostics/warnings [VERIFIED: R/sf_utils.R]
  d3_zoom.R        # roxygen and actual sf zoom suppression warning [VERIFIED: R/d3_zoom.R]
vignettes/
  gg2d3.Rmd        # main user-guide sf section [VERIFIED: vignettes/gg2d3.Rmd]
  gg2d3-interactivity.Rmd # optional sf interactivity/zoom caveat [VERIFIED: vignettes/gg2d3-interactivity.Rmd]
  d3-drawing-diagnostics.md # limitations/support boundary doc [VERIFIED: vignettes/d3-drawing-diagnostics.md]
tests/testthat/
  test-sf-ir.R
  test-sf-utils.R
  test-sf-renderer.R
  test-sf-interactivity.R
  test-sf-visual.R
test_output/
  phase35-*.html   # manual browser validation fixtures [VERIFIED: tests/testthat/test-sf-visual.R convention]
```

### Pattern 1: Generated Docs Source First

**What:** Edit `README.Rmd` and roxygen comments; regenerate `README.md` and `man/*.Rd`. [VERIFIED: README.Rmd, R/gg2d3.R, R/d3_zoom.R, R/sf_utils.R, man/*.Rd]  
**When to use:** Any Phase 35 documentation change that affects README or help output. [VERIFIED: 35-CONTEXT.md]  
**Source:** usethis docs say `README.Rmd` users must render regularly to keep `README.md` current, and roxygen2 docs say roxygenize produces Rd files. [CITED: https://usethis.r-lib.org/reference/use_readme_rmd.html, CITED: https://roxygen2.r-lib.org/reference/roxygenize.html]

### Pattern 2: Optional Spatial Dependencies Stay Guarded

**What:** Keep all sf/geojsonsf/rnaturalearth tests guarded with `skip_if_not_installed()`. [VERIFIED: tests/testthat/test-sf-visual.R, tests/testthat/test-sf-ir.R]  
**When to use:** Any test or fixture that needs spatial packages not in Imports. [VERIFIED: DESCRIPTION]  
**Source:** testthat documents `skip_if_not_installed(pkg, minimum_version = NULL)` and says it skips if the package is not installed or cannot be loaded. [CITED: https://testthat.r-lib.org/reference/skip.html]

### Pattern 3: Validate Contracts in R, Not Pixels

**What:** Assert warning text, diagnostics fields, row ids, `sf_bbox`, geometry/data parity, source selectors, centroid attrs, and file existence. [VERIFIED: 35-CONTEXT.md, tests/testthat/test-sf-ir.R, tests/testthat/test-sf-renderer.R, tests/testthat/test-sf-interactivity.R]  
**When to use:** Phase 35 fixture hardening where behavior can be proved without screenshot diffing. [VERIFIED: 35-CONTEXT.md]  
**Example:**

```r
test_that("skipped sf rows do not become selectable paths", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  # Build mixed sf fixture; assert layer$data, layer$geometries,
  # accepted_rows, skipped_rows, and row_id all refer only to accepted polygons.
})
```

The exact fixture should reuse helpers already present in `test-sf-ir.R` and `test-sf-utils.R`. [VERIFIED: tests/testthat/test-sf-ir.R, tests/testthat/test-sf-utils.R]

### Anti-Patterns to Avoid

- **Hand-editing generated README:** `README.md` is generated from `README.Rmd`; edit source and regenerate. [VERIFIED: README.Rmd, 35-CONTEXT.md]
- **Documenting broad map support:** Phase 35 must document polygon-family choropleths/overlays only. [VERIFIED: 35-CONTEXT.md]
- **Adding new sf geometry types:** Non-polygon sf rendering is deferred beyond v1.8. [VERIFIED: .planning/REQUIREMENTS.md, 35-CONTEXT.md]
- **Adding JS reprojection or slippy zoom:** R-side normalization and sf zoom suppression are locked for this milestone. [VERIFIED: 35-CONTEXT.md, R/d3_zoom.R]
- **Relying on screenshot diffs:** Full screenshot/pixel regression is out of scope. [VERIFIED: 35-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CRS transformation | JavaScript-side CRS/projection conversion | `sf::st_transform()` in R for known CRS inputs | Project decision keeps CRS normalization in R; sf docs define `st_transform()` as coordinate transformation to a new CRS. [VERIFIED: 35-CONTEXT.md, R/sf_utils.R, CITED: https://r-spatial.github.io/sf/reference/st_transform.html] |
| GeoJSON serialization | Custom string/JSON geometry serializer | `geojsonsf::sfc_geojson()` | Existing helper uses it and geojsonsf docs show `sfc_geojson()` returning geometries. [VERIFIED: R/sf_utils.R, CITED: https://www.rdocumentation.org/packages/geojsonsf/versions/2.0.3] |
| Invalid geometry repair | Automatic repair or coercion in gg2d3 | Skip invalid rows and document diagnostics | Existing helper skips invalid geometries; sf docs expose `st_make_valid()`, but Phase 35 is documentation/validation hardening, not automatic geometry repair. [VERIFIED: R/sf_utils.R, 35-CONTEXT.md, CITED: https://r-spatial.github.io/sf/reference/valid.html] |
| Visual regression | Custom screenshot diff system | HTML fixtures plus structural test assertions | Full pixel regression is deferred. [VERIFIED: 35-CONTEXT.md] |
| Browser map engine behavior | Tile basemaps, slippy controls, JS reprojection | D3 SVG `path.geom-sf` with `geoIdentity().reflectY(true).fitExtent()` | D3 docs support `geoPath()` SVG path generation and `geoIdentity()` planar transform fitting; map-engine features are out of scope. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js, 35-CONTEXT.md, CITED: https://d3js.org/d3-geo/path, CITED: https://d3js.org/d3-geo/projection] |

**Key insight:** Phase 35 should lock down the truthful contract around implemented behavior rather than solve spatial rendering problems that were intentionally deferred. [VERIFIED: 35-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Updating Generated Files Without Sources
**What goes wrong:** `README.md` or `man/*.Rd` can drift from source docs. [VERIFIED: README.Rmd, man/*.Rd headers]  
**Why it happens:** `README.md` and Rd files are generated outputs. [VERIFIED: README.Rmd, man/*.Rd headers, CITED: https://usethis.r-lib.org/reference/use_readme_rmd.html, CITED: https://roxygen2.r-lib.org/reference/roxygenize.html]  
**How to avoid:** Edit `README.Rmd` and roxygen comments first, then run `devtools::build_readme()` and `devtools::document()`. [VERIFIED: AGENTS.md]  
**Warning signs:** Generated file headers still point to stale source language or `README.Rmd` is newer than `README.md`. [VERIFIED: README.Rmd]

### Pitfall 2: Docs Overpromise GIS Support
**What goes wrong:** Users infer tile maps, slippy controls, browser reprojection, non-polygon rendering, or large-map guarantees. [VERIFIED: 35-CONTEXT.md]  
**Why it happens:** `geom_sf` in ggplot2 is broad, but gg2d3 v1.8 support is only polygon-family rendering. [VERIFIED: 35-CONTEXT.md, .planning/REQUIREMENTS.md]  
**How to avoid:** Put "polygon-family choropleths and overlays" near the first mention and list anti-features in detailed docs. [VERIFIED: 35-CONTEXT.md]  
**Warning signs:** Docs say simply "`geom_sf` supported" without `POLYGON`/`MULTIPOLYGON` qualification. [VERIFIED: 35-CONTEXT.md]

### Pitfall 3: Skipped Rows Still Interactive
**What goes wrong:** Unsupported, empty, invalid, or missing geometry rows could appear in tooltip/brush/handler payloads even though no valid path should exist. [VERIFIED: 35-CONTEXT.md]  
**Why it happens:** sf layers maintain parallel `data` and `geometries` arrays, so filtering must stay aligned. [VERIFIED: R/sf_utils.R, inst/htmlwidgets/gg2d3.js]  
**How to avoid:** Add tests that accepted `row_id` values, `accepted_rows`, `skipped_rows`, and path selector expectations all refer only to accepted polygon rows. [VERIFIED: tests/testthat/test-sf-ir.R, tests/testthat/test-sf-renderer.R]  
**Warning signs:** `length(layer$data) != length(layer$geometries)` or skipped row ids appear in `layer$data`. [VERIFIED: tests/testthat/test-sf-ir.R, R/validate_ir.R]

### Pitfall 4: Missing CRS Language Implies Reprojection
**What goes wrong:** Docs imply missing-CRS data is transformed to WGS84. [VERIFIED: 35-CONTEXT.md]  
**Why it happens:** Known CRS inputs are normalized, but missing CRS emits a warning and serializes coordinates as-is. [VERIFIED: R/sf_utils.R]  
**How to avoid:** Quote or closely paraphrase the actual warning from `prepare_sf_geometry_ir()`: `geom_sf layer has missing CRS; coordinates will be serialized as-is`. [VERIFIED: R/sf_utils.R]  
**Warning signs:** Docs describe missing CRS as "normalized" or "reprojected". [VERIFIED: R/sf_utils.R]

## Code Examples

### Manual HTML Fixture Pattern

```r
test_that("phase35 sf choropleth fixture is generated", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")

  out_dir <- .test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) + ggplot2::geom_sf()
  w <- gg2d3(p)

  outpath <- file.path(out_dir, "phase35-sf-choropleth.html")
  htmlwidgets::saveWidget(w, file = normalizePath(outpath, mustWork = FALSE), selfcontained = TRUE)
  expect_true(file.exists(outpath))
})
```

This follows the existing `test-sf-visual.R` pattern and htmlwidgets `saveWidget()` saves a widget to an HTML file. [VERIFIED: tests/testthat/test-sf-visual.R, CITED: https://rdrr.io/cran/htmlwidgets/man/saveWidget.html]

### Unsupported Geometry Guard Pattern

```r
expect_warning(
  ir <- as_d3_ir(ggplot2::ggplot(mixed) + ggplot2::geom_sf()),
  regexp = "skipped 1"
)

layer <- ir$layers[[1]]
row_ids <- vapply(layer$data, function(row) row$row_id, numeric(1))

expect_equal(row_ids, c(1, 3))
expect_equal(layer$sf_diagnostics$accepted_rows, c(1L, 3L))
expect_equal(layer$sf_diagnostics$skipped_rows, 2L)
expect_equal(length(layer$data), length(layer$geometries))
```

This is already present in `test-sf-ir.R`; Phase 35 should extend the same pattern to prove skipped rows cannot become selectable paths. [VERIFIED: tests/testthat/test-sf-ir.R, 35-CONTEXT.md]

### Zoom Suppression Pattern

```r
expect_warning(
  w_zoom <- gg2d3(p) |> d3_zoom(),
  "geom_sf.*zoom|zoom.*geom_sf"
)
expect_null(w_zoom$x$interactivity$zoom)
```

This matches the existing `d3_zoom()` sf suppression contract. [VERIFIED: R/d3_zoom.R, tests/testthat/test-zoom-brush.R]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `vignettes/d3-drawing-diagnostics.md` says `geom_sf` is unsupported | Document `geom_sf` polygon-family support plus explicit anti-features | Phase 35 target after Phases 32-34 shipped sf behavior [VERIFIED: vignettes/d3-drawing-diagnostics.md, prior verification files] | Planning must include stale-doc replacement. [VERIFIED: 35-CONTEXT.md] |
| v1.7 research/prototype only | v1.8 Phases 32-34 implemented IR, renderer, interactivity, stacked, and faceted projection contracts | Completed 2026-05-20 [VERIFIED: prior verification files] | Phase 35 validates and documents implemented behavior, not prototypes. [VERIFIED: .planning/PROJECT.md] |
| Single-panel visual fixture only | Canonical validation set includes single, stacked, facet_wrap, facet_grid, unsupported/mixed, invalid/empty/missing, interactivity, centroid brush, and zoom suppression | Locked in Phase 35 context [VERIFIED: 35-CONTEXT.md] | Planner should split fixtures/tests by behavior area. [VERIFIED: 35-CONTEXT.md] |

**Deprecated/outdated:**
- `geom_sf` listed as unsupported in diagnostics doc. [VERIFIED: vignettes/d3-drawing-diagnostics.md]
- Vignette and README counts that say "15 geom types" are stale relative to README's table listing more current geoms and Phase 35 sf support. [VERIFIED: README.Rmd, vignettes/gg2d3.Rmd, 35-CONTEXT.md]

## Assumptions Log

All claims in this research were verified or cited; no user confirmation is needed before planning. [VERIFIED: source audit and official docs lookup]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

## Open Questions

1. **Dedicated `geom_sf` vignette or existing main vignette section?** [VERIFIED: 35-CONTEXT.md]
   - What we know: Either option is allowed if the support story is discoverable. [VERIFIED: 35-CONTEXT.md]
   - What's unclear: The preferred documentation IA is not locked. [VERIFIED: 35-CONTEXT.md]
   - Recommendation: Use the existing main vignette unless the section grows beyond a concise usage/contract block; this minimizes new vignette maintenance. [VERIFIED: vignettes/gg2d3.Rmd, 35-CONTEXT.md]

2. **Cheap browser smoke check availability?** [VERIFIED: 35-CONTEXT.md]
   - What we know: Manual HTML fixtures plus structural assertions are acceptable. [VERIFIED: 35-CONTEXT.md]
   - What's unclear: No local browser DOM harness is established in the current test suite. [VERIFIED: tests/testthat directory scan]
   - Recommendation: Plan structural HTML/file existence checks as required; make browser DOM inspection optional if a cheap local harness is already available during execution. [VERIFIED: 35-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | All package docs/tests | yes | 4.6.0 | none needed [VERIFIED: local Rscript probe] |
| ggplot2 | Plot build and fixtures | yes | 4.0.3 | none needed [VERIFIED: local Rscript probe] |
| htmlwidgets | Fixture HTML saving | yes | 1.6.4 | none needed [VERIFIED: local Rscript probe] |
| testthat | Validation tests | yes | 3.3.2 | none needed [VERIFIED: local Rscript probe] |
| sf | Spatial fixtures and IR tests | yes | 1.1.1 | skip guarded tests when absent [VERIFIED: local Rscript probe, tests/testthat/test-sf-visual.R] |
| geojsonsf | GeoJSON serialization tests | yes | 2.0.5 | skip guarded tests when absent [VERIFIED: local Rscript probe, tests/testthat/test-sf-visual.R] |
| rnaturalearth | Optional world multipolygon fixture | yes | 1.2.0 | skip world fixture when absent [VERIFIED: local Rscript probe, tests/testthat/test-sf-visual.R] |
| roxygen2 | Rd regeneration | yes | 8.0.0 | none needed [VERIFIED: local Rscript probe] |
| devtools | `document()`, `build_readme()`, `test()` | yes | 2.5.2 | call roxygen2/testthat directly if needed [VERIFIED: local Rscript probe, AGENTS.md] |
| rmarkdown | README/vignette rendering | yes | 2.31 | none needed [VERIFIED: local Rscript probe] |
| knitr | Rmd rendering | yes | 1.51 | none needed [VERIFIED: local Rscript probe] |

**Missing dependencies with no fallback:** None found. [VERIFIED: local Rscript probe]  
**Missing dependencies with fallback:** None found; optional spatial dependencies are present locally but should remain guarded for other environments. [VERIFIED: local Rscript probe, DESCRIPTION, tests/testthat/test-sf-visual.R]

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json`, so validation architecture should be included. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 [VERIFIED: CRAN testthat, local packageVersion] |
| Config file | `DESCRIPTION` with `Config/testthat/edition: 3` [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R", reporter = "summary")'` [VERIFIED: command run passed 2026-05-20] |
| Full sf suite command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-visual.R"); testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` [VERIFIED: existing prior phase verification commands and current files] |
| Docs generation command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` [VERIFIED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SFDOC-01 | README, vignette, diagnostics, and help output describe polygon support, skipped rows, CRS behavior, zoom suppression, and anti-features. [VERIFIED: .planning/REQUIREMENTS.md, 35-CONTEXT.md] | docs/source assertion plus generated-doc diff review | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` | partial; docs exist but are stale for sf [VERIFIED: README.Rmd, vignettes/d3-drawing-diagnostics.md, man/*.Rd] |
| SFDOC-02 | Single-panel choropleth fixture exists and asserts sf IR structure. [VERIFIED: .planning/REQUIREMENTS.md, tests/testthat/test-sf-visual.R] | fixture/unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-visual.R", reporter = "summary")'` | yes, needs expansion [VERIFIED: tests/testthat/test-sf-visual.R] |
| SFDOC-02 | Stacked sf overlay fixture and structural assertions prove shared projection/bbox. [VERIFIED: 35-CONTEXT.md] | fixture/unit | same `test-sf-visual.R` command plus `test-sf-ir.R` | partial; IR test exists, visual fixture missing [VERIFIED: tests/testthat/test-sf-ir.R, tests/testthat/test-sf-visual.R] |
| SFDOC-02 | `facet_wrap()` and `facet_grid()` fixtures plus per-panel bbox checks. [VERIFIED: 35-CONTEXT.md] | fixture/unit | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-facets.R"); testthat::test_file("tests/testthat/test-facet-grid.R")'` | partial; IR tests exist, visual fixtures missing [VERIFIED: tests/testthat/test-facets.R, tests/testthat/test-facet-grid.R] |
| SFDOC-02 | Unsupported/empty/invalid/missing geometry rows warn/skip and cannot become selectable paths. [VERIFIED: 35-CONTEXT.md] | unit/source-contract | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-utils.R"); testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R")'` | partial; diagnostics tests exist, selectable-path guard needs hardening [VERIFIED: tests/testthat/test-sf-utils.R, tests/testthat/test-sf-ir.R, tests/testthat/test-sf-renderer.R] |
| SFDOC-02 | Tooltip/hover/handler, centroid brush, and zoom suppression smoke checks. [VERIFIED: 35-CONTEXT.md] | unit/source-contract | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'` | yes, may need fixture linkage [VERIFIED: tests/testthat/test-sf-interactivity.R, tests/testthat/test-zoom-brush.R] |

### Sampling Rate

- **Per task commit:** Run the narrow file touched by the task, such as `test-sf-ir.R`, `test-sf-visual.R`, or documentation generation. [VERIFIED: existing phase verification pattern]
- **Per wave merge:** Run the full sf suite command listed above. [VERIFIED: prior phase verification files]
- **Phase gate:** Run docs generation plus full sf suite before `/gsd-verify-work`; run full `devtools::test()` only if time allows because prior Phase 32 notes mention unrelated full-suite failures. [VERIFIED: 32-VERIFICATION.md]

### Wave 0 Gaps

- [ ] `tests/testthat/test-sf-visual.R` — add Phase 35 fixtures for stacked overlay, facet wrap, facet grid, unsupported/mixed rows, invalid/empty/missing rows, tooltip/hover/handler, centroid brush, and zoom suppression. [VERIFIED: 35-CONTEXT.md, tests/testthat/test-sf-visual.R]
- [ ] `tests/testthat/test-sf-renderer.R` or `test-sf-interactivity.R` — add source/IR assertion proving skipped rows cannot appear as selectable `path.geom-sf` rows. [VERIFIED: 35-CONTEXT.md, tests/testthat/test-sf-renderer.R]
- [ ] Docs-source checks are not currently represented as tests; planner should decide whether to add simple `expect_match(readLines(...))` assertions or rely on review plus generated outputs. [VERIFIED: tests directory scan]

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so security review is included. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication surface is introduced by docs/tests. [VERIFIED: phase scope in 35-CONTEXT.md] |
| V3 Session Management | no | No session behavior is introduced by docs/tests. [VERIFIED: phase scope in 35-CONTEXT.md] |
| V4 Access Control | no | No authorization boundary is introduced by docs/tests. [VERIFIED: phase scope in 35-CONTEXT.md] |
| V5 Input Validation | yes | Existing sf filtering validates geometry type, empty geometry, missing geometry, and validity before rendering. [VERIFIED: R/sf_utils.R] |
| V6 Cryptography | no | No cryptographic behavior is introduced by docs/tests. [VERIFIED: phase scope in 35-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading interactive payload for skipped geometry | Tampering / information integrity | Keep skipped rows out of `data`/`geometries`; sanitize underscore-prefixed renderer fields before callbacks. [VERIFIED: R/sf_utils.R, inst/htmlwidgets/modules/events.js, inst/htmlwidgets/modules/tooltip.js, inst/htmlwidgets/modules/brush.js] |
| User-supplied JavaScript handler docs imply private fields are stable API | Information disclosure / integrity | Document public row data only; private `_geom` and `_centroid` are sanitized. [VERIFIED: tests/testthat/test-sf-interactivity.R] |
| Invalid geometry passed to renderer | Denial of service / robustness | Skip invalid geometries in R using `sf::st_is_valid()` before GeoJSON serialization. [VERIFIED: R/sf_utils.R, CITED: https://r-spatial.github.io/sf/reference/valid.html] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/35-geom-sf-docs-and-validation-hardening/35-CONTEXT.md` — locked decisions, canonical fixture set, out-of-scope boundaries. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` — SFDOC-01 and SFDOC-02 definitions. [VERIFIED: local file]
- `.planning/ROADMAP.md` — Phase 35 goal, success criteria, likely files. [VERIFIED: local file]
- `.planning/PROJECT.md` — current v1.8 state and decisions. [VERIFIED: local file]
- `AGENTS.md` and `/Users/davidzenz/.codex/RTK.md` — project commands and `rtk` shell convention. [VERIFIED: local files]
- `R/sf_utils.R`, `R/d3_zoom.R`, `R/gg2d3.R`, `R/as_d3_ir.R`, `R/validate_ir.R` — implemented R contracts. [VERIFIED: local files]
- `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/geoms/sf.js`, `events.js`, `tooltip.js`, `brush.js` — implemented D3/interactivity contracts. [VERIFIED: local files]
- `tests/testthat/test-sf-*.R`, `test-facets.R`, `test-facet-grid.R`, `test-zoom-brush.R` — existing test and fixture conventions. [VERIFIED: local files]
- Official CRAN package pages for ggplot2, htmlwidgets, sf, geojsonsf, testthat, roxygen2, devtools, rnaturalearth — current CRAN versions and publication dates. [CITED: https://cran.r-project.org/package=ggplot2, CITED: https://cran.r-project.org/package=htmlwidgets, CITED: https://cran.r-project.org/package=sf, CITED: https://cran.r-project.org/package=geojsonsf, CITED: https://cran.r-project.org/package=testthat, CITED: https://cran.r-project.org/package=roxygen2, CITED: https://cran.r-project.org/package=devtools, CITED: https://cran.r-project.org/package=rnaturalearth]

### Secondary (MEDIUM confidence)

- testthat skip documentation — skip guard behavior. [CITED: https://testthat.r-lib.org/reference/skip.html]
- roxygen2 roxygenize documentation — Rd generation behavior. [CITED: https://roxygen2.r-lib.org/reference/roxygenize.html]
- usethis README.Rmd documentation — README render workflow. [CITED: https://usethis.r-lib.org/reference/use_readme_rmd.html]
- htmlwidgets saveWidget documentation — HTML widget fixture serialization. [CITED: https://rdrr.io/cran/htmlwidgets/man/saveWidget.html]
- sf st_transform, st_is_valid, and sf3 docs — CRS and validity API behavior. [CITED: https://r-spatial.github.io/sf/reference/st_transform.html, CITED: https://r-spatial.github.io/sf/reference/valid.html, CITED: https://r-spatial.github.io/sf/articles/sf3.html]
- D3 geoPath and geoIdentity docs — SVG path and planar transform fit behavior. [CITED: https://d3js.org/d3-geo/path, CITED: https://d3js.org/d3-geo/projection]

### Tertiary (LOW confidence)

- None. [VERIFIED: source hierarchy review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — CRAN versions and local installed versions were verified. [VERIFIED: CRAN package pages, local Rscript probe]
- Architecture: HIGH — implementation and prior verification files agree on the sf pipeline. [VERIFIED: local source files, prior verification files]
- Pitfalls: HIGH — pitfalls map directly to stale docs, locked decisions, or implemented warning/filtering behavior. [VERIFIED: vignettes/d3-drawing-diagnostics.md, 35-CONTEXT.md, R/sf_utils.R, R/d3_zoom.R]
- Validation architecture: HIGH — existing tests and prior phase verification provide direct command patterns; Wave 0 gaps are explicit. [VERIFIED: tests/testthat, prior verification files]

**Research date:** 2026-05-20 [VERIFIED: system date]  
**Valid until:** 2026-06-19 for local phase planning; re-check CRAN versions if planning is delayed. [VERIFIED: research date and package-release volatility]
