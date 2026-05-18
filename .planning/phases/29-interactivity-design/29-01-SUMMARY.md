---
phase: 29
plan: 01
subsystem: interactivity-design
tags: [design-doc, sf, interactivity, tooltip, brush, zoom, choropleth]
dependency_graph:
  requires:
    - .planning/phases/29-interactivity-design/29-CONTEXT.md
    - .planning/phases/29-interactivity-design/29-RESEARCH.md
    - .planning/phases/29-interactivity-design/29-VALIDATION.md
  provides:
    - design-spec: SF interactivity (INTR-01/02/03) build-phase contract for IMPL-04
  affects:
    - .planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md
    - .planning/phases/29-interactivity-design/verify-design-doc.sh
tech_stack:
  added: []
  patterns:
    - selector-registry-extension (path.geom-sf joins INTERACTIVE_SELECTORS)
    - row-id-lookup-over-attribute-embedding (data-row-id only; no data-fill/data-color)
    - pixel-position-brush-testing (centroid pixel point-in-rect)
    - svg-group-transform-zoom (divergence from element-repositioning)
    - svg-presentation-attribute (vector-effect=non-scaling-stroke, NOT CSS)
key_files:
  created:
    - .planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md
    - .planning/phases/29-interactivity-design/verify-design-doc.sh
  modified: []
decisions:
  - "Option A: canonicalize sf path centroid as single data-centroid=\"x,y\" attribute per D-02; IMPL-04 will rename data-cx/data-cy in inst/htmlwidgets/modules/geoms/sf.js lines 99-104"
  - "Polygon hit-testing explicitly rejected for sf brush; centroid-only per D-05 with three-rationale documentation (memory, compute, UX)"
  - "sf zoom uses SVG group transform on .sf-zoom-layer (D-08); diverges from element-repositioning pattern used by every other geom (D-10)"
  - "vector-effect=non-scaling-stroke specified as SVG presentation attribute, NOT CSS, so it survives htmlwidgets::saveWidget serialization"
  - "Centroid limitation (regions whose centroid lies outside brush rect) documented (D-07); bbox-fallback mitigation explicitly deferred to a later interactivity milestone"
metrics:
  duration_minutes: 2
  completed: 2026-05-18
---

# Phase 29 Plan 01: SF Interactivity Design Summary

**One-liner:** Locked the build-phase contract for `geom_sf` interactivity (tooltip/hover, brush, zoom) in a single combined design document covering all 11 decisions D-01..D-11, with the `data-centroid` vs `data-cx`/`data-cy` inconsistency resolved in favor of `data-centroid` (Option A) and scheduled for rename in IMPL-04.

## What Shipped

1. **`.planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md`** — combined design document. 654 lines. Structure:
   - YAML frontmatter (phase, plan, deliverable, status, implements, build-phase target IMPL-04)
   - Overview
   - **Critical Inconsistency Resolution** — picks Option A (`data-centroid="x,y"`); names IMPL-04 as the migration owner; acknowledges Phase 28's provisional `data-cx`/`data-cy` naming with file:line evidence
   - **INTR-01** (Tooltip and Hover Extension) — D-01, D-02, D-03, D-04
   - **INTR-02** (Brush Selection Algorithm) — D-05, D-06 (with three rationales a/b/c and verbatim comparison matrix), D-07
   - **INTR-03** (Zoom Architecture) — D-08, D-09, D-10 (three reasons element-repositioning cannot be reused), D-11
   - **Build-Phase Implementation Reference (IMPL-04)** — 9-row table mapping each change to file and decision
   - Deferred / Out of Scope
   - Success Rubric

2. **`.planning/phases/29-interactivity-design/verify-design-doc.sh`** — executable bash verifier. 70 lines. Greps for every `### D-NN` heading (D-01..D-11), every `## INTR-0N` top-level section, the Critical Inconsistency resolution, the centroid-vs-polygon comparison matrix, the `vector-effect="non-scaling-stroke"` spec, the "presentation attribute" framing, the `sf-zoom-layer` group class, and the IMPL-04/build-phase reference. Exits 0 with `PASS` when complete; exits 1 with `FAIL` (or 2 with `FATAL` if the doc is missing).

## Verifier State

`bash .planning/phases/29-interactivity-design/verify-design-doc.sh` — **PASS** (exit 0). All 24 grep checks succeed against the produced design doc.

## Critical Inconsistency Resolution (highlighted)

- **What was inconsistent:** CONTEXT.md D-02 specifies single `data-centroid="x,y"`; Phase 28 `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104 emits separate `data-cx` + `data-cy`.
- **What was chosen:** **Option A — `data-centroid="x,y"`** per CONTEXT.md D-02.
- **Why:** matches the locked decision; one attribute read in brush.js (single `getAttribute` + `split(',')`) vs two (two `getAttribute` + two `parseFloat`); simpler to grep for in tests; rename is a contained ~5-line edit in `sf.js` only (no other file currently reads `data-cx`/`data-cy`); `isFinite` guard transfers cleanly.
- **Build-phase migration owner:** **IMPL-04** (v1.8+ milestone). Task: modify `inst/htmlwidgets/modules/geoms/sf.js` lines 99–104 to emit `data-centroid` as a single comma-joined string and drop `data-cx`/`data-cy`.

## Build-Phase Target

All implementation lands in **IMPL-04** (v1.8+ milestone). Phase 29 produced documentation only — no `.js`, `.R`, or test file modified. The design doc's Build-Phase Implementation Reference table is the contract: 9 specific changes mapped to specific files and decisions, so IMPL-04 implements without re-deciding.

## Code/Test Files Modified

**None.** Verified via `git status --porcelain inst/ R/ tests/` after both task commits — output is empty.

## Decisions Made

- **Option A for `data-centroid`** (see Critical Inconsistency Resolution above).
- **Polygon hit-test rejected** for sf brush (D-06) with three durable rationales (memory, compute, UX) and a comparison matrix that future contributors can cite when the question recurs.
- **SVG group transform** chosen for sf zoom (D-08) over the element-repositioning pattern every other geom uses; divergence rationale documented in three points (D-10) so the build phase does not try to retrofit sf into `repositionElements()`.
- **`vector-effect="non-scaling-stroke"` as presentation attribute, not CSS** (D-09), so it survives `htmlwidgets::saveWidget(selfcontained=TRUE)` and pkgdown vignette serialization. The pitfall is explicitly flagged so a future "simplification" PR does not regress it.
- **Centroid limitation documented but mitigation deferred** (D-07) — no speculative bbox-fallback code; revisit only if user surface confirms pain.

## Deviations from Plan

None — plan executed exactly as written. Both tasks landed in single commits with no auto-fix iterations needed. Verifier was authored first and FAILED with `FATAL` (doc missing) as the plan predicted; flipped to `PASS` after Task 2.

## Commits

- `86e9912` chore(29-01): add design-doc verifier script
- `aed4ff2` docs(29-01): write SF interactivity design doc (INTR-01/02/03)

## Self-Check: PASSED

- FOUND: .planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md
- FOUND: .planning/phases/29-interactivity-design/verify-design-doc.sh (executable)
- FOUND commit: 86e9912
- FOUND commit: aed4ff2
- Verifier exits 0 with PASS
- No .js/.R/test files modified
