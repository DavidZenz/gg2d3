# Phase 32: geom_sf IR Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 32-geom_sf IR Foundation
**Areas discussed:** Unsupported geometries, Missing CRS, IR metadata shape, Production hardening stance

---

## Unsupported Geometries

| Option | Description | Selected |
|--------|-------------|----------|
| Warn and skip | Warn-and-skip unsupported rows, keep valid polygon rows and stable `row_id`. | ✓ |
| Fail layer | Fail the whole sf layer if any unsupported geometry appears. | |
| Preserve placeholders | Preserve placeholder rows for unsupported geometries, but render nothing. | |

**User's choice:** Recommendations are fine.
**Notes:** Recommended behavior selected to preserve useful polygon output while making unsupported rows visible and testable.

---

## Missing CRS

| Option | Description | Selected |
|--------|-------------|----------|
| Warn and serialize | Warn and serialize as-is, treating coordinates as already usable. | ✓ |
| Error | Error unless CRS is known. | |
| Silent serialize | Silently serialize as-is. | |

**User's choice:** Recommendations are fine.
**Notes:** Recommended behavior selected because JavaScript-side reprojection is out of scope and some already-usable coordinate data may arrive without CRS metadata.

---

## IR Metadata Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Bbox plus diagnostics | Emit bbox plus explicit sf diagnostics now; defer richer per-panel projection metadata to Phase 34. | ✓ |
| Minimal bbox | Emit only the minimal `coord$bbox`. | |
| Future-ready panel metadata | Build richer per-panel metadata now in Phase 32. | |

**User's choice:** Recommendations are fine.
**Notes:** Recommended behavior selected to make Phase 32 production-hardened without absorbing Phase 34 stacked/faceted projection scope.

---

## Production Hardening Stance

| Option | Description | Selected |
|--------|-------------|----------|
| Harden in place | Harden the existing v1.7 prototype in place. | ✓ |
| Redesign IR | Redesign the sf IR shape before implementing. | |
| Experimental path | Keep prototype code but isolate it behind a new experimental path. | |

**User's choice:** Recommendations are fine.
**Notes:** Recommended behavior selected because the prototype already has useful `R/sf_utils.R`, `GeomSf`, CRS, bbox, and row-alignment scaffolding.

---

## the agent's Discretion

- Exact helper names and internal sf diagnostic structure.
- Exact file split between `R/sf_utils.R`, `R/as_d3_ir.R`, and validation helpers.
- Exact warning text, as long as it is clear and testable.

## Deferred Ideas

- Renderer and interactivity behavior belong to Phase 33.
- Stacked and faceted projection alignment belongs to Phase 34.
- Documentation and browser validation packaging belongs to Phase 35.
