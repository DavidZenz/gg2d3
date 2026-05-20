# Phase 32: geom_sf IR Foundation - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 32 delivers the R-side `geom_sf` IR foundation only. It hardens extraction, polygon-family gating, CRS normalization behavior, bbox/projection metadata, row/geometry alignment, validation, and tests for `POLYGON` and `MULTIPOLYGON` sf layers. D3 rendering, tooltip/hover/brush wiring, zoom suppression behavior, stacked sf projection alignment, and faceted sf maps are later phases.

</domain>

<decisions>
## Implementation Decisions

### Unsupported Geometries
- **D-01:** Unsupported sf geometries should warn and skip predictably rather than failing the whole layer.
- **D-02:** Valid `POLYGON` and `MULTIPOLYGON` rows must remain usable when unsupported rows are present.
- **D-03:** `row_id`, `data`, and `geometries` must stay parallel after filtering so downstream renderer and interactivity code can safely join geometry and aesthetics.

### Missing CRS
- **D-04:** Missing CRS should warn and serialize as-is for now, treating coordinates as already usable in the existing SVG/htmlwidgets renderer.
- **D-05:** Known CRS inputs must continue to normalize to WGS84 in R before GeoJSON serialization.
- **D-06:** JavaScript-side reprojection remains out of scope for this phase and this milestone.

### IR Metadata Shape
- **D-07:** Phase 32 should emit the existing bbox needed by the current sf renderer plus explicit sf diagnostics that describe accepted/skipped geometry rows and CRS handling.
- **D-08:** Rich per-panel projection metadata for stacked and faceted sf maps is deferred to Phase 34, though Phase 32 should avoid shaping IR in a way that blocks it.
- **D-09:** Minimal `coord$bbox` alone is not enough for production hardening because downstream planning needs visibility into unsupported geometry and CRS outcomes.

### Production Hardening
- **D-10:** Treat the v1.7 prototype as the base and harden it in place rather than redesigning the sf IR shape.
- **D-11:** Preserve the established `GeomSf` branch in `R/as_d3_ir.R`, `R/sf_utils.R` helper boundary, and existing test files unless planning finds a narrow extraction helper that reduces risk.

### the agent's Discretion
- The planner may choose exact helper names and internal return structures for sf diagnostics.
- The planner may decide whether unsupported geometry filtering lives in `R/sf_utils.R`, `R/as_d3_ir.R`, or a small shared helper, as long as the public behavior above holds.
- The planner may choose exact warning text, but it must be testable and user-facing enough to explain skipped geometry and missing CRS behavior.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope
- `.planning/ROADMAP.md` — Defines Phase 32 goal, requirements, success criteria, and phase boundaries.
- `.planning/REQUIREMENTS.md` — Defines SFIR-01, SFIR-02, and SFIR-03.
- `.planning/milestones/v1.7-ROADMAP.md` — Archived v1.7 research milestone context.
- `.planning/milestones/v1.7-REQUIREMENTS.md` — Archived sf research requirements and traceability.
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — Confirms the research handoff passed and notes non-blocking validation-process caveat.

### Phase 32 Source Material
- `.planning/PROJECT.md` — Project-level decisions for `geojsonsf`, WGS84 normalization, `geoIdentity`, centroid brushing, zoom suppression, and polygon-first `geom_sf`.
- `.planning/ROADMAP.md` — Phase 32 plus downstream Phase 33-35 boundaries.
- `.planning/REQUIREMENTS.md` — Current v1.8 SFIR requirements and explicit out-of-scope map behavior.

### Note on Archived Phase Artifacts
- The previous `.planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` handoff was consumed into `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and the v1.7 milestone archive before phase directories were cleared. Downstream agents should rely on the canonical files above rather than stale phase-directory paths.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/sf_utils.R`: Existing sf helper boundary with `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, and `get_layer_crs()`.
- `R/as_d3_ir.R`: Existing `GeomSf` branch already normalizes geometry, serializes GeoJSON, emits `row_id`, stores CRS metadata, and computes `coord$bbox`.
- `R/validate_ir.R`: Existing IR validation entry point; Phase 32 should extend or preserve sf validation semantics.
- `tests/testthat/test-sf-ir.R`: Existing happy-path sf IR tests for NC polygons, bbox, CRS normalization, aesthetic passthrough, and data/geometry parallelism.
- `tests/testthat/test-sf-utils.R`: Existing sf helper tests using real `sf` fixtures.
- `tests/testthat/test-sf-renderer.R`: Existing row alignment tests that can be expanded if Phase 32 changes row filtering behavior.

### Established Patterns
- Optional spatial dependencies are guarded with `skip_if_not_installed("sf")` and `skip_if_not_installed("geojsonsf")` in tests.
- The package uses real ggplot2 builds and real sf fixtures rather than mocks for IR tests.
- gg2d3's architecture is R → JSON IR → D3; Phase 32 should keep CRS work in R and keep the browser renderer free of reprojection logic.
- Existing code maps ggplot geom classes to string geoms in `R/as_d3_ir.R`; `GeomSf` already maps to `"sf"`.

### Integration Points
- `R/as_d3_ir.R` is where sf layer extraction joins aesthetics, geometry, CRS metadata, and row IDs.
- `R/sf_utils.R` is the natural place for geometry-column detection, CRS normalization, polygon-family detection, and serialization helpers.
- `tests/testthat/test-sf-ir.R` should become the main proof that SFIR-01, SFIR-02, and SFIR-03 are satisfied.
- `DESCRIPTION` already lists `sf` and `geojsonsf` as optional dependencies, so Phase 32 should preserve optional dependency behavior.

</code_context>

<specifics>
## Specific Ideas

- The current prototype should be hardened, not replaced.
- Unsupported geometry handling should prefer useful partial output over all-or-nothing failure.
- Missing CRS should be visible to users via warnings, but not block plots whose coordinates are already usable.
- Diagnostics should make future renderer phases easier without prematurely implementing stacked/faceted projection semantics.

</specifics>

<deferred>
## Deferred Ideas

- D3 path rendering and `path.geom-sf` behavior — Phase 33.
- Tooltip, hover, centroid brush, and zoom suppression wiring — Phase 33.
- Shared projection alignment for stacked sf layers — Phase 34.
- Per-panel bbox/projection behavior for faceted sf maps — Phase 34.
- Package-facing sf docs, diagnostics vignette updates, README status, and browser visual validation package — Phase 35.
- Non-polygon sf rendering, tile basemaps, slippy map controls, JavaScript-side CRS reprojection, polygon-overlap brushing, and large-map performance guarantees remain outside v1.8 scope.

</deferred>

---

*Phase: 32-geom-sf-ir-foundation*
*Context gathered: 2026-05-20*
