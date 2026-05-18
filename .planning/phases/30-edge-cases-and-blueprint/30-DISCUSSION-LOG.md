# Phase 30: Edge Cases and Blueprint - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-18
**Phase:** 30-edge-cases-and-blueprint
**Areas discussed:** Edge case investigation depth, Faceted sf scope, Anti-features list scope, Build plan granularity + doc structure

---

## Gray Area Selection

| Option | Selected |
|--------|----------|
| Edge case investigation depth | ✓ |
| Faceted sf scope | ✓ |
| Anti-features list scope | ✓ |
| Build plan granularity + doc structure | ✓ |

**User's choice:** All four areas.

---

## Edge case investigation depth

### Q1: How should the 3 edge cases be investigated?

| Option | Description | Selected |
|--------|-------------|----------|
| Empirical scripts per case (Recommended) | One R script per edge case; build ggplot, run as_d3_ir, inspect IR; matches Phase 27/28 pattern. | ✓ |
| Desk research only | Reason from code + docs; faster but risks missing IR-shape surprises. | |
| Hybrid — script only for faceted sf | Mixed-geom and multi-layer reasoned from code; faceted prototyped. | |

### Q2: Where do prototype scripts live and what's their lifecycle?

| Option | Description | Selected |
|--------|-------------|----------|
| test_output/ scratch + findings into blueprint (Recommended) | Scripts run from gitignored test_output/; not committed; findings folded into 30-01-BLUEPRINT.md. | ✓ |
| Commit scripts under .planning/phases/30-.../ | Scripts committed for rerun/audit. | |
| tests/testthat/ as exploratory test files | Each edge case framed as documenting/regression test. | |

---

## Faceted sf scope

### Q1: Which bbox strategy?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-panel coord.bbox (Recommended) | Per-panel bbox from panel-subset features; matches free-scale facet semantics. | ✓ |
| Shared bbox across all panels | Single global bbox; visually comparable but shrinks subsets. | |
| Mirror ggplot2's scales argument | Honor facet_wrap(scales=); more work but matches ggplot2 expectations. | |

### Q2: How much faceted-sf detail in the blueprint?

| Option | Description | Selected |
|--------|-------------|----------|
| Document bbox decision + flag known unknowns (Recommended) | Lock bbox, flag strips/axes/xlim/scales as build items. | ✓ |
| Full design — every faceted-sf decision locked | Risk of scope creep. | |
| Minimal — one paragraph noting it works via facets engine | Lowest investment, highest risk of build-phase surprise. | |

---

## Anti-features list scope

### Q1: Which items appear in the anti-features list?

| Option | Description | Selected |
|--------|-------------|----------|
| Tile basemaps (charter) | Slippy-tile basemaps. | ✓ |
| JS-side reprojection (charter) | Projection logic in D3. | ✓ |
| Slippy zoom / Leaflet-style pan (charter) | True slippy-map semantics. | ✓ |
| Phase 27-29 surfaced extras | Centroid-fallback brush, semantic zoom, GeomPolygon orphan, multi-CRS-per-layer. | |

**Notes:** Phase 27-29 surfaced extras stay in Deferred Ideas in CONTEXT.md rather than the anti-features list — distinguishing "not now" from "out of scope forever".

---

## Build plan granularity + doc structure

### Q1: How granular is the impl-plan section?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase + plan + file + concrete change (Recommended) | File/line-anchored, matches Phase 29 precedent; /gsd-plan-phase runs without re-research. | ✓ |
| Phase + plan outline only | Lighter; defers file specifics to plan-phase. | |
| Phase only | Just build phases with a goal sentence. | |

### Q2: How is the blueprint structured as files?

| Option | Description | Selected |
|--------|-------------|----------|
| Single combined 30-01-BLUEPRINT.md (Recommended) | One file covers BLPR-01/02/03; matches Phase 29 precedent. | ✓ |
| Split into 3 files (one per BLPR requirement) | Parallel-friendly; more cross-referencing overhead. | |
| Combined doc + separate impl-plan | Two-file split; impl-plan standalone for build milestone. | |

---

## Claude's Discretion

- Section ordering inside 30-01-BLUEPRINT.md
- Presence/format of ASCII diagrams or example IR JSON snippets
- Prototype-script invocation details (R version, exact filenames per case)
- Naming convention for future build phases (e.g., IMPL-04 vs Phase 32) — planner aligns with v1.8 milestone framing

## Deferred Ideas

- Centroid-first + bbox-fallback brush (carried from Phase 29)
- Semantic zoom for choropleth (carried from Phase 29)
- facet_wrap(scales=) mirroring for faceted sf (new)
- Faceted-sf flagged unknowns (panel strips, axis suppression, coord_sf xlim/ylim per-panel)
- GeomPolygon orphan resurrection (CLAUDE.md tech debt)
- Multi-CRS-per-layer (new)
