---
phase: 59-release-hygiene-and-local-spatial-recovery
plan: "02"
subsystem: diagnostics
tags: [sf, gdal, pkgdown, diagnostics, release-hygiene]
requires:
  - phase: 59-release-hygiene-and-local-spatial-recovery
    provides: Phase 59 context and local spatial recovery decision
provides:
  - Local spatial stack diagnostic command
  - Maintainer docs for interpreting `classified_skip`
  - README pointer to local sf/GDAL diagnostics
affects: [pkgdown-validation, sf-evidence, maintainer-docs]
tech-stack:
  added: []
  patterns: [Rscript diagnostic command reusing pkgdown helper classification]
key-files:
  created:
    - tools/diagnose-spatial-stack.R
  modified:
    - vignettes/d3-drawing-diagnostics.md
    - README.Rmd
    - README.md
key-decisions:
  - "Use a diagnostic command instead of attempting to repair the local Homebrew/R spatial stack."
  - "Treat local `classified_skip` as acceptable only when diagnostics show `sf` or `geojsonsf` is not loadable."
patterns-established:
  - "Local optional dependency diagnostics print stable markers for evidence ledgers."
requirements-completed:
  - REL-02
duration: 5 min
completed: 2026-06-02
---

# Phase 59 Plan 02: Spatial Stack Diagnostics Summary

**Local `sf`/GDAL diagnostic command with docs that separate environment repair from gg2d3 regressions**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-02T11:17:28Z
- **Completed:** 2026-06-02T11:20:37Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `tools/diagnose-spatial-stack.R`, which reports `sf` and `geojsonsf` loadability, pkgdown sf outcome, and a maintainer recommendation.
- Documented local sf/GDAL diagnostics and repair semantics in `vignettes/d3-drawing-diagnostics.md`.
- Added matching README source/output pointers to the diagnostic command.

## Task Commits

1. **Tasks 1-3: add diagnostic script, document repair flow, verify command/docs** - `85e3aad` (feat)

## Files Created/Modified

- `tools/diagnose-spatial-stack.R` - New local diagnostic command for spatial package loadability and pkgdown sf outcome.
- `vignettes/d3-drawing-diagnostics.md` - Documents local sf/GDAL diagnostics, output markers, and repair flow.
- `README.Rmd` - Adds source pointer to the diagnostic command.
- `README.md` - Mirrors README diagnostic pointer.

## Decisions Made

- Used `loadNamespace()` inside `tryCatch()` so dynamic-library failures produce `not_loadable:` messages instead of aborting.
- Reused `pkgdown_site_sf_outcome()` for generated-site classification rather than duplicating HTML parsing.
- Mirrored the README pointer manually because the required wording was short and no broader README regeneration was needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Local `sf` remains not loadable because `/opt/homebrew/opt/gdal/lib/libgdal.38.dylib` is missing. The diagnostic command records this as local environment repair, not a gg2d3 regression.

## User Setup Required

None for this plan. Maintainers who want rendered local sf evidence must repair or reinstall the local spatial stack, then rerun release validation.

## Next Phase Readiness

Plan 59-03 can consume `tools/diagnose-spatial-stack.R` output and record local spatial status in `59-VERIFICATION.md`.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'parse("tools/diagnose-spatial-stack.R"); cat("script parses\n")'` passed.
- `rtk Rscript --vanilla tools/diagnose-spatial-stack.R` passed and reported `sf: not_loadable`, `geojsonsf: loadable version 2.0.5`, `pkgdown sf outcome: classified_skip`, and a repair recommendation.
- `rtk Rscript --vanilla tools/diagnose-spatial-stack.R --site-root docs` passed with the same local classification.
- `rtk rg -n "Local sf/GDAL diagnostics|tools/diagnose-spatial-stack.R|local environment repair, not a gg2d3 regression|validate-pkgdown-site.R --mode release|classified_skip" vignettes/d3-drawing-diagnostics.md` passed.
- `rtk rg -n "tools/diagnose-spatial-stack.R|d3-drawing-diagnostics" README.Rmd README.md` passed.
- `rtk rg -n "Local sf/GDAL diagnostics|diagnose-spatial-stack|pkgdown sf outcome|recommendation" tools/diagnose-spatial-stack.R vignettes/d3-drawing-diagnostics.md README.Rmd README.md` passed.

---
*Phase: 59-release-hygiene-and-local-spatial-recovery*
*Completed: 2026-06-02*
