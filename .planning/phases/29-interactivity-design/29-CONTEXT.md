# Phase 29: Interactivity Design - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Document how `geom_sf` map regions should integrate with gg2d3's existing interactivity systems. This phase covers hover, tooltip, brush, and zoom design decisions for `path.geom-sf` elements. It produces implementation guidance for a future build phase; it does not implement production interactivity code.

</domain>

<decisions>
## Implementation Decisions

### Tooltip and hover contract
- **D-01:** `d3_tooltip()` for `geom_sf` should prioritize original ggplot mapped variables when available, matching existing tooltip behavior through `ir.aes_by_var`.
- **D-02:** `d3_hover()` should reuse the existing hover behavior for sf paths: add `path.geom-sf` to the existing interactive selector list, dim non-hovered regions, and optionally apply the configured hover stroke/stroke width.
- **D-03:** Tooltip content should come from the bound row object on each path. `data-row-id` is a stable DOM/debug join key, not the primary tooltip data source.
- **D-04:** Future implementation should not duplicate all tooltip-relevant values into DOM `data-*` attributes. The bound row is the canonical data contract; DOM attributes stay limited to interaction geometry and join/debug fields.

### Brush selection semantics
- **D-05:** `d3_brush()` on `geom_sf` should select regions by centroid: a path is selected when its stored `data-cx`/`data-cy` falls inside the brush rectangle.
- **D-06:** The centroid behavior must be documented clearly as centroid-based region selection, not polygon-overlap or spatial-intersection selection.
- **D-07:** Brush callbacks should return the existing bound row objects for selected sf regions, consistent with other geoms. Do not return GeoJSON payloads in callback data.
- **D-08:** Future implementation should extend `brush.js` path handling to prefer `data-cx`/`data-cy` for `path.geom-sf` instead of using SVG bounding-box centers.

### Zoom architecture
- **D-09:** For the first build, `d3_zoom()` should be suppressed for widgets containing sf panels rather than attempting Cartesian zoom on geographic paths.
- **D-10:** Suppression should be visible from R: `d3_zoom()` should warn when attached to a widget containing `geom_sf` / sf IR layers.
- **D-11:** Map zoom is an explicit deferral, not a permanent anti-feature. If implemented later, the favored candidate is projection/path re-rendering, not SVG group transform.
- **D-12:** SVG group transform is rejected for the first build because it scales stroke widths and conflicts with gg2d3's existing Cartesian zoom design principle of preserving mark stroke widths.

### the agent's Discretion
- Exact warning text for `d3_zoom()` suppression.
- Exact documentation location for the centroid-brush limitation, as long as it is visible to users and downstream implementers.
- Whether selector lists remain duplicated in `events.js` and `brush.js` or get consolidated during a future refactor.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` - Phase 29 goal and success criteria for tooltip/hover, brush, and zoom design.
- `.planning/REQUIREMENTS.md` - `INTR-01`, `INTR-02`, and `INTR-03`; also future `IMPL-04`.

### Prior sf decisions
- `.planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md` - R-side sf extraction, CRS normalization, and IR schema decisions.
- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` - `path.geom-sf`, `row_id`, `data-cx`, `data-cy`, and `geoIdentity` renderer decisions.
- `.planning/phases/28-d3-renderer-prototyping/28-UI-SPEC.md` - DOM contract for `path.geom-sf`, including `data-row-id`, `data-cx`, and `data-cy`.
- `.planning/phases/28-d3-renderer-prototyping/28-RESEARCH.md` - D3 geoPath, centroid storage, and sf renderer patterns.

### Research findings
- `.planning/research/SUMMARY.md` - v1.7 synthesis; Phase 3 interactivity wiring and zoom risk summary.
- `.planning/research/ARCHITECTURE.md` - Interactivity flow for map regions and zoom architecture notes.
- `.planning/research/FEATURES.md` - Choropleth interactivity priorities and out-of-scope map behaviors.
- `.planning/research/PITFALLS.md` - Pitfall 5 (zoom incompatibility) and Pitfall 6 (brush centroid selection).

### Existing code hooks
- `inst/htmlwidgets/modules/events.js` - Existing tooltip/hover selector list and event attachment flow.
- `inst/htmlwidgets/modules/tooltip.js` - Existing bound-row tooltip formatting and `aes_by_var` behavior.
- `inst/htmlwidgets/modules/brush.js` - Existing brush selector list, pixel rectangle selection, and callback data collection.
- `inst/htmlwidgets/modules/zoom.js` - Existing Cartesian zoom behavior that must not be applied blindly to sf paths.
- `inst/htmlwidgets/modules/geoms/sf.js` - Current sf path renderer with `class="geom-sf"`, bound row data, `data-row-id`, `data-cx`, and `data-cy`.
- `R/d3_zoom.R` - R-side `d3_zoom()` entry point where sf warning/suppression should be designed.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `events.js` `INTERACTIVE_SELECTORS`: add `path.geom-sf` so existing tooltip and hover handlers attach to sf paths.
- `tooltip.js` `format()`: already prefers original mapped variable names via `ir.aes_by_var`; sf tooltips should reuse this rather than inventing sf-specific formatting.
- `brush.js` `highlightSelection()` and `collectSelectedData()`: already operate over selector-matched elements and bound rows; sf support should extend path hit testing, not callback shape.
- `sf.js`: already binds row objects to paths and writes `data-row-id`, `data-cx`, and `data-cy`.

### Established Patterns
- Interactivity modules use selector arrays per module; prior project decisions accept this duplicated selector-list pattern.
- Brush selection is pixel-rectangle based, not data-domain based, so centroid selection fits the existing architecture.
- Cartesian zoom updates positions through scales and `geomRegistry.updateGeoms()`. sf paths are projection-generated `d` strings, so this pattern does not apply.
- gg2d3 avoids SVG group transform zoom for Cartesian geoms because scaled strokes are visually wrong; that same concern applies to sf paths.

### Integration Points
- `events.js`: add `path.geom-sf` to tooltip/hover/custom handler selectors.
- `brush.js`: add `path.geom-sf` to selectors and update `isElementInPixelRect()` so sf paths use `data-cx`/`data-cy`.
- `zoom.js` / `R/d3_zoom.R`: detect sf layers and suppress Cartesian zoom with an R-side warning.
- Documentation/vignettes: document that sf brush selection is centroid-based and that map zoom is deferred in the first sf build.

</code_context>

<specifics>
## Specific Ideas

- Keep sf interactivity additive: extend existing `d3_tooltip()`, `d3_hover()`, and `d3_brush()` behavior rather than introducing map-specific user APIs.
- Preserve the user-facing mental model that tooltips show what the user mapped in `ggplot(aes(...))`, not internal IR/debug fields.
- Be transparent about centroid brushing. A region with a centroid outside the brush rectangle should not be selected even if part of its polygon overlaps the rectangle.
- Treat true map zoom as future work. The first build should avoid a broken half-zoom where axes change and polygons do not.

</specifics>

<deferred>
## Deferred Ideas

- Map-specific zoom/pan via projection re-rendering - future phase after the first sf build proves basic rendering and interactivity.
- Polygon-overlap or point-in-polygon brush selection - future phase only if centroid selection proves insufficient.
- Tile/slippy-map behavior - remains out of scope for gg2d3's SVG/htmlwidgets model.

</deferred>

---

*Phase: 29-interactivity-design*
*Context gathered: 2026-05-19*
