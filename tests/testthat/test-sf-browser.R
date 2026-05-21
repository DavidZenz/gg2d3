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

    assert_no_browser_errors(logs)
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

    assert_no_browser_errors(logs)
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
