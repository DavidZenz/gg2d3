# Browser smoke tests for live geom_sf DOM rendering.

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_sf_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-sf.R",
    "helper-browser-sf.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

.browser_sf_fixture_names <- function() {
  c(
    "phase35-sf-choropleth.html",
    "phase35-sf-stacked-overlay.html",
    "phase35-sf-facet-wrap.html",
    "phase35-sf-facet-grid.html",
    "phase35-sf-skipped-rows.html",
    "phase35-sf-interactivity-smoke.html"
  )
}

.browser_sf_expected_counts <- function() {
  c(
    "phase35-sf-choropleth.html" = 100L,
    "phase35-sf-stacked-overlay.html" = 4L,
    "phase35-sf-facet-wrap.html" = 2L,
    "phase35-sf-facet-grid.html" = 2L,
    "phase35-sf-skipped-rows.html" = 2L,
    "phase35-sf-interactivity-smoke.html" = 100L
  )
}

.browser_sf_file_url <- function(path) {
  paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
}

.browser_sf_path_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll(\"path.geom-sf\")).map(path => ({",
    'd: path.getAttribute("d"),',
    'dataRowId: path.getAttribute("data-row-id"),',
    'dataCx: path.getAttribute("data-cx"),',
    'dataCy: path.getAttribute("data-cy"),',
    'cx: Number(path.getAttribute("data-cx")),',
    'cy: Number(path.getAttribute("data-cy"))',
    "})))()"
  )
}

.browser_sf_panel_count_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll(\".panel\"))",
    ".map(panel => panel.querySelectorAll(\"path.geom-sf\").length))()"
  )
}

.browser_sf_private_fields <- function() {
  c("_geom", "_centroid")
}

.browser_sf_expect_public_payload <- function(payload) {
  expect_false(is.null(payload))
  expect_false(any(.browser_sf_private_fields() %in% names(payload)))
}

.browser_sf_expect_public_payload_rows <- function(rows) {
  expect_gt(length(rows), 0)
  private_fields <- .browser_sf_private_fields()
  for (row in rows) {
    expect_false(any(private_fields %in% names(row)))
  }
}

.browser_sf_interaction_script <- function() {
  paste(
    "(() => new Promise(resolve => {",
    "const path = document.querySelector('path.geom-sf');",
    "const panelGroup = path ? path.closest('.panel') : null;",
    "const cx = path ? Number(path.getAttribute('data-cx')) : NaN;",
    "const cy = path ? Number(path.getAttribute('data-cy')) : NaN;",
    "if (path) {",
    '  path.dispatchEvent(new MouseEvent("click"));',
    "  path.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "}",
    "const tooltip = document.querySelector('.gg2d3-tooltip');",
    "const brush = panelGroup && panelGroup.__gg2d3_brush;",
    "if (brush && Number.isFinite(cx) && Number.isFinite(cy)) {",
    "  brush.group.call(brush.behavior.move, [[cx - 2, cy - 2], [cx + 2, cy + 2]]);",
    "}",
    "setTimeout(() => resolve({",
    "  pathCount: document.querySelectorAll('path.geom-sf').length,",
    "  hasBrushOverlay: !!document.querySelector('.brush-overlay'),",
    "  cx: cx,",
    "  cy: cy,",
    "  click: window.__gg2d3_sf_click || null,",
    "  tooltipText: tooltip ? (tooltip.textContent || tooltip.innerHTML || '') : '',",
    "  brush: window.__gg2d3_sf_brush || []",
    "}), 50);",
    "}))()"
  )
}

.browser_sf_assert_interaction_payloads <- function() {
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  choropleth <- ggplot2::ggplot(nc, ggplot2::aes(fill = BIR74)) +
    ggplot2::geom_sf()

  widget <- gg2d3(choropleth) |>
    d3_brush(on_brush = "window.__gg2d3_sf_brush = selectedData;") |>
    d3_tooltip() |>
    d3_hover() |>
    d3_handlers(click = "function(event, d) { window.__gg2d3_sf_click = d; }")

  expect_warning(
    widget <- d3_zoom(widget),
    regexp = "geom_sf.*zoom|zoom.*geom_sf"
  )
  expect_true(widget$x$interactivity$brush$enabled)
  expect_true(widget$x$interactivity$tooltip$enabled)
  expect_true(widget$x$interactivity$hover$enabled)
  expect_false(is.null(widget$x$interactivity$handlers$click))
  expect_null(widget$x$interactivity$zoom)

  html_path <- save_browser_sf_widget(
    widget,
    "phase36-sf-interaction-payloads.html"
  )

  with_chromote_session({
    logs <- browser_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_sf_file_url(html_path), delay = 1)
        wait_for_sf_paths(session, expected = 100L, timeout = 10)

        result <- eval_js_value(session, .browser_sf_interaction_script())

        expect_equal(result$pathCount, 100L)
        expect_true(isTRUE(result$hasBrushOverlay))
        expect_true(is.finite(result$cx))
        expect_true(is.finite(result$cy))
        .browser_sf_expect_public_payload(result$click)
        expect_false(grepl("_geom|_centroid", result$tooltipText))
        .browser_sf_expect_public_payload_rows(result$brush)
        assert_no_browser_errors(logs)
      },
      error = function(e) {
        write_browser_failure_artifacts(
          "phase36-sf-interaction-payloads",
          html_path,
          logs,
          session
        )
        stop(e)
      }
    )
  })
}

test_that("BRSF-01 DOM: Phase 35 sf fixtures render live geom-sf paths", {
  skip_browser_sf_smoke()

  fixtures <- .phase35_sf_fixture_set()
  expected_names <- .browser_sf_fixture_names()
  expected_counts <- .browser_sf_expected_counts()

  expect_equal(names(fixtures), expected_names)
  expect_equal(names(expected_counts), expected_names)

  with_chromote_session({
    logs <- browser_console_collector(session)

    for (fixture_name in expected_names) {
      html_path <- fixtures[[fixture_name]]
      expect_true(file.exists(html_path))

      tryCatch(
        {
          session$go_to(.browser_sf_file_url(html_path), delay = 1)
          wait_for_sf_paths(
            session,
            expected = unname(expected_counts[[fixture_name]]),
            timeout = 10
          )
          paths <- eval_js_value(session, .browser_sf_path_script())

          expect_length(paths, expected_counts[[fixture_name]])

          d_values <- vapply(paths, function(path) path$d, character(1))
          row_ids <- vapply(paths, function(path) path$dataRowId, character(1))
          cx_values <- vapply(paths, function(path) path$cx, numeric(1))
          cy_values <- vapply(paths, function(path) path$cy, numeric(1))

          expect_true(all(nzchar(d_values)))
          expect_true(all(nzchar(row_ids)))
          expect_true(all(is.finite(cx_values)))
          expect_true(all(is.finite(cy_values)))

          if (identical(fixture_name, "phase35-sf-skipped-rows.html")) {
            expect_equal(row_ids, c("1", "5"))
            expect_false(any(c("2", "3", "4") %in% row_ids))
          }
          assert_no_browser_errors(logs)
        },
        error = function(e) {
          write_browser_failure_artifacts(
            tools::file_path_sans_ext(fixture_name),
            html_path,
            logs,
            session
          )
          stop(e)
        }
      )
    }
  })
})

test_that("BRSF-02 DOM: faceted sf fixtures keep panel-local path counts", {
  skip_browser_sf_smoke()

  fixtures <- .phase35_sf_fixture_set()
  expected_counts <- .browser_sf_expected_counts()
  expected_panel_counts <- list(
    "phase35-sf-facet-wrap.html" = c(1L, 1L),
    "phase35-sf-facet-grid.html" = c(0L, 0L, 1L, 1L)
  )

  with_chromote_session({
    logs <- browser_console_collector(session)

    for (fixture_name in names(expected_panel_counts)) {
      html_path <- fixtures[[fixture_name]]
      expect_true(file.exists(html_path))

      tryCatch(
        {
          session$go_to(.browser_sf_file_url(html_path), delay = 1)
          wait_for_sf_paths(
            session,
            expected = unname(expected_counts[[fixture_name]]),
            timeout = 10
          )

          panel_counts <- eval_js_value(session, .browser_sf_panel_count_script())
          panel_counts <- as.integer(unlist(panel_counts, use.names = FALSE))

          expect_equal(sort(panel_counts), expected_panel_counts[[fixture_name]])
          assert_no_browser_errors(logs)
        },
        error = function(e) {
          write_browser_failure_artifacts(
            tools::file_path_sans_ext(fixture_name),
            html_path,
            logs,
            session
          )
          stop(e)
        }
      )
    }
  })
})

test_that("BRSF-03 artifact: browser sf fixtures use deterministic local output", {
  skip_browser_sf_smoke()

  fixtures <- .phase35_sf_fixture_set()
  artifact_dir <- browser_sf_artifact_dir()
  fixture_paths <- normalizePath(unlist(fixtures), winslash = "/", mustWork = TRUE)
  artifact_path <- normalizePath(artifact_dir, winslash = "/", mustWork = FALSE)

  expect_true(all(file.exists(unlist(fixtures))))
  expect_true(all(grepl("test_output", fixture_paths, fixed = TRUE)))
  expect_true(grepl("test_output/browser-sf", artifact_path, fixed = TRUE))
  expect_true(file.exists(artifact_dir))
})

test_that("BRSF-03 artifact: browser errors write deterministic log files", {
  artifact_dir <- browser_sf_artifact_dir()
  html_path <- tempfile("browser-sf-artifact-", fileext = ".html")
  writeLines("<!doctype html><title>browser sf artifact</title>", html_path)
  fixture_name <- "artifact-contract"

  logs <- list(
    list(
      source = "Runtime.consoleAPICalled",
      type = "error",
      message = "console failure"
    ),
    list(
      source = "Runtime.exceptionThrown",
      type = "exception",
      message = "page failure"
    )
  )

  write_browser_failure_artifacts(fixture_name, html_path, logs, session = NULL)

  expect_true(file.exists(file.path(artifact_dir, paste0(fixture_name, "-console.log"))))
  expect_true(file.exists(file.path(artifact_dir, paste0(fixture_name, "-page-errors.log"))))
  expect_error(assert_no_browser_errors(logs), "Browser errors were captured")
})

test_that("BRSF-02 interaction: browser interaction helper is wired", {
  expect_true(is.function(.browser_sf_assert_interaction_payloads))
})

test_that("BRSF-02 interaction: sf browser payloads are sanitized and brush uses centroids", {
  skip_browser_sf_smoke()

  .browser_sf_assert_interaction_payloads()
})
