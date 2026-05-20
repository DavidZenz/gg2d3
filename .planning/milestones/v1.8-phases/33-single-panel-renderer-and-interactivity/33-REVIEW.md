---
phase: 33-single-panel-renderer-and-interactivity
reviewed: 2026-05-20T13:55:09Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - inst/htmlwidgets/modules/geoms/sf.js
  - inst/htmlwidgets/modules/events.js
  - inst/htmlwidgets/modules/tooltip.js
  - inst/htmlwidgets/modules/brush.js
  - R/d3_zoom.R
  - tests/testthat/test-sf-interactivity.R
  - tests/testthat/test-zoom-brush.R
  - tests/testthat/test-sf-renderer.R
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
resolved:
  warning: 1
status: clean
---

# Phase 33: Code Review Report

**Reviewed:** 2026-05-20T13:55:09Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** clean after fix

## Summary

Reviewed the Phase 33 sf renderer, event selector integration, tooltip sanitization, brush selection, zoom suppression, and focused tests. The initial review found one warning: `path.geom-sf` custom handlers exposed raw renderer-private fields. That warning was fixed in `2a82fe6` by sanitizing handler and Shiny payloads in `events.js`; the focused R tests pass after the fix.

Verification run:

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R")'` - passed
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-interactivity.R")'` - passed
- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-zoom-brush.R")'` - passed

## Resolved Warnings

### WR-01: Sf Custom Handlers Leak Renderer-Private Fields

**File:** `inst/htmlwidgets/modules/events.js:668`

**Issue:** Phase 33 adds `path.geom-sf` to the shared interactive selector list, which means `d3_handlers()` and `shiny_id` now run on sf paths too. Unlike tooltip rows and brush callback rows, `attachHandlers()` forwarded the raw bound datum to user callbacks and Shiny. For sf paths that datum includes `_geom` and `_centroid` from `sf.js`, so the new handler support exposed private renderer fields and potentially large GeoJSON payloads despite the phase sanitization contract.

**Resolution:** Fixed in `2a82fe6`. `events.js` now defines `sanitizeEventDatum()` and sends sanitized data to click handlers, mouseover/mouseout handlers, and Shiny `setInputValue()`. `tests/testthat/test-sf-interactivity.R` now guards that handler path.

## Info

### IN-01: Sanitization Tests Are Source-String Checks, Not Callback Behavior Tests

**File:** `tests/testthat/test-sf-interactivity.R:31`

**Issue:** The tooltip and brush sanitization tests only assert that helper names and string fragments exist. They do not execute the JavaScript sanitizer behavior or cover the newly exposed custom handler/Shiny callback path. This allowed the raw handler datum leak above to remain untested.

**Fix:** Add a small JS-runtime test harness or source a module in a DOM-capable test fixture so callback payload assertions use an input row containing `_geom`, `_centroid`, and public fields, then assert only public fields reach tooltip formatters, brush `on_brush`, and custom handlers.

---

_Reviewed: 2026-05-20T13:55:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
