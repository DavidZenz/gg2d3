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

# Ensure %||% is available regardless of helper sourcing order.
# helper-browser-visual.R defines %||% but may not be sourced yet when this file
# is loaded in a partial-helper environment (e.g., test_file() with pre-loaded
# skip_browser_visual_smoke but missing %||%).
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}

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

# Representative regions and their current generated-article contracts. These
# values intentionally describe the live article payloads, rather than relying
# on a page-wide SVG minimum that could miss a detached or stale example.
.PKGDOWN_VISUAL_REGION_CONTRACTS <- list(
  `basic-usage` = list(widgetCount = 2L, svgCount = 2L),
  `sf-family-maps-with-geom_sf` = list(widgetCount = 1L, svgCount = 1L),
  `linked-views-with-crosstalk` = list(widgetCount = 2L, svgCount = 2L)
)

.PKGDOWN_VISUAL_EXPECTED_WIDGETS <- list(
  `basic-usage` = list(
    list(title = "Motor Trend Cars", x = "wt", y = "mpg", rows = 32L),
    list(title = "Motor Trend Cars", x = "wt", y = "mpg", rows = 32L)
  ),
  `sf-family-maps-with-geom_sf` = list(
    list(layerGeom = "sf", rows = 100L)
  ),
  `linked-views-with-crosstalk` = list(
    list(x = "Sepal.Length", y = "Sepal.Width", rows = 150L),
    list(x = "Petal.Length", y = "Petal.Width", rows = 150L)
  )
)

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

# Read the PNG IHDR dimensions without introducing a new test dependency.
.pkgdown_visual_png_dimensions <- function(path) {
  bytes <- readBin(path, what = "raw", n = 24L)
  signature <- c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L)
  if (length(bytes) < 24L || !identical(as.integer(bytes[1:8]), signature)) {
    return(NULL)
  }

  decode_uint32 <- function(raw_bytes) {
    sum(as.numeric(raw_bytes) * c(256^3, 256^2, 256, 1))
  }

  list(
    width = as.integer(decode_uint32(bytes[17:20])),
    height = as.integer(decode_uint32(bytes[21:24]))
  )
}

# JS IIFE that returns a DOM summary for blank/stale widget detection on the pkgdown article.
# Reports per-widget SVG child counts (path/circle/rect/line/g) to detect blank renderers.
# threshold: minimum SVG child count for a widget to be considered non-blank (default 3L).
.pkgdown_visual_dom_summary_script <- function(
    threshold = .PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD,
    expected_widgets = .PKGDOWN_VISUAL_EXPECTED_WIDGETS
) {
  region_contracts <- jsonlite::toJSON(
    .PKGDOWN_VISUAL_REGION_CONTRACTS,
    auto_unbox = TRUE,
    pretty = FALSE
  )
  expected_widgets <- jsonlite::toJSON(
    expected_widgets,
    auto_unbox = TRUE,
    pretty = FALSE
  )

  paste0(
    "(() => {",
    "const count = s => document.querySelectorAll(s).length;",
    "const widgetSelector = '.gg2d3.html-widget';",
    "const widgets = document.querySelectorAll('.gg2d3.html-widget');",
    "const svgs = document.querySelectorAll('.gg2d3.html-widget svg');",
    "const svgChildCounts = Array.from(svgs).map(svg =>",
    "  svg.querySelectorAll('path, circle, rect, line, g').length",
    ");",
    "const widgetSvgChildCounts = Array.from(widgets).map(widget => Array.from(widget.querySelectorAll('svg')).map(svg =>",
    "  svg.querySelectorAll('path, circle, rect, line, g').length",
    "));",
    "const nearestSection = id => {",
    "  const heading = document.getElementById(id);",
    "  let node = heading;",
    "  while (node && !(node.matches && node.matches('.section'))) node = node.parentElement;",
    "  return node;",
    "};",
    "const regionContracts = ", region_contracts, ";",
    "const expectedWidgets = ", expected_widgets, ";",
    "const regionWidgetCounts = {};",
    "const regionSvgCounts = {};",
    "const regionGeometryCounts = {};",
    "const regionGroupCounts = {};",
    "const regionHeadingPresent = {};",
    "const regionWidgets = {};",
    "Object.keys(regionContracts).forEach(id => {",
    "  const section = nearestSection(id);",
    "  regionHeadingPresent[id] = !!section;",
    "  regionWidgets[id] = section ? Array.from(section.querySelectorAll(widgetSelector)) : [];",
    "  regionWidgetCounts[id] = regionWidgets[id].length;",
    "  regionSvgCounts[id] = section ? section.querySelectorAll(widgetSelector + ' svg').length : 0;",
    "  regionGeometryCounts[id] = section ? section.querySelectorAll('.geom-sf').length : 0;",
    "  regionGroupCounts[id] = section ? section.querySelectorAll('.geom-sf-group').length : 0;",
    "});",
    "const markerSection = nearestSection('v1-13-validation-and-caveat-summary');",
    "const browserVisualSmokeMarkerCount = markerSection ? Array.from(markerSection.querySelectorAll('code')).filter(code => code.textContent === 'test_output/browser-visual-smoke/').length : 0;",
    "const payloadById = new Map();",
    "Array.from(document.querySelectorAll('script[type=\"application/json\"][data-for]')).forEach(script => {",
    "  const id = script.getAttribute('data-for');",
    "  try { payloadById.set(id, JSON.parse(script.textContent || '{}')); }",
    "  catch (error) { payloadById.set(id, null); }",
    "});",
    "const irFor = payload => payload && payload.x && payload.x.ir ? payload.x.ir : null;",
    "const layerRows = (ir, geom) => ir && Array.isArray(ir.layers) ? ir.layers.filter(layer => layer && layer.geom === geom).reduce((total, layer) => total + (Array.isArray(layer.data) ? layer.data.length : 0), 0) : 0;",
    "const allWidgetRecords = Array.from(widgets).map(widget => {",
    "  const id = widget.id || '';",
    "  const payload = payloadById.has(id) ? payloadById.get(id) : null;",
    "  const ir = irFor(payload);",
    "  return { id, payload, ir, widget, svgText: (widget.querySelector('svg') || {}).textContent || '', pointMarkCount: widget.querySelectorAll('circle.geom-point').length };",
    "});",
    "const payloadWidgetCount = allWidgetRecords.filter(record => record.payload !== null).length;",
    "const payloadMismatchCount = allWidgetRecords.filter(record => record.payload === null).length;",
    "const expectedContent = [];",
    "let freshnessMismatchCount = 0;",
    "Object.keys(expectedWidgets).forEach(region => {",
    "  const widgetsInRegion = regionWidgets[region] || [];",
    "  (expectedWidgets[region] || []).forEach((expected, index) => {",
    "    const widget = widgetsInRegion[index] || null;",
    "    const record = widget ? allWidgetRecords.find(item => item.widget === widget) : null;",
    "    const ir = record ? record.ir : null;",
    "    const reasons = [];",
    "    const payloadRows = expected.layerGeom ? layerRows(ir, expected.layerGeom) : layerRows(ir, 'point');",
    "    const liveText = record ? record.svgText : '';",
    "    const live = {",
    "      titlePresent: expected.title ? liveText.includes(expected.title) : null,",
    "      xLabelPresent: expected.x ? liveText.includes(expected.x) : null,",
    "      yLabelPresent: expected.y ? liveText.includes(expected.y) : null,",
    "      pointMarkCount: record ? record.pointMarkCount : 0,",
    "      sfGeometryCount: widget ? widget.querySelectorAll('.geom-sf').length : 0,",
    "      sfGroupCount: widget ? widget.querySelectorAll('.geom-sf-group').length : 0",
    "    };",
    "    if (!record) reasons.push('missing representative widget');",
    "    if (expected.title && (!ir || ir.title !== expected.title || !live.titlePresent)) reasons.push('title mismatch');",
    "    if (expected.x && (!ir || !ir.axes || !ir.axes.x || ir.axes.x.label !== expected.x || !live.xLabelPresent)) reasons.push('x-axis label mismatch');",
    "    if (expected.y && (!ir || !ir.axes || !ir.axes.y || ir.axes.y.label !== expected.y || !live.yLabelPresent)) reasons.push('y-axis label mismatch');",
    "    if (expected.layerGeom && (!ir || !ir.layers || !ir.layers.some(layer => layer && layer.geom === expected.layerGeom))) reasons.push('expected layer mismatch');",
    "    if (payloadRows !== expected.rows) reasons.push('payload row count mismatch');",
    "    if (!expected.layerGeom && record && record.pointMarkCount < payloadRows) reasons.push('live point mark count below payload rows');",
    "    if (expected.layerGeom && record && live.sfGeometryCount < 1) reasons.push('live sf geometry missing');",
    "    if (expected.layerGeom && record && live.sfGroupCount < 1) reasons.push('live sf group missing');",
    "    if (reasons.length) freshnessMismatchCount += 1;",
    "    expectedContent.push({ region, domOrder: index, widgetId: record ? record.id : null, expected, payloadRows, live, mismatchReasons: reasons });",
    "  });",
    "});",
    "return {",
    "  title: document.title || '',",
    "  widgetCount: widgets.length,",
    "  renderedSvgCount: svgs.length,",
    "  svgChildCounts: svgChildCounts,",
    "  widgetSvgChildCounts: widgetSvgChildCounts,",
    "  blankWidgetCount: widgetSvgChildCounts.filter(counts => counts.length === 0 || counts.some(n => n < ", threshold, ")).length,",
    "  geomSfCount: count('.geom-sf'),",
    "  crosstalkGroupCount: count('[data-gg2d3-crosstalk-group]'),",
    "  regionWidgetCounts: regionWidgetCounts,",
    "  regionSvgCounts: regionSvgCounts,",
    "  regionGeometryCounts: regionGeometryCounts,",
    "  regionGroupCounts: regionGroupCounts,",
    "  regionHeadingPresent: regionHeadingPresent,",
    "  browserVisualSmokeMarkerCount: browserVisualSmokeMarkerCount,",
    "  payloadWidgetCount: payloadWidgetCount,",
    "  payloadMismatchCount: payloadMismatchCount,",
    "  freshnessMismatchCount: freshnessMismatchCount,",
    "  expectedContent: expectedContent,",
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

  expected_widgets <- .PKGDOWN_VISUAL_EXPECTED_WIDGETS
  if (!identical(sf_outcome, "rendered")) {
    expected_widgets[["sf-family-maps-with-geom_sf"]] <- NULL
  }
  if (!ct_outcome %in% c("rendered", "rendered_unlinked_assets")) {
    expected_widgets[["linked-views-with-crosstalk"]] <- NULL
  }

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
    dom_summary <- eval_js_value(
      session,
      .pkgdown_visual_dom_summary_script(expected_widgets = expected_widgets)
    )

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

    # Exact marker contract: the generated article must retain the source
    # article's documented browser visual artifact path exactly once.
    testthat::expect_equal(
      as.integer(dom_summary$browserVisualSmokeMarkerCount),
      1L,
      label = "generated v1.13 summary must contain exactly one browser visual smoke marker"
    )

    # Named region contracts prevent unrelated page widgets from satisfying
    # the gate when a representative article section is missing or detached.
    for (region in names(.PKGDOWN_VISUAL_REGION_CONTRACTS)) {
      contract <- .PKGDOWN_VISUAL_REGION_CONTRACTS[[region]]
      testthat::expect_true(
        isTRUE(dom_summary$regionHeadingPresent[[region]]),
        label = paste0("generated article must contain heading/section #", region)
      )
      if (region == "basic-usage" ||
          (region == "linked-views-with-crosstalk" &&
           ct_outcome %in% c("rendered", "rendered_unlinked_assets"))) {
        testthat::expect_equal(
          as.integer(dom_summary$regionWidgetCounts[[region]]),
          contract$widgetCount,
          label = paste0("named region #", region, " must contain its current widget count")
        )
        testthat::expect_equal(
          as.integer(dom_summary$regionSvgCounts[[region]]),
          contract$svgCount,
          label = paste0("named region #", region, " must contain its current rendered SVG count")
        )
      }
    }

    # Every page widget must be associated with a current generated payload;
    # non-empty SVGs alone are not sufficient evidence of freshness.
    testthat::expect_equal(
      as.integer(dom_summary$payloadWidgetCount),
      as.integer(dom_summary$widgetCount),
      label = "every gg2d3 widget must have a matching application/json payload"
    )
    testthat::expect_equal(
      as.integer(dom_summary$payloadMismatchCount),
      0L,
      label = "widget-to-generated-payload association must have zero mismatches"
    )
    testthat::expect_equal(
      as.integer(dom_summary$freshnessMismatchCount),
      0L,
      label = "expected-content/live-DOM freshness comparison must have zero mismatches"
    )

    # sf outcome branch (D-06): require geom-sf elements when rendered; accept skip notice
    # when sf/GDAL is unavailable locally; fail on "missing" (neither rendered nor classified).
    if (sf_outcome == "rendered") {
      testthat::expect_gte(
        dom_summary$geomSfCount,
        1L,
        label = "sf widget must have rendered .geom-sf elements when sf outcome is rendered"
      )
      testthat::expect_equal(
        as.integer(dom_summary$regionWidgetCounts[["sf-family-maps-with-geom_sf"]]),
        .PKGDOWN_VISUAL_REGION_CONTRACTS[["sf-family-maps-with-geom_sf"]]$widgetCount,
        label = "rendered sf region must contain exactly one widget"
      )
      testthat::expect_equal(
        as.integer(dom_summary$regionSvgCounts[["sf-family-maps-with-geom_sf"]]),
        .PKGDOWN_VISUAL_REGION_CONTRACTS[["sf-family-maps-with-geom_sf"]]$svgCount,
        label = "rendered sf region must contain exactly one SVG"
      )
      testthat::expect_gte(
        as.integer(dom_summary$regionGeometryCounts[["sf-family-maps-with-geom_sf"]]),
        1L,
        label = "rendered sf region must contain .geom-sf geometry"
      )
      testthat::expect_gte(
        as.integer(dom_summary$regionGroupCounts[["sf-family-maps-with-geom_sf"]]),
        1L,
        label = "rendered sf region must contain a .geom-sf-group"
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
      testthat::expect_equal(
        as.integer(dom_summary$regionWidgetCounts[["linked-views-with-crosstalk"]]),
        .PKGDOWN_VISUAL_REGION_CONTRACTS[["linked-views-with-crosstalk"]]$widgetCount,
        label = "rendered Crosstalk region must contain exactly two widgets"
      )
      testthat::expect_equal(
        as.integer(dom_summary$regionSvgCounts[["linked-views-with-crosstalk"]]),
        .PKGDOWN_VISUAL_REGION_CONTRACTS[["linked-views-with-crosstalk"]]$svgCount,
        label = "rendered Crosstalk region must contain exactly two SVGs"
      )
    } else if (ct_outcome == "classified_skip") {
      has_ct_skip <- eval_js_value(
        session,
        "document.body.innerText.includes('PKGDOWN_CROSSTALK_OPTIONAL_SKIP')"
      )
      testthat::expect_true(
        has_ct_skip,
        label = "Crosstalk skip notice (PKGDOWN_CROSSTALK_OPTIONAL_SKIP) must be visible in page body text"
      )
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

    # Full-page screenshot evidence for D-05. The explicit html selector and
    # captureBeyondViewport option are part of the visual-regression contract.
    session$screenshot(
      filename = png_path,
      selector = "html",
      options = list(captureBeyondViewport = TRUE),
      delay = 0.5
    )
    testthat::expect_true(file.exists(png_path), label = "screenshot PNG artifact must exist")

    png_dimensions <- .pkgdown_visual_png_dimensions(png_path)
    testthat::expect_true(
      !is.null(png_dimensions),
      label = "full-page screenshot must have a readable PNG header"
    )
    if (!is.null(png_dimensions)) {
      testthat::expect_gt(
        png_dimensions$height,
        900L,
        label = "full-page screenshot height must exceed the 900px browser viewport"
      )
      dom_summary$pngWidth <- png_dimensions$width
      dom_summary$pngHeight <- png_dimensions$height
    }

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
