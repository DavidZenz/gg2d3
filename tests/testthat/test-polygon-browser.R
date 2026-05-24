# Browser smoke tests for live ordinary geom_polygon DOM rendering.

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

.browser_polygon_file_url <- function(path) {
  paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
}

.browser_polygon_data <- function() {
  data.frame(
    group = rep(c("alpha", "beta"), each = 4),
    vertex = rep(1:4, 2),
    x = c(0, 2, 1.6, 0.2, 3, 5, 4.6, 3.2),
    y = c(0, 0.3, 1.8, 1.4, 1, 1.3, 2.8, 2.4),
    fill_value = rep(c("warm", "cool"), each = 4),
    stroke_value = rep(c("ink", "graphite"), each = 4)
  )
}

.browser_polygon_single_plot <- function() {
  ggplot(.browser_polygon_data()[1:4, ], aes(x, y, group = group)) +
    geom_polygon(fill = "#79A7D3", colour = "#1B365D", linewidth = 0.8, alpha = 0.7)
}

.browser_polygon_grouped_plot <- function() {
  ggplot(.browser_polygon_data(), aes(x, y, group = group, fill = group)) +
    geom_polygon(colour = "#283618", linewidth = 0.7, alpha = 0.8)
}

.browser_polygon_faceted_plot <- function() {
  ggplot(.browser_polygon_data(), aes(x, y, group = group, fill = group)) +
    geom_polygon(colour = "#283618", linewidth = 0.7, alpha = 0.8) +
    facet_wrap(~ group)
}

.browser_polygon_styled_plot <- function() {
  ggplot(
    .browser_polygon_data(),
    aes(x, y, group = group, fill = fill_value, colour = stroke_value)
  ) +
    geom_polygon(linewidth = 1.1, alpha = 0.75)
}

.browser_polygon_na_fill_plot <- function() {
  ggplot(.browser_polygon_data()[1:4, ], aes(x, y, group = group)) +
    geom_polygon(fill = NA, colour = "#1B365D", linewidth = 0.8)
}

.browser_polygon_na_colour_plot <- function() {
  ggplot(.browser_polygon_data()[1:4, ], aes(x, y, group = group)) +
    geom_polygon(fill = "#79A7D3", colour = NA, linewidth = 0.8)
}

.browser_polygon_interactive_plot <- function() {
  ggplot(.browser_polygon_data(), aes(x, y, group = group, fill = group)) +
    geom_polygon(colour = "#283618", linewidth = 0.7, alpha = 0.8)
}

.browser_polygon_crosstalk_plot <- function(faceted = FALSE) {
  testthat::skip_if_not_installed("crosstalk")
  dat <- .browser_polygon_data()
  dat$row_key <- paste0("row-", seq_len(nrow(dat)))
  shared <- crosstalk::SharedData$new(
    dat,
    key = ~ row_key,
    group = "phase44_polygon_crosstalk"
  )
  p <- ggplot(dat, aes(x, y, group = group, fill = group)) +
    geom_polygon(colour = "#283618", linewidth = 0.7, alpha = 0.8)
  p$data <- shared
  if (isTRUE(faceted)) {
    p <- p + facet_wrap(~ group)
  }
  p
}

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

.browser_polygon_crosstalk_keys_script <- function() {
  paste(
    "(() => Array.from(document.querySelectorAll('path.geom-polygon'))",
    ".map(path => path.getAttribute('data-crosstalk-key') || ''))()"
  )
}

.browser_polygon_wait_for_paths <- function(session, expected, timeout = 10) {
  deadline <- Sys.time() + timeout
  repeat {
    count <- eval_js_value(
      session,
      "document.querySelectorAll('path.geom-polygon').length"
    )
    if (!is.null(count) && count >= expected) {
      return(eval_js_value(session, .browser_polygon_paths_script()))
    }
    if (Sys.time() >= deadline) break
    Sys.sleep(0.1)
  }

  testthat::fail(sprintf(
    "Timed out waiting for %s path.geom-polygon nodes after %s seconds",
    expected,
    timeout
  ))
}

.browser_polygon_expect_paths <- function(paths, expected) {
  expect_length(paths, expected)
  for (path in paths) {
    expect_true(grepl("geom-polygon", path$className, fixed = TRUE))
    expect_true(nzchar(path$d))
    expect_true(grepl("Z\\s*$", path$d))
    expect_true(isTRUE(path$hasClipAncestor))
  }
}

.browser_polygon_private_fields <- function() {
  "_polygonPoints"
}

.browser_polygon_expect_public_payload <- function(payload) {
  expect_false(is.null(payload))
  expect_true("group" %in% names(payload))
  expect_false(any(.browser_polygon_private_fields() %in% names(payload)))
}

.browser_polygon_expect_public_payload_rows <- function(rows) {
  expect_gt(length(rows), 0)
  for (row in rows) {
    .browser_polygon_expect_public_payload(row)
  }
}

.browser_polygon_interaction_script <- function() {
  paste(
    "(() => new Promise(resolve => {",
    "window.__gg2d3_polygon_click = null;",
    "window.__gg2d3_polygon_mouseover = null;",
    "window.__gg2d3_polygon_brush = [];",
    "window.__gg2d3_polygon_shiny = null;",
    "window.Shiny = { setInputValue: function(id, value) { window.__gg2d3_polygon_shiny = { id: id, value: value }; } };",
    "const mark = document.querySelector('path.geom-polygon');",
    "const panelGroup = mark ? mark.closest('.panel') : null;",
    "const bbox = mark ? mark.getBBox() : null;",
    "const cx = bbox ? bbox.x + bbox.width / 2 : NaN;",
    "const cy = bbox ? bbox.y + bbox.height / 2 : NaN;",
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
    "    pathCount: document.querySelectorAll('path.geom-polygon').length,",
    "    hasBrushOverlay: !!document.querySelector('.brush-overlay'),",
    "    click: window.__gg2d3_polygon_click || null,",
    "    mouseover: window.__gg2d3_polygon_mouseover || null,",
    "    shiny: window.__gg2d3_polygon_shiny || null,",
    "    tooltipText: tooltip ? (tooltip.textContent || tooltip.innerHTML || '') : '',",
    "    brush: window.__gg2d3_polygon_brush || []",
    "  });",
    "}, 150);",
    "}))()"
  )
}

test_that("POLY-02 DOM: single and grouped polygon paths render closed clipped marks", {
  skip_browser_polygon_smoke()

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
    }
  })
})

test_that("POLY-02 DOM: faceted polygon paths keep panel-local counts", {
  skip_browser_polygon_smoke()

  html_path <- save_browser_polygon_widget(
    gg2d3(.browser_polygon_faceted_plot()),
    "phase44-polygon-faceted.html"
  )

  with_chromote_session({
    logs <- browser_polygon_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_polygon_file_url(html_path), delay = 1)
        paths <- .browser_polygon_wait_for_paths(session, 2L)
        .browser_polygon_expect_paths(paths, 2L)
        panel_counts <- as.integer(unlist(eval_js_value(session, .browser_polygon_panel_count_script())))
        expect_equal(panel_counts, c(1L, 1L))
        assert_no_polygon_browser_errors(logs)
      },
      error = function(e) {
        write_browser_polygon_failure_artifacts("phase44-polygon-faceted", html_path, logs)
        stop(e)
      }
    )
  })
})

test_that("POLY-02 DOM: mapped styling and NA fill/stroke attributes are visible", {
  skip_browser_polygon_smoke()

  fixtures <- list(
    styled = list(plot = .browser_polygon_styled_plot(), expected = 2L),
    na_fill = list(plot = .browser_polygon_na_fill_plot(), expected = 1L),
    na_colour = list(plot = .browser_polygon_na_colour_plot(), expected = 1L)
  )

  with_chromote_session({
    logs <- browser_polygon_console_collector(session)

    for (name in names(fixtures)) {
      html_path <- save_browser_polygon_widget(
        gg2d3(fixtures[[name]]$plot),
        paste0("phase44-polygon-", name, ".html")
      )

      tryCatch(
        {
          session$go_to(.browser_polygon_file_url(html_path), delay = 1)
          paths <- .browser_polygon_wait_for_paths(session, fixtures[[name]]$expected)
          .browser_polygon_expect_paths(paths, fixtures[[name]]$expected)

          if (identical(name, "styled")) {
            fills <- vapply(paths, function(path) path$fill, character(1))
            strokes <- vapply(paths, function(path) path$stroke, character(1))
            expect_true(all(nzchar(fills)))
            expect_true(all(nzchar(strokes)))
            expect_gt(length(unique(fills)), 1L)
            expect_gt(length(unique(strokes)), 1L)
          }
          if (identical(name, "na_fill")) {
            expect_equal(paths[[1]]$fill, "none")
          }
          if (identical(name, "na_colour")) {
            expect_equal(paths[[1]]$stroke, "none")
          }

          assert_no_polygon_browser_errors(logs)
        },
        error = function(e) {
          write_browser_polygon_failure_artifacts(paste0("phase44-polygon-", name), html_path, logs)
          stop(e)
        }
      )
    }
  })
})

test_that("POLY-03 DOM: polygon interaction payloads are representative and sanitized", {
  skip_browser_polygon_smoke()

  widget <- gg2d3(.browser_polygon_interactive_plot()) |>
    d3_tooltip() |>
    d3_hover() |>
    d3_brush(on_brush = "window.__gg2d3_polygon_brush = selectedData;") |>
    d3_handlers(
      click = "function(event, d) { window.__gg2d3_polygon_click = d; }",
      mouseover = "function(event, d) { window.__gg2d3_polygon_mouseover = d; }",
      shiny_id = "phase44_polygon"
    )

  html_path <- save_browser_polygon_widget(
    widget,
    "phase44-polygon-interactivity.html"
  )

  with_chromote_session({
    logs <- browser_polygon_console_collector(session)

    tryCatch(
      {
        session$go_to(.browser_polygon_file_url(html_path), delay = 1)
        .browser_polygon_wait_for_paths(session, 2L)
        result <- eval_js_value(session, .browser_polygon_interaction_script())

        expect_equal(result$pathCount, 2L)
        expect_true(isTRUE(result$hasBrushOverlay))
        .browser_polygon_expect_public_payload(result$click)
        .browser_polygon_expect_public_payload(result$mouseover)
        expect_equal(result$shiny$id, "phase44_polygon")
        .browser_polygon_expect_public_payload(result$shiny$value)
        expect_false(grepl("_polygonPoints", result$tooltipText, fixed = TRUE))
        .browser_polygon_expect_public_payload_rows(result$brush)
        assert_no_polygon_browser_errors(logs)
      },
      error = function(e) {
        write_browser_polygon_failure_artifacts("phase44-polygon-interactivity", html_path, logs)
        stop(e)
      }
    )
  })
})

test_that("POLY-03 DOM: grouped polygon crosstalk keys use representative source rows", {
  skip_browser_polygon_smoke()

  fixtures <- list(
    grouped = list(
      plot = .browser_polygon_crosstalk_plot(),
      file = "phase44-polygon-crosstalk.html"
    ),
    faceted = list(
      plot = .browser_polygon_crosstalk_plot(faceted = TRUE),
      file = "phase44-polygon-faceted-crosstalk.html"
    )
  )

  with_chromote_session({
    logs <- browser_polygon_console_collector(session)

    for (name in names(fixtures)) {
      html_path <- save_browser_polygon_widget(
        gg2d3(fixtures[[name]]$plot),
        fixtures[[name]]$file
      )

      tryCatch(
        {
          session$go_to(.browser_polygon_file_url(html_path), delay = 1)
          .browser_polygon_wait_for_paths(session, 2L)
          keys <- as.character(unlist(eval_js_value(session, .browser_polygon_crosstalk_keys_script())))
          expect_equal(keys, c("row-1", "row-5"))
          assert_no_polygon_browser_errors(logs)
        },
        error = function(e) {
          write_browser_polygon_failure_artifacts(paste0("phase44-polygon-crosstalk-", name), html_path, logs)
          stop(e)
        }
      )
    }
  })
})
