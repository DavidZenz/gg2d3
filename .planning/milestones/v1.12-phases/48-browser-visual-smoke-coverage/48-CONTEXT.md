# Phase 48: Browser Visual Smoke Coverage - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 48 delivers deterministic local browser visual smoke coverage for representative gg2d3 surfaces. It should create inspectable screenshot or image artifacts under ignored local output, reuse the existing browser-smoke dependency boundaries, and skip cleanly when optional local browser or spatial dependencies are unavailable.

This phase does not add CI-enforced pixel thresholds, committed golden images, broad renderer refactors, or new geometry support. Those belong to later v1.12 phases or future milestones.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/ROADMAP.md` — Phase 48 goal, requirements, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — VIS-01, VIS-02, and VIS-03 acceptance scope.
- `.planning/PROJECT.md` — Current v1.12 milestone goal, constraints, known tech debt, and out-of-scope boundaries.
- `.planning/RETROSPECTIVE.md` — v1.11 lessons about optional browser/spatial skips and generated artifact consistency.

### Existing browser and visual test assets
- `tests/testthat/helper-browser-sf.R` — Existing chromote session, skip, console-log, saved-widget, and failure-artifact helpers for sf browser smoke tests.
- `tests/testthat/helper-browser-polygon.R` — Existing chromote session, skip, console-log, saved-widget, and failure-artifact helpers for ordinary polygon browser smoke tests.
- `tests/testthat/helper-sf-fixtures.R` — Existing `test_output/` conventions and reusable sf fixture generation.
- `tests/testthat/test-sf-browser.R` — Existing optional live-browser sf DOM and interaction smoke coverage.
- `tests/testthat/test-polygon-browser.R` — Existing optional live-browser ordinary polygon DOM and interaction smoke coverage.
- `tests/testthat/test-sf-annotations-browser.R` — Existing optional live-browser sf text/label annotation smoke coverage.
- `tests/testthat/visual-*.R` — Older manual visual HTML checks that may provide fixture ideas but should not dictate the final screenshot/report contract.

### Artifact boundaries
- `.gitignore` — Existing ignored `test_output/` and root image artifact patterns.
- `.Rbuildignore` — Existing package-build exclusion for `test_output/` and generated root image artifacts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skip_browser_sf_smoke()` and `skip_browser_polygon_smoke()` already encode CRAN, chromote, Chrome/Chromium, sf, and geojsonsf skip semantics.
- `with_chromote_session()` and `eval_js_value()` already provide live-browser execution primitives.
- `browser_sf_artifact_dir()` and `browser_polygon_artifact_dir()` already write under `test_output/`.
- Existing `write_browser_failure_artifacts()` helpers already copy HTML and write browser logs; Phase 48 should extend this pattern to screenshots and DOM summaries.
- Existing sf and polygon browser tests already provide representative fixture builders and DOM scripts for mark counting, panel counting, payload inspection, and runtime error capture.

### Established Patterns
- Browser validation is optional and skip-friendly, not mandatory for CRAN-like or dependency-limited environments.
- HTML widgets used for browser validation should be non-self-contained when practical to avoid unnecessary Pandoc dependency.
- Generated visual/browser artifacts belong under `test_output/`, which is ignored by git and excluded from package builds.
- Failure evidence should preserve local artifact paths rather than embedding local logs in public docs.

### Integration Points
- Phase 48 should likely add or consolidate browser visual helpers under `tests/testthat/`.
- The explicit maintainer command can be documented in package docs, diagnostics, or a planning validation artifact, depending on what the planner finds most consistent with current release-gate documentation.
- Any testthat integration should be opt-in, probably via an environment variable analogous to existing optional visual/browser test gates.

</code_context>

<specifics>
## Specific Ideas

- Recommended artifact bundle: screenshot, copied HTML, browser log, DOM summary, and a generated local index/report.
- Recommended coverage: representative matrix across Cartesian geoms, facets, interactivity-facing marks, sf marks, ordinary polygons, and sf annotations.
- Recommended execution model: explicit maintainer command, with optional testthat path gated by environment variable.

</specifics>

<deferred>
## Deferred Ideas

- CI-enforced screenshot diffs and cross-platform pixel thresholds remain future work after local visual artifacts stabilize.
- Committed golden/reference images remain future work unless Phase 48 proves outputs are stable enough across local environments.
- Renderer architecture changes and geometry edge-case fixes are out of scope for Phase 48 and belong to Phases 49-51.

</deferred>

---

*Phase: 48-browser-visual-smoke-coverage*
*Context gathered: 2026-05-25*
