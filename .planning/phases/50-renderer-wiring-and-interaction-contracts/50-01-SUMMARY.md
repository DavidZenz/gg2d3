---
phase: 50-renderer-wiring-and-interaction-contracts
plan: 01
subsystem: architecture
tags: [javascript, htmlwidgets, d3, renderer-contracts, tests]
requires:
  - phase: 49
    provides: R-side IR helper boundary hardening completed before JS renderer hardening
provides:
  - Internal geom contract metadata for supported renderer aliases, update selectors, interaction selectors, and private fields
  - Source-contract tests for renderer registration and update selector coverage
affects: [renderer-wiring, geom-registry, interactivity, tests]
tech-stack:
  added: []
  patterns: [internal JS contract module, source-level contract tests]
key-files:
  created:
    - inst/htmlwidgets/modules/geom-contracts.js
    - tests/testthat/test-renderer-wiring-contracts.R
  modified:
    - inst/htmlwidgets/gg2d3.yaml
key-decisions:
  - "Kept geom contracts internal under window.gg2d3.geomContracts rather than creating a public extension API."
  - "Marked abline, sf, sf_text, and sf_label update coverage as explicit-none because updateGeoms() has no branches for them today."
  - "Used source-level R tests to compare renderer registrations and update selectors without requiring browser launch."
patterns-established:
  - "Geom contract entries carry aliases, render selectors, update metadata, interaction selectors, private fields, and public payload expectations."
  - "Renderer wiring tests parse JavaScript source to fail when supported aliases or update selectors drift."
requirements-completed: [ARCH-02]
duration: 16min
completed: 2026-05-26
---

# Phase 50 Plan 01: Renderer Contract Summary

**Internal geom contract metadata with source tests that guard renderer aliases and update selector coverage**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-26T19:27:20Z
- **Completed:** 2026-05-26T19:43:39Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `inst/htmlwidgets/modules/geom-contracts.js` with supported geom aliases, renderer selectors, update metadata, interaction selectors, private fields, and public payload flags.
- Loaded `geom-contracts.js` before tooltip, events, brush, crosstalk, and geom registry consumers in `inst/htmlwidgets/gg2d3.yaml`.
- Added `tests/testthat/test-renderer-wiring-contracts.R` to compare registered renderer aliases and non-excluded update selectors against the contract.
- Preserved explicit no-update documentation for `abline`, `sf`, `sf_text`, and `sf_label`.

## Task Commits

1. **Task 1: Add internal geom contract module** - `59161ca` (feat)
2. **Task 2: Add renderer registration and update coverage contract tests** - `c277736` (test)

## Files Created/Modified

- `inst/htmlwidgets/modules/geom-contracts.js` - Internal geom wiring contract and helper accessors.
- `inst/htmlwidgets/gg2d3.yaml` - Loads the contract module before renderer/interactivity consumers.
- `tests/testthat/test-renderer-wiring-contracts.R` - Source-contract tests for aliases, update selectors, and private fields.

## Decisions Made

The contract is intentionally internal and loaded as a classic htmlwidgets script. This matches the existing `window.gg2d3.*` module pattern and avoids creating a public plugin API in Phase 50.

`abline`, `sf`, `sf_text`, and `sf_label` use `update.type: "explicit-none"` because the current `updateGeoms()` implementation does not update those marks during zoom/reset. The contract makes that visible instead of silently implying coverage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` - passed.
- `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-zoom-path-datum.R")'` - passed.
- `git diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 50-02 can now use `geomContracts.selectorsFor(surface)` or source-contract validation to reduce duplicated events, brush, and crosstalk selector wiring.

---
*Phase: 50-renderer-wiring-and-interaction-contracts*
*Completed: 2026-05-26*
