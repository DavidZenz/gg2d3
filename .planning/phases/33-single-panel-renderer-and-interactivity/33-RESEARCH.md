---
phase: 33
slug: single-panel-renderer-and-interactivity
status: complete
created: 2026-05-20
source: inline-codebase-research
---

# Phase 33 - Technical Research

## Phase Goal

Render Phase 32 `geom_sf` polygon-family IR as D3 SVG paths for a single panel and make the existing tooltip, hover, brush, and zoom APIs behave deliberately with sf layers.

## Requirement Coverage

| Requirement | Meaning | Research Outcome |
|-------------|---------|------------------|
| SFREND-01 | Single-panel `geom_sf` renders as SVG paths | Existing `inst/htmlwidgets/modules/geoms/sf.js` already builds a FeatureCollection, uses `d3.geoIdentity().reflectY(true).fitExtent(...)`, and renders `path.geom-sf`; the phase should harden and test this contract. |
| SFINTR-01 | Tooltip/hover work for sf paths | `events.js` centralizes interactive selectors and currently omits `path.geom-sf`; adding that selector connects tooltip, hover, handlers, and legend state paths. Tooltip internals need explicit sanitization for sf private fields. |
| SFINTR-02 | Brush selection uses sf centroids | `sf.js` already writes `data-cx`/`data-cy`; `brush.js` currently uses path bbox centers for paths. It should special-case `path.geom-sf` to use centroid attributes only. |
| SFINTR-03 | Zoom is disabled or warned for sf | `R/d3_zoom.R` enables Cartesian zoom unconditionally, while `zoom.js` rescales x/y axes and updates Cartesian geoms. It should warn and leave sf widgets without zoom config. |

## Codebase Findings

### D3 sf renderer

`inst/htmlwidgets/modules/geoms/sf.js` is the correct renderer entry point. It:

- Accepts `renderSf(layer, g, xScale, yScale, options)`.
- Parses `layer.geometries` into GeoJSON features.
- Uses `d3.geoIdentity().reflectY(true).fitExtent([[4, 4], [width - 4, height - 4]], featureCollection)`.
- Renders `path.geom-sf`.
- Sets `fill`, `stroke`, `stroke-width`, `opacity`, `fill-rule`, `data-row-id`, `data-cx`, and `data-cy`.
- Binds the row data to each path and attaches private `_geom` / `_centroid` helper fields.

This is already close to the target. The implementation plan should preserve this projection strategy because Phase 34 owns multi-layer/faceted/shared projection semantics.

### Event selectors

`inst/htmlwidgets/modules/events.js` has a shared `INTERACTIVE_SELECTORS` list used by:

- Tooltip attachment.
- Hover dimming/highlight.
- Custom click/dblclick/contextmenu handlers.
- Legend state helpers.

It omits `path.geom-sf`. Adding the selector is the central integration point. The same class should be used by `sf.js`; do not introduce a parallel sf-only event pipeline.

### Tooltip formatting

`inst/htmlwidgets/modules/tooltip.js` already drops underscore-prefixed fields in default field discovery, but sf rows can still leak renderer internals through:

- Whole-row custom formatters, because they receive the enriched row object.
- Explicit `fields` values such as `"_geom"` or `"_centroid"`.

The phase should add a small sanitization helper in `tooltip.js` and use it before field selection and formatter calls. The helper should remove keys beginning with `_` from the row exposed to users while preserving normal aesthetic and variable-name fields. This keeps `data-cx`/`data-cy` as DOM attributes only, not tooltip fields.

### Brush selection

`inst/htmlwidgets/modules/brush.js` has its own `INTERACTIVE_SELECTORS` list and selection logic. It currently includes path geoms and uses `getBBox()` center for `path.geom-line`, `path.geom-area`, and similar elements.

For sf, this would select by rendered polygon bbox center, which violates the Phase 33 decision. The right integration is:

- Add `path.geom-sf` to the brush selectors.
- In `isElementInPixelRect(el, pixelRect)`, branch before the generic path bbox logic when `el.matches("path.geom-sf")`.
- Parse `data-cx` and `data-cy`; return false if either is missing or non-finite.
- Test inclusion with the same point-in-rect check used for point-like geoms.
- Keep all non-sf path behavior unchanged.

`collectSelectedData()` should also sanitize selected sf rows before sending callbacks so private `_geom` and `_centroid` fields do not become public API.

### Zoom behavior

`R/d3_zoom.R` currently validates inputs, stores `widget$x$interactivity$zoom`, and attaches `zoom.js`. `zoom.js` assumes Cartesian x/y scales and calls the shared geometry update path. It has no concept of geospatial projection or path recalculation.

The safest Phase 33 behavior is the discussed warning suppression:

- Detect `geom == "sf"` in `widget$x$ir$layers`.
- Emit a warning containing `geom_sf` and `zoom`.
- Return the original widget without setting `widget$x$interactivity$zoom` and without attaching an onRender zoom callback.
- Preserve all existing non-sf zoom behavior and validation.

## Implementation Strategy

Split the work into three sequential plans:

1. Harden the sf renderer contract and integrate tooltip/hover selectors.
2. Add centroid-only brush selection and callback data sanitization for sf.
3. Suppress Cartesian zoom for sf widgets in R.

This sequencing keeps shared test files from being edited concurrently and lets each plan verify one user-visible behavior.

## Validation Architecture

Phase 33 can be covered with targeted R tests and source-contract tests. The repository does not currently have a headless browser DOM test harness for htmlwidgets, so the plan should avoid inventing a large new browser stack for this phase.

Automated validation should include:

- `tests/testthat/test-sf-renderer.R` for renderer IR/path contract checks that are feasible from R.
- A new focused `tests/testthat/test-sf-interactivity.R` for source-contract checks on JS selectors, tooltip sanitization, centroid brush branching, and zoom suppression.
- Existing `tests/testthat/test-zoom-brush.R` for non-sf regression coverage after changing `d3_zoom.R`.
- Existing visual fixture generation in `tests/testthat/test-sf-visual.R` when optional `sf` dependencies are available.

Manual validation is acceptable for rendered browser appearance because Phase 35 owns documentation/validation hardening, but each behavior must have an automated guard that fails if the planned integration points are removed.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tooltip or brush exposes `_geom` and `_centroid` as user data | Private renderer representation becomes accidental API | Sanitize rows before tooltip formatters and brush callbacks. |
| Brush accidentally uses polygon bbox center | Selection behavior differs from Phase 33 decision | Add an sf-specific `data-cx`/`data-cy` branch before generic path bbox logic. |
| Zoom partially applies to sf paths | Misleading maps or broken geometry transforms | Suppress at `d3_zoom()` before JS config is attached. |
| Renderer hardening drifts into Phase 34 shared projection | Scope creep and fragile mixed-layer behavior | Keep projection local to `sf.js`; no shared projection model in this phase. |
| Existing unrelated interactivity tests fail | False red during execution | Add sf-specific tests and run targeted files that avoid known unrelated hover-default failure unless that test is fixed deliberately. |

## Recommended Verification Commands

```r
pkgload::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-sf-renderer.R")
testthat::test_file("tests/testthat/test-sf-interactivity.R")
testthat::test_file("tests/testthat/test-zoom-brush.R")
```

Full `devtools::test()` may still show unrelated pre-existing failures in non-sf interactivity or coordinate tests. Phase execution should report those separately instead of treating them as Phase 33 regressions.
