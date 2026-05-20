# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)
- ◆ **v1.8 Production geom_sf Polygon MVP** — Phases 32-35 (active)

## Active Milestone: v1.8 Production geom_sf Polygon MVP

**Goal:** Ship production-safe `geom_sf` polygon rendering for gg2d3, starting with polygon-family choropleths and the interactivity behaviors proven in v1.7.

**Requirements:** 11 total, 11 mapped
**Phases:** 4
**Starting phase:** 32

### Phase 32: geom_sf IR Foundation

**Goal:** Implement the R-side sf extraction path that converts polygon-family `geom_sf` layers into stable, validated gg2d3 IR.

**Requirements:** SFIR-01, SFIR-02, SFIR-03
**Depends on:** v1.7 Phase 27 findings and Phase 30 blueprint
**Status:** Complete

**Success criteria:**
1. `gg2d3()` extracts `POLYGON` and `MULTIPOLYGON` geometries from `geom_sf` layers into JSON-serializable IR.
2. Known CRS inputs are normalized to WGS84 in R before GeoJSON serialization.
3. IR carries bbox/projection metadata needed by the D3 renderer without requiring JavaScript reprojection.
4. Unsupported, empty, invalid, or missing geometries warn or skip predictably while preserving valid row alignment.

**Likely files:**
- `R/sf_utils.R`
- `R/as_d3_ir.R`
- `R/validate_ir.R`
- `tests/testthat/test-sf-ir.R`

### Phase 33: Single-Panel Renderer and Interactivity

**Goal:** Render single-panel polygon choropleths as D3 SVG paths and wire them into the existing tooltip, hover, brush, and zoom APIs.

**Requirements:** SFREND-01, SFINTR-01, SFINTR-02, SFINTR-03
**Depends on:** Phase 32
**Status:** Complete

**Success criteria:**
1. `geom_sf` polygons render as `path.geom-sf` with fill, stroke, and multipolygon hole behavior matching the v1.7 prototype.
2. `path.geom-sf` elements expose stable row ids and centroid attributes (`data-cx`, `data-cy`).
3. Existing tooltip and hover APIs work against bound sf row data.
4. Existing brush APIs select sf regions by centroid containment.
5. `d3_zoom()` detects sf layers and warns/suppresses unsupported Cartesian zoom behavior.

**Likely files:**
- `inst/htmlwidgets/modules/geoms/sf.js`
- `inst/htmlwidgets/modules/events.js`
- `inst/htmlwidgets/modules/brush.js`
- `R/d3_zoom.R`
- `tests/testthat/test-sf-renderer.R`
- `tests/testthat/test-sf-visual.R`

### Phase 34: Stacked and Faceted Projection Alignment

**Goal:** Extend sf projection handling so stacked sf layers align in one panel and faceted sf maps fit each panel from its own data.

**Requirements:** SFREND-02, SFREND-03
**Depends on:** Phase 33
**Status:** Complete

**Success criteria:**
1. Multiple sf layers in the same panel share one panel-level bbox/projection instead of fitting each layer independently.
2. `gg2d3.js` passes shared panel projection state into every sf layer renderer.
3. `facet_wrap()` sf maps filter rows by `PANEL` and fit each panel using that panel's sf features.
4. `facet_grid()` sf maps preserve panel layout and use per-panel bbox/projection metadata without cross-panel leakage.

**Likely files:**
- `R/as_d3_ir.R`
- `R/sf_utils.R`
- `R/validate_ir.R`
- `inst/htmlwidgets/gg2d3.js`
- `inst/htmlwidgets/modules/geoms/sf.js`
- `tests/testthat/test-facets.R`
- `tests/testthat/test-facet-grid.R`
- `tests/testthat/test-sf-visual.R`

### Phase 35: geom_sf Docs and Validation Hardening

**Goal:** Lock down the production sf behavior with docs, diagnostics, automated checks, and browser validation fixtures.

**Requirements:** SFDOC-01, SFDOC-02
**Depends on:** Phase 34
**Status:** Pending

**Success criteria:**
1. Package docs describe supported polygon behavior, unsupported geometry handling, zoom suppression, and map anti-features.
2. Validation fixtures cover single-panel choropleths, stacked overlays, facet wrap maps, and facet grid maps.
3. Tests cover unsupported geometry warnings/skips and guard against misleading selectable paths for invalid geometry rows.
4. README/vignette/help output gives users a clear, truthful `geom_sf` support story.

**Likely files:**
- `README.Rmd`
- `README.md`
- `vignettes/geom-sf-blueprint.Rmd`
- `vignettes/d3-drawing-diagnostics.md`
- `man/gg2d3.Rd`
- `tests/testthat/test-sf-ir.R`
- `tests/testthat/test-sf-renderer.R`
- `tests/testthat/test-sf-visual.R`

## Archived Milestones

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-02-16</summary>

See `.planning/milestones/v1.0-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.1 Interactive Exploration (Phases 13-15) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.1-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.2 Smooth Transitions & Scale Parity (Phases 16-17) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.2-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.3 Advanced Facets & Custom Interactivity (Phases 18-19) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.3-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.4 Comprehensive Theme Parity & Reference Geoms (Phases 20-21) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.4-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.5 Non-Cartesian Systems & Advanced Stats (Phases 22-23) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.5-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.6 Advanced Geoms & API Polish (Phases 24-26) — SHIPPED 2026-04-04</summary>

See `.planning/milestones/v1.6-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.7-ROADMAP.md` for full details.

Delivered the `geom_sf` research handoff: R extraction feasibility, D3 polygon rendering prototype, interactivity design, and future implementation blueprint.

</details>

<details>
<summary>✅ Distribution: pkgdown and GH Pages Publishing (Phase 31) — SHIPPED 2026-05-17</summary>

Phase 31 was orthogonal to the v1.7 choropleth stream. It ported the pkgdown/GitHub Pages publishing work from the v1.1 `stupefied-austin` branch.

See `.planning/milestones/v1.7-ROADMAP.md` and phase history for distribution details.

</details>

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 32. geom_sf IR Foundation | v1.8 | 2/2 | Complete    | 2026-05-20 |
| 33. Single-Panel Renderer and Interactivity | v1.8 | 3/3 | Complete    | 2026-05-20 |
| 34. Stacked and Faceted Projection Alignment | v1.8 | 2/2 | Complete | 2026-05-20 |
| 35. geom_sf Docs and Validation Hardening | v1.8 | SFDOC-01, SFDOC-02 | Pending | — |

---
*Roadmap updated: 2026-05-20 after completing Phase 34*
