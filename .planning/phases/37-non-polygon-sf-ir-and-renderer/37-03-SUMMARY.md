---
phase: 37-non-polygon-sf-ir-and-renderer
plan: 03
status: complete
completed: 2026-05-21
requirements: [SFGEOM-03]
commits:
  - 3742d97 test(37-03): add sf interactivity family contracts
  - e37b53a feat(37-03): extend sf interactivity selectors and brush dedupe
---

# Plan 37-03 Summary

Updated shared interactivity selectors so tooltip, hover, handlers, and brush reach every sf mark via `.geom-sf`, covering polygon paths, line paths, and point circles. Brush hit testing now checks sf `data-cx`/`data-cy` anchors before generic element fallback, and selected rows are deduplicated by non-null `row_id` so multipoint child circles report one source row.

Payload sanitization continues to remove underscore-prefixed renderer internals, including `_geom`, `_centroid`, `_sfFamily`, and point-child metadata.

## Verification

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-sf-interactivity.R")'` passed.

## Self-Check

PASSED. sf point, line, and polygon marks participate in the shared interactivity path while public brush/callback data remains source-row-oriented and sanitized.
