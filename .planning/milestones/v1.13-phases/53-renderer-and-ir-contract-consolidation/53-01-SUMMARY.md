---
phase: 53-renderer-and-ir-contract-consolidation
plan: 01
subsystem: testing
tags: [testthat, renderer-contracts, htmlwidgets, d3]

requires:
  - phase: 52-ci-visual-regression-foundation
    provides: browser visual smoke foundation and artifact checks
provides:
  - Renderer module source/load-order contract checks
  - Explicit renderer exception assertions
  - Public payload sanitizer coverage checks
affects: [renderer-contracts, phase-53-ir-boundaries, phase-53-validation]

tech-stack:
  added: []
  patterns: [source-level renderer contracts, explicit unsupported-surface reasons]

key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/geom-contracts.js
    - tests/testthat/test-renderer-wiring-contracts.R

key-decisions:
  - "Renderer contract tests now verify declared module paths, htmlwidgets load order, and render selectors against source."
  - "Intentional empty update/interaction surfaces must be explicit and reason-bearing."
  - "Public payload expectations remain contract-level declarations and are backed by sanitizer checks."

patterns-established:
  - "Use contract_modules(), yaml_script_entries(), and selector_supported_by_module() for source/load-order contract assertions."
  - "Use reason-bearing selector exceptions instead of bare empty arrays for unsupported interaction surfaces."

requirements-completed:
  - 53-01-01
  - 53-01-02

duration: 34 min
completed: 2026-05-28
---

# Phase 53 Plan 01: Renderer Contract Hardening Summary

**Renderer contract tests now guard module reachability, load order, selector drift, explicit exceptions, and public payload sanitizer coverage.**

## Performance

- **Duration:** 34 min
- **Completed:** 2026-05-28
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added source-level contract helpers and tests for renderer module paths, `gg2d3.yaml` script load order, and declared render selectors.
- Added exception checks so empty update and interaction surfaces must carry explicit reasons.
- Added public payload checks so every geom declares `publicPayload` and all contract private fields remain underscore-prefixed.
- Converted hline/vline/abline interaction exceptions from bare empty arrays to reason-bearing selector exceptions.
- Removed the stale `line.geom-boxplot-staple` render selector from the boxplot contract because the renderer never emits that class.

## Task Commits

1. **Task 1: Verify module paths, load order, and render selectors** - `d2dd84e` (test)
2. **Task 2: Enforce explicit exceptions and payload sanitizer coverage** - `b8b2490` (test)

## Files Created/Modified

- `tests/testthat/test-renderer-wiring-contracts.R` - Adds contract source helpers and tests for module/load-order/selector drift, reason-bearing exceptions, and public payload sanitizer coverage.
- `inst/htmlwidgets/modules/geom-contracts.js` - Adds reason-bearing interaction exceptions for reference marks and removes one stale boxplot selector declaration.

## Deviations from Plan

### Auto-fixed Issues

- Removed `line.geom-boxplot-staple` from the contract. The plan expected source checks to pass against existing declarations, but the new test found this stale selector; `geoms/boxplot.js` does not emit the class, so the contract was corrected.

---

**Total deviations:** 1 auto-fixed.
**Impact on plan:** No scope expansion; contract now matches renderer output more accurately.

## Verification

- `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` - passed with 594 passes.
- `rtk rg -n "contract_modules|contract_render_selectors|yaml_script_entries|selector_class_tokens|selector_supported_by_module" tests/testthat/test-renderer-wiring-contracts.R` - passed.
- `rtk rg -n "geom contract module paths and htmlwidgets load order are complete|geom contract render selectors are produced by declared renderer modules" tests/testthat/test-renderer-wiring-contracts.R` - passed.
- `rtk rg -n "Missing contract module|Missing yaml script|Missing renderer selector|Load order drift" tests/testthat/test-renderer-wiring-contracts.R` - passed.
- `rtk rg -n "contract_update_exceptions|contract_interaction_exceptions|contract_public_payloads|contract_private_fields" tests/testthat/test-renderer-wiring-contracts.R` - passed.
- `rtk rg -n "geom contract exceptions are explicit and reason-bearing|geom contract public payload expectations are sanitizer-covered" tests/testthat/test-renderer-wiring-contracts.R` - passed.
- `rtk rg -n "reason: '.*currently|reason: \".*currently|publicPayload: true|publicPayload: false" inst/htmlwidgets/modules/geom-contracts.js` - passed.
- `rtk rg -n "publicData\\.sanitizeDatum|_polygonPoints|_sourceIndex|_geom|_centroid|_sfFamily|_sfAnchor|_pointCoord|_pointIndex" tests/testthat/test-renderer-wiring-contracts.R` - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 can extract IR helper boundaries with renderer contract tests already guarding the JavaScript side.

## Self-Check: PASSED

---
*Phase: 53-renderer-and-ir-contract-consolidation*
*Completed: 2026-05-28*
