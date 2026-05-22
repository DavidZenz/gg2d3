---
phase: 38-sf-interaction-facet-and-documentation-hardening
plan: 03
subsystem: documentation
tags: [sf, docs, roxygen, README, vignettes]

requires:
  - phase: 38-01-sf-interaction-browser-gates
    provides: sf family interactivity browser assertions
  - phase: 38-02-sf-facet-validation
    provides: sf family facet and empty-panel validation
provides:
  - Public v1.9 sf support contract across README and vignettes
  - Interaction and diagnostics docs for sanitized source-row payloads, representative-anchor brushing, zoom suppression, and map anti-features
  - Refreshed roxygen-generated help and README output
affects: [README, vignettes, roxygen, man-pages]

tech-stack:
  added: []
  patterns: [source-doc then generated-doc refresh, explicit sf anti-feature documentation]

key-files:
  created: []
  modified:
    - README.Rmd
    - README.md
    - vignettes/gg2d3.Rmd
    - vignettes/gg2d3-interactivity.Rmd
    - vignettes/d3-drawing-diagnostics.md
    - R/gg2d3.R
    - R/d3_tooltip.R
    - R/d3_hover.R
    - R/d3_handlers.R
    - R/d3_brush.R
    - R/d3_zoom.R
    - man/gg2d3.Rd
    - man/d3_tooltip.Rd
    - man/d3_hover.Rd
    - man/d3_handlers.Rd
    - man/d3_brush.Rd
    - man/d3_zoom.Rd
    - man/extract_sf_geometries.Rd
    - man/detect_dominant_geom_type.Rd

key-decisions:
  - "Document v1.9 sf as a family contract: polygon-family, point-family, and line-family support with explicit unsupported geometry behavior."
  - "Name map anti-features directly instead of implying general map-engine behavior."
  - "Keep generated README.md and Rd files in sync with source docs through devtools::document() and devtools::build_readme()."

patterns-established:
  - "README keeps the sf contract compact while the main/interactivity/diagnostics vignettes carry the detailed behavior and limits."
  - "Roxygen help topics explain sf interactivity semantics at the exported API where users discover the functions."

requirements-completed: [SFXDOC-03]

duration: 5 min
completed: 2026-05-22
---

# Phase 38 Plan 03: sf Documentation Hardening Summary

**Public docs and generated help now describe the v1.9 polygon, point, and line sf support contract with explicit interaction semantics and map limits**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-22T10:50:01Z
- **Completed:** 2026-05-22T10:54:44Z
- **Tasks:** 3
- **Files modified:** 19

## Accomplishments

- Updated README and the main vignette from v1.8 polygon-only wording to the v1.9 polygon-family, point-family, and line-family contract.
- Updated interactivity and diagnostics docs to describe sanitized source-row payloads, representative-anchor brushing, sf browser validation, zoom suppression, unsupported geometries, and map anti-features.
- Updated roxygen source and regenerated README/Rd output so generated package help matches the source documentation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Update README and main vignette sf support contract** - `b81b157` (docs)
2. **Task 2: Update interactivity and diagnostics docs with precise sf limits** - `16216bf` (docs)
3. **Task 3: Update roxygen help and regenerate generated docs** - `4b75383` (docs)

**Plan metadata:** pending

## Files Created/Modified

- `README.Rmd`, `README.md` - Public compact sf support summary.
- `vignettes/gg2d3.Rmd` - Main tutorial-level v1.9 sf support contract.
- `vignettes/gg2d3-interactivity.Rmd` - Interaction semantics for `.geom-sf`, sanitized payloads, representative anchors, and zoom suppression.
- `vignettes/d3-drawing-diagnostics.md` - Unsupported sf behavior and map anti-features.
- `R/*.R`, `man/*.Rd` - Exported API help updated and regenerated.

## Decisions Made

- Kept docs honest about gg2d3 being an SVG/htmlwidgets renderer, not a general map engine.
- Included `man/extract_sf_geometries.Rd` and `man/detect_dominant_geom_type.Rd` because roxygen regenerated stale helper docs from already-updated source.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Non-blocking] Included two additional regenerated sf helper Rd files**
- **Found during:** Task 3 (Update roxygen help and regenerate generated docs)
- **Issue:** `devtools::document()` also refreshed `man/extract_sf_geometries.Rd` and `man/detect_dominant_geom_type.Rd`, which were stale relative to current source docs.
- **Fix:** Kept the generated updates rather than leaving source/generated documentation drift.
- **Files modified:** `man/extract_sf_geometries.Rd`, `man/detect_dominant_geom_type.Rd`.
- **Verification:** Roxygen generation exited 0 and source/generated phrase checks passed.
- **Committed in:** `4b75383`.

---

**Total deviations:** 1 auto-fixed (non-blocking generated-doc sync).
**Impact on plan:** No scope change. Generated docs are more consistent with source.

## Issues Encountered

`devtools::build_readme()` succeeded. It reported advisory dependency freshness notices for `bslib` and `cpp11`; no install was required.

## User Setup Required

None.

## Next Phase Readiness

Phase-level verification can now check all SFXDOC requirements and mark Phase 38 complete.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` exited 0.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-interactivity.R")'` passed with 90 assertions.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` passed with 164 assertions.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-browser.R")'` exited 0 with clean skips for live browser tests.

---
*Phase: 38-sf-interaction-facet-and-documentation-hardening*
*Completed: 2026-05-22*
