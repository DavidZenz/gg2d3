# Phase 48: Browser Visual Smoke Coverage - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 5 source/generated targets, plus 2 config boundaries
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/testthat/helper-browser-visual.R` | utility / test helper | file-I/O + browser request-response | `tests/testthat/helper-browser-sf.R` | exact |
| `tests/testthat/test-browser-visual-smoke.R` | test | browser request-response + file-I/O | `tests/testthat/test-polygon-browser.R` | exact |
| `vignettes/d3-drawing-diagnostics.md` | docs | static documentation | `vignettes/d3-drawing-diagnostics.md` | exact |
| `test_output/browser-visual-smoke/index.html` | generated report artifact | file-I/O | `tests/testthat/visual-zoom-line-check.R` | role-match |
| `test_output/browser-visual-smoke/index.json` | generated report artifact | file-I/O / transform | `tests/testthat/helper-browser-sf.R` | role-match |

Config boundaries examined, no planned edit unless implementation writes outside `test_output/`:

| Existing File | Role | Data Flow | Relevant Lines |
|---------------|------|-----------|----------------|
| `.gitignore` | config | file-I/O hygiene | `test_output/` ignored at line 10 |
| `.Rbuildignore` | config | package-build hygiene | `test_output` excluded at lines 17-19 |

## Pattern Assignments

### `tests/testthat/helper-browser-visual.R` (utility / test helper, file-I/O + browser request-response)

**Primary analog:** `tests/testthat/helper-browser-sf.R`

**Secondary analogs:** `tests/testthat/helper-browser-polygon.R`, `tests/testthat/helper-sf-fixtures.R`

**Loader/source pattern** (`tests/testthat/helper-browser-sf.R` lines 3-15):
```r
# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists(".test_output_dir", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-sf-fixtures.R",
    "helper-sf-fixtures.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}
```

**Root output pattern** (`tests/testthat/helper-sf-fixtures.R` lines 6-14):
```r
.test_output_dir <- function() {
  pkg_root <- tryCatch(
    rprojroot::find_package_root_file(),
    error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
  )
  file.path(pkg_root, "test_output")
}
```

**Skip / browser availability pattern** (`tests/testthat/helper-browser-sf.R` lines 21-47):
```r
skip_browser_sf_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("geojsonsf")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote sf smoke tests"
  )

  launch <- tryCatch(
    {
      session <- chromote::ChromoteSession$new(width = 10, height = 10)
      on.exit(session$close(), add = TRUE)
      TRUE
    },
    error = function(e) e
  )
  testthat::skip_if(
    !isTRUE(launch),
    paste("chromote session launch unavailable:", conditionMessage(launch))
  )

  invisible(TRUE)
}
```

**Non-sf skip variant** (`tests/testthat/helper-browser-polygon.R` lines 20-49): copy this for rows that do not need `sf` / `geojsonsf`.
```r
skip_browser_polygon_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote polygon smoke tests"
  )
  ...
}
```

**Artifact directory and widget save pattern** (`tests/testthat/helper-browser-sf.R` lines 49-64):
```r
browser_sf_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-sf")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

save_browser_sf_widget <- function(widget, filename) {
  outpath <- file.path(browser_sf_artifact_dir(), filename)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(outpath, mustWork = FALSE),
    selfcontained = FALSE
  )
  testthat::expect_true(file.exists(outpath))
  outpath
}
```

Apply as `browser_visual_artifact_dir()` using `file.path(.test_output_dir(), "browser-visual-smoke")`.

**Chromote session and JS evaluation pattern** (`tests/testthat/helper-browser-sf.R` lines 66-83):
```r
with_chromote_session <- function(code, width = 900, height = 700) {
  session <- chromote::ChromoteSession$new(width = width, height = height)
  on.exit(session$close(), add = TRUE)

  eval(
    substitute(code),
    envir = list2env(list(session = session), parent = parent.frame())
  )
}

eval_js_value <- function(session, script) {
  result <- session$Runtime$evaluate(
    script,
    returnByValue = TRUE,
    awaitPromise = TRUE
  )
  result$result$value
}
```

**Console/error collection pattern** (`tests/testthat/helper-browser-sf.R` lines 170-207):
```r
browser_console_collector <- function(session) {
  logs <- new.env(parent = emptyenv())
  logs$entries <- list()

  append_log <- function(entry) {
    logs$entries[[length(logs$entries) + 1L]] <- entry
  }

  session$Runtime$enable()
  session$Runtime$consoleAPICalled(
    callback_ = function(...) {
      event <- .browser_sf_event(...)
      append_log(list(
        source = "Runtime.consoleAPICalled",
        type = event$type %||% "log",
        message = .browser_sf_console_text(event),
        timestamp = event$timestamp %||% NA
      ))
    },
    wait_ = FALSE
  )
  ...
  function() logs$entries
}
```

**Browser error assertion pattern** (`tests/testthat/helper-browser-sf.R` lines 217-235):
```r
assert_no_browser_errors <- function(logs) {
  entries <- .browser_sf_logs(logs)
  if (length(entries) == 0) return(invisible(TRUE))

  is_error <- vapply(entries, function(entry) {
    identical(entry$source, "Runtime.exceptionThrown") ||
      identical(entry$type, "exception") ||
      identical(entry$type, "error") ||
      identical(entry$type, "assert")
  }, logical(1))

  if (any(is_error)) {
    messages <- vapply(entries[is_error], function(entry) {
      paste(entry$source %||% "browser", entry$type %||% "error", entry$message %||% "", sep = ": ")
    }, character(1))
    testthat::fail(paste(c("Browser errors were captured:", messages), collapse = "\n"))
  }

  invisible(TRUE)
}
```

**Failure artifact pattern** (`tests/testthat/helper-browser-sf.R` lines 238-284):
```r
write_browser_failure_artifacts <- function(name, html_path, logs, session = NULL) {
  out_dir <- browser_sf_artifact_dir()
  prefix <- file.path(out_dir, name)
  entries <- .browser_sf_logs(logs)
  ...
  html_copy <- paste0(prefix, ".html")
  if (!identical(normalizePath(html_path, mustWork = FALSE), normalizePath(html_copy, mustWork = FALSE))) {
    file.copy(html_path, html_copy, overwrite = TRUE)
  }

  jsonlite::write_json(
    list(
      html_path = normalizePath(html_path, mustWork = FALSE),
      logs = entries
    ),
    path = paste0(prefix, "-browser-log.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(prefix)
}
```

Extend this pattern for Phase 48 to also write `*.png` screenshots and `*-dom-summary.json` on success and failure where technically feasible.

### `tests/testthat/test-browser-visual-smoke.R` (test, browser request-response + file-I/O)

**Primary analog:** `tests/testthat/test-polygon-browser.R`

**Secondary analogs:** `tests/testthat/test-sf-browser.R`, `tests/testthat/test-sf-annotations-browser.R`, `tests/testthat/test-date-scales.R`

**Helper loading pattern** (`tests/testthat/test-polygon-browser.R` lines 3-17):
```r
# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_polygon_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-polygon.R",
    "helper-browser-polygon.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

library(ggplot2)
```

Use the same candidate-source style for `helper-browser-visual.R`.

**Opt-in gate pattern** (`tests/testthat/test-date-scales.R` lines 265-269):
```r
test_that("visual test: date/time scales render correctly", {
  skip_on_ci()
  skip_if_not(interactive() || identical(Sys.getenv("GG2D3_VISUAL_TESTS"), "true"))
```

For Phase 48, use the researched explicit env var:
```r
testthat::skip_if_not(
  identical(Sys.getenv("GG2D3_BROWSER_VISUAL_SMOKE"), "true"),
  "Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate browser visual smoke artifacts"
)
```

**Fixture matrix pattern** (`tests/testthat/test-polygon-browser.R` lines 208-220):
```r
fixtures <- list(
  single = list(plot = .browser_polygon_single_plot(), expected = 1L),
  grouped = list(plot = .browser_polygon_grouped_plot(), expected = 2L)
)

with_chromote_session({
  logs <- browser_polygon_console_collector(session)

  for (name in names(fixtures)) {
    html_path <- save_browser_polygon_widget(
      gg2d3(fixtures[[name]]$plot),
      paste0("phase44-polygon-", name, ".html")
    )
```

**Browser execution / failure pattern** (`tests/testthat/test-polygon-browser.R` lines 222-233):
```r
tryCatch(
  {
    session$go_to(.browser_polygon_file_url(html_path), delay = 1)
    paths <- .browser_polygon_wait_for_paths(session, fixtures[[name]]$expected)
    .browser_polygon_expect_paths(paths, fixtures[[name]]$expected)
    assert_no_polygon_browser_errors(logs)
  },
  error = function(e) {
    write_browser_polygon_failure_artifacts(paste0("phase44-polygon-", name), html_path, logs)
    stop(e)
  }
)
```

**Static DOM summary scripts for ordinary polygon rows** (`tests/testthat/test-polygon-browser.R` lines 91-118):
```r
.browser_polygon_paths_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('path.geom-polygon')).map(path => ({",
    "d: path.getAttribute('d') || '',",
    "fill: path.getAttribute('fill') || '',",
    "stroke: path.getAttribute('stroke') || '',",
    "opacity: path.getAttribute('opacity') || '',",
    "strokeWidth: path.getAttribute('stroke-width') || '',",
    "strokeDasharray: path.getAttribute('stroke-dasharray') || '',",
    "hasClipAncestor: !!path.closest('g[clip-path]'),",
    "className: path.getAttribute('class') || ''",
    "})))()"
  )
}

.browser_polygon_panel_count_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('.panel'))",
    ".map(panel => panel.querySelectorAll('path.geom-polygon').length))()"
  )
}
```

**Static DOM summary scripts for sf rows** (`tests/testthat/test-sf-browser.R` lines 70-93):
```r
.browser_sf_panel_marks_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll(\".panel\")).map(panel => {",
    "const background = panel.querySelector(\"rect\");",
    "const panelWidth = background ? Number(background.getAttribute(\"width\")) : NaN;",
    "const panelHeight = background ? Number(background.getAttribute(\"height\")) : NaN;",
    "const marks = Array.from(panel.querySelectorAll(\".geom-sf\")).map(mark => ({",
    "tag: mark.tagName.toLowerCase(),",
    "className: mark.getAttribute(\"class\") || \"\",",
    "rowId: mark.getAttribute(\"data-row-id\"),",
    "dataCx: Number(mark.getAttribute(\"data-cx\")),",
    "dataCy: Number(mark.getAttribute(\"data-cy\")),",
    "panelWidth: panelWidth,",
    "panelHeight: panelHeight",
    "}));",
    "return {",
    "count: marks.length,",
    "panelWidth: panelWidth,",
    "panelHeight: panelHeight,",
    "marks: marks",
    "};",
    "}))()"
  )
}
```

**Static DOM summary scripts for sf annotation rows** (`tests/testthat/test-sf-annotations-browser.R` lines 52-64):
```r
.browser_sfann_marks_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('text.geom-sf.geom-sf-text, g.geom-sf.geom-sf-label')).map(mark => ({",
    "tag: mark.tagName.toLowerCase(),",
    "className: mark.getAttribute('class') || '',",
    "rowId: mark.getAttribute('data-row-id'),",
    "dataCx: Number(mark.getAttribute('data-cx')),",
    "dataCy: Number(mark.getAttribute('data-cy')),",
    "labelText: mark.textContent || '',",
    "boxCount: mark.querySelectorAll('rect.geom-sf-label-box').length,",
    "textCount: mark.querySelectorAll('text.geom-sf-label-text').length",
    "})))()"
  )
}
```

**Interactivity-facing fixture pattern** (`tests/testthat/test-polygon-browser.R` lines 319-327):
```r
widget <- gg2d3(.browser_polygon_interactive_plot()) |>
  d3_tooltip() |>
  d3_hover() |>
  d3_brush(on_brush = "window.__gg2d3_polygon_brush = selectedData;") |>
  d3_handlers(
    click = "function(event, d) { window.__gg2d3_polygon_click = d; }",
    mouseover = "function(event, d) { window.__gg2d3_polygon_mouseover = d; }",
    shiny_id = "phase44_polygon"
  )
```

**sf annotation fixture coverage pattern** (`tests/testthat/test-sf-annotations-browser.R` lines 142-179):
```r
list(
  "phase46-sfann-polygon-text.html" = list(
    expected = 1L,
    plot = ggplot2::ggplot(polygon_text, ggplot2::aes(label = label)) +
      ggplot2::geom_sf_text()
  ),
  "phase46-sfann-point-label.html" = list(
    expected = 1L,
    plot = ggplot2::ggplot(point_label, ggplot2::aes(label = label)) +
      ggplot2::geom_sf_label(fill = "white")
  ),
  ...
)
```

**sf fixture set pattern** (`tests/testthat/test-sf-browser.R` lines 283-291):
```r
test_that("BRSF-01 DOM: Phase 35 sf fixtures render live geom-sf paths", {
  skip_browser_sf_smoke()

  fixtures <- .phase35_sf_fixture_set()
  expected_names <- .browser_sf_fixture_names()
  expected_counts <- .browser_sf_expected_counts()

  expect_equal(names(fixtures), expected_names)
  expect_equal(names(expected_counts), expected_names)
```

Do not make this global for the whole visual smoke run. The new matrix should let sf-only rows skip while non-sf rows still produce artifacts when browser dependencies are available.

### `vignettes/d3-drawing-diagnostics.md` (docs, static documentation)

**Analog:** `vignettes/d3-drawing-diagnostics.md`

**Existing maintainer-facing browser validation placement** (lines 49-55):
```markdown
Interactivity targets `.geom-sf` polygon, point, and line marks. Tooltip,
hover, custom handler, and Shiny-style callback payloads are sanitized
source-row objects. Brush selection uses representative-anchor brushing from
rendered `data-cx` and `data-cy` anchors rather than geometric intersection.
Optional browser validation is R/testthat/chromote based and may skip cleanly;
when available, it covers sf family interactivity, stacked overlays, faceted and
empty panels, skipped rows, and zoom suppression.
```

Add the explicit Phase 48 command near this browser-validation paragraph or in a short new maintainer diagnostics section:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

Keep the doc focused on maintainer diagnostics; do not embed local artifact paths beyond `test_output/browser-visual-smoke/`.

### `test_output/browser-visual-smoke/index.html` (generated report artifact, file-I/O)

**Analog:** `tests/testthat/visual-zoom-line-check.R`

**Generated index pattern** (lines 71-86):
```r
index <- paste0(
  "<!doctype html><meta charset='utf-8'>",
  "<title>Zoom-on-path-geom Regression Check</title>",
  "<style>body{font-family:system-ui;max-width:720px;margin:2em auto;padding:0 1em}",
  "li{margin:.5em 0}</style>",
  "<h1>Zoom-on-path-geom Regression Check</h1>",
  "<p>For each plot: scroll-wheel to zoom, drag to pan. All marks ",
  "(line, area, ribbon, points) must transform together with the axes. ",
  "Double-click to reset.</p><ul>",
  paste(vapply(cases, function(c) {
    sprintf("<li><a href='%s'>%s</a></li>", c$file, c$title)
  }, character(1)), collapse = ""),
  "</ul>"
)
writeLines(index, "test_output/test_zoom_line.html")
message("Saved visual check index to: test_output/test_zoom_line.html")
```

For Phase 48, generate `index.html` under `browser_visual_artifact_dir()` and link each row to screenshot, HTML, DOM summary JSON, and browser log JSON. This is generated output, not committed source.

### `test_output/browser-visual-smoke/index.json` (generated report artifact, file-I/O / transform)

**Analog:** `tests/testthat/helper-browser-sf.R`

**JSON artifact pattern** (`tests/testthat/helper-browser-sf.R` lines 273-282):
```r
jsonlite::write_json(
  list(
    html_path = normalizePath(html_path, mustWork = FALSE),
    logs = entries
  ),
  path = paste0(prefix, "-browser-log.json"),
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null"
)
```

Use the same `jsonlite::write_json(..., auto_unbox = TRUE, pretty = TRUE, null = "null")` shape for `index.json` and per-fixture `*-dom-summary.json` / `*-browser-log.json`.

## Shared Patterns

### Optional Browser Skips

**Source:** `tests/testthat/helper-browser-sf.R` lines 21-47 and `tests/testthat/helper-browser-polygon.R` lines 20-49

**Apply to:** `helper-browser-visual.R`, `test-browser-visual-smoke.R`

Use `skip_on_cran()`, `skip_if_not_installed("chromote", "0.5.1")`, `chromote::find_chrome()`, and a real `ChromoteSession$new(width = 10, height = 10)` launch probe. Use `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")` only inside sf-specific rows/helpers, not as a global gate for the full visual smoke matrix.

### Opt-In Visual Smoke Gate

**Source:** `tests/testthat/test-date-scales.R` lines 265-269

**Apply to:** `test-browser-visual-smoke.R`

Default `testthat::test_file("tests/testthat/test-browser-visual-smoke.R")` should skip quickly unless `GG2D3_BROWSER_VISUAL_SMOKE=true` is set. Full browser run command should also set `NOT_CRAN=true`.

### Local Artifact Hygiene

**Source:** `.gitignore` line 10
```gitignore
test_output/
```

**Source:** `.Rbuildignore` lines 17-19
```text
^test_output$
^test_output/
^(.*/)?test_output($|/)
```

**Apply to:** all generated screenshots, HTML, browser logs, DOM summaries, and reports.

No `.gitignore` / `.Rbuildignore` edit is needed if all new outputs stay under `test_output/browser-visual-smoke/`.

### Non-Self-Contained HTML

**Source:** `tests/testthat/helper-browser-sf.R` lines 55-64

**Apply to:** every Phase 48 HTML fixture

Always call `htmlwidgets::saveWidget(..., selfcontained = FALSE)` to avoid adding a Pandoc dependency to visual-smoke runs.

### Static Browser Scripts

**Source:** `tests/testthat/test-polygon-browser.R` lines 91-118, `tests/testthat/test-sf-browser.R` lines 70-93, `tests/testthat/test-sf-annotations-browser.R` lines 52-64

**Apply to:** DOM summary and interaction evidence collection.

Keep DOM scripts static and fixture-controlled. Do not interpolate arbitrary user input into JavaScript strings.

### Failure Evidence

**Source:** `tests/testthat/helper-browser-sf.R` lines 238-284 and `tests/testthat/test-polygon-browser.R` lines 222-233

**Apply to:** visual-smoke runner and every matrix row.

Copy HTML and write browser logs on failure, then extend the pattern to screenshot and DOM summary capture. The `tryCatch(..., error = function(e) { write_artifacts(...); stop(e) })` shape is the existing error handling convention.

## No Direct Analog Found

| Needed Pattern | Role | Data Flow | Reason | Planner Guidance |
|----------------|------|-----------|--------|------------------|
| Screenshot capture | utility | browser request-response + file-I/O | No existing repo code calls `ChromoteSession$screenshot()` | Use the researched chromote API: after `session$go_to(...)` and DOM wait, call `session$screenshot(filename = screenshot_path, selector = "html", delay = 0.5)` or equivalent local chromote method. |
| Per-row skip status report without aborting all rows | test helper | batch + file-I/O | Existing browser tests use testthat skips globally per test | Implement fixture metadata with dependency groups and record skipped rows in `index.json` / `index.html`; use testthat skips only for the top-level opt-in/browser boundary where appropriate. |

## Metadata

**Analog search scope:** `tests/testthat/`, `vignettes/`, `.gitignore`, `.Rbuildignore`

**Files scanned:** browser helpers, browser tests, sf fixture helpers, older visual scripts, diagnostics vignette, ignore/build-ignore config

**Pattern extraction date:** 2026-05-25
