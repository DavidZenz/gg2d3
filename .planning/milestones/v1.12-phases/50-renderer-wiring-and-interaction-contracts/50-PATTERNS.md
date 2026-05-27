# Phase 50: Renderer Wiring And Interaction Contracts - Pattern Map

**Mapped:** 2026-05-26
**Status:** Complete

## PATTERN MAPPING COMPLETE

## Files To Modify

| File | Role | Closest Existing Pattern | Notes |
|------|------|--------------------------|-------|
| `inst/htmlwidgets/modules/geom-contracts.js` | New internal geom contract | `inst/htmlwidgets/modules/geom-registry.js` namespace export pattern | Export under `window.gg2d3.geomContracts`; keep internal and undocumented as public API. |
| `inst/htmlwidgets/modules/public-data.js` | New shared public datum sanitizer | Existing local `sanitizeEventDatum()`, `sanitizeSelectedDatum()`, `sanitizeTooltipDatum()` functions | Export a small helper such as `sanitizeDatum()` that strips underscore-prefixed keys. |
| `inst/htmlwidgets/gg2d3.yaml` | Module load order | Existing module list ordering | Load new helper modules before consumers. |
| `inst/htmlwidgets/modules/geom-registry.js` | Registry and update coverage consumer | Existing `window.gg2d3.geomRegistry` API | Keep `updateGeoms()` incremental; add metadata use only where low risk. |
| `inst/htmlwidgets/modules/events.js` | Event selector and sanitizer consumer | Existing `INTERACTIVE_SELECTORS` and handler paths | Derive selectors or assert exact match against contract; call shared sanitizer for public datum. |
| `inst/htmlwidgets/modules/brush.js` | Brush selector and sanitizer consumer | Existing sf centroid branch plus generic bbox branch | Preserve sf centroid handling and generic polygon bbox behavior. |
| `inst/htmlwidgets/modules/crosstalk.js` | Crosstalk selector consumer | Existing `_sourceIndex` key binding | Continue internal `_sourceIndex` use; do not expose private fields as public payload. |
| `inst/htmlwidgets/modules/tooltip.js` | Tooltip sanitizer consumer | Existing field filtering and `sanitizeTooltipDatum()` | Preserve `config.fields` underscore filtering. |
| `tests/testthat/test-renderer-wiring-contracts.R` | New source-contract suite | Existing JS source tests in polygon/sf interactivity files | Centralize contract, selector, update, and sanitizer source checks. |
| Existing polygon/sf tests | Focused regression reinforcement | `test-polygon-interactivity.R`, `test-sf-interactivity.R`, `test-sf-annotations-interactivity.R` | Update only if helper names changed; keep dependency skips unchanged. |

## Existing Patterns To Reuse

### Namespace Export Pattern

Modules initialize `window.gg2d3` and export a namespaced object:

```js
if (!window.gg2d3.geomRegistry) window.gg2d3.geomRegistry = {};
window.gg2d3.geomRegistry.register = registerGeom;
```

New helpers should follow this style. Avoid ES modules because htmlwidgets loads files through `gg2d3.yaml`.

### Source-Contract Test Pattern

Existing R tests read JavaScript modules as text and assert strings:

```r
read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) stop("Cannot find module: ", path, call. = FALSE)
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}
```

Phase 50 should reuse this pattern and add small extraction helpers for selector arrays and contract entries. Avoid full JavaScript parsing unless the existing test stack already provides it.

### Local Sanitizer Pattern

The three local sanitizers all do the same thing:

```js
Object.keys(d).forEach(function(key) {
  if (key.startsWith('_')) return;
  sanitized[key] = d[key];
});
```

The shared helper can preserve this exact behavior. Public payload helpers should return the original value for non-object, null, undefined, and array inputs to avoid changing callback behavior.

## Data Flow

```text
geom-contracts.js
  -> renderer registration contract tests
  -> geom-registry update coverage contract tests
  -> events/brush/crosstalk selector derivation or exact-match tests
  -> public-data sanitizer private-field tests

renderer modules
  -> geom-registry.register(...)
  -> geom-registry.render(...)
  -> geom-registry.updateGeoms(...)

public interactions
  -> tooltip/events/brush callbacks
  -> public-data sanitizer
  -> user-facing payload without underscore-prefixed fields
```

## Landmines

- `crosstalk.js` has a deliberately shorter selector list than `events.js` and `brush.js`; exact equality across all three modules would be a regression.
- `crosstalk.js` reads `_sourceIndex` internally for grouped polygon key binding; tests should distinguish internal metadata use from public payload leakage.
- `brush.js` handles sf elements through `data-cx`/`data-cy` before falling back to `getBBox()` for ordinary paths; polygon tests currently assert that separation.
- `geom-registry.js` update coverage includes selectors that do not map one-to-one with renderer names, especially interval, boxplot, smooth/ribbon/density, hline/vline, and sf/annotation geoms.
- `geom_abline` currently renders as a line but may not have a dedicated zoom update path. The contract should mark that intentionally if still true after implementation.
- Browser visual smoke is opt-in and should not become mandatory for ordinary local test runs.
