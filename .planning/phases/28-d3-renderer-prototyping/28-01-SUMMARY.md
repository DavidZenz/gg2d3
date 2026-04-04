---
phase: 28-d3-renderer-prototyping
plan: "01"
subsystem: sf-geom-renderer
tags: [d3, geom-sf, geopath, ir, row-id]
dependency_graph:
  requires: [Phase 27 sf IR extraction]
  provides: [sf.js geom renderer, row_id in sf IR data rows]
  affects: [gg2d3.yaml script loading, geom registry]
tech_stack:
  added: [d3.geoIdentity, d3.geoPath]
  patterns: [IIFE geom module, geomRegistry.register, reflectY fitExtent]
key_files:
  created:
    - inst/htmlwidgets/modules/geoms/sf.js
    - tests/testthat/test-sf-renderer.R
  modified:
    - R/as_d3_ir.R
    - inst/htmlwidgets/gg2d3.yaml
key_decisions:
  - "row_id injected into df before to_rows() call so keep_aes inclusion is automatic"
  - "xScale/yScale params received but ignored in sf renderer — geoIdentity handles projection"
  - "Centroids pre-computed in single pass to avoid double computation in D3 .attr() calls"
  - "Null geometry handling: filtered from fitExtent FeatureCollection but kept in rows for positional alignment"
metrics:
  duration: "8 minutes"
  completed: "2026-04-04T18:07:16Z"
  tasks_completed: 2
  files_changed: 4
---

# Phase 28 Plan 01: sf.js Geom Renderer Summary

**One-liner:** D3 geom_sf renderer using geoIdentity+reflectY+fitExtent with row_id IR field for geometry-aesthetic join.

## What Was Built

Implemented the primary Phase 28 deliverable: a working D3 renderer for `geom_sf` layers that renders GeoJSON polygons as SVG path elements with correct projection, hole rendering, and aesthetic passthrough.

### Task 1: row_id in sf IR branch

Added `"row_id"` to the `keep_aes` vector in `R/as_d3_ir.R` so it survives the `intersect(keep_aes, names(df))` filter in `to_rows()`. Added `df[["row_id"]] <- seq_along(sf_geom_strings)` after `detect_dominant_geom_type()` call in the sf branch, before `to_rows(df)`. Created `tests/testthat/test-sf-renderer.R` with 5 test blocks (12 assertions) covering:

- row_id present in every sf data row
- row_id values are sequential integers 1..n
- geometries and data arrays have equal length
- row_id at position i equals i (positional correspondence)
- non-sf layers do not contain row_id (no regression)

### Task 2: sf.js geom renderer module

Created `inst/htmlwidgets/modules/geoms/sf.js` (113 lines) as an IIFE module following the point.js pattern. Key behaviors:

- Registered as `'sf'` in geomRegistry via `window.gg2d3.geomRegistry.register('sf', renderSf)`
- Uses `d3.geoIdentity().reflectY(true).fitExtent([[4,4],[w-4,h-4]], fc)` for projection (D-09, 4px padding per UI-SPEC)
- Applies `fill-rule="evenodd"` unconditionally on every path (D-08, REND-02)
- Writes `data-cx`/`data-cy` centroid attributes with `isFinite()` guard (D-11, Phase 29 prep)
- Writes `data-row-id` attribute for geometry-aesthetic join (D-06)
- Handles null geometries via JSON.parse try/catch
- `makeColorAccessors(layer, options)` for fill/stroke/opacity (REND-03)
- Pre-computes centroids in a single pass before the D3 `.data().enter()` chain

Updated `inst/htmlwidgets/gg2d3.yaml` to load `- geoms/sf.js` after `- geoms/smooth.js`.

## Verification Results

- `test-sf-renderer.R`: FAIL 0 | WARN 0 | SKIP 0 | PASS 12
- `test-sf-ir.R`: FAIL 0 | WARN 0 | SKIP 0 | PASS 24 (no regression)
- `devtools::test()` full suite: FAIL 0 | WARN 5 | SKIP 2 | PASS 700 (warnings are pre-existing polar-coord warnings unrelated to this plan)
- All acceptance criteria verified: sf.js >= 50 lines, geoIdentity+reflectY+fitExtent, fill-rule evenodd, data-cx/data-cy/data-row-id attributes, geoms/sf.js in yaml

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. The renderer is fully wired with real GeoJSON parsing, real projection, and real aesthetic passthrough.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1    | 2a98501 | feat(28-01): add row_id to sf branch IR and unit tests |
| 2    | 5a519c9 | feat(28-01): create sf.js geom renderer and wire into gg2d3.yaml |

## Self-Check: PASSED

- inst/htmlwidgets/modules/geoms/sf.js: FOUND
- tests/testthat/test-sf-renderer.R: FOUND
- Commit 2a98501: FOUND
- Commit 5a519c9: FOUND
