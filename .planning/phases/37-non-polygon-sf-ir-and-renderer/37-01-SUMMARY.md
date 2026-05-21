---
phase: 37-non-polygon-sf-ir-and-renderer
plan: 01
status: complete
completed: 2026-05-21
requirements: [SFGEOM-01, SFGEOM-02, SFGEOM-04]
commits:
  - 29f28d3 test(37-01): add non-polygon sf IR contracts
  - 467127e feat(37-01): support point and line sf IR families
  - 3205ad1 test(37-01): cover mixed sf panel bboxes
---

# Plan 37-01 Summary

Expanded the R-side `geom_sf()` IR contract from polygon-only to polygon, point, and line families. Accepted sf rows now carry `.sf_family`, layers carry `sf_family`, and diagnostics include `accepted_geometry_families` while preserving row-id and geometry/data parallelism.

Added contract tests for `POINT`, `MULTIPOINT`, `LINESTRING`, `MULTILINESTRING`, mixed accepted rows, unsupported `GEOMETRYCOLLECTION`, polygon+point overlays, polygon+line overlays, and empty facet panels.

## Verification

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-ir.R")'` passed.
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-renderer.R")'` passed as a pre-renderer regression check.

## Self-Check

PASSED. The IR now accepts point and line families by default, emits family metadata and diagnostics, and computes panel-scoped `sf_bbox` across mixed stacked and faceted sf panels.
