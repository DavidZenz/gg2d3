# Phase 36: Browser sf Smoke Harness - Research

**Researched:** 2026-05-20
**Domain:** R testthat + chromote browser smoke testing for htmlwidgets/D3 `geom_sf()` rendering
**Confidence:** HIGH for DOM rendering harness, MEDIUM for brush gesture automation

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Browser Runner Contract
- **D-01:** Use `chromote` as the first-choice browser smoke runner.
- **D-02:** Add `chromote` only as an optional `Suggests` dependency; do not add Playwright, Puppeteer, Selenium, or Node-based browser tooling in this phase.
- **D-03:** Browser tests must skip cleanly on CRAN, when Chrome/chromote is unavailable, or when optional spatial dependencies required by fixtures are unavailable.

### Fixture Matrix
- **D-04:** Cover the full v1.8 polygon regression fixture set in the browser harness: choropleth, stacked overlay, facet wrap, facet grid, skipped-row filtering, interactivity smoke, and sf zoom suppression.
- **D-05:** Reuse or extract the existing Phase 35 fixture generation patterns from `tests/testthat/test-sf-visual.R` rather than inventing an unrelated fixture style.
- **D-06:** Do not include future point/line sf fixtures in Phase 36 except as deferred placeholders. Point and line behavior belongs to Phase 37 after the polygon harness exists.

### Assertion Depth
- **D-07:** Assert live DOM behavior, not source strings or screenshots: `path.geom-sf` counts, non-empty `d`, stable `data-row-id`, finite `data-cx`/`data-cy`, and no page or console errors.
- **D-08:** Include minimal interaction smoke where reliable through `chromote`: centroid brush selection, sanitized brush callback payloads, sanitized tooltip/custom handler payloads, and preserved interactivity when `d3_zoom()` is suppressed for sf.
- **D-09:** If brush gesture automation is unreliable in `chromote`, planners should still require a documented gap plus the strongest feasible DOM/callback assertion before considering a new browser stack.

### Failure Artifacts
- **D-10:** Generate non-self-contained htmlwidgets output for browser fixtures.
- **D-11:** Leave useful failure artifacts for local debugging: generated HTML and captured console/page-error logs at minimum.
- **D-12:** Screenshots may be written as optional diagnostics if cheap, but screenshots and pixel diffs are not assertions and must not become the Phase 36 gate.

### Claude's Discretion

### Agent Discretion
- Exact helper names, file layout, polling implementation, artifact filenames, and `testthat` helper structure are left to the planning/execution agents, provided the decisions above and BRSF requirements are satisfied.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Playwright, Puppeteer, Selenium, and Node browser tooling remain deferred unless Phase 36 proves `chromote` cannot reliably cover required render or interaction checks.
- Screenshot or pixel-diff visual regression remains deferred; Phase 36 should use DOM and event behavior as its gate.
- Point and line sf browser fixtures belong in Phase 37/38 after non-polygon sf support exists.
- Projection-aware map zoom/pan remains out of scope; Phase 36 only verifies sf zoom suppression.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRSF-01 | Automated browser smoke tests render saved sf widgets and assert live DOM `path.geom-sf` nodes, non-empty path data, row ids, finite anchor attributes, and no page or console errors. | Use `chromote` sessions with `go_to()` plus `Runtime.evaluate()` DOM assertions; a local probe rendered two `path.geom-sf` nodes with row ids and finite anchors. [VERIFIED: local chromote probe] |
| BRSF-02 | Browser smoke tests cover polygon regressions for choropleths, stacked overlays, faceted panels, skipped-row filtering, tooltip/handler payload sanitization, centroid brushing, and sf zoom suppression. | Reuse `.phase35_sf_fixture_set()` for the six Phase 35 fixture names and add live-browser checks against `sf.js`, `brush.js`, `events.js`, `tooltip.js`, and `d3_zoom.R` contracts. [VERIFIED: tests/testthat/test-sf-visual.R; VERIFIED: inst/htmlwidgets/modules/*.js; VERIFIED: R/d3_zoom.R] |
| BRSF-03 | Browser fixture generation uses non-self-contained htmlwidgets output, skips cleanly when optional browser/spatial dependencies are unavailable, and leaves useful failure artifacts for local debugging. | Existing `.phase35_save_widget()` already calls `htmlwidgets::saveWidget(..., selfcontained = FALSE)` and writes under project-root `test_output/`; testthat and chromote docs support skip-on-CRAN and optional dependency skips. [VERIFIED: tests/testthat/test-sf-visual.R:38; CITED: https://search.r-project.org/CRAN/refmans/htmlwidgets/html/saveWidget.html; CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html; CITED: https://testthat.r-lib.org/reference/skip.html] |
</phase_requirements>

## Summary

Phase 36 should add a narrow test-only browser harness, not change production sf rendering. [VERIFIED: 36-CONTEXT.md D-01 through D-12] The harness should stay inside R/testthat, add `chromote` to `Suggests`, generate non-self-contained htmlwidgets fixtures, open them with headless Chrome, poll for rendered `path.geom-sf` elements, and assert DOM attributes plus captured browser errors. [VERIFIED: 36-CONTEXT.md; CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html; CITED: https://search.r-project.org/CRAN/refmans/htmlwidgets/html/saveWidget.html]

The implementation should reuse the Phase 35 polygon fixture generator rather than creating a parallel fixture DSL. [VERIFIED: 36-CONTEXT.md D-05; VERIFIED: tests/testthat/test-sf-visual.R:113] The current fixture set already covers choropleth, stacked overlay, `facet_wrap()`, `facet_grid()`, skipped-row filtering, interactivity smoke, and zoom suppression. [VERIFIED: tests/testthat/test-sf-visual.R:113-212]

**Primary recommendation:** Implement `tests/testthat/helper-browser-sf.R` plus `tests/testthat/test-sf-browser.R`; add `chromote (>= 0.5.1)` to `Suggests`; centralize browser open/poll/assert/artifact helpers so Phase 37 and Phase 38 can reuse them. [VERIFIED: DESCRIPTION:20; VERIFIED: local R packageVersion chromote 0.5.1; VERIFIED: .planning/research/SUMMARY.md]

## Project Constraints (from CLAUDE.md)

- Use the existing three-layer pipeline: R layer converts ggplot2 to IR, IR is JSON-serializable, and D3/htmlwidgets render SVG in the browser. [VERIFIED: CLAUDE.md]
- Use package development commands such as `devtools::load_all()`, `devtools::document()`, `devtools::test()`, and `testthat::test_file(...)`. [VERIFIED: CLAUDE.md]
- Keep D3 v7 vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`; the vendored file is D3 v7.9.0. [VERIFIED: CLAUDE.md; VERIFIED: inst/htmlwidgets/lib/d3/d3.v7.min.js header]
- Treat `R/gg2d3.R`, `R/as_d3_ir.R`, `inst/htmlwidgets/gg2d3.js`, and `inst/htmlwidgets/gg2d3.yaml` as core package files. [VERIFIED: CLAUDE.md]
- Preserve the existing `test_output/` visual artifact convention for generated HTML fixtures. [VERIFIED: tests/testthat/test-sf-visual.R:9-21; VERIFIED: .gitignore:10]
- No project-defined `.claude/skills/` or `.agents/skills/` directories were found. [VERIFIED: rtk ls .claude/skills .agents/skills]
- The repository currently has unrelated dirty/untracked files: `.planning/config.json`, `.claude/`, and `AGENTS.md`; planners/executors must not revert these. [VERIFIED: git status --short]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Fixture construction | R test layer | htmlwidgets | R owns ggplot/sf fixture data and `gg2d3()` widget creation; htmlwidgets serializes the widget to browser-loadable HTML. [VERIFIED: tests/testthat/test-sf-visual.R:113-212] |
| Browser navigation and DOM evaluation | Test harness / Browser | Browser DOM | `chromote` owns Chrome sessions, navigation, and JavaScript evaluation; assertions read live DOM after D3 has run. [CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html] |
| sf path rendering | D3 Layer | IR Layer | `sf.js` parses layer geometries, fits projection from `sfBBox`, and creates `path.geom-sf` nodes with row and anchor attributes. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js:67-140] |
| Tooltip and handler sanitization | D3 Layer | Test harness | `events.js` and `tooltip.js` strip underscore-prefixed private fields; browser tests should exercise actual event/callback payloads. [VERIFIED: inst/htmlwidgets/modules/events.js:56-64; VERIFIED: inst/htmlwidgets/modules/tooltip.js:117-126] |
| Centroid brush smoke | D3 Layer | Browser test harness | `brush.js` selects `path.geom-sf` by `data-cx`/`data-cy`; browser tests should verify the selected callback payload and opacity effects where reliable. [VERIFIED: inst/htmlwidgets/modules/brush.js:310-315; VERIFIED: inst/htmlwidgets/modules/brush.js:414-429] |
| Failure artifacts | Test harness | Filesystem | The harness should save HTML and captured browser logs under local ignored artifact paths. [VERIFIED: 36-CONTEXT.md D-11; VERIFIED: .gitignore:10-11] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 | Package runtime and tests | Current local R runtime for this repo. [VERIFIED: `rtk Rscript --version`] |
| testthat | installed 3.3.2; DESCRIPTION requires >= 3.0.0 | Test framework and skip guards | Existing package uses testthat edition 3 and `tests/testthat.R` runs `test_check("gg2d3")`. [VERIFIED: DESCRIPTION:20-27; VERIFIED: tests/testthat.R] |
| chromote | installed 0.5.1; add `chromote (>= 0.5.1)` to `Suggests` | Headless Chrome session, local HTML navigation, DOM JavaScript evaluation | User locked `chromote`; chromote docs expose `ChromoteSession$new()`, `go_to()`, `Runtime.evaluate()`, and screenshot helpers. [VERIFIED: 36-CONTEXT.md D-01; VERIFIED: local packageVersion chromote; CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html] |
| htmlwidgets | installed 1.6.4 | Save widgets as HTML fixtures | `saveWidget()` supports `selfcontained = FALSE`, which writes dependencies into an adjacent directory. [VERIFIED: local packageVersion htmlwidgets; CITED: https://search.r-project.org/CRAN/refmans/htmlwidgets/html/saveWidget.html] |
| D3 | vendored 7.9.0 | Browser SVG path rendering and brush behavior | The repo vendors D3 v7.9.0 and `sf.js` already uses `d3.geoPath()` and `d3.geoIdentity()`. [VERIFIED: inst/htmlwidgets/lib/d3/d3.v7.min.js header; VERIFIED: inst/htmlwidgets/modules/geoms/sf.js:89-93] |
| sf | installed 1.1.1; DESCRIPTION requires >= 1.0.0 | Optional spatial fixture construction | Existing sf tests and Phase 35 fixtures require `sf` and skip when unavailable. [VERIFIED: DESCRIPTION:23; VERIFIED: tests/testthat/test-sf-visual.R:269] |
| geojsonsf | installed 2.0.5; DESCRIPTION requires >= 2.0.0 | Optional sf GeoJSON serialization dependency | Existing sf tests skip when unavailable. [VERIFIED: DESCRIPTION:24; VERIFIED: tests/testthat/test-sf-ir.R:1-2] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rnaturalearth | installed 1.2.0 | Optional world multipolygon visual fixture | Keep optional; only needed for older world-hole visual fixture, not the minimum Phase 36 browser gate. [VERIFIED: DESCRIPTION:25; VERIFIED: tests/testthat/test-sf-visual.R:236-266] |
| jsonlite | installed 2.0.0 | JSON parsing/serialization support | Already imported by package; useful if helper code writes structured browser logs. [VERIFIED: DESCRIPTION:17; VERIFIED: local packageVersion jsonlite] |
| Chrome / Chromium | Google Chrome found at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | Browser executable for chromote | `chromote::find_chrome()` found local Chrome; tests must skip if this fails elsewhere. [VERIFIED: local `chromote::find_chrome()` probe; CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chromote` | Playwright/Puppeteer/Selenium | Explicitly deferred by user; would add Node/browser-driver stack outside R/testthat. [VERIFIED: 36-CONTEXT.md D-02; VERIFIED: 36-CONTEXT.md Deferred Ideas] |
| DOM assertions | Screenshots or pixel diffs | Explicitly not the Phase 36 gate; screenshots are optional diagnostics only. [VERIFIED: 36-CONTEXT.md D-12] |
| `htmlwidgets::saveWidget()` | Hand-written HTML fixture scaffolding | Existing Phase 35 helper already saves real package widgets and preserves htmlwidgets dependency layout. [VERIFIED: tests/testthat/test-sf-visual.R:38-47] |

**Installation:**
```r
# DESCRIPTION Suggests addition
Suggests:
    chromote (>= 0.5.1)
```

**Contributor setup:**
```r
install.packages(c("chromote", "sf", "geojsonsf"))
```

**Version verification:** Local R package versions were verified with `rtk Rscript --vanilla -e 'packageVersion(...)'`; `chromote`, `testthat`, `htmlwidgets`, `sf`, `geojsonsf`, and Chrome availability are current in this workspace as of 2026-05-20. [VERIFIED: local R packageVersion probe; VERIFIED: local chromote find_chrome probe]

## Architecture Patterns

### System Architecture Diagram

```text
testthat test
  -> skip guards: CRAN, chromote, Chrome, sf, geojsonsf
  -> Phase 35 fixture builder / extracted fixture helpers
  -> htmlwidgets::saveWidget(selfcontained = FALSE)
  -> chromote::ChromoteSession$go_to(file://fixture.html)
  -> render wait / poll loop
       -> success: path.geom-sf nodes exist
       -> timeout: save HTML + browser logs + optional screenshot
  -> Runtime.evaluate DOM assertions
       -> count, d, data-row-id, data-cx, data-cy
       -> facet panel counts and skipped-row row ids
       -> sanitized tooltip/handler/brush payloads
  -> assert no console errors and no unhandled exceptions
```

### Recommended Project Structure

```text
tests/testthat/
├── helper-browser-sf.R       # chromote session, skip, wait, artifact helpers [RECOMMENDED]
├── helper-sf-fixtures.R      # extracted Phase 35 fixture constructors if reuse requires sharing [RECOMMENDED]
├── test-sf-browser.R         # Phase 36 live browser smoke tests [RECOMMENDED]
├── test-sf-visual.R          # existing manual fixture generator; keep or delegate to shared helpers [VERIFIED]
└── test-sf-interactivity.R   # existing source-contract tests; keep as cheap complement [VERIFIED]
test_output/
└── browser-sf/               # generated HTML, logs, optional screenshots; ignored locally [RECOMMENDED]
```

### Pattern 1: Guarded Browser Test Entry

**What:** Begin each browser smoke `test_that()` with `skip_on_cran()`, `skip_if_not_installed("chromote")`, `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and a helper that skips when `chromote::find_chrome()` or session launch fails. [CITED: https://testthat.r-lib.org/reference/skip.html; CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html]

**When to use:** Every Phase 36 browser smoke test. [VERIFIED: 36-CONTEXT.md D-03]

**Example:**
```r
skip_on_cran()
skip_if_not_installed("chromote", "0.5.1")
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
skip_if(is.null(chrome), "Chrome/Chromium not available for chromote smoke test")
```

### Pattern 2: Reliable Navigation Plus Render Poll

**What:** Use `ChromoteSession$go_to()` for navigation, then poll the browser until `document.querySelectorAll("path.geom-sf").length` reaches the expected count. [CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html; CITED: https://rstudio.github.io/chromote/articles/commands-and-events.html]

**When to use:** Every saved widget browser assertion. [VERIFIED: local chromote probe]

**Example:**
```r
b <- chromote::ChromoteSession$new(width = 900, height = 700)
on.exit(b$close(), add = TRUE)
b$go_to(paste0("file://", normalizePath(html_path)), delay = 1)

paths <- b$Runtime$evaluate(
  'Array.from(document.querySelectorAll("path.geom-sf")).map(p => ({
    d: p.getAttribute("d"),
    row: p.getAttribute("data-row-id"),
    cx: p.getAttribute("data-cx"),
    cy: p.getAttribute("data-cy")
  }))',
  returnByValue = TRUE
)$result$value
```

### Pattern 3: Centralized Failure Artifacts

**What:** Keep generated HTML and browser logs even on failure; optionally save a screenshot as diagnosis, not as assertion. [VERIFIED: 36-CONTEXT.md D-11 and D-12]

**When to use:** In `on.exit()` or failure wrapper around each chromote test. [ASSUMED]

**Example:**
```r
with_browser_artifacts <- function(name, html_path, logs, code) {
  tryCatch(
    force(code),
    error = function(e) {
      writeLines(logs(), file.path(.test_output_dir(), "browser-sf", paste0(name, "-console.log")))
      stop(e)
    }
  )
}
```

### Anti-Patterns to Avoid

- **Adding a second browser ecosystem:** Do not add Playwright, Puppeteer, Selenium, or Node tooling unless the Phase 36 plan documents a proven `chromote` gap. [VERIFIED: 36-CONTEXT.md D-02 and D-09]
- **Testing saved HTML source instead of rendered DOM:** Static source checks cannot prove `path.geom-sf` nodes were created by D3 at runtime. [VERIFIED: .planning/research/SUMMARY.md; VERIFIED: Phase 35 verification noted runtime renderer creates `geom-sf` DOM]
- **Using screenshot diffs as the gate:** Screenshots can help debug but must not replace DOM/event assertions. [VERIFIED: 36-CONTEXT.md D-12]
- **Duplicating Phase 35 fixtures:** Reuse or extract `.phase35_sf_fixture_set()` patterns so fixture behavior stays aligned. [VERIFIED: 36-CONTEXT.md D-05; VERIFIED: tests/testthat/test-sf-visual.R:113-212]
- **Letting browser tests fail on CRAN because Chrome is absent:** chromote docs recommend not running Chrome-dependent tests on CRAN. [CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser driving | Custom WebSocket/CDP client | `chromote` | chromote wraps Chrome DevTools Protocol sessions for R and is locked by user decision. [VERIFIED: 36-CONTEXT.md D-01; CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html] |
| HTML fixture serialization | Manual HTML + dependency copying | `htmlwidgets::saveWidget(selfcontained = FALSE)` | htmlwidgets already handles widget dependency layout and current fixture helper uses it. [VERIFIED: tests/testthat/test-sf-visual.R:38-47; CITED: https://search.r-project.org/CRAN/refmans/htmlwidgets/html/saveWidget.html] |
| Geographic path assertions | Custom SVG path parser | DOM attribute presence + D3-rendered `d` string | D3 `geoPath()` produces SVG path strings from GeoJSON; Phase 36 only needs smoke-level non-empty output. [CITED: https://d3js.org/d3-geo/path] |
| Optional dependency handling | Manual `requireNamespace()` plus bespoke skip messages everywhere | `testthat::skip_if_not_installed()` and helper wrappers | testthat provides standard skip helpers for optional packages. [CITED: https://testthat.r-lib.org/reference/skip.html] |
| Tooltip/handler payload sanitizer | New sanitizer only for tests | Existing `events.js` and `tooltip.js` sanitizers | Production modules already remove underscore-prefixed private fields; browser tests should exercise them. [VERIFIED: inst/htmlwidgets/modules/events.js:56-64; VERIFIED: inst/htmlwidgets/modules/tooltip.js:117-126] |

**Key insight:** The hard part is not generating HTML; it is waiting for real htmlwidgets/D3 rendering and asserting browser state without making Chrome availability a package-check failure. [VERIFIED: local chromote probe; CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html]

## Common Pitfalls

### Pitfall 1: Render Race After Page Load
**What goes wrong:** `go_to()` completes but htmlwidgets `onRender()` work or D3 drawing is not visible yet. [ASSUMED]
**Why it happens:** chromote docs distinguish page load from later page work, and htmlwidgets callbacks can run after navigation. [CITED: https://rstudio.github.io/chromote/reference/ChromoteSession.html; VERIFIED: R/d3_zoom.R:86-96]
**How to avoid:** Add a bounded polling helper that repeatedly evaluates `document.querySelectorAll("path.geom-sf").length` and only asserts attributes after expected nodes exist. [VERIFIED: local chromote probe]
**Warning signs:** Intermittent zero-path results, especially on CI. [ASSUMED]

### Pitfall 2: Console Collection Starts Too Late
**What goes wrong:** The test misses early JavaScript errors during widget initialization. [ASSUMED]
**Why it happens:** CDP events must be subscribed/enabled before the event occurs. [CITED: https://rstudio.github.io/chromote/articles/commands-and-events.html; CITED: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/]
**How to avoid:** Initialize console/error collection before navigation and persist logs into failure artifacts. [CITED: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/]
**Warning signs:** Local browser visibly fails while test reports only DOM timeout. [ASSUMED]

### Pitfall 3: Brush Automation Is Flaky
**What goes wrong:** Pointer gestures do not fire the same `d3.brush()` end behavior under headless Chrome as in manual use. [ASSUMED]
**Why it happens:** The project brush module depends on D3 brush overlays and window-level pointer capture during drag. [VERIFIED: inst/htmlwidgets/modules/brush.js:131-134]
**How to avoid:** Plan the strongest reliable assertion first: either simulate a real drag over `.brush-overlay .overlay`, or invoke in-page brush behavior/selection if exposed; if neither is reliable, document the gap per D-09 and still assert centroid attributes plus sanitized callback path. [VERIFIED: 36-CONTEXT.md D-09; ASSUMED]
**Warning signs:** DOM path assertions pass but callback payload remains empty after gesture simulation. [ASSUMED]

### Pitfall 4: Sanitization Checked Only By Source Regex
**What goes wrong:** Source-contract tests pass while actual runtime callbacks expose `_geom` or `_centroid`. [VERIFIED: tests/testthat/test-sf-interactivity.R currently uses source checks]
**Why it happens:** The existing interactivity tests read module text; Phase 36 requires live DOM/event behavior. [VERIFIED: tests/testthat/test-sf-interactivity.R:31-102; VERIFIED: 36-CONTEXT.md D-07]
**How to avoid:** Browser tests should click or hover a `path.geom-sf` and inspect `window.__gg2d3_sf_click` or tooltip/custom formatter output. [VERIFIED: tests/testthat/test-sf-visual.R:193-197; VERIFIED: inst/htmlwidgets/modules/events.js:679-686]
**Warning signs:** No runtime assertion touches `window.__gg2d3_sf_click` or tooltip DOM. [ASSUMED]

### Pitfall 5: Facets Assert Global Counts Only
**What goes wrong:** A total path count passes while sf paths render into the wrong panel. [ASSUMED]
**Why it happens:** The IR has panel-local `sf_bbox` and facet metadata; a global DOM count cannot prove panel isolation. [VERIFIED: tests/testthat/test-sf-visual.R:154-170; VERIFIED: tests/testthat/test-sf-ir.R:200-224]
**How to avoid:** Query each `.panel` separately and assert expected per-panel counts for facet wrap and facet grid, including empty grid panels. [VERIFIED: tests/testthat/test-sf-visual.R:160-170]
**Warning signs:** `document.querySelectorAll("path.geom-sf").length` is the only facet assertion. [ASSUMED]

## Code Examples

### Live DOM Path Contract

```r
# Source: local chromote probe + ChromoteSession docs
paths <- b$Runtime$evaluate(
  'Array.from(document.querySelectorAll("path.geom-sf")).map(p => ({
    d: p.getAttribute("d"),
    row: p.getAttribute("data-row-id"),
    cx: Number(p.getAttribute("data-cx")),
    cy: Number(p.getAttribute("data-cy"))
  }))',
  returnByValue = TRUE
)$result$value

expect_true(length(paths) > 0)
expect_true(all(vapply(paths, function(x) nzchar(x$d), logical(1))))
expect_true(all(vapply(paths, function(x) nzchar(x$row), logical(1))))
expect_true(all(vapply(paths, function(x) is.finite(x$cx) && is.finite(x$cy), logical(1))))
```

### Fixture Save Contract

```r
# Source: tests/testthat/test-sf-visual.R:38-47 and htmlwidgets docs
htmlwidgets::saveWidget(
  widget,
  file = normalizePath(outpath, mustWork = FALSE),
  selfcontained = FALSE
)
```

### Browser Error Domains

```r
# Source: Chrome DevTools Protocol Runtime docs
# Planner should implement as a helper and verify exact chromote async wiring.
# Capture Runtime.consoleAPICalled types "error", "warning", "assert" and Runtime.exceptionThrown.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual Phase 35 HTML inspection in `test_output/phase35-*.html` | Automated Phase 36 chromote DOM smoke tests over the same fixture family | v1.9 Phase 36, 2026-05-20 planning | Protects polygon sf behavior before Phase 37 non-polygon expansion. [VERIFIED: .planning/milestones/v1.8-MILESTONE-AUDIT.md; VERIFIED: 36-CONTEXT.md] |
| Source-level interactivity checks in `test-sf-interactivity.R` | Keep source checks but add live callback/tooltip/brush assertions | v1.9 Phase 36 | Catches runtime regressions source regex cannot catch. [VERIFIED: tests/testthat/test-sf-interactivity.R; VERIFIED: 36-CONTEXT.md D-07] |
| Screenshot/manual confidence | DOM/event assertions with optional screenshots only on failure | v1.9 Phase 36 | Reduces flake and avoids pixel-diff gate. [VERIFIED: 36-CONTEXT.md D-12] |

**Deprecated/outdated:**
- Treating `test_output/phase35-*.html` existence as enough for sf browser confidence is outdated for v1.9; Phase 36 requires live DOM assertions. [VERIFIED: .planning/REQUIREMENTS.md BRSF-01 through BRSF-03]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A bounded poll loop over DOM queries will be stable enough on CI after `go_to()`. | Common Pitfalls / Pattern 2 | Browser tests may be flaky; planner should require timeout diagnostics and local/CI trial. |
| A2 | Brush can be tested through either pointer gestures or in-page brush movement without changing production code. | Common Pitfalls / Open Questions | BRSF-02 centroid brush may need a documented gap plus strongest feasible callback assertion per D-09. |
| A3 | Console/page error collection can be wired cleanly with chromote Runtime events in synchronous testthat helpers. | Common Pitfalls / Code Examples | BRSF-01 no-error assertion may need helper iteration or narrower accepted error scope. |

## Open Questions (RESOLVED)

1. **Brush gesture implementation**
   - What we know: `brush.js` uses `d3.brush()` and selects sf paths by `data-cx`/`data-cy`. [VERIFIED: inst/htmlwidgets/modules/brush.js:118-129; VERIFIED: inst/htmlwidgets/modules/brush.js:310-315]
   - Resolution: Plan 36-03 chooses programmatic brush movement through the existing `panelGroup.node().__gg2d3_brush.group.call(panelGroup.node().__gg2d3_brush.behavior.move, [[cx - 2, cy - 2], [cx + 2, cy + 2]])` path, using the first sf path's finite `data-cx` and `data-cy`. This avoids relying on headless pointer drag fidelity while still exercising the production D3 brush behavior and `on_brush` callback.
   - Fallback: If programmatic movement proves unreliable during execution, follow D-09: document the gap in the plan summary and keep the strongest feasible assertion over centroid attributes and sanitized callback plumbing before considering a non-`chromote` browser stack.

2. **Console/page error capture helper shape**
   - What we know: CDP Runtime exposes `consoleAPICalled` and `exceptionThrown` events, and chromote wraps CDP commands/events. [CITED: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/; CITED: https://rstudio.github.io/chromote/articles/commands-and-events.html]
   - Resolution: Plans 36-01 and 36-03 choose centralized helper functions in `tests/testthat/helper-browser-sf.R`: `browser_console_collector(session)`, `assert_no_browser_errors(logs)`, and `write_browser_failure_artifacts(name, html_path, logs, session = NULL)`. Runtime listeners must be registered before any `go_to()` call.
   - Failure policy: Treat `Runtime.consoleAPICalled` types `error` and `assert`, plus all `Runtime.exceptionThrown` entries, as test failures. Persist deterministic `<fixture>-console.log` and `<fixture>-page-errors.log` files. Warnings may be captured for diagnostics but are not the Phase 36 fail condition unless execution discovers package-specific warnings that should be promoted.

3. **Fixture file ownership**
   - What we know: `test_output/` and HTML fixture files are ignored locally. [VERIFIED: .gitignore:10; VERIFIED: .gitignore:50]
   - Resolution: Plans 36-01 and 36-02 choose `test_output/browser-sf/` via `browser_sf_artifact_dir()`, implemented as `file.path(.test_output_dir(), "browser-sf")`. Generated HTML, console logs, page-error logs, and optional screenshots should live under that subdirectory.
   - Ownership rule: Source fixtures should be shared through `tests/testthat/helper-sf-fixtures.R` when extraction is useful; generated fixture files remain ignored local artifacts and must not be committed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript | All test commands | yes | 4.6.0 | None needed. [VERIFIED: `rtk Rscript --version`] |
| testthat | Test harness | yes | 3.3.2 | None needed. [VERIFIED: local packageVersion testthat] |
| chromote | Browser smoke runner | yes | 0.5.1 | Skip tests if unavailable. [VERIFIED: local packageVersion chromote; VERIFIED: 36-CONTEXT.md D-03] |
| Google Chrome | chromote browser executable | yes | path found | Skip tests if unavailable. [VERIFIED: local `chromote::find_chrome()` probe] |
| sf | Spatial fixtures | yes | 1.1.1 | Skip sf browser tests if unavailable. [VERIFIED: local packageVersion sf; VERIFIED: tests/testthat/test-sf-visual.R:269] |
| geojsonsf | sf serialization | yes | 2.0.5 | Skip sf browser tests if unavailable. [VERIFIED: local packageVersion geojsonsf; VERIFIED: tests/testthat/test-sf-ir.R:1-2] |
| rnaturalearth | Optional world visual fixture | yes | 1.2.0 | Do not require for core Phase 36 fixture matrix. [VERIFIED: local packageVersion rnaturalearth; VERIFIED: tests/testthat/test-sf-visual.R:236-266] |

**Missing dependencies with no fallback:**
- None in this workspace. [VERIFIED: local package/version probes]

**Missing dependencies with fallback:**
- None in this workspace; planner must still include skip paths for CRAN and machines without Chrome/spatial packages. [VERIFIED: 36-CONTEXT.md D-03; CITED: https://rstudio.github.io/chromote/articles/example-cran-tests.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 installed; DESCRIPTION requires testthat >= 3.0.0. [VERIFIED: local packageVersion testthat; VERIFIED: DESCRIPTION:20-27] |
| Config file | `DESCRIPTION` with `Config/testthat/edition: 3`; `tests/testthat.R` calls `test_check("gg2d3")`. [VERIFIED: DESCRIPTION:26; VERIFIED: tests/testthat.R] |
| Quick run command | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` [RECOMMENDED] |
| Existing sf quick command | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-visual.R")'` [VERIFIED: tests/testthat/test-sf-visual.R:3] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::test()'` [VERIFIED: CLAUDE.md development commands] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BRSF-01 | Open saved sf widget, assert `path.geom-sf`, non-empty `d`, row ids, finite anchors, and no browser errors. | browser smoke | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "DOM")'` | no, Wave 0. [VERIFIED: rg browser file absence] |
| BRSF-02 | Cover choropleth, stacked overlay, facets, skipped rows, sanitized payloads, brush, and zoom suppression. | browser smoke + interaction smoke | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "fixture|interaction")'` | no, Wave 0. [VERIFIED: rg browser file absence] |
| BRSF-03 | Generate non-self-contained fixtures, skip optional deps cleanly, and preserve artifacts. | unit/browser helper | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R", filter = "artifact|skip")'` | no, Wave 0. [VERIFIED: rg browser file absence] |

### Sampling Rate

- **Per task commit:** Run the new browser test file when `chromote` and Chrome are available; otherwise verify skip output plus existing sf source tests. [VERIFIED: 36-CONTEXT.md D-03]
- **Per wave merge:** Run `test-sf-browser.R`, `test-sf-visual.R`, `test-sf-interactivity.R`, and `test-sf-ir.R`. [VERIFIED: canonical refs in 36-CONTEXT.md]
- **Phase gate:** Full suite green before `/gsd-verify-work`, with browser smoke either passing locally/CI or cleanly skipped only for documented optional dependency absence. [VERIFIED: 36-CONTEXT.md D-03]

### Wave 0 Gaps

- [ ] `tests/testthat/helper-browser-sf.R` - chromote skip/session/navigation/poll/log/artifact helpers. [RECOMMENDED]
- [ ] `tests/testthat/test-sf-browser.R` - BRSF-01 through BRSF-03 live browser smoke assertions. [RECOMMENDED]
- [ ] Optional extraction from `tests/testthat/test-sf-visual.R` into `tests/testthat/helper-sf-fixtures.R` if direct reuse would duplicate fixture code. [RECOMMENDED; VERIFIED: tests/testthat/test-sf-visual.R:24-212]
- [ ] Helper-level console/page error accumulation using CDP Runtime events. [CITED: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/]
- [ ] Brush gesture spike or documented D-09 fallback. [VERIFIED: 36-CONTEXT.md D-09]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication surface is introduced by local browser tests. [VERIFIED: Phase 36 scope] |
| V3 Session Management | no | No session state is introduced. [VERIFIED: Phase 36 scope] |
| V4 Access Control | no | Tests open local generated files only. [VERIFIED: Phase 36 scope] |
| V5 Input Validation | yes | Assert tooltip, custom handler, and brush payloads exclude underscore-prefixed renderer internals. [VERIFIED: inst/htmlwidgets/modules/events.js:56-64; VERIFIED: inst/htmlwidgets/modules/tooltip.js:117-126; VERIFIED: inst/htmlwidgets/modules/brush.js:400-408] |
| V6 Cryptography | no | No cryptographic behavior is introduced. [VERIFIED: Phase 36 scope] |

### Known Threat Patterns for Browser Fixture Tests

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Private renderer state leaks through callbacks (`_geom`, `_centroid`) | Information Disclosure | Runtime browser assertions for sanitized tooltip, handler, and brush payloads. [VERIFIED: tests/testthat/test-sf-interactivity.R:31-102] |
| Browser test executes stale or wrong fixture file | Tampering | Use deterministic artifact paths and assert the expected widget/fixture name before navigation. [ASSUMED] |
| Console/page errors hidden by passing DOM count | Repudiation | Capture and persist browser error logs; fail tests on runtime errors. [CITED: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/36-browser-sf-smoke-harness/36-CONTEXT.md` - locked runner, fixture, assertion, artifact, and deferred-scope decisions. [VERIFIED]
- `.planning/REQUIREMENTS.md` - BRSF-01, BRSF-02, BRSF-03 requirements. [VERIFIED]
- `.planning/ROADMAP.md` - Phase 36 goal and success criteria. [VERIFIED]
- `.planning/STATE.md` - current Phase 36 state and known chromote risks. [VERIFIED]
- `.planning/research/SUMMARY.md` - milestone stack and Phase 36 risk summary. [VERIFIED]
- `DESCRIPTION` - current dependency surface. [VERIFIED]
- `tests/testthat/test-sf-visual.R` - Phase 35 fixtures and non-self-contained save helper. [VERIFIED]
- `tests/testthat/test-sf-interactivity.R` - existing source-contract tests for sf selectors and sanitization. [VERIFIED]
- `tests/testthat/test-sf-ir.R` - sf row identity, skipped-row, stacked bbox, and diagnostics coverage. [VERIFIED]
- `inst/htmlwidgets/modules/geoms/sf.js` - renderer DOM contract. [VERIFIED]
- `inst/htmlwidgets/modules/brush.js`, `events.js`, `tooltip.js` - interaction and sanitization contracts. [VERIFIED]
- `R/d3_zoom.R` - sf zoom suppression behavior. [VERIFIED]
- Local chromote probe - saved a temporary non-self-contained sf widget, opened it through `file://`, and observed two live `path.geom-sf` nodes with row ids `1,2` and finite anchors. [VERIFIED]

### Primary Docs (HIGH confidence)

- https://rstudio.github.io/chromote/reference/ChromoteSession.html - session creation, navigation, evaluation, screenshots. [CITED]
- https://rstudio.github.io/chromote/articles/example-cran-tests.html - chromote/Chrome tests should not run on CRAN; use `skip_on_cran()` and CI. [CITED]
- https://rstudio.github.io/chromote/articles/commands-and-events.html - CDP command/event behavior and reliable event timing concerns. [CITED]
- https://testthat.r-lib.org/reference/skip.html - `skip_on_cran()` and `skip_if_not_installed()`. [CITED]
- https://search.r-project.org/CRAN/refmans/htmlwidgets/html/saveWidget.html - `saveWidget()` and `selfcontained` behavior. [CITED]
- https://d3js.org/d3-geo/path - `geoPath()` renders GeoJSON to SVG path data and supports centroids/point radius. [CITED]
- https://chromedevtools.github.io/devtools-protocol/tot/Runtime/ - `Runtime.consoleAPICalled` and `Runtime.exceptionThrown` events. [CITED]

### Secondary (MEDIUM confidence)

- `.planning/research/STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, and `PITFALLS.md` - prior milestone research synthesized into `.planning/research/SUMMARY.md`; use as background, with Phase 36 CONTEXT taking precedence. [VERIFIED]

### Tertiary (LOW confidence)

- None used as authority. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - locked by CONTEXT, current local package versions, and official docs. [VERIFIED]
- Architecture: HIGH - current Phase 35 fixtures and D3 modules expose concrete contracts. [VERIFIED]
- Pitfalls: MEDIUM - render wait was locally verified; brush gesture and console collection helper details still need implementation validation. [VERIFIED: local chromote probe; ASSUMED]

**Research date:** 2026-05-20
**Valid until:** 2026-06-19 for local code contracts; re-check chromote/testthat docs before changing browser-helper APIs. [ASSUMED]
