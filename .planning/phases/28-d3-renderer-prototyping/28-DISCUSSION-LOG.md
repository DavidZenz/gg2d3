# Phase 28: D3 Renderer Prototyping - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 28-d3-renderer-prototyping
**Areas discussed:** Prototype deliverable format, Visual validation approach, Geometry-aesthetic linkage, Fill-rule scope

---

## Prototype Deliverable Format

| Option | Description | Selected |
|--------|-------------|----------|
| Integrated sf.js module (Recommended) | Create inst/htmlwidgets/modules/geoms/sf.js following geomRegistry.register() pattern. Matches Phase 27's real in-package approach. | ✓ |
| Standalone HTML file | Self-contained HTML with inline D3 + hardcoded GeoJSON. Fastest to iterate but disconnected from pipeline. | |
| Both | Integrated module plus standalone HTML test harness. | |

**User's choice:** Integrated sf.js module
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Register normally (Recommended) | Register as 'sf' via geomRegistry.register(). Receives xScale/yScale but ignores them, uses geoPath internally. | ✓ |
| Special branch in gg2d3.js | Add coord.type === 'sf' detection to bypass normal pipeline. | |

**User's choice:** Register normally
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Wire it now (Recommended) | Add sf.js to gg2d3.yaml so it loads with the package. End-to-end testable. | ✓ |
| Defer wiring to Phase 30 | Create sf.js but don't add to yaml. Phase 30 documents integration. | |

**User's choice:** Wire it now
**Notes:** None

---

## Visual Validation Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Visual test HTML output (Recommended) | Generate test HTML files in test_output/ for manual side-by-side comparison. Consistent with prior milestones. | ✓ |
| R-side snapshot comparison | Use vdiffr or similar for PNG comparison. More rigorous but adds infrastructure. | |
| Programmatic SVG checks | Test SVG element count, fill values, bounding box. Structural only. | |

**User's choice:** Visual test HTML output
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| NC counties + world borders (Recommended) | Both datasets for simple polygon baseline and multipolygon hole validation. | ✓ |
| NC counties only | Simpler scope, holes testing deferred. | |
| You decide | Claude picks dataset coverage. | |

**User's choice:** NC counties + world borders
**Notes:** None

---

## Geometry-Aesthetic Linkage

| Option | Description | Selected |
|--------|-------------|----------|
| Index-based 1:1 (Recommended) | geometries[i] corresponds to data[i]. Simple, no extra key infrastructure. | |
| Key-based join | Add row_id field to both arrays and join by key. More robust if row order could diverge. | ✓ |
| Merged into GeoJSON properties | Embed aesthetics into GeoJSON Feature properties. Changes Phase 27 serialization. | |

**User's choice:** Key-based join
**Notes:** User chose explicit row_id over implicit index-based mapping.

| Option | Description | Selected |
|--------|-------------|----------|
| Row index as explicit key | Add numeric row_id to both data[] and geometries[]. Minimal R-side change via seq_along(). | ✓ |
| Feature wrapper with ID | Wrap Geometry in GeoJSON Feature with id property. More standard but larger IR payload. | |
| You decide | Claude picks pragmatic approach. | |

**User's choice:** Row index as explicit key
**Notes:** Effectively index-based but with explicit contract via row_id field.

---

## Fill-Rule Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All sf paths (Recommended) | Apply evenodd universally. No harm on simple polygons, correctly handles holes. Simpler. | ✓ |
| MULTIPOLYGON only | Check geom_type per feature. More precise but needs per-row geometry type info. | |
| You decide | Claude picks based on d3.geoPath behavior. | |

**User's choice:** All sf paths
**Notes:** None

---

## Claude's Discretion

- Internal renderSf() function structure
- CSS class naming for sf path elements
- Error handling for malformed GeoJSON
- fitExtent padding values

## Deferred Ideas

None -- discussion stayed within phase scope.
