---
phase: 35-geom-sf-docs-and-validation-hardening
plan: 01
subsystem: documentation
tags: [geom_sf, sf, roxygen, README, vignettes]

requires:
  - phase: 32-geom-sf-ir-foundation
    provides: geom_sf IR extraction, CRS normalization, and skipped-row diagnostics
  - phase: 33-single-panel-renderer-and-interactivity
    provides: geom_sf path rendering, centroid brushing, and zoom suppression
  - phase: 34-stacked-and-faceted-projection-alignment
    provides: stacked and faceted sf projection behavior
provides:
  - Public polygon-family geom_sf support contract in README, vignettes, diagnostics, and help
  - Generated README.md and roxygen Rd output synchronized with source docs
affects: [phase-35-validation, SFDOC-01, geom_sf-docs]

tech-stack:
  added: []
  patterns: [source-first generated docs, explicit support-boundary documentation]

key-files:
  created:
    - .planning/phases/35-geom-sf-docs-and-validation-hardening/35-01-SUMMARY.md
  modified:
    - README.Rmd
    - README.md
    - vignettes/gg2d3.Rmd
    - vignettes/gg2d3-interactivity.Rmd
    - vignettes/d3-drawing-diagnostics.md
    - R/gg2d3.R
    - R/sf_utils.R
    - R/d3_zoom.R
    - man/gg2d3.Rd
    - man/d3_zoom.Rd
    - man/extract_sf_geometries.Rd
    - man/normalize_to_wgs84.Rd
    - man/detect_dominant_geom_type.Rd
    - man/get_layer_crs.Rd

key-decisions:
  - "Document geom_sf as polygon-family support only: POLYGON and MULTIPOLYGON."
  - "Keep README concise and put detailed CRS, skipped-row, interactivity, and anti-feature boundaries in vignettes/help."
  - "Suppress public Rd generation for the internal prepare_sf_geometry_ir() helper with @noRd."

patterns-established:
  - "Generated outputs are rebuilt from README.Rmd and roxygen source; generated files were not hand-edited."
  - "Map anti-features are documented explicitly alongside supported polygon-family behavior."

requirements-completed: [SFDOC-01]

duration: 5min
completed: 2026-05-20T15:31:00Z
---

# Phase 35 Plan 01: geom_sf Docs Support Contract Summary

**Polygon-family geom_sf support is now documented consistently across README, vignettes, diagnostics, roxygen source, and generated help.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-20T15:26:54Z
- **Completed:** 2026-05-20T15:31:00Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Added a concise README `geom_sf()` support note for polygon-family choropleths and overlays.
- Added a main vignette `geom_sf()` section with an `sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)` example and the exact CRS/skipped-row warning contract.
- Updated interactivity and diagnostics docs to describe `path.geom-sf`, centroid brushing, zoom suppression, and explicit map anti-features.
- Added roxygen source notes and regenerated README/Rd output from source documentation.

## Task Commits

1. **Task 35-01-01: Update source documentation support contract** - `8239c14` (`docs`)
2. **Task 35-01-02: Regenerate README and roxygen help output** - `27160af` (`docs`)

## Files Created/Modified

- `README.Rmd` - Source README polygon-family `geom_sf()` support note.
- `README.md` - Generated README output from `README.Rmd`.
- `vignettes/gg2d3.Rmd` - Main vignette `geom_sf()` example and support contract.
- `vignettes/gg2d3-interactivity.Rmd` - Sf tooltip/hover/handler, centroid brush, and zoom caveats.
- `vignettes/d3-drawing-diagnostics.md` - Replaced stale unsupported `geom_sf` claim with current support boundaries.
- `R/gg2d3.R` - Main widget roxygen support-boundary note.
- `R/sf_utils.R` - Sf helper roxygen warning/scope notes and internal helper `@noRd`.
- `R/d3_zoom.R` - Zoom suppression roxygen note with exact warning.
- `man/gg2d3.Rd` - Generated main widget help.
- `man/d3_zoom.Rd` - Generated zoom help.
- `man/extract_sf_geometries.Rd` - Generated sf geometry extraction help.
- `man/normalize_to_wgs84.Rd` - Generated CRS normalization help.
- `man/detect_dominant_geom_type.Rd` - Generated geometry type help.
- `man/get_layer_crs.Rd` - Generated CRS metadata help.

## Verification

- `rtk rg -n "polygon-family|POLYGON|MULTIPOLYGON|coordinates will be serialized as-is|zoom has been suppressed|tile basemaps|slippy map controls|JavaScript-side CRS reprojection|polygon-overlap brushing" README.Rmd vignettes/gg2d3.Rmd vignettes/gg2d3-interactivity.Rmd vignettes/d3-drawing-diagnostics.md R/gg2d3.R R/sf_utils.R R/d3_zoom.R`
- `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'`
- `rtk rg -n "README.md is generated from README.Rmd" README.md`
- `rtk rg -n "polygon-family" README.md`
- `rtk rg -n "geom_sf" man/gg2d3.Rd man/d3_zoom.Rd`
- `rtk rg -n "zoom has been suppressed" man/d3_zoom.Rd`
- `rtk rg -n "unsupported.*geom_sf|geom_sf.*unsupported" README.md man vignettes R`
- `rtk rg -n "polygon-family|POLYGON|MULTIPOLYGON|coordinates will be serialized as-is|zoom has been suppressed" README.Rmd README.md vignettes R man`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Suppressed generated public help for an internal helper**
- **Found during:** Task 35-01-02
- **Issue:** `devtools::document()` generated an untracked `man/prepare_sf_geometry_ir.Rd` for an internal helper outside the plan's public help surface.
- **Fix:** Added `@noRd` to the helper roxygen block and reran `devtools::document(); devtools::build_readme()`.
- **Files modified:** `R/sf_utils.R`
- **Verification:** `rtk git status --short` no longer showed `man/prepare_sf_geometry_ir.Rd`; generated help checks passed.
- **Committed in:** `27160af`

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Kept generated public documentation scoped to the assigned help files without changing runtime behavior.

## Known Stubs

None. Stub-pattern scan found only expected `NA_* if not available` API documentation in CRS help/source.

## Threat Flags

None. This plan changed documentation only and introduced no new endpoints, auth paths, file access paths, schema changes, or trust-boundary runtime behavior.

## Issues Encountered

- `devtools::document(); devtools::build_readme()` completed successfully but reported outdated development dependencies: `bslib` 0.10.0 vs 0.11.0 and `cpp11` 0.5.4 vs 0.5.5. No dependency updates were required for this docs plan.
- Concurrent executor changes remained dirty in `tests/testthat/test-sf-interactivity.R`, `tests/testthat/test-sf-ir.R`, `tests/testthat/test-sf-renderer.R`, `tests/testthat/test-sf-utils.R`, and `tests/testthat/test-zoom-brush.R`; this plan did not touch them.

## User Setup Required

None.

## Next Phase Readiness

SFDOC-01 is ready for Phase 35 validation. The docs now state the exact warning strings, polygon-family geometry scope, sf interactivity caveats, zoom suppression, and explicit map anti-features required by downstream verification.

## Self-Check: PASSED

- Summary file exists: `.planning/phases/35-geom-sf-docs-and-validation-hardening/35-01-SUMMARY.md`
- Task commit exists: `8239c14`
- Task commit exists: `27160af`

---
*Phase: 35-geom-sf-docs-and-validation-hardening*
*Completed: 2026-05-20*
