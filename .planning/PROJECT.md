# gg2d3

## What This Is

An R package that renders ggplot2 graphics as interactive D3.js SVG visualizations in the browser via htmlwidgets. Users pass a ggplot object to `gg2d3()` and get a pixel-perfect D3 reproduction with tooltips, zoom, brush selection, and linked views. Aimed at the R community as an open-source package.

## Core Value

Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## Current State

v1.7 shipped 2026-05-18 — Choropleth Map Research milestone complete. Build-ready blueprint exists for adding `geom_sf` choropleth support: R-side IR extraction is prototyped and merged (`R/sf_utils.R`, GeomSf/CoordSf dispatch in `as_d3_ir.R`), a D3 sf renderer prototype is human-verified (`inst/htmlwidgets/modules/geoms/sf.js`), and the interactivity contract + phase-by-phase implementation blueprint are documented (`.planning/milestones/v1.7-phases/.../30-01-BLUEPRINT.md`). The public package site is live at https://davidzenz.github.io/gg2d3/ via pkgdown + GitHub Pages (Phase 31, cross-milestone — satisfies DOCS-02).

## Next Milestone Goals

No active milestone. Likely next candidate: **v1.8 sf build milestone (IMPL-04)** — execute Build Phases A/B/C from the v1.7 blueprint to turn the sf prototype into production:

- Canonicalize centroid attribute (`data-centroid="x,y"`) and migrate tooltip/hover/brush wiring
- Implement zoom architecture (`.sf-zoom-layer` SVG group transform + `vector-effect="non-scaling-stroke"`)
- Handle edge cases (mixed geometry sentinel + warn-not-drop; per-panel bbox for faceted sf)
- Production-grade tests covering the three edge cases and live interactivity flows

Run `/gsd-new-milestone` to plan.

<details>
<summary>Previous focus (v1.7 Choropleth Map Research — shipped 2026-05-18)</summary>

**Goal:** Investigate how gg2d3 can support choropleth map rendering via `geom_sf()` and produce a build-ready implementation blueprint.

**Delivered:**
- R sf extraction pipeline: `sf_utils.R` + GeomSf/CoordSf dispatch in `as_d3_ir.R`, WGS84 normalization, IR schema doc
- D3 sf renderer prototype: `sf.js` with `geoIdentity().reflectY(true).fitExtent()`, evenodd fill-rule for holes, centroid attrs
- SF interactivity design contract (29-01-SF-INTERACTIVITY-DESIGN.md, 654 lines, 11 design decisions)
- Implementation blueprint (30-01-BLUEPRINT.md, 734 lines) with edge cases, three explicit anti-features, and Build Phase A/B/C plan
- Cross-milestone: pkgdown site live with 44 interactive widgets in the Get Started vignette (Phase 31 → DOCS-02)

See `.planning/milestones/v1.7-ROADMAP.md` and `.planning/milestones/v1.7-MILESTONE-AUDIT.md` for full details.

</details>

**Shipped through v1.7:**
- 25 geom types with full interactivity (hover, tooltip, brush, zoom)
- Composable pipe-based interactivity API (`d3_tooltip`, `d3_zoom`, `d3_brush`, `d3_hover`, `d3_transitions`, `d3_handlers`)
- Interactive legends with toggle/solo/reset/hover
- Facets (wrap + grid) with linked interactivity
- Non-Cartesian coordinates (polar) and advanced stats (density, smooth)
- Comprehensive theme parity and reference geoms
- Performance optimized for >5000 points
- `geom_sf` prototype + build-ready blueprint (v1.7 research)
- Public pkgdown site at https://davidzenz.github.io/gg2d3/ (Phase 31 distribution)

## Requirements

### Validated

- ✓ Basic geom rendering (point, line, path, bar, col, rect, tile, text) — pre-existing
- ✓ Continuous and categorical scale support — pre-existing
- ✓ Axis rendering with titles — pre-existing
- ✓ Color and fill aesthetic mapping — pre-existing
- ✓ Theme translation (backgrounds, grids, axes, text) — pre-existing
- ✓ Stacked bars — pre-existing
- ✓ Basic coord_flip support — pre-existing
- ✓ Three-layer pipeline (R → IR → D3) — pre-existing
- ✓ htmlwidgets integration — pre-existing
- ✓ Full geom coverage (statistical, area/ribbon, annotation geoms) — v1.0
- ✓ Pixel-perfect visual fidelity matching ggplot2 output — v1.0
- ✓ Legend rendering for all aesthetic types — v1.0
- ✓ Facet support (facet_wrap, facet_grid) — v1.0
- ✓ Full scale coverage (date/time, color palettes, sqrt, reverse) — v1.0
- ✓ Pipe-based interactivity API (tooltips, linked views) — v1.0
- ✓ Comprehensive test suite — v1.0
- ✓ Interactive legend controls (toggle/filter/highlight) — v1.1
- ✓ Animation and transition support — v1.2
- ✓ Advanced facets and custom interactivity — v1.3
- ✓ Comprehensive theme parity and reference geoms — v1.4
- ✓ Non-Cartesian systems and advanced stats — v1.5
- ✓ Specialized geoms (dotplot, rug, errorbar, linerange, pointrange) — v1.6
- ✓ Full interactivity wiring for all 25 geoms — v1.6
- ✓ `geom_sf()` IR extraction via `ggplot_build()` + GeomSf/CoordSf dispatch — v1.7 (Phase 27)
- ✓ Polygon/multipolygon geometry mapping to IR layer (GeoJSON via geojsonsf) — v1.7 (Phase 27)
- ✓ D3 `d3.geoPath()` + `geoIdentity().reflectY().fitExtent()` rendering prototype — v1.7 (Phase 28)
- ✓ CRS handling — unconditional WGS84 normalization in R (no JS reprojection) — v1.7 (Phase 27)
- ✓ Interactivity design contract for `path.geom-sf` (tooltip/brush/zoom) — v1.7 (Phase 29)
- ✓ Choropleth implementation blueprint with edge cases + anti-features + Build Phase A/B/C — v1.7 (Phase 30)
- ✓ Public pkgdown site at https://davidzenz.github.io/gg2d3/ with live widgets in Get Started — v1.7 distribution (Phase 31, DOCS-02)

### Active

(None — next milestone TBD; run `/gsd-new-milestone`)

### Out of Scope

- Shiny integration beyond basic htmlwidgets — separate future effort
- Custom D3 extensions unrelated to ggplot2 mapping — not the package's purpose
- ggplot2 extension packages (ggridges, ggrepel, etc.) — focus on core ggplot2 first
- Mobile-specific optimizations — web-first

## Context

gg2d3 shipped v1.7 (Choropleth Map Research) with the package source tree at ~14,900 LOC across R + JavaScript + Rmd. The three-layer pipeline (R → IR → D3) now extends to `geom_sf` via a prototype path (`R/sf_utils.R`, GeomSf/CoordSf dispatch in `as_d3_ir.R`, `inst/htmlwidgets/modules/geoms/sf.js`) with sf and geojsonsf added to Suggests (no GDAL/GEOS/PROJ forced on users). The public package site is live and rebuilt on every push to master.

**Known tech debt:**
- Monolithic `as_d3_ir()` function (~1000 lines) needs modularization
- Private API dependency on `ggplot2:::calc_element()` creates fragility
- Orphaned GeomPolygon reference (no renderer) — flagged in v1.7 blueprint as deferred deferred item, not anti-feature
- rect geom edge cases with out-of-bounds rendering
- Phase 29 design-doc human-UAT items remain pending (4 subjective reads); programmatic verification of the doc passed (6/6 truths)
- Phase 31 user-setup plan (31-04 GitHub Pages enablement) and Phase 31 itself have no formal SUMMARY/VERIFICATION artifacts despite live deployment

## Constraints

- **Tech stack**: R + JavaScript (D3.js v7) via htmlwidgets — established, not changing
- **ggplot2 compatibility**: Must work with current ggplot2 release; private API usage (`:::calc_element()`) is a known fragility
- **Visual fidelity**: Pixel-perfect matching of ggplot2 output at 96 DPI web standard
- **Package conventions**: Must follow CRAN-compatible R package structure (DESCRIPTION, NAMESPACE, roxygen2 docs)
- **Browser rendering**: SVG output only, no canvas/WebGL — D3.js conventions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Geom coverage before visual polish | User priority — broader coverage unlocks more use cases | ✓ Good — 25 geoms shipped |
| Legends early, facets later | Legends needed to verify geom rendering; facets are more complex | ✓ Good — legends ready for facet integration |
| Pipe-based interactivity API | Composable like ggplot layers: `gg2d3(p) \|> d3_tooltip() \|> d3_zoom()` | ✓ Good — clean API, non-breaking |
| Pixel-perfect fidelity target | R community expects professional output matching ggplot2 | ✓ Good — ggplot2 .pt conversion factor, visual verification |
| Registry-based geom dispatch | Adding new geoms without modifying core rendering code | ✓ Good — 25 geoms self-register |
| Pure-function layout engine | Single source of truth for all positioning, no DOM dependency | ✓ Good — eliminated magic numbers |
| Pre-computed statistics in R | Statistical computations (boxplot, violin, density, smooth) in R, not JS | ✓ Good — leverages ggplot2's stat system |
| D3 scaleUtc for temporal axes | Consistent cross-browser rendering with UTC-based time scales | ✓ Good — timezone-aware tooltips via Intl.DateTimeFormat |
| Crosstalk for linked views | Client-side linked brushing without Shiny dependency | ✓ Good — works in static HTML |
| Scoped INTERACTIVE_SELECTORS | Each interactivity module maintains its own selector array for geom classes | ✓ Good — extensible, caught as gap in v1.6 audit |
| Standardized onRender pattern | All d3_* functions use consistent onRender + setTimeout for reliable event attachment | ✓ Good — eliminated race conditions |
| sf research before sf build | Investigate `geom_sf()` end-to-end (IR + D3 + interactivity + edge cases) before committing to a build milestone, to avoid scope explosion mid-build | ✓ Good — v1.7 shipped a build-ready blueprint; IMPL-04 can execute against file/line-anchored plan |
| `geojsonsf::sfc_geojson()` for sf serialization | Native sfc → GeoJSON in R is faster and lossless vs. jsonlite roundtrip | ✓ Good — adopted in `sf_utils.R` |
| Unconditional WGS84 normalization in R | `sf::st_transform(geom_col, 4326)` before serialization eliminates need for JS-side reprojection (an explicit anti-feature) | ✓ Good — `coord.bbox` always WGS84 |
| `d3.geoIdentity().reflectY(true).fitExtent()` for sf rendering | Avoid JS reprojection while still aligning SVG y-axis correctly; one-line projection setup | ✓ Good — works for NC and world borders prototypes |
| `fill-rule="evenodd"` for multipolygon holes | SVG default winding rule renders holes as filled; evenodd correctly renders holes as transparent | ✓ Good — verified visually with world borders |
| Centroid-based brush (reject polygon hit-testing) for sf | Centroid storage is O(N) cheap; polygon hit-test cost grows with vertex count and offers minor UX benefit | ✓ Good — D-06 with three documented rationales (memory/compute/UX) |
| SVG group-transform zoom for sf (diverge from element-repositioning) | Reapplying geoPath on every zoom is expensive; group transform with non-scaling-stroke achieves same UX cheaply | ✓ Good — D-08/09/10 in 29-01 design doc |
| `vector-effect="non-scaling-stroke"` as SVG presentation attribute (not CSS) | CSS rules don't survive `saveWidget` serialization; presentation attributes do | ✓ Good — D-09 explicit NOT-CSS framing |
| Three explicit sf anti-features (tile basemaps, JS reprojection, slippy zoom) | Each conflicts with SVG-only mandate or existing zoom architecture — durable rationales prevent scope creep | ✓ Good — distinguished from "deferred" items |
| pkgdown via r-lib v2-branch template + SHA-pinned deploy action | Match the canonical r-lib pattern (auditable, well-supported); SHA-pin deploy action mitigates supply-chain risk | ✓ Good — site live with widgets on 2026-05-17 |

---
*Last updated: 2026-05-18 after v1.7 Choropleth Map Research milestone shipped*
