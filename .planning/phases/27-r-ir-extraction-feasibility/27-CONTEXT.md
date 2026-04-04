# Phase 27: R IR Extraction Feasibility - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Empirically verify and prototype the R-side geometry extraction pipeline for geom_sf layers. Deliverables: working `R/sf_utils.R` functions (behind `requireNamespace()` guards), documented IR schema extension with annotated example JSON, and feasibility findings across multiple test datasets. This is the feasibility gate for the entire v1.7 milestone — if geometry extraction fails, investigate alternatives deeply.

</domain>

<decisions>
## Implementation Decisions

### Prototype format
- **D-01:** Produce real in-package functions in `R/sf_utils.R`, not throwaway scripts. Functions include `extract_sf_geometries()`, `normalize_to_wgs84()`, `detect_dominant_geom_type()`, `get_layer_crs()` — all behind `requireNamespace("sf")` guards.
- **D-02:** Modify `R/as_d3_ir.R` to add `GeomSf` dispatch and `CoordSf` detection branch, following the existing `CoordFlip`/`CoordPolar` pattern at line 636-639.
- **D-03:** Add `sf` and `geojsonsf` to `Suggests` in DESCRIPTION (not Imports — avoid forcing GDAL/GEOS/PROJ on all users).

### Fallback depth
- **D-04:** If `ggplot_build()` strips the `sfc` geometry column, investigate multiple fallback paths deeply: pre-build extraction from `p$layers[[i]]$data`, patching ggplot_build output, `stat_sf_coordinates`, and processing sf outside ggplot entirely. Document each path's viability and tradeoffs.
- **D-05:** Do not abandon the milestone on first failure — exhaustive investigation of alternatives is required before declaring infeasibility.

### Test data scope
- **D-06:** Test against three datasets: (1) NC shapefile bundled with `sf` (baseline, simple polygons, WGS84), (2) world borders via `rnaturalearth` (complex multipolygons with holes/islands), (3) projected CRS data (at least EPSG:3857 or state-plane) to verify `st_transform` normalization.
- **D-07:** Skip US county-level performance testing (3000+ features) — performance is Phase 28+ concern.

### IR schema formality
- **D-08:** Document the IR schema extension as annotated example JSON output from a real sf plot, consistent with how the existing IR is documented (by example, not formal JSON Schema).
- **D-09:** Annotated JSON must show all new fields: `layer.geometries[]`, `layer.crs`, `layer.geom_type`, `coord.type = "sf"`, `coord.bbox`.

### Carried from research
- **D-10:** Use `geojsonsf::sfc_geojson()` for serialization (not `jsonlite::toJSON` which wraps in FeatureCollection).
- **D-11:** CRS normalization to WGS84 (EPSG:4326) via `sf::st_transform()` is mandatory and unconditional.
- **D-12:** Geometry column name must be detected dynamically via `attr(data, "sf_column")` with fallback to `names(data)[sapply(data, inherits, "sfc")][1]` — never hardcode `"geometry"`.

### Claude's Discretion
- Internal function signatures and argument naming in `sf_utils.R`
- Whether to add payload size warnings for large geometry sets in this phase or defer to Phase 30
- Exact error messages for missing sf/geojsonsf packages

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing pipeline (understand before modifying)
- `R/as_d3_ir.R` — Current IR extraction logic; `keep_aes` whitelist (line 21), `to_rows()` serialization (line 28), coord detection (line 636-639), geom dispatch
- `R/gg2d3.R` — Widget entry point that calls `as_d3_ir()`
- `.planning/codebase/ARCHITECTURE.md` — Three-layer pipeline documentation

### Research findings
- `.planning/research/SUMMARY.md` — Synthesized research; architecture approach, pitfalls, phase structure
- `.planning/research/STACK.md` — sf/geojsonsf/d3-geo version details and integration notes
- `.planning/research/ARCHITECTURE.md` — Detailed data flow for sf layers through the pipeline
- `.planning/research/PITFALLS.md` — 8 critical pitfalls with prevention strategies (5 apply to Phase 27)

### Requirements
- `.planning/REQUIREMENTS.md` — FEAS-01 through FEAS-04 define Phase 27 scope

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `as_d3_ir.R:keep_aes` (line 21): Whitelist of aesthetic columns to preserve — sf layers need `geometry` excluded from this and handled separately
- `as_d3_ir.R:to_rows()` (line 28): Row-wise serialization — cannot handle `sfc` list-columns; sf layers need geometry extracted before this function runs
- `as_d3_ir.R:636-639`: Coord type detection pattern (`CoordFlip`, `CoordFixed`, `CoordPolar`) — `CoordSf` follows this exact pattern

### Established Patterns
- **Coord branching:** `inherits(b$plot$coordinates, "CoordXxx")` checks at line 636-639 — add `CoordSf` here
- **Geom dispatch:** `geom_name` extraction and switch-based handling in layer processing — add `"sf"` case
- **Optional dependency:** `requireNamespace()` pattern for conditional features — use for sf/geojsonsf
- **Polar metadata:** `polar_meta` extraction at line 645-647 — similar pattern for sf metadata (bbox, crs)

### Integration Points
- `as_d3_ir.R` layer processing loop: Where each layer's data is extracted, filtered by `keep_aes`, and converted via `to_rows()` — sf layers need a branch before `keep_aes` filtering to extract geometry
- `DESCRIPTION Suggests:` field: Where `sf` and `geojsonsf` get added
- `inst/htmlwidgets/gg2d3.js renderValue()`: Will consume the new IR fields in Phase 28 (not this phase)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The research phase produced clear technical direction; this phase executes that direction as real code.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 27-r-ir-extraction-feasibility*
*Context gathered: 2026-04-04*
