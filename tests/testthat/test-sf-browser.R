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

.browser_sf_mark_panel_count_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll(\".panel\"))",
    ".map(panel => panel.querySelectorAll(\".geom-sf\").length))()"
  )
}

.browser_sf_private_fields <- function() {
  c("_geom", "_centroid", "_sfFamily", "_pointIndex", "_pointCoord")
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

.browser_sf_phase38_interaction_script <- function() {
  paste(
    "(() => new Promise(resolve => {",
    "window.__gg2d3_sf_click = null;",
    "window.__gg2d3_sf_mouseover = null;",
    "window.__gg2d3_sf_brush = [];",
    "window.__gg2d3_sf_shiny = null;",
    "window.Shiny = { setInputValue: function(id, value) { window.__gg2d3_sf_shiny = { id: id, value: value }; } };",
    "const mark = document.querySelector('.geom-sf');",
    "const panelGroup = mark ? mark.closest('.panel') : null;",
    "const cx = mark ? Number(mark.getAttribute('data-cx')) : NaN;",
    "const cy = mark ? Number(mark.getAttribute('data-cy')) : NaN;",
    "if (mark) {",
    "  mark.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "  mark.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "}",
    "const brush = panelGroup && panelGroup.__gg2d3_brush;",
    "if (brush && Number.isFinite(cx) && Number.isFinite(cy)) {",
    "  brush.group.call(brush.behavior.move, [[cx - 3, cy - 3], [cx + 3, cy + 3]]);",
    "}",
    "setTimeout(() => {",
    "  const tooltip = document.querySelector('.gg2d3-tooltip');",
    "  resolve({",
    "    tag: mark ? mark.tagName.toLowerCase() : '',",
    "    className: mark ? (mark.getAttribute('class') || '') : '',",
    "    rowId: mark ? mark.getAttribute('data-row-id') : null,",
    "    cx: cx,",
    "    cy: cy,",
    "    click: window.__gg2d3_sf_click || null,",
    "    mouseover: window.__gg2d3_sf_mouseover || null,",
    "    shiny: window.__gg2d3_sf_shiny || null,",
    "    tooltipText: tooltip ? (tooltip.textContent || tooltip.innerHTML || '') : '',",
    "    brush: window.__gg2d3_sf_brush || []",
    "  });",
    "}, 100);",
    "}))()"
  )
}

.browser_sf_expect_unique_public_rows <- function(rows) {
  .browser_sf_expect_public_payload_rows(rows)
  row_ids <- vapply(rows, function(row) as.character(row$row_id), character(1))
  expect_true(all(nzchar(row_ids)))
  expect_equal(row_ids, unique(row_ids))
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
    "phase35-sf-facet-grid.html" = c(1L, 0L, 0L, 1L)
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

          expect_equal(panel_counts, expected_panel_counts[[fixture_name]])
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

test_that("SFGEOM-03 DOM: point and line sf fixtures render live geom-sf marks", {
  skip_browser_sf_smoke()

  fixtures <- .phase37_sf_fixture_set()

  with_chromote_session({
    logs <- browser_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-point-only.html"]]), delay = 1)
        point_marks <- wait_for_sf_marks(session, expected = 3L, timeout = 10)
        point_circles <- point_marks[vapply(point_marks, function(mark) {
          identical(mark$tag, "circle") && grepl("geom-sf-point", mark$className, fixed = TRUE)
        }, logical(1))]

        expect_gt(length(point_circles), 0)
        for (mark in point_circles) {
          expect_true(is.finite(mark$cx))
          expect_true(is.finite(mark$cy))
          expect_true(is.finite(mark$r))
          expect_gt(mark$r, 0)
          expect_true(nzchar(mark$rowId))
          expect_true(is.finite(mark$dataCx))
          expect_true(is.finite(mark$dataCy))
        }
        assert_no_browser_errors(logs)

        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-line-only.html"]]), delay = 1)
        line_marks <- wait_for_sf_marks(session, expected = 2L, timeout = 10)
        line_paths <- line_marks[vapply(line_marks, function(mark) {
          identical(mark$tag, "path") && grepl("geom-sf-line", mark$className, fixed = TRUE)
        }, logical(1))]

        expect_gt(length(line_paths), 0)
        for (mark in line_paths) {
          expect_true(nzchar(mark$d))
          expect_true(mark$fill %in% c("none", "rgba(0, 0, 0, 0)", "transparent"))
          expect_true(nzchar(mark$rowId))
          expect_true(is.finite(mark$dataCx))
          expect_true(is.finite(mark$dataCy))
        }
        assert_no_browser_errors(logs)
      },
      error = function(e) {
        write_browser_failure_artifacts(
          "phase37-sf-point-line",
          fixtures[["phase37-sf-point-only.html"]],
          logs,
          session
        )
        stop(e)
      }
    )
  })
})

test_that("SFGEOM-04 DOM: mixed sf overlays and facets keep panel-local marks", {
  skip_browser_sf_smoke()

  fixtures <- .phase37_sf_fixture_set()

  with_chromote_session({
    logs <- browser_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-polygon-point-overlay.html"]]), delay = 1)
        polygon_point_marks <- wait_for_sf_marks(session, expected = 4L, timeout = 10)
        polygon_point_classes <- vapply(polygon_point_marks, function(mark) mark$className, character(1))
        expect_true(any(grepl("geom-sf-polygon", polygon_point_classes, fixed = TRUE)))
        expect_true(any(grepl("geom-sf-point", polygon_point_classes, fixed = TRUE)))
        assert_no_browser_errors(logs)

        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-polygon-line-overlay.html"]]), delay = 1)
        polygon_line_marks <- wait_for_sf_marks(session, expected = 3L, timeout = 10)
        polygon_line_classes <- vapply(polygon_line_marks, function(mark) mark$className, character(1))
        expect_true(any(grepl("geom-sf-polygon", polygon_line_classes, fixed = TRUE)))
        expect_true(any(grepl("geom-sf-line", polygon_line_classes, fixed = TRUE)))
        assert_no_browser_errors(logs)

        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-mixed-skipped.html"]]), delay = 1)
        mixed_marks <- wait_for_sf_marks(session, expected = 3L, timeout = 10)
        mixed_classes <- vapply(mixed_marks, function(mark) mark$className, character(1))
        mixed_row_ids <- vapply(mixed_marks, function(mark) mark$rowId, character(1))
        expect_true(any(grepl("geom-sf-polygon", mixed_classes, fixed = TRUE)))
        expect_true(any(grepl("geom-sf-point", mixed_classes, fixed = TRUE)))
        expect_true(any(grepl("geom-sf-line", mixed_classes, fixed = TRUE)))
        expect_false("4" %in% mixed_row_ids)
        assert_no_browser_errors(logs)

        session$go_to(.browser_sf_file_url(fixtures[["phase37-sf-faceted-empty.html"]]), delay = 1)
        wait_for_sf_marks(session, expected = 2L, timeout = 10)
        panel_counts <- eval_js_value(session, .browser_sf_mark_panel_count_script())
        panel_counts <- as.integer(unlist(panel_counts, use.names = FALSE))
        expect_equal(panel_counts, c(1L, 1L, 0L))
        assert_no_browser_errors(logs)
      },
      error = function(e) {
        write_browser_failure_artifacts(
          "phase37-sf-mixed-facets",
          fixtures[["phase37-sf-mixed-skipped.html"]],
          logs,
          session
        )
        stop(e)
      }
    )
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

test_that("SFXDOC-01 DOM: sf point and line interactions expose sanitized source-row payloads", {
  skip_browser_sf_smoke()

  fixtures <- .phase38_sf_interaction_fixture_set()
  expected <- list(
    "phase38-sf-point-interaction.html" = list(
      count = 3L,
      tag = "circle",
      class = "geom-sf-point"
    ),
    "phase38-sf-line-interaction.html" = list(
      count = 2L,
      tag = "path",
      class = "geom-sf-line"
    )
  )

  with_chromote_session({
    logs <- browser_console_collector(session)

    for (fixture_name in names(expected)) {
      html_path <- fixtures[[fixture_name]]
      expect_true(file.exists(html_path))

      tryCatch(
        {
          session$go_to(.browser_sf_file_url(html_path), delay = 1)
          wait_for_sf_marks(
            session,
            expected = expected[[fixture_name]]$count,
            timeout = 10
          )

          result <- eval_js_value(session, .browser_sf_phase38_interaction_script())

          expect_identical(result$tag, expected[[fixture_name]]$tag)
          expect_true(grepl(expected[[fixture_name]]$class, result$className, fixed = TRUE))
          expect_true(nzchar(result$rowId))
          expect_true(is.finite(result$cx))
          expect_true(is.finite(result$cy))
          .browser_sf_expect_public_payload(result$click)
          .browser_sf_expect_public_payload(result$mouseover)
          expect_equal(result$shiny$id, "phase38_sf")
          .browser_sf_expect_public_payload(result$shiny$value)
          expect_false(grepl("_geom|_centroid|_sfFamily|_pointIndex|_pointCoord", result$tooltipText))
          .browser_sf_expect_unique_public_rows(result$brush)
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
