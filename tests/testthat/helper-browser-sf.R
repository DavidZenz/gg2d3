# Chromote helpers for live-browser geom_sf smoke tests.

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

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

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

wait_for_sf_marks <- function(session, expected, timeout = 10) {
  deadline <- Sys.time() + timeout
  mark_script <- paste(
    "(() => Array.from(document.querySelectorAll(\".geom-sf\")).map(mark => ({",
    "tag: mark.tagName.toLowerCase(),",
    "className: mark.getAttribute(\"class\") || \"\",",
    "rowId: mark.getAttribute(\"data-row-id\"),",
    "dataCx: Number(mark.getAttribute(\"data-cx\")),",
    "dataCy: Number(mark.getAttribute(\"data-cy\")),",
    "cx: Number(mark.getAttribute(\"cx\")),",
    "cy: Number(mark.getAttribute(\"cy\")),",
    "d: mark.getAttribute(\"d\") || \"\",",
    "r: Number(mark.getAttribute(\"r\")),",
    "fill: mark.getAttribute(\"fill\") || window.getComputedStyle(mark).fill || \"\"",
    "})))()"
  )

  repeat {
    count <- eval_js_value(
      session,
      "document.querySelectorAll(\".geom-sf\").length"
    )
    if (!is.null(count) && count >= expected) {
      return(eval_js_value(session, mark_script))
    }
    if (Sys.time() >= deadline) break
    Sys.sleep(0.1)
  }

  testthat::fail(sprintf(
    "Timed out waiting for %s .geom-sf nodes after %s seconds",
    expected,
    timeout
  ))
}

wait_for_sf_paths <- function(session, expected, timeout = 10) {
  deadline <- Sys.time() + timeout
  path_script <- paste(
    "(() => Array.from(document.querySelectorAll(\"path.geom-sf\")).map(path => ({",
    "d: path.getAttribute(\"d\"),",
    "rowId: path.getAttribute(\"data-row-id\"),",
    "dataRowId: path.getAttribute(\"data-row-id\"),",
    "cx: Number(path.getAttribute(\"data-cx\")),",
    "cy: Number(path.getAttribute(\"data-cy\")),",
    "dataCx: path.getAttribute(\"data-cx\"),",
    "dataCy: path.getAttribute(\"data-cy\")",
    "})))()"
  )

  repeat {
    count <- eval_js_value(
      session,
      "document.querySelectorAll(\"path.geom-sf\").length"
    )
    if (!is.null(count) && count >= expected) {
      return(eval_js_value(session, path_script))
    }
    if (Sys.time() >= deadline) break
    Sys.sleep(0.1)
  }

  testthat::fail(sprintf(
    "Timed out waiting for %s path.geom-sf nodes after %s seconds",
    expected,
    timeout
  ))
}

.browser_sf_event <- function(...) {
  args <- list(...)
  if (length(args) == 1 && is.list(args[[1]])) args[[1]] else args
}

.browser_sf_console_text <- function(event) {
  values <- event$args %||% list()
  text <- vapply(values, function(value) {
    if (!is.null(value$value)) return(as.character(value$value))
    if (!is.null(value$description)) return(as.character(value$description))
    if (!is.null(value$type)) return(as.character(value$type))
    ""
  }, character(1))
  paste(text[nzchar(text)], collapse = " ")
}

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
  session$Runtime$exceptionThrown(
    callback_ = function(...) {
      event <- .browser_sf_event(...)
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

.browser_sf_logs <- function(logs) {
  if (is.function(logs)) return(logs())
  if (is.environment(logs) && exists("entries", logs, inherits = FALSE)) {
    return(logs$entries)
  }
  logs
}

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

write_browser_failure_artifacts <- function(name, html_path, logs, session = NULL) {
  out_dir <- browser_sf_artifact_dir()
  prefix <- file.path(out_dir, name)
  entries <- .browser_sf_logs(logs)
  console_entries <- entries[vapply(entries, function(entry) {
    identical(entry$source, "Runtime.consoleAPICalled")
  }, logical(1))]
  page_error_entries <- entries[vapply(entries, function(entry) {
    identical(entry$source, "Runtime.exceptionThrown") ||
      identical(entry$type, "exception")
  }, logical(1))]

  format_entry <- function(entry) {
    paste(
      entry$source %||% "browser",
      entry$type %||% "log",
      entry$message %||% "",
      sep = ": "
    )
  }

  writeLines(
    vapply(console_entries, format_entry, character(1)),
    con = paste0(prefix, "-console.log")
  )
  writeLines(
    vapply(page_error_entries, format_entry, character(1)),
    con = paste0(prefix, "-page-errors.log")
  )

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
