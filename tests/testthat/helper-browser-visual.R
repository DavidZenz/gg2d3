# Shared helpers for opt-in browser visual smoke artifacts.

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

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) {
    if (is.null(x)) y else x
  }
}

browser_visual_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-visual-smoke")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

browser_visual_fixture_id <- function(id) {
  clean <- gsub("[^A-Za-z0-9_-]+", "-", as.character(id))
  clean <- gsub("^-+|-+$", "", clean)
  if (!nzchar(clean)) {
    stop("Browser visual fixture id is empty after sanitization.", call. = FALSE)
  }
  clean
}

browser_visual_paths <- function(id) {
  clean <- browser_visual_fixture_id(id)
  prefix <- file.path(browser_visual_artifact_dir(), clean)
  list(
    html = paste0(prefix, ".html"),
    png = paste0(prefix, ".png"),
    dom_summary = paste0(prefix, "-dom-summary.json"),
    browser_log = paste0(prefix, "-browser-log.json")
  )
}

browser_visual_file_url <- function(path) {
  paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
}

browser_visual_require_opt_in <- function() {
  testthat::skip_if_not(
    identical(Sys.getenv("GG2D3_BROWSER_VISUAL_SMOKE"), "true"),
    "Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate browser visual smoke artifacts"
  )
}

skip_browser_visual_smoke <- function() {
  browser_visual_require_opt_in()
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote browser visual smoke tests"
  )

  launch <- tryCatch(
    {
      session <- chromote::ChromoteSession$new(width = 10, height = 10)
      on.exit(session$close(), add = TRUE)
      TRUE
    },
    error = function(e) e
  )
  launch_message <- if (inherits(launch, "condition")) {
    conditionMessage(launch)
  } else {
    as.character(launch)
  }
  testthat::skip_if(
    !isTRUE(launch),
    paste("chromote session launch unavailable:", launch_message)
  )

  invisible(TRUE)
}

browser_visual_optional_dependencies <- function(require_sf = FALSE, require_geojsonsf = FALSE) {
  missing <- character()
  if (isTRUE(require_sf) && !requireNamespace("sf", quietly = TRUE)) {
    missing <- c(missing, "sf")
  }
  if (isTRUE(require_geojsonsf) && !requireNamespace("geojsonsf", quietly = TRUE)) {
    missing <- c(missing, "geojsonsf")
  }

  if (length(missing) == 0) {
    return(list(
      available = TRUE,
      missing = character(),
      message = "All optional dependencies are available"
    ))
  }

  list(
    available = FALSE,
    missing = missing,
    message = paste("Missing optional dependencies:", paste(missing, collapse = ", "))
  )
}

if (!exists("with_chromote_session", mode = "function")) {
  with_chromote_session <- function(code, width = 900, height = 700) {
    session <- chromote::ChromoteSession$new(width = width, height = height)
    on.exit(session$close(), add = TRUE)

    eval(
      substitute(code),
      envir = list2env(list(session = session), parent = parent.frame())
    )
  }
}

if (!exists("eval_js_value", mode = "function")) {
  eval_js_value <- function(session, script) {
    result <- session$Runtime$evaluate(
      script,
      returnByValue = TRUE,
      awaitPromise = TRUE
    )
    result$result$value
  }
}

save_browser_visual_widget <- function(widget, id) {
  paths <- browser_visual_paths(id)
  htmlwidgets::saveWidget(
    widget,
    file = normalizePath(paths$html, mustWork = FALSE),
    selfcontained = FALSE
  )
  testthat::expect_true(file.exists(paths$html))
  paths$html
}

browser_visual_dom_summary_script <- function(extra_selector_counts = character()) {
  # Keep this helper-owned script static; expected fixture selectors are checked separately.
  paste(
    "(() => {",
    "const count = selector => document.querySelectorAll(selector).length;",
    "return {",
    "title: document.title || '',",
    "svgCount: count('svg'),",
    "panelCount: count('.panel'),",
    "markCounts: {",
    "point: count('circle.geom-point'),",
    "line: count('path.geom-line'),",
    "bar: count('rect.geom-bar'),",
    "rect: count('rect.geom-rect'),",
    "text: count('text.geom-text'),",
    "polygon: count('path.geom-polygon'),",
    "sf: count('.geom-sf'),",
    "sfText: count('text.geom-sf.geom-sf-text'),",
    "sfLabel: count('g.geom-sf.geom-sf-label')",
    "},",
    "bodyTextLength: document.body ? document.body.innerText.length : 0",
    "};",
    "})()"
  )
}

.browser_visual_event <- function(...) {
  args <- list(...)
  if (length(args) == 1 && is.list(args[[1]])) args[[1]] else args
}

.browser_visual_console_text <- function(event) {
  values <- event$args %||% list()
  text <- vapply(values, function(value) {
    if (!is.null(value$value)) return(as.character(value$value))
    if (!is.null(value$description)) return(as.character(value$description))
    if (!is.null(value$type)) return(as.character(value$type))
    ""
  }, character(1))
  paste(text[nzchar(text)], collapse = " ")
}

browser_visual_console_collector <- function(session) {
  logs <- new.env(parent = emptyenv())
  logs$entries <- list()

  append_log <- function(entry) {
    logs$entries[[length(logs$entries) + 1L]] <- entry
  }

  session$Runtime$enable()
  session$Runtime$consoleAPICalled(
    callback_ = function(...) {
      event <- .browser_visual_event(...)
      append_log(list(
        source = "Runtime.consoleAPICalled",
        type = event$type %||% "log",
        message = .browser_visual_console_text(event),
        timestamp = event$timestamp %||% NA
      ))
    },
    wait_ = FALSE
  )
  session$Runtime$exceptionThrown(
    callback_ = function(...) {
      event <- .browser_visual_event(...)
      details <- event$exceptionDetails %||% list()
      append_log(list(
        source = "Runtime.exceptionThrown",
        type = "exception",
        message = details$text %||% "JavaScript exception thrown",
        lineNumber = details$lineNumber %||% NA,
        columnNumber = details$columnNumber %||% NA
      ))
    },
    wait_ = FALSE
  )

  function() logs$entries
}

browser_visual_logs <- function(logs) {
  if (is.function(logs)) return(logs())
  if (is.environment(logs) && exists("entries", logs, inherits = FALSE)) {
    return(logs$entries)
  }
  logs %||% list()
}

assert_no_browser_visual_errors <- function(logs) {
  entries <- browser_visual_logs(logs)
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

.browser_visual_write_json <- function(x, path) {
  jsonlite::write_json(
    x,
    path = path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
}

write_browser_visual_artifacts <- function(id, html_path, logs, session = NULL,
                                           dom_summary = NULL, status = "passed",
                                           error = NULL, skip_reason = NULL) {
  paths <- browser_visual_paths(id)
  entries <- browser_visual_logs(logs)
  screenshot_error <- NULL

  if (!identical(normalizePath(html_path, mustWork = FALSE), normalizePath(paths$html, mustWork = FALSE))) {
    file.copy(html_path, paths$html, overwrite = TRUE)
  }

  if (!is.null(dom_summary)) {
    .browser_visual_write_json(dom_summary, paths$dom_summary)
  }

  if (!is.null(session)) {
    screenshot <- tryCatch(
      {
        session$screenshot(filename = paths$png, selector = "html", delay = 0.5)
        TRUE
      },
      error = function(e) e
    )
    if (!isTRUE(screenshot)) {
      screenshot_error <- conditionMessage(screenshot)
    }
  }

  .browser_visual_write_json(
    list(
      id = browser_visual_fixture_id(id),
      status = status,
      html_path = normalizePath(paths$html, mustWork = FALSE),
      screenshot_path = normalizePath(paths$png, mustWork = FALSE),
      dom_summary_path = normalizePath(paths$dom_summary, mustWork = FALSE),
      skip_reason = skip_reason,
      error = if (is.null(error)) NULL else conditionMessage(error),
      screenshot_error = screenshot_error,
      logs = entries
    ),
    paths$browser_log
  )

  invisible(paths)
}

.browser_visual_wait_for_svg <- function(session, timeout = 10) {
  deadline <- Sys.time() + timeout
  repeat {
    count <- eval_js_value(session, "document.querySelectorAll('svg').length")
    if (!is.null(count) && count > 0) return(invisible(TRUE))
    if (Sys.time() >= deadline) break
    Sys.sleep(0.1)
  }
  testthat::fail(sprintf("Timed out waiting for browser visual SVG after %s seconds", timeout))
}

.browser_visual_selector_count <- function(session, selector) {
  selector_json <- jsonlite::toJSON(as.character(selector), auto_unbox = TRUE)
  eval_js_value(
    session,
    paste0("document.querySelectorAll(", selector_json, ").length")
  )
}

capture_browser_visual_fixture <- function(session, fixture) {
  id <- browser_visual_fixture_id(fixture$id)
  category <- fixture$category %||% "uncategorized"
  logs <- fixture$logs %||% browser_visual_console_collector(session)
  html_path <- NULL
  dom_summary <- NULL

  tryCatch(
    {
      html_path <- save_browser_visual_widget(fixture$widget, id)
      session$go_to(browser_visual_file_url(html_path), delay = 1)
      .browser_visual_wait_for_svg(session)
      dom_summary <- eval_js_value(session, browser_visual_dom_summary_script())

      expected <- fixture$expected %||% list()
      for (selector in names(expected)) {
        actual <- .browser_visual_selector_count(session, selector)
        testthat::expect_gte(
          as.integer(actual),
          as.integer(expected[[selector]]),
          info = sprintf("Expected at least %s nodes for selector %s in %s", expected[[selector]], selector, id)
        )
      }

      assert_no_browser_visual_errors(logs)
      paths <- write_browser_visual_artifacts(id, html_path, logs, session, dom_summary, status = "passed")
      list(
        id = id,
        category = category,
        status = "passed",
        html = paths$html,
        screenshot = paths$png,
        dom_summary = paths$dom_summary,
        browser_log = paths$browser_log,
        skip_reason = NULL,
        error = NULL
      )
    },
    error = function(e) {
      if (is.null(html_path)) {
        paths <- browser_visual_paths(id)
        html_path <- paths$html
      }
      paths <- write_browser_visual_artifacts(id, html_path, logs, session, dom_summary, status = "failed", error = e)
      list(
        id = id,
        category = category,
        status = "failed",
        html = paths$html,
        screenshot = paths$png,
        dom_summary = paths$dom_summary,
        browser_log = paths$browser_log,
        skip_reason = NULL,
        error = conditionMessage(e)
      )
    }
  )
}

.browser_visual_relative_path <- function(path) {
  if (is.null(path) || !nzchar(path)) return("")
  basename(path)
}

write_browser_visual_index <- function(rows) {
  out_dir <- browser_visual_artifact_dir()
  index_json <- file.path(out_dir, "index.json")
  index_html <- file.path(out_dir, "index.html")

  .browser_visual_write_json(
    list(
      generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      artifact_dir = normalizePath(out_dir, mustWork = FALSE),
      rows = rows
    ),
    index_json
  )

  row_html <- vapply(rows, function(row) {
    id <- htmltools::htmlEscape(row$id %||% "")
    category <- htmltools::htmlEscape(row$category %||% "")
    status <- htmltools::htmlEscape(row$status %||% "")
    skip_reason <- htmltools::htmlEscape(row$skip_reason %||% "")
    links <- c(
      html = row$html %||% "",
      screenshot = row$screenshot %||% "",
      dom = row$dom_summary %||% "",
      log = row$browser_log %||% ""
    )
    links <- links[nzchar(links)]
    link_html <- paste(vapply(names(links), function(label) {
      href <- htmltools::htmlEscape(.browser_visual_relative_path(links[[label]]))
      sprintf("<a href=\"%s\">%s</a>", href, htmltools::htmlEscape(label))
    }, character(1)), collapse = " ")
    sprintf(
      "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
      id, category, status, link_html, skip_reason
    )
  }, character(1))

  html <- paste0(
    "<!doctype html><meta charset=\"utf-8\">",
    "<title>gg2d3 Browser Visual Smoke</title>",
    "<style>body{font-family:system-ui,sans-serif;max-width:1100px;margin:2em auto;padding:0 1em}",
    "table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:.45em;text-align:left}",
    "th{background:#f5f5f5}a{margin-right:.6em}</style>",
    "<h1>gg2d3 Browser Visual Smoke</h1>",
    "<p>Generated local artifacts for maintainer inspection. These files live under <code>test_output/browser-visual-smoke/</code>.</p>",
    "<table><thead><tr><th>Fixture</th><th>Category</th><th>Status</th><th>Artifacts</th><th>Skip reason</th></tr></thead><tbody>",
    paste(row_html, collapse = ""),
    "</tbody></table>"
  )
  writeLines(html, index_html, useBytes = TRUE)

  invisible(list(html = index_html, json = index_json))
}
