# Phase 41: Release-Blocking Debt Triage - Context

## Phase Summary

Maintainers need known release-facing debt fixed or explicitly deferred with rationale before broader v1.10 validation proceeds.

## Decisions

### Advisory follow-ups

- Treat the direct `pkgload`/`rprojroot` dependency declarations as already resolved by Phase 40, but verify the state during planning/execution.
- Treat facet browser panel identity assertions as already addressed if tests continue to compare panel-local counts in panel order rather than sorted distributions.
- Phase 41 should classify these advisory follow-ups as resolved with evidence instead of adding redundant behavior work unless verification finds a regression.

### Ordinary `geom_polygon()` support

- Do not expand Phase 41 into a new ordinary `geom_polygon()` renderer implementation.
- The release-blocking issue is stale or contradictory support signaling around ordinary `geom_polygon()`, especially where the package simultaneously recognizes `GeomPolygon` in IR and documents `geom_polygon()` as unsupported in the vignette.
- Execution should reconcile support tables, validation behavior, and documentation so the release contract is explicit.
- If ordinary `geom_polygon()` remains unsupported, classify it as a deferred non-blocker with rationale and next-step guidance.

### Rect/tile out-of-bounds behavior

- Triage `geom_rect()`/`geom_tile()` out-of-bounds rendering before deciding whether to change renderer behavior.
- Fix only if the issue is small, low-risk, and clearly release-blocking.
- Otherwise, add focused characterization or documentation and classify the remaining renderer behavior as a deferred non-blocker with rationale.

### Debt artifact

- Produce a dedicated debt audit artifact during Phase 41 that records each known item, status, evidence, release-blocking judgment, rationale, and next step.
- The artifact should be reviewable by a maintainer without reconstructing the phase from commit history.

## Constraints

- Keep Phase 41 to release-blocking debt triage, not new feature expansion.
- Do not weaken the shipped `geom_sf()` polygon-family contract while clarifying ordinary `geom_polygon()` status.
- Preserve CRAN/package hygiene improvements from Phase 40.
- Prefer narrow tests and documentation updates over broad renderer rewrites unless a debt item is proven blocking.

## User Preferences

- User accepted the recommended defaults for all discussed gray areas.
- Favor practical release-readiness decisions with explicit rationale over open-ended polishing.

## Open Questions

- Whether ordinary `geom_polygon()` should be removed from public support tables, kept as recognized-but-unsupported IR, or handled by a clearer unsupported-renderer path.
- Whether the rect/tile out-of-bounds edge case reproduces in current renderer tests strongly enough to require a code fix in this milestone.
- Exact shape and filename of the debt audit artifact can be chosen during planning.

## Canonical References

### Phase Requirements

- `.planning/ROADMAP.md` - Phase 41 goal, dependencies, success criteria, and expected plans.
- `.planning/REQUIREMENTS.md` - DEBT-01 and DEBT-02 acceptance requirements.
- `.planning/PROJECT.md` - v1.10 release hardening scope and known tech debt list.
- `.planning/STATE.md` - current milestone state and Phase 41 position.

### Advisory Evidence

- `.planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-REVIEW.md` - original advisory about facet panel identity assertions.
- `tests/testthat/test-sf-browser.R` - current browser sf tests, including panel-local facet count assertions.
- `DESCRIPTION` - package dependency declarations to verify `pkgload` and `rprojroot` status from Phase 40.

### Polygon Debt

- `R/as_d3_ir.R` - maps `GeomPolygon` to ordinary `polygon` IR.
- `R/validate_ir.R` - currently recognizes `polygon` as a known geom type.
- `README.Rmd` - public support table currently lists `geom_polygon()`.
- `vignettes/gg2d3.Rmd` - documents unsupported ordinary `geom_polygon()` behavior.
- `vignettes/d3-drawing-diagnostics.md` - diagnostic documentation for supported/unsupported renderer behavior.

### Rect/Tile Debt

- `inst/htmlwidgets/modules/geoms/rect.js` - current `geom_rect()`/`geom_tile()` renderer.
- `tests/testthat/test-regression-core.R` - current core regression matrix includes basic `geom_rect()`.
- `vignettes/d3-drawing-diagnostics.md` - documents rect/tile out-of-bounds edge cases.

## Existing Code Insights

### Reusable Assets

- Browser sf helper tests already provide panel-local DOM count patterns for verifying facet identity.
- Core regression tests already include a simple `geom_rect()` IR smoke case that can be expanded or paired with a targeted out-of-bounds characterization.
- The unsupported-renderer diagnostic path already documents ordinary `geom_polygon()` as an in-panel unsupported message candidate.

### Established Patterns

- Release hardening phases should verify and classify evidence, then make narrow fixes only where the release contract is misleading or behavior is clearly blocking.
- Documentation must distinguish ordinary ggplot2 `geom_polygon()` from supported `geom_sf()` polygon-family geometries.
- Deferred release debt needs explicit rationale and next-step guidance rather than vague known-issue notes.

### Integration Points

- R-layer geom detection and IR validation determine whether ordinary polygons are accepted into IR.
- D3 geom registry determines whether recognized IR renders live marks or falls through to unsupported-geom diagnostics.
- README/vignette diagnostics define the public support contract downstream users will read.

## Specific Ideas

- Use a debt audit table with columns similar to: item, evidence, classification, action, rationale, next step.
- Include one entry for each required debt item: dependency declarations, facet panel identity assertions, ordinary `geom_polygon()` support signaling, and rect/tile out-of-bounds behavior.

## Deferred Ideas

- Implementing ordinary `geom_polygon()` as a new supported renderer is deferred unless planning proves the contradiction is release-blocking and trivial to close.
- Broader renderer rewrites for clipping or scale bounds should be deferred if a narrow rect/tile fix cannot be validated safely in this milestone.

---

*Phase: 41-release-blocking-debt-triage*
*Context gathered: 2026-05-23*
