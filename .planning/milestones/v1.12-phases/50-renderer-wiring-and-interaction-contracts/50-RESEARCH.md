# Phase 50: Renderer Wiring And Interaction Contracts - Research

**Researched:** 2026-05-26
**Status:** Complete

## RESEARCH COMPLETE

## Executive Summary

Phase 50 should introduce a small internal JavaScript geom contract and use it to guard the duplicated renderer, zoom/update, and interaction wiring surfaces. The safest implementation path is incremental:

1. Add `inst/htmlwidgets/modules/geom-contracts.js` with supported geom metadata and source-contract tests that compare it to existing renderer registrations and update selectors.
2. Connect or validate `events.js`, `brush.js`, and `crosstalk.js` against module-specific selector lists derived from that contract.
3. Centralize public datum sanitization for tooltip, event callbacks, and brush callbacks, while preserving private metadata for renderer internals and crosstalk key binding.

This phase should not rewrite geometry behavior or create a public plugin API. It should make missing wiring fail fast in source-level tests.

## Current Code Findings

### `inst/htmlwidgets/modules/geom-registry.js`

The registry already owns renderer registration through `registerGeom()`, `render()`, `has()`, and `list()`. It also owns `updateGeoms()`, which contains procedural update branches for:

- `circle.geom-point`
- `rect.geom-bar`
- `rect.geom-rect`
- `text.geom-text`
- `line.geom-segment`
- `path.geom-ribbon`, `path.geom-violin`, `path.geom-smooth-ribbon`
- `path.geom-line`, `path.geom-path`, `path.geom-smooth`, `path.geom-density-outline`
- `path.geom-polygon`
- `path.geom-area`, `path.geom-density`
- boxplot box, whisker, median, staple, and outlier selectors
- `line.geom-hline` and `line.geom-vline`
- `circle.geom-dotplot`
- `line.geom-rug`
- interval groups for errorbar, linerange, and pointrange

This is a good first validation target because registration names and update selectors can be checked from source without launching a browser.

### Geom Renderer Modules

Renderer modules self-register with `window.gg2d3.geomRegistry.register(...)`. Registered names include:

- `point`
- `line`, `path`
- `polygon`
- `bar`, `col`
- `rect`, `tile`
- `text`
- `area`
- `ribbon`
- `segment`
- `hline`, `vline`, `abline`
- `dotplot`
- `rug`
- `errorbar`, `linerange`, `pointrange`
- `boxplot`
- `violin`
- `density`
- `smooth`
- `sf`, `sf_text`, `sf_label`

The contract should capture aliases explicitly so tests can fail when a renderer module adds a supported name without adding expected update or interaction metadata.

### Interaction Modules

`events.js` and `brush.js` currently maintain nearly identical `INTERACTIVE_SELECTORS` lists, including interval selectors. `crosstalk.js` intentionally has a shorter list and uses `_sourceIndex` internally to map polygon grouped marks back to original rows.

The phase should not force all modules to share one identical selector array. It should provide module-specific selectors from a single contract or tests that prove the local lists match the contract's module-specific expectations.

### Public Payload Sanitization

`events.js`, `brush.js`, and `tooltip.js` each implement local sanitizer functions that strip keys whose names start with `_`. That behavior is correct but duplicated. The important private fields are:

- ordinary polygon: `_polygonPoints`, `_sourceIndex`
- sf and sf annotations: `_geom`, `_centroid`, `_sfFamily`, `_sfAnchor`, `_pointCoord`, `_pointIndex`

Crosstalk may continue to read `_sourceIndex` internally before public payload sanitization. Tooltip, event handlers, Shiny event payloads, and brush callback data should omit underscore-prefixed fields.

## Planning Implications

### Recommended File Strategy

- Create `inst/htmlwidgets/modules/geom-contracts.js` before `tooltip.js`, `events.js`, `brush.js`, `crosstalk.js`, and `geom-registry.js` in `inst/htmlwidgets/gg2d3.yaml`.
- Create `inst/htmlwidgets/modules/public-data.js` or a similarly small helper for public datum sanitization before tooltip/events/brush consumers in `gg2d3.yaml`.
- Add a new focused source-contract test file, `tests/testthat/test-renderer-wiring-contracts.R`, instead of scattering all assertions into older regression files.
- Update existing polygon and sf interactivity tests only where they need to assert the new shared helper or contract-owned selectors.

### Recommended Contract Shape

The contract should be a plain JavaScript array exported under `window.gg2d3.geomContracts`. Each entry should include concrete fields:

- `geom`: canonical geom name
- `aliases`: renderer names handled by the same module
- `module`: renderer module path or short module name
- `renderSelectors`: DOM selectors produced by the renderer
- `update`: update coverage type and selectors, or `none` with a reason
- `interactions`: per-module selectors for `events`, `brush`, and `crosstalk`, with intentional exclusions represented by empty arrays plus a reason
- `privateFields`: underscore-prefixed renderer fields that must not appear in public payloads
- `publicPayload`: boolean indicating sanitizer coverage is required

### Recommended Test Strategy

Add source-level tests that:

1. Parse `geom-contracts.js` enough to extract every declared geom and selector string.
2. Assert all contract aliases appear in renderer `register(...)` calls.
3. Assert every registered geom is represented in the contract or is explicitly excluded.
4. Assert every contract update selector appears in `updateGeoms()`, and every `updateGeoms()` geom selector is represented in the contract.
5. Assert `events.js`, `brush.js`, and `crosstalk.js` use contract-derived selectors or exactly match contract selectors for their module.
6. Assert tooltip/events/brush call the shared public datum sanitizer and that the private field set is represented in contract tests.

Browser smoke remains optional confidence after source contracts pass.

## Validation Architecture

Phase 50 validation should prove all four roadmap success criteria:

1. **Contract source of truth exists:** grep for `window.gg2d3.geomContracts` and helper accessors, plus source tests for all registered geoms.
2. **Update and selector coverage fails fast:** source tests compare contract selectors with `geom-registry.js`, `events.js`, `brush.js`, and `crosstalk.js`.
3. **Public sanitizer consistency:** tooltip, events, and brush all use one shared sanitizer or are contract-tested against identical underscore stripping behavior.
4. **Polygon and sf annotation private fields covered:** tests include `_polygonPoints`, `_sourceIndex`, `_geom`, `_centroid`, `_sfFamily`, `_sfAnchor`, `_pointCoord`, and `_pointIndex`.

Required verification commands:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-interactivity.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-path-datum.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The browser smoke command may skip unless `GG2D3_BROWSER_VISUAL_SMOKE=true`. sf-dependent checks may skip only for missing optional spatial dependencies.

## Security Notes

This phase does not introduce network access or a new public extension surface. The main risks are integrity and information disclosure:

- integrity: missing update/selector wiring silently breaks interaction or zoom for a supported geom;
- information disclosure: renderer-private geometry fields leak to user callbacks, tooltip payloads, Shiny inputs, or brush callbacks.

Plans should include threat-model entries for both classes and verify them with source-level tests.
