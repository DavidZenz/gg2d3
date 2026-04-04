# Phase 27: R IR Extraction Feasibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 27-r-ir-extraction-feasibility
**Areas discussed:** Prototype format, Fallback depth, Test data scope, IR schema formality

---

## Prototype Format

| Option | Description | Selected |
|--------|-------------|----------|
| In-package functions (Recommended) | Write actual R/sf_utils.R with extract_sf_geometries(), etc. behind requireNamespace() guards. Phase 28+ builds on real code. | ✓ |
| Standalone R scripts | Scripts in test_output/ or .planning/ that exercise the extraction pipeline. Disposable — rewritten when building for real. | |
| Findings doc only | Document in .planning/ with code snippets showing what works. No runnable artifacts. | |

**User's choice:** In-package functions
**Notes:** User wants real code from the start so downstream phases build on actual implementation, not throwaway prototypes.

---

## Fallback Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Quick pivot (Recommended) | Document the failure, test one alternative (extract geometry from the original sf layer data before ggplot_build), and assess viability. Stop there. | |
| Deep investigation | Explore multiple fallback paths: pre-build extraction, patching ggplot_build output, using stat_sf_coordinates, or processing sf outside ggplot entirely. | ✓ |
| Stop if it fails | If ggplot_build strips geometry, mark the milestone as infeasible and pivot to a different approach in a new milestone. | |

**User's choice:** Deep investigation
**Notes:** User wants exhaustive investigation of alternatives before declaring infeasibility. Multiple fallback paths should be explored.

---

## Test Data Scope

| Option | Description | Selected |
|--------|-------------|----------|
| NC shapefile (bundled) | Standard sf test fixture — 100 counties, simple polygons, WGS84. Always included. | ✓ |
| US counties (tigris) | ~3200 features, real-world complexity, tests performance. Requires tigris package. | |
| World borders (rnaturalearth) | Complex multipolygons with holes (lakes, islands), tests winding order handling. | ✓ |
| Projected CRS data | Data in EPSG:3857 or state-plane CRS to verify st_transform normalization works. | ✓ |

**User's choice:** NC shapefile, World borders, Projected CRS data (multi-select)
**Notes:** Skip US county-level performance testing — performance is a later concern. Focus on geometry complexity and CRS normalization.

---

## IR Schema Formality

| Option | Description | Selected |
|--------|-------------|----------|
| Annotated example JSON (Recommended) | Produce a real IR output JSON from an sf plot with inline annotations explaining each new field. Consistent with existing IR documentation style. | ✓ |
| Formal JSON Schema | Write a proper JSON Schema (.json) defining the sf layer structure. More rigorous, but no existing schema to extend. | |
| You decide | Claude picks the approach that best serves downstream phases. | |

**User's choice:** Annotated example JSON
**Notes:** Consistent with how the existing IR is documented — by example rather than formal schema.

---

## Claude's Discretion

- Internal function signatures and argument naming in sf_utils.R
- Payload size warning timing (this phase vs Phase 30)
- Exact error messages for missing sf/geojsonsf packages

## Deferred Ideas

None — discussion stayed within phase scope.
