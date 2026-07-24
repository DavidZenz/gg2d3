# Phase 60: Pkgdown Visual Regression Depth - Research

**Researched:** 2026-07-24
**Domain:** R/chromote browser capture, htmlwidgets pkgdown page rendering, GitHub Actions CI integration
**Confidence:** HIGH (all findings verified against codebase; no external packages added)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Load `docs/articles/gg2d3.html` from the generated pkgdown site, not fresh in-test fixtures.
- **D-02:** Prerequisite of `pkgdown::build_site()` having run to populate `docs/` is accepted.
- **D-03:** CI visual capture runs inside the existing `pkgdown.yaml` workflow, added as a step after the build step. Artifact uploaded alongside or as a separate named artifact.
- **D-04:** Detection uses DOM-based SVG child count after page load + settle. Count SVG child elements (path, circle, rect, line, g with content) inside each widget region. Assert count >= threshold (e.g., 3) per expected non-empty widget.
- **D-05:** Capture produces a full-page PNG screenshot and a DOM summary JSON per page, following `helper-browser-visual.R` artifact pattern.
- **D-06:** sf widget regions pass if SVG child count >= threshold OR page contains `PKGDOWN_SF_OPTIONAL_SKIP` text. Mirrors existing pkgdown-site validation semantics.
- **D-07:** Capture targets `docs/articles/gg2d3.html` only (main article, not interactivity article).
- **D-08:** Interactivity article is out of scope for Phase 60.
- **D-09:** New test file: `tests/testthat/test-pkgdown-visual.R`. Reuses `helper-browser-visual.R`.
- **D-10:** Uses existing `GG2D3_BROWSER_VISUAL_SMOKE=true` opt-in env var. No new dedicated env var.
- **D-11:** Artifact output goes to `test_output/pkgdown-visual/` inside existing gitignored `test_output/`.

### Claude's Discretion

- Exact SVG child count threshold for "non-blank" assertions (must be documented in comments and adjustable).
- Settle interval (wait after page load) for chromote, following existing smoke test patterns.
- Exact chromote session setup for loading `file://` URL.

### Deferred Ideas (OUT OF SCOPE)

- Interactivity article capture (`gg2d3-interactivity.html`).
- Full perceptual-diff thresholds across a browser matrix (FUT-01).
- Pixel-brightness blank detection.
- External uptime/freshness monitoring for the public pkgdown site (FUT-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIS-01 | Maintainers can capture representative pkgdown article screenshots or equivalent browser evidence for pages that include core widgets, sf examples, Crosstalk examples, and visual-smoke links. | Covered by new `test-pkgdown-visual.R` that loads `docs/articles/gg2d3.html` in chromote, takes a full-page PNG screenshot, and writes a DOM summary JSON. The page contains 48 gg2d3 widgets including core, sf (or skip notice), and Crosstalk examples. |
| VIS-02 | The visual evidence gate detects blank, missing, or visibly stale widget regions in selected pkgdown pages before release. | Covered by DOM-based SVG child count assertion (threshold >= 3) per widget region. sf region uses `pkgdown_site_sf_outcome()` to decide whether to require SVG children or accept `PKGDOWN_SF_OPTIONAL_SKIP`. Crosstalk region is checked via `pkgdown_site_crosstalk_outcome()`. |
| VIS-03 | Visual-regression artifacts remain deterministic, ignored from package builds, and documented with clear local/CI skip behavior. | Artifacts go to `test_output/pkgdown-visual/` which is already covered by `.gitignore` pattern `^test_output/` and `.Rbuildignore` pattern `^test_output$`. Test uses `GG2D3_BROWSER_VISUAL_SMOKE=true` opt-in (same as existing smoke tests). CI uses `GG2D3_BROWSER_VISUAL_CI=true` to escalate skips to failures. |
</phase_requirements>

---

## Summary

Phase 60 adds browser-captured visual evidence for `docs/articles/gg2d3.html` (the generated pkgdown article) to supplement the existing text/marker-based validation in `test-pkgdown-site.R`. The deliverable is a single new testthat file that reuses existing helper infrastructure from `helper-browser-visual.R` and `helper-pkgdown-site.R` to: load the pkgdown article in chromote, count SVG children inside widget containers to detect blank/stale renderers, take a full-page PNG screenshot, and write a DOM summary JSON. The test is gated by the existing `GG2D3_BROWSER_VISUAL_SMOKE=true` env var and its CI step is added to `pkgdown.yaml` after the build step.

The key architectural insight is that this phase is almost entirely a **composition** problem, not a new-pattern problem. All required primitives already exist: `skip_browser_visual_smoke()`, `browser_visual_file_url()`, `eval_js_value()`, `with_chromote_session()`, `.browser_visual_selector_count()`, `pkgdown_site_sf_outcome()`, `pkgdown_site_crosstalk_outcome()`, and the artifact-writing pattern from `write_browser_visual_artifacts()`. The new test file adapts these to the pkgdown context (navigating to an existing built HTML file rather than a `saveWidget()` output, and targeting the `.gg2d3.html-widget` container selector rather than individual widget fixtures).

The CI integration follows the exact pattern established in `browser-visual-smoke.yaml`: locate Chrome binary, set env vars, run Rscript, upload artifacts as a named artifact. The new step is inserted into `pkgdown.yaml` between the existing "Validate generated pkgdown site" step and the "Upload pkgdown site artifact" step.

**Primary recommendation:** Implement `test-pkgdown-visual.R` as a single test that navigates to the pre-built pkgdown article, asserts widget SVG child counts, and writes artifacts to `test_output/pkgdown-visual/`. Extend `pkgdown.yaml` with a Chrome-locate step + a `Rscript` run step + an upload-artifact step, mirroring `browser-visual-smoke.yaml`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Visual capture (chromote, screenshot, DOM) | Test layer (R) | CI layer (YAML) | Chromote sessions run in testthat context; CI orchestrates the test run |
| SVG blank/stale detection | Test layer (R) | — | DOM-based JS evaluation inside the chromote session |
| sf region handling (rendered vs skip-notice) | Test layer (R) via existing helper | — | `pkgdown_site_sf_outcome()` already classifies the HTML; test reads that outcome to decide assertion |
| Artifact storage (PNG, JSON) | Test layer (R) | CI artifact upload (YAML) | Test writes to `test_output/pkgdown-visual/`; CI uploads the directory |
| Opt-in/CI gate | Env var convention | testthat skip/fail | `GG2D3_BROWSER_VISUAL_SMOKE=true` opts in; `GG2D3_BROWSER_VISUAL_CI=true` escalates skips |
| pkgdown site build prerequisite | CI layer (YAML) / local docs | — | `docs/articles/gg2d3.html` must exist before the test runs |

---

## Standard Stack

This phase installs no new packages. All required packages are already in `DESCRIPTION:Suggests`.

### Existing Packages Used

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chromote | >= 0.5.1 | Headless Chrome CDP session | Already in DESCRIPTION Suggests; already used in browser-visual-smoke tests |
| testthat | >= 3.0.0 | Test framework | Already in DESCRIPTION Suggests; project standard |
| jsonlite | (any) | JSON DOM summary writing | Used by existing `helper-browser-visual.R` |
| htmltools | (any) | HTML escaping for index.html | Used by existing `helper-browser-visual.R` |

### No New Packages Required

No new external packages are introduced. [VERIFIED: codebase grep of DESCRIPTION]

---

## Package Legitimacy Audit

No new packages are installed in this phase. All dependencies are already in the project.

| Package | Registry | Age | Verdict | Disposition |
|---------|----------|-----|---------|-------------|
| chromote | CRAN | 5+ yrs | OK (already in project) | Approved — already in use |
| testthat | CRAN | 15+ yrs | OK (already in project) | Approved — already in use |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious (SUS):** none

---

## Architecture Patterns

### System Architecture Diagram

```
Local developer or CI runner
        |
        v
[GG2D3_BROWSER_VISUAL_SMOKE=true set]
        |
        v
[test-pkgdown-visual.R]
  skip_browser_visual_smoke()  -->  skip if not opted-in or Chrome unavailable
  pkgdown_site_skip_if_generated_docs_unavailable()  -->  skip if docs/ not built
        |
        v
  [Chromote session: 1280x900]
        |
  session$go_to("file:///abs/path/docs/articles/gg2d3.html", delay = 2)
        |
  [Browser: load 13MB pkgdown page]
  [htmlwidgets DOMContentLoaded -> staticRender() -> D3 renders 48 SVGs]
        |
  poll: .browser_visual_wait_for_svg_count(session, min_count = 10, timeout = 30)
        |
  [DOM assertions]
  eval_js_value: count .gg2d3.html-widget elements
  eval_js_value: count .gg2d3.html-widget svg elements (one per rendered widget)
  eval_js_value: count SVG children in representative widgets (threshold >= 3)
        |
  [sf outcome branch]
  pkgdown_site_sf_outcome() == "rendered" -> assert sf widget SVG children >= 3
  pkgdown_site_sf_outcome() == "classified_skip" -> assert PKGDOWN_SF_OPTIONAL_SKIP text present
        |
  [Crosstalk outcome branch]
  pkgdown_site_crosstalk_outcome() in c("rendered","rendered_unlinked_assets") -> assert crosstalk widgets present
  pkgdown_site_crosstalk_outcome() == "classified_skip" -> accept
        |
  session$screenshot(filename = ".../pkgdown-visual/pkgdown-main-article.png", selector = "html")
  write JSON DOM summary to ".../pkgdown-visual/pkgdown-main-article-dom-summary.json"
  write browser log to ".../pkgdown-visual/pkgdown-main-article-browser-log.json"
        |
        v
  test passes / BVIS-PKG-01 passes
        |
        v
[pkgdown.yaml CI] uploads test_output/pkgdown-visual/ as "pkgdown-visual-{run_id}"
```

### Recommended Project Structure

No new directories required. New files only:

```
tests/testthat/
├── test-pkgdown-visual.R       # NEW: browser capture for pkgdown article (Phase 60)
├── helper-browser-visual.R     # EXISTING: reused unchanged
├── helper-pkgdown-site.R       # EXISTING: reused unchanged
└── test-pkgdown-site.R         # EXISTING: unchanged (marker-based tests remain)

test_output/
└── pkgdown-visual/             # CREATED AT TEST RUN TIME (gitignored)
    ├── pkgdown-main-article.png
    ├── pkgdown-main-article-dom-summary.json
    └── pkgdown-main-article-browser-log.json

.github/workflows/
└── pkgdown.yaml                # MODIFIED: add 3 new steps (locate-chrome, visual-capture, upload)
```

### Pattern 1: Navigate to Existing pkgdown File (No saveWidget)

The existing smoke test uses `save_browser_visual_widget()` to write a fresh HTML file, then navigates to it. For Phase 60, the HTML file already exists at `docs/articles/gg2d3.html`. Skip `save_browser_visual_widget()` and navigate directly.

**What:** Navigate to the pre-built pkgdown article using `browser_visual_file_url()`.
**When to use:** When the target HTML file is already on disk (pkgdown generated output).

```r
# Source: verified from helper-browser-visual.R lines 49-51
article_path <- file.path(root, "docs", "articles", "gg2d3.html")
url <- browser_visual_file_url(article_path)  # -> "file:///abs/path/docs/articles/gg2d3.html"
session$go_to(url, delay = 2)  # delay=2: extra settle after DOMContentLoaded+scripts
```

### Pattern 2: Wait for Multiple SVGs (pkgdown has 48 widgets)

The existing `.browser_visual_wait_for_svg()` waits until `svg count > 0`. For a full pkgdown page with 48 widgets, we need a higher threshold to ensure most widgets have rendered before asserting.

**What:** Poll until at least `min_count` SVGs are present, with a longer timeout.
**When to use:** When loading a full pkgdown article (not a single-widget HTML).

```r
# New helper to add to test-pkgdown-visual.R (not to shared helper — pkgdown-specific)
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

### Pattern 3: Per-Widget SVG Child Count DOM Script

Extends the existing `browser_visual_dom_summary_script()` pattern with pkgdown-specific counts.

**What:** JS evaluation that returns widget counts and a sample of per-widget SVG child counts.
**When to use:** After page settle in the pkgdown visual test.

```r
# Source: extends pattern from helper-browser-visual.R lines 224-248
pkgdown_visual_dom_summary_script <- function() {
  # SVG_CHILD_BLANK_THRESHOLD = 3 (documented; adjustable here)
  paste(
    "(() => {",
    "const count = s => document.querySelectorAll(s).length;",
    "const widgets = document.querySelectorAll('.gg2d3.html-widget');",
    "const svgs = document.querySelectorAll('.gg2d3.html-widget svg');",
    "const widgetSvgCounts = Array.from(svgs).map(svg =>",
    "  svg.querySelectorAll('path, circle, rect, line, g').length",
    ");",
    "return {",
    "  title: document.title || '',",
    "  widgetCount: widgets.length,",
    "  renderedSvgCount: svgs.length,",
    "  widgetSvgChildCounts: widgetSvgCounts,",
    "  blankWidgets: widgetSvgCounts.filter(n => n < 3).length,",  # threshold = 3
    "  bodyTextLength: document.body ? document.body.innerText.length : 0,",
    "  hasSfSkipNotice: document.body.innerText.includes('PKGDOWN_SF_OPTIONAL_SKIP')",
    "};",
    "})()"
  )
}
```

### Pattern 4: sf Outcome Branch for D-06

**What:** Decide whether to require SVG children or accept skip notice for the sf widget region.
**When to use:** After DOM summary is collected.

```r
# Source: pkgdown_site_sf_outcome() verified from helper-pkgdown-site.R lines 157-185
sf_outcome <- pkgdown_site_sf_outcome()  # "rendered", "classified_skip", or "missing"

if (sf_outcome == "rendered") {
  # Assert: sf widget has SVG children >= 3
  # Count `.geom-sf` elements or check widgetSvgChildCounts for sf widget index
  sf_child_count <- eval_js_value(session, "document.querySelectorAll('.geom-sf').length")
  testthat::expect_gte(sf_child_count, 1L,
    label = "sf widget must have rendered geom-sf elements when sf outcome is rendered")
} else if (sf_outcome == "classified_skip") {
  # Assert: skip notice text is present in page
  has_skip <- eval_js_value(session,
    "document.body.innerText.includes('PKGDOWN_SF_OPTIONAL_SKIP')")
  testthat::expect_true(has_skip, label = "sf skip notice must be visible in page")
} else {
  # "missing" = neither rendered nor classified — this is a failure
  testthat::fail(sprintf("sf region outcome is 'missing' in pkgdown article; sf_outcome: %s", sf_outcome))
}
```

### Pattern 5: CI Step in pkgdown.yaml (Modeled on browser-visual-smoke.yaml)

**What:** Three new steps added to `pkgdown.yaml` after the "Validate generated pkgdown site" step.
**When to use:** In CI, after `pkgdown::build_site()` has run.

```yaml
# Source: verified from .github/workflows/browser-visual-smoke.yaml (existing pattern)
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

      - name: Upload pkgdown visual artifacts
        if: always()
        uses: actions/upload-artifact@v6
        with:
          name: pkgdown-visual-${{ github.run_id }}
          path: test_output/pkgdown-visual/
          if-no-files-found: warn
          retention-days: 14
```

### Anti-Patterns to Avoid

- **Using `saveWidget()` for the pkgdown article:** The pkgdown HTML already exists at `docs/articles/gg2d3.html`. Do NOT call `saveWidget()` — navigate to the existing file directly with `browser_visual_file_url()`.
- **Using `.browser_visual_wait_for_svg()` with min_count=1:** The existing helper waits for the first SVG only. For a 13MB page with 48 widgets, this fires before most widgets render. Use a higher threshold (e.g., 10+) or a longer settle interval.
- **Hardcoding the docs path:** Use `pkgdown_site_skip_if_generated_docs_unavailable()` and `pkgdown_site_resolve_path()` from `helper-pkgdown-site.R` to resolve `docs/articles/gg2d3.html` portably — the test must work from both `tests/testthat/` working directory and the project root.
- **Modifying `helper-browser-visual.R`:** Add pkgdown-specific helpers directly in `test-pkgdown-visual.R` using file-private `.pkgdown_*` function prefixes. The shared helper is stable infrastructure and should not grow pkgdown-specific logic.
- **Setting `GG2D3_BROWSER_VISUAL_CI=true` globally in pkgdown.yaml job env:** The existing job-level env does not have this. Add it only to the specific "Run pkgdown visual capture" step's `env:` block, not the job-level `env:` block, to avoid affecting other steps.
- **Expecting sf SVG children when outcome is `classified_skip`:** The current local sf outcome is `classified_skip` (GDAL unavailable). The test must branch on `pkgdown_site_sf_outcome()` and accept the skip notice — never unconditionally assert sf SVG children.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chromote session setup and teardown | Custom session management | `with_chromote_session()` in `helper-browser-visual.R` | Already handles on.exit cleanup, width/height config |
| Opt-in guard + chromote availability check | Custom env var checks | `skip_browser_visual_smoke()` in `helper-browser-visual.R` | Already checks env var, chromote install, version (>= 0.5.1), Chrome binary, and session launch |
| DOM summary JSON writing | Custom JSON serialization | `.browser_visual_write_json()` + `write_browser_visual_artifacts()` in `helper-browser-visual.R` | Already handles artifact paths and JSON schema |
| sf/Crosstalk outcome classification | Custom text scanning | `pkgdown_site_sf_outcome()` + `pkgdown_site_crosstalk_outcome()` in `helper-pkgdown-site.R` | Already classifies rendered/classified_skip/missing |
| Chrome binary detection in CI | Custom shell logic | Copy exact `browser-visual-smoke.yaml` "Locate Chrome" step | Already validated on ubuntu-latest; covers google-chrome, chromium variants |
| JavaScript DOM selector counting | Custom chromote cdp calls | `eval_js_value()` + `.browser_visual_selector_count()` in `helper-browser-visual.R` | Already handle JSON serialization of selector strings |
| docs path resolution (local vs CI) | Custom path logic | `pkgdown_site_resolve_path()` + `pkgdown_site_skip_if_generated_docs_unavailable()` in `helper-pkgdown-site.R` | Already handles relative path resolution from test working dir |

**Key insight:** Phase 60 is a composition of already-proven patterns. Every primitive needed has been battle-tested in either `test-browser-visual-smoke.R` or `test-pkgdown-site.R`. The planner should resist the temptation to design new helpers — the test file should call existing helpers and adapt their outputs inline.

---

## Common Pitfalls

### Pitfall 1: pkgdown Page Not Built Before Test

**What goes wrong:** `pkgdown_site_skip_if_generated_docs_unavailable()` skips the test locally; CI fails because the test is skipped with `GG2D3_BROWSER_VISUAL_CI=true` (skip in CI mode escalates to fail).

**Why it happens:** The CI step must run AFTER `Build site` completes. If the step is placed before the build or if the build fails silently, `docs/articles/gg2d3.html` does not exist.

**How to avoid:** In `pkgdown.yaml`, ensure the new capture step has `needs:` or is placed after the build step in the YAML step order (YAML steps execute sequentially). Add an explicit `if: success()` condition if desired.

**Warning signs:** Test output: "generated docs site is not available" at the top of the test run.

### Pitfall 2: Settle Interval Too Short for 13MB pkgdown Page

**What goes wrong:** `go_to(url, delay=1)` fires after Page.loadEventFired, but the 13MB page with many external scripts may not have finished initializing all 48 htmlwidgets by then. DOM summary shows `renderedSvgCount: 0` or very low counts.

**Why it happens:** `go_to` delay is applied after `Page.loadEventFired`, but htmlwidgets' `DOMContentLoaded` handler fires async relative to load. With 48 widgets, D3 rendering takes additional microtask queue cycles.

**How to avoid:** Use `delay = 2` (vs. `delay = 1` for single-widget files). Additionally, poll with `.pkgdown_visual_wait_for_widgets(min_svg_count = 10)` before asserting. If the poll times out, the error message identifies the actual SVG count reached.

**Warning signs:** `renderedSvgCount` in DOM summary is < 10. `blankWidgets` count equals `widgetCount`.

### Pitfall 3: Relative Script Paths Not Resolving Under file:// Protocol

**What goes wrong:** The pkgdown article loads scripts via relative paths (`gg2d3_files/...`, `../deps/...`). Under `file://` in some Chrome security profiles, cross-directory relative paths may fail.

**Why it happens:** Chrome's file:// security model allows same-directory relative paths. Paths like `../deps/` resolve to sibling directories of the HTML file, which works in standard Chrome without `--allow-file-access-from-files`.

**How to avoid:** Use `browser_visual_file_url(normalizePath(article_path, mustWork=TRUE))` which produces an absolute path. Chrome resolves relative paths against the base URL. The existing smoke tests already use `selfcontained=FALSE` with external script references and this works correctly. [VERIFIED: codebase inspection of helper-browser-visual.R line 217 and test_output/browser-visual-smoke/]

**Warning signs:** Browser log contains "Failed to load resource" entries for `gg2d3_files/` scripts. `renderedSvgCount` is 0 and browser log has errors.

### Pitfall 4: Widget Container Selector Is Not `.html-widget-container`

**What goes wrong:** Using `.html-widget-container` as the CSS selector for gg2d3 widget divs finds zero elements, so SVG child count assertions fail.

**Why it happens:** htmlwidgets in pkgdown pages does NOT add an `.html-widget-container` wrapper. The widget div itself has `class="gg2d3 html-widget"` (or `class="gg2d3 html-widget html-fill-item"`). This is different from some documentation examples.

**How to avoid:** Use `.gg2d3.html-widget` as the selector. [VERIFIED: codebase inspection of docs/articles/gg2d3.html]

**Warning signs:** `widgetCount: 0` in DOM summary when there should be 48 widgets.

### Pitfall 5: sf SVG Child Count Assertion Fails Locally Due to classified_skip

**What goes wrong:** Test hardcodes `expect_gte(sf_svg_children, 3)` without branching on sf outcome. Locally (where sf is classified_skip), this fails because there are no sf SVG children.

**Why it happens:** The local environment has sf installed but GDAL unavailable, so sf R code falls back to the skip path and the pkgdown article shows the `PKGDOWN_SF_OPTIONAL_SKIP` notice instead of rendered sf widgets.

**How to avoid:** Always call `pkgdown_site_sf_outcome()` first and branch: require SVG children only when outcome is "rendered"; accept skip notice when outcome is "classified_skip". [VERIFIED: helper-pkgdown-site.R lines 157-185; current sf outcome confirmed as "classified_skip" via Rscript]

**Warning signs:** Test passes in CI (where sf renders) but fails locally.

### Pitfall 6: chromote Not Available in pkgdown.yaml CI Environment

**What goes wrong:** The "Run pkgdown visual capture" step calls `skip_browser_visual_smoke()` which checks for chromote and skips, then `browser_visual_skip_or_fail()` escalates to failure because `GG2D3_BROWSER_VISUAL_CI=true`.

**Why it happens:** `pkgdown.yaml` uses `extra-packages: any::pkgdown, local::.` with `needs: website`. The `DESCRIPTION` has `chromote` in `Suggests` but there is no `Config/Needs/website` field — so r-lib/actions does not install chromote automatically.

**How to avoid:** Add `any::chromote` to the `extra-packages:` list in the `setup-r-dependencies` step. Alternatively add `Config/Needs/pkgdown-visual: chromote` to DESCRIPTION and extend `needs:` — but the simpler approach is direct `extra-packages` extension. [VERIFIED: DESCRIPTION Suggests section; pkgdown.yaml extra-packages line]

**Warning signs:** CI fails with "chromote package not installed for browser visual smoke tests".

---

## Code Examples

### Full Test File Structure

```r
# Source: adapted from tests/testthat/test-browser-visual-smoke.R (verified)
# tests/testthat/test-pkgdown-visual.R

if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

# Load helpers if not already loaded by testthat
if (!exists("skip_browser_visual_smoke", mode = "function")) {
  for (f in c("tests/testthat/helper-browser-visual.R", "helper-browser-visual.R")) {
    if (file.exists(f)) { source(f); break }
  }
}
if (!exists("pkgdown_site_sf_outcome", mode = "function")) {
  for (f in c("tests/testthat/helper-pkgdown-site.R", "helper-pkgdown-site.R")) {
    if (file.exists(f)) { source(f); break }
  }
}

# SVG child count threshold for "non-blank" widget assertion.
# A gg2d3 widget with >= 3 SVG child elements (path/circle/rect/line/g) is considered rendered.
# Increase this value if blank-detection should be stricter; decrease only with documentation.
.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD <- 3L

# Artifact directory for pkgdown visual artifacts (parallel to browser-visual-smoke/)
pkgdown_visual_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "pkgdown-visual")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}

# ... helper functions ...

test_that("BVIS-PKG-01 pkgdown article browser capture detects rendered widgets and records evidence", {
  skip_browser_visual_smoke()
  pkgdown_site_skip_if_generated_docs_unavailable()

  # ... test body ...
})
```

### DOM Summary Script for pkgdown Page

```r
# Source: extends browser_visual_dom_summary_script() from helper-browser-visual.R lines 224-248
.pkgdown_visual_dom_summary_script <- function(threshold = 3L) {
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

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Text/marker-based pkgdown validation only | Text/marker + browser DOM-based SVG child count | Phase 60 | Catches blank widgets that have correct HTML structure but no rendered content |
| Single-widget HTML files in smoke tests | Full pkgdown article loaded as-built | Phase 60 | Proves the actual published HTML renders correctly end-to-end |

**Deprecated/outdated:**

- Pixel-brightness blank detection: considered and rejected in CONTEXT.md in favor of DOM-based SVG child count. Do not implement.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub Actions ubuntu-latest has Google Chrome pre-installed and discoverable at `google-chrome` or `google-chrome-stable` | CI Integration Pattern (Pattern 5) | CI step would fail to locate Chrome; test would skip/fail. Mitigation: the Locate Chrome step exits 0 even if Chrome is not found (non-fatal), so test would just skip without failing the step. | 
| A2 | `go_to(url, delay = 2)` + polling for min 10 SVGs with 30s timeout is sufficient for a 13MB pkgdown page with 48 widgets on ubuntu-latest | Pitfall 2, Pattern 2 | If insufficient, `blankWidgetCount` would be non-zero and test would fail. Mitigation: the settle interval is Claude's discretion (CONTEXT.md) and can be adjusted without interface changes. |

**Risk assessment:** Both assumptions are low-risk. A1 follows the established `browser-visual-smoke.yaml` pattern which already runs successfully on ubuntu-latest. A2 uses a longer settle than the existing smoke tests and has a generous poll timeout; the threshold is documented and adjustable.

---

## Open Questions

1. **chromote installation in pkgdown.yaml CI**
   - What we know: chromote is in DESCRIPTION Suggests; `setup-r-dependencies` with `needs: website` does not install Suggests automatically; `browser-visual-smoke.yaml` uses `extra-packages: local::.` with `needs: check` (which installs test dependencies).
   - What's unclear: Whether adding `any::chromote` to `extra-packages` in the pkgdown job is sufficient, or if it creates a dependency conflict with the website `needs:`.
   - Recommendation: Add `any::chromote` to the existing `extra-packages:` line: `extra-packages: any::pkgdown, any::chromote, local::.`. If this creates issues, add a separate install step instead.

2. **Full-page screenshot size on CI**
   - What we know: The pkgdown article is 13MB HTML and very long. A full-page screenshot of the entire rendered page could be very large.
   - What's unclear: Whether `selector = "html"` captures the full scrollable page height or just the viewport.
   - Recommendation: Use viewport screenshot (no selector, or `selector = "body"`) rather than full-page scroll capture. The PNG is for human review only (D-05); a viewport screenshot is sufficient evidence.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| chromote R package | `skip_browser_visual_smoke()` | Locally: YES | 0.5.1 (meets >= 0.5.1 requirement) | skip (opt-in test) |
| Google Chrome binary | chromote session | Locally: YES | `/Applications/Google Chrome.app/...` | skip via `skip_browser_visual_smoke()` |
| docs/articles/gg2d3.html | Test navigation target | Locally: YES (13MB, built 2026-06-01) | — | skip via `pkgdown_site_skip_if_generated_docs_unavailable()` |
| rprojroot (for `.test_output_dir()`) | Artifact path resolution | Locally: YES (in DESCRIPTION Suggests) | — | fallback path via `normalizePath(file.path(getwd(), "../../.."))` |

**Missing dependencies with no fallback:** None locally.

**CI notes:** chromote must be added to `extra-packages` in pkgdown.yaml. Chrome is pre-installed on ubuntu-latest. docs/ is built by the preceding "Build site" step.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat >= 3.0.0 |
| Config file | `Config/testthat/edition: 3` in DESCRIPTION |
| Quick run command | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'` |
| Full suite command | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true devtools::test()` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIS-01 | Capture screenshot and DOM summary of pkgdown article | browser/opt-in | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'` | NO: Wave 0 creates this file |
| VIS-02 | Detect blank/stale widget regions (SVG child count < threshold) | browser/opt-in | same as VIS-01 | NO: Wave 0 creates this file |
| VIS-03 | Artifacts in gitignored path, skip behavior documented | integration | same as VIS-01 | NO: Wave 0 creates this file |

### Sampling Rate

- **Per task commit:** No automated sampling (opt-in browser test; too slow for commit hooks)
- **Per wave merge:** `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'`
- **Phase gate:** Full suite green (`devtools::test()`) + manual `GG2D3_BROWSER_VISUAL_SMOKE=true` run before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-pkgdown-visual.R` — covers VIS-01, VIS-02, VIS-03
- [ ] `test_output/pkgdown-visual/` directory created at first test run (auto-created by helper)
- [ ] `.github/workflows/pkgdown.yaml` modified (Locate Chrome + Run capture + Upload artifact steps)

*(Existing test infrastructure is reused; only one new test file and workflow modification are needed)*

---

## Security Domain

This phase adds no new external network calls, no user input handling, and no authentication surfaces. The chromote session loads a local `file://` URL only. GitHub Actions artifact upload is an existing, trusted mechanism. Security enforcement applies minimally:

| ASVS Category | Applies | Control |
|---------------|---------|---------|
| V5 Input Validation | No | No user input; test selectors are hardcoded constants |
| V6 Cryptography | No | No crypto operations |
| V2 Authentication | No | No auth surfaces added |

No new threat patterns are introduced.

---

## Project Constraints (from CLAUDE.md)

- **R package development:** Use `devtools::load_all()` or `pkgload::load_all(quiet=TRUE)` (not `library()`).
- **Visual test output:** Always save to `test_output/` in the project root, not `/tmp/`. The new `test_output/pkgdown-visual/` directory follows this convention.
- **Testing:** Use `testthat::test_file()` for single file runs; `devtools::test()` for full suite.
- **D3 vendored locally:** Already present at `inst/htmlwidgets/lib/d3/d3.v7.min.js`. No change needed.
- **chromote availability:** May be unavailable if `devtools` is not installed; use `pkgload::load_all()` which has fewer dependencies.

---

## Sources

### Primary (HIGH confidence — verified against codebase)

- `tests/testthat/helper-browser-visual.R` — All chromote session primitives, artifact writing pattern, opt-in guard
- `tests/testthat/test-browser-visual-smoke.R` — Full smoke test pattern to follow (session setup, fixture loop, artifact writing)
- `tests/testthat/helper-pkgdown-site.R` — `pkgdown_site_sf_outcome()`, `pkgdown_site_crosstalk_outcome()`, path resolution helpers
- `tests/testthat/test-pkgdown-site.R` — Existing marker-based tests (not replaced by Phase 60)
- `.github/workflows/browser-visual-smoke.yaml` — Exact CI pattern: locate Chrome, Rscript run, upload-artifact
- `.github/workflows/pkgdown.yaml` — Current step order; insertion point for new steps
- `docs/articles/gg2d3.html` — Confirmed: 48 gg2d3 widgets, uses `.gg2d3.html-widget` container selector, `classified_skip` sf outcome, `rendered` Crosstalk outcome, 13MB page
- `DESCRIPTION` — chromote >= 0.5.1 already in Suggests; no new package needed
- `.gitignore`, `.Rbuildignore` — `test_output/` already excluded by both files

### Secondary (MEDIUM confidence — chromote API)

- chromote R package `ChromoteSession$go_to` source — Confirmed: waits for `Page.loadEventFired` then applies delay; [CITED: inspected via Rscript deparse()]

### Tertiary (LOW confidence — assumed from training knowledge)

- GitHub Actions ubuntu-latest has Google Chrome pre-installed [ASSUMED] — pattern follows `browser-visual-smoke.yaml` which already runs on ubuntu-latest; risk is low

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new packages; all reused from existing codebase
- Architecture: HIGH — all patterns verified against existing working test infrastructure
- Pitfalls: HIGH — all pitfalls derived from direct codebase inspection (selector names, file sizes, sf outcome)
- CI integration: MEDIUM — follows exact existing pattern from browser-visual-smoke.yaml; chromote installation path is an open question

**Research date:** 2026-07-24
**Valid until:** 2026-08-24 (stable infrastructure; only invalidated if helper-browser-visual.R or pkgdown article structure changes significantly)
