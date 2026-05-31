# Phase 54: Geometry Polish Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 54-Geometry Polish Closure
**Areas discussed:** `geom_label()` box behavior, polygon subgroup/hole boundary, transformed rect/tile closure, text placement triage

---

## `geom_label()` Box Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Implement bounded label boxes | Implement ordinary `geom_label()` SVG label boxes with rect + text, fill/colour/alpha/size, and basic padding. | yes |
| Diagnostics only | Keep `geom_label()` mapped to text and strengthen diagnostics only. | |
| Classify first | Classify first, then implement only if fixtures show a small safe path. | |

**User's choice:** recommendations are fine.
**Notes:** The recommended implementation path is selected, with fallback to source-backed diagnostics if research finds the bounded path is not small and safe.

---

## Polygon Subgroup/Hole Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Fixture-led non-goal default | Build focused fixtures and document subgroup/hole topology as an explicit non-goal unless a tiny ggplot-compatible subset is obvious. | yes |
| Attempt support now | Attempt bounded subgroup/hole support now. | |
| Preserve metadata only | Preserve `subgroup` in IR only as future metadata, without rendering holes. | |

**User's choice:** recommendations are fine.
**Notes:** Default to fixture-led classification and explicit non-goal documentation unless research identifies a tiny, low-risk implementation path.

---

## Transformed Rect/Tile Closure

| Option | Description | Selected |
|--------|-------------|----------|
| Strengthen current boundary | Treat current direct transformed-bound scaling as the likely boundary, add stronger fixtures/evidence, fix only confirmed shared scale/render drift. | yes |
| Refactor shared semantics | Actively refactor shared scale/rect semantics now. | |
| Defer entirely | Defer transformed rect/tile entirely with docs. | |

**User's choice:** recommendations are fine.
**Notes:** The phase should strengthen log/sqrt/reverse evidence and shared render/update checks, not reopen a broad rect/tile scale refactor unless tests expose drift.

---

## Text Placement Triage

| Option | Description | Selected |
|--------|-------------|----------|
| Small parity wins | Attempt small parity wins for ordinary text/label `hjust`, `vjust`, and `angle`; explicitly defer collision avoidance and path-following. | yes |
| Documentation only | Only document all text placement limits. | |
| Label boxes only | Prioritize label boxes only; leave text placement unchanged. | |

**User's choice:** recommendations are fine.
**Notes:** Justification and rotation are in scope for bounded attempts. Font family is secondary if it fits naturally. Collision avoidance, rich text, and path-following remain deferred.

---

## The Agent's Discretion

- Split Phase 54 plans by blast radius and validation needs.
- Decide exact tests and source files during research/planning while preserving the selected scope boundaries.
- Use browser visual smoke as downstream confidence rather than the sole gate.

## Deferred Ideas

- Full ggrepel-compatible collision avoidance.
- Path-following text and rich text.
- Broad GIS-style polygon topology repair.
- Pixel thresholds and committed golden screenshots.
