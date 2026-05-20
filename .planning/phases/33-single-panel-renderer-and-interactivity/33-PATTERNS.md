---
phase: 33
slug: single-panel-renderer-and-interactivity
status: complete
created: 2026-05-20
source: inline-pattern-mapping
---

# Phase 33 - Pattern Mapping

## Files and Closest Analogs

| Target File | Role | Closest Existing Pattern | Notes |
|-------------|------|--------------------------|-------|
| `inst/htmlwidgets/modules/geoms/sf.js` | D3 geom renderer | `inst/htmlwidgets/modules/geoms/rect.js`, `inst/htmlwidgets/modules/geoms/point.js` | Exports one renderer into `window.gg2d3.geoms`; binds row data to SVG elements and uses shared style helpers where possible. |
| `inst/htmlwidgets/modules/events.js` | Shared interactivity attachment | Existing selector-driven tooltip, hover, and handler functions in the same file | Add `path.geom-sf` to existing selectors instead of adding sf-specific event handlers. |
| `inst/htmlwidgets/modules/tooltip.js` | Tooltip formatting and row exposure | Existing `format(d, config, ir)` enrichment and internal-key filtering | Add a small row sanitization helper and use it consistently for default fields, explicit fields, and whole-row custom formatters. |
| `inst/htmlwidgets/modules/brush.js` | Brush selection and selected-data callbacks | Existing `isElementInPixelRect()` branches for circles, rects, text, and paths | Add an sf path branch before generic path bbox center handling. |
| `R/d3_zoom.R` | R interactivity config wrapper | Existing input validation and `htmlwidgets::onRender()` pattern in `R/d3_hover.R`, `R/d3_tooltip.R`, and current `R/d3_zoom.R` | Insert sf guard after validation and before config mutation/onRender attachment. |
| `tests/testthat/test-sf-renderer.R` | sf renderer/IR contract tests | Existing sf and geom tests using `skip_if_not_installed()` | Extend narrow sf assertions without requiring browser execution. |
| `tests/testthat/test-sf-interactivity.R` | sf interactivity contract tests | Source-contract test style used elsewhere in package tests | New file for Phase 33 so existing unrelated interactivity failures do not mask sf regressions. |
| `tests/testthat/test-zoom-brush.R` | Zoom/brush R API tests | Current non-sf `d3_zoom()` and `d3_brush()` tests | Add sf warning/suppression tests while preserving point-plot zoom expectations. |

## Existing Local Conventions

- R interactivity wrappers validate that input inherits `"gg2d3"`, initialize `widget$x$interactivity`, store a config list, then attach an `htmlwidgets::onRender()` callback.
- JS modules initialize `window.gg2d3` defensively and export named functions under submodules such as `window.gg2d3.tooltip` and `window.gg2d3.events`.
- Geom SVG classes follow `geom-*`, so sf should continue to use `geom-sf`.
- Tests prefer `pkgload::load_all(quiet = TRUE)` and `testthat::test_file(...)` for targeted checks.
- Optional sf tests use `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")`.

## Implementation Constraints

- Do not introduce shared projection state, panel projection registries, or facet-aware projection logic in Phase 33.
- Do not make `d3_zoom()` partially transform sf paths; suppression is the intended API behavior.
- Do not expose renderer private fields beginning with `_` through tooltip content or brush callbacks.
- Do not change non-sf path brush behavior while adding centroid selection for `path.geom-sf`.
- Do not depend on a new browser automation test harness for this phase.

## Suggested Test Pattern

Source-contract tests can read module files with `readLines()` and assert stable integration points, for example:

```r
events_js <- paste(readLines("inst/htmlwidgets/modules/events.js", warn = FALSE), collapse = "\n")
expect_match(events_js, "path\\.geom-sf")
```

For R API behavior, use real widgets where feasible:

```r
p <- ggplot2::ggplot(nc) + ggplot2::geom_sf()
expect_warning(w <- d3_zoom(gg2d3(p)), "geom_sf")
expect_null(w$x$interactivity$zoom)
```
