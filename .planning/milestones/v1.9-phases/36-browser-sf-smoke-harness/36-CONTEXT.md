# Phase 36: Browser sf Smoke Harness - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 36 turns the v1.8 manual sf HTML checks into repeatable live-browser smoke tests. It protects existing polygon `geom_sf()` behavior before Phase 37 expands support to point and line sf geometry families.

The phase should validate rendered browser behavior for existing polygon sf widgets. It should not add new sf geometry families, change the production renderer contract, or introduce a separate browser/runtime stack unless the selected harness proves unable to cover required smoke checks.

</domain>

<decisions>
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

### Agent Discretion
- Exact helper names, file layout, polling implementation, artifact filenames, and `testthat` helper structure are left to the planning/execution agents, provided the decisions above and BRSF requirements are satisfied.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning
- `.planning/ROADMAP.md` - Phase 36 goal, success criteria, dependencies, and phase boundary.
- `.planning/REQUIREMENTS.md` - BRSF-01, BRSF-02, and BRSF-03 acceptance requirements.
- `.planning/research/SUMMARY.md` - v1.9 stack guidance, `chromote` recommendation, non-additions, and Phase 36 research risk.
- `.planning/STATE.md` - current milestone state and known open risk around `chromote` render waits, console/page errors, and brush simulation.

### Existing Tests And Fixtures
- `tests/testthat/test-sf-visual.R` - current manual sf fixture generation, Phase 35 polygon regression fixtures, non-self-contained `saveWidget()` usage, and sf interactivity smoke widget.
- `tests/testthat/test-sf-interactivity.R` - existing source-level assertions for sf DOM selectors, callback sanitization, brush centroid selection, and zoom suppression composition.
- `tests/testthat/test-sf-ir.R` - existing R-side sf row identity, skipped-row, stacked bbox, and diagnostics coverage.

### Renderer And Interaction Code
- `inst/htmlwidgets/modules/geoms/sf.js` - browser sf renderer, `path.geom-sf`, `data-row-id`, `data-cx`, `data-cy`, and projection behavior.
- `inst/htmlwidgets/modules/brush.js` - brush target selector list, sf centroid selection semantics, and brush callback sanitization.
- `inst/htmlwidgets/modules/events.js` - tooltip/custom handler target selectors and event payload sanitization.
- `inst/htmlwidgets/modules/tooltip.js` - tooltip payload sanitization.
- `R/d3_zoom.R` - sf zoom suppression behavior and warning contract.
- `DESCRIPTION` - package dependency surface; `chromote` should be added only to `Suggests`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.phase35_save_widget()` in `tests/testthat/test-sf-visual.R` already writes non-self-contained widgets into project `test_output/`.
- `.phase35_sf_fixture_set()` already creates the exact polygon fixture matrix Phase 36 should automate in-browser.
- `read_module()` in `tests/testthat/test-sf-interactivity.R` shows the existing test style for module-focused assertions, but Phase 36 should move beyond source inspection into live DOM checks.

### Established Patterns
- Optional spatial dependencies are handled with `skip_if_not_installed("sf")`, `skip_if_not_installed("geojsonsf")`, and fixture-specific skips.
- sf renderer paths use `path.geom-sf` as the stable selector and expose source row and centroid attributes through `data-row-id`, `data-cx`, and `data-cy`.
- sf brushing is intentionally centroid/representative-anchor based, not polygon intersection based.
- `d3_zoom()` currently suppresses zoom for sf widgets and returns the widget unchanged with a warning.

### Integration Points
- Browser smoke helpers should live under `tests/testthat/` or `tests/testthat/helper-*.R` and integrate with `testthat`.
- Fixture HTML output should stay in the existing project-root `test_output/` convention unless planning finds a stronger local convention.
- Console/page error collection and render-complete polling should be centralized in helper code so future Phase 37 and Phase 38 browser checks can reuse it.

</code_context>

<specifics>
## Specific Ideas

The user selected areas 1-4 and accepted the recommended options for all of them. That locks the browser runner, fixture matrix, assertion depth, and artifact policy above.

</specifics>

<deferred>
## Deferred Ideas

- Playwright, Puppeteer, Selenium, and Node browser tooling remain deferred unless Phase 36 proves `chromote` cannot reliably cover required render or interaction checks.
- Screenshot or pixel-diff visual regression remains deferred; Phase 36 should use DOM and event behavior as its gate.
- Point and line sf browser fixtures belong in Phase 37/38 after non-polygon sf support exists.
- Projection-aware map zoom/pan remains out of scope; Phase 36 only verifies sf zoom suppression.

</deferred>

---

*Phase: 36-browser-sf-smoke-harness*
*Context gathered: 2026-05-20*
