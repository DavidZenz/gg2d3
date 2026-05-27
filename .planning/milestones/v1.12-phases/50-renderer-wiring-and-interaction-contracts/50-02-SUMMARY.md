---
phase: 50-renderer-wiring-and-interaction-contracts
plan: 02
subsystem: architecture
tags: [javascript, htmlwidgets, d3, interactivity, crosstalk, tests]
requires:
  - phase: 50-01
    provides: Internal geom contract metadata for selector coverage
provides:
  - Contract-derived event and brush interaction selectors with literal fallbacks
  - Contract-derived crosstalk selectors with explicit module-specific exclusions
  - Source-contract tests for event, brush, and crosstalk selector coverage
affects: [renderer-wiring, interactivity, crosstalk, tests]
tech-stack:
  added: []
  patterns: [contract-derived interaction selectors, explicit exclusion reasons]
key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/events.js
    - inst/htmlwidgets/modules/brush.js
    - inst/htmlwidgets/modules/crosstalk.js
    - tests/testthat/test-renderer-wiring-contracts.R
key-decisions:
  - "Derived events, brush, and crosstalk selectors at runtime from window.gg2d3.geomContracts with existing literal arrays retained as fallbacks."
  - "Kept crosstalk intentionally narrower than events and brush for dotplot, rug, and interval marks, with reason strings asserted by tests."
patterns-established:
  - "Interaction modules ask geomContracts.selectorsFor(surface) for their module-specific selector surface."
  - "Renderer wiring tests parse contract interaction blocks to guard polygon and sf selector coverage."
requirements-completed: [ARCH-02]
duration: 5min
completed: 2026-05-26
---

# Phase 50 Plan 02: Interaction Selector Contract Summary

**Event, brush, and crosstalk selectors now derive from internal geom contracts with tests guarding polygon, sf, and module-specific coverage**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-26T19:44:08Z
- **Completed:** 2026-05-26T19:48:56Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Updated `events.js` and `brush.js` to use `geomContracts.selectorsFor("events")` and `geomContracts.selectorsFor("brush")`, falling back to the previous literal selectors if the contract module is unavailable.
- Updated `crosstalk.js` to use `geomContracts.selectorsFor("crosstalk")` without making it blindly identical to event/brush coverage.
- Extended renderer wiring contract tests to assert polygon, sf, and annotation selector coverage across events, brush, and crosstalk.
- Added assertions that crosstalk dotplot, rug, and interval omissions are intentional and documented by reason strings.

## Task Commits

1. **Task 1: Wire events and brush selectors to contract coverage** - `373c8e8` (feat)
2. **Task 2: Validate crosstalk selector differences explicitly** - `b7fcd6e` (feat)

## Files Created/Modified

- `inst/htmlwidgets/modules/events.js` - Derives event selectors from the geom contract with fallback literals.
- `inst/htmlwidgets/modules/brush.js` - Derives brush selectors from the geom contract while preserving sf brush branch semantics.
- `inst/htmlwidgets/modules/crosstalk.js` - Derives crosstalk selectors from the geom contract with narrower module-specific coverage.
- `tests/testthat/test-renderer-wiring-contracts.R` - Adds interaction selector contract parsing and assertions.

## Decisions Made

Crosstalk remains intentionally narrower than event and brush selection. Dotplot, rug, and interval component marks are not added to crosstalk in this plan because the existing module did not bind them; the contract now records those differences explicitly instead of hiding them in a duplicated selector list.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

One fixed-string assertion initially used regex-style escaping for crosstalk reason text. The assertion was corrected before the crosstalk task commit and the contract tests passed.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` - passed.
- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'` - passed with the expected optional `{sf}` skip.
- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'` - passed with expected optional `{sf}` skips.
- `git diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 50-03 can now centralize public payload sanitization against the same geom contract private-field vocabulary, covering tooltips, hover/click handlers, and brush payloads.

---
*Phase: 50-renderer-wiring-and-interaction-contracts*
*Completed: 2026-05-26*
