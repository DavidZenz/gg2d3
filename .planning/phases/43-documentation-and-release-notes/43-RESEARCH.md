# Phase 43: Documentation And Release Notes - Research

**Researched:** 2026-05-23 [VERIFIED: system date]
**Domain:** R package documentation, release notes, and release-gate evidence synthesis [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: repo planning artifacts and release-facing source/docs listed in Sources]

## User Constraints

- Do not modify package behavior. [VERIFIED: user prompt]
- Do not reopen ordinary `geom_polygon()` or broad rect/tile renderer work; preserve those as documented deferred non-blockers unless new evidence contradicts them. [VERIFIED: user prompt; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
- Keep browser validation optional and R/testthat/chromote based; do not introduce Playwright/Puppeteer/Selenium/screenshot-diff requirements for v1.10. [VERIFIED: user prompt; .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]

## Summary

Phase 43 is a release-facing documentation and evidence-synthesis phase, not a renderer or validation-infrastructure phase. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md] The shipped user-facing `geom_sf()` contract supports polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`) rows; unsupported, empty, invalid, or missing rows are skipped with warnings while accepted rows remain renderable. [VERIFIED: README.Rmd; vignettes/gg2d3.Rmd; vignettes/d3-drawing-diagnostics.md; R/sf_utils.R; man/extract_sf_geometries.Rd]

The stale-language risk is concentrated in release-facing narrative docs, not in generated Rd alone. [VERIFIED: `rtk rg` scan over README.Rmd README.md vignettes R man] `vignettes/gg2d3.Rmd` still says the supported geoms are "core Cartesian geoms below plus polygon-family `geom_sf()`" and labels the support contract as "v1.9", while Phase 43 and v1.10 docs should describe the current polygon/point/line contract without stale milestone language. [VERIFIED: vignettes/gg2d3.Rmd; .planning/REQUIREMENTS.md]

The release notes/checklist should reuse Phase 42 summaries rather than raw local logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md] The final Phase 42 result was `PASSED WITH EXPECTED OPTIONAL SKIPS`; the final `devtools::document(); devtools::build_readme(); devtools::test()` run passed with 817 passed, 40 skipped, and 6 warnings; the final `R CMD check --as-cran` passed with 4 NOTEs and no ERROR/WARNING. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md]

**Primary recommendation:** Execute exactly two Phase 43 plans: first sweep README/vignettes/roxygen/generated Rd language, then create a v1.10 release checklist/notes artifact sourced from Phase 42 gate evidence and Phase 41 deferred-risk classifications. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]

## Project Constraints (from CLAUDE.md)

- Use the existing R package workflow: `devtools::load_all()`, `devtools::document()`, `devtools::test()`, single-file `testthat::test_file()`, and `devtools::build_readme()`. [VERIFIED: CLAUDE.md]
- Keep the established architecture as R layer (`R/as_d3_ir.R`), IR layer, and D3 layer (`inst/htmlwidgets/gg2d3.js`). [VERIFIED: CLAUDE.md]
- D3 v7 is vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: CLAUDE.md]
- Known limitations include no legends or facets in the older CLAUDE.md snapshot, but current project docs and roadmap supersede that snapshot for shipped capabilities such as legends/facets and sf family expansion. [VERIFIED: CLAUDE.md; .planning/PROJECT.md]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | README, vignettes, diagnostics docs, roxygen source, and generated help consistently describe the shipped polygon/point/line `geom_sf()` contract, optional browser validation, map anti-features, and release-support status without stale milestone language. [VERIFIED: .planning/REQUIREMENTS.md] | Target `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, relevant roxygen sources in `R/`, and generated `man/*.Rd`; verify with source scans plus `devtools::document()` and `devtools::build_readme()`. [VERIFIED: repo scan; DESCRIPTION; CLAUDE.md] |
| DOC-02 | A v1.10 release checklist or notes artifact records checks run, residual risks, deferred non-blockers, and recommended next-milestone candidates. [VERIFIED: .planning/REQUIREMENTS.md] | Use `42-GATE-RUN.md`, `42-VALIDATION-GATE.md`, `42-VERIFICATION.md`, `41-DEBT-AUDIT.md`, and `PROJECT.md` as sources; avoid copying local logs into release docs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| User-facing documentation language | R package docs | Generated Rd/help | README/vignettes and roxygen source own wording; generated `man/*.Rd` must reflect roxygen output. [VERIFIED: README.Rmd; R/*.R; man/*.Rd] |
| Release checklist/notes | Planning/docs artifacts | R package docs | Phase 43 needs a release-facing artifact recording gate evidence and residual risks; it should source Phase 42 and Phase 41 artifacts. [VERIFIED: .planning/ROADMAP.md; .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |
| Optional browser validation contract | Test infrastructure | Documentation | Browser validation remains R/testthat/chromote based and optional; docs should describe this without making browser tooling mandatory. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md; tests/testthat/helper-browser-sf.R] |
| Residual-risk tracking | Planning/docs artifacts | User docs where relevant | Ordinary `geom_polygon()` and rect/tile out-of-bounds behavior are deferred non-blockers and should stay documented as such. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md; vignettes/d3-drawing-diagnostics.md] |

## Current Shipped `geom_sf()` Contract

| Contract Area | Current Contract |
|---------------|------------------|
| Accepted geometry families | `geom_sf()` accepts polygon-family (`POLYGON`, `MULTIPOLYGON`), point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`, `MULTILINESTRING`). [VERIFIED: R/sf_utils.R; README.Rmd; vignettes/gg2d3.Rmd; man/gg2d3.Rd] |
| DOM/rendering families | Polygon and line families render as SVG paths; point families render as SVG circle marks with `.geom-sf`, `.geom-sf-polygon`, `.geom-sf-line`, or `.geom-sf-point` classes. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js; vignettes/d3-drawing-diagnostics.md; tests/testthat/test-sf-renderer.R] |
| CRS behavior | Known CRS inputs are normalized to WGS84 in R before serialization; missing CRS emits `geom_sf layer has missing CRS; coordinates will be serialized as-is`. [VERIFIED: R/sf_utils.R; vignettes/gg2d3.Rmd; man/extract_sf_geometries.Rd] |
| Skipped-row diagnostics | Unsupported, empty, invalid, or missing geometries emit `geom_sf layer skipped %d unsupported, empty, invalid, or missing geometries`; diagnostics include accepted rows, skipped rows, skipped reason details, missing CRS flag, accepted geometry types/families, and unsupported geometry types. [VERIFIED: R/sf_utils.R; tests/testthat/test-sf-ir.R; tests/testthat/test-sf-utils.R] |
| Interactivity | Tooltip, hover, custom handlers, Shiny-style callbacks, and brush payloads use `.geom-sf` marks and sanitized source-row payloads. [VERIFIED: R/d3_tooltip.R; R/d3_hover.R; R/d3_handlers.R; R/d3_brush.R; tests/testthat/test-sf-interactivity.R] |
| Brush behavior | sf brushing uses representative `data-cx`/`data-cy` anchors, not true geometry-overlap intersection. [VERIFIED: R/d3_brush.R; inst/htmlwidgets/modules/brush.js; vignettes/d3-drawing-diagnostics.md] |
| Zoom behavior | `d3_zoom()` suppresses zoom for widgets containing `geom_sf()` layers and warns that `geom_sf` zoom is not supported yet. [VERIFIED: R/d3_zoom.R; man/d3_zoom.Rd; tests/testthat/test-zoom-brush.R] |
| Browser validation | Browser validation is optional and R/testthat/chromote based; it covers sf family interactivity, stacked overlays, faceted and empty panels, skipped rows, and zoom suppression when optional tooling is available. [VERIFIED: tests/testthat/test-sf-browser.R; tests/testthat/helper-browser-sf.R; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] |
| Map anti-features | gg2d3 does not provide tile basemaps, slippy map controls, JavaScript-side CRS reprojection, true geometry-overlap brushing, `GEOMETRYCOLLECTION` expansion, or large-map performance guarantees. [VERIFIED: vignettes/d3-drawing-diagnostics.md; R/gg2d3.R; man/gg2d3.Rd] |

## Stale Language Risks

| Risk | Evidence | Target Fix |
|------|----------|------------|
| Main vignette understates sf support as polygon-family only | `vignettes/gg2d3.Rmd` says "core Cartesian geoms below plus polygon-family `geom_sf()`". [VERIFIED: vignettes/gg2d3.Rmd] | Change to polygon-, point-, and line-family `geom_sf()` support. [VERIFIED: .planning/REQUIREMENTS.md] |
| Main vignette labels support contract as v1.9 | `vignettes/gg2d3.Rmd` says "The v1.9 `geom_sf()` support contract..." [VERIFIED: vignettes/gg2d3.Rmd] | Use milestone-neutral or v1.10 release wording, because Phase 43 ships v1.10 documentation polish. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md] |
| README has a capitalization/style issue around ordinary `geom_polygon()` | `README.Rmd` and `README.md` start the sentence with lowercase "ordinary geom_polygon()". [VERIFIED: README.Rmd; README.md] | Normalize wording while preserving the deferred non-blocker message. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] |
| Generated help must stay roxygen-derived | `man/*.Rd` files state "Please edit documentation in R/..."; manual Rd edits would be overwritten. [VERIFIED: man/gg2d3.Rd; man/d3_brush.Rd; man/extract_sf_geometries.Rd] | Edit roxygen in `R/*.R`, run `devtools::document()`, then review generated `man/*.Rd`. [VERIFIED: CLAUDE.md; DESCRIPTION] |
| Release evidence could leak local logs if copied directly | Phase 42 points to `/private/tmp/gg2d3.Rcheck/00check.log` and browser artifact patterns as local debug artifacts. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] | Release notes should summarize outcomes and reference artifact classes/paths, not paste local logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |

## Standard Stack

### Core

| Tool/Library | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Rscript/R | 4.6.0 | Runs package documentation and test commands. [VERIFIED: `rtk Rscript --version`] | Existing package workflow is R-based. [VERIFIED: CLAUDE.md] |
| devtools | 2.5.2 | Runs `document()`, `build_readme()`, `test()`, and package development helpers. [VERIFIED: local package version probe; CLAUDE.md] | Existing contributor workflow uses devtools commands. [VERIFIED: CLAUDE.md] |
| roxygen2 | 8.0.0 | Generates `man/*.Rd` and NAMESPACE from roxygen source. [VERIFIED: DESCRIPTION; local package version probe] | Generated help points back to `R/*.R`, so roxygen source is canonical. [VERIFIED: man/*.Rd] |
| testthat | 3.3.2 | Runs source/doc validation checks and existing package tests. [VERIFIED: DESCRIPTION; local package version probe] | `DESCRIPTION` declares testthat edition 3. [VERIFIED: DESCRIPTION] |
| knitr/rmarkdown | knitr 1.51; rmarkdown 2.31 | Builds README/vignettes. [VERIFIED: DESCRIPTION; local package version probe] | `DESCRIPTION` uses `VignetteBuilder: knitr`; README workflow uses `devtools::build_readme()`. [VERIFIED: DESCRIPTION; CLAUDE.md] |

### Supporting

| Tool/Library | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| chromote | 0.5.1 | Optional live browser smoke harness dependency. [VERIFIED: DESCRIPTION; local package version probe] | Mention as optional validation tooling only; do not make it a Phase 43 requirement. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| sf | NOT_INSTALLED locally | Optional spatial validation dependency for sf examples/tests. [VERIFIED: local package version probe; .planning/phases/42-release-validation-gate/42-GATE-RUN.md] | Keep examples/tests guarded and classify missing `sf` skips as expected when messages match the gate. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md] |
| geojsonsf | 2.0.5 | Optional sf serialization helper. [VERIFIED: DESCRIPTION; local package version probe] | Required by sf validation paths when `sf` examples/tests run. [VERIFIED: R/sf_utils.R; tests/testthat/helper-browser-sf.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| R/testthat/chromote optional browser smoke | Playwright, Puppeteer, Selenium, screenshot diffing | Out of scope for v1.10 and contrary to Phase 40/42 decisions. [VERIFIED: user prompt; .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] |
| Roxygen source edits plus generation | Manual `man/*.Rd` edits | Manual Rd edits conflict with generated-help workflow and will be overwritten. [VERIFIED: man/*.Rd; CLAUDE.md] |
| Phase-local release notes/checklist artifact | Raw `.Rcheck` log publication | Phase 42 says release notes should reuse summarized evidence and not publish local logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |

**Installation:** No new installation is recommended for Phase 43. [VERIFIED: .planning/REQUIREMENTS.md; user prompt]

## Architecture Patterns

### System Architecture Diagram

```text
Planning inputs + release-gate evidence
  -> Phase 43 plan 43-01 docs language sweep
     -> README.Rmd / vignettes / roxygen R source
     -> devtools::document() + devtools::build_readme()
     -> README.md + man/*.Rd generated consistency check
  -> Phase 43 plan 43-02 release checklist/notes
     -> summarize Phase 42 outcomes + Phase 41 deferred non-blockers
     -> record residual risks + next-milestone candidates
     -> source/doc scans confirm no stale or forbidden release language
```

All arrows above are documentation/evidence flow, not runtime package behavior changes. [VERIFIED: user prompt; .planning/ROADMAP.md]

### Recommended Project Structure

```text
.planning/phases/43-documentation-and-release-notes/
├── 43-RESEARCH.md                 # this artifact [VERIFIED: user prompt]
├── 43-01-PLAN.md                  # docs language sweep plan [VERIFIED: .planning/ROADMAP.md]
├── 43-02-PLAN.md                  # release checklist/notes plan [VERIFIED: .planning/ROADMAP.md]
└── 43-v1.10-release-notes.md      # recommended release checklist/notes output [ASSUMED]
```

### Pattern 1: Source-First Documentation Generation

**What:** Edit `README.Rmd` and roxygen source files first, then regenerate `README.md` and `man/*.Rd`. [VERIFIED: README.Rmd; man/*.Rd; CLAUDE.md]

**When to use:** Use for DOC-01 because README and generated help must be consistent. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

[VERIFIED: CLAUDE.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]

### Pattern 2: Evidence-Summarized Release Notes

**What:** Summarize final gate outcomes, expected skips, NOTEs, residual risks, and next candidates from planning artifacts rather than copying local command logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md]

**When to use:** Use for DOC-02 because the release checklist must record checks run and residual risks without leaking local logs. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/42-release-validation-gate/42-VERIFICATION.md]

**Example evidence bullets to preserve:**

```text
- Final full R gate: passed with 817 passed, 40 skipped, 6 warnings. [VERIFIED: 42-GATE-RUN.md]
- Final R CMD check --as-cran: passed with 4 NOTEs and no ERROR/WARNING. [VERIFIED: 42-GATE-RUN.md]
- Expected optional skips: missing sf, skip_on_cran browser smoke, default visual-test skip, empty crosstalk test. [VERIFIED: 42-GATE-RUN.md]
```

### Anti-Patterns to Avoid

- Reopening ordinary `geom_polygon()` renderer implementation in Phase 43 is out of scope. [VERIFIED: user prompt; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
- Rewriting rect/tile rendering during a docs phase is out of scope. [VERIFIED: user prompt; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
- Adding Node/browser stacks or screenshot-diff validation is out of scope for v1.10. [VERIFIED: user prompt; .planning/REQUIREMENTS.md]
- Editing only generated `README.md` or `man/*.Rd` without source updates creates drift. [VERIFIED: README.Rmd; man/*.Rd]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Documentation generation | Custom Rd or README generators | `devtools::document()` and `devtools::build_readme()` | Existing package workflow already standardizes these commands. [VERIFIED: CLAUDE.md] |
| Release validation evidence | New wrapper script or ad hoc log parser | Existing `42-VALIDATION-GATE.md`, `42-GATE-RUN.md`, and `42-VERIFICATION.md` | Phase 42 already records the gate, outcome, expected skips, and artifact interpretation. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |
| Browser validation | Playwright/Puppeteer/Selenium/screenshot diff | Existing optional R/testthat/chromote smoke harness | v1.10 requires optional browser validation and explicitly excludes those stacks. [VERIFIED: user prompt; .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| Residual-risk policy | New undocumented triage categories | Phase 41 `Deferred non-blocker` classifications | Phase 41 already classified ordinary `geom_polygon()` and rect/tile out-of-bounds debt with rationale and next steps. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] |

**Key insight:** Phase 43 should improve release truthfulness by aligning docs to already-validated behavior, not by changing package behavior or validation infrastructure. [VERIFIED: .planning/ROADMAP.md; user prompt]

## Common Pitfalls

### Pitfall 1: Source/Generated Doc Drift

**What goes wrong:** `README.md` or `man/*.Rd` is edited directly and then overwritten by generation. [VERIFIED: README.Rmd; man/*.Rd]
**Why it happens:** Generated files are checked into the repo, but their canonical sources are `README.Rmd` and roxygen comments. [VERIFIED: README.Rmd; man/*.Rd]
**How to avoid:** Edit sources first and run `devtools::document(); devtools::build_readme()`. [VERIFIED: CLAUDE.md]
**Warning signs:** `README.Rmd` and `README.md` disagree, or Rd files differ from `R/*.R` roxygen comments. [VERIFIED: repo scan]

### Pitfall 2: Overclaiming Browser Validation

**What goes wrong:** Release docs imply browser validation is mandatory or always executed. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md]
**Why it happens:** Phase 42 records browser smoke coverage and expected skips in the same gate. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md]
**How to avoid:** Say browser validation is optional and skips cleanly when CRAN-like, chromote, Chrome/Chromium, `sf`, or `geojsonsf` gates are unavailable. [VERIFIED: tests/testthat/helper-browser-sf.R; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]
**Warning signs:** Mentions of Playwright/Puppeteer/Selenium or screenshot-diff requirements in v1.10 docs. [VERIFIED: user prompt; .planning/REQUIREMENTS.md]

### Pitfall 3: Blurring `geom_sf()` Polygons With Ordinary `geom_polygon()`

**What goes wrong:** Documentation claims ordinary `geom_polygon()` support because `geom_sf()` polygon-family support exists. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
**Why it happens:** `GeomPolygon` maps into IR as `polygon`, but no ordinary polygon renderer is registered. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
**How to avoid:** Keep ordinary `geom_polygon()` documented as unsupported/deferred and explicitly separate it from supported `geom_sf()` polygon-family rendering. [VERIFIED: README.Rmd; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]
**Warning signs:** Supported geom tables include ordinary `geom_polygon`. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md]

### Pitfall 4: Publishing Local Logs As Release Notes

**What goes wrong:** Release notes contain machine-local `/private/tmp` logs or browser artifact contents. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md]
**Why it happens:** Phase 42 lists exact artifact paths for debugging. [VERIFIED: .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]
**How to avoid:** Summarize outcomes and reference artifact classes/paths only. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md]
**Warning signs:** Release notes paste `00check.log` contents or browser console/page-error logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]

## Code Examples

### Documentation Generation

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

[VERIFIED: CLAUDE.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]

### Fast DOC-01 Source Consistency Scan

```bash
rtk rg -n 'polygon-family `geom_sf\(\)`|The v1\.9 `geom_sf\(\)` support contract|Playwright|Puppeteer|Selenium|screenshot-diff|screenshot diff|visual diff' README.Rmd README.md vignettes R man
```

[VERIFIED: local `rtk rg` scan pattern]

### Fast DOC-02 Evidence Scan

```bash
rtk rg -n 'PASSED WITH EXPECTED OPTIONAL SKIPS|R CMD check --as-cran|4 NOTEs|Deferred non-blocker|ordinary geom_polygon|rect/tile out-of-bounds|Phase 43 Handoff' .planning/phases/42-release-validation-gate .planning/phases/41-release-blocking-debt-triage
```

[VERIFIED: local planning artifact scan pattern]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polygon-only `geom_sf()` release language | Polygon, point, and line family `geom_sf()` support language | v1.9 sf robustness/expansion, now v1.10 docs polish [VERIFIED: .planning/PROJECT.md; .planning/ROADMAP.md] | DOC-01 must remove stale polygon-only and stale v1.9 phrasing where it appears. [VERIFIED: .planning/REQUIREMENTS.md; vignettes/gg2d3.Rmd] |
| Optional browser behavior as scattered test detail | Documented optional browser/spatial skip contract | Phase 40/42 [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] | Release notes can classify missing `sf` and `skip_on_cran()` as expected optional skips when messages match. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md] |
| Renderer debt hidden in docs | Ordinary `geom_polygon()` and rect/tile edge cases classified as deferred non-blockers | Phase 41 [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] | Phase 43 should record residual risks and next candidates without implementation. [VERIFIED: user prompt; .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- Public wording that says support is only polygon-family `geom_sf()` is outdated for v1.10 docs. [VERIFIED: vignettes/gg2d3.Rmd; .planning/PROJECT.md]
- Public wording that frames the support contract as "v1.9" is stale in a v1.10 release-hardening checkpoint. [VERIFIED: vignettes/gg2d3.Rmd; .planning/ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript/R | Docs/tests/check commands | yes | 4.6.0 | none needed [VERIFIED: `rtk Rscript --version`] |
| devtools | README/docs/test generation | yes | 2.5.2 | direct roxygen2/testthat commands if needed [VERIFIED: local package probe] |
| roxygen2 | Rd generation | yes | 8.0.0 | none recommended [VERIFIED: local package probe] |
| testthat | fast source/doc checks | yes | 3.3.2 | none recommended [VERIFIED: local package probe; DESCRIPTION] |
| knitr | vignette/README support | yes | 1.51 | none recommended [VERIFIED: local package probe; DESCRIPTION] |
| rmarkdown | vignette/README support | yes | 2.31 | none recommended [VERIFIED: local package probe; DESCRIPTION] |
| chromote | optional browser smoke evidence | yes | 0.5.1 | expected optional skip if unavailable [VERIFIED: local package probe; .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| sf | optional sf examples/tests | no | NOT_INSTALLED | expected optional skip when explicit [VERIFIED: local package probe; .planning/phases/42-release-validation-gate/42-GATE-RUN.md] |
| geojsonsf | sf serialization/tests | yes | 2.0.5 | expected optional skip if unavailable [VERIFIED: local package probe; tests/testthat/helper-browser-sf.R] |

**Missing dependencies with no fallback:**
- None for Phase 43 documentation research and planning. [VERIFIED: local environment probe; .planning/REQUIREMENTS.md]

**Missing dependencies with fallback:**
- `sf` is not installed locally; existing sf and browser paths skip explicitly, and Phase 42 classified missing `sf` as expected optional evidence. [VERIFIED: local package probe; .planning/phases/42-release-validation-gate/42-GATE-RUN.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 with R 4.6.0 [VERIFIED: local package probe; `rtk Rscript --version`] |
| Config file | `DESCRIPTION` with `Config/testthat/edition: 3` [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` [VERIFIED: CLAUDE.md; .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` [VERIFIED: .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOC-01 | Release-facing docs and generated help describe polygon/point/line `geom_sf()`, optional browser validation, map anti-features, and no stale milestone language. [VERIFIED: .planning/REQUIREMENTS.md] | source/doc generation | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` plus `rtk rg -n 'polygon-family `geom_sf\\(\\)`|The v1\\.9 `geom_sf\\(\\)` support contract|Playwright|Puppeteer|Selenium|screenshot-diff|screenshot diff|visual diff' README.Rmd README.md vignettes R man` [VERIFIED: local scan pattern] | yes [VERIFIED: README.Rmd; vignettes/gg2d3.Rmd; R/*.R; man/*.Rd] |
| DOC-02 | Release checklist/notes records checks run, residual risks, deferred non-blockers, and next-milestone candidates. [VERIFIED: .planning/REQUIREMENTS.md] | source/doc scan | `rtk rg -n 'PASSED WITH EXPECTED OPTIONAL SKIPS|R CMD check --as-cran|4 NOTEs|Deferred non-blocker|ordinary geom_polygon|rect/tile out-of-bounds|next-milestone' .planning/phases/43-documentation-and-release-notes .planning/phases/42-release-validation-gate .planning/phases/41-release-blocking-debt-triage` [VERIFIED: planning artifact scan pattern] | target file missing until 43-02 [VERIFIED: phase directory listing] |

### Sampling Rate

- **Per task commit:** Run the DOC-specific source/doc scans and generation command for touched docs. [VERIFIED: .planning/REQUIREMENTS.md; CLAUDE.md]
- **Per wave merge:** Run `devtools::document(); devtools::build_readme(); devtools::test()` if roxygen, README, or vignette code chunks changed. [VERIFIED: .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]
- **Phase gate:** Use the Phase 42 full release gate command sequence if Phase 43 changes materially affect generated docs or examples. [VERIFIED: .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md]

### Wave 0 Gaps

- [ ] Create the DOC-02 release checklist/notes artifact in `.planning/phases/43-documentation-and-release-notes/`. [VERIFIED: phase directory listing; .planning/REQUIREMENTS.md]
- [ ] Add no new validation framework; existing testthat/devtools commands cover this phase. [VERIFIED: DESCRIPTION; CLAUDE.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 43 does not add authentication behavior. [VERIFIED: .planning/REQUIREMENTS.md; user prompt] |
| V3 Session Management | no | Phase 43 does not add session behavior. [VERIFIED: .planning/REQUIREMENTS.md; user prompt] |
| V4 Access Control | no | Phase 43 does not add access-control behavior. [VERIFIED: .planning/REQUIREMENTS.md; user prompt] |
| V5 Input Validation | yes, documentation accuracy only | Use source scans and generated-doc checks to prevent misleading user-facing claims. [VERIFIED: .planning/REQUIREMENTS.md] |
| V6 Cryptography | no | Phase 43 does not add cryptographic behavior. [VERIFIED: .planning/REQUIREMENTS.md; user prompt] |

### Known Threat Patterns for Documentation/Release Notes

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading support claims | Tampering/Repudiation | Cross-check README/vignettes/Rd against source and Phase 41/42 evidence. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] |
| Local log leakage | Information Disclosure | Summarize outcomes and reference artifact paths without embedding local logs. [VERIFIED: .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |

## Planning Recommendations

1. **43-01 docs language sweep** - Update `README.Rmd`, regenerate `README.md`, update `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md` if needed, and roxygen sources in `R/gg2d3.R`, `R/sf_utils.R`, `R/d3_tooltip.R`, `R/d3_hover.R`, `R/d3_handlers.R`, `R/d3_brush.R`, and `R/d3_zoom.R` only where wording is stale or incomplete. [VERIFIED: .planning/ROADMAP.md; repo scan] Verify with `devtools::document(); devtools::build_readme()` and source scans for stale v1.9/polygon-only/browser-stack language. [VERIFIED: CLAUDE.md; .planning/REQUIREMENTS.md]
2. **43-02 v1.10 release checklist/notes** - Create a phase-local release checklist/notes artifact, recommended path `.planning/phases/43-documentation-and-release-notes/43-v1.10-release-notes.md`, summarizing Phase 42 checks run, final `R CMD check --as-cran` result, expected optional skips, 4 retained NOTEs, Phase 41 deferred non-blockers, residual risks, and next-milestone candidates. [VERIFIED: .planning/ROADMAP.md; .planning/phases/42-release-validation-gate/42-GATE-RUN.md; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] The artifact path is recommended, not pre-existing. [ASSUMED]

## Target Files And Verification Commands

| Plan | Target Files | Verification Commands |
|------|--------------|-----------------------|
| 43-01 | `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, relevant roxygen in `R/*.R`, generated `man/*.Rd`. [VERIFIED: .planning/REQUIREMENTS.md; repo scan] | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'`; `rtk rg -n 'polygon-family `geom_sf\\(\\)`|The v1\\.9 `geom_sf\\(\\)` support contract|Playwright|Puppeteer|Selenium|screenshot-diff|screenshot diff|visual diff' README.Rmd README.md vignettes R man`; `rtk rg -n 'POLYGON|MULTIPOLYGON|POINT|MULTIPOINT|LINESTRING|MULTILINESTRING|optional browser|chromote|map anti-features|ordinary geom_polygon' README.Rmd README.md vignettes R man`. [VERIFIED: local scan patterns] |
| 43-02 | `.planning/phases/43-documentation-and-release-notes/43-v1.10-release-notes.md` or equivalent phase-local release artifact. [ASSUMED] | `rtk rg -n 'PASSED WITH EXPECTED OPTIONAL SKIPS|817 passed|40 skipped|6 warnings|4 NOTEs|no ERROR/WARNING|Deferred non-blocker|ordinary geom_polygon|rect/tile out-of-bounds|next-milestone' .planning/phases/43-documentation-and-release-notes`; `rtk rg -n '/private/tmp/gg2d3.Rcheck/00check.log|test_output/browser-sf' .planning/phases/43-documentation-and-release-notes` should show only path references, not pasted log contents. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md; .planning/phases/42-release-validation-gate/42-VERIFICATION.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The release checklist/notes artifact should be named `.planning/phases/43-documentation-and-release-notes/43-v1.10-release-notes.md`. | Planning Recommendations; Target Files | Planner may choose a different phase-local filename, but DOC-02 can still be satisfied if the artifact records the required content. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should the release checklist also be copied into a root-level `NEWS.md`?** [ASSUMED]
   What we know: DOC-02 requires a v1.10 checklist or notes artifact, but does not name `NEWS.md`. [VERIFIED: .planning/REQUIREMENTS.md]
   What's unclear: The repo currently has no root `NEWS.md` in the scanned release-facing file list. [VERIFIED: user prompt file list; repo scan]
   Resolution: Keep the required artifact phase-local for v1.10. Do not create a package-level `NEWS.md` in Phase 43 unless the user explicitly asks for it later. [ASSUMED]

2. **RESOLVED: Should final Phase 43 rerun the full Phase 42 gate?** [ASSUMED]
   What we know: Phase 42 already passed the full gate with expected optional skips. [VERIFIED: .planning/phases/42-release-validation-gate/42-GATE-RUN.md]
   What's unclear: Phase 43 may only change prose, but roxygen/example/vignette changes can affect generated docs. [VERIFIED: CLAUDE.md]
   Resolution: Require docs generation and DOC-01/DOC-02 source scans during execution. Reuse Phase 42 full-gate evidence unless Phase 43 materially changes executable examples, tests, or behavior; if that happens, rerun the relevant Phase 42 gate tier. [ASSUMED]

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md` - Phase 43 goal, expected plans, and success criteria. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - DOC-01/DOC-02 and v1.10 exclusions. [VERIFIED: file read]
- `.planning/PROJECT.md` - v1.10 context, known tech debt, decisions. [VERIFIED: file read]
- `.planning/STATE.md` - current phase state and recent decisions. [VERIFIED: file read]
- `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md` - release gate commands, skip contract, artifacts. [VERIFIED: file read]
- `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` - final gate evidence and check outcomes. [VERIFIED: file read]
- `.planning/phases/42-release-validation-gate/42-VERIFICATION.md` - Phase 43 handoff and evidence reuse rules. [VERIFIED: file read]
- `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md` - deferred non-blocker classifications. [VERIFIED: file read]
- `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/*.R`, `man/*.Rd`, `DESCRIPTION` - release-facing docs/source/help. [VERIFIED: file reads and `rtk rg` scans]

### Secondary (MEDIUM confidence)

- Local environment probes for R and package versions. [VERIFIED: `rtk Rscript --version`; local package version probe]

### Tertiary (LOW confidence)

- Filename recommendation for the DOC-02 artifact. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and workflow were verified from local probes, DESCRIPTION, and CLAUDE.md. [VERIFIED: local package probe; DESCRIPTION; CLAUDE.md]
- Architecture: HIGH - Phase 43 is documentation/evidence flow over existing R package docs and planning artifacts. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
- Pitfalls: HIGH - stale wording and deferred risks were found directly in release-facing docs and Phase 41/42 evidence. [VERIFIED: repo scan; .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md; .planning/phases/42-release-validation-gate/42-GATE-RUN.md]

**Research date:** 2026-05-23 [VERIFIED: system date]
**Valid until:** 2026-06-22 unless Phase 43 or package validation evidence changes first. [ASSUMED]

## RESEARCH COMPLETE
