# Project Research Summary

**Project:** gg2d3 v1.7 — geom_sf / choropleth map rendering
**Domain:** Geographic visualization extension to an existing ggplot2-to-D3 SVG pipeline
**Researched:** 2026-04-04
**Confidence:** HIGH (R layer and D3-geo API), MEDIUM (ggplot_build sf geometry column survival — needs empirical verification)

## Executive Summary

gg2d3 v1.7 adds choropleth map rendering by extending the existing three-layer pipeline (R -> IR -> D3) to handle `geom_sf` layers. The recommended approach is a clean separation of concerns: R normalizes CRS to WGS84 and serializes geometries to GeoJSON strings via `geojsonsf::sfc_geojson()`; the IR carries geometries as a parallel array alongside existing aesthetic row data; JavaScript renders `<path>` elements using `d3.geoIdentity().reflectY(true).fitExtent()` — deliberately not re-projecting, since `coord_sf` has already handled projection on the R side. No new JavaScript libraries are needed; `d3-geo` is already bundled in the vendored D3 v7.9.0. The `sf` and `geojsonsf` packages go into `Suggests`, not `Imports`, to avoid forcing GDAL/GEOS/PROJ system dependencies on users who don't need maps.

The implementation splits cleanly into four phases that match the existing codebase's module boundaries: (1) R-side IR extraction, (2) basic D3 rendering, (3) interactivity wiring, and (4) edge cases and polish. Phase 1 is the feasibility gate — if `ggplot_build()` does not preserve the `sfc` geometry list-column through its data transformation, the entire feature set is blocked. Research strongly indicates it is preserved (per ggplot2 source and related GitHub issues), but this must be verified empirically before implementation begins.

The primary technical risks are all known and preventable: the `sfc` geometry column breaking existing `to_rows()` serialization (avoid by extracting geometry before calling `to_rows()`), the Cartesian scale system being meaningless for `coord_sf` plots (bypass entirely, use `bbox` instead), winding order mismatches causing holes to render as filled regions (fix with `fill-rule="evenodd"`), and D3 zoom being architecturally incompatible with geoPath rendering (suppress or implement as a separate panel-level transform). None of these require redesigning existing architecture — they are additive special cases with well-documented solutions.

## Key Findings

### Recommended Stack

The v1.6 stack is unchanged. Two new R packages are added to `Suggests` only. No new JS libraries are required.

**Core technologies (net-new for v1.7):**
- `sf` (>= 1.0-0, CRAN Feb 2026): CRS detection, WGS84 normalization via `st_transform()`, geometry type inspection — the only authoritative R spatial package; sp/rgdal are deprecated and CRAN-archived
- `geojsonsf` (2.0.3, CRAN Nov 2025): `sfc_geojson()` converts an `sfc` list-column to a character vector of GeoJSON strings — C++ backed, in-memory, no I/O overhead; preferred over `jsonlite::toJSON(sf_object)` which wraps in a FeatureCollection and breaks the per-row IR format
- `d3-geo` (bundled in d3 v7.9.0, already vendored): `d3.geoPath()`, `d3.geoIdentity()`, `fitExtent()` — no additional vendoring needed

**Critical version note:** `geojsonsf` requires `sf >= 1.0`; `sf 1.0+` uses WKT2 for CRS strings (not proj4), which is what `st_crs()` returns. All version dependencies are already satisfied by the existing environment.

### Expected Features

**Must have (table stakes — P1, v1.7 MVP):**
- Polygon region rendering: `geom_sf(aes(fill = var))` produces filled `<path>` elements via `d3.geoPath()`
- Fill aesthetic mapped to data variable — ggplot_build resolves hex per row; IR passthrough is trivial once geometry extraction works
- Boundary stroke (colour + linewidth aesthetics) — standard SVG path rendering
- Aspect ratio preservation — `geoIdentity().fitExtent()` handles this automatically
- Hover tooltip on region — extend existing `d3_tooltip()` to include `path.geom-sf` selectors
- Hover highlight (opacity dim on non-hovered regions) — extend existing `d3_hover()` INTERACTIVE_SELECTORS
- `theme_void()` compatibility — axes/grids suppressed when `CoordSf` detected; panel background behavior must be verified

**Should have (differentiators — P2, v1.7.x):**
- POINT and LINESTRING geom_sf dispatch — route to existing point/line renderers via geometry type detection
- Multiple geom_sf layer stacking (e.g., polygon fill layer + border overlay layer)
- Stepped/binned fill scales (`scale_fill_steps`) — explicit validation; likely works already since ggplot_build resolves to hex values per row

**Defer (v2+):**
- Map-specific zoom/pan — conflicts with existing Cartesian zoom; requires separate geoPath projection rescaling
- Click-to-select region for linked views — rectangular brush does not generalize to polygon hit-testing
- Raster/tile basemap — outside SVG-only mandate; Leaflet is the right tool for tile maps
- Additional named D3 projections (Mercator, Albers) — `geoIdentity + fitExtent` is correct for the R-projected case
- `geom_sf_text` / `geom_sf_label` — requires interior point extraction and coordinate projection; scope-increasing for MVP

### Architecture Approach

The integration is additive and follows existing module patterns without redesigning the pipeline. A new `R/sf_utils.R` centralizes sf-specific R functions behind optional `requireNamespace()` guards. A new `inst/htmlwidgets/modules/geoms/sf.js` self-registers in the existing geom registry. The main `gg2d3.js` render path gets a single routing branch: if `ir.coord.type === "sf"`, call `renderSfPanel()` (which skips Cartesian scale creation); otherwise proceed unchanged. The IR gains three additive fields on sf layers (`geometries[]`, `crs`, `geom_type`) and two fields on the coord object (`coord.type = "sf"`, `coord.bbox`).

**Major components:**
1. `R/sf_utils.R` (new) — `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, `get_layer_crs()`; isolates all sf dependency behind `requireNamespace()` guards
2. `R/as_d3_ir.R` (modified) — add `GeomSf` to geom dispatch switch; add `CoordSf` branch to coord detection; call sf_utils functions in sf layer path; exclude `geometry` column from `keep_aes`
3. `inst/htmlwidgets/modules/geoms/sf.js` (new) — parses GeoJSON strings, builds `geoIdentity().reflectY(true).fitExtent()` projection, renders `<path class="geom-sf">` per row, computes centroids as `data-cx`/`data-cy` for brush compatibility
4. `inst/htmlwidgets/gg2d3.js` (modified) — `renderSfPanel()` function; coord routing branch at panel dispatch
5. `modules/events.js`, `modules/brush.js` (modified) — add `'path.geom-sf'` to INTERACTIVE_SELECTORS (only after centroid attributes are implemented in sf.js)

### Critical Pitfalls

1. **sfc geometry column breaks `to_rows()` serialization** — `sfc` list-columns are not JSON-serializable by `jsonlite`; the `keep_aes` whitelist silently drops them. Fix: extract geometry via `geojsonsf::sfc_geojson()` before calling `to_rows()`, exclude `"geometry"` from `keep_aes` for sf layers, store as a parallel `layer.geometries[]` array. Address in Phase 1 — this is the foundational blocker.

2. **`coord_sf` bypasses the entire Cartesian scale system** — `ir.scales.x/y` will be meaningless for sf plots; passing them to the renderer causes crashes or empty output. Fix: detect `CoordSf` early, short-circuit Cartesian scale extraction entirely, emit `ir.coord.bbox` instead, build geoPath from panel dimensions in the sf renderer. Address in Phases 1 and 2.

3. **GeoJSON winding order mismatch causes holes to render filled** — `geojsonsf` outputs RFC 7946 winding (exterior CCW, holes CW); d3-geo expects the opposite. Fix: set `fill-rule="evenodd"` on all `path.geom-sf` elements. One-line fix, but invisible without testing against a MULTIPOLYGON with interior rings. Address in Phase 2.

4. **Non-WGS84 CRS input collapses rendering** — projected coordinates (e.g., EPSG:3857 in meters) are numerically incompatible with the `geoIdentity + fitExtent` approach. Fix: always call `sf::st_transform(geom_col, 4326)` unconditionally before serialization. Never make this optional. Address in Phase 1.

5. **Geometry column name is not always `"geometry"`** — PostGIS-sourced data frequently uses `the_geom`; hardcoding the column name causes silent empty renders. Fix: always use `attr(data, "sf_column")` with fallback to `names(data)[sapply(data, inherits, "sfc")][1]`. Address in Phase 1.

**Additional pitfalls to track:** D3 zoom incompatibility with geoPath (Phase 3 — suppress zoom for sf panels or implement separate panel-level transform); brush INTERACTIVE_SELECTORS update order (add centroid attributes to paths in Phase 2 before adding selector in Phase 3); large geometry payload bloat (add size warning in Phase 1; document `rmapshaper::ms_simplify()` preprocessing).

## Implications for Roadmap

Research maps cleanly to four sequential phases with clear dependency ordering. The architecture team's suggested build order matches the dependency graph: R extraction must precede D3 rendering, which must precede interactivity wiring, which must precede edge case handling.

### Phase 1: R IR Extraction — geom_sf Layer Support

**Rationale:** Every downstream phase depends on the IR correctly representing sf layers. If geometry extraction fails, there is nothing to render. This phase has no JavaScript dependency and can be verified with pure R tests. It also contains the highest concentration of critical pitfalls (5 of 8 pitfalls are Phase 1 concerns).

**Delivers:** `gg2d3(p)` where `p` has `geom_sf` correctly serializes to IR — `layer.geometries[]` contains valid GeoJSON strings, `layer.data[]` contains resolved aesthetics, `ir.coord.type === "sf"` and `ir.coord.bbox` are present. All 8 critical pitfalls have prevention code in place.

**Implements:**
- `R/sf_utils.R`: `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, `get_layer_crs()`
- `as_d3_ir.R`: `GeomSf` dispatch, `CoordSf` branch, `geometry` exclusion from `keep_aes`, parallel `geometries[]` array
- `DESCRIPTION`: add `sf` and `geojsonsf` to `Suggests`
- Add payload size warning for large geometry sets

**Avoids:** Pitfalls 1 (sfc serialization), 4 (CRS normalization), 8 (geometry column name), 7 (payload size warning)

**Research flag:** VERIFY FIRST — empirically confirm `ggplot_build()` preserves the `sfc` geometry list-column with current ggplot2 (3.5.x / 4.0.x). Run `b <- ggplot_build(ggplot(nc) + geom_sf()); "geometry" %in% names(b$data[[1]])` before writing any extraction code. This is the feasibility gate for the entire milestone.

### Phase 2: D3 Renderer — Basic Polygon Rendering

**Rationale:** Core visual output. No interactivity needed to prove the rendering pipeline works. Should be verified with visual tests before wiring interactivity, which is harder to debug. The `fill-rule="evenodd"` fix for winding order must be applied here, not retroactively.

**Delivers:** A `gg2d3(ggplot(nc) + geom_sf(aes(fill = BIR74)))` call renders a correctly filled, correctly oriented choropleth with visible region boundaries and fill colors matching ggplot2's output.

**Implements:**
- `inst/htmlwidgets/modules/geoms/sf.js`: `renderSf()`, `geoIdentity().reflectY(true).fitExtent()`, per-row `<path class="geom-sf">`, `fill-rule="evenodd"`, centroid computation as `data-cx`/`data-cy` data attributes
- `gg2d3.js`: `renderSfPanel()`, coord routing branch
- `gg2d3.yaml`: include `modules/geoms/sf.js` in module load order

**Avoids:** Pitfalls 2 (Cartesian scale bypass), 3 (winding order), 5 (D3 zoom incompatibility — suppress zoom for sf panels in this phase)

**Research flag:** STANDARD — `d3.geoIdentity`, `d3.geoPath`, `fitExtent` are well-documented D3 APIs; no additional research needed. Visual verification required with NC shapefile test fixture.

### Phase 3: Interactivity Wiring

**Rationale:** Hover tooltip and highlight are P1 MVP features and the primary interactive differentiator over static ggplot2 maps. Must come after Phase 2 because the interactivity selectors depend on `path.geom-sf` elements existing in the DOM with centroid data attributes computed in Phase 2.

**Delivers:** Hovering over a map region shows tooltip with fill value (and label aesthetic if present); non-hovered regions dim. Brush rectangle draws and highlights/dims polygon regions by centroid position.

**Implements:**
- `modules/events.js`: add `'path.geom-sf'` to INTERACTIVE_SELECTORS
- `modules/brush.js`: add `'path.geom-sf'` to INTERACTIVE_SELECTORS; verify `data-cx`/`data-cy` attributes drive brush selection logic
- Tooltip data attributes on path elements: `data-tooltip`, `data-fill-value`, region identifier

**Avoids:** Pitfall 6 (brush incompatibility — centroid-based selection, not polygon overlap)

**Research flag:** STANDARD — follows existing `d3_hover()` and `d3_tooltip()` extension patterns from v1.6 interactivity wiring. Pattern is documented in project MEMORY.md.

### Phase 4: Edge Cases and Polish

**Rationale:** Handles real-world data patterns (mixed geometry types, multiple layers, faceted maps) that don't appear in the canonical NC shapefile test case but will surface immediately in user adoption. Also the right phase to decide whether to implement proper geographic zoom or document the limitation.

**Delivers:** Multiple geom_sf layers stack correctly; POINT and LINESTRING geometries dispatch to existing renderers; faceted sf maps filter by PANEL column; IR schema validator updated to accept new sf fields; explicit zoom behavior (suppressed with documentation, or SVG group transform approach).

**Implements:**
- Geometry type dispatch: POLYGON/MULTIPOLYGON -> sf.js, POINT -> existing point renderer, LINESTRING -> existing path renderer
- Multiple layer stacking: second `geom_sf` layer renders above first; `<g>` layer order correct
- Facet support: filter `b$data[[i]]` by `PANEL` column for sf layers (same as Cartesian geoms)
- `validate_ir.R`: add optional `coord.type`, `coord.bbox`, `layer.geometries`, `layer.crs`, `layer.geom_type` fields if validator exists
- Zoom: SVG group transform approach or explicit zoom suppression with `warning("Zoom not supported for geom_sf panels in gg2d3 v1.7")`

**Research flag:** NEEDS RESEARCH — Zoom approach decision. Project MEMORY.md documents that gg2d3 deliberately avoided SVG group transforms for Cartesian zoom (stroke width scaling). Same concern applies here. Evaluate whether the tradeoff is acceptable for geographic zoom or whether zoom should remain suppressed through v1.7.

### Phase Ordering Rationale

- **Phase 1 before Phase 2:** No rendering without IR data. The `ggplot_build()` geometry column survival check is the single most important feasibility gate.
- **Phase 2 before Phase 3:** Selectors and event handlers require target DOM elements to exist. Computing centroids in Phase 2 enables centroid-based brush selection in Phase 3 without reopening Phase 2 files.
- **Phase 3 before Phase 4:** Interactivity wiring must work on the canonical single-layer polygon case before testing complex multi-layer and faceted scenarios that add more moving parts.
- **Geometry, then aesthetics, then interaction:** Follows the existing gg2d3 phasing pattern established across all 26 prior phases.

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 1 (before any code):** Empirical verification of `ggplot_build()` geometry column survival — run `b <- ggplot_build(ggplot(nc) + geom_sf()); "geometry" %in% names(b$data[[1]])` before writing any extraction code. If FALSE, the entire approach changes.
- **Phase 4:** Geographic zoom architecture decision — SVG group transform vs. geoPath re-render vs. suppression. Needs a short spike to evaluate stroke-width scaling behavior before committing.

**Phases with standard patterns (skip research):**
- **Phase 2:** `d3.geoPath`, `geoIdentity`, `fitExtent`, `reflectY` are all in official D3 documentation with working examples. Standard choropleth render pattern.
- **Phase 3:** Follows established v1.6 interactivity extension pattern. MEMORY.md has the exact D3 selector and brush architecture documented.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | sf, geojsonsf, d3-geo all verified via official CRAN and D3 documentation. Version compatibility confirmed. No alternatives needed. |
| Features | HIGH | Feature taxonomy is definitive. The one LOW-confidence item (ggplot_build geometry column survival) is a binary empirical check, not a research gap. |
| Architecture | HIGH | Pipeline mechanics verified against ggplot2 source code and existing gg2d3 codebase. Three anti-patterns and their fixes are concrete and sourced. |
| Pitfalls | HIGH | 8 pitfalls with concrete prevention strategies. Winding order, CRS normalization, brush centroid approach all documented in official sources or verified community patterns. |

**Overall confidence:** HIGH — the implementation path is clear. The only meaningful uncertainty is the `ggplot_build()` geometry column empirical check, which should be the first act of Phase 1.

### Gaps to Address

- **ggplot_build geometry column survival (LOW, empirical):** Must verify `b$data[[i]]$geometry` exists and retains `sfc` class after `ggplot_build()` with current ggplot2. FEATURES.md flags historical issues (ggplot2 GitHub issue #3453). Run test before writing `extract_sf_geometries()`. If geometry is stripped, the fallback is to extract directly from `p$layers[[i]]$data` before `ggplot_build()`, but aesthetics won't be resolved — this would require substantial rework.
- **validate_ir.R schema coverage:** Not confirmed whether gg2d3 v1.6 has a schema validator. If it exists, it must be updated in Phase 4. Check `R/validate_ir.R` at Phase 4 start.
- **Faceted sf map data structure:** How `coord_sf` interacts with `b$layout` for faceted plots was not verified. Standard facet handling (`filter(PANEL == panel_num)`) likely applies but should be confirmed during Phase 4 planning.

## Sources

### Primary (HIGH confidence)

- https://cran.r-project.org/web/packages/sf/sf.pdf — sf 1.1-0 CRAN release date, system deps, API
- https://r-spatial.github.io/sf/reference/st_transform.html — st_transform CRS conversion
- https://r-spatial.github.io/sf/reference/st_crs.html — st_crs introspection and WGS84/EPSG:4326 usage
- https://cran.r-project.org/web/packages/geojsonsf/geojsonsf.pdf — sfc_geojson API, CRAN Nov 2025 build
- https://d3js.org/d3-geo/path — d3.geoPath API, SVG path output, geoPath.bounds for bounding box
- https://d3js.org/d3-geo/projection — geoIdentity.reflectY(true), fitExtent/fitSize API
- https://github.com/tidyverse/ggplot2/blob/main/R/geom-sf.R — geometry column preserved through ggplot_build, aesthetic defaults per geometry type
- https://ggplot2.tidyverse.org/reference/ggsf.html — coord_sf, geom_sf public API

### Secondary (MEDIUM confidence)

- https://github.com/SymbolixAU/geojsonsf — geojsonsf v2.0.3, CRAN date confirmed Nov 2025
- https://macwright.com/2015/03/23/geojson-second-bite — GeoJSON winding order vs D3 convention analysis
- https://r-graph-gallery.com/327-chloropleth-map-from-geojson-with-ggplot2.html — standard choropleth workflow patterns
- https://d3-graph-gallery.com/graph/choropleth_hover_effect.html — D3 choropleth hover interaction pattern
- https://github.com/tidyverse/ggplot2/issues/3453 — ggplot_build geometry column survival with tibble versions (historical, resolved)

### Tertiary (LOW confidence — needs empirical validation)

- ggplot_build output structure for sf layers — inferred from ggplot2 source and documentation; must be verified in a running R session before Phase 1 implementation

### Internal

- gg2d3 MEMORY.md — D3 brush architecture, pixel-position vs. data-domain design decision, zoom filter pattern
- gg2d3 brush.js, events.js, geom-registry.js, as_d3_ir.R — existing patterns that sf integration must follow

---
*Research completed: 2026-04-04*
*Ready for roadmap: yes*
