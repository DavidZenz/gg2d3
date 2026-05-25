# Phase 48: Browser Visual Smoke Coverage - Research

**Researched:** 2026-05-25
**Domain:** R/testthat/chromote browser artifact generation for htmlwidgets
**Confidence:** HIGH for local code patterns; MEDIUM for sf execution in this machine because `sf` is not installed

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Artifact Contract
- **D-01:** Produce browser screenshots plus the supporting HTML and browser logs for each visual smoke fixture.
- **D-02:** Generate a small local index or report that ties each fixture to its screenshot, HTML, logs, and status. The report is for local maintainer inspection and must live under ignored output.
- **D-03:** Keep generated visual artifacts out of package sources and commits. The established `test_output/` ignored directory is the default destination unless planning finds a stronger existing convention.

### Fixture Coverage Set
- **D-04:** Use a representative v1.12 visual matrix rather than a minimal smoke-only set or exhaustive historical coverage.
- **D-05:** The matrix should cover core Cartesian geoms, facets, interactivity-facing marks, sf geometry marks, ordinary `geom_polygon()`, and `geom_sf_text()` / `geom_sf_label()` annotations.
- **D-06:** Favor fixtures that expose distinct rendering surfaces and recent regression risk over many near-duplicates.

### Run And Skip Policy
- **D-07:** Provide an explicit maintainer command for visual smoke execution.
- **D-08:** Keep normal package/test workflows optional and skip-friendly. If the visual smoke also plugs into testthat, it should be gated by an opt-in environment variable.
- **D-09:** Skip messages must identify the unavailable optional dependency or browser condition, including Chrome/Chromium, `chromote`, `sf`, and `geojsonsf` where relevant.

### Failure Evidence
- **D-10:** On failure, write a screenshot, copied HTML fixture, browser log, and DOM summary where technically feasible.
- **D-11:** Failure artifacts should be sufficient to diagnose blank output, misplaced elements, missing marks, and browser runtime errors without immediately rerunning the smoke command.

### the agent's Discretion
- Exact command spelling, helper names, fixture filenames, report format, screenshot dimensions, and DOM summary schema are left to planning/implementation.
- The planner may reuse or consolidate existing browser helper functions if doing so reduces duplication without weakening current polygon or sf browser tests.

### Claude's Discretion
- Exact command spelling, helper names, fixture filenames, report format, screenshot dimensions, and DOM summary schema are left to planning/implementation.
- The planner may reuse or consolidate existing browser helper functions if doing so reduces duplication without weakening current polygon or sf browser tests.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- CI-enforced screenshot diffs and cross-platform pixel thresholds remain future work after local visual artifacts stabilize.
- Committed golden/reference images remain future work unless Phase 48 proves outputs are stable enough across local environments.
- Renderer architecture changes and geometry edge-case fixes are out of scope for Phase 48 and belong to Phases 49-51.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIS-01 | Maintainers can run a deterministic browser visual smoke command that renders representative gg2d3 plots to inspectable screenshot or image artifacts under an ignored local output directory. | Use `test_output/browser-visual-smoke/`, `htmlwidgets::saveWidget(selfcontained = FALSE)`, `chromote::ChromoteSession$screenshot()`, and a generated report. [VERIFIED: .planning/REQUIREMENTS.md; tests/testthat/helper-sf-fixtures.R; local R introspection] |
| VIS-02 | Visual smoke coverage includes representative core surfaces: Cartesian geoms, facets, interactivity-facing marks, sf geometry marks, and the newly shipped polygon/sf-annotation geometry paths. | Reuse existing polygon, sf, and sf annotation fixture builders/scripts, and add compact Cartesian/facet/interactivity fixtures inspired by older `visual-*.R` files. [VERIFIED: tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-browser.R; tests/testthat/test-sf-annotations-browser.R; tests/testthat/visual-*.R] |
| VIS-03 | Visual/browser validation skips cleanly with explicit messages when optional local dependencies such as Chrome, chromote, sf, or geojsonsf are unavailable. | Extend existing `skip_browser_*_smoke()` semantics and add a visual-smoke opt-in env gate. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R; tests/testthat/test-date-scales.R] |
</phase_requirements>

## Summary

Phase 48 should build on the existing R/testthat/chromote browser smoke stack rather than introduce Node browser tooling or screenshot-diff infrastructure. [VERIFIED: DESCRIPTION; tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md] The current suite already saves non-self-contained htmlwidgets under ignored `test_output/`, opens them via `file://` in chromote, captures console/page errors, and asserts DOM facts for sf, ordinary polygons, and sf annotations. [VERIFIED: tests/testthat/helper-sf-fixtures.R; tests/testthat/test-sf-browser.R; tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-annotations-browser.R; .gitignore; .Rbuildignore]

The main missing implementation unit is a reusable visual-smoke runner that adds screenshots, DOM-summary JSON, per-fixture status, and a local index/report while preserving skip-friendly behavior. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; local chromote introspection] The planner should create a small shared helper, likely `tests/testthat/helper-browser-visual.R`, plus an opt-in test file or maintainer script that runs the representative matrix only when a deliberate env var such as `GG2D3_BROWSER_VISUAL_SMOKE=true` is set. [VERIFIED: tests/testthat/test-date-scales.R; local testthat introspection]

**Primary recommendation:** Add shared visual smoke helpers and a gated `test-browser-visual-smoke.R` command that writes `html`, `png`, `dom-summary.json`, `browser-log.json`, and `index.html`/`index.json` under `test_output/browser-visual-smoke/`, with no pixel thresholds or committed artifacts. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; .gitignore; .Rbuildignore; local chromote introspection]

## Project Constraints (from CLAUDE.md)

- Development commands are `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: CLAUDE.md]
- D3 v7 must be vendored locally at `inst/htmlwidgets/lib/d3/d3.v7.min.js`; the file exists locally. [VERIFIED: CLAUDE.md; `wc -c inst/htmlwidgets/lib/d3/d3.v7.min.js`]
- The architectural pipeline is R layer `R/as_d3_ir.R` -> JSON-serializable IR -> D3 layer `inst/htmlwidgets/gg2d3.js`. [VERIFIED: CLAUDE.md]
- Existing supported surfaces include continuous/categorical scales, axes, color/fill aesthetics, themes, stacked bars, and basic `coord_flip`. [VERIFIED: CLAUDE.md]
- Existing known limitations include no legends/facets in the old AGENTS limitation list, `geom_path` x sorting, bar-domain assumptions, coord_flip axis-side issues, and limited text options; Phase 48 should document evidence, not fix these. [VERIFIED: CLAUDE.md; .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Fixture definition | R test layer | ggplot2/htmlwidgets | Plots/widgets are constructed in R before browser execution. [VERIFIED: tests/testthat/test-polygon-browser.R; tests/testthat/helper-sf-fixtures.R] |
| HTML artifact generation | R test layer | htmlwidgets | Existing helpers call `htmlwidgets::saveWidget(..., selfcontained = FALSE)`. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| Browser rendering and screenshot capture | Browser automation | D3/htmlwidgets runtime | chromote opens local HTML and can write screenshots through `ChromoteSession$screenshot()`. [VERIFIED: tests/testthat/test-sf-browser.R; local chromote introspection] |
| DOM summary evidence | Browser automation | R JSON writer | Existing tests already evaluate static JavaScript summaries; new helper should write those summaries as JSON. [VERIFIED: tests/testthat/test-sf-browser.R; tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-annotations-browser.R] |
| Report/index generation | R test layer | Browser artifacts | The report is local metadata tying fixture status to generated files. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md] |
| Optional dependency gating | R test layer | testthat/chromote | Current skip helpers gate CRAN, chromote, Chrome launch, `sf`, and `geojsonsf`. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 local | Run package tests and visual-smoke command. | Existing package/runtime language. [VERIFIED: local `Rscript --version`; DESCRIPTION] |
| testthat | 3.3.2 local, `>= 3.0.0` in Suggests | Optional test file, skips, and expectations. | Existing package test framework. [VERIFIED: DESCRIPTION; local R introspection] |
| chromote | 0.5.1 local, `>= 0.5.1` in Suggests | Headless Chrome navigation, JS evaluation, screenshots. | Existing browser automation dependency. [VERIFIED: DESCRIPTION; local chromote introspection] |
| htmlwidgets | 1.6.4 local | Save gg2d3 widgets to HTML fixtures. | Existing gg2d3 delivery mechanism. [VERIFIED: DESCRIPTION; local R introspection] |
| jsonlite | 2.0.0 local | Write DOM summaries and report JSON. | Existing imported JSON dependency. [VERIFIED: DESCRIPTION; local R introspection] |
| ggplot2 | 4.0.3 local | Build representative plots. | Existing imported plotting layer. [VERIFIED: DESCRIPTION; local R introspection] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sf | Missing locally, `>= 1.0.0` in Suggests | sf visual fixtures and annotations. | Required only for sf matrix rows; skip explicitly when unavailable. [VERIFIED: DESCRIPTION; local R introspection] |
| geojsonsf | 2.0.5 local, `>= 2.0.0` in Suggests | sf serialization support. | Required only for sf fixture generation. [VERIFIED: DESCRIPTION; local R introspection] |
| crosstalk | 1.2.2 local | Interactivity-facing shared-data fixtures. | Use for crosstalk/interactivity rows when available. [VERIFIED: DESCRIPTION; tests/testthat/test-polygon-browser.R; local R introspection] |
| pkgload | 1.5.2 local | Load package in direct `test_file()` execution. | Existing helpers call `pkgload::load_all()` when namespace is absent. [VERIFIED: tests/testthat/helper-browser-sf.R; local R introspection] |
| rprojroot | 2.1.1 local | Resolve project-root `test_output/`. | Existing output helpers use package-root discovery. [VERIFIED: tests/testthat/helper-sf-fixtures.R; tests/testthat/helper-browser-polygon.R; local R introspection] |
| htmltools | 0.5.9 local | Optional local HTML report/index generation. | Use if a richer `index.html` is easier than string assembly. [VERIFIED: DESCRIPTION; local R introspection] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chromote::ChromoteSession$screenshot()` | `webshot2` | `webshot2` is not installed locally and is not in `DESCRIPTION`; chromote already exists and exposes screenshot support. [VERIFIED: local R introspection; DESCRIPTION] |
| `test_output/browser-visual-smoke/` | New root output directory | `test_output/` is already gitignored and build-ignored; a new root directory would need extra hygiene. [VERIFIED: .gitignore; .Rbuildignore] |
| Opt-in testthat file | Always-on testthat browser screenshots | Current browser tests skip by default under CRAN-like `Rscript`; Phase 48 decisions require optional workflows. [VERIFIED: local test runs; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md] |
| Screenshot diffs | Local artifact generation only | Pixel thresholds and goldens are explicitly deferred. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; .planning/REQUIREMENTS.md] |

**Installation:**
```r
# No new package should be required for the core Phase 48 path.
# sf remains optional and is already listed in Suggests.
```
[VERIFIED: DESCRIPTION; local R introspection]

**Version verification:** Versions above were verified with local R package introspection because the phase explicitly requested no network dependency. [VERIFIED: local `Rscript --vanilla -e ... packageVersion(...)`]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer command
  -> opt-in testthat/runner gate
  -> dependency checks
      -> missing optional dependency: skip with explicit message
      -> available dependencies: build fixture matrix
  -> ggplot fixture -> gg2d3 widget -> non-self-contained HTML under test_output/
  -> chromote opens file:// HTML
  -> wait for expected DOM marks
      -> success: screenshot + DOM summary + logs + status
      -> failure: screenshot if possible + copied HTML + DOM summary if possible + logs + error status
  -> local index/report under test_output/browser-visual-smoke/
```
[VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R; tests/testthat/test-sf-browser.R; tests/testthat/test-polygon-browser.R; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]

### Recommended Project Structure

```text
tests/testthat/
├── helper-browser-visual.R      # shared visual-smoke artifact, screenshot, DOM-summary, report helpers
├── test-browser-visual-smoke.R  # opt-in representative visual artifact test/runner
├── helper-browser-sf.R          # existing reusable sf browser primitives
├── helper-browser-polygon.R     # existing reusable polygon browser primitives
└── helper-sf-fixtures.R         # existing sf fixture/output helpers

test_output/
└── browser-visual-smoke/
    ├── index.html
    ├── index.json
    ├── <fixture>.html
    ├── <fixture>.png
    ├── <fixture>-dom-summary.json
    └── <fixture>-browser-log.json
```
[VERIFIED: tests/testthat helper layout; .gitignore; .Rbuildignore; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]

### Pattern 1: Shared Artifact Runner

**What:** A helper accepts fixture metadata (`id`, `plot` or `widget`, expected selector/counts, optional dependency family), writes HTML, opens it in chromote, waits for DOM readiness, writes screenshot/log/DOM artifacts, and returns a status row. [VERIFIED: existing helper patterns in tests/testthat/helper-browser-sf.R and helper-browser-polygon.R]

**When to use:** Every visual-smoke fixture should go through this runner so screenshots, logs, DOM summaries, and report rows have the same names and shape. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]

**Example:**
```r
# Source: tests/testthat/helper-browser-sf.R and local chromote introspection
session$go_to(file_url, delay = 1)
marks <- eval_js_value(session, dom_summary_script)
session$screenshot(filename = screenshot_path, selector = "html", delay = 0.5)
jsonlite::write_json(marks, dom_summary_path, auto_unbox = TRUE, pretty = TRUE)
```

### Pattern 2: Non-Self-Contained Fixtures

**What:** Save widgets with `htmlwidgets::saveWidget(widget, selfcontained = FALSE)` under `test_output/`. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R; tests/testthat/helper-sf-fixtures.R]

**When to use:** Use for all Phase 48 visual-smoke HTML because prior retrospectives identify self-contained fixtures as a Pandoc dependency trap. [VERIFIED: .planning/RETROSPECTIVE.md]

**Example:**
```r
# Source: tests/testthat/helper-browser-sf.R
htmlwidgets::saveWidget(
  widget,
  file = normalizePath(outpath, mustWork = FALSE),
  selfcontained = FALSE
)
```

### Pattern 3: Opt-In Testthat Gate

**What:** Start the new visual smoke test with an explicit env var skip before doing heavy work. [VERIFIED: tests/testthat/test-date-scales.R]

**When to use:** The normal `devtools::test()` path should not generate screenshots unless the maintainer opts in. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]

**Example:**
```r
# Source pattern: tests/testthat/test-date-scales.R
testthat::skip_if_not(
  identical(Sys.getenv("GG2D3_BROWSER_VISUAL_SMOKE"), "true"),
  "Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate browser visual smoke artifacts"
)
```

### Anti-Patterns to Avoid

- **Do not add pixel/golden comparisons:** Phase 48 is artifact generation and smoke evidence only; CI thresholds and committed goldens are deferred. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; .planning/REQUIREMENTS.md]
- **Do not use `testthat::test_file(..., filter = ...)` in plans:** Local `testthat::test_file()` formals do not include `filter`, and prior phase summaries record this as a repeated issue. [VERIFIED: local testthat introspection; .planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-03-SUMMARY.md]
- **Do not make `sf` required for the whole visual smoke run:** `sf` is missing locally, while non-sf browser smoke can still be useful; sf-specific rows must skip without blocking non-sf rows. [VERIFIED: local R introspection; .planning/REQUIREMENTS.md]
- **Do not save self-contained visual-smoke HTML:** Existing browser fixtures use non-self-contained files, and v1.8 retrospective says this avoids Pandoc. [VERIFIED: tests/testthat/helper-browser-sf.R; .planning/RETROSPECTIVE.md]
- **Do not duplicate sf/polygon browser helpers wholesale:** There is already overlap in session, JS evaluation, console collection, and artifact writing; Phase 48 should consolidate shared behavior carefully. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser automation | New Playwright/Puppeteer/Selenium/Node stack | `chromote` | chromote is already in Suggests and used by current browser tests. [VERIFIED: DESCRIPTION; tests/testthat/helper-browser-sf.R] |
| HTML widget serialization | Custom HTML or manual dependency copying | `htmlwidgets::saveWidget(selfcontained = FALSE)` | Current fixtures already rely on htmlwidgets dependency handling. [VERIFIED: tests/testthat/helper-sf-fixtures.R] |
| JSON output | Manual JSON strings | `jsonlite::write_json()` | Existing failure helper writes browser log JSON with jsonlite. [VERIFIED: tests/testthat/helper-browser-sf.R] |
| DOM readiness polling | Fixed sleeps only | Existing polling helpers plus targeted selectors | Existing `wait_for_*` helpers poll selectors with timeout and fail with useful messages. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/test-polygon-browser.R] |
| Optional dependency checks | Ad hoc `require()` failures | `testthat::skip_if_not_installed()`, `skip_if()`, `skip_on_cran()` | Existing skip helpers already use these APIs and produce skip outcomes. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| Local artifact ignore rules | New unignored output path | `test_output/` | `test_output/` is already ignored by git and excluded from source builds. [VERIFIED: .gitignore; .Rbuildignore] |

**Key insight:** Phase 48 should standardize evidence capture around existing browser smoke primitives; the hard part is artifact/report contract, not browser orchestration. [VERIFIED: tests/testthat helper patterns; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: CRAN-Like Default Skips Hide Visual-Smoke Execution
**What goes wrong:** Running `Rscript testthat::test_file(...)` without opt-in or `NOT_CRAN=true` skips existing chromote tests as "On CRAN". [VERIFIED: local test runs]
**Why it happens:** Current helpers call `testthat::skip_on_cran()` before browser launch. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R]
**How to avoid:** Document two commands: normal skip-friendly command and explicit visual-smoke command with env vars. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
**Warning signs:** Test output shows only skips and no artifact screenshots. [VERIFIED: local test runs]

### Pitfall 2: Chrome Found But Chromote Session Fails
**What goes wrong:** `chromote::find_chrome()` can find Chrome while `ChromoteSession$new()` still fails; local run reported "Cannot find an available port." [VERIFIED: local `NOT_CRAN=true` polygon browser test]
**Why it happens:** Browser process launch and debugging-port allocation are separate from binary discovery. [VERIFIED: tests/testthat/helper-browser-polygon.R; local test run]
**How to avoid:** Keep the existing launch probe and include the launch failure in skip/status report rows. [VERIFIED: tests/testthat/helper-browser-polygon.R]
**Warning signs:** Skip message starts `chromote session launch unavailable:`. [VERIFIED: local test run]

### Pitfall 3: sf Matrix Blocks Whole Run
**What goes wrong:** A missing `sf` package could prevent non-sf visual artifacts if dependency checks are global. [VERIFIED: local R introspection; .planning/REQUIREMENTS.md]
**Why it happens:** sf fixtures require `sf`, but Cartesian/polygon fixtures do not. [VERIFIED: tests/testthat/test-sf-browser.R; tests/testthat/test-polygon-browser.R]
**How to avoid:** Split fixture metadata into dependency groups and record skipped rows individually. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
**Warning signs:** Report has no non-sf screenshots because an sf dependency check ran first. [ASSUMED]

### Pitfall 4: Self-Contained HTML Pulls In Pandoc
**What goes wrong:** Visual fixture generation becomes dependent on Pandoc. [VERIFIED: .planning/RETROSPECTIVE.md]
**Why it happens:** `htmlwidgets::saveWidget()` defaults `selfcontained = TRUE`, while existing browser helpers explicitly set `FALSE`. [VERIFIED: local htmlwidgets introspection; tests/testthat/helper-browser-sf.R]
**How to avoid:** Visual-smoke helper should default and assert `selfcontained = FALSE`. [VERIFIED: tests/testthat/helper-browser-sf.R]
**Warning signs:** Generated files include embedded base64 blobs or failures mention Pandoc. [VERIFIED: .planning/RETROSPECTIVE.md]

### Pitfall 5: Old Manual Visual Scripts Are Too Broad And Inconsistent
**What goes wrong:** Reusing `visual-*.R` directly produces self-contained files and inconsistent output/report names. [VERIFIED: tests/testthat/visual-*.R]
**Why it happens:** Older visual scripts predate the current chromote artifact contract. [VERIFIED: tests/testthat/visual-*.R; .planning/RETROSPECTIVE.md]
**How to avoid:** Mine them only for fixture ideas; implement Phase 48 fixtures through the new runner. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
**Warning signs:** Phase 48 output lands as `test_output/test_*.html` without screenshots or index rows. [VERIFIED: tests/testthat/visual-*.R]

## Code Examples

### Existing Browser Skip Boundary
```r
# Source: tests/testthat/helper-browser-sf.R
testthat::skip_on_cran()
testthat::skip_if_not_installed("chromote", "0.5.1")
testthat::skip_if_not_installed("sf")
testthat::skip_if_not_installed("geojsonsf")
```

### Existing Failure Artifact Pattern
```r
# Source: tests/testthat/helper-browser-sf.R
writeLines(vapply(console_entries, format_entry, character(1)),
           con = paste0(prefix, "-console.log"))
jsonlite::write_json(
  list(html_path = normalizePath(html_path, mustWork = FALSE), logs = entries),
  path = paste0(prefix, "-browser-log.json"),
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null"
)
```

### Recommended DOM Summary Shape
```r
# Source pattern: tests/testthat/test-sf-browser.R and test-polygon-browser.R
dom_summary <- eval_js_value(session, paste(
  "(() => ({",
  "  title: document.title || '',",
  "  svgCount: document.querySelectorAll('svg').length,",
  "  panelCount: document.querySelectorAll('.panel').length,",
  "  marks: Array.from(document.querySelectorAll('.geom-sf, path.geom-polygon, circle, path, rect, text')).length,",
  "  errors: window.__gg2d3_errors || []",
  "}))()"
))
```

### Recommended Maintainer Command
```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```
[VERIFIED: existing `NOT_CRAN` behavior from local browser test; tests/testthat/test-date-scales.R opt-in env pattern; local testthat introspection]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `visual-*.R` scripts with `selfcontained = TRUE` | Browser helpers save non-self-contained HTML under `test_output/browser-*` | Established across v1.8-v1.11 browser work | Avoids Pandoc and keeps artifacts inspectable. [VERIFIED: tests/testthat/visual-*.R; tests/testthat/helper-browser-sf.R; .planning/RETROSPECTIVE.md] |
| DOM smoke without screenshots | Phase 48 local screenshots plus DOM/log/report artifacts | Phase 48 decision | Gives maintainers inspectable visual evidence without pixel thresholds. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md] |
| Per-feature browser helpers | Shared visual-smoke runner plus feature-specific fixture builders | Recommended for Phase 48 | Reduces duplication around sessions, screenshots, logs, and reports. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| Test command filters | Whole-file test commands | v1.9 lessons | Local `test_file()` does not expose `filter`; plans should avoid it. [VERIFIED: local testthat introspection; .planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-03-SUMMARY.md] |

**Deprecated/outdated:**
- Directly using `tests/testthat/visual-*.R` as the Phase 48 runner is outdated because those scripts lack screenshots, DOM summaries, status reports, and consistent skip boundaries. [VERIFIED: tests/testthat/visual-*.R; .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
- Treating screenshot artifacts as CI pass/fail references is out of scope for this phase. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A missing `sf` package could block non-sf output if dependency checks are global. | Common Pitfalls | Planner may over-split dependency groups, but the split still improves skip reporting. |

## Open Questions

1. **Where should the explicit maintainer command be documented?**
   - What we know: Phase 48 requires an explicit command, and existing project docs include vignettes/diagnostics and planning validation artifacts. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; vignettes/d3-drawing-diagnostics.md]
   - What's unclear: Whether to add user-facing package docs or keep it in maintainer diagnostics only. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
   - Recommendation: Put the command in `vignettes/d3-drawing-diagnostics.md` or a maintainer-facing diagnostics doc, not README marketing copy. [ASSUMED]

2. **Should successful fixture artifacts include browser logs even when empty?**
   - What we know: Phase 48 requires screenshots, HTML, logs, and report; existing log helpers write logs mainly on failure. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md; tests/testthat/helper-browser-sf.R]
   - What's unclear: Whether empty success logs should be written as files or only represented in `index.json`. [ASSUMED]
   - Recommendation: Write `*-browser-log.json` for every row for report consistency. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript | All test/runner commands | yes | 4.6.0 | None needed. [VERIFIED: local `Rscript --version`] |
| D3 v7 vendor file | htmlwidgets browser rendering | yes | vendored `d3.v7.min.js` present | None needed. [VERIFIED: `wc -c inst/htmlwidgets/lib/d3/d3.v7.min.js`] |
| Chrome/Chromium | chromote browser rendering | yes, binary found | Google Chrome app path found | Skip if launch unavailable. [VERIFIED: local `chromote::find_chrome()`; tests/testthat/helper-browser-polygon.R] |
| chromote | Browser navigation/screenshot | yes | 0.5.1 | Skip browser visual smoke if missing. [VERIFIED: local R introspection; DESCRIPTION] |
| chromote session launch | Live browser execution | no in local probe | Port launch failed during `NOT_CRAN=true` polygon test | Skip with launch error and still report skipped status. [VERIFIED: local test run] |
| sf | sf fixtures and sf annotations | no | NA | Skip sf fixture rows; non-sf rows should still run. [VERIFIED: local R introspection] |
| geojsonsf | sf serialization | yes | 2.0.5 | Skip sf fixture rows if missing. [VERIFIED: local R introspection] |
| webshot2 | Alternative screenshot path | no | NA | Do not use; chromote already has screenshot API. [VERIFIED: local R introspection; local chromote introspection] |

**Missing dependencies with no fallback:**
- None for the non-sf visual-smoke planning path; live browser execution depends on chromote session launch and should skip/report when unavailable. [VERIFIED: local test run; tests/testthat/helper-browser-polygon.R]

**Missing dependencies with fallback:**
- `sf` is missing locally; skip sf geometry and sf annotation visual rows while continuing Cartesian/polygon rows. [VERIFIED: local R introspection; .planning/REQUIREMENTS.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 local, edition 3 configured. [VERIFIED: DESCRIPTION; local R introspection] |
| Config file | `DESCRIPTION` with `Config/testthat/edition: 3`. [VERIFIED: DESCRIPTION] |
| Quick run command | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` should skip unless opted in. [VERIFIED: tests/testthat/test-date-scales.R pattern] |
| Full visual-smoke command | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'`. [VERIFIED: local `NOT_CRAN` behavior; local testthat introspection] |
| Existing browser smoke commands | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-browser.R")'` and `...test-sf-browser.R` skip cleanly by default. [VERIFIED: local test runs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VIS-01 | Opt-in command writes screenshots/images and HTML/report under ignored output. | browser smoke + artifact contract | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | No, Wave 0. [VERIFIED: tests/testthat listing] |
| VIS-02 | Fixture matrix covers Cartesian, facets, interactivity, sf marks, ordinary polygon, and sf annotations. | browser smoke + source checks | Same command plus source `rg` checks for fixture IDs/selectors. | No, Wave 0. [VERIFIED: tests/testthat listing; existing browser files] |
| VIS-03 | Missing Chrome/chromote/sf/geojsonsf paths skip/report explicitly. | unit/helper + browser skip | `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | No, Wave 0. [VERIFIED: tests/testthat listing] |

### Sampling Rate

- **Per task commit:** Run the relevant helper/source test and the new visual-smoke file in default mode to ensure it skips fast. [VERIFIED: local default browser test runs]
- **Per wave merge:** Run existing polygon/sf browser smoke files plus new visual-smoke file; accept explicit skips for unavailable optional dependencies. [VERIFIED: tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-browser.R]
- **Phase gate:** Run the opt-in command on a machine with live chromote session support; record skipped sf rows if `sf` remains unavailable. [VERIFIED: local environment audit]

### Wave 0 Gaps

- [ ] `tests/testthat/helper-browser-visual.R` - shared screenshot, DOM summary, report, and status helpers for VIS-01/VIS-03. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-browser-visual-smoke.R` - opt-in representative matrix for VIS-01/VIS-02/VIS-03. [VERIFIED: tests/testthat listing]
- [ ] Report/index generator for `test_output/browser-visual-smoke/index.html` and `index.json`. [VERIFIED: .planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md]
- [ ] Documentation of the maintainer command in a maintainer-facing diagnostics location. [VERIFIED: .planning/ROADMAP.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth surface in local test artifacts. [VERIFIED: Phase 48 scope in .planning/ROADMAP.md] |
| V3 Session Management | no | No sessions are introduced. [VERIFIED: Phase 48 scope in .planning/ROADMAP.md] |
| V4 Access Control | no | Local ignored artifacts only; no served app or permissions model. [VERIFIED: .gitignore; .Rbuildignore] |
| V5 Input Validation | yes | Keep evaluated JS static; do not interpolate untrusted user input into browser scripts. [VERIFIED: existing static JS script patterns in tests/testthat/test-sf-browser.R and test-polygon-browser.R] |
| V6 Cryptography | no | No crypto behavior is introduced. [VERIFIED: Phase 48 scope in .planning/ROADMAP.md] |

### Known Threat Patterns for R/chromote visual smoke

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental commit of generated screenshots/logs | Information Disclosure | Write only under ignored/build-ignored `test_output/`. [VERIFIED: .gitignore; .Rbuildignore] |
| Dynamic JavaScript injection in browser summaries | Tampering/Elevation of Privilege | Use static JS summary strings and fixture metadata-controlled filenames. [VERIFIED: existing static scripts in browser tests] |
| Remote browser automation dependency drift | Supply Chain | Do not add Playwright/Puppeteer/Selenium/Node; reuse chromote in Suggests. [VERIFIED: DESCRIPTION; .planning/research/SUMMARY.md] |
| Local file path disclosure in public docs | Information Disclosure | Keep report/log paths in local artifacts and summarize only commands/docs. [VERIFIED: .planning/RETROSPECTIVE.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md` - locked decisions, deferred scope, artifact contract, skip policy.
- `.planning/REQUIREMENTS.md` - VIS-01, VIS-02, VIS-03 and future/out-of-scope visual regression boundaries.
- `.planning/ROADMAP.md` - Phase 48 goal, dependencies, success criteria.
- `.planning/PROJECT.md` and `.planning/STATE.md` - v1.12 project direction and current phase state.
- `.planning/RETROSPECTIVE.md` - v1.11/v1.10 lessons about optional skips, artifact paths, and non-self-contained fixtures.
- `CLAUDE.md` and `AGENTS.md` - package architecture and development commands.
- `DESCRIPTION` - R package dependencies and testthat edition.
- `tests/testthat/helper-browser-sf.R`, `helper-browser-polygon.R`, `helper-sf-fixtures.R` - current browser helper patterns.
- `tests/testthat/test-sf-browser.R`, `test-polygon-browser.R`, `test-sf-annotations-browser.R`, `test-date-scales.R` - current browser/visual skip and fixture patterns.
- `.gitignore`, `.Rbuildignore` - generated artifact hygiene.
- Local R introspection - installed versions and chromote/testthat/htmlwidgets APIs.

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md`, `.planning/research/STACK.md`, `.planning/research/PITFALLS.md` - prior browser smoke research; useful as historical confirmation, superseded by current local code.
- `.planning/milestones/v1.9-*` and `.planning/milestones/v1.11-*` summaries - prior lessons about `test_file(filter=...)`, optional browser skips, and artifact behavior.

### Tertiary (LOW confidence)

- None used for implementation-critical facts.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `DESCRIPTION` and local R package introspection.
- Architecture: HIGH - verified from existing test helpers and browser tests.
- Pitfalls: HIGH for CRAN-like skip, non-self-contained output, local `test_file()` no-filter behavior, and current missing `sf`; MEDIUM for final report/documentation placement.

**Research date:** 2026-05-25
**Valid until:** 2026-06-24 for local code patterns; recheck package versions and browser availability before implementation.

