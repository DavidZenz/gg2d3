# Optional browser smoke tests for live sf text/label annotation DOM rendering.

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

.browser_sfann_square_ring <- function(xmin = 0, ymin = 0, xmax = 1, ymax = 1) {
  matrix(
    c(
      xmin, ymin,
      xmax, ymin,
      xmax, ymax,
      xmin, ymax,
      xmin, ymin
    ),
    ncol = 2,
    byrow = TRUE
  )
}

.browser_sfann_file_url <- function(path) {
  paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
}

.browser_sfann_private_fields <- function() {
  c("_geom", "_centroid", "_sfFamily", "_sfAnchor", "_pointCoord", "_pointIndex")
}

.browser_sfann_expect_public_payload <- function(payload) {
  expect_false(is.null(payload))
  expect_false(any(.browser_sfann_private_fields() %in% names(payload)))
}

.browser_sfann_expect_public_rows <- function(rows) {
  expect_gt(length(rows), 0)
  for (row in rows) {
    .browser_sfann_expect_public_payload(row)
    expect_true("label" %in% names(row))
    expect_true("row_id" %in% names(row))
  }
}

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

.browser_sfann_panel_counts_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('.panel'))",
    ".map(panel => panel.querySelectorAll('text.geom-sf.geom-sf-text, g.geom-sf.geom-sf-label').length))()"
  )
}

.browser_sfann_interaction_script <- function() {
  paste(
    "(() => new Promise(resolve => {",
    "window.__gg2d3_sfann_brush = [];",
    "window.__gg2d3_sfann_click = null;",
    "window.__gg2d3_sfann_mouseover = null;",
    "window.__gg2d3_sfann_shiny = null;",
    "window.Shiny = { setInputValue: function(id, value) { window.__gg2d3_sfann_shiny = { id, value }; } };",
    "const mark = document.querySelector('text.geom-sf.geom-sf-text, g.geom-sf.geom-sf-label');",
    "const panelGroup = mark ? mark.closest('.panel') : null;",
    "const cx = mark ? Number(mark.getAttribute('data-cx')) : NaN;",
    "const cy = mark ? Number(mark.getAttribute('data-cy')) : NaN;",
    "if (mark) {",
    "  mark.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "  mark.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, cancelable: true, view: window, clientX: cx, clientY: cy }));",
    "}",
    "const brush = panelGroup && panelGroup.__gg2d3_brush;",
    "if (brush && Number.isFinite(cx) && Number.isFinite(cy)) {",
    "  brush.group.call(brush.behavior.move, [[cx - 4, cy - 4], [cx + 4, cy + 4]]);",
    "}",
    "setTimeout(() => {",
    "  const tooltip = document.querySelector('.gg2d3-tooltip');",
    "  resolve({",
    "    className: mark ? (mark.getAttribute('class') || '') : '',",
    "    cx: cx,",
    "    cy: cy,",
    "    click: window.__gg2d3_sfann_click || null,",
    "    mouseover: window.__gg2d3_sfann_mouseover || null,",
    "    shiny: window.__gg2d3_sfann_shiny || null,",
    "    tooltipText: tooltip ? (tooltip.textContent || tooltip.innerHTML || '') : '',",
    "    brush: window.__gg2d3_sfann_brush || []",
    "  });",
    "}, 150);",
    "}))()"
  )
}

.browser_sfann_fixture_plots <- function() {
  polygon_text <- sf::st_sf(
    label = "polygon text",
    geometry = sf::st_sfc(sf::st_polygon(list(.browser_sfann_square_ring())), crs = 4326)
  )
  point_label <- sf::st_sf(
    label = "point label",
    geometry = sf::st_sfc(sf::st_point(c(2, 2)), crs = 4326)
  )
  line_text <- sf::st_sf(
    label = "line text",
    geometry = sf::st_sfc(sf::st_linestring(matrix(c(3, 0, 4, 1, 5, 0), ncol = 2, byrow = TRUE)), crs = 4326)
  )
  stacked_base <- sf::st_sf(
    label = "base",
    geometry = sf::st_sfc(sf::st_polygon(list(.browser_sfann_square_ring(0, 0, 1, 1))), crs = 4326)
  )
  faceted <- sf::st_sf(
    label = c("facet A", "facet B"),
    panel = factor(c("A", "B"), levels = c("A", "B")),
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), sf::st_point(c(50, 20)), crs = 4326)
  )
  skipped <- sf::st_sf(
    label = c("ok", "skip"),
    geometry = sf::st_sfc(
      sf::st_point(c(0, 0)),
      sf::st_geometrycollection(list(sf::st_point(c(10, 10)))),
      crs = 4326
    )
  )

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
    "phase46-sfann-line-text.html" = list(
      expected = 1L,
      plot = ggplot2::ggplot(line_text, ggplot2::aes(label = label)) +
        ggplot2::geom_sf_text()
    ),
    "phase46-sfann-stacked.html" = list(
      expected = 2L,
      plot = ggplot2::ggplot() +
        ggplot2::geom_sf(data = stacked_base, fill = "#B3D4FC") +
        ggplot2::geom_sf_text(data = point_label, ggplot2::aes(label = label)) +
        ggplot2::geom_sf_label(data = line_text, ggplot2::aes(label = label), fill = "white")
    ),
    "phase46-sfann-faceted.html" = list(
      expected = 2L,
      faceted = TRUE,
      plot = ggplot2::ggplot(faceted, ggplot2::aes(label = label)) +
        ggplot2::geom_sf_label(fill = "white") +
        ggplot2::facet_wrap(~ panel)
    ),
    "phase46-sfann-skipped.html" = list(
      expected = 1L,
      warning = "skipped",
      plot = ggplot2::ggplot(skipped, ggplot2::aes(label = label)) +
        ggplot2::geom_sf_text()
    )
  )
}

test_that("SFANN-01 SFANN-02 DOM: sf annotation fixtures render text and label marks", {
  skip_browser_sf_smoke()

  fixtures <- .browser_sfann_fixture_plots()

  with_chromote_session({
    logs <- browser_console_collector(session)

    for (fixture_name in names(fixtures)) {
      fixture <- fixtures[[fixture_name]]
      if (!is.null(fixture$warning)) {
        expect_warning(widget <- gg2d3(fixture$plot), regexp = fixture$warning)
      } else {
        widget <- gg2d3(fixture$plot)
      }
      html_path <- save_browser_sf_widget(widget, fixture_name)

      tryCatch(
        {
          session$go_to(.browser_sfann_file_url(html_path), delay = 1)
          wait_for_sf_marks(session, expected = fixture$expected, timeout = 10)
          marks <- eval_js_value(session, .browser_sfann_marks_script())

          expect_equal(length(marks), fixture$expected)
          for (mark in marks) {
            expect_true(grepl("geom-sf-text|geom-sf-label", mark$className))
            expect_true(nzchar(mark$rowId))
            expect_true(is.finite(mark$dataCx))
            expect_true(is.finite(mark$dataCy))
            if (grepl("geom-sf-label", mark$className, fixed = TRUE)) {
              expect_equal(mark$boxCount, 1L)
              expect_equal(mark$textCount, 1L)
            }
          }

          if (isTRUE(fixture$faceted)) {
            panel_counts <- as.integer(unlist(eval_js_value(session, .browser_sfann_panel_counts_script())))
            expect_equal(panel_counts, c(1L, 1L))
          }

          assert_no_browser_errors(logs)
        },
        error = function(e) {
          write_browser_failure_artifacts(
            sub("\\.html$", "", fixture_name),
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

test_that("SFANN-03 DOM: sf annotation interaction payloads are public rows", {
  skip_browser_sf_smoke()

  point_label <- sf::st_sf(
    label = "interactive label",
    geometry = sf::st_sfc(sf::st_point(c(2, 2)), crs = 4326)
  )
  widget <- gg2d3(
    ggplot2::ggplot(point_label, ggplot2::aes(label = label)) +
      ggplot2::geom_sf_label(fill = "white")
  ) |>
    d3_tooltip() |>
    d3_hover() |>
    d3_brush(on_brush = "window.__gg2d3_sfann_brush = selectedData;") |>
    d3_handlers(
      click = "function(event, d) { window.__gg2d3_sfann_click = d; }",
      mouseover = "function(event, d) { window.__gg2d3_sfann_mouseover = d; }",
      shiny_id = "phase46_sfann"
    )

  html_path <- save_browser_sf_widget(widget, "phase46-sfann-interactivity.html")

  with_chromote_session({
    logs <- browser_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_sfann_file_url(html_path), delay = 1)
        wait_for_sf_marks(session, expected = 1L, timeout = 10)
        result <- eval_js_value(session, .browser_sfann_interaction_script())

        expect_true(grepl("geom-sf-label", result$className, fixed = TRUE))
        expect_true(is.finite(result$cx))
        expect_true(is.finite(result$cy))
        .browser_sfann_expect_public_payload(result$click)
        .browser_sfann_expect_public_payload(result$mouseover)
        .browser_sfann_expect_public_payload(result$shiny$value)
        .browser_sfann_expect_public_rows(result$brush)
        expect_false(grepl("_geom|_centroid|_sfFamily|_sfAnchor|_pointCoord|_pointIndex", result$tooltipText))
        assert_no_browser_errors(logs)
      },
      error = function(e) {
        write_browser_failure_artifacts(
          "phase46-sfann-interactivity",
          html_path,
          logs,
          session
        )
        stop(e)
      }
    )
  })
})
