---
phase: 60-pkgdown-visual-regression-depth
plan: "04"
subsystem: testing
tags: [pkgdown, chromote, browser-visual, dom-assertion, visual-regression]

# Dependency graph
requires:
  - phase: 60-pkgdown-visual-regression-depth
    provides: Opt-in pkgdown browser capture, CI invocation, and documented artifact/skip contracts
provides:
  - Named core, sf, and Crosstalk region coverage in the pkgdown browser gate
  - Widget-to-application/json payload matching and expected-content freshness evidence
  - Full-page PNG capture with readable dimensions recorded in the DOM summary
affects: [pkgdown visual regression, VIS-01, VIS-02, VIS-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Browser DOM region contracts are anchored to generated heading IDs and nearest .section containers
    - Live htmlwidget payloads are matched by data-for widget IDs before freshness assertions pass
    - Full-page screenshot dimensions are checked from the PNG IHDR without adding a test dependency

key-files:
  created:
    - .planning/phases/60-pkgdown-visual-regression-depth/60-04-SUMMARY.md
  modified:
    - tests/testthat/test-pkgdown-visual.R

key-decisions:
  - "Keep current generated-article expectations explicit: two basic-usage widgets, one 100-row sf widget, and two 150-row Crosstalk widgets with their current axis labels."
  - "Exclude optional sf/Crosstalk expected-content entries from freshness counting when the existing helper classifies that branch as skipped, while still requiring the named heading and visible skip marker."
  - "Use the requested html selector plus captureBeyondViewport and verify PNG height exceeds the 900px viewport."

patterns-established:
  - "Named-region coverage: a page-wide SVG minimum is only a coarse companion guard; representative sections must meet exact widget/SVG contracts."
  - "Freshness evidence: each representative record reports expected payload fields, live SVG text/mark counts, and mismatch reasons in the JSON summary."

requirements-completed: [VIS-01, VIS-02, VIS-03]

coverage:
  - id: D1
    description: "Opt-in pkgdown browser gate asserts named representative regions, current widget payload associations, marker count, and expected-content freshness."
    requirement: VIS-02
    verification:
      - kind: unit
        ref: "R parse: tests/testthat/test-pkgdown-visual.R"
        status: pass
      - kind: other
        ref: "Node compilation of generated DOM-summary IIFE"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rendered branch captures and validates full-page PNG plus DOM-summary evidence."
    requirement: VIS-01
    verification:
      - kind: e2e
        ref: "NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true testthat::test_file(tests/testthat/test-pkgdown-visual.R)"
        status: unknown
    human_judgment: true
    rationale: "Local Chrome/chromote was unavailable, so the shared helper skipped before capture; rendered PNG/JSON artifacts were not fabricated or read."

# Metrics
duration: 10m
completed: 2026-08-12
status: complete
---

# Phase 60 Plan 04: Named Pkgdown Region Freshness Summary

**The pkgdown visual gate now proves named core/sf/Crosstalk coverage against live widget payloads and records full-page screenshot evidence without weakening optional skip behavior.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-08-12T10:10:00Z (approximate)
- **Completed:** 2026-08-12T10:20:46Z
- **Tasks:** 1 completed
- **Files modified:** 1 production/test file; 1 planning summary created

## Accomplishments

- Added exact generated-article contracts for `basic-usage`, `sf-family-maps-with-geom_sf`, and `linked-views-with-crosstalk`, including widget/SVG counts and the exact `test_output/browser-visual-smoke/` marker count.
- Matched every rendered widget container to its current `application/json[data-for]` payload and recorded payload mismatches, representative expected/live fields, point-mark counts, sf geometry/group counts, and freshness mismatches.
- Replaced the viewport-only screenshot with the required full-page `html` capture using `captureBeyondViewport = TRUE`, and verified the PNG IHDR height exceeds the 900px viewport when capture is available.
- Preserved existing DOM detection, artifact paths, optional sf/Crosstalk classification, local opt-out behavior, and CI escalation semantics.

## Task Commits

Each task was committed atomically:

1. **Task 1: Gate the named pkgdown regions through live browser payloads** - `65750f4` (feat)

**Plan metadata:** pending final metadata commit.

## Files Created/Modified

- `tests/testthat/test-pkgdown-visual.R` - Named region contracts, payload matching, freshness checks, marker evidence, and full-page PNG validation.
- `.planning/phases/60-pkgdown-visual-regression-depth/60-04-SUMMARY.md` - This execution summary.

## Decisions Made

- The generated article’s current values were inspected directly before setting constants: both basic widgets are `Motor Trend Cars` with `wt`/`mpg` and 32 point rows; sf is one `sf` layer with 100 rows; Crosstalk uses the two specified 150-row Iris axis pairs.
- Optional branches remain helper-driven. A classified skip still requires its heading/section and visible `PKGDOWN_*_OPTIONAL_SKIP` marker, but does not count absent optional widgets as freshness mismatches.
- The unavailable-browser path remains a clean skip and does not inspect absent or historical PNG/JSON artifacts.

## Verification Results

- `rtk Rscript --vanilla -e 'parse(file="tests/testthat/test-pkgdown-visual.R")'` — PASS (`PARSE_OK`).
- Opt-in focused test — SKIP as documented: Chromote reported `Cannot find an available port` and Chrome was not runnable. The test exited successfully through the shared local skip path; no capture artifact was read.
- Opt-out focused test — PASS with the expected opt-in skip (`OPT_OUT_SKIP_OK`).
- Generated DOM-summary IIFE compiled with Node — PASS (`JS_SYNTAX_OK`).
- `git diff --check` and helper/workflow isolation checks — PASS; only `tests/testthat/test-pkgdown-visual.R` changed in the task commit.
- Rendered-browser artifact schema and PNG dimension assertions — not run locally because Chrome/chromote was unavailable. CI or a Chrome-capable maintainer run must provide that runtime evidence.

## Deviations from Plan

None. The browser-unavailable result followed the plan’s documented skip behavior and was recorded as an unrun rendered-capture verification rather than treated as a rendered pass.

## Issues Encountered

- Local Chromote could not launch Chrome because no available port/browser runtime was available. This is an environment limitation, not an implementation failure; the shared helper skipped before reading or writing capture evidence.

## Known Stubs

None.

## Threat Flags

None. The change remains within the planned generated-HTML-to-browser-DOM and ignored-artifact boundaries; shared helpers, workflow configuration, and capture scope were not changed.

## Next Phase Readiness

The named-region and live-payload gate is committed and ready for CI or a Chrome-capable local run. The only outstanding evidence is the rendered branch’s runtime PNG/JSON validation because Chrome was unavailable in this environment.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| Summary file exists | FOUND |
| Task commit `65750f4` exists | FOUND |
| Key production/test file exists | FOUND |
| Summary has no whitespace errors | PASS |
| Browser limitation recorded without fabricated artifacts | PASS |

---
*Phase: 60-pkgdown-visual-regression-depth*
*Plan: 04*
*Completed: 2026-08-12*
