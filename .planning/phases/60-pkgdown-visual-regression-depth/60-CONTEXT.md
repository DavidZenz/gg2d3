# Phase 60: Pkgdown Visual Regression Depth - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 60 adds browser visual evidence for selected pkgdown article pages, going beyond the existing text/marker-based validation in `validate-pkgdown-site.R`. The deliverable is a repeatable test that loads the generated `docs/articles/gg2d3.html` in chromote, captures a full-page PNG screenshot plus per-widget DOM JSON (SVG child count), asserts that widget regions are not blank, and stores artifacts under ignored paths. The test runs locally (opt-in) and inside the existing `pkgdown.yaml` CI workflow after `pkgdown::build_site()` produces the site.

This phase does not add full perceptual-diff thresholds across a browser matrix — that is a future item (FUT-01). It does not add new geometry or architecture changes.

</domain>

<decisions>
## Implementation Decisions

### Page Source And CI Integration
- **D-01:** The capture step loads `docs/articles/gg2d3.html` from the generated pkgdown site, not fresh in-test fixtures. This proves the actual published site HTML has rendered widgets.
- **D-02:** A prerequisite of `pkgdown::build_site()` (or equivalent) having run to populate `docs/` is accepted. The test documents this requirement; maintainers run the build step first locally.
- **D-03:** In CI, the visual capture runs inside the existing `pkgdown.yaml` workflow, added as a step after the pkgdown build step. No separate workflow file. The capture artifact is uploaded alongside the existing `pkgdown-site-${run_id}` artifact (or as a separate named artifact from the same workflow run).

### Blank/Stale Detection Mechanism
- **D-04:** Detection uses DOM-based SVG child count: after page load + a settle interval, evaluate JS inside the chromote session to count SVG child elements (path, circle, rect, line, g with content) inside each `.html-widget-container`. Assert count >= a threshold (e.g., 3) for each expected non-empty widget region.
- **D-05:** Capture also produces a full-page PNG screenshot and a DOM summary JSON per page, following the existing `helper-browser-visual.R` artifact pattern. PNG is for human review; JSON carries the programmatic SVG child counts used for pass/fail.
- **D-06:** sf widget regions pass if the SVG child count meets threshold (rendered) OR if the page contains the expected `PKGDOWN_SF_OPTIONAL_SKIP` skip-notice text. This mirrors the existing pkgdown-site validation semantics.

### Capture Scope
- **D-07:** Capture targets the main article only: `docs/articles/gg2d3.html`. This page contains representative core widgets, a `geom_sf()` polygon widget or skip notice, and linked Crosstalk examples — covering all three required evidence types (VIS-01, VIS-02).
- **D-08:** The interactivity article (`gg2d3-interactivity.html`) is out of scope for Phase 60. It does not add sf or Crosstalk evidence and is deferred if needed.

### Command Surface
- **D-09:** Implementation lives in a new testthat file `tests/testthat/test-pkgdown-visual.R`, alongside `test-browser-visual-smoke.R`, using the same `helper-browser-visual.R` infrastructure.
- **D-10:** The test uses the existing `GG2D3_BROWSER_VISUAL_SMOKE=true` opt-in env var (no new dedicated env var). The `pkgdown.yaml` CI step already sets this env var.
- **D-11:** Artifact output goes to `test_output/pkgdown-visual/` inside the existing gitignored `test_output/` directory. Artifacts are excluded from source package builds via the existing `.Rbuildignore` / `.gitignore` patterns.

### Claude's Discretion
- The agent may choose the exact SVG child count threshold for "non-blank" assertions, provided it is clearly documented in comments and can be adjusted without breaking the interface.
- The agent may choose the settle interval (wait after page load) for chromote, following the existing smoke test patterns.
- The agent may choose the exact chromote session setup for loading `file://` URL vs a local HTTP server, whichever the existing `browser_visual_file_url()` helper supports cleanly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Phase 60 goal, requirements (VIS-01, VIS-02, VIS-03), success criteria, and plan breakdown.
- `.planning/REQUIREMENTS.md` — VIS-01, VIS-02, VIS-03 definitions.
- `.planning/PROJECT.md` — Current milestone context, known local sf/GDAL skip, and visual regression depth goal.

### Existing Browser Visual Infrastructure
- `tests/testthat/helper-browser-visual.R` — Chromote opt-in helpers: `skip_browser_visual_smoke()`, `browser_visual_require_opt_in()`, `browser_visual_paths()`, `browser_visual_ci_mode()`, `browser_visual_file_url()`. New test file MUST reuse these helpers.
- `tests/testthat/test-browser-visual-smoke.R` — Pattern reference for how browser visual fixtures are structured and how artifacts are written.

### Pkgdown Validation Infrastructure
- `tests/testthat/helper-pkgdown-site.R` — Skip/render classification helpers: `pkgdown_site_sf_outcome()`, `pkgdown_site_spatial_loadable()`. The sf skip-or-rendered semantics (D-06) are defined here.
- `tools/validate-pkgdown-site.R` — Existing text/marker-based pkgdown validation command; Phase 60 does NOT replace this.
- `tests/testthat/test-pkgdown-site.R` — Existing marker-based pkgdown site tests; Phase 60 extends the evidence, does not replace.

### CI Workflow Surface
- `.github/workflows/pkgdown.yaml` — Phase 60 adds a visual capture step here, after `pkgdown::build_site()`. Agent must read this file before editing to understand existing step order, env vars, and artifact upload.

### Phase 59 Context (Prior Decisions)
- `.planning/phases/59-release-hygiene-and-local-spatial-recovery/59-CONTEXT.md` — D-10, D-11: Phase 59 deferred representative screenshots and blank/stale widget detection to Phase 60.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skip_browser_visual_smoke()` in `helper-browser-visual.R` — handles opt-in env var, chromote availability, Chrome binary, and session launch checks. New test file should call this at the top of each test.
- `browser_visual_paths(id)` — returns `list(html, png, dom_summary, browser_log)` for a given fixture id. Adapt for pkgdown-visual artifact naming.
- `browser_visual_file_url(path)` — converts a local file path to a `file://` URL for chromote.
- `browser_visual_ci_mode()` — returns TRUE when `GG2D3_BROWSER_VISUAL_CI=true`. Used to escalate skip to fail in CI.
- `pkgdown_site_sf_outcome(root)` in `helper-pkgdown-site.R` — returns "rendered", "classified_skip", or "missing". Use to decide whether to require sf SVG children or accept the skip notice (D-06).
- `browser_visual_artifact_dir()` — returns and creates `test_output/browser-visual-smoke/`. A parallel `pkgdown_visual_artifact_dir()` should create `test_output/pkgdown-visual/`.

### Established Patterns
- Opt-in browser tests: `GG2D3_BROWSER_VISUAL_SMOKE=true` env var guards all browser execution.
- Optional dependency skip semantics: sf/GDAL failures produce a visible skip notice in the HTML; detection should check for both rendered content and the skip marker text.
- Artifact storage: `test_output/` is gitignored; `.Rbuildignore` excludes `^test_output/` from package builds.
- DOM summaries: `dom_summary.json` per fixture accumulates browser metadata + element counts. Extend the schema to include per-widget SVG child counts for pkgdown captures.

### Integration Points
- `pkgdown.yaml` CI step order: checkout → setup-r → setup-r-dependencies → (existing build step) → (new capture step) → upload artifact. Agent reads the file before editing.
- `test_output/pkgdown-visual/` is the new artifact directory; it should follow the same gitignore and `.Rbuildignore` exclusion as `test_output/browser-visual-smoke/`.

</code_context>

<specifics>
## Specific Ideas

- The capture should load `docs/articles/gg2d3.html` as a `file://` URL in chromote (same approach as existing smoke tests for `.html` fixtures).
- Per-widget DOM assertion should count SVG children (path, circle, rect, g elements with child content) inside `.html-widget-container` divs. Threshold >= 3 is a reasonable starting point; document it.
- PNG artifact is for maintainer review (did the page render visually?); JSON artifact enables programmatic CI gating.
- The sf region detection should check both: SVG child count >= threshold AND whether the page text contains the skip-notice marker, to produce a "rendered or classified_skip" verdict matching existing validation semantics.

</specifics>

<deferred>
## Deferred Ideas

- Interactivity article capture (`gg2d3-interactivity.html`) — out of scope for Phase 60; can be added later if needed.
- Full perceptual-diff thresholds across a browser matrix — future work (FUT-01 in REQUIREMENTS.md).
- Pixel-brightness blank detection — considered and rejected in favor of DOM-based SVG child count, which is faster and avoids false positives on white-background plots.
- External uptime/freshness monitoring for the public pkgdown site — future work (FUT-04).

</deferred>

---

*Phase: 60-pkgdown-visual-regression-depth*
*Context gathered: 2026-07-23*
