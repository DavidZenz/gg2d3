# Feature Landscape

**Domain:** gg2d3 v1.9 sf Robustness and Expansion
**Researched:** 2026-05-20
**Overall confidence:** HIGH for local project state and `geom_sf()` semantics; MEDIUM for exact browser-runner mechanics until the project chooses Playwright wiring.

## Executive Framing

v1.9 should make `geom_sf()` feel less like a polygon-only special case and more like a deliberately bounded sf renderer. From a user perspective, the milestone should mean: existing polygon choropleths keep working, sf point and line layers render with the same interactivity verbs users already know, and unsupported map-engine expectations remain explicitly out of scope.

From a developer perspective, v1.9 should convert the current sf browser-validation debt into a repeatable DOM smoke suite. The goal is not screenshot-perfect visual regression testing. The goal is to catch broken rendered marks, missing centroid attributes, selector drift, brush regressions, and fixture failures before a user manually opens HTML.

Package hardening should be visible through outcomes, not new APIs: smaller and better-tested internals around sf IR preparation, one controlled wrapper around fragile ggplot2 theme extraction, clearer unsupported-geometry diagnostics, and resolved stale renderer/documentation inconsistencies. Avoid a broad rewrite of the package while sf behavior is expanding.

## Table Stakes

Features users and maintainers should expect in v1.9. Missing these means the milestone did not actually harden sf support.

| Feature | Why Expected | Complexity | User Contract | Developer Contract |
|---------|--------------|------------|---------------|--------------------|
| Automated DOM smoke validation for sf fixtures | v1.8 left browser-side behavior protected by source tests and manual HTML fixtures only | Medium | Users do not see this directly, but releases are less likely to ship blank maps or broken interactions | A repeatable command generates deterministic widgets, opens them in a real browser, fails on console errors/page errors, and asserts DOM state with selectors |
| Polygon regression DOM checks | v1.8 polygon support is now production behavior and must not regress while adding points/lines | Low-Medium | Existing `POLYGON`/`MULTIPOLYGON` choropleths still render as `path.geom-sf` with tooltip, hover, handlers, centroid brush, facets, stacked alignment, and zoom suppression | Tests assert non-empty `path.geom-sf` count, non-empty `d`, `fill-rule="evenodd"`, `data-row-id`, finite `data-cx`/`data-cy`, per-panel isolation, and brush opacity changes |
| Browser fixture automation | Manual fixture inspection does not scale as sf support expands | Medium | Documentation examples and test fixtures stay aligned with real rendering | Fixture generation is scripted, deterministic, and artifact-producing. Failures leave HTML, screenshot, and console logs for diagnosis |
| POINT rendering in `geom_sf()` | Official ggplot2 documents `geom_sf()` as drawing points, lines, or polygons depending on feature geometry | Medium | `POINT` sf layers render as visible point marks with color, fill, alpha, size, tooltip, hover, handlers, brush, legends where applicable, facets, and stacked sf alignment | R IR accepts `POINT`; JS projects coordinates through the same panel sf projection and renders `circle.geom-sf.geom-sf-point` or equivalent class with finite `cx`, `cy`, `data-cx`, `data-cy`, and source row identity |
| MULTIPOINT rendering | Multipoint is the point-family partner and common in sf data | Medium-High | One source feature may draw multiple point marks; hovering or brushing any child mark exposes/selects the source row once | Renderer expands child coordinates while preserving one `row_id`. Callback payloads are deduplicated by source row and sanitized like polygon callbacks |
| LINESTRING rendering in `geom_sf()` | Lines are a core sf family and are required for roads, rivers, routes, and borders | Medium | `LINESTRING` sf layers render as ordered SVG paths with stroke color, linewidth, linetype where available, alpha, tooltip, hover, handlers, centroid brush, facets, and stacked alignment | R IR accepts `LINESTRING`; JS uses GeoJSON coordinate order, does not apply Cartesian x sorting, and renders `path.geom-sf.geom-sf-line` with non-empty `d` and finite brush anchor attributes |
| MULTILINESTRING rendering | Multiline features are common for administrative borders and route groups | Medium-High | A source multiline feature appears as one feature-level line mark or grouped subpaths that behave as one row for tooltip/brush/callbacks | Renderer preserves source row identity and does not duplicate callback rows unless the public behavior explicitly documents per-part callbacks |
| Geometry-family diagnostics | v1.8 diagnostics are a key support contract | Medium | Unsupported, empty, invalid, or missing geometries are skipped with clear warnings; accepted point/line/polygon rows continue to render | `sf_diagnostics` distinguishes accepted geometry families, skipped rows, skipped reasons, missing CRS, and unsupported geometry types. Existing row/geometry alignment tests are extended rather than replaced |
| Shared projection across sf families | Stacked polygon/point/line overlays must align | Medium | A polygon base layer plus point or line overlay uses one panel projection, including facets | `sf_bbox` is computed from all accepted sf geometries in the panel, across polygon, point, and line families, while empty panels keep `sf_bbox = NULL` |
| Existing sf interactivity parity | Users already pipe `d3_tooltip()`, `d3_hover()`, `d3_brush()`, and `d3_handlers()` | Medium | Point and line sf marks participate in existing interactivity verbs without new user syntax | Selector arrays include all sf mark classes. Renderer-private `_geom` and `_centroid` fields remain stripped from tooltip/handler/brush payloads |
| Continued sf zoom suppression | Current `d3_zoom()` is Cartesian and misleading for projected sf maps | Low | `d3_zoom()` still warns and returns an unzoomed widget for any sf layer | Browser tests assert no zoom behavior is attached to sf widgets and warning text remains clear |
| Documentation updates for v1.9 sf support | Current docs say non-polygon sf is unsupported | Low | README, vignette, diagnostics, and roxygen describe polygon, point, and line support boundaries accurately | Docs are updated from source files, and tests or search checks prevent stale "non-polygon unsupported" language after implementation |
| High-risk package hardening outcomes | v1.9 explicitly includes package hardening | Medium-High | No new user API, but fewer surprising failures after ggplot2 or renderer edge cases | Harden `as_d3_ir()` seams around sf preparation, theme extraction, and unsupported geoms. Add regression coverage for fragile paths touched by v1.9 |

## Differentiators

Features that are not strictly necessary for correctness, but make v1.9 meaningfully stronger than "points and lines now draw."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| DOM assertions over source-string checks | Catches failures where JS source contains a selector but rendered SVG is blank or malformed | Medium | Prefer a real browser runner over jsdom for SVG path layout, D3 brush behavior, pointer events, and console/page-error collection |
| Browser test artifact bundle | Makes browser failures debuggable instead of opaque CI failures | Low-Medium | Store generated HTML, screenshot, and console log for each failed fixture; this is a maintainer feature, not a user feature |
| Geometry-family CSS classes | Enables precise testing and future styling without breaking old selectors | Low | Keep `path.geom-sf` for polygon compatibility, add family-specific classes such as `geom-sf-polygon`, `geom-sf-point`, and `geom-sf-line` |
| Mixed sf overlay examples | Demonstrates real map workflows: choropleth plus points, boundaries plus routes | Low | Use simple sf fixtures, not large real-world map datasets, so examples remain fast and deterministic |
| Deduplicated brush callback rows for multi-geometries | Keeps callbacks source-row-oriented, which matches R data-frame semantics | Medium | Especially important for `MULTIPOINT` and `MULTILINESTRING` where one row may produce multiple SVG children |
| Structured hardening checklist in validation | Turns broad "package hardening" into auditable outcomes | Low | Useful categories: private API wrapper, orphaned renderer mappings, rect/tile edge fixture, sf helper tests, documentation truthfulness |
| Graceful optional-dependency behavior | Keeps CRAN/package checks sane while allowing richer local browser validation | Medium | Browser tests should be skipped with a clear reason when browser tooling is unavailable; runtime package dependencies should not grow because of dev validation |

## Anti-Features

Features to explicitly avoid in v1.9.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Tile basemaps or raster map backgrounds | Converts gg2d3 into a Leaflet/Mapbox-style map engine, contradicting the SVG/htmlwidgets renderer boundary | Keep gg2d3 focused on ggplot-authored SVG layers; recommend map-specific packages for tiled maps |
| Slippy-map zoom and pan | Existing `d3_zoom()` is Cartesian. True map zoom must update projection/path rendering, not just rescale axes | Continue warning/suppressing zoom for sf widgets; research map zoom only after sf family rendering is stable |
| JavaScript-side CRS reprojection | CRS math is already handled reliably by `sf` in R; duplicating arbitrary projection logic in JS is scope explosion | Preserve R-side WGS84 normalization and document missing CRS behavior |
| True polygon/line overlap brushing | Geometric intersection and hit-testing are much more complex than the current centroid/pixel-anchor brush model | Keep centroid or mark-anchor brushing in v1.9; evaluate true geometry brushing only if real workflows need it |
| `GEOMETRYCOLLECTION` support | Collections require recursive family dispatch, nested diagnostics, and difficult callback semantics | Continue skipping with clear diagnostics until atomic point, line, and polygon families are stable |
| `geom_sf_text()` / `geom_sf_label()` | Label placement requires `stat_sf_coordinates()`, point-on-surface behavior, collision concerns, and text-specific options | Defer to a separate text/label sf milestone |
| Full rewrite of `as_d3_ir()` | High risk while expanding sf behavior; broad refactors could destabilize 25 existing geoms | Extract or wrap only the high-risk seams touched by v1.9 and add tests around them |
| Adding browser automation as a runtime dependency | Users should not install Node/browser tooling to render widgets | Keep Playwright or equivalent as dev/CI validation only |
| Pixel-diff screenshot testing as the main gate | Brittle across platforms and fonts; v1.9 risk is mostly missing DOM marks and interactions | Use DOM assertions as the required gate; screenshots are diagnostic artifacts |
| Large-map performance guarantees | SVG map performance depends on feature count and geometry complexity | Add warnings/docs and small fixtures; defer simplification/performance budgets |

## Future / Deferred Items

These are valuable, but should not be required for v1.9 completion.

| Future Item | Why Deferred | Trigger to Revisit |
|-------------|--------------|--------------------|
| `GEOMETRYCOLLECTION` support | Requires nested geometry handling after atomic families are proven | Users provide common collection workflows that cannot be pre-flattened in R |
| Map-specific zoom/pan | Needs projection-aware rerendering and a separate API decision from Cartesian `d3_zoom()` | Point/line/polygon support is stable and users repeatedly ask for map navigation |
| True geometry-intersection brushing | Requires point-in-polygon or path intersection logic and careful performance limits | Centroid/anchor brushing proves insufficient in documented user workflows |
| `geom_sf_text()` and `geom_sf_label()` | Needs placement, `fun.geometry`, text styling, and overlap behavior | A later milestone focuses on labels and annotation parity |
| Global-comparison faceted projection mode | Current facet behavior intentionally uses panel-specific bbox projection | Users need comparable geography scale across facets more than per-panel fit |
| Geometry simplification guidance or helper | Large shapefiles can overload SVG DOM | Browser validation reveals performance failures or docs receive repeated large-map support questions |
| Visual diff suite | More expensive and brittle than DOM smoke checks | DOM smoke tests are stable and there is a specific fidelity regression class that selectors cannot catch |

## Feature Dependencies

```text
Browser fixture generation
  -> DOM smoke runner
  -> Polygon regression checks
  -> Point/line DOM checks
  -> Brush/tooltip/handler smoke checks

sf IR family expansion
  -> Accept POINT/MULTIPOINT/LINESTRING/MULTILINESTRING
  -> Preserve skipped-row diagnostics and source row identity
  -> Compute panel sf_bbox from all accepted sf families
  -> Render family-specific SVG marks through one sf projection
  -> Wire family-specific marks into tooltip/hover/brush/handler selectors

Package hardening
  -> Wrap ggplot2 private theme extraction
  -> Refactor only touched IR seams
  -> Resolve stale geom/documentation contradictions
  -> Add regression tests for known fragile renderer paths
```

## MVP Recommendation

Prioritize:

1. DOM smoke validation for existing polygon `geom_sf()` behavior.
2. R IR family expansion for `POINT`, `MULTIPOINT`, `LINESTRING`, and `MULTILINESTRING` with diagnostics and panel `sf_bbox` integration.
3. D3 sf renderer dispatch for point and line marks with existing tooltip, hover, handler, and brush behavior.
4. Documentation updates that replace the v1.8 polygon-only contract with a v1.9 polygon/point/line contract.
5. Focused hardening around `as_d3_ir()` sf seams, private theme extraction, and stale renderer/docs inconsistencies.

Defer:

- `GEOMETRYCOLLECTION`, `geom_sf_text()`, map zoom, true geometry brushing, tile basemaps, and large-map performance guarantees.
- Full `as_d3_ir()` rewrite. Modularize only where it lowers immediate v1.9 risk.

## User Perspective

### Existing Polygon Users

Existing code such as:

```r
ggplot(nc, aes(fill = AREA)) +
  geom_sf(color = "white", linewidth = 0.2) |>
  gg2d3() |>
  d3_tooltip() |>
  d3_brush()
```

should behave the same as v1.8. The DOM should still contain `path.geom-sf` polygon marks, tooltips should expose public row fields only, brush selection should use projected centroid attributes, and `d3_zoom()` should continue to warn and suppress unsupported zoom.

### Point sf Users

Users should be able to pass sf point data directly:

```r
ggplot(cities, aes(size = population, color = type)) +
  geom_sf() |>
  gg2d3() |>
  d3_tooltip() |>
  d3_hover() |>
  d3_brush()
```

Expected behavior:

- `POINT` rows render as SVG point marks projected into the sf panel.
- `MULTIPOINT` rows render all child points while retaining one source-row identity.
- Mapped `color`, `fill`, `alpha`, and `size` are honored as far as existing gg2d3 point semantics allow.
- Tooltips and custom handlers receive sanitized row data, not renderer-private geometry fields.
- Brushing selects point marks by projected pixel position.
- Facets and stacked sf layers use panel-specific projection metadata.

### Line sf Users

Users should be able to pass line sf data directly:

```r
ggplot(routes, aes(color = route_type, linewidth = traffic)) +
  geom_sf() |>
  gg2d3() |>
  d3_tooltip() |>
  d3_hover()
```

Expected behavior:

- `LINESTRING` and `MULTILINESTRING` rows render as SVG paths using geometry coordinate order.
- Lines use stroke-oriented semantics: no accidental polygon fill, visible stroke, linewidth, alpha, and linetype where supported.
- Brushing uses a projected line anchor or centroid, not full line-intersection geometry.
- A line overlay on a polygon map aligns with the polygon layer because both use the same panel projection.

### Unsupported sf Users

Users with unsupported geometry families should get predictable behavior:

- Empty, invalid, missing, and unsupported rows are skipped with warnings.
- Valid accepted rows in the same layer still render.
- `GEOMETRYCOLLECTION`, sf text/label geoms, basemaps, slippy map controls, JavaScript CRS reprojection, and map zoom remain unsupported and documented.

## Developer Perspective

### DOM Browser Validation Contract

The browser validation suite should verify observable rendered behavior:

| Fixture | DOM Assertions | Interaction Assertions |
|---------|----------------|------------------------|
| Single-panel polygon choropleth | `path.geom-sf` count, non-empty `d`, finite `data-cx`/`data-cy`, `data-row-id`, fill/stroke attrs | Tooltip target attaches; brush dims unselected polygons; callback rows are sanitized |
| Stacked polygon + point overlay | Polygon paths and point circles both present; one panel projection; overlay coordinates fall inside panel | Hover/tooltip selectors target both families |
| Stacked polygon + line overlay | Polygon and line paths both present; line `d` non-empty; no fill on lines | Brush uses line anchor/centroid; handler row payload remains public |
| Faceted sf points/lines | Per-panel marks match panel data; empty panels do not fall back to global bbox | Brush is panel-local |
| Unsupported/mixed fixture | Accepted rows render; skipped rows are absent; diagnostics match warnings | Browser does not error on skipped geometries |
| sf zoom fixture | Widget renders normally | `d3_zoom()` warning is emitted and zoom behavior is not attached |

Use a real browser runner where possible. Playwright is a good fit because its locator assertions auto-retry and include DOM attribute/count checks; MDN confirms `querySelectorAll()` returns static selector matches, which is enough for low-level fallback assertions.

### sf IR Contract

Extend the current `prepare_sf_geometry_ir()` family rather than inventing a parallel sf pipeline.

Recommended accepted atomic families:

- Polygon: `POLYGON`, `MULTIPOLYGON` - already supported and must remain backward-compatible.
- Point: `POINT`, `MULTIPOINT`.
- Line: `LINESTRING`, `MULTILINESTRING`.

Recommended IR additions:

- A family discriminator such as `sf_family = "polygon" | "point" | "line"` when homogeneous.
- For mixed accepted atomic families, either split internally into family buckets or include a row-level family field. Prefer splitting internally in the renderer only if source row identity and diagnostics stay simple.
- Keep `row_id`, `geometries`, normalized `geometry`, `crs`, and `sf_diagnostics`.
- Expand `sf_diagnostics$accepted_geometry_types` and `unsupported_geometry_types`; add `accepted_geometry_families` if useful for validation.
- Compute `sf_bbox` from all accepted sf geometries in a panel, not just polygons.

### D3 Renderer Contract

Keep one sf projection model per panel and dispatch mark creation by GeoJSON geometry type.

Recommended DOM classes:

- Polygons: keep `path.geom-sf`; optionally add `geom-sf-polygon`.
- Points: `circle.geom-sf.geom-sf-point`.
- Lines: `path.geom-sf.geom-sf-line`.

Required attributes:

- All sf marks: `data-row-id`, finite `data-cx`, finite `data-cy` when a brush anchor exists.
- Paths: non-empty `d` for accepted line/polygon rows.
- Polygons: `fill-rule="evenodd"` remains for holes.
- Lines: `fill="none"` or equivalent no-fill behavior.
- Points: `cx`, `cy`, and `r`.

Interactivity selectors must target the full sf family, not only `path.geom-sf`. Browser tests should fail if a new sf mark renders but is invisible to tooltip, hover, brush, or handlers.

### Package Hardening Outcomes

Hardening should produce checkable results:

| Outcome | Done Means |
|---------|------------|
| Controlled ggplot2 private API usage | Calls to `ggplot2:::calc_element()` are centralized behind an internal helper with tests for common themes and meaningful fallback/error behavior |
| Smaller sf IR surface | sf geometry detection, filtering, CRS normalization, family classification, bbox calculation, and diagnostics are individually testable helpers |
| No stale renderer/documentation contradictions | README, vignette, diagnostics, roxygen, and renderer mappings agree on supported geoms and unsupported behavior |
| Safer unsupported-geom path | Unsupported geoms produce clear in-panel messages or warnings without silently blank widgets |
| Regression tests for known renderer edge cases | At least one targeted fixture covers the highest-risk existing edge cases touched by v1.9, especially sf projection, rect/tile clipping if modified, and orphaned geom mappings |
| Browser validation isolated from runtime | Users can install and render gg2d3 without browser automation dependencies |

## Validation Expectations

Minimum validation gates for v1.9:

- R tests for sf point/line IR extraction, CRS normalization, skipped-row diagnostics, source row identity, and panel `sf_bbox`.
- R/source tests for selector arrays including polygon, point, and line sf marks.
- Browser DOM smoke tests for polygon regression, point rendering, line rendering, stacked overlays, facets, brush, and zoom suppression.
- Documentation search checks to prevent stale polygon-only or non-polygon-unsupported claims after v1.9 docs are updated.
- Package hardening tests around any extracted private API wrapper or refactored `as_d3_ir()` helpers.

## Sources

### Local Project Sources - High Confidence

- `.planning/PROJECT.md` - v1.9 goal, v1.8 shipped state, target features, constraints, known tech debt.
- `.planning/milestones/v1.8-MILESTONE-AUDIT.md` - confirms v1.8 passed and identifies DOM-level sf browser smoke testing as remaining validation debt.
- `.planning/milestones/v1.8-REQUIREMENTS.md` - polygon support contract and deferred non-polygon sf requirements.
- `README.Rmd` - current public feature overview and polygon-family `geom_sf()` support note.
- `vignettes/gg2d3.Rmd` - current user-facing sf support contract, interactivity behavior, and error-handling guarantees.
- `vignettes/d3-drawing-diagnostics.md` - current limitations, private API risk, and non-polygon unsupported language to update.
- `R/sf_utils.R`, `R/gg2d3.R`, `inst/htmlwidgets/modules/geoms/sf.js`, `inst/htmlwidgets/modules/brush.js` - current sf IR/rendering/brush contracts.
- `.planning/codebase/CONCERNS.md` - monolithic IR, private ggplot2 API, renderer edge cases, and stale concerns relevant to hardening.

### External Primary Sources - High Confidence

- ggplot2 `geom_sf()` reference: https://ggplot2.tidyverse.org/reference/ggsf.html
  - Confirms `geom_sf()` draws points, lines, or polygons depending on simple features present; `geometry` is a special `sfc` aesthetic; CRS handling is coordinated by `coord_sf()`.
- sf simple features vignette: https://r-spatial.github.io/sf/articles/sf1.html
  - Confirms atomic sf geometry representations including `POINT`, `LINESTRING`, `POLYGON`, and mixed `sfc_GEOMETRY` cases.
- Playwright assertions docs: https://playwright.dev/docs/test-assertions
  - Supports DOM validation through locator assertions such as attribute, class, CSS, and count checks.
- MDN `querySelectorAll()` docs: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll
  - Supports low-level selector-based DOM checks when browser runner assertions need direct DOM queries.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| User-facing sf feature boundaries | HIGH | Local milestone docs and official ggplot2 docs agree on point/line/polygon `geom_sf()` semantics; project constraints clearly exclude map-engine behavior |
| DOM validation feature shape | MEDIUM-HIGH | Browser smoke assertions are clear; exact runner location and CI command require implementation planning |
| Point/line renderer contract | MEDIUM-HIGH | GeoJSON family semantics are clear; multipoint/multiline row identity needs careful implementation tests |
| Package hardening outcomes | MEDIUM | Tech debt is documented, but exact scope should stay constrained during roadmap planning |
| Deferred items | HIGH | Deferrals align with v1.8 requirements, project constraints, and existing diagnostics docs |
