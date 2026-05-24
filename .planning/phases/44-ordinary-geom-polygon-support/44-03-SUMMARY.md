---
phase: 44-ordinary-geom-polygon-support
plan: 03
subsystem: interactivity
tags: [R, testthat, JavaScript, D3, chromote, geom_polygon, htmlwidgets]

requires:
  - phase: 44-02
    provides: Grouped ordinary geom_polygon renderer with path.geom-polygon marks and representative public rows
provides:
  - POLY-03 selector coverage for events, brush, and crosstalk polygon interactivity
  - Sanitizer source tests proving polygon private _polygonPoints stays out of public callback paths
  - Optional browser DOM smoke coverage for polygon rendering, facets, styling, and sanitized payloads
affects: [Phase 45, Phase 47, POLY-03, browser-validation]

tech-stack:
  added: []
  patterns:
    - selector-driven polygon interactivity through existing APIs
    - optional chromote browser smoke helper without sf or geojsonsf requirements
    - function-expression and raw-body event handler compilation

key-files:
  created:
    - tests/testthat/test-polygon-interactivity.R
    - tests/testthat/helper-browser-polygon.R
    - tests/testthat/test-polygon-browser.R
  modified:
    - inst/htmlwidgets/modules/events.js
    - inst/htmlwidgets/modules/brush.js
    - inst/htmlwidgets/modules/crosstalk.js

key-decisions:
  - "Added path.geom-polygon to existing selector arrays only; no polygon-specific tooltip, hover, brush, handler, Shiny, or crosstalk API was introduced."
  - "Kept ordinary polygon brushing on the existing generic path getBBox() branch rather than adding centroid, anchor, or point-in-polygon behavior."
  - "Extended the existing custom handler compiler to support full function-expression strings because the POLY-03 browser fixture uses the documented handler shape."

patterns-established:
  - "Polygon browser smoke tests use DOM/callback assertions and deterministic test_output/browser-polygon artifacts, not screenshots."
  - "Polygon callback assertions require representative public group data and reject _polygonPoints in click, mouseover, Shiny-style, tooltip, and brush payloads."

requirements-completed: [POLY-03]

duration: 10 min
completed: 2026-05-24
---

# Phase 44 Plan 03: Ordinary Geom Polygon Interactivity Summary

**Ordinary `geom_polygon()` marks now participate in existing selector-driven interactivity with sanitized representative payload coverage**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-24T18:20:36Z
- **Completed:** 2026-05-24T18:30:03Z
- **Tasks:** 3 completed
- **Files modified:** 6 source/test files, plus planning metadata

## Accomplishments

- Added POLY-03 source tests for polygon selectors and sanitizer contracts across `events.js`, `brush.js`, `crosstalk.js`, `tooltip.js`, and `geoms/polygon.js`.
- Added `path.geom-polygon` to existing events, brush, and crosstalk selector arrays.
- Added optional chromote/browser DOM smoke coverage for single, grouped, faceted, styled, `fill = NA`, `colour = NA`, and interactive ordinary polygon fixtures.
- Fixed custom event handler compilation so documented full function-expression handler strings execute for polygon click and mouseover payload tests.

## Task Commits

Each planned task was committed atomically:

1. **Task 1: Add polygon interaction selector and sanitizer source tests** - `75b1617` (test, RED)
2. **Task 2: Add path.geom-polygon to existing interaction selector plumbing** - `42a71d3` (feat, GREEN)
3. **Task 3: Add optional browser DOM smoke coverage for polygon rendering and payloads** - `8320348` (test)

Additional scoped fix:

- **Rule 1 fix: support function-expression event handlers** - `e6372b0` (fix)

## Files Created/Modified

- `tests/testthat/test-polygon-interactivity.R` - POLY-03 source guards for selector coverage, sanitizer paths, private `_polygonPoints`, and handler compiler support.
- `inst/htmlwidgets/modules/events.js` - Adds `path.geom-polygon` and compiles full function-expression handler strings as callable callbacks.
- `inst/htmlwidgets/modules/brush.js` - Adds `path.geom-polygon` to brush selectors while retaining generic path `getBBox()` selection behavior.
- `inst/htmlwidgets/modules/crosstalk.js` - Adds `path.geom-polygon` to linked-selection selector plumbing.
- `tests/testthat/helper-browser-polygon.R` - Optional chromote helper and deterministic browser-polygon artifact writer.
- `tests/testthat/test-polygon-browser.R` - DOM/callback smoke coverage for polygon paths, facets, styling, and sanitized payloads.

## Decisions Made

- Reused existing interaction APIs and selector plumbing rather than adding polygon-specific interaction functions.
- Kept ordinary polygon brush behavior bounds-based via SVG path `getBBox()`, matching Phase 44 D-10.
- Treated full function-expression handler compilation as a correctness fix for the existing `d3_handlers()` API because the plan and docs use that handler shape.

## Verification

| Command | Result |
|---------|--------|
| `rtk rg -n "POLY-03|path\\.geom-polygon|sanitizeEventDatum|sanitizeSelectedDatum|sanitizeTooltipDatum|_polygonPoints|startsWith\\('_'\\)" tests/testthat/test-polygon-interactivity.R` | PASS |
| `rtk rg -n "events\\.js|brush\\.js|crosstalk\\.js|tooltip\\.js|polygon\\.js|getBBox|data-cx|data-cy" tests/testthat/test-polygon-interactivity.R` | PASS |
| `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` before selector implementation | RED as expected: 3 missing `path.geom-polygon` selector failures |
| `rtk rg -n "path\\.geom-polygon" inst/htmlwidgets/modules/events.js inst/htmlwidgets/modules/brush.js inst/htmlwidgets/modules/crosstalk.js` | PASS, selector present in all three files |
| `rtk rg -n "geom-polygon.*data-cx|geom-polygon.*data-cy|point-in-polygon|centroid|polygon-specific" inst/htmlwidgets/modules/events.js inst/htmlwidgets/modules/brush.js inst/htmlwidgets/modules/crosstalk.js` | PASS, no matches |
| `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` after selector implementation | PASS, 39 assertions |
| `rtk rg -n "skip_browser_polygon_smoke|browser_polygon_artifact_dir|save_browser_polygon_widget|chromote|Chrome/Chromium" tests/testthat/helper-browser-polygon.R` | PASS |
| `rtk rg -n "POLY-02|POLY-03|path\\.geom-polygon|__gg2d3_polygon_brush|__gg2d3_polygon_click|__gg2d3_polygon_mouseover|phase44_polygon|_polygonPoints|clip-path|fill = NA|colour = NA" tests/testthat/test-polygon-browser.R` | PASS |
| `rtk rg -n "screenshot|pixel|visual diff|playwright|puppeteer|selenium" tests/testthat/test-polygon-browser.R tests/testthat/helper-browser-polygon.R` | PASS, no matches |
| `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | PASS with 4 explicit CRAN-like browser skips |
| `rtk env NOT_CRAN=true Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | PASS with 4 explicit optional-tool skips when chromote could not find an available port |
| `rtk Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | PASS: 41 interactivity assertions; browser file skipped 4 under CRAN-like gate |
| `rtk Rscript --vanilla -e 'devtools::test()'` | PASS: `0` failures, `6` warnings, `40` skips, `1041` passing assertions; polygon-browser executed live with `73` passing assertions |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed overly broad brush source assertion**
- **Found during:** Task 2 (selector implementation)
- **Issue:** The new test searched the whole `brush.js` file for `geom-polygon.*data-cx`, which crossed unrelated sf lines and failed even though no polygon-specific branch existed.
- **Fix:** Tightened the assertion to inspect only source lines containing `geom-polygon`.
- **Files modified:** `tests/testthat/test-polygon-interactivity.R`
- **Verification:** `test-polygon-interactivity.R` passed after selector implementation.
- **Committed in:** `42a71d3`

**2. [Rule 1 - Bug] Fixed polygon browser skip helper message**
- **Found during:** Plan-level `devtools::test()`
- **Issue:** `skip_browser_polygon_smoke()` evaluated `conditionMessage(launch)` even when launch succeeded, causing errors in full-suite execution.
- **Fix:** Safely derived the launch message only when the launch result is a condition.
- **Files modified:** `tests/testthat/helper-browser-polygon.R`
- **Verification:** `test-polygon-browser.R` passed/skipped cleanly under both CRAN-like and forced `NOT_CRAN=true` runs.
- **Committed in:** `8320348`

**3. [Rule 1 - Bug] Fixed full function-expression custom handlers**
- **Found during:** Live polygon browser smoke in `devtools::test()`
- **Issue:** `events.js` compiled `d3_handlers(click = "function(event, d) { ... }")` strings as raw function bodies, so browser click/mouseover callbacks did not run.
- **Fix:** Added `compileEventHandler()` to support both full function expressions and raw handler bodies.
- **Files modified:** `inst/htmlwidgets/modules/events.js`, `tests/testthat/test-polygon-interactivity.R`
- **Verification:** `test-polygon-interactivity.R` passed, and full `devtools::test()` passed with live `polygon-browser` coverage.
- **Committed in:** `e6372b0`

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)  
**Impact on plan:** All fixes were required to make the planned selector and browser validation correct. No new public polygon API or out-of-scope geometry behavior was added.

## TDD Gate Compliance

- **Task 1 RED:** `75b1617` added source tests first. The test run produced the expected missing selector failures before production selector changes.
- **Task 2 GREEN:** `42a71d3` added the selector plumbing and made the source tests pass.
- **Task 3:** Browser smoke coverage was added after the renderer/selector implementation already existed. The CRAN-like direct command skipped cleanly, while the full suite later executed live polygon-browser coverage and passed after the scoped handler fix.

## Issues Encountered

- Local direct browser runs can skip when chromote cannot find an available port. The helper reports this explicitly as an optional-tool skip.
- Full `devtools::test()` did find an available browser session and executed `polygon-browser` live, producing 73 passing polygon browser assertions.

## Known Stubs

- `inst/htmlwidgets/modules/crosstalk.js:309` contains a pre-existing `Brush connection placeholder` console message. This plan only added `path.geom-polygon` to the selector array and did not depend on that placeholder path.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The plan reused the existing local htmlwidgets callback surface, selector plumbing, and optional browser execution path; no new network, auth, file-access, or schema boundary was introduced.

## Next Phase Readiness

Phase 44 is complete for POLY-01, POLY-02, and POLY-03. Phase 45 can now use ordinary polygon support as a stable baseline while investigating rect/tile edge behavior.

## Self-Check: PASSED

- Found summary file: `.planning/phases/44-ordinary-geom-polygon-support/44-03-SUMMARY.md`
- Found source test file: `tests/testthat/test-polygon-interactivity.R`
- Found browser helper file: `tests/testthat/helper-browser-polygon.R`
- Found browser test file: `tests/testthat/test-polygon-browser.R`
- Found task commit `75b1617`: `test(44-03): add failing polygon interactivity source tests`
- Found task commit `42a71d3`: `feat(44-03): wire polygon interaction selectors`
- Found task commit `8320348`: `test(44-03): add polygon browser smoke coverage`
- Found fix commit `e6372b0`: `fix(44-03): support function-expression event handlers`

---
*Phase: 44-ordinary-geom-polygon-support*
*Completed: 2026-05-24*
