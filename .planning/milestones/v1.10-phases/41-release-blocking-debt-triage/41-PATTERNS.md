# Phase 41 Pattern Map

## Files and Roles

| File | Role | Closest Pattern |
|------|------|-----------------|
| `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md` | Release debt classification artifact | Phase 40 audit artifacts such as `40-DEPENDENCY-AUDIT.md`, `40-SKIP-AUDIT.md`, and `40-ARTIFACT-AUDIT.md` |
| `DESCRIPTION` | Package metadata evidence for dependency advisory | Phase 40 dependency hygiene plan |
| `tests/testthat/test-sf-browser.R` | Browser sf panel identity evidence and possible regression target | Existing BRSF and SFGEOM browser tests |
| `README.Rmd` and `README.md` | Public support contract | Existing README support table and generated README pair |
| `vignettes/gg2d3.Rmd` | Main vignette support and unsupported-geom contract | Existing error-handling and edge-case section |
| `vignettes/d3-drawing-diagnostics.md` | Known limitation diagnostics | Existing rect/tile and private API diagnostic notes |
| `R/as_d3_ir.R` and `R/validate_ir.R` | Ordinary polygon IR recognition | Existing geom mapping and validation lists |
| `inst/htmlwidgets/modules/geoms/rect.js` | Rect/tile renderer behavior | Existing renderer module pattern |
| `tests/testthat/test-regression-core.R` | Focused regression coverage | Existing HARD regression matrix |

## Reusable Patterns

### Audit Artifact

Phase 40 audit artifacts use a stable pattern:

- Define the scan or evidence source.
- List findings.
- Record required changes.
- Record verification evidence.

Phase 41 should use the same shape but add release-blocking classification fields:

- Item
- Requirement
- Evidence
- Status
- Release-blocking judgment
- Action
- Rationale
- Next step

### Browser Facet Evidence

`tests/testthat/test-sf-browser.R` already uses ordered expected vectors for panel-local counts. Phase 41 should preserve that direct vector comparison instead of sorting counts.

### Documentation Contract Updates

README source is `README.Rmd`; tracked `README.md` should be kept synchronized if README support text changes. Avoid treating root `README.html` as a source artifact.

### Renderer Source Checks

Renderer behavior can be guarded with source-level tests or `rtk rg` checks when a browser run is not required. Phase 41 should avoid adding heavyweight browser tooling or screenshot-diff infrastructure.
