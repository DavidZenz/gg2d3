# Opt-in browser visual capture for the generated pkgdown article.
# Detects blank/stale gg2d3 widget regions by counting SVG child elements per widget.
#
# Run locally with:
#   NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e \
#     'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'
#
# Artifacts are written to test_output/pkgdown-visual/ (gitignored, Rbuildignored).

# Load package if not already loaded (supports both devtools::test() and testthat::test_file())
if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

if (!exists("skip_browser_visual_smoke", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-browser-visual.R",
    "helper-browser-visual.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

if (!exists("pkgdown_site_sf_outcome", mode = "function")) {
  helper_candidates <- c(
    "tests/testthat/helper-pkgdown-site.R",
    "helper-pkgdown-site.R"
  )
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]
  if (!is.na(helper_path)) {
    source(helper_path)
  }
}

# SVG child count threshold for "non-blank" widget assertion.
# A gg2d3 widget with >= 3 SVG child elements (path/circle/rect/line/g) is considered rendered.
# This value is chosen per Claude's discretion (see CONTEXT.md) as a reasonable lower bound
# for a rendered D3 visualization. Increase for stricter blank detection; decrease only with
# documentation of why a valid widget can have fewer than 3 SVG children.
.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD <- 3L

# Artifact directory for pkgdown visual test outputs.
# Parallel to browser_visual_artifact_dir() -> test_output/browser-visual-smoke/
# but file-private: pkgdown-specific helpers live in this file, not in shared helper.
pkgdown_visual_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "pkgdown-visual")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

# Poll until at least min_svg_count gg2d3 widget SVGs are present, or timeout.
# Uses a higher threshold than .browser_visual_wait_for_svg() (which waits for count > 0)
# because the pkgdown article has ~48 widgets and we need most to render before asserting.
# Not added to shared helper: this is a pkgdown-specific polling strategy.
.pkgdown_visual_wait_for_widgets <- function(session, min_svg_count = 10, timeout = 30) {
  deadline <- Sys.time() + timeout
  count <- NULL
  repeat {
    count <- eval_js_value(session, "document.querySelectorAll('.gg2d3.html-widget svg').length")
    if (!is.null(count) && count >= min_svg_count) return(invisible(TRUE))
    if (Sys.time() >= deadline) break
    Sys.sleep(0.25)
  }
  testthat::fail(sprintf(
    "Timed out waiting for %d pkgdown widget SVGs after %ds (got %s)",
    min_svg_count, timeout, count %||% 0
  ))
}

# JS IIFE that returns a DOM summary for blank/stale widget detection on the pkgdown article.
# Reports per-widget SVG child counts (path/circle/rect/line/g) to detect blank renderers.
# threshold: minimum SVG child count for a widget to be considered non-blank (default 3L).
.pkgdown_visual_dom_summary_script <- function(threshold = .PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD) {
  paste0(
    "(() => {",
    "const count = s => document.querySelectorAll(s).length;",
    "const widgets = document.querySelectorAll('.gg2d3.html-widget');",
    "const svgs = document.querySelectorAll('.gg2d3.html-widget svg');",
    "const svgChildCounts = Array.from(svgs).map(svg =>",
    "  svg.querySelectorAll('path, circle, rect, line, g').length",
    ");",
    "return {",
    "  title: document.title || '',",
    "  widgetCount: widgets.length,",
    "  renderedSvgCount: svgs.length,",
    "  svgChildCounts: svgChildCounts,",
    "  blankWidgetCount: svgChildCounts.filter(n => n < ", threshold, ").length,",
    "  geomSfCount: count('.geom-sf'),",
    "  crosstalkGroupCount: count('[data-gg2d3-crosstalk-group]'),",
    "  bodyTextLength: document.body ? document.body.innerText.length : 0",
    "};",
    "})()"
  )
}

test_that("BVIS-PKG-01 pkgdown article browser capture detects rendered widgets and records evidence", {
  # Opt-in guard: set GG2D3_BROWSER_VISUAL_SMOKE=true to run this test.
  # Skips if env var is unset, chromote is unavailable, or Chrome binary is missing.
  skip_browser_visual_smoke()
  # Prerequisite: docs/articles/gg2d3.html must be present (pkgdown::build_site() must have run).
  pkgdown_site_skip_if_generated_docs_unavailable()

  # Resolve article path and classify sf/Crosstalk outcomes before entering the session.
  # These read the HTML from disk (not from chromote) and must be called before or inside
  # the session; called here so outcome classification happens regardless of session success.
  article_path <- pkgdown_site_resolve_path("docs/articles/gg2d3.html")
  sf_outcome <- pkgdown_site_sf_outcome()
  ct_outcome <- pkgdown_site_crosstalk_outcome()

  with_chromote_session({
    logs <- browser_visual_console_collector(session)

    # Navigate to the pre-built pkgdown article via file:// URL.
    # delay = 2: extra settle for this 13MB page with ~48 widgets (vs delay = 1 for single-widget
    # files in smoke tests). htmlwidgets DOMContentLoaded fires async; widgets need time to render.
    url <- browser_visual_file_url(normalizePath(article_path, mustWork = TRUE))
    session$go_to(url, delay = 2)

    # Poll until >= 10 gg2d3 SVGs are present; timeout after 30s.
    # Ensures most widgets have rendered before we assert counts.
    .pkgdown_visual_wait_for_widgets(session, min_svg_count = 10, timeout = 30)

    # Collect DOM summary: widget counts, SVG child counts per widget, sf/Crosstalk counts.
    dom_summary <- eval_js_value(session, .pkgdown_visual_dom_summary_script())

    # Core assertions: at least 10 gg2d3 SVG widgets rendered, none blank.
    testthat::expect_gte(
      dom_summary$renderedSvgCount,
      10L,
      label = "pkgdown article must render at least 10 gg2d3 SVG widgets"
    )
    testthat::expect_equal(
      dom_summary$blankWidgetCount,
      0L,
      label = paste0(
        "all rendered gg2d3 SVG widgets must have >= ",
        .PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD,
        " SVG child elements (path/circle/rect/line/g)"
      )
    )

    # sf outcome branch (D-06): require geom-sf elements when rendered; accept skip notice
    # when sf/GDAL is unavailable locally; fail on "missing" (neither rendered nor classified).
    if (sf_outcome == "rendered") {
      testthat::expect_gte(
        dom_summary$geomSfCount,
        1L,
        label = "sf widget must have rendered .geom-sf elements when sf outcome is rendered"
      )
    } else if (sf_outcome == "classified_skip") {
      has_skip <- eval_js_value(
        session,
        "document.body.innerText.includes('PKGDOWN_SF_OPTIONAL_SKIP')"
      )
      testthat::expect_true(
        has_skip,
        label = "sf skip notice (PKGDOWN_SF_OPTIONAL_SKIP) must be visible in page body text"
      )
    } else {
      testthat::fail(sprintf(
        "sf region outcome is 'missing' in pkgdown article; expected 'rendered' or 'classified_skip' (sf_outcome: %s)",
        sf_outcome
      ))
    }

    # Crosstalk outcome branch: require crosstalk group attribute when rendered or
    # rendered_unlinked_assets; accept classified_skip; fail on "missing".
    if (ct_outcome %in% c("rendered", "rendered_unlinked_assets")) {
      ct_count <- .browser_visual_selector_count(session, "[data-gg2d3-crosstalk-group]")
      testthat::expect_gte(
        as.integer(ct_count),
        1L,
        label = "Crosstalk widgets must be present ([data-gg2d3-crosstalk-group]) when outcome is rendered"
      )
    } else if (ct_outcome == "classified_skip") {
      # Accept: skip notice is in place; no DOM assertion required.
    } else {
      testthat::fail(sprintf(
        "Crosstalk region outcome is 'missing' in pkgdown article; expected 'rendered', 'rendered_unlinked_assets', or 'classified_skip' (ct_outcome: %s)",
        ct_outcome
      ))
    }

    # No browser JavaScript exceptions during rendering.
    assert_no_browser_visual_errors(logs)

    # Write artifacts to test_output/pkgdown-visual/ (gitignored and Rbuildignored).
    out_dir  <- pkgdown_visual_artifact_dir()
    png_path  <- file.path(out_dir, "pkgdown-main-article.png")
    json_path <- file.path(out_dir, "pkgdown-main-article-dom-summary.json")
    log_path  <- file.path(out_dir, "pkgdown-main-article-browser-log.json")

    # Viewport screenshot (no selector argument): captures the visible 1280x900 viewport.
    # Full-page scroll capture is omitted per RESEARCH Open Question 2 (page is very tall;
    # viewport evidence is sufficient for human review per D-05).
    session$screenshot(filename = png_path, delay = 0.5)
    testthat::expect_true(file.exists(png_path), label = "screenshot PNG artifact must exist")

    # DOM summary JSON: programmatic evidence for CI gating (SVG counts, blank count, etc.).
    jsonlite::write_json(dom_summary, path = json_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
    testthat::expect_true(file.exists(json_path), label = "DOM summary JSON artifact must exist")

    # Browser log JSON: session metadata and console log entries for debugging.
    entries <- browser_visual_logs(logs)
    jsonlite::write_json(
      list(
        status            = "passed",
        article_path      = normalizePath(article_path, mustWork = FALSE),
        screenshot_path   = normalizePath(png_path, mustWork = FALSE),
        dom_summary_path  = normalizePath(json_path, mustWork = FALSE),
        logs              = entries
      ),
      path       = log_path,
      auto_unbox = TRUE,
      pretty     = TRUE,
      null       = "null"
    )
    testthat::expect_true(file.exists(log_path), label = "browser log JSON artifact must exist")

  }, width = 1280, height = 900)
})
