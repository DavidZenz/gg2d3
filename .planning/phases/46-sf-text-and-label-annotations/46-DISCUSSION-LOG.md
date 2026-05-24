# Phase 46: sf Text And Label Annotations - Discussion Log

**Discussed:** 2026-05-24
**User selection:** Recommendations accepted.
**Outcome:** Ready for `$gsd-plan-phase 46`.

## Area 1: Anchor Semantics

**Question:** What should labels attach to for polygons, points, and lines?

- **A. Recommended:** Use one representative anchor per feature. Points use their point coordinate, polygons use a representative point or centroid-style anchor, and lines use a deterministic midpoint or centroid-style anchor. No collision avoidance or path-following.
- **B. Narrow:** Support point annotations first and defer polygon/line labels.
- **C. Broad:** Add path-following labels and more advanced placement immediately.

**Selected:** A.

## Area 2: Styling Contract

**Question:** Which aesthetics must Phase 46 honor?

- **A. Recommended:** Support the core visible contract: `label`, `colour`, label `fill`, `alpha`, `size`, and existing easy text fields like font, `hjust`, and `vjust` where already available. Defer rotation, rich text, exact padding parity, and ggrepel behavior.
- **B. Minimal:** Support only label text and color.
- **C. Broad:** Aim for full ggplot2 `geom_sf_text()` and `geom_sf_label()` visual parity now.

**Selected:** A.

## Area 3: Interactivity

**Question:** How should tooltip, hover, brush, and handlers treat sf annotation marks?

- **A. Recommended:** Annotation marks are interactive at text/label mark level, reuse existing plumbing, use anchor-based `data-cx` / `data-cy` for brushing, and keep renderer-private geometry metadata out of public payloads.
- **B. Render-only:** Do not wire interactivity for sf annotations in this phase.
- **C. Geometry payloads:** Expose full geometry or private renderer fields to callbacks.

**Selected:** A.

## Area 4: Validation

**Question:** What fixtures and gates prove Phase 46 is done?

- **A. Recommended:** IR tests plus renderer/source/DOM tests for polygon, point, line, skipped rows, stacked layers, facets, and interactivity/sanitization. Optional browser smoke is fine; no screenshot testing.
- **B. R-side only:** Cover extraction and diagnostics but leave renderer behavior mostly manual.
- **C. Visual-heavy:** Add screenshot/perceptual diff tests for label placement.

**Selected:** A.

## Recommendations Captured

- Keep Phase 46 focused on useful projected anchors, not a map-label layout engine.
- Reuse current sf projection metadata and `data-cx` / `data-cy` conventions.
- Reuse existing tooltip, hover, brush, and handler APIs with sanitized payloads.
- Validate through stable IR/source/DOM evidence and optional CRAN-compatible browser smoke.

## the agent's Discretion

- Exact polygon and line anchor algorithm, after checking ggplot2/sf behavior and existing projection helpers.
- Exact renderer/module split and helper names.
- Exact browser smoke fixture split, provided the required matrix is covered.

## Deferred Ideas

- ggrepel collision avoidance.
- Path-following line labels.
- Rich text, rotation/angle parity, and exact label padding/radius/stroke parity.
- New sf-annotation-specific interactivity APIs.
- Screenshot or perceptual visual regression infrastructure.
