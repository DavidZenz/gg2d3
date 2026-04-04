# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- 🚧 **v1.7 Choropleth Map Research** — Phases 27-30 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-02-16</summary>

See .planning/milestones/v1.0-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.1 Interactive Exploration (Phases 13-15) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.1-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.2 Smooth Transitions & Scale Parity (Phases 16-17) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.2-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.3 Advanced Facets & Custom Interactivity (Phases 18-19) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.3-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.4 Comprehensive Theme Parity & Reference Geoms (Phases 20-21) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.4-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.5 Non-Cartesian Systems & Advanced Stats (Phases 22-23) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.5-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.6 Advanced Geoms & API Polish (Phases 24-26) — SHIPPED 2026-04-04</summary>

See .planning/milestones/v1.6-ROADMAP.md for full details.

</details>

### 🚧 v1.7 Choropleth Map Research (In Progress)

**Milestone Goal:** Investigate how gg2d3 can support choropleth map rendering via `geom_sf()` and produce a clear implementation blueprint for a future build milestone. This is a research milestone — deliverables are investigation documents, prototype scripts, and design findings, not production code.

- [ ] **Phase 27: R IR Extraction Feasibility** - Verify and prototype the R-side geometry extraction pipeline for geom_sf layers
- [ ] **Phase 28: D3 Renderer Prototyping** - Prototype basic polygon rendering via d3.geoPath and validate the visual output
- [ ] **Phase 29: Interactivity Design** - Document and evaluate the interactivity extension strategy for map regions
- [ ] **Phase 30: Edge Cases and Blueprint** - Investigate complex scenarios and produce the implementation blueprint

## Phase Details

### Phase 27: R IR Extraction Feasibility
**Goal**: The R-side extraction path for geom_sf layers is empirically verified and prototyped — we know exactly what ggplot_build() yields for sf layers, how to normalize CRS, how to serialize geometries to GeoJSON, and what IR schema extensions are required
**Depends on**: Nothing (first phase of milestone)
**Requirements**: FEAS-01, FEAS-02, FEAS-03, FEAS-04
**Success Criteria** (what must be TRUE):
  1. A researcher can run a single R script and confirm whether `ggplot_build()` preserves the `sfc` geometry list-column for a `geom_sf` layer (FEAS-01 resolved with empirical evidence, not assumption)
  2. A prototype R function produces a character vector of valid GeoJSON strings from an `sfc` column via `geojsonsf::sfc_geojson()`, verified against at least one real shapefile (e.g., the NC dataset bundled with sf)
  3. A researcher can confirm that `sf::st_transform(geom_col, 4326)` successfully normalizes at least two common projected CRS inputs (e.g., EPSG:3857, EPSG:32618) to WGS84 without error
  4. A written IR schema document specifies the new fields for sf layers (`geometries[]`, `crs`, `geom_type`, `coord.type`, `coord.bbox`) with example JSON showing their structure
**Plans:** 1/2 plans executed
Plans:
- [x] 27-01-PLAN.md — sf geometry utility functions (sf_utils.R) with tests and DESCRIPTION update
- [ ] 27-02-PLAN.md — GeomSf/CoordSf integration into as_d3_ir pipeline, validator update, IR schema document

### Phase 28: D3 Renderer Prototyping
**Goal**: A working prototype JavaScript snippet (or standalone HTML file) renders GeoJSON polygon data from the Phase 27 IR using `d3.geoIdentity().reflectY(true).fitExtent()`, correctly filling regions by aesthetic value and handling multipolygons with holes
**Depends on**: Phase 27
**Requirements**: REND-01, REND-02, REND-03
**Success Criteria** (what must be TRUE):
  1. A standalone HTML prototype renders the NC counties shapefile as a filled choropleth using `d3.geoPath()` and `geoIdentity().reflectY(true).fitExtent()`, with region shapes visually matching ggplot2's `geom_sf` output
  2. A researcher can visually confirm that MULTIPOLYGON features with interior rings (holes) render with transparent holes rather than filled interiors, confirming `fill-rule="evenodd"` resolves the winding order issue
  3. Fill color and stroke color values passed through the IR (as resolved hex strings) appear correctly on each `<path>` element in the rendered output, matching the per-row aesthetic data
**Plans**: TBD

### Phase 29: Interactivity Design
**Goal**: The interactivity extension strategy for geom_sf map regions is fully documented with enough specificity that a future build phase can implement each capability without additional design decisions
**Depends on**: Phase 28
**Requirements**: INTR-01, INTR-02, INTR-03
**Success Criteria** (what must be TRUE):
  1. A written document describes exactly how to extend `d3_tooltip()` and `d3_hover()` to include `path.geom-sf` selectors, including which data attributes must be present on each `<path>` element and how tooltip content maps to region aesthetics
  2. A written comparison of centroid-based brush selection vs. polygon hit-testing for sf regions exists, with a clear recommendation and rationale (including why the other approach was rejected), sufficient for a developer to implement without revisiting the decision
  3. A written decision on zoom architecture for sf panels exists — either a concrete implementation approach (e.g., SVG group transform with documented stroke-width tradeoff) or an explicit deferral with rationale — leaving no ambiguity for the build phase
**Plans**: TBD

### Phase 30: Edge Cases and Blueprint
**Goal**: A complete, actionable implementation blueprint exists that documents complex real-world scenarios, explicit anti-features, and a phase-by-phase build plan with concrete file changes — ready to hand directly to a build milestone
**Depends on**: Phase 29
**Requirements**: BLPR-01, BLPR-02, BLPR-03
**Success Criteria** (what must be TRUE):
  1. A written document covers at minimum three edge cases — mixed geometry types in a single layer, multiple stacked geom_sf layers, and faceted sf maps — with specific findings on how each interacts with the existing pipeline and what handling is required
  2. A written anti-features list exists with at least three explicitly deferred capabilities (e.g., tile basemaps, JS-side projection, slippy zoom), each with a rationale sentence explaining why it is out of scope
  3. A phase-by-phase implementation plan exists that names specific files to create or modify, describes the concrete changes in each file, and is sequenced to match the existing gg2d3 phase/plan conventions — sufficient for `/gsd:plan-phase` to execute without requiring new research
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 27 → 28 → 29 → 30

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 27. R IR Extraction Feasibility | v1.7 | 1/2 | In Progress|  |
| 28. D3 Renderer Prototyping | v1.7 | 0/? | Not started | - |
| 29. Interactivity Design | v1.7 | 0/? | Not started | - |
| 30. Edge Cases and Blueprint | v1.7 | 0/? | Not started | - |

---
*Roadmap updated: 2026-04-04*
