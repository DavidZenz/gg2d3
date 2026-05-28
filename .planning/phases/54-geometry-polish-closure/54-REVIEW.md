---
phase: 54-geometry-polish-closure
reviewed: 2026-05-28T18:47:37Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - R/ir_layer_helpers.R
  - R/validate_ir.R
  - README.Rmd
  - README.md
  - inst/htmlwidgets/modules/geom-contracts.js
  - inst/htmlwidgets/modules/geom-registry.js
  - inst/htmlwidgets/modules/geoms/rect.js
  - inst/htmlwidgets/modules/geoms/text.js
  - tests/testthat/test-polygon-ir.R
  - tests/testthat/test-polygon-renderer.R
  - tests/testthat/test-rect-tile-ir.R
  - tests/testthat/test-rect-tile-renderer.R
  - tests/testthat/test-renderer-wiring-contracts.R
  - tests/testthat/test-text-label-polish.R
  - vignettes/d3-drawing-diagnostics.md
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 54: Code Review Report

**Reviewed:** 2026-05-28T18:47:37Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the Phase 54 IR helpers, validation, text/label and rect/tile renderer changes, renderer contract wiring, focused tests, README, and diagnostics documentation. The focused R/testthat suites for text/label polish, rect/tile IR and renderer contracts, renderer wiring contracts, polygon IR, and polygon renderer contracts passed locally.

One high-confidence user-visible issue remains: the new contract advertises brush support for ordinary `geom_label()` groups, but the existing brush hit-testing path does not handle SVG `<g>` elements.

## Warnings

### WR-01: `geom_label()` brush contract selects an unsupported SVG group

**File:** `inst/htmlwidgets/modules/geom-contracts.js:100`
**Issue:** The Phase 54 contract adds `g.geom-label` to the brush selectors, and `text.js` renders labels as `<g class="geom-label">` with `data-cx` / `data-cy` anchors. However, the brush hit-test implementation only recognizes `.geom-sf` anchors and primitive `circle`, `rect`, `text`, `line`, and `path` nodes. For a selected brush region, every `g.geom-label` falls through as unselected, so labels are dimmed even when their anchor is inside the brush and omitted from `on_brush` selected data.
**Fix:** Either remove `g.geom-label` from the brush contract until brush support exists, or update the brush hit-test to honor generic anchor attributes before tag-specific checks. Preferred fix:

```javascript
function isElementInPixelRect(node, rect) {
  var anchoredCx = parseFloat(node.getAttribute('data-cx'));
  var anchoredCy = parseFloat(node.getAttribute('data-cy'));
  if (Number.isFinite(anchoredCx) || Number.isFinite(anchoredCy)) {
    return isPointInPixelRect(anchoredCx, anchoredCy, rect);
  }

  var tagName = node.tagName.toLowerCase();
  // existing circle/rect/text/line/path handling...
}
```

Add a focused browser or source-level test that proves `g.geom-label` brush selection uses its `data-cx` / `data-cy` anchor rather than falling through as unselectable.

---

_Reviewed: 2026-05-28T18:47:37Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
