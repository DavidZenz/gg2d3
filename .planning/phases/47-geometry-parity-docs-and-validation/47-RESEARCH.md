# Phase 47: Geometry Parity Docs And Validation - Research

**Researched:** 2026-05-25 [VERIFIED: local date]
**Domain:** R package documentation, generated roxygen/help artifacts, and geometry validation evidence for gg2d3 v1.11 [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
**Confidence:** HIGH [VERIFIED: local repository inspection]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
The following locked decisions are copied from `.planning/phases/47-geometry-parity-docs-and-validation/47-CONTEXT.md`. [VERIFIED: 47-CONTEXT.md]

#### Public Support Wording
- **D-01:** Use a balanced support table or equivalent structured wording in public docs: mark v1.11 polygon, rect/tile, and sf annotation features as supported while keeping limitations visible next to the support statement.
- **D-02:** Avoid both over-cautious stale wording and broad "everything matches ggplot2" claims. The docs should say what is supported, what evidence backs it, and where exact parity remains deferred.
- **D-03:** Replace now-stale statements that ordinary `geom_polygon()` lacks a renderer and that `geom_sf_text()` / `geom_sf_label()` are unsupported.

#### Validation Evidence Shape
- **D-04:** Record validation evidence as a feature matrix mapping each geometry area to representative test files, useful commands, browser smoke coverage, and skip semantics.
- **D-05:** The matrix should distinguish source/IR/unit coverage from optional browser DOM smoke coverage. Optional skips are acceptable when local dependencies such as `sf`, `chromote`, or Chrome are unavailable, but the notes should explain what the skipped tests would cover.
- **D-06:** Keep the validation notes representative rather than exhaustive. Link the important tests and smoke fixtures; do not turn the docs into a full test index.

#### Deferred Scope Placement
- **D-07:** Put concise limitations in README, vignettes, and help pages where users encounter support claims.
- **D-08:** Put detailed caveats and residual risks in `vignettes/d3-drawing-diagnostics.md`, then link or reference that diagnostics doc from concise public notes.
- **D-09:** Keep future/deferred geometry items explicit: polygon topology/hole repair beyond the supported grouped-path contract, full rect/tile transformed-scale edge parity, tile basemaps, slippy controls, JavaScript-side CRS reprojection, ggrepel collision avoidance, rich text, rotation parity, and path-following annotation placement are not shipped by Phase 47.

#### Generated Documentation Policy
- **D-10:** Update source docs first: `README.Rmd`, vignettes, and roxygen comments.
- **D-11:** Regenerate generated artifacts in this phase when sources change, including `README.md` and affected `man/*.Rd`.
- **D-12:** Do not manually patch generated help as the primary source of truth. If a generated file needs different wording, change its roxygen source and regenerate.

### Claude's Discretion
The following discretion items are copied from `.planning/phases/47-geometry-parity-docs-and-validation/47-CONTEXT.md`. [VERIFIED: 47-CONTEXT.md]

- Planners may choose the exact layout of support tables and validation matrices as long as the feature-to-evidence mapping is easy to scan.
- Planners may decide whether validation notes live in a dedicated new file, in diagnostics, or both, provided the roadmap success criteria are covered and canonical docs link to the evidence.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCVAL-01 | README, vignettes, diagnostics docs, roxygen source, generated help, and validation notes describe the v1.11 ordinary polygon, rect/tile edge, and sf annotation support contract with representative tests or browser smoke coverage. [VERIFIED: .planning/REQUIREMENTS.md] | Use source-first docs regeneration, stale-claim grep checks, and a representative validation matrix tied to existing Phase 44-46 tests and optional browser smoke files. [VERIFIED: 47-CONTEXT.md; tests/testthat/test-polygon-browser.R; tests/testthat/test-rect-tile-ir.R; tests/testthat/test-sf-annotations-browser.R] |
</phase_requirements>

## Summary

Phase 47 should be planned as documentation and evidence work, not renderer work. The prior phases already shipped ordinary `geom_polygon()`, rect/tile edge closure, and `geom_sf_text()` / `geom_sf_label()` support; this phase must reconcile public docs, roxygen source, generated README/help, diagnostics, and validation notes with that shipped contract. [VERIFIED: .planning/ROADMAP.md; .planning/PROJECT.md; 47-CONTEXT.md]

The current documentation still contains stale claims that Phase 47 must remove: `README.Rmd` and generated `README.md` say ordinary `geom_polygon()` lacks a D3 renderer, the main vignette still includes an unsupported ordinary polygon example, and diagnostics says `geom_sf_text()` and `geom_sf_label()` are unsupported. [VERIFIED: README.Rmd; README.md; vignettes/gg2d3.Rmd; vignettes/d3-drawing-diagnostics.md]

**Primary recommendation:** Plan `47-01` as the source-first docs sweep plus regeneration, and plan `47-02` as a maintainer-facing validation evidence artifact plus diagnostics residual-risk update. [VERIFIED: .planning/ROADMAP.md; 47-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Use the established three-layer package architecture: R extraction in `R/as_d3_ir.R`, JSON-serializable IR, and D3 SVG rendering under `inst/htmlwidgets/`. [VERIFIED: AGENTS.md]
- Use the documented development commands: `devtools::load_all()`, `devtools::document()`, `devtools::test()`, single-file `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: AGENTS.md; README.Rmd]
- Keep D3 v7 vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`; Phase 47 should not add remote runtime dependencies. [VERIFIED: AGENTS.md; inst/htmlwidgets/gg2d3.yaml]
- Respect documented limitations: no legends/facets/polygon/path behavior should be claimed beyond the current support contract unless already implemented and tested. [VERIFIED: AGENTS.md; vignettes/d3-drawing-diagnostics.md]
- Shell commands in this repository should be prefixed with `rtk`. [VERIFIED: /Users/davidzenz/.codex/RTK.md]
- No project-specific `.claude/skills/` or `.agents/skills/` directory was present; `.claude/` exists only with launch/worktree artifacts. [VERIFIED: local `rg --files .claude/skills .agents/skills`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public support wording | Documentation / R package source | Generated artifacts | `README.Rmd`, vignettes, and roxygen comments own the truth; `README.md` and `man/*.Rd` are regenerated outputs. [VERIFIED: 47-CONTEXT.md; README.Rmd] |
| Generated help synchronization | R package documentation tooling | Generated artifacts | `devtools::document()` updates roxygen-generated help, and `devtools::build_readme()` updates `README.md`. [VERIFIED: AGENTS.md; README.Rmd] |
| Validation evidence notes | Planning/docs artifacts | Test suite | Evidence should link representative tests and browser smoke rather than duplicate every test case. [VERIFIED: 47-CONTEXT.md] |
| Optional browser/spatial smoke interpretation | Test suite | Local environment | Browser and sf checks are optional and skip through testthat helpers when `sf`, `chromote`, `geojsonsf`, or Chrome are absent. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| R | 4.6.0 local | Package runtime and docs/test execution. [VERIFIED: local Rscript version probe] | Existing gg2d3 package is an R package. [VERIFIED: DESCRIPTION] |
| devtools | 2.5.2 local | `load_all()`, `document()`, `test()`, and `build_readme()` workflows. [VERIFIED: local Rscript version probe; AGENTS.md] | Project docs list devtools commands as the maintainer workflow. [VERIFIED: AGENTS.md; README.Rmd] |
| roxygen2 | 8.0.0 local | Generate `man/*.Rd` from roxygen source. [VERIFIED: local Rscript version probe; DESCRIPTION] | DESCRIPTION records `Config/roxygen2/version: 8.0.0`. [VERIFIED: DESCRIPTION] |
| testthat | 3.3.2 local | Run focused validation files. [VERIFIED: local Rscript version probe] | DESCRIPTION uses testthat edition 3 and Suggests `testthat (>= 3.0.0)`. [VERIFIED: DESCRIPTION] |
| pkgload | 1.5.2 local | Load package before direct `test_file()` runs. [VERIFIED: local Rscript version probe] | Existing tests and phase plans use `pkgload::load_all(quiet=TRUE)` before focused tests. [VERIFIED: tests/testthat/test-polygon-ir.R; 46-VERIFICATION.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| rmarkdown | 2.31 local | Vignette/README rendering support. [VERIFIED: local Rscript version probe; DESCRIPTION] | Use indirectly through `devtools::build_readme()` and vignette tooling. [VERIFIED: README.Rmd; DESCRIPTION] |
| knitr | 1.51 local | Render R Markdown chunks. [VERIFIED: local Rscript version probe; DESCRIPTION] | Use for README/vignette source rendering. [VERIFIED: README.Rmd; DESCRIPTION] |
| htmlwidgets | 1.6.4 local | Widget output and browser smoke fixture saving. [VERIFIED: local Rscript version probe; DESCRIPTION] | Required by package runtime and browser smoke fixtures. [VERIFIED: DESCRIPTION; tests/testthat/helper-browser-sf.R] |
| chromote | 0.5.1 local | Optional browser DOM smoke execution. [VERIFIED: local Rscript version probe] | Use only for optional browser smoke; skip cleanly on CRAN or browser launch failure. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| Chrome/Chromium | Google Chrome app found locally | Browser target for chromote smoke. [VERIFIED: local Rscript `chromote::find_chrome()` probe] | Required only when running optional live browser smoke. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| sf | missing locally | Spatial fixtures for sf annotation tests. [VERIFIED: local Rscript package probe] | Required by sf annotation IR/browser tests; absence should produce explicit test skips. [VERIFIED: tests/testthat/test-sf-annotations-ir.R; tests/testthat/helper-browser-sf.R] |
| geojsonsf | 2.0.5 local | sf GeoJSON serialization. [VERIFIED: local Rscript version probe] | Required by sf extraction and sf annotation tests. [VERIFIED: R/sf_utils.R; tests/testthat/test-sf-annotations-ir.R] |
| crosstalk | 1.2.2 local | Optional linked-view/crosstalk polygon validation. [VERIFIED: local Rscript version probe] | Required by polygon crosstalk smoke branch. [VERIFIED: tests/testthat/test-polygon-browser.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Source-first roxygen and README regeneration | Manual edits to `README.md` and `man/*.Rd` | Rejected by D-12 because generated files must not be patched as the primary source of truth. [VERIFIED: 47-CONTEXT.md] |
| Existing testthat/chromote browser smoke | Playwright, Puppeteer, Selenium, screenshot diff, or vdiffr | Rejected for this phase because prior phase contracts use source/DOM assertions and explicitly avoid screenshot/perceptual tooling. [VERIFIED: 45-CONTEXT.md; 46-03-PLAN.md] |
| Representative validation matrix | Full exhaustive test index | Rejected by D-06; docs should link important tests and smoke fixtures, not duplicate the test suite. [VERIFIED: 47-CONTEXT.md] |

**Installation:** No new packages should be added for Phase 47. [VERIFIED: 47-CONTEXT.md; DESCRIPTION]

**Version verification:** Package/tool versions above were verified from the local R library with `rtk Rscript --vanilla -e ...`; the research does not claim registry-current versions. [VERIFIED: local Rscript package probe]

## Architecture Patterns

### System Architecture Diagram

```text
Docs/support contract inputs
  |
  v
Source docs: README.Rmd + vignettes + roxygen comments
  |         \
  |          \-- diagnostics/residual-risk notes
  v
Generated artifacts: README.md + man/*.Rd
  |
  v
Validation evidence matrix
  |
  +--> IR/source/unit tests for polygon, rect/tile, sf annotations
  |
  +--> Optional browser DOM smoke for polygon and sf annotations
  |
  v
Planner/executor verification: grep stale claims + run focused tests + inspect generated diffs
```

This diagram reflects the source-first generation boundary and evidence flow required by Phase 47. [VERIFIED: 47-CONTEXT.md; AGENTS.md]

### Recommended Project Structure

```text
.planning/phases/47-geometry-parity-docs-and-validation/
├── 47-RESEARCH.md                 # this research artifact
├── 47-01-PLAN.md                  # source docs + generated docs sweep
├── 47-02-PLAN.md                  # validation evidence + residual risks
├── 47-VALIDATION.md               # recommended validation matrix artifact
└── 47-VERIFICATION.md             # execution result, if planner keeps phase pattern

README.Rmd                         # source README support table/contract
README.md                          # generated README
vignettes/gg2d3.Rmd                # main user vignette
vignettes/gg2d3-interactivity.Rmd  # interaction caveats
vignettes/d3-drawing-diagnostics.md# detailed caveats and residual risk
R/*.R                              # roxygen source
man/*.Rd                           # generated help
```

The phase should prefer a small `.planning/.../47-VALIDATION.md` evidence artifact and concise links from user docs to diagnostics. [VERIFIED: 47-CONTEXT.md; prior 42-VALIDATION-GATE.md pattern]

### Pattern 1: Source-First Documentation Update

**What:** Edit `README.Rmd`, vignettes, and roxygen comments first; regenerate `README.md` and affected `man/*.Rd` afterward. [VERIFIED: 47-CONTEXT.md; AGENTS.md]

**When to use:** Every time public wording or help text changes in this phase. [VERIFIED: 47-CONTEXT.md]

**Example:**

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

The README source itself notes that `README.md` is generated from `README.Rmd` and should be re-rendered with `devtools::build_readme()`. [VERIFIED: README.Rmd]

### Pattern 2: Stale Claim Sweep Before and After Regeneration

**What:** Use targeted `rg` checks for claims that now contradict v1.11 support. [VERIFIED: local rg over README.Rmd README.md vignettes R man]

**When to use:** Before planning edits to scope work, and after regeneration to prove stale wording did not survive in generated artifacts. [VERIFIED: 47-CONTEXT.md]

**Example:**

```bash
rtk rg -n 'does not currently have a D3 renderer|no renderer is registered|geom_sf_text\(\).*not supported|geom_sf_label\(\).*not supported' README.Rmd README.md vignettes R man
```

Current matches include README source/generated stale ordinary polygon wording and diagnostics stale sf annotation wording. [VERIFIED: README.Rmd; README.md; vignettes/d3-drawing-diagnostics.md]

### Pattern 3: Representative Feature-to-Evidence Matrix

**What:** Create a compact validation matrix mapping each shipped geometry area to source/IR/unit coverage, optional browser smoke coverage, useful commands, skip semantics, and residual risks. [VERIFIED: 47-CONTEXT.md]

**When to use:** Plan `47-02` should produce this as the central maintainer-facing evidence artifact. [VERIFIED: .planning/ROADMAP.md; 47-CONTEXT.md]

**Example row shape:**

```markdown
| Geometry area | Source/IR/unit evidence | Browser smoke | Skip semantics | Residual risk |
|---------------|-------------------------|---------------|----------------|---------------|
| Ordinary polygons | tests/testthat/test-polygon-ir.R; test-polygon-renderer.R; test-polygon-interactivity.R | tests/testthat/test-polygon-browser.R | chromote/Chrome optional | topology/hole repair deferred |
```

This matches D-04 through D-06 and avoids turning docs into a full test index. [VERIFIED: 47-CONTEXT.md]

### Anti-Patterns to Avoid

- **Manual generated-file-only edits:** They will drift from roxygen/README source and violate D-12. [VERIFIED: 47-CONTEXT.md]
- **Overclaiming exact ggplot2 parity:** D-02 requires balanced support wording with evidence and limitations. [VERIFIED: 47-CONTEXT.md]
- **Adding new renderer behavior during docs validation:** Phase 47 is explicitly documentation/evidence work and does not add behavior. [VERIFIED: 47-CONTEXT.md]
- **Introducing screenshot/perceptual/browser tooling:** Prior v1.11 validation uses IR/source/DOM assertions and rejects screenshot/perceptual tooling for this scope. [VERIFIED: 45-CONTEXT.md; 46-03-PLAN.md]
- **Collapsing optional skips into failures:** Browser/spatial checks are designed to skip cleanly when optional local dependencies are unavailable. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| R help generation | Manual `.Rd` authoring | roxygen comments plus `devtools::document()` | Generated help is source-owned by roxygen in this project. [VERIFIED: 47-CONTEXT.md; DESCRIPTION] |
| README generation | Manual `README.md` edits | `README.Rmd` plus `devtools::build_readme()` | README source states generated README policy. [VERIFIED: README.Rmd] |
| Browser smoke harness | New Node/browser runner | Existing testthat/chromote helpers | Project already has CRAN-compatible skip helpers and DOM assertion patterns. [VERIFIED: tests/testthat/helper-browser-sf.R; tests/testthat/helper-browser-polygon.R] |
| Full test inventory docs | Exhaustive duplicated index | Representative evidence matrix | D-06 requires representative links only. [VERIFIED: 47-CONTEXT.md] |
| Geometry parity claims | Broad prose promises | Structured support table with adjacent limitations | D-01 and D-02 require supported scope plus limitations together. [VERIFIED: 47-CONTEXT.md] |

**Key insight:** The hard part is not implementing geometry; it is keeping every user-facing and maintainer-facing support surface synchronized with the already-tested v1.11 boundary. [VERIFIED: .planning/ROADMAP.md; 47-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Generated Docs Drift

**What goes wrong:** Source docs are updated but `README.md` or `man/*.Rd` still contains stale support claims. [VERIFIED: README.Rmd generated-file note; 47-CONTEXT.md]
**Why it happens:** Generated artifacts are tracked and require explicit regeneration. [VERIFIED: README.Rmd; man/*.Rd present]
**How to avoid:** Make regeneration and generated diff inspection explicit in `47-01`. [VERIFIED: 47-CONTEXT.md]
**Warning signs:** `rg` still finds stale phrases in `README.md` or `man/*.Rd` after source edits. [VERIFIED: local rg stale-claim sweep]

### Pitfall 2: Ordinary Polygon Wording Swings Too Far

**What goes wrong:** Docs move from "unsupported" to implying full advanced polygon topology parity. [VERIFIED: 47-CONTEXT.md]
**Why it happens:** Phase 44 shipped grouped closed paths, but future topology/hole repair remains deferred. [VERIFIED: 44-VERIFICATION.md; 47-CONTEXT.md]
**How to avoid:** State ordinary `geom_polygon()` support as grouped closed SVG path rendering with styling/facets/interactivity evidence, and list topology/hole repair beyond the supported contract as deferred. [VERIFIED: 44-VERIFICATION.md; 47-CONTEXT.md]
**Warning signs:** Public docs omit limitations next to the support statement. [VERIFIED: 47-CONTEXT.md]

### Pitfall 3: sf Annotation Docs Overpromise Label Placement

**What goes wrong:** Docs imply ggrepel, path-following labels, rich text, or full rotation parity. [VERIFIED: 47-CONTEXT.md]
**Why it happens:** Phase 46 shipped projected-anchor rendering and existing interaction contracts, not advanced annotation placement engines. [VERIFIED: .planning/ROADMAP.md; 46-VERIFICATION.md]
**How to avoid:** Describe `geom_sf_text()` and `geom_sf_label()` as projected-anchor annotations for accepted polygon/point/line families, with skipped-row diagnostics and existing tooltip/hover/brush/handler behavior. [VERIFIED: tests/testthat/test-sf-annotations-ir.R; tests/testthat/test-sf-annotations-renderer.R; tests/testthat/test-sf-annotations-interactivity.R]
**Warning signs:** Docs mention collision avoidance, rich text, or path-following behavior as shipped. [VERIFIED: 47-CONTEXT.md]

### Pitfall 4: Treating Optional Browser Skips As Missing Validation

**What goes wrong:** The validation artifact reads as failed or incomplete on machines without `sf` or browser tooling. [VERIFIED: local environment probe; helper-browser-sf.R]
**Why it happens:** Local `sf` is currently missing, while chromote and Chrome are present. [VERIFIED: local Rscript package probe]
**How to avoid:** Record source/IR/unit coverage separately from optional live DOM coverage, and document what skipped browser/spatial tests would cover. [VERIFIED: 47-CONTEXT.md; tests/testthat/helper-browser-sf.R]
**Warning signs:** A matrix has only one pass/fail cell for both source and browser evidence. [VERIFIED: 47-CONTEXT.md]

## Code Examples

### Documentation Regeneration

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
```

Use this after editing roxygen comments or `README.Rmd`. [VERIFIED: AGENTS.md; README.Rmd]

### Focused Stale-Claim Check

```bash
rtk rg -n 'does not currently have a D3 renderer|no renderer is registered|geom_sf_text\(\).*not supported|geom_sf_label\(\).*not supported' README.Rmd README.md vignettes R man
```

Use this as a post-edit guard for the known stale Phase 47 claims. [VERIFIED: local rg stale-claim sweep]

### Representative Focused Validation Commands

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'
```

These commands map to the three geometry areas in DOCVAL-01; sf-specific tests may skip when `sf` is unavailable. [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-rect-tile-ir.R; tests/testthat/test-sf-annotations-ir.R; local environment probe]

### Optional Browser Smoke Commands

```bash
rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-browser.R")'
rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'
```

These commands exercise live DOM smoke when optional local browser/spatial dependencies are available; they are expected to skip cleanly under documented missing-dependency conditions. [VERIFIED: tests/testthat/helper-browser-polygon.R; tests/testthat/helper-browser-sf.R]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ordinary `geom_polygon()` documented as lacking a renderer | Ordinary `geom_polygon()` is shipped as grouped closed SVG paths with source/DOM/interactivity evidence | Phase 44, 2026-05-24 | README and vignette unsupported wording is stale. [VERIFIED: 44-VERIFICATION.md; README.Rmd; vignettes/gg2d3.Rmd] |
| Rect/tile out-of-bounds behavior left as deferred uncertainty | Rect/tile scale-limit, coord-limit, band-scale, reverse, coord_flip, and facet behavior classified/fixed or closed with evidence | Phase 45, 2026-05-24 | Diagnostics should point to classification and tests, with transformed-scale expansion still deferred. [VERIFIED: 45-RECT-TILE-CLASSIFICATION.md; vignettes/d3-drawing-diagnostics.md] |
| `geom_sf_text()` / `geom_sf_label()` documented as unsupported | sf text/label annotations are shipped as projected-anchor `sf_text` and `sf_label` layers with DOM/interactivity evidence | Phase 46, 2026-05-25 | Diagnostics and help should describe support and limitations instead of unsupported status. [VERIFIED: 46-VERIFICATION.md; R/as_d3_ir.R; R/validate_ir.R] |
| Browser validation only noted for sf polygon/point/line families | Optional browser smoke now also includes ordinary polygons and sf annotation DOM/payload checks | Phases 44 and 46 | Validation notes should distinguish optional browser smoke by geometry area. [VERIFIED: tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-annotations-browser.R] |

**Deprecated/outdated:**
- `Ordinary geom_polygon() does not currently have a D3 renderer` is outdated for v1.11. [VERIFIED: README.Rmd; README.md; 44-VERIFICATION.md]
- Main vignette unsupported polygon example/commentary is outdated for v1.11. [VERIFIED: vignettes/gg2d3.Rmd; 44-VERIFICATION.md]
- Diagnostics claim that `geom_sf_text()` and `geom_sf_label()` are unsupported is outdated for v1.11. [VERIFIED: vignettes/d3-drawing-diagnostics.md; 46-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified against local project files or local tool probes; no `[ASSUMED]` claims are used. [VERIFIED: local repository inspection]

## Open Questions

1. **Exact validation artifact filename**
   - What we know: Context allows a dedicated new file, diagnostics, or both if success criteria are covered. [VERIFIED: 47-CONTEXT.md]
   - What's unclear: The roadmap does not mandate the filename. [VERIFIED: .planning/ROADMAP.md]
   - Recommendation: Use `.planning/phases/47-geometry-parity-docs-and-validation/47-VALIDATION.md` for the matrix and link/mention it from diagnostics. [VERIFIED: prior phase pattern in 44-VALIDATION.md, 45-VALIDATION.md, 46-VALIDATION.md]

2. **Whether to run full package tests in Phase 47**
   - What we know: Focused tests are enough for representative evidence, while `devtools::test()` is the standard full package command. [VERIFIED: AGENTS.md; 47-CONTEXT.md]
   - What's unclear: The roadmap does not require a full release gate for this docs-only phase. [VERIFIED: .planning/ROADMAP.md]
   - Recommendation: Run focused docs/geometry checks during plans; reserve `devtools::test()` for final phase verification or when generated docs raise broader concerns. [VERIFIED: 47-CONTEXT.md; prior 42-VALIDATION-GATE.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | Docs/tests | yes | 4.6.0 | none needed. [VERIFIED: local Rscript probe] |
| devtools | docs/test workflow | yes | 2.5.2 | Use direct `roxygen2`, `testthat`, and `pkgload` calls if needed. [VERIFIED: local Rscript probe] |
| roxygen2 | generated help | yes | 8.0.0 | none needed. [VERIFIED: local Rscript probe] |
| testthat | focused validation | yes | 3.3.2 | none needed. [VERIFIED: local Rscript probe] |
| pkgload | direct test files | yes | 1.5.2 | `devtools::load_all()` if preferred. [VERIFIED: local Rscript probe; AGENTS.md] |
| rmarkdown | README/vignette rendering | yes | 2.31 | none needed. [VERIFIED: local Rscript probe] |
| knitr | README/vignette rendering | yes | 1.51 | none needed. [VERIFIED: local Rscript probe] |
| chromote | optional browser smoke | yes | 0.5.1 | Clean skip if unavailable. [VERIFIED: local Rscript probe; helper-browser-sf.R] |
| Chrome/Chromium | optional browser smoke | yes | Google Chrome app found | Clean skip if unavailable. [VERIFIED: local Rscript probe; helper-browser-polygon.R] |
| sf | sf annotation tests/browser smoke | no | missing | Explicit test skips; install `sf` for live sf annotation evidence. [VERIFIED: local Rscript probe; test-sf-annotations-ir.R] |
| geojsonsf | sf serialization | yes | 2.0.5 | Explicit test skips if unavailable. [VERIFIED: local Rscript probe; test-sf-annotations-ir.R] |
| crosstalk | polygon crosstalk smoke | yes | 1.2.2 | Skip crosstalk-specific branch if unavailable. [VERIFIED: local Rscript probe; test-polygon-browser.R] |

**Missing dependencies with no fallback:**
- None for documentation generation; `sf` is missing locally but sf tests are designed to skip explicitly. [VERIFIED: local Rscript probe; tests/testthat/test-sf-annotations-ir.R]

**Missing dependencies with fallback:**
- `sf` is missing locally; focused sf annotation test commands will skip instead of proving live sf behavior unless `sf` is installed. [VERIFIED: local Rscript probe; tests/testthat/test-sf-annotations-ir.R]

## Validation Architecture

Nyquist validation is enabled by default because `.planning/config.json` does not set `workflow.nyquist_validation` to `false`. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 local [VERIFIED: local Rscript probe] |
| Config file | DESCRIPTION with `Config/testthat/edition: 3` [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-rect-tile-ir.R] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::test()'` [VERIFIED: AGENTS.md] |
| Docs generation command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` [VERIFIED: AGENTS.md; README.Rmd] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCVAL-01 | Ordinary polygon support contract documented with representative IR/source/interactivity/browser evidence | docs + unit/source + optional browser | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` and optional `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | yes. [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-polygon-renderer.R; tests/testthat/test-polygon-interactivity.R; tests/testthat/test-polygon-browser.R] |
| DOCVAL-01 | Rect/tile edge behavior documented with classification and source/IR coverage | docs + unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes. [VERIFIED: tests/testthat/test-rect-tile-ir.R; tests/testthat/test-rect-tile-renderer.R] |
| DOCVAL-01 | sf annotation support contract documented with representative IR/source/interactivity/browser evidence | docs + unit/source + optional browser | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'` and optional `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'` | yes, but local `sf` is missing and sf tests may skip. [VERIFIED: tests/testthat/test-sf-annotations-ir.R; tests/testthat/test-sf-annotations-renderer.R; tests/testthat/test-sf-annotations-interactivity.R; tests/testthat/test-sf-annotations-browser.R; local Rscript probe] |
| DOCVAL-01 | Generated README/help synchronized with source docs | docs generation + grep | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` plus stale-claim `rtk rg` check | source/generated files exist. [VERIFIED: README.Rmd; README.md; R/gg2d3.R; man/gg2d3.Rd] |

### Sampling Rate

- **Per task commit:** Run stale-claim grep checks over touched docs and focused test files for the geometry area being documented. [VERIFIED: 47-CONTEXT.md]
- **Per wave merge:** Run docs regeneration and inspect generated `README.md` / `man/*.Rd` diffs. [VERIFIED: 47-CONTEXT.md; AGENTS.md]
- **Phase gate:** Run all representative geometry commands that do not require missing local dependencies; record explicit skips for optional sf/browser smoke. [VERIFIED: 47-CONTEXT.md; local environment probe]

### Wave 0 Gaps

- [ ] `.planning/phases/47-geometry-parity-docs-and-validation/47-VALIDATION.md` - new artifact for DOCVAL-01 feature-to-evidence matrix. [VERIFIED: 47-CONTEXT.md]
- [ ] Stale docs wording in `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, and `vignettes/d3-drawing-diagnostics.md` must be corrected. [VERIFIED: local rg stale-claim sweep]
- [ ] Roxygen source files should be checked for sf annotation and ordinary polygon wording before regenerating `man/*.Rd`. [VERIFIED: 47-CONTEXT.md; R/gg2d3.R; R/d3_tooltip.R; R/d3_brush.R; R/d3_handlers.R; R/d3_hover.R; R/sf_utils.R]

## Security Domain

Security enforcement is treated as enabled because `.planning/config.json` does not explicitly set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 47 does not add authentication behavior. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Phase 47 does not add sessions. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | Phase 47 does not add authorization behavior. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Preserve existing testthat validation and callback payload sanitization docs; do not add new executable input paths. [VERIFIED: tests/testthat/test-polygon-interactivity.R; tests/testthat/test-sf-annotations-interactivity.R] |
| V6 Cryptography | no | Phase 47 does not add cryptography. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for docs/validation work

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public docs expose renderer-private fields as supported API | Information Disclosure | Keep docs aligned with sanitized public payload tests and avoid documenting underscore-prefixed renderer fields. [VERIFIED: tests/testthat/test-polygon-interactivity.R; tests/testthat/test-sf-annotations-interactivity.R] |
| Docs encourage unsafe external browser tooling additions | Tampering / Supply Chain | Use existing R/testthat/chromote helpers only; do not add Node browser dependencies. [VERIFIED: 46-03-PLAN.md; helper-browser-sf.R] |
| Generated docs hide stale support claims | Repudiation / Integrity | Regenerate from source and run stale-claim grep checks over source and generated docs. [VERIFIED: 47-CONTEXT.md] |

## Plan Split Guidance

### 47-01 - Sweep source and generated documentation

Scope should include `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/gg2d3-interactivity.Rmd`, `vignettes/d3-drawing-diagnostics.md`, roxygen sources in `R/gg2d3.R`, `R/d3_tooltip.R`, `R/d3_brush.R`, `R/d3_handlers.R`, `R/d3_hover.R`, `R/d3_crosstalk.R`, and `R/sf_utils.R`, plus generated help files listed in context. [VERIFIED: 47-CONTEXT.md]

Primary edits should replace stale unsupported wording, add a balanced support table or equivalent contract, and keep concise limitations near support claims. [VERIFIED: 47-CONTEXT.md; local rg stale-claim sweep]

Verification should include docs regeneration, stale-claim grep, and generated artifact diff inspection. [VERIFIED: 47-CONTEXT.md; AGENTS.md]

### 47-02 - Record validation evidence, residual risks, and next-milestone candidates

Scope should create or update a validation evidence artifact mapping ordinary polygons, rect/tile edge behavior, and sf annotations to representative test files, optional browser smoke, commands, skip semantics, and residual risks. [VERIFIED: 47-CONTEXT.md]

The artifact should link Phase 45 rect/tile classification notes, Phase 44 polygon browser/source tests, and Phase 46 sf annotation IR/source/browser tests. [VERIFIED: 45-RECT-TILE-CLASSIFICATION.md; tests/testthat/test-polygon-browser.R; tests/testthat/test-sf-annotations-browser.R]

Residual/future items should remain explicit: polygon topology/hole repair beyond grouped paths, transformed-scale rect/tile expansion, tile basemaps/slippy controls, JavaScript CRS reprojection, ggrepel collision avoidance, rich text, rotation parity, and path-following annotation placement. [VERIFIED: 47-CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/47-geometry-parity-docs-and-validation/47-CONTEXT.md` - locked docs/evidence decisions and canonical surfaces. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - DOCVAL-01 requirement. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 47 success criteria and plan split. [VERIFIED: file read]
- `.planning/PROJECT.md` and `.planning/STATE.md` - milestone status and prior decisions. [VERIFIED: file read]
- `AGENTS.md` and `/Users/davidzenz/.codex/RTK.md` - project commands and shell prefix rule. [VERIFIED: file read]
- `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/gg2d3-interactivity.Rmd`, `vignettes/d3-drawing-diagnostics.md` - docs surfaces and stale claims. [VERIFIED: local `sed` / `rg`]
- `R/gg2d3.R`, `R/d3_tooltip.R`, `R/d3_brush.R`, `R/d3_handlers.R`, `R/d3_hover.R`, `R/d3_crosstalk.R`, `R/sf_utils.R` - roxygen/help source surfaces. [VERIFIED: local `sed` / `rg`]
- `tests/testthat/test-polygon-*.R`, `tests/testthat/test-rect-tile-*.R`, `tests/testthat/test-sf-annotations-*.R`, and browser helpers - representative validation evidence and skip behavior. [VERIFIED: local `sed` / `rg`]
- `.planning/phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md` - rect/tile classification evidence. [VERIFIED: file read]

### Secondary (MEDIUM confidence)

- Prior phase validation patterns in `.planning/phases/44-*`, `.planning/phases/45-*`, `.planning/phases/46-*`, and `.planning/milestones/v1.10-phases/42-*`. [VERIFIED: local `rg`]

### Tertiary (LOW confidence)

- None. [VERIFIED: no web-only or unverified sources used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and workflows verified from DESCRIPTION, AGENTS.md, README.Rmd, and local R package probes. [VERIFIED: DESCRIPTION; AGENTS.md; local Rscript probe]
- Architecture: HIGH - docs/source/generated boundary is explicitly locked in Phase 47 context. [VERIFIED: 47-CONTEXT.md]
- Pitfalls: HIGH - stale claims were found by local grep and prior phase evidence confirms the shipped behavior. [VERIFIED: local rg stale-claim sweep; 44-VERIFICATION.md; 46-VERIFICATION.md]

**Research date:** 2026-05-25 [VERIFIED: local date]
**Valid until:** 2026-06-01 for local docs/test surfaces; re-run grep and environment probes if Phase 47 starts later. [VERIFIED: time-sensitive local repository state]
