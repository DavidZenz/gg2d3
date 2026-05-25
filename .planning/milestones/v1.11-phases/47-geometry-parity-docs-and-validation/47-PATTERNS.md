# Phase 47: Geometry Parity Docs And Validation - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 31
**Analogs found:** 30 / 31

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.Rmd` | documentation source | transform | `README.Rmd` current support/geoms section | exact |
| `README.md` | generated documentation | transform | `README.md` generated from README.Rmd | exact |
| `vignettes/gg2d3.Rmd` | documentation source | transform | `vignettes/gg2d3.Rmd` supported geoms and sf contract sections | exact |
| `vignettes/gg2d3-interactivity.Rmd` | documentation source | transform | `vignettes/gg2d3-interactivity.Rmd` interaction caveats | exact |
| `vignettes/d3-drawing-diagnostics.md` | maintainer/user diagnostics doc | batch | existing diagnostics geom/sf/rect sections | exact |
| `R/gg2d3.R` | roxygen source / exported widget API | transform | existing roxygen description in `R/gg2d3.R` | exact |
| `R/d3_tooltip.R` | roxygen source / interactivity helper | transform | existing sf tooltip contract in `R/d3_tooltip.R` | exact |
| `R/d3_brush.R` | roxygen source / interactivity helper | transform | existing sf brush contract in `R/d3_brush.R` | exact |
| `R/d3_handlers.R` | roxygen source / interactivity helper | transform | existing handler contract in `R/d3_handlers.R` | exact |
| `R/d3_hover.R` | roxygen source / interactivity helper | transform | existing hover contract in `R/d3_hover.R` | exact |
| `R/d3_crosstalk.R` | roxygen source / internal utility | transform | existing internal roxygen block in `R/d3_crosstalk.R` | role-match |
| `R/sf_utils.R` | roxygen source / sf utility | transform | existing sf support and diagnostics roxygen in `R/sf_utils.R` | exact |
| `man/gg2d3.Rd` | generated help | transform | `man/gg2d3.Rd` roxygen output from `R/gg2d3.R` | exact |
| `man/d3_tooltip.Rd` | generated help | transform | `man/d3_brush.Rd` generated details pattern | role-match |
| `man/d3_brush.Rd` | generated help | transform | `man/d3_brush.Rd` generated details pattern | exact |
| `man/d3_handlers.Rd` | generated help | transform | `R/d3_handlers.R` plus generated Rd convention | role-match |
| `man/d3_hover.Rd` | generated help | transform | `R/d3_hover.R` plus generated Rd convention | role-match |
| `man/d3_crosstalk.Rd` | generated help | transform | `man/d3_crosstalk_internal.Rd` actual generated file | partial |
| `man/extract_sf_geometries.Rd` | generated help | transform | `man/extract_sf_geometries.Rd` from `R/sf_utils.R` | exact |
| `.planning/phases/47-geometry-parity-docs-and-validation/47-VALIDATION.md` | validation artifact | batch | `47-VALIDATION.md`, `44-VALIDATION.md`, `45-VALIDATION.md`, `46-VALIDATION.md` | exact |
| `tests/testthat/test-polygon-ir.R` | test / evidence reference | batch | existing polygon IR tests | exact |
| `tests/testthat/test-polygon-renderer.R` | test / evidence reference | batch | existing polygon source-contract tests | exact |
| `tests/testthat/test-polygon-interactivity.R` | test / evidence reference | batch | existing polygon interactivity source tests | exact |
| `tests/testthat/test-polygon-browser.R` | test / optional browser evidence | request-response / DOM | existing polygon chromote smoke tests | exact |
| `tests/testthat/test-rect-tile-ir.R` | test / evidence reference | batch | existing rect/tile IR fixture matrix | exact |
| `tests/testthat/test-rect-tile-renderer.R` | test / evidence reference | batch | existing rect/tile source-contract tests | exact |
| `tests/testthat/test-sf-annotations-ir.R` | test / evidence reference | batch | existing sf annotation IR tests | exact |
| `tests/testthat/test-sf-annotations-renderer.R` | test / evidence reference | batch | existing sf annotation renderer source tests | exact |
| `tests/testthat/test-sf-annotations-interactivity.R` | test / evidence reference | batch | existing sf annotation interactivity source tests | exact |
| `tests/testthat/test-sf-annotations-browser.R` | test / optional browser evidence | request-response / DOM | existing sf annotation chromote smoke tests | exact |
| `tests/testthat/helper-browser-polygon.R`, `tests/testthat/helper-browser-sf.R` | test utility / skip helpers | request-response / file-I/O | existing chromote helper skip/artifact pattern | exact |

## Pattern Assignments

### `README.Rmd` and `README.md` (documentation source/generated, transform)

**Analog:** `README.Rmd`

**Source-first README pattern** (lines 1-5, 153-155):
```markdown
---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

*Note:* `README.md` is generated from `README.Rmd`. Use `devtools::build_readme()` to re-render.
```

**Support table and adjacent caveat pattern** (lines 50-72):
```markdown
### Geoms

| Category | Geoms |
|----------|-------|
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text` |
| Area/Ribbon | `geom_area`, `geom_ribbon` |
| Intervals | `geom_segment`, `geom_errorbar`, `geom_linerange`, `geom_pointrange` |
| Annotation | `geom_hline`, `geom_vline`, `geom_abline`, `geom_rug` |
| Statistical | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_smooth` (loess, gam, lm), `geom_dotplot` |

gg2d3 also supports `geom_sf()` for polygon-family (`POLYGON`,
`MULTIPOLYGON`), point-family (`POINT`, `MULTIPOINT`), and line-family
(`LINESTRING`, `MULTILINESTRING`) geometries.
```

**Generated README analog** (README.md lines 1-2, 44-64, 159-160):
```markdown
<!-- README.md is generated from README.Rmd. Please edit that file -->

| Category | Geoms |
|----|----|
| Basic | `geom_point`, `geom_line`, `geom_path`, `geom_bar`, `geom_col`, `geom_rect`, `geom_tile`, `geom_text` |

*Note:* `README.md` is generated from `README.Rmd`. Use
`devtools::build_readme()` to re-render.
```

**Planner instruction:** update `README.Rmd` first. `README.md` should only change through `devtools::build_readme()`. Replace the stale lines 71-72 / generated lines 63-64 with supported ordinary polygon wording plus limitations.

---

### `vignettes/gg2d3.Rmd` (documentation source, transform)

**Analog:** `vignettes/gg2d3.Rmd`

**Supported geoms intro pattern** (lines 42-48):
```markdown
## Supported geoms

gg2d3 supports the core Cartesian geoms below plus polygon-family,
point-family, and line-family `geom_sf()`.
All aesthetics that ggplot2 maps (color, fill, size, shape, alpha, linewidth)
are carried through to D3.
```

**Explicit support contract with limitations pattern** (lines 155-190):
```markdown
### sf family maps with `geom_sf`

`geom_sf()` supports polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family
(`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`)
geometries.

The `geom_sf()` support contract is intentionally explicit:

- Accepted families are polygon-family (`POLYGON`, `MULTIPOLYGON`),
  point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
  `MULTILINESTRING`).
- Optional browser validation is R/testthat/chromote based and may skip cleanly;
  when available, it covers sf family interactivity, stacked overlays, faceted
  and empty panels, and zoom suppression.
- gg2d3 does not provide tile basemaps, slippy map controls, JavaScript-side
  CRS reprojection, true geometry-overlap brushing, or large-map performance
  guarantees.
```

**Stale polygon example to replace** (lines 560-569):
```r
# Unsupported geom: browser-console warning instead of ordinary polygon marks
(ggplot(map_data("state"), aes(long, lat, group = group)) +
  geom_polygon()) |>
  gg2d3()
# ordinary polygon marks are not rendered; the browser console warns that no
# renderer is registered for "polygon".
```

**Planner instruction:** reuse the explicit support-contract bullet style. Change the ordinary polygon example from unsupported-warning wording to a supported grouped-path example with topology/hole-repair caveats nearby.

---

### `vignettes/gg2d3-interactivity.Rmd` (documentation source, transform)

**Analog:** `vignettes/gg2d3-interactivity.Rmd`

**Interaction caveat pattern** (lines 242-262):
```markdown
## Interaction caveats

- **`geom_sf` layers** — tooltip, hover, custom handlers, Shiny-style click
  handlers, and brush callbacks target `.geom-sf` polygon, point, and line
  marks. Public callback payloads are sanitized source-row objects with
  renderer-only fields removed. Brush selection uses rendered representative
  anchors from `data-cx` and `data-cy` rather than true geometry-overlap
  brushing; these representative anchors are stable panel-local hit-test
  points.
```

**Planner instruction:** add ordinary polygon and sf annotation mentions here only where interactivity behavior is relevant. Keep this concise: target classes, sanitized payloads, representative-anchor behavior, optional browser skip semantics.

---

### `vignettes/d3-drawing-diagnostics.md` (diagnostics doc, batch)

**Analog:** `vignettes/d3-drawing-diagnostics.md`

**Coverage and unsupported-geoms pattern** (lines 7-14):
```markdown
## Geom coverage

gg2d3 supports core Cartesian geoms (point, line, path, bar, col, rect, tile,
text, area, ribbon, segment, hline/vline/abline, boxplot, violin, density,
smooth) plus polygon-family, point-family, and line-family `geom_sf`.

Geoms outside this set (for example `geom_contour`) log a warning and do not
render.
```

**Detailed residual-risk pattern** (lines 60-74):
```markdown
## Rect/tile edge cases

Phase 45 closed the deferred `geom_rect` and `geom_tile` out-of-bounds item.
Focused fixtures distinguish scale-limit censoring from `coord_cartesian()` and
SVG clipping: scale limits can produce `NA` bounds before gg2d3 sees the rows,
while coordinate limits preserve finite bounds and rely on the panel clip path.

Transformed scale expansion remains out of scope for this closure and broader public support
contract wording is left to Phase 47.
```

**Stale sf annotation wording to replace** (lines 25-28):
```markdown
Unsupported, empty, invalid, or missing sf geometries are skipped with a
warning while accepted rows remain renderable. `GEOMETRYCOLLECTION`,
`geom_sf_text()`, and `geom_sf_label()` are not supported.
```

**Planner instruction:** diagnostics is the home for detailed caveats: polygon topology/hole repair beyond grouped closed paths, rect/tile transformed-scale expansion, map anti-features, and sf annotation limitations.

---

### Roxygen Sources and Generated Help (roxygen source/generated help, transform)

**Analogs:** `R/gg2d3.R`, `R/d3_brush.R`, `R/sf_utils.R`, generated `man/*.Rd`

**Main exported help pattern** (`R/gg2d3.R` lines 1-10):
```r
#' Render a ggplot as a D3 widget
#'
#' gg2d3 supports `geom_sf()` polygon-family (`POLYGON`, `MULTIPOLYGON`),
#' point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
#' `MULTILINESTRING`) layers. The map anti-features are explicit: no tile
#' basemaps, slippy map controls, JavaScript-side CRS reprojection, true
#' geometry-overlap brushing, or large-map performance guarantees.
#' Optional browser validation for sf behavior is R/testthat/chromote based and
#' may skip cleanly when optional local tooling is unavailable.
```

**Interactivity helper contract pattern** (`R/d3_brush.R` lines 7-11):
```r
#' For `geom_sf()` layers, brushing uses representative-anchor selection from
#' rendered `data-cx` and `data-cy` coordinates on `.geom-sf` polygon-family,
#' point-family, and line-family marks. Brush callbacks receive sanitized
#' source-row payloads; true geometry-overlap brushing is outside the current
#' map anti-features boundary.
```

**Sibling helper wording to keep consistent:**
- `R/d3_tooltip.R` lines 6-8: tooltip attaches to `.geom-sf` marks and uses sanitized source-row payloads.
- `R/d3_handlers.R` lines 3-6: handlers attach to `.geom-sf` marks and pass sanitized payloads to JS/Shiny callbacks.
- `R/d3_hover.R` lines 7-9: hover attaches to `.geom-sf` marks and exposes sanitized payloads.
- `R/d3_crosstalk.R` lines 1-8: internal docs use `@name` and `@keywords internal`, generating `man/d3_crosstalk_internal.Rd`.

**sf utility diagnostics pattern** (`R/sf_utils.R` lines 8-13, 61-70):
```r
#' gg2d3's public `geom_sf()` renderer accepts polygon, point, and line
#' geometry families. Missing CRS emits
#' "geom_sf layer has missing CRS; coordinates will be serialized as-is".
#' Unsupported, empty, invalid, or missing geometries emit
#' "geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries"
#' and are skipped before rendering.
```

**Generated Rd source pointer pattern** (`man/gg2d3.Rd` lines 1-2):
```r
% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gg2d3.R
```

**Generated details pattern** (`man/d3_brush.Rd` lines 43-49):
```r
\details{
For \code{geom_sf()} layers, brushing uses representative-anchor selection from
rendered \code{data-cx} and \code{data-cy} coordinates on \code{.geom-sf} polygon-family,
point-family, and line-family marks. Brush callbacks receive sanitized
source-row payloads; true geometry-overlap brushing is outside the current
map anti-features boundary.
}
```

**Planner instruction:** modify roxygen comments, then regenerate `man/*.Rd` with `devtools::document()`. Do not manually patch generated Rd as the primary source.

---

### `47-VALIDATION.md` / Phase 47 Evidence Artifact (validation artifact, batch)

**Analogs:** existing `47-VALIDATION.md`, prior `44-VALIDATION.md`, `45-VALIDATION.md`, `46-VALIDATION.md`

**Phase validation infrastructure pattern** (`47-VALIDATION.md` lines 16-25):
```markdown
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2, roxygen2 8.0.0, devtools 2.5.2 |
| **Quick run command** | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` |
| **Docs generation command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` |
```

**Per-task verification map pattern** (`47-VALIDATION.md` lines 38-46):
```markdown
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-doc-source | 01 | 1 | DOCVAL-01 | T-47-01 | Public docs do not expose private renderer fields or stale unsupported claims | docs grep | `rtk rg -n 'does not currently have a D3 renderer|no renderer is registered|geom_sf_text\\(\\).*not supported|geom_sf_label\\(\\).*not supported' README.Rmd README.md vignettes R man` | yes | pending |
| 47-02-polygon | 02 | 1 | DOCVAL-01 | T-47-03 | Polygon evidence documents sanitized public payload and supported grouped-path contract | unit/source/browser optional | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` | yes | pending |
```

**Manual interpretation pattern** (`47-VALIDATION.md` lines 58-64):
```markdown
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Generated docs diff inspection | DOCVAL-01 | Generated files may change unrelated formatting; a maintainer should confirm source-first changes produced expected help/README updates | Inspect `git diff -- README.md man/*.Rd` after `devtools::document(); devtools::build_readme()` |
| Optional browser smoke interpretation | DOCVAL-01 | Local machines may lack `sf`, `chromote`, or Chrome; skips need interpretation rather than failing the phase | Record pass/skip outcome for `test-polygon-browser.R` and `test-sf-annotations-browser.R`, including skipped dependency reason |
```

**Prior validation row shape analogs:**
- `44-VALIDATION.md` lines 16-24: test infrastructure table with optional chromote browser smoke.
- `44-VALIDATION.md` lines 37-48: per-task verification rows for polygon IR/source/browser.
- `45-VALIDATION.md` lines 49-53: Wave 0 requirements list for rect/tile IR, renderer, optional browser.
- `46-VALIDATION.md` lines 12-21: sf annotation quick/full/browser commands.

**Planner instruction:** if Phase 47 needs a separate evidence matrix, keep the existing validation-strategy structure and add a compact feature-to-evidence matrix mapping polygon, rect/tile, and sf annotation areas to representative tests, optional browser smoke, skip semantics, and residual risk.

---

### Representative Test Evidence Files (test/evidence references, batch and DOM)

**Polygon IR pattern** (`tests/testthat/test-polygon-ir.R` lines 1-17, 37-58):
```r
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

expect_polygon_ir <- function(plot) {
  ir <- as_d3_ir(plot)
  expect_true(expect_valid_ir(ir))
  layer <- ir$layers[[1]]
  expect_equal(layer$geom, "polygon")
  expect_true(length(layer$data) > 0L)
  layer
}

test_that("POLY-01 recognizes a single non-monotone geom_polygon layer", {
  layer <- expect_polygon_ir(
    ggplot(polygon_data, aes(x, y)) +
      geom_polygon(fill = "#79A7D3", colour = "#1B365D")
  )
})
```

**Polygon source-contract pattern** (`tests/testthat/test-polygon-renderer.R` lines 10-18, 20-31):
```r
test_that("POLY-02 polygon renderer module is bundled and registered", {
  polygon_js <- read_repo_file("inst/htmlwidgets/modules/geoms/polygon.js")
  yaml <- read_repo_file("inst/htmlwidgets/gg2d3.yaml")

  expect_match(yaml, "geoms/polygon\\.js")
  expect_match(polygon_js, "function renderPolygon")
  expect_match(polygon_js, "geomRegistry\\.register\\(['\"]polygon['\"]")
})
```

**Polygon browser smoke pattern** (`tests/testthat/helper-browser-polygon.R` lines 20-49; `test-polygon-browser.R` lines 205-236, 316-351):
```r
skip_browser_polygon_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote polygon smoke tests"
  )
}

test_that("POLY-02 DOM: single and grouped polygon paths render closed clipped marks", {
  skip_browser_polygon_smoke()
  with_chromote_session({
    session$go_to(.browser_polygon_file_url(html_path), delay = 1)
    paths <- .browser_polygon_wait_for_paths(session, fixtures[[name]]$expected)
    .browser_polygon_expect_paths(paths, fixtures[[name]]$expected)
    assert_no_polygon_browser_errors(logs)
  })
})
```

**Rect/tile IR matrix pattern** (`tests/testthat/test-rect-tile-ir.R` lines 26-41, 43-93, 95-148):
```r
classify_rect_ir_case <- function(plot) {
  built <- ggplot2::ggplot_build(plot)$data[[1]]
  ir <- as_d3_ir(plot)
  layer <- ir$layers[[1]]

  expect_equal(layer$geom, "rect")
  expect_equal(length(layer$data), nrow(built))

  list(built = built, ir = ir, layer = layer)
}

rect_tile_cases <- list(
  continuous_scale_limits = ggplot(...) + geom_rect(...) + scale_x_continuous(limits = c(0, 1)),
  coord_cartesian_limits = ggplot(...) + geom_rect(...) + coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)),
  discrete_tile_grid_limits = ggplot(...) + geom_tile(...) + scale_x_discrete(limits = c("a", "b"))
)
```

**Rect/tile source-contract pattern** (`tests/testthat/test-rect-tile-renderer.R` lines 31-38, 130-135):
```r
test_that("RECT-01 rect renderer module registers rect and tile aliases", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")

  expect_match(rect_js, "function renderRect")
  expect_match(rect_js, "geomRegistry\\.register\\(\\['rect', 'tile'\\]")
})

test_that("Phase 45 does not require browser smoke for rect/tile closure", {
  notes <- classification_notes()
  expect_false(grepl("browser-required", notes, fixed = TRUE))
  expect_match(notes, "Browser smoke: not required")
})
```

**sf annotation IR pattern** (`tests/testthat/test-sf-annotations-ir.R` lines 1-4, 40-48, 50-64, 81-118):
```r
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

expect_sf_annotation_layer <- function(layer, geom, annotation_type) {
  expect_equal(layer$geom, geom)
  expect_equal(layer$annotation_type, annotation_type)
  expect_true(length(layer$geometries) > 0)
  expect_equal(length(layer$data), length(layer$geometries))
  expect_false(is.null(layer$sf_diagnostics))
}

test_that("SFANN-01 geom_sf_text creates sf_text IR with labels aesthetics and diagnostics", {
  ir <- as_d3_ir(ggplot2::ggplot(source_sf, ggplot2::aes(label = label)) +
    ggplot2::geom_sf_text(size = 3))
  layer <- expect_sf_annotation_layer(ir$layers[[1]], "sf_text", "text")
  expect_no_warning(validate_ir(ir))
})
```

**sf annotation browser smoke pattern** (`tests/testthat/helper-browser-sf.R` lines 21-47; `test-sf-annotations-browser.R` lines 181-235, 237-289):
```r
skip_browser_sf_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")
}

test_that("SFANN-01 SFANN-02 DOM: sf annotation fixtures render text and label marks", {
  skip_browser_sf_smoke()
  fixtures <- .browser_sfann_fixture_plots()
  with_chromote_session({
    wait_for_sf_marks(session, expected = fixture$expected, timeout = 10)
    marks <- eval_js_value(session, .browser_sfann_marks_script())
    expect_equal(length(marks), fixture$expected)
    assert_no_browser_errors(logs)
  })
})
```

**Planner instruction:** Phase 47 should reference these tests as evidence, not copy them into new tests unless a docs claim lacks coverage. Browser files are optional smoke evidence and must be described with clean skip semantics.

## Shared Patterns

### Source-First Documentation

**Source:** `README.Rmd` lines 5 and 155; `man/gg2d3.Rd` lines 1-2.

**Apply to:** README, roxygen, generated README, generated `man/*.Rd`.

```markdown
<!-- README.md is generated from README.Rmd. Please edit that file -->
```

```r
% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gg2d3.R
```

### Stale Claim Guard

**Source:** `47-VALIDATION.md` lines 42-43.

**Apply to:** `README.Rmd`, `README.md`, `vignettes`, `R`, `man`.

```bash
rtk rg -n 'does not currently have a D3 renderer|no renderer is registered|geom_sf_text\\(\\).*not supported|geom_sf_label\\(\\).*not supported' README.Rmd README.md vignettes R man
```

### Documentation Regeneration

**Source:** `47-VALIDATION.md` line 24.

**Apply to:** generated README and generated help after source docs change.

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

### Optional Browser Skip Semantics

**Source:** `helper-browser-polygon.R` lines 20-49; `helper-browser-sf.R` lines 21-47.

**Apply to:** validation evidence notes for `test-polygon-browser.R` and `test-sf-annotations-browser.R`.

```r
testthat::skip_on_cran()
testthat::skip_if_not_installed("chromote", "0.5.1")
testthat::skip_if_not_installed("sf")
testthat::skip_if_not_installed("geojsonsf")
```

### Evidence Matrix Shape

**Source:** `47-VALIDATION.md` lines 38-46 plus context decisions D-04 through D-06.

**Apply to:** Phase 47 validation evidence artifact.

```markdown
| Geometry area | Source/IR/unit evidence | Optional browser smoke | Skip semantics | Residual risk |
|---------------|-------------------------|------------------------|----------------|---------------|
| Ordinary polygons | `test-polygon-ir.R`; `test-polygon-renderer.R`; `test-polygon-interactivity.R` | `test-polygon-browser.R` | chromote/Chrome optional | topology/hole repair deferred |
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `man/d3_crosstalk.Rd` | generated help | transform | Context names this file, but the repo currently generates `man/d3_crosstalk_internal.Rd` from `R/d3_crosstalk.R` lines 1-8 (`@name d3_crosstalk_internal`). Planner should verify whether the context path is stale or whether roxygen naming must change. |

## Metadata

**Analog search scope:** `README.Rmd`, `README.md`, `vignettes/`, `R/`, `man/`, `tests/testthat/`, `.planning/phases/44-*`, `.planning/phases/45-*`, `.planning/phases/46-*`, `.planning/phases/47-*`

**Files scanned:** 70+

**Pattern extraction date:** 2026-05-25
