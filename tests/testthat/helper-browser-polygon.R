# Chromote helpers for live-browser ordinary geom_polygon smoke tests.

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists(".test_output_dir", mode = "function")) {
  .test_output_dir <- function() {
    pkg_root <- tryCatch(
      rprojroot::find_package_root_file(),
      error = function(e) normalizePath(file.path(getwd(), "../../.."), mustWork = FALSE)
    )
    file.path(pkg_root, "test_output")
  }
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

skip_browser_polygon_smoke <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("chromote", "0.5.1")

  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  testthat::skip_if(
    is.null(chrome) || !nzchar(chrome),
    "Chrome/Chromium not available for chromote polygon smoke tests"
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

browser_polygon_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-polygon")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

save_browser_polygon_widget <- function(widget, filename) {
  outpath <- file.path(browser_polygon_artifact_dir(), filename)
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

.browser_polygon_event <- function(...) {
  args <- list(...)
  if (length(args) == 1 && is.list(args[[1]])) args[[1]] else args
}

.browser_polygon_console_text <- function(event) {
  values <- event$args %||% list()
  text <- vapply(values, function(value) {
    if (!is.null(value$value)) return(as.character(value$value))
    if (!is.null(value$description)) return(as.character(value$description))
    if (!is.null(value$type)) return(as.character(value$type))
    ""
  }, character(1))
  paste(text[nzchar(text)], collapse = " ")
}

browser_polygon_console_collector <- function(session) {
  logs <- new.env(parent = emptyenv())
  logs$entries <- list()

  append_log <- function(entry) {
    logs$entries[[length(logs$entries) + 1L]] <- entry
  }

  session$Runtime$enable()
  session$Runtime$consoleAPICalled(
    callback_ = function(...) {
      event <- .browser_polygon_event(...)
      append_log(list(
        source = "Runtime.consoleAPICalled",
        type = event$type %||% "log",
        message = .browser_polygon_console_text(event),
        timestamp = event$timestamp %||% NA
      ))
    },
    wait_ = FALSE
  )
  session$Runtime$exceptionThrown(
    callback_ = function(...) {
      event <- .browser_polygon_event(...)
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

.browser_polygon_logs <- function(logs) {
  if (is.function(logs)) return(logs())
  if (is.environment(logs) && exists("entries", logs, inherits = FALSE)) {
    return(logs$entries)
  }
  logs
}

assert_no_polygon_browser_errors <- function(logs) {
  entries <- .browser_polygon_logs(logs)
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

write_browser_polygon_failure_artifacts <- function(name, html_path, logs) {
  out_dir <- browser_polygon_artifact_dir()
  prefix <- file.path(out_dir, name)
  entries <- .browser_polygon_logs(logs)

  format_entry <- function(entry) {
    paste(
      entry$source %||% "browser",
      entry$type %||% "log",
      entry$message %||% "",
      sep = ": "
    )
  }

  writeLines(
    vapply(entries, format_entry, character(1)),
    con = paste0(prefix, "-browser.log")
  )

  html_copy <- paste0(prefix, ".html")
  if (!identical(normalizePath(html_path, mustWork = FALSE), normalizePath(html_copy, mustWork = FALSE))) {
    file.copy(html_path, html_copy, overwrite = TRUE)
  }

  invisible(prefix)
}
