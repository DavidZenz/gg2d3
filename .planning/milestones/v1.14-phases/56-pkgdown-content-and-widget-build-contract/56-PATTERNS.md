# Phase 56: Pkgdown Content And Widget Build Contract - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 16 new/modified file targets
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/testthat/test-pkgdown-site.R` | test | file-I/O / transform | `tests/testthat/test-renderer-wiring-contracts.R`; `tests/testthat/helper-browser-visual.R` | role-match |
| `vignettes/gg2d3.Rmd` | source docs | transform | `vignettes/gg2d3.Rmd` current sf/article pattern | exact |
| `README.Rmd` | source docs | transform | `README.Rmd` support/validation contract section | exact |
| `vignettes/d3-drawing-diagnostics.md` | source docs | transform / artifact taxonomy | `vignettes/d3-drawing-diagnostics.md` browser visual evidence section | exact |
| `NEWS.md` | source docs | transform | `NEWS.md` development release notes | exact |
| `R/gg2d3.R` | source docs / roxygen | transform | `R/gg2d3.R` roxygen support contract | exact |
| `R/sf_utils.R` | source docs / roxygen | request-response errors / transform | `R/sf_utils.R` dependency and sf diagnostics docs | exact |
| `DESCRIPTION` | config | dependency resolution | `DESCRIPTION` Suggests + testthat config | exact |
| `_pkgdown.yml` | config | site generation | `_pkgdown.yml` reference/site index | exact |
| `.github/workflows/pkgdown.yaml` | CI config | batch / deploy | `.github/workflows/pkgdown.yaml` pkgdown job | exact |
| `README.md` | generated docs | transform | generated from `README.Rmd` | exact |
| `man/gg2d3.Rd` and sf helper `.Rd` files | generated docs | transform | generated from `R/gg2d3.R` and `R/sf_utils.R` | exact |
| `docs/articles/gg2d3.html` | generated pkgdown docs | transform / htmlwidget embedding | current `docs/articles/gg2d3.html` | exact |
| `docs/articles/gg2d3.md` | generated pkgdown docs | transform / text snapshot | current `docs/articles/gg2d3.md` | exact |
| `docs/news/index.html` | generated pkgdown docs | transform | current `docs/news/index.html` | exact |
| `docs/reference/gg2d3.html`, `docs/reference/extract_sf_geometries.html`, `docs/articles/gg2d3_files/**` | generated pkgdown docs/assets | transform / file-I/O | current reference pages and article-local widget dependencies | exact |

## Pattern Assignments

### `tests/testthat/test-pkgdown-site.R` (test, file-I/O / transform)

**Analogs:** `tests/testthat/test-renderer-wiring-contracts.R`, `tests/testthat/helper-browser-visual.R`, `tests/testthat/test-browser-visual-smoke.R`

**File read helper pattern** (`tests/testthat/test-renderer-wiring-contracts.R` lines 1-9):
```r
read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}
```

**Generated-file assertion pattern** (`tests/testthat/test-renderer-wiring-contracts.R` lines 257-293):
```r
test_that("geom contract module paths and htmlwidgets load order are complete", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  yaml <- read_module("inst/htmlwidgets/gg2d3.yaml")
  modules <- contract_modules(contract_js)
  scripts <- yaml_script_entries(yaml)

  for (module in modules) {
    path <- file.path("inst/htmlwidgets/modules", module$module)
    expect_true(
      file.exists(path) || file.exists(file.path("..", "..", path)) ||
        nzchar(system.file(sub("^inst/", "", path), package = "gg2d3")),
      info = paste("Missing contract module:", module$geom, module$module)
    )
    expect_true(
      module$module %in% scripts,
      info = paste("Missing yaml script:", module$geom, module$module)
    )
  }
})
```

**Optional dependency classification pattern** (`tests/testthat/helper-browser-visual.R` lines 166-188):
```r
browser_visual_optional_dependencies <- function(require_sf = FALSE, require_geojsonsf = FALSE) {
  missing <- character()
  if (isTRUE(require_sf) && !requireNamespace("sf", quietly = TRUE)) {
    missing <- c(missing, "sf")
  }
  if (isTRUE(require_geojsonsf) && !requireNamespace("geojsonsf", quietly = TRUE)) {
    missing <- c(missing, "geojsonsf")
  }

  if (length(missing) == 0) {
    return(list(available = TRUE, missing = character(), message = "All optional dependencies are available"))
  }

  list(available = FALSE, missing = missing,
       message = paste("Missing optional dependencies:", paste(missing, collapse = ", ")))
}
```

**Status/error handling pattern** (`tests/testthat/helper-browser-visual.R` lines 474-526):
```r
validate_browser_visual_rows <- function(rows, allow_spatial_skips = TRUE) {
  if (!is.list(rows) || length(rows) == 0) {
    testthat::fail("Browser visual report rows must be a non-empty list.")
  }

  for (idx in seq_along(rows)) {
    row <- rows[[idx]]
    status <- row$status %||% ""
    if (!status %in% c("passed", "failed", "skipped")) {
      testthat::fail(sprintf("Browser visual row %s has invalid status: %s", idx, status))
    }
    if (identical(status, "skipped") && !nzchar(row$skip_reason %||% "")) {
      testthat::fail(sprintf("Browser visual row %s is skipped but has no skip reason.", idx))
    }
  }
}
```

**Apply to Phase 56:** create small helpers such as `read_generated(path)`, `expect_generated_contains(path, markers)`, and `expect_generated_asset(path)`; check `docs/articles/gg2d3.html`, `docs/articles/gg2d3.md`, `docs/reference/*.html`, `docs/news/index.html`, and `docs/articles/gg2d3_files/**`.

### `vignettes/gg2d3.Rmd` (source docs, transform)

**Analog:** existing `vignettes/gg2d3.Rmd`

**Chunk defaults pattern** (lines 10-16):
````markdown
```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
```
````

**Current sf section and silent dependency gate to replace/harden** (lines 202-221):
````markdown
### sf family maps with `geom_sf`

`geom_sf()` supports polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family
(`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`)
geometries.

```{r, eval = requireNamespace("sf", quietly = TRUE) && requireNamespace("geojsonsf", quietly = TRUE)}
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

(ggplot(nc, aes(fill = AREA)) +
  geom_sf(color = "white", linewidth = 0.2) +
  scale_fill_gradient(low = "#eff3ff", high = "#08519c") +
  labs(fill = "Area")) |>
  gg2d3()
```
````

**Support-contract text pattern** (lines 223-240):
```markdown
The `geom_sf()` support contract is intentionally explicit:

- Accepted families are polygon-family (`POLYGON`, `MULTIPOLYGON`),
  point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
  `MULTILINESTRING`), including projected-anchor `geom_sf_text()` and
  `geom_sf_label()` annotations for those families.
- known CRS inputs are normalized to WGS84 in R before serialization.
- Missing CRS emits `geom_sf layer has missing CRS; coordinates will be serialized as-is`.
- Rows that are unsupported, empty, invalid, or missing emit
  `geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries`
```

**Apply to Phase 56:** keep the sf section visible in all environments. Move `requireNamespace()` checks inside an evaluated chunk and emit a stable marker such as `PKGDOWN_SF_OPTIONAL_SKIP: missing sf` when dependencies are unavailable.

### `README.Rmd` (source docs, transform)

**Analog:** existing `README.Rmd`

**Generated-source warning pattern** (lines 1-13):
````markdown
---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  out.width = "100%"
)
```
````

**Support and artifact summary pattern** (lines 48-74):
```markdown
## v1.13 support and validation contract

The v1.13 release track adds regression confidence and bounded geometry polish
without broadening gg2d3 into a full ggplot2 or GIS topology clone.

- Browser visual validation has a dedicated GitHub Actions workflow and a
  CI-equivalent local mode. It writes inspectable `index.html`, `index.json`,
  fixture HTML, screenshot, DOM-summary, and browser-log artifacts under
  `test_output/browser-visual-smoke/` when enabled, while local runs may skip
  cleanly if optional browser tooling is unavailable.

See `vignettes/d3-drawing-diagnostics.md` for validation commands, artifact
paths, CI-mode behavior, architecture boundaries, geometry caveats, and future
work IDs.
```

**sf support pattern** (lines 108-118):
```markdown
gg2d3 also supports `geom_sf()` for polygon-family (`POLYGON`,
`MULTIPOLYGON`), point-family (`POINT`, `MULTIPOINT`), and line-family
(`LINESTRING`, `MULTILINESTRING`) geometries, plus `geom_sf_text()` and
`geom_sf_label()` annotations at projected anchors aligned with those accepted
sf families. Rows that are unsupported, empty, invalid, or missing are skipped
with warnings while accepted rows render; known CRS inputs are normalized in R
before serialization, and missing CRS coordinates are serialized as-is with a
warning.
```

### `vignettes/d3-drawing-diagnostics.md` (source docs, artifact taxonomy)

**Analog:** existing diagnostics document

**Release evidence taxonomy pattern** (lines 17-45):
````markdown
## v1.13 release validation overview

The v1.13 release documentation, validation, and geometry contract is built from
source docs, source tests, generated help, and summarized validation evidence.
The primary release validation commands are:

```bash
Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
Rscript --vanilla -e 'devtools::test()'
R CMD build --no-manual /path/to/gg2d3
R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Release evidence should summarize command outcomes and artifact paths, not
paste browser logs, `00check.log` contents, or raw generated artifacts into
public documentation.
````

**Browser artifact distinction pattern** (lines 91-144):
```markdown
## Browser visual smoke artifacts

Maintainers can generate local browser-rendered visual smoke artifacts with the
opt-in test runner.

Generated files live under `test_output/browser-visual-smoke/`, which is ignored
by git and excluded from package builds. The report files are `index.html` and
`index.json`.

Local skip behavior and CI behavior differ intentionally.
Screenshots are inspection evidence only. Committed baseline image comparisons
and automated image-difference tolerances are deferred until CI artifacts prove
stable across environments.
```

**Apply to Phase 56:** add a pkgdown-specific artifact taxonomy beside browser visual smoke: source docs define intent, generated `docs/` proves local/pkgdown rendering, GitHub Pages/deploy artifacts prove publication, and browser smoke proves representative browser behavior.

### `NEWS.md` (source docs, transform)

**Analog:** existing `NEWS.md`

**Development release-note pattern** (lines 1-8):
```markdown
# gg2d3 (development version)

## v1.13 release notes
* **CI/browser visual smoke validation**: Added a dedicated browser visual smoke workflow with CI-mode behavior, stable DOM/report metadata checks, and downloadable artifact bundles.
* **Release-readiness gate**: Phase 55 evidence records focused renderer/IR/geometry source gates, documentation generation, `devtools::test()`, browser visual smoke behavior, source package build, and `R CMD check --as-cran` command classes.
```

**Apply to Phase 56:** add a concise v1.14/pkgdown bullet under development notes. Keep evidence as command classes and artifact categories, not raw logs.

### `R/gg2d3.R` and `R/sf_utils.R` (roxygen source docs, transform)

**Analogs:** existing roxygen blocks in `R/gg2d3.R` and `R/sf_utils.R`

**Main widget support contract** (`R/gg2d3.R` lines 1-16):
```r
#' Render a ggplot as a D3 widget
#'
#' gg2d3 supports ordinary `geom_polygon()` as grouped closed SVG paths,
#' ordinary `geom_label()` as bounded SVG label groups, `geom_rect()` and
#' `geom_tile()` edge behavior for the shipped Cartesian scale and
#' panel-clipping contract, and `geom_sf()` polygon-family (`POLYGON`,
#' `MULTIPOLYGON`), point-family (`POINT`, `MULTIPOINT`), and line-family
#' (`LINESTRING`, `MULTILINESTRING`) layers. `geom_sf_text()` and
#' `geom_sf_label()` render labels at projected anchors aligned with the
#' existing sf panel projection.
```

**sf helper dependency/error pattern** (`R/sf_utils.R` lines 19-33):
```r
extract_sf_geometries <- function(df) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "The 'sf' package is required for geom_sf support. ",
      "Install with: install.packages('sf')",
      call. = FALSE
    )
  }
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop(
      "The 'geojsonsf' package is required for geom_sf support. ",
      "Install with: install.packages('geojsonsf')",
      call. = FALSE
    )
  }
```

**sf diagnostics pattern** (`R/sf_utils.R` lines 137-151):
```r
if (warn && missing_crs) {
  warning(
    "geom_sf layer has missing CRS; coordinates will be serialized as-is",
    call. = FALSE
  )
}
if (warn && any(skipped)) {
  warning(
    sprintf(
      "geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries",
      sum(skipped)
    ),
    call. = FALSE
  )
}
```

**Apply to Phase 56:** if roxygen support text changes, run `devtools::document()` before pkgdown. Generated `man/*.Rd` and `docs/reference/*.html` are downstream artifacts, not hand edits.

### `DESCRIPTION`, `_pkgdown.yml`, `.github/workflows/pkgdown.yaml` (config, dependency/site build)

**Dependency declaration pattern** (`DESCRIPTION` lines 22-40):
```text
Suggests:
    chromote (>= 0.5.1),
    crosstalk,
    devtools,
    geojsonsf (>= 2.0.0),
    htmltools,
    knitr,
    pkgload,
    rmarkdown,
    rnaturalearth,
    rprojroot,
    scales,
    sf (>= 1.0.0),
    testthat (>= 3.0.0),
    V8
VignetteBuilder: knitr
Config/testthat/edition: 3
```

**Pkgdown site index pattern** (`_pkgdown.yml` lines 1-31):
```yaml
url: https://davidzenz.github.io/gg2d3/

template:
  bootstrap: 5

development:
  mode: release

reference:
- title: Main entry
  contents:
  - gg2d3
- title: Internals
  contents:
  - extract_sf_geometries
  - get_layer_crs
  - normalize_to_wgs84
```

**CI website dependency/build pattern** (`.github/workflows/pkgdown.yaml` lines 31-46):
```yaml
- uses: r-lib/actions/setup-r-dependencies@v2
  with:
    extra-packages: any::pkgdown, local::.
    needs: website

- name: Build site
  run: pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
  shell: Rscript {0}

- name: Deploy to GitHub pages
  if: github.event_name != 'pull_request'
  uses: JamesIves/github-pages-deploy-action@d92aa235d04922e8f08b40ce78cc5442fcfbfa2f
  with:
    clean: false
    branch: gh-pages
    folder: docs
```

**Apply to Phase 56:** inspect before changing. Prefer hardening the existing `Suggests` + `needs: website` route over new install machinery.

### Generated Docs and Assets (`README.md`, `man/*.Rd`, `docs/**`)

**Analogs:** current generated outputs

**Generated article dependency pattern** (`docs/articles/gg2d3.html` line 57):
```html
<script src="gg2d3_files/htmlwidgets-1.6.4/htmlwidgets.js"></script>
<script src="gg2d3_files/d3-7/d3.v7.min.js"></script>
<script src="gg2d3_files/gg2d3-modules-0.0.1/..."></script>
<script src="gg2d3_files/gg2d3-binding-0.0.0.9000/gg2d3.js"></script>
```

**Generated widget scaffold pattern** (`docs/articles/gg2d3.html` lines 85-90):
```html
<div class="gg2d3 html-widget html-fill-item" id="htmlwidget-..." style="width:700px;height:432.632880098888px;"></div>
<div id="htmlwidget-..." style="width:800px;height:500px;" class="gg2d3 html-widget"></div>
```

**Generated markdown stale-site signal** (`docs/articles/gg2d3.md` lines 31-35):
```markdown
## Supported geoms

gg2d3 supports 15 geom types. All aesthetics that ggplot2 maps (color,
fill, size, shape, alpha, linewidth) are carried through to D3.
```

**Generated reference source-link pattern** (`docs/reference/gg2d3.html` lines 35-43):
```html
<h1>Render a ggplot as a D3 widget</h1>
<small class="dont-index">Source:
  <a href="https://github.com/<you>/gg2d3/blob/HEAD/R/gg2d3.R">
    <code>R/gg2d3.R</code>
  </a>
</small>
<div class="d-none name"><code>gg2d3.Rd</code></div>
```

**Generated news stale-site signal** (`docs/news/index.html` lines 41-47):
```html
<h2 class="pkg-version" data-toc-text="development version" id="gg2d3-development-version">gg2d3 (development version)</h2>
<h3 id="gg2d3-development-version-1">gg2d3 0.6.0 (2026-03-31)</h3>
```

**Apply to Phase 56:** do not hand-edit these files. Regenerate with `devtools::build_readme()`, `devtools::document()`, and `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`, then assert markers and dependency directories.

## Shared Patterns

### Source-First Regeneration
**Source:** `README.Rmd` lines 5 and 208; `.github/workflows/pkgdown.yaml` lines 36-38
**Apply to:** all source docs, roxygen, `README.md`, `man/*.Rd`, and `docs/**`
```r
devtools::document()
devtools::build_readme()
pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
```

### Visible Optional Dependency Outcomes
**Source:** `tests/testthat/helper-browser-visual.R` lines 166-188; `vignettes/gg2d3.Rmd` lines 213-221
**Apply to:** `vignettes/gg2d3.Rmd` sf chunk and `tests/testthat/test-pkgdown-site.R`
```r
has_sf <- requireNamespace("sf", quietly = TRUE)
has_geojsonsf <- requireNamespace("geojsonsf", quietly = TRUE)
if (!has_sf || !has_geojsonsf) {
  cat("PKGDOWN_SF_OPTIONAL_SKIP: missing ",
      paste(c(if (!has_sf) "sf", if (!has_geojsonsf) "geojsonsf"), collapse = ", "),
      "\n", sep = "")
} else {
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  (ggplot(nc, aes(fill = AREA)) + geom_sf()) |> gg2d3()
}
```

### Generated Site Evidence Is Not Browser Visual Smoke
**Source:** `vignettes/d3-drawing-diagnostics.md` lines 91-144
**Apply to:** README/diagnostics wording and handoff
```markdown
Generated files live under `test_output/browser-visual-smoke/`, which is ignored
by git and excluded from package builds.
Screenshots are inspection evidence only. Committed baseline image comparisons
and automated image-difference tolerances are deferred.
```
Adapt this pattern for pkgdown: generated `docs/` is committed release surface; GitHub Pages/deploy output proves publication; browser smoke artifacts remain separate inspection evidence.

### Test Failure Messages Carry Artifact Context
**Source:** `tests/testthat/test-renderer-wiring-contracts.R` lines 263-273; `tests/testthat/helper-browser-visual.R` lines 498-526
**Apply to:** `tests/testthat/test-pkgdown-site.R`
```r
expect_true(
  grepl(marker, text, fixed = TRUE),
  info = paste("Missing generated-site marker:", path, marker)
)
```

## No Analog Found

No file lacks a local analog. The only new file, `tests/testthat/test-pkgdown-site.R`, should combine existing file-content contract tests with browser-visual optional-dependency classification patterns.

## Metadata

**Analog search scope:** `tests/testthat/`, `R/`, `vignettes/`, root docs/config, `.github/workflows/`, and current `docs/`
**Files scanned:** 50+ test/source/config/generated files via `rg --files` and targeted reads
**Pattern extraction date:** 2026-05-31
