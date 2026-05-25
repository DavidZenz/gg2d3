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
