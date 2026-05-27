# Phase 51: Geometry Edge-Case Classification And Polish - Research

**Researched:** 2026-05-26
**Domain:** ggplot2 built-data classification, gg2d3 IR, D3 SVG geometry rendering
**Confidence:** HIGH for codebase seams and validation shape; MEDIUM for exact transformed-scale visual outcomes until fixtures compare ggplot2 build/IR/browser output.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Rect/Tile Transform Classification
- **D-01:** Build focused fixtures for `geom_rect()` and `geom_tile()` on transformed scales, especially log, sqrt, and reverse where applicable.
- **D-02:** Compare ggplot2 built data, gg2d3 IR, and D3-rendered behavior before changing implementation.
- **D-03:** Fix only small renderer-boundary mismatches, such as finite transformed bounds, categorical/tile placement drift, or zoom/update parity issues.
- **D-04:** If parity would require broad coordinate-system semantics or deeper ggplot2 transformation emulation, document it as an explicit non-goal with evidence rather than expanding scope.

### Polygon Topology Contract
- **D-05:** Treat ordinary `geom_polygon()` as grouped closed SVG paths that preserve ggplot2 built row order.
- **D-06:** Characterize holes, subgroups, ring order, and related edge cases against ggplot2 output before deciding whether any code change is warranted.
- **D-07:** Support only cases that can be represented honestly by grouped SVG paths without topology repair.
- **D-08:** Explicitly document unsupported full GIS-style topology repair, automatic hole inference, and invalid polygon fixing.

### Text/Label Polish Scope
- **D-09:** Attempt at most one small verified text/label improvement if it is source-local and low-risk.
- **D-10:** Good candidate improvements include basic `geom_label()` parity or better `hjust`/`vjust`/`angle` handling for ordinary `geom_text()`.
- **D-11:** Treat collision avoidance and path-following labels as classify-and-defer unless research finds a tiny, robust implementation path.
- **D-12:** Do not implement a full ggrepel clone in this phase.

### Validation Evidence
- **D-13:** Require source or IR tests for every classified behavior.
- **D-14:** Add renderer source checks when the behavior is JavaScript-boundary-specific.
- **D-15:** Use optional browser visual smoke or generated inspectable HTML for representative visual cases across rect/tile, polygon, and text/label surfaces.
- **D-16:** Record pass/skip evidence in `51-VALIDATION.md`, preserving existing optional `{sf}` and browser dependency skip policy.

### the agent's Discretion
- Exact fixture names, test-file split, generated artifact filenames, and whether a tiny improvement is worth implementing are left to research/planning.
- The planner may decide that classification-only is the right outcome for a sub-area if the evidence shows a fix would exceed the phase boundary.

### Claude's Discretion
- Exact fixture names, test-file split, generated artifact filenames, and whether a tiny improvement is worth implementing are left to research/planning.
- The planner may decide that classification-only is the right outcome for a sub-area if the evidence shows a fix would exceed the phase boundary.

### Deferred Ideas (OUT OF SCOPE)
- Full GIS topology repair, automatic hole inference, invalid polygon fixing, and polygon-overlap brushing remain future work or explicit non-goals unless the product direction changes.
- Full ggrepel-compatible collision avoidance remains FUT-05 and should not be implemented in Phase 51.
- Broad path-following label placement remains a future feature unless a tiny, isolated classification artifact is enough.
- CI-hosted screenshot/perceptual diffs and committed golden images remain FUT-01/FUT-02 after local visual smoke stabilizes.
- Projection-aware map interactions beyond ggplot parity remain FUT-06.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEOM-01 | Transformed-scale rect/tile behavior is classified with focused fixtures and either fixed at the implicated boundary or documented as an explicit non-goal with evidence. | Existing scale helpers expose log, sqrt, reverse, and symlog transform metadata; existing rect renderer/update paths are the only likely source-local fix points. [VERIFIED: `.planning/REQUIREMENTS.md`; `R/ir_scale_helpers.R:28-58`; `inst/htmlwidgets/modules/geoms/rect.js:85-130`; `inst/htmlwidgets/modules/geom-registry.js:219-257`] |
| GEOM-02 | Ordinary polygon topology and hole/subgroup behavior is characterized against ggplot2 output, with supported cases locked by tests and unsupported cases documented without overclaiming. | Current ordinary polygon renderer groups by built `group` and emits one closed path per group; ggplot2 documents `subgroup` support for holes, which gg2d3 does not currently keep in non-sf layer rows. [VERIFIED: `.planning/REQUIREMENTS.md`; `inst/htmlwidgets/modules/geoms/polygon.js:83-121`; `R/ir_layer_helpers.R:16-27`; CITED: `https://ggplot2.tidyverse.org/reference/geom_polygon.html`] |
| GEOM-03 | Text and label geometry polish candidates, including collision avoidance and path-following placement, are either scoped into a small verified improvement or explicitly deferred with implementation-ready evidence. | Ordinary `GeomLabel` is currently normalized to `geom = "text"`; ordinary `text.js` ignores `hjust`, `vjust`, `angle`, font family/face, and label boxes, while sf annotation rendering already has local helpers for justification, font styling, and label boxes. [VERIFIED: `.planning/REQUIREMENTS.md`; `R/ir_layer_helpers.R:76-79`; `inst/htmlwidgets/modules/geoms/text.js:81-86`; `inst/htmlwidgets/modules/geoms/sf.js:213-249`; CITED: `https://ggplot2.tidyverse.org/reference/geom_text.html`] |
</phase_requirements>

## Summary

Phase 51 should be planned as a classification-first polish phase, not as a geometry-engine expansion. The prior v1.11 rect/tile work explicitly skipped transformed scales and fixed only categorical tile and update-path mismatches; Phase 51 should now add the missing transformed-scale matrix and compare ggplot2 built data, IR rows, and D3 source/browser behavior before changing code. [VERIFIED: `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md`; `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`]

The ordinary polygon surface should stay a grouped closed-path contract. ggplot2 supports `subgroup` holes, but current gg2d3 rowization does not preserve `subgroup`, and `polygon.js` does not produce compound paths or `fill-rule`; therefore Phase 51 should characterize subgroup/hole cases and only support what can be represented honestly by existing grouped SVG paths. [VERIFIED: `R/ir_layer_helpers.R:16-27`; `inst/htmlwidgets/modules/geoms/polygon.js:83-121`; CITED: `https://ggplot2.tidyverse.org/reference/geom_polygon.html`]

For text/label polish, the best low-risk candidate is ordinary `geom_text()` alignment/angle/style parity, not collision avoidance or path-following labels. A small implementation can reuse the sf annotation renderer's `hjust`/`vjust`/font-style patterns, but the planner should require source/IR tests first and should choose classification-only if adding `geom_label()` boxes or update-path support grows beyond a local change. [VERIFIED: `inst/htmlwidgets/modules/geoms/text.js:81-86`; `inst/htmlwidgets/modules/geoms/sf.js:213-249`; `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`]

**Primary recommendation:** Plan four slices: transformed rect/tile classification and tiny fixes; ordinary polygon topology/hole/subgroup characterization; text/label classification plus at most one local polish change; final validation artifact and optional browser visual evidence. [VERIFIED: `.planning/ROADMAP.md`; source inspection]

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Use the existing R package structure and dev commands: `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: `CLAUDE.md`]
- The package architecture is R extraction, JSON-serializable IR, then D3 SVG rendering through htmlwidgets. [VERIFIED: `CLAUDE.md`; `R/as_d3_ir.R`; `inst/htmlwidgets/modules/geom-registry.js`]
- D3 v7 is vendored locally; do not introduce remote D3 dependencies. [VERIFIED: `CLAUDE.md`; `inst/htmlwidgets/gg2d3.yaml`]
- Use actual helper filenames `R/ir_scale_helpers.R` and `R/ir_layer_helpers.R`; the Phase 51 context's `R/ir_helpers_scales.R` / `R/ir_helpers_layers.R` names are stale. [VERIFIED: `rtk rg --files R`; user correction 2026-05-26]
- Keep generated browser and visual artifacts under ignored `test_output/` paths and preserve optional browser/spatial skip semantics. [VERIFIED: `tests/testthat/helper-browser-visual.R:21-45`; `.planning/phases/48-browser-visual-smoke-coverage/48-CONTEXT.md`]
- Use `rtk` as the shell-command prefix while working in this repository. [VERIFIED: `/Users/davidzenz/.codex/RTK.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Transformed rect/tile classification | R IR Layer | D3 Renderer | ggplot2 build output and scale helper transform metadata determine input truth; `rect.js` and `geom-registry.js` own pixel placement and update parity. [VERIFIED: `R/ir_scale_helpers.R:28-58`; `inst/htmlwidgets/modules/geoms/rect.js:85-130`; `inst/htmlwidgets/modules/geom-registry.js:219-311`] |
| Rect/tile visual evidence | Browser Runtime | Test Layer | Optional visual smoke generates HTML, PNG, DOM summary, and browser log under `test_output/browser-visual-smoke/`. [VERIFIED: `tests/testthat/helper-browser-visual.R:21-45`; `tests/testthat/test-browser-visual-smoke.R:279-329`] |
| Ordinary polygon topology classification | R IR Layer | D3 Renderer | R rowization decides whether `subgroup` survives; D3 grouped paths decide whether holes/subgroups can render honestly. [VERIFIED: `R/ir_layer_helpers.R:16-27`; `inst/htmlwidgets/modules/geoms/polygon.js:94-121`] |
| Polygon browser proof | Browser Runtime | Test Layer | Existing polygon browser tests assert closed clipped paths and public payload behavior, and Phase 51 can reuse this pattern for topology fixtures. [VERIFIED: `tests/testthat/test-polygon-browser.R:205-305`] |
| Ordinary text/label polish | D3 Renderer | R IR Layer | `GeomLabel` currently maps to text and ordinary `text.js` owns actual SVG attributes; R helper changes are needed only if new aesthetics must be retained. [VERIFIED: `R/ir_layer_helpers.R:76-79`; `inst/htmlwidgets/modules/geoms/text.js:63-86`] |
| Validation notes | Planning Artifact | Test Layer | Phase context requires pass/skip evidence in `51-VALIDATION.md`; tests provide evidence, generated artifacts remain local. [VERIFIED: `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`] |

## Standard Stack

| Component | Version / Status | Purpose | Phase 51 Guidance |
|-----------|------------------|---------|-------------------|
| R | 4.6.0 local | Run package tests and fixture classification. [VERIFIED: local `Rscript --version`] | Use existing testthat commands; no new runtime required. [VERIFIED: `DESCRIPTION`] |
| ggplot2 | 4.0.3 local | Ground truth for built data and geometry semantics. [VERIFIED: local package audit] | Compare `ggplot_build(plot)$data[[1]]` against `as_d3_ir(plot)` before code changes. [VERIFIED: `tests/testthat/test-rect-tile-ir.R:28-43`] |
| D3 | v7 vendored | SVG scale/path/rect/text rendering. [VERIFIED: `CLAUDE.md`; `inst/htmlwidgets/gg2d3.yaml`] | Use existing renderer modules; do not replace with a topology or label-placement engine. [VERIFIED: `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`] |
| testthat | 3.3.2 local | IR/source/browser tests. [VERIFIED: local package audit] | Required strata for every classified behavior. [VERIFIED: `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`] |
| chromote | 0.5.1 local | Optional browser visual/DOM evidence. [VERIFIED: local package audit] | Keep opt-in and skip-friendly via `GG2D3_BROWSER_VISUAL_SMOKE=true`. [VERIFIED: `tests/testthat/helper-browser-visual.R:48-84`] |
| sf | Missing locally | Optional sf annotation browser/IR fixtures. [VERIFIED: local package audit] | Missing `{sf}` is not blocking; record expected skips. [VERIFIED: `tests/testthat/test-sf-annotations-ir.R:1-2`; `tests/testthat/helper-browser-visual.R:86-106`] |
| geojsonsf | 2.0.5 local | Optional sf serialization dependency. [VERIFIED: local package audit] | Still optional; useful only for sf annotation tests. [VERIFIED: `DESCRIPTION`] |

## Technical Findings

### Transformed Rect/Tile Classification

- Existing transformed-scale metadata covers `log10`, `log2`, `log`, `sqrt`, `reverse`, and `pseudo_log`/symlog, and log domains are validated before JS rendering. [VERIFIED: `R/ir_scale_helpers.R:1-58`; `R/ir_scale_helpers.R:158-189`]
- Existing rect/tile IR fixtures cover scale limits, `coord_cartesian()`, discrete tiles, reverse, `coord_flip()`, and facets, but they do not cover transformed rect/tile matrices for log and sqrt. [VERIFIED: `tests/testthat/test-rect-tile-ir.R:43-148`; `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md`]
- Initial rect rendering and zoom/update geometry use separate but similar helper blocks; any transformed-scale fix must update both or explicitly prove update parity is unaffected. [VERIFIED: `inst/htmlwidgets/modules/geoms/rect.js:85-130`; `inst/htmlwidgets/modules/geom-registry.js:219-257`; `inst/htmlwidgets/modules/geom-registry.js:293-311`]
- `rect.js` filters only `null`/`undefined` bounds before scaling, so transformed `NaN` or non-finite pixel values should be part of the Phase 51 fixture assertions. [VERIFIED: `inst/htmlwidgets/modules/geoms/rect.js:46-50`]
- Recommended classification matrix: `geom_rect()` with positive log x/y bounds, bounds touching non-positive log territory, sqrt x/y bounds, reverse x/y bounds, `geom_tile()` on transformed continuous x/y where ggplot2 computes `xmin/xmax/ymin/ymax`, and categorical tile controls to ensure Phase 45 band fixes do not drift. [VERIFIED: `R/ir_scale_helpers.R:38-50`; `tests/testthat/test-rect-tile-ir.R`; ASSUMED: exact fixture names]

### Ordinary Polygon Topology / Hole / Subgroup Behavior

- Current ordinary polygon IR preserves `PANEL`, `x`, `y`, `group`, `fill`, `colour`, `alpha`, `linewidth`, and `linetype`, but `subgroup` is not retained in `gg2d3_ir_layer_keep_aes()`. [VERIFIED: `R/ir_layer_helpers.R:16-27`; `tests/testthat/test-polygon-ir.R:32-156`]
- Current ordinary polygon renderer groups by `group`, filters finite points, requires at least three points, and emits one `path.geom-polygon` per group using `curveLinearClosed`. [VERIFIED: `inst/htmlwidgets/modules/geoms/polygon.js:83-121`]
- Current ordinary polygon renderer has no compound-path or `fill-rule` support; by contrast the sf polygon renderer explicitly sets `fill-rule="evenodd"` for GeoJSON polygon-family marks. [VERIFIED: `inst/htmlwidgets/modules/geoms/polygon.js:113-121`; `inst/htmlwidgets/modules/geoms/sf.js:327-340`]
- ggplot2 documents polygon holes via the `subgroup` aesthetic, so Phase 51 should not claim hole parity unless tests prove the `subgroup` contract is preserved and rendered. [CITED: `https://ggplot2.tidyverse.org/reference/geom_polygon.html`; VERIFIED: `R/ir_layer_helpers.R:16-27`]
- Recommended classification cases: two independent groups, subgroup-with-hole input, reversed ring order, fewer-than-three-point subgroup, missing coordinate rows, and intentionally self-crossing/invalid polygon. Supported cases should remain row-order grouped paths; unsupported cases should be documented as no topology repair / no automatic hole inference. [VERIFIED: `inst/htmlwidgets/modules/geoms/polygon.js:40-47`; `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md`; ASSUMED: exact invalid polygon fixture shape]

### Text/Label Polish Candidates

- `GeomLabel` currently maps to ordinary `"text"` at the R helper boundary, so `geom_label()` does not get a distinct renderer or label box in ordinary Cartesian plots. [VERIFIED: `R/ir_layer_helpers.R:76-79`; `inst/htmlwidgets/modules/geoms/text.js:91-92`]
- Ordinary `text.js` centers all text with fixed `dominant-baseline="middle"`, `text-anchor="middle"`, and `font-size: 10px`; it does not apply row/param `hjust`, `vjust`, `angle`, `family`, `fontface`, or mapped/static size. [VERIFIED: `inst/htmlwidgets/modules/geoms/text.js:81-86`]
- Non-sf layer rowization currently keeps `label` and `size`, but not ordinary text `hjust`, `vjust`, `angle`, `fontface`, or `family`; sf helpers do keep those for sf annotations. [VERIFIED: `R/ir_layer_helpers.R:16-27`; `R/sf_utils.R:231-237`]
- sf annotation rendering already has compact helpers for `hjust` to SVG `text-anchor`, `vjust` to `dominant-baseline`, size conversion, family, bold, and italic. These are the best local analogs for ordinary text polish. [VERIFIED: `inst/htmlwidgets/modules/geoms/sf.js:194-249`; `inst/htmlwidgets/modules/geoms/sf.js:393-411`]
- ggplot2 documents `geom_text()` and `geom_label()` as adding one label per row and supporting alignment/angle aesthetics; it also documents label-specific behavior separately from text. [CITED: `https://ggplot2.tidyverse.org/reference/geom_text.html`]
- Recommended tiny improvement: preserve and render ordinary text `hjust`, `vjust`, `angle`, `size`, `family`, and `fontface` if the row/param data is already available or can be added to `gg2d3_ir_layer_keep_aes()` without broad churn. Treat ordinary `geom_label()` boxes, collision avoidance, and path-following as deferrals unless the planner can keep them source-local and tested. [VERIFIED: `R/ir_layer_helpers.R:16-27`; `inst/htmlwidgets/modules/geoms/text.js:81-86`; ASSUMED: implementation effort estimate]

## Recommended Implementation Sequence

| Slice | Goal | Likely Files | Evidence Gate |
|-------|------|--------------|---------------|
| 51-01 Rect/tile transformed-scale classification | Add fixtures comparing ggplot2 built rows, IR rows, renderer source, and optional browser/HTML evidence for log/sqrt/reverse rect/tile cases. | `tests/testthat/test-rect-tile-ir.R`, `tests/testthat/test-rect-tile-renderer.R`, optional `tests/testthat/test-browser-visual-smoke.R`, `51-VALIDATION.md` | `GEOM-01` source/IR tests pass; any fix touches only `rect.js` and/or `geom-registry.js`. [VERIFIED: source inspection] |
| 51-02 Ordinary polygon topology classification | Characterize grouped paths, holes/subgroups, ring order, and unsupported topology cases without GIS repair. | `tests/testthat/test-polygon-ir.R`, `tests/testthat/test-polygon-renderer.R`, `tests/testthat/test-polygon-browser.R` or visual smoke fixture, `51-VALIDATION.md` | `GEOM-02` tests lock supported grouped-path behavior and document unsupported subgroup/hole semantics honestly. [VERIFIED: source inspection] |
| 51-03 Text/label polish classification and tiny fix | Decide whether to implement ordinary text alignment/style or classify/defer label boxes/collision/path-following. | `R/ir_layer_helpers.R`, `inst/htmlwidgets/modules/geoms/text.js`, `inst/htmlwidgets/modules/geom-registry.js`, new or existing text tests, optional visual smoke fixture | `GEOM-03` has either one local verified improvement or clear deferral evidence. [VERIFIED: source inspection] |
| 51-04 Final validation notes | Record commands, pass/skip evidence, optional artifacts, and explicit non-goals. | `.planning/phases/51-geometry-edge-case-classification-and-polish/51-VALIDATION.md`, possibly `vignettes/d3-drawing-diagnostics.md` if implementation changes public caveats | Validation evidence includes GEOM-01/02/03 status and optional skip reasons. [VERIFIED: `51-CONTEXT.md`] |

## Concrete File Targets

| Area | Primary Targets | Notes |
|------|-----------------|-------|
| Rect/tile IR | `tests/testthat/test-rect-tile-ir.R`, `R/ir_scale_helpers.R`, `R/as_d3_ir.R` | Prefer tests first; helper code should change only if IR classification exposes a proven mismatch. [VERIFIED: current tests/source] |
| Rect/tile JS | `inst/htmlwidgets/modules/geoms/rect.js`, `inst/htmlwidgets/modules/geom-registry.js`, `tests/testthat/test-rect-tile-renderer.R` | Keep initial render and update logic in sync. [VERIFIED: duplicated geometry helpers] |
| Polygon IR | `tests/testthat/test-polygon-ir.R`, `R/ir_layer_helpers.R` | Add `subgroup` only if implementing honest subgroup support; otherwise test/document absence. [VERIFIED: `R/ir_layer_helpers.R:16-27`] |
| Polygon JS | `inst/htmlwidgets/modules/geoms/polygon.js`, `tests/testthat/test-polygon-renderer.R`, `tests/testthat/test-polygon-interactivity.R` | Do not add topology repair. Source tests can guard no sorting and no private payload leaks. [VERIFIED: current source tests] |
| Text/label | `R/ir_layer_helpers.R`, `inst/htmlwidgets/modules/geoms/text.js`, `inst/htmlwidgets/modules/geom-registry.js`, new `tests/testthat/test-text-label-polish.R` or focused additions to renderer tests | If update path needs angle/alignment parity, update `geom-registry.js` text block too. [VERIFIED: `geom-registry.js:313-317`] |
| Visual evidence | `tests/testthat/test-browser-visual-smoke.R`, `tests/testthat/helper-browser-visual.R`, `test_output/browser-visual-smoke/` | Artifact outputs stay ignored and optional. [VERIFIED: helper implementation] |

## Test Commands

Use `rtk` in this repository. Commands below are the recommended phase gates; browser visual smoke is opt-in. [VERIFIED: `/Users/davidzenz/.codex/RTK.md`]

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-regression-core.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
rtk git diff --check
```

## Validation Architecture

### Test Strata

| Stratum | Purpose | Files / Commands | Evidence Standard |
|---------|---------|------------------|-------------------|
| ggplot2 built-data classification | Establish whether ggplot2 censors, transforms, preserves, or represents the edge case before gg2d3 changes. | `tests/testthat/test-rect-tile-ir.R`, `tests/testthat/test-polygon-ir.R`, new text/label fixture tests. | Assertions compare `ggplot2::ggplot_build(plot)$data[[1]]` to `as_d3_ir(plot)$layers[[1]]`. [VERIFIED: `tests/testthat/test-rect-tile-ir.R:28-43`] |
| IR/schema tests | Lock supported row fields, transform metadata, grouping, and validation behavior. | `validate_ir(ir)`, `tests/testthat/test-ir-helper-boundaries.R`, area-specific files. | `validate_ir()` is silent and row/field assertions prove the behavior. [VERIFIED: `tests/testthat/test-polygon-ir.R:5-22`] |
| JS source-contract tests | Guard D3-boundary behavior that source can prove without a browser. | `test-rect-tile-renderer.R`, `test-polygon-renderer.R`, `test-sf-annotations-renderer.R`, text/label source tests. | Tests assert renderer registration, selectors/classes, update path, finite guards, and no unsupported topology/placement claims. [VERIFIED: existing renderer tests] |
| Optional browser DOM/visual smoke | Generate inspectable proof for representative visual cases and catch blank/missing mark regressions. | `tests/testthat/test-browser-visual-smoke.R`, optionally `test-polygon-browser.R` or `test-sf-annotations-browser.R`. | Passed rows have HTML, screenshot, DOM summary, and browser log; failures write artifacts under `test_output/`. [VERIFIED: `tests/testthat/helper-browser-visual.R:289-417`] |
| Final validation note | Preserve evidence and skip reasons for planner/verifier. | `.planning/phases/51-geometry-edge-case-classification-and-polish/51-VALIDATION.md` | Must list GEOM-01/02/03 evidence, commands run, pass/fail/skip outcomes, and non-goals. [VERIFIED: `51-CONTEXT.md`] |

### Optional Browser Visual Evidence

Browser visual evidence is optional and opt-in. Normal `test_file("tests/testthat/test-browser-visual-smoke.R")` should skip unless `GG2D3_BROWSER_VISUAL_SMOKE=true`; an opt-in run should write artifacts to `test_output/browser-visual-smoke/` including an index, HTML, screenshot, DOM summary, and browser log for non-skipped fixtures. [VERIFIED: `tests/testthat/helper-browser-visual.R:48-84`; `tests/testthat/test-browser-visual-smoke.R:314-329`]

Representative Phase 51 browser evidence should include at least one fixture per surface when available: transformed rect/tile, ordinary polygon topology-supported case, and text/label polish or deferral example. [VERIFIED: `51-CONTEXT.md`; ASSUMED: exact fixture IDs]

### Skip Behavior

Browser visual smoke must skip cleanly when the opt-in environment variable is absent, on CRAN, when `chromote` or Chrome/Chromium is unavailable, or when a chromote session cannot launch. [VERIFIED: `tests/testthat/helper-browser-visual.R:48-84`] sf-related annotation/browser cases must skip when `{sf}` or `geojsonsf` is unavailable; local audit found `{sf}` missing and `geojsonsf` available. [VERIFIED: local package audit; `tests/testthat/helper-browser-visual.R:86-106`]

### What Counts as Evidence

| Requirement | Required Evidence | Optional Evidence |
|-------------|-------------------|-------------------|
| GEOM-01 | Rect/tile transformed fixtures with ggplot2 built-data vs IR assertions; source tests for any `rect.js` or `geom-registry.js` change; `51-VALIDATION.md` notes classifying fix vs non-goal. | Browser visual artifact for a transformed rect/tile representative, or explicit opt-in/browser skip. |
| GEOM-02 | Polygon fixtures covering groups, subgroup/hole/ring-order edge cases; tests locking supported grouped-path behavior; explicit unsupported topology notes. | Browser DOM/visual proof that supported polygon fixtures render closed clipped paths. |
| GEOM-03 | Text/label fixture classification and either source/IR/browser tests for one tiny improvement or an implementation-ready deferral note for collision/path-following/label boxes. | Visual artifact showing alignment/angle/label behavior, or explicit browser skip. |

## Risks And Pitfalls

- **Changing before classifying:** Rect/tile transformed-scale behavior can be ggplot2 data censoring rather than a D3 bug; tests must inspect `ggplot_build()` first. [VERIFIED: Phase 45 classification; `tests/testthat/test-rect-tile-ir.R`]
- **Initial render/update drift:** Rect and text geometry have both initial render and zoom/update paths; changing only one can pass source checks but fail interaction. [VERIFIED: `rect.js`; `geom-registry.js:293-317`]
- **Non-finite transformed pixels:** Log/sqrt edge cases may produce `NA`, `NaN`, or non-finite pixel positions at different layers; tests should distinguish built-data censoring from renderer non-finite output. [VERIFIED: `R/ir_scale_helpers.R:1-24`; `rect.js:46-50`]
- **Overclaiming polygon holes:** ggplot2 `subgroup` holes are documented, but gg2d3 currently does not retain `subgroup` and ordinary polygon renderer lacks compound paths. [CITED: `https://ggplot2.tidyverse.org/reference/geom_polygon.html`; VERIFIED: `R/ir_layer_helpers.R:16-27`; `polygon.js`]
- **Turning text polish into layout engine work:** Collision avoidance and path-following labels require global placement/path algorithms, beyond a local renderer fix. [VERIFIED: `51-CONTEXT.md`; ASSUMED: algorithmic complexity]
- **Optional dependency ambiguity:** Browser and sf skips are acceptable evidence only when recorded explicitly with skip reasons. [VERIFIED: `RETROSPECTIVE.md`; `helper-browser-visual.R`]

## Explicit Non-Goals

- Full GIS topology repair, invalid polygon fixing, automatic hole inference, or polygon-overlap brushing. [VERIFIED: `51-CONTEXT.md`; `.planning/REQUIREMENTS.md`]
- Full ggrepel-compatible collision avoidance. [VERIFIED: `51-CONTEXT.md`; `.planning/REQUIREMENTS.md`]
- Broad path-following text placement. [VERIFIED: `51-CONTEXT.md`]
- CI-hosted screenshots, perceptual diffs, or committed golden images. [VERIFIED: `.planning/REQUIREMENTS.md`; `48-CONTEXT.md`]
- Broad renderer/IR architecture refactors beyond local geometry fixes. [VERIFIED: `51-CONTEXT.md`]
- JavaScript CRS reprojection, tile basemaps, slippy controls, or map-engine behavior. [VERIFIED: `.planning/PROJECT.md`; `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ggplot2 behavior truth | Custom transform/censoring semantics | `ggplot2::ggplot_build()` fixture comparison | ggplot2 is the ground truth for built rows and transformed scales. [VERIFIED: existing tests] |
| Rect/tile transformed-scale scale math | New ad hoc JS transform layer | Existing IR scale metadata + D3 scales | Scale creation already supports log/sqrt/reverse/symlog. [VERIFIED: `R/ir_scale_helpers.R`; `inst/htmlwidgets/modules/scales.js:129-199`] |
| Polygon topology repair | Custom GIS repair/validity engine | Existing grouped SVG path contract, or sf pipeline for real spatial geometry | Phase scope forbids GIS repair and ordinary polygon is not `geom_sf()`. [VERIFIED: `51-CONTEXT.md`] |
| Text collision avoidance | Custom ggrepel clone | Classify and defer to FUT-05 | Full collision placement is a future requirement, not Phase 51. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Browser visual report | New artifact framework | Existing `helper-browser-visual.R` | Phase 48 already created skip/artifact/index behavior. [VERIFIED: `helper-browser-visual.R`] |

## Open Questions

1. **Should `subgroup` be added to ordinary non-sf IR?**
   - What we know: ggplot2 documents `subgroup` holes, and gg2d3 currently drops `subgroup`. [CITED: ggplot2 docs; VERIFIED: `R/ir_layer_helpers.R:16-27`]
   - What's unclear: Whether adding `subgroup` without compound-path rendering would create misleading partial support. [ASSUMED]
   - Recommendation: First classify ggplot2 built data and document unsupported holes unless both IR and renderer changes remain small.

2. **Which text/label improvement is small enough?**
   - What we know: ordinary text ignores alignment/angle/style; sf annotation renderer already has local helpers. [VERIFIED: `text.js`; `sf.js`]
   - What's unclear: Whether `geom_label()` boxes can be added without update/interactivity/visual drift. [ASSUMED]
   - Recommendation: Prefer ordinary `geom_text()` hjust/vjust/angle/style parity; defer label boxes if they require new grouped SVG structure.

3. **Can transformed rect/tile browser evidence run locally?**
   - What we know: `chromote` is installed locally, but browser availability was not probed during this read-only research; `{sf}` is missing. [VERIFIED: local package audit]
   - What's unclear: Whether Chrome/Chromium launches in the implementer environment. [VERIFIED: not checked]
   - Recommendation: Plan browser visual smoke as optional and record skip/pass outcome in `51-VALIDATION.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript | All tests | yes | 4.6.0 | none needed |
| ggplot2 | Built-data classification | yes | 4.0.3 | none needed |
| testthat | Automated tests | yes | 3.3.2 | none needed |
| pkgload | Direct test-file commands | yes | 1.5.2 | `devtools::load_all()` |
| chromote | Optional browser visual smoke | yes | 0.5.1 | skip with message if browser unavailable |
| sf | sf annotation fixtures/browser evidence | no | - | skip sf-specific tests |
| geojsonsf | sf serialization when sf exists | yes | 2.0.5 | skip sf-specific tests if unavailable |
| crosstalk | Polygon interactivity/crosstalk tests | yes | 1.2.2 | skip or source-only coverage if unavailable |

**Missing dependencies with no fallback:** None for Phase 51 core GEOM-01/02/03 source and IR classification. [VERIFIED: local package audit]

**Missing dependencies with fallback:** `{sf}` is missing; use existing `skip_if_not_installed("sf")` and record skip evidence for sf annotation/browser cases. [VERIFIED: local package audit; existing sf tests]

## Security Domain

Phase 51 does not add authentication, sessions, authorization, storage, cryptography, or network calls. [VERIFIED: phase scope; source targets] The relevant safety concern is public interaction payload hygiene: polygon and sf private renderer fields must remain underscore-prefixed and sanitized before tooltip/event/brush exposure. [VERIFIED: `tests/testthat/test-polygon-interactivity.R`; `tests/testthat/test-renderer-wiring-contracts.R`; `50-03-SUMMARY.md`]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth surface. [VERIFIED: phase scope] |
| V3 Session Management | no | No session surface. [VERIFIED: phase scope] |
| V4 Access Control | no | No protected resources. [VERIFIED: phase scope] |
| V5 Input Validation | yes | Validate IR and sanitize public payload fields. [VERIFIED: `validate_ir.R`; `public-data.js` from Phase 50] |
| V6 Cryptography | no | No crypto surface. [VERIFIED: phase scope] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/51-geometry-edge-case-classification-and-polish/51-CONTEXT.md` - locked decisions, non-goals, validation evidence policy.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/RETROSPECTIVE.md`, `.planning/STATE.md` - milestone scope, GEOM-01/02/03, prior lessons.
- `CLAUDE.md` and `/Users/davidzenz/.codex/RTK.md` - project commands and command-prefix rule.
- `R/as_d3_ir.R`, `R/ir_scale_helpers.R`, `R/ir_layer_helpers.R`, `R/sf_utils.R` - R/IR extraction and helper boundaries.
- `inst/htmlwidgets/modules/geoms/rect.js`, `polygon.js`, `text.js`, `sf.js`, `inst/htmlwidgets/modules/geom-registry.js` - D3 renderer/update seams.
- Existing tests named in the user request plus `test-sf-annotations-renderer.R`, `test-sf-annotations-interactivity.R`, `test-ir-helper-boundaries.R`, and browser visual helpers.
- `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md` - prior rect/tile classification and transformed-scale skip.
- `.planning/phases/50-renderer-wiring-and-interaction-contracts/50-03-SUMMARY.md` - Phase 50 public sanitizer and validation readiness.

### Secondary (MEDIUM confidence)

- ggplot2 official docs for `geom_polygon()` hole/subgroup semantics: `https://ggplot2.tidyverse.org/reference/geom_polygon.html`.
- ggplot2 official docs for `geom_text()` / `geom_label()` aesthetics and label behavior: `https://ggplot2.tidyverse.org/reference/geom_text.html`.

### Assumptions (LOW confidence)

- Exact fixture names and artifact filenames are left to the planner. [ASSUMED]
- Ordinary `geom_text()` alignment/style is likely smaller than ordinary `geom_label()` box parity. [ASSUMED]
- Exact invalid/self-crossing polygon fixture shape should be selected during planning. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from DESCRIPTION and local package audit.
- Architecture: HIGH - verified from source files and prior phase artifacts.
- Rect/tile recommendations: MEDIUM - seams are verified, but transformed visual outcomes need new fixtures.
- Polygon recommendations: HIGH for current grouped-path behavior, MEDIUM for subgroup/hole outcome until classified against ggplot2 built data.
- Text/label recommendations: MEDIUM - current gaps are verified, but best tiny improvement must be confirmed by tests.

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 for codebase-local findings; recheck ggplot2 docs/package versions if dependencies change.

## RESEARCH COMPLETE
