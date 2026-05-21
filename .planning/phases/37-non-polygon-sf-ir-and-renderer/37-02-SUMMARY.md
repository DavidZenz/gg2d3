---
phase: 37-non-polygon-sf-ir-and-renderer
plan: 02
status: complete
completed: 2026-05-21
requirements: [SFGEOM-03, SFGEOM-04]
commits:
  - 43db925 test(37-02): add sf renderer family source contracts
  - 7ed48ec feat(37-02): render sf points and lines by family
  - 1b132ed test(37-02): add sf renderer IR smoke fixtures
---

# Plan 37-02 Summary

Refactored `sf.js` to render sf geometries by family through one panel projection. Polygons remain `path.geom-sf` and now also carry `geom-sf-polygon`; lines render as no-fill `path.geom-sf.geom-sf-line`; points and multipoints render as `circle.geom-sf.geom-sf-point` marks with stable row ids and finite anchor attributes.

Added renderer source tests for the family dispatch contract and IR smoke tests proving point, multipoint, line, multiline, and stacked polygon+point data arrive with the metadata the renderer needs.

## Verification

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-renderer.R")'` passed.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R"); testthat::test_file("tests/testthat/test-sf-renderer.R")'` passed.

## Self-Check

PASSED. The renderer keeps polygon compatibility while drawing visible point and line sf marks with shared `.geom-sf` semantics, row ids, anchors, and core styling.
