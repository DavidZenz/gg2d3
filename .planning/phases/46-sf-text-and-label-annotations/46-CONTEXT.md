# Phase 46: sf Text And Label Annotations - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 46 adds `geom_sf_text()` and `geom_sf_label()` support for gg2d3. Users should be able to render sf text and label annotations at projected anchors that align with existing polygon, point, and line `geom_sf()` panel projections in single-panel, stacked-layer, and faceted plots. This phase includes IR extraction, renderer placement, supported styling, skipped-row diagnostics, and existing interactivity contracts. It does not add ggrepel collision avoidance, path-following labels, map-label layout engines, new sf zoom behavior, tiled-map behavior, JavaScript CRS reprojection, broad public documentation, or new interactivity APIs.

</domain>

<decisions>
## Implementation Decisions

### Anchor Semantics
- **D-01:** Use one representative projected anchor per accepted sf feature for `geom_sf_text()` and `geom_sf_label()`.
- **D-02:** Point annotations should anchor at the projected point coordinate, matching existing sf point positioning.
- **D-03:** Polygon and multipolygon annotations should use a deterministic representative point or centroid-style anchor that aligns with the existing sf panel projection contract.
- **D-04:** Line and multiline annotations should use a deterministic midpoint or centroid-style projected anchor; do not implement path-following labels in this phase.
- **D-05:** Research/planning may choose the exact polygon and line anchor algorithm with evidence, but it must be stable, testable, and aligned with the current `data-cx` / `data-cy` anchor convention.

### Styling Contract
- **D-06:** Support the core visible annotation contract: `label`, text `colour`, label `fill`, `alpha`, and `size`.
- **D-07:** Support font-related fields, `hjust`, and `vjust` when they are already present in ggplot2 built data and can be carried through existing text-style patterns without a large new subsystem.
- **D-08:** `geom_sf_label()` should draw a label background behind the text; exact ggplot2 padding, radius, and stroke parity are not required unless the existing renderer architecture makes them cheap and reliable.
- **D-09:** Defer rotation/angle, rich text, collision avoidance, and ggrepel-style label placement.

### Interactivity
- **D-10:** sf text and label marks should be interactive at the annotation mark level where meaningful.
- **D-11:** Tooltip, hover, custom handlers, and brush behavior should reuse the existing interactivity plumbing instead of introducing sf-annotation-specific APIs.
- **D-12:** Brush selection should use anchor coordinates, exposed as `data-cx` and `data-cy`, consistent with existing sf centroid/anchor behavior.
- **D-13:** Public callback and tooltip payloads must not leak renderer-private geometry fields such as `_geom`, `_centroid`, `_sfFamily`, or any new private anchor metadata.

### Validation Matrix
- **D-14:** Cover polygon, point, line, skipped-row, stacked-layer, and faceted sf annotation cases.
- **D-15:** Use IR tests for extraction, labels, supported aesthetics, panel membership, anchors, and diagnostics.
- **D-16:** Use renderer/source and DOM-oriented tests for projected anchor placement, text/label DOM classes, style attributes, panel routing, and sanitized payload behavior.
- **D-17:** Browser smoke coverage is useful but should remain optional and CRAN-compatible, following the existing chromote/browser smoke pattern.
- **D-18:** Do not add screenshot or perceptual-diff testing for this phase.

### Documentation Boundary
- **D-19:** Record implementation evidence and diagnostics in Phase 46 artifacts and targeted validation notes.
- **D-20:** Leave broad README, vignette, roxygen, and generated-help support-contract updates to Phase 47 unless Phase 46 changes the user-facing contract in a way that must be documented immediately.

### Agent Discretion
- Exact helper names, file split, fixture names, and test-file placement are left to research/planning.
- Planner may decide whether sf text/label rendering lives in the existing sf renderer, the existing text renderer, or a focused new renderer, provided it reuses the current projection and interactivity contracts.
- Planner may choose the exact anchor algorithm for polygon and line geometries after checking ggplot2/sf built-data behavior and the current renderer projection path.
- Planner may choose the exact browser smoke fixture split, as long as the required matrix is covered by stable automated evidence.

</decisions>

<specifics>
## Specific Ideas

- The desired behavior is useful centroid/anchor-style sf annotation support, not a full label placement engine.
- Annotation anchors should align visually with existing `geom_sf()` polygon, point, and line layers in the same panel.
- The existing `data-cx` / `data-cy` convention is the preferred bridge between projected sf placement and interactivity.
- A valid Phase 46 outcome can support a conservative, explicit subset of text/label aesthetics if unsupported edge cases are deferred clearly.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/ROADMAP.md` - Phase 46 goal, dependency on Phase 45, success criteria, and three expected plan files.
- `.planning/REQUIREMENTS.md` - SFANN-01, SFANN-02, and SFANN-03 define the extraction, rendering, diagnostics, and interactivity contract; FUT-03 defers ggrepel collision avoidance.
- `.planning/PROJECT.md` - v1.11 current state and target feature wording for `geom_sf_text()` and `geom_sf_label()`.
- `.planning/STATE.md` - current milestone progress, prior decisions, and resume context.

### Prior decisions
- `.planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md` - Reuse existing interactivity APIs, sanitize renderer-private fields, prefer DOM/source assertions over screenshot diffs.
- `.planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md` - Evidence-first validation, optional CRAN-compatible browser smoke, no screenshot/perceptual diffing, broad docs deferred to Phase 47.
- `.planning/milestones/v1.8-phases/33-single-panel-renderer-and-interactivity/33-CONTEXT.md` - Existing sf tooltip, hover, handler, brush, centroid, zoom suppression, and sanitized payload contracts.
- `.planning/milestones/v1.9-phases/37-non-polygon-sf-ir-and-renderer/37-CONTEXT.md` - Existing point/line sf family expansion and shared `.geom-sf` selector strategy.
- `.planning/milestones/v1.9-phases/38-sf-interaction-facet-and-documentation-hardening/38-CONTEXT.md` - sf facets, interaction hardening, and DOM/IR validation preference.

### Code and tests
- `.planning/codebase/ARCHITECTURE.md` - R IR to D3 renderer pipeline and module boundaries.
- `.planning/codebase/CONCERNS.md` - known renderer, sf, and validation fragility to avoid widening.
- `.planning/codebase/TESTING.md` - testthat and optional browser-smoke testing patterns.
- `R/as_d3_ir.R` - geom mapping and layer dispatch entry point for text, label, and sf layers.
- `R/sf_utils.R` - sf geometry filtering, CRS normalization, row identity, diagnostics, panel bbox helpers, and current retained aesthetic fields.
- `inst/htmlwidgets/modules/geoms/sf.js` - existing sf projection, centroid/anchor computation, family-specific marks, and `data-cx` / `data-cy` attributes.
- `inst/htmlwidgets/modules/geoms/text.js` - existing `geom_text` renderer behavior and baseline text styling.
- `inst/htmlwidgets/modules/events.js` - interactive mark selector wiring and handler payload path.
- `inst/htmlwidgets/modules/brush.js` - brush selection behavior for sf marks and text anchors.
- `inst/htmlwidgets/modules/tooltip.js` - tooltip data sanitization and mark handling.
- `inst/htmlwidgets/modules/crosstalk.js` - linked-view key and mark binding behavior.
- `R/d3_tooltip.R`, `R/d3_hover.R`, `R/d3_handlers.R`, `R/d3_brush.R` - public interactivity API docs and selector expectations.
- `tests/testthat/` - existing IR, sf, facet, renderer, browser, and regression tests to extend with Phase 46 coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/sf_utils.R` already centralizes supported sf geometry filtering, CRS normalization, skipped-row diagnostics, source row identity, panel geometry aggregation, and `sf_bbox` attachment.
- `sf_layer_data_rows()` already preserves `label`, `colour`, `fill`, `size`, `alpha`, `group`, `row_id`, and `.sf_family`, which are directly relevant to sf annotations.
- `inst/htmlwidgets/modules/geoms/sf.js` already builds a per-panel `d3.geoIdentity().reflectY(true).fitExtent()` projection and stores projected centroids as `data-cx` / `data-cy`.
- `inst/htmlwidgets/modules/geoms/text.js` provides a simple baseline for SVG text mark creation, label text extraction, fill color, opacity, and centered text alignment.
- Existing interactivity modules already understand `.geom-sf` and `text.geom-text` selectors in several places, giving Phase 46 reusable plumbing for hover, tooltip, brush, and handlers.

### Established Patterns
- sf renderer behavior should stay projection-based and use R-normalized geometry; browser-side CRS reprojection remains out of scope.
- sf marks carry private renderer fields for geometry and projected anchors, but public callbacks and tooltips must receive sanitized rows.
- Browser-oriented validation should skip cleanly when optional dependencies or browser capabilities are unavailable.
- Tests should prefer IR/source/DOM assertions that are stable across environments.

### Integration Points
- R layer: detect `geom_sf_text()` and `geom_sf_label()` distinctly enough to produce annotation IR while reusing sf geometry preparation and diagnostics.
- IR schema: carry label text, supported aesthetics, panel membership, row identity, sf family, and projected-anchor inputs without exposing private renderer metadata as public data.
- JS renderer: place text and label marks using the same projection source and panel bbox as existing sf polygon/point/line layers.
- Interactivity: add or reuse stable DOM classes/selectors for sf text and labels, retain `data-cx` / `data-cy`, and verify tooltip/hover/brush/handler sanitization.
- Tests: add representative sf annotation fixtures under `tests/testthat/`, including polygon, point, line, skipped rows, stacked layers, facets, and interactivity sanitization.

</code_context>

<deferred>
## Deferred Ideas

- `ggrepel`-style collision avoidance and label repulsion.
- Path-following labels for line geometries.
- Rich text labels, angle/rotation parity, and exact ggplot2 label padding/radius/stroke parity beyond the conservative Phase 46 support contract.
- New interactivity APIs specific to sf annotations.
- Tiled maps, slippy-map controls, JavaScript CRS reprojection, and projection-aware map interactions beyond the current SVG/htmlwidgets ggplot parity scope.
- Broad v1.11 public documentation updates, covered by Phase 47 unless Phase 46 uncovers an immediate support-contract change.
- Screenshot or perceptual visual regression infrastructure.

</deferred>

---

*Phase: 46-sf-text-and-label-annotations*
*Context gathered: 2026-05-24*
