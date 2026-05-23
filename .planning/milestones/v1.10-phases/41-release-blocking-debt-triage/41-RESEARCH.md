# Phase 41: Release-Blocking Debt Triage - Research

## RESEARCH COMPLETE

## Phase Scope

Phase 41 is a release-hardening triage phase, not a feature-expansion phase. The work should prove that known release-facing debt is either fixed or explicitly classified as non-blocking with evidence and next steps.

Roadmap expects exactly two plans:

- `41-01-PLAN.md` - Resolve or classify recent advisory follow-ups from review and verification artifacts.
- `41-02-PLAN.md` - Triage stale renderer/documentation debt around `GeomPolygon` and rect out-of-bounds behavior.

Requirements:

- `DEBT-01` - Recent advisory follow-ups are fixed or explicitly classified non-blocking.
- `DEBT-02` - Known renderer/documentation debt is triaged, fixed where blocking, or deferred with rationale.

## Evidence Snapshot

### Dependency Advisory

`DESCRIPTION` already lists `pkgload` and `rprojroot` in `Suggests`, alongside other optional test/browser/vignette helpers. This appears to satisfy the direct dependency declaration follow-up from Phase 36/40, but Phase 41 should record the evidence in a release-facing debt audit.

Verification command:

```bash
rtk Rscript --vanilla -e 'd <- read.dcf("DESCRIPTION"); suggests <- d[1, "Suggests"]; stopifnot(grepl("pkgload", suggests, fixed = TRUE), grepl("rprojroot", suggests, fixed = TRUE)); cat("dependency advisory resolved\n")'
```

### Facet Browser Panel Identity Advisory

`tests/testthat/test-sf-browser.R` already contains a focused test named `BRSF-02 DOM: faceted sf fixtures keep panel-local path counts`.

Current expected panel counts preserve identity by comparing panel-order vectors directly:

- `phase35-sf-facet-wrap.html` -> `c(1L, 1L)`
- `phase35-sf-facet-grid.html` -> `c(1L, 0L, 0L, 1L)`

The test no longer sorts panel counts before comparing. Phase 41 should verify and classify this as resolved unless a scan finds a regression.

### Ordinary `geom_polygon()` Debt

The debt is about ordinary ggplot2 `geom_polygon()`, not `geom_sf()` polygon-family support.

Current signals are contradictory:

- `README.Rmd` lists `geom_polygon` in the Area/Ribbon support row.
- `R/as_d3_ir.R` maps `GeomPolygon` to ordinary `polygon` IR.
- `R/validate_ir.R` recognizes `polygon` as a known geom.
- No D3 renderer registers ordinary `polygon`.
- `vignettes/gg2d3.Rmd` documents ordinary `geom_polygon()` as unsupported, but currently says unsupported geoms produce an in-panel message.
- `inst/htmlwidgets/modules/geom-registry.js` currently emits a console warning and returns zero marks when no renderer is registered.

Recommended release-hardening approach:

- Do not implement a new ordinary polygon renderer in this phase.
- Remove or qualify public support-table claims that ordinary `geom_polygon()` is supported.
- Keep `GeomPolygon` IR recognition only if the implementation path still needs unsupported-geom diagnostics, but document that no ordinary polygon renderer exists.
- Add or update tests/source checks so support signaling cannot silently drift again.

### Rect/Tile Out-of-Bounds Debt

`inst/htmlwidgets/modules/geoms/rect.js` renders `geom_rect()` and `geom_tile()` with `xmin`, `xmax`, `ymin`, and `ymax`. Continuous dimensions use absolute pixel differences; clipping occurs at the panel group level.

Current diagnostic docs say:

> `geom_rect` and `geom_tile` may render incorrectly when coordinates extend outside the panel area (negative widths/heights). Clipping is applied at the panel boundary.

The phrase "negative widths/heights" is stale or imprecise because the renderer uses `Math.abs()` for continuous width/height. However, out-of-bounds coordinates and reversed/censored scale edge cases may still be a real renderer risk. Phase 41 should characterize and classify this debt before changing renderer behavior.

Recommended release-hardening approach:

- Add an audit entry explaining what the current renderer does.
- Add a narrow source or regression test that guards the known current behavior.
- Fix docs to avoid inaccurate "negative widths/heights" wording.
- Only change renderer logic if a focused reproduction proves the current behavior is release-blocking and the fix is low-risk.

## Implementation Strategy

### Plan 41-01

Create the shared `41-DEBT-AUDIT.md` and classify advisory follow-ups:

- `pkgload` direct declaration - resolved if `DESCRIPTION` Suggests contains `pkgload`.
- `rprojroot` direct declaration - resolved if `DESCRIPTION` Suggests contains `rprojroot`.
- Facet panel identity assertion - resolved if browser sf test compares `panel_counts` directly to ordered expected vectors and no `sort(panel_counts)` appears in that test.

### Plan 41-02

Extend `41-DEBT-AUDIT.md` and reconcile renderer/doc debt:

- Ordinary `geom_polygon()` - remove/qualify support claims, preserve distinction from `geom_sf()` polygon-family support, classify ordinary polygon rendering as deferred unless implemented.
- Rect/tile out-of-bounds - characterize current renderer behavior, update inaccurate docs, add focused test/source guard, classify residual risk.

## Validation Architecture

Test infrastructure:

- Framework: `testthat` for R tests; source-level checks with `rtk rg`; metadata checks with `rtk Rscript`.
- Quick command: `rtk Rscript --vanilla -e 'read.dcf("DESCRIPTION"); cat("DESCRIPTION parse ok\n")'`
- Focused source checks: `rtk rg` over `DESCRIPTION`, `tests/testthat/test-sf-browser.R`, `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/as_d3_ir.R`, `R/validate_ir.R`, and `inst/htmlwidgets/modules/geoms/rect.js`.
- Focused tests: use `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'` only if Phase 41 edits regression tests or core IR behavior.

Sampling:

- After each plan, run the plan-specific `rtk rg` and `rtk Rscript` checks.
- After both plans, confirm every `DEBT-01` and `DEBT-02` item appears in `41-DEBT-AUDIT.md` with a status of `Resolved`, `Fixed`, or `Deferred non-blocker`.
- Do not run full `R CMD check`; Phase 42 owns the full release validation gate.

## Out of Scope

- Implementing a full ordinary `geom_polygon()` D3 renderer.
- Broad rect/tile renderer rewrites or visual-diff infrastructure.
- Changing the shipped `geom_sf()` polygon-family support contract.
