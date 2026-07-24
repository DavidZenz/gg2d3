# Phase 60: Pkgdown Visual Regression Depth - Pattern Map

**Mapped:** 2026-07-24
**Files analyzed:** 2 (1 new test file, 1 modified CI workflow)
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/testthat/test-pkgdown-visual.R` | test | request-response (chromote DOM eval) | `tests/testthat/test-browser-visual-smoke.R` | exact |
| `.github/workflows/pkgdown.yaml` | config (CI workflow) | event-driven (GitHub Actions) | `.github/workflows/browser-visual-smoke.yaml` | exact |

---

## Pattern Assignments

### `tests/testthat/test-pkgdown-visual.R` (test, browser DOM evaluation)

**Analog:** `tests/testthat/test-browser-visual-smoke.R`

**Helper sourcing pattern** (lines 1-15 of analog):
```r
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
# Also source helper-pkgdown-site.R the same way, guarding on pkgdown_site_sf_outcome
```

**Artifact directory pattern** (analog: `browser_visual_artifact_dir()` in helper-browser-visual.R lines 23-27):
```r
# Parallel artifact dir for pkgdown visual — defined in test file itself (not shared helper)
pkgdown_visual_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "pkgdown-visual")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}
```
Note: `.test_output_dir()` is defined in `helper-sf-fixtures.R`; the helper sourcing chain in `helper-browser-visual.R` lines 6-15 loads it automatically.

**Opt-in guard pattern** (analog: lines 293-294 of test-browser-visual-smoke.R):
```r
test_that("BVIS-PKG-01 pkgdown article browser capture detects rendered widgets and records evidence", {
  skip_browser_visual_smoke()                            # checks env var + chromote availability
  pkgdown_site_skip_if_generated_docs_unavailable()     # checks docs/articles/gg2d3.html exists
  # ...
})
```

**Session setup pattern** (analog: lines 309-321 of test-browser-visual-smoke.R):
```r
with_chromote_session({
  # session is injected into this block's environment
  logs <- browser_visual_console_collector(session)

  # Navigate to pre-built pkgdown article (NO saveWidget — file already exists)
  article_path <- pkgdown_site_resolve_path("docs/articles/gg2d3.html")
  url <- browser_visual_file_url(normalizePath(article_path, mustWork = TRUE))
  session$go_to(url, delay = 2)  # delay=2 for 13MB page, longer than smoke test's delay=1

  # Poll until at least 10 SVGs present (not just count > 0 like .browser_visual_wait_for_svg)
  .pkgdown_visual_wait_for_widgets(session, min_svg_count = 10, timeout = 30)

  # DOM summary + assertions + artifacts...
}, width = 1280, height = 900)
```

**Wait-for-widgets poll pattern** (new, file-private — DO NOT add to shared helper):
```r
.pkgdown_visual_wait_for_widgets <- function(session, min_svg_count = 10, timeout = 30) {
  deadline <- Sys.time() + timeout
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
```
Note: `%||%` is defined in `helper-browser-visual.R` lines 17-21.

**DOM summary script pattern** (analog: `browser_visual_dom_summary_script()` in helper-browser-visual.R lines 224-248, extended for pkgdown page):
```r
# SVG_CHILD_BLANK_THRESHOLD = 3L (documented constant; adjust here without interface change)
.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD <- 3L

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
```

**DOM eval + assertion pattern** (analog: `eval_js_value()` + selector loop in capture_browser_visual_fixture lines 421-432):
```r
dom_summary <- eval_js_value(session, .pkgdown_visual_dom_summary_script())

# Core widget count assertion
testthat::expect_gte(
  dom_summary$renderedSvgCount,
  10L,
  label = "pkgdown article must render at least 10 gg2d3 SVG widgets"
)
testthat::expect_equal(
  dom_summary$blankWidgetCount,
  0L,
  label = "all rendered gg2d3 SVG widgets must have >= 3 SVG child elements"
)
```

**sf outcome branch pattern** (analog: `pkgdown_site_sf_outcome()` in helper-pkgdown-site.R lines 157-185):
```r
sf_outcome <- pkgdown_site_sf_outcome()   # "rendered", "classified_skip", or "missing"

if (sf_outcome == "rendered") {
  testthat::expect_gte(
    dom_summary$geomSfCount, 1L,
    label = "sf widget must have rendered .geom-sf elements when sf outcome is rendered"
  )
} else if (sf_outcome == "classified_skip") {
  has_skip <- eval_js_value(session,
    "document.body.innerText.includes('PKGDOWN_SF_OPTIONAL_SKIP')")
  testthat::expect_true(has_skip, label = "sf skip notice must be visible in page")
} else {
  testthat::fail(sprintf("sf region outcome is 'missing'; sf_outcome: %s", sf_outcome))
}
```

**Crosstalk outcome branch pattern** (analog: `pkgdown_site_crosstalk_outcome()` in helper-pkgdown-site.R lines 249-280):
```r
ct_outcome <- pkgdown_site_crosstalk_outcome()
if (ct_outcome %in% c("rendered", "rendered_unlinked_assets")) {
  ct_count <- .browser_visual_selector_count(session, "[data-gg2d3-crosstalk-group]")
  testthat::expect_gte(
    as.integer(ct_count), 1L,
    label = "Crosstalk widgets must be present in page when outcome is rendered"
  )
} else if (ct_outcome == "classified_skip") {
  # accept — skip notice is in place
} else {
  testthat::fail(sprintf("Crosstalk region outcome is 'missing'; ct_outcome: %s", ct_outcome))
}
```

**Screenshot + artifact writing pattern** (analog: `write_browser_visual_artifacts()` in helper-browser-visual.R lines 344-388; adapted for pkgdown — no html file to copy, no fixture id):
```r
# Artifact paths (pkgdown-specific — not using browser_visual_paths() which appends .html)
out_dir <- pkgdown_visual_artifact_dir()
png_path     <- file.path(out_dir, "pkgdown-main-article.png")
json_path    <- file.path(out_dir, "pkgdown-main-article-dom-summary.json")
log_path     <- file.path(out_dir, "pkgdown-main-article-browser-log.json")

# Screenshot (viewport; selector omitted for viewport-only capture)
session$screenshot(filename = png_path, delay = 0.5)
testthat::expect_true(file.exists(png_path))

# DOM summary JSON
jsonlite::write_json(dom_summary, path = json_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
testthat::expect_true(file.exists(json_path))

# Browser log JSON
entries <- browser_visual_logs(logs)
jsonlite::write_json(
  list(
    status = "passed",
    article_path = normalizePath(article_path, mustWork = FALSE),
    screenshot_path = normalizePath(png_path, mustWork = FALSE),
    dom_summary_path = normalizePath(json_path, mustWork = FALSE),
    logs = entries
  ),
  path = log_path,
  auto_unbox = TRUE, pretty = TRUE, null = "null"
)
testthat::expect_true(file.exists(log_path))
```

**Browser error assertion pattern** (analog: `assert_no_browser_visual_errors()` in helper-browser-visual.R lines 313-332):
```r
assert_no_browser_visual_errors(logs)
```

---

### `.github/workflows/pkgdown.yaml` (config, CI workflow modification)

**Analog:** `.github/workflows/browser-visual-smoke.yaml`

**Locate Chrome step** (analog: lines 26-40 of browser-visual-smoke.yaml — NOTE: in pkgdown.yaml the step exits 0 when Chrome not found, not exit 1, to be non-fatal):
```yaml
      - name: Locate Chrome for chromote (pkgdown visual)
        shell: bash
        run: |
          set -euo pipefail
          for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
            if command -v "${candidate}" >/dev/null 2>&1; then
              chrome_path="$(command -v "${candidate}")"
              echo "CHROMOTE_CHROME=${chrome_path}" >> "${GITHUB_ENV}"
              "${chrome_path}" --version
              exit 0
            fi
          done
          echo "No Chrome/Chromium found; pkgdown visual capture will be skipped"
          # Non-fatal: test will skip via skip_browser_visual_smoke() if Chrome unavailable
```

**Run Rscript step** (analog: lines 41-51 of browser-visual-smoke.yaml — NOTE: env vars set at step level only, NOT job level; `GG2D3_BROWSER_VISUAL_CI=true` must NOT be added to the job-level env block):
```yaml
      - name: Run pkgdown visual capture
        env:
          NOT_CRAN: "true"
          GG2D3_BROWSER_VISUAL_SMOKE: "true"
          GG2D3_BROWSER_VISUAL_CI: "true"
        shell: bash
        run: |
          Rscript --vanilla -e '
            tryCatch({
              pkgload::load_all(quiet = TRUE)
              res <- testthat::test_file("tests/testthat/test-pkgdown-visual.R")
              df <- as.data.frame(res)
              if (any(df$failed > 0) || any(df$error)) quit(status = 1)
            }, error = function(e) { message("FATAL: ", conditionMessage(e)); quit(status = 1) })
          '
```

**Upload artifact step** (analog: lines 53-60 of browser-visual-smoke.yaml):
```yaml
      - name: Upload pkgdown visual artifacts
        if: always()
        uses: actions/upload-artifact@v6
        with:
          name: pkgdown-visual-${{ github.run_id }}
          path: test_output/pkgdown-visual/
          if-no-files-found: warn
          retention-days: 14
```

**Insertion point in pkgdown.yaml:** After "Validate generated pkgdown site" step (line 71-72) and before "Upload pkgdown site artifact" step (line 74). The three new steps go in this order:
1. Locate Chrome for chromote (pkgdown visual)
2. Run pkgdown visual capture
3. Upload pkgdown visual artifacts

**chromote installation:** Add `any::chromote` to the existing `extra-packages:` line in the `setup-r-dependencies` step (currently line 33: `extra-packages: any::pkgdown, local::.`) → change to: `extra-packages: any::pkgdown, any::chromote, local::.`

---

## Shared Patterns

### Opt-in Guard + CI Escalation
**Source:** `tests/testthat/helper-browser-visual.R` lines 53-69
**Apply to:** `test-pkgdown-visual.R` (call `skip_browser_visual_smoke()` at start of every test)
```r
# skip_browser_visual_smoke() checks all of:
# 1. GG2D3_BROWSER_VISUAL_SMOKE=true env var
# 2. chromote package installed (>= 0.5.1)
# 3. Chrome binary available
# 4. Session can launch
# If GG2D3_BROWSER_VISUAL_CI=true, any skip escalates to stop()
```

### Chromote Session + Console Logging
**Source:** `tests/testthat/helper-browser-visual.R` lines 190-211 (`with_chromote_session`, `eval_js_value`)
**Apply to:** `test-pkgdown-visual.R` — use `with_chromote_session({ ... }, width=1280, height=900)` and `eval_js_value(session, script)` for all DOM queries.

### JSON Artifact Writing
**Source:** `tests/testthat/helper-browser-visual.R` lines 334-342 (`.browser_visual_write_json`)
**Apply to:** `test-pkgdown-visual.R` — use `jsonlite::write_json(..., auto_unbox=TRUE, pretty=TRUE, null="null")` for both dom_summary and browser log JSON files.

### CSS Selector Counting
**Source:** `tests/testthat/helper-browser-visual.R` lines 401-407 (`.browser_visual_selector_count`)
**Apply to:** `test-pkgdown-visual.R` — use `.browser_visual_selector_count(session, selector)` for per-widget counts (e.g. Crosstalk widget count).

### pkgdown Path Resolution
**Source:** `tests/testthat/helper-pkgdown-site.R` lines 50-71 (`pkgdown_site_resolve_path`)
**Apply to:** `test-pkgdown-visual.R` — use `pkgdown_site_resolve_path("docs/articles/gg2d3.html")` rather than hardcoding paths; this handles both local and CI working directories.

---

## Critical Selector Notes

- **Widget container selector:** Use `.gg2d3.html-widget` (NOT `.html-widget-container` — htmlwidgets in pkgdown does not add that wrapper). Verified from `docs/articles/gg2d3.html`.
- **SVG selector for polling:** `'.gg2d3.html-widget svg'` counts rendered SVGs inside widget divs.
- **sf geom selector:** `.geom-sf` counts rendered sf geometry elements.
- **Crosstalk selector:** `[data-gg2d3-crosstalk-group]` (from `pkgdown_site_generated_crosstalk_asset_markers` in helper-pkgdown-site.R line 28).

---

## No Analog Found

All files have close analogs. No files require falling back to RESEARCH.md patterns only.

---

## Anti-Patterns to Avoid (from RESEARCH.md)

- Do NOT call `saveWidget()` — navigate to the pre-existing `docs/articles/gg2d3.html` directly.
- Do NOT use `.browser_visual_wait_for_svg()` (waits for count > 0); use the new `.pkgdown_visual_wait_for_widgets()` with `min_svg_count = 10`.
- Do NOT add pkgdown-specific helpers to `helper-browser-visual.R`; put file-private helpers (`.pkgdown_*` prefix) in `test-pkgdown-visual.R` itself.
- Do NOT set `GG2D3_BROWSER_VISUAL_CI=true` at the pkgdown.yaml job level; add it only to the specific step's `env:` block.
- Do NOT unconditionally assert sf SVG children — always branch on `pkgdown_site_sf_outcome()` first.

---

## Metadata

**Analog search scope:** `tests/testthat/`, `.github/workflows/`
**Files scanned:** 4 (helper-browser-visual.R, test-browser-visual-smoke.R, helper-pkgdown-site.R, browser-visual-smoke.yaml, pkgdown.yaml)
**Pattern extraction date:** 2026-07-24
