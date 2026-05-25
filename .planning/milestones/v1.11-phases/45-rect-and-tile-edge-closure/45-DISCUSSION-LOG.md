# Phase 45: Rect And Tile Edge Closure - Discussion Log

**Discussed:** 2026-05-24
**User selection:** Areas `1-4`; recommendations accepted.
**Outcome:** Ready for `$gsd-plan-phase 45`.

## Area 1: Fixture Matrix

**Question:** Which rect/tile cases should the reproduction matrix cover?

- **A. Recommended:** Continuous scale limits, `coord_cartesian()` limits, discrete `geom_tile()` grids, reversed scales, `coord_flip()`, and facets. Skip transformed scales unless existing evidence shows risk.
- **B. Narrow:** Continuous scale limits and `coord_cartesian()` only.
- **C. Broad:** Include transformed scales and any available edge-coordinate variants immediately.

**Selected:** A.

## Area 2: Fix vs Non-Issue Threshold

**Question:** When should the phase fix behavior versus close it as verified non-issue?

- **A. Recommended:** Fix only visible or DOM-measurable mismatches against ggplot behavior; close ggplot-compatible behavior or intended SVG panel clipping with tests and rationale.
- **B. Aggressive:** Normalize every out-of-panel rect/tile coordinate even when clipping already hides the difference.
- **C. Conservative:** Prefer documentation-only closure unless the mismatch is severe.

**Selected:** A.

## Area 3: Validation Shape

**Question:** What validation should prove the closure?

- **A. Recommended:** IR tests, JavaScript/source contract tests, and optional browser DOM smoke for representative cases. No screenshot or perceptual diffing.
- **B. Minimal:** R-side IR tests only.
- **C. Visual-heavy:** Add screenshot comparison for rect/tile fixtures.

**Selected:** A.

## Area 4: Closure Documentation

**Question:** Where should the outcome be recorded?

- **A. Recommended:** Update `vignettes/d3-drawing-diagnostics.md` and Phase 45 verification notes now; leave broader public docs to Phase 47 unless behavior changes user-facing support.
- **B. Phase-only:** Record only in Phase 45 verification notes.
- **C. Broad docs now:** Update README, vignettes, roxygen, and diagnostics in this phase.

**Selected:** A.

## Recommendations Captured

- Keep Phase 45 evidence-driven: reproduce/classify first, then fix only confirmed mismatch.
- Preserve panel clipping as an acceptable outcome when it matches ggplot2 or intended SVG behavior.
- Keep validation mechanical and stable through IR/source/DOM assertions.
- Close the v1.10 deferred diagnostics note with precise evidence rather than broad wording.
