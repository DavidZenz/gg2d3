# Phase 30: Edge Cases and Blueprint - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 30 produces **one combined written blueprint document** (`30-01-BLUEPRINT.md`) that hands off to a future build milestone (IMPL-04+). The blueprint covers:

- **BLPR-01:** Edge case findings (mixed geometry types, multi-layer stacking, faceted sf maps)
- **BLPR-02:** Anti-features list with rationale
- **BLPR-03:** Phase-by-phase implementation plan with concrete file changes

**In scope:** investigation, decision-locking, and documentation detailed enough that `/gsd-plan-phase` can execute the future build milestone without doing new research. Empirical R prototype scripts for the three edge cases are in scope as evidence-gathering.

**Out of scope:** any production R/JS code for sf rendering or interactivity. Implementation lands in the build milestone (per v1.7 charter — this milestone is research-only).

</domain>

<decisions>
## Implementation Decisions

### Edge case investigation method (BLPR-01)

- **D-01:** Each of the three edge cases (mixed geometry types in a single layer, multiple stacked geom_sf layers, faceted sf maps) is investigated with an **empirical R prototype script** that builds a representative ggplot, runs `as_d3_ir()`, and inspects the resulting IR. Matches the Phase 27/28 evidence-over-assumption pattern; cheap insurance against IR-shape surprises that only surface when `ggplot_build()` sees these inputs.
- **D-02:** Prototype scripts run from `test_output/` (project-gitignored per CLAUDE.md memory) and produce IR JSON dumps for inspection. The scripts themselves are **not committed**. Their findings — the actual IR shape, any errors, and what the pipeline does or fails to do — are summarized into `30-01-BLUEPRINT.md` as the durable record. Output dumps may be referenced inline in the blueprint where they illustrate a finding.

### Faceted sf scope (BLPR-01)

- **D-03:** The blueprint specifies **per-panel `coord.bbox`** for faceted sf — each panel computes its own bbox from its panel-subset features, then `d3.geoIdentity().reflectY(true).fitExtent()` runs per panel. Consistent with the Phase 27 decision to put bbox on `coord` (not layer) and matches ggplot2's free-scale facet semantics by default. Shared-bbox and ggplot2-`scales`-mirroring approaches were considered and rejected for v1.7 scope.
- **D-04:** Faceted-sf coverage in the blueprint locks the bbox decision (D-03) and **flags known unknowns** as build-phase items rather than resolving them now. Flagged unknowns to enumerate in the blueprint:
  - Panel strip rendering interaction with sf panels (do strips render normally on a map?)
  - Axis suppression — sf panels typically suppress axes; does the facets engine honor that per-panel?
  - Interaction with `coord_sf(xlim=, ylim=)` per panel
  - Free-vs-fixed scales behavior — currently per-panel = "free-like"; mirroring `facet_wrap(scales=)` is a follow-up
  This keeps Phase 30 scope honest: lock what is decidable from desk + prototype, flag the rest for build-phase verification.

### Anti-features list (BLPR-02)

- **D-05:** The anti-features section locks exactly the **three charter-named items**, each with a rationale sentence:
  1. **Tile basemaps** (slippy-tile basemaps rendered under sf layers) — out of scope; gg2d3 renders ggplot output, and basemap composition is a separate authoring concern.
  2. **JS-side reprojection** — Phase 27 locked R-side `sf::st_transform` to WGS84 before serialization; any projection logic in D3 stays out of scope to preserve the single-source-of-truth contract.
  3. **Slippy zoom / Leaflet-style pan** (tile loading at zoom levels) — distinct from the Phase 29 SVG group-transform zoom; out of scope to keep gg2d3's zoom uniform across geom types.
- **D-06:** Items surfaced during Phase 27–29 (centroid-fallback brush, semantic zoom, GeomPolygon orphan resurrection, multi-CRS-per-layer) are **not** added to the anti-features list. They remain in the Deferred Ideas section below where they were already captured — distinguishable from "explicitly out of scope forever" anti-features.

### Build plan granularity (BLPR-03)

- **D-07:** The implementation-plan section is structured at **phase + plan + file + concrete change** granularity. Each future build phase lists its plans; each plan names the files to touch and the concrete change (example level of specificity: "`brush.js` line 27 `INTERACTIVE_SELECTORS` — add `'path.geom-sf'`"). Matches the file/line specificity Phase 29's design doc reached for `sf.js`/`brush.js`/`zoom.js`. The downstream `/gsd-plan-phase` for the build milestone executes from this without re-deriving the spec.

### Document structure

- **D-08:** Single combined deliverable: `30-01-BLUEPRINT.md` covers BLPR-01 (edge cases), BLPR-02 (anti-features), and BLPR-03 (impl plan) in one file. Matches the Phase 29 precedent (`29-01-SF-INTERACTIVITY-DESIGN.md` covered INTR-01/02/03 in one doc). Single plan: `30-01-PLAN.md`.

### Claude's Discretion

- Exact section ordering inside `30-01-BLUEPRINT.md`, presence of ASCII diagrams or example IR JSON snippets, and prototype-script invocation details (R version, working directory, exact filename per case) are planner/executor discretion.
- The specific naming of future build phases listed in the implementation plan (e.g., "IMPL-04: sf rendering core" vs. "Phase 32: sf path emission") — planner decides naming convention aligned with v1.8 milestone framing when proposed.

### Folded Todos

None — no pending todos in `.planning/todos/pending/`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 30 charter
- `.planning/ROADMAP.md` § "Phase 30: Edge Cases and Blueprint" — goal, success criteria, BLPR-01/02/03 mapping
- `.planning/REQUIREMENTS.md` — BLPR-01, BLPR-02, BLPR-03 requirement statements

### Upstream research (entire v1.7 milestone chain)
- `.planning/phases/27-r-ir-extraction-feasibility/27-CONTEXT.md` — locks: sf + geojsonsf in Suggests only, `sf::st_transform` to WGS84 on R side, sf IR schema fields
- `.planning/phases/27-r-ir-extraction-feasibility/27-02-SUMMARY.md` — final sf IR schema: `geometries[]`, `crs`, `geom_type`, `coord.type`, `coord.bbox`; sf panels use NULL x_range/y_range with bbox on coord
- `.planning/phases/28-d3-renderer-prototyping/28-CONTEXT.md` — locks: `d3.geoIdentity().reflectY(true).fitExtent()` projection, no JS reprojection
- `.planning/phases/28-d3-renderer-prototyping/28-01-SUMMARY.md` — `sf.js` renderer module shape; `row_id` available; D-02 (Phase 29) renames to `data-row-id`
- `.planning/phases/28-d3-renderer-prototyping/28-02-SUMMARY.md` — visual verification of REND-01/02/03 (multipolygon fill-rule=evenodd, fill/stroke per-row)
- `.planning/phases/29-interactivity-design/29-CONTEXT.md` — D-01..D-11 lock the sf interactivity surface
- `.planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md` — the design-doc shape and depth that `30-01-BLUEPRINT.md` should match (file/line-anchored change specificity)

### Integration surface (files the build milestone will touch — same set surfaced in Phase 29)
- `R/as_d3_ir.R` — sf branch lives here; mixed-geometry / multi-layer behavior is decided by how this function's per-layer dispatch handles the sf case
- `inst/htmlwidgets/modules/geoms/sf.js` — Phase 28 renderer; build phase adds `data-row-id`, `data-centroid`, `vector-effect="non-scaling-stroke"` per Phase 29 D-01..D-04, D-09
- `inst/htmlwidgets/modules/brush.js` `INTERACTIVE_SELECTORS` (line 27ff) — sf brush participation per Phase 29 D-05
- `inst/htmlwidgets/modules/tooltip.js` — selector dispatch table; sf joins per Phase 29 D-03
- `inst/htmlwidgets/modules/hover.js` — same registry pattern as tooltip
- `inst/htmlwidgets/modules/zoom.js` — branch on sf-present per Phase 29 D-08, D-10, D-11; route transform to `.sf-zoom-layer` group
- `inst/htmlwidgets/modules/events.js` — cross-module coordination protocol (`data-brush-active`)

### Project conventions (CLAUDE.md + memory)
- `CLAUDE.md` — three-layer pipeline (R → IR → D3), package conventions
- `MEMORY.md` entries (auto-loaded): visual test output to `test_output/` (justifies D-02 scratch location); pixel-position highlighting; DOM-attribute cross-module coordination; zoom event isolation via `zoom.filter()`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Phase 27 sf branch in `R/as_d3_ir.R`** — already handles single-layer single-geom-type sf. Edge case prototypes invoke this directly; findings document how it behaves under mixed-geometry and multi-layer inputs without modification.
- **Phase 28 `sf.js` renderer** — single-layer rendering path is in place. Multi-layer stacking edge case becomes a question of "what does the existing layer loop do when two layers are both sf?" — empirically answerable via prototype.
- **Existing facets layout engine** — handles per-panel rendering for all current geoms. Faceted-sf prototype tests whether routing sf panels through this engine "just works" given per-panel `coord.bbox`.
- **Phase 29 design doc shape** (`29-01-SF-INTERACTIVITY-DESIGN.md`) — concrete template for the depth/specificity `30-01-BLUEPRINT.md` should reach in its impl-plan section.

### Established Patterns
- **Empirical-script-driven research** — Phases 27 and 28 both ran small R scripts to validate behavior before locking decisions. D-01 continues this pattern.
- **`test_output/` for gitignored scratch** — established in MEMORY.md, used by all visual verification. D-02 reuses.
- **Combined design doc per phase** — Phase 29 shipped one doc for INTR-01/02/03. D-08 mirrors for BLPR-01/02/03.
- **File/line-anchored impl callouts** — Phase 29's design doc cites `brush.js` line 27 etc. D-07 commits to the same granularity.

### Integration Points
- The blueprint's impl-plan section is the integration point between v1.7 research and the future build milestone — every file the build phase will touch is named here.
- Per-panel `coord.bbox` (D-03) integrates with the existing facets engine via the same `coord` field Phase 27 added; no new coordinate-handling code is required at the layout level.

</code_context>

<specifics>
## Specific Ideas

- **Prototype script subjects** to use as concrete edge-case fixtures (planner discretion to refine):
  - Mixed geometry: an `sf` data frame with both POLYGON and POINT features in one layer, or POLYGON + LINESTRING.
  - Multi-layer stacking: NC counties (POLYGON fill) + a state-boundary overlay (POLYGON stroke-only or LINESTRING) in the same plot.
  - Faceted sf: NC counties facetted by a categorical column (e.g., a synthetic region grouping), one panel per group.
- **Per-panel `coord.bbox`** implementation hint for the impl-plan section: the bbox computation already exists in the R-side sf branch (Phase 27); for facets it must run per panel-subset rather than once globally. This is a small change scoped in the build phase.
- **Anti-features rationale style** — short and quotable: "X is out of scope because Y" in one sentence each. Phase 30's anti-features section is consumed by future contributors who need to know "is this on the roadmap or off forever" without reading the whole blueprint.

</specifics>

<deferred>
## Deferred Ideas

(Carried from Phase 29 + new this phase. These are NOT anti-features per D-06 — they are "not now, possibly later" items kept in the project memory so future milestones can pick them up.)

- **Centroid-first + bbox-fallback brush** (carried from Phase 29) — revisit if users surface the "large region not selected" limitation.
- **Semantic zoom for choropleth** (carried from Phase 29) — its own milestone.
- **`facet_wrap(scales=)` mirroring for faceted sf** (new) — per D-04, the blueprint locks per-panel bbox but does not honor ggplot2's `scales` argument for sf facets. Logged here so a future polish phase can add it.
- **Faceted-sf flagged unknowns** (new) — panel strips, axis suppression, `coord_sf(xlim=, ylim=)` per-panel interaction. Each becomes a build-phase verification task; not blockers for the blueprint.
- **GeomPolygon orphan resurrection** (carried from CLAUDE.md tech debt) — separate cleanup, unrelated to sf scope.
- **Multi-CRS-per-layer** (new) — one layer containing geometries with mixed source CRSs. Phase 27 normalizes per-layer; the multi-CRS-within-layer case is unusual and out of v1.7. Logged for future awareness.

</deferred>

---

*Phase: 30-edge-cases-and-blueprint*
*Context gathered: 2026-05-18*
