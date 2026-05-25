---
phase: 45-rect-and-tile-edge-closure
plan: 01
subsystem: testing
tags: [r, testthat, ggplot2, d3, rect, tile]

requires:
  - phase: 44-ordinary-geom-polygon-support
    provides: "Recent IR and renderer source-contract test patterns"
provides:
  - "RECT-01 rect/tile IR fixture matrix for scale limits, coord limits, discrete tiles, reverse scales, coord_flip, and facets"
  - "Rect/tile renderer and update-path source-contract tests"
  - "Classification artifact separating ggplot2-compatible behavior from Plan 45-02 fix candidates"
affects: [45-rect-and-tile-edge-closure, rect, tile, renderer-update]

tech-stack:
  added: []
  patterns: ["ggplot_build() versus as_d3_ir() characterization", "source contract tests for JavaScript renderer/update paths"]

key-files:
  created:
    - tests/testthat/test-rect-tile-ir.R
    - tests/testthat/test-rect-tile-renderer.R
    - .planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md
  modified: []

key-decisions:
  - "Scale-limit rect/tile bound censoring is ggplot2-compatible and should not be fixed in the renderer."
  - "Coordinate-limit rect/tile behavior should be treated as panel clipping, not data censoring."
  - "Plan 45-02 should focus on source-measurable initial stroke accessor and geom-registry update-path candidates."

patterns-established:
  - "RECT-01 matrix compares ggplot2 built rows with gg2d3 IR rows before renderer assumptions."
  - "Renderer source tests can require either parity logic or explicit classification for the follow-up plan."

requirements-completed: [RECT-01]

duration: 5m9s
completed: 2026-05-24
---

# Phase 45 Plan 01: Rect/Tile Evidence Matrix Summary

**Rect/tile edge behavior classified with ggplot2-built-data fixtures and renderer/update source contracts for Plan 45-02.**

## Performance

- **Duration:** 5m9s
- **Started:** 2026-05-24T19:50:35Z
- **Completed:** 2026-05-24T19:55:44Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `rect_tile_cases` covering continuous scale limits, `coord_cartesian()` limits, discrete `geom_tile()` limits, reversed scales, `coord_flip()`, and facets.
- Added source-contract tests for `rect.js` initial rendering and `geom-registry.js` update behavior.
- Created a classification artifact that marks scale-limit censoring and panel clipping as non-issues, while carrying source-measurable renderer/update candidates to Plan 45-02.

## Task Commits

1. **Task 1: Add the RECT-01 IR fixture matrix** - `8df6ba8` (test)
2. **Task 2: Add renderer/update source contracts and classification notes** - `a275331` (test)

## Files Created/Modified

- `tests/testthat/test-rect-tile-ir.R` - RECT-01 fixture matrix comparing `ggplot_build()` rows with `as_d3_ir()` rows.
- `tests/testthat/test-rect-tile-renderer.R` - Source-contract tests for rect/tile initial rendering and update paths.
- `.planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md` - Human-readable classification table and Plan 45-02 action notes.

## Decisions Made

- Scale limits and coordinate limits are classified separately: scale limits can censor bounds to `NA`, while coordinate limits preserve bounds for clipped rendering.
- Current initial rect rendering has the expected bounds, band, flip, and fill/opacity contracts, but stroke accessor parity remains a Plan 45-02 candidate.
- Current `geom-registry.js` rect updates target the right DOM nodes and geometry attributes, but lack explicit band-scale and flip branches matching `rect.js`; Plan 45-02 should patch or prove parity.

## Deviations from Plan

None - plan executed within the intended evidence-first scope.

## Issues Encountered

- The first Task 1 test draft assumed scale limits censor every bound in an affected row. The RED run showed ggplot2 can censor individual out-of-limit bounds instead. The test was corrected to compare the complete `NA` matrix between `ggplot_build()` and `as_d3_ir()`.

## Verification

Passed:

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'
```

## Known Stubs

None. The stub scan only found source-test null checks, not UI/data placeholders.

## Threat Flags

None. The plan adds tests and planning documentation only; no new network, auth, file-write, or endpoint trust boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 45-02 can use `45-RECT-TILE-CLASSIFICATION.md` to focus on the remaining source-measurable candidates: rect initial stroke accessor parity and `geom-registry.js` update-path band/flip parity.

## Self-Check: PASSED

- Created files verified with `rtk ls`.
- Task commits `8df6ba8` and `a275331` verified in `git log --oneline --all`.
- No tracked file deletions were present in either task commit.

---
*Phase: 45-rect-and-tile-edge-closure*
*Completed: 2026-05-24*
